import { LightningElement, api, track } from "lwc";
import fetchRecords from "@salesforce/apex/DITLookupController.fetchRecords";
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 500;

export default class ReusableLookup extends LightningElement {
  @api helpText = "custom search lookup";
  @api label = "Parent Account";
  @api required;
  @api selectedIconName = "standard:account";
  @api objectLabel = "Account";
  @api dlRecordId;
  @api loaderId;
  @api isError;
  recordsList = [];
  selectedRecordName;
  isduplicate;
  fields = [];
  @api objectApiName = "Account";
  @api fieldApiName = "Name";
  @api otherFieldApiName = "";
  isLoading = false;

  @api parentRecordId;
  @api parentFieldApiName;
  @api fieldChanged;
  _selectedRecordId;
  @api
  get selectedRecordId() {
    return this._selectedRecordId;
  }
  set selectedRecordId(value) {
    this._selectedRecordId = value;
  }

  @api
  get searchString() {
    return this._searchString;
  }
  set searchString(value) {
    this._searchString = value;
    if (this.selectedRecordId) this.selectedRecordName = value;
  }
  _searchString;
  firstName = "";
  lastName = "";

  get isSignOther() {
    if (this.selectedRecordId) {
      this.selectedRecordName = this.searchString;
    }
    if (this.objectApiName == "Contact" && this.searchString) {
      let names = this.searchString.split(" ");

      if (names.length == 1) {
        this.lastName = names[0];
      } else if (names.length > 1) {
        for (let i = 0; i < names.length - 1; i++) {
          if (names[i]) this.firstName += names[i] + " ";
        }
        this.lastName = names[names.length - 1];
      }
    }
    return this.fieldChanged == "Significant_Other__c";
  }
  showCreation = false;
  duplicaterec = [];
  preventClosingOfSerachPanel = false;

  handleCreate(event) {
    this.showCreation = true;
  }
  handleCreationCancel(event) {
    this.showCreation = false;
  }
  handleCreationSuccess(event) {
    this.showCreation = false;
    this._selectedRecordId = this.isSignOther ? event.detail.Id : event.detail;
    if (this.selectedRecordId) {
      this.fetchSobjectRecords(true, true);
    }
  }
  get methodInput() {
    return {
      objectApiName: this.objectApiName,
      fieldApiName: this.fieldApiName,
      otherFieldApiName: this.otherFieldApiName,
      searchString: this.searchString,
      selectedRecordId: this.selectedRecordId,
      parentRecordId: this.parentRecordId,
      parentFieldApiName: this.parentFieldApiName
    };
  }

  get showRecentRecords() {
    if (!this.recordsList) {
      return false;
    }

    return this.recordsList.length > 0;
  }

  //getting the default selected record
  connectedCallback() {
    this.selectedRecordName = this.searchString;
    if (this.objectApiName == "Account") {
      this.fields = ["Name"];
    }
    if (this.objectApiName == "Contact") {
      this.fields = ["FirstName", "LastName", "Email"];
    }
    if (this.searchString) {
      this.isLoading = true;
      this.fetchSobjectRecords(true, false);
    }
  }

  //call the apex method
  fetchSobjectRecords(loadEvent, isCreate) {
    fetchRecords({
      inputWrapper: this.methodInput
    })
      .then((result) => {
        let filteredRecords = [];
        if (this.duplicaterec && this.selectedRecordName) {
          filteredRecords = this.duplicaterec.filter((rec) => {
            return (
              rec.mainField.toLowerCase().replace("the ", "") ===
              this.selectedRecordName.toLowerCase().replace("the ", "")
            );
          });
        }
        if (
          this.searchString &&
          (result.length > 1 ||
            (result.length == 1 &&
              this.searchString.replace("the ", "") !=
                result[0].mainField.replace("the ", "") &&
              !this.selectedRecordId))
        ) {
          this.isduplicate = true;
          this.duplicaterec = result;
        } else {
          this.isduplicate = false;
          this.duplicaterec = [];
        }
        // BRME-6786: tell the host row whether the + button will show potential duplicates, so the
        // Review Errors org message can reflect the actual resolution flow for this row.
        this.dispatchEvent(
          new CustomEvent("candidateschecked", {
            detail: {
              dlRecordId: this.dlRecordId,
              fieldChanged: this.fieldChanged,
              hasCandidates: this.duplicaterec.length > 0
            },
            bubbles: true,
            composed: true
          })
        );
        if (loadEvent && result && result.length > 0) {
          if (this.selectedRecordName == result[0].mainField)
            this.selectedRecordName = result[0].mainField;

          if (isCreate || (loadEvent && this.selectedRecordId)) {
            this._searchString = result[0].mainField;
            this.selectedRecordName = result[0].mainField;
            let selectedRecord = {
              fieldChanged: this.fieldChanged,
              mainField: result[0].mainField,
              subField: "",
              id: result[0].id,
              dlRecordId: this.dlRecordId,
              akaMatch: filteredRecords.length > 1
            };
            // Creates the event
            const selectedEvent = new CustomEvent("valueselect", {
              detail: { selectedRecord }
            });
            this.dispatchEvent(selectedEvent);
          }
        } else if (result) {
          this.recordsList = JSON.parse(JSON.stringify(result));
        } else {
          this.recordsList = [];
        }
        this.isLoading = false;
      })
      .catch((error) => {
        this.isLoading = false;
        console.log(error);
      });
  }

  get isValueSelected() {
    console.log(this.selectedRecordId);
    return this.selectedRecordId;
  }

  //handler for calling apex when user change the value in lookup
  handleChange(event) {
    this._searchString = event.target.value;
    if (this.searchString.length > 2) this.fetchSobjectRecords(false, false);
    if (this.isError && !event.target.value) this.handleCommit();
  }

  handleFocus() {
    if (this.selectedRecordId || !this.searchString) return;
    if (this.duplicaterec && this.duplicaterec.length) {
      this.recordsList = JSON.parse(JSON.stringify(this.duplicaterec));
      return;
    }
    if (this.searchString.trim().length > 2) {
      this.fetchSobjectRecords(false, false);
    }
  }

  //handler for clicking outside the selection panel
  handleBlur() {
    this.recordsList = [];
    this.preventClosingOfSerachPanel = false;
  }

  //handle the click inside the search panel to prevent it getting closed
  handleDivClick() {
    this.preventClosingOfSerachPanel = true;
  }

  //handler for deselection of the selected item
  handleCommit() {
    this._selectedRecordId = "";
    this.selectedRecordName = "";
    this._searchString = "";
    this.isduplicate = false;
    this.duplicaterec = [];
    // BRME-6786: clearing the selection re-exposes the error; report no candidates so the message resets.
    this.dispatchEvent(
      new CustomEvent("candidateschecked", {
        detail: {
          dlRecordId: this.dlRecordId,
          fieldChanged: this.fieldChanged,
          hasCandidates: false
        },
        bubbles: true,
        composed: true
      })
    );
    let selectedRecord = {
      fieldChanged: this.fieldChanged,
      mainField: "",
      subField: "",
      id: "",
      dlRecordId: this.dlRecordId
    };
    // Creates the event
    const selectedEvent = new CustomEvent("valueselect", {
      detail: { selectedRecord }
    });
    //dispatching the custom event
    this.dispatchEvent(selectedEvent);
  }

  //handler for selection of records from lookup result list
  handleSelect(event) {
    let selectedRecord = {
      fieldChanged: this.fieldChanged,
      mainField: event.currentTarget.dataset.mainfield,
      subField: event.currentTarget.dataset.subfield,
      id: event.currentTarget.dataset.id,
      dlRecordId: this.dlRecordId
    };
    this._selectedRecordId = selectedRecord.id;
    this.selectedRecordName = selectedRecord.mainField;
    this.recordsList = [];
    // Creates the event
    const selectedEvent = new CustomEvent("valueselect", {
      detail: { selectedRecord }
    });
    //dispatching the custom event
    this.dispatchEvent(selectedEvent);
  }

  //to close the search panel when clicked outside of search input
  handleInputBlur(event) {
    // Debouncing this method: Do not actually invoke the Apex call as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    window.clearTimeout(this.delayTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.delayTimeout = setTimeout(() => {
      if (!this.preventClosingOfSerachPanel) {
        this.recordsList = [];
      }
      this.preventClosingOfSerachPanel = false;
    }, DELAY);
  }
}