import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class BlinkContactQuickAction extends NavigationMixin(LightningElement) {

    @api recordId;

    connectedCallback() {
        setTimeout(() => {
            this.navigateToBlinkTab();
        }, 5);
    }

    navigateToBlinkTab() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'B_Link'
            },
            state: {
                c__isFromContact: true,
                c__recordId: this.recordId
            }
        });
    }
}