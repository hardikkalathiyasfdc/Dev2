import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import syncInitiative from '@salesforce/apex/IMSyncInitiativeController.syncInitiative';

export default class ImSyncInitiative extends LightningElement {
    @api recordId;

    @api invoke() {

        syncInitiative({initiativeId : this.recordId})
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Initiative sync job started successfully.',
                        variant: 'success',
                    }),
                );
            })
            .catch((error) => {
                console.log('Error: ' + JSON.stringify(error));
            });

    }
}