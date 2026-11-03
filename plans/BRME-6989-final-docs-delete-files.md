# BRME-6989 — Plan: BIM Admins/Super Users can delete files from the Final Docs section

## Ticket

**BRME-6989 — BIM: BIM Admins should be able to delete files from Final Docs Section**
- **AC:** BIM Super Users can delete files in the Final Docs Files section.
- **Context from requester:** There is no separate "Super User" permission set today — Super Users currently hold the same **IM: Admin** permission-set group as full Admins. Only **Kelly Mehlenbacher** and **Sara Ginsberg** are Super Users (more access than a normal user, less than a full admin). We likely need a **new custom permission (or permission set)** scoped to just them, rather than opening delete up to every member of IM: Admin.

## Summary

The Final Docs "Files" section on the Initiative record page is the `fileGroup` LWC (instance `c_fileGroup4`, category `Final Docs`). The component **already implements a complete delete flow** (a per-row trash icon, a confirmation modal, and an Apex `deleteFile` method), but it is **turned off for the Final Docs instance** — its `showDeleteButton` property is set to `false` in the flexipage. The adjacent **Private Docs** instance (`c_fileGroup5`) has `showDeleteButton = true`, proving the mechanism works.

The work is therefore not "build delete" but "expose delete, gated so only BIM Admins/Super Users see it." We add a new custom permission for Final Docs file deletion, wire it into the permission check, flip `showDeleteButton` to `true`, and grant the permission only to the intended users.

## Key findings (from workspace + org research)

### Component / delete mechanism (already built)
- [fileGroup.html](force-app/main/default/lwc/fileGroup/fileGroup.html): delete confirmation modal (`isFileDelete`) + datatable `onrowaction={handleRowAction}`.
- [fileGroup.js](force-app/main/default/lwc/fileGroup/fileGroup.js): `showDeleteButton` `@api` property; `applyPermission()` appends a `delete` button-icon column only when `displayReadMode === false && showDeleteButton`; `handleDelete()` calls `deleteFile`.
- [FileGroupController.cls](force-app/main/default/classes/FileGroupController.cls):
  - `getPermissions(customPermission, category, recordId)` (cacheable) returns `true` = **read mode** (hides Add/Delete). Returns `false` (edit mode) only when the user (a) is in a permission set that is part of the `File_Group_Edit_Access` group and (b) has the given custom permission via `FeatureManagement.checkPermission`, and (c) the initiative isn't Completed and the user isn't record-read-only.
  - `deleteFile(recordId, fileType)` — deletes a `File_Link__c` (Link) or a `ContentDocument` (file) via `BBApps_Crud.doDelete(..., SYSTEM_MODE)`. **No permission check inside `deleteFile` itself** — gating is purely client-side via column visibility. (See *Hardening* note below.)

### Flexipage wiring — the actual switch
[IM_Budgeted_Initiative_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml):
- Final Docs `fileGroup` (`c_fileGroup4`, [lines 2974-2997](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L2974-L2997)): `showDeleteButton = false`, `customPermission = IM_Initiative_Final_Docs_FileGroup`, `showAddFiles = true`.
- Private Docs `fileGroup` (`c_fileGroup5`, [lines 2998-3027](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L2998-L3027)): `showDeleteButton = true` — reference for the target state. Its whole component is also visibility-gated by `$Permission.CustomPermission.IM_Initiative_Private_Docs_FileGroup`.

### Custom permissions (all already exist in org + repo)
- `IM_Initiative_Final_Docs_FileGroup` ([file](force-app/main/default/customPermissions/IM_Initiative_Final_Docs_FileGroup.customPermission-meta.xml)) — "grant access to File Group on Final Docs." Currently passed to `getPermissions`.
- `IM_Final_Doc_Tab_Access` — gates the Final Docs **tab** visibility.
- `IM_Final_Doc_Edit_Access` — "used on fileGroup LWC."
- **None is delete-specific.** A new one is needed so delete can be granted to Super Users without granting it to all edit-access holders.

### Permission sets (org)
- `IM_Admin` is a **Permission Set Group** (label "IM: Admin") with **18 active members** — including **Kelly Mehlenbacher** and **Sara Ginsberg** (the two Super Users) and full admins (Hardik, IM System, Gauri, etc.). So "same as Admins" today = membership in this group.
- `IM_Final_Doc_Tab_Edit_Access` / `IM_Final_Doc_Tab_Read_Access`: only **Ravi Bheemreddy** holds these in dev2 (thin test coverage).
- `File_Group_Edit_Access`: held by **IM System** and **JT Tindall**; its group membership is the first gate in `getPermissions`.

### Test data (set up for this ticket)
- Record: **Test - 08/14/2026 1.0** (`a0qbc00000HmnW5AAJ`), Status = Ready for Approval.
- This record had **no File_Group__c rows** (trigger did not create them on insert), so uploads fell back to the running User. Fixed via [scripts/brme6989-testdata-setup.apex](scripts/brme6989-testdata-setup.apex): created `FG-02455 / Final Docs` (`a0Gbc000009zEIbEAM`) and `FG-02456 / Private Docs` (`a0Gbc000009zEIcEAM`), and deleted the stray user-linked docs.
- Uploaded `BRME-6989-Test-Final-Memo.txt` + `BRME-6989-Test-Budget-Narrative.pdf` into the Final Docs group — both now linked to `a0Gbc000009zEIbEAM` (verified via ContentDocumentLink). UI shows **Files (2)**, and **no delete icon** for the current admin user → confirms the gap.

## Proposed approach

1. **New custom permission** `IM_Initiative_Final_Docs_Delete` ("IM: Initiative Final Docs File Delete") — the dedicated gate for the Final Docs delete icon.
2. **New permission set** `IM: Final Doc Tab Delete Access` (`IM_Final_Doc_Tab_Delete_Access`) that:
   - enables custom permission `IM_Initiative_Final_Docs_Delete`, and
   - carries the object/field grants delete needs (File_Link__c delete; ContentDocument delete comes from standard Files perms + `File_Group_Edit_Access` group membership per `getPermissions` step 1).
   - Assign to **Kelly Mehlenbacher** and **Sara Ginsberg** (Super Users). Optionally add it into the `IM_Admin` group if full admins should also delete — *open decision #1*.
3. **fileGroup LWC** — extend the permission logic so the Final Docs delete column appears only for holders of the new permission, without changing Add/Files behavior for everyone else.
4. **Flexipage** — flip `showDeleteButton` to `true` on `c_fileGroup4` (Final Docs) so the delete column is allowed to render (it remains hidden for anyone without the new permission).

## Changes

### 1. New custom permission
`force-app/main/default/customPermissions/IM_Initiative_Final_Docs_Delete.customPermission-meta.xml`
- label `IM: Initiative Final Docs Delete`, description `BRME-6989: Grants delete of files in the Initiative Final Docs section (BIM Super Users/Admins).`

### 2. New permission set
`force-app/main/default/permissionsets/IM_Final_Doc_Tab_Delete_Access.permissionset-meta.xml`
- label `IM: Final Doc Tab Delete Access`, description `BRME-6989: Delete access for Final Docs Files section.`
- `<customPermissions>` → `IM_Initiative_Final_Docs_Delete` (enabled), and keep `IM_Initiative_Final_Docs_FileGroup` + `IM_Final_Doc_Tab_Access` enabled so holders keep tab/edit visibility.
- Object/FLS: mirror the delete-relevant grants from [File_Group_Edit_Access](force-app/main/default/permissionsets/File_Group_Edit_Access.permissionset-meta.xml) (File_Group__c, File_Link__c create/read/edit/delete) so `deleteFile` on a File_Link succeeds.

### 3. fileGroup LWC — permission-gated delete
[fileGroup.js](force-app/main/default/lwc/fileGroup/fileGroup.js):
- Add `@api deletePermission` (String, optional) so the Final Docs instance can pass `IM_Initiative_Final_Docs_Delete` separately from the edit `customPermission`.
- New `@salesforce/apex/FileGroupController.canDeleteFiles` import.
- In `applyPermission()` (and the deleted-row refresh path), append the `delete` column only when `showDeleteButton && canDelete === true`, independent of `displayReadMode` (so Admins/Super Users get delete even while others are read-only).

[fileGroup.js-meta.xml](force-app/main/default/lwc/fileGroup/fileGroup.js-meta.xml): add `deletePermission` String property (optional).

### 4. FileGroupController — enforce + expose the check
[FileGroupController.cls](force-app/main/default/classes/FileGroupController.cls):
- New `@AuraEnabled(cacheable=true) public static Boolean canDeleteFiles(String customPermission)` → `FeatureManagement.checkPermission(customPermission)` (returns false for blank).
- **Hardening (recommended):** add a permission guard inside `deleteFile` — today it has **no server-side check** and runs in SYSTEM_MODE. Accept an optional `deletePermission` and `assertDeleteAccess()` (mirror `assertFileGroupAccess` pattern) so direct Apex/JS calls can't bypass the UI gate. *Open decision #2 — whether to include hardening in this ticket or a follow-up.*

[FileGroupControllerTest.cls](force-app/main/default/classes/FileGroupControllerTest.cls): add tests — user **with** `IM_Initiative_Final_Docs_Delete` gets `canDeleteFiles = true` and delete succeeds; user **without** it gets false / delete blocked (if hardening is in).

### 5. Flexipage — enable delete on Final Docs
[IM_Budgeted_Initiative_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml#L2974-L2997) `c_fileGroup4`:
- `showDeleteButton` → `true`
- add `<componentInstanceProperties><name>deletePermission</name><value>IM_Initiative_Final_Docs_Delete</value></componentInstanceProperties>`

### 6. Manifest
[manifest/package.xml](manifest/package.xml): add `CustomPermission: IM_Initiative_Final_Docs_Delete`, `PermissionSet: IM_Final_Doc_Tab_Delete_Access`; confirm `LightningComponentBundle: fileGroup`, `FlexiPage: IM_Budgeted_Initiative_Page`, `ApexClass: FileGroupController/FileGroupControllerTest` are covered.

## Org assignment (post-deploy, manual or scripted)
Assign `IM: Final Doc Tab Delete Access` to **Kelly Mehlenbacher** (`0054v00000FUkMcAAL`) and **Sara Ginsberg** (`0056g000002O6LtAAK`). (Confirm these are the intended Kelly/Sara — see open decision #3.)

## Open decisions

1. **Scope of delete:** only the 2 Super Users, or all 18 IM_Admin group members? AC says "BIM Super Users" — plan targets a dedicated permission set assigned to Kelly + Sara. If admins should also delete, add the new permission set into the `IM_Admin` group instead of individual assignment.
2. **Server-side hardening of `deleteFile`:** include in BRME-6989 (adds an Apex permission assert) or defer? Recommend including, since delete currently has no server-side gate.
3. **Which Kelly/Sara:** several Kellys (Henning, Mehlenbacher, Sullivan, Larson, Shultz) and Saras (Ginsberg, Singletary, Goggin, Shoener…) exist. Plan assumes **Kelly Mehlenbacher** and **Sara Ginsberg** (both in IM_Admin). Confirm with the requester.
4. **File link vs file:** confirm delete should cover both uploaded files (`ContentDocument`) and any `File_Link__c` rows in the Final Docs group (Private Docs pattern deletes both).

## Verification
1. Dry-run deploy + verify via org `DeployRequest` (Tooling API), per deploy workflow.
2. Run `FileGroupControllerTest` (RunSpecifiedTests) — must pass with the new tests.
3. On `a0qbc00000HmnW5AAJ` → Final Docs:
   - As **Kelly/Sara** (with new perm set): delete icon visible → delete `BRME-6989-Test-Budget-Narrative.pdf` → confirm removed from `a0Gbc000009zEIbEAM` (ContentDocumentLink gone).
   - As a **non-super-user** (no new perm set): no delete icon; Add Files still works as before.
4. Confirm `Files (n)` count and refresh update after delete.

## Out of scope
- No change to Private Docs delete (already on).
- No change to `IM_Final_Doc_Tab_Access` tab gating.
- No page-layout change (section is an LWC on the flexipage).
