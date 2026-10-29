({
  handleUpload: function (cmp, files) {
    if (!files || !files.length) {
      return;
    }
    let file = files[0];
    cmp.set("v.fileName", file.name);
    let self = this;
    cmp.set("v.isLoading", true);
    this.parseData(cmp, file)
      .then(
        $A.getCallback(function () {
          let params = {
            fileName: cmp.get("v.fileName"),
            columns: cmp.get("v.uploadColumns")
          };
          return self.util.controllerPromise(cmp, "createNewDataLoad", params);
        })
      )
      .then(
        $A.getCallback(function (dataLoad) {
          cmp.set("v.dataLoaderId", dataLoad.Id);
          return self.saveExcelRows(cmp, dataLoad.Id);
        })
      )
      .then(
        $A.getCallback(function (results) {
          let params = {
            dataRecordId: cmp.get("v.dataLoaderId"),
            stage: "setup"
          };
          return self.util.controllerPromise(cmp, "updateStage", params);
        })
      )
      .then(
        $A.getCallback(function () {
          cmp.set("v.isLoading", false);
          cmp.set("v.stage", "setup");
        })
      )
      .catch(
        $A.getCallback(function (msg) {
            if(self.util)
          self.util.showToastError(msg);
          cmp.set("v.isLoading", false);
        })
      );
  },
  saveExcelRows: function (cmp, dataLoadId) {
    let self = this;
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        self.saveExcelHelper(
          cmp,
          dataLoadId,
          [],
          cmp.get("v.uploadData"),
          resolve,
          reject
        );
      })
    );
  },
  saveExcelHelper: function (
    cmp,
    dataLoadId,
    rowList,
    masterList,
    resolve,
    reject
  ) {
    let self = this;
    if (!masterList || !masterList.length) {
      resolve(rowList);
      return;
    }
    let tempRows = [];
    for (let i = 0; i < masterList.length && i < self.batchSize; i++) {
      tempRows.push(masterList.shift());
    }
    self.util
      .controllerPromise(cmp, "createNewExcelRows", {
        dataLoaderId: dataLoadId,
        excelRows: tempRows,
        offset: rowList.length
      })
      .then(
        $A.getCallback(function (records) {
          for (let i = 0; i < records.length; i++) {
            rowList.push(records[i]);
          }
          self.saveExcelHelper(
            cmp,
            dataLoadId,
            rowList,
            masterList,
            resolve,
            reject
          );
        })
      )
      .catch(
        $A.getCallback(function (msg) {
          reject(msg);
        })
      );
  },
  parseData: function (cmp, file) {
    let self = this;
    if (self.isCsv(file)) {
      return self.parseCsv(cmp, file);
    } else {
      return self.parseExcel(cmp, file);
    }
  },
  isCsv: function (file) {
    let name = file.name;
    let checks = name.split(".");
    return checks[checks.length - 1].toLowerCase() == "csv";
  },
  parseCsv: function (cmp, file) {
    let self = this;
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        self
          .readCsv(file)
          .then(
            $A.getCallback(function (result) {
              let params = { type: "load csv", data: result.data };
              return self.util.runWorker("$Resource.DITWorker", params);
            })
          )
          .then(
            $A.getCallback(function (results) {
              cmp.set("v.uploadData", results.data);
              cmp.set("v.uploadColumns", results.headers);
              resolve();
            })
          )
          .catch(
            $A.getCallback(function (msg) {
              reject(msg);
            })
          );
      })
    );
  },
  readCsv: function (file) {
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        if (!file) {
          reject("Failed to read file.");
          return;
        }
        Papa.parse(file, { complete: resolve });
      })
    );
  },
  parseExcel: function (cmp, file) {
    let self = this;
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        self
          .parseUpload(file)
          .then(
            $A.getCallback(function (excelSheet) {
              let sheetData = self.getSheetData(excelSheet);
              cmp.set("v.uploadData", sheetData);
              return self.getSheetColMap(excelSheet);
            })
          )
          .then(
            $A.getCallback(function (sheetColumns) {
              cmp.set("v.uploadColumns", sheetColumns);
              resolve();
            })
          )
          .catch(
            $A.getCallback(function (msg) {
              reject(msg);
            })
          );
      })
    );
  },
  handleExcel: function (cmp, file) {
    let self = this;
    cmp.set("v.isLoading", true);
    this.parseUpload(file)
      .then(
        $A.getCallback(function (excelSheet) {
          let sheetData = self.getSheetData(excelSheet);
          cmp.set("v.uploadData", sheetData);
          return self.getSheetColMap(excelSheet);
        })
      )
      .then(
        $A.getCallback(function (sheetColumns) {
          cmp.set("v.uploadColumns", sheetColumns);
          cmp.set("v.isLoading", false);
          cmp.set("v.stage", "setup");
        })
      )
      .catch(
        $A.getCallback(function (msg) {
            if( self.util)
          self.util.showToastError(msg);
          cmp.set("v.isLoading", false);
        })
      );
  },
  parseUpload: function (file) {
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        if (!file) {
          reject("Failed to read file.");
          return;
        }

        let reader = new FileReader();
        reader.onload = function (e) {
          let data = e.target.result;
          let workbook = XLSX.read(data, {
            type: "binary"
          });
          resolve(workbook.Sheets[workbook.SheetNames[0]]);
        };

        reader.onerror = function (ex) {
          reject(ex);
        };

        reader.readAsBinaryString(file);
      })
    );
  },
  getSheetData: function (excelSheet) {
    return XLSX.utils.sheet_to_row_object_array(excelSheet);
  },
  getSheetColMap: function (excelSheet) {
    let params = {};
    params.type = "colMap";
    params.data = excelSheet;
    return this.util.runWorker("$Resource.DITWorker", params);
  },
  loadPreviousFileList: function (cmp) {
    cmp.set("v.isLoading", true);
    this.util
      .controllerPromise(cmp, "getPreviousDataLoads")
      .then(
        $A.getCallback(function (optList) {
          cmp.set("v.previousFileList", optList);
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
           if( self.util)
        self.util.showToastError(errMsg);
      });
  },
  loadFile: function (cmp, id) {
    let self = this;
    if (!id) {
      this.util.showToastError("Error unable to load file with missing id.");
      return;
    }
    cmp.set("v.isLoading", true);
    this.util
      .controllerPromise(cmp, "getDataLoad", { dataId: id })
      .then(
        $A.getCallback(function (dataLoad) {
          cmp.set("v.isLoading", false);
          cmp.set("v.dataLoaderId", dataLoad.Id);
          cmp.set("v.dataLoad", dataLoad);
          cmp.set("v.fileName", dataLoad.Name__c);
          cmp.set("v.stage", dataLoad.Stage__c);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
           if( self.util)
        self.util.showToastError(errMsg);
      });
  }
});