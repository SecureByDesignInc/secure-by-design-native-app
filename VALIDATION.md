# Validation — Secure By Design 0.3.0

Validated with Flutter 3.47.6 / Dart 3.13.5 on October 5, 2026.

- Flutter analysis: no issues.
- Flutter tests: 49 passing.
- Upgrade safety: existing progress, last path, haptic preferences, and analytics defaults survive. (The onboarding, getting-started and rewards checks were retired with those features on 1 November 2026.)
- Home (1 November 2026): the hero and the Cyber Range taster; where no web view can run (the test engine), the round's fallback card. The Training Hub: the group links, search and results, a tile opening its course beneath its row, the coming-soon tiles in course order in the Build the Network group, the Tools and the seven RMF steps.
- Haptics: user actions, opt-out persistence, duplicate suppression, silent background/desktop behavior, and unavailable platform channels.
- Actual Flutter screen previews: Home, Training, Explore, and My Progress at 390×844 logical pixels.
- Adaptive navigation: 320, 390, 768, and 1280 logical pixels at 1× and 2× text size.
- All published course panels (15 since 0.8.0): 320-pixel phone at 1× and 2× text size, including materials bookmarks.
- Full lesson flow: incorrect/correct quiz gating, completion, restart persistence, and visible course progress.
- Native sharing: fixed homepage payload, cancellation, and positive iPad presentation anchor.
- Offline network reference: traffic-flow navigation and root CA details without a live network path.
- Sync: isolated account caches, no automatic guest import, explicit import preserving guest records, offline queue persistence across restart, bookmark removal, and rejection of stale or wrong-account responses.
- Existing account, onboarding, privacy-default analytics, and feedback checks continue passing.

Website support uses additive migration 0007 and the existing reader account system. Its 32 targeted backend tests pass, including cross-client course/bookmark sync, account isolation, expired sessions, browser/native credential separation, malformed batches, tombstones, and archived Journal preservation. Website type checking and production build pass.

These shared-code and widget checks do not replace native platform compilation. The Codemagic pull-request workflow compiles unsigned iOS; merging main runs the signed TestFlight workflow. Check its result for this exact commit before treating the release as delivered. Physical iPhone/iPad testing is still needed for the system share sheet, WebGL interaction in the 3D web view, account sign-in, and real network interruption. Android and desktop platform builds have not been executed in this Linux validation environment.

No public App Store release, Google Play listing, new lab entitlement, or video recording is included.

## Course catalog update — 0.8.0 (October 7, 2026)

- Importer run against a copy of the Site checkout: 15 courses, 82 lessons, 213 knowledge checks, 64 materials, 7 traffic processes, 5 what-ifs, 26 policy rules, and 23 systems. The Site's progress and resource catalogs were read, not written.
- Every lesson ID exists in the Site's `content/training-progress.json`; all 28 previous lesson IDs and 12 previous material IDs (with their URLs) are unchanged.
- New widget and unit tests cover site order and numbering, the three authorization parts over one set of module IDs, configuration materials and lesson structure, multi-check lesson completion with unchanged XP, device-only bookmarks staying out of account sync, and the offline what-ifs and policy register.
- Flutter was not available in the authoring environment; `flutter analyze` and `flutter test` run in the Native app checks workflow on the pull request. Device checks for this release: open several new courses and a multi-check lesson on an iPhone, save a new workbook while signed in, and confirm sync still reports no error.

