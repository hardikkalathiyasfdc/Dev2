import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import LWCDatatablePicklist from '@salesforce/resourceUrl/LWCDatatablePicklist';
import { getRecord } from "lightning/uiRecordApi";
 import NAME_FIELD from "@salesforce/schema/Contact.Name";
import ID_FIELD from "@salesforce/schema/Contact.Id";

const fields = [NAME_FIELD, ID_FIELD];

export default class LookupColumn extends LightningElement {
    @api value;
    @api fieldName;
    @api object;
    @api context;
    @api name;
    @api fields;
    @api target;
    @track showLookup = false;
    @track record;
 
    //get the sobject record info with fields to show as url navigation text
    @wire(getRecord, { recordId: '$value', fields })
    wiredContacts({ error, data }) {
        if (data) {
          debugger;
            this.record = data;
           
        } else if (error) {
            this.error = error;
        }
    }
 
 
   //label of formatted url
    get lookupName() {
    //  debugger;
       
        return (this.value && this.record) && this.record.fields?  this.record.fields['Name'].value : '';
    }
 
    //value of formatted url
    get lookupValue() {
      // debugger;
        return (this.value  && this.record && this.record.fields && this.record.fields['Id'].value) ? '/' + this.value : '';
    }
 
    renderedCallback() {
        Promise.all([
            loadStyle(this, LWCDatatablePicklist),
        ]).then(() => { });
 
        let container = this.template.querySelector('div.container');
        container?.focus();
 
        window.addEventListener('click', (evt) => {
           if(container == undefined){
               this.showLookup = false;
           }
        });
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
          data: { context: this.context, value: this.value, field: this.fieldName }
        }
      })
    );
  }
    handleClick(event) {
        //wait to close all other lookup edit 
        setTimeout(() => {
            this.showLookup = true;
        }, 100);
    }
}