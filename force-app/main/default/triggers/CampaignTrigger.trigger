trigger CampaignTrigger on Campaign (after update, before insert, before update) {
    TriggerFactory.createAndExecuteHandler(CampaignTriggerHandler.class);
}