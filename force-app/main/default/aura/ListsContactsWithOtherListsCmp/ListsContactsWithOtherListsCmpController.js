({
  init: function (cmp, event, helper) {
    helper.util = new cmputil();
    helper.setConfig(cmp);
  },
  loadData: function (cmp, event, helper) {
    helper.loadData(cmp);
  },
  handleKeyUp: function (cmp, event, helper) {
    if (event.which == 13) {
      helper.loadData(cmp);
    }
  },
  prevPage: function (cmp, evt, helper) {
    let curPage = cmp.get("v.curPage");
    curPage -= 1;
    cmp.set("v.curPage", curPage);
    helper.loadData(cmp);
  },
  nextPage: function (cmp, evt, helper) {
    let curPage = cmp.get("v.curPage");
    curPage += 1;
    cmp.set("v.curPage", curPage);
    helper.loadData(cmp);
  },
  export: function (cmp, evt, helper) {
    helper.export(cmp);
  }
});