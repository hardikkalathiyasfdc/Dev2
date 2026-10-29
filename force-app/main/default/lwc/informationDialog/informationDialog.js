import { LightningElement, api } from 'lwc';

export default class InformationDialog extends LightningElement {
    @api message;
	@api header;

	handleOk(event) {
		this.dispatchEvent(new CustomEvent('cancel'));
	}
}