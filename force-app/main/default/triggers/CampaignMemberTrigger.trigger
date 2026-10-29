/*********************************************
* Created: March 27, 2017
* Created By: Lewis Blau - Slalom Consulting
* Business Purpose: Trigger will insert the bio_photo text from Contact. This was done with a trigger since the field is a Rich text and
                    a formula and process builder can't process Rich Text fields. Bio Description was changed to a text field.              
* Updates
* ----------------------------------
* Updated By        Date                Comment
* Lewis Blau        03/27/2017          Created
* Loveena Stephen   11/28/2019          Updated code to use new field         
***********************************************/
trigger CampaignMemberTrigger on CampaignMember (before insert, before update, after insert, after update, before delete) {
    TriggerFactory.createAndExecuteHandler(CampaignMemberTriggerHandler.class);
}