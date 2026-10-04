# App getting-started email sequence

Status: optional native sign-in and consent UI are implemented in this branch. The shared account backend was deployed as website version 98 on October 4, 2026 (commit cb59832f12749ec040f15d8cae521dab91f4899a). All three templates are published in Resend and the disabled automation draft is saved. The iOS cloud check passed for implementation commit 9e22cc2de16860edfbaa9db25870bab867235d08, including analysis, all 29 Flutter tests, and unsigned iOS compilation. Email sending remains disabled; no recipients have been enrolled and no messages sent. This branch is not yet released in TestFlight.

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
5. Completed: publish the three templates and save the disabled automation draft. Sender is `Jon at Secure By Design <support@notify.securebydesigninc.com>` on the verified notification domain; replies go to `support@securebydesigninc.com`. Add the approved business mailing address to each footer before production activation. Do not copy a private billing address from chat receipts.
6. Pending: create a separate, user-approved Resend full-access key for contact/events/automation operations, stored only as the secret backend environment variable `RESEND_AUTOMATIONS_API_KEY`. The existing sending-only `RESEND_API_KEY` remains dedicated to website transactional messages. Native enrollment requires both the new secret and `APP_ONBOARDING_EMAIL_ENABLED=true`; neither is configured yet. Reconcile the provider draft with `generated/automation.json` before activation: the UI currently displays condition values as the string `"false"`, so confirm/correct the API type to boolean `false`, and replace each empty false-branch placeholder with the generated explicit terminal delay. Verify template aliases, event definition `sbd.app.onboarding.v1`, live contact conditions, unsubscribe behavior, hard-bounce/complaint suppression, and account entitlement. No new paid subscription is approved. Resend automatically creates the contact when an event starts a run; existing subscription preferences must be preserved.
7. Activate only after a recipient-authorized end-to-end test: opt in once; sign in again; verify one run; unsubscribe before the next send; confirm the remaining sends are skipped. Use an isolated shorter-delay test automation, not edits to a running production sequence. Server ownership, token isolation, sign-out, expiry, reset revocation, shared rate limits, and native email enrollment are covered by 22 focused server tests plus a real Workers runtime test. Flutter analysis passes; all existing app tests and the new account logic tests pass, and the two new screen tests pass after small-screen verification. Complete a device-to-production sign-in check before release.

For a later in-app opt-out UI, update the provider subscription first and verify it; do not merely flip a device-local setting while the provider still holds an active run. Provider unsubscribe is global to its marketing contact; explain that scope in the email preference UI.

## Saved provider configuration

Automation: `01a104be-8361-72cd-b0b9-6b2cc7e78565`, **Secure By Design — App getting started**. The draft uses the custom event `sbd.app.onboarding.v1`, the welcome message, a 3-day delay, the learning tip, a 4-day delay, and the feedback message. It is not active; the condition/terminal-branch checks above are still required.

| Published template | Provider ID |
| --- | --- |
| `sbd-app-welcome-v1` | `8976e05e-9be0-4355-b4d4-a668cf8f1bb0` |
| `sbd-app-learning-tip-v1` | `7cc8b4db-1136-486f-9a93-533298a94796` |
| `sbd-app-feedback-v1` | `8e161ab7-50a7-48a4-b7ba-5fa5374cfe59` |

The published previews retain the navy/cyan design and hosted unsubscribe links. No live delivery, unsubscribe, or device-to-production test has been completed. Codemagic `ios-cloud-check` build `6ac1b9fc7394575b200add3c` passed; TestFlight remains at build 0.1.0 (7).

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
