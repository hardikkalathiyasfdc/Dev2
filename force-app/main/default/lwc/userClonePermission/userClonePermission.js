import { LightningElement, track, wire } from 'lwc';
import clonePermission from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.clonePermission';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import cloneProcessError from '@salesforce/label/c.LWC_UserClonePermissionCloneProcessErrMsg';
import copyToError from '@salesforce/label/c.LWC_UserClonePermissionCopyToErrMsg';
import copyFromError from '@salesforce/label/c.LWC_UserClonePermissionCopyFromErrMsg';
import successMsg from '@salesforce/label/c.LWC_UserClonePermissionCloneSuccessMsg';

export default class userClonePermission extends LightningElement {

	showSpinner = false;
	cloneDisabled = false;

	error;
	message;
	selectedToUsers;
	fromUser;

	handleCopyTo(event) {
		this.selectedToUsers = event.detail;
	}

	handleCopyFrom(event) {
		this.fromUser = event.detail;
	}

	handleClone() {
		this.cloneDisabled = true;
		if( this.selectedToUsers === undefined || this.selectedToUsers.length === 0 ) {
			this.error = copyToError;
			this.cloneDisabled = false;
			return;
		}

		if( this.fromUser === undefined ) {
			this.error = copyFromError;
			this.cloneDisabled = false;
			return;
		}

		this.showSpinner = true;

		let tmpSelectdIds = [];
		this.selectedToUsers.forEach(x => {
			tmpSelectdIds.push(x.Id);
		});

		this.clonePermision(tmpSelectdIds.join(','), this.fromUser[0].Id);
	}

	clonePermision(copyToUsers, copyFromUserId) {
		clonePermission({
			'copyToUsers': copyToUsers,
			'copyFromUserId': copyFromUserId
		})
		.then(result => {
			this.showSpinner = false;
			if( result === 'failure' ) {
				this.error = cloneProcessError;
				this.cloneDisabled = true;
			} else {
				this.message= successMsg;
				this.showNotification();
				this.handleCancel();
			}
		})
		.catch(error => {
			this.showSpinner = false;
			this.error = cloneProcessError;
			this.cloneDisabled = true;
		})
	}

	showNotification() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: this.message,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

	handleCancel() {
		this.dispatchEvent(new CustomEvent('cancel'));
	}
}