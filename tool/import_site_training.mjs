// Imports the published Secure By Design training catalog and the Inside the Network
// reference from a Site checkout into the native app.
//
//   node tool/import_site_training.mjs /path/to/site
//
// Writes lib/data/published_catalog.dart and assets/training/network.json in this
// repository. The catalog comes from the Site's scripts/prepare-app-content.mjs, the same
// code that publishes public/app-content/v1/catalog.json for the app to download, so the
// catalog built into the app and the one it downloads can never drift apart. The Site
// maintains content/training-progress.json and content/training-resources.json itself.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

const siteArg = process.argv.slice(2).find(arg => !arg.startsWith('--'));
if (!siteArg) {
  console.error('Usage: node tool/import_site_training.mjs /path/to/site');
  process.exit(2);
}
const site = path.resolve(siteArg);
const root = path.resolve(import.meta.dirname, '..');
const {appContent, APP_CONTENT_SCHEMA} = await import(pathToFileURL(path.join(site, 'scripts/prepare-app-content.mjs')));
const {content, materials, manifest} = appContent(site);
const {categories, courses, comingSoon} = content;
// The Community & Careers Hub's state pages (the Site's content/community-states.json).
const states = JSON.parse(fs.readFileSync(path.join(site, 'content/community-states.json'), 'utf8'))
  .map(({code, name, slug}) => ({code, name, slug}));
if (states.length < 51 || states.some(st => !/^[a-z-]+$/.test(st.slug))) throw new Error('Unexpected community state list');

const q = s => JSON.stringify(String(s)).replace(/\$/g, '\\$');
const list = (items, render = q) => `[${items.map(render).join(', ')}]`;
// Category icons stay app presentation; the Site supplies the IDs, titles and descriptions.
const categoryIcon = id => id === 'network-authorization' ? 'journal' : 'directory';
const categoryDart = c => `  TrainingCategory(${q(c.id)}, ${q(c.title)}, ${q(c.description)}, icon: ${q(categoryIcon(c.id))})`;
const soonDart = c => `  ComingSoonCourse(id: ${q(c.id)}, number: ${q(c.number)}, title: ${q(c.title)}, subtitle: ${q(c.subtitle)}, description: ${q(c.description)}, categoryId: ${q(c.categoryId)})`;
const materialDart = r => `LearningResource(id: ${q(r.id)}, title: ${q(r.title)}, publisher: ${q(r.publisher)}, description: ${q(r.description)}, url: ${q(r.url)}, category: ${q(r.category)}, icon: ${q(r.icon)}${r.syncable ? '' : ', syncable: false'})`;
const questionDart = x => `QuizQuestion(${q(x.question)}, ${list(x.answers)}, ${x.correct}, ${q(x.explanation)})`;
const guideDart = g => `LessonGuide(id: ${q(g.id)}, chapter: ${q(g.chapter)}, checklist: ${list(g.checklist)}, stepTitles: ${list(g.stepTitles)})`;
const lessonDart = l => {
  const [first, ...more] = l.quizzes;
  return `Lesson(id: ${q(l.id)}, title: ${q(l.title)}, minutes: ${l.minutes}, summary: ${q(l.summary)}, ` +
    (l.objectives?.length ? `objectives: ${list(l.objectives)}, ` : '') +
    `sections: ${list(l.sections, s => `LessonSection(${q(s.heading)}, ${q(s.body)})`)}, ` +
    `question: ${q(first.question)}, answers: ${list(first.answers)}, correctAnswer: ${first.correct}, explanation: ${q(first.explanation)}, ` +
    (more.length ? `moreQuestions: ${list(more, questionDart)}, ` : '') +
    (l.recap?.length ? `recap: ${list(l.recap)}, ` : '') +
    (l.next ? `nextStep: ${q(l.next)}, ` : '') +
    (l.youtubeId ? `youtubeId: ${q(l.youtubeId)}, ` : '') +
    (l.guide ? `guide: ${guideDart(l.guide)}, ` : '') +
    `sourceUrl: ${q(l.source)}, sourceLabel: 'Open the complete guide')`;
};
const pathDart = c => `  LearningPath(id: ${q(c.id)}, number: ${q(c.number)}, title: ${q(c.title)}, subtitle: ${q(c.subtitle)}, category: ${q(c.category)}, categoryId: ${q(c.categoryId)}, description: ${q(c.description)}, icon: ${q(c.icon)}, published: true, studyTime: ${q(c.studyTime)}, topics: ${c.topics},` +
  (c.trailerYoutubeId ? ` trailerYoutubeId: ${q(c.trailerYoutubeId)},` : '') + '\n' +
  `    materials: [\n${c.materials.map(r => '      ' + materialDart(r)).join(',\n')}\n    ],\n` +
  `    lessons: [\n${c.lessons.map(l => '      ' + lessonDart(l)).join(',\n')}\n    ])`;
const output = `// Generated from the published Secure By Design training catalog.
// Run: node tool/import_site_training.mjs /path/to/site
// The app downloads newer versions of this catalog from
// https://securebydesigninc.com/app-content/v1/ (lib/data/content_feed.dart).
import 'models.dart';

/// The schema and version (the first 16 hex digits of the catalog's SHA-256)
/// of the website catalog this build ships.
const bundledCatalogSchema = ${APP_CONTENT_SCHEMA};
const bundledCatalogVersion = ${q(manifest.version)};

const bundledCategories = <TrainingCategory>[
${categories.map(categoryDart).join(',\n')}
];

/// Catalog tiles labeled "Coming soon": shown, never opened, until they have lessons.
const bundledComingSoon = <ComingSoonCourse>[
${comingSoon.map(soonDart).join(',\n')}
];

const bundledPaths = <LearningPath>[
${courses.map(pathDart).join(',\n')}
];

/// The Community & Careers Hub's state pages, \`/community/<slug>\` on the website.
const bundledCommunityStates = <CommunityState>[
${states.map(st => `  CommunityState(${q(st.code)}, ${q(st.name)}, ${q(st.slug)})`).join(',\n')}
];
`;
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

const lessonCount = courses.reduce((n, c) => n + c.lessons.length, 0);
const localOnly = materials.filter(r => !r.syncable).map(r => r.id);
console.log(`Imported catalog ${manifest.version}: ${courses.length} courses, ${comingSoon.length} coming soon, ${lessonCount} lessons, ` +
  `${courses.reduce((n, c) => n + c.lessons.reduce((m, l) => m + l.quizzes.length, 0), 0)} knowledge checks, ${materials.length} materials, ` +
  `${scenarios.length} traffic processes, ${whatIfs.length} what-ifs, ${policy.length} policy rules, and ${nodes.length} systems.`);
if (localOnly.length) console.log(`Materials not in the Site bookmark catalog (saved on this device only): ${localOnly.join(', ')}`);
