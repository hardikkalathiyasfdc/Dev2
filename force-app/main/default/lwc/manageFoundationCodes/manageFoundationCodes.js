import { LightningElement,wire,api} from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import { updateRecord} from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from "@salesforce/apex";
import hasManageCodePermission from '@salesforce/customPermission/Manage_Foundation_Codes_Access';

import getFoundationCodes from '@salesforce/apex/ManageFoundationCodesCntrl.getFoundationCodes';
import syncAll from '@salesforce/apex/ManageFoundationCodesCntrl.syncAll';
import syncLastSyncJobStatus from '@salesforce/apex/ManageFoundationCodesCntrl.syncLastSyncJobStatus';

import NAME_FIELD from "@salesforce/schema/Foundation_Code__c.Name";
import CODE_NAME_FIELD from "@salesforce/schema/Foundation_Code__c.Foundation_Code__c";
import PARENT_FIELD from "@salesforce/schema/Foundation_Code__c.Parent__c";


export default class ManageFoundationCodes extends NavigationMixin(LightningElement) {
    @api recordId;
    @api viewMode;
    @api action = 'Change Parent';

    treeTitle = 'Hierarchy';
    codes = [];
    selected;
    foundationCodesResult;
    currentCode;
    currentSelectedRows = [];
    parentChildsMap = new Map();

    connectedCallback(){
        this.selected = this.recordId;
        this.getSyncStatus();
    }

    get hasManagePermission() {
      return hasManageCodePermission;
   }

    @wire(getFoundationCodes)
    wireHierarchyData(result) {
        let self = this;
        this.foundationCodesResult = result;
        if (result.data) {
          let parentChilds = new Map();
            this.codes = [];
            let itemMap = new Map();
            result.data.forEach((code) => {
              var item = itemMap[code.Id];
              var label = code.Status__c == 'Active' ? code.BGive_Description__c : code.BGive_Description__c + ' ('+code.Status__c+')';
              if(code.Sync_Warning__c || code.Sync_Error__c){
                label += ' [Not Synced]';
              }
              if(!item){                
                item = {
                    label: label,
                    name: code.Id,
                    expanded: false,
                    selected : true,
                    items: [],
                    _children : []
                }
                if(self.viewMode){
                    item.href = '/'+code.Id;
                }
              }else{
                item.label = label,
                item.expanded =  false;
                if(self.viewMode){
                  item.href = '/'+code.Id;
                }
              }

              itemMap [item.name] = item;

                if(code.Parent__c){
                  var parentCode = itemMap[code.Parent__c];
                    if(!parentCode){
                      itemMap[code.Parent__c] = {name: code.Parent__c,items: [],
                        _children : []};
                        parentCode = itemMap[code.Parent__c];
                    }
                    parentCode.items.push(item);
                    parentCode._children.push(item);

                    if(!self.viewMode) {
                      if(parentChilds.get(code.Parent__c)) {
                        parentChilds.get(code.Parent__c).push(code.Id);
                      } else {
                        parentChilds.set(code.Parent__c, [code.Id]);
                      }
                      if(code.Parent__r.Parent__c && parentChilds.get(code.Parent__r.Parent__c)) {
                        parentChilds.get(code.Parent__r.Parent__c).push(code.Id);
                        if(code.Parent__r.Parent__r.Parent__c && parentChilds.get(code.Parent__r.Parent__r.Parent__c)) {
                          parentChilds.get(code.Parent__r.Parent__r.Parent__c).push(code.Id);
                          if(code.Parent__r.Parent__r.Parent__r.Parent__c && parentChilds.get(code.Parent__r.Parent__r.Parent__r.Parent__c)) {
                            parentChilds.get(code.Parent__r.Parent__r.Parent__r.Parent__c).push(code.Id);
                            if(code.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c && parentChilds.get(code.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c)) {
                              parentChilds.get(code.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c).push(code.Id);
                              if(code.Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c && parentChilds.get(code.Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c)) {
                                parentChilds.get(code.Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c).push(code.Id);
                              }
                            }
                          }
                        }
                      }
                    }
                } else{
                    self.codes.push(item);
                    parentChilds.set(code.Id, []);
                }
                
                this.parentChildsMap = parentChilds;
            });
        }
    }
   

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [NAME_FIELD, PARENT_FIELD]
      })
      wireGetData( result ) {
        this.currentCode = result;
        if(this.recordId)
            this.selected = this.recordId;
    }
    
    get foundationCodeName() {
        return getFieldValue(this.currentCode.data, NAME_FIELD);
    }

    handleOnselect(event) {
        this.selected = event.detail.name; 
    }

    handleSave(){
      console.log('######parentChilds.get(this.selected): ' + JSON.stringify(this.parentChildsMap.get(this.recordId)));
      var recordIdChilds = this.parentChildsMap.get(this.recordId);
      
      if(this.selected == getFieldValue(this.currentCode.data, PARENT_FIELD)) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "Foundation Code is already under the selected Parent.",
            variant: "error",
          }),
        );
        return;
      }
      if(recordIdChilds) {
        const found = recordIdChilds.find((element) => element == this.selected);
        console.log('######found: ' + found);
          if(this.action == 'Change Parent'){
            if(found) {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: "Foundation Code can not be moved under its children.",
                  variant: "error",
                }),
              );
            } else {
              this.changeParent();
            }
          }
        } else {
          this.changeParent();
        }
    }

    changeParent(){
     
        const fields = {};
        fields[PARENT_FIELD.fieldApiName] = this.selected;
        fields["Id"] = this.recordId;
        const recordInput = { fields };
        updateRecord(recordInput)
          .then(() => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Foundation Code is moved to new parent successfully!",
                variant: "success",
              }),
            );
            refreshApex(this.foundationCodesResult);
            this.closeQuickAction();
          })
          .catch((error) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error creating record",
                message: error.body.message,
                variant: "error",
              }),
            );
          });
    }

    closeQuickAction() {
      this.dispatchEvent(new CloseActionScreenEvent());
    }

    get message(){
      if(this.action == 'Change Parent'){
        return 'Select New Parent For : '+ this.foundationCodeName;
      }
      return '';
    }

    handleCreateRecord() {
      const defaultValues = encodeDefaultFieldValues({
        Parent__c: this.recordId
      });
  
      console.log(defaultValues);
  
      this[NavigationMixin.Navigate]({
        type: "standard__objectPage",
        attributes: {
          objectApiName: "Foundation_Code__c",
          actionName: "new",
        },
        state: {
          defaultFieldValues: defaultValues,
        },
      });
    }

    handleSyncAll(){
      syncAll()
        .then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success",
                  message: "Sync all request submitted successfully.",
                  variant: "success",
                }),
              );

              this.getSyncStatus();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: "Error while syncing codes."+error.body.message,
                  variant: "error",
                }),
              );
        });
    }

    syncProgressValue;
    jobInstance;
    getSyncStatus(){
      syncLastSyncJobStatus()
        .then(result => {

           this.jobInstance = result;

            if(this.jobInstance != null){
              this.syncProgressValue = (this.jobInstance.JobItemsProcessed * 100) / this.jobInstance.TotalJobItems;
            }
            if(this.syncProgressValue < 100){
              this.getSyncStatus();
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: "Error Fetching Sync Status."+error.body.message,
                  variant: "error",
                }),
              );
        });
    }
}