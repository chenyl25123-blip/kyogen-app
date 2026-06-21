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
- Active test branch: `codex/email-validator-hotfix`.
- Remote branch pushed: `origin/codex/email-validator-hotfix`.
- Latest pushed commit on this branch: `399105c`.
- Branch policy: treat `codex/email-validator-hotfix` as the test branch. Do not merge to the production branch until tests pass and the user explicitly approves the merge.
- App Store review previously rejected because iPhone login was missing.
- User added/confirmed iPhone login requirement; branch now includes phone login support and emergency contact email validation fix.
- User wants future Claude/Codex development to continue on a branch and complete tests before reporting done.
- User prefers Chinese communication; key error messages can remain in English for searchability.

## Recent Work

### 2026-06-21

- Defined `codex/email-validator-hotfix` as the current test branch.
- Merge rule: test branch changes require passing verification and explicit user approval before merging to the production branch.

### 2026-06-21

- Changed notification policy:
  - JST 09:00 sends push after one missed day.
  - JST 21:00 sends emergency email on the same missed-day cycle as the morning push.
- Fixed the stale alert edge case where a user could receive an emergency email without the matching morning push after `lastNotifiedAt` was reset by a later check-in.
- Added shared Cloud Functions policy helpers in `functions/src/checkin_policy.ts`.
- Added Functions policy test:
  - `functions/test/checkin_policy_test.js`
- Verification passed:
  - `cd functions && npm test`
  - `flutter test`
  - `flutter analyze`
  - `git diff --check`

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
- Keep the PR/test branch unmerged until user approval after testing.
- Review the App Store upload image before final release; user asked to be reminded to replace it.
- After merge, build and submit the updated iOS version for review.
