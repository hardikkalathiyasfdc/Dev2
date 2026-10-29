({
  init: function (cmp, evt, helper) {
    helper.util = new cmputil();
    helper.setTags(cmp);
  },
  addTag: function (cmp, evt, helper) {
    let selected = evt.getParam("recordByEvent");
    helper.saveTag(cmp, selected);
  },
  removeTag: function (cmp, evt, helper) {
    let idx = Number(evt.getParam("index"));
    helper.removeTag(cmp, idx);
  }
});