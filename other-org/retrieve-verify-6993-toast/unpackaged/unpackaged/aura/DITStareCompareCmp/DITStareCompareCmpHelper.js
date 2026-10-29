({
  filterDup: function (cmp) {
    let filterContacts = [];
    let selectedContact = cmp.get("v.selectedContact");
    let excelCont = {};

    for (let i = 0; i < selectedContact.fields.length; i++) {
      excelCont[this.columnMap[selectedContact.fields[i].excel.api]] =
        selectedContact.fields[i].excel.value;
    }

    let names = selectedContact.name.split(" ");
    excelCont.FirstName = names[0];
    excelCont.LastName = names[1];

    let records = selectedContact.sfContacts;
    filterContacts = records.filter(function (rec) {
      return (
        !excelCont.UUID__c ||
        (rec.UUID__c &&
          excelCont.UUID__c &&
          rec.UUID__c == excelCont.UUID__c &&
          rec.LastName &&
          excelCont.LastName &&
          rec.LastName == excelCont.LastName) ||
        rec.Email == excelCont.Email ||
        rec.Alternate_Email__c == excelCont.Email ||
        rec.Business_Email_2__c == excelCont.Email ||
        (rec.Converted_Full_Name__c && excelCont.Converted_Full_Name__c) ||
        (rec.Converted_FirstName__c &&
          excelCont.FirstName &&
          rec.Converted_FirstName__c == excelCont.FirstName &&
          rec.Converted_LastName__c &&
          excelCont.LastName &&
          rec.Converted_LastName__c == excelCont.LastName)
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
      cmp.set("v.showDuplicatesModal", false);
    }

    if (con.hasDuplicates && !con.isConfirmed && filterRecords.length > 1) {
      let recordsToDisplay = [];
      recordsToDisplay = this.formatDataToDisplayInTable(
        recordsToDisplay,
        cmp.get("v.columns"),
        filterRecords
      );
      cmp.set("v.dupesData", recordsToDisplay);
      cmp.set("v.showDuplicatesModal", true);
      this.setDuplicatesTableWidth(cmp);
    } else if (filterRecords.length == 1) {
      this.updateSFValues(cmp, cmp.get("v.selectedContact"), filterRecords[0]);
    }
  },

  // The duplicate MyTable is created by aura:if. Defer sizing until Aura has rendered the child,
  // otherwise cmp.find can return undefined and MyTable remains on its initial loading spinner.
  setDuplicatesTableWidth: function (cmp) {
    setTimeout(
      $A.getCallback(function () {
        let myTable = cmp.find("myTable");
        if (myTable && myTable.setWidth) {
          myTable.setWidth();
        }
      }),
      300
    );
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

      selected.sfContacts =
        selected.sfContacts && selected.sfContacts.length > 0
          ? [selected.sfContacts[0]]
          : "";
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
        selected.fields[i].excel.options = [
          { value: selected.fields[i].excel.value }
        ];
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
        cmp.set("v.showDuplicatesModal", false);
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
            label: "Contact Alert Reason",
            api: "Contact_Alert_Reason__c",
            type: "STRING",
            isEdit: false,
            isSortable: true
          });
          columns.push({ api: "Converted_Full_Name__c" });
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
          cmp.set("v.rawResult", result);
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

    cmp.set("v.convertedNameMap", convertedNameMap);
    return prevMap;
  },

  // BRME-4435: build read-only exact-match and new-contact rows using the dedicated no-review columns.
  buildNoReviewTable: function (cmp, defaultConfirmed, newContactData) {
    let records = [];
    let seen = {};
    for (let i = 0; i < defaultConfirmed.length; i++) {
      let c = defaultConfirmed[i];
      if (
        c.sfContacts &&
        c.sfContacts.length > 0 &&
        !seen[c.sfContacts[0].Id]
      ) {
        seen[c.sfContacts[0].Id] = true;
        let rec = Object.assign({}, c.sfContacts[0]);
        let uploadValues = c.uploadValues || {};
        rec.Source__c = uploadValues.Source__c || "";
        rec.RSVP__c = uploadValues.RSVP__c || "";
        rec.Attendance__c = uploadValues.Attendance__c || "";
        rec.List_Member_Notes__c = uploadValues.List_Member_Notes__c || "";
        records.push(rec);
      }
    }
    let uploadToTable = {
      Salutation__c: "Salutation",
      First_Name__c: "FirstName",
      Middle_Name__c: "MiddleName",
      Last_Name__c: "LastName",
      Suffix__c: "Suffix",
      Title__c: "Title",
      Organization_Name__c: "Account.Name",
      Business_Email__c: "Email",
      Personal_Email__c: "Alternate_Email__c",
      Additional_Email__c: "Business_Email_2__c",
      Source__c: "Source__c",
      RSVP__c: "RSVP__c",
      Attendance__c: "Attendance__c",
      List_Member_Notes__c: "List_Member_Notes__c",
      UUID__c: "UUID__c"
    };
    for (let i = 0; i < newContactData.length; i++) {
      let data = newContactData[i];
      let rec = {};
      for (let j = 0; j < data.cells.length; j++) {
        let cell = data.cells[j];
        if (uploadToTable[cell.api]) {
          rec[uploadToTable[cell.api]] = cell.value;
        }
      }
      rec.Account = { Name: rec["Account.Name"] || "" };
      records.push(rec);
    }
    let columns = cmp.get("v.noReviewColumns") || [];
    cmp.set(
      "v.noReviewAllData",
      this.formatDataToDisplayInTable([], columns, records)
    );
    cmp.set("v.noReviewData", cmp.get("v.noReviewAllData"));
    cmp.set("v.noReviewCount", defaultConfirmed.length + newContactData.length);
  },

  // BRME-4435: filter the no-review table client-side by the search box text (matches any cell value).
  filterNoReview: function (cmp) {
    let term = (cmp.get("v.noReviewSearch") || "").toLowerCase().trim();
    let all = cmp.get("v.noReviewAllData") || [];
    let filtered = all;
    if (term) {
      filtered = all.filter(function (row) {
        return (row.cells || []).some(function (cell) {
          return (
            cell.value != null &&
            String(cell.value).toLowerCase().indexOf(term) !== -1
          );
        });
      });
    }
    cmp.set("v.noReviewData", filtered);
    // c:MyTable renders v.tableData (set by the ListWorker); push the filtered rows into the child table too.
    let t = cmp.find("noReviewTable");
    if (t) {
      t.set("v.data", filtered);
      t.set("v.tableData", filtered);
    }
  },

  setContactList: function (cmp, result) {
    let contactList = [];
    let defaultConfirmed = [];
    let newContactData = []; // BRME-4435: upload rows with no candidates = new contacts (require no review)
    for (let i = 0; i < this.previewData.length; i++) {
      let data = this.previewData[i];
      let fullNameKey = "",
        firstLastNameKey = "",
        dataLoadRecord = {};
      let firstName =
        data.cells.find((cell) => cell.api === "First_Name__c")?.value || "";
      let lastName =
        data.cells.find((cell) => cell.api === "Last_Name__c")?.value || "";
      for (let j = 0; j < data.cells.length; j++) {
        let cell = data.cells[j];
        dataLoadRecord[cell.api] = cell.value;

        if (cell.api === "Converted_Full_Name__c") {
          let value =
            cell.value && cell.value.length ? cell.value.trim() : "null";
          fullNameKey += value;
        } else if (
          cell.api === "First_Name__c" ||
          cell.api === "Last_Name__c"
        ) {
          let value =
            cell.value && cell.value.length ? cell.value.trim() : "null";
          firstLastNameKey += value;
        }
      }

      fullNameKey = fullNameKey.toLowerCase();
      firstLastNameKey = firstLastNameKey.toLowerCase();
      let matchedKey =
        result[fullNameKey]?.length > 0 ? fullNameKey : firstLastNameKey;
      if (result[fullNameKey] || result[firstLastNameKey]) {
        let sfContacts = [
          ...(result[fullNameKey] || []),
          ...(result[firstLastNameKey] || [])
        ]; // new Array(result[matchedKey])[0];

        let contact = {};

        if (this.prevMap[fullNameKey] || this.prevMap[firstLastNameKey]) {
          let previousKey = this.prevMap[fullNameKey]
            ? fullNameKey
            : firstLastNameKey;
          contact.isConfirmed = this.prevMap[previousKey].isConfirmed;
        }

        sfContacts = sfContacts.filter(
          (contact, index, contactsArray) =>
            contactsArray.findIndex((c) => c.Id === contact.Id) === index
        );
        contact.name = firstName + " " + lastName;
        contact.fields = [];
        contact.id = data.id;
        // BRME-4435: retain uploaded Data Load values for Source/RSVP/Attendance/Notes in the no-review table.
        contact.uploadValues = dataLoadRecord;
        contact.sfContactsLength = sfContacts.length;
        if (sfContacts.length > 0 && dataLoadRecord["UUID__c"]) {
          let uuidFilterRecords = sfContacts.filter(
            (rec) => rec.UUID__c == dataLoadRecord["UUID__c"]
          );
          sfContacts =
            uuidFilterRecords.length > 0 ? uuidFilterRecords : sfContacts;
        }

        contact.sfContacts = sfContacts;
        contact.hasDuplicates = sfContacts.length >= 1 ? true : false;
        // BRME-6993: carry the resolved Organization Id (Excel side) for the different-org check.
        contact.Organization_Id__c = data.Organization_Id__c || null;

        let isSame = true;

        if (contact.hasDuplicates) {
          for (let j = 0; j < data.cells.length; j++) {
            let cell = data.cells[j];
            if (this.columnMap[cell.api]) {
              let temp = this.getContactCell(cell, sfContacts[0]);

              if (temp.sf.api === "Organization_Name__c") {
                temp.sf.value =
                  sfContacts.length > 0 && sfContacts[0].Account
                    ? sfContacts[0].Account.Name
                    : "";
              }

              if (temp.sf.api === "Significant_Other__c") {
                temp.sf.value =
                  sfContacts.length > 0 && sfContacts[0].Significant_Other__r
                    ? sfContacts[0].Significant_Other__r.Name
                    : "";
              }

              if (this.prevMap[matchedKey]) {
                temp.excel.isSelected =
                  this.prevMap[matchedKey].fields[j]?.excel.isSelected;
                temp.sf.isSelected =
                  this.prevMap[matchedKey].fields[j]?.sf.isSelected;
              } else {
                temp.sf.isSelected = true;
              }

              contact.fields.push(temp);

              if (
                temp.excel.value &&
                temp.excel.value.toLowerCase().replace(/\s+/g, "") !=
                  temp.sf.value.toLowerCase().replace(/\s+/g, "")
              ) {
                isSame = false;
              }
            }
          }

          let sfCon = sfContacts[0];

          // BRME-6993: add the editable "Use Same Address as Organization" checkbox to the Excel column.
          // It is not an upload column, so it is built here (initialized unchecked per ticket decision);
          // the BRM side shows the existing value for reference. recalcOrgChange computes the warning/highlights.
          if (contact.hasDuplicates) {
            let sf0 = sfContacts[0];
            contact.fields.push({
              api: "Use_Same_Address_as_Organization__c",
              label: "Use Same Address as Organization",
              isShow: true,
              excel: {
                api: "Use_Same_Address_as_Organization__c",
                value: false,
                isSelected: false,
                isEdit: true,
                type: "BOOLEAN"
              },
              sf: {
                api: "Use_Same_Address_as_Organization__c",
                value: sf0.Use_Same_Address_as_Organization__c === true,
                isSelected: true
              },
              contactId: sf0.Id
            });
            this.recalcOrgChange(cmp, contact);
          }

          if (
            isSame &&
            contact.hasDuplicates &&
            dataLoadRecord["Last_Name__c"] ==
              sfCon[this.columnMap["Last_Name__c"]] &&
            dataLoadRecord["Business_Email__c"] ==
              sfCon[this.columnMap["Business_Email__c"]]
          ) {
            isSame = true;
          }
        }

        if (sfContacts.length >= 1) {
          let isSameUUID = false;

          if (
            sfContacts.length >= 1 &&
            isSame &&
            dataLoadRecord["UUID__c"] &&
            sfContacts[0].UUID__c &&
            sfContacts[0].UUID__c == dataLoadRecord["UUID__c"]
          ) {
            isSameUUID = true; // Uncommented as part of BRME-5545
            contact.sfContacts = sfContacts;
          }

          if (
            (!dataLoadRecord.First_Name__c ||
              !dataLoadRecord.Last_Name__c ||
              !dataLoadRecord.Business_Email__c) &&
            (!dataLoadRecord["UUID__c"] || !isSameUUID)
          ) {
            isSame = false;
          }
        }

        if (!isSame || data.isAlredaySignificantOther) {
          contact.isAlredaySignificantOther = data.isAlredaySignificantOther;
          contact =
            this.prevMap &&
            this.prevMap[matchedKey] &&
            this.prevMap[matchedKey].isConfirmed
              ? this.prevMap[matchedKey]
              : contact;
          contactList.push(contact);
        } else if (contact.hasDuplicates) {
          contact.isConfirmed = true;
          defaultConfirmed.push(contact);
        }
      } else if (
        this.prevMap[matchedKey] &&
        this.prevMap[matchedKey].isConfirmed
      ) {
        contactList.push(this.prevMap[matchedKey]);
      } else {
        // BRME-4435: no candidates and not previously confirmed -> new contact to be created (no review).
        newContactData.push(data);
      }
    }

    // BRME-4435: populate the collapsible no-review table (exact matches + new contacts).
    this.buildNoReviewTable(cmp, defaultConfirmed, newContactData);

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

      if (
        !contact.hasDuplicates &&
        !hasStart &&
        !contact.isDeleted &&
        !contact.isConfirmed
      ) {
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

    cmp.set("v.confirmNumber", confirmed);
    cmp.set("v.contactList", contactList);
    cmp.set(
      "v.selectedContact",
      contactList && contactList.length > 0
        ? contactList[contactList.length - 1]
        : []
    );
    // BRME-4435: when every row requires no review, contactList is empty so the component swaps to the
    // "no contacts to merge" panel and skips showDupTable — populate the no-review table there too.
    if (!contactList || contactList.length === 0) {
      this.buildNoReviewTable(cmp, defaultConfirmed, newContactData);
    }
    this.showDupTable(cmp, confirmed);
  },

  // BRME-6993: business reason — when the user picks a DIFFERENT organization from the Excel column, the
  // contact's organization will change on save; if the BRM contact uses the org's address (Use Same Address
  // as Organization = true), its address will be overwritten by the new org's address. Warn the reviewer and
  // flag the related fields.
  //
  // Recalculates, for the given row, whether the Confirm warning should show and which related fields get the
  // yellow highlight. Called whenever the Organization Name selection (or the checkbox) changes.
  //   Warning gating:   different Excel org selected AND BRM contact Use_Same_Address_as_Organization__c == true.
  //   Highlight (only when the warning applies): Email/Phone when populated on BRM; Address when any BRM
  //                     Mailing* component is populated AND the EFFECTIVE checkbox is false.
  recalcOrgChange: function (cmp, contact) {
    if (!contact || !contact.fields) return;
    let sf0 =
      contact.sfContacts && contact.sfContacts.length > 0
        ? contact.sfContacts[0]
        : null;
    let orgField = null,
      emailField = null,
      phoneField = null,
      chkField = null;
    let addrFields = [];
    for (let i = 0; i < contact.fields.length; i++) {
      let f = contact.fields[i];
      if (f.api === "Organization_Name__c") orgField = f;
      else if (f.api === "Business_Email__c") emailField = f;
      else if (f.api === "Business_Phone__c") phoneField = f;
      else if (f.api === "Use_Same_Address_as_Organization__c") chkField = f;
      else if (
        [
          "Business_Street_1__c",
          "Business_City__c",
          "Business_State__c",
          "Business_Postal_Code__c",
          "Business_Country__c"
        ].indexOf(f.api) !== -1
      )
        addrFields.push(f);
    }
    // resolve org Ids: BRM side = candidate's AccountId; Excel side = the row's resolved Organization_Id__c
    let brmOrgId =
      sf0 && sf0.AccountId
        ? sf0.AccountId
        : sf0 && sf0.Account
          ? sf0.Account.Id
          : null;
    let excelOrgId = contact.Organization_Id__c || null;
    let excelOrgSelected = !!(
      orgField &&
      orgField.excel &&
      orgField.excel.isSelected
    );
    let isDifferentOrg =
      excelOrgSelected && brmOrgId && excelOrgId && brmOrgId !== excelOrgId;
    let brmChkTrue = !!(
      sf0 && sf0.Use_Same_Address_as_Organization__c === true
    );
    // effective checkbox value = what the user has set in the Excel column (drives the save)
    let effectiveChk =
      chkField && chkField.excel ? chkField.excel.value === true : false;

    let warn = isDifferentOrg && brmChkTrue;
    contact.orgChangeWarn = warn;

    // BRME-6993: show the advisory toast the moment the warn condition becomes true (e.g. the Excel-side org
    // radio is selected), not only on Confirm. Guard with orgChangeWarnShown so repeated recalcs don't stack toasts.
    if (warn && !contact.orgChangeWarnShown) {
      contact.orgChangeWarnShown = true;
      this.showStickyToast(
        "Please review and update highlighted fields related to this change.",
        "Review organization change",
        "warning"
      );
    } else if (!warn) {
      contact.orgChangeWarnShown = false;
    }

    // reset all highlight flags first (no stale state), then apply the qualifying ones
    let setFlag = function (f, on) {
      if (f && f.excel) {
        f.excel.isNewHighlight = on;
      }
    };
    setFlag(emailField, false);
    setFlag(phoneField, false);
    for (let i = 0; i < addrFields.length; i++) setFlag(addrFields[i], false);
    if (warn) {
      setFlag(emailField, !!(sf0 && sf0.Email));
      setFlag(phoneField, !!(sf0 && sf0.Phone));
      let brmHasAddr = !!(
        sf0 &&
        (sf0.MailingStreet ||
          sf0.MailingCity ||
          sf0.MailingState ||
          sf0.MailingPostalCode ||
          sf0.MailingCountry)
      );
      let addrOn = brmHasAddr && effectiveChk === false;
      for (let i = 0; i < addrFields.length; i++)
        setFlag(addrFields[i], addrOn);
    }
  },

  saveRecord: function (cmp, moreFields, fieldChanged) {
    let self = this;
    cmp.set("v.isLoading", true);
    let record = {};
    let selected = cmp.get("v.selectedContact");
    record.Id = selected.id;

    for (let i = 0; i < selected.fields.length; i++) {
      let excelField = selected.fields[i].excel;
      let val =
        excelField.value && excelField.value.length ? excelField.value : "";
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
          selected.errorMsg = "";
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

  // BRME-6993: sticky (non-auto-dismissing) advisory toast for the different-organization warning.
  showStickyToast: function (msg, title, type) {
    let toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: title,
      message: msg,
      type: type,
      mode: "sticky"
    });
    toastEvent.fire();
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

    temp.isShow =
      this.defaultColumns[cell.api] || excel.value || sf.value ? true : false;
    temp.api = excel.api;
    temp.excel = excel;
    temp.sf = sf;
    temp.showAllFields = false;
    temp.contactId = sfContact.Id;

    if (temp.isShow && !temp.excel.isChecked) {
      temp.sf.isChecked = true;
    }
    if (cell.api === "Contact_Alert_Reason__c") {
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
      // BRME-6993: carry the resolved Organization Id so the different-organization check can compare IDs.
      row.Organization_Id__c = record.Organization_Id__c;
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
      cell.value = record["Account"] ? record["Account"].Name : "";
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
    let contactList = cmp.get("v.contactList");
    let index = contactList.indexOf(selectedContact);

    for (let j = 0; j < selectedContact.fields.length; j++) {
      selectedContact.fields[j].sf.value =
        sfContact[this.columnMap[selectedContact.fields[j].api]];

      if (selectedContact.fields[j].sf.label === "Organization Name") {
        selectedContact.fields[j].sf.value = sfContact.Account
          ? sfContact.Account.Name
          : "";
      }

      if (selectedContact.fields[j].sf.api === "Significant_Other__c") {
        selectedContact.fields[j].sf.value = sfContact.Significant_Other__r
          ? sfContact.Significant_Other__r.Name
          : "";
      }

      if (!selectedContact.isCreate) {
        selectedContact.fields[j].contactId = sfContact.Id;
      }

      selectedContact.fields[j].isShow =
        this.defaultColumns[selectedContact.fields[j].api] ||
        selectedContact.fields[j].excel.value ||
        selectedContact.fields[j].sf.value
          ? true
          : false;
    }

    selectedContact.showAllFields = false;
    this.setFieldDiffs(selectedContact);
    contactList[index] = selectedContact;
    cmp.set("v.contactList", contactList);
    cmp.set("v.selectedContact", selectedContact);
  },

  updateTable: function (cmp, params) {
    console.log("update table 1 ::::: ");
    let rawResult = cmp.get("v.rawResult");
    let contactList = cmp.get("v.contactList");
    let selectedContact = cmp.get("v.selectedContact");
    let index = contactList.indexOf(selectedContact);
    let selectedContactName = selectedContact.name
      .replaceAll(" ", "-")
      .toLowerCase();
    let dupdata = cmp.get("v.dupesData");
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
        this.util.showToastError("This is already Confirmed");
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
    cmp.set("v.showDuplicatesModal", false);
  },

  prepareResult: function (contactList, contactMap) {
    let duplicateContactsMap = {};

    for (let contactRecord of contactList) {
      let fullNameKey =
        contactRecord.Converted_Full_Name__c?.toLowerCase() || "";
      let firstLastNameKey =
        (contactRecord.Converted_FirstName__c?.toLowerCase() || "") +
        (contactRecord.Converted_LastName__c?.toLowerCase() || "");

      if (contactMap[fullNameKey]) {
        let duplicateList = duplicateContactsMap[fullNameKey]
          ? duplicateContactsMap[fullNameKey]
          : [];
        duplicateList.push(contactRecord);
        duplicateContactsMap[fullNameKey] = duplicateList;
      }
      if (contactMap[firstLastNameKey] && firstLastNameKey !== fullNameKey) {
        let duplicateList = duplicateContactsMap[firstLastNameKey]
          ? duplicateContactsMap[firstLastNameKey]
          : [];
        duplicateList.push(contactRecord);
        duplicateContactsMap[firstLastNameKey] = duplicateList;
      }

      let isDuplicateFound = false;

      for (let existingKey of Object.keys(contactMap)) {
        let existingContact = contactMap[existingKey];
        let existingFullNameKey =
          existingContact["Converted_Full_Name__c"].toLowerCase();

        if (
          (existingContact["Business_Email__c"] &&
            existingContact["UUID__c"] != contactRecord.UUID__c &&
            (existingContact["Business_Email__c"] == contactRecord.Email ||
              existingContact["Business_Email__c"] ==
                contactRecord.Personal_Email_2__c ||
              existingContact["Business_Email__c"] ==
                contactRecord.Alternate_Email__c ||
              existingContact["Business_Email__c"] ==
                contactRecord.Business_Email_2__c ||
              existingContact["Business_Email__c"] ==
                contactRecord.Web_Email__)) ||
          contactRecord.Converted_Full_Name__c?.includes(
            existingContact["Converted_Full_Name__c"]
          )
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
          contactRecord.UUID__c &&
          existingContact["UUID__c"] == contactRecord.UUID__c &&
          contactRecord.Converted_Full_Name__c?.includes(
            existingContact["Converted_Full_Name__c"]
          )
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

      if (
        contactRecord.FirstName == contactRecord.Preferred_First_Name__c ||
        isDuplicateFound
      ) {
        continue;
      }

      // BRME-7012: Preferred First Name is an alternate first name for matching, so a contact whose
      // Preferred_First_Name__c equals the imported First Name (with matching Last Name) is a valid
      // potential duplicate even when there is no email match. The batch-wide SOQL in
      // DITCmpController.getDupeContactList already returns these candidates, but they were dropped here
      // because this block used to key them under a hyphenated "preferredName-lastName" key that no upload
      // row ever looks up (rows look up the whitespace-stripped "firstName+lastName" / converted-full-name
      // keys produced by the DITWorker getContacts map). Key by the same normalization the worker uses, and
      // file the candidate under the matching row's real lookup keys so each row is matched independently.
      if (contactRecord.Preferred_First_Name__c && contactRecord.LastName) {
        let preferredLookupKey = (
          contactRecord.Preferred_First_Name__c + contactRecord.LastName
        )
          .toLowerCase()
          .replace(/\s+/g, "");

        if (contactMap[preferredLookupKey]) {
          let matchedRow = contactMap[preferredLookupKey];
          let rowFirstLastKey = (
            (matchedRow["First_Name__c"] || "").trim() +
            (matchedRow["Last_Name__c"] || "").trim()
          ).toLowerCase();
          let rowFullNameKey = (matchedRow["Converted_Full_Name__c"] || "")
            .trim()
            .toLowerCase();
          for (let rowKey of [rowFirstLastKey, rowFullNameKey]) {
            if (rowKey && rowKey !== "nullnull") {
              let duplicateList = duplicateContactsMap[rowKey]
                ? duplicateContactsMap[rowKey]
                : [];
              if (
                !duplicateList.some(function (c) {
                  return c.Id === contactRecord.Id;
                })
              ) {
                duplicateList.push(contactRecord);
              }
              duplicateContactsMap[rowKey] = duplicateList;
            }
          }
        }
      }
    }

    return duplicateContactsMap;
  },

  setButtonVisibility: function (cmp) {
    let selected = cmp.get("v.selectedContact");
    let disableConfirm = true;
    let disabledCreateAsNew = true;

    for (let i = 0; i < selected.fields.length; i++) {
      if (selected.fields[i].api === "Contact_Alert_Reason__c") {
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
      if (state == "SUCCESS") {
        if (response.getReturnValue()) {
          this.util.showToastError(
            "Unable to create as a new contact, this UUID is already on an existing contact"
          );
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
      if (field.api === "Contact_Alert_Reason__c") {
        field.excel.isDiff = false;
        continue;
      }
      let excelVal = field.excel.value == null ? "" : String(field.excel.value);
      let sfVal = field.sf.value == null ? "" : String(field.sf.value);
      if (!excelVal.trim().length) {
        field.excel.isDiff = false;
        continue;
      }
      field.excel.isDiff =
        excelVal.trim().toLowerCase() !== sfVal.trim().toLowerCase();
    }
  }
});