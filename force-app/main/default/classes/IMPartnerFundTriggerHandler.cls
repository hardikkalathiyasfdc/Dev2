/**
* Author            : Gauri Sagane
* Date              : 02/20/2025
* Jira              : IM-113
* Description       : This class is used by Partner Fund Trigger and contains helper methods.
* Test              : IMPartnerFundTriggerHandlerTest
* ChangeLog         :
* Paddy - 05/04/2026: IM-554: Added logic to populate Partner Fund Summary.
**/

public with sharing class IMPartnerFundTriggerHandler extends TriggerHandler {

    public List<IM_Funding_Source__c> newPartnerFunds;
    public List<IM_Funding_Source__c> oldPartnerFunds;
    public Map<Id, IM_Funding_Source__c> oldMap;
    public Map<Id, IM_Funding_Source__c> newMap;

    private Set<Id> budgetIds = new Set<Id>();

    public IMPartnerFundTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, IM_Funding_Source__c>) Trigger.oldMap, (Map<Id, IM_Funding_Source__c>) Trigger.newMap);
    }

    public IMPartnerFundTriggerHandler(List<IM_Funding_Source__c> oldPartnerFundsList, List<IM_Funding_Source__c> newPartnerFundsList) {
        oldPartnerFunds = oldPartnerFundsList;
        newPartnerFunds = newPartnerFundsList;
    }

    public IMPartnerFundTriggerHandler(List<IM_Funding_Source__c> oldPartnerFundsList, List<IM_Funding_Source__c> newPartnerFundsList , Map<Id, IM_Funding_Source__c> oldMap , Map<Id, IM_Funding_Source__c> newMap) {
        newPartnerFunds = newPartnerFundsList;
        oldPartnerFunds = oldPartnerFundsList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void beforeInsert(SObject so) {
        IM_Funding_Source__c partnerFund = (IM_Funding_Source__c)so;
        partnerFund.Name = partnerFund.Partner__c;
    }

    public override void afterInsert(SObject so) {
        IM_Funding_Source__c partnerFund = (IM_Funding_Source__c)so;
        budgetIds.add(partnerFund.Budget__c);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        IM_Funding_Source__c newPartnerFund = (IM_Funding_Source__c)so;
        IM_Funding_Source__c oldPartnerFund = (IM_Funding_Source__c)oldSo;

        if(isFieldChanged(newPartnerFund, 'Partner__c')){
            newPartnerFund.Name = newPartnerFund.Partner__c;
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        IM_Funding_Source__c newPartnerFund = (IM_Funding_Source__c)so;
        IM_Funding_Source__c oldPartnerFund = (IM_Funding_Source__c)oldSo;

        if(isFieldChanged(newPartnerFund, 'Partner__c') || isFieldChanged(newPartnerFund, 'Allocated_Amount__c')) {
            budgetIds.add(newPartnerFund.Budget__c);
        }
    }

    public override void andFinally() {
        if(!budgetIds.isEmpty()) {
            populatePartnerFundSummary();
        }
    }

    /**
	 * Description : Method to populate Partnet Fund Summary if Parnter Fund is present
	 * Parameters  : None
	 * Return Type : Void
	 */
    private void populatePartnerFundSummary() {
        List<IM_Budget__c> budgetsToUpdate = new List<IM_Budget__c>();
        Map<Id, List<IM_Funding_Source__c>> fundingSourcesByBudget = getFundingSourcesByBudget(budgetIds);
        for(IM_Budget__c budget : [
            SELECT Initiative__r.Partner_Funding_Type__c
            FROM IM_Budget__C
            WHERE Id IN :budgetIds
            WITH SYSTEM_MODE
        ]) {            
            String msg = composeAlertFromFundingSources(fundingSourcesByBudget.get(budget.Id), budget.Initiative__r.Partner_Funding_Type__c);
            budgetsToUpdate.add(new IM_Budget__c(Id = budget.Id, Partner_Fund_Summary__c = msg));
        }
        BBApps_Crud.doUpdate(
			budgetsToUpdate
		);
    }

    private static Map<Id, List<IM_Funding_Source__c>> getFundingSourcesByBudget(Set<Id> budgetIds) {
        Map<Id, List<IM_Funding_Source__c>> fundingSourcesByBudget = new Map<Id, List<IM_Funding_Source__c>>();

        if(budgetIds.isEmpty()) {
            return fundingSourcesByBudget;
        }

        for(IM_Funding_Source__c fs : [
            SELECT Budget__c, Allocated_Amount__c, Partner__c
            FROM IM_Funding_Source__c
            WHERE Budget__c IN :budgetIds
            WITH SYSTEM_MODE
            ORDER BY CreatedDate ASC
        ]) {
            List<IM_Funding_Source__c> fundingSources = fundingSourcesByBudget.containsKey(fs.Budget__c) ? fundingSourcesByBudget.get(fs.Budget__c) : new List<IM_Funding_Source__c>();
            fundingSources.add(fs);
            fundingSourcesByBudget.put(fs.Budget__c, fundingSources);
        }
        return fundingSourcesByBudget;
    }

    private static String composeAlertFromFundingSources(List<IM_Funding_Source__c> fundingPartners, String partnerFundingType) {
        if(fundingPartners == null || fundingPartners.isEmpty()) {
            return '';
        }
        List<String> messages = new List<String>();
        for(IM_Funding_Source__c fs : fundingPartners) {
            messages.add('$' + IMUtil.formatAmount(fs.Allocated_Amount__c) + ' from ' + fs.Partner__c);
        }

        String alertMessage = String.join(messages, ', ');
        if (partnerFundingType == 'Supplemental') {
           return alertMessage + ' is not included in the number.';
        }
        return alertMessage + ' is included in the number.';
    }
}