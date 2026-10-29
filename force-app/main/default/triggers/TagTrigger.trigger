/**
 * Author :
 * Date : 11/26/2024
 * JIRA : BRME-5549
 * Description : The purpose is to handle the bulk update of Tag__c records, ensuring that changes to the Name field are propagated to related Tag_Junction__c records.
 * Test : TagsCmpControllerTest
 * Change Log 

 **/

trigger TagTrigger on Tag__c(
    before insert,
    before update,
    after insert,
    after update
) 
{
    TriggerFactory.createAndExecuteHandler(TagTriggerHandler.class);
}