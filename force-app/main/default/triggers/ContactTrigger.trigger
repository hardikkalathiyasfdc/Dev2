/*********************************************
* Created: March 27, 2017
* Created By: Lewis Blau - Slalom Consulting
* Business Purpose: ContactTrigger was created to update the any Campaign Member Bio Photo for creating 
*                   The Bio Photo Report. This will only update photos on Active Campaigns
* Updates
* ----------------------------------
* Updated By    Date            Comment
* Lewis Blau    03/27/2017      Created  
* Lewis Blau    04/07/2017      Added code of Bio Description to update Date feild
* Slalom        05/01/2019      Added business logic for creating Contact Categories
* Slalom        09/18/2019      Detect where the contact was created from mobile vs desktop, based on the Session Platform
* Slalom        09/26/2019      Resize bio photo to 100px x 100pxß
* Bloomberg     01/10/2020      TriggerFactory pattern
***********************************************/
/***
 * Going forward DO NOT add ANY code here. All code should be in ContactTriggerHandler.
 * For details refer to https://meltedwires.com/2013/06/05/trigger-pattern-for-tidy-streamlined-bulkified-triggers-revisited/
 * TODO: move all code in here to ContactTriggerHandler
 ****/
trigger ContactTrigger on Contact (after update, before update, before insert, after insert, before delete, after delete) {
        
    TriggerFactory.createAndExecuteHandler(ContactTriggerHandler.class);
}