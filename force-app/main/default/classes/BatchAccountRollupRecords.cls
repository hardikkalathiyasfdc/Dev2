/**
* Author : Hardik Kalathiya
* Date   : 03/19/2024
* Jira   : BRME-4774
* Description : This is scheduler class which calculates Touchpoint Summary on Organization Object
* Test   : BatchAccountRollupRecordsTest
**/
public class BatchAccountRollupRecords implements Database.Batchable<sObject>, Schedulable {
    private static final String ERR_START   = 'BARR_START_FAILED';
    private static final String ERR_EXECUTE = 'BARR_EXECUTE_FAILED'; 

    public static String strQuery = 'Select Id from Account';
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this,200); 
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        try {
            return  Database.getquerylocator(strQuery);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_START);
            BBApps_ErrorHandler.logErrors(ex, f);
            return null;
        }
    }
    
    public void execute(Database.BatchableContext BC, List<Account> accountList){
        try{
            List<Account> lstAccountToUpdate = new List<Account>();
            Integer countOfChildRecords = 0;
            List<Account> listAccount = [Select Id,Touchpoint_Summary__c,
                                      (Select Id From List_Organizations__r),
                                      (Select Id, Contact__c From Interactions1__r), 
                                      (Select Id From Org_Associations__r),
                                      (Select Id From Donors1__r),
                                      (Select Id From Donors__r),
                                      (Select Id From Tags__r),
                                      (Select Id From Opportunities),
                                      (Select Id From Confidential_Briefings__r),
                                      (Select Id From Interactions__r)
                                      From Account Where Id IN: accountList
                                     ];
            for(Account accRecord : listAccount){
                Integer orgCount=  accRecord.List_Organizations__r != null ?  accRecord.List_Organizations__r.size() : 0;
                Integer interactionsWithOrgCount = 0;
                Set<Id> uniqueContactIds = new Set<Id> ();
                for (Interaction__c i: accRecord.Interactions1__r) {
                    if (i.Contact__c != null) {
                        uniqueContactIds.add (i.Contact__c);
                    }
                }
                interactionsWithOrgCount = uniqueContactIds.size();
                Integer orgAssociationCount = accRecord.Org_Associations__r != null ? accRecord.Org_Associations__r.size() : 0;
                Integer tagCount = accRecord.Tags__r != null ? accRecord.Tags__r.size() : 0;
                Integer oppCount = accRecord.Opportunities != null ? accRecord.Opportunities.size() : 0;
                Integer conFileCount = accRecord.Confidential_Briefings__r != null ? accRecord.Confidential_Briefings__r.size() : 0;
                Integer pledgeCount= accRecord.Donors__r != null  && accRecord.Donors__r.Size()>0 ? 1 : 0;
                Integer recvCount= accRecord.Donors1__r != null   && accRecord.Donors1__r.Size()>0 ? 1 : 0;
                Integer orgHighlightedCount = accRecord.Interactions__r != null ? accRecord.Interactions__r.size() : 0;
                
                countOfChildRecords = orgCount + interactionsWithOrgCount + orgAssociationCount + tagCount + oppCount + conFileCount + pledgeCount + recvCount + orgHighlightedCount;
                
                if(accRecord.Touchpoint_Summary__c != countOfChildRecords)
                {
                    Account acc  = new Account();
                    acc.Id = accRecord.Id;
                    acc.Touchpoint_Summary__c = countOfChildRecords;
                    lstAccountToUpdate.add(acc);
                }
            }
            if(!lstAccountToUpdate.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(lstAccountToUpdate, false, ERR_EXECUTE);
            }
        }
        
        catch(Exception ex){
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}