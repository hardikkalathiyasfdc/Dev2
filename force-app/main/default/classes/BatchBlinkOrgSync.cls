/**
* Author : Gauri Sagane
* Date   : 09/24/2024
* Jira   : IM-34
* Description : This is the batch class to sync field values of BRM orgs with BGive.
* Test : BatchBlinkOrgSyncTest
*/

public with sharing class BatchBlinkOrgSync implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    public String query;
    List<Id> orgIds ;

    /**
    * Description : Constructor to initialize variables
    * Parameters : ids List<Id>
    */
    public BatchBlinkOrgSync(List<Id> ids) {
        this.orgIds = ids;
        List<String> fields = BLinkUtil.getSyncFieldsBRMToBGive('Account');

        query = 'SELECT Id, Bgive_Id__c ';
        if(fields != null){
            query += ','+ String.join(fields, ',');
        }
        query += ' From Account';
         if(orgIds != null && !orgIds.isEmpty()){
            query += ' WHERE Id IN :orgIds';
         }
    }

    /**
    * Description : Returns a Database.QueryLocator object representing the query locator used to retrieve records for processing
    * Parameters : bc Database.BatchableContext
    * Return Type : Database.QueryLocator
    */
    public Database.QueryLocator start (Database.BatchableContext bc) {
        return Database.getQueryLocator(query, AccessLevel.SYSTEM_MODE);
    }

    /**
    * Description : Method to perform the sync task
    * Parameters : bc Database.BatchableContext, orgs List<Account>
    * Return Type : void
    */
    public void execute (Database.BatchableContext bc, List<Account> orgs) {

        try{
            if(!orgs.isEmpty()) {

                for(Account org : orgs) {
                   new BLinkOrgService().sync(org);
                }
            }
        }catch(Exception e){
            UtilityClass.logError('' , e.getMessage() + '\n' + e.getLineNumber(), Assets.BLINK_SYNC_ERROR_TYPE);
        }
    }

    /**
    * Description : Method containing tasks to be performed after the processing of batch
    * Parameters : bc Database.BatchableContext
    * Return Type : void
    */
    public void finish (Database.BatchableContext bc){

    }
}