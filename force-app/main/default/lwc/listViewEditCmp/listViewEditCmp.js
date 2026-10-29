import { LightningElement, wire, track, api } from "lwc";
import getListMembers from "@salesforce/apex/ListViewEditCmpController.getListMembers";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import saveListMembers from "@salesforce/apex/ListViewEditCmpController.saveListMembers";

export default class ListViewEditCmp extends LightningElement {
  @track columns = [];
  @track rowStart = 0;
  @track draftValues = [];
  @track data = [];
  @track isLoaded = false;
  @track showNext = false;
  @track showPrev = false;
  @track showPagination = false;
  @track title = "List edit";
  @track sortField = "CreatedDate";
  @track sortDirection = "desc";
  @track rowOffset = 0;
  @api recordId;
  lastSavedData = [];
  pageSize = 0;
  pageNum = 0;

  @wire(CurrentPageReference)
  currentPageReference;

  connectedCallback() {
    if (this.recordId == null) {
      this.recordId =
        this.currentPageReference &&
        this.currentPageReference.state &&
        this.currentPageReference.state.c__id;
    }
    this.loadTable();
  }

  loadTable() {
    let self = this;
    self.isLoaded = false;
    getListMembers({
      campaignId: self.recordId,
      pageNum: this.pageNum,
      sortField: this.sortField,
      sortDir: this.sortDirection
    })
      .then((result) => {
        let headers = self.getHeaders(result);
        self.setData(result, headers);
        self.setHeaders(result, headers);
        self.setPagination(result);
        self.setTitle(result);
        self.isLoaded = true;
      })
      .catch((error) => {
        console.log(error);
        self.showErrorToast(error);
      });
  }

  get isPagination() {
    return this.showPagination ? true : false;
  }
  get isLoading() {
    return this.isLoaded ? true : false;
  }
  get isPrev() {
    return this.showPrev ? true : false;
  }

  get getDraftValues() {
    return this.draftValues;
  }

  get isNext() {
    return this.showNext ? true : false;
  }
  get getSortField() {
    return this.sortField;
  }

  get getSortDir() {
    return this.sortDirection;
  }
  get getRowOffset() {
    return this.rowOffset;
  }
  handleSort(event) {
    let evtField = this.getFormattedFieldName(event.detail.fieldName);
    let isFieldChanged = evtField != this.sortField;
    this.sortField = evtField;
    this.sortDirection =
      this.sortDirection == "asc" && !isFieldChanged ? "desc" : "asc";
    this.loadTable();
  }

  getFormattedFieldName(field) {
    const url = "urlTarget";
    if (field.length >= url.length && field.includes(url)) {
      field = field.substring(url.length + 1);
    }
    return field;
  }

  handleNext() {
    this.pageNum++;
    this.loadTable();
  }

  handlePrev() {
    this.pageNum--;
    this.loadTable();
  }

  handleCancel(event) {
    this.data = JSON.parse(JSON.stringify(this.lastSavedData));
    this.draftValues = [];
  }

  handleSave(event) {
    this.mergeDraftValues(event.detail.draftValues);
    let self = this;
    self.isLoaded = false;
    saveListMembers({ membersList: self.draftValues })
      .then((result) => {
        self.draftValues = [];
        self.lastSavedData = JSON.parse(JSON.stringify(self.data));
        self.showSuccessToast("Save Successful!");
      })
      .catch((error) => {
        self.data = JSON.parse(JSON.stringify(self.lastSavedData));
        self.showErrorToast(error);
      });
  }

  mergeDraftValues(draftList) {
    for (let i = 0; i < draftList.length; i++) {
      let isFound = false;
      let check = draftList[i];
      for (let j = 0; j < this.draftValues.length; j++) {
        if (this.draftValues[j].Id == check.Id) {
          isFound = true;
          this.updateDraftValues(check);
          break;
        }
      }
      if (!isFound) {
        this.draftValues.push(check);
      }
      this.updateDataValues(check);
    }
  }

  getHeaders(result) {
    let headers = [];
    let temp = result.config.headers.split(",");
    for (let i = 0; i < temp.length; i++) {
      let check = temp[i];
      if (check && check.length) {
        headers.push(check);
      }
    }
    return headers;
  }

  showErrorToast(msg) {
    msg = this.getErrorMsg(msg);
    const evt = new ShowToastEvent({
      title: "Error",
      message: msg,
      variant: "error"
    });
    this.dispatchEvent(evt);
    this.isLoaded = true;
  }

  showSuccessToast(msg) {
    const evt = new ShowToastEvent({
      title: "Success",
      message: msg,
      variant: "success"
    });
    this.dispatchEvent(evt);
    this.isLoaded = true;
  }

  getErrorMsg(msg) {
    if (typeof msg === "object") {
      msg = msg && msg.body && msg.body.message;
      return !msg ? JSON.stringify(msg) : msg;
    }
    return msg;
  }

  setPagination(result) {
    let pageSize =
      result &&
      result.config &&
      !isNaN(result.config.pageSize) &&
      Number(result.config.pageSize);
    let dataSize = result && !isNaN(result.dataSize) && Number(result.dataSize);
    if (!pageSize || !dataSize || dataSize <= pageSize) {
      this.rowOffset = 0;
      this.showNext = false;
      this.showPrev = false;
      this.showPagination = false;
      return;
    }
    this.rowOffset = pageSize * this.pageNum;
    this.showPrev = this.pageNum != 0;
    this.showNext = (this.pageNum + 1) * pageSize <= dataSize;
    this.showPagination = this.showPrev || this.showNext;
  }

  setHeaders(result, headers) {
    this.columns = [];
    let urlMap = this.getUrlMap(result);
    for (let i = 0; i < headers.length; i++) {
      let key = headers[i];
      let field = this.getField(result, key);
      if (field) {
        let isEditable = field.setting && field.setting.IsEditable__c;
        let col = {
          label: field.label,
          fieldName: key,
          editable: isEditable,
          sortable: field.isSortable
        };
        if (urlMap[key]) {
          col.type = "url";
          col.label = field.label;
          col.fieldName = "urlTarget-" + key;
          col.typeAttributes = { label: { fieldName: key } };
        } else if (field.type == "picklist") {
          col.type = "picklist";
          let listVals = [];
          for (let j = 0; j < field.listVals.length; j++) {
            listVals.push({
              label: field.listVals[j],
              value: field.listVals[j]
            });
          }
          col.typeAttributes = {
            placeholder: "Choose a value",
            options: listVals,
            value: { fieldName: key },
            context: { fieldName: "Id" },
            label: key
          };
        }
        this.columns.push(col);
      }
    }
  }

  getUrlMap(result) {
    let urlList =
      result &&
      result.config &&
      result.config.urlHeaders &&
      result.config.urlHeaders.split(",");
    if (!urlList || !urlList.length) {
      return {};
    }

    let urlMap = {};
    for (let i = 0; i < urlList.length; i++) {
      let check = urlList[i];
      if (check && check.length) {
        urlMap[check] = check;
      }
    }
    return urlMap;
  }

  picklistChanged(event) {
    event.stopPropagation();
    let dataRecieved = event.detail.data;
    let updatedItem = {
      Id: dataRecieved.context
    };
    updatedItem[dataRecieved.field] = dataRecieved.value;
    this.updateDraftValues(updatedItem);
    this.updateDataValues(updatedItem);
  }

  handleCellChanged(event) {
    let newDrafts = event.detail.draftValues;
    let copyData = [...this.draftValues];
    for (let i = 0; i < newDrafts.length; i++) {
      let check = newDrafts[i];
      let isFound = false;
      for (let j = 0; j < copyData.length; j++) {
        if (check.Id == copyData[j].Id) {
          copyData[j] = check;
          isFound = true;
          break;
        }
      }
      if (!isFound) {
        copyData.push(check);
      }
    }

    if (copyData.length >= 200) {
      this.showErrorToast(
        "You can only edit at most 200 members before saving."
      );
      this.draftValues = JSON.parse(JSON.stringify(this.draftValues));
      return;
    }
    this.draftValues = JSON.parse(JSON.stringify(copyData));
  }

  updateDataValues(updateItem) {
    let copyData = [...this.data];
    copyData.forEach((item) => {
      if (item.Id === updateItem.Id) {
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
      }
    });
    this.data = [...copyData];
  }

  updateDraftValues(updateItem) {
    let draftValueChanged = false;
    let copyDraftValues = [...this.draftValues];
    copyDraftValues.forEach((item) => {
      if (item.Id === updateItem.Id) {
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
        draftValueChanged = true;
      }
    });

    if (draftValueChanged) {
      this.draftValues = [...copyDraftValues];
    } else {
      this.draftValues = [...copyDraftValues, updateItem];
    }
  }

  setTitle(result) {
    let title = result.campaignName;
    if (!title) {
      return;
    }
    this.title = "Edit " + title;
  }

  setData(result, headers) {
    this.data = [];
    let members = result.data;
    for (let i = 0; i < members.length; i++) {
      let member = members[i];
      let row = {};
      for (let j = 0; j < headers.length; j++) {
        let key = headers[j];
        let field = this.getField(result, key);
        if (field) {
          let val = member[key] != null ? member[key] : "";
          if (val && val.length > 255) {
            val = val.substring(0, 255) + "...";
            field.setting.IsEditable__c = false;
          }
          row[key] = val;
        } else {
          row[key] = "";
        }

        if (field.type == "picklist" && row[key] == "") {
          row[key] = "none";
        }
        let urlKey = "urlTarget-" + key;
        row[urlKey] = "../../" + member.Id;
      }
      row.Id = member.Id;
      this.data.push(row);
    }
    this.lastSavedData = JSON.parse(JSON.stringify(this.data));
  }

  getField(result, key) {
    return (
      result &&
      result.config &&
      result.config.fields &&
      result.config.fields[key]
    );
  }
}