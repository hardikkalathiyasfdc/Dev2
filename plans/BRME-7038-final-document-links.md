# BRME-7038 — Plan: Final Document URL Fields + Combined Hyperlink Formula on Initiative

## Summary

Add three URL fields (Final Memo, Budget Narrative, Approval Email) and a combined hyperlink formula field to `IM_Initiative__c`. Display them in a two-column field section on the **Final Docs** tab of the Initiative Lightning record page (shared by Budgeted Initiative and Amendment record types). Grant edit FLS to Grants, read-only FLS to Leadership/Pipeline Manager.

## Key Findings (from workspace)

- The Initiative record page is a single flexipage, [IM_Budgeted_Initiative_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml), assigned as the `View` action override for the whole `IM_Initiative__c` object — it serves **both** Budgeted Initiative and Amendment record types. One page edit covers both.
- A **Final Docs** tab already exists on that page ([flexipage_tab5](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L3590-L3612), body facet `Facet-3eef7e4e-a21e-48b4-8f92-affe35f12b07`), currently holding only two `fileGroup` components. Tab visibility is gated by the `IM_Final_Doc_Tab_Access` custom permission.
- Field files live in [objects/IM_Initiative__c/fields](force-app/main/default/objects/IM_Initiative__c/fields). Naming/format convention per [Bgive_URL__c](force-app/main/default/objects/IM_Initiative__c/fields/Bgive_URL__c.field-meta.xml) and [Bgive_Link__c](force-app/main/default/objects/IM_Initiative__c/fields/Bgive_Link__c.field-meta.xml) (URL type + HYPERLINK formula with `IF(NOT(ISBLANK(...)))` guard).
- Existing permission sets: `IM: Final Doc Tab Edit Access` / `IM: Final Doc Tab Read Access` (custom permissions only, no FLS yet) and `IM: Approval Tab Edit Access` / `IM: Approval Tab Read Access` (carry Initiative FLS).

## Open Decisions (ticket discrepancies)

1. **Formula field label** — "Key details" says *Final Documents Links*; the "Fields" list says *View Required Docs*. **Proposed:** label `View Required Docs`, API `View_Required_Docs__c` (matches the Fields list, which is more specific).
2. **Approval email API name** — label is *Approval Email Link* but the ticket formula references `Approval_Doc_Link__c`. **Proposed:** keep API `Approval_Doc_Link__c` so the supplied formula works verbatim; label stays `Approval Email Link`.
3. **Permission set name** — ticket says *"IM: Approval Overview Tab Edit Access"*; no such set exists in the repo. Closest match: `IM: Approval Tab Edit Access`. **Proposed:** put edit FLS in `IM_Approval_Tab_Edit_Access` and read FLS in `IM_Approval_Tab_Read_Access` (per ticket text). Confirm with the ticket author whether they renamed the set in prod.
4. **Blank-link handling** — the ticket formula as written renders broken links for blank URLs, which violates the acceptance criteria ("Any link that is not yet populated is omitted"). **Proposed:** wrap each HYPERLINK in `IF(ISBLANK(...), "", ...)` guards (see formula below).

## Changes

### 1. New fields (4 files in `force-app/main/default/objects/IM_Initiative__c/fields/`)

| File | Label | API | Type |
|---|---|---|---|
| Final_Memo_Link__c.field-meta.xml | Final Memo Link | `Final_Memo_Link__c` | Url |
| Budget_Narrative_Link__c.field-meta.xml | Budget Narrative Link | `Budget_Narrative_Link__c` | Url |
| Approval_Doc_Link__c.field-meta.xml | Approval Email Link | `Approval_Doc_Link__c` | Url |
| View_Required_Docs__c.field-meta.xml | View Required Docs | `View_Required_Docs__c` | Text (formula) |

Formula (blank-safe version of the ticket formula):

```
IF(NOT(ISBLANK(Final_Memo_Link__c)), HYPERLINK(Final_Memo_Link__c, "Final Memo", "_blank") & BR(), "") &
IF(NOT(ISBLANK(Budget_Narrative_Link__c)), HYPERLINK(Budget_Narrative_Link__c, "Budget Narrative", "_blank") & BR(), "") &
IF(NOT(ISBLANK(Approval_Doc_Link__c)), HYPERLINK(Approval_Doc_Link__c, "Email confirmation of Approval", "_blank"), "")
```

Each field gets a `BRME-7038: ...` description, following the `IM-433: ...` convention in existing fields.

### 2. Flexipage edit — Final Docs tab

In [IM_Budgeted_Initiative_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml), add a `flexipage:fieldSection` component (label: `Final Document Links`, `horizontalAlignment` true, 2 columns) into the Final Docs tab facet (`Facet-3eef7e4e-a21e-48b4-8f92-affe35f12b07`), above the existing `fileGroup` components:

- **Left column:** Budget Narrative Link, Final Memo Link
- **Right column:** Approval Email Link, View Required Docs (formula, `uiBehavior` readonly)

Placement of the formula field in the right column under Approval Email Link keeps the section balanced; it can move to its own full-width section if reviewers prefer.

### 3. Permission sets (FLS)

- [IM_Approval_Tab_Edit_Access.permissionset-meta.xml](force-app/main/default/permissionsets/IM_Approval_Tab_Edit_Access.permissionset-meta.xml): add `editable=true/readable=true` FLS for the 3 URL fields; `readable=true` only for the formula field.
- [IM_Approval_Tab_Read_Access.permissionset-meta.xml](force-app/main/default/permissionsets/IM_Approval_Tab_Read_Access.permissionset-meta.xml): add `readable=true` (editable=false) FLS for all 4 fields.

This satisfies: Edit = Grants only; Read = Grants, Leadership, Pipeline Manager (whichever users hold these sets). No changes needed to the Final Doc Tab sets unless decision #3 resolves differently.

### 4. Manifest

Add the 4 `CustomField` entries (and confirm `PermissionSet` + `FlexiPage` are covered) in [manifest/package.xml](manifest/package.xml) so the change deploys as a unit.

## Verification

1. ✅ Deployed to dev2Current (Deploy ID `0Afbc00000D3A3NCAV`, 7/7 components succeeded): 4 fields created, flexipage + 2 permission sets changed.
2. ✅ Test data on existing Budgeted Initiatives:
   - `Test - 08/14/2026 3.0` (`a0qbc00000I5Kq9AAF`): Final Memo + Budget Narrative populated, Approval Email blank → formula output contains only the two populated hyperlinks, blank link omitted (acceptance criteria verified).
   - `Test - 08/14/2026 2.0` (`a0qbc00000I0wsrAAB`): all three links populated → formula renders all three hyperlinks with `_blank` targets and correct labels.
3. Manual UI check remaining: open both records → Final Docs tab → "Final Document Links" section shows the two-column layout; links open in new tabs.
4. FLS spot-check remaining: user with only Read set sees all 4 fields read-only; user without either set sees none.

## Out of scope / notes

- No page layout (`IM_Initiative__c-Initiative Layout`) change — fields surface via the flexipage dynamic form, not the classic layout.
- No Apex/test changes required (formula + FLS + flexipage only).
