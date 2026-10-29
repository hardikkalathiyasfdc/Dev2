/**
* Author : Gauri Sagane
* Date   : 02/20/2025
* Jira   : IM-113
* Description : This is a trigger on the Partner Funds object.
*/

trigger IMPartnerFundTrigger on IM_Funding_Source__c(before insert, before update, after insert, after update) {
    TriggerFactory.createAndExecuteHandler(IMPartnerFundTriggerHandler.class);
}