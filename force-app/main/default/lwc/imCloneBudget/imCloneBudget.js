import {LightningElement, api, wire} from 'lwc';
import getUserAccessLevel from '@salesforce/apex/IMUtil.getUserAccessLevel';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CloseActionScreenEvent} from 'lightning/actions';
import {NavigationMixin} from 'lightning/navigation';
import cloneBudget from '@salesforce/apex/IMCloneBudgetController.cloneBudget';
import getTeamValue from '@salesforce/apex/IMCloneBudgetController.getTeamValue';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/IM_Budget__c.Name';
import { getErrorMessages, processErrorMessage } from 'c/utils';
const NOT_ALLOWED = 'You do not have the permission to perform this action.';
const CLONE_FAILED = 'Clone Failed:';

export default class ImCloneBudget extends NavigationMixin(LightningElement) {
//Variables
    _recordId;
    budgetName;
    teamId;
    hasEditAccess = false;
    initiativeId;
    clonedBudgetId;

    //Filter criteria for the record picker
    get filter() {
        return {
            criteria: [
                {
                    fieldPath: 'RecordType.Name',
                    operator: 'eq',
                    value: 'Budgeted Initiative',
                },
                {
                    fieldPath: 'Team__c',
                    operator: 'eq',
                    value: this.teamId ? this.teamId : null,
                },
            ],
            filterLogic: '1 AND 2',
        };
    }

    @api set recordId(value) {
        this._recordId = value;
        this.getUserAccess();
    }

    get recordId() {
        return this._recordId;
    }

    @wire(getRecord, {recordId: '$recordId', fields: [NAME_FIELD]})
    wiredBudget({error, data}) {
        if (data) {
            this.budgetName = getFieldValue(data, NAME_FIELD);
        } else if (error) {
            console.error('Error on Budget Name: ' + JSON.stringify(error));
        }
    }

    /*
    Description: Check if the user access level is read, then throw an error, if not read then set hasEditAccess as true
    Jira Story : IM-274
    */
    async getUserAccess() {
        const userAccess = await getUserAccessLevel({recordId: this._recordId});
        if (userAccess) {
            if (userAccess.MaxAccessLevel == 'Read') {
                this.showToast(CLONE_FAILED,  NOT_ALLOWED, 'error');






                this.handleCancel();
            } else {
                this.setTeamValue();
                this.hasEditAccess = true;
            }
        }
    }

    /*
    Description: set the team value to be used in filter for record picker
    Jira Story : IM-373
    */
    async setTeamValue() {
        this.teamId = await getTeamValue({budgetId: this._recordId});
    }

    /*
    Description: Fired on the change of initiative on the record picker from UI
    Jira Story : IM-48
    */
    handleRecordChange(event) {
        this.initiativeId = event.detail.recordId;
    }

    /*
    Description: handles the cancel event triggered from the UI
    Jira Story : IM-48
    */
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /*
    Description: handles the save operation, triggered from the UI.
    Jira Story : IM-48
    */
    handleSave(event) {
        if(!this.initiativeId) {
            this.showToast('Validation Error', 'Please select an Initiative before saving.', 'error');
            return;
        }
        if(!this.budgetName) {
            this.showToast('Validation Error', 'Please enter Budget Name before saving.', 'error');
            return;
        }
        cloneBudget({budgetId: this._recordId, initiativeId: this.initiativeId, newBudgetName: this.budgetName})
            .then((result) => {
                this.clonedBudgetId = result;
                this.showToast('Success',  'Budget cloned successfully.', 'success');
                this.navigateToBudgetRecord();
            })
            .catch((error) => {
                console.error('Error on Clone: ' + JSON.stringify(error));
                let errorMessages = getErrorMessages(error);
                let errorMessage = errorMessages[0];
                let validationErrorIndex = errorMessages[0].indexOf('No two budgets');
                if(validationErrorIndex != -1) {
                    errorMessage = errorMessage.substring(validationErrorIndex);
                    errorMessage = errorMessage.replace(': []', '');
                }
                this.showToast(CLONE_FAILED,  errorMessage, 'error');
            });
    }

    /*
	Description: Captures the name entered in the budget name input
	Jira Story: IM-491
	*/
	handleNameChange(event){
		this.budgetName = event.detail.value;
	}

    /*
    Description: handles the navigation of the record page to the newly created clone
    Jira Story : IM-48
    */
    navigateToBudgetRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.clonedBudgetId,
                actionName: 'view',
            },
        });
    }    

    /*
    Description: displays a toast on the record page
    */
	showToast(title, message, variant) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: title,
				message: message,
				variant: variant,
				mode: 'dismissable'
			})
		);
	}
}