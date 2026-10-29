// BRME-6786: generates the DIT-compatible .xlsx test workbooks into ../test-data/
// Uses the npm `xlsx` package installed in BRME-7012/tooling/node_modules.
// Run:  node BRME-6786/tooling/make-xlsx.js
const fs = require('fs');
const path = require('path');
const XLSX = require(path.join(__dirname, '..', '..', 'BRME-7012', 'tooling', 'node_modules', 'xlsx'));

// 32-column DIT template (same as BRME-7012/4425). Org values go under the "Organization Name" header
// (index 7) so it auto-maps to Data_Load_Record__c.Organization_Name__c (label = "Organization Name").
// NOTE: the legacy user template calls this column "Company", which does NOT auto-map (mapped manually in DIT).
const HEADERS = ['Salutation', 'First Name', 'Middle Name', 'Last Name', 'Suffix', 'Preferred First Name', 'Title', 'Organization Name', 'Business Email', 'Personal Email', 'Additional Email', 'Business Phone (Country Code)', 'Business Phone', 'Mobile Phone (Country Code)', 'Mobile Phone', 'Additional Phone (Country Code)', 'Additional Phone', 'Business Street Address 1', 'Business Street Address 2', 'Business Street Address 3', 'Business City', 'Business State', 'Business Postal Code', 'Business Country', 'Home Street Line1', 'Home Street Line2', 'Home Street Line3', 'Home City', 'Home State', 'Home Postal Code', 'Home Country', 'Notes '];
const SHEET_NAME = 'Sheet1';
const COL = { FIRST: 1, LAST: 3, ORG: 7 };

function makeRow(firstName, lastName, orgName) {
    const row = new Array(HEADERS.length).fill('');
    row[COL.FIRST] = firstName;
    row[COL.LAST] = lastName;
    row[COL.ORG] = orgName;
    return row;
}

const WORKBOOKS = {
    // Scenario 1: "not found" message today, but the duplicate modal DOES have a candidate (BRME6786 Holdings Group).
    'BRME-6786-scenario1-similar-records.xlsx': [
        makeRow('Sam', 'BRME6786Row1', 'BRME6786 Holdings')
    ],
    // Scenario 2: genuinely absent, no candidates -> Create Organization.
    'BRME-6786-scenario2-create-org.xlsx': [
        makeRow('Nina', 'BRME6786Row2', 'BRME6786 Nonexistent Foundation')
    ],
    // Scenario 3: "Multiple ... found in BRM" today, duplicate modal has 2 candidates.
    'BRME-6786-scenario3-multiple.xlsx': [
        makeRow('Mike', 'BRME6786Row3', 'BRME6786 City Foundation')
    ],
    // Mixed: all three scenarios + an exact-match control row (auto-links, no error row).
    'BRME-6786-mixed.xlsx': [
        makeRow('Sam', 'BRME6786Row1', 'BRME6786 Holdings'),
        makeRow('Nina', 'BRME6786Row2', 'BRME6786 Nonexistent Foundation'),
        makeRow('Mike', 'BRME6786Row3', 'BRME6786 City Foundation'),
        makeRow('Eve', 'BRME6786Row4', 'BRME6786 Exact Org')
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

for (const fileName of Object.keys(WORKBOOKS)) {
    const wb = XLSX.read(fs.readFileSync(path.join(outDir, fileName)), { type: 'buffer' });
    const rows = XLSX.utils.sheet_to_row_object_array(wb.Sheets[wb.SheetNames[0]]);
    console.log('VERIFY ' + fileName + ' -> ' + rows.map(r => r['First Name'] + '|' + r['Last Name'] + '|' + r['Organization Name']).join('  ;  '));
}
