// BRME-4862: generates DIT-compatible .xlsx test workbooks into ../test-data/
// Reuses the npm `xlsx` package vendored in BRME-7012/tooling/node_modules (no fresh install).
// Run:  node BRME-4862/tooling/make-test-data.js
const fs = require('fs');
const path = require('path');
const XLSX = require(path.resolve(__dirname, '..', '..', 'BRME-7012', 'tooling', 'node_modules', 'xlsx'));

// 15-column DIT template (BRME-4862 layout).
const HEADERS = [
    'First Name', 'Last Name', 'Preferred First Name', 'Title', 'Organization Name',
    'Business Email', 'Personal Email', 'Business Phone', 'Business Phone Country Code',
    'Mobile Phone', 'Mobile Phone Country Code', 'Source', 'RSVP', 'Attendance', 'List Member Notes'
];
const SHEET_NAME = 'Sheet1';
const ORG = 'BRME5632 Org A';

// Error types (exactly one injected per error row)
const ERR_MISSING_LAST_NAME = 'missingLastName';       // blank Last Name -> "Last Name is required"
const ERR_PHONE_NO_CODE = 'phoneNoCountryCode';        // Business Phone set, Business Phone Country Code blank

function row(n, errorType) {
    const r = new Array(HEADERS.length).fill('');
    r[0] = 'Test' + n;                                  // First Name
    r[1] = errorType === ERR_MISSING_LAST_NAME ? '' : 'User' + n; // Last Name
    r[4] = ORG;                                         // Organization Name
    r[5] = 'tuser' + n + '@example.com';                // Business Email
    r[7] = '2125550100';                                // Business Phone
    r[8] = errorType === ERR_PHONE_NO_CODE ? '' : '1';  // Business Phone Country Code
    return r;
}

// totalRows data rows; an error is injected every `everyNth` row, alternating
// missingLastName / phoneNoCountryCode so the split is exactly 50/50.
function buildRows(totalRows, everyNth) {
    const rows = [];
    let errorIndex = 0;
    const distribution = { missingLastName: 0, phoneNoCountryCode: 0, clean: 0 };
    for (let i = 1; i <= totalRows; i++) {
        let errorType = null;
        if (i % everyNth === 0) {
            errorType = (errorIndex % 2 === 0) ? ERR_MISSING_LAST_NAME : ERR_PHONE_NO_CODE;
            errorIndex++;
        }
        if (errorType) distribution[errorType]++; else distribution.clean++;
        rows.push(row(i, errorType));
    }
    return { rows, distribution };
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

const WORKBOOKS = {
    'BRME-4862-200rows-10errors.xlsx': buildRows(200, 20), // every 20th row -> 10 errors (5/5)
    'BRME-4862-200rows-50errors.xlsx': buildRows(200, 4)   // every 4th row  -> 50 errors (25/25)
};

const outDir = path.join(__dirname, '..', 'test-data');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

for (const fileName of Object.keys(WORKBOOKS)) {
    const { rows, distribution } = WORKBOOKS[fileName];
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, buildSheet(rows), SHEET_NAME);
    const out = XLSX.write(wb, { bookType: 'xlsx', type: 'buffer' });
    fs.writeFileSync(path.join(outDir, fileName), out);
    console.log('WROTE ' + fileName + ' (' + out.length + ' bytes) rows=' + rows.length +
        ' errors=' + (distribution.missingLastName + distribution.phoneNoCountryCode) +
        ' [missingLastName=' + distribution.missingLastName + ', phoneNoCountryCode=' + distribution.phoneNoCountryCode + ']');
}

// Verification pass: re-read each file and count error rows by inspecting cell values.
for (const fileName of Object.keys(WORKBOOKS)) {
    const wb = XLSX.read(fs.readFileSync(path.join(outDir, fileName)), { type: 'buffer' });
    const rows = XLSX.utils.sheet_to_row_object_array(wb.Sheets[wb.SheetNames[0]]);
    let missingLast = 0, phoneNoCode = 0;
    for (const r of rows) {
        const last = r['Last Name'];
        const phone = r['Business Phone'];
        const code = r['Business Phone Country Code'];
        if (last === undefined || last === '') missingLast++;
        else if (phone !== undefined && phone !== '' && (code === undefined || code === '')) phoneNoCode++;
    }
    console.log('VERIFY ' + fileName + ' -> totalRows=' + rows.length +
        ' missingLastName=' + missingLast + ' phoneNoCountryCode=' + phoneNoCode);
}
