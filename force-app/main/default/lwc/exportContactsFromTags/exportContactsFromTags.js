import { LightningElement, api, wire } from 'lwc';
import getContacts from "@salesforce/apex/ExportContactsController.getContacts";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import Confidential_Info from '@salesforce/customPermission/Confidential_Info';



export default class ExportContactsFromTags extends NavigationMixin(LightningElement) {
    @api contacts;
    @api tagIds;
    @api navigateToList;
    selectedTags
    typeSelection = true;	
    listAddScreen = false;	
    showListLookup = false;	
    showListText = false;	
    targetList =  '';	
    typeOfExport = '';	
    isLoading = false;	
    newList = false;	
    columnSelection = false;	

    get allColumns() {
       let cols= [	
        {label:'Salutation',value:'salutation'},	
        {label:'First/Preferred First Name',value:'firstOrPreferredFirstName'},	
        {label:'First Name',value:'firstName'},	
        {label:'Preferred First Name',value:'preferredFirstName'},
        {label:'Middle Name',value:'middleName'},
        //{label:'Business Street',value:'businessstreet'},

        {label:'Last Name',value:'lastName'},	
        //{label:'Guest Email',value:'guestEmail'},	
        //{label:'Guest Email Type',value:'guestEmailType'},	
        {label:'Business Email',value:'businessEmail'},	
        {label:'Personal Email',value:'personalEmail'},	
        {label:'Additional Email',value:'additionalEmail'},	
    
        {label:'Significant Other Name (Preferred)',value:'SignificantOtherPreferredFirstName'},	
        {label:'Title',value:'title'},	
        {label:'Organization',value:'organization'},	
        {label:'Priority Email',value:'priorityEmail'},	
        {label:'F&F Tags',value:'ffTags'},	
        {label:'Other Tags',value:'otherTags'},	
        {label:'Contact ID',value:'id'},	
        	
        //{label:'List Member Outreach Method',value:'listMemberOutreachMethod'},	
        //{label:'List Member Preferred Email',value:'listMemberPreferredEmail'},	
        //{label:'List Member Preferred Mail/Address',value:'listMemberPreferredMailAddress'},	
        //{label:'List Member ID',value:'listMemberId'},	
    ];

    if(Confidential_Info){
        cols.push(
        {label:'Confidential Email',value:'confidentialEmail'});
    }


    let cols2 =[{label:'Business Phone (Country Code)',value:'businessPhoneCC'},	
        {label:'Business Phone',value:'businessPhone'},	
        {label:'Mobile Phone (Country Code)',value:'mobilePhoneCC'},	
        {label:'Mobile Phone',value:'mobilePhone'},	
        //{label:'Business Address',value:'businessAddress'},	
        //{label:'Home Address',value:'homeAddress'},
        {label:'Business Street',value:'BusinessStreet'},
        {label:'Business City',value:'BusinessCity'},
        {label:'Business State/Province',value:'BusinesState'},
        {label:'Business Zip/Postal Code',value:'BusinessPostalCode'},
        {label:'Business Country',value:'BusinessCountry'},

        {label:'Home Street',value:'HomeStreet'},    
        {label:'Home City',value:'HomeCity'},
        {label:'Home Zip/Postal Code',value:'HomePostalCode'},
        {label:'Home State/Province',value:'HomeStateProvince'},
        {label:'Home Country',value:'HomeCountry'},


        {label:'Confidential Address Type',value:'ConfidentialAddressType'},
        {label:'Confidential Street',value:'ConfidentialStreet'},
        {label:'Confidential Street2',value:'ConfidentialStreet2'},
        {label:'Confidential Street3',value:'ConfidentialStreet3'},
        {label:'Confidential City',value:'ConfidentialCity'},
        {label:'Confidential State/Province',value:'ConfidentialStateProvince'},
        {label:'Confidential Zip/Postal Code',value:'ConfidentialZipPostalCode'},
        {label:'Confidential Country',value:'ConfidentialCountry'},

        {label:'Assistant Name',value:'assistantName'},	
        {label:'Assistant Business Email',value:'assistantEmail'},	
        {label:'Staff Role',value:'staffRole'},
        {label:'Correspondence Annual Report Salutation',value:'annualReportSalutation'},
        {label:'Correspondence Dear Line',value:'correspondenceDearLine'},	
	    
        {label:'Salutation Spouse',value:'salutationSpouse'},
        {label:'Significant Other',value:'significantOther'},
        {label:'Significant Other Salutation',value:'SignificantSalutation'},
        {label:'Correspondence Significant Other Annual Report Salutation',value:'SignificantARSalutation'},
        {label:'LP Client',value:'client'},
        {label:'Do Not Contact',value:'DoNotCall'},
        {label:'Contact Alert Reason',value:'ContactAlertReason'},
        
        //{label:'Significant Other Salutation',value:'Primary_Spouse__c'},
        {label:'Tag ID',value:'tagId'},
        {label:'Tags ID',value:'tagsId'},
        {label:'Tag Private',value:'tagPrivate'},
        {label:'Tag Owner',value:'tagOwner'}]


    return cols.concat(cols2);	
    }
  //  columnHeaders = ['Salutation','First/Preferred First Name','Last Name','Significant Other','Title','Organization','F&F Tags','Other Tags','Contact ID'];	
  //  selectedColumns = ["salutation","firstOrPreferredFirstName","lastName","significantOther","title","organization","ffTags","otherTags","id"];	
    columnHeaders = ['First/Preferred First Name','Last Name','Significant Other Name (Preferred)','Title','Organization','Priority Email','F&F Tags','Other Tags','Contact ID','List Member ID'];	
    selectedColumns = ["firstOrPreferredFirstName","lastName","SignificantOtherPreferredFirstName","title","organization","priorityEmail","ffTags","otherTags","id","listMemberId"];	
    get options() {	
        return [	
            { label: 'Standard', value: 'Standard' },	
            { label: 'Executive', value: 'Executive' }	
        ];	
    }

    //columnHeader = ['First/Preferred First Name', 'Last Name','Significant Other','Title', 'Organization', 'Priority Email', 'F&F Tags', 'Other Tags', 'Contact ID', 'Salutation'];

    connectedCallback () {
        console.log('tagids :::::: '+this.tagIds);
       
        //this.getContacts();
    }

    handleChange(event) {	
        this.typeOfExport = event.detail.value;	
        this.typeSelection = false;	
        this.columnSelection = true;	
       // if(this.typeOfExport !== '') this.getContacts();	
    }	
    handleColumnSelection(event) {	
        this.selectedColumns = event.detail.value;	
        let headers = [];	
        for (let i=0; i<this.selectedColumns.length; i++) {	
            let header = this.allColumns.find(o => o.value === this.selectedColumns[i]);	
            headers.push(header.label);	
        }	
        this.columnHeaders = headers;	
    }	
    handleFinish() {	
        if(this.typeOfExport !== '') this.getContacts();	
        else{
            this.template.querySelector('c-custom-toast').showToast('error','Please select export type before exporting','utility:error',10000);
        }
    }

    handleCancel(){
        window.history.back();
    }

    getContacts () {
        getContacts({
            "tagIds":this.tagIds,
            "typeOfExport": this.typeOfExport
        })
        .then((result) => {
            if (result.error) {
                console.log('error ::::: ');
            } else {
                console.log('d ====== '+JSON.stringify(result));
                this.contacts = result;
                if (this.contacts.length > 0) {
                    this.selectedTags = this.contacts[0].selectedTags;
                } 
                this.exportToCSV();
            }
        })
        .catch((error) => {
            console.log(error);
        });
    }

  
    exportToCSV() {  	
        console.log('export to csv ::: '+this.contacts.length);	
        var jsonRecordsData = this.contacts;  	
        let csvIterativeData;  	
        let csvSeperator  	
        let newLineCharacter;  	
        csvSeperator = ",";  	
        newLineCharacter = "\n";  	
        let tagsName= (this.selectedTags) ? this.selectedTags.substring(0,this.selectedTags.length-1):'';	
        csvIterativeData = 'Contact Report with the following tags: '+ tagsName
        csvIterativeData += newLineCharacter; 
        csvIterativeData += newLineCharacter; 
        csvIterativeData += this.columnHeaders.join(csvSeperator);  	
        csvIterativeData += newLineCharacter;	
        console.log('length >>>>>>> '+jsonRecordsData.length);
        for (let i = 0; i < jsonRecordsData.length; i++) {	
            console.log('index :::: '+i);	
          let counter = 0;	
          for (let iteratorObj in this.selectedColumns) {	
            let dataKey = this.selectedColumns[iteratorObj];	
            console.log('dataKey >>>> '+dataKey);
            if (counter > 0) {  csvIterativeData += csvSeperator;  }  	
            if (  jsonRecordsData[i][dataKey] !== null &&  	
              jsonRecordsData[i][dataKey] !== undefined  	
            ) {	
                if(jsonRecordsData[i][dataKey].includes('"')) {	
                    csvIterativeData += '"' + jsonRecordsData[i][dataKey].replace(/"/g, '""') + '"';	
                } else {	
                    csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';	
                }	
                  	
            } else {	
                csvIterativeData += '""';  	
            }  	
            counter++; 
            console.log('Counter '+counter); 	
          }  	
          csvIterativeData += newLineCharacter;  	
        }	
        console.log("csvIterativeData :::: "+ csvIterativeData);  	
        this.hrefdata = "data:text/csv;charset=utf-8,%EF%BB%BF" + encodeURIComponent(csvIterativeData);	
        let downloadElement = document.createElement('a');	
        downloadElement.href = this.hrefdata;	
        downloadElement.target = '_blank';	
        downloadElement.download = 'Custom Export.csv';	
        document.body.appendChild(downloadElement);	
        downloadElement.click();	
        window.history.back();
        //this.navigateToTab();
        this.isLoading = false;	
    }	


    showToast() {
        const event = new ShowToastEvent({
            title: 'Get Help',
            message:
                'Salesforce documentation is available in the app. Click ? in the upper-right corner.',
        });
        this.dispatchEvent(event);
    }
        
}