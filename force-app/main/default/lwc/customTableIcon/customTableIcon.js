import { api, LightningElement } from "lwc";

export default class CustomTableIcon extends LightningElement {
  @api recordId;
  @api emailMap;
  hasSaveTheDate;
  hasInvitation;
  hasReminder;
  hasEmail;

  connectedCallback() {
    if (!this.emailMap) {
      return;
    }
    this.hasSaveTheDate = this.emailMap.savethedate.hasVal;
    this.hasInvitation = this.emailMap.invitation.hasVal;
    this.hasReminder = this.emailMap.reminder.hasVal;
    this.hasEmail = this.emailMap.email.hasVal;
  }
  onSaveTheDate() {
    this.onClick("savethedate");
  }

  onInvitation() {
    this.onClick("invitation");
  }

  onReminder() {
    this.onClick("reminder");
  }

  onEmail() {
    this.onClick("email");
  }

  onClick(myIcon) {
    this.dispatchEvent(
      new CustomEvent("iconclicked", {
        composed: true,
        bubbles: true,
        cancelable: true,
        detail: {
          data: { iconId: myIcon, recordId: this.recordId }
        }
      })
    );
  }

  getTitle(key) {
    if (!this.emailMap || !this.emailMap[key]) {
      return "";
    }
    let status = this.getStatus(key);
    if (!status.length) {
      return "";
    }
    let emailDate = this.getDateTime(key);
    if (!emailDate.length) {
      return status;
    }
    return status + " on " + emailDate;
  }

  getStatus(key) {
    return this.emailMap[key].status ? this.emailMap[key].status : "";
  }

  getDateTime(key) {
    if (
      !this.emailMap[key] ||
      !this.emailMap[key].sent ||
      !this.emailMap[key].sent.length
    ) {
      return "";
    }
    const d = new Date(this.emailMap[key].sent);
    return d.toLocaleDateString() + " " + d.toLocaleTimeString();
  }

  isError(check){
    const ERRMSG = 'Error:';
    if(!check || check.length <= ERRMSG.length){
      return false;
    }
    return check.substring(0, ERRMSG.length) == ERRMSG;
  }

  get saveTitle() {
    return this.getTitle("savethedate");
  }

  get invTitle() {
    return this.getTitle("invitation");
  }

  get reminderTitle() {
    return this.getTitle("reminder");
  }

  get emailTitle() {
    return this.getTitle("email");
  }

  get saveCss() {
    let check = this.getTitle("savethedate");
    if (check && check.length && !this.isError(check)) {
      return "slds-button sentBtn saveBtn";
    }
    return "slds-button defaultBtn saveBtn";
  }

  get invCss() {
    let check = this.getTitle("invitation");
    if (check && check.length && !this.isError(check)) {
      return "slds-button sentBtn invBtn";
    }
    return "slds-button defaultBtn invBtn";
  }

  get reminderCss() {
    let check = this.getTitle("reminder");
    if (check && check.length && !this.isError(check)) {
      return "slds-button sentBtn remindBtn";
    }
    return "slds-button defaultBtn remindBtn";
  }

  get emailCss() {
    let check = this.getTitle("email");
    if (check && check.length && !this.isError(check)) {
      return "slds-button sentBtn emailBtn";
    }
    return "slds-button defaultBtn emailBtn";
  }
}