import { LightningElement, api, wire } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import getDNCContacts from "@salesforce/apex/ExportContactsController.getDNCContacts";
import hasRestrictedAccess from '@salesforce/customPermission/Private_Name_Fields';
import NUMBER_OF_DO_NOT_CONTACT_FIELD from '@salesforce/schema/Campaign.Do_Not_Contact__c';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

export default class ExportDNCFile extends LightningElement {
	@api recordId;
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
    doNotContactCount;
    columnSelection = false;	
		allColumns = [	
        {label:'Salutation',value:'salutation'},	
        {label:'First/Preferred First Name',value:'firstOrPreferredFirstName'},	
        {label:'First Name',value:'firstName'},	
        {label:'Preferred First Name',value:'preferredFirstName'},
        {label:'Middle Name',value:'middleName'},
        {label:'Last Name',value:'lastName'},	
        //{label:'Guest Email',value:'guestEmail'},	
        //{label:'Guest Email Type',value:'guestEmailType'},	
        {label:'Business Email',value:'businessEmail'},	
        {label:'Personal Email',value:'personalEmail'},	
        {label:'Additional Email',value:'additionalEmail'},	
        {label:'Significant Other',value:'significantOther'},	
        {label:'Contact Alert Reason',value:'ContactAlertReason'},	
        {label:'Title',value:'title'},	
        {label:'Organization',value:'organization'},	
        {label:'Priority Email',value:'priorityEmail'},	
        {label:'F&F Tags',value:'ffTags'},	
        {label:'Other Tags',value:'otherTags'},	
        {label:'Contact ID',value:'id'},	
        {label:'Confidential Email',value:'confidentialEmail'},	
        {label:'Business Phone (Country Code)',value:'businessPhoneCC'},	
        {label:'Business Phone',value:'businessPhone'},	
        {label:'Mobile Phone (Country Code)',value:'mobilePhoneCC'},	
        {label:'Mobile Phone',value:'mobilePhone'},	
        {label:'Business Address',value:'businessAddress'},	
        {label:'Home Address',value:'homeAddress'},	
        {label:'Staff Name',value:'assistantName'},	
        {label:'Staff Business Email',value:'assistantEmail'},	
        {label:'Staff Role',value:'staffRole'},
        {label:'Correspondence Dear Line',value:'correspondenceDearLine'},	
        {label:'Correspondence Annual Report Salutation',value:'annualReportSalutation'},	
        {label:'Salutation Spouse',value:'salutationSpouse'},
        {label:'LP Client',value:'client'},
        {label:'Tag ID',value:'tagId'},
        {label:'Tags ID',value:'tagsId'},
        {label:'Tag Private',value:'tagPrivate'},
        {label:'Tag Owner',value:'tagOwner'},	
        //{label:'List Member Outreach Method',value:'listMemberOutreachMethod'},	
        //{label:'List Member Preferred Email',value:'listMemberPreferredEmail'},	
        //{label:'List Member Preferred Mail/Address',value:'listMemberPreferredMailAddress'},	
        {label:'List Member ID',value:'listMemberId'},	
    ];	
    //columnHeaders = ['Salutation','First/Preferred First Name','Last Name','Significant Other','Title','Organization','F&F Tags','Other Tags','Contact ID'];	
    selectedColumns = ["firstOrPreferredFirstName","lastName","significantOther","title","organization","ContactAlertReason","id","listMemberId"];	
    columnHeaders = ['First/Preferred First Name','Last Name', 'Significant Other','Title','Organization',"Contact Alert Reason",'Contact ID','List Member ID'];	
    
		
		connectedCallback(){
				console.log(' recordid >>> '+this.recordId);
				this.getDNCContacts();
		}

        @wire(getRecord, {recordId: '$recordId', fields: [NUMBER_OF_DO_NOT_CONTACT_FIELD]})
        wiredList({data, error}) {
            if(data){
                console.log('###########wiredList-data: ' + JSON.stringify(data));
                this.doNotContactCount = data.fields?.Do_Not_Contact__c?.value;
                console.log('###########wiredList-doNotContactCount: ' + doNotContactCount);
            } else if(error){
                console.error('Error fetching member count', error);
            }
        }
		
		getDNCContacts() {
				getDNCContacts({
                    "recordId":this.recordId
                })
                .then((result) => {
                    if (result.error) {
                        console.log('error ::::: ');
                    } else {
                        console.log('d ====== '+JSON.stringify(result));
                        this.contacts = result;
                        //this.exportToCSV();
                        let restrictedContactCount =
                            this.contacts.length > 0
                                ? this.contacts.filter(contact => contact.contact && contact.contact.Restricted__c === true).length
                                : 0;
                        if(!hasRestrictedAccess) {
                            restrictedContactCount = Math.max(this.doNotContactCount - (this.contacts ? this.contacts.length : 0), 0);
                        }
                        console.log('###########restrictedContactCount: ' + restrictedContactCount);
                        if (restrictedContactCount > 0) {
                            this.confirmCSVExport(restrictedContactCount);
                        } else {
                            this.exportToCSV();
                        }
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
        csvIterativeData = 'Contact Report with the following : ';
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

    async confirmCSVExport(restrictedCount) {
        let warningMessage = 'Your results contain ' + restrictedCount + ' Private Contact(s).';
        if (!hasRestrictedAccess && restrictedCount > 0) {
				warningMessage = 'You\'ve encountered a problem with some of the records you selected (' +
					restrictedCount + ' record(s) are not exporting). ' +
					'Please contact brmpartnerships@bloomberg.org for further assistance.';
		}
        const confirmed = await LightningConfirm.open({
            message: warningMessage,
            label: 'Warning!',
            variant: 'warning',
            theme: 'warning'
        });
        if (confirmed) {
            this.exportToCSV();
        } else {
            window.history.back();
        }
    }
}