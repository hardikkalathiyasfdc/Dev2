({
  init: function (cmp, event, helper) {
    console.log("contacts ::: " + JSON.stringify(cmp.get("v.contactList")));
    helper.util = new cmputil();
    helper.lockedColumns = {
      Organization_Name__c: true,
      Assistant_Name__c: true,
      First_Name__c: true,
      Last_Name__c: true
    };
    helper.requiredColumns = {
      First_Name__c: "FirstName",
      Last_Name__c: "LastName"
    };

    helper.defaultColumns = {
      First_Name__c: "FirstName",
      Last_Name__c: "LastName",
      Middle_Name__c: "MiddleName",
      Title__c: "Title",
      Organization_Name__c: "AccountId",
      Business_Email__c: "Email",
      Personal_Email__c: "Alternate_Email__c",
      Additional_Email__c: "Business_Email_2__c"
    };
    helper.editColumns = {
      First_Name__c: true,
      Last_Name__c: true,
      Middle_Name__c: true,
      Title__c: true,
      Preferred_First_Name__c: true,
      Business_Email__c: true,
      Suffix__c: true,
      Personal_Email__c: true,
      Additional_Email__c: true
    };

    helper.columnMap = {
      FirstName: "FirstName",
      LastName: "LastName",
      First_Name__c: "FirstName",
      Last_Name__c: "LastName",
      Organization_Name__c: "AccountId",
      Title__c: "Title",
      Salutation__c: "Salutation",
      Middle_Name__c: "MiddleName",
      Suffix__c: "Suffix",
      Preferred_First_Name__c: "Preferred_First_Name__c",
      Business_Email__c: "Email",
      Personal_Email__c: "Alternate_Email__c",
      Additional_Email__c: "Business_Email_2__c",
      Personal_Email_2__c: "Personal_Email_2__c",
      HomePhoneCountryCode__c: "HomePhoneCountryCode__c",
      HomePhone__c: "HomePhone",
      Mobile_Phone_Country_Code__c: "Mobile_Phone_Country_Code__c",
      Cell__c: "MobilePhone",
      AdditionalPhoneCountryCode__c: "AdditionalPhoneCountryCode__c",
      AdditionalPhone__c: "AdditionalPhone__c",
      Business_Phone__c: "Phone",
      Business_Phone_Country_Code__c: "Office_Phone_Country_Code__c",
      Business_Street_1__c: "MailingStreet",
      Business_City__c: "MailingCity",
      Business_State__c: "MailingState",
      Business_Postal_Code__c: "MailingPostalCode",
      Business_Country__c: "MailingCountry",
      Home_Street_1__c: "OtherStreet",
      Home_City__c: "OtherCity",
      Home_State__c: "OtherState",
      Home_Postal_Code__c: "OtherPostalCode",
      Home_Country__c: "OtherCountry",
      UUID__c: "UUID__c",
      Preferred_Last_Name__c: "Preferred_Last_Name__c"
    };

    cmp.set("v.columns", [
      { label: "First Name", api: "FirstName", type: "HYPERLINK" },
      { label: "Middle Name", api: "MiddleName", type: "STRING" },
      { label: "Last Name", api: "LastName", type: "HYPERLINK" },
      {
        label: "Preferred First Name",
        api: "Preferred_First_Name__c",
        type: "STRING"
      },
      { label: "Title", api: "Title", type: "STRING" },
      { label: "Organization Name", api: "Account.Name", type: "STRING" },
      { label: "Business Email", api: "Email", type: "STRING" },
      { label: "Personal Email", api: "Alternate_Email__c", type: "STRING" },
      { label: "Additional Email", api: "Business_Email_2__c", type: "STRING" },
      { label: "Business Phone", api: "Phone", type: "STRING" },
      { label: "Mobile Phone", api: "MobilePhone", type: "STRING" },
      { label: "Additional Phone", api: "AdditionalPhone__c", type: "STRING" },
      { label: "Significant Other", api: "Significant_Name__c", type: "STRING" }
    ]);

    helper.loadData(cmp);
  },
  // BRME-6786: reusableLookup reports whether the + button will show potential duplicates for a row;
  // update the org error message to match the actual resolution flow.
  handleCandidatesChecked: function (cmp, event, helper) {
    let detail = event.getParam("detail") || event.detail || {};
    if (!detail.dlRecordId && event.getParams) {
      detail = Object.assign({}, event.getParams(), detail);
    }
    helper.updateOrgMessage(cmp, detail);
  },
  handleValueSelected2: function (cmp, event, helper) {
    debugger;
    let record = {};
    let selectedRecord = event.getParam("selectedRecord");
    let fieldChanged = selectedRecord.fieldChanged;
    let recordName = selectedRecord.mainField;
    let selectedRecordId = selectedRecord.id;
    record.Id = selectedRecord.dlRecordId;

    if (fieldChanged == "Organization_Name__c") {
      record.Organization__c = selectedRecordId;
      record.Organization_Name__c = recordName;
      record.Organization_Id__c = selectedRecordId;
    }
    helper.util
      .controllerPromise(cmp, "updateDataRecord", {
        dataRecord: record
      })
      .then(
        $A.getCallback(function (data) {
          helper.updateError(cmp, fieldChanged, selectedRecord.dlRecordId);
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        console.log(errMsg);
        self.util.showToastError(errMsg);
      });
  },
  handleValueSelected: function (cmp, event, helper) {
    cmp.set("v.isLoading", true);
    let updateRecords = [];
    let updateRecordIds = [];
    let selectedRecord = event.getParam("selectedRecord");
    let fieldChanged = selectedRecord.fieldChanged;
    let recordName = selectedRecord.mainField;
    let selectedRecordId = selectedRecord.id;
    let dlrecordName = "";
    let unconfirmedRecords = cmp.get("v.unconfirmedRecords");
    for (let dlRecord of unconfirmedRecords) {
      if (selectedRecord.dlRecordId == dlRecord.Id) {
        if (fieldChanged == "Organization_Name__c")
          dlrecordName = dlRecord.Organization_Name__c;
      }
    }
    for (let dlRecord of unconfirmedRecords) {
      if (
        selectedRecord.dlRecordId == dlRecord.Id ||
        (dlrecordName &&
          fieldChanged == "Organization_Name__c" &&
          dlRecord.Organization_Name__c &&
          dlRecord.Organization_Name__c.toLowerCase() ==
            dlrecordName.toLowerCase()) //&& !selectedRecord.akaMatch
      ) {
        let record = {};
        record.Id = dlRecord.Id;

        if (fieldChanged == "Organization_Name__c") {
          record.Organization__c = selectedRecordId;
          record.Organization_Name__c = recordName;
          record.Organization_Id__c = selectedRecordId;
          dlRecord.Organization__c = selectedRecordId;
          dlRecord.Organization_Name__c = recordName;
          dlRecord.Organization_Id__c = selectedRecordId;
          dlRecord.orgError = false;
          if (!updateRecordIds.includes(record.Id)) {
            record.IsReviewValidate__c = true;
            updateRecords.push(record);
            updateRecordIds.push(record.Id);
          }
        }
      }
    }
    if (updateRecords.length > 0) {
      helper.util
        .controllerPromise(cmp, "updateDataRecords", {
          dataRecords: updateRecords,
          isSignficantOther:
            fieldChanged == "Significant_Other__c" ? true : false
        })
        .then(
          $A.getCallback(function (data) {
            cmp.set("v.isLoading", false);
            cmp.set("v.unconfirmedRecords", unconfirmedRecords);
          })
        )
        .catch((errMsg) => {
          cmp.set("v.isLoading", false);
          console.log(errMsg);
          helper.util.showToastError(errMsg);
        });
    } else {
      cmp.set("v.isLoading", false);
      cmp.set("v.isDataLoaded", true);
    }
  },
  handleInputChange: function (cmp, event, helper) {
    debugger;
    let unconfirmedRecords = cmp.get("v.unconfirmedRecords");
    let value = event.getSource().get("v.value");
    let recId = event.getSource().get("v.name");
    let record = {};
    for (let rec of unconfirmedRecords) {
      if (rec.Id == recId && record.UUID__c != value) {
        record.Id = rec.Id;
        record.IsReviewValidate__c = true;
        rec.UUID__c = value;
        record.UUID__c = value;
        rec.isError = false;
        rec.errorMsg = "";
      }
    }

    let self = this;
    cmp.set("v.isLoading", true);

    helper.util
      .controllerPromise(cmp, "updateDataRecord", { dataRecord: record })
      .then(
        $A.getCallback(function (data) {
          cmp.set("v.unconfirmedRecords", unconfirmedRecords);
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
      });
  }
});