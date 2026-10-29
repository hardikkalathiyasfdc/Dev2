# BRME-6993 — DIT Compare: warn on different Organization from Excel

Phase 1 package: investigation, synthetic baseline data, DIT upload workbooks, reproduction steps.

> **Warn on Confirm when a different Excel organization is selected; conditionally highlight Business Email/Phone/Address ("(NEW)"); add editable "Use Same Address as Organization" checkbox.**

- Plan: [BRME-6993-implementation-plan.md](BRME-6993-implementation-plan.md)
- Record IDs: [setup/record-manifest.md](setup/record-manifest.md)
- Org: **dev2Current** sandbox — DIT at `https://bbrm--dev2.sandbox.lightning.force.com/lightning/n/Data_Import2`.

## 1. Record setup (already done — 2026-10-23)

**Accounts:** `001bc00000kkfowAAA` = **BRME6993 Org A** (BRM, on the contacts) · `001bc00000kkfoxAAA` = **BRME6993 Org B** (the "different" Excel org).

**Contacts (all on Org A):**

| ID | Name | Email | Phone | Address | Same-Addr checkbox | Scenario |
|---|---|---|---|---|---|---|
| `003bc000018L8YYAA0` | Fiona BRME6993Full | ✓ | ✓ | ✓ | false | S1 |
| `003bc000018L8YZAA0` | Theo BRME6993ChkTrue | ✓ | ✓ | ✓ | true | S2 |
| `003bc000018KoOdAAK` | Paula BRME6993Partial | ✓ | — | — | false | S3 |
| `003bc000018KoOeAAK` | Adam BRME6993AddrOnly | — | — | ✓ | false | S3 |
| `003bc000018KoOfAAK` | Bianca BRME6993Bare | — | — | — | false | S3 |

## 2. DIT upload files

In [test-data/](test-data/) — `.xlsx`, sheet `Sheet1`, 32-col DIT template; org under the **Organization Name** header (auto-maps).

| File | Row(s) | Purpose |
|---|---|---|
| `BRME-6993-s1-diffOrg-full-chkFalse.xlsx` | Fiona / Org B | different org; all BRM fields populated; chk=false → warn + all 3 highlighted |
| `BRME-6993-s2-diffOrg-chkTrue.xlsx` | Theo / Org B | chk=true → address NOT highlighted |
| `BRME-6993-s3-partial-fields.xlsx` | Paula/Adam/Bianca / Org B | independent field-population conditions |
| `BRME-6993-s4-sameOrg.xlsx` | Fiona / Org A | same org → no warning |
| `BRME-6993-s5-keepBrm.xlsx` | Theo / Org B | Excel has Org B but user keeps BRM org → no warning |
| `BRME-6993-s9-checkbox.xlsx` | Fiona / Org B | toggle the new checkbox; verify saved Contact + address |

To regenerate: `node BRME-6993/tooling/make-xlsx.js`.

## 3. Upload / mapping steps

1. DIT → **Upload File** → choose workbook → Next.
2. **Map Columns** → verify First/Last Name + Organization Name (+ Business Email/Phone/address where present) mapped → Next.
3. **Preview** → Next. **Review Errors** → resolve any org mapping (org names resolve to the baseline Accounts) → Next.
4. **Compare Potential Duplicates** → the row matches the baseline contact by name+email → select the **Excel** Organization Name radio, then **Confirm**.

## 4. Baseline (current, pre-change) behavior

- Selecting a different Excel org and clicking **Confirm** completes immediately — **no warning**.
- No yellow "(NEW)" highlighting tied to org change.
- No **Use Same Address as Organization** control on the Compare stage.

## 5. Expected after the fix

- Confirm with a different Excel org → modal: **"Please review and update highlighted fields related to this change."** (Continue / Go Back).
- Business Email/Phone/Address highlighted + "(NEW)" per the BRM-population + checkbox conditions.
- The checkbox is editable in the Excel column and its value saves correctly (with checkbox=true + org change, the contact inherits the new org's address on save).
- Same org / keep-BRM / org not Excel-selected → no warning.

## 6. Cleanup

1. Delete test Data_Load__c records (cascades).
2. `sf apex run -o dev2Current -f BRME-6993/setup/brme6993-cleanup.apex` (deletes only the manifest Contacts + Accounts).
3. Other tickets' records untouched.

## 7. Artifacts

- Generator: [tooling/make-xlsx.js](tooling/make-xlsx.js)
- Setup: [setup/brme6993-create-baseline.apex](setup/brme6993-create-baseline.apex), [setup/brme6993-create-missing.apex](setup/brme6993-create-missing.apex)
