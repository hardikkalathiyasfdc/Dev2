import { LightningElement, api, track } from "lwc";

export default class CustomTableDate extends LightningElement {
  @api object;
  @api field;
  @api value;
  @api type;
  @api context;
  @track isModalOpen = false;
  setHoverStyles() {
    let target = this.template.querySelector("button");
    target.style = "float: right; opacity: 0.5; margin-right: 5%; margin-left:80%; position:absolute;";
    let myDiv = this.template.querySelector("div");
    myDiv.style = "width:100%; background: white; height:100%; margin-left:5%;";
  }
  setHoverOutStyles() {
    let target = this.template.querySelector("button");
    target.style = "display:none;";
    let myDiv = this.template.querySelector("div");
    myDiv.style = "margin-left:5%;";
  }
  openModal() {
    this.isModalOpen = true;
  }
  closeModal() {
    this.isModalOpen = false;
  }
  handleChange(event) {
    let val = event && event.detail && event.detail.value;
    this.value = val;
    this.dispatchEvent(
      new CustomEvent("picklistchanged", {
        composed: true,
        bubbles: true,
        cancelable: true,
        detail: {
          data: { context: this.context, value: this.value, field: this.field }
        }
      })
    );
    this.isModalOpen = false;
  }

  get isDate() {
    return this.type && this.type == 'date' && this.value;
  }

  get isDateTime(){
    return this.type && this.type == 'datetime'&& this.value;
  }

  get isText() {
    return (!this.type || this.type.indexOf("date") < 0) && this.value;
  }
}