/*********************************
* Created: 07/15/2025
* Created By: Nishant Bakhrey    
**********************************/
trigger ListOrganizationTrigger on ListOrganization__c(after insert, before delete) {
    TriggerFactory.createAndExecuteHandler(ListOrganizationTriggerHandler.class);
}