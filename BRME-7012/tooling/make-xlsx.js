// BRME-7012: generates the DIT-compatible .xlsx test workbooks into ../test-data/
// Uses the npm `xlsx` package (installed in this folder via `npm install`).
// Run:  node BRME-7012/tooling/make-xlsx.js
const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

// Exact 32-column DIT template, mirrored from the user's real file
// "C:\Users\Hardik\Downloads\Preferred First Name DIT Test.xlsx" (sheet "Sheet1", 2026-10-23).
// Header order/labels match the DIT auto-map (field labels; "Notes " keeps its trailing space).
const HEADERS = ['Salutation', 'First Name', 'Middle Name', 'Last Name', 'Suffix', 'Preferred First Name', 'Title', 'Company', 'Business Email', 'Personal Email', 'Additional Email', 'Business Phone (Country Code)', 'Business Phone', 'Mobile Phone (Country Code)', 'Mobile Phone', 'Additional Phone (Country Code)', 'Additional Phone', 'Business Street Address 1', 'Business Street Address 2', 'Business Street Address 3', 'Business City', 'Business State', 'Business Postal Code', 'Business Country', 'Home Street Line1', 'Home Street Line2', 'Home Street Line3', 'Home City', 'Home State', 'Home Postal Code', 'Home Country', 'Notes '];
const SHEET_NAME = 'Sheet1';
const COL = { FIRST: 1, LAST: 3, PREF: 5, EMAIL: 8 };

function makeRow(firstName, lastName, preferredFirstName, businessEmail) {
    const row = new Array(HEADERS.length).fill('');
    row[COL.FIRST] = firstName;
    row[COL.LAST] = lastName;
    row[COL.PREF] = preferredFirstName;
    row[COL.EMAIL] = businessEmail;
    return row;
}

const WORKBOOKS = {
    // 1. Single-row preferred-name reproduction:
    //    existing Contact Patricia BRME7012Test (Preferred First Name = Patti) must be flagged
    //    even though the row has no email. Exact-name Contact Patti BRME7012Test must also remain.
    'BRME-7012-single-row-preferred-name.xlsx': [
        makeRow('Patti', 'BRME7012Test', '', '')
    ],
    // 2. Two-row reproduction of the reported clue:
    //    row 1 no email, row 2 email = Patricia's Business Email.
    'BRME-7012-two-row-email-clue.xlsx': [
        makeRow('Patti', 'BRME7012Test', '', ''),
        makeRow('Patti', 'BRME7012Test', '', 'patricia.brme7012@brme7012.invalid')
    ],
    // 3. Regression scenarios (see README for expected candidates per row).
    'BRME-7012-regression.xlsx': [
        makeRow('Patti', 'BRME7012Test', '', ''),                                       // R1 preferred-name + exact-name candidates
        makeRow('PATTI', 'BRME7012Test', '', ''),                                       // R2 case-insensitivity probe
        makeRow('Patti', 'BRME7012Nomatch', '', ''),                                    // R3 negative: no last-name match, no email
        makeRow('Randall', 'BRME7012Email', '', 'randy.alt.brme7012@brme7012.invalid'), // R4 email regression (matches Alternate Email)
        makeRow('Bob', 'BRME7012Test', '', ''),                                         // R5 exact-name, existing Contact has blank Preferred First Name
        makeRow('Patti ', 'BRME7012Test', '', '')                                       // R6 whitespace probe (trailing space in First Name)
    ]
};

function buildSheet(rows) {
    const all = [HEADERS].concat(rows);
    const ws = {};
    let maxCol = 0;
    let maxRow = all.length;
    for (let r = 0; r < all.length; r++) {
        for (let c = 0; c < all[r].length; c++) {
            const addr = XLSX.utils.encode_cell({ r: r, c: c });
            ws[addr] = { v: all[r][c], t: 's' };
            if (c > maxCol) maxCol = c;
        }
    }
    ws['!ref'] = XLSX.utils.encode_range({ s: { r: 0, c: 0 }, e: { r: maxRow - 1, c: maxCol } });
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

// Self-check: parse each file back the same way DITLoadCmp does (first sheet, row object array).
for (const fileName of Object.keys(WORKBOOKS)) {
    const wb = XLSX.read(fs.readFileSync(path.join(outDir, fileName)), { type: 'buffer' });
    const sheet = wb.Sheets[wb.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_row_object_array(sheet);
    console.log('VERIFY ' + fileName + ' -> ' + JSON.stringify(rows));
}
