import { LightningElement, api, track } from "lwc";

export default class CustomTableHtml extends LightningElement {
    @api value;
    
    renderedCallback() {
        if(this.value){
            this.template.querySelector('div').innerHTML = this.value;
        }
    }
}