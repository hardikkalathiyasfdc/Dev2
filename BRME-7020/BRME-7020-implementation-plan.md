# BRME-7020 — Implementation Plan

**Ticket:** Program Highlights — Ability to Submit Private Highlights for the Highlights Review Team.

**Status:** Phase 1 investigation complete. **Implemented and deployed to dev2Current (2026-10-29).** End-to-end verification passed.

---

## 1. Requirement and acceptance criteria

The Highlights Review sub-team creates **private highlights** for leadership communications (Board Highlights, year-end memos to MRB).

1. Checkbox **Private** (`Private__c`, default false) on `Highlight_Interaction__c`, on the Details interface for creation/editing.
2. Only the **Highlights & Metrics: Reviewer** permission set gets read/edit FLS on the field.
3. Private records are readable/editable by members of a new **Highlights: Private Highlights Review** public group.
4. Ordinary internal/program users must not see private records via record pages, related lists, reports, dashboards, exports, global search, or custom interfaces.
5. Private highlights may optionally be submitted for MRB — no MRB requirement introduced.
6. Private highlights can never reach CityView (UI, API, automation, batch).
7. No automatic interaction-record creation for private highlights (reviewers add interactions manually).
8. Non-private behavior preserved.

**Field permission (perm set) and record access (public group) are distinct assignments** — neither alone grants the other.

## 2. Org and inspected components

| Item | Value |
|---|---|
| Org alias | `dev2Current` (sandbox `bbrm--dev2`) |
| Example record | `a0Xbc000003mcCXEAY` (inspect only if org connection available) |
| Object | `Highlight_Interaction__c` (label "Highlight"), API 67.0 |

Inspected: object + all 16 fields + 1 validation rule + compact layout + list view; `Highlight_Interaction__c-Highlight Layout`; `Highlight_Request_Record_Page` flexipage; `HighlightInteractionTriggerHandler`, `HighlightSubmitController`, `HighlightMetricsController`, `InteractionTriggerHandler`, `CityViewDetailPageController`, `ExportOrganizationHighlightsController`, `FileGroupController`, `FieldHistoryController` (+ tests); LWCs `highlightSubmitForReview`, `highlightCompleteReview`, `highlightMetrics`, `cityViewHighlights`, `exportOrganizationHighlights`, `fileGroup`, `customFieldHistoryTable`; quick actions `Submit_for_Review` / `Complete_Review`; all 4 permission sets touching the object; all 28 permission set groups; groups/sharingRules/profiles folders (none exist); 21 flows (none touch the object).

## 3. Verified current-state facts (repo, 2026-10-29)

### Object

- `sharingModel` = **Private** ([Highlight_Interaction__c.object-meta.xml](../force-app/main/default/objects/Highlight_Interaction__c/Highlight_Interaction__c.object-meta.xml)) — independently owned, **no master-detail parent** (only Lookup `Team__c` → `Team__c`, Restrict). `enableReports=true`, `enableSearch=true`, `enableSharing=true`, `enableHistory=true`.
- No `Private__c` (or any "Private"-named) field exists anywhere in the repo. `Private__c` is free.
- Existing validation rule `Include_in_CityView_Validation` (active): blocks `Include_In_CityView__c && Not_For_External_Use__c`, bypassable via `$Setup.Bypass_Automation_Setting__c.Highlight_Interaction_Validation__c`.

### CityView / MRB field map (all Checkbox default false unless noted)

| Field | Role |
|---|---|
| `Include_In_CityView__c` | Requestor flag "selected for CityView" |
| `Publish_To_CityView__c` | Reviewer flag "actually published" |
| `Status__c` | Picklist Draft (default) → Submitted → Reviewed (restricted, required) |
| `CityView_Highlight_Description__c` | LongText; auto-copied from `Description__c` on submit |
| `Include_As_MRB_Highlight__c` / `MRB_Highlight_Description__c` | MRB selection + text (text auto-copied from Leadership desc) |
| `Include_As_Leadership_Highlight__c` / `Leadership_Highlight_Description__c` | Leadership selection + text |
| `Not_For_External_Use__c` | Existing internal-only flag (blocks CityView via rule) |

No submission-timestamp/write-back field exists; nothing marks a highlight "sent" — "submitted to CityView" in practice = `Include_In_CityView__c` (request) and/or `Publish_To_CityView__c` + `Status__c=Reviewed` (publish).

### Lifecycle (all Apex/LWC; zero flows)

1. **Create** (Status=Draft) → trigger `afterInsert` creates a `File_Group__c` child (attachments).
2. **Submit for Review** quick action → `highlightSubmitForReview` LWC → `HighlightSubmitController` (**with sharing**, `WITH USER_MODE`): requires ≥1 of `Include_In_Program_Highlight__c` / `Include_In_CityView__c` / `Add_As_Contact_Interaction__c`; CityView requires an Organization participant. Sets `Status__c=Submitted`. Trigger copies descriptions.
3. **Review** (reviewer-only page section) → reviewer sets `Publish_To_CityView__c`, MRB/Leadership flags, notes.
4. **Complete Review** → `Status__c=Reviewed`.
5. **Publish**: `HighlightInteractionTriggerHandler.afterUpdate` (**without sharing**, queries `WITH SYSTEM_MODE`) on Reviewed + `Publish_To_CityView__c` → `processInteractions()` auto-creates one `Interaction__c` per participant (`CityView_Review_Status__c='Publish to CityView'`, record type Recent_Engagement for orgs) and back-links participants. **This is the only auto-creation of interaction records from highlights.**
6. **Display**: CityView is internal — `cityViewHighlights` LWC → `CityViewDetailPageController.getCityViewHighlights` (with sharing, `WITH SECURITY_ENFORCED`) reads `Interaction__c` where publish status + `Private_Interaction__c=false`. **No callout/batch/scheduled/platform-event submission of highlights exists.**

### Security inventory

- Permission sets with object perms on `Highlight_Interaction__c`:
  - `Highlights_Metrics_Requestor` (C/R/E; 8 requestor fields) — **no** reviewer fields.
  - `Highlights_Metrics_Reviewer` (C/R/E; 15 fields incl. `Publish_To_CityView__c`, MRB/Leadership, `Reviewer_Notes__c`; custom permission `Highlights_Metrics_Reviewer`; member of PSG `Highlights_Metrics_Reviewer_Group`).
  - `Manage_All_Users` (full CRUD + **View/Modify All Records**; no field perms).
  - `sfdcInternalInt__sfdc_a360_sfcrm_data_extract` "Data Cloud Salesforce Connector" (Read + **View All Records + View All Fields**, fields read-only).
- **No groups, sharingRules, queues, or profiles exist in the repo.** No Apex-managed sharing (`Highlight_Interaction__Share` never written).
- **Org-side only (retrieved 2026-10-29 into [other-org/retrieve-brme7020/](../other-org/retrieve-brme7020/)):** the org has ONE owner-based rule not in the repo — `Highlight_Interaction__c.Highlights_Sharing_for_All_Users` (BRME-6952): `allInternalUsers` → `allInternalUsers`, access **Edit**. **Every highlight is currently R/W to all internal users.** This rule would also share *private* records to everyone → it must be deleted for the privacy requirement to hold (see §5 #12 and §9).
- Org check 2026-10-29: no Group whose label contains "Highlight" exists — no naming conflict for the new group.
- Example record `a0Xbc000003mcCXEAY` "August Highlights": Status=Submitted, `Include_In_CityView__c=true`, `Publish_To_CityView__c=true` — a published CityView highlight; under the new rule it cannot be made private until unpublished (see §6).
- Related OWDs: `Interaction__c` Private; `Interaction_Participant__c` ControlledByParent; `Metric_Value__c` ControlledByParent; `Metric__c` ReadWrite; `Team__c` ReadWrite; **`File_Group__c` Read (public read-only)**.
- Legacy parallel path: `Interaction__c.Add_to_CityView__c` manual clone (`InteractionTriggerHandler`, without sharing) — user-driven on Interactions, not highlight-driven.

## 4. Mandatory security investigation — findings and design verdict

**Verdict: the requested design is enforceable.** OWD is already **Private**, so the baseline denies everyone except the owner. Criteria-based sharing then opens access exactly as requested. No OWD change is needed or made.

| Access path | Finding | Disposition |
|---|---|---|
| OWD internal | `Private` (repo) | Baseline kept — supports the design |
| OWD external | Private (≤ internal) | No portal/site access to object found |
| Role hierarchy / Grant Access Using Hierarchies | Custom object; GAUH org-side setting (default ON) | **Exception:** users above the owner in the role hierarchy keep access. Optional org-side toggle off; documented for QA/manual decision |
| Ownership | Owner always R/W | **Exception:** an owner who is an ordinary user retains access to a private record they own. Mitigation by process: reviewers create/own private highlights |
| View All / Modify All on object | `Manage_All_Users` perm set | **Privileged exception** (admin tooling) — unchanged |
| View All Data / Modify All Data | System admins | **Privileged exception** — unchanged |
| View All Records + View All Fields | Data Cloud connector perm set reads **all** highlights incl. private and will see `Private__c` data regardless of FLS | **Accepted (2026-10-29):** integration extract continues to see private data — OK per user |
| Apex `without sharing` / `SYSTEM_MODE` | `HighlightInteractionTriggerHandler` (writes only), `MetricValueTriggerHandler`, `FieldHistoryService` | Do not return highlight data to users; trigger guard added for publish path |
| User-facing controllers | All `with sharing` + `USER_MODE`/`SECURITY_ENFORCED` (`HighlightSubmitController`, `HighlightMetricsController`, `CityViewDetailPageController`, `FileGroupController`, `FieldHistoryController`, `ExportOrganizationHighlightsController`) | Record sharing enforced; private records invisible to unauthorized users |
| CityView display / export | Read `Interaction__c`, never `Highlight_Interaction__c`; export field set `Export_Organization_Highlights` has no highlight reference | Safe once publish path is blocked for private (validation + trigger guard) |
| Reports/dashboards/global search/lookup dialogs | `enableReports=true`, `enableSearch=true`; no report/dashboard metadata in repo | Standard sharing enforcement under OWD Private; org-side "run as" dashboards need review (none in repo) |
| Files | `File_Group__c` OWD **Read** → file-group records (and potentially attached files) for private highlights are readable by all internal users via API/reports. Effect: the highlight record stays private, but its attachments area can leak — at minimum the highlight's existence/name via the file group's `Highlight__c` lookup, potentially attached documents (ContentDocument sharing follows the visible group record) | **Residual leak path — accepted with process guidance (2026-10-29):** reviewers should not attach confidential files to private highlights. Changing File_Group__c OWD affects Events etc. — out of scope |
| Role hierarchy / GAUH | Users above an owner in the role hierarchy keep access to that owner's private records unless "Grant Access Using Hierarchies" is disabled org-side for the object | **Org-level setting — not changed (2026-10-29)** |
| Ownership | Record owner always has R/W to their own private records | **Agreed process (2026-10-29):** reviewers create/own private highlights |
| Field history | `customFieldHistoryTable` gated by `History_Table_Access`; controller with sharing | Follows record access; `Private__c` history tracked like other checkboxes |
| `Private=false` rule effect | Org-side owner rule `Highlights_Sharing_for_All_Users` already gives all internal users R/W on **all** highlights today; the criteria rule formalizes this for `Private__c=false` only. **The owner rule must be deleted or private records stay visible to everyone.** | Deletion staged in `BRME-7020/destructive/` — requires explicit authorization (§9) |

"Only reviewers" cannot be literal because of owners, role hierarchy above owner, and privileged View-All grants above. The smallest viable design = Private OWD (kept) + the two criteria rules + reviewer-only FLS, with the exceptions documented.

## 5. Changes

| # | File | Change |
|---|---|---|
| 1 | `objects/Highlight_Interaction__c/fields/Private__c.field-meta.xml` (new) | Checkbox, label `Private`, default false, `trackHistory=true` (repo checkbox convention), description BRME-7020 |
| 2 | `objects/Highlight_Interaction__c/validationRules/Private_CityView_Validation.validationRule-meta.xml` (new) | Active; `!$Setup.Bypass_Automation_Setting__c.Highlight_Interaction_Validation__c && AND(Private__c, OR(Include_In_CityView__c, Publish_To_CityView__c))`; message: **"Private highlights cannot be submitted to CityView."** Covers both directions: private→CityView submit and CityView→mark-private. Fires on any DML (UI, quick action, API, data load) — not UI-only |
| 3 | `groups/Highlights_Private_Highlights_Review.group-meta.xml` (new) | Label `Highlights: Private Highlights Review`; **no members** (membership is an org-side admin task) |
| 4 | `sharingRules/Highlight_Interaction__c.sharingRules-meta.xml` (new) | Two criteria-based rules: `Highlight_Non_Private_All_Internal` (`Private__c=false` → Edit to AllInternalUsers); `Highlight_Private_Review_Group` (`Private__c=true` → Edit to group `Highlights_Private_Highlights_Review`). Criteria rules auto-recalculate when `Private__c` changes in either direction (obsolete access removed by recalc) |
| 5 | `permissionsets/Highlights_Metrics_Reviewer.permissionset-meta.xml` | Add FLS `Highlight_Interaction__c.Private__c` read+edit (alphabetical position). Requestor / Manage_All_Users / Data Cloud perm sets deliberately untouched |
| 6 | `layouts/Highlight_Interaction__c-Highlight Layout.layout-meta.xml` | Add `Private__c` (Edit) in Information column after `Publish_To_CityView__c` — covers New/Edit modals (creation + editing). FLS hides it for non-reviewers |
| 7 | `flexipages/Highlight_Request_Record_Page.flexipage-meta.xml` | Add `Record.Private__c` to the reviewer-only "Applications" Draft facet (next to `Not_For_External_Use__c`) and the reviewer-only "Review" facet (next to `Publish_To_CityView__c`). FLS is the enforcement; section visibility matches the existing reviewer pattern — not a visual-only control |
| 8 | `classes/HighlightInteractionTriggerHandler.cls` | Defensive guards: skip CityView interaction creation and participant CityView-description sync when `Private__c=true` (covers validation-bypass/data-load paths; bulk-safe — set membership only). No change to File_Group creation, metric rollup, or description copy |
| 9 | `classes/HighlightSubmitController.cls` | Private-aware validation: a private highlight satisfies the "at least one option" rule (no MRB requirement added); explicit error if private + `Include_In_CityView__c`. `Private__c` read is FLS-gated (`getDescribe().isAccessible()` + conditional `USER_MODE` query) so requestors without FLS are unaffected by the new field |
| 10 | `classes/HighlightInteractionTriggerHandlerTest.cls` | New tests: validation both directions; trigger guard with bypass setting (no interactions for private+publish); reviewer perm set grants `Private__c` FLS (FieldPermissions metadata assertion); existing publish flow intact |
| 11 | `classes/HighlightSubmitControllerTest.cls` | New tests: private-only highlight validates/submits (reviewer user, real FLS via USER_MODE); private+CityView errors; requestor without FLS unaffected |
| 12 | `BRME-7020/destructive/destructiveChanges.xml` (new) | Deletes the org-side owner rule `Highlight_Interaction__c.Highlights_Sharing_for_All_Users` (`SharingOwnerRule`). **Mandatory for privacy** — with it present, private records remain R/W to all internal users. Run only with explicit authorization: `sf project deploy start --manifest BRME-7020/destructive/package.xml --post-destructive-changes BRME-7020/destructive/destructiveChanges.xml` |

Not changed (deliberately): Requestor perm set, compact layout/list view (would expose the field to non-reviewers), `ExportOrganizationHighlightsController` (no highlight data), CityView LWCs (no highlight data), MRB automation (none exists — MRB reporting is manual/out-of-repo), `Add_As_Contact_Interaction__c` (only takes effect through the publish path, which private blocks).

## 6. Already-published CityView content — cleanup decision

A highlight already published (`Status=Reviewed`, `Publish_To_CityView__c=true`, Interactions created) **cannot** be marked private (validation). To privatize it, a reviewer must first unpublish (`Publish_To_CityView__c=false`) — but the already-created `Interaction__c` records remain at `CityView_Review_Status__c='Publish to CityView'` (no retraction automation exists; pre-existing gap). **Decision (2026-10-29): no retraction/deletion of existing content — no action.** No sensitive leadership content exists on this object yet; if that changes, the manual option is to unpublish the highlight and set its Interactions to `Retract from CityView` (requires `City_View_Publish`).

## 7. Security exceptions summary (residual)

1. Record owners and users above them in the role hierarchy (GAUH org setting unchanged — agreed 2026-10-29; agreed process: reviewers own private highlights).
2. `Manage_All_Users` (View/Modify All) and admins with View/Modify All Data.
3. Data Cloud connector integration user (View All Records + View All Fields) — accepted, no change (2026-10-29).
4. `File_Group__c` attachments to private highlights readable org-wide (OWD Read) — process guidance: no confidential attachments on private highlights (2026-10-29).

## 8. Tests and verification

**Apex (automated):** items 10–11 above. Run: `HighlightInteractionTriggerHandlerTest`, `HighlightSubmitControllerTest`, `HighlightMetricsControllerTest`, `ExportOrganizationHighlightsTest` (regression). Note: `System.runAs` alone is not treated as proof — FLS assertions go through real `USER_MODE` query enforcement and a `FieldPermissions` metadata query; record-sharing behavior is verified manually below (criteria-rule recalc is not reliably assertable in unit tests).

**Deploy validation (done 2026-10-29):** `sf project deploy start --dry-run` of all 13 components with `RunSpecifiedTests` (HighlightInteractionTriggerHandlerTest, HighlightSubmitControllerTest, HighlightMetricsControllerTest, ExportOrganizationHighlightsTest) — org `DeployRequest 0Afbc00000DJwiLCAT`: **Succeeded, 13/13 components, 29/29 tests passed, 0 errors**.

**Real deploy (done 2026-10-29, authorized):** `DeployRequest 0Afbc00000DJyLxCAL` (13/13 components, 29/29 tests) + destructive `DeployRequest 0Afbc00000DJoCwCAL` deleting `Highlights_Sharing_for_All_Users`. Post-deploy retrieve confirmed only the two criteria rules remain on the object. Note: the installed sf CLI 2.62.6 has no `--description` flag, so no deploy message could be attached to the `DeployRequest`.

### End-to-end verification on dev2Current (2026-10-29)

Scripts: [scripts/brme7020-e2e-a-users.apex](../scripts/brme7020-e2e-a-users.apex) (5 test users), [scripts/brme7020-e2e-b-checks.apex](../scripts/brme7020-e2e-b-checks.apex) (functional + sharing), [scripts/brme7020-e2e-d-keep.apex](../scripts/brme7020-e2e-d-keep.apex) + [scripts/brme7020-e2e-e-shareprobe.apex](../scripts/brme7020-e2e-e-shareprobe.apex) (persistent sharing probe).

Functional (all PASS):

- F1 private + `Include_In_CityView__c` → blocked with "Private highlights cannot be submitted to CityView."
- F2 private + `Publish_To_CityView__c` → blocked.
- F3 existing CityView highlight → `Private__c=true` → blocked.
- F4 private highlight validates + submits with no include flags (MRB optional), reaches Reviewed, **0 auto-created Interactions**.
- F5 non-private highlight still publishes → Interaction created (regression intact).

Sharing matrix (5 test users: group-only, reviewer-no-group, both, requestor, none) via `UserRecordAccess` after sharing recalculation:

| User | Private record | Non-private record |
|---|---|---|
| Group member only (no PS) | **read/edit true** | read/edit true |
| Reviewer PS, no group | read/edit **false** | read/edit true |
| Both PS + group | read/edit true | read/edit true |
| Requestor only | read/edit false | read/edit true |
| No PS, no group | read/edit false | read/edit true |

This confirms: the group controls record access; the permission set controls the field; neither substitutes for the other; ordinary users cannot see private records. FLS-by-user enforcement (Private__c hidden from requestors, visible/editable to reviewers) is covered by `HighlightSubmitControllerTest` via real `USER_MODE` queries.

Note: criteria-based sharing recalculation is **deferred and asynchronous** in this org — access is not immediate on record create/flag-change; it completed after a forced rule redeploy. For QA, allow recalc time (or re-save a record / wait) before asserting access.

**Manual QA (after authorized deploy):**

1. Reviewer PS + group member: sees/edits `Private`; private record readable/editable.
2. Reviewer PS, no group: can set `Private` on own records; cannot open another owner's private record (direct URL → insufficient privileges). Exceptions: role-hierarchy managers, View-All holders.
3. Group member without reviewer PS: opens private record but `Private` checkbox hidden/read-only (no FLS).
4. Ordinary user: non-private highlights work as today; private record blocked via direct URL, tab list views, global search, lookup dialogs, ad-hoc reports.
5. Private + `Include_In_CityView__c` (or `Publish_To_CityView__c`) save → error "Private highlights cannot be submitted to CityView." (UI and API/data-load).
6. Existing CityView highlight → check `Private` → same error.
7. Private + `Include_As_MRB_Highlight__c` (optional) submits/reviews/completes; no Interaction records auto-created; reviewer adds interactions manually.
8. Flip `Private` true→false→true; after sharing recalc, access follows (group gains/loses access; all-internal gains/loses).
9. Regression: non-private submit → review → publish creates Interactions and shows in CityView/export.
10. Reports/dashboards/exports/global search as ordinary user return no private-highlight data (confirm no "run as" dashboards for this object in org).

## 9. Deployment dependencies / manual setup

- Deploy order within one package is fine (field → group → sharingRules → validation → permset → layout/flexipage → Apex).
- **Required in the same authorized deploy (post-destructive) — agreed 2026-10-29:** delete org-side owner rule `Highlight_Interaction__c.Highlights_Sharing_for_All_Users` via `BRME-7020/destructive/` — without this, privacy is not enforced. Non-private access is unchanged because the new criteria rule replaces it for `Private__c=false`.
- Org-side after deploy: populate group **Highlights: Private Highlights Review** membership (user determines members at test time, per 2026-10-29); verify no admin-profile FLS is needed; confirm no "run as" dashboards expose the object (no dashboard metadata in repo — org-side review at QA time). Standard reports need no change: under OWD Private + the criteria rules, private records simply never appear for ordinary users while reviewers see them (matches the ticket's reporting intent).
- After deploy + recalculation, verify in Setup → Sharing Settings that only the two criteria rules remain for Highlight.
