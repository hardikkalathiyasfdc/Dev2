import { LightningElement, api } from 'lwc';
import fetchRecords from '@salesforce/apex/ReusableLookupController.fetchRecords';
import fetchDefaultRecord from '@salesforce/apex/CustomSingleSelectLookupLwcController.fetchDefaultRecord';
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 500;

export default class ReusableLookup extends LightningElement {
    @api helpText = "custom search lookup";
    @api label = "";
    @api required;
    @api selectedIconName = "standard:account";
    @api objectLabel = "Contact";
    recordsList = [];
    selectedRecordName;
    defaulttRecordName;
    defaultval=false;
    isnew=false;
    @api objectApiName = "Contact";
    @api fieldApiName = "Name";
    @api otherFieldApiName = "Industry";
    @api searchString = "";
    @api selectedRecordId = "";
    @api parentRecordId;
    @api parentFieldApiName;

    preventClosingOfSerachPanel = false;

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

    _defaultRecordId;
    get defaultRecordId(){
        return this._defaultRecordId;
    }

    @api
    set defaultRecordId(value) {
        if (this._defaultRecordId !== value) {
            this._defaultRecordId = value;
            fetchDefaultRecord({ recordId: this.defaultRecordId, 'sObjectApiName': this.objectApiName })
            .then((result) => {
                if (result != null) {
                    this.defaulttRecordName = result.Name;
                    this.selectedRecordName = result.Name;
                    this.defaultval=true;
                }
            })
            .catch((error) => {
                this.error = error;
                this.selectedRecord = {};
            });
        }
    }

    connectedCallback() {
        if (this.defaultRecordId != '') {
            fetchDefaultRecord({ recordId: this.defaultRecordId, 'sObjectApiName': this.objectApiName })
                .then((result) => {
                    if (result != null) {
                        this.defaulttRecordName = result.Name;
                        this.defaultval=true;
                    }
                })
                .catch((error) => {
                    this.error = error;
                    this.selectedRecord = {};
                });
        } else{ 
            this.isnew=ture
           this.defaultval=false;
        }
        if (this.selectedRecordId) {
            this.fetchSobjectRecords(true);
        }
    }

    //call the apex method
    fetchSobjectRecords(loadEvent) {
        fetchRecords({
            inputWrapper: this.methodInput
        }).then(result => {
            if (loadEvent && result) {
                this.selectedRecordName = result[0].mainField;
            } else if (result) {
                this.recordsList = JSON.parse(JSON.stringify(result));
            } else {
                this.recordsList = [];
            }
        }).catch(error => {
            console.log(error);
        })
    }

    get isValueSelected() {
        return this.selectedRecordId;
    }

    //handler for calling apex when user change the value in lookup
    handleChange(event) {
        this.searchString = event.target.value;
        this.fetchSobjectRecords(false);
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
    handleCommit(event) {
    // Prevent any form submit bubbling up to the parent record-edit-form
    if (event) {
        event.preventDefault?.();
        event.stopPropagation?.();
    }

    // Clear local state
    this.selectedRecordId = null;
    this.selectedRecordName = null;

    // Emit a consistent, null-safe payload that parents can rely on
    this.dispatchEvent(new CustomEvent('valueselected', {
        detail: {
            selectedRecord: null,                   // <-- IMPORTANT: null when cleared
            rowKey: this.rowKey || this.dataset?.id || null, // optional helper for parent to find the row
            fieldApiName: this.fieldApiName || this.fieldName || null
        },
        bubbles: true,
        composed: true
    }));
}
    handleCommitdeff(){
        this.defaulttRecordName="";
         this.defaultRecordId="";
          this.preventClosingOfSerachPanel = true;
    }

    //handler for selection of records from lookup result list
    handleSelect(event) {
        let selectedRecord = {
            mainField: event.currentTarget.dataset.mainfield,
            subField: event.currentTarget.dataset.subfield,
            id: event.currentTarget.dataset.id
        };
        this.selectedRecordId = selectedRecord.id;
        this.selectedRecordName = selectedRecord.mainField;
        this.recordsList = [];
        // Creates the event
        const selectedEvent = new CustomEvent('valueselected', {
            detail: selectedRecord
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