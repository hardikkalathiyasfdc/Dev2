import { LightningElement, api, wire,track } from 'lwc';
// import apex method from salesforce module 
import fetchLookupDataFilter from '@salesforce/apex/organizationCustomLookUpController.fetchLookupDataFilter';
import fetchDefaultRecord from '@salesforce/apex/organizationCustomLookUpController.fetchDefaultRecord';
const DELAY = 300; // dealy apex callout timing in miliseconds  

export default class OrganizationCustomLookUp extends LightningElement {
// public properties with initial default values 
@api label = 'custom lookup label';
@api placeholder = 'search...';
@api iconName = 'standard:account';
@api sObjectApiName = 'Account';
@api defaultRecordId = '';

@api filterData = '';
@api parentfieldApiName ='';
@api parentRecordId ='';
@api isParentRequired = false;
@api isRequired;

_required = false;

// private properties 
lstResult = []; // to store list of returned records 
@track orgName; 
@track temp=[];
hasRecords = true;
searchKey = ''; // to store input field value    
isSearchLoading = false; // to control loading spinner  
delayTimeout;
selectedRecord = {}; // to store selected lookup record in object formate 


// initial function to populate default selected lookup record if defaultRecordId provided  
connectedCallback() {
    this._required  = this.isRequired ? true : false;
    //console.log('isRequired::::',this.isRequired);
    console.log('this.defaultRecordId>>>>',this.defaultRecordId);
     if (this.defaultRecordId != '') {
         console.log('Inside this.defaultRecordId>>>>');
        fetchDefaultRecord({ recordId: this.defaultRecordId, 'sObjectApiName': this.sObjectApiName })
            .then((result) => {
                console.log('default result>>>>',result);
                console.log(result);
                if (result != null) {
                    this.selectedRecord = result;
                    this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                }
            })
            .catch((error) => {
                console.log(error);
                this.error = error;
                this.selectedRecord = {};
            });
    } 
}

get hasRequired(){
    return  this._required && this.isRequired ? this.isRequired : false; 
}

@api isvalid(){
    const All_Valid =true;
    this._required  = this.isRequired ? true : false;
     All_Valid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, input_Field_Reference) => {
            input_Field_Reference.reportValidity();
            return validSoFar && input_Field_Reference.checkValidity();
        }, true);   
                  
    return All_Valid;
}

// wire function property to fetch search record based on user input
/*  @wire(getRecord, { recordId: '$defaultRecordId', sObjectApiName: '$sObjectApiName' })
defaultResult(value) {
    const { data, error } = value; 
    if (data) {
        this.selectedRecord = result;
        this.handelSelectRecordHelper(); 
    }
    else if (error) {
        console.log('(error---> ' + JSON.stringify(error));
            this.selectedRecord = {};
    }
}; */


// wire function property to fetch search record based on user input
@wire(fetchLookupDataFilter, 
{ searchKey: '$searchKey', 
    sObjectApiName: '$sObjectApiName', 
    parentfieldApiName:'$parentfieldApiName',
    pRecordId: '$parentRecordId',
    isParentRequired:'$isParentRequired'
})
searchResult(value) {
    const { data, error } = value; // destructure the provisioned value
    this.isSearchLoading = false;
    if (data) {            
        this.hasRecords = data.length == 0 ? false : true;
        this.lstResult = JSON.parse(JSON.stringify(data));
        console.log('Organization result>>>>>>', JSON.stringify(data));
    }
    else if (error) {
        console.log('(error---> ' + JSON.stringify(error));
    }
};


// update searchKey property on input field change  
handleKeyChange(event) {
    // Debouncing this method: Do not update the reactive property as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    this.isSearchLoading = true;
    
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    this.delayTimeout = setTimeout(() => {
        this.searchKey = searchKey;
    }, DELAY);
}
// method to toggle lookup result section on UI 
toggleResult(event) {
    const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
    const clsList = lookupInputContainer.classList;
    const whichEvent = event.target.getAttribute('data-source');
    switch (whichEvent) {
        case 'searchInputField':
            this._required  = false;
            clsList.add('slds-is-open');
            break;
        case 'lookupContainer':
            this._required  = this.isRequired ? true : false;
            clsList.remove('slds-is-open');
            break;
    }
}

// method to clear selected lookup record  
handleRemove(event) {
    event.preventDefault();
    this.searchKey = '';
    this.selectedRecord = {};
    this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
    
    // remove selected pill and display input field again 
    const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
    searchBoxWrapper.classList.remove('slds-hide');
    searchBoxWrapper.classList.add('slds-show');
    const pillDiv = this.template.querySelector('.pillDiv');
    pillDiv.classList.remove('slds-show');
    pillDiv.classList.add('slds-hide'); 
    
}
// method to update selected record from search result 
handelSelectedRecord(event) {        
    var objId = event.target.getAttribute('data-recid'); // get selected record Id 
    console.log('the selected ID-->'+objId);
    this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list 
    this.temp=JSON.parse(JSON.stringify(this.selectedRecord));
        this.orgName=this.temp.Name;
    //this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function
        this.dispatchEvent(new CustomEvent('lookupupdate', { detail: { selectedRecord:  this.selectedRecord  } })); 
    this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
        this._required  = this.isRequired ? true : false;
    
}
/*COMMON HELPER METHOD STARTED*/
handelSelectRecordHelper() {
    this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
    const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
    searchBoxWrapper.classList.remove('slds-show');
    searchBoxWrapper.classList.add('slds-hide');
    const pillDiv = this.template.querySelector('.pillDiv');
    pillDiv.classList.remove('slds-hide');
    pillDiv.classList.add('slds-show');
}
// send selected lookup record to parent component using custom event
lookupUpdatehandler(value) {
    const oEvent = new CustomEvent('lookupupdate',
        {
            'detail': { selectedRecord: value }
        }
    );
    this.dispatchEvent(oEvent);
}
 @api isValidRecp(){       
       console.log('record Appeall',this.selectedRecord);
        var isVal = true;
        if(this.selectedRecord.Id === null || this.selectedRecord.Id === undefined ){
        isVal = false;
        }else{
            isVal = true;
        }
       
        console.log('validationn isVal',isVal);
        return isVal;
    }
}