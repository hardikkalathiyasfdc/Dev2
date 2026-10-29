/**
* Author : Hardik Kalathiya
* Date : 11/14/2024
* JIRA : BRME-5537
* Description : The ContentDocumentLinkHandler class is a trigger handler that processes ContentDocumentLink records, 
handling logic related to agreements and interactions based on the linked entity type.
* Test : ContentDocumentTriggerTest
* Change Log 
Hardik Kalathiya on 11/14/2024 - BRME-5537: Refactor Triggers ContentDocumentLinkTrigger &ContentDocumentTrigger 
**/
public with sharing class ContentDocumentLinkHandler  extends TriggerHandler {
    public override void bulkAfter() {
        if(Trigger.isInsert){
            ContentDocumentService.processContentDocuments(Trigger.new, true);      
        }
    } 
}