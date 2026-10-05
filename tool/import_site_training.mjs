import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {pathToFileURL} from 'node:url';

const site=path.resolve(process.argv[2]);
const root=path.resolve(import.meta.dirname,'..');
const read=p=>JSON.parse(fs.readFileSync(path.join(site,p),'utf8'));
const catalog=read('content/videos.json');
const configurations=read('content/configuration-courses.json');
const dc=read('public/training/dc01-dc02/lesson.json');
const context={window:{}};
for(const p of ['catalog-data.js','learning-data.js'])vm.runInNewContext(fs.readFileSync(path.join(site,'public/training/rmf',p),'utf8'),context);
const {CATALOG,LEARNING}=context.window;
const base='https://securebydesigninc.com';
const q=s=>JSON.stringify(String(s)).replace(/\$/g,'\\$');
const section=(h,b)=>`LessonSection(${q(h)}, ${q(b)})`;
const resource=(id,title,url,description,category='Training materials')=>({id,title,url:base+url,description,category,publisher:'Secure By Design',icon:'directory'});
const dcMaterials=[resource('dc-guide','Interactive build guide',catalog.episodes[0].training.guide,'Explore the build and keep your evidence record.'),resource('dc-pdf','Companion workbook · PDF',catalog.episodes[0].training.pdf,'12 pages · edition 0.3'),resource('dc-word','Editable workbook · Word',catalog.episodes[0].training.word,'Make the workbook your own.'),resource('dc-package','Complete learning package · ZIP',catalog.episodes[0].training.package,'Guide, workbooks, and verification commands.')];
const rmfMaterials=[resource('rmf-guide','Interactive authorization course',catalog.courses[0].training.guide,'Lessons, evidence examples, and the capstone.'),resource('rmf-word','Full training catalog · Word',catalog.courses[0].training.word,'Edition 1.0 · 12 modules'),resource('rmf-evidence','Body of Evidence examples and starters','/training/rmf/index.html#evidence','Ten examples with editable Markdown and CSV starters.'),resource('rmf-capstone','Authorization package capstone','/training/rmf/index.html#capstone','Assemble, defend, and maintain the practice package.')];
const courses=[{
 ...catalog.episodes[0],category:'Network build',icon:'directory',studyTime:'5 guided chapters',topics:5,materials:dcMaterials,
 lessons:dc.chapters.map(c=>({id:`training:dc01-dc02:${c.id}`,title:c.title,minutes:10,summary:c.outcome,sections:[section('Understand the why',c.intro),...(c.foundationIds||[]).flatMap(id=>{const f=dc.foundations.find(x=>x.id===id);return [section(f.title,f.summary),...f.blocks.map(s=>section(...s)),section('Remember',f.takeaway)]}),...c.steps.map(s=>section(...s)),section(c.commandLabel,c.command),section('What to look for',c.expected),section('Avoid this mistake',c.mistake),section('Keep your evidence',c.evidencePrompt)],quiz:[c.quiz.prompt,c.quiz.answers,c.quiz.correct,c.quiz.feedback],source:base+catalog.episodes[0].training.guide+'#'+c.id})),
},{
 ...catalog.courses[0],category:'Network authorization',icon:'risk',studyTime:'12 modules · 36 topics · 24 study hours',topics:36,materials:rmfMaterials,
 lessons:CATALOG.map((m,i)=>{const l=LEARNING[i];return{id:`training:rmf-boe-ato:${m.id}`,title:`${m.id} · ${m.title}`,minutes:Math.round(Number(m.hours)*60),summary:m.outcome,sections:[...l.learn.map(a=>section(a[0],a.slice(1).join('\n\n'))),section(l.example[0],l.example[1].map(a=>a.join(': ')).join('\n\n')),section('Build',m.build),section('Prove',m.prove)],quiz:l.quiz,source:base+'/training/rmf/index.html#catalog/'+m.id};}),
}, ...configurations.map(config=>{
 const course=catalog.courses.find(c=>c.id===config.id);
 return {...course,category:'Network build',icon:config.id==='two-tier-pki'?'risk':'directory',studyTime:`${config.lessons.length} guided lessons · Self-paced`,topics:config.lessons.length,
 materials:[resource(`${course.id}-guide`,`${course.title} · Interactive guide`,course.training.guide,course.subtitle),resource(`${course.id}-checklist`,`${course.title} · Configuration checklist`,course.training.checklist,'Download a Markdown checklist for your configuration and evidence.')],
 lessons:config.lessons.map(l=>({id:`training:${course.id}:${l.id}`,title:l.title,minutes:l.minutes,summary:l.summary,sections:[section('Before you start',config.prerequisites.join('\n\n')),section('The lab plan',config.labNote),...l.steps.map((s,i)=>section(`Step ${i+1}`,s)),section('Inspect your configuration',l.command),section('What success looks like',l.check),section('Keep your evidence',l.evidence),section('Source documentation',config.sources.filter(s=>l.sources.includes(s.id)).map(s=>`${s.title}\n${s.url}`).join('\n\n'))],quiz:[l.quiz.question,l.quiz.answers,l.quiz.correct,l.quiz.explanation],source:base+course.training.guide+'#'+l.id}))};
})];
courses.sort((a,b)=>catalog.categories.findIndex(c=>c.id===a.categoryId)-catalog.categories.findIndex(c=>c.id===b.categoryId)||(a.categoryOrder??0)-(b.categoryOrder??0));
const materialDart=r=>`LearningResource(id:${q(r.id)},title:${q(r.title)},publisher:${q(r.publisher)},description:${q(r.description)},url:${q(r.url)},category:${q(r.category)},icon:${q(r.icon)})`;
const lessonDart=l=>`Lesson(id:${q(l.id)},title:${q(l.title)},minutes:${l.minutes},summary:${q(l.summary)},sections:[${l.sections.join(',')}],question:${q(l.quiz[0])},answers:[${l.quiz[1].map(q).join(',')}],correctAnswer:${l.quiz[2]},explanation:${q(l.quiz[3])},sourceUrl:${q(l.source)},sourceLabel:'Open the complete guide')`;
const output=`// Generated from the published Secure By Design training catalog.\n// Run: node tool/import_site_training.mjs /path/to/site\nimport 'models.dart';\n\nconst publishedPaths = <LearningPath>[${courses.map(c=>`LearningPath(id:${q(c.id)},number:${q(c.number)},title:${q(c.title)},subtitle:${q(c.subtitle)},category:${q(c.category)},description:${q(c.description)},icon:${q(c.icon)},published:true,studyTime:${q(c.studyTime)},topics:${c.topics},materials:[${c.materials.map(materialDart).join(',')}],lessons:[${c.lessons.map(lessonDart).join(',')}])`).join(',')}];\n`;
fs.writeFileSync(path.join(root,'lib/data/published_catalog.dart'),output);
const {inventory}=await import(pathToFileURL(path.join(site,'public/inside-network-model/inventory.js')));
const architecture=await import(pathToFileURL(path.join(site,'public/inside-network-model/architecture.js')));
const {scenarios,technical}=await import(pathToFileURL(path.join(site,'public/inside-network-model/technical.js')));
fs.mkdirSync(path.join(root,'assets/training'),{recursive:true});
fs.writeFileSync(path.join(root,'assets/training/network.json'),JSON.stringify({nodes:architecture.buildArchitectureNodes(inventory.nodes),vlans:architecture.vlans,facilities:architecture.facilities,scenarios,technical},null,2));
const progress=courses.flatMap(c=>c.lessons.map(l=>({id:l.id,title:l.title,href:l.source.replace(base,''),group:c.category})));
fs.writeFileSync(path.join(site,'content/training-progress.json'),JSON.stringify(progress,null,2)+'\n');
fs.writeFileSync(path.join(site,'content/training-resources.json'),JSON.stringify(courses.flatMap(c=>c.materials),null,2)+'\n');
console.log(`Imported ${courses.length} courses, ${progress.length} learning units, and ${scenarios.length} network flows.`);
