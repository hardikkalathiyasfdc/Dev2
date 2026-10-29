import { LightningElement, api } from 'lwc';
import LightningModal from "lightning/modal";
import getBgiveGrant from '@salesforce/apex/IMGrantViewController.getBgiveGrant';
import getPaymentsByRequestId from '@salesforce/apex/IMGrantViewController.getPaymentsByRequestId';
import unlinkGrant from '@salesforce/apex/IMGrantViewController.unlinkGrant';
import sendEmail from '@salesforce/apex/IMGrantViewController.sendEmail';
import hasUnlinkPermission from '@salesforce/customPermission/IM_Unlink_Grant';

const DECLINE_ERROR = 'The Bgive grant associated with this request is not declined. Please decline the Bgive grant before declining the request.';
const DELETE_ERROR = 'There are payments with non-zero amount associated with this request. Please ensure all payments are $0 in Bgive before deleting the request.';
const ERROR_MESSAGE = 'An error occurred while processing your request. Please contact Salesforce Support for help.';

export default class ImUnlinkGrant extends LightningModal {

    @api imGrant;
    @api budgetGrant;
    @api bgiveBaseUrl;
    bgiveGrantURL;
    selectedAction;
    bgiveGrant;
    payments;
    grantContigId;
    errorMessages = [];
    isSaveDisabled = false;
    isCancelDisabled = false;
    isActionDisabled = false;
    isError = false;
    showSpinner = false;

    get actionOptions() {
        if(hasUnlinkPermission){
            return [
                { value: "Decline", label: "Decline" },
                { value: "Delete", label: "Delete" },
                { value: "Unlink", label: "Unlink" },
            ];
        }else{
            return [
                { value: "Decline", label: "Decline" },
                { value: "Delete", label: "Delete" },
            ];
        }
    }

    get isDecline() {
        return this.selectedAction === 'Decline';
    }

    get isDelete() {
        return this.selectedAction === 'Delete';
    }

    connectedCallback() {
		if(this.imGrant?.Bgive_Id__c != null){
			this.bgiveGrantURL = this.bgiveBaseUrl + this.imGrant.Bgive_Id__c;
		}
        this.grantContigId = this.imGrant?.Bgive_Contig_Id__c;
	}

    handleActionChange(event) {
        this.selectedAction = event.detail.value;
        this.showSpinner = false;
        this.isSaveDisabled = false;
        this.isCancelDisabled = false;
    }

    handleSave() {
        this.showSpinner = true;
        this.isSaveDisabled = true;
        this.isCancelDisabled = true;
        this.validateActions();
    }

    handleClose() {
        this.close('close');
    }

    validateActions() {
        this.errorMessages = [];
        this.isError = false;

        if(this.selectedAction === undefined) {
            this.errorMessages.push('Please select an action before proceeding.');
            this.showSpinner = false;
            this.isError = true;
        } else if(this.selectedAction === 'Decline') {
            this.validateBgiveGrant(this.imGrant.Bgive_Contig_Id__c);
        } else if(this.selectedAction === 'Delete') {
            this.validatePayments(this.imGrant.Bgive_Id__c);
        } else if(this.selectedAction === 'Unlink') {
            this.unlinkGrant(this.selectedAction);
        }
    }

    async validateBgiveGrant(grantContigId) {
        getBgiveGrant({grantRequestContigId: grantContigId})
            .then((result) => {
                this.bgiveGrant = JSON.parse(JSON.stringify(result));
                if(this.bgiveGrant.state !== 'Declined') {
                    // Bgive grant is not declined, cannot proceed with decline of request
                    setTimeout(() => {
                        this.errorMessages.push(DECLINE_ERROR);
                        this.showSpinner = false;
                        this.isError = true;
                        this.isSaveDisabled = false;
                        this.isCancelDisabled = false;
                    }, 1000);
                }else{
                    // We are good to proceed with decline
                    setTimeout(() => {
                        this.unlinkGrant(this.selectedAction);
                    }, 1000);
                }
            })
            .catch((error) => {
                this.showSpinner = false;
                this.errorMessages.push(ERROR_MESSAGE);
                this.isError = true;
            });
    }

    async validatePayments(requestId) {
        getPaymentsByRequestId({requestId: requestId})
            .then((result) => {
                this.payments = JSON.parse(JSON.stringify(result));
                let hasNonZeroAmountPayment = this.checkPayments();
                if(hasNonZeroAmountPayment) {
                    setTimeout(() => {
                        // There are payments with non-zero amount, cannot proceed with delete of request
                        this.errorMessages.push(DELETE_ERROR);
                        this.showSpinner = false;
                        this.isError = true;
                        this.isSaveDisabled = false;
                        this.isCancelDisabled = false;
                    }, 1000);
                }else{
                    // We are good to proceed with delete
                    setTimeout(() => {
                        this.unlinkGrant(this.selectedAction);
                    }, 1000);
                }
            })
            .catch((error) => {
                this.showSpinner = false;
                this.errorMessages.push(ERROR_MESSAGE);
                this.isError = true;
            });
    }

    // Method to check if there are any payments with non-zero amount in Bgive for the given request
    checkPayments() {
        if(this.payments?.length > 0) {
            for(let payment of this.payments) {
                if((payment.amount_due_local && payment.amount_due_local != 0) || (payment.amount_paid_local && payment.amount_paid_local != 0)) {
                    return true;
                }
            }
        }
        return false;
    }

    // Method to unlink grants in case of zero amount scenario
	async unlinkGrant(actionType) {
		unlinkGrant({imGrant: this.imGrant, budgetGrant: this.budgetGrant, actionType: actionType})
			.then((result) => {
                if(actionType == 'Decline' || actionType == 'Unlink'){
                    this.showSpinner = false;
					this.close(this.selectedAction);
                } else if(actionType == 'Delete'){
                    setTimeout(() => {
                        this.sendEmail();
                    }, 1000);
                }
			})
			.catch((error) => {
                this.errorMessages.push(ERROR_MESSAGE);
                this.showSpinner = false;
                this.isError = true;
			});
	}

    // Method to send an email to Bgive Helpdesk to notify them of the request deletion in case of zero amount scenario
    async sendEmail() {
		sendEmail({ imGrant: this.imGrant, grantContigId: this.grantContigId, bgiveGrantURL: this.bgiveGrantURL })
			.then((result) => {
                this.showSpinner = false;
                this.close(this.selectedAction);
			})
			.catch((error) => {
                this.showSpinner = false;
                this.close('Email Failed');
			});
	}
}