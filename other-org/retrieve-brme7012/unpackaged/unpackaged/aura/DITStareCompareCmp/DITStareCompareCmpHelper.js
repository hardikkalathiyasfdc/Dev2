({
    filterDup: function (cmp) {
        let filterContacts = [];
        let selectedContact = cmp.get("v.selectedContact");
        let excelCont = {};

        for (let i = 0; i < selectedContact.fields.length; i++) {
            excelCont[this.columnMap[selectedContact.fields[i].excel.api]] = selectedContact.fields[i].excel.value;
        }

        let names = selectedContact.name.split(' ');
        excelCont.FirstName = names[0];
        excelCont.LastName = names[1];

        let records = selectedContact.sfContacts;
        filterContacts = records.filter(function (rec) {
            return (
                (!excelCont.UUID__c ||
                    (rec.UUID__c && excelCont.UUID__c && rec.UUID__c == excelCont.UUID__c) &&
                    rec.LastName && excelCont.LastName && rec.LastName == excelCont.LastName
                ) ||
                (
                    rec.Email == excelCont.Email ||
                    rec.Alternate_Email__c == excelCont.Email ||
                    rec.Business_Email_2__c == excelCont.Email
                ) ||
                (rec.Converted_Full_Name__c && excelCont.Converted_Full_Name__c) ||
                ( rec.Converted_FirstName__c && excelCont.FirstName && rec.Converted_FirstName__c == excelCont.FirstName &&  rec.Converted_LastName__c && excelCont.LastName && rec.Converted_LastName__c == excelCont.LastName)
            );
        });

        return filterContacts;
    },

    showDupTable: function (cmp, name) {
        let idx = Number(name);
        let data = cmp.get("v.contactList");

        for (let i = 0; i < data.length; i++) {
            let c = data[i];
            if (i != idx) {
                c.isSelected = false;
            } else {
                c.isSelected = true;
            }
        }

        let con = data[idx];
        if (!con) return;

        con.idx = idx;
        cmp.set("v.selectedContact", con);
        this.setButtonVisibility(cmp);
        cmp.set("v.contactList", data);

        let filterRecords = this.filterDup(cmp);

        if (filterRecords.length == 1) {
            cmp.set('v.showDuplicatesModal', false);
        }

        if (con.hasDuplicates && !con.isConfirmed && filterRecords.length > 1) {
            let recordsToDisplay = [];
            recordsToDisplay = this.formatDataToDisplayInTable(recordsToDisplay, cmp.get('v.columns'), filterRecords);
            cmp.set("v.dupesData", recordsToDisplay);
            cmp.set('v.showDuplicatesModal', true);

            let myTable = cmp.find("myTable");
            if (myTable) {
                myTable.setWidth();
            }
        } else if (filterRecords.length == 1) {
            this.updateSFValues(cmp, cmp.get("v.selectedContact"), filterRecords[0]);
        }
    },

    updateDataLoadRecords: function (cmp, defaultConfirmed) {
        cmp.set("v.isLoading", true);
        let updateRecords = [];

        for (let j = 0; j < defaultConfirmed.length; j++) {
            let record = {};
            let selected = defaultConfirmed[j];
            record.Id = selected.id;
            let self = this;

            for (let i = 0; i < selected.fields.length; i++) {
                if (selected.fields[i].sf) {
                    selected.fields[i].sf.options = [];
                }
                if (selected.fields[i].excel) {
                    selected.fields[i].excel.options = [];
                }
            }

            selected.sfContacts = selected.sfContacts && selected.sfContacts.length > 0
                ? [selected.sfContacts[0]]
                : '';
            record.IsConfirmed__c = true;
            record.Contact_ID__c = selected.sfContacts[0].Id;
            record.Contact__c = selected.sfContacts[0].Id;
            updateRecords.push(record);
        }

        this.util
            .controllerPromise(cmp, "updateDataRecords", {
                dataRecords: updateRecords,
                isSignficantOther: false
            })
            .then(
                $A.getCallback(function (data) {
                    cmp.set("v.isLoading", false);
                })
            )
            .catch((errMsg) => {
                cmp.set("v.isLoading", false);
                console.log(errMsg);
                self.util.showToastError(errMsg);
            });
    },

    updateSelected: function (cmp, selected) {
        let record = {};
        record.Id = selected.id;
        let self = this;
        cmp.set("v.isLoading", true);

        for (let i = 0; i < selected.fields.length; i++) {
            if (selected.fields[i].excel) {
                selected.fields[i].excel.options = [{ value: selected.fields[i].excel.value }];
            }
            if (selected.fields[i].sf) {
                selected.fields[i].sf.options = [];
            }
        }

        record.IsConfirmed__c = selected.isConfirmed;
        record.Contact_Data__c = JSON.stringify(selected);

        this.util
            .controllerPromise(cmp, "updateDataRecord", {
                dataRecord: record
            })
            .then(
                $A.getCallback(function (data) {
                    cmp.set("v.isLoading", false);
                })
            )
            .catch((errMsg) => {
                cmp.set("v.isLoading", false);
                console.log(errMsg);
                self.util.showToastError(errMsg);
            });
    },

    confirmContact: function (cmp) {
        let sel = cmp.get("v.selectedContact");
        let idx = sel.idx;
        let data = cmp.get("v.contactList");

        data[idx].isConfirmed = true;
        data[idx].isCreate = sel.isCreate;
        sel.isConfirmed = true;

        let hasNotConfirmed = false;
        let confirmNum = 0;
        this.updateSelected(cmp, sel);

        for (let i = 0; i < data.length; i++) {
            if (!data[i].isConfirmed && !data[i].isDeleted) {
                hasNotConfirmed = true;
            } else {
                confirmNum++;
            }
        }

        cmp.set("v.confirmNumber", confirmNum);

        if (!hasNotConfirmed) {
            cmp.set("v.selectedContact", sel);
            cmp.set("v.contactList", data);
            cmp.set("v.isMergeReady", true);
            if (sel.idx < data.length) {
                cmp.set('v.showDuplicatesModal', false);
            }
            return;
        }

        let selected = idx;
        while (selected < data.length && data[selected].isConfirmed) selected++;

        if (selected >= data.length) {
            selected = 0;
            while (selected >= 0 && data[selected].isConfirmed) {
                selected++;
            }
        }

        data[idx].isSelected = false;
        data[selected].isSelected = true;
        cmp.set("v.selectedContact", data[selected]);
        cmp.set("v.contactList", data);

        if (selected < data.length) {
            this.showDupTable(cmp, selected);
        }
    },

    loadData: function (cmp) {
        let self = this;
        cmp.set("v.isLoading", true);

        this.util
            .controllerPromise(cmp, "getColumns")
            .then(
                $A.getCallback(function (columns) {
                    columns.unshift({
                        label: 'Contact Alert Reason',
                        api: 'Contact_Alert_Reason__c',
                        type: 'STRING',
                        isEdit: false,
                        isSortable: true
                    });
                    columns.push({ api: 'Converted_Full_Name__c' });
                    self.columns = columns;
                    let params = {
                        dataLoadId: cmp.get("v.dataLoaderId")
                    };
                    return self.util.controllerPromise(cmp, "loadPreviewData", params);
                })
            )
            .then(
                $A.getCallback(function (result) {
                    let previewData = [];
                    cmp.set("v.totalRecordCount", result.records.length);
                    if (result.records && result.records.length) {
                        self.prevMap = self.getPrevMap(result.records, cmp);
                        self.setCreatedRow(previewData, result);
                    }
                    let params = {
                        type: "validate",
                        data: previewData
                    };
                    return self.util.runWorker("$Resource.DITWorker", params);
                })
            )
            .then(
                $A.getCallback(function (result) {
                    let params = {
                        type: "getContacts",
                        data: result.data,
                        columns: self.columns,
                        requiredColumns: self.requiredColumns
                    };
                    self.previewData = result.data;
                    return self.util.runWorker("$Resource.DITWorker", params);
                })
            )
            .then(
                $A.getCallback(function (result) {
                    self.contactMapResult = result;
                    return self.util.controllerPromise(cmp, "getDupes", {
                        contactMap: result,
                        columnMap: self.columnMap
                    });
                })
            )
            .then(
                $A.getCallback(function (result) {
                    result = self.prepareResult(result, self.contactMapResult);
                    self.dupeMap = result;
                    cmp.set('v.rawResult', result);
                    self.setContactList(cmp, result);
                    setTimeout(function () {
                        self.updateRadio(cmp);
                        cmp.set("v.isLoading", false);
                    }, 500);
                })
            )
            .catch((errMsg) => {
                cmp.set("v.isLoading", false);
                self.util.showToastError(errMsg);
            });
    },

    updateRadio: function (cmp) {
        let selected = cmp.get("v.selectedContact");
        let matches = document.querySelectorAll(".sfRadio");

        for (let i = 0; i < matches.length; i++) {
            let match = matches[i];
            let idx = match.name;
            if (selected.fields[Number(idx)].sf.isSelected) {
                match.click();
            }
        }

        matches = document.querySelectorAll(".excelRadio");
        for (let i = 0; i < matches.length; i++) {
            let match = matches[i];
            let idx = match.name;
            if (selected.fields[Number(idx)].excel.isSelected) {
                match.click();
            }
        }
    },

    getPrevMap: function (records, cmp) {
        let prevMap = {};
        let convertedNameMap = {};

        for (let i = 0; i < records.length; i++) {
            let rec = records[i];
            let conData = {};
            let key = rec.Converted_Full_Name__c;

            if (rec.Contact_Data__c && rec.Contact_Data__c.length) {
                conData = JSON.parse(rec.Contact_Data__c);
                conData.isConfirmed = rec.IsConfirmed__c;
                prevMap[key.toLowerCase()] = conData;
            }
        }

        cmp.set('v.convertedNameMap', convertedNameMap);
        return prevMap;
    },

    setContactList: function (cmp, result) {
        let contactList = [];
        let defaultConfirmed = [];
        for (let i = 0; i < this.previewData.length; i++) {
            let data = this.previewData[i];
            let fullNameKey = "", firstLastNameKey = "", dataLoadRecord = {};
            let firstName = data.cells.find(cell => cell.api === "First_Name__c")?.value || "";
            let lastName = data.cells.find(cell => cell.api === "Last_Name__c")?.value || "";
            for (let j = 0; j < data.cells.length; j++) {
                let cell = data.cells[j];
                dataLoadRecord[cell.api] = cell.value;

                if (cell.api === "Converted_Full_Name__c") {
                    let value = cell.value && cell.value.length ? cell.value.trim() : "null";
                    fullNameKey += value;
                } else if (cell.api === "First_Name__c" || cell.api === "Last_Name__c") {
                    let value = cell.value && cell.value.length ? cell.value.trim() : "null";
                    firstLastNameKey += value;
                }
            }

            fullNameKey = fullNameKey.toLowerCase();
            firstLastNameKey = firstLastNameKey.toLowerCase();
            let matchedKey = result[fullNameKey]?.length > 0 ? fullNameKey : firstLastNameKey;
            if (result[fullNameKey] || result[firstLastNameKey]) {

                let sfContacts =[ ...(result[fullNameKey] || []),...(result[firstLastNameKey] || [])];// new Array(result[matchedKey])[0];

                let contact = {};

                if (this.prevMap[fullNameKey] || this.prevMap[firstLastNameKey]) {
                    let previousKey = this.prevMap[fullNameKey] ? fullNameKey : firstLastNameKey;
                    contact.isConfirmed = this.prevMap[previousKey].isConfirmed;
                }

                sfContacts = sfContacts.filter((contact, index, contactsArray) => contactsArray.findIndex(c => c.Id === contact.Id) === index);
                contact.name = firstName + ' ' + lastName;
                contact.fields = [];
                contact.id = data.id;
                contact.sfContactsLength = sfContacts.length;
                if (sfContacts.length > 0 && dataLoadRecord['UUID__c']) {
                    let uuidFilterRecords = sfContacts.filter(rec => rec.UUID__c == dataLoadRecord['UUID__c']);
                    sfContacts = uuidFilterRecords.length > 0 ? uuidFilterRecords : sfContacts;
                }

                contact.sfContacts = sfContacts;
                contact.hasDuplicates = sfContacts.length >= 1 ? true : false;

                let isSame = true;

                if (contact.hasDuplicates) {
                    for (let j = 0; j < data.cells.length; j++) {
                        let cell = data.cells[j];
                        if (this.columnMap[cell.api]) {
                            let temp = this.getContactCell(cell, sfContacts[0]);

                            if (temp.sf.api === "Organization_Name__c") {
                                temp.sf.value = (sfContacts.length > 0 && sfContacts[0].Account)
                                    ? sfContacts[0].Account.Name
                                    : '';
                            }

                            if (temp.sf.api === "Significant_Other__c") {
                                temp.sf.value = (sfContacts.length > 0 && sfContacts[0].Significant_Other__r)
                                    ? sfContacts[0].Significant_Other__r.Name
                                    : '';
                            }

                            if (this.prevMap[matchedKey]) {
                                temp.excel.isSelected = this.prevMap[matchedKey].fields[j]?.excel.isSelected;
                                temp.sf.isSelected = this.prevMap[matchedKey].fields[j]?.sf.isSelected;
                            } else {
                                temp.sf.isSelected = true;
                            }

                            contact.fields.push(temp);

                            if (
                                temp.excel.value &&
                                temp.excel.value.toLowerCase().replace(/\s+/g, '') !=
                                temp.sf.value.toLowerCase().replace(/\s+/g, '')
                            ) {
                                isSame = false;
                            }
                        }
                    }

                    let sfCon = sfContacts[0];

                    if (
                        isSame &&
                        contact.hasDuplicates &&
                        (
                            dataLoadRecord['Last_Name__c'] == sfCon[this.columnMap['Last_Name__c']] &&
                            dataLoadRecord['Business_Email__c'] == sfCon[this.columnMap['Business_Email__c']]
                        )
                    ) {
                        isSame = true;
                    }
                }

                if (sfContacts.length >= 1) {
                    let isSameUUID = false;

                    if (
                        sfContacts.length >= 1 &&
                        isSame &&
                        dataLoadRecord['UUID__c'] &&
                        sfContacts[0].UUID__c &&
                        sfContacts[0].UUID__c == dataLoadRecord['UUID__c']
                    ) {
                        isSameUUID = true; // Uncommented as part of BRME-5545
                        contact.sfContacts = sfContacts;
                    }

                    if (
                        (!dataLoadRecord.First_Name__c || !dataLoadRecord.Last_Name__c || !dataLoadRecord.Business_Email__c) &&
                        (!dataLoadRecord['UUID__c'] || !isSameUUID)
                    ) {
                        isSame = false;
                    }
                }

                if (!isSame || data.isAlredaySignificantOther) {
                    contact.isAlredaySignificantOther = data.isAlredaySignificantOther;
                    contact = (this.prevMap && this.prevMap[matchedKey] && this.prevMap[matchedKey].isConfirmed)
                        ? this.prevMap[matchedKey]
                        : contact;
                    contactList.push(contact);
                } else if (contact.hasDuplicates) {
                    contact.isConfirmed = true;
                    defaultConfirmed.push(contact);
                }
            } else if (this.prevMap[matchedKey] && this.prevMap[matchedKey].isConfirmed) {
                contactList.push(this.prevMap[matchedKey]);
            }
        }

        if (defaultConfirmed.length > 0) {
            this.updateDataLoadRecords(cmp, defaultConfirmed);
        }

        let startIdx = 0;
        let hasStart = false;
        let confirmed = 0;

        for (let i = 0; i < contactList.length; i++) {
            let contact = contactList[i];

            if (contact.Contact_Data__c) {
                startIdx = i;
                contact.isConfirmed = contact.isConfirmed__c;
            }

            contact.idx = i;

            if (!contact.hasDuplicates && !hasStart && !contact.isDeleted && !contact.isConfirmed) {
                startIdx = i;
                hasStart = true;
                contact.isSelected = true;
            }

            if (contact.isConfirmed || contact.isDeleted) {
                confirmed++;
            }
        }

        if (contactList && contactList.length > 0) {
            contactList[startIdx].isSelected = true;
        }

        for (let i = 0; i < contactList.length; i++) {
            this.setFieldDiffs(contactList[i]);
        }

        cmp.set('v.confirmNumber', confirmed);
        cmp.set("v.contactList", contactList);
        cmp.set("v.selectedContact", (contactList && contactList.length > 0) ? contactList[contactList.length - 1] : []);
        this.showDupTable(cmp, confirmed);
    },

    saveRecord: function (cmp, moreFields, fieldChanged) {
        let self = this;
        cmp.set("v.isLoading", true);
        let record = {};
        let selected = cmp.get("v.selectedContact");
        record.Id = selected.id;

        for (let i = 0; i < selected.fields.length; i++) {
            let excelField = selected.fields[i].excel;
            let val = excelField.value && excelField.value.length ? excelField.value : "";
            record[excelField.api] = val;

            if (selected.fields[i].sf) {
                selected.fields[i].sf.options = [];
            }
            if (selected.fields[i].excel) {
                selected.fields[i].excel.options = [];
            }
        }

        if (moreFields) {
            record = Object.assign(record, moreFields);
        }
        this.setFieldDiffs(selected);
        record.Contact_Data__c = JSON.stringify(selected);

        this.util
            .controllerPromise(cmp, "updateDataRecord", {
                dataRecord: record
            })
            .then(
                $A.getCallback(function (data) {
                    selected.errorMsg = '';
                    cmp.set("v.selectedContact", selected);
                    cmp.set("v.isLoading", false);
                })
            )
            .catch((errMsg) => {
                cmp.set("v.isLoading", false);
                console.log(errMsg);
                selected.errorMsg = errMsg;
                cmp.set("v.selectedContact", selected);
                this.util.showToastError(errMsg);
            });
    },

    getContactCell: function (cell, sfContact) {
        let temp = {};
        temp.label = cell.label;

        let excel = JSON.parse(JSON.stringify(cell));
        excel.isEdit = this.editColumns[cell.api] ? true : false;
        excel.isChecked = true;

        let sf = JSON.parse(JSON.stringify(cell));
        sf.value = sfContact[this.columnMap[cell.api]];
        sf.value = sf.value == null ? "" : sf.value;

        temp.isShow = (this.defaultColumns[cell.api] || excel.value || sf.value) ? true : false;
        temp.api = excel.api;
        temp.excel = excel;
        temp.sf = sf;
        temp.showAllFields = false;
        temp.contactId = sfContact.Id;

        if (temp.isShow && !temp.excel.isChecked) {
            temp.sf.isChecked = true;
        }
        if (cell.api === 'Contact_Alert_Reason__c') {
            excel.isEdit = false;
            temp.isReadOnlyAlert = true;
        }

        return temp;
    },

    setCreatedRow: function (previewData, result) {
        let rows = [];

        for (let i = 0; i < result.records.length; i++) {
            let record = result.records[i];
            let row = {};
            row.id = record.Id;
            row.isAlredaySignificantOther = record.isAlredaySignificantOther__c;
            row.cells = [];

            for (let j = 0; j < this.columns.length; j++) {
                row.cells.push(this.getCell(this.columns[j], record));
            }

            rows.push(row);
        }

        for (let i = 0; i < rows.length; i++) {
            previewData.push(rows[i]);
        }
    },

    getCell: function (previewCol, record) {
        let cell = JSON.parse(JSON.stringify(previewCol));
        cell.isEdit = false;
        cell.value = record[cell.api] != null ? record[cell.api] : "";
        if (cell.api == "Account.Name") {
            cell.value = record['Account'] ? record['Account'].Name : "";
        }
        if (cell.api === "Contact_Alert_Reason__c" && cell.value) {
            cell.style = "background: #f3ba15;";
        }
        return cell;
    },

    processSelectContact: function (cmp, event, helper) {
        let name = event.getSource().get("v.name");
        if (isNaN(name)) {
            return;
        }

        let idx = Number(name);
        let data = cmp.get("v.contactList");

        for (let i = 0; i < data.length; i++) {
            let c = data[i];
            if (i != idx) {
                c.isSelected = false;
            } else {
                c.isSelected = true;
            }
        }

        let con = data[idx];
        this.setFieldDiffs(data[idx]);
        cmp.set("v.selectedContact", data[idx]);
        cmp.set("v.contactList", data);
        cmp.set("v.showDuplicatesModal", false);

        setTimeout(function () {
            helper.updateRadio(cmp);
        }, 1000);
    },

    formatDataToDisplayInTable: function (previewData, columns, records) {
        let rows = [];

        for (let i = 0; i < records.length; i++) {
            let record = records[i];
            let row = {};
            row.id = record.Id;
            row.cells = [];

            for (let j = 0; j < columns.length; j++) {
                let cell = this.getCell(columns[j], record);
                if (cell.excel) cell.excel.isSelected = false;
                if (cell.sf) cell.sf.isSelected = true;
                row.cells.push(cell);
            }

            rows.push(row);
        }

        for (let i = 0; i < rows.length; i++) {
            previewData.push(rows[i]);
        }

        return previewData;
    },

    updateSFValues: function (cmp, selectedContact, sfContact) {
        let contactList = cmp.get('v.contactList');
        let index = contactList.indexOf(selectedContact);

        for (let j = 0; j < selectedContact.fields.length; j++) {
            selectedContact.fields[j].sf.value = sfContact[this.columnMap[selectedContact.fields[j].api]];

            if (selectedContact.fields[j].sf.label === "Organization Name") {
                selectedContact.fields[j].sf.value = sfContact.Account ? sfContact.Account.Name : '';
            }

            if (selectedContact.fields[j].sf.api === "Significant_Other__c") {
                selectedContact.fields[j].sf.value = sfContact.Significant_Other__r
                    ? sfContact.Significant_Other__r.Name
                    : '';
            }

            if (!selectedContact.isCreate) {
                selectedContact.fields[j].contactId = sfContact.Id;
            }

            selectedContact.fields[j].isShow = (
                this.defaultColumns[selectedContact.fields[j].api] ||
                selectedContact.fields[j].excel.value ||
                selectedContact.fields[j].sf.value
            ) ? true : false;
        }

        selectedContact.showAllFields = false;
        this.setFieldDiffs(selectedContact);
        contactList[index] = selectedContact;
        cmp.set("v.contactList", contactList);
        cmp.set("v.selectedContact", selectedContact);
    },

    updateTable: function (cmp, params) {
        console.log('update table 1 ::::: ');
        let rawResult = cmp.get("v.rawResult");
        let contactList = cmp.get('v.contactList');
        let selectedContact = cmp.get('v.selectedContact');
        let index = contactList.indexOf(selectedContact);
        let selectedContactName = selectedContact.name.replaceAll(' ', '-').toLowerCase();
        let dupdata = cmp.get('v.dupesData');
        let sfContact = {};

        let dupd = dupdata[params.row];
        let conIndex = 0;

        for (let i = 0; i < contactList.length; i++) {
            if (
                contactList[i].isConfirmed &&
                contactList[i].sfContacts &&
                contactList[i].sfContacts.length > 0 &&
                contactList[i].sfContacts[0].Id == dupd.id
            ) {
                this.util.showToastError('This is already Confirmed');
                return;
            }
        }

        for (let i = 0; i < selectedContact.sfContacts.length; i++) {
            if (selectedContact.sfContacts[i].Id == dupd.id) {
                sfContact = selectedContact.sfContacts[i];
                conIndex = i;
                break;
            }
        }

        let firstCon = selectedContact.sfContacts[0];
        selectedContact.sfContacts[0] = sfContact;
        selectedContact.sfContacts[conIndex] = firstCon;

        this.updateSFValues(cmp, selectedContact, sfContact);
        cmp.set('v.showDuplicatesModal', false);
    },

    prepareResult: function (contactList, contactMap) {
        let duplicateContactsMap = {};

        for (let contactRecord of contactList) {
            let fullNameKey = contactRecord.Converted_Full_Name__c?.toLowerCase() || '';
            let firstLastNameKey =
                (contactRecord.Converted_FirstName__c?.toLowerCase() || '') +
                (contactRecord.Converted_LastName__c?.toLowerCase() || '');

            if (contactMap[fullNameKey]) {
                let duplicateList = duplicateContactsMap[fullNameKey]
                    ? duplicateContactsMap[fullNameKey]
                    : [];
                duplicateList.push(contactRecord);
                duplicateContactsMap[fullNameKey] = duplicateList;
            }
        	if (contactMap[firstLastNameKey]  && firstLastNameKey !== fullNameKey) {
                let duplicateList = duplicateContactsMap[firstLastNameKey]
                    ? duplicateContactsMap[firstLastNameKey]
                    : [];
                duplicateList.push(contactRecord);
                duplicateContactsMap[firstLastNameKey] = duplicateList;
            }

            let isDuplicateFound = false;

            for (let existingKey of Object.keys(contactMap)) {
                let existingContact = contactMap[existingKey];
                let existingFullNameKey = existingContact['Converted_Full_Name__c'].toLowerCase();

                if (
                    (
                        existingContact['Business_Email__c'] &&
                        existingContact['UUID__c'] != contactRecord.UUID__c &&
                        (
                            existingContact['Business_Email__c'] == contactRecord.Email ||
                            existingContact['Business_Email__c'] == contactRecord.Personal_Email_2__c ||
                            existingContact['Business_Email__c'] == contactRecord.Alternate_Email__c ||
                            existingContact['Business_Email__c'] == contactRecord.Business_Email_2__c ||
                            existingContact['Business_Email__c'] == contactRecord.Web_Email__
                        )
                    ) ||
                    contactRecord.Converted_Full_Name__c?.includes(existingContact['Converted_Full_Name__c'])
                ) {
                    let duplicateList = duplicateContactsMap[fullNameKey]
                        ? duplicateContactsMap[fullNameKey]
                        : duplicateContactsMap[existingFullNameKey]
                            ? duplicateContactsMap[existingFullNameKey]
                            : [];

                    duplicateList.push(contactRecord);
                    duplicateContactsMap[existingFullNameKey] = duplicateList;
                    isDuplicateFound = true;
                }

                if (
                    (contactRecord.UUID__c && existingContact['UUID__c'] == contactRecord.UUID__c) &&
                    contactRecord.Converted_Full_Name__c?.includes(existingContact['Converted_Full_Name__c'])
                ) {
                    let duplicateList = duplicateContactsMap[fullNameKey]
                        ? duplicateContactsMap[fullNameKey]
                        : duplicateContactsMap[existingFullNameKey]
                            ? duplicateContactsMap[existingFullNameKey]
                            : [];

                    duplicateList.push(contactRecord);
                    duplicateContactsMap[fullNameKey] = duplicateList;
                    isDuplicateFound = true;
                }
            }

            if (contactRecord.FirstName == contactRecord.Preferred_First_Name__c || isDuplicateFound) {
                continue;
            }

            let preferredNameKey = (contactRecord.Preferred_First_Name__c + '-' + contactRecord.LastName).toLowerCase();

            if (contactMap[preferredNameKey]) {
                let duplicateList = duplicateContactsMap[preferredNameKey]
                    ? duplicateContactsMap[preferredNameKey]
                    : [];
                duplicateList.push(contactRecord);
                duplicateContactsMap[preferredNameKey] = duplicateList;
            }
        }

        return duplicateContactsMap;
    },

    setButtonVisibility: function (cmp) {
        let selected = cmp.get('v.selectedContact');
        let disableConfirm = true;
        let disabledCreateAsNew = true;

        for (let i = 0; i < selected.fields.length; i++) {
            if (selected.fields[i].api === 'Contact_Alert_Reason__c') {
                continue;
            }
            if (selected.fields[i].sf.isSelected) {
                disableConfirm = false;
            }
            if (selected.fields[i].excel.isSelected) {
                disabledCreateAsNew = false;
            }
        }

        cmp.set("v.disabledCreateAsNew", disabledCreateAsNew);
        cmp.set("v.disabledConfirm", disableConfirm);
    },

    checkIfContactExistInBRM: function (component, selected, excelUUID) {
        var action = component.get("c.checkIfContactExistInBRM");
        action.setParams({ UUID: excelUUID });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                if (response.getReturnValue()) {
                    this.util.showToastError('Unable to create as a new contact, this UUID is already on an existing contact');
                } else {
                    component.set("v.disabledConfirm", false);
                    selected.isCreate = true;
                    component.set("v.selectedContact", selected);
                    this.confirmContact(component);
                    component.set("v.disabledCreateAsNew", true);
                }
            }
        });
        $A.enqueueAction(action);
    },

    setFieldDiffs: function (selectedContact) {
        if (!selectedContact || !selectedContact.fields) {
            return;
        }
        for (let i = 0; i < selectedContact.fields.length; i++) {
            let field = selectedContact.fields[i];
            if (!field || !field.excel || !field.sf) {
                continue;
            }
            if (field.api === 'Contact_Alert_Reason__c') {
                field.excel.isDiff = false;
                continue;
            }
            let excelVal = (field.excel.value == null) ? '' : String(field.excel.value);
            let sfVal = (field.sf.value == null) ? '' : String(field.sf.value);
            if (!excelVal.trim().length) {
                field.excel.isDiff = false;
                continue;
            }
            field.excel.isDiff = excelVal.trim().toLowerCase() !== sfVal.trim().toLowerCase();
        }
    }
});