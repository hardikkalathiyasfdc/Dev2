import { LightningElement, api, track } from "lwc";

import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class NewDonationCmp extends LightningElement {
  @api listId;
  @api showModal;
  @track activeSections = [
    "DonorInformation",
    "PointOfContact",
    "giftInformation",
    "listingTextAndLocation",
    "agreements",
    "notes"
  ];
  @track showLoader = false;
  selectedType;
  activeProspectSections = [
    "ProspectInformation",
    "notes"];
  closeNewDonation(event) {
    const selectedEvent = new CustomEvent("close");

    // Dispatches the event.
    this.dispatchEvent(selectedEvent);
  }

  handleSubmit() {
    this.showLoader = true;
  }

  handleNewDonationSuccess() {
    console.log("works");
    const selectedEvent = new CustomEvent("save");
    this.showLoader = false;
    this.dispatchEvent(selectedEvent);
  }

  handleError(e) {
    this.showLoader = false;
    let msg = e.detail.detail;
    const event = new ShowToastEvent({
      title: "Error",
      message: msg,
      variant: "error"
    });
    this.dispatchEvent(event);
  }

  get isDonation() {
    return this.selectedType == 'Donor' ? true : false;
  }

  get isProspect() {
    return this.selectedType == 'Prospect' ? true : false;
  }

  handleTypeChange(event) {
    this.selectedType = event.detail.value;
  }
}