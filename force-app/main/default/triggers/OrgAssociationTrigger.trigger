trigger OrgAssociationTrigger on Org_Association__c (after insert, after update) {
	TriggerFactory.createAndExecuteHandler(OrgAssociationTriggerHandler.class);
}