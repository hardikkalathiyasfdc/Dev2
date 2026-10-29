({
  init: function (cmp, event, helper) {
    helper.util = new cmputil();
    cmp.set("v.listId", cmp.get("v.recordId"));    
  },
  close: function (component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },
  handleSuccess: function (cmp, event, helper) {
    let msg = "New " + cmp.get("v.selectedRecordTypeName") + " Created";
    var params = event.getParams();
    var recordId = params.response.id;
    helper.util.showToast("Success", msg, "success");
    $A.get("e.force:refreshView").fire();
    $A.get("e.force:closeQuickAction").fire();
  },
  handleChange : function (cmp, event, helper) {
    var selectedOptionValue = event.getParam("value");
    var recordTypes = cmp.get("v.recordTypeMap");
    cmp.set("v.recordTypeId", selectedOptionValue);
    for(var key in recordTypes) {
      var recType = recordTypes[key];
      if(recType.value == selectedOptionValue) {
        cmp.set("v.selectedRecordTypeName", recType.label);
        break;
      }
    }
  },
  handleError : function (cmp, event, helper) {
    console.log('######handleError');
    var record = event.getParam("error");
    console.log('######handleError-error: ' + JSON.stringify(record));
  },
  handleTypeChange : function (cmp, event, helper) {
    console.log('######handleTypeChange');
    var selectedType = event.getParam("value");
    console.log('######handleTypeChange-selectedType: ' + selectedType);
    if (selectedType === "Donor") {
      console.log('######handleTypeChange-Donor');
      cmp.set("v.selectedTypeName", "Donor");
      cmp.set("v.titleInfo", "Donor Information");
      cmp.set("v.donorTypeLabel", "Donor Type");
      cmp.set("v.contactLabel", "Donor Individual");
      cmp.set("v.organizationLabel", "Donor Organization");
      cmp.set("v.notesLabel", "Donor Notes");     
    } else if (selectedType === "Prospect") {
      console.log('######handleTypeChange-Prospect');
      cmp.set("v.selectedTypeName", "Prospect");
      cmp.set("v.titleInfo", "Prospect Information");
      cmp.set("v.donorTypeLabel", "Prospect Type");
      cmp.set("v.contactLabel", "Prospect Individual");
      cmp.set("v.organizationLabel", "Prospect Organization");
      cmp.set("v.notesLabel", "Prospect Notes");
      cmp.set("v.statusLabel", "Prospect Status");
      cmp.set("v.priorityLabel", "Prospect Priority");
    }
  }

  /*handleOnSubmit : function(cmp, event, helper) {
    event.preventDefault();
    var eventFields = event.getParam("fields");
    console.log('###########handleOnSubmit-recordTypeId: ' + cmp.get("v.recordTypeId"));
    eventFields["recordTypeId"] = cmp.get("v.recordTypeId");
    console.log('###########handleOnSubmit-eventFields: ' + JSON.stringify(eventFields));
    cmp.find('listMemberCreateForm').submit(eventFields);
  },*/
});