({
  scroll: function (cmp) {
    let myTableId = cmp.get("v.tableId");
    var header = document.getElementById(myTableId);
    if (window.pageYOffset > header.offsetTop) {
      console.log("sticky");
    } else {
      console.log("notSticky");
    }
  },
  updateCell: function (cmp, mapping, record, type, errMsg) {
    let rowNum = this.getMapRowNum(mapping);
    let cellNum = this.getMapCellNum(mapping);
    if (rowNum == null || cellNum == null) {
      return;
    }
    let compEvent = cmp.getEvent("changeEvent");
    let params = {};
    params.row = rowNum;
    params.cell = cellNum;
    params.tableId = cmp.get("v.tableId");
    params.type = type;

    if (record) {
      let data = cmp.get("v.data");
      let cell = data[rowNum].cells[cellNum];
      cell.value = record.Name;
      cell.id = record.Id;
      cell.class = "";
      cmp.set("v.data", data);
    }
    compEvent.setParams(params);
    compEvent.fire();
  },
  updateCheckboxes: function (cmp, mapping, isChecked) {
    let rowNum = this.getMapRowNum(mapping);
    let cellNum = this.getMapCellNum(mapping);
    if (rowNum == null || cellNum == null) {
      return;
    }
    let compEvent = cmp.getEvent("changeEvent");
    let params = {};
    params.row = rowNum;
    params.cell = cellNum;
    params.tableId = cmp.get("v.tableId");

    let data = cmp.get("v.data");
    let row = data[rowNum];
    params.rowId = row.id;
    params.rec = row;
    let updatedData = [];

    for (let i = 0; i < data.length; i++) {
      let rec = data[i];
      if (row.id == rec.id) {
        rec.isChecked = isChecked ? true : false;
      } else {
        rec.isChecked = false;
      }
      updatedData.push(rec);
    }

    cmp.set("v.tableData", updatedData);
    cmp.set("v.data", updatedData);
    compEvent.setParams(params);
    compEvent.fire();
  },
  updateUICell: function (cmp, row, col, cell) {
    let tdSelector =
      'td[id="' + cmp.get("v.tableId") + "-" + row + "-" + col + '"]';
    let errorSelector = tdSelector + " div.requiredError";

    if (cell && cell.class && cell.class.length) {
      jQuery(tdSelector).addClass(cell.class);
    } else {
      jQuery(tdSelector).removeClass("yellow");
    }
    if (cell && cell.requiredError && cell.requiredError.length) {
      jQuery(tdSelector).addClass("red");
      jQuery(errorSelector).text(cell.requiredError);
    } else {
      jQuery(tdSelector).removeClass("red");
      jQuery(errorSelector).text("");
    }

    if (cell && cell.isReadOnly) {
      jQuery(tdSelector).text(cell.value);
    }
    let cmpId = row + "-" + col;
    if (!cell || cell.type != "LOOKUP") {
      return;
    }

    let lookups = cmp.find("lookup");
    if (!lookups || !lookups.length) {
      return;
    }

    for (let i = 0; i < lookups.length; i++) {
      let lookup = lookups[i];
      if (cmpId == lookup.get("v.cmpId")) {
        lookup.updateVal(cell.value);
        break;
      }
    }
  },
  getMapRowNum: function (mapping) {
    if (!this.isMapValid(mapping)) {
      return null;
    }
    return Number(mapping.split("-")[0]);
  },
  getMapCellNum: function (mapping) {
    if (!this.isMapValid(mapping)) {
      return null;
    }
    return Number(mapping.split("-")[1]);
  },
  isMapValid: function (mapping) {
    if (!mapping || !mapping.length) {
      return false;
    }
    let maps = mapping.split("-");
    if (maps.length != 2) {
      return false;
    }
    return !isNaN(maps[0]) && !isNaN(maps[1]);
  },
  setWidths: function (cmp) {
    console.log("set eidths ::::");
    let params = {};
    params.type = "setWidth";
    params.columns = cmp.get("v.columns");
    params.data = cmp.get("v.data");
    console.log("asdas :::: " + JSON.stringify(params.data));
    cmp.set("v.isLoading", true);
    cmp.set("v.isInit", false);
    this.runWorker(params)
      .then((a) => {
        console.log("cols :::::: " + JSON.stringify(a.columns));
        cmp.set("v.columns", a.columns);
        cmp.set("v.data", a.data);
        cmp.set("v.tableData", a.data);
        cmp.set("v.tableWidth", a.totalWidth);
        cmp.set("v.tableHeight", a.totalHeight);
        cmp.set("v.isLoading", false);
        cmp.set("v.isInit", true);
      })
      .catch((msg) => {
        console.log("error");
        console.log(msg);
        cmp.set("v.isLoading", false);
      });
  },
  runWorker: function (params) {
    let self = this;
    let url = $A.get("$Resource.ListWorker");
    self.worker = new Worker(url);
    return new Promise((resolve, reject) => {
      self.worker.postMessage(params);
      self.worker.onmessage = function (e) {
        resolve(e.data);
      };
    });
  }
});