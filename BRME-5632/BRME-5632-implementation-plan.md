# BRME-5632 — DIT Import Error Report (Excel) + Email Notification

**Ticket:** DIT Import — make all import errors available in a clear, actionable Excel report; notify the importing user by email with the report attached.

**Status:** Implemented, deployed to `dev2Current`, and verified end-to-end (import → download → record attachment → email). 19/19 tests green.

---

## Final implementation (2026-10-23)

**Changed components** (all carry `BRME-5632` comments):

1. [DITCmpController.cls](force-app/main/default/classes/DITCmpController.cls)
   - `saveWithRowErrors(srList, inputRecords, wrappers, operation)` — structured per-row error maps `{operation, statusCode, message, fields, recordId, rowId, rowIndex, excelRow}`. `excelRow` is the row's stored `Excel_Row__c` JSON (queried by failed-row Id) so the report always has every original DIT column.
   - `upsertContactsList` — captures create + update errors into `resultMap.rowErrors`.
   - `upsertMemberRecordsWithErrors` — member upsert returning `{successCount, rowErrors}` (member errors were previously swallowed).
   - `saveErrorReport(dataLoadId, fileName, base64Data)` — decodes the report once, persists it as a `ContentVersion` on the `Data_Load__c`, then sends the email (best-effort) with the same bytes attached.
   - `sendErrorReportEmail(fileName, reportBody)` — builds a `SingleEmailMessage` from the `DIT_Import_Errors_Template`, To = importing user only (no CC/BCC), From = org-wide `bpsalesforceteam@e.bloomberg.org` when present, attaches the report. Best-effort: exceptions are logged, never thrown, so the saved file is not rolled back.
   - New constants `ERR_SAVE_ERROR_REPORT`, `ERR_ERROR_REPORT_EMAIL`.
2. [DITCmpHelper.js](force-app/main/default/aura/DITCmp/DITCmpHelper.js) — accumulates `results.rowErrorList` across batches (contact + member); on completion, when non-empty, calls `buildAndSaveErrorReport` → `buildErrorReportWorkbook` (async) → downloads + persists via `saveErrorReport`.
   - **Builder (ExcelJS):** A1 = DIT file name; row 2 blank; row 3 = bold headers; data from row 4. Columns: `Error - Please Review` (plain language) + `Technical Error` (raw `StatusCode: message`) + **all original DIT columns** (order + values from `Excel_Row__c`) + `Contact ID 18` (+ `List Member ID 18` / `List ID 18` only when a list was used). Only errored rows; multiple errors combined per row; values written as text (formula-injection safe).
   - **Highlighting:** the failing field's cell is filled light red (`FFF8CBAD`). Salesforce field API names are mapped to DIT headers with exact-normalized match first, then known aliases, then a guarded prefix match (avoids the earlier off-by-one that highlighted `Title` instead of `First Name`).
3. [DITCmp.cmp](force-app/main/default/aura/DITCmp/DITCmp.cmp) — `ltng:require` now loads `$Resource.ExcelJS + '/unpkg/exceljs.min.js'` (the vendored SheetJS is v0.8.0, a read/community build with no workbook-write/styling API — ExcelJS is the repo's standard for real `.xlsx` with styling).
4. [DITCmpControllerTest.cls](force-app/main/default/classes/DITCmpControllerTest.cls) — `testErrorReport_BRME5632` covers `upsertMemberRecordsWithErrors` + `saveErrorReport`.
5. Email template — [force-app/main/default/email/DIT_Import_Errors_Template.email](force-app/main/default/email/DIT_Import_Errors_Template.email) + `.email-meta.xml` (custom/Aloha, subject **"Action Required: DIT Import Errors Detected"**, `{!User.FirstName}` merge field). Lives in **Unfiled Public Classic Email Templates** (folder is a system/virtual folder — assigned via API, not deployable metadata).
6. [Data_Load__c-Data Load Layout](force-app/main/default/layouts/Data_Load__c-Data Load%20Layout.layout-meta.xml) — added the standard **Files** related list so the attached report is visible/downloadable on the Data Load record page.

**Deployment & tests:** latest `DeployRequest 0Afbc00000DFDzxCAH` — **Succeeded, 0 errors, 19/19 tests**. (sf CLI prints a cosmetic `Missing message metadata.transfer:Finalizing` error on success — verify via `DeployRequest`, not CLI exit code.)

**Verified end-to-end (2026-10-23):**
- Report generates with all 35 columns (2 error + 32 DIT + Contact ID 18), only the failed row, populated values written, empty values blank, failing field highlighted.
- `excelRow present=true len=822` in the Apex log confirms the original row JSON reaches the builder.
- Report downloads in-browser and attaches to the `Data_Load__c` (visible under Related → Files).
- Email queued and sent — log: `EMAIL_QUEUE … toAddresses:[hkalathiya@bloomberg.org] … subject: Action Required: DIT Import Errors Detected` and `email success=true`. (Sandbox org-wide sender emails typically land in the recipient's Junk folder.)

---

## Design decisions / resolved questions (2026-10-23)

1. **Layout rows** — ticket said "Row B"/"Row C"; implemented as A1 filename, row 2 blank, row 3 headers, data from row 4 (flag if Data Team disagrees).
2. **Optional ID columns** — `List Member ID 18` / `List ID 18` appear **only when the import used a list**.
3. **Technical detail retention** — a separate `Technical Error` column holds the raw `StatusCode: message` alongside the plain-language `Error - Please Review`.
4. **Report access** — persisted as a `ContentVersion` on the `Data_Load__c` (re-downloadable + the email attachment) in addition to the immediate browser download.
5. **Email scope** — built and enabled (expanded beyond the ticket's "template only"): To = importing user only, no CC/BCC. Body = template (`{!User.FirstName}` greeting); report attached. From = org-wide `bpsalesforceteam@e.bloomberg.org` (falls back to the running user if no org-wide address exists).
6. **No emails in dev/test beyond the importing user** — confirmed: nothing is CC'd/BCC'd to `bpsalesforceteam@e.bloomberg.org`; that address is only the sender. Production recipient list is contingent on Data Team approval.

## Assumptions

- The report is produced client-side (ExcelJS) and also persisted via `ContentVersion` so it can be attached to the email and re-downloaded.
- The validation failure used for testing is a 45-char First Name (passes the 50-char Preview/DLR check, fails the 40-char Contact field → `STRING_TOO_LONG`) at the Import stage.
- Rollback: no git in the workspace — re-deploy retrieved copies from `other-org/retrieve-brme5632-rollback/`.

**BRME-7012 / 4425 / 6786 / 6993:** untouched by this change.

**Org:** `dev2Current` → `https://bbrm--dev2.sandbox.my.salesforce.com` (sandbox).
