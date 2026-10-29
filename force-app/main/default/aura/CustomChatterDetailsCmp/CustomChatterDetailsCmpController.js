({
  init: function (cmp, evt, helper) {
    helper.util = new cmputil();
    let myId = helper.getId(cmp);
    cmp.set("v.detailsId", myId);
    helper.loadData(cmp);
  },
  prevPage: function (cmp, evt, helper) {
    let curPage = cmp.get("v.curPage");
    curPage -= 1;
    cmp.set("v.curPage", curPage);
    helper.showData(cmp);
  },
  nextPage: function (cmp, evt, helper) {
    let curPage = cmp.get("v.curPage");
    curPage += 1;
    cmp.set("v.curPage", curPage);
    helper.showData(cmp);
  }
});