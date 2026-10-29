import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class BlinkOrganizationQuickAction extends NavigationMixin(LightningElement) {

    @api recordId;

    connectedCallback() {
        setTimeout(() => {
            this.navigateToBlinkTab();
        }, 5);
    }

    navigateToBlinkTab() {
        const ts = Date.now();
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'B_Link'
            },
            state: {
                c__isFromOrg: true,
                c__recordId: this.recordId,
                c__refreshToken: ts
            }
        });
    }
}