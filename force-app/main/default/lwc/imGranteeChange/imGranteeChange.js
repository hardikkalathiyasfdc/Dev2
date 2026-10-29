import { LightningElement, api } from 'lwc';
import LightningModal from "lightning/modal";
import validatePartner from '@salesforce/apex/IMGrantViewController.validatePartner';
import getBgiveGrant from '@salesforce/apex/IMGrantViewController.getBgiveGrant';
import changePartner from '@salesforce/apex/IMGrantViewController.changePartner';
import syncPartnerWithBGive from '@salesforce/apex/IMGrantViewController.syncPartnerWithBGive';

export default class ImGranteeChange extends LightningModal {

    @api budgetGrant;
    @api imGrant;
    @api allBudgetGrants;
    @api allBudgetIds;
    partnerId;
    uniqueIdentifier;
    budgetOrgs;
    bgiveGrant;
    allUniqueIdentifiers;
    partnerAKA;
    isIdentifierPresent = false;
    errorMessages = [];
    isUniqueIdentifierRequired = false;
    isSaveDisabled = true;
    isError = false;
    showSpinner = false;

    displayInfo = {
		primaryField: "Name",
		additionalFields: ["AKA__c"],
	};

	matchingInfo = {
		primaryField: { fieldPath: "Name", mode: "contains" },
		additionalFields: [{ fieldPath: "AKA__c" }],
	};

	get displayInfoAdditionalFieldData() {
		return JSON.stringify(this.displayInfo?.additionalFields ?? []);
	}

    handlePartnerChange(event) {
        this.partnerId = event.detail.recordId;
        if(this.partnerId){
            this.isError = false;
            this.errorMessages = [];
            this.validatePartner();
        }else{
            this.isSaveDisabled = true;
        }
    }

    // IM-570: Method to validate the new Partner Selected
    async validatePartner() {
        try {
            const result = await validatePartner({ budgetGrant: this.budgetGrant, partnerId: this.partnerId, budgetIds: this.allBudgetIds });
            this.allUniqueIdentifiers = result?.uniqueIdentifiers ?? [];
            this.budgetOrgs = result?.budgetOrgs ?? [];
            if(result?.partner){
                this.partnerAKA = result?.partner.AKA__c;
            } else{
                this.partnerAKA = null;
            }
            if(!result.isBlinked){
                this.errorMessages.push('Please first ensure the Organization is B-Link before changing the Partner Org on this Grant.');
                this.showSpinner = false;
                this.isError = true;
            } else if(result.isBudgetOrgPresent || this.budgetGrant?.Unique_Identifier__c != null){
                this.isUniqueIdentifierRequired = true;
                if(this.budgetGrant?.Unique_Identifier__c){
                    this.isIdentifierPresent = true;
                    this.uniqueIdentifier = this.budgetGrant.Unique_Identifier__c;
                    this.isSaveDisabled = false;
                }
                this.showSpinner = false;
            } else{
                this.showSpinner = false;
                this.isSaveDisabled = false;
            }
        } catch (error) {
            this.showErrorToast(error);
        }
    }

    handleIdentifierChange(event) {
        this.uniqueIdentifier = event.target.value;
        this.isSaveDisabled = false;
    }

    handleClose() {
        this.close('close');
    }

    handleSave() {
        this.isError = false;
        this.errorMessages = [];
        if(this.isUniqueIdentifierRequired && !this.uniqueIdentifier){
            this.errorMessages.push('Unique Identifier is required. Please enter a value before saving.');
            this.isError = true;
        } else if(!this.isUniqueIdentifierRequired){
            // No unique identifier needed and budget grant doesn't have one, proceed with grantee change
            this.checkBgiveGranteeStatus();
        }else {
            // Unique identifier is required and provided, validate it
            this.validateIdentifier();
        }
    }

    // IM-570: Method to validate the new Unique Identifier
    validateIdentifier() {
        try {
            if(this.allUniqueIdentifiers?.includes(this.uniqueIdentifier)){
                this.errorMessages.push('This Unique Identifier is already in use, please enter a unique value.');
                this.isError = true;
            } else{
                this.checkBgiveGranteeStatus();
            }
        } catch (error) {
            this.close('error');
        }
    }

    // IM-570: Method to validate the new Grantee Selected
    async checkBgiveGranteeStatus() {
        try {
            this.bgiveGrant = await getBgiveGrant({ grantRequestContigId: this.imGrant.Bgive_Contig_Id__c });
            if(this.bgiveGrant && this.bgiveGrant.granted == 1){
                this.errorMessages.push('The Partner Org on this Grant cannot be updated because it is either too far in the workflow or was declined.');
                this.isError = true;
            } else{
                this.showSpinner = true;
                this.changePartner();
            }
        } catch (error) {
            this.close('error');
        }
    }

    // IM-570: Method to validate the new Partner Selected
    async changePartner() {
        try {
            if(this.isIdentifierPresent && this.uniqueIdentifier === this.budgetGrant?.Unique_Identifier__c){
                this.uniqueIdentifier = null;
            }
            const result = await changePartner({ imGrant: this.imGrant, budgetGrantMap: this.allBudgetGrants, partnerId: this.partnerId, uniqueIdentifier: this.uniqueIdentifier, budgetOrgs: this.budgetOrgs, budgetIds: this.allBudgetIds });
            if(result){
                this.syncPartnerWithBGive();
            }
        } catch (error) {
            this.close('error');
        }
    }

    // IM-570: Method to validate the new Partner Selected
    async syncPartnerWithBGive() {
        try {
            const result = await syncPartnerWithBGive({ imGrantId: this.imGrant?.Id });
            this.showSpinner = false;
            this.close('success');
        } catch (error) {
            this.close('error');
        }
    }
}