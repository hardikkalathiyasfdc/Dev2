# BRME-5632 — DIT Import error report

Phase 1 package: investigation, synthetic baseline data, DIT upload workbooks, sample report, email-template draft.

> **Make all DIT import errors available in a clear, actionable Excel report (+ a reusable email template; no email delivery).**

- Plan: [BRME-5632-implementation-plan.md](BRME-5632-implementation-plan.md)
- Record IDs: [setup/record-manifest.md](setup/record-manifest.md)
- Org: **dev2Current** sandbox — DIT at `https://bbrm--dev2.sandbox.lightning.force.com/lightning/n/Data_Import2`.

## 1. Record setup (already done — 2026-10-23)

| ID | Type | Name | Purpose |
|---|---|---|---|
| `001bc00000klnxKAAQ` | Account | BRME5632 Org | Org to link |
| `003bc000018Lgf3AAC` | Contact | Owen BRME5632Update | Update-blocked scenario |
| `701bc00000klnxLAAQ` | Campaign | BRME5632 List | List-member scenarios |

The reproducible failure needs no record: Business Phone populated + Business Phone (Country Code) blank → validation rule `Office_Phone_Country_Code` blocks the save (verified).

## 2. DIT upload files

In [test-data/](test-data/) — `.xlsx`, sheet `Sheet1`, 32-col DIT template.

| File | Row(s) | Expected today |
|---|---|---|
| `BRME-5632-s1-create-blocked.xlsx` | Carl (phone, no country code) | create fails: "Business Phone (Country Code) must be populated." |
| `BRME-5632-s2-update-blocked.xlsx` | Owen (update, phone, no code) | update fails (same rule) |
| `BRME-5632-s3-mixed.xlsx` | Gina (valid) + Hank (fails) | 1 succeeds, 1 fails |
| `BRME-5632-s6-success.xlsx` | Ivy (valid) | fully succeeds (regression control) |

To regenerate: `node BRME-5632/tooling/make-xlsx.js`.

## 3. Upload / mapping steps (baseline)

1. DIT → **Upload File** → choose workbook → Next.
2. **Map Columns** → verify First/Last Name, Organization Name, Business Email, Business Phone, Business Phone (Country Code) mapped → Next.
3. **Preview** → **Review Errors** → resolve org → Next → **Compare Potential Duplicates** → Confirm/Create as needed → **Import**.
4. On Import, note the current error display (a single run-on toast; nothing persisted, no per-row detail).

## 4. Baseline (current) behavior

- Errors appear only in a transient toast (concatenated, no row identity), then gone; confetti still fires.
- List-member failures are silently discarded.
- No report is produced.

## 5. Expected after the fix

- A **Download error report** option on Import completion producing a real `.xlsx`: A1 = filename, row 2 blank, row 3 headers (`Error - Please Review` + original columns + Contact/List Member/List IDs), failed field values highlighted red.
- Only error rows; multiple errors per row combined; honest partial-success wording; valid 18-char IDs where known.
- Fully successful import → no error report/notification.
- Email template exists but **no email is sent** (delivery out of scope, pending Data Team approval).

## 6. Sample + email draft

- Sample report (layout demo): [sample-report/BRME-5632-sample-error-report.xlsx](sample-report/BRME-5632-sample-error-report.xlsx)
- Email template draft: [email-template/](email-template/)

## 7. Cleanup

1. Delete test Data_Load__c records (cascade).
2. `sf apex run -o dev2Current -f BRME-5632/setup/brme5632-cleanup.apex` (deletes only BRME5632-named records).
3. Delete any Contacts/CampaignMembers created by an Import run during testing.

## 8. Artifacts

- Generators: [tooling/make-xlsx.js](tooling/make-xlsx.js), [tooling/make-sample-report.js](tooling/make-sample-report.js)
- Setup/probe: [setup/brme5632-create-baseline.apex](setup/brme5632-create-baseline.apex), [setup/brme5632-probe.apex](setup/brme5632-probe.apex)
