import { LightningElement, track, wire, api } from "lwc";

import searchList from "@salesforce/apex/EventMangementAuraCtrl.searchList";
export default class listSearch extends LightningElement {
  @api multiple;

  availableLists;
  selectedLists;
  curInput;

  @api
  clearSelection() {
    this.selectedLists = undefined;
  }

  handleChange(event) {
    this.value = event.target.value;
  }

  handleSearchChange(event) {
    this.availableLists = undefined;
    let searchString = event.target.value;
	searchString = searchString ? searchString.trim() : '';
      this.searchList(searchString);
  }

  searchList(searchString) {
    this.curInput = this.formatSearch(searchString);
    this.searchId = this.uuidv4();
    let self = this;
    searchList({
      listSearch: self.curInput,
      searchId: self.searchId
    })
      .then((result) => {
        if (result.searchId && result.searchId.length && result.searchId != self.searchId) {
          return;
        }
        let availableLists = result && result.results ? result.results : [];
        availableLists.forEach((x) => {
          if (x.RecordType.DeveloperName === "Pre_Event") {
            x.displayEvent = true;
          } else {
            x.displayEvent = false;
          }
        });
        this.availableLists = availableLists;
        this.error = undefined;
        this.onfocus();
      })
      .catch((error) => {
        this.availableLists = undefined;
        this.error = error;
      });
  }
  uuidv4() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
      (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    );
  }
  formatSearch(input) {
    if (!input || input == "") {
      return "";
    }
    let myExp = "([\\'\\&\\|\\!\\(\\)\\{\\}\\[\\]^~\\:\\\\\\+\\-])";
    let re = new RegExp(myExp, "g");
    input = input.replaceAll(re, "\\$1");
    return input;
  }

  removeSelection(event) {
    let id = event.target.id.split("-")[0];
    this.selectedLists = this.selectedLists.filter((x) => x.Id !== id);
    this.updateEvent();
  }

  getSelectedRows(event) {
    let selectedRowId = event.target.id.split("-")[0];

    let selected = {};
    this.availableLists.forEach((item) => {
      if (item.Id === selectedRowId) {
        selected.Id = item.Id;
        selected.Name = item.Name;
      }
    });

    if (this.selectedLists === undefined) {
      this.selectedLists = [];
    }

    let existed = this.selectedLists.find((x) => x.Id === selected.Id);

    if (existed === undefined) {
      if (this.multiple && this.multiple === "false") {
        this.selectedLists[0] = selected;
      } else {
        this.selectedLists.push(selected);
      }
    }

    this.updateEvent();

    this.template.querySelectorAll("lightning-input").forEach((element) => {
      element.value = null;
    });

    this.availableLists = undefined;
    this.template
      .querySelector('[data-id="lookup-pill"]')
      .classList.add("slds-is-close");
    this.template
      .querySelector('[data-id="lookup-pill"]')
      .classList.remove("slds-is-open");

    this.template
      .querySelector('[data-id="searchRes"]')
      .classList.add("slds-is-close");
    this.template
      .querySelector('[data-id="searchRes"]')
      .classList.remove("slds-is-open");
  }

  handleResultClose(event) {
    this.availableLists = undefined;
  }

  onblur(event) {
    this.template
      .querySelector('[data-id="searchRes"]')
      .classList.add("slds-is-close");
    this.template
      .querySelector('[data-id="searchRes"]')
      .classList.remove("slds-is-open");
  }

  onfocus(event) {
    this.template
      .querySelector('[data-id="searchRes"]')
      .classList.add("slds-is-open");
    this.template
      .querySelector('[data-id="searchRes"]')
      .classList.remove("slds-is-close");
  }

  updateEvent() {
    const selectedEvent = new CustomEvent("update", {
      detail: this.selectedLists
    });

    // Dispatches the event.
    this.dispatchEvent(selectedEvent);
  }
}