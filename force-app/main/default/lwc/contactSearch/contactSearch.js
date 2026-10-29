import { LightningElement, api, track } from "lwc";
import searchContact from "@salesforce/apex/EventMangementAuraCtrl.searchContact";

export default class contactSearch extends LightningElement {
	@api multiple;
	@api sectionLabel;
	@api showSignificantOther = false;
	@api selectedContacts;
	@track availableContacts;
	curSearch;
	searchDebounce;
	isSearching = false;

	get showDropdown() {
		return this.isSearching || (Array.isArray(this.availableContacts) && this.availableContacts.length > 0);
	}

	@api
	clearSelection() {
		this.selectedContacts = undefined;
	}

	handleChange(event) {
		this.value = event.target.value;
	}

	handleSearchChange(event) {
		this.availableContacts = undefined;
		let searchString = event.target.value;
		searchString = searchString ? searchString.trim() : '';
		window.clearTimeout(this.searchDebounce);
		if(!searchString) {
			this.availableContacts = [];
			this.isSearching = false;
			this.onblur();
			return;
		}
		this.onfocus();
		this.searchDebounce = window.setTimeout(() => {
			this.searchContacts(searchString);
		}, 20);
	}

	searchContacts(searchString) {
		this.curSearch = this.formatSearch(searchString);
		this.isSearching = true;
		searchContact({
			cntSearch: this.curSearch
		}).then((result) => {
			if(this.curSearch != result.input) return;
			let availableContacts = result && result.results ? result.results : [];
			availableContacts.forEach((x) => {
				if(x.DoNotCall) x.warning = "Do Not Contact";
				if(x.Deceased__c) x.warning = "Deceased";
			});
			this.availableContacts = availableContacts;
			this.isSearching = false;
			this.error = undefined;
		}).catch((error) => {
			this.availableContacts = undefined;
			this.isSearching = false;
			this.error = error;
		});
	}

	formatSearch(input) {
		if(!input || input == "") return "";
		let myExp = "([\\'\\&\\|\\!\\(\\)\\{\\}\\[\\]^~\\:\\\\\\+\\-])";
		let re = new RegExp(myExp, "g");
		input = input.replaceAll(re, "\\$1");
		return input;
	}

	removeSelection(event) {
		let selectedRowId = event.currentTarget.id.split("-")[0];
		this.selectedContacts = this.selectedContacts.filter(
			(element) => element.Id !== selectedRowId
		);
		this.updateEvent();
	}

	getSelectedRows(event) {
		const selectedRowId = event.currentTarget?.dataset?.recordId;
  		if(!selectedRowId) return;
		const contacts = Array.isArray(this.availableContacts) ? this.availableContacts : [];
		const match = contacts.find((c) => c.Id === selectedRowId);
		if(!match) return;
		const selected = { Id: match.Id, Name: match.Name };
		if(this.selectedContacts === undefined) {
			this.selectedContacts = [];
		}
		if(this.multiple === "true") {
			let existed = this.selectedContacts.find((x) => x.Id === selected.Id);
			if(existed === undefined) {
				this.selectedContacts.push(selected);
			}
		} else {
			this.selectedContacts[0] = selected;
		}
		this.updateEvent();
		this.template.querySelector('[data-id="lookup-pill"]').classList.add("slds-is-close");
		this.template.querySelector('[data-id="lookup-pill"]').classList.remove("slds-is-open");
		this.template.querySelector('[data-id="searchRes"]').classList.add("slds-is-close");
		this.template.querySelector('[data-id="searchRes"]').classList.remove("slds-is-open");
		this.availableContacts = undefined;
		this.template.querySelectorAll("lightning-input").forEach((element) => {
			element.value = null;
		});
	}

	handleResultClose() {
		this.availableContacts = undefined;
	}

	onblur() {
		this.template.querySelector('[data-id="searchRes"]').classList.add("slds-is-close");
		this.template.querySelector('[data-id="searchRes"]').classList.remove("slds-is-open");
	}

	onfocus() {
		this.template.querySelector('[data-id="searchRes"]').classList.add("slds-is-open");
		this.template.querySelector('[data-id="searchRes"]').classList.remove("slds-is-close");
	}

	updateEvent() {
		const selectedEvent = new CustomEvent("update", {
			detail: this.selectedContacts
		});
		this.dispatchEvent(selectedEvent);
	}
}