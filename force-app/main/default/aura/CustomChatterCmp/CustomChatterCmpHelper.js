({
  init: function (cmp, myData, selectedTab) {
    let cmpName = this.getCmpName(selectedTab);
    myData.curPage = 0;
    myData.rows = [];
    myData.columns =
      selectedTab === "ListTab"
        ? this.getCampaignCols()
        : this.getContactCols();
    myData.pageSize = selectedTab === "ListTab" ? 50 : 100;
    cmp.set(cmpName, myData);
    cmp.set("v.hasNext", false);
    cmp.set("v.hasPrev", false);
  },
  loadSelectedTab: function(cmp){
    let selectedTab = cmp.get("v.selectedTab");
    let myData =
      selectedTab === "ListTab" ? cmp.get("v.list") : cmp.get("v.contact");
    myData.curPage = 0;
    this.loadData(cmp, myData, selectedTab);
  },
  loadData: function (cmp, myData, selectedTab) {
    cmp.set("v.isLoading", true);
    let params = { pageNum: myData.curPage, pageSize: myData.pageSize };
    let self = this;
    let controllerName =
      selectedTab === "ListTab" ? "getCampaignFeed" : "getContactFeed";
    self.util
      .controllerPromise(cmp, controllerName, params)
      .then((result) => {
        if (!result || !result.data || !result.data.length) {
          myData.rows = [];
          cmp.set(self.getCmpName(selectedTab), myData);
          cmp.set("v.isLoading", false);
          return;
        }
        console.log(result);
        for (let i = 0; i < result.data.length; i++) {
          self.formatChildren(result.data[i]);
        }
        myData.rows = result.data;
        cmp.set(self.getCmpName(selectedTab), myData);
        cmp.set("v.isLoading", false);
        self.setPages(myData.curPage, result.size, myData.pageSize, cmp);
        let tree =
          selectedTab === "ListTab"
            ? cmp.find("listTree")
            : cmp.find("contactTree");
        tree.expandAll();
      })
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  setPages: function (curPage, curSize, maxSize, cmp) {
    curSize = !isNaN(curSize) ? curSize : 0;
    let showNext = (curPage + 1) * maxSize < curSize && curSize > maxSize;
    let showPrev = curPage != 0;
    cmp.set("v.showNext", showNext);
    cmp.set("v.showPrev", showPrev);
  },
  formatChildren: function (data) {
    if (!data || !data.children) {
      return;
    }
    data._children = data.children;
    for (let i = 0; i < data.children.length; i++) {
      this.formatChildren(data.children[i]);
    }
    delete data.children;
  },
  getCmpName: function (selectedTab) {
    return selectedTab === "ListTab" ? "v.list" : "v.contact";
  },
  getCampaignCols: function (cmp) {
    const COLUMNS = [
      {
        type: "url",
        fieldName: "nameUrl",
        label: "List",
        typeAttributes: {
          label: { fieldName: "name" },
          target: '_blank'
        }
      },
      {
        type: "text",
        fieldName: "change",
        label: "Changes"
      },
      {
        type: "url",
        fieldName: "createdByUrl",
        label: "Modified By",
        typeAttributes: {
          label: { fieldName: "createdBy" },
          target: '_blank'
        }
      },
      {
        type: "text",
        fieldName: "modDate",
        label: "Modified Date"
      }
    ];
    return COLUMNS;
  },
  getContactCols: function (cmp) {
    const COLUMNS = [
      {
        type: "url",
        fieldName: "nameUrl",
        label: "Contact",
        typeAttributes: {
          label: { fieldName: "name" },
          target: '_blank'
        }
      },
      {
        type: "text",
        fieldName: "fieldName",
        label: "Field"
      },
      {
        type: "text",
        fieldName: "oldVal",
        label: "Old Value"
      },
      {
        type: "text",
        fieldName: "newVal",
        label: "New Value"
      },
      {
        type: "url",
        fieldName: "createdByUrl",
        label: "Modified By",
        typeAttributes: {
          label: { fieldName: "createdBy" },
          target: '_blank'
        }
      },
      {
        type: "text",
        fieldName: "modDate",
        label: "Modified Date"
      }
    ];
    return COLUMNS;
  }
});