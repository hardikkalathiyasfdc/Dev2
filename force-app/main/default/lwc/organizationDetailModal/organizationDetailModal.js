import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class OrganizationDetailModal extends LightningModal {
    @api orgDetails;

    connectedCallback() {
        console.log('##########OrganizationDetailModal-connectedCallback: ' + JSON.stringify(this.orgDetails));
    }

    handleOk() {
        this.close('ok');
    }

    handleCancel() {
        this.close('cancel');
    }
}