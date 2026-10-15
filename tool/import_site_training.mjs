// Imports the published Secure By Design training catalog and the Inside the Network
// reference from a Site checkout into the native app.
//
//   node tool/import_site_training.mjs /path/to/site [--write-site]
//
// Writes lib/data/published_catalog.dart and assets/training/network.json in this
// repository. The Site maintains content/training-progress.json and
// content/training-resources.json itself; they are only read here. Pass --write-site
// to regenerate them from the app's catalog (not part of the normal workflow).
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {pathToFileURL} from 'node:url';

const args = process.argv.slice(2);
const writeSite = args.includes('--write-site');
const siteArg = args.find(arg => !arg.startsWith('--'));
if (!siteArg) {
  console.error('Usage: node tool/import_site_training.mjs /path/to/site [--write-site]');
  process.exit(2);
}
const site = path.resolve(siteArg);
const root = path.resolve(import.meta.dirname, '..');
const read = p => JSON.parse(fs.readFileSync(path.join(site, p), 'utf8'));
const fail = message => { throw new Error(message); };

const catalog = read('content/videos.json');
const configurations = read('content/configuration-courses.json');
const dc = read('public/training/dc01-dc02/lesson.json');
const siteProgress = read('content/training-progress.json');
const siteResources = read('content/training-resources.json');
const context = {window: {}};
for (const p of ['catalog-data.js', 'learning-data.js']) {
  vm.runInNewContext(fs.readFileSync(path.join(site, 'public/training/rmf', p), 'utf8'), context);
}
const {CATALOG, CATALOG_PARTS, LEARNING} = context.window;

const base = 'https://securebydesigninc.com';
const q = s => JSON.stringify(String(s)).replace(/\$/g, '\\$');
const section = (heading, body) => ({heading, body});
const quiz = (question, answers, correct, explanation) => {
  if (!Array.isArray(answers) || !(correct >= 0 && correct < answers.length)) fail(`Invalid quiz: ${question}`);
  return {question, answers, correct, explanation};
};
const resource = (id, title, url, description) =>
  ({id, title, url: url.startsWith('http') ? url : base + url, description, category: 'Training materials', publisher: 'Secure By Design', icon: 'directory'});
// Reuse the Site's bookmark ID for a destination it already catalogs.
const siteIdFor = (url, fallback) => siteResources.find(r => r.url === base + url)?.id ?? fallback;
// Coming-soon tiles (kind "coming-soon") have no material yet, so the app leaves them out until they do.
const entries = [...catalog.episodes, ...catalog.courses.filter(c => c.kind !== 'coming-soon')];
const entry = id => entries.find(e => e.id === id) ?? fail(`Catalog entry ${id} is missing from content/videos.json`);

// 1.1 · Promote Primary & Secondary Domain Controller (DC01/DC02 episode)
const dcEntry = entry('dc01-dc02');
const dcCourse = {
  ...dcEntry, category: 'Network build', icon: 'directory', studyTime: `${dc.chapters.length} guided chapters`, topics: dc.chapters.length,
  materials: [
    // One download per course (owner request, 9 October 2026): the guide plus its ZIP.
    resource('dc-guide', 'Interactive build guide', dcEntry.training.guide, 'Explore the build and keep your evidence record.'),
    resource('dc-package', 'Training materials · ZIP', dcEntry.training.package, 'Offline guide, workbook (PDF and Word), and verification commands.'),
  ],
  lessons: dc.chapters.map(c => ({
    id: `training:dc01-dc02:${c.id}`, title: c.title, minutes: 10, summary: c.outcome,
    sections: [
      section('Understand the why', c.intro),
      ...(c.foundationIds || []).flatMap(id => {
        const f = dc.foundations.find(x => x.id === id) ?? fail(`Unknown foundation ${id}`);
        return [section(f.title, f.summary), ...f.blocks.map(s => section(...s)), section('Remember', f.takeaway)];
      }),
      ...c.steps.map(s => section(...s)),
      section(c.commandLabel, c.command), section('What to look for', c.expected),
      section('Avoid this mistake', c.mistake), section('Keep your evidence', c.evidencePrompt),
    ],
    quizzes: [quiz(c.quiz.prompt, c.quiz.answers, c.quiz.correct, c.quiz.feedback)],
    source: base + dcEntry.training.guide + '#' + c.id,
  })),
};

// 2.1–2.3 · Network Authorization: three courses, each with its own page and download (owner request,
// 15 October 2026). Modules follow the RMF steps of NIST SP 800-37 Rev. 2 with the 2016 JSIG mapped in.
// Lesson IDs stay training:rmf-boe-ato:<module> so saved progress survives.
const rmfParts = catalog.courses.filter(c => c.categoryId === 'network-authorization').sort((a, b) => a.categoryOrder - b.categoryOrder);
if (rmfParts[0]?.id !== 'rmf-boe-ato') fail('The first Network Authorization part must keep the rmf-boe-ato ID.');
if (rmfParts.flatMap(p => p.moduleIds).join() !== CATALOG.map(m => m.id).join()) fail('RMF parts must cover every module once, in order.');
// The Site's own entry for a destination (bookmark ID, title, description), so saved materials match the Site.
const siteResource = url => {
  const r = siteResources.find(x => x.url === base + url && !x.retired) ?? fail(`The Site has no training resource for ${url}`);
  return resource(r.id, r.title, url, r.description);
};
const taskLines = tasks => tasks.map(([id, name]) => `${id} · ${name}`).join('\n');
const rmfStep = m => {
  const r = m.rmf;
  return [
    section(m.phase === 'Foundations' ? 'Before the RMF steps' : `The RMF step · ${r.step}`, r.roles),
    ...(r.nist.length ? [section('NIST SP 800-37 Rev. 2 tasks', taskLines(r.nist))] : []),
    ...(r.jsig.length ? [section('JSIG (11 April 2016) tasks', taskLines(r.jsig))] : m.phase === 'Prepare' ? [section('JSIG (11 April 2016) tasks', 'The 2016 JSIG has no Prepare step.')] : []),
    section('What this module produces', r.outputs.map(o => `• ${o}`).join('\n') + (r.jsigOutputs.length ? `\n\nJSIG step outputs: ${r.jsigOutputs.join('; ')}` : '')),
    ...(r.difference ? [section('Where the JSIG and NIST differ', r.difference)] : []),
  ];
};
const rmfCourses = rmfParts.map(part => {
  const layout = CATALOG_PARTS.find(p => p.id === part.id) ?? fail(`${part.id} is missing from CATALOG_PARTS`);
  const page = `/training/${layout.folder}/index.html`;
  const modules = CATALOG.filter(m => part.moduleIds.includes(m.id));
  const topics = modules.reduce((n, m) => n + m.lessons.length, 0);
  const hours = modules.reduce((n, m) => n + Number(m.hours), 0) + (part.capstoneHours ?? 0);
  if (topics !== part.lessonCount || hours !== part.estimatedHours) fail(`${part.id} counts differ from the module catalog`);
  return {
    ...part, category: 'Network authorization', icon: 'risk',
    studyTime: `${modules.length} modules · ${topics} topics · ${hours} study hours`,
    topics, materials: [siteResource(page), siteResource(part.training.package), ...part.training.relatedResources.map(r => siteResource(r.href))],
    lessons: modules.map(m => {
      const l = LEARNING[CATALOG.indexOf(m)];
      return {
        id: `training:rmf-boe-ato:${m.id}`, title: `${m.id} · ${m.title}`, minutes: Math.round(Number(m.hours) * 60), summary: m.outcome,
        sections: [...rmfStep(m), ...l.learn.map(a => section(a[0], a.slice(1).join('\n\n'))), section(l.example[0], l.example[1].map(a => a.join(': ')).join('\n\n')), section('Build', m.build), section('Prove', m.prove)],
        quizzes: [quiz(...l.quiz)],
        source: base + page + '#catalog/' + m.id,
      };
    }),
  };
});

// 1.2–1.10 · Configuration courses
const configCourses = configurations.map(config => {
  const course = entry(config.id), t = course.training;
  const materials = [
    resource(siteIdFor(t.guide, `${course.id}-guide`), `${course.title} · Interactive guide`, t.guide, course.subtitle),
    resource(siteIdFor(t.package ?? fail(`${course.id} has no training package`), `${course.id}-package`), `${course.title} · Training materials (ZIP)`, t.package,
      'Workbook (PDF and Word), checklist, and verification commands.'),
  ];
  return {
    ...course, category: 'Network build', icon: course.id.includes('pki') ? 'risk' : course.id === 'logging-pipeline' ? 'monitoring' : 'directory',
    studyTime: `${config.lessons.length} guided lessons · Self-paced`, topics: config.lessons.length, materials,
    lessons: config.lessons.map(l => {
      if (!Array.isArray(l.quizzes) || !l.quizzes.length) fail(`${config.id}/${l.id} has no knowledge checks`);
      return {
        id: `training:${course.id}:${l.id}`, title: l.title, minutes: l.minutes, summary: l.summary,
        objectives: l.objectives ?? [], recap: l.recap ?? [], next: l.next ?? '',
        sections: [
          section('Before you start', config.prerequisites.join('\n\n')), section('The lab plan', config.labNote),
          ...l.steps.map((s, i) => section(`Step ${i + 1}`, s)),
          section('Inspect your configuration', l.command), section('What success looks like', l.check), section('Keep your evidence', l.evidence),
          section('Source documentation', config.sources.filter(s => l.sources.includes(s.id)).map(s => `${s.title}\n${s.url}`).join('\n\n')),
        ],
        quizzes: l.quizzes.map(x => quiz(x.question, x.answers, x.correct, x.explanation)),
        source: base + t.guide + '#' + l.id,
      };
    }),
  };
});

const courses = [dcCourse, ...rmfCourses, ...configCourses];
const categoryIndex = c => catalog.categories.findIndex(x => x.id === c.categoryId);
courses.sort((a, b) => categoryIndex(a) - categoryIndex(b) || (a.categoryOrder ?? 0) - (b.categoryOrder ?? 0));
if (courses.length !== entries.length) fail(`Imported ${courses.length} courses, but the Site publishes ${entries.length} catalog entries.`);

// IDs must already be known to the Site's sync endpoints, or account sync would reject the batch.
const lessons = courses.flatMap(c => c.lessons);
const lessonIds = lessons.map(l => l.id);
if (new Set(lessonIds).size !== lessonIds.length) fail('Duplicate lesson IDs');
const knownLessons = new Set(siteProgress.map(p => p.id));
const unknownLessons = lessonIds.filter(id => !knownLessons.has(id));
if (unknownLessons.length && !writeSite) fail(`Lessons missing from the Site progress catalog: ${unknownLessons.join(', ')}`);
const materialsById = new Map();
for (const r of courses.flatMap(c => c.materials)) {
  const existing = materialsById.get(r.id);
  if (existing && JSON.stringify(existing) !== JSON.stringify(r)) fail(`Material ID ${r.id} is used for different destinations`);
  materialsById.set(r.id, r);
}
const knownResources = new Set(siteResources.map(r => r.id));
const syncable = id => writeSite || knownResources.has(id);

const list = (items, render = q) => `[${items.map(render).join(', ')}]`;
const materialDart = r => `LearningResource(id: ${q(r.id)}, title: ${q(r.title)}, publisher: ${q(r.publisher)}, description: ${q(r.description)}, url: ${q(r.url)}, category: ${q(r.category)}, icon: ${q(r.icon)}${syncable(r.id) ? '' : ', syncable: false'})`;
const questionDart = x => `QuizQuestion(${q(x.question)}, ${list(x.answers)}, ${x.correct}, ${q(x.explanation)})`;
const lessonDart = l => {
  const [first, ...more] = l.quizzes;
  return `Lesson(id: ${q(l.id)}, title: ${q(l.title)}, minutes: ${l.minutes}, summary: ${q(l.summary)}, ` +
    (l.objectives?.length ? `objectives: ${list(l.objectives)}, ` : '') +
    `sections: ${list(l.sections, s => `LessonSection(${q(s.heading)}, ${q(s.body)})`)}, ` +
    `question: ${q(first.question)}, answers: ${list(first.answers)}, correctAnswer: ${first.correct}, explanation: ${q(first.explanation)}, ` +
    (more.length ? `moreQuestions: ${list(more, questionDart)}, ` : '') +
    (l.recap?.length ? `recap: ${list(l.recap)}, ` : '') +
    (l.next ? `nextStep: ${q(l.next)}, ` : '') +
    `sourceUrl: ${q(l.source)}, sourceLabel: 'Open the complete guide')`;
};
const pathDart = c => `  LearningPath(id: ${q(c.id)}, number: ${q(c.number)}, title: ${q(c.title)}, subtitle: ${q(c.subtitle)}, category: ${q(c.category)}, description: ${q(c.description)}, icon: ${q(c.icon)}, published: true, studyTime: ${q(c.studyTime)}, topics: ${c.topics},\n` +
  `    materials: [\n${c.materials.map(r => '      ' + materialDart(r)).join(',\n')}\n    ],\n` +
  `    lessons: [\n${c.lessons.map(l => '      ' + lessonDart(l)).join(',\n')}\n    ])`;
const output = `// Generated from the published Secure By Design training catalog.\n// Run: node tool/import_site_training.mjs /path/to/site\nimport 'models.dart';\n\nconst publishedPaths = <LearningPath>[\n${courses.map(pathDart).join(',\n')}\n];\n`;
fs.writeFileSync(path.join(root, 'lib/data/published_catalog.dart'), output);

// Inside the Network: the same modules the Site's 3D model and text view use.
const model = p => import(pathToFileURL(path.join(site, 'public/inside-network-model', p)));
const {inventory} = await model('inventory.js');
const architecture = await model('architecture.js');
const {scenarios, whatIfs = [], technical} = await model('technical.js');
const {trafficRules = [], policyStatus = {}} = await model('security.js');
const {stepPolicy} = await model('flow-policy.js');
const nodes = architecture.buildArchitectureNodes(inventory.nodes);
const withPolicy = sequence => ({
  ...sequence,
  steps: sequence.steps.map(step => {
    const policy = stepPolicy(step);
    return {...step, policy: {kind: policy.kind, rule: policy.rule?.id ?? null, label: policy.label}};
  }),
});
const policy = trafficRules.map(({id, from, to, service, transport, purpose, owner, status}) =>
  ({id, from, to, service, transport, purpose, owner, status, statusLabel: policyStatus[status] ?? status}));
fs.mkdirSync(path.join(root, 'assets/training'), {recursive: true});
fs.writeFileSync(path.join(root, 'assets/training/network.json'), JSON.stringify({
  nodes, vlans: architecture.vlans, facilities: architecture.facilities,
  scenarios: scenarios.map(withPolicy), whatIfs: whatIfs.map(withPolicy), policy, technical,
}, null, 2) + '\n');

if (writeSite) {
  const progress = courses.flatMap(c => c.lessons.map(l => ({id: l.id, title: l.title, href: l.source.replace(base, ''), group: c.category})));
  fs.writeFileSync(path.join(site, 'content/training-progress.json'), JSON.stringify(progress, null, 2) + '\n');
  fs.writeFileSync(path.join(site, 'content/training-resources.json'), JSON.stringify([...materialsById.values()], null, 2) + '\n');
  console.log('Wrote the Site progress and resource catalogs (--write-site).');
}
const localOnly = [...materialsById.keys()].filter(id => !syncable(id));
console.log(`Imported ${courses.length} courses, ${lessons.length} lessons, ${lessons.reduce((n, l) => n + l.quizzes.length, 0)} knowledge checks, ` +
  `${materialsById.size} materials, ${scenarios.length} traffic processes, ${whatIfs.length} what-ifs, ${policy.length} policy rules, and ${nodes.length} systems.`);
if (localOnly.length) console.log(`Materials not in the Site bookmark catalog (saved on this device only): ${localOnly.join(', ')}`);
