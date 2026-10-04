# Archived email sequence — disabled

On October 3, 2026 (America/Denver), the owner chose in-app welcome messages, learning tips, and feedback prompts instead of lifecycle email. Do not activate this Resend sequence or request a mailing address for it. No marketing emails or test emails have been sent by this workflow.

## Current app behavior

- `lib/data/getting_started.dart` tracks the first use of this app version, dismissals, and the prompts preference in device-local storage. No account identity is stored with guidance.
- Home shows one dismissible card at a time: welcome immediately, resources after three elapsed days, and feedback after seven elapsed days. An overdue card waits until Home is opened; there are no scheduled emails, background jobs, or push notifications.
- Dismissals and the original start time survive app restarts and sign-ins. Reinstalling or clearing app data can reset them; they are not synchronized across devices.
- About this preview contains a Getting-started prompts switch. Turning it back on does not erase dismissals or restart the clock.
- Guest/offline learning remains available. UserJot opens externally only when the reader taps Share an idea. Existing optional PostHog settings are independent.
- The native account screen uses verified website accounts but exposes no email enrollment control. Sign-in makes no `/api/native-onboarding` requests. App-related email is reserved for account verification and password reset through the existing website account service.

## Preserved backend and provider draft

The native authentication backend is deployed in website version 98 (source commit cb59832f12749ec040f15d8cae521dab91f4899a). The dedicated `RESEND_AUTOMATIONS_API_KEY` was securely saved and deployed at environment revision 2. It is unused by the new in-app flow. The existing transactional `RESEND_API_KEY` remains unchanged. `APP_ONBOARDING_EMAIL_ENABLED` is unset/off, verified October 4 UTC.

Resend automation `01a104be-8361-72cd-b0b9-6b2cc7e78565` remains disabled. The three published templates and this directory's generated definition are archived preparation, not release requirements. The owner has not approved disclosing a physical mailing address. Retain the draft without activating it.

## Verification and release

Tests cover the 0/3/7-day boundaries, persisted dismissal and preferences, clock rollback, account sign-in without marketing requests, and narrow layouts with enlarged text. Run `flutter analyze` and `flutter test`, then the Codemagic iOS cloud check on the new source commit. Prior successful builds do not validate these latest changes. TestFlight remains 0.1.0 (7) until a new signed release completes.
