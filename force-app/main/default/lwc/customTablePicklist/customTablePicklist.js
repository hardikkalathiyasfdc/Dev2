import { LightningElement, api, track } from "lwc";
export default class CustomTablePicklist extends LightningElement {
  @api label;
  @api placeholder;
  @api options;
  @api value;
  @api context;
  @api field;
  @api none;
  @track isModalOpen = false;

  setHoverStyles() {
    let target = this.template.querySelector("button");
    target.style = "float: right; opacity: 0.5; margin-right: 5%";
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
    let val =
      event &&
      event.currentTarget &&
      event.currentTarget.dataset &&
      event.currentTarget.dataset.item;
    if (!val && val != "") {
      return;
    }
    this.value = val;
    this.dispatchEvent(
      new CustomEvent("picklistchanged", {
        composed: true,
        bubbles: true,
        cancelable: true,
        detail: {
          data: { context: this.context, value: this.value, field: this.label }
        }
      })
    );
    this.isModalOpen = false;
  }

  get hasNone() {
    return this.none == true;
  }
}