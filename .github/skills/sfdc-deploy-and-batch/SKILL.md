---
name: sfdc-deploy-and-batch
description: 'Hard-won lessons for Salesforce Apex batch/callout work and sf CLI deploys in this repo. USE FOR: writing/editing Apex batch or queueable classes, callout integration (zkipster/BBApps_Crud), diagnosing silent failures, deploying with the sf CLI, fixing Apex test coverage. Avoids repeat mistakes: SObjectException from unqueried fields, swallowed partial DML failures, static-state confusion, cosmetic CLI deploy errors.'
---

# Salesforce Deploy & Batch/Callout Lessons

Lessons from the zkipster sync work. Read before editing batch/queueable Apex, `ZkipsterIntegration`, `BBApps_Crud` callouts, or running `sf` deploys/tests.

## 1. Never trust the field list — verify what the query actually returns

- **Accessing a field/relationship not in the SOQL query throws `System.SObjectException` at runtime** ("SObject row was retrieved via SOQL without querying the requested field"). This is the #1 cause of silent batch failure here.
- Before reading `record.Relationship__c.Field__c` or any field in a batch/queueable, **confirm that exact field is in the query string** that feeds the batch (e.g. `EventMangementAuraCtrl.syncZkipsterGuests`). Don't assume a field added to a similar query is present.
- `parent.Relationship__c` (e.g. `CampaignMember.Campaign`) throws if the relationship sub-field wasn't selected. Prefer keying off an Id already on the record (`campId`, `CampaignId`) and querying the parent separately.
- **This bit us repeatedly in the zkipster sync**: `execute()` read `guest.Campaign.ZkipsterGuestListId__c` (not in the query) and `ZkipsterIntegration.syncZkipsterGuestsCreation/Update` did too. Both threw `SObjectException` → batch "Completed" with 0 records synced and no error email. Fix: the batch queries the guest-list id once from `campId` and passes it into `syncZkipsterGuestsCreation(guest, guestListId)` / `syncZkipsterGuestsUpdate(guest, guestListId)` overloads; keep the single-arg versions as delegating wrappers for other callers. When a batch *completes* but nothing synced and no error row exists, suspect an unqueried field first.
- **A non-existent field in the query string is worse**: the prod `syncZkipsterGuests` query referenced `Contact.LP_London_Dear_Line__c`, which does NOT exist (correct field: `Contact.CorrespondenceDearLine__c`). `Database.getQueryLocator()` throws `QueryException` in `start()` → 0 members processed, no error surfaced. Validate any field you add to a dynamic SOQL string against the object's describe (`sf sobject describe`), and grep the whole repo for a field before removing/renaming it.
- **Never store an external-system id in an `Id`-typed variable.** `Id guestListId = camp.ZkipsterGuestListId__c;` threw `System.StringException: Invalid id: 1041579` because zkipster ids aren't Salesforce ids. This killed every `execute()` before any callout. External ids must be `String`. When a batch "completes" with 0 callouts and no error row, check for type-cast exceptions (`StringException: Invalid id`).
- **To capture a batch exception when logs are filtered**: write it to a queryable field (e.g. `update new Campaign(Id=campId, Description=('ERR: '+ex.getMessage()).left(250))`) in the catch, run the batch, then query it. Faster than fighting ApexLog debug levels. Remove the diagnostic after.
- **Isolate per-record failures inside a batch loop.** One bad record (e.g. null `PartySize__c` → NPE in `.intValue()`) thrown mid-loop aborts the whole scope, so only records processed *before* it get saved. Wrap each record's callout/DML in its own try/catch: failed record → `failedRecordIds` + `isFailed=true`, loop continues. Verified: 7 synced, 1 failed individually. Null-check any Decimal before `.intValue()` if it should default instead of fail.
- **Error observability gap**: `BBApps_ErrorHandler.logErrors` only publishes a platform event (EventBus) — it does NOT `insert MB_Error__c`. If no subscriber persists the event, errors vanish silently. Don't rely on `MB_Error__c` existing to confirm a failure; capture the exception message directly (assertion message / ApexLog `EXCEPTION_THROWN`).

## 2. `BBApps_Crud` returns `List<BBApps_DMLResult>`, NOT `Database.SaveResult[]`

- `doUpdateWithHandling` / `doInsertWithHandling` / `doUpsertWithHandling` return `List<BBApps_DMLResult>`. Assigning to `List<Database.SaveResult>` fails to compile.
- `BBApps_DMLResult` exposes `.isSuccess()` and `.getId()` — iterate and check `isSuccess()` on each.
- **With `allOrNothing=false`, failures are swallowed**: the wrapper logs them (via `BBApps_ErrorHandler`) and returns normally — no throw. You MUST inspect the returned results to detect partial failure, otherwise the code reports success. This caused the "sync succeeded but nothing synced" bug.
- A `catch (Exception)` alone is NOT sufficient failure detection — partial DML and callout `'error'` returns don't throw.

## 3. Static lists don't survive across batch scope executions reliably

- `Database.Stateful` preserves *instance* fields, but a `public static List` on another class (e.g. `ZkipsterIntegration.errors`) is **not** a reliable cross-execution accumulator — and if nothing ever populates it, checks against it are dead code. Verify a static "errors" list is actually written before relying on `errors.size() > 0`.
- Track failure state on the batch's own instance fields (`isFailed`, `failedRecordIds`).

## 4. sf CLI deploys: the "locale en_US" error is cosmetic

- `sf project deploy start` may exit non-zero with `Metadata API request failed: Missing message metadata.transfer:Finalizing for locale en_US` even when the deploy **succeeds** server-side. Do NOT trust the CLI exit code/output.
- **Always verify via the org**: query `DeployRequest` (Tooling API) for `Status`, `NumberComponentErrors`, `NumberTestErrors` before concluding success/failure.

## 5. Deploy gating: a failing test rolls back the whole deploy

- With `--test-level RunSpecifiedTests`/`RunLocalTests`, one failing test (or coverage below 75% on any selected class) **fails and rolls back ALL components**, leaving the org on the old code. Subsequent test-only deploys then fail with "Method does not exist" because the new prod method never landed.
- To commit production classes when a test is still red, deploy with `--test-level NoTestRun` first, then fix tests. Confirm with `DeployRequest`, not CLI output.

## 6. Apex test mocks: match on the real endpoint + HTTP method

- `HttpCalloutMock.respond` receives the full endpoint URL. Route with `contains()` on distinct path segments AND check `req.getMethod()` — e.g. `/guest-lists/{id}/guests` (GET, list) vs `/guests` (POST, create) vs `/guests/{id}` (PATCH, update). Overlapping `contains('/guests')` matches several; order branches carefully.
- A mock returning the wrong status code makes `zkipsterCallout` return the literal string `'error'`, which the caller treats as failure (not an exception).

## 7. Debugging a silent test/batch failure — don't guess, capture

- Reading logs via `Select-String` on `System.debug` often returns nothing (log levels filter it). Fastest reliable signal: put the diagnostic into the **assertion message** (e.g. `failedIds=`, record state, last `MB_Error__c.Description__c`) so it surfaces in the test failure text.
- For batches, check the `ApexTestHandler` ApexLog and search for `EXCEPTION_THROWN` to get the real stack, instead of re-running blind.

## 8. Org data diagnosis for duplicates

- "Duplicate guest in zkipster" = BRM `CampaignMember.ZkipsterGuestId__c` was null, so every sync takes the create branch. Query the member's `ZkipsterGuestId__c` + `Synced_With_Zkipster__c` first to confirm linkage before assuming a code bug.

## 9. Custom field metadata authoring (BRME-7039)

- **`formulaTreatBlanksAs`: use `BlankAsBlank` for Text formulas, `BlankAsZero` only for Number formulas.** `BlankAsZero` is the metadata default, so it's easy to leave in by accident on a Text formula — it's semantically wrong there and can cause surprising number coercion. Check the field's `<type>` and set it deliberately.
- **TextArea fields have a fixed 255 limit — do NOT include `<length>`** ("Can not specify 'length' for a CustomField of type TextArea"). Only `LongTextArea` takes `<length>` (repo convention: 32768 for notes fields).
- **Validation rule `fullName` max is 40 chars.** Long descriptive names (e.g. `Strategic_Locations_Aligned_Notes_Required`) fail deploy; shorten to fit.
- **New custom fields are invisible to SOQL ("No such column") until FLS is granted**, even for the deploying admin in some permset configurations. Don't conclude the deploy failed — assign the permission set first, then query. `sf org assign permset` takes ONE `--name` per invocation; a comma-separated list reports "not found".
- **Anonymous Apex data loads that touch `IM_Initiative__c.Current_Budget__c` fail** with `System.LimitException: Can only throw this exception type...` — `IMBudgetHelper.updateActiveStatus` wraps errors in `AuraHandledException`. Workaround: `TriggerFactory.setBypass('IMBudgetedInitiativeHandler')` in the script.
- **`Current_Budget__c` lookup filter**: budget must be Status = Pending Approval/Approved and belong to the same initiative, else `FIELD_FILTER_VALIDATION_EXCEPTION`.

## 10. Every metadata change: dry-run validate against the org first

- **For EVERY metadata change you make, run at least a `--dry-run` deploy against the target org before touching anything further** — even if you never intend to actually deploy. This is the fastest way to catch structural problems (duplicate facet declarations, bad references, invalid property values) that static inspection misses. Command: `sf project deploy start --metadata "<Type>:<Name>" -o <org> --dry-run`. Then verify the real result via the org's `DeployRequest` (Tooling API) `Status`/`NumberComponentErrors` — don't trust CLI output alone (see §4).
- **Review the diff for anything that would overwrite an existing org change before deploying.** If a diff/retrieve shows your change clobbering something already in the org that you didn't intend to replace, STOP and ask the user before deploying. Do not silently push an overwrite.
- **Ask questions whenever in doubt** — if a dry-run result is ambiguous, the diff looks like it might overwrite org state, or it's unclear whether to actually deploy vs. validate-only, ask the user instead of guessing.
- The sandbox blocks the sf CLI (`EPERM lstat 'C:\'`); run deploy/retrieve/validate commands with unsandboxed execution.

## 11. Sync every retrieve to git (dated package.xml, auto-push on dev2)

The GitHub repo is the source of truth — not just for changes we author, but for the org's state. **Every** retrieve (manual or automated) must be committed and pushed so GitHub always mirrors the org.

- **Dated package manifest per retrieve**: keep the `package.xml` used for each retrieve under the ticket folder as `package-<YYYY-MM-DD>.xml` (e.g. `BRME-7020/retrieves/package-2026-10-29.xml`) so we can see what was pulled, when, and why. Don't overwrite a single `package.xml` across retrieves.
- **Retrieve into source, not only `other-org/`**: `other-org/retrieve-*` is scratch/verification. When the retrieved metadata belongs in the project (a component we own), also place it under `force-app/main/default/...` so it's tracked as real source.
- **Commit + push on dev2/dev2Current without asking** — remote `https://github.com/hardikkalathiyasfdc/Dev2`, branch `main`. Message subject: `BRME-XXXX: retrieve <components>` (or `chore: org sync retrieve <date>` if no ticket); body: what was retrieved and the org it came from.
- **Other orgs (e.g. Dev1)**: do NOT push here — ask the user for that org's repo URL first (see `.github/copilot-instructions.md`).
- **git executable**: not on terminal PATH — use `& "C:\Program Files\Git\cmd\git.exe" ...`.
- Review the retrieved diff before committing; if it would overwrite something unexpected, STOP and ask.

## 12. Every deployment message lists modified components (one per line)

- **Whenever you report a deployment** (in chat, in a commit body, in a PR, or in a `--description`/DeployRequest note), list the modified components **one below another** — not as an inline comma list.
- Use workspace-relative paths, one per line, e.g.:
  - `force-app/main/default/aura/DITCmp/DITCmp.cmp`
  - `force-app/main/default/aura/DITCmp/DITCmpHelper.js`
- Applies to both the user-facing summary and the git commit body so anyone can see exactly what changed at a glance.

## 13. Flosum is the real deploy path — leave a handoff brief + test record IDs

The user promotes changes **from Flosum, environment to environment** — the `sf project deploy start` we run against a sandbox is only for validation/verification, not the production path. After our change lands in the target sandbox, the user does further processing in Flosum (commit/promote). So every task that ends with "live in the target sandbox" must close out with a **handoff brief** they can paste into / reference from Flosum:

- **What was deployed**: ticket + one-line intent, then the modified components **one per line** (per §12), with the org alias it landed in (e.g. `dev2Current`).
- **Verification result**: deploy/validate status (DeployRequest Id), tests run + pass/fail counts, and any dry-run-only caveats.
- **Test records used for validation**: the exact record IDs + names (e.g. Grant `a0obc000003FE49AAG` / IMGRANT-288227) and what was done to each (pushed to Bgive, amount changed 100k→120k, etc.), so the user can re-check the same records after promoting.
- **Anything not deployable by metadata / manual steps**: CMDT record changes that must travel with the deployment, permission-set assignments done manually, data setup scripts run, and known org-specific deltas the user should NOT overwrite when promoting.
- Keep it short — a compact block at the end of the final summary message, not a separate file (unless the user asks for a doc under the ticket folder).
