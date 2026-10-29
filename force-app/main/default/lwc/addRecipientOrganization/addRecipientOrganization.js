import { LightningElement, track, api, wire } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from "lightning/messageService";
import recepientdata from "@salesforce/messageChannel/recepientsaveddata__c";
import checkdeleteRecord from '@salesforce/apex/FundraisingProjectController.validateanddeleteOrg';

export default class AddRecipientOrganization extends LightningElement {

    @track record;
    @api allRecords = [];
    toggleSaveLabel = 'Save';
    @api fileds;
    @api objectName;
    @api cardTitle;
    @api cardIcon;
    @api addRowButtonName;

    orgRequired = true;
    orgDisplayFields = ['Search_Display_Name__c', 'AKA__c', 'Legal_Name__c']
    orgSearchFields = ['Search_Display_Name__c'];

    contactDisplayFields = ['Search_Display_Name__c', 'Title', 'Email_Org_Name__c'];
    contactSearchFields = ['Search_Display_Name__c'];

    disableNewRecord = false;
    @wire(MessageContext)
    messageContext;

    addRow() {
        const len = this.allRecords.length;
        var rows = [];
        var objRec = Object.assign({}, this.record);
        objRec.key = len ? len : 0;
        rows = this.allRecords ? this.allRecords : [];
        rows.push(objRec);
        this.allRecords = rows;
        publish(this.messageContext, recepientdata, { record: this.allRecords });
    }
    get tempRecords() {
        if (this.allRecords) {
            const allRecs = this.allRecords;

            var recs = [];
            for (var i = 0; i < allRecs.length; i++) {
                let objRec = Object.assign({}, this.allRecords[i]);
                objRec.key = i;
                objRec.orgIds = allRecs[i].Organization__c ? [allRecs[i].Organization__c] : [];
                objRec.contactIds = allRecs[i].Recipient_Soft_Credit__c ? [allRecs[i].Recipient_Soft_Credit__c] : [];
                objRec.sobjectType = this.objectName;
                objRec.Fundraising_Project__c = allRecs[i].Fundraising_Project__c;
                if (allRecs[i].Recipient_Soft_Credit__c != undefined)
                    objRec.Recipient_Soft_Credit__c = allRecs[i].Recipient_Soft_Credit__c;
                recs.push(objRec);
            }
        } else {
        }
        this.allRecords = [];
        this.allRecords = recs;

        return this.allRecords;
    }
    addrecordtoarray(event) {
        var recs = this.allRecords;
        const indexPos = event.currentTarget.name;
        const recId = event.currentTarget.dataset.selectedid;
        recs[event.currentTarget.dataset.keyid][indexPos] = event.currentTarget.value;
        this.allRecords = recs;

        let payload = { record: this.allRecords };

        publish(this.messageContext, recepientdata, payload);
    }

    lookupReciRecord(event) {
        try {
            const rowElement = event.target.closest('td');
            const key = rowElement?.dataset?.keyid;
            const fieldName = rowElement.dataset.fieldname;
            const selectedId = (event.detail.selectedIds.length > 0 && event.detail.selectedIds) ? event.detail.selectedIds[0] : null; // 👈 since your lookup returns ONLY Id

            if (!key && key !== 0) {
                console.error('Key missing');
                return;
            }
            let recs = [...this.allRecords];
            if (!selectedId) {
                recs[key].orgIds = [];
            }

            recs[key][fieldName] = selectedId;
            this.allRecords = recs;

            publish(this.messageContext, recepientdata, { record: this.allRecords });

        } catch (e) {
            console.error('Lookup Error:', e);
        }
    }

    removeRow1(event) {
        const indexPos = event.currentTarget.name;
        const recId = event.currentTarget.id;
        const myArray = recId.split("-");
        let recordid = myArray[0];
        checkdeleteRecord({ recordid: recordid })
            .then(result => {
                if (result) {
                    let remList = [];
                    remList = this.allRecords;
                    remList.splice(indexPos, 1);
                    this.allRecords = remList;
                    let payload = { record: this.allRecords };
                    publish(this.messageContext, recepientdata, payload);
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Delete Recipient',
                            message: 'Recipient Organization can not be deleted, it is already linked to Pledge.',
                            variant: 'error',
                        }),
                    );
                }
            })
            .catch(error => {
                console.log(error);
                this.error = error;
            });
    }

    @api handleSave() {
        if (this.allRecords) {
            this.allRecords.forEach(rec => {
                delete rec['key'];
                if (!rec.Id) {
                    delete rec['Id'];
                }
            });
        }
        return this.allRecords;
    }
}