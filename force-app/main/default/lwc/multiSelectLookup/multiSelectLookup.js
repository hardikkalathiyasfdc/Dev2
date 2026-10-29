import { LightningElement, api } from 'lwc';
import fetchLookUpValues from '@salesforce/apex/SObjectMultiSelectionController.fetchFilterLookUpValues';
import fetchLookUpAllValues from '@salesforce/apex/SObjectMultiSelectionController.fetchLookUpAllValues';
import fetchLookUpAllValuesWithExcludeValues from '@salesforce/apex/SObjectMultiSelectionController.fetchLookUpAllValuesWithExcludeValues';
import fetchLookUpAllSouceValues from '@salesforce/apex/SObjectMultiSelectionController.fetchLookUpAllSouceValues';
import fetchLookUpAllSouceValuesWithExcludeValues from '@salesforce/apex/SObjectMultiSelectionController.fetchLookUpAllSouceValuesWithExcludeValues';

export default class MultiSelectLookup extends LightningElement {
    @api labelName;
    @api objectApiName;
    @api fieldApiNames;
    @api filterFieldApiName;
    @api iconName;
    @api recordTypeId;
    @api isListMemberSource = false;
    @api campaignId;
    @api hideCancel = false;
    
    @api
    set defaultValues(data) {
        if (data && Array.isArray(data)) {
            this.globalSelectedItems = [...data];
            this.value = data.map(d => d.value);
            this.previousSelectedItems = [...data];
        }
    }
    get defaultValues() {
        return this.globalSelectedItems;
    }

    globalSelectedItems = []; //holds all the selected checkbox items
    items = []; //holds all records retrieving from database
    selectedItems = []; //holds only selected checkbox items that is being displayed based on search
    tempItems = [];
    //since values on checkbox deselection is difficult to track, so workaround to store previous values.
    //clicking on Done button, first previousSelectedItems items to be deleted and then selectedItems to be added into globalSelectedItems
    previousSelectedItems = []; 
    value = []; //this holds checkbox values (Ids) which will be shown as selected
    searchInput ='';    //captures the text to be searched from user input
    isDialogDisplay = false; //based on this flag dialog box will be displayed with checkbox items
    isDisplayMessage = false; //to show 'No records found' message

    get showCancel() {
        return !this.hideCancel;
    }
    
    connectedCallback() {
		if(this.isListMemberSource) {
            this.fetchLookUpAllSouceValues();
        } else {
		    this.fetchLookUpAllValues();
        }
	}

    fetchLookUpAllSouceValues() {
		fetchLookUpAllSouceValues({
            'campaignId' : this.campaignId
        }).then(result => {
            if(result.length > 0) {
                result.map(resElement => {
                    this.tempItems = [
                        ...this.tempItems,
                        { value: resElement.Id, label: resElement.Name }
                    ];
                    this.globalSelectedItems.map(element => {
                        if(element.value == resElement.Id) {
                            this.value.push(element.value);
                            this.previousSelectedItems.push(element);                      
                        }
                    });
                });
            } 
        }).catch(error => {
			this.error = error;
			this.allRecords = undefined;
		});
    }

	fetchLookUpAllValues() {
		fetchLookUpAllValues({			
            'objectAPIName' : this.objectApiName,
			'recordTypeId' : this.recordTypeId
		}).then(result => {
			//this.allRecords = result;
			//this.error = undefined;	
            if(result.length > 0) {
                result.map(resElement => {
                    this.tempItems = [
                        ...this.tempItems, 
                        { value: resElement.Id, label: resElement.Name }
                    ];
                    this.globalSelectedItems.map(element => {
                        if(element.value == resElement.Id) {
                            this.value.push(element.value);
                            this.previousSelectedItems.push(element);                      
                        }
                    });
                });
            } else {
                //display No records found message
                this.isDialogDisplay = false;
                this.isDisplayMessage = true;                    
            }		
		}).catch(error => {
			console.log(error);
			this.error = error;
			this.allRecords = undefined;
		});
	}

    onchangeSearchInput(event) {
        this.searchInput = event.target.value;
        if(this.searchInput.trim().length>0) {
            //retrieve records based on search input
            fetchLookUpValues({
                'searchKeyWord':this.searchInput,
                'excludeIds':JSON.stringify(this.globalSelectedItems),
                'objectAPIName' : this.objectApiName,
                'recordTypeId' : this.recordTypeId
            }).then(result => { 
                this.items = []; //initialize the array before assigning values coming from apex
                this.value = [];
                this.previousSelectedItems = [];
                if(result.length > 0) {
                    result.map(resElement => {
                        //prepare items array using spread operator which will be used as checkbox options
                        this.items = [
                            ...this.items,
                            { value: resElement.Id, label: resElement.Name }
                        ];
                        /*since previously choosen items to be retained, so create value array for checkbox group.
                            This value will be directly assigned as checkbox value & will be displayed as checked.
                        */
                        this.globalSelectedItems.map(element => {
                            if(element.value == resElement.Id) {
                                this.previousSelectedItems.push(element);                      
                            }
                        });
                    });
                    this.isDialogDisplay = true; //display dialog
                    this.isDisplayMessage = false;
                } else {
                    //display No records found message
                    this.isDialogDisplay = false;
                    this.isDisplayMessage = true;                    
                }
            }).catch(error => {
                this.error = error;
                this.items = undefined;
                this.isDialogDisplay = false;
            });
        } else this.isDialogDisplay = false;
    }

    //This method is called during checkbox value change
    handleCheckboxChange(event) {
        let selectItemTemp = event.detail.value;
        this.selectedItems = []; //it will hold only newly selected checkbox items.    
        /* find the value in items array which has been prepared during database call
           and push the key/value inside selectedItems array           
        */
        selectItemTemp.map( p => {            
            let arr = this.items.find(element => element.value == p);
            if(arr != undefined) this.selectedItems.push(arr);
        }); 
        this.previousSelectedItems.map(p => {
            this.globalSelectedItems = 
                this.globalSelectedItems.filter(item => item.value != p.value);
        });
        //now add newly selected items to the globalSelectedItems
        this.globalSelectedItems.push(...this.selectedItems);
        //store current selection as previousSelectionItems
        this.previousSelectedItems = this.selectedItems;
    }

    //this method removes the pill item
    handleRemoveRecord(event) {
        const removeItem = event.target.dataset.item;
        //this will prepare globalSelectedItems array excluding the item to be removed.
        this.globalSelectedItems = 
            this.globalSelectedItems.filter(item => item.value  != removeItem);
        const arrItems = this.globalSelectedItems;
        this.selectedItems = this.globalSelectedItems;
        //initialize values again
        this.initializeValues();
        this.value = []; 
        //propagate event to parent component
        const evtCustomEvent = new CustomEvent('remove', {   
            detail: { removeItem, arrItems }
        });
        this.dispatchEvent(evtCustomEvent);
    }

    //Done dialog button click event prepares globalSelectedItems which is used to display pills
    handleDoneClick() {
        //remove previous selected items first as there could be changes in checkbox selection
        this.previousSelectedItems.map(p => {
            this.globalSelectedItems = 
                this.globalSelectedItems.filter(item => item.value != p.value);
        });
        //now add newly selected items to the globalSelectedItems
        this.globalSelectedItems.push(...this.selectedItems);        
        const arrItems = this.globalSelectedItems;
        //store current selection as previousSelectionItems
        this.previousSelectedItems = this.selectedItems;
        this.initializeValues();
        this.selectedItems =[];
        //propagate event to parent component
        const evtCustomEvent = new CustomEvent('retrieve', { 
            detail: {arrItems}
        });
        this.dispatchEvent(evtCustomEvent);
    }

    //Cancel button click hides the dialog
    handleCancelClick() {
        this.initializeValues();
    }

    //this method initializes values after performing operations
    initializeValues() {
        this.searchInput = '';        
        this.isDialogDisplay = false;
    }

    handleFocus() {
        //this.fetchLookUpAllValuesWithExcludeValues(); 
        if(this.isListMemberSource) {	
            this.fetchLookUpAllSouceValuesWithExcludeValues();
        } else {
            this.fetchLookUpAllValuesWithExcludeValues(); 
        }
	}

    @api clearSelection() {
		this.globalSelectedItems = [];
	}

    fetchLookUpAllValuesWithExcludeValues() {
		fetchLookUpAllValuesWithExcludeValues({			
            'objectAPIName' : this.objectApiName,
			'recordTypeId' : this.recordTypeId,
            'excludeIds' : JSON.stringify(this.globalSelectedItems)
		}).then(result => {
            this.items = [];
            this.previousSelectedItems = [];
            if(result.length > 0) {
                result.map(resElement => {
                    this.items = [
                        ...this.items,
                        { value: resElement.Id, label: resElement.Name }
                    ];
                    this.globalSelectedItems.map(element => {
                        if(element.value == resElement.Id) {
                            this.previousSelectedItems.push(element);                      
                        }
                    });
                });
                this.isDialogDisplay = true; //display dialog
                this.isDisplayMessage = false;
            } else {
                //display No records found message
                this.isDialogDisplay = false;
                this.isDisplayMessage = true;                    
            }
		}).catch(error => {
			console.log(error);
			this.error = error;
			this.allRecords = undefined;
		});
	}

    fetchLookUpAllSouceValuesWithExcludeValues() {
		fetchLookUpAllSouceValuesWithExcludeValues({			
            'campaignId' : this.campaignId,
            'excludeIds' : JSON.stringify(this.globalSelectedItems)
		}).then(result => {
            this.items = [];
            this.previousSelectedItems = [];
            if(result.length > 0) {
                result.map(resElement => {
                    this.items = [
                        ...this.items,
                        { value: resElement.Id, label: resElement.Name }
                    ];
                    this.globalSelectedItems.map(element => {
                        if(element.value == resElement.Id) {
                            this.previousSelectedItems.push(element);                      
                        }
                    });
                });
                this.isDialogDisplay = true; //display dialog
                this.isDisplayMessage = false;
            } else {
                //display No records found message
                this.isDialogDisplay = false;
                this.isDisplayMessage = true;                    
            }
		}).catch(error => {
			console.log(error);
			this.error = error;
			this.allRecords = undefined;
		});
	}
}