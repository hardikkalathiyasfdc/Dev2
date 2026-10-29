({
  init: function (cmp, evt, helper) {
    helper.util = new cmputil();
    helper.init(cmp, cmp.get("v.list"), "ListTab");
    helper.init(cmp, cmp.get("v.contact"), "ContactTab");
    helper.loadSelectedTab(cmp);
  },
  tabSelected: function (cmp, evt, helper) {
    helper.loadSelectedTab(cmp);
  },
  prevPage: function (cmp, evt, helper) {
    let selectedTab = cmp.get("v.selectedTab");
    let myData =
      selectedTab === "ListTab" ? cmp.get("v.list") : cmp.get("v.contact");
    myData.curPage -= 1;
    helper.loadData(cmp, myData, selectedTab);
  },
  nextPage: function (cmp, evt, helper) {
    let selectedTab = cmp.get("v.selectedTab");
    let myData =
      selectedTab === "ListTab" ? cmp.get("v.list") : cmp.get("v.contact");
    myData.curPage += 1;
    helper.loadData(cmp, myData, selectedTab);
  }
});