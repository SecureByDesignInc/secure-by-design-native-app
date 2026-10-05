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
- Both published course panels: 320-pixel phone at 1× and 2× text size, including materials bookmarks.
- Full lesson flow: incorrect/correct quiz gating, completion, restart persistence, and visible course progress.
- Native sharing: fixed homepage payload, cancellation, and positive iPad presentation anchor.
- Offline network reference: traffic-flow navigation and root CA details without a live network path.
- Sync: isolated account caches, no automatic guest import, explicit import preserving guest records, offline queue persistence across restart, bookmark removal, and rejection of stale or wrong-account responses.
- Existing account, onboarding, privacy-default analytics, and feedback checks continue passing.

Website support uses additive migration 0007 and the existing reader account system. Its 32 targeted backend tests pass, including cross-client course/bookmark sync, account isolation, expired sessions, browser/native credential separation, malformed batches, tombstones, and archived Journal preservation. Website type checking and production build pass.

These shared-code and widget checks do not replace native platform compilation. The Codemagic pull-request workflow compiles unsigned iOS; merging main runs the signed TestFlight workflow. Check its result for this exact commit before treating the release as delivered. Physical iPhone/iPad testing is still needed for the system share sheet, WebGL interaction in the 3D web view, account sign-in, and real network interruption. Android and desktop platform builds have not been executed in this Linux validation environment.

No public App Store release, Google Play listing, new lab entitlement, or video recording is included.
