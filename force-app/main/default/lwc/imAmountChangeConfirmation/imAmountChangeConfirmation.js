import { LightningElement, api } from 'lwc';
import LightningModal from "lightning/modal";

export default class ImAmountChangeConfirmation extends LightningModal {
    @api budgetGrant;
    localAmount;

    handleSave() {
        if(this.localAmount == undefined || this.localAmount == ''){
            const budgetAmountLocal = this.template.querySelector('[data-id="BudgetAmountLocal"]');
            budgetAmountLocal.reportValidity();
        }else{
            this.close(this.localAmount);
        }
    }

    handleClose() {
        this.close();
    }

    handleLocalAmountChange(event){
        this.localAmount = event.target.value;
    }
}