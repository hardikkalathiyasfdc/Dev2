({
  init: function (cmp, event, helper) {
    helper.util = new cmputil();
    debugger;
    helper.setListInfo(cmp);
    cmp.set("v.isConfirm", false);
  },
  close: function (component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },
  selectTag: function (cmp, evt, helper) {
    let selected = evt.getParam("recordByEvent");
    cmp.set("v.selected", selected);
  },
  handleSubmit: function (cmp, event, helper) {
    event.preventDefault(); // stop the form from submitting
    var fields = event.getParam("fields");
    if (!fields.Tag__c || fields.Tag__c == "") {
      helper.util.showToast("Error", "Please select a tag to add", "error");
      return;
    }
    cmp.set("v.selectedTagId", fields.Tag__c);
    helper.save(cmp);
  }
});