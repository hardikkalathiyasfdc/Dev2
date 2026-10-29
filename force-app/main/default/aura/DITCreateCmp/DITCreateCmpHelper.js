({
    contactFetchData: function (component, event, helper) {
        component.set("v.isLoading", true);
        let params = {};
        params.columnMap = this.columnMap;
        params.dataLoaderId = component.get("v.dataLoaderId");
        var action = component.get("c.getContactsSummary");
        action.setParams(params);
        action.setCallback(this, function (response) {

            var state = response.getState();
            component.set("v.isLoading", false);
            let results = response.getReturnValue();
            if(state === "SUCCESS") {

                let deletedContactIds = [];
                let contactModifiedIds = [];
                let contactIds = [];
                let createIdList = [];

                component.set("v.recordList", results.recordList);
                component.set("v.orgsList", results.orgsList);

                for (let data of results.recordList) {
                    if(data.Contact_Data__c) {

                        let conMap = JSON.parse(data.Contact_Data__c)

                        let fieldList = conMap.fields;
                        if(conMap.isCreate || 'true' == conMap.isCreate) {
                            createIdList.push(data.Id);
                            continue;
                        }
                        if(conMap.isDeleted || 'true' == conMap.isDeleted) {
                            deletedContactIds.push(data.Id);
                            continue;
                        }
                        for (let field of fieldList) {

                            contactIds.push(field.contactId);

                            let excelMap = field.excel;

                            if(excelMap.isSelected) {
                                contactModifiedIds.push(data.Id);
                                break;
                            }

                        }
                    } else if(!data.IsConfirmed__c) {
                        createIdList.push(data.Id);
                    }

                    if(data.Contact_ID__c) {
                        contactIds.push(data.Contact_ID__c);
                    }
                }
                helper.contactFetchData2(component, {
                    deletedContactIds: deletedContactIds,
                    contactModifiedIds: contactModifiedIds,
                    contactIds: contactIds,
                    dataLoaderId: component.get("v.dataLoaderId"),
                    createIdList: createIdList,
                    columnMap: this.columnMap
                });
            }
        });
        $A.enqueueAction(action);
    },
    contactFetchData2: function (cmp, params) {
        cmp.set("v.isLoading", true);

        var action2 = cmp.get("c.getImportedDetail");
        action2.setParams(params);
        action2.setCallback(this, function (response) {
            var state = response.getState();
            cmp.set("v.isLoading", false);
            let results = response.getReturnValue();
            if(state === "SUCCESS") {
                this.processResp(cmp, results.conactMap, params, results.recordList);
            }
        });
        $A.enqueueAction(action2);
    },
    processResp: function (component, conactMap, params, recordList) {
        let deleteContactList = [];
        let deceasedContactList = [];
        let updateList = [];
        let doNotContactList = [];
        let contactModifiedList = [];
        let createList = [];
        for (let data of recordList) {
            let c = {};
            if(data.Contact_Data__c) {
                let conMap = JSON.parse(data.Contact_Data__c);
                let fieldList = conMap['fields'];
                c.Assistant__c = data.Assistant__c;
                let isCreateRow = (params.createIdList && params.createIdList.includes(data.Id)) || conMap.isCreate;
                let isDeleteRow = (params.deletedContactIds && params.deletedContactIds.includes(data.Id)) || conMap.isDeleted;
                let selectedSfContactId = null;
                if(conMap.sfContacts && Number.isInteger(conMap.idx) && conMap.sfContacts[conMap.idx]) {
                    selectedSfContactId = conMap.sfContacts[conMap.idx].Id;
                }
                if(!selectedSfContactId && fieldList.length > 0) {
                    selectedSfContactId = fieldList[0].contactId || null;
                }
                for(let field of fieldList) {
                    let fieldApi = field['api'];
                    let excelMap = field['excel'];
                    let sfMap = field['sf'];
                    let value = '';
                    let isExcelSelected = false;
                    isExcelSelected = excelMap['isSelected'];
                    if(isExcelSelected || isCreateRow || isDeleteRow) {
                        value = (excelMap.value !== undefined && excelMap.value !== null) ? excelMap.value : '';
                    } else {
                        value = sfMap['value'];
                    }
                    if(fieldApi == 'Organization_Name__c') c['Advance_Field_Notes__c'] = value;
                    if(fieldApi == 'Significant_Other__c') c['Assistant_First_Name__c'] = value;
                    if(this.columnMap[fieldApi]) c[this.columnMap[fieldApi]] = value;
                }
                if(!isCreateRow && selectedSfContactId) {
                    c.Id = selectedSfContactId;
                }
            } else {
                if(data['Contact_ID__c'] !== '' && data['Contact_ID__c'] !== undefined) {
                    c.Id = data['Contact_ID__c'];
                }
                for(const [key, value] of Object.entries(this.columnMap)) {
                    c[value] = data[key];
                }
                c['Advance_Field_Notes__c'] = data['Organization_Name__c'];
                c['Assistant_First_Name__c'] = data['Significant_Other__c'];
            }
            if(params.deletedContactIds.includes(data.Id)) {
                deleteContactList.push(c);
            } else if(c.Id && conactMap[c.Id] !== undefined && conactMap[c.Id].Deceased__c) {
                deceasedContactList.push(c);
            } else if(c.Id && conactMap[c.Id] !== undefined && conactMap[c.Id].DoNotCall) {
                doNotContactList.push(c);
            } else if(params.contactModifiedIds.includes(data.Id)) {
                contactModifiedList.push(c);
            } else if(params.createIdList.includes(data.Id)) {
                createList.push(c);
            } else {
                updateList.push(c);
            }
        }
        component.set("v.createList", createList);
        component.set("v.updateList", updateList);
        component.set("v.doNotContactList", doNotContactList);
        component.set("v.deceasedContactList", deceasedContactList);
        component.set("v.deleteContactList", deleteContactList);
        component.set("v.contactModifiedList", contactModifiedList);
        component.set("v.doNotcontactCount", doNotContactList.length + deceasedContactList.length + deleteContactList.length);
    },
    filterColumns: function (component, helper) {

        let actionGetPerm = component.get('c.fetchCustomPermission');
        actionGetPerm.setCallback(this, function (response) {
            if(response.getState() === 'SUCCESS') {
                var columns = helper.columns;
                var mapCustomPermission = response.getReturnValue();
                var columnsTofilter = [];

                if(!mapCustomPermission['Confidential_Info'])
                    columnsTofilter.push('Personal_Email_2__c')
                if(!mapCustomPermission['Contact_Home_Phone_Personal_Email'])
                    columnsTofilter.push('Alternate_Email__c')
                if(!mapCustomPermission['Contact_UUID'])
                    columnsTofilter.push('UUID__c')

                columns = columns.filter(column => !columnsTofilter.includes(column.fieldName));
                if(!mapCustomPermission['Contact_Home_Address'])
                    columns = columns.filter(column => !column.label.includes('Home'));
                // Set the columns in the component after handling the permission check
                component.set('v.columns', columns);

            }

        });
        $A.enqueueAction(actionGetPerm);
    },
})