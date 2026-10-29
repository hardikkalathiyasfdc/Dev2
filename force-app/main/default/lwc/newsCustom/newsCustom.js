import { LightningElement, api, wire } from "lwc";
import newsGrabber from "@salesforce/apex/NewsCustomController.newsGrabber";
//jlu apply update to use user's locale's settings
import getTimeZone from "@salesforce/apex/NewsCustomController.getTimeZone";

export default class NewsCustom extends LightningElement {
  @api recordId;

  @wire(newsGrabber, {
    recId: "$recordId"
  })
  wrappers;
  //jlu apply update to use user's locale's settings
  @wire(getTimeZone) timeZone;
  get userTimeZone() {
      console.log(this.timeZone);
    return this.timeZone.data;
  }
}