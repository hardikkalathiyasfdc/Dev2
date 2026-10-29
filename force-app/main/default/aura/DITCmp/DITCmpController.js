({
  init: function (component, event, helper) {
    helper.util = new cmputil();
    // BRME-4862: wider batches so Map Columns -> Next pays fewer round-trips on large files.
    helper.batchSize = 200;
    helper.columnMap = {
      First_Name__c: "FirstName",
      Last_Name__c: "LastName",
      Organization_Id__c: "AccountId",
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
      Dietary__c: "Dietary__c",
      UUID__c: "UUID__c",
      Preferred_Last_Name__c: "Preferred_Last_Name__c"
    };
  },
  handleBack: function (cmp, event, helper) {
    let stage = cmp.get("v.stage");
    if (stage == "setup") {
      cmp.set("v.stage", "loadFile");
    }

    if (stage == "preview") {
      cmp.set("v.showPreviewBackWarning", true);
    }

    if (stage == "unconfirm") {
      // BRME-4862: when Preview was skipped (clean file), Back returns to Map Columns.
      if (cmp.get("v.skippedPreview")) {
        cmp.set("v.stage", "setup");
      } else {
        cmp.set("v.stage", "preview");
      }
    }
    if (stage == "contact") {
      cmp.set("v.stage", "unconfirm");
    }
    if (stage == "create") {
      cmp.set("v.stage", "contact");
    }
  },
  handleDone: function (cmp, event, helper) {
    let createValue = cmp.get("v.createValue");
    let params = {};
    params.offset = 0;
    params.batchSize = 20;
    params.columnMap = helper.columnMap;
    params.dataLoaderId = cmp.get("v.dataLoaderId");
    helper.LightningConfirm.open({
      message: "Are you sure you want to create and modify these contacts?",
      theme: "warning",
      label: "Please Confirm"
    }).then(function (result) {
      // result is true if clicked "OK"
      // result is false if clicked "Cancel"
      console.log("confirm result is", result);
      if (result) {
        if (createValue == "existingList") {
          let sel = cmp.get("v.selectedList");
          if (!sel || !sel.Id || !sel.Id.length) {
            helper.util.showToastError(
              "You must select a list from the search bar."
            );
            return;
          }
          params.listId = sel.Id;
        } else if (createValue == "newList") {
          let name = cmp.get("v.newListName");
          if (!name || !name.length) {
            helper.util.showToastError("You enter a new list name.");
            return;
          }
          params.listName = name;
        }
        helper.finish(cmp, params);
      }
    });
  },
  handleNext: function (cmp, event, helper) {
    let stage = cmp.get("v.stage");
    console.log(stage);
    cmp.set("v.isLoading", true);
    if (stage == "setup") {
      helper.handleSetupNext(cmp);
    }

    if (stage == "preview") {
      cmp.set("v.isStageChange", true);
      helper.previewNext(cmp);
    }
    if (stage == "contact") {
      helper.contactNext(cmp);
    }
    if (stage == "unconfirm") {
      helper.unconfirmNext(cmp);
    }

    cmp.set("v.isLoading", false);
  },
  handlePreviousSetup: function (cmp, event, helper) {
    cmp.set("v.stage", "loadFile");
  },
  handlePreviewBtn: function (cmp, event, helper) {
    helper.showPreview(cmp);
  },
  showSetup: function (cmp) {
    cmp.set("v.showPreviewBackWarning", false);
    cmp.set("v.stage", "setup");
  },
  setupNext: function (cmp, event, helper) {
    cmp.set("v.showPreviewBackWarning", false);
    cmp.set("v.showSetupWarning", false);
    helper.setupNext(cmp);
  },
  closeSetupWarning: function (cmp) {
    cmp.set("v.showSetupWarning", false);
  },
  closePreviewWarning: function (cmp) {
    cmp.set("v.showPreviewBackWarning", false);
  },
  closePreviewError: function (cmp) {
    cmp.set("v.showPreviewError", false);
  },
  // BRME-4862: Preview reported zero errors -> skip it and go straight to Review Errors.
  handleSkipPreview: function (cmp, event, helper) {
    cmp.set("v.skippedPreview", true);
    cmp.set("v.isLoading", true);
    let data = { Id: cmp.get("v.dataLoaderId"), Stage__c: "unconfirm" };
    helper.util
      .controllerPromise(cmp, "updateData", { data: data })
      .then(
        $A.getCallback(function () {
          cmp.set("v.isLoading", false);
          helper.showContact(cmp);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        helper.util.showToastError(errMsg);
      });
  },
  closeDupeModal: function (cmp, event, helper) {
    cmp.set("v.showDupe", false);
  },
  handleStageClick: function (cmp, event, helper) {
    let stage = event.currentTarget.name;
    if (!stage) {
      return;
    }
    cmp.set("v.stage", stage);
  }
});