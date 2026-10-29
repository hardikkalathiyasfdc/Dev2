({
  loadData: function (cmp) {
    let self = this;
    let startTime = cmp.get("v.startTime");
    let endTime = cmp.get("v.endTime");
    startTime = startTime != null && startTime != "" ? startTime : null;
    endTime = endTime != null && endTime != "" ? endTime : null;
    let params = {
      startTime: startTime,
      endTime: endTime
    };
    cmp.set("v.isLoading", true);
    this.util
      .controllerPromise(cmp, "getData", params)
      .then(
        $A.getCallback(function (result) {
          cmp.set("v.isLoading", false);
          result = result != null ? result : {};
          result.data = result.data != null ? result.data : [];
          cmp.set("v.curPage", 0);
          cmp.set("v.reportExtract", result);
          self.setFilters(cmp, result.data);
          self.setData(cmp);
          cmp.set("v.startTime", result.startTime);
          cmp.set("v.endTime", result.endTime);
        })
      )
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  setData: function (cmp) {
    let reportExtract = cmp.get("v.reportExtract");
    let curPage = cmp.get("v.curPage");
    reportExtract = reportExtract != null ? reportExtract : {};
    reportExtract.data = reportExtract.data != null ? reportExtract.data : [];
    curPage = curPage != null ? curPage : 0;
    reportExtract.offset = curPage * this.maxSize;
    reportExtract.rows = [];
    let filteredRows = this.getFilteredRows(reportExtract, cmp);
    let start = curPage * this.maxSize;
    let max = start + this.maxSize;
    max = Math.min(filteredRows.length, max);
    for (let i = start; i < max; i++) {
      reportExtract.rows.push(filteredRows[i]);
    }
    let showPrev = curPage != 0;
    cmp.set("v.showPrev", showPrev);
    let showNext = (curPage + 1) * this.maxSize <= filteredRows.length;
    cmp.set("v.showNext", showNext);
    cmp.set("v.reportExtract", reportExtract);
    if (reportExtract.data.length > 20000) {
      this.util.showToast(
        "Info",
        "There are more 20,000 report events that occurred between the time periods selected, older results may be lost",
        "info"
      );
    }
  },
  getFilteredRows: function (reportExtract, cmp) {
    let filter = cmp.get("v.filterCols");
    let filteredRows = [];
    for (let i = 0; i < reportExtract.data.length; i++) {
      let extract = reportExtract.data[i];
      if (this.isViewable(extract, filter)) {
        extract.reportName =
          extract.reportName && extract.reportName.length
            ? extract.reportName
            : extract.reportId;

        filteredRows.push(extract);
      }
    }
    return filteredRows;
  },
  export: function (cmp) {
    let cols = cmp.get("v.columns");
    let data = "";
    let colKeys = [];
    for (let i = 0; i < cols.length; i++) {
      let col = cols[i];
      data += this.getCsvFormatted(col.label);
      if (i < cols.length - 1) {
        data += ",";
      } else {
        data += "\n";
      }
      let key =
        col.type != "url" ? col.fieldName : col.typeAttributes.label.fieldName;
      colKeys.push(key);
    }
    let reportExtract = cmp.get("v.reportExtract");
    let filteredRows = this.getFilteredRows(reportExtract, cmp);
    for (let i = 0; i < filteredRows.length; i++) {
      for (let j = 0; j < colKeys.length; j++) {
        data += this.getCsvFormatted(filteredRows[i][colKeys[j]]);
        if (j < colKeys.length - 1) {
          data += ",";
        } else {
          data += "\n";
        }
      }
    }
    this.download(data);
  },
  getCsvFormatted: function (d) {
    d = d != null ? d : "";
    let regExp = new RegExp('"', "g");
    return '"' + d.replace(regExp, '\\"') + '"';
  },
  download: function (data) {
    data = !data ? "" : data;
    let hiddenElement = document.createElement("a");
    hiddenElement.href = "data:text/csv;charset=utf-8," + encodeURI(data);
    hiddenElement.target = "_self";
    hiddenElement.download =
      "Report Monitoring " + this.getFormattedTime() + ".csv";
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
  isViewable: function (extract, filter) {
    for (let key in extract) {
      if (filter[key] && !filter[key].all && !filter[key][extract[key]]) {
        return false;
      }
    }
    return true;
  },
  setFilters: function (cmp, data) {
    let cols = cmp.get("v.columns");
    let filter = {};
    let colMap = {};
    for (let i = 0; i < cols.length; i++) {
      let col = cols[i];
      let colKey =
        col.type != "url" ? col.fieldName : col.typeAttributes.label.fieldName;
      if (col.iconName) {
        delete col.iconName;
      }
      filter[colKey] = {};
      filter[colKey].all = true;
      colMap[colKey] = i;
    }
    let actionMap = {};
    for (let i = 0; i < data.length; i++) {
      let item = data[i];
      for (let key in item) {
        if (filter[key]) {
          filter[key][item[key]] = false;
          let colIdx = colMap[key];
          actionMap[colIdx] = actionMap[colIdx] ? actionMap[colIdx] : {};
          actionMap[colIdx][item[key]] = true;
        }
      }
    }
    cmp.set("v.filterCols", filter);
    for (let key in actionMap) {
      let col = cols[key];
      col.actions = [{ label: "All", checked: true, name: "all" }];
      for (let item in actionMap[key]) {
        col.actions.push({ label: item, checked: false, name: item });
      }
    }
    cmp.set("v.columns", cols);
  },
  initColumns: function (cmp) {
    let cols = [
      {
        label: "Report Name",
        fieldName: "reportUrl",
        type: "url",
        hideDefaultActions: true,
        typeAttributes: { label: { fieldName: "reportName" } }
      },
      {
        label: "List Name",
        fieldName: "listUrl",
        type: "url",
        hideDefaultActions: true,
        typeAttributes: { label: { fieldName: "listName" } }
      },
      {
        label: "User",
        fieldName: "userUrl",
        type: "url",
        hideDefaultActions: true,
        typeAttributes: { label: { fieldName: "userName" } }
      },
      {
        label: "User's Team",
        fieldName: "userTeam",
        type: "text",
        hideDefaultActions: true
      },
      {
        label: "Operation",
        fieldName: "operation",
        type: "text",
        hideDefaultActions: true
      },
      {
        label: "Event Date",
        fieldName: "eventDate",
        type: "date",
        hideDefaultActions: true
      },
      {
        label: "Rows Processed",
        fieldName: "rowsProcessed",
        type: "text",
        hideDefaultActions: true
      }
    ];
    cmp.set("v.columns", cols);
  },
  initOptions: function (cmp) {
    cmp.set("v.isLoading", true);
    let self = this;
    this.util
      .controllerPromise(cmp, "getOptions")
      .then(
        $A.getCallback(function (result) {
          if (!result) {
            cmp.set("v.isLoading", false);
            return;
          }
          cmp.set("v.options", result);
        })
      )
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  }
});