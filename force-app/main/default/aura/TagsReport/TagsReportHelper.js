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
  loadTable: function (cmp) {
    let contactFields = cmp.get("v.contactFields");
    let includeTags = this.getTagIds("tagInclude", cmp);
    let excludeTags = this.getTagIds("tagExclude", cmp);
    this.initTable(cmp);
    if (!includeTags.length) {
      return;
    }
    cmp.set("v.isLoading", true);
    let params = {
      contactFields: contactFields,
      includeTags: includeTags,
      excludeTags: excludeTags
    };

    let self = this;
    this.util
      .controllerPromise(cmp, "getData", params)
      .then((result) => {
        cmp.set("v.isLoading", false);
        if (!result) {
          return;
        }
        cmp.set("v.tagResults", result);
      })
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  initTable: function (cmp) {
    cmp.set("v.tagResults", {});
    cmp.set("v.showPrev", false);
    cmp.set("v.showNext", false);
    cmp.set("v.rowOffset", 0);
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
  addTag: function (tag, cmpId, cmp) {
    let tagList = this.getTagList(cmpId, cmp);

    for (let i = 0; i < tagList.length; i++) {
      let check = tagList[i];
      if (check.id == tag.Id) {
        return;
      }
    }
    let url = "/lightning/r/Tag__c/" + tag.Id + "/view";
    tagList.push({
      id: tag.Id,
      label: tag.Name,
      href: url
    });
    this.setTagList(tagList, cmpId, cmp);

    this.loadTable(cmp);
  },
  removeTag: function (cmpId, evt, cmp) {
    let idx = Number(evt.getParam("index"));
    let tagList = this.getTagList(cmpId, cmp);
    tagList.splice(idx, 1);
    this.setTagList(tagList, cmpId, cmp);

    this.loadTable(cmp);
  },
  getTagIds: function (cmpId, cmp) {
    let idList = [];
    let tagList = this.getTagList(cmpId, cmp);
    for (let i = 0; i < tagList.length; i++) {
      let tag = tagList[i];
      idList.push(tag.id);
    }
    return idList;
  },
  getTagList: function (cmpId, cmp) {
    if (cmpId == "tagExclude") {
      return cmp.get("v.excludeTags");
    }
    return cmp.get("v.includeTags");
  },
  setTagList: function (tagList, cmpId, cmp) {
    if (cmpId == "tagExclude") {
      cmp.set("v.excludeTags", tagList);
    } else {
      cmp.set("v.includeTags", tagList);
    }
  },
  export: function (cmp) {
    let data = this.getCSV(cmp.get("v.tagResults"), cmp.get("v.contactFields"));
    if (!data || data == "") {
      return;
    }
    var hiddenElement = document.createElement("a");
    hiddenElement.href = "data:text/csv;charset=utf-8," + encodeURI(data);
    hiddenElement.target = "_self";
    hiddenElement.download =
      "ExportTagData " + this.getFormattedTime() + ".csv";
    document.body.appendChild(hiddenElement);
    hiddenElement.click();
  },
  getFormattedTime: function () {
    var today = new Date();
    var y = today.getFullYear();
    var m = today.getMonth() + 1;
    var d = today.getDate();
    var h = today.getHours();
    var mi = today.getMinutes();
    var s = today.getSeconds();
    return y + "-" + m + "-" + d + "-" + h + "-" + mi + "-" + s;
  },
  getCSV: function (result, contactFields) {
    let csv = "";
    if (
      !result ||
      !result.data ||
      !result.data.length ||
      !result.columns ||
      !result.columns.length
    ) {
      return csv;
    }
    let headers = "";
    for (let i = 0; i < result.columns.length; i++) {
      let col = result.columns[i];
      let label = col.label;
      headers += this.getCSVVal(label);
      if (i < result.columns.length - 1) {
        headers += ",";
      } else {
        headers += "\n";
      }
    }
    csv = headers;
    for (let i = 0; i < result.data.length; i++) {
      let data = result.data[i];
      let line = this.getCSVLine(data, contactFields);
      if (line && line.length) {
        csv += line;
      }
    }
    return csv;
  },
  getCSVLine: function (data, contactFields) {
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
    line += this.getCSVVal(data.tags);
    return line.length ? line + "\n" : "";
  },
  getCSVVal: function (val) {
    if (typeof val == "boolean") {
      return val + "";
    }
    if (!val) {
      return "";
    }
    val = val + "";
    let regExp = new RegExp('"', "g");
    val = val.replace(regExp, '""');
    return '"' + val + '"';
  }
});