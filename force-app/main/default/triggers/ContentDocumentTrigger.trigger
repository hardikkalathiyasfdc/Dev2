/**
* Author : Hardik Kalathiya
* Date : 11/14/2024
* JIRA : BRME-5537
* Description: BRME-5537
This trigger allows custom logic to be executed during the file deletion process. 
We used the before delete context because it allows us to update the related Agreement and Interaction records for the deleted file.

* Salesforce Limitation: ContentDocument does not trigger when a user selects an existing File. ContentDocument only triggers when we upload a new file.
This is the reason why we have not used insert context in this trigger.

* Test : ContentDocumentTriggerTest
* Change Log 
Hardik Kalathiya on 11/14/2024 - BRME-5537: Refactor Triggers ContentDocumentLinkTrigger &ContentDocumentTrigger 
**/

trigger ContentDocumentTrigger on ContentDocument (before delete) {
    TriggerFactory.createAndExecuteHandler(ContentDocumentHandler.class);
}