// BRME-4862: generates a DIT-compatible .xlsx where EVERY row has an error (200/200).
// Mixes the supported error types so Preview renders 200 error rows.
// Reuses the npm `xlsx` package vendored in BRME-7012/tooling/node_modules (no fresh install).
// Run:  node BRME-4862/tooling/make-200-errors.js
const fs = require('fs');
const path = require('path');
const XLSX = require(path.resolve(__dirname, '..', '..', 'BRME-7012', 'tooling', 'node_modules', 'xlsx'));

const HEADERS = [
    'First Name', 'Last Name', 'Preferred First Name', 'Title', 'Organization Name',
    'Business Email', 'Personal Email', 'Additional Email',
    'Business Phone', 'Business Phone (Country Code)',
    'Mobile Phone', 'Mobile Phone (Country Code)',
    'Additional Phone', 'Additional Phone (Country Code)',
    'Source', 'RSVP', 'Attendance', 'List Member Notes'
];
const COL = {};
HEADERS.forEach((h, i) => { COL[h] = i; });

const SHEET_NAME = 'Sheet1';
const ORG = 'BRME5632 Org A';
const CODE = 'United States(+1)';   // valid restricted-picklist entry
const PHONE = '2125550100';

// Cycle through error types so all appear across the 200 rows.
const TYPES = ['missingLastName', 'bizNoCode', 'mobileNoCode', 'addNoCode', 'bizEmailBad', 'persEmailBad', 'addEmailBad'];

function baseRow(n) {
    const r = new Array(HEADERS.length).fill('');
    r[COL['First Name']] = 'Test' + n;
    r[COL['Last Name']] = 'User' + n;
    r[COL['Organization Name']] = ORG;
    r[COL['Business Email']] = 'tuser' + n + '@example.com';
    r[COL['Business Phone']] = PHONE;
    r[COL['Business Phone (Country Code)']] = CODE;
    r[COL['Mobile Phone']] = '9175550100';
    r[COL['Mobile Phone (Country Code)']] = CODE;
    r[COL['Additional Phone']] = '6465550100';
    r[COL['Additional Phone (Country Code)']] = CODE;
    return r;
}

function applyError(r, n, type) {
    switch (type) {
        case 'missingLastName': r[COL['Last Name']] = ''; break;
        case 'bizNoCode': r[COL['Business Phone (Country Code)']] = ''; break;
        case 'mobileNoCode': r[COL['Mobile Phone (Country Code)']] = ''; break;
        case 'addNoCode': r[COL['Additional Phone (Country Code)']] = ''; break;
        case 'bizEmailBad': r[COL['Business Email']] = 'tuser' + n + '-not-an-email'; break;
        case 'persEmailBad': r[COL['Personal Email']] = 'personal' + n + '@'; break;
        case 'addEmailBad': r[COL['Additional Email']] = 'add' + n + '@nodot'; break;
    }
    return r;
}

const TOTAL = 200;
const rows = [];
const counts = {};
for (let i = 1; i <= TOTAL; i++) {
    const type = TYPES[(i - 1) % TYPES.length];
    rows.push(applyError(baseRow(i), i, type));
    counts[type] = (counts[type] || 0) + 1;
}

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
const fileName = 'BRME-4862-200rows-all-errors.xlsx';
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, buildSheet(rows), SHEET_NAME);
const out = XLSX.write(wb, { bookType: 'xlsx', type: 'buffer' });
fs.writeFileSync(path.join(outDir, fileName), out);

console.log('WROTE ' + fileName + ' (' + out.length + ' bytes) rows=' + rows.length);
console.log('COUNTS ' + JSON.stringify(counts));

// Verification pass: count rows that carry at least one error.
const wb2 = XLSX.read(fs.readFileSync(path.join(outDir, fileName)), { type: 'buffer' });
const data = XLSX.utils.sheet_to_row_object_array(wb2.Sheets[wb2.SheetNames[0]]);
const emailRe = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
let errorRows = 0;
for (const r of data) {
    const err =
        !r['Last Name'] ||
        (r['Business Phone'] && !r['Business Phone (Country Code)']) ||
        (r['Mobile Phone'] && !r['Mobile Phone (Country Code)']) ||
        (r['Additional Phone'] && !r['Additional Phone (Country Code)']) ||
        (r['Business Email'] && !emailRe.test(r['Business Email'])) ||
        (r['Personal Email'] && !emailRe.test(r['Personal Email'])) ||
        (r['Additional Email'] && !emailRe.test(r['Additional Email']));
    if (err) errorRows++;
}
console.log('ERROR_ROWS=' + errorRows + ' / ' + data.length);
