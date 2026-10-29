import { LightningElement, api } from 'lwc';
import LightningModal from "lightning/modal";

export default class ImAmendmentDetails extends LightningModal {

    @api imGrant;
    @api amendmentTotalAmount;
    amendmentType;
    amendmentEndDate;
    amendmentAmount;
    hasBudgetChanged;
    conceptApproval;
    continuationOrRealignment;

    isTypeAdministrative = false;

    isError = false;
    errorMessages = [];

    connectedCallback() {
        // IM-488: Added logic to convert the component to a modal
        this.amendmentEndDate = this.imGrant.End_Date__c;
        this.amendmentAmount = this.amendmentTotalAmount;
    }

    get amendmentTypeValues(){
        return [
            { label: 'Grant Amendment', value: 'Grant Amendment' },
            { label: 'SPA-Amendment', value: 'SPA-Amendment' },
            { label: 'Administrative', value: 'Administrative' },
        ];
    }

    get budgetChangedvalues(){
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }

    get continuationOrRealignmentOptions() {
        return [
            { label: 'Continuation of Funding', value: 'Continuation of Funding' },
            { label: 'Strategic Realignment', value: 'Strategic Realignment' },
        ];
    }

    handleAmdTypeChange(event){
        this.amendmentType = event.detail.value;
        if(this.amendmentType == 'Administrative'){
            this.isTypeAdministrative = true;
        }else{
            this.isTypeAdministrative = false;
        }
    }

    handleAmdEndDateChange(event){
        this.amendmentEndDate = event.detail.value;
    }

    handleHasBudgetChanged(event){
        this.hasBudgetChanged = event.detail.value;
    }

    handleConceptApprovalChange(event){
        this.conceptApproval = event.detail.value;
    }

    handleContinuationOrRealignmentChange(event) {
        this.continuationOrRealignment = event.detail.value;
    }

    handleAmdDetailsSave() {
        this.validateAmendmentDetails();
        if(this.errorMessages.length > 0){
            this.isError = true;
        }else{
            this.isError = false;
            let amendmentData = this.amendmentDetails();
            this.close(amendmentData);
        }
    }

    handleClose() {
        this.close('close');
    }

    @api
    amendmentDetails(){
        let amendmentDetails = {
            "amendment_type" : this.amendmentType,
            "end_date" : this.amendmentEndDate,
            "amount_recommended_local" : this.amendmentAmount,
            "state" : 'update',
            "bgive_im_connection" : 'IM Managed'
        };
        if(!this.isTypeAdministrative){
            amendmentDetails['budget_change'] = this.hasBudgetChanged;
            amendmentDetails['concept_approval_received'] = this.conceptApproval;
            amendmentDetails['continuation_of_funding'] = this.continuationOrRealignment;
        }else{
            amendmentDetails['budget_change'] = 'No';
            amendmentDetails['concept_approval_received'] = 'No';
        }
        const amendmentData = {
            errors: this.errorMessages,
            amendmentDetails: amendmentDetails
        }
        return amendmentData;
    }

    validateAmendmentDetails(){
        this.errorMessages = [];
        if(this.amendmentType == undefined){
            this.errorMessages.push('Please select an amendment type');
        }
        if(this.amendmentEndDate == undefined){
            this.errorMessages.push('Please provide Amendment End Date');
        }
        if(this.amendmentAmount == undefined){
            this.errorMessages.push('Please add New Total Amount Recommended (Local)');
        }
        if(!this.isTypeAdministrative && this.hasBudgetChanged == undefined){
            this.errorMessages.push('Please provide details about Budget Change');
        }
        if(!this.isTypeAdministrative && this.conceptApproval == undefined){
            this.errorMessages.push('Please provide details about Concept Approval');
        }
        //Required when amendment type is ""Grant Amendment" or "SPA-Amendment"
        if(!this.isTypeAdministrative && this.continuationOrRealignment == undefined) {
            this.errorMessages.push('Please provide details about Continuation of Funding');
        }
    }
}