import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createAmendment from '@salesforce/apex/IMCreateAmendmentController.createAmendment';

const REDIRECT_OBJECT = 'IM_Initiative__c';
const GENERIC_CREATE_AMENDMENT_FAIL_HEADER = 'Amendment creation failed: ';
const SUCCESS_TOAST = 'Amendment record is created successfully.';

export default class ImCreateAmendment extends NavigationMixin(LightningElement) {
    
    //Variables
    _recordId;
    amendmentRecordId;
    showSpinner = false;
    
    @api set recordId(value) {
        this._recordId = value;
        //Once salesforce sets the record Id internally, call the apex method responsible for record creation.
        this.createAmendment();
    }
    
    get recordId() {
        return this._recordId;
    }
    
    /*
    Description: create the initiative amendment record
    Jira Story : IM-170
    */
    async createAmendment(){
        try{
            this.showSpinner = true;
            let result = await createAmendment({ initiativeId : this._recordId});
            if(result && result != ''){
                if(result){
                    this.amendmentRecordId = result;
                    //Amendment record is created, navigate to the newly created record page
                    this.navigateToRecordPage();
                }else{
                    this.showSpinner = false;
                    this.showErrorToast(GENERIC_CREATE_AMENDMENT_FAIL_HEADER, ' Amendment creation failed with an error in apex');
                }
            }
        } catch (error) {
            this.showSpinner = false;
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showErrorToast(GENERIC_CREATE_AMENDMENT_FAIL_HEADER, error.body.message);
        }
    }
    
    /*
    Description: Show Success Toast Message when amendment is created.
    Jira Story : IM-170
    */
    showSuccessToast(displayMessage) {
        const successEvent = new ShowToastEvent({
            title: 'Success',
            message: displayMessage,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(successEvent);
    }
    
    /*
    Description: Show Error Toast Message when error occurs
    Jira Story : IM-170
    */
    showErrorToast(title, displayMessage) {
        const errorEvt = new ShowToastEvent({
            title: title,
            message: displayMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(errorEvt);
    }
    
    /*
    Description: Navigates to the newly created amendment record.
    Jira Story : IM-170
    */
    navigateToRecordPage() {
        this.showSpinner = false;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.amendmentRecordId,
                objectApiName: REDIRECT_OBJECT,
                actionName: 'view'
            },
        });
        this.showSuccessToast(SUCCESS_TOAST);
    }
}