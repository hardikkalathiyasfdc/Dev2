onmessage = function (e) {
  let result = null;
  let type = e.data.type;
  if (type == "setWidth") {
    let myWorker = new WidthWorker();
    result = myWorker.setWidth(e.data.columns, e.data.data);
  }
  postMessage(result);
};

class WidthWorker {
  minWidth = 100;
  viewCharWidth = 6;
  editCharWidth = 10;
  picklistCharWidth = 6;
  thCharWidth = 10;
  maxWidth = 500;
  setWidth(columns, data) {
    let result = {};
    result.columns = columns;
    result.data = data;
    result.totalWidth = 0;
    result.totalHeight = 0;
    if (!columns || !columns.length) {
      return result;
    }
    for (let i = 0; i < columns.length; i++) {
      let col = columns[i];
      if (col.label && col.label.length) {
        let width = col.label.length * this.thCharWidth;
        col.width = Math.min(this.maxWidth, Math.max(width, this.minWidth));
      }
    }

    if (data && data.length) {
      for (let i = 0; i < data.length; i++) {
        let row = data[i];
        if (row && row.cells && row.cells.length) {
          for (let j = 0; j < row.cells.length; j++) {
            let cell = row.cells[j];
            let width = this.getWidth(cell);
            if (columns.length > j) {
              columns[j].width = Math.max(width, columns[j].width);
            }
          }
        }
      }
    }
    let totalWidth = 0;
    for (let i = 0; i < columns.length; i++) {
      let col = columns[i];
      if (col.width && !isNaN(col.width)) {
        if (col.isSticky) {
          col.style =
            "left: " + totalWidth + "px;width: " + col.width + "px;z-index:4;";
        } else {
          col.style = "width: " + col.width + "px;";
        }
        col.offset = totalWidth + 0;
        totalWidth += col.width;
      }
    }

    for (let i = 0; i < data.length; i++) {
      let row = data[i];
      if (row && row.cells && row.cells.length) {
        for (let j = 0; j < row.cells.length; j++) {
          let cell = row.cells[j];
          let col = columns.length > j && columns[j];
          if (col && col.isSticky) {
            let leftStyle =
              "left: " + col.offset + "px; position: sticky;z-index:3;";
            cell.style = leftStyle;
          }
        }
      }
    }

    result.totalWidth = totalWidth;
    result.totalHeight = data.length * 42;
    return result;
  }

  getWidth(cell) {
    if (!cell || !cell.type) {
      return this.minWidth;
    }
    let width = 0;
    if (cell.type == "PICKLIST") {
      let options =
        cell.options && cell.options.length
          ? cell.options
          : cell.originalOptions;
      if (options && options.length) {
        for (let i = 0; i < options.length; i++) {
          let opt = options[i];
          if (opt.value && opt.value.length) {
            width = Math.max(
              width,
              opt.value.length * this.picklistCharWidth + 5
            );
          }
        }
      }
    } else if (cell.type == "LOOKUP") {
      let charWidth = cell.isEdit ? this.editCharWidth : this.viewCharWidth;
      charWidth = cell.value.length * charWidth + 30;
      width = Math.max(250, charWidth);
    } else if (cell.value && cell.value.length) {
      let charWidth = cell.isEdit ? this.editCharWidth : this.viewCharWidth;
      width = cell.value.length * charWidth;
    }
    return Math.min(this.maxWidth, Math.max(width, this.minWidth));
  }
}
