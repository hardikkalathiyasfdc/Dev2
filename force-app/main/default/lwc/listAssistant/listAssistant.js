import { api, LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import updateAssistants from "@salesforce/apex/EventMangementAuraCtrl.updateAssistants";

export default class ListAssistant extends LightningElement {
  options = [
    { label: "", value: "" },
    { label: "Yes", value: "true" },
    { label: "No", value: "false" }
  ];
  value = "";
  updateChecked = false;
  @api recordIds;
  @api total;
  isLoading = false;
  handleOptionsChange(event) {
    this.value = event.detail.value;
  }
  handleUpdateAssistant() {}
  handleUpdateChange(event) {
    this.updateChecked = event.detail.checked;
    console.log(this.updateChecked);
  }
  handleUpdate() {
      console.log('handleupdate');
    if (this.value == "" && !this.updateChecked) {
      return this.showErrorToast(
        "Please either select a cc to assistant value to update or select update assistants information."
      );
    }
    this.isLoading = true;
    let self = this;
    updateAssistants({
      memIdList: self.recordIds,
      ccVal: self.value,
      isUpdate: self.updateChecked
    })
      .then(() => {
        self.isLoading = false;
        self.dispatchEvent(new CustomEvent("closeassistantrefresh"));
        self.showSuccessToast("Assistants updated.");
      })
      .catch((error) => {
        console.log(error);
        self.isLoading = false;
        self.showErrorToast(error);
      });
  }
  onClose() {
    this.dispatchEvent(new CustomEvent("closeassistant"));
  }

  showSuccessToast(msg) {
    const evt = new ShowToastEvent({
      title: "Success",
      message: msg,
      variant: "success"
    });
    this.dispatchEvent(evt);
  }

  showErrorToast(msg) {
    msg = this.getErrMsg(msg);
    const evt = new ShowToastEvent({
      title: "Error",
      message: msg,
      variant: "error"
    });
    this.dispatchEvent(evt);
  }

  getErrMsg(error) {
    if (!error) {
      return null;
    }
    let errMsg = null;
    if (Array.isArray(error)) {
      for (let i = 0; i < error.length; i++) {
        errMsg = this.getErrMsg(error[i]);
        if (errMsg) {
          return errMsg;
        }
      }
    } else if (typeof error === "object" && error !== null) {
      for (let key in error) {
        if (key == "message") {
          return error[key];
        } else {
          errMsg = this.getErrMsg(error[key]);
          if (errMsg) {
            return errMsg;
          }
        }
      }
    } else {
      return error;
    }
    return errMsg;
  }
}