# BRME-7020-FG — Plan: Private File Groups for Private Highlights

**Goal:** a private highlight's attachment container (`File_Group__c`) must not be visible to ordinary users. Currently `File_Group__c` OWD = **Read** → every file group is readable by all internal users, leaking the private highlight's existence/name via the `Highlight__c` lookup.

**Status:** Plan only. **Not implemented.** Needs architect sign-off because `File_Group__c` is shared infrastructure (see Impact).

---

## 1. Org facts (verified 2026-10-30, dev2Current)

- `File_Group__c.object-meta.xml`: `sharingModel = Read`, `enableReports=false`, `enableSearch=false`, `enableSharing=true`. Name is AutoNumber `FG-{00000}`.
- **Consumers (live data):** `Object_Type__c` = `Initiative` (35), `Highlight` (22). Code also creates file groups for **Announcements** (`IMAnnouncementTriggerHandler`), **Budgeted Initiatives** (`IMBudgetedInitiativeHandler`), **Amendments** (`IMAmendmentInitiativeHandler`), **Initiatives** (`IMInitiativeTriggerHandlerHelper`). → **Not just a Highlights change.**
- Files surface via `FileGroupController.getAllFiles(fileGroupId)`: queries `ContentDocumentLink` (files) and `File_Link__c` (links) **`WITH SYSTEM_MODE`** — i.e. it does **not** enforce record sharing on the file group. See §4 caveat.

## 2. ⚠️ Key finding that changes the design

`FileGroupController.getFileGroup` and `getAllFiles` both run in **SYSTEM_MODE**. That means even if we make the file-group *record* private, the files panel is driven by passing a `fileGroupId` the component already resolved — SYSTEM_MODE reads would still return its files/links to anyone who reaches the component with that id. **OWD + sharing rules alone do not fully close the leak through this LWC.** To truly restrict, the controller must enforce the file group's `Private__c` (see change #6).

## 3. Changes

| # | Component | Change |
|---|---|---|
| 1 | `File_Group__c.Private__c` (new CustomField) | Checkbox, default `false`, label `Private`, description BRME-7020 |
| 2 | `File_Group__c` object-meta | `sharingModel` **Read → Private** |
| 3 | `sharingRules/File_Group__c.sharingRules-meta.xml` (new) | Mirrors the highlight pattern exactly. Two criteria rules: `FileGroup_Non_Private_All_Internal` (`Private__c=false` → **Edit** to `AllInternalUsers`); `FileGroup_Private_Review_Group` (`Private__c=true` → **Edit** to group `Highlights_Private_Highlights_Review`). The first rule is **mandatory** — it preserves current read access for Initiatives/Announcements/Budgets/Amendments/non-private highlights, which OWD Private would otherwise remove |
| 4 | `HighlightInteractionTriggerHandler.cls` | Sync file-group privacy to the highlight: on `Private__c` change (both directions) and on insert, set child `File_Group__c.Private__c = highlight.Private__c`. Bulk-safe |
| 5 | Highlight delete → file group | **Cascade delete** file groups when their highlight is deleted (trigger `afterDelete`; the `Highlight__c` lookup is not master-detail so children are orphaned otherwise). Recommended since file groups are 1:1 containers with no independent value — confirm attached-file retention isn't required |
| 6 | `FileGroupController.cls` | Enforce privacy in SYSTEM_MODE reads: `getFileGroup` — when the resolved group's `Private__c=true`, require the running user to be in `Highlights_Private_Highlights_Review` (FeatureManagement/perm or group-membership check) before returning the id; `getAllFiles` — same gate on `fileGroupId`. Without this, sharing rules don't stop the LWC path |
| 7 | Perm set FLS | `File_Group__c.Private__c` read/edit only on `Highlights_Metrics_Reviewer` (field hidden from ordinary users) |
| 8 | Tests | `FileGroupControllerTest` + `HighlightInteractionTriggerHandlerTest`: private file group hidden from non-group user; flip both directions; delete cascade; non-private unchanged |

## 4. Ordering / deploy (critical)

Deploy **#1, #3, #7 together, then #2**, or all in one package — but **never OWD→Private without the `Private=false → AllInternalUsers` rule live**, or every existing Initiative/Announcement/Budget file group loses access for all users. Deploying OWD + sharing rules triggers a **sharing recalculation** (async).

## 5. Decisions / answers from user (2026-10-30)

- **General-purpose flag:** `File_Group__c.Private__c` is **not highlight-specific** — it's the shared privacy flag for any object that uses file groups. Highlights set it via the sync automation (#4); Initiatives/Announcements/Budgets/Amendments simply leave it `false` (so their file groups stay shared to all internal users via the first rule). If another object later needs private attachments, it sets `Private__c=true` on its file groups the same way — no sharing-model change needed.
- Sharing mirrors highlights: `Private=true` → group **Highlights: Private Highlights Review**; `Private=false` → AllInternalUsers.
- Other consumers: **verified** — Initiative, Announcement, Budget, Amendment. The `Private=false → AllInternalUsers` rule covers them; no functional change intended for them.
- Backfill: **not needed** — `Private__c` on highlights is brand-new; field defaults to `false`.
- Flip mid-life: **not automatic** — needs change #4 (automation). Sharing recalc on flip is async.
- Files (ContentDocument): **no separate document-level handling** — container gating (#3 + #6) is sufficient per user.

## 6. Impact / risk

- **Blast radius:** `File_Group__c` OWD change affects Initiatives, Announcements, Budgets, Amendments — not just Highlights. Mitigated by the `Private=false → AllInternalUsers` rule, but this is why architect sign-off is required.
- **Recalc:** OWD + criteria-rule changes trigger full sharing recalculation on `File_Group__c` (async; access not immediate).
- **SYSTEM_MODE controller** (change #6) is the part that actually prevents disclosure through the file component; sharing rules alone are insufficient here.

## 7. Open questions for you

1. **Delete cascade (#5):** OK to delete the file group when its highlight is deleted, or must attached files be retained (orphan + auto-private instead)?
2. Sign-off on touching shared `File_Group__c` OWD given the Initiative/Announcement/Budget consumers.

(Resolved: the controller gate #6 keys record privacy off **group** membership in `Highlights_Private_Highlights_Review`, matching the record-sharing rule — not the permission set.)
