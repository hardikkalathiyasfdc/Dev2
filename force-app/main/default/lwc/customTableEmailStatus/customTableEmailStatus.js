import { api, LightningElement } from "lwc";

export default class CustomTableEmailStatus extends LightningElement {
    @api value;

    get isErrorStatus(){
        const check = 'ERROR:'
        if(!this.value || !this.value.length || this.value.length < check.length){
            return false;
        }
        let cmp = this.value.substring(0, check.length);
        cmp = cmp.toUpperCase();
        return cmp == check;
    }
}