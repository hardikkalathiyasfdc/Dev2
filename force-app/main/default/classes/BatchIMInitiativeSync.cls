/**
* Author       : Sai Bhargav Thotakura
* Created Date : Jan 25 2025
* Jira         : IM-49 
* Description  : Batch Class to handle Sync Process between BGive and BRM
* Test         : Yet To be Created
*/
public with sharing class BatchIMInitiativeSync implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    
    public Set<Id> initiativeIdSet;
    public String defaultQuery = Assets.BGIVE_DEFAULT_QUERY;

    public class BatchIMInitiativeSyncException extends Exception {} 
    
    //constructor
    public BatchIMInitiativeSync(Set<Id> initiativeIdSet) {
        this.initiativeIdSet = initiativeIdSet;
        this.defaultQuery = defaultQuery+' WHERE Id IN:initiativeIdSet';
    }
    
    /**
    * Description  : Used to schedule the batch class
    * Parameters   : Schedulable Context Instance
    * Return Type  : None
    */
    public void execute(SchedulableContext ctx){
        Id batchJobId = Database.executeBatch(this);
    }
    
    /**
    * Description  : Start Method to run query and get Initiative Data
    * Parameters   : Batchable Context instance
    * Return Type  : Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext ct){
        return Database.getQueryLocator(defaultQuery, AccessLevel.SYSTEM_MODE);
    }
    /**
    * Description  : Execute Method to execute the sync logic
    * Parameters   : Batchable Context instance, List<sObject> Scope
    * Return Type  : None
    */
    public void execute(Database.BatchableContext ct,List<sObject> scope){
        if(scope.size()>0){
            for(sObject sobj : scope){
                IMInitiativeService.sync(sobj.Id);
            }
        }else{
            BBApps_ErrorHandler.logErrors(new BatchIMInitiativeSyncException('No Records present in scope for BatchIMInitiativeSync'), new BBApps_ErrorCustomFields(Assets.BGIVE_SYNC_ERROR_TYPE));
        }
    }
    /**
    * Description  : Finish Method to execute post sync logic
    * Parameters   : Batchable Context instance
    * Return Type  : None
    */
    public void finish(Database.BatchableContext ct){
        //finish logic - email or something as needed per business
    }
}