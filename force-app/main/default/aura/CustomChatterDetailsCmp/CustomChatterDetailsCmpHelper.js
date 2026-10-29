({
  loadData: function (cmp) {
    let myId = this.getId(cmp);
    let sObject = this.getSobjectName(myId);
    let curPage = cmp.get("v.curPage");
    this.pageSize = 100;
    if (!sObject.length) {
      this.showError("Not a contact or campaign found with given id: " + myId);
      return;
    }

    if (sObject == "contact") {
      this.loadContacts(myId, curPage, cmp);
      return;
    }
    this.loadLists(myId, curPage, cmp);
  },
  loadLists: function (myId, curPage, cmp) {
    let params = { myId: myId };
    let self = this;
    this.util
      .controllerPromise(cmp, "getListDetails", params)
      .then((result) => {
        if (!result || !result.data) {
          return;
        }
        self.allData = result;
        let list = self.getListData(cmp, result);
        cmp.set("v.isLoading", false);
        cmp.set("v.list", list);
      })
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  loadContacts: function (myId, curPage, cmp) {
    let params = { myId: myId };
    let self = this;
    this.util
      .controllerPromise(cmp, "getContactDetails", params)
      .then((result) => {
        if (!result || !result.data) {
          return;
        }
        self.allData = result;
        let contact = self.getContactData(cmp, result);
        cmp.set("v.isLoading", false);
        cmp.set("v.contact", contact);
      })
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  showData: function (cmp, result) {
    let contact = cmp.get("v.contact");
    if (contact.data) {
      cmp.set("v.contact", this.getContactData(cmp, this.allData));
    } else {
      cmp.set("v.list", this.getListData(cmp, this.allData));
    }
  },
  getContactData: function (cmp, result) {
    let contact = cmp.get("v.contact");
    contact.name = result.data.name;
    contact.columns = this.getContactColumns();
    contact.data = [];
    contact.lists = {};
    contact.lists.columns = this.getContactListColumns();
    contact.lists.data = [];
    let j = 0;
    let curPage = cmp.get("v.curPage");
    let start = curPage * this.pageSize;
    let max = curPage * this.pageSize + this.pageSize;
    max = Math.min(max, result.data.children.length);
    for (let i = 0; i < result.data.children.length; i++) {
      let child = result.data.children[i];
      if (child.fieldName) {
        if (j >= start && j < max) {
          contact.data.push(child);
        }
        j++;
      } else {
        contact.lists.data.push(child);
      }
    }
    this.setPaginations(cmp, curPage, result);
    contact.offset = curPage * this.pageSize;
    return contact;
  },
  getListData: function (cmp, result) {
    let list = cmp.get("v.list");
    list.name = result.data.name;
    list.columns = this.getListColumns();
    list.data = [];
    let j = 0;
    let curPage = cmp.get("v.curPage");
    let start = curPage * this.pageSize;
    let max = curPage * this.pageSize + this.pageSize;
    max = Math.min(max, result.data.children.length);
    for (let i = 0; i < result.data.children.length; i++) {
      let child = result.data.children[i];
      if (j >= start && j < max) {
        list.data.push(child);
      }
      j++;
    }
    this.setPaginations(cmp, curPage, result);
    list.offset = curPage * this.pageSize;
    return list;
  },
  setPaginations: function (cmp, curPage, result) {
    let showPrev = curPage != 0;
    cmp.set("v.showPrev", showPrev);
    let showNext = (curPage + 1) * this.pageSize < result.data.children.length;
    cmp.set("v.showNext", showNext);
  },
  showError: function (msg) {
    errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
    cmp.set("v.isLoading", false);
    this.util.showToast("Error", errMsg, "error");
  },
  getId: function (cmp) {
    let pageRef = cmp.get("v.pageReference");
    let myId = pageRef != null && pageRef.state && pageRef.state.c__detailsId;
    return !myId ? cmp.get("v.detailsId") : myId;
  },
  getSobjectName: function (id) {
    if (!id || !id.length || id.length <= 3) {
      return "";
    }
    let prefix = id.substring(0, 3);
    if (prefix === "003") {
      return "contact";
    }

    if (prefix === "701") {
      return "list";
    }
    return "";
  },
  getContactListColumns: function () {
    const COLUMNS = [
      {
        type: "url",
        fieldName: "nameUrl",
          label: "List Name",
        typeAttributes: {
          label: { fieldName: "name" }
        }
      }
    ];
    return COLUMNS;
  },
  getContactColumns: function () {
    const COLUMNS = [
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
          label: { fieldName: "createdBy" }
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
  getListColumns: function () {
    const COLUMNS = [
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
          label: { fieldName: "createdBy" }
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