/**
* Author : Lahari Anumala Setty
* Date   : 1/25/2024
* Jira   : BRME-4990
* Description : This is batch class created for MyNotes custom object to update the 'shared with' field
* Test   : BatchPopulateMyNotesSharedWithTest
**/

public class BatchPopulateMyNotesSharedWith implements Database.Batchable<SObject>,Schedulable {

    private static final String ERR_CLASS_FAILED = 'BatchPopulateMyNotesSharedWith_CLASS_FAILED';
    private static final String ERR_CLASS_UPDATE = 'BatchPopulateMyNotesSharedWith_UPDATE_FAILED';
    
    /**
    * This method will fetch all the Ids from MyNotes object
    */
    public String query='';
    public BatchPopulateMyNotesSharedWith(){
        this.query = 'SELECT Id,Name FROM My_Notes__c';
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        return  Database.getquerylocator(this.query);
    }
    
    /**
    * This method will populate the 'shared with' field based on notes shared 
    */
    public void execute(Database.BatchableContext BC, List<My_Notes__c> listOfMyNotes) {
        try {
            Set<Id> myNotesIds = new Set<Id>();
            List<My_Notes__Share> myNotesShareList = new List<My_Notes__Share>();
            List<MB_Error__c> errorLogs = new List<MB_Error__c>();
            Map<Id, My_Notes__c> mapOfMyNotesToUpdate = new Map<Id, My_Notes__c>();
            //Retrieve ids from MyNotes
            for(My_Notes__c myNotes : listOfMyNotes) {
                myNotesIds.add(myNotes.Id);
            }
            //Retrieve shared notes for the ids from MyNotes
            myNotesShareList = [SELECT Id, ParentId, UserOrGroup.Name, Parent.Owner.Name 
                                FROM My_Notes__Share 
                                WHERE ParentId IN :myNotesIds];
            for(My_Notes__Share myNotesShareRecord : myNotesShareList) {
                if(!mapOfMyNotesToUpdate.containsKey(myNotesShareRecord.ParentId)) {
                    My_Notes__c myNotes = new My_Notes__c();
                    myNotes.Id = myNotesShareRecord.ParentId;
                    myNotes.Shared_With__c = '';
                    mapOfMyNotesToUpdate.put(myNotesShareRecord.ParentId,myNotes);
                } 
                if(myNotesShareRecord.UserOrGroup.Name != myNotesShareRecord.Parent.Owner.Name) {
                    My_Notes__c myNotes = mapOfMyNotesToUpdate.get(myNotesShareRecord.ParentId);
                    if(!String.isEmpty(mapOfMyNotesToUpdate.get(myNotesShareRecord.ParentId).Shared_With__c)){
                        myNotes.Shared_With__c = mapOfMyNotesToUpdate.get(myNotesShareRecord.ParentId).Shared_With__c + ', ';
                    }
                    if(myNotesShareRecord.UserOrGroup.Name != NULL){
                        myNotes.Shared_With__c +=  myNotesShareRecord.UserOrGroup.Name;
                    } else {
                        myNotes.Shared_With__c +=  Assets.ALL_INTERNAL_USERS;
                    }
                    mapOfMyNotesToUpdate.put(myNotesShareRecord.ParentId,myNotes);
                }
            }
            BBApps_Crud.doUpdateWithHandling(mapOfMyNotesToUpdate.values(), false, new BBApps_ErrorCustomFields(ERR_CLASS_UPDATE));
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
    
    public void execute(SchedulableContext sc) {
        BatchPopulateMyNotesSharedWith myShareNoteObj = new BatchPopulateMyNotesSharedWith();
        Database.executeBatch(myShareNoteObj);
    }
}