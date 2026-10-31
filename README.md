# Secure By Design — native app proof of concept

Version 0.8.0 · October 7, 2026

A shared Flutter application for iOS/iPadOS, Android, Windows, macOS, and Linux. Native apps come first. The web app is deferred.

## What works

- Seven tabs in the website's navigation order with its navy/cyan design: Home, System Hub, Training Hub, ATO Package Builder Hub, Community & Careers Hub, Cyber Range, and My Account. Phones show short labels (Home · Systems · Training · ATO · Community · Range · Account) that stay on one line at any text size; screen readers and the wide-screen sidebar use the full hub names.
- Cyber Range (owner direction, 26 October 2026; the battle, 30 October 2026): the website's Range, opened in a WebView the way the System Hub's 3D view is, so the site and the app share one build. One battle against the computer: seven multiple-choice rounds from the lab question bank, open to everyone. In the app it plays as a guest with a random operator and callsign kept on the device; its sign-in link opens the website in the browser, where a Community account keeps them.
- The website's Training Hub catalog: Build the Network 1.1–1.12 and Network Authorization 2.1 (11 courses, 107 lessons), in the website's two categories, with 1.9 (SBD-EPO01) and 1.10 (SBD-NESSUS01) shown in course order as "Coming soon" tiles that don't open.
- Training updates without a new build: the app checks `securebydesigninc.com/app-content/v1/manifest.json` in the background, downloads a changed catalog, verifies its SHA-256 and that every course parses, and uses it from the next launch. Offline or on any error it keeps the catalog it shipped with (see Course content updates).
- Lab mode on every Build the Network lesson: the phone as a second screen. One step at a time, the inspection commands with a copy button per command, then the lesson's checklist and observations from the website's course guide. For a signed-in learner, checks and notes sync with the website guide's own records, so ticking a check in the app ticks it on the website. The screen stays on while lab mode is open.
- Practice comes round on a widening schedule (1, 3, 7, 21, then 60 days after each session); the most overdue lesson comes first.
- Overview, Lessons, and Materials views; lessons play their YouTube walkthrough (privacy-enhanced embed) once the website lists one, and are honestly labeled Video coming soon until then.
- System Hub: Inside the Network — seven offline traffic processes, five what-ifs, the system references, and the policy register; the complete website 3D explorer opens in-app on iOS, Android, and macOS.
- ATO Package Builder Hub: the seven RMF steps, each with its course 2.1 lessons (opened in the app), its templates, and the package builder (opened on the website, where it saves to the learner's account).
- Community & Careers Hub: the Discord, LinkedIn, Book a call, all 51 state pages, what every state page holds, and what's coming soon to the hub.
- Live Threat Map: a Home card opens Radware's map on Radware's own site (owner decision, 20 October 2026: link out; the app no longer embeds the map or covers parts of it).
- Resources & references and saved materials in My Account; native homepage sharing: Learn it. Share it. Pay it forward.
- Optional website-account sign-in and shared progress/bookmarks. Choose Connect progress; Add my device-only progress is a separate, confirmed import. In-app account deletion.
- Account-specific offline caches, durable pending changes, retry on resume, and untouched guest history on sign-out.
- A skippable first-run welcome: goals, starting level, recommendations from the website's courses, and an optional note from Secure By Design. The Home checklist follows actual lesson and bookmark progress. The three app-only sample courses were retired on 20 October 2026; tests keep them as a fixture (`test/support/sample_paths.dart`).
- Device-only onboarding choices, getting-started prompts, optional anonymous analytics, and existing feedback flow.
- Optional haptic feedback on supported iOS and Android devices. Use the info button → Haptic feedback to turn it off.
- An app privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`): no tracking; optional analytics; email, progress and lab notes only for a signed-in learner. Keep it in step with the App Store privacy label.

Course text and the network reference work offline. 3D, downloads, external resources, and account synchronization require a connection. Account sessions stay in memory and expire within 12 hours. Lab access remains request-based. This release does not add public store listings or recordings.

## Onboarding design

The original welcome adapted the outcome-first presentation, useful personalization, founder note, and continuing checklist described in [Mobbin’s onboarding video](https://www.youtube.com/watch?v=Qsq-Sj_rojU), with [Tiimo’s flow](https://mobbin.com/explore/flows/817f5bfd-1701-4756-bcbc-dcdfc3597723) as a reference. Goals and starting level select existing lessons, with their real durations. Recommendations never claim a guaranteed result or completion date. The note is original Secure By Design copy. Sharing is voluntary; lesson access and optional sign-in keep their existing behavior.

The new profile is stored under `sbd.onboarding.v1`, separate from account progress and analytics. Existing install markers prevent an intrusive first-run replay after upgrading. Finishing or skipping suppresses the old welcome card while retaining the existing learning-tip schedule. Disabling getting-started prompts hides the Home checklist.

## Start here

For an iPhone, use **CODEMAGIC_SETUP.md** to build through a hosted Mac from a Windows laptop, or **IPHONE_SETUP.md** to build on a physical Mac. The project archive is source code rather than an installable IPA or App Store release.

Install Flutter **3.47.6 stable** (the version used to validate this project), or a compatible later stable release. The bundled dependency lockfile preserves the tested package versions.

From this project folder:

```bash
flutter pub get
flutter doctor
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with a real identifier from `flutter devices`.

## Native targets

| Target | Development machine | Next check |
| --- | --- | --- |
| iOS / iPadOS | macOS with Xcode | Simulator, Personal Team signing, real iPhone/iPad |
| Android | macOS, Windows, or Linux with Android tooling | Emulator, then real device |
| macOS | macOS with Xcode | `flutter run -d macos` |
| Windows | Windows with Visual Studio's Desktop development with C++ tools | `flutter run -d windows` |
| Linux | Linux with Flutter's documented native build dependencies | `flutter run -d linux` |

The generated iOS project uses iOS 15 as its minimum deployment target; the macOS project uses macOS 12. The desktop and mobile runner projects are included. Each native build still needs validation on its corresponding toolchain/device. No web runner or web deployment is included.

## Validation

See **VALIDATION.md** for the checked behavior and the remaining platform checks. To repeat the shared-code checks:

```bash
flutter analyze
flutter test
```

The preview images in `previews/` are rendered by Flutter's test engine at phone dimensions. They show actual app widgets; they are not captures from an iOS Simulator or physical phone.

## Design reference

Read from [securebydesigninc.com](https://securebydesigninc.com) on October 3, 2026:

| Token | Value |
| --- | --- |
| Background | `#050B14` |
| Card surface | `#102237` |
| Main text | `#F3F7FF` |
| Secondary text | `#AEBDD0` |
| Cyan accent | `#83DCFA` |
| Blue accent | `#378EFA` |
| Border | `#2B3D53` |
| Typeface | Geist |

The logo mark is the existing website asset's displayed viewport. It is reused for the header and launcher icons. Geist is distributed under the included SIL Open Font License in `assets/fonts/OFL.txt`.

## Project map

| File or folder | Purpose |
| --- | --- |
| `lib/main.dart` / `lib/bootstrap.dart` | Startup, local-state loading, retry state |
| `lib/app.dart` | Application shell and adaptive navigation |
| `lib/theme.dart` | Shared design tokens and component styles |
| `lib/data/catalog.dart` | Sample lessons, questions, and reference links |
| `lib/data/learning_store.dart` | Serialized local progress and bookmark writes |
| `lib/screens/` | Home, learning paths, lessons, resources, and progress |
| `lib/widgets/` | Shared interface components |
| `test/` | Learning flow, persistence, and layout validation |
| `tool/generate_brand_icons.py` | Reproduce the native launcher assets with Python/Pillow |
| `codemagic.yaml` | Hosted macOS validation and signed TestFlight workflows |
| `CODEMAGIC_SETUP.md` | Windows-to-Codemagic setup and signing walkthrough |

## Course content updates

The website is the one source of the training catalog. Its build (`scripts/prepare-content.mjs` → `scripts/prepare-app-content.mjs`) publishes `public/app-content/v1/catalog.json` and `manifest.json`; the app downloads them, so a website deploy reaches the app without an App Store or Google Play release. The catalog carries content only (text, quizzes, links, video IDs), never code.

To ship the current catalog inside a build, import it from a Site checkout:

```bash
node tool/import_site_training.mjs /path/to/site
flutter analyze
flutter test
```

The importer runs the Site's own `appContent()` code, so the bundled catalog and the downloaded one are built the same way and share a version (the first 16 hex digits of the catalog's SHA-256). It stops if a lesson ID is missing from the Site's `content/training-progress.json`, because account sync would reject it. Materials the Site's bookmark catalog does not list are generated with `syncable: false`. Preserve existing lesson and material IDs on content edits. A change to the catalog's shape needs a new schema number on both sides; this release reads schema 1 and ignores any other.

## Release workflow

Codemagic checks pull requests targeting main and builds the signed TestFlight IPA when main changes, provided the existing repository webhook is enabled. The Apple integration and bundle identifier remain unchanged. No public App Store review or external tester invitation is configured. The Native app checks GitHub Actions workflow also runs analysis and widget tests on pull requests, with rendered preview artifacts. Platform compilation and physical-device checks are separate from the Flutter widget tests.

## Official setup references

- [Flutter installation](https://docs.flutter.dev/install/manual)
- [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup)
- [Apple Developer account and Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup)
- [Flutter desktop setup](https://docs.flutter.dev/platform-integration/desktop)

Original sample explanations link to [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview), [NIST](https://csrc.nist.gov/projects/risk-management/about-rmf), and [Splunk](https://help.splunk.com/en/splunk-enterprise/get-started/overview/9.1/about-splunk-enterprise/about-splunk-enterprise) within the app.

## Daily learning (0.4.0)

Home and My Account include a local-calendar streak, seven-day calendar, daily XP goal (10/20/40), XP levels, three daily quests, a 30-quest monthly challenge, six achievements, and lesson/review celebrations. Haptics retain the existing default-on preference. Completed lessons can be reviewed through Practice; the correct answer is required before rewards are saved.

- New lessons earn 20 XP; reviews earn 10; correct first attempts add 5. Each lesson earns rewards once per calendar day. Each completed daily quest adds 10 XP once. There are no timers, purchases, or penalties that lock lessons.
- One lesson or review maintains a streak independently of the daily goal. One automatic freeze is earned on the first active day; another every seven active days, capped at two. Freezes preserve a run but add neither streak days nor XP. Historical best streak remains after a reset.
- Immutable local date/lesson keys make rewards idempotent across retries and device imports. Existing undated completions do not become fictional streak history. Dates keep their original local-calendar meaning across time-zone changes. The daily goal is device-local and account-scoped.
- `/api/native-activity` syncs account activity with bounded uploads and paginated history. Guest data only joins an account through the existing explicit import. Delayed responses are discarded after account changes, and failed writes remain pending. Activity is private; there are no fabricated competitors, public leaderboards, or friend invitations. Website reading completions do not retroactively earn app activity rewards.
- Deploy the additive Site migration 0008 and native-activity endpoint before distributing this app. The previous app remains compatible with its unchanged native-progress endpoint.

## No membership tiers: a free Community account for everyone (16 October 2026)

At the owner's request, everything related to membership tiers is gone from the app, as it is from the website. Every Secure By Design account is a free Community account. My Account ends with a "Free Community account" panel and the note from Secure By Design (`lib/widgets/community_account.dart`), using the same words as the website's My Account. Home no longer shows a membership card after the first lesson, the lesson celebration has no membership link, and the account card has no "View membership options" button. `lib/screens/membership_screen.dart`, `lib/data/membership.dart` and `assets/membership-plans.json` are deleted, and `test/community_account_test.dart` checks that they stay gone. The website's sign-in responses still carry `membership: {plan: 'community', status: 'active'}`; the app doesn't need that field. This supersedes the three membership sections below.

## Memberships: "Coming soon" only (13 October 2026)

At the owner's request no membership specifics are shown: no plan names, prices, features or billing. My Account's membership options show one "Coming soon" statement, a short line, a link back to Training, and the note from Secure By Design; the account card no longer shows a Community badge, and the invitations read "Memberships are coming soon." `assets/membership-plans.json` is again an identical copy of the website's `content/membership-plans.json` (now `creatorNote`, `comingSoon`, `comingSoonDetail`). This supersedes the two membership sections below.

## Membership plans (0.4.1)

Memberships are available from Info, My Account, and after learning. The first lesson celebration offers an optional link; Continue remains the primary action. Community keeps all current lessons, rewards, downloads, and optional progress sync. Builder ($20/month or $180/year) and Guided ($99/month) are coming-soon previews. Detail selection and the billing-period toggle are local display state only: no checkout, subscription, paid entitlement, or marketing signup exists. The bundled `assets/membership-plans.json` matches the website’s `content/membership-plans.json`; update both together. Haptics keep the saved default-on preference.

## My Account consolidation (0.5.0)

My Account combines account access, learning progress, rewards, and the full membership comparison. Home and first-lesson membership invitations open this tab at the membership section. Continue with Community returns to Training; comparing plans never creates a subscription or changes learning records. Builder and Guided remain coming soon.


## App design refresh (0.7.0)

The native app adapts the reviewed Mobbin references: Brilliant's goal and level
choices, Uxcel Go's grouped cards, MasterClass's expandable curriculum, and the
Speak / Gentler Streak account patterns. No website files, imported course
content, progress IDs, backend endpoints, membership pricing, or entitlements
change in this release.

- Onboarding is three steps: goals, starting level, and a real recommended lesson.
  It stays skippable, retains existing profiles, and keeps the creator note optional.
- Training uses app-only Network Foundations, Certificates & Trust, and Network
  Authorization categories. Tiles expand to reveal course outcomes, durations,
  and directly accessible lessons. Completion and materials stay visible;
  unavailable recordings remain labeled Video coming soon.
- My Account is a compact hub for Community access, genuine learning statistics,
  continuation, saved materials, rewards, learning preferences, account security,
  privacy, feedback, and membership comparison. Detailed controls open from this
  hub. Device-progress import still requires its existing explicit confirmation.
- Existing navy/cyan colors, Geist typeface, offline learning, and platform
  accessibility preferences are preserved. No mandatory signup or new tracking.

References:
- https://mobbin.com/flows/20ad012b-2683-4c0c-beb8-8ff62c6f509e
- https://mobbin.com/screens/dba87d9e-9955-49be-be73-686477e601ee
- https://mobbin.com/screens/72dcf33e-58e8-486f-a178-583a2d411f67
- https://mobbin.com/screens/b1802d44-e332-4130-bbf4-f195931c7bd1
- https://mobbin.com/screens/83aeb4be-08be-4066-8f85-510daf0ecf8a

## Course catalog update (0.8.0)

The bundled content now matches the website's Training Library and Inside the
Network as of October 7, 2026. Membership, onboarding, account sync endpoints,
and existing lesson, course, and material IDs are unchanged.

- **15 courses in site order.** Build the Network 1.1–1.12 adds Harden the
  baseline, Connect and segment the network, Finish the PKI services,
  Addressing and tiered administration, the logging pipeline, Bring in the
  fleet, Patch, protect, and watch for weakness, Stand up the business
  services, and Prove you can recover.
  PKI courses 1.4 and 1.6 sit in Certificates & Trust; the rest of 1.x in
  Network Foundations. Cards and course pages show the course number.
- **Network Authorization in three parts.** 2.1 Risk Management Framework
  (modules 01–04), 2.2 Body of Evidence (05–09), and 2.3 Authorization to
  Operate (10–12 and the capstone) mirror the website's tiles. Lesson IDs stay
  `training:rmf-boe-ato:<module>`, and the first part keeps the
  `rmf-boe-ato` course ID, so saved progress and onboarding recommendations
  carry over. The interactive course and Word catalog appear in each part.
- **Lessons.** Configuration lessons open with “In this lesson you will”
  objectives and end with a recap and the next step. Every knowledge check from
  the website is included (three or four per configuration lesson). All must be
  answered correctly to complete the lesson. Rewards are unchanged: one lesson
  completion earns 20 XP (10 for a review), and the 5 XP first-try bonus
  requires every check in that lesson to be right on the first attempt.
- **Materials.** Configuration courses list the interactive guide, workbook PDF
  and Word files, the printable checklist, and the Markdown checklist.
  Materials the website's bookmark catalog does not list yet (the new
  workbooks and checklists) can be saved on this device but are not sent to
  account sync, which would otherwise reject the update. They sync once the
  website adds them and the catalog is re-imported.
- **Inside the Network.** Adds the seventh process, “Use a web app”, the five
  what-ifs (DC01 is down, certificate expired, a PC tries SQL, PC-to-PC remote
  desktop, and the attack drill), each step's policy decision, and the policy
  register rules for the selected system. Counts in the screen copy are derived
  from the bundled data.
- **Importer.** `tool/import_site_training.mjs` reads the current course
  format (`quizzes`, `objectives`, `recap`, `next`, workbooks, checklist page,
  RMF parts) and no longer writes Site files unless `--write-site` is passed.

## Training library restructure (October 8, 2026)

The bundled catalog was re-imported from the website after the owner
restructured the Build the Network path. It now runs 1.1–1.10.

- **Course 1.5 removed.** “Connect and segment the network” is gone; later
  courses assume the network's routing and segmentation already exist. Its time
  lesson moved into course 1.2, now “Configure DNS and time”.
- **One PKI course.** Former 1.6 “Finish the PKI services” merged into 1.4,
  now “Configure the two-tier PKI” (10 lessons), the only course in
  Certificates & Trust.
- **Renumbered.** Tiered administration is 1.5, logging 1.6, fleet 1.7,
  patching 1.8, business services 1.9, recovery 1.10. Course IDs are unchanged.
- **Saved progress.** `LearningStore` carries device progress for the moved
  lessons (`training:connect-segment:time` and `training:pki-services:*`) to
  their new IDs; the website migrates account progress the same way.
- The import also brought `assets/training/network.json` up to the website's
  current Inside the Network reference.
- **SBD-TIME01 removed.** Learners use the domain controller as the NTP
  source: course 1.2's time lesson is now “Make SBD-DC01 the domain's time
  source”, and the network reference no longer lists TIME01 or rule F08.


## Tier 2 admin seat as a virtual machine (October 13, 2026)

The bundled catalog and `assets/training/network.json` were re-imported from the website after the owner asked for fewer admin machines.

- **Course 1.5 (materials edition 1.5).** The three admin seats now run on two machines. SBD-ADMIN-PC01, the Tier 2 seat, is a virtual machine on SBD-ADMIN-SRV01; AdminJumpBox01 runs no virtual machines. This is the arrangement the DISA Windows PAW STIG allows where workstations are scarce.
- **New content.** The design lesson assigns each tier its seat under the STIG. The admin-hosts, logon-restrictions and prove lessons cover each seat's Group Policy and maintenance group, the virtual machine's host and guest settings, and who may sign in on each seat. All four lessons gain steps and knowledge checks. Lesson IDs are unchanged, so saved progress carries over. The course is about 3.2 hours.
- **Network reference.** SBD-ADMIN-PC01 keeps its own address (10.0.60.30) and rule A03. Its description, SBD-ADMIN-SRV01's, the VLAN 60 boundary and the attack drill's step 6 describe the virtual machine.

## One course per system (October 14, 2026)

The website split its consolidated Build the Network courses into one course per system, so the path now runs 1.1–1.19 (website PR #48). The app imports it with `node tool/import_site_training.mjs <site checkout>`: 17 build courses plus the three Network Authorization parts, 105 lessons. Website tiles 1.16 (SBD-EPO01) and 1.17 (SBD-NESSUS01) are "Coming soon" with no material, so the app leaves them out until they have lessons. Lessons that moved keep their lesson id; `LearningStore._movedLessons` carries device progress to their new course (the website's `content/progress-moves.json` lists the same moves), and progress for the withdrawn endpoint-protection and scanning lessons drops out. Categories in `lib/data/training_categories.dart` list the new courses.

## Revamp: website parity, content feed and lab mode (20 October 2026)

- Navigation, categories, coming-soon tiles and hubs now follow the website (see What works). The Explore tab is gone: Inside the Network is the System Hub, community links moved to the Community & Careers Hub, references to My Account, and the Live Threat Map to Home.
- `lib/data/content_feed.dart`, `catalog_json.dart`: the downloaded catalog. `lib/data/catalog.dart` holds the catalog in use (`useCatalog`), set once at startup in `lib/bootstrap.dart`.
- `lib/screens/lab_mode_screen.dart`, `lib/data/guide_state.dart`: lab mode and its checks and notes (`/api/native-progress/guide/<id>` on the website). `lib/data/keep_awake.dart` with handlers in `ios/Runner/AppDelegate.swift` and `MainActivity.kt` keeps the screen on.
- `lib/app_tabs.dart`, `lib/screens/hub_screens.dart`, `lib/data/ato_builder.dart` (mirrors the website's `package-builder-hub.tsx`).
