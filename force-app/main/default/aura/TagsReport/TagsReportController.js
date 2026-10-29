({
  init: function (cmp, event, helper) {
    helper.util = new cmputil();
    helper.setConfig(cmp);
  },
  addTag: function (cmp, evt, helper) {
    let selected = evt.getParam("recordByEvent");
    let cmpId = evt.getParam("cmpId");
    helper.addTag(selected, cmpId, cmp);
  },
  removeIncludeTag: function (cmp, evt, helper) {
    helper.removeTag("tagInclude", evt, cmp);
  },
  removeExcludeTag: function (cmp, evt, helper) {
    helper.removeTag("tagExclude", evt, cmp);
  },
  loadData: function(cmp, evt, helper){
    helper.loadTable(cmp);
  },
  export: function (cmp, evt, helper) {
    debugger;
    helper.export(cmp);
  }
});