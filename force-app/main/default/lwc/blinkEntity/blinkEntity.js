import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import hasContactBlinkAccess from '@salesforce/customPermission/Contact_B_Link_Access';
import hasOrgBlinkAccess from '@salesforce/customPermission/Organization_B_Link_Access';

export default class BlinkEntity extends LightningElement {

    isFromContact = false;
    isFromOrg = false;
    recordId;
    isContactBlinkVisible = hasContactBlinkAccess;
    isOrgBlinkVisible = hasOrgBlinkAccess;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if(currentPageReference) {
            this.isFromContact = currentPageReference.state?.c__isFromContact;
            this.isFromOrg = currentPageReference.state?.c__isFromOrg;
            this.recordId = currentPageReference.state?.c__recordId;
        }
    }
}