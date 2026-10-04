import test from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import {createEnrollmentHandler,resendEventSender} from './enrollment.mjs';
import {automationDefinition,messages,renderTemplate,EVENT,CONSENT_VERSION} from './sequence.mjs';

function setup(overrides={}) {
  const raw=new DatabaseSync(':memory:');raw.exec(readFileSync(new URL('./schema.sql',import.meta.url),'utf8'));
  const db={prepare(sql){let args=[];return {bind(...next){args=next;return this},async first(){return raw.prepare(sql).get(...args)},async run(){return raw.prepare(sql).run(...args)}}}};
  const calls=[];
  const handler=createEnrollmentHandler({db,enabled:true,authenticate:async()=>({id:'account-1',email:'learner@example.invalid',emailVerified:true}),sendEvent:async value=>{calls.push(value)},...overrides});
  return {raw,handler,calls};
}
const origin='https://securebydesigninc.com';
const consent={consent:true,consentVersion:CONSENT_VERSION};
function request(body=consent,headers={},method='POST') {return new Request(origin+'/api/app-onboarding-email',{method,headers:{origin,'content-type':'application/json',...headers},...(method==='GET'?{}:{body:JSON.stringify(body)})});}

test('no verified account, no opt-in, or disabled integration cannot send',async()=>{
  for(const identity of [null,{id:'x',email:'attacker@example.invalid',emailVerified:false}]){
    const s=setup({authenticate:async()=>identity});assert.equal((await s.handler(request())).status,401);assert.equal(s.calls.length,0);
  }
  const off=setup({enabled:false});assert.equal((await off.handler(request())).status,503);assert.equal(off.calls.length,0);
  const s=setup();for(const body of [{},{consent:false,consentVersion:CONSENT_VERSION},{...consent,consentVersion:'old'},{...consent,email:'attacker@example.invalid'},{...consent,account_id:'someone-else'},null,[]])assert.equal((await s.handler(request(body))).status,400);
  assert.equal(s.calls.length,0);
});
test('same-origin enforcement and bounded bodies protect the cookie adapter',async()=>{
  const s=setup();for(const headers of [{origin:'https://attacker.invalid'},{origin:'null'},{origin:''},{'sec-fetch-site':'cross-site'}])assert.equal((await s.handler(request(consent,headers))).status,403);
  assert.equal((await s.handler(request(consent,{'content-type':'text/plain'}))).status,400);
  assert.equal((await s.handler(request({value:'x'.repeat(2000)}))).status,413);
  assert.equal(s.calls.length,0);
});
test('two devices and repeated sign-ins start only one sequence',async()=>{
  const s=setup();const results=await Promise.all([s.handler(request()),s.handler(request())]);
  assert.ok(results.some(r=>r.status===202));assert.equal(s.calls.length,1);
  assert.equal((await s.handler(request())).status,200);assert.equal(s.calls.length,1);
  assert.deepEqual(s.calls[0],{event:EVENT,email:'learner@example.invalid',payload:{sequence_version:CONSENT_VERSION}});
  const row=s.raw.prepare('SELECT * FROM app_email_enrollments').get();assert.equal(row.state,'accepted');assert.equal(row.consent_version,CONSENT_VERSION);assert.ok(row.consent_at);assert.ok(row.consent_text.includes('3 days'));
});
test('uncertain provider responses are not retried and do not claim success',async()=>{
  let attempts=0;const s=setup({sendEvent:async()=>{attempts++;throw Error('timeout')}});
  assert.equal((await s.handler(request())).status,502);assert.equal((await s.handler(request())).status,409);assert.equal(attempts,1);
  assert.equal(s.raw.prepare('SELECT state FROM app_email_enrollments').get().state,'review_required');
});
test('GET status is read-only and scoped to the authenticated account',async()=>{
  const s=setup();let response=await s.handler(request(undefined,{},'GET'));assert.equal((await response.json()).enrollment,'not_enrolled');assert.match(response.headers.get('cache-control'),/no-store/);assert.equal(s.calls.length,0);
  await s.handler(request());assert.equal((await (await s.handler(request(undefined,{},'GET'))).json()).enrollment,'accepted');
});
test('storage failure prevents network delivery',async()=>{
  const s=setup();s.raw.exec('DROP TABLE app_email_enrollments');assert.equal((await s.handler(request())).status,503);assert.equal(s.calls.length,0);
});
test('Resend adapter uses only server credentials and exact event API acceptance',async()=>{
  const event={event:EVENT,email:'learner@example.invalid',payload:{sequence_version:CONSENT_VERSION}};
  let called=0;await resendEventSender('test-secret',async(url,init)=>{called++;assert.equal(url,'https://api.resend.com/events/send');assert.equal(init.redirect,'error');assert.equal(init.headers.authorization,'Bearer test-secret');assert.deepEqual(JSON.parse(init.body),event);return new Response('',{status:202})})(event);assert.equal(called,1);
  await assert.rejects(()=>resendEventSender('',async()=>{throw Error('must not call')})(event));
  await assert.rejects(()=>resendEventSender('test',async()=>new Response('',{status:429}))(event));
});
test('journey sends on days 0, 3, 7 and ends immediately after an unsubscribe',()=>{
  const flow=automationDefinition();assert.equal(flow.status,'disabled');
  function simulate(unsubscribeAt=Infinity){let key='start',days=0,sent=[];for(let count=0;count<25&&key;count++){
    const step=flow.steps.find(s=>s.key===key);assert.ok(step);
    if(step.type==='delay'&&step.config.duration.endsWith('days'))days+=Number(step.config.duration.split(' ')[0]);
    if(step.type==='send_email')sent.push({key,days});
    const type=step.type==='condition'?(days<unsubscribeAt?'condition_met':'condition_not_met'):'default';
    key=flow.connections.find(c=>c.from===key&&(c.type||'default')===type)?.to;
  }return sent;}
  assert.deepEqual(simulate(),[{key:'welcome',days:0},{key:'tip',days:3},{key:'feedback',days:7}]);
  assert.deepEqual(simulate(0),[]);assert.deepEqual(simulate(1),[{key:'welcome',days:0}]);assert.deepEqual(simulate(4),[{key:'welcome',days:0},{key:'tip',days:3}]);
  for(const step of flow.steps.filter(s=>s.type==='condition'))assert.deepEqual(step.config,{type:'rule',field:'contact.unsubscribed',operator:'eq',value:false});
});
test('all three branded templates contain the provider unsubscribe link',()=>{
  assert.equal(messages.length,3);for(const message of messages){const html=renderTemplate(message);assert.match(html,/\{\{\{RESEND_UNSUBSCRIBE_URL\}\}\}/);assert.match(html,/#83dcfa/);assert.match(html,/#102237/);assert.ok(html.includes(message.link));assert.ok(!html.includes('localhost'));}
});
