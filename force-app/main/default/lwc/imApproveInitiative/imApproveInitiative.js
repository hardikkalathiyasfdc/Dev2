import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { refreshApex } from "@salesforce/apex";
import ID_FIELD from '@salesforce/schema/IM_Initiative__c.Id';
import STATUS from '@salesforce/schema/IM_Initiative__c.Status__c';
import APPROVED from '@salesforce/schema/IM_Initiative__c.Approved__c';
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
import getInitiative from '@salesforce/apex/IMApproveInitiativeController.getInitiative';
// import updateBudgetStatus from '@salesforce/apex/IMApproveInitiativeController.updateBudgetStatus';

// Constants
const YES = 'Yes';
const APPROVER_NOT_POPULATED = 'Please populate the Approver on Initiative and try again.'

export default class ImApproveInitiative extends LightningElement {
    @api recordId;
    _invoked = false;
    initiative;
    isError = false;

    @wire(getRecord, { recordId: '$recordId', fields: [CURRENT_BUDGET, PARENT_INITIATIVE, APPROVER, INITIATIVE_TYPE, TERM_ALIGNMENT, REQUIRED_APPROVAL_DOCS, INITIATIVE_BUDGET_NAME, LOCATIONS_ALIGNED, BUDGET_ALIGNS, TYPE_OF_WORK_ALIGNS] })
    wiredInitiative({ data, error }) {
        if (data) {
            this.initiative = data;
            console.log('ini: '+this.initiative);
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    // @wire(getInitiative, { initiativeId: '$recordId' })
    // wiredInitiative({ data, error }) {
    //     if (data) {
    //         this.initiative = data;
    //         console.log('ini: '+this.initiative);
    //         this.error = undefined;
    //     } else if (error) {
    //         this.error = error;
    //     }
    // }

    // @api set recordId(value) {
	// 	this._recordId = value;
	// }

	// get recordId() {
	// 	return this._recordId;
	// }

    // connectedCallback() {
	// 	this.getInitiative();
	// }


    @api async invoke() {
        if(this._invoked) return;
        this._invoked = true;

        try {
            console.log('ini: ',this.initiative);
            if(!this.initiative) return;

            const errors = this.validateCheckList();
            console.log('err len: ',errors.length);
            console.log('err: ',errors);
            if(this.isError) {
                this.showErrorToast('Checklist is not complete. Please submit the initiative for revisions');
            } else if(errors.length) {
                errors.forEach((error) => this.showErrorToast(error));
                this._invoked = false;
            }

            if(getFieldValue(this.initiative, INITIATIVE_TYPE) == 'Amendment') {
                this.updateBudgetStatus(getFieldValue(this.initiative, CURRENT_BUDGET));
            } else{
                const fields = {};
                fields[ID_FIELD.fieldApiName] = this.recordId;
                fields[STATUS.fieldApiName] = 'Ongoing';
                fields[APPROVED.fieldApiName] = true;
                fields[APPROVED_DATE.fieldApiName] = new Date().toISOString().split('T')[0];
                fields[ORIGINAL_APPROVED_DATE.fieldApiName] = getFieldValue(this.initiative, APPROVED_DATE) ? getFieldValue(this.initiative, APPROVED_DATE) : new Date().toISOString().split('T')[0];

                const recordInput = { fields };

                updateRecord(recordInput)
                    .then(() => {
                        this.showSuccessToast('Initiative is successfully approved');
                        // return refreshApex(this.initiative);
                    })
                    .catch((error) => {
                        this.showErrorToast('Cannot approve initiative', error);
                    });
            }
        } catch(error) {
            console.log('error: ',error);
            this._invoked = false;
        }

    }

    validateCheckList() {
        console.log('here: ',this.initiative);
        const errors = [];
        const termAlignment = getFieldValue(this.initiative, TERM_ALIGNMENT);
        const initiativeBudgetName = getFieldValue(this.initiative, INITIATIVE_BUDGET_NAME);
        const requiredApprovalDocs = getFieldValue(this.initiative, REQUIRED_APPROVAL_DOCS);
        const locationAligned = getFieldValue(this.initiative, LOCATIONS_ALIGNED);
        const budgetAligns = getFieldValue(this.initiative, BUDGET_ALIGNS);
        const typeOfWorkAligns = getFieldValue(this.initiative, TYPE_OF_WORK_ALIGNS);
        const approver = getFieldValue(this.initiative, APPROVER);

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
        }else if(!approver){
            errors.push(APPROVER_NOT_POPULATED)
        }
        return errors;
    }


    async updateBudgetStatus(budgetId) {
        try {
            const result = await updateBudgetStatus({ budgetId:budgetId });
            
        } catch (error) {
            console.error('Error Occured in updateBudgetStatus function- ', error);
        }
    }


    // async getInitiative() {
    //     try {
    //         console.log('recordId: ',this._recordId);
    //         this.initiative = await getInitiative({ initiativeId: this._recordId });
    //         console.log('ini here: ',this.initiative);
    //     } catch (error) {
    //         console.error('Error Occured in Get Initiative function- ', error);
    //     }
    // }

    // async updateInitiativeStatus() {
    //     try {
    //         await updateInitiative({ initiative:this.initiative });
    //     } catch (error) {
    //         console.error('Error Occured in updateBudgetStatus function- ', error);
    //     }
    // }

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