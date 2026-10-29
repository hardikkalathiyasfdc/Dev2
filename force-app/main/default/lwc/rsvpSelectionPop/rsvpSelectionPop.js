import { LightningElement, track, wire } from "lwc";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class rsvpSelectionPop extends LightningElement {
  value;
  rsvpValue;
  attendanceValue;
  options = [
    { label: "", value: "" },
    { label: "RSVP None", value: "None" },
    { label: "RSVP Pend", value: "Pend" },
    { label: "RSVP Yes", value: "Yes" },
    { label: "RSVP - Cocktails Only", value: "Yes - Cocktails Only" },
    { label: "RSVP - In Person", value: "Yes - In Person" },
    { label: "RSVP - Virtually", value: "Yes - Virtually" },
    { label: "RSVP No", value: "No" },
    { label: "Attended None", value: "AttendedNone" },
    { label: "Attended - Cocktails Only", value: "AttendedYes - Cocktails Only" },
    { label: "Attended - In Person", value: "AttendedYes - In Person" },
    { label: "Attended - Virtually", value: "AttendedYes - Virtually" },
    { label: "Did Not Attend", value: "AttendedDid Not Attend" },
    { label: "Did Not Attend - Cancelled RSVP", value: "AttendedDid Not Attend - Cancelled RSVP" },
    { label: "Waitlist 1", value: "Waitlist 1" },
    { label: "Waitlist 2", value: "Waitlist 2" }
  ];

  	rsvpAttendanceOptions = {
        'RSVP': [
            { label: 'Pend', value: 'Pend' },
            { label: 'Yes', value: 'Yes' },
			{ label: 'Yes - Cocktails Only', value: 'Yes - Cocktails Only' },
            { label: 'Yes - In Person', value: 'Yes - In Person' },
			{ label: 'Yes - Virtually', value: 'Yes - Virtually' },
            { label: 'No', value: 'No' },
			{ label: 'Waitlist 1', value: 'Waitlist 1' },
            { label: 'Waitlist 2', value: 'Waitlist 2' }
        ],
        'Attendance': [
            { label: 'Yes - Cocktails Only', value: 'Yes - Cocktails Only' },
			{ label: 'Yes - In Person', value: 'Yes - In Person' },
			{ label: 'Yes - Virtually', value: 'Yes - Virtually' },
			{ label: 'Did Not Attend', value: 'Did Not Attend' },
			{ label: 'Did Not Attend - Cancelled RSVP', value: 'Did Not Attend - Cancelled RSVP' }
        ]
    };

  connectedCallback() {}

  handleChange(event) {
    this.value = event.target.value;
  }

  
	handleSelectionChange(event) {
		this.rsvpValue = event.detail?.RSVP;
		this.attendanceValue = event.detail?.Attendance;
	}

  handleCancel() {
    this.dispatchEvent(new CustomEvent("cancel"));
  }

  handleSave() {
  if (!this.rsvpValue  && !this.attendanceValue) {
      this.showToast(
        "Warning",
        "Please select a status to coninue.",
        "warning"
      );
      return;
    }

    // Creates the event with the contact ID data.
    const selectedEvent = new CustomEvent("selected", { detail: {rsvpValue : this.rsvpValue,attendanceValue: this.attendanceValue} });

    // Dispatches the event.
    this.dispatchEvent(selectedEvent);
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }
}