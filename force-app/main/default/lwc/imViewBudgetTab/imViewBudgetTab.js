import {LightningElement, api} from 'lwc';

export default class ImViewBudgetTab extends LightningElement {
	@api columnOptions;
	col1;
	col2;
	col3;
	col4;

	tabName;

	handleColumn1Change(event) {
		this.col1 = event.detail.value;
		let col1 = this.template.querySelector('.col1');
		if (this.col1 === 'None') {
			col1.setCustomValidity('Column 1 cannot be None. Please select another value');
			col1.reportValidity();
		} else {
			col1.setCustomValidity('');
			col1.reportValidity();
		}
		this.dispatchCustomEvent('colchange', 'Col1', event.detail.value);
	}

	handleColumn2Change(event) {
		this.col2 = event.detail.value;
	}

	handleColumn3Change(event) {
		this.col3 = event.detail.value;
	}

	handleColumn4Change(event) {
		this.col4 = event.detail.value;
	}

	handleTabNameChange(event) {
		this.tabName = event.detail.value;
		this.dispatchCustomEvent('tabnamechange', 'tabName', event.detail.value);
	}

	@api getTabName() {
		return this.tabName;
	}

	@api getSelectedColumns() {
		return {
			'tabName': this.tabName,
			'col1': this.col1,
			'col2': this.col2,
			'col3': this.col3,
			'col4': this.col4,
		};
	}

	dispatchCustomEvent(eventName, key, value) {
		this.dispatchEvent(
			new CustomEvent(eventName, {
				composed: true,
				bubbles: true,
				cancelable: true,
				detail: {
					data: {key: key, value: value},
				},
			})
		);
	}
}