# Project Memory

Purpose: keep the current project context in the repo so a new agent window can continue without a separate handoff file.

## How To Update

- Add only high-signal context: decisions, current branch, release status, active blockers, and next actions.
- Keep newest entries at the top.
- Prefer short factual bullets over long conversation transcripts.
- When context changes, update the relevant entry instead of duplicating stale information.

## Current Snapshot

Date: 2026-06-21

- App: 今日も元気 / Kyogen, Flutter iOS-first safety check-in app.
- Firebase project: `projects-696e9`.
- Bundle ID: `jp.kyogen.kyogen`.
- GitHub repo: `chenyl25123-blip/kyogen-app`.
- Active branch: `codex/email-validator-hotfix`.
- Remote branch pushed: `origin/codex/email-validator-hotfix`.
- Latest pushed commit on this branch: `e669d441d9006de861d6cba0da6f65d0d6fba076`.
- App Store review previously rejected because iPhone login was missing.
- User added/confirmed iPhone login requirement; branch now includes phone login support and emergency contact email validation fix.
- User wants future Claude/Codex development to continue on a branch and complete tests before reporting done.
- User prefers Chinese communication; key error messages can remain in English for searchability.

## Recent Work

### 2026-06-21

- Fixed emergency contact email validation. The previous regex rejected common addresses like `user@gmail.com`.
- Added shared email validator in `lib/utils/email_validator.dart`.
- Added Japanese mobile phone normalization and validation in `lib/utils/phone_number.dart`.
- Added phone number linking flow through Firebase Auth.
- Added `phoneLinked` field to `AppUser`.
- Updated Cloud Functions user creation logic to record `phoneLinked`.
- Updated privacy text to mention phone number collection for SMS authentication.
- Updated tests:
  - `test/email_validator_test.dart`
  - `test/phone_number_test.dart`
  - `test/widget_test.dart`
- Verification passed:
  - `flutter analyze`
  - `flutter test`
  - `cd functions && npm run build`
  - `git diff --check`

## Next Actions

- Open PR from `codex/email-validator-hotfix`:
  `https://github.com/chenyl25123-blip/kyogen-app/pull/new/codex/email-validator-hotfix`
- Review the App Store upload image before final release; user asked to be reminded to replace it.
- After merge, build and submit the updated iOS version for review.

