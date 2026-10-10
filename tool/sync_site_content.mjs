// Refreshes the app's bundled offline content (assets/training/content.json) from the website's
// content feed. Installed apps download the same feed on launch and resume; this copy is what a
// new install shows before its first download, and what the tests check.
//
//   node tool/sync_site_content.mjs                   download https://securebydesigninc.com/app/content/v1.json
//   node tool/sync_site_content.mjs <url>             download another feed URL
//   node tool/sync_site_content.mjs /path/to/site     build it from a website checkout
//   node tool/sync_site_content.mjs feed.json         copy a saved feed
//
// Prints `changed=<true|false>` and `version=<content version>` (also written to $GITHUB_OUTPUT
// when set). The website builds the feed with scripts/prepare-app-content.mjs; see its
// docs/native-app-content.md. Keep lesson and material IDs stable on content edits.
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';

const SCHEMA = 1;
const DEFAULT_FEED = 'https://securebydesigninc.com/app/content/v1.json';
const root = path.resolve(import.meta.dirname, '..');
const target = path.join(root, 'assets/training/content.json');
const source = process.argv[2] ?? DEFAULT_FEED;

async function readFeed() {
  if (/^https?:\/\//.test(source)) {
    const response = await fetch(source, {headers: {accept: 'application/json'}, cache: 'no-store'});
    if (!response.ok) throw new Error(`${source} answered ${response.status}`);
    return response.text();
  }
  const resolved = path.resolve(source);
  if (fs.statSync(resolved).isDirectory()) {
    return execFileSync(process.execPath, [path.join(resolved, 'scripts/prepare-app-content.mjs'), '--stdout'],
      {cwd: resolved, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024});
  }
  return fs.readFileSync(resolved, 'utf8');
}

const fail = message => { throw new Error(`Content feed: ${message}`); };
const text = await readFeed();
const feed = JSON.parse(text);
if (feed.schema !== SCHEMA) fail(`schema ${feed.schema}; this app reads schema ${SCHEMA}`);
if (!/^[0-9a-f]{16}$/.test(feed.version ?? '')) fail('missing content version');
if (!Array.isArray(feed.courses) || !feed.courses.length) fail('no courses');
const lessonIds = feed.courses.flatMap(c => (c.lessons ?? []).map(l => l.id));
if (new Set(lessonIds).size !== lessonIds.length) fail('repeated lesson IDs');
if (feed.courses.some(c => !c.lessons?.length || c.lessons.some(l => !l.quizzes?.length))) fail('a course or lesson is incomplete');
if (!Array.isArray(feed.network?.nodes)) fail('no Inside the Network reference');

// Lessons this build shipped with should stay in the feed; moved lessons need a mapping in
// LearningStore._movedLessons (and the website's server migration) so progress follows them.
const previous = fs.existsSync(target) ? JSON.parse(fs.readFileSync(target, 'utf8')) : null;
const before = new Set((previous?.courses ?? []).flatMap(c => c.lessons.map(l => l.id)));
const dropped = [...before].filter(id => !lessonIds.includes(id));

const normalized = JSON.stringify(feed) + '\n';
const changed = previous?.version !== feed.version || fs.readFileSync(target, 'utf8') !== normalized;
if (changed) fs.writeFileSync(target, normalized);

const lessons = feed.courses.reduce((n, c) => n + c.lessons.length, 0);
console.log(`${changed ? 'Updated' : 'Unchanged:'} bundled content ${feed.version}: ${feed.courses.length} courses, ${lessons} lessons.`);
if (dropped.length) console.log(`::warning title=Lessons removed::${dropped.join(', ')} — saved progress for these stays on devices but is no longer shown. Add a mapping in LearningStore._movedLessons if they moved.`);
console.log(`changed=${changed}`);
console.log(`version=${feed.version}`);
if (process.env.GITHUB_OUTPUT) {
  fs.appendFileSync(process.env.GITHUB_OUTPUT, `changed=${changed}\nversion=${feed.version}\ndropped=${dropped.join(' ')}\n`);
}
