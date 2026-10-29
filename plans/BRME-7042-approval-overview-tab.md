# BRME-7042 — Plan: Approval Overview Tab on Initiative & Amendment Record Pages

## Summary

Create custom permission **IM: Approval Overview Tab Access**, grant it in the two existing Approval Overview Tab permission sets, and add a new **Approval Overview** tab to the Initiative Lightning record page immediately after the **Final Docs** tab. The tab consolidates four sections — **Details**, **Approval Details**, **Approval Checklist** (fields already built in BRME-7039), and **Report Charts** (three budget breakdown pie charts, built from scratch, with conditional display). Tab visibility: `Approved = false` AND `Status != Draft/Completed/Declined` AND custom permission; `Approved = true` also implements the Ask 3 post-approval **hide** rule. Persona-based edit/read behavior is driven by FLS (Ask 2) plus a new PM approval-fields edit permission set.

## Key Findings (from workspace)

- **One flexipage serves both record types.** [IM_Budgeted_Initiative_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml) is the `View` override for the whole `IM_Initiative__c` object — it covers **Budgeted Initiative and Amendment** (BRME-7038 finding). One page edit satisfies "Initiative and Amendment record pages". No record-type criterion on the new tab.
- **Tab order / insertion point:** Final Docs = `flexipage_tab5` ([lines 3590-3612](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L3590-L3612)), immediately followed by Approvals = `flexipage_tab6` (~[line 3850](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L3850)). The new tab is inserted **between** them.
- **Tab visibility pattern with custom permission + record fields exists** — the Grants tab uses `booleanFilter` with `{!Record.Approved__c}`, `{!$Permission.CustomPermission.X}` and `{!Record.RecordType.DeveloperName}` criteria (see flexipage_tab10). Same pattern applies to the new tab.
- **Approval Checklist fields all exist** (BRME-7039): `Term_Alignment__c`, `Required_Approval_Docs__c`, `Initiative_Name_and_Budget_Name_Review__c`, `Strategic_Locations_Aligned__c` + Notes, `Budget_Aligns_with_Memo__c` + Notes, `Type_of_Work_Aligns_Memo__c` + Notes, plus `View_Required_Docs__c` (Final Docs Links, BRME-7038). Notes-required validation rules and `= "No"` dynamic visibility already built. The section currently lives in the **Approvals** tab (`flexipage_fieldSection_brme7039_checklist`, facet `Facet-eeccf20a-3635-4815-a18f-2744bd9ea137`, [line 3287](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L3287)).
- **Approval Details fields exist:** `Approver__c` is a **picklist** (global value set `Approver`) = ticket's "dropdown" ✅; `Approved_Date__c` (label *Approved Date* — ticket says "Approval Date", minor label mismatch to confirm); `Approval_Notes__c` (LongTextArea 32768).
- **Details fields exist:** `Start_Date__c`, `End_Date__c`, `Term__c` (formula, months), `Amount_Term__c`, `Run_Rate__c`, `Current_Budget__c` (lookup). **Budget Term** = `Current_Budget__r.Budget_Term_months__c` — cross-object field items are supported in this page (precedent: `Record.Foundation_Code__r.Full_Path__c` at [line 3494](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L3494)).
- **Chart display conditions** reference `IM_Budget__c.Component__c` / `Geography__c` / `Type_of_Work__c` checkboxes (confirmed in [objects/IM_Budget__c/fields](force-app/main/default/objects/IM_Budget__c/fields)). Flexipage visibility rules **cannot reference cross-object fields**, so 3 mirror formula fields on Initiative are needed.
- **The three reports do NOT exist in dev2Current** (verified via SOQL on `Report`) nor anywhere (confirmed with user) — **they are created from scratch** in this ticket (see Change #4b).
- **Report source object:** `IM_Budget_Row__c` has the dimension lookups `Component__c`, `Geography__c`, `Type_of_Work__c` (Lookup, confirmed) plus `Total_Amount__c` (Currency) and links to the budget via `Budget__c` (Lookup). Reports group rows by each dimension, sum Total Amount, and filter by the current budget so charts scope to the record.
- **reportChart component pattern** (from [BRM_Home_Page_Featuring_BIM_and_CityView](force-app/main/default/flexipages/BRM_Home_Page_Featuring_BIM_and_CityView.flexipage-meta.xml#L200-L219)): `flexipage:reportChart` with `cacheAge`, `label`, `reportName` (developer name), `showRefreshButton`, optional `visibilityRule`.
- **Permission sets exist:** [IM_Approval_Overview_Tab_Edit_Access](force-app/main/default/permissionsets/IM_Approval_Overview_Tab_Edit_Access.permissionset-meta.xml) (editable FLS on checklist + approval fields + doc links) and [IM_Approval_Overview_Tab_Read_Access](force-app/main/default/permissionsets/IM_Approval_Overview_Tab_Read_Access.permissionset-meta.xml) (read-only). Neither has a `<customPermissions>` node yet.
- **Custom permission file convention:** [customPermissions](force-app/main/default/customPermissions) e.g. `IM_Final_Doc_Tab_Access.customPermission-meta.xml`; API name `IM_Approval_Overview_Tab_Access`, label `IM: Approval Overview Tab Access`.
- **Status values:** Draft, Declined, In Development, Ready for Approval, Ongoing, Completed (`Complete` inactive). Approval happens before Ongoing.
- Dynamic Forms respects FLS: fields with read-only FLS render read-only on the tab automatically — this is the mechanism for the Ask 2 persona matrix.

## Changes

### 1. Custom Permission (1 new file)

`force-app/main/default/customPermissions/IM_Approval_Overview_Tab_Access.customPermission-meta.xml` — label **IM: Approval Overview Tab Access**, description `BRME-7042: Grants access to the Approval Overview tab on the Initiative record page.`

### 2. Permission sets (2 edited files)

Add to **both** [IM_Approval_Overview_Tab_Edit_Access](force-app/main/default/permissionsets/IM_Approval_Overview_Tab_Edit_Access.permissionset-meta.xml) and [IM_Approval_Overview_Tab_Read_Access](force-app/main/default/permissionsets/IM_Approval_Overview_Tab_Read_Access.permissionset-meta.xml):

```xml
<customPermissions>
    <enabled>true</enabled>
    <name>IM_Approval_Overview_Tab_Access</name>
</customPermissions>
```

Also add `readable` FLS for the 3 new chart-condition formula fields (Change #3) to both sets. **Persona assignment (Ask 2)** — permission set assignments:

| Persona | Permission set(s) | Result on tab |
|---|---|---|
| Grants | **IM: Approval Overview Tab Edit Access** | Edit checklist, approval fields, final doc links ✅ |
| Pipeline Manager | **IM: Approval Overview Tab Read Access** + **IM: Approval Tab Edit Access** (existing) | Read-only tab except Approver / Approval Date / Approval Notes ✅ |
| Leadership | **IM: Approval Overview Tab Read Access** | View incl. Final Document links, all read-only ✅ |

**PM edit via existing sets (Decision #5):** the existing [IM_Approval_Tab_Edit_Access](force-app/main/default/permissionsets/IM_Approval_Tab_Edit_Access.permissionset-meta.xml) already grants editable FLS on `IM_Initiative__c.Approver__c` (and the other approval/edit fields) but does **not** touch the BRME-7039 checklist fields — exactly the PM scope. So PMs get Read Access (tab visibility + read-only on everything) **plus** the existing Approval Tab Edit Access (editable on the 3 approval fields). **No new permission set is created.** Verify at implementation that Edit Access grants editable on all three of `Approver__c`, `Approved_Date__c`, `Approval_Notes__c` (add any missing to that set).

### 3. New formula fields for chart visibility (3 new files)

Flexipage visibility rules can't traverse `Current_Budget__r.*`, so add Checkbox formula fields on `IM_Initiative__c` (in `objects/IM_Initiative__c/fields/`):

| File | Label | Formula |
|---|---|---|
| Current_Budget_Component__c.field-meta.xml | Current Budget: Component | `Current_Budget__r.Component__c` |
| Current_Budget_Geography__c.field-meta.xml | Current Budget: Geography | `Current_Budget__r.Geography__c` |
| Current_Budget_Type_of_Work__c.field-meta.xml | Current Budget: Type of Work | `Current_Budget__r.Type_of_Work__c` |

Blank lookup → unchecked (false), so charts hide when there is no Current Budget. `BRME-7042: ...` descriptions. These fields are **not placed on any page section** — they exist only for visibility rules.

### 4a. Flexipage — new Approval Overview tab

Edit [IM_Budgeted_Initiative_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml):

**a) New tab** (`flexipage_tabApprovalOverview`, title `Approval Overview`) inserted after the Final Docs `itemInstances` block (after [line ~3612](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L3612)):

```xml
<visibilityRule>
    <booleanFilter>1 AND 2 AND 3 AND 4 AND 5</booleanFilter>
    <criteria><leftValue>{!Record.Approved__c}</leftValue><operator>EQUAL</operator><rightValue>false</rightValue></criteria>
    <criteria><leftValue>{!Record.Status__c}</leftValue><operator>NE</operator><rightValue>Draft</rightValue></criteria>
    <criteria><leftValue>{!Record.Status__c}</leftValue><operator>NE</operator><rightValue>Completed</rightValue></criteria>
    <criteria><leftValue>{!Record.Status__c}</leftValue><operator>NE</operator><rightValue>Declined</rightValue></criteria>
    <criteria><leftValue>{!$Permission.CustomPermission.IM_Approval_Overview_Tab_Access}</leftValue><operator>EQUAL</operator><rightValue>true</rightValue></criteria>
</visibilityRule>
```

Ask 3 is satisfied by criterion 1: once approved, `Approved__c = true` hides the tab (Decision #3 — hide, keyed on `Approved__c`, not Status). No separate `Status != Ongoing` criterion needed.

**b) Tab body facet** with four sections in ticket order:

1. **Details** — `flexipage:fieldSection`, one column, all `uiBehavior` readonly: Start Date, End Date, Term, `Record.Current_Budget__r.Budget_Term_months__c` (Budget Term), `Record.Current_Budget__c` (Current Budget = **lookup, readonly**, Decision #6), Amount/Term, Run Rate.
2. **Approval Details** — `flexipage:fieldSection`, one column: Approver, Approved Date, Approval Notes (all editable; actual editability enforced by FLS per persona).
3. **Approval Checklist** — **move** the existing `flexipage_fieldSection_brme7039_checklist` block (and its column facets) from the Approvals tab into this tab, keeping the 4 picklists, 2 readonly formula fields, `View_Required_Docs__c` (label **View Required Docs** — the ticket's "Final Docs Links" item), and the `= "No"` visibility rules on the Notes fields. (Confirmed Decision #1: this is the new consolidated tab.)
4. **Report Charts** — three `flexipage:reportChart` item instances rendering the reports' **pie charts** (Decision #2), each with a single-criterion `visibilityRule` on its mirror field (`{!Record.Current_Budget_Component__c}` EQUAL `true`, etc.). `reportName` values = the three report developer names created in #4b. Record-scoping: each report filters on the current budget so the chart shows only this record's breakdown; verify "filter by record" behavior in App Builder after deploy.

Section headers exactly as ticket: `Details`, `Approval Details`, `Approval Checklist` — no "Allocation" wording (acceptance criterion).

### 4b. New Custom Report Type + 3 reports (created from scratch — Decision #2)

**New Custom Report Type** `Initiatives_With_Budget_And_Budget_Rows` — label **Initiatives With Budget and Budget Rows**. Object relationship: **Initiative → Budget → Budget Rows** (3 objects; NO Budget_Grant join — this fixes the earlier blank-chart issue where the reused `Initiatives_with_Budget_Rows__c` CRT inner-joined through Budget_Grant and dropped rows without a grant). Category: Other Reports.

**3 reports** created under `force-app/main/default/reports/IMApprovalOverviewReports/`, each a summary report grouped by the row dimension, summed on `Total_Amount__c`, with a **pie chart**:

| File | Name | Grouping (row) | Pie chart |
|---|---|---|---|
| Budget_Breakdown_by_Component.report-meta.xml | Budget Breakdown by Component | Component Name (`IM_Budget_Row__c.Component__c.Name`) | pie |
| Budget_Breakdown_by_Geography.report-meta.xml | Budget Breakdown by Geography | Geography (`IM_Budget_Row__c.Geography__c.Name`) | pie |
| Budget_Breakdown_by_Type_of_Work.report-meta.xml | Budget Breakdown by Type Of Work | Type Of Work (`IM_Budget_Row__c.Type_of_Work__c`) | pie |

**Columns** (all three): Budget Name (`IM_Budget__c.Name`), Budget Row Total Amount (`IM_Budget_Row__c.Total_Amount__c`, Sum), **Partner Funding Type** (`IM_Initiative__c.Partner_Funding_Type__c`), Budget Amount (`IM_Budget__c.Budget_Amount__c`).

**Filters** (all three):
- Time frame: **All Time** (All Initiatives).
- `IM_Budget__c.Status__c` = **Pending Approval** OR `IM_Budget__c.Is_Active__c` = **True** (filter logic `1 OR 2`).
- Budget Row **Funding Partner is blank**: `IM_Budget_Row__c.Partner_Fund__c` = "" (blank).
- **Supplemental rule:** `IM_Initiative__c.Partner_Funding_Type__c` **≠ 'Supplemental'** — this excludes partner-fund rows by removing the Supplemental-funded rows when the initiative is Supplemental; included otherwise (per ticket's "Partner funds excluded when Supplemental; included otherwise"). `Partner_Funding_Type__c` is the Initiative picklist holding value `Supplemental` (found via `IMBudgetTriggerHandler.cls` line 165).

**Chart** (all three): Pie, show **percentage + amount (values) + legend** (legendPosition Bottom, showPercentages + showValues true).

- **Folder:** `IMApprovalOverviewReports` (**IM Approval Overview Reports** — a managed/shared folder, NOT public, per user: "a managed folder is better than public"). Shared read-only to personas; edit stays with admin.
- **Record-scoping:** include the **Initiative Id** column so the embedded `flexipage:reportChart` "filter by record" binds to the current record's Id (Decision: scope via record filter on Initiative Id). Verify binding in App Builder after deploy.
- Each report gets a `BRME-7042: ...` description.

> **Note:** The 3 reports previously built on the old `Initiatives_with_Budget_Rows__c` CRT will be **re-pointed** to the new CRT and updated with the columns/filters/chart options above.

### 5. Manifest

Add to [manifest/package.xml](manifest/package.xml): `CustomPermission: IM_Approval_Overview_Tab_Access`, `PermissionSet: IM_Approval_Overview_Tab_*_Access` (+ `IM_Approval_Tab_Edit_Access` if its FLS needs the 3 approval fields), `CustomField: IM_Initiative__c.Current_Budget_*__c` (3), `CustomReportType: Initiatives_With_Budget_And_Budget_Rows`, `ReportFolder: IMApprovalOverviewReports`, `Report: IMApprovalOverviewReports/Budget_Breakdown_by_*` (3), confirm `FlexiPage: IM_Budgeted_Initiative_Page` covered.

### 6. Apex tests

**Not needed** — all BRME-7042 fields are formulas (no Apex logic), so no test class was retained. (A temporary `IMInitiativeApprovalOverviewTest` was created during implementation to validate the mirror formulas, passed 3/3, then removed since there is no Apex to cover.)

## Decisions (confirmed with user)

1. **Approval Checklist location** — the new Approval Overview tab is the consolidated home: **move** the BRME-7039 section from the Approvals tab into it.
2. **Charts** — reports don't exist anywhere; **create the 3 reports from scratch** (Change #4b) and embed their **pie charts** on the record page via `flexipage:reportChart`. Source object `IM_Budget_Row__c`, folder `GrantsTeamInitiativeManagement`.
3. **Ask 3 (hide vs lock when Ongoing)** — **hide**, keyed on `Approved__c = true` (not Status). This is already criterion 1 of the base visibility rule, so no extra XML needed.
4. **Terminal statuses** — tab **hidden when Status = Completed and when Declined** (criteria added to the tab visibility rule).
5. **Pipeline Manager edit of approval fields** — **reuse the existing `IM: Approval Tab Edit Access`** set (it grants editable FLS on the approval fields but not the checklist fields = the exact PM scope). PMs get it **on top of** `IM: Approval Overview Tab Read Access`. **No new permission set created.**
6. **"Current Budget" in Details** — show the **lookup field** `Current_Budget__c`, **read-only** on this tab.
7. **Approved Date label** — keep existing label **"Approved Date"** (same field; no change).

## Open Decisions

**None.** All decisions confirmed. Ready to implement.

## Verification

1. Deploy to dev2Current with `--test-level NoTestRun`; verify via `DeployRequest` Tooling API query (repo lesson #4/#5 — CLI exit code and "locale en_US" error are not authoritative).
2. Assign both permission sets before UI/SOQL checks (repo lesson — new FLS gates visibility; `sf org assign permset` needs one `--name` per call).
3. Tab matrix test records: Draft initiative (tab hidden), In Development/Ready for Approval + unapproved (tab visible), Completed/Declined (hidden per Decision #4), Approved = true (hidden per Decision #3/Ask 3), user without custom permission (hidden).
4. Section checks: Details values match Current Budget; Approval Checklist Notes appear/require on "No"; charts render for a budget with Component/Geography/Type of Work checked and hide otherwise.
5. Persona checks (Ask 2): Grants user edits checklist/approval/links; PM edits only the 3 approval fields; Leadership read-only incl. links.
6. Both record types: verify on a Budgeted Initiative and an Amendment record.
7. Apex tests pass if mirror fields created.

## Out of scope / notes

- No changes to the existing **Approvals** tab other than relocating the Approval Checklist section (if Decision #1 = move). The Approvals tab and its `IM_Approval_Tab_Access` gating stay as-is.
- No new validation rules (Notes-required rules already exist from BRME-7039).
- No page layout (classic) changes — everything surfaces via the dynamic-forms flexipage.
- Reports/charts are built from scratch in this ticket (Change #4b); report record-scoping binding to be verified in App Builder (see #4b note).

## Implementation Log (completed 2026-10-13)

### Deployed to dev2Current (Deploy IDs `0Afbc00000D6RinCAF` reports, `0Afbc00000D6RqrCAF` main, `0Afbc00000D6RxJCAV` test — all Succeeded via DeployRequest)

| Component | Files | Notes |
|---|---|---|
| Custom permission | [IM_Approval_Overview_Tab_Access.customPermission-meta.xml](force-app/main/default/customPermissions/IM_Approval_Overview_Tab_Access.customPermission-meta.xml) | label "IM: Approval Overview Tab Access" |
| 4 formula fields | [Current_Budget_Component__c](force-app/main/default/objects/IM_Initiative__c/fields/Current_Budget_Component__c.field-meta.xml), [Current_Budget_Geography__c](force-app/main/default/objects/IM_Initiative__c/fields/Current_Budget_Geography__c.field-meta.xml), [Current_Budget_Type_of_Work__c](force-app/main/default/objects/IM_Initiative__c/fields/Current_Budget_Type_of_Work__c.field-meta.xml) (chart visibility mirrors), [Current_Budget_Term_months__c](force-app/main/default/objects/IM_Initiative__c/fields/Current_Budget_Term_months__c.field-meta.xml) (Budget Term for Details) | `BRME-7042:` descriptions |
| 3 permission sets | Edit/Read Access + [IM_Approval_Tab_Edit_Access](force-app/main/default/permissionsets/IM_Approval_Tab_Edit_Access.permissionset-meta.xml) | custom permission granted in Edit/Read; Details-field + mirror-field FLS added; PM set gained `Approved_Date__c`+`Approval_Notes__c` |
| 3 reports | [reports/GrantsTeamInitiativeManagement](force-app/main/default/reports/GrantsTeamInitiativeManagement) — Budget_Breakdown_by_Component / Geography / Type_of_Work | summary reports, pie charts, `Initiatives_with_Budget_Rows__c` report type |
| Flexipage | [IM_Budgeted_Initiative_Page](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml) | new "Approval Overview" tab after Final Docs (5-criterion visibility), Details/Approval Details sections (1-col), Approval Checklist section (1-col, moved), 3 conditional reportCharts |
| 3 reports folder | [IMApprovalOverviewReports](force-app/main/default/reports/IMApprovalOverviewReports.reportFolder-meta.xml) | reports moved here; Shared/ReadOnly for all users, edit stays with admin |

> Apex test: `IMInitiativeApprovalOverviewTest` was created to validate the mirror formulas (3/3 pass), then **removed** — the fields are pure formulas with no Apex to cover.

### Phase 2 — New custom report type + reports (completed 2026-10-13)

Rebuilt the breakdown reports per the updated ticket spec (new CRT, more columns, filters):

| Component | Files | Notes |
|---|---|---|
| Custom Report Type | [Initiatives_With_Budget_And_Budget_Rows.reportType-meta.xml](force-app/main/default/reportTypes/Initiatives_With_Budget_And_Budget_Rows.reportType-meta.xml) | Initiative → Budget → Budget Rows (NO Budget_Grant inner join). Deployed; developer name `Initiatives_With_Budget_And_Budget_Rows__c`. |
| 3 reports (updated) | [reports/IMApprovalOverviewReports](force-app/main/default/reports/IMApprovalOverviewReports) — Budget_Breakdown_by_Component / Geography / Type_of_Work | Re-pointed to the new CRT; added columns Budget Name, Partner Funding Type, Budget Amount; filters Partner_Fund blank + (Status=Pending Approval OR Is_Active) + Partner_Funding_Type≠Supplemental; pie charts with legend. |
| Report folder | [IMApprovalOverviewReports](force-app/main/default/reports/IMApprovalOverviewReports.reportFolder-meta.xml) | accessType `PublicInternal` (all internal users, ReadOnly). |

**Verified in browser:** all 3 pie charts render on the Approval Overview tab with data (Component=TBD, Geography/Type of Work grouped, $10,000 each) on record `a0qbc00000HmnW5AAJ`.

### Gotchas (Phase 2)

6. **Custom Report Type metadata** — file lives in `reportTypes/` dir with `.reportType-meta.xml` suffix and root element `<ReportType>` (NOT `CustomReportType`). Joins are recursive: `<join><join>...</join></join>` with `outerJoin`+`relationship` (no `childObject`/`field`/`relationshipName`). Developer name gets a `__c` suffix.
7. **CRT column keys** use the full relationship path with `$` separator: `IM_Initiative__c.Budgets__r.Budget_Rows__r$<Field>`; the dimension grouping for a lookup is `...$Component__c` (the `.Name` suffix appears only in the report-type describe, not the report XML).
8. **Report `timeFrameFilter`** — omitting it defaults to "All Time"; the new CRT doesn't expose `IM_Initiative__c$CreatedDate` as a date column, so the filter had to be removed to deploy.
9. **Report `showPercentages`/`showValues`** are not valid elements in `ReportChart` — percentage/amount show via the pie legend by default.
10. **Report folder `accessType`** must be `PublicInternal` (not `Public`/`Shared`) for "all internal users"; `Hidden` blocks the embedded charts from rendering for non-shared users.

### Remaining manual verification

- Assign `IM: Approval Overview Tab Read/Edit Access` to users (tab visibility requires the custom permission).
- Confirm the embedded reportChart "filter by record" scopes the pie to the current initiative (App Builder); the report's primary object is Initiative so it should bind on the record Id.
- UI pass on a Budgeted Initiative and an Amendment across the status matrix (Draft hidden, In Development/Ready visible, Completed/Declined/Approved hidden).
