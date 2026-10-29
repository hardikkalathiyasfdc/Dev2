import { LightningElement, track, wire, api} from 'lwc';

export default class deleteConfirmation extends LightningElement {
	@api message;
	@api cancelButtonLabel;
	@api confirmButtonLabel

	handleCancel(event) {
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	handleSave(event) {
		this.dispatchEvent(new CustomEvent('confirm'));
	}
}