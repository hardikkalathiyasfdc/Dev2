// BRME-6993: generates DIT-compatible .xlsx test workbooks into ../test-data/
// Uses the npm `xlsx` package installed in BRME-7012/tooling/node_modules.
// Run:  node BRME-6993/tooling/make-xlsx.js
const fs = require('fs');
const path = require('path');
const XLSX = require(path.join(__dirname, '..', '..', 'BRME-7012', 'tooling', 'node_modules', 'xlsx'));

// 32-column DIT template (same as BRME-7012/4425/6786). Org values under "Organization Name" (index 7),
// address under Business Street/City/State/Postal/Country. See README for scenario mapping.
const HEADERS = ['Salutation', 'First Name', 'Middle Name', 'Last Name', 'Suffix', 'Preferred First Name', 'Title', 'Organization Name', 'Business Email', 'Personal Email', 'Additional Email', 'Business Phone (Country Code)', 'Business Phone', 'Mobile Phone (Country Code)', 'Mobile Phone', 'Additional Phone (Country Code)', 'Additional Phone', 'Business Street Address 1', 'Business Street Address 2', 'Business Street Address 3', 'Business City', 'Business State', 'Business Postal Code', 'Business Country', 'Home Street Line1', 'Home Street Line2', 'Home Street Line3', 'Home City', 'Home State', 'Home Postal Code', 'Home Country', 'Notes '];
const SHEET_NAME = 'Sheet1';
const COL = { FIRST: 1, LAST: 3, ORG: 7, EMAIL: 8, PHONE: 12, STREET: 17, CITY: 20, STATE: 21, ZIP: 22, COUNTRY: 23 };

const ORG_BRM = 'BRME6993 Org A';   // existing BRM org (on the baseline contacts)
const ORG_XL = 'BRME6993 Org B';    // different org, what Excel rows reference

function row(first, last, org, opts) {
    const r = new Array(HEADERS.length).fill('');
    r[COL.FIRST] = first; r[COL.LAST] = last; r[COL.ORG] = org;
    if (opts && opts.email) r[COL.EMAIL] = opts.email;
    if (opts && opts.phone) r[COL.PHONE] = opts.phone;
    if (opts && opts.addr) { r[COL.STREET] = opts.addr[0]; r[COL.CITY] = opts.addr[1]; r[COL.STATE] = opts.addr[2]; r[COL.ZIP] = opts.addr[3]; r[COL.COUNTRY] = opts.addr[4]; }
    return r;
}
const ADDR = ['100 Alpha Way', 'New York', 'NY', '10001', 'United States'];

const WORKBOOKS = {
    // S1: different Excel org selected; BRM email+phone+address populated; checkbox FALSE (Fiona).
    'BRME-6993-s1-diffOrg-full-chkFalse.xlsx': [row('Fiona', 'BRME6993Full', ORG_XL, { email: 'fiona.brme6993@brme6993.invalid', phone: '212-555-0101', addr: ADDR })],
    // S2: different Excel org; checkbox TRUE (Theo).
    'BRME-6993-s2-diffOrg-chkTrue.xlsx': [row('Theo', 'BRME6993ChkTrue', ORG_XL, { email: 'theo.brme6993@brme6993.invalid', phone: '212-555-0102', addr: ADDR })],
    // S3: different Excel org; independent BRM field population (partial/addr-only/bare).
    'BRME-6993-s3-partial-fields.xlsx': [
        row('Paula', 'BRME6993Partial', ORG_XL, { email: 'paula.brme6993@brme6993.invalid' }),   // email only
        row('Adam', 'BRME6993AddrOnly', ORG_XL, { addr: ADDR }),                                 // address only
        row('Bianca', 'BRME6993Bare', ORG_XL)                                                    // none
    ],
    // S4: SAME org selected from Excel (control — no warning).
    'BRME-6993-s4-sameOrg.xlsx': [row('Fiona', 'BRME6993Full', ORG_BRM, { email: 'fiona.brme6993@brme6993.invalid' })],
    // S5: different org present in Excel but user keeps the BRM org (no warning).
    'BRME-6993-s5-keepBrm.xlsx': [row('Theo', 'BRME6993ChkTrue', ORG_XL, { email: 'theo.brme6993@brme6993.invalid' })],
    // S9: checkbox edit + save behaviour (Fiona; user toggles the new checkbox in the Excel column).
    'BRME-6993-s9-checkbox.xlsx': [row('Fiona', 'BRME6993Full', ORG_XL, { email: 'fiona.brme6993@brme6993.invalid', phone: '212-555-0101', addr: ADDR })]
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
    console.log('VERIFY ' + fileName + ' -> ' + rows.map(r => r['First Name'] + '|' + r['Last Name'] + '|' + r['Organization Name']).join('  ;  '));
}
