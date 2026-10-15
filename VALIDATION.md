# Validation — Secure By Design 0.3.0

Validated with Flutter 3.47.6 / Dart 3.13.5 on October 5, 2026.

- Flutter analysis: no issues.
- Flutter tests: 49 passing.
- Personalized onboarding: every goal/level maps to real lessons; a new learner completes a recommended lesson and the Home checklist reflects the result; skipping and reopening persist correctly.
- Upgrade safety: existing progress, last path, prompt preferences, haptic preferences, and analytics defaults survive.
- Onboarding at 390 pixels and at 320 pixels with 2× text, including the creator note and a complete lesson.
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


## Streak v1, onboarding analytics choice — 0.9.0 (October 8, 2026)

- Streaks: new learners start with two freezes (was one). A streak of 3+ days that breaks by one or two unprotected missed days can be earned back, free, by finishing two lessons or reviews on the two days after the first miss. Home shows a supportive restore card while the window is open; it never highlights the loss.
- Celebrations: full milestone celebrations only at 7, 30, 100 and 365 days, with a heavier haptic and a spring-in that is skipped under Reduce Motion. Ordinary days keep the small celebration, plus a "one more day to your milestone" hint and a note when a freeze is earned.
- Quests & rewards: a month calendar shows practiced, frozen and earned-back days.
- Onboarding: the plan step now asks, with neither answer preselected, whether to share anonymous usage. Nothing is sent unless the learner says yes. Onboarding answers never leave the device.
- Analytics (only with consent): onboarding_completed (skipped, started_lesson), daily_goal_set (goal_xp), streak_extended, streak_milestone, earn_back_offered, earn_back_completed (streak count). The My Account disclosure lists the new events.
- Tests added for earn-back windows and expiry, milestone and restore rewards, bounded event properties, the Home restore card at 390 px and 320 px with 2× text, and reduced-motion milestones. Two existing expectations changed with the new rules: the starting freeze count, and a streak now surviving two missed days.
- Flutter was not available in the authoring environment; `flutter analyze`, `flutter test` and the Android bundle build run in the Native app checks workflow on the pull request. Device checks: complete a lesson on day 7 to see the milestone, turn on Reduce Motion and repeat, and skip two days without freezes to see the restore card.
