/**
* Author            : Paddy
* Date              : 03/17/2025
* Jira              : IM-124
* Description       : This class is used by IMGeography Trigger.
* Test              : IMBudgetOrgTriggerHandlerTest
*/
public with sharing class IMBudgetOrgTriggerHandler extends TriggerHandler {
    public List<IM_Budget_Org__c> newBudgetOrgs;
    public List<IM_Budget_Org__c> oldBudgetOrgs;
    public Map<Id, IM_Budget_Org__c> oldMap;
    public Map<Id, IM_Budget_Org__c> newMap;

    public List<IM_Budget_Org__c> budgetOrgsToUpdate = new List<IM_Budget_Org__c>();

    public IMBudgetOrgTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, IM_Budget_Org__c>) Trigger.oldMap, (Map<Id, IM_Budget_Org__c>) Trigger.newMap);
    }

    public IMBudgetOrgTriggerHandler(List<IM_Budget_Org__c> oldBudgetOrgList, List<IM_Budget_Org__c> newBudgetOrgList) {
        newBudgetOrgs = newBudgetOrgList;
        oldBudgetOrgs = oldBudgetOrgList;
    }

    public IMBudgetOrgTriggerHandler(List<IM_Budget_Org__c> oldBudgetOrgList, List<IM_Budget_Org__c> newBudgetOrgList , Map<Id, IM_Budget_Org__c> oldMap , Map<Id, IM_Budget_Org__c> newMap) {
        newBudgetOrgs = newBudgetOrgList;
        oldBudgetOrgs = oldBudgetOrgList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void beforeInsert(SObject so) {
        IM_Budget_Org__c budgetOrg = (IM_Budget_Org__c)so;
        setExternalId(budgetOrg);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        IM_Budget_Org__c newBudgetOrg = (IM_Budget_Org__c)so;
        IM_Budget_Org__c oldBudgetOrg = (IM_Budget_Org__c)oldSo;

        if(isFieldChanged(newBudgetOrg, 'Type__c') || isFieldChanged(newBudgetOrg, 'Organization__c')) {
            setExternalId(newBudgetOrg);
        }
    }

    private void setExternalId(IM_Budget_Org__c budgetOrg) {
        budgetOrg.External_Id__c = budgetOrg.Budget__c + budgetOrg.Type__c + budgetOrg.Organization__c;
    }
}