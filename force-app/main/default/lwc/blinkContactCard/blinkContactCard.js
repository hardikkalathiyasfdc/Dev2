import { LightningElement, api, wire } from 'lwc';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class BlinkContactCard extends LightningElement {
    @api contactDetails;
    @api isBrmContact = false;
    @api brmContactOrganizationName;
    objectInfo;
    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        }
    }

    get canReadRestricted() {
        return  this.objectInfo && this.objectInfo.fields.Restricted__c;
    }

    get isRestricted() {
        return this.contactDetails.Restricted__c ;
    }
    get brmContactURL() {
        return '/' + this.contactDetails.Id;
    }
    get contactName() {
        return this.isRestricted && this.canReadRestricted ? this.contactDetails.Restricted_Name__c : this.contactDetails.Name;
    }

    get organizationName() {
        return this.isBrmContact ?  this.isRestricted && this.canReadRestricted ? this.contactDetails.Restricted_Org_Name__c : this.brmContactOrganizationName : this.brmContactOrganizationName;
    }

    get title() {
        return this.isBrmContact ? this.contactDetails.Title : this.contactDetails.title;
    }

    get email() {
        return this.isBrmContact ? this.contactDetails.Email : this.contactDetails.email;
    }

    get phone() {
        return this.isBrmContact ? this.contactDetails.Phone : this.contactDetails.phone;
    }

    get brmIdLabel() {
        return this.isBrmContact ? 'BRM Id' : 'BGive Contig Id';
    }

    get brmIdValue() {
        return this.isBrmContact ? this.contactDetails.Id : this.contactDetails.contig_id;
    }
}