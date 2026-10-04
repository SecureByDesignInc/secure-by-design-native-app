import {mkdir,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {messages,renderTemplate,automationDefinition} from './sequence.mjs';
const directory=new URL('./generated/',import.meta.url);await mkdir(directory,{recursive:true});
for(const message of messages)await writeFile(new URL(message.alias+'.html',directory),renderTemplate(message));
await writeFile(new URL('automation.json',directory),JSON.stringify(automationDefinition(),null,2)+'\n');
console.log(fileURLToPath(directory));
