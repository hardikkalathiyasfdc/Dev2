// BRME-4862: generates a DIT-compatible .xlsx with a controlled mix of error types.
// Reuses the npm `xlsx` package vendored in BRME-7012/tooling/node_modules (no fresh install).
// Run:  node BRME-4862/tooling/make-mixed-errors.js
const fs = require('fs');
const path = require('path');
const XLSX = require(path.resolve(__dirname, '..', '..', 'BRME-7012', 'tooling', 'node_modules', 'xlsx'));

// Column headers matching DIT field labels (from Data_Import_Fields field set).
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
// Country-code fields are RESTRICTED picklists; must use a valid entry, not a bare "1".
const CODE = 'United States(+1)';
const PHONE = '2125550100';

// Error types
const E_LAST = 'missingLastName';        // blank Last Name
const E_MOBILE = 'mobileNoCode';         // Mobile Phone set, Mobile Phone (Country Code) blank
const E_BIZ = 'bizPhoneNoCode';          // Business Phone set, Business Phone (Country Code) blank
const E_ADD = 'addPhoneNoCode';          // Additional Phone set, Additional Phone (Country Code) blank
const E_BIZEM = 'bizEmailBad';           // Business Email malformed
const E_PERSEM = 'persEmailBad';         // Personal Email malformed
const E_ADDEM = 'addEmailBad';           // Additional Email malformed

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
        case E_LAST: r[COL['Last Name']] = ''; break;
        case E_MOBILE: r[COL['Mobile Phone (Country Code)']] = ''; break;
        case E_BIZ: r[COL['Business Phone (Country Code)']] = ''; break;
        case E_ADD: r[COL['Additional Phone (Country Code)']] = ''; break;
        case E_BIZEM: r[COL['Business Email']] = 'tuser' + n + '-not-an-email'; break;
        case E_PERSEM: r[COL['Personal Email']] = 'personal' + n + '@'; break;
        case E_ADDEM: r[COL['Additional Email']] = 'add' + n + '@nodot'; break;
    }
    return r;
}

// Requested distribution
const PLAN = [
    [E_LAST, 50],
    [E_MOBILE, 25],
    [E_BIZ, 25],
    [E_ADD, 25],
    [E_BIZEM, 25],
    [E_PERSEM, 25],
    [E_ADDEM, 25]
];

const rows = [];
let n = 0;
const counts = {};
for (const [type, count] of PLAN) {
    for (let i = 0; i < count; i++) {
        n++;
        rows.push(applyError(baseRow(n), n, type));
        counts[type] = (counts[type] || 0) + 1;
    }
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
const fileName = 'BRME-4862-mixed-errors-200rows.xlsx';
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, buildSheet(rows), SHEET_NAME);
const out = XLSX.write(wb, { bookType: 'xlsx', type: 'buffer' });
fs.writeFileSync(path.join(outDir, fileName), out);

console.log('WROTE ' + fileName + ' (' + out.length + ' bytes) rows=' + rows.length);
console.log('COUNTS ' + JSON.stringify(counts));

// Verification pass: re-read and re-count by inspecting cell values.
const wb2 = XLSX.read(fs.readFileSync(path.join(outDir, fileName)), { type: 'buffer' });
const data = XLSX.utils.sheet_to_row_object_array(wb2.Sheets[wb2.SheetNames[0]]);
let v = { missingLast: 0, mobileNoCode: 0, bizNoCode: 0, addNoCode: 0, bizEmailBad: 0, persEmailBad: 0, addEmailBad: 0 };
const emailRe = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
for (const r of data) {
    if (!r['Last Name']) v.missingLast++;
    if (r['Mobile Phone'] && !r['Mobile Phone (Country Code)']) v.mobileNoCode++;
    if (r['Business Phone'] && !r['Business Phone (Country Code)']) v.bizNoCode++;
    if (r['Additional Phone'] && !r['Additional Phone (Country Code)']) v.addNoCode++;
    if (r['Business Email'] && !emailRe.test(r['Business Email'])) v.bizEmailBad++;
    if (r['Personal Email'] && !emailRe.test(r['Personal Email'])) v.persEmailBad++;
    if (r['Additional Email'] && !emailRe.test(r['Additional Email'])) v.addEmailBad++;
}
console.log('VERIFY ' + JSON.stringify(v));
