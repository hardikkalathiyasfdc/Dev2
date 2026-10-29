import { LightningElement, track, api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const FIELDS = ['Donor__c.Amount__c', 'Donor__c.Contact__c', 'Donor__c.Credit_Type__c', 'Donor__c.Donor_Type__c'];
import SAMPLEMC from '@salesforce/messageChannel/PledgePageRefresh__c';
import { publish,subscribe,unsubscribe,createMessageContext,releaseMessageContext } from 'lightning/messageService';
import deleteRecrddonobb from '@salesforce/apex/PledgeRecordEditFormController.deleteRecrd';
export default class AddPledgeDonorsBenefites extends NavigationMixin(LightningElement) {

    @track record;
    @track isdonorRequired;
    _allRecords = [];
    @api
    get allRecords() {
        return this._allRecords;
    }
    set allRecords(value) {
        this._allRecords = (value || []).map(rec => ({
            ...rec,
            benefitsDefaultIds: rec.Benefits__c ? [rec.Benefits__c] : (rec.benefitsDefaultIds || []),
            contactDefaultIds: rec.Contact__c ? [rec.Contact__c] : (rec.contactDefaultIds || []),
            organizationDefaultIds: rec.Organization__c ? [rec.Organization__c] : (rec.organizationDefaultIds || [])
        }));
    }
    @api allDelReds = [];
    toggleSaveLabel = 'Save';
    @api fileds; /*[{label:'Donor Type', fieldName:'Donor_Type__c',required:true, isvalueshow:false}, {label:'Donor', fieldName:'Contact__c', required:true, isvalueshow:false},
                   {label:'Credit Type', fieldName:'Credit_Type__c', required:false , isvalueshow:false}, {label:'Amount', fieldName:'Amount__c', required:false,isvalueshow:true}];*/
        
    @api objectName; //'Donor__c'
    @api cardTitle;
    @api cardIcon;
    @api addRowButtonName;
donorfield = ['Donor_Type__c', 'Credit_Type__c', 'Amount__c'];
    @api fEId;
    isParentRequired = true;
    accountDisplayFields = ['Search_Display_Name__c', 'Computed_AKA__c', 'Legal_Name__c', 'Website'];
    accountSearchFields = ['Search_Display_Name__c'];
    contactDisplayFields = ['Search_Display_Name__c', 'Account.Search_Display_Name__c', 'Email'];
    contactSearchFields = ['Search_Display_Name__c'];
    benefitsDisplayFields = ['Name'];
    benefitsSearchFields = ['Name'];
    @api isPledgeBenifits = false;    

    /* donor Specific - Start */
    @api hasDonorSpecific;
    @api pledgeAmount;
       subscription = null;
context = createMessageContext();
    /* donor Specific - Start */
publisherMessage = '';
    subscription = null;
  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
   // @wire(MessageContext)
    //messageContext;

     connectedCallback(){
        this.record = { Id : '', key : Math.random().toString(36).substring(2, 15), sobjectType : this.objectName};
        this.addRowButtonName =  this.addRowButtonName  ?  this.addRowButtonName  : 'Add New Row';
        //this.onLoadEmptyRec();  
       // console.log('this.pledgeAmount>>>>>',JSON.stringify(this.pledgeAmount));
           this.subscribeToMessageChannel();
       
    }

     // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        
        this.subscription = subscribe(this.context, SAMPLEMC, (RecData) => {
            this.displayMessage(RecData);
        });
    }


    // Handler for message received by component
    displayMessage(RecData) {
        console.log('Save naviview donor',RecData.recordId);
        this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        objectApiName: "Pledge__c",
        actionName: "view",
        recordId: RecData.recordId
      }
    });
  //   eval("$A.get('e.force:refreshView').fire();");
             

    }
    
    arrayIsEmpty(array) {    
        if (!Array.isArray(array)) {
            return false;
        }        
        if (array.length == 0) {
            //Return TRUE if the array is empty
            return true;
        }
        return false;
    }

    onLoadEmptyRec(){
        var recs = [];
        if(this.arrayIsEmpty(this.allRecords)){
            let objRec = Object.assign({}, this.record);
            objRec.key = 0;
           // objRec.isDelete = false;
            if(this.hasDonorSpecific){
                objRec.Donor_Type__c = '';
                objRec.isShowContact =  objRec['Donor_Type__c'] == 'Contact';
            }  
            objRec.Amount__c = this.pledgeAmount; 
            if(this.allRecords.length < 1 ){
             objRec.Credit_Type__c = 'Donor - Primary';
         }else{
objRec.Credit_Type__c = 'Donor - Soft';  
         } 
           
            recs.push(objRec);
        } 
        console.log('onLoadEmptyRec',recs);
        this.allRecords = recs;
    }
    
    get tempRecords() {
        if (this.allRecords) {
            const allRecs = this.allRecords;
             console.log('tempRecords',allRecs);
            var recs = [];
            for (var i = 0; i < allRecs.length; i++) {
                let objRec = Object.assign({}, this.allRecords[i]);
                objRec.key = i;
                objRec.sobjectType = this.objectName;
                //objRec.isDelete = true;
                if (this.hasDonorSpecific) {
                    objRec.isShowContact = objRec['Donor_Type__c'] == 'Contact';
                    //console.log(' objRec.isShowContact:::', objRec.isShowContact, '>>>>>>',objRec['Donor_Type__c']);
                }
                
                recs.push(objRec);
            }
        }else{
          // console.log('this.allRecords>>>>>>>>',this.allRecords); 
        }
        //console.log('this.allRecords>>>>>>>>',this.allRecords);    
        return recs;
    }

    @api
    updateAllAmounts(amount) {
        if (this.allRecords && this.allRecords.length > 0) {
            this.allRecords = this.allRecords.map(row => ({ ...row, Amount__c: amount }));
        }
    }

    addRow1(){
        //console.log('add row start :::', this.allRecords);
        const len = this.allRecords.length;
        var rows = [];
        var objRec = Object.assign({}, this.record);
        objRec.key = len ? len : 0;
         if(this.hasDonorSpecific){
            objRec.Donor_Type__c = 'Contact';
          
            //objRec.isDelete = true;
            objRec.isShowContact =  objRec['Donor_Type__c'] == 'Contact';

         }
        
           objRec.Amount__c = this.pledgeAmount;
         if(this.allRecords.length < 1 ){
          objRec.Credit_Type__c = 'Donor - Primary';
         }else{
              objRec.Credit_Type__c = 'Donor - Soft'; 
         }
        objRec.benefitsDefaultIds = [];
        objRec.contactDefaultIds = [];
        objRec.organizationDefaultIds = [];
          
          
          console.log('pledgeAmount:::', this.pledgeAmount);
        rows = this.allRecords ? [...this.allRecords] : [];
        rows.push(objRec);
        this.allRecords = [...rows];
      //  this.allRecords = [...this.allRecords];
        console.log('add row end:::', this.allRecords);
    }

    handleValueSelectedOnAccount(e) {
        const sel = (e.detail && e.detail.selectedIds) ? e.detail.selectedIds[0] : null;

        const rowKey =
            (e.currentTarget && e.currentTarget.getAttribute('data-id')) ||
            (e.target && e.target.getAttribute('data-id')) ||
            null;

        if (!rowKey) {
            console.warn('No rowKey on event; ensure data-id is on the element with onvalueselected handler.');
            return;
        }

        const idx = parseInt(rowKey, 10);
        if (isNaN(idx) || idx < 0 || idx >= this.allRecords.length) {
            console.warn('Row not found for key:', rowKey);
            return;
        }

        const value = sel || null;

        const updatedRow = { ...this.allRecords[idx], Contact__c: value, contactDefaultIds: value ? [value] : [] };
        const next = [...this.allRecords];
        next.splice(idx, 1, updatedRow);
        this.allRecords = next;

        this.outstandingOverrideAck = false;
        this.outstandingOverrideKey = null;
    }

    removeRow1(event){
        let delrr = [];
        
         let delrrnew = [];
        if(this.allDelReds){
        delrrnew = this.allDelReds ;
         }
        const indexPos = event.currentTarget.name;
        const recId = event.currentTarget.id;
        console.log('recId>>>>',recId);
          console.log('lst Dell>>>>',  this.allDelReds);
        
        let remList = [];
        
        remList = this.allRecords;
          console.log('lst remList>>>>', remList);
        if(remList.length >1 ){ 
        remList.splice(indexPos,1);
        this.allRecords = remList;
         if(recId){
            var recIds = recId.split('-');
            //console.log('recId>>>>',recIds[0]);
            var rede=recIds[0];
           
           // this.deleteRecord(recIds[0]);
        }
          delrr.push(rede);
           
            }else if(remList.length == 1 && remList[0].Benefits__c != null){
            remList.splice(indexPos,1);
            this.allRecords = remList;
            if(recId){
            var recIds = recId.split('-');
            //console.log('recId>>>>',recIds[0]);
            var rede=recIds[0];
             delrr.push(rede);  
            // this.deleteRecord(recIds[0]);
        }
           
         }
         else{ 
          this.dispatchEvent(
            new ShowToastEvent({
                title: 'can not delete last record',
                message: 'can not delete last record',
                variant: 'error',
            }),
        );
        }
        
        delrrnew.push(delrr);
        this.allDelReds = delrrnew;
     
        console.log('recId dell>>>>',  this.allDelReds);
       
    }   

    handlefieldChange(event){
        if (this.allRecords) {
            const allRecs = this.allRecords;
             console.log('tempRecords',allRecs);
            var recs = [];
            for (var i = 0; i < allRecs.length; i++) {
                let objRec = Object.assign({}, this.allRecords[i]);
                objRec.key = i;
                objRec.sobjectType = this.objectName;
                //objRec.isDelete = true;
                if (this.hasDonorSpecific) {
                    objRec.isShowContact = objRec['Donor_Type__c'] == 'Contact';
                    //console.log(' objRec.isShowContact:::', objRec.isShowContact, '>>>>>>',objRec['Donor_Type__c']);
                }
                
                recs.push(objRec);
            }
        }else{
          // console.log('this.allRecords>>>>>>>>',this.allRecords); 
        }
        this.allRecords = recs;
       const allRecs = this.allRecords;
       console.log('onchnage allRecs:::', allRecs);
        let foundelement = allRecs.find(ele => ele.key == event.target.dataset.id);
          console.log('id deatatta:::', event.target.dataset.id);
        let fname =  event.target.name;
        let value =  event.target.value; 
        console.log('foundelement:::', foundelement);
 
        console.log('value:::', value);    
        console.log('fname:::', fname);   
        foundelement[fname] = value;
        
        this.allRecords = [...this.allRecords];
     
        
        console.log(' ==> vv' +  JSON.stringify(this.allRecords));
    }

    get benefitsFilterClause() {
        return this.fEId ? `Fundraising_Effort__c = '${this.fEId}'` : '';
    }

    get recipientOrgFilterClause() {
        return this.fEId ? `Recipient_Organization__c = '${this.fEId}'` : '';
    }

    handleOrganizationSelected(e) {
        const value = (e.detail && e.detail.selectedIds) ? e.detail.selectedIds[0] : null;

        const rowKey =
            (e.currentTarget && e.currentTarget.getAttribute('data-id')) ||
            (e.target && e.target.getAttribute('data-id')) ||
            null;

        if (!rowKey) {
            console.warn('No rowKey on event; ensure data-id is on the element with onchange handler.');
            return;
        }

        const idx = parseInt(rowKey, 10);
        if (isNaN(idx) || idx < 0 || idx >= this.allRecords.length) {
            console.warn('Row not found for key:', rowKey);
            return;
        }

        const updatedRow = { ...this.allRecords[idx], Organization__c: value, organizationDefaultIds: value ? [value] : [] };
        const next = [...this.allRecords];
        next.splice(idx, 1, updatedRow);
        this.allRecords = next;
    }

    lookupFpmRecord(event){
        event.preventDefault();        
        let foundelement = this.allRecords.find(ele => ele.key == event.target.dataset.id);
        console.log('foundelement ::' + JSON.stringify(foundelement));
        var rec = event.detail.selectedIds ? event.detail.selectedIds[0] : null;
        foundelement['Benefits__c'] = rec;
        foundelement['benefitsDefaultIds'] = rec ? [rec] : [];
        this.allRecords = [...this.allRecords];
    }

    deleteRecord(recId){
         deleteRecord(recId)
            .then(() => {
               console.log('record deleted successfully ::::');
            })
            .catch(error => {
               console.log('delete row error:::: ',error);
            });
    }
    
    @api isValid(){       
        var isValcredit= false ; 
        var isVal = true;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            isVal = isVal &&   element.reportValidity();
        });
        if(this.allRecords){
            this.allRecords.forEach( rec => {
               console.log('validationn ',rec);
              
               if(rec.sobjectType=='Donor__c' && (!rec.Contact__c && !rec.Organization__c)){
                    isVal=  false; 
            
             return  isVal;
               }
                
            });
        }
       
        console.log('validationn isVal',isVal);
        return isVal;
    }
    @api isValidCredit(){       
         var isValtry = false;
        var isVal = true;
       
            this.allRecords.forEach( rec => {
                console.log('validationn cvlaidd ',rec);
               console.log('validationn cvlaidd ',rec.Credit_Type__c);
              
               if(rec.Credit_Type__c === 'Donor - Primary' ){
                    isValtry=  true; 
                    return isVal;
                    
            
               }else{
                  isVal=  false;   
               }
                
            });
        
        if(isValtry ==  true){
             isVal=  true; 
            
        }
       return isVal;
    }
     @api validAmountCheck(){
  var amont = 0;
         this.allRecords.forEach( rec => {
                console.log('validationn amount1 ',rec);
                 
                if(rec.Credit_Type__c === 'Donor - Primary' ){
                    if(rec.Amount__c!=''){
                       
                    amont =  Number(amont) +  Number(rec.Amount__c); 
                    console.log('validationn amount2 ',amont);
                 
                    }else{
                        
                      amont =  Number(amont) + Number(this.pledgeAmount) ;   
                       console.log('validationn amount3 ',amont);
                    }
                   
            
               }
                
            });
             console.log('validationn amount4 ',amont);
            return amont;
    }
    @api handleSave(){
  
        const uiProps = ['key', 'isShowContact', 'benefitsDefaultIds', 'contactDefaultIds', 'organizationDefaultIds'];
        const lookupFields = ['Contact__c', 'Organization__c', 'Benefits__c'];
        const records = this.allRecords ? this.allRecords.map(rec => {
            let cleaned = Object.assign({}, rec);
            uiProps.forEach(prop => delete cleaned[prop]);
            lookupFields.forEach(f => { if (cleaned[f] === null || cleaned[f] === undefined) delete cleaned[f]; });
            cleaned.sobjectType = this.objectName;
            if (!cleaned.Id) {
                delete cleaned['Id'];
               }
            return cleaned;
        }) : [];
        
        console.log( ' Final Save ==> ' + JSON.stringify(records));
        return records;
    }
@api handleDnordelete(){
   console.log('record deleted inside ::::'+this.allDelReds);
    
     
    return this.allDelReds;
}
}