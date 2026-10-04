# App getting-started email sequence

Status: optional native sign-in and consent UI are implemented in this branch. The shared account backend was deployed as website version 97 on October 4, 2026 (commit 3161302f355ff1f6ac281bbb8aeeb7abd1009891). Email sending remains disabled; no recipients have been enrolled and no messages sent. Resend dashboard access is awaiting sign-in, provider configuration, and a live delivery/unsubscribe check. This branch is not yet released in TestFlight.

## Behavior

- After a verified account signs in, offer the separate, unchecked consent in `sequence.mjs`. Account creation, app use, and optional PostHog analytics must work without subscribing.
- A confirmed opt-in starts one sequence: welcome immediately, a resources tip after 3 days, feedback request after 7 days. The second delay is 4 days.
- Each email has a Resend-hosted unsubscribe link. Every send step checks the contact's current `unsubscribed` value; an unsubscribed or unknown value takes a terminal branch. Do not reset provider subscription preferences when a reader signs in again.
- The primary key prevents a repeated login, reinstall, or another device from restarting the sequence. Only the server-authenticated account can determine the recipient. No existing newsletter audience is imported.
- Resend owns the delayed execution, so the app can be closed. PostHog is not an identity source and receives no emails or enrollment records.
- Ambiguous network responses are retained as `review_required` (or `dispatching` after a process crash). Reconcile the provider event/run logs before any manual retry. The event endpoint has no documented idempotency guarantee, so automatically retrying could duplicate the entire sequence. An accepted event means queued, not inbox delivery.

## Integration with the existing account backend

The website's `server/reader-auth.js` already verifies email and password and exposes `getReader(request, env)`. It stores a cookie session, not a native bearer token. Preserve its Origin checks and HttpOnly cookie handling. Do not let a native caller simply supply an account ID or an email as authentication.

1. Completed: account backend migration 0006 adds the enrollment table and a constant-default session client kind. Existing account IDs, progress, sessions, and browser Origin checks are preserved.
2. Completed: `/api/native-auth/signin`, `/session`, and `/signout` use distinct native bearer sessions. The app uses the existing verified email/password accounts. A 256-bit token is hashed at rest on the server, expires after 12 hours, and is held only in app memory. Website password reset revokes all sessions. Native and browser credentials are not interchangeable, and both clients share the same brute-force limits.
3. Completed: `/api/native-onboarding` authenticates the native bearer token and stores explicit versioned consent before dispatch. `APP_ONBOARDING_EMAIL_ENABLED` remains unset/off. The app displays availability honestly and never sends an event merely because someone signs in.
4. Completed: the optional account screen is accessible from the app information sheet. Account creation and password recovery use the existing website. Guest/offline learning remains available. Progress synchronization is still future work and is not claimed by the account screen. The consent control is unchecked, separate from PostHog, and submits only consent plus its version.
5. Import/publish the three templates and create the disabled automation generated below. Use the verified notification sender already configured for the website and `support@securebydesigninc.com` for replies. Add the approved business mailing address to each footer before production activation. Do not copy a private billing address from chat receipts.
6. Verify Resend entitlement, template aliases, event definition `sbd.app.onboarding.v1`, live contact condition behavior, unsubscribe behavior, hard-bounce/complaint suppression, and sender status in the actual account. No new paid subscription is approved. The contact email is automatically created by Resend when an event starts a run; existing subscription preferences must be preserved.
7. Activate only after a recipient-authorized end-to-end test: opt in once; sign in again; verify one run; unsubscribe before the next send; confirm the remaining sends are skipped. Use an isolated shorter-delay test automation, not edits to a running production sequence. Server ownership, token isolation, sign-out, expiry, reset revocation, shared rate limits, and native email enrollment are covered by 22 focused server tests plus a real Workers runtime test. Flutter analysis passes; all existing app tests and the new account logic tests pass, and the two new screen tests pass after small-screen verification. Complete a device-to-production sign-in check before release.

For a later in-app opt-out UI, update the provider subscription first and verify it; do not merely flip a device-local setting while the provider still holds an active run. Provider unsubscribe is global to its marketing contact; explain that scope in the email preference UI.

## Local verification and review

Requires Node 22.13+ (tested on Node 24). No npm packages or API key needed:

```sh
node --test backend/onboarding/onboarding.test.mjs
node backend/onboarding/export.mjs
```

`generated/` contains the three HTML emails and a disabled automation request. These can be reviewed without sending mail. Templates use the native app's navy/cyan palette and a soft header gradient with solid-color fallback.

## Provider references (checked October 4, 2026)

- https://resend.com/docs/api-reference/events/send-event
- https://resend.com/docs/dashboard/automations/trigger
- https://resend.com/docs/dashboard/automations/condition
- https://resend.com/docs/dashboard/automations/send-email
- https://resend.com/docs/api-reference/automations/create-automation

Do not report this as released until provider activation, a native cloud build, and end-to-end device/email verification are complete. The existing TestFlight build remains unchanged. Three legacy website suites depend on an obsolete dist/server/index.js import and could not run under the current Vinext build layout; their code was not modified. The focused account suites, Workers runtime integration, and full website production build passed.
