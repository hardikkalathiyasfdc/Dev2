// BRME-5632: generates DIT-compatible .xlsx test workbooks into ../test-data/
// Uses the npm `xlsx` package installed in BRME-7012/tooling/node_modules.
// Run:  node BRME-5632/tooling/make-xlsx.js
const fs = require('fs');
const path = require('path');
const XLSX = require(path.join(__dirname, '..', '..', 'BRME-7012', 'tooling', 'node_modules', 'xlsx'));

// 32-column DIT template (same as prior tickets). Indexes: First=1, Last=3, Org=7, Email=8, Phone=12.
const HEADERS = ['Salutation', 'First Name', 'Middle Name', 'Last Name', 'Suffix', 'Preferred First Name', 'Title', 'Organization Name', 'Business Email', 'Personal Email', 'Additional Email', 'Business Phone (Country Code)', 'Business Phone', 'Mobile Phone (Country Code)', 'Mobile Phone', 'Additional Phone (Country Code)', 'Additional Phone', 'Business Street Address 1', 'Business Street Address 2', 'Business Street Address 3', 'Business City', 'Business State', 'Business Postal Code', 'Business Country', 'Home Street Line1', 'Home Street Line2', 'Home Street Line3', 'Home City', 'Home State', 'Home Postal Code', 'Home Country', 'Notes '];
const SHEET_NAME = 'Sheet1';
const COL = { FIRST: 1, LAST: 3, ORG: 7, EMAIL: 8, PHONE_CODE: 11, PHONE: 12 };

function row(first, last, org, email, opts) {
    const r = new Array(HEADERS.length).fill('');
    r[COL.FIRST] = first; r[COL.LAST] = last; r[COL.ORG] = org; r[COL.EMAIL] = email;
    if (opts && opts.phone) r[COL.PHONE] = opts.phone;           // Business Phone
    if (opts && opts.phoneCode) r[COL.PHONE_CODE] = opts.phoneCode; // Business Phone (Country Code)
    return r;
}
const ORG = 'BRME5632 Org';

// A reproducible Contact save failure: Business Phone populated WITHOUT Business Phone (Country Code)
// -> active validation rule Office_Phone_Country_Code blocks the save.
const PHONE_ONLY = { phone: '212-555-0100' };            // no country code => validation failure
const PHONE_OK   = { phone: '212-555-0100', phoneCode: 'United States(+1)' }; // valid

const WORKBOOKS = {
    // Import-stage failure: First Name 45 chars — passes Preview (DLR First_Name__c max 50) but fails the
    // server Contact insert (Contact.FirstName max 40 -> STRING_TOO_LONG). Good contrast vs a valid row.
    'BRME-5632-s1-create-blocked.xlsx': [
        row('ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRS', 'BRME5632Create', ORG, 'carl.brme5632@brme5632.invalid', PHONE_OK) // 45-char first name
    ],
    // Update-blocked: same over-long first name applied to the existing contact (Owen) via an update.
    'BRME-5632-s2-update-blocked.xlsx': [
        row('ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRS', 'BRME5632Update', ORG, 'owen.brme5632@brme5632.invalid', PHONE_OK)
    ],
    // Mixed: one valid (Gina) + one failing (over-long first name).
    'BRME-5632-s3-mixed.xlsx': [
        row('Gina', 'BRME5632Good', ORG, 'gina.brme5632@brme5632.invalid', PHONE_OK),
        row('ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRS', 'BRME5632Bad', ORG, 'hank.brme5632@brme5632.invalid', PHONE_OK)
    ],
    // Fully successful import (regression control).
    'BRME-5632-s6-success.xlsx': [row('Ivy', 'BRME5632Success', ORG, 'ivy.brme5632@brme5632.invalid', PHONE_OK)]
};

function buildSheet(rows) {
    const all = [HEADERS].concat(rows);
    const ws = {};
    let maxCol = 0;
    for (let r = 0; r < all.length; r++) {
        for (let c = 0; c < all[r].length; c++) {
            ws[XLSX.utils.encode_cell({ r, c })] = { v: all[r][c], t: 's' };
            if (c > maxCol) maxCol = c;
        }
    }
    ws['!ref'] = XLSX.utils.encode_range({ s: { r: 0, c: 0 }, e: { r: all.length - 1, c: maxCol } });
    return ws;
}
const outDir = path.join(__dirname, '..', 'test-data');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
for (const fileName of Object.keys(WORKBOOKS)) {
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, buildSheet(WORKBOOKS[fileName]), SHEET_NAME);
    const out = XLSX.write(wb, { bookType: 'xlsx', type: 'buffer' });
    fs.writeFileSync(path.join(outDir, fileName), out);
    console.log('WROTE ' + fileName + ' (' + out.length + ' bytes)');
}
for (const fileName of Object.keys(WORKBOOKS)) {
    const wb = XLSX.read(fs.readFileSync(path.join(outDir, fileName)), { type: 'buffer' });
    const rows = XLSX.utils.sheet_to_row_object_array(wb.Sheets[wb.SheetNames[0]]);
    console.log('VERIFY ' + fileName + ' -> ' + rows.map(r => r['First Name'] + '|' + r['Last Name'] + '|ph=' + r['Business Phone'] + '|code=' + r['Business Phone (Country Code)']).join('  ;  '));
}
