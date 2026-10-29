import { LightningElement, api, wire } from "lwc";
import getRecordTypes from "@salesforce/apex/CreateInteractionsController.getRecordTypes";
import getFieldsByRecordType from "@salesforce/apex/CreateInteractionsController.getFieldsByRecordType";
import autoCreateInteractions from "@salesforce/apex/CreateInteractionsController.autoCreateInteractions";
import conMembersCount from "@salesforce/apex/CreateInteractionsController.conMembersCount";
import getInaccessibleContactCount from "@salesforce/apex/CreateInteractionsController.getInaccessibleContactCount";

const EXCLUDED_RECORD_TYPES = ["Master", "Recent_Engagement"];
const SUPPORT_EMAIL = "brmpartnerships@bloomberg.org";
const STEP_RECORD_TYPE = "recordType";
const STEP_FIELDS = "fields";
const DML_ROW_LIMIT = 10000;

export default class CreateInteractionsModal extends LightningElement {
	@api recordId;
	@api contactIds;
	@api embedded = false;

	step = STEP_RECORD_TYPE;
	recordTypes = [];
	selectedRecordTypeId;
	interactionFields = [];
	showSpinner = false;
	formLoaded = false;
	errorMessage;
	listCount = 0;
	skippedCount = 0;

	connectedCallback() {
		if (!this.hasExplicitTargets) {
			this.loadListCount();
		}
		this.loadSkippedCount();
	}

	loadListCount() {
		conMembersCount({ campId: this.recordId })
			.then((count) => {
				this.listCount = count || 0;
				if (!this.listCount) {
					this.dispatchEvent(new CustomEvent("close", { detail: { reason: "noMembers" } }));
				}
			})
			.catch(() => {
				this.errorMessage = "The number of list members could not be read.";
			});
	}

	loadSkippedCount() {
		getInaccessibleContactCount({ campId: this.recordId, contactIds: this.contactIds })
			.then((count) => {
				this.skippedCount = count || 0;
			})
			.catch(() => {
				this.skippedCount = 0;
			});
	}

	@wire(getRecordTypes)
	wiredRecordTypes({ data, error }) {
		if (data) {
			let parsed;
			try {
				parsed = JSON.parse(data) || [];
			} catch (e) {
				this.errorMessage = "Interaction record types could not be read. Contact your administrator.";
				return;
			}
			this.recordTypes = parsed
				.filter(
					(rt) =>
						rt.active === true &&
						rt.available === true &&
						!EXCLUDED_RECORD_TYPES.includes(rt.developerName)
				)
				.map((rt) => ({
					label: rt.name,
					value: rt.recordTypeId,
					devName: rt.developerName
				}));
			if (!this.recordTypes.length) {
				this.errorMessage = "No Interaction record types are available to you.";
			}
		} else if (error) {
			this.errorMessage = "Interaction record types could not be loaded. Contact your administrator.";
		}
	}

	get showChrome() {
		return !this.embedded;
	}

	get modalClass() {
		return this.embedded ? "" : "slds-modal slds-fade-in-open slds-modal_large";
	}

	get containerClass() {
		return this.embedded ? "" : "slds-modal__container";
	}

	get contentClass() {
		return this.embedded ? "slds-is-relative slds-p-around_medium" : "slds-modal__content slds-p-around_medium";
	}

	get isRecordTypeStep() {
		return this.step === STEP_RECORD_TYPE;
	}

	get headerLabel() {
		return "Create Interactions";
	}

	get recordTypeOptions() {
		return this.recordTypes.map((rt) => ({ label: rt.label, value: rt.value }));
	}

	get hasExplicitTargets() {
		return !!(this.contactIds && this.contactIds.length);
	}

	get targetCount() {
		return this.hasExplicitTargets ? this.contactIds.length : this.listCount;
	}

	get targetSummary() {
		if (!this.hasExplicitTargets) {
			return "This creates one Interaction for every contact on this list.";
		}
		const noun = this.targetCount === 1 ? "contact" : "contacts";
		return `This creates one Interaction for each of the ${this.targetCount} ${noun} in your current view.`;
	}

	get showRestrictedWarning() {
		return this.skippedCount > 0;
	}

	get restrictedWarningMessage() {
		const noun = this.skippedCount === 1 ? "contact is" : "contacts are";
		return `You've encountered a problem with some of the records you selected (${this.skippedCount} ${noun} private), please contact ${SUPPORT_EMAIL} for further assistance.`;
	}

	get creatableCount() {
		return Math.max(this.targetCount - this.skippedCount, 0);
	}

	get isNextDisabled() {
		return !this.selectedRecordTypeId || this.showSpinner;
	}

	get isCreateDisabled() {
		return this.showSpinner || !this.formLoaded || this.targetCount > DML_ROW_LIMIT;
	}

	get createButtonLabel() {
		return this.creatableCount ? `Create ${this.creatableCount} Interactions` : "Create Interactions";
	}

	get createButtonTitle() {
		return this.hasExplicitTargets
			? `Creates one Interaction for each of the ${this.targetCount} contacts in your current view`
			: "Creates one Interaction for every contact on this list";
	}

	handleRecordTypeChange(event) {
		this.selectedRecordTypeId = event.detail.value;
		this.errorMessage = undefined;
	}

	handleKeyDown(event) {
		if (event.key === "Escape" && !this.showSpinner) {
			this.handleCancel();
		}
	}

	handleCancel() {
		this.dispatchEvent(new CustomEvent("close", { detail: { reason: "cancel" } }));
	}

	handleBack() {
		this.errorMessage = undefined;
		this.formLoaded = false;
		this.step = STEP_RECORD_TYPE;
	}

	handleNext() {
		this.errorMessage = undefined;
		if (this.targetCount > DML_ROW_LIMIT) {
			this.errorMessage = `This would create ${this.targetCount} records. Narrow the view to ${DML_ROW_LIMIT} or fewer and try again.`;
			return;
		}
		const selected = this.recordTypes.find((rt) => rt.value === this.selectedRecordTypeId);
		if (!selected) {
			this.errorMessage = "Select a record type to continue.";
			return;
		}
		this.showSpinner = true;
		getFieldsByRecordType({ devName: selected.devName })
			.then((result) => {
				let parsed = [];
				try {
					parsed = result ? JSON.parse(result) : [];
				} catch (e) {
					parsed = [];
				}
				this.interactionFields = parsed.map((item) => ({
					fieldPath: item.fieldPath,
					label: item.label,
					required: item.required === true
				}));
				if (!this.interactionFields.length) {
					this.errorMessage = `No field set named ${selected.devName} was found for Interaction__c.`;
					return;
				}
				this.step = STEP_FIELDS;
			})
			.catch(() => {
				this.errorMessage = "The fields for this record type could not be loaded.";
			})
			.finally(() => {
				this.showSpinner = false;
			});
	}

	handleCreateClick() {
		this.errorMessage = undefined;
		const inputs = [...this.template.querySelectorAll("lightning-input-field")];
		if (!inputs.length) {
			this.errorMessage = "The Interaction fields haven't finished loading.";
			return;
		}
		const invalid = inputs.filter((input) => !input.reportValidity());
		if (invalid.length) {
			return;
		}
		const fields = {};
		inputs.forEach((input) => {
			if (input.value !== undefined && input.value !== null && input.value !== "") {
				fields[input.fieldName] = input.value;
			}
		});
		this.createInteractions(fields);
	}

	handleFormLoad() {
		this.formLoaded = true;
	}

	handleFormError(event) {
		this.showSpinner = false;
		const detail = event && event.detail;
		this.errorMessage =
			(detail && (detail.message || detail.detail)) || "The Interaction details couldn't be validated.";
	}

	createInteractions(fields) {
		this.showSpinner = true;
		autoCreateInteractions({
			interactionIns: fields,
			campId: this.recordId,
			selectedCons: this.contactPayload,
			recordTypeId: this.selectedRecordTypeId
		})
			.then((count) => {
				this.showSpinner = false;
				this.dispatchEvent(
					new CustomEvent("success", { detail: { count: count || this.creatableCount } })
				);
			})
			.catch((error) => {
				this.showSpinner = false;
				this.errorMessage = this.getErrorMessage(error);
			});
	}

	get contactPayload() {
		if (!this.hasExplicitTargets) {
			return null;
		}
		const ids = [...new Set(this.contactIds.filter(Boolean))];
		return ids.length ? ids.map((id) => ({ Id: id })) : null;
	}

	getErrorMessage(error) {
		if (!error) {
			return "The Interactions couldn't be created.";
		}
		if (typeof error === "string") {
			return error;
		}
		const body = error.body;
		if (body) {
			if (Array.isArray(body)) {
				return body.map((e) => e.message).join(", ");
			}
			if (body.output) {
				const messages = [];
				(body.output.errors || []).forEach((e) => messages.push(e.message));
				Object.keys(body.output.fieldErrors || {}).forEach((fieldName) => {
					body.output.fieldErrors[fieldName].forEach((e) =>
						messages.push(`${fieldName}: ${e.message}`)
					);
				});
				if (messages.length) {
					return messages.join("\n");
				}
			}
			if (body.pageErrors && body.pageErrors.length) {
				return body.pageErrors.map((e) => e.message).join("\n");
			}
			if (body.message) {
				return body.message;
			}
		}
		return error.message || "The Interactions couldn't be created.";
	}
}