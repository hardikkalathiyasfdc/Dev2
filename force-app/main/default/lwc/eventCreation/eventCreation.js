import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from "lightning/uiRecordApi";
import { refreshApex } from "@salesforce/apex";
import getCurrentUser from "@salesforce/apex/EventMangementAuraCtrl.getCurrentUser";
import getCurrentTiemZone from "@salesforce/apex/EventMangementAuraCtrl.getCurrentTiemZone";
import getEventRecordTypeId from "@salesforce/apex/EventMangementAuraCtrl.getEventRecordTypeId";
import getOrgEmails from "@salesforce/apex/EventMangementAuraCtrl.getOrgEmails";
import createEvent from "@salesforce/apex/EventMangementAuraCtrl.createEvent";
import hasGalaDetailsAccess from '@salesforce/customPermission/Events_Events_Managed_Gala_Details';

const FIELDS = [
	"Account.BillingStreet",
	"Account.BillingStateCode",
	"Account.BillingPostalCode",
	"Account.BillingCity",
	"Account.BillingCountry",
	"Account.Name"
];

export default class eventCreation extends LightningElement {
	@track objectInfo;
	@track address = {};
	showSpinner = false;
	currentUser;
	timezoneKey;
	eventEndDate;
	selectedOrgId;
	eventType;
	locationName;
	pastEvent;
	invitationRequired = false;
	invitationEmails;
	invitationEmail;
	invitationDisplayName;
	currentEventType;
	defaultUser;
	allUserInfo;
	showOrgCreation = false;
	allOrgInfo;
	eventName;
	showExternal = false;
	isZkipsterEvent = false;
	showExternalCreation = false;
	externalId;
	orgEmails;
	selectedEmail;
	defaultStatus;
	recordTypeId;
	description;
	defaultSubject;

	get shallShowGalaDetails() {
		return hasGalaDetailsAccess;
	}

	@wire(getCurrentUser, { userId: "$defaultUser" })
	currentUserInfo(result) {
		this.allUserInfo = result;
		if(result.data) {
			let userData = JSON.parse(result.data);
			this.currentUser = userData[0].Id;
			if(userData[0].BP_Team__c === "Events") {
				this.currentEventType = "NY Event";
			} else if(userData[0].BP_Team__c && userData[0].BP_Team__c.includes("London")) {
				this.currentEventType = "London Event";
			}
		}
	}

	@wire(getCurrentTiemZone)
	timezoneInfo(result) {
		if(result.data) {
			this.timezoneKey = result.data;
		}
	}

	@wire(getEventRecordTypeId)
	wireEventRecordTypeId(result) {
		if(result.data) {
			this.recordTypeId = result.data;
		}
	}

	@wire(getOrgEmails)
	WireOrgEmails(result) {
		if(result.data) {
			let emails = JSON.parse(result.data);
			this.orgEmails = emails;
			let options = [];
			emails.forEach((x) => {
				let option = {};
				option.label = x.DisplayName + " - [" + x.Address + "]";
				option.value = x.Id;
				options.push(option);
			});

			this.invitationEmails = options;
		}
	}

	@wire(getRecord, { recordId: "$selectedOrgId", fields: FIELDS })
	wireOrgAddressInfo(result) {
		this.allOrgInfo = result;
		if(result.data) {
			let account = result.data;
			let address = {};
			address.BillingStreet = account.fields.BillingStreet.value;
			address.BillingCity = account.fields.BillingCity.value;
			address.BillingStateCode = account.fields.BillingStateCode.value;
			address.BillingPostalCode = account.fields.BillingPostalCode.value;
			address.BillingCountry = account.fields.BillingCountry.value;
			this.locationName = account.fields.Name.value;
			this.address = address;
		}
	}

	createNewVenue() {
		this.showOrgCreation = true;
	}

	handleCreationCancel() {
		this.showOrgCreation = false;
		this.showExternalCreation = false;
	}

	handleCreationSuccess(event) {
		this.selectedOrgId = event.detail;
		refreshApex(this.allOrgInfo);
		this.showOrgCreation = false;
	}

	handleExternalSuccess(event) {
		this.externalId = event.detail;
		this.showExternalCreation = false;
	}

	handleEventNameChange(event) {
		this.eventName = event.target.value;
		this.description = event.target.value;
	}

	handleProgramAreaTeamChange(event) {
		this.showExternal = event.target.value === "External";
	}

	createNewExternal() {
		this.showExternalCreation = true;
	}

	hanleLocationTypeChange(event) {
		let typeValue = event.target.value;
		let locationType = {};
		if(typeValue === "InPlace") {
			locationType.showLocation = true;
		} else if(typeValue === "Virtual") {
			locationType.showVirtualLink = true;
		} else if(typeValue === "Hybrid") {
			locationType.showVirtualLink = true;
			locationType.showLocation = true;
		} else {
			locationType.showVirtualLink = false;
			locationType.showLocation = false;
		}
		this.eventType = locationType;
	}

	handleLocationChange(event) {
		let orgId = event.target.value;
		this.selectedOrgId = orgId;
		if(orgId === "") {
			this.locationName = undefined;
			this.address = {};
		}
	}

	handleEventCoordinatorChange(event) {
		this.defaultUser = event.target.value;
		refreshApex(this.allUserInfo);
	}

	handleSuccess() {
		this.showSpinner = false;
		this.showToast("Success", "The Event is created successfully.", "success");
		this.dispatchEvent(new CustomEvent("cancel"));
	}

	handleInvitationEmailChange(event) {
		this.invitationEmail = event.target.value;

		let selectedOrg = this.orgEmails.find((x) => x.Id === this.invitationEmail);
		this.selectedEmail = selectedOrg.Address;
		this.invitationDisplayName = selectedOrg.DisplayName;
	}

	handleLocationNameChange(event) {
		this.locationName = event.target.value;
	}

	handleStartDateChange(event) {
		let startDate = event.target.value;
		this.eventEndDate = this.dateTimeUpdate(startDate, 1, 30);
		if(new Date(startDate) > new Date()) {
			this.defaultStatus = "Upcoming";
		} else {
			this.defaultStatus = "Complete";
		}
		let mo = this.dateToMD(new Date(startDate));
		this.defaultSubject =
			"Invitation for {0} to attend " +
			this.formatEventName(this.eventName) +
			", " +
			mo;
	}

	formatEventName(evtName) {
		if(!evtName || !evtName.length) {
			return evtName;
		}

		let checkThe = "the ";
		evtName = evtName.trim();
		if(evtName.length < checkThe.length) {
			return evtName;
		}
		let check = evtName.substring(0, checkThe.length);
		if(check.toLowerCase() == checkThe) {
			return evtName;
		}
		return "the " + evtName;
	}

	handleEndDateChange(event) {
		let endDate = event.target.value;
		if(new Date(endDate) > new Date()) {
			this.defaultStatus = "Upcoming";
		} else {
			this.defaultStatus = "Complete";
		}
	}

	handleZkipsterEventChange(event) {
		this.isZkipsterEvent = event.target.value;
		if(this.isZkipsterEvent === true) {
			this.invitationRequired = true;
		} else {
			this.invitationRequired = false;
		}
	}

	dateToMD(date) {
		let strArray = [
			"January",
			"February",
			"March",
			"April",
			"May",
			"June",
			"July",
			"August",
			"September",
			"October",
			"November",
			"December"
		];
		let d = date.getDate();
		let m = strArray[date.getMonth()];
		return m + " " + d;
	}

	handleSubmit(event) {
		event.preventDefault(); // stop the form from submitting
		this.showSpinner = true;
		const fields = event.detail.fields;
		let requiredFields = [];
		if(this.eventType.showLocation === true) {
			const allInputs = Array.from(
				this.template.querySelectorAll("lightning-input")
			).filter((element) => {
				if(element.required === true && element.value === "") {
					return element;
				} else if(element.value !== "") {
					if(element.label === "Location Name") {
						fields.LocationName__c = element.value;
					} else if(element.label === "Street") {
						fields.AddressLine__c = element.value;
					} else if(element.label === "City") {
						fields.City__c = element.value;
					} else if(element.label === "State/Province") {
						fields.State__c = element.value;
					} else if(element.label === "Country") {
						fields.Country__c = element.value;
					}
				}
			}).map((element) => element.label);
			requiredFields = [...allInputs];
			if(this.eventType.showVirtualLink === false) {
				fields.VirtualEventLink__c = "";
			}
		} else if(this.eventType.showVirtualLink === true) {
			if(this.eventType.showLocation === false) {
				fields.AddressLine__c = "";
				fields.City__c = "";
				fields.State__c = "";
				fields.Country__c = "";
				fields.LocationDetail__c = "";
				fields.LocationName__c = "";
			}
		}
		if(this.invitationRequired === true) {
			if(!this.invitationEmail) {
				requiredFields.push("Invitation From Email");
			} else {
				fields.InvitationEmailId__c = this.invitationEmail;
			}
		}
		if(requiredFields.length > 0) {
			this.showToast(
				"Error",
				"Please complete all required fields: " + requiredFields.join(", "),
				"error"
			);
			this.showSpinner = false;
			return;
		}
		fields.Name = this.eventName;
		fields.EventCoordinator__c = this.currentUser;
		fields.InvitationFromEmail__c = this.selectedEmail;
		fields.InvitaitonEmailFromName__c = this.invitationDisplayName;
		fields.NYEventorLondonEvent__c = this.currentEventType;
		fields.LocationName__c = this.locationName;
		let startDate = new Date(fields.Start_Date_Time__c);
		let defaultOffset = this.getTimeZoneOffset(startDate, this.timezoneKey);
		let newTimeZoneSet = this.getTimeZoneOffset(startDate, fields.TimeZone__c);
		fields.StartDateUtc__c = this.dateTimeUpdate(
			startDate,
			newTimeZoneSet - defaultOffset,
			0
		);
		fields.EndDateUtc__c = this.dateTimeUpdate(
			new Date(fields.End_Date_Time__c),
			newTimeZoneSet - defaultOffset,
			0
		);
		createEvent({
			newEvent: fields
		}).then(() => {
			this.handleSuccess();
		}).catch((errMsg) => {
			errMsg = this.getErrMsg(errMsg);
			errMsg = errMsg ? errMsg : "Error";
			this.showSpinner = false;
			this.showToast("Error", errMsg, "error");
		});
	}

	getErrMsg(error) {
		if(!error) {
			return null;
		}
		let errMsg = null;
		if(Array.isArray(error)) {
			for(let i = 0; i < error.length; i++) {
				errMsg = this.getErrMsg(error[i]);
				if(errMsg && errMsg.length) {
					return errMsg;
				}
			}
		} else if(typeof error === "object") {
			for(let key in error) {
				if(key == "message") {
					return error[key];
				} else {
					errMsg = this.getErrMsg(error[key]);
					if(errMsg && errMsg.length) {
						return errMsg;
					}
				}
			}
		}
		return errMsg;
	}

	dateTimeUpdate(date, hours, mins) {
		var startDatetime = new Date(date);
		startDatetime.setHours(startDatetime.getHours() + hours);
		startDatetime.setMinutes(startDatetime.getMinutes() + mins);
		return startDatetime.toISOString();
	}

	getTimeZoneOffset(date, timeZone) {
		let iso = date
			.toLocaleString("en-CA", { timeZone, hour12: false })
			.replace(", ", "T");
		iso += "." + date.getMilliseconds().toString().padStart(3, "0");
		// Lie to the Date object constructor that it's a UTC time.
		const lie = new Date(iso + "Z");
		return -(lie - date) / 60 / 1000 / 60;
	}

	showToast(title, message, variant) {
		const evt = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(evt);
	}

	handleCancel() {
		this.dispatchEvent(new CustomEvent("cancel"));
	}

	genericInputChange(event) {
		let address = {};
		address.street = event.target.street;
		address.city = event.target.city;
		address.province = event.target.province;
		address.country = event.target.country;
		address.postalCode = event.target.postalCode;
		this.address = address;
	}
}