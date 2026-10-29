// BRME-4425: generates the DIT-compatible .xlsx test workbooks into ../test-data/
// Uses the npm `xlsx` package installed in BRME-7012/tooling/node_modules.
// Run:  node BRME-4425/tooling/make-xlsx.js
const fs = require('fs');
const path = require('path');
const XLSX = require(path.join(__dirname, '..', '..', 'BRME-7012', 'tooling', 'node_modules', 'xlsx'));

// Same 32-column DIT template as BRME-7012 (mirrors the real upload file; "Notes " keeps its trailing space).
const HEADERS = ['Salutation', 'First Name', 'Middle Name', 'Last Name', 'Suffix', 'Preferred First Name', 'Title', 'Company', 'Business Email', 'Personal Email', 'Additional Email', 'Business Phone (Country Code)', 'Business Phone', 'Mobile Phone (Country Code)', 'Mobile Phone', 'Additional Phone (Country Code)', 'Additional Phone', 'Business Street Address 1', 'Business Street Address 2', 'Business Street Address 3', 'Business City', 'Business State', 'Business Postal Code', 'Business Country', 'Home Street Line1', 'Home Street Line2', 'Home Street Line3', 'Home City', 'Home State', 'Home Postal Code', 'Home Country', 'Notes '];
const SHEET_NAME = 'Sheet1';
const COL = { FIRST: 1, LAST: 3, EMAIL: 8 };

function makeRow(firstName, lastName, businessEmail) {
    const row = new Array(HEADERS.length).fill('');
    row[COL.FIRST] = firstName;
    row[COL.LAST] = lastName;
    row[COL.EMAIL] = businessEmail;
    return row;
}

const WORKBOOKS = {
    // 1. Three exact matches (First+Last+Business Email equal the baseline contacts) -> all "require no review".
    'BRME-4425-exact-matches.xlsx': [
        makeRow('Alice',   'BRME4425Exact', 'alice.brme4425@brme4425.invalid'),
        makeRow('Brendan', 'BRME4425Exact', 'brendan.brme4425@brme4425.invalid'),
        makeRow('Carla',   'BRME4425Exact', 'carla.brme4425@brme4425.invalid')
    ],
    // 2. Mixed: 2 exact matches (no review) + 1 review row (name match, different email) + 1 brand-new contact.
    'BRME-4425-mixed.xlsx': [
        makeRow('Alice',   'BRME4425Exact', 'alice.brme4425@brme4425.invalid'),     // exact -> no review
        makeRow('Brendan', 'BRME4425Exact', 'brendan.brme4425@brme4425.invalid'),   // exact -> no review
        makeRow('Carla',   'BRME4425Exact', 'carla.DIFFERENT@brme4425.invalid'),    // name match, email differs -> REVIEW
        makeRow('Derek',   'BRME4425New',   'derek.brme4425@brme4425.invalid')      // no BRM match -> new contact (no review)
    ],
    // 3. Zero no-review: exact First+Last name match (so a candidate is found) but Business Email differs
    //    on a mapped field -> isSame=false -> both REQUIRE REVIEW (0 no-review).
    'BRME-4425-zero-no-review.xlsx': [
        makeRow('Alice',   'BRME4425Exact', 'alice.DIFFERENT@brme4425.invalid'),
        makeRow('Brendan', 'BRME4425Exact', 'brendan.DIFFERENT@brme4425.invalid')
    ]
};

function buildSheet(rows) {
    const all = [HEADERS].concat(rows);
    const ws = {};
    let maxCol = 0;
    for (let r = 0; r < all.length; r++) {
        for (let c = 0; c < all[r].length; c++) {
            ws[XLSX.utils.encode_cell({ r: r, c: c })] = { v: all[r][c], t: 's' };
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

// Self-check: parse each file back the same way DITLoadCmp does (first sheet, row object array).
for (const fileName of Object.keys(WORKBOOKS)) {
    const wb = XLSX.read(fs.readFileSync(path.join(outDir, fileName)), { type: 'buffer' });
    const rows = XLSX.utils.sheet_to_row_object_array(wb.Sheets[wb.SheetNames[0]]);
    console.log('VERIFY ' + fileName + ' -> ' + rows.map(r => r['First Name'] + '|' + r['Last Name'] + '|' + r['Business Email']).join('  ;  '));
}
