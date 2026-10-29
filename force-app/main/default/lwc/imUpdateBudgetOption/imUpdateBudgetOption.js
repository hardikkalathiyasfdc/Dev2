import {LightningElement, api} from 'lwc';
import getUserAccessLevel from '@salesforce/apex/IMUtil.getUserAccessLevel';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CloseActionScreenEvent} from 'lightning/actions';
import {notifyRecordUpdateAvailable} from 'lightning/uiRecordApi';
import {getErrorMessages, processErrorMessage} from 'c/utils';
import LightningConfirm from 'lightning/confirm';
import getBudgetRows from '@salesforce/apex/IMBudgetOptionsController.getBudgetRows';
import updateBudgetRows from '@salesforce/apex/IMBudgetOptionsController.updateBudgetRows';
import updateCheckboxes from '@salesforce/apex/IMUtil.updateCheckboxes';
import getBudget from '@salesforce/apex/IMBudgetOptionsController.getBudget';
import updateBudget from '@salesforce/apex/IMBudgetOptionsController.updateBudget';
import deleteBudgetChildRecords from '@salesforce/apex/IMBudgetOptionsController.deleteBudgetChildRecords';
const NOT_ALLOWED = 'You do not have the permission to perform this action.';
const AMENDMENT = 'Amendment';
export default class ImUpdateBudgetOption extends LightningElement {
	//Variables
	_recordId;
	_objectApiName;
	hasEditAccess = false;
	isWarning = false;
	isComponentChange = false;
	isSubComponentChange = false;
	isGeographyChange = false;
	isIdentifierChange = false;
	isPayeeChange = false;
	isWorkTypeChange = false;
	isDurationChange = false;
	isPartnerChange = false;
	isSubPartnerChange = false;
	isPartnerFundChange = false;
    errorMessage = '';
    budget;
    budgetCopy;
    newBudget;
    budgetRows;
	isPartnerFund = false;
	disablePartner = false;
	disableUniqueIdentifier = false;
	disablePayeeFiscalSponsor = false;
	disableSubPartnerType = false;
	disablePartnerFund = false;
	disableDurationRunRate = false;
	disableTypeOfWork = false;

	@api set recordId(value) {
		this._recordId = value;
		if (this._recordId != undefined) {
			this.getUserAccess();
		}
	}

	get recordId() {
		return this._recordId;
	}

	@api set objectApiName(value) {
		this._objectApiName = value;
	}

	get objectApiName() {
		return this._objectApiName;
	}

	/*
    Description: Check if the user access level is read, then throw an error, if not read then set hasEditAccess as true
    Jira Story : IM-274
    */
	async getUserAccess() {
		try {
			const userAccess = await getUserAccessLevel({recordId: this._recordId});
			if (userAccess) {
				if (userAccess.MaxAccessLevel == 'Read') {
					this.showToast('error', 'Update Budget Options Failed:', NOT_ALLOWED);






					this.handleClose();
				} else {
					this.hasEditAccess = true;
					this.getBudget();
					this.getBudgetRows();
				}
			}
		} catch (error) {
			this.showToast('error', 'Error Occured: ', error);
		}
	}

	/*
    Description: handles the close event triggered from the UI
    Jira Story : IM-105
    */
	handleClose() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	/*
    Description: handles the save operation, triggered from the UI.
    Jira Story : IM-105
    */
	handleSubmit(event) {
		try {
			event.preventDefault();
			const fields = event.detail.fields;
			if (!this.isWarning) {
				this.errorMessage = 'The data in columns ';
				this.budgetCopy.Budget_Categories__c = fields.Budget_Categories__c;
				this.budgetCopy.Partner_Partner_Role__c = fields.Partner_Partner_Role__c;
				this.budgetCopy.Unique_Identifier__c = fields.Unique_Identifier__c;
				this.budgetCopy.Payee_Fiscal_Sponsor__c = fields.Payee_Fiscal_Sponsor__c;
				this.budgetCopy.SubPartner_SubPartner_Type__c = fields.SubPartner_SubPartner_Type__c;
				this.budgetCopy.Duration_Run_Rate__c = fields.Duration_Run_Rate__c;
				this.budgetCopy.Type_of_Work__c = fields.Type_of_Work__c;
				this.budgetCopy.Partner_Fund__c = fields.Partner_Fund__c;
				this.updateCheckboxes();
			}
		} catch (error) {
			console.error('Error Occured in Handle Submit: ', error);
			this.showToast('error', 'Error Occured in Handle Submit: ', error);
		}
	}

	/*
    Description: handles the confirmation of the user on the UI for the updated budget options, then calls updateBudgetRows
    Jira Story : IM-105
    */
	async getConfirmation() {
		try {
			if (this.isWarning) {
				const result = await LightningConfirm.open({
					message: this.errorMessage,
					variant: 'header',
					label: 'Confirmation',
					theme: 'warning',
				});
				if (result) {
					this.errorMessage = '';
					this.isWarning = false;
					this.budgetRows.forEach((row) => {
						if (this.isComponentChange) {
							row.Component__c = null;
						}
						if (this.isSubComponentChange) {
							row.SubComponent__c = null;
						}
						if (this.isGeographyChange) {
							row.Geography__c = null;
						}
						if (this.isIdentifierChange) {
							row.Unique_Identifier__c = '';
						}
						if (this.isPayeeChange) {
							row.Payee_Fiscal_Sponsor__c = null;
						}
						if (this.isWorkTypeChange) {
							row.Type_of_Work__c = null;
						}
						if (this.isDurationChange) {
							row.Duration_months__c = null;
						}
						if (this.isPartnerChange) {
							row.Partner__c = null;
							row.Partner_Role__c = '';
						}
						if (this.isSubPartnerChange) {
							row.Sub_Partner__c = null;
							row.Sub_Partner_Type__c = '';
						}
						if (this.isPartnerFundChange) {
							row.Partner_Fund__c = null;
						}
					});
					const fieldValMap = {
						'Component__c': this.isComponentChange,
						'SubComponent__c': this.isSubComponentChange,
						'Geography__c': this.isGeographyChange,
						'Partner__c': this.isPartnerChange,
						'Partner_Role__c': this.isPartnerChange,
						'Unique_Identifier__c': this.isIdentifierChange,
						'Payee_Fiscal_Sponsor__c': this.isPayeeChange,
						'Sub_Partner__c': this.isSubPartnerChange,
						'Sub_Partner_Type__c': this.isSubPartnerChange,
						'Duration_months__c': this.isDurationChange,
						'Type_of_Work__c': this.isWorkTypeChange,
						'Partner_Fund__c': this.isPartnerFundChange,
					};

					this.updateBudgetRows(fieldValMap);
					notifyRecordUpdateAvailable([{recordId: this._recordId}]);
					this.handleClose();
				} else {
					this.resetVariables();
				}
			}
		} catch (error) {
			console.error('Error Occured in getConfirmation: ', error);
			this.showToast('error', 'Error Occured in getConfirmation: ', error);
		}
	}

	/*
    Description: get the budget data from apex by passing the recordId
    Jira Story : IM-105
    */
	async getBudget() {
        getBudget({budgetId: this._recordId})
            .then((result) => {
				this.budget = JSON.parse(JSON.stringify(result));
				this.budgetCopy = JSON.parse(JSON.stringify(result));
				this.isPartnerFund = this.budget && this.budget.Initiative__r.Partner_Funds__c ? true : false;
				// IM-333: Do not allow removing fields if the record is Approved or if its Amendment
				if (this.budget && this.budget.Initiative__r.Approved__c) {
					this.setFieldsEnabled(this.budget);
				} else if (this.budget && this.budget.Initiative__r.Initiative_Type__c === AMENDMENT) {
					this.getMainBudget(this.budget.Initiative__r.Amendment_of__r.Current_Budget__c);
				}
            })
            .catch((error) => {
                let errorMessages = getErrorMessages(error);
                this.showToast('error','Error:',errorMessages[0]); 
            });
			}

	/*
    Description: Method to get the main budget (i.e current budget on main initiative of amendment initiative)
    Jira Story : IM-333
    */
	async getMainBudget(budgetId) {
		try {
			const result = await getBudget({budgetId: budgetId});
			if (result) {
				let mainBudget = JSON.parse(JSON.stringify(result));
				this.setFieldsEnabled(mainBudget);
			}
		} catch (error) {
			this.showToast('error', 'Error Occured in getMainBudget: ', error);
		}
	}

	/*
    Description: Method to enable/disable budget options based on approval status or record type
    Jira Story : IM-333
    */
	setFieldsEnabled(budget) {
		let disabledBudgetOptions = budget.Disable_Budget_Options__c?.split(',') ?? [];
		this.disablePartner = disabledBudgetOptions.includes('Partner_Partner_Role__c');
		this.disableUniqueIdentifier = disabledBudgetOptions.includes('Unique_Identifier__c');
		this.disablePayeeFiscalSponsor = disabledBudgetOptions.includes('Payee_Fiscal_Sponsor__c');
		this.disableSubPartnerType = disabledBudgetOptions.includes('SubPartner_SubPartner_Type__c');
		this.disablePartnerFund = disabledBudgetOptions.includes('Partner_Fund__c');
		this.disableDurationRunRate = disabledBudgetOptions.includes('Duration_Run_Rate__c');
		this.disableTypeOfWork = disabledBudgetOptions.includes('Type_of_Work__c');
	}

	/*
    Description: get the budget rows from Apex by passing the budgetId
    Jira Story : IM-105
    */
	async getBudgetRows() {
        getBudgetRows({budgetId: this._recordId})
            .then((result) => {
				this.budgetRows = JSON.parse(JSON.stringify(result));
            })
            .catch((error) => {
                let errorMessages = getErrorMessages(error);
                this.showToast('error','Error:',errorMessages[0]); 
            });
			}

	/*
    Description: update the budget rows, if success showToast
    Jira Story : IM-105
    */
	async updateBudgetRows(fieldValMap) {
    	await updateBudgetRows({budget: this.budgetCopy, budgetRows: this.budgetRows, fieldValMap: fieldValMap})
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Budget Options updated successfully',
						variant: 'success',
                    })
                );
                this.deleteRecords(fieldValMap);
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch((error) => {
                let errorMessages = getErrorMessages(error);
                this.showToast('error','Error:',errorMessages[0]); 
            });
	}

	/*
    Description: update the budget record, if success showToast
    Jira Story : IM-105
    */
	async updateBudget() {
        updateBudget({budget: this.budgetCopy})
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Budget Options updated successfully',
						variant: 'success',
                    })
                );
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
			this.dispatchEvent(new CloseActionScreenEvent());
		})
            .catch((error) => {
			let errorMessages = getErrorMessages(error);
                this.showToast('error','Error:',processErrorMessage(errorMessages[0])); 
                this.isOptionsOpen = false;
		});
	}

	/*
    Description: handles the budget checkboxes save.
    Jira Story : IM-105
    */
	async updateCheckboxes() {
        updateCheckboxes({budgetRec: this.budgetCopy})
            .then((result) => {
				this.newBudget = JSON.parse(JSON.stringify(result));
				this.budgetCopy.Component__c = this.newBudget.Component__c;
				this.budgetCopy.SubComponent__c = this.newBudget.SubComponent__c;
				this.budgetCopy.Geography__c = this.newBudget.Geography__c;
				this.budgetCopy.Duration_months__c = this.newBudget.Duration_months__c;
				this.budgetCopy.Run_Rate__c = this.newBudget.Run_Rate__c;
				this.budgetCopy.Partner__c = this.newBudget.Partner__c;
				this.budgetCopy.Partner_Role__c = this.newBudget.Partner_Role__c;
				this.budgetCopy.Sub_Partner__c = this.newBudget.Sub_Partner__c;
				this.budgetCopy.Sub_Partner_Type__c = this.newBudget.Sub_Partner_Type__c;
				
				if (this.budgetRows.length > 0) {
					this.budgetRows.forEach((row) => {
						if (this.budget.Component__c && !this.newBudget.Component__c && row.Component__c && !this.isComponentChange) {
							this.errorMessage += 'Component, ';
							this.isComponentChange = true;
						}
						if (this.budget.SubComponent__c && !this.newBudget.SubComponent__c && row.SubComponent__c && !this.isSubComponentChange) {
							this.errorMessage += 'SubComponent, ';
							this.isSubComponentChange = true;
						}
						if (this.budget.Geography__c && !this.newBudget.Geography__c && row.Geography__c && !this.isGeographyChange) {
							this.errorMessage += 'Geography, ';
							this.isGeographyChange = true;
						}
						if (this.budget.Partner_Partner_Role__c && !this.newBudget.Partner_Partner_Role__c && row.Partner__c && !this.isPartnerChange) {
							this.errorMessage += 'Partner, Partner Role, ';
							this.isPartnerChange = true;
						}
						if (this.budget.Unique_Identifier__c && !this.newBudget.Unique_Identifier__c && row.Unique_Identifier__c && !this.isIdentifierChange) {
							this.errorMessage += 'Unique Identifier, ';
							this.isIdentifierChange = true;
						}
						if (
							this.budget.Payee_Fiscal_Sponsor__c &&
							!this.newBudget.Payee_Fiscal_Sponsor__c &&
							row.Payee_Fiscal_Sponsor__c &&
							!this.isPayeeChange
						) {
							this.errorMessage += 'Payee Fiscal Sponsor, ';
							this.isPayeeChange = true;
						}
						if (
							this.budget.SubPartner_SubPartner_Type__c &&
							!this.newBudget.SubPartner_SubPartner_Type__c &&
							row.Sub_Partner__c &&
							!this.isSubPartnerChange
						) {
							this.errorMessage += 'SubPartner, SubPartner Type, ';
							this.isSubPartnerChange = true;
						}
						if (this.budget.Duration_Run_Rate__c && !this.newBudget.Duration_Run_Rate__c && row.Duration_months__c && !this.isDurationChange) {
							this.errorMessage += 'Duration, Run rate, ';
							this.isDurationChange = true;
						}
						if (this.budget.Type_of_Work__c && !this.newBudget.Type_of_Work__c && row.Type_of_Work__c && !this.isWorkTypeChange) {
							this.errorMessage += 'Type of Work, ';
							this.isWorkTypeChange = true;
						}
						if (this.budget.Partner_Fund__c && !this.newBudget.Partner_Fund__c && row.Partner_Fund__c && !this.isPartnerFundChange) {
							this.errorMessage += 'Partner Fund, ';
							this.isPartnerFundChange = true;
						}
					});
					if (this.errorMessage.includes(',')) {
						this.errorMessage = this.errorMessage.substring(0, this.errorMessage.lastIndexOf(','));
						this.errorMessage += ' will be lost if these boxes are unchecked.';
						this.isWarning = true;
						this.getConfirmation();
					} else {
						this.updateBudget();
					}
				} else {
					this.updateBudget();
				}
            })
            .catch((error) => {
                let errorMessages = getErrorMessages(error);
                this.showToast('error','Error:',errorMessages[0]); 
			});
		
	}

	/*
    Description: Delete child records on column removal.
    Jira Story : IM-374
    */
	async deleteRecords(fieldValMap) {
		try {
			await deleteBudgetChildRecords({budget: this.budgetCopy, fieldValMap: fieldValMap});
		} catch (error) {
			console.error('Error Occured in deleteRecords: ', error);
			this.showToast('error', 'Error Occured in deleteRecords: ', error);
		}

	}

	/*
    Description: Reset all variable related to field changes.
    Jira Story : IM-374
    */
	resetVariables() {
		this.isWarning = false;
		this.isComponentChange = false;
		this.isSubComponentChange = false;
		this.isGeographyChange = false;
		this.isIdentifierChange = false;
		this.isPayeeChange = false;
		this.isWorkTypeChange = false;
		this.isDurationChange = false;
		this.isPartnerChange = false;
		this.isSubPartnerChange = false;
		this.isPartnerFundChange = false;
	}

	/*
    Description: fires a toast message with the variable values that are passed
    Jira Story : IM-105
    */
	showToast(variant, title, displayMessage) {
		const successEvt = new ShowToastEvent({
			title: title,
			message: displayMessage,
			variant: variant,
			mode: 'dismissable',
		});
		this.dispatchEvent(successEvt);
	}
}