import { LightningElement, api, wire } from 'lwc';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class BlinkOrganizationCard extends LightningElement {
    @api orgDetails;
    @api isBrmOrg = false;
    objectInfo;
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        }
    }
    get canReadRestricted() {
        return this.objectInfo && this.objectInfo.fields.Restricted__c;
    }

    get isRestricted() {
        return this.orgDetails.Restricted__c;
    }
     get orgName() {
        return this.isRestricted && this.canReadRestricted ? this.orgDetails.Restricted_Org_Name__c : this.orgDetails.Name;
    }

    get brmOrgURL() {
        return '/' + this.orgDetails.Id;
    }

    get taxId() {
        return this.isBrmOrg ? this.orgDetails.Tax_ID__c : this.orgDetails.tax_id;
    }

    get taxStatus() {
        return this.isBrmOrg ? this.orgDetails.Tax_Status__c : this.orgDetails.tax_class;
    }

    get legalName() {
        return this.isBrmOrg ? this.orgDetails.Legal_Name__c : this.orgDetails.legal_name;
    }

    get aka() {
        return this.isBrmOrg ? this.orgDetails.AKA__c : this.orgDetails.acronym;
    }
}