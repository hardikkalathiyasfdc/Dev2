trigger GeoAreaTrigger on Geo_Area__c (before update, before insert, after update) {
    TriggerFactory.createAndExecuteHandler(GeoAreaTriggerHandler.class);
}