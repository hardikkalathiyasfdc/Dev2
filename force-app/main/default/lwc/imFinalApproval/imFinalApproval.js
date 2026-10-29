import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import NAME_FIELD from '@salesforce/schema/IM_Initiative__c.Name';
import TEAM_FIELD from '@salesforce/schema/IM_Initiative__c.Team__c';
import SEGMENT_FIELD from '@salesforce/schema/IM_Initiative__c.Segment__c';
import START_DATE_FIELD from '@salesforce/schema/IM_Initiative__c.Start_Date__c';
import END_DATE_FIELD from '@salesforce/schema/IM_Initiative__c.End_Date__c';
import TERM_FIELD from '@salesforce/schema/IM_Initiative__c.Term__c';
import CURRENT_BUDGET_FIELD from '@salesforce/schema/IM_Initiative__c.Current_Budget__c';
import PARENT_INITIATIVE_FIELD from '@salesforce/schema/IM_Initiative__c.Parent_Initiative__c';
import APPROVED_AMOUNT_FIELD from '@salesforce/schema/IM_Initiative__c.Approved_Amount__c';
import BUDGET_TERM_MONTHS_FIELD from '@salesforce/schema/IM_Initiative__c.Current_Budget__r.Budget_Term_months__c';
import APPROVED_DATE_FIELD from '@salesforce/schema/IM_Initiative__c.Approved_Date__c';
import ORIGINAL_APPROVED_DATE from '@salesforce/schema/IM_Initiative__c.Original_Approved_Date__c';
import APPROVED_FIELD from '@salesforce/schema/IM_Initiative__c.Approved__c';
import STATUS_FIELD from '@salesforce/schema/IM_Initiative__c.Status__c';
import APPROVER_FIELD from '@salesforce/schema/IM_Initiative__c.Approver__c';
import INCLUDE_IN_PROJECTIONS_FIELD from '@salesforce/schema/IM_Initiative__c.Include_in_Projections__c';
import FOCUS_AREA_FIELD from '@salesforce/schema/IM_Initiative__c.Focus_Area__c';
import getBudgetData from '@salesforce/apex/IMFinalApprovalController.getBudgetData';
import getTeamFocusArea from '@salesforce/apex/IMFinalApprovalController.getTeamFocusArea';
import getPendingApprovalBudgets from '@salesforce/apex/IMFinalApprovalController.getPendingApprovalBudgets';
import updateBudgetStatus from '@salesforce/apex/IMFinalApprovalController.updateBudgetStatus';

export default class ImFinalApproval extends NavigationMixin(LightningElement) {
    
    //Fields to show on the modal
    nameField = NAME_FIELD;
    teamField = TEAM_FIELD;
    segmentField = SEGMENT_FIELD;
    startDateField = START_DATE_FIELD;
    endDateField = END_DATE_FIELD;
    termField = TERM_FIELD;
    currentBudgetField = CURRENT_BUDGET_FIELD;
    parentInitiativeField = PARENT_INITIATIVE_FIELD;
    approvedAmountField = APPROVED_AMOUNT_FIELD;
    budgetTermMonthsField = BUDGET_TERM_MONTHS_FIELD;
    approvedDateField = APPROVED_DATE_FIELD;
    originalApprovedDateField = ORIGINAL_APPROVED_DATE;
    approvedField = APPROVED_FIELD;
    statusField = STATUS_FIELD;
    includeInProjectionsField = INCLUDE_IN_PROJECTIONS_FIELD;
    focusAreaField = FOCUS_AREA_FIELD;
    approverField = APPROVER_FIELD;
    
    //public variables
    @api recordId;
    @api objectApiName;
    
    //class variable
    approvalLabel = '';
    @track startDateFieldValue;
    @track endDateFieldValue;
    @track currentBudgetFieldValue;
    @track budgetTermMonthsFieldValue = 0;
    @track termValue = 0;
    @track approvedAmountValue = 0;
    @track hideSection = false;
    @track hideButton = false;
    @track focusAreaId = '';
    @track approvedDateValue;
    approverFieldValue;
    isBudgetedInitiative = false;
    isStartDateDisabled = false;
    currentBudgetOptions = [];
    showSpinner = false;
    nameFieldError = '';
    
    /**
    * Description : Called on load of final approval record edit form 
    * Jira        : IM-52 : Final Approval Tracking
    */
    handleLoad(event) {
        try {
            let recordData = event.detail.records[this.recordId].fields;
            //Check if the initiative record is Amendment.
            if(recordData.Initiative_Type__c?.value == 'Amendment'){
                this.approvalLabel = 'Amendment Approval';
                this.isStartDateDisabled = true;
            }else{
                this.approvalLabel = 'Final Approval';
                this.isBudgetedInitiative = true;
            }
            //Assign Start and End Date and Approved Date values
            this.approvedDateValue = new Date().toISOString();
            if (recordData.Start_Date__c && recordData.End_Date__c) {
                this.startDateFieldValue = recordData.Start_Date__c.value;
                this.endDateFieldValue = recordData.End_Date__c.value;
                if (this.startDateFieldValue && this.endDateFieldValue) {
                    this.startDateFieldValue.replaceAll('-', '/');
                    this.endDateFieldValue.replaceAll('-', '/');
                    this.calculateTerm(this.startDateFieldValue, this.endDateFieldValue)
                }
            }
            this.getPendingApprovalBudgets(this.recordId);
            //If current budget value is present, fetch the value from apex
            if (recordData.Current_Budget__c) {
                this.currentBudgetFieldValue = recordData.Current_Budget__c.value;
                this.getCurrentBudget(recordData.Current_Budget__c.value);
            }
        } catch (error) {
            console.error('Error Occured in handleLoad function- ', error);
        }
    }
    
    /**
    * Description : Called on Submit of final approval in modal footer 
    * Jira        : IM-52 : Final Approval Tracking
    */
    customHandleSubmit(){
       this.showSpinner = true;
       const isValid = this.validateBeforeSubmit();
       if(isValid){
           //this.showSpinner = false;
           this.template.querySelector('[data-id="customSave"]').click();
       } else {





























            this.showSpinner = false;
            return;
       }

    }
    
    /**
    * Description : Called on Submit of final approval record edit form 
    * Jira        : IM-52 : Final Approval Tracking
    */
    handleSubmit(event) {
        //Submit the form and LDS takes care of save.
        try {
            event.preventDefault();
            const fields = event.detail.fields;
            
            const currentBudgetField = this.template.querySelector('[data-id="currentBudgets"]');
            const isCurrentBudgetValid = currentBudgetField.reportValidity();
            
            if(isCurrentBudgetValid) {
            if (this.termValue != this.budgetTermMonthsFieldValue) {
                this.showErrorToast('Current Budget Term must match with Initiative Term');
            } else {
                fields.Approved__c = true;
                fields.Include_in_Projections__c = false;
                fields.Current_Budget__c = this.currentBudgetFieldValue;
                if(this.focusAreaId){
                    fields.Focus_Area__c = this.focusAreaId;
                }
                if(this.isBudgetedInitiative){
                    fields.Status__c = 'Ongoing';
                    //IM-371: Capture Original Approved Date for Budgeted Initiative
                    fields.Original_Approved_Date__c = fields.Approved_Date__c;
                    this.template.querySelector('lightning-record-edit-form').submit(fields);
                }else{
                    // IM-461: Update the Current Budget's Status to Approved before marking the Amendment as Completed
                    this.updateBudgetStatus(this.currentBudgetFieldValue, fields);
                }
            }

            }
        } catch (error) {
            this.showSpinner = false;
            console.error('Error Occured in handleSubmit function- ', error);
        }
    }
    
    /**
    * Description : Called on Cancel of final approval record edit form 
    * Jira        : IM-52 : Final Approval Tracking
    */
    handleCancel() {
        //Close Modal and navigate back to record detail page
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
    * Description : Called on error of final approval record edit form. 
    * Jira        : M-223 : Add spinner while saving final approval record.
    */
    handleError() {
        this.showSpinner = false;
    }
    
    /**
    * Description : Called on Success of final approval record edit form 
    * Jira        : IM-52 : Final Approval Tracking
    */
    handleSuccess() {
        this.showSpinner = false;
        //Show success Toast
        try {
            const successEvt = new ShowToastEvent({
                title: 'Approval:',
                message: 'Save Successful',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(successEvt);
            //Close Modal and navigate back to record detail page
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'IM_Initiative__c',
                    actionName: 'view'
                },
            });
        } catch (error) {
            this.showSpinner = false;
            console.error('Error Occured in handleSuccess function- ', error);
        }
    }
    
    /**
    * Description : Called on Team Value Change
    * Jira        : IM-52 : Final Approval Tracking
    */
    handleTeamChange(event) {
        //get focus area value based on the team value selected.
        if(event.target.value){
            this.getTeamFocusArea(event.target.value);
        }
    }
    
    /**
    * Description : Called when start Date is modified on final approval record edit form 
    * Jira        : IM-52 : Final Approval Tracking
    */
    handleStartDateChange(event) {
        try {
            this.startDateFieldValue = event.target.value;
            if (this.startDateFieldValue) {
                this.startDateFieldValue.replaceAll('-', '/');
                if (this.startDateFieldValue && this.endDateFieldValue) {
                    this.calculateTerm(this.startDateFieldValue, this.endDateFieldValue)
                }
            }
        } catch (error) {
            this.showSpinner = false;
            console.error('Error Occured in handleStartDateChange function- ', error);
        }
    }
    
    /**
    * Description : Called when end Date is modified on final approval record edit form 
    * Jira        : IM-52 : Final Approval Tracking 
    */
    handleEndDateChange(event) {
        this.endDateFieldValue = event.target.value;
        if (this.endDateFieldValue) {
            this.endDateFieldValue.replaceAll('-', '/');
            if (this.startDateFieldValue && this.endDateFieldValue) {
                this.calculateTerm(this.startDateFieldValue, this.endDateFieldValue);
            }
        }
    }
    
    /**
    * Description : Called to calculate the initiative Term to show on final approval record edit form
    * Jira        : IM-52 : Final Approval Tracking
    */
    calculateTerm(startDate, endDate) {
        try {
            startDate = this.parseDate(startDate);
            endDate = this.parseDate(endDate);

            if (endDate > startDate) {
                //Calculate the differences between the start and end dates
                var yearsDifference = endDate.getFullYear() - startDate.getFullYear();
                var monthsDifference = endDate.getMonth() - startDate.getMonth();
                var daysDifference = endDate.getDate() - startDate.getDate();
                var monthCorrection = 0;
                if (daysDifference > 0) {
                    monthCorrection = 1;
                }
                this.termValue = 1 * (yearsDifference * 12 + monthsDifference + monthCorrection);
                return true;
            } else {
                this.showErrorToast('End Date cannot be less than start Date');
                return false;
            }
        } catch (error) {
            this.showSpinner = false;
            return false;
            console.error('Error Occured in calculateTerm function- ', error);
        }
    }
    
    /**
    * Description : Parses a date string in yyyy-mm-dd format and returns a Date object.
    *               This method explicilty parses the date components to avoid timezone
    *               issues that can occur with Date.parse() when using yyyy-mm-dd format.
    * Jira        : IM-514
    */
    parseDate(dateString) {
        var parts = dateString.split('-');
        if(parts.length === 3) {
            return new Date(parts[0], parts[1] - 1, parts[2]);
        }
        // Fallback to Date.parse() for other formats.
        return new Date(Date.parse(dateString));
    }
    
    /**
    * Description : Called when current budget is modified on final approval record edit form 
    * Jira        : IM-52 : Final Approval Tracking
    */
    handleCurrentBudgetChange(event) {
        try {
            this.currentBudgetFieldValue = event.target.value;
            if (this.currentBudgetFieldValue) {
                this.getCurrentBudget(this.currentBudgetFieldValue);
            } else {
                this.budgetTermMonthsFieldValue = 0;
                this.approvedAmountValue = 0;
            }
        } catch (error) {
            this.showSpinner = false;
            console.error('Error Occured in handleCurrentBudgetChange function- ', error);
        }
    }
    
    /**
    * Description : Calls apex to get the budget amount and budget term values from selected budget
    * Jira        : IM-52 : Final Approval Tracking
    */
    async getCurrentBudget(budgetId) {
        try {
            let result = await getBudgetData({ budgetId: budgetId });
            if (result[0]) {
                //Check Budget Amount
                if (result[0].Budget_Amount__c != null) {
                    this.approvedAmountValue = result[0].Budget_Amount__c;
                } else {
                    this.showErrorToast('Selected Budget does not have Budget Amount value');
                }
                //Check Budget Term Months
                if (result[0].Budget_Term_months__c != null) {
                    this.budgetTermMonthsFieldValue = result[0].Budget_Term_months__c;
                } else {
                    this.showErrorToast('Selected Budget does not have Budget Term Months value');
                }
            }
        } catch (error) {
            this.showSpinner = false;
            console.error('Error Occured in getCurrentBudget function- ', error);
        }
    }
    
    /**
    * Description : Get the Focus Area Id from the team value
    * Jira        : IM-52 : Final Approval Tracking
    */
    async getTeamFocusArea(teamId) {
        try {
            let result = await getTeamFocusArea({ teamId: teamId });
            this.focusAreaId = result[0].Focus_Area__c;
        } catch (error) {
            console.error('Error Occured in getTeamFocusArea function- ', error);
        }
    }

    /**
    * Description : Get the Budgets with pending approval status based on initiative.
    * Jira        : IM-190
    */
    async getPendingApprovalBudgets(initiativeId) {
        try {
            let data = await getPendingApprovalBudgets({ initiativeId:initiativeId });
            let options = [];
            for (var key in data) {
                options.push({ label: data[key].Name, value: data[key].Id  });
            }
            this.currentBudgetOptions = options;
            if(options.length == 1) {
                this.currentBudgetFieldValue = options[0].value;
                this.getCurrentBudget(this.currentBudgetFieldValue);
            }
        } catch (error) {
            console.error('Error Occured in getPendingApprovalBudgets function- ', error);
        }
    }

    /**
    * Description : Update the Current Budget's Status to Approved
    * Jira        : IM-461
    */
    async updateBudgetStatus(budgetId, fields) {
        try {
            await updateBudgetStatus({ budgetId:budgetId });
            fields.Status__c = 'Completed';
            fields.Parent_Initiative__c = null;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        } catch (error) {
            console.error('Error Occured in updateBudgetStatus function- ', error);
        }
    }
    
    /*
    Description: Show Error Toast Message when called
    Jira Story : IM-52 : Final Approval Tracking
    */
    showErrorToast(displayMessage) {
        this.showSpinner = false;
        const errorEvt = new ShowToastEvent({
            title: 'Error Occured:',
            message: displayMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(errorEvt);
    }

    /*
    Runs all cliend-side validataions for the Final Approval modal and returns a boolean.
    This centralizes validation logic used by customHandleSubmit.
    @returns boolean true if all validations pass, false otherwise.
    */
    validateBeforeSubmit() {
        const approverField = this.template.querySelector('[data-id="approver"]');
        const isApproverValid = approverField.reportValidity();
        if(this.isBudgetedInitiative) {
            const nameField = this.template.querySelector('[data-id="name"]');
            let isNameValid = nameField.reportValidity();
            if(!isNameValid) {
                this.nameFieldError = '';
                return false;
            }
            isNameValid = this.validateNameField(nameField);
            const parentInitiativeField = this.template.querySelector('[data-id="parentInitiative"]');
            const isParentInitiativeValid = parentInitiativeField.reportValidity();
            const teamField = this.template.querySelector('[data-id="team"]');
            const isTeamValid = teamField.reportValidity();
            const segmentField = this.template.querySelector('[data-id="segment"]');
            const isSegmentValid = segmentField.reportValidity();

            if(!isNameValid || !isParentInitiativeValid || !isTeamValid || !isSegmentValid || !isApproverValid) {
                return false;
            }
        }

        const startDateField = this.template.querySelector('[data-id="startDate"]');
        const isStartDateValid = startDateField.reportValidity();
        const endDateField = this.template.querySelector('[data-id="endDate"]');
        const isEndDateValid = endDateField.reportValidity();
        const approvedDateField = this.template.querySelector('[data-id="approvedDate"]');
        const isApprovedDateValid = approvedDateField.reportValidity();
        const currentBudgetField = this.template.querySelector('[data-id="currentBudgets"]');
        const isCurrentBudgetValid = currentBudgetField.reportValidity();
        if(!isStartDateValid || !isEndDateValid || !isApprovedDateValid || !isCurrentBudgetValid || !isApproverValid) {
            return false;
        }
        if(!this.calculateTerm(this.startDateFieldValue, this.endDateFieldValue)) {
            return false;
        }
        if(!this.validateApprovedDateNotFuture(approvedDateField)) {
            return false;
        }
        return true;
    }

    /*
    Description: Validates the Name field with comprehensive checks.
    Jira Story : IM-382
    */
    validateNameField(nameField) {
        const nameValue = nameField.value;
        if(!nameValue || nameValue.trim().length == 0) {
            this.nameFieldError = 'Name cannot contain only spaces.';
            return false;
        }

        const trimmedValue = nameValue.trim();
        if(this.containsOnlySpecialCharacters(trimmedValue)) {
            this.nameFieldError = 'Name cannot contain only special characters.';
            return false;
        }
        if(this.containsOnlyNumbers(trimmedValue)) {
            this.nameFieldError = 'Name cannot contain only numbers.';
            return false;
        }
        if(this.containsOnlySpecialCharsAndNumbers(trimmedValue)) {
            this.nameFieldError = 'Name must contain at least some letters.';
            return false;
        }

        this.nameFieldError = '';
        return true;
    }

    /*
    Description: Checks if the approved date is future date.
    Jira Story : IM-528
    */
    validateApprovedDateNotFuture(approvedDateField) {
        const approvedDateValue = approvedDateField?.value;
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const approvedDate = this.parseDate(approvedDateValue);
        if(approvedDate > today) {
            this.showErrorToast('Approved date cannot be in future.');
            return false;
        }
        return true;
    }

    /*
    Description: Checks if the sting contains only special characters.
    Jira Story : IM-382
    */
    containsOnlySpecialCharacters(value) {
        const specialCharRegex = /^[^a-zA-Z0-9]+$/;
        return specialCharRegex.test(value);
    }

    /*
    Description: Checks if the sting contains only numbers.
    Jira Story : IM-382
    */
    containsOnlyNumbers(value) {
        const numberRegex = /^[0-9]+$/;
        return numberRegex.test(value);
    }

    /*
    Description: Checks if the sting contains only special character and numbers.
    Jira Story : IM-382
    */
    containsOnlySpecialCharsAndNumbers(value) {
        const specialCharAndNumberRegex = /^[^a-zA-Z\s]+$/;
        return specialCharAndNumberRegex.test(value);
    }
}