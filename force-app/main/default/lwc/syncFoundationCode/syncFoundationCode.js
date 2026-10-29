import { LightningElement,api,wire} from 'lwc';
import sync from '@salesforce/apex/ManageFoundationCodesCntrl.syncCode';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';

export default class SyncFoundationCode extends LightningElement {

    @wire(CurrentPageReference) currentPageReference;

    @api recordId;

    @api invoke() {
        var recId = this.currentPageReference?.attributes?.recordId;
       
        sync({ recordId : recId })
        .then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success",
                  message: "Foundation Code is sync request submitted successfully.",
                  variant: "success",
                }),
              );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: "Error while syncing code."+error.body.message,
                  variant: "error",
                }),
              );
        });
    }


}