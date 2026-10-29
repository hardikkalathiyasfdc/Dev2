// BRME-5632: generates a SAMPLE expected error-report workbook into ../sample-report/
// This is a hand-authored sample (NOT actual execution output) to agree the layout.
// Layout per ticket: A1 = original filename; row 2 blank; row 3 = table headers; data from row 4.
// Run:  node BRME-5632/tooling/make-sample-report.js
const fs = require('fs');
const path = require('path');
const XLSX = require(path.join(__dirname, '..', '..', 'BRME-7012', 'tooling', 'node_modules', 'xlsx'));

const FILENAME = 'BRME-5632-s3-mixed.xlsx';
// Original upload columns (32-col DIT template) — order preserved.
const UPLOAD_HEADERS = ['Salutation', 'First Name', 'Middle Name', 'Last Name', 'Suffix', 'Preferred First Name', 'Title', 'Organization Name', 'Business Email', 'Personal Email', 'Additional Email', 'Business Phone (Country Code)', 'Business Phone', 'Mobile Phone (Country Code)', 'Mobile Phone', 'Additional Phone (Country Code)', 'Additional Phone', 'Business Street Address 1', 'Business Street Address 2', 'Business Street Address 3', 'Business City', 'Business State', 'Business Postal Code', 'Business Country', 'Home Street Line1', 'Home Street Line2', 'Home Street Line3', 'Home City', 'Home State', 'Home Postal Code', 'Home Country', 'Notes '];

// Column order: [Error - Please Review] + [all upload columns] + [Contact ID 18] + [List Member ID 18] + [List ID 18]
const HEADERS = ['Error - Please Review'].concat(UPLOAD_HEADERS).concat(['Contact ID 18', 'List Member ID 18', 'List ID 18']);

// Sample: only the FAILING row appears (Gina succeeded -> excluded). Hank failed the phone-country-code validation.
// Failed field value (Business Phone) is highlighted red. Contact/ListMember/List IDs blank (create rolled back).
function hankRow() {
    const r = new Array(UPLOAD_HEADERS.length).fill('');
    r[1] = 'Hank'; r[3] = 'BRME5632Bad'; r[7] = 'BRME5632 Org'; r[8] = 'hank.brme5632@brme5632.invalid'; r[12] = '212-555-0100';
    return r;
}
const errMsg = 'Contact could not be created: Business Phone (Country Code) must be populated. Add a Business Phone (Country Code) for this value, or clear Business Phone. If unsure, contact bpsalesforceteam@e.bloomberg.org.';
const dataRow = [errMsg].concat(hankRow()).concat(['', '', '']); // IDs blank (create rolled back)

// Build sheet with A1 filename, row2 blank, row3 headers, row4 data.
const ws = {};
ws['A1'] = { v: FILENAME, t: 's' };
HEADERS.forEach((h, c) => { ws[XLSX.utils.encode_cell({ r: 2, c })] = { v: h, t: 's' }; }); // r:2 = row 3
dataRow.forEach((v, c) => {
    const cell = { v, t: 's' };
    // Highlight the failed field value (Business Phone, upload col index 12 -> report col index 1+12=13) red.
    if (c === 13) cell.s = { fill: { fgColor: { rgb: 'FFFF0000' } }, font: { color: { rgb: 'FFFFFFFF' } } };
    ws[XLSX.utils.encode_cell({ r: 3, c })] = cell; // r:3 = row 4
});
ws['!ref'] = XLSX.utils.encode_range({ s: { r: 0, c: 0 }, e: { r: 3, c: HEADERS.length - 1 } });

const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws, SHEET_NAME = 'Import Errors');
const outDir = path.join(__dirname, '..', 'sample-report');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
const out = XLSX.write(wb, { bookType: 'xlsx', type: 'buffer', bookSST: true });
fs.writeFileSync(path.join(outDir, 'BRME-5632-sample-error-report.xlsx'), out);
console.log('WROTE sample report (' + out.length + ' bytes)');

// verify
const r = XLSX.read(out, { type: 'buffer' });
const s = r.Sheets[r.SheetNames[0]];
console.log('A1 =', s['A1'] ? s['A1'].v : '(empty)');
console.log('Row2 blank? A2 =', s['A2'] ? s['A2'].v : '(blank)');
console.log('Header row3 A3 =', s['A3'] ? s['A3'].v : '(blank)');
console.log('Data row4 A4 =', s['A4'] ? s['A4'].v : '(blank)');
