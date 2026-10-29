({
  setConfig: function (cmp) {
    let self = this;
    this.util
      .controllerPromise(cmp, "getConfig")
      .then((result) => {
        if (!result) {
          return;
        }
        self.setOptions(result, "contact", cmp);
        self.setOptions(result, "list", cmp);
        cmp.set("v.isLoading", false);
      })
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  setOptions: function (result, tag, cmp) {
    let optTag = tag + "Options";
    let options = result[optTag] ? result[optTag] : [];
    optTag = "v." + optTag;
    cmp.set(optTag, options);
    let valTag = tag + "Fields";
    let vals = result[valTag] ? result[valTag] : [];
    valTag = "v." + valTag;
    cmp.set(valTag, vals);
  },
  export: function (cmp) {
    cmp.set("v.isLoading", true);
    let listId = cmp.find("inputListId").get("v.value");
    let contactFields = cmp.get("v.contactFields");
    let listFields = cmp.get("v.listFields");
    let params = {
      listId: listId,
      listFields: listFields,
      contactFields: contactFields
    };
    let self = this;
    this.util
      .controllerPromise(cmp, "getCSV", params)
      .then((result) => {
        if (!result) {
          cmp.set("v.isLoading", false);
          return;
        }

        var hiddenElement = document.createElement("a");
        let data = self.getCSV(result, contactFields, listFields);
        if (!data || data == "") {
          return;
        }
        hiddenElement.href = "data:text/csv;charset=utf-8," + encodeURI(data);
        hiddenElement.target = "_self";
        hiddenElement.download = "ExportData.csv";
        document.body.appendChild(hiddenElement);
        hiddenElement.click();

        cmp.set("v.isLoading", false);
      })
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  getCSV: function (result, contactFields, listFields) {
    let csv = "";
    if (
      !result ||
      !result.data ||
      !result.data.length ||
      !result.cols ||
      !result.cols.length
    ) {
      return csv;
    }
    csv = result.cols;
    for (let i = 0; i < result.data.length; i++) {
      let data = result.data[i];
      let line = this.getCSVLine(data, contactFields, listFields);
      if (line && line.length) {
        csv += line;
      }
    }
    return csv;
  },
  getCSVLine: function (data, contactFields, listFields) {
    let line = "";
    for (let i = 0; i < contactFields.length; i++) {
      let field = "contact." + contactFields[i];
      let fieldName = field + "Name";
      if (data[fieldName] != null) {
        line += this.getCSVVal(data[fieldName]) + ",";
      } else if (data[field] != null) {
        line += this.getCSVVal(data[field]) + ",";
      } else {
        line += ",";
      }
    }

    for (let i = 0; i < listFields.length; i++) {
      let field = "list." + listFields[i];
      let fieldName = field + "Name";
      if (data[fieldName] != null) {
        line += this.getCSVVal(data[fieldName]) + ",";
      } else if (data[field] != null) {
        line += this.getCSVVal(data[field]) + ",";
      } else {
        line += ",";
      }
    }
    return line.length ? line.substring(0, line.length - 1) + "\n" : line;
  },
  getCSVVal: function (val) {
    if (typeof val == "boolean") {
      return val + "";
    }
    if (!val) {
      return "";
    }
    val = val + "";
    val = val.replace(/\\/g, "\\\\").replace(/\\/g, '\\"');
    return '"' + val + '"';
  },
  loadData: function (cmp) {
    cmp.set("v.isLoading", true);
    let listId = cmp.find("inputListId").get("v.value");
    let contactFields = cmp.get("v.contactFields");
    let listFields = cmp.get("v.listFields");
    let curPage = cmp.get("v.curPage");
    if (!listId || listId == "") {
      return;
    }

    cmp.set("v.isLoading", true);
    let params = {
      listId: listId,
      listFields: listFields,
      contactFields: contactFields,
      curPage: curPage
    };
    let self = this;
    this.util
      .controllerPromise(cmp, "getData", params)
      .then((result) => {
        if (!result) {
          cmp.set("v.isLoading", false);
          return;
        }
        cmp.set("v.contactLists", result);
        cmp.set("v.showPrev", curPage != 0);
        let showNext = (curPage + 1) * result.pageSize < result.size;
        cmp.set("v.showNext", showNext);
        cmp.set("v.rowOffset", curPage * result.pageSize);
        cmp.set("v.isLoading", false);
      })
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  }
});