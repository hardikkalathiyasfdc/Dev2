import { LightningElement, wire, track, api } from 'lwc';
import getPreviousSoftCreditRelationships from '@salesforce/apex/PledgeWidgetController.getPreviousSoftCredits';

export default class PledgeSoftCreditsWidget extends LightningElement {

    @api recordId;
    @track donorContactColumns = [
        {
            label: 'Contact(s)',
            fieldName: 'donorUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'donorName'
                },
                target: '_blank'
            }
        },
        {
            label: 'Title',
            fieldName: 'title',
            type: 'text',
            sortable: true
        },
        {
            label: 'Organization',
            fieldName: 'orgUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'orgName'
                },
                target: '_blank'
            }
        },
        {
            label: 'Business Email',
            fieldName: 'email',
            type: 'text',
            sortable: true
        }
    ];
    @track previousContactSoftCredits = [];
    @track donorOrgColumns = [
        {
            label: 'Organization(s)',
            fieldName: 'donorUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'donorName'
                },
                target: '_blank'
            }
        },
        {
            label: 'AKA',
            fieldName: 'aka',
            type: 'text',
            sortable: true
        },
        {
            label: 'Organization Email',
            fieldName: 'email',
            type: 'text',
            sortable: true
        },
    ];
    @track previousOrgSoftCredits = [];
    showList = false;
    hasContacts = false;
    hasOrgs = false;

    connectedCallback () {
        console.log ('record Id :::::::: '+this.recordId);
        this.getPreviousSoftCreditRelationships(this.recordId);
    }

    getPreviousSoftCreditRelationships (recordId) {
        getPreviousSoftCreditRelationships({ recordId: recordId })
             .then((result) => {
                console.log('donors 1 :::::::: '+JSON.stringify(result));
                if(result.donorContacts !== null && result.donorContacts !== undefined) {
                    result.donorContacts.forEach(rec => {
                        let objRec = Object.assign({}, rec);
                        objRec['donorId'] = rec.donorId;
                        objRec['donorName'] = rec.donorName;
                        objRec['donorUrl'] = '/' + rec.donorId;
                        objRec['orgName'] = rec.contact.Account.Name;
                        objRec['orgUrl'] = '/' + rec.contact.AccountId;
                        objRec['title'] = rec.contact.Title;
                        objRec['email'] = rec.contact.Email;
            
                        this.previousContactSoftCredits.push(objRec);
                    });
                    this.hasContacts = true;
                    console.log(' 1.6 :::::::: ');
                    console.log('previousSoftCredits 1 :::::::: '+JSON.stringify(this.previousContactSoftCredits));
                }
                
                if(result.donorOrgs !== null && result.donorOrgs !== undefined) {
                    result.donorOrgs.forEach(rec => {
                        let objRec = Object.assign({}, rec);
                        objRec['donorId'] = rec.donorId;
                        objRec['donorName'] = rec.donorName;
                        objRec['donorUrl'] = '/' + rec.donorId;
                        objRec['aka'] = rec.organization.AKA__c;
                        objRec['email'] = rec.organization.Organization_Email__c;
                        this.previousOrgSoftCredits.push(objRec);
                    });
                    this.hasOrgs = true;
                    console.log('previousSoftOrgCredits 1 :::::::: '+JSON.stringify(this.previousOrgSoftCredits));
                }
                
                this.showList = true;
             })
             .catch(error => {
                 console.log('get child records error >>>>>', error);
             })
    }
}