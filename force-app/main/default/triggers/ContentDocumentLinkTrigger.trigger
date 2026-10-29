/**
* Author : Hardik Kalathiya
* Date : 11/14/2024
* JIRA : BRME-5537
* Description : BRME 5537
This trigger allows custom logic to be executed during the file insert process.
We used the after insert context because it allows us to update the related Agreement and Interaction records when are inserted in the ContentDocumentLink.
* Salesforce Limitation: 	When a user deletes a file, ContentDocumentLink will not Trigger, so delete file related logic is handled in ContentDocumentTrigger seperately.
* Test : ContentDocumentTriggerTest
* Change Log 
Hardik Kalathiya on 11/14/2024 - BRME-5537: Refactor Triggers ContentDocumentLinkTrigger &ContentDocumentTrigger 
**/
trigger ContentDocumentLinkTrigger on ContentDocumentLink ( after insert ){
    TriggerFactory.createAndExecuteHandler(ContentDocumentLinkHandler.class);
}