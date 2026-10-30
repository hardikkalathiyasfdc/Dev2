# BIM — Plan: Stop auto-populating Requested Amount on Bgive grant push

Ticket: **TBD** ("BIM - BIM AutoPopulated Requested Amount" — rename this file/folder when the Jira/BRME id is assigned).

## Summary

When a grant is pushed from BIM to Bgive, **Requested Amount** (`amount_requested_local` on Bgive `grant_request`) is auto-populated with the same value as **Recommended Amount** and is then **never updated** on later pushes. This is driven entirely by Custom Metadata configuration — no Apex change is required for the primary fix. Requested Amount is meant to be **partner-entered** in the Bgive portal, so BIM should stop populating/updating it. If Bgive requires a value at `grant_request` creation (Stu testing), fall back to sending **$0.00** on initial create only — still metadata-only.

## Key Findings (from workspace)

- **The behavior is CMDT config, not code logic per-field.** The sync engine [BGiveApiSync.cls](force-app/main/default/classes/BGiveApiSync.cls) `fillDataMap()` gates every mapped field with `isInsert || (isAlwaysSync && performUpdate)`:
  - [Bgive_Sync_Field_Mapping.GrantRequestedBudgetAmountLocal.md-meta.xml](force-app/main/default/customMetadata/Bgive_Sync_Field_Mapping.GrantRequestedBudgetAmountLocal.md-meta.xml): `IM_Grant__c.Budget_Amount_Local__c` → `amount_requested_local`, `Sync_Mode__c = 'BRM To Bgive Initial'` → **sent on create only**.
  - [Bgive_Sync_Field_Mapping.GrantBudgetAmountLocal.md-meta.xml](force-app/main/default/customMetadata/Bgive_Sync_Field_Mapping.GrantBudgetAmountLocal.md-meta.xml): `IM_Grant__c.Total_Amount_Local__c` → `amount_recommended_local`, `Sync_Mode__c = 'BRM To Bgive Always'` → sent on create **and** every update (`alwaysSyncFieldsMap` drives both the mismatch check and re-send).
  - At first push, `Budget_Amount_Local__c` (roll-up of active [IM_Budget_Grant__c.Budget_Amount_Local__c](force-app/main/default/objects/IM_Grant__c/fields/Budget_Amount_Local__c.field-meta.xml)) equals the recommended/total amount — hence "Requested = Recommended". On later amount changes + re-push, `performUpdate` is computed from Always-mode fields only, so `amount_requested_local` is excluded → **stale value in Bgive. This is exactly the reported bug.**
- **Update path confirmed.** [BGiveApiSync.cls](force-app/main/default/classes/BGiveApiSync.cls): `getBgiveRecord()` queries Bgive by `brm_id`; existing record → update runs only when an Always-mode field mismatches (`checkForFieldMismatch()` sets `performUpdate`); `getBgiveRecord()` also only queries back Always-mode columns. Initial-mode fields are invisible to the update path.
- **Entry point is manual/UI-only.** [imGrantView.js](force-app/main/default/lwc/imGrantView/imGrantView.js) "Push to Bgive" → [IMGrantViewController.pushToBGive](force-app/main/default/classes/IMGrantViewController.cls#L390) → `IMGrantService.sync(...)` → `BGiveApiSync.sync(...)`. No trigger, flow, batch, or scheduled job pushes grants — so a CMDT change covers **all** push paths.
- **BRM never reads Requested Amount back.** No `Bgive to BRM` mapping for `amount_requested_local` exists; inbound refresh (`syncFromBgive`/`syncIMGrant`, [IMGrantService.cls](force-app/main/default/classes/IMGrantService.cls#L437-L438)) only mirrors `amount_recommended_local` onto `Bgive_Amount_Local__c`. Partner edits in Bgive are untouched by anything in this org — safe to stop sending.
- **No partner-facing component in this repo** displays Requested Amount; it lives only in the Bgive portal. Internal displays ([IM_Grant_Record_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Grant_Record_Page.flexipage-meta.xml#L202), [imBgiveGrantDetails](force-app/main/default/lwc/imBgiveGrantDetails/imBgiveGrantDetails.html#L99)) show the SF-side budget/Bgive amounts and are unaffected.
- **`None` field-type + `Default_Value__c` give a metadata-only constant.** `getValue()` in [BGiveApiSync.cls](force-app/main/default/classes/BGiveApiSync.cls) returns `Default_Value__c` when `BRM_Field_Type__c = 'None'`, and the CMDT validation rule `BRM_Field_Required_Except_for_Type_None` allows a blank `BRM_Field__c` in that case. This enables the $0.00 fallback without code.
- **Test touchpoints:** [BGiveApiSyncTest.cls](force-app/main/default/classes/BGiveApiSyncTest.cls#L51) `testSyncForGrant` (mock `Data_JSON__c` includes `Budget_Amount_Local__c`; no assertion on `amount_requested_local` today); [IMGrantServiceTest.cls](force-app/main/default/classes/IMGrantServiceTest.cls#L271) mocks `amount_requested_local` inbound (harmless, but review).

## Changes

### Option A (primary): stop sending Requested Amount entirely — metadata-only

1. **Delete the CMDT record** `Bgive_Sync_Field_Mapping.GrantRequestedBudgetAmountLocal` via destructive changes:
   - Add to the deploy `destructiveChanges.xml`: type `CustomMetadata`, member `Bgive_Sync_Field_Mapping.GrantRequestedBudgetAmountLocal`.
   - Result: `amount_requested_local` is no longer in `bgiveSyncFieldMapping`, so `fillDataMap()` never puts it in a create or update payload. Create payload keeps all other fields unchanged.
2. **No Apex changes.**
3. **Lock the behavior with a test** — extend `testSyncForGrant` in [BGiveApiSyncTest.cls](force-app/main/default/classes/BGiveApiSyncTest.cls): assert the create payload does **not** contain `amount_requested_local` (and still contains `amount_recommended_local`). Note: the test mocks CMDT or relies on org CMDT — verify how the mapping list is loaded in the test (`IMUtil.getBGiveSyncFieldMapList` reads real CMDT unless mocked), and mirror the metadata change in test setup if needed.

### Option B (fallback, only if Stu's testing shows Bgive requires the field on create): send $0.00 on initial create — metadata-only

Edit [Bgive_Sync_Field_Mapping.GrantRequestedBudgetAmountLocal.md-meta.xml](force-app/main/default/customMetadata/Bgive_Sync_Field_Mapping.GrantRequestedBudgetAmountLocal.md-meta.xml) instead of deleting it:

| CMDT field | From | To |
|---|---|---|
| `BRM_Field_Type__c` | `Field` | `None` |
| `BRM_Field__c` | `Budget_Amount_Local__c` | *(nil)* |
| `Default_Value__c` | *(nil)* | `0` |
| `Mapping_Type__c` | `Value` | `Value` (unchanged) |
| `Sync_Mode__c` | `BRM To Bgive Initial` | `BRM To Bgive Initial` (unchanged) |

Result: on create, `getValue('None', null, '0')` returns `0` → `amount_requested_local = 0`; update path still never sends it. **Watch-out:** `Default_Value__c` is LongTextArea, so the payload value serializes as the **string** `"0"` — verify Bgive accepts a string numeric for `amount_requested_local` during sandbox testing; if it rejects it, add a small numeric-coercion for `None`-type defaults in `getValue()` (only code change then).

### Data remediation (existing grants — needs business decision)

Grants already pushed have a stale `amount_requested_local` in Bgive (equal to the initial budget amount, never updated). Options:
1. **Leave as-is** — partners overwrite when they fill it; stale values remain visible until then.
2. **One-time Bgive-side cleanup** — script against the Bgive API to blank/zero `amount_requested_local` on existing `grant_request` records. **Risk:** Bgive may not distinguish BIM-stamped values from partner-entered ones — a blanket wipe could erase real partner input. Decide with Grants team/Stu; if done, scope it (e.g. only requests not yet submitted by the partner).

### Tests

| Test | Assert |
|---|---|
| `BGiveApiSyncTest.testSyncForGrant` (extend) | create payload excludes `amount_requested_local` (Option A) / includes `0` (Option B); `amount_recommended_local` still present on create and update |
| `BGiveApiSyncTest` grant update scenario (extend/add) | update payload never contains `amount_requested_local`; partner-side value not touched |
| Regression: `IMGrantServiceTest`, `IMGrantViewControllerTest` | existing sync/link/unlink flows green |

## Decisions / open questions

1. **Option A vs Option B is gated on Stu's Bgive testing** — whether `grant_request` create succeeds without `amount_requested_local`. Default to A (cleanest, matches "remove this field completely from being populated or updated by BIM").
2. **Existing-data cleanup** (blanket vs scoped vs none) — open question for Grants team/Stu; Bgive can't necessarily tell BIM-stamped from partner-entered values.
3. **No Bgive→BRM read-back of Requested Amount** is added — partners own the field; nothing in BRM consumes it today.
4. **Ticket id TBD** — plan lives in `plans/`; rename to `plans/<TICKET>-...md` (and prefix commit/deploy messages) once assigned.

## Verification

1. Dry-run deploy to dev2Current first (`sf project deploy start --dry-run`, destructiveChanges for Option A), verify via org `DeployRequest` (Tooling API) — CLI exit code / "locale en_US" error are not authoritative (repo lessons #4/#10). Review the diff for unintended overwrites before any real deploy.
2. Run `BGiveApiSyncTest`, `IMGrantServiceTest`, `IMGrantViewControllerTest` (deploy with `--test-level RunSpecifiedTests` for the real deploy).
3. E2E on dev2Current:
   - Create a grant in BIM → Push to Bgive → in Bgive verify **Requested Amount is blank/$0.00** and Recommended Amount matches the grant total.
   - Increase and decrease the grant amount in BIM → re-push → verify Recommended Amount updates and **Requested Amount is unchanged** (still blank/$0.00, or partner-entered value intact).
4. Confirm the push still succeeds end-to-end (no Bgive validation error for a missing requested amount — this is Stu's test item).

## Out of scope / notes

- **Pre-existing static-state risk in [BGiveApiSync.cls](force-app/main/default/classes/BGiveApiSync.cls):** `isInsert` / `performUpdate` are `static` and never reset at the start of `sync()` — a second sync in the same transaction can inherit stale flags (repo lesson #3, static-state confusion). **Reviewed and explicitly descoped** (user decision 2026-10-30): no caller syncs twice in one transaction today, so this stays as-is. A `resetStaticState()` fix was briefly added and reverted; if bulk/migration scripts ever loop sync calls, revisit it then.
- No changes to the Recommended Amount mapping, the inbound `Bgive_Amount_Local__c` mirror, or any LWC/layout.
- Rollback: re-deploy the deleted CMDT record (Option A) or restore the original mapping values (Option B) — keep a copy of the current record file in git history; no data migration needed to roll back.

## Implementation Log (deployed to dev2Current 2026-10-30 — Deploy ID `0Afbc00000DLKYxCAP`, Succeeded, 4/4 tests, 0 errors)

**Option B implemented** (user-confirmed 2026-10-30, ahead of Stu's test — $0.00 is safe even if Bgive requires the field on create).

| Component | Files | Notes |
|---|---|---|
| CMDT mapping | [Bgive_Sync_Field_Mapping.GrantRequestedBudgetAmountLocal.md-meta.xml](force-app/main/default/customMetadata/Bgive_Sync_Field_Mapping.GrantRequestedBudgetAmountLocal.md-meta.xml) | `BRM_Field_Type__c` Field→`None`, `BRM_Field__c`→null, `Default_Value__c`→`0`; `Sync_Mode__c` stays `BRM To Bgive Initial` → `amount_requested_local` sent as `0` on create only, never on update. Verified in org post-deploy. |
| Sync engine | [BGiveApiSync.cls](force-app/main/default/classes/BGiveApiSync.cls) | **REVERTED (2026-10-30, user decision)** — the `resetStaticState()` hardening was removed; user judged the consecutive-syncs-in-one-transaction scenario out of scope since it doesn't occur in current flows. Class is now untouched for this ticket. |
| Tests | [BGiveApiSyncTest.cls](force-app/main/default/classes/BGiveApiSyncTest.cls) | Grant mock now routes GET/POST/PUT and captures the request body; new `testRequestedAmountSentAsZeroOnCreate` (asserts `"amount_requested_local":"0"` in the create `data` param) and `testRequestedAmountNotSentOnUpdate` (asserts absent from update `data` param, `amount_recommended_local` still sent). |
| Scripts | [bim-requested-amount-setup.apex](scripts/bim-requested-amount-setup.apex), [bim-requested-amount-e2e.apex](scripts/bim-requested-amount-e2e.apex), [bim-requested-amount-e2e-read.apex](scripts/bim-requested-amount-e2e-read.apex), [bim-requested-amount-e2e-b-change.apex](scripts/bim-requested-amount-e2e-b-change.apex), [bim-requested-amount-e2e-c-update.apex](scripts/bim-requested-amount-e2e-c-update.apex) | E2E data setup + sync/readback steps for grant `a0obc000003FE49AAG`. |

### Gotchas hit during deploy/E2E

1. **CLI 2.62.6 has no `--description` flag** for `sf project deploy start` → the deploy-description convention can't be satisfied at this CLI version; the detail lives in the git commit body instead.
2. **Statics are not allowed on inner classes** → the mock's capture state lives on the top-level test class (`grantReturnEmptyList` / `grantLastRequestBody` / `grantLastRequestMethod`).
3. **Update-payload assertions must inspect only the `data` form param** — the `cols` param legitimately lists `amount_requested_local` (columns to return); first deploy attempt failed the assertion on `cols`, not on the payload.
4. **PRE-EXISTING: `IMGrantViewControllerTest` + `IMGrantServiceTest` fail 46/46 in dev2Current on unmodified code** (verified with a standalone test run before this deploy): `@TestSetup` → `TestDataFactory.createBudget` → IMBudgetTrigger AfterInsert → IMInitiativeTrigger AfterUpdate → `IMBudgetHelper.updateActiveStatus` → `AuraHandledException` (the known BRME-7040-chain issue, skill §9). **Not caused by this change.** Deploys in dev2Current must scope `--tests` to unaffected suites (this deploy used `BGiveApiSyncTest` only) until that is fixed.
5. **Anonymous-apex E2E: `IMGrantService.sync` ends with DML** (`updateGrantRecord`) → any Bgive readback callout in the same script fails with "uncommitted work pending". Sync and readback must run as separate scripts/transactions.
6. **Live Bgive E2E BLOCKED in dev2Current**: Named Credential `Fluxx_OAuth_Sandbox`'s external credential isn't fully configured ("try reconnecting to the external system") — no Fluxx callouts succeed from this sandbox until an admin re-auths it in Setup. Grant data is prepped (below); after reconnect, run in order: `bim-requested-amount-e2e.apex` → `-e2e-read.apex` → `-e2e-b-change.apex` → `-e2e-c-update.apex` → `-e2e-read.apex`.

### Unit-test evidence (from deploy `0Afbc00000DLKYxCAP`)

- Create payload `data` param contains `"amount_requested_local":"0"`.
- Update payload `data` param contains no `amount_requested_local`; `amount_recommended_local` still present.
