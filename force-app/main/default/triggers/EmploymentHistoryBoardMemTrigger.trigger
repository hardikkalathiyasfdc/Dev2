/*********************************************
* Created: October 30, 2019
* Created By: Slalom Consulting
* Business Purpose: EmploymentHistoryBoardMemTrigger was created to update Board Mem/Former Board Mem field on Contact object 
*                   This updates the status on Contact accordingly.
* Updates
* ----------------------------------
* Updated By    Date            Comment
* 
***********************************************/
trigger EmploymentHistoryBoardMemTrigger on Employment_History_and_Board_Membership__c (before insert, before update, after insert, after update, after delete) {
    TriggerFactory.createAndExecuteHandler(EmploymentHistoryBoardMemTriggerHandler.class);
}