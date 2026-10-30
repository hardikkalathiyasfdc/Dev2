onmessage = function (e) {
  let result = null;
  let type = e.data.type;
  try {
    if (type == "colMap") {
      let myWorker = new ColumnMapWorker();
      result = myWorker.getColumns(e.data.data);
    } else if (type == "load csv") {
      let myWorker = new LoadWorker();
      result = myWorker.parseCsvMap(e.data.data);
    } else if (type == "setup init") {
      let myWorker = new SetupWorker();
      result = myWorker.getSetupData(e.data.sfColumns, e.data.excelColumns);
    } else if (type == "setup picklists") {
      let myWorker = new SetupWorker();
      result = myWorker.removeSelected(e.data.data);
    } else if (type == "validate") {
      let myWorker = new ValidateWorker();
      result = myWorker.validateData(e.data.data);
    } else if (type == "validate cell") {
      let myWorker = new ValidateWorker();
      result = myWorker.validateSingleCell(e.data.cell);
    } else if (type == "validate preview") {
      let myWorker = new ValidateWorker();
      result = myWorker.validatePreview(e.data.data);
    } else if (type == "getContacts") {
      let myWorker = new ContactWorker();
      result = myWorker.getContactMap(
        e.data.data,
        e.data.columns,
        e.data.requiredColumns
      );
    }
  } catch (e) {
    result = { error: e.message };
  }
  postMessage(result);
};

class LoadWorker {
  parseCsvMap(data) {
    let result = {};
    if (!data || !data.length) {
      return;
    }
    result.headers = {};
    result.data = [];
    let headers = [];
    let headerMap = {};
    for (let i = 0; i < data[0].length; i++) {
      let val = data[0][i];
      if (val && val.length) {
        headerMap[val] = i;
        headers.push(val);
        result.headers[val.toLowerCase()] = val;
      }
    }

    for (let i = 1; i < data.length; i++) {
      let dataRow = data[i];
      let row = {};
      let hasVal = false;
      for (let j = 0; j < headers.length; j++) {
        let header = headers[j];
        let idx = headerMap[header];
        let val = idx < dataRow.length && dataRow[idx] ? dataRow[idx] : "";
        row[header] = val.trim();
        if (val && val.length) {
          hasVal = true;
        }
      }
      if (hasVal) {
        result.data.push(row);
      }
    }
    return result;
  }
}

class ContactWorker {
  getContactMap(data, columns, requiredColumns) {
    if (!data || !columns || !requiredColumns) {
      return {};
    }

    const colMap = this.getColMap(columns, requiredColumns);
    const contacts = {};

    const normalize = (str) => (str || "").toLowerCase().replace(/\s+/g, "");

    for (let i = 0; i < data.length; i++) {
      const row = data[i].cells;
      const contact = {};
      contact.Id = data[i].id;

      let firstName = "";
      let lastName = "";
      let fullName = "";

      for (let api in colMap) {
        const mapObj = colMap[api];
        let val = row[mapObj.idx] && row[mapObj.idx].value;
        val = val && val.length ? val.trim() : "";

        contact[mapObj.conField] = val;

        if (mapObj.conField === "First_Name__c") {
          firstName = val;
        } else if (mapObj.conField === "Last_Name__c") {
          lastName = val;
        } else if (mapObj.conField === "Converted_Full_Name__c") {
          fullName = val;
        }
      }

      for (let j = 0; j < row.length; j++) {
        const cell = row[j];
        let val = cell.value && cell.value.length ? cell.value : "";
        contact[cell.api] = val.trim();
        contact.row = i;
        contact.cell = j;
      }

      const nameKey = normalize(firstName + lastName);
      const fullNameKey = normalize(fullName);

      if (nameKey) {
        contacts[nameKey] = contact;
      }

      if (fullNameKey && fullNameKey !== nameKey) {
        contacts[fullNameKey] = contact;
      }
    }

    return contacts;
  }

  getColMap(columns, requiredColumns) {
    const colMap = {};
    for (let i = 0; i < columns.length; i++) {
      const col = columns[i];
      if (requiredColumns[col.api]) {
        colMap[col.api] = {
          conField: requiredColumns[col.api],
          idx: i
        };
      }
    }
    return colMap;
  }
}

class ColumnMapWorker {
  getColumns(excelSheet) {
    let colMap = {};
    for (let key in excelSheet) {
      let check = excelSheet[key];

      if (
        typeof check === "object" &&
        this.isFirstRow(key) &&
        check.v &&
        check.v.toLowerCase
      ) {
        let col = check.v;
        col = col.trim();
        col = col.toLowerCase();
        colMap[col] = check.v.trim();
      }
    }
    return colMap;
  }
  isFirstRow(key) {
    let numb = key.match(/\d/g);
    numb = numb.join("");
    return numb == "1";
  }
}

class ValidateWorker {
  requiredErrors = {};
  validatePreview(rows) {
    if (!rows || !rows.length) {
      return null;
    }
    let errors = {};

    for (let i = 0; i < rows.length; i++) {
      let row = rows[i];
      let hasErrors = false;
      for (let j = 0; j < row.cells.length; j++) {
        let cell = row.cells[j];
        cell.isSticky = false;
        cell.isEdit = false;
        if (cell.requiredError && cell.requiredError.length) {
          errors[cell.requiredError] = cell.requiredError;
        }
        if (cell.isRequired && !cell.value) {
          cell.requiredError = cell.label + " is required";
          errors[cell.requiredError] = cell.label + " is required";
        }
      }
    }
    return Object.keys(errors);
  }

  validateData(rows) {
    if (!rows || !rows.length) {
      return rows;
    }
    for (let i = 0; i < rows.length; i++) {
      let row = rows[i];
      for (let j = 0; j < row.cells.length; j++) {
        let cell = row.cells[j];
        this.validateCell(cell);
      }
    }
    let results = {};
    results.data = rows;
    if (Object.keys(this.requiredErrors).length)
      results.errors = this.requiredErrors;
    return results;
  }

  validateSingleCell(cell) {
    if (!cell) {
      return cell;
    }
    this.requiredErrors = {};
    this.validateCell(cell);
    return cell;
  }

  validateCell(cell) {
    cell.requiredError = cell.requiredError;
    if (cell.type == "LOOKUP") {
      this.validateLookup(cell);
    } else if (cell.type == "PICKLIST") {
      this.validatePicklist(cell);
    } else if (cell.type == "EMAIL") {
      this.validateEmail(cell);
    } else if (cell.type == "STRING") {
      this.validateText(cell);
    }
    this.validateRequired(cell);
    if (cell.requiredError && cell.requiredError.length) {
      this.requiredErrors[cell.requiredError] = true;
    }
  }

  // BRME-4862: flag malformed email addresses at load (type EMAIL cells).
  validateEmail(cell) {
    if (!cell.value || !cell.value.length) {
      return;
    }
    let emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
    if (!emailRegex.test(cell.value)) {
      this.setRequiredError(cell, "is not a valid email address.");
    }
  }

  validateLookup(cell) {
    if (
      (!cell.value || !cell.value.length || !cell.hasMultiple) &&
      !cell.isRequired
    ) {
      return;
    }

    if ((cell.isRequired && !cell.id) || cell.hasMultiple) {
      let msg = cell.hasMultiple
        ? " has multiple results in BRM.  Please search for the correct one."
        : " is not found in BRM.";

      this.setRequiredError(cell, msg);
    }
  }

  validatePicklist(cell) {
    if (!cell.value || !cell.value.length || !cell.options) {
      return;
    }
    let isValid = false;
    for (let i = 0; i < cell.options.length; i++) {
      let opt = cell.options[i];
      if (opt.value == cell.value) {
        isValid = true;
        break;
      }
    }
    if (!isValid) {
      this.setRequiredError(cell, "is not a value in picklist.");
    }
  }

  validateText(cell) {
    if (!cell.value || !cell.value.length || !cell.maxLength) {
      return;
    }
    if (cell.value.length > cell.maxLength) {
      this.setRequiredError(cell, "too long.  Max(" + cell.maxLength + ")");
    }
  }

  validateRequired(cell) {
    if (!cell.isRequired || (cell.value && cell.value.length)) {
      return;
    }
    this.setRequiredError(cell, cell.label + " is required.");
  }

  setRequiredError(cell, msg) {
    let errMsg =
      cell.value + " " + cell.requiredError ? cell.requiredError : msg;
    cell.requiredError = errMsg;
    cell.class = "red";
  }
}

class SetupWorker {
  removeSelected(setupData) {
    if (!setupData || !setupData.length) {
      return;
    }
    let seenMap = this.getSeenMap(setupData);
    for (let i = 0; i < setupData.length; i++) {
      let row = setupData[i];
      let excelCell = this.getExcelCell(row);
      this.cleanOptions(excelCell, seenMap);
      this.setRequiredExcel(excelCell);
    }
    return setupData;
  }

  getSetupData(sfColumns, excelColumns) {
    let setupData = [];
    for (let i = 0; i < sfColumns.length; i++) {
      let sfCol = sfColumns[i];
      let row = this.getSetupRow(i);
      row.cells.push(this.getSFCell(sfCol));
      row.cells.push(this.getNewExcelCell(sfCol, excelColumns));
      setupData.push(row);
    }
    return setupData;
  }

  setRequiredExcel(excelCell) {
    if (!excelCell) {
      return;
    }
    if (!excelCell.value || !excelCell.value.length) {
      excelCell.class = excelCell.isRequired ? "red" : "yellow";
    } else {
      excelCell.class = "";
    }
  }

  cleanOptions(excelCell, seenMap) {
    if (!excelCell) {
      return;
    }
    let options = [];
    for (let i = 0; i < excelCell.originalOptions.length; i++) {
      let opt = excelCell.originalOptions[i];
      if (opt.value == excelCell.value || !seenMap[opt.value]) {
        options.push(opt);
      }
    }
    excelCell.options = options;
    if (!options.length) {
      excelCell.value = "";
    }
  }

  getSeenMap(setupData) {
    let seenMap = {};
    for (let i = 0; i < setupData.length; i++) {
      let row = setupData[i];
      let excelCell = this.getExcelCell(row);
      if (excelCell && excelCell.value && excelCell.value.length) {
        seenMap[excelCell.value] = true;
      }
    }
    return seenMap;
  }

  getExcelCell(row) {
    return row.cells && row.cells.length > 1 ? row.cells[1] : null;
  }

  getSetupRow(i) {
    let row = {};
    row.id = i;
    row.cells = [];
    return row;
  }

  getSFCell(sfCol) {
    let cell = {};
    cell.isEdit = false;
    cell.type = "STRING";
    cell.value = sfCol.label;
    return cell;
  }

  getNewExcelCell(sfCol, excelColumns) {
    let cell = {};
    cell.isEdit = true;
    cell.api = sfCol.api;
    cell.colName = sfCol.label;
    cell.type = "PICKLIST";
    cell.value = this.getExcelVal(sfCol, excelColumns);
    cell.isRequired = sfCol.isRequired;
    this.setRequiredCell(cell, sfCol.isRequired);
    this.setPicklist(cell, excelColumns);
    return cell;
  }

  getExcelVal(sfCol, excelColumns) {
    let sfLabel =
      sfCol.label && sfCol.label.length && sfCol.label.toLowerCase
        ? sfCol.label
        : null;
    if (!sfLabel) {
      return "";
    }
    let excelVal = excelColumns[sfLabel.toLowerCase()];
    if (!excelVal || !excelVal.length) {
      return "";
    }
    return sfLabel;
  }

  setRequiredCell(cell, isRequired) {
    cell.isRequired = isRequired;
    if (!cell.value.length && cell.isRequired) {
      cell.class = "red";
    } else if (!cell.value.length) {
      cell.class = "yellow";
    }
  }

  setPicklist(cell, excelColumns) {
    cell.options = [];
    cell.originalOptions = [];
    for (let key in excelColumns) {
      let val = excelColumns[key];
      let opt = { label: val, value: val };
      cell.originalOptions.push(opt);
    }
    cell.originalOptions = cell.originalOptions.sort((a, b) => {
      a =
        a && a.value != null && a.value.toLowerCase
          ? a.value.toLowerCase()
          : "";
      b =
        b && b.value != null && b.value.toLowerCase
          ? b.value.toLowerCase()
          : "";
      return a > b ? 1 : -1;
    });
  }
}
