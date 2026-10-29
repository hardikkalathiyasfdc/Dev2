import { LightningElement, api, track } from "lwc";
import sendEmail from "@salesforce/apex/EventSummaryCmpController.sendEmail";
import getHighlightHours from "@salesforce/apex/EventSummaryCmpController.getHighlightHours";
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';

import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class EventSummaryCmp extends LightningElement {
  @api recordId;
  @track emailParams = {
    isSalutationChecked : false,
    isTitleChecked : false,
    isOrgChecked : false,
    isAddressChecked : false,
    isCityChecked : false,
    isStateChecked : false,
    isCountryChecked : false,
    isAddGuestOfChecked : false,
    isAddSourceChecked : false,
    isAKAChecked : false,
    isWaitlistChecked : false,
    isPreferredNameChecked : false,
    isPreferredLastnameChecked :false,
    fromDate:'',
    toDate:'',
    sourceNames:[]
  };

  currentDatetime = new Date();
  isListMemberSource = true;
  selectedListIds = [];
  listOptions = [];
  listValues = [];

  connectedCallback() {
    let d = new Date();
    this.emailParams.toDate = d.toISOString();
    this.getHighlightHours(d);
  }

  getHighlightHours(d) {
    getHighlightHours({})
      .then((result) => {
        if (result.error) {
          this.showNotification('Error', result.error, 'error','dismissable');
        } else {
          let highlightHours = result;
          let fromDate = d;
          fromDate.setHours(fromDate.getHours() - highlightHours);
          this.emailParams.fromDate = fromDate.toISOString();
        }
      })
      .catch((error) => {
        console.log(error);
        this.showNotification('Error',error, 'error','dismissable');
      });
  }

  closeEmail() {
    const selectedEvent = new CustomEvent("closeemail");
    this.dispatchEvent(selectedEvent);
  }

  checkboxChange (event) {
    let name = event.target.name;
    console.log('name :: '+name);    
    if(name === 'salutationSelection') this.emailParams.isSalutationChecked = event.target.checked;
    if(name === 'titleSelection') this.emailParams.isTitleChecked = event.target.checked;
    if(name === 'orgSelection') this.emailParams.isOrgChecked = event.target.checked;
    if(name === 'citySelection') this.emailParams.isCityChecked = event.target.checked;
    if(name === 'stateSelection') this.emailParams.isStateChecked = event.target.checked;
    if(name === 'countrySelection') this.emailParams.isCountryChecked = event.target.checked;
    if(name === 'addGuestOfSelection') this.emailParams.isAddGuestOfChecked = event.target.checked;
    if(name === 'addSourceSelection') this.emailParams.isAddSourceChecked = event.target.checked;
    if(name === 'akaSelection') this.emailParams.isAKAChecked = event.target.checked;
    if(name === 'waitlistSelection') this.emailParams.isWaitlistChecked = event.target.checked;
    if(name === 'preferredNameSelection') this.emailParams.isPreferredNameChecked = event.target.checked;
    if(name === 'isPreferredLastnameChecked') this.emailParams.isPreferredLastnameChecked = event.target.checked;
    console.log('emailParams :: '+JSON.stringify(this.emailParams));
  }

  dateChange (event) {
    let name = event.target.name;
    if(name === 'fromDate') this.emailParams.fromDate = event.target.value;
    if(name === 'toDate') this.emailParams.toDate = event.target.value;
  }

  isInputValid() {
    let fromDateValid = true;
    let toDateValid = true;

    let fromDate = this.template.querySelector(".fromDate");
    let toDate = this.template.querySelector(".toDate");

    if(Date.parse(fromDate.value) > this.currentDatetime.getTime()) {
      fromDate.setCustomValidity("Date cannot be in the future");
      fromDateValid = false;
    } else {
      fromDate.setCustomValidity("");
      fromDateValid = true;
    }

    if(Date.parse(toDate.value) > this.currentDatetime.getTime()) {
      toDate.setCustomValidity("Date cannot be in the future");
      toDateValid = false;
    } else {
      toDate.setCustomValidity("");
      toDateValid = true;
    }

    if(toDateValid && fromDateValid) {
      if(Date.parse(toDate.value) < Date.parse(fromDate.value)) {
        fromDate.setCustomValidity("From date cannot be greater than To Date");
        toDate.setCustomValidity("From date cannot be greater than To Date");
        fromDateValid = false;
        toDateValid = false;
      } else {
        console.log('7 :::::: ');
        fromDate.setCustomValidity("");
        toDate.setCustomValidity("");
        fromDateValid = true;
        toDateValid = true;
      }
    }

    fromDate.reportValidity();
    toDate.reportValidity();

    return fromDateValid && toDateValid;
  }

  sendEmail() {
    let isValid = this.isInputValid();
    if(!isValid) return;
    let self = this;
    sendEmail({
      listId: self.recordId,
      sendEmail: self.userEmail,
      params: JSON.stringify(this.emailParams)
    })
      .then((result) => {
        if (result.error) {
          this.showNotification('Error',result.error, 'error','dismissable');
        } else {
          if( result.restrictedContact && !hasPrivateNameFieldsAccess){
             let message = `\n\n You've encountered a problem with some of the records you selected ` +  result.restrictedContact+ ` records are not exporting). ` +
							`Please contact brmpartnerships@bloomberg.org for further assistance. \n\n`;
               self.showNotification('Warning', message, 'warning','sticky');
          }
          let msg = "A report will be generated and email sent to " + result.success;
            self.showNotification('Success', msg, 'success','dismissable');
        }
        self.closeEmail();
      })
      .catch((error) => {
        console.log(error);
        this.showNotification('Error',error, 'error','dismissable');
      });
  }

  showNotification(title, message, variant, mode) {
    const evt = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant,
			mode: mode,
    });
    this.dispatchEvent(evt);
  }

  getErrMsg(error) {
    if (!error) {
      return null;
    }
    let errMsg = null;
    if (Array.isArray(error)) {
      for (let i = 0; i < error.length; i++) {
        errMsg = this.getErrMsg(error[i]);
        if (errMsg) {
          return errMsg;
        }
      }
    } else if (typeof error === "object" && error !== null) {
      for (let key in error) {
        if (key == "message") {
          return error[key];
        } else {
          errMsg = this.getErrMsg(error[key]);
          if (errMsg) {
            return errMsg;
          }
        }
      }
    }
  }

  listSelected(event) {
    var selectedData = event.detail.arrItems;
    this.selectedLists = event.detail.arrItems;    
    this.selectedListIds = [];       
    let selectedOptions = [];
    this.listOptions = [];
    this.listValues = [];
    selectedData.forEach(selectedData =>{            
        this.selectedListIds.push(selectedData.value);
        //this.listOptions.push({label:selectedData.Id, value:selectedData.Id});
        this.listValues.push(selectedData.value);
        selectedOptions.push({label:selectedData.label, value:selectedData.value});
    });
    this.listOptions = selectedOptions;
    this.emailParams.sourceNames = this.listValues;
  }
}