import { LightningElement, api, track } from "lwc";

export default class CustomTableCheckbox extends LightningElement {
  @api value;
  @api type;
  @api context;
  @api field;
  @api editable;

  get isDisabled(){
    return !this.editable;
  }

  handleChange(event){
      let val = event.target.checked;
      console.log(val);
      console.log(this.field);
      this.dispatchEvent(
        new CustomEvent("picklistchanged", {
          composed: true,
          bubbles: true,
          cancelable: true,
          detail: {
            data: { context: this.context, value: val, field: this.field }
          }
        })
      );
  }
}