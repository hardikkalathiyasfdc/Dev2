import { LightningElement, api, track } from "lwc";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import myStyle from "@salesforce/resourceUrl/CustomTableLookupCss";
export default class CustomTableLookup extends LightningElement {
  @api object;
  @api field;
  @api value;
  @api context;
  @api hide;
  @track newValue = "";
  @track isModalOpen = false;

  renderedCallback() {
    Promise.all([loadStyle(this, myStyle)]);
  }
  setHoverStyles() {
    let target = this.template.querySelector("button");
    target.style = "float: right; opacity: 0.5; margin-right: 5%";
    let myDiv = this.template.querySelector("div");
    myDiv.style =
      "width:100%; background: white; height:100%; margin-left:5%;margin-right:5%;";
  }
  setHoverOutStyles() {
    let target = this.template.querySelector("button");
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
    debugger;
    console.log(event);
    this.value = event.detail.value[0];
    this.value = !this.value ? '' : this.value;
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
  }
  get hasObject() {
    return !this.hide && this.object != null && this.object.length;
  }
}