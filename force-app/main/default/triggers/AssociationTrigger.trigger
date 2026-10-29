trigger AssociationTrigger on Association__c (after update) {
	TriggerFactory.createAndExecuteHandler(AssociationTriggerHandler.class);
}