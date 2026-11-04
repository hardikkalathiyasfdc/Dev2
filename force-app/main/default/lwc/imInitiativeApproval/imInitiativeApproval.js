import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/IM_Initiative__c.Id';
import STATUS from '@salesforce/schema/IM_Initiative__c.Status__c';
import ISAPPROVED from '@salesforce/schema/IM_Initiative__c.Approved__c';
import APPROVED_DATE from '@salesforce/schema/IM_Initiative__c.Approved_Date__c';
import APPROVER from '@salesforce/schema/IM_Initiative__c.Approver__c';
import ORIGINAL_APPROVED_DATE from '@salesforce/schema/IM_Initiative__c.Original_Approved_Date__c';
import INITIATIVE_TYPE from '@salesforce/schema/IM_Initiative__c.Initiative_Type__c';
import CURRENT_BUDGET from '@salesforce/schema/IM_Initiative__c.Current_Budget__c';
import PARENT_INITIATIVE from '@salesforce/schema/IM_Initiative__c.Parent_Initiative__c';
import TERM_ALIGNMENT from '@salesforce/schema/IM_Initiative__c.Term_Alignment__c';
import REQUIRED_APPROVAL_DOCS from '@salesforce/schema/IM_Initiative__c.Required_Approval_Docs__c';
import INITIATIVE_BUDGET_NAME from '@salesforce/schema/IM_Initiative__c.Initiative_Name_and_Budget_Name_Review__c';
import LOCATIONS_ALIGNED from '@salesforce/schema/IM_Initiative__c.Strategic_Locations_Aligned__c';
import BUDGET_ALIGNS from '@salesforce/schema/IM_Initiative__c.Budget_Aligns_with_Memo__c';
import TYPE_OF_WORK_ALIGNS from '@salesforce/schema/IM_Initiative__c.Type_of_Work_Aligns_Memo__c';
import BUDGET_ID_FIELD from '@salesforce/schema/IM_Budget__c.Id';
import BUDGET_STATUS from '@salesforce/schema/IM_Budget__c.Status__c';

// Constants
const YES = 'Yes';
const APPROVER_NOT_POPULATED = 'Please populate the Approver on Initiative and try again.'
const PENDING_APPROVAL = 'Pending Approval';
const APPROVED = 'Approved';
const COMPLETED = 'Completed';
const ONGOING = 'Ongoing';

export default class ImInitiativeApproval extends LightningElement {
    @api recordId;
    _invoked = false;
    initiative;
    isAmendment = false;
    isInitiativeUpdated = false;
    showSpinner = false;
    isError = false;

    @wire(getRecord, { recordId: '$recordId', fields: [INITIATIVE_TYPE, CURRENT_BUDGET, PARENT_INITIATIVE, APPROVER, TERM_ALIGNMENT, REQUIRED_APPROVAL_DOCS, INITIATIVE_BUDGET_NAME, LOCATIONS_ALIGNED, BUDGET_ALIGNS, TYPE_OF_WORK_ALIGNS] })
    wiredInitiative({ data, error }) {
        if (data) {
            this.initiative = data;
            if(getFieldValue(this.initiative, INITIATIVE_TYPE)  == 'Amendment') {
                this.isAmendment = true;
            }
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }


    @api async invoke() {
        if(this._invoked) return;
        this._invoked = true;

        try {
            if(!this.initiative) return;

            const errors = this.validateCheckList();
            if(this.isError) {
                this._invoked = false;
                this.showErrorToast('Checklist is not complete. Please submit the initiative for revisions');
            } else if(errors.length) {
                this._invoked = false;
                errors.forEach((error) => this.showErrorToast(error));
            } else{
                if(this.isAmendment) {
                    this.showSpinner = true;
                    this.updateBudgetStatus(APPROVED);
                } else{
                    this.showSpinner = true;
                    this.updateInitiative();
                }
            }
        } catch(error) {
            this._invoked = false;
        }

    }

    validateCheckList() {
        const errors = [];
        this.isError = false;
        const termAlignment = getFieldValue(this.initiative, TERM_ALIGNMENT);
        const initiativeBudgetName = getFieldValue(this.initiative, INITIATIVE_BUDGET_NAME);
        const requiredApprovalDocs = getFieldValue(this.initiative, REQUIRED_APPROVAL_DOCS);
        const locationAligned = getFieldValue(this.initiative, LOCATIONS_ALIGNED);
        const budgetAligns = getFieldValue(this.initiative, BUDGET_ALIGNS);
        const typeOfWorkAligns = getFieldValue(this.initiative, TYPE_OF_WORK_ALIGNS);
        const approver = getFieldValue(this.initiative, APPROVER);
        const parentInitiative = getFieldValue(this.initiative, PARENT_INITIATIVE);
        const currentBudget = getFieldValue(this.initiative, CURRENT_BUDGET);

        if(termAlignment != YES) {
            this.isError = true;
        }else if(initiativeBudgetName != YES) {
            this.isError = true;
        }else if(requiredApprovalDocs != YES) {
            this.isError = true;
        }else if(!locationAligned) {
            this.isError = true;
        }else if(!budgetAligns) {
            this.isError = true;
        }else if(!typeOfWorkAligns) {
            this.isError = true;
        }else if(!parentInitiative) {
            this.isError = true;
        }else if(!currentBudget) {
            this.isError = true;
        }else if(!approver){
            errors.push(APPROVER_NOT_POPULATED)
        }
        return errors;
    }


    updateBudgetStatus(status) {
        const fields = {}
        fields[BUDGET_ID_FIELD.fieldApiName] = getFieldValue(this.initiative, CURRENT_BUDGET);      
        fields[BUDGET_STATUS.fieldApiName] = status;

        const recordInput = { fields };

        updateRecord(recordInput)
        .then(() => {
            if(!this.isInitiativeUpdated){
                this.updateInitiative();
            }
        })
        .catch((error) => {
            this.showSpinner = false;
            this.showErrorToast(error);
        });
    }

    updateInitiative() {
        const fields = {}
        fields[ID_FIELD.fieldApiName] = this.recordId;      
        fields[ISAPPROVED.fieldApiName] = true;
        fields[APPROVED_DATE.fieldApiName] = new Date().toISOString().split('T')[0];
        fields[APPROVER.fieldApiName] = getFieldValue(this.initiative, APPROVER);

        if(this.isAmendment) {
            fields[STATUS.fieldApiName] = COMPLETED;
            fields[PARENT_INITIATIVE.fieldApiName] = '';
        }else {
            fields[STATUS.fieldApiName] = ONGOING;
            fields[ORIGINAL_APPROVED_DATE.fieldApiName] = getFieldValue(this.initiative, APPROVED_DATE) ? getFieldValue(this.initiative, APPROVED_DATE) : new Date().toISOString().split('T')[0];
        }

        const recordInput = { fields };

        updateRecord(recordInput)
        .then(() => {
            this.isInitiativeUpdated = true;
            this.showSpinner = false;
            this.showSuccessToast('Initiative is successfully approved');
        })
        .catch((error) => {
            if(this.isAmendment) {
                this.isInitiativeUpdated = true;
                this.showSpinner = false;
                this.updateBudgetStatus(PENDING_APPROVAL);
            }
            this.showErrorToast('Cannot approve initiative', error);
        });
    }

    showErrorToast(displayMessage) {
        const errorEvt = new ShowToastEvent({
            title: 'Error',
            message: displayMessage,
            variant: 'error',
            mode: 'dismissable',
        });
        this.dispatchEvent(errorEvt);
    }

    showSuccessToast(displayMessage) {
        const errorEvt = new ShowToastEvent({
            title: 'Success',
            message: displayMessage,
            variant: 'success',
            mode: 'dismissable',
        });
        this.dispatchEvent(errorEvt);
    }
}