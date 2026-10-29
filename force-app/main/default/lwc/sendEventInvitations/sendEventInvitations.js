import { api, LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendEmail from "@salesforce/apex/SendEventInvitationsController.sendEmail";

export default class SendEventInvitations extends LightningElement {
  @api recordIds;
  @api emailOptions;
  @api emailType;
  @api total;
  @api selectedMembers;
  columns = [
    { label: "First Name", fieldName: "UB_FirstName__c", type: "text" },
    { label: "Last Name", fieldName: "UB_LastName__c", type: "text" },
    { label: "Email", fieldName: "Guest_Email__c", type: "text" },
    { label: "Warning", fieldName: "warning", type: "text" }
  ];
  isLoading = false;
  errorsList = [];
  successNum = 0;
  warningMap = {
    savethedate: "saveWarning",
    invitation: "inviteWarning",
    reminder: "reminderWarning",
    email: "emailWarning"
  };
  onClose() {
    this.dispatchEvent(new CustomEvent("closeinvitation"));
  }
  handleEmailChange(event) {
    this.emailType = event.detail.value;
    console.log(this.emailType);
    if (!this.selectedMembers || !this.selectedMembers.length) {
      return;
    }
    let newList = [];

    for (let i = 0; i < this.selectedMembers.length; i++) {
      let item = this.selectedMembers[i];
      let typeWarn = item[this.warningMap[this.emailType]];
      typeWarn = !typeWarn ? "" : typeWarn;
      console.log(item);
      let newItem = {};
      newItem = Object.assign(newItem, item);
      newItem.warning = item.generalWarning + typeWarn;
      console.log(newItem.warning);
      newList.push(newItem);
    }
    newList = newList.sort((a, b) => {
      return a.warning && a.warning.length ? -1 : 1;
    });
    this.selectedMembers = JSON.parse(JSON.stringify(newList));
  }
  handleSend() {
    let self = this;
    this.errorsList = [];
    this.successNum = 0;
    if (!this.emailType || !this.emailType.length) {
      self.showErrorToast("You must select an email type to send.");
      return;
    }

    this.isLoading = true;
    sendEmail({
      memIds: self.recordIds,
      emailType: self.emailType
    })
      .then((errList) => {
        self.isLoading = false;
        if (!errList || !errList.length) {
          self.showSuccessToast();
          self.onClose();
          return;
        }
        self.errorsList = errList;
        self.successNum = self.recordIds.length - errList.length;
      })
      .catch((error) => {
        self.isLoading = false;
        console.log(error);
        self.showErrorToast(error);
      });
  }
  get hasSelected() {
    return this.recordIds && this.recordIds.length && !this.errorsList.length;
  }

  get hasNoneSelected() {
    return !this.recordIds || !this.recordIds.length;
  }
  showErrorToast(msg) {
    msg = this.getErrMsg(msg);
    const evt = new ShowToastEvent({
      title: "Error",
      message: msg,
      variant: "error",
	  mode: "sticky"
    });
    this.dispatchEvent(evt);
  }
  showSuccessToast() {
    const evt = new ShowToastEvent({
      title: "Success",
      message: this.recordIds.length + " email invitations sent.",
      variant: "success"
    });
    this.dispatchEvent(evt);
  }

  getErrMsg(error) {
    console.log(error);
    if (!error) {
      return null;
    }
    let errMsg = null;
    if (Array.isArray(error)) {
      for (let i = 0; i < error.length; i++) {
        errMsg = this.getErrMsg(error[i]);
        if (errMsg && errMsg.length) {
          return errMsg;
        }
      }
    } else if (typeof error === "object") {
      for (let key in error) {
        if (key == "message") {
          return error[key];
        } else {
          errMsg = this.getErrMsg(error[key]);
          if (errMsg &&  errMsg.length) {
            return errMsg;
          }
        }
      }
    }

    return errMsg;
  }
}