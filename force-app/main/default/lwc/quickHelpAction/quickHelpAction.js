import { LightningElement, wire } from 'lwc';
import getReplyToEmail from '@salesforce/apex/EmailUtility.getReplyToEmail';

export default class QuickHelpAction extends LightningElement {
    brmHelpEmailAdress;

    @wire(getReplyToEmail) 
    getReplyToEmail(result) {
        const { data, error } = result;
        if(data) {
            this.brmHelpEmailAdress = data;
        } else if(error) {
            console.log('Error fetching record type:', error);
        }
    }
    
    handleEmailClick() {
        window.open('mailto:' + this.brmHelpEmailAdress + '?subject=Salesforce Question', '_blank');
    }
}