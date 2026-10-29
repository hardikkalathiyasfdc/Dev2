({
  init: function (cmp) {
    let self = this;
    let setupCols = [
      { label: "BRM Field", isSort: false, type: "STRING" },
      { label: "Excel Column", isSort: false, type: "PICKLIST" }
    ];
    cmp.set("v.sfColumns", setupCols);
    cmp.set("v.isLoading", true);
    this.util
      .controllerPromise(cmp, "getColumns")
      .then(
        $A.getCallback(function (sfCols) {
          self.sfColumns = sfCols;
          let params = { dataId: cmp.get("v.dataLoaderId") };
          return self.util.controllerPromise(cmp, "getSetupColumns", params);
        })
      )
      .then(
        $A.getCallback(function (excelColumns) {
          if (excelColumns) {
            self.hasColumns = true;
            self.excelColumns = excelColumns;
            cmp.set("v.excelColumns", excelColumns);
            return null;
          }
          self.hasColumns = false;
          let params = { dataId: cmp.get("v.dataLoaderId") };
          return self.util.controllerPromise(cmp, "getExcelColumns", params);
        })
      )
      .then(
        $A.getCallback(function (excelColumns) {
          if (self.hasColumns) {
            return null;
          }
          let params = {};
          params.type = "setup init";
          params.sfColumns = self.sfColumns;
          params.excelColumns = excelColumns;
          return self.util.runWorker("$Resource.DITWorker", params);
        })
      )
      .then(
        $A.getCallback(function (excelColumns) {
          if (self.hasColumns) {
            return self.excelColumns;
          }
          self.excelColumns = excelColumns;
          return self.util.controllerPromise(cmp, "getColMap", {
            dataId: cmp.get("v.dataLoaderId")
          });
        })
      )
      .then(
        $A.getCallback(function (results) {
          if (results) {
            return results;
          }
          return self.cleanPicklists(self.excelColumns);
        })
      )
      .then(
        $A.getCallback(function (excelColumns) {
          self.excelColumns = excelColumns;
          let params = {
            dataRecordId: cmp.get("v.dataLoaderId"),
            colMap: excelColumns
          };
          return self.util.controllerPromise(cmp, "updateSetupColumns", params);
        })
      )
      .then(
        $A.getCallback(function () {
          cmp.set("v.excelColumns", self.excelColumns);
          cmp.find("myTable").setWidth();
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.util.showToastError(errMsg);
        cmp.set("v.stage", "loadFile");
      });
  },
  getDataLoadCols: function (dataLoad) {
    let colMap = JSON.parse(dataLoad.Column_Map__c);
    let cols = {};
    for (let key in colMap) {
      let value = colMap[key];
      cols[value.toLowerCase()] = value;
    }
    return cols;
  },
  handleSetupCellChange: function (cmp, row, col) {
    let self = this;
    cmp.set("v.isLoading", true);
    this.cleanPicklists(cmp.get("v.excelColumns"))
      .then(
        $A.getCallback(function (excelColumns) {
          self.excelColumns = excelColumns;
          let params = {
            dataRecordId: cmp.get("v.dataLoaderId"),
            colMap: excelColumns
          };
          return self.util.controllerPromise(cmp, "updateSetupColumns", params);
        })
      )
      .then(
        $A.getCallback(function () {
          cmp.set("v.excelColumns", self.excelColumns);
          cmp.set("v.tableData", self.excelColumns);
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.util.showToastError(errMsg);
      });
  },
  cleanPicklists: function (excelColumns) {
    let params = {};
    params.type = "setup picklists";
    params.data = excelColumns;
    return this.util.runWorker("$Resource.DITWorker", params);
  }
});