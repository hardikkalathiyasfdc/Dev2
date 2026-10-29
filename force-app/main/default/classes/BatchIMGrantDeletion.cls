/**
 * Author : Gauri Sagane
 * Date   : 07/18/2025
 * Jira   : IM-300
 * Description : This is the batch class to hard delete IM Grants which are marked as soft deleted
 * Test : BatchIMGrantDeletionTest
 * ChangeLog :
 * Gauri Sagane on  - IM-438 - Modified batch to only delete IM Grants which are marked for deletion and who doesn't have any children
 */

public with sharing class BatchIMGrantDeletion implements Schedulable, Database.Batchable<sObject> {

	private static final String ERR_DELETE_IM_GRANTS = 'DELETE_IM_GRANTS_FAILED';
	String query;

	/**
	 * Description  : Used to schedule the batch class
	 * Parameters   : Schedulable Context Instance
	 * Return Type  : None
	 */
	public void execute(SchedulableContext sc) {
		Id batchJobId = Database.executeBatch(this);
	}

	/**
	 * Description  : Start Method to run query and get Grants
	 * Parameters   : bc Batchable Context instance
	 * Return Type  : Database.QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		Set<Id> imGrantIds = new Set<Id>();
		for (IM_Grant__c imGrant : [SELECT Id FROM IM_Grant__c WHERE Id NOT IN (SELECT IM_Grant__c FROM IM_Budget_Grant__c) AND Id NOT IN (SELECT IM_Grant__c FROM IM_Non_Budget_Grant__c) WITH SYSTEM_MODE LIMIT 50000]) {
            imGrantIds.add(imGrant.Id);
        }
		query = 'SELECT Id FROM IM_Grant__c WHERE Id IN :imGrantIds OR Deleted__c = true';
		return Database.getQueryLocator(query, AccessLevel.SYSTEM_MODE);
	}

	/**
	 * Description  : Execute Method to hard delete IM Grants
	 * Parameters   : bc Batchable Context instance, List<IM_Grant__c> imGrantsToDelete
	 * Return Type  : None
	 */
	public void execute(Database.BatchableContext bc, List<IM_Grant__c> imGrantsToDelete) {
		BBApps_Crud.doDeleteWithHandling(
			imGrantsToDelete,
			false,
			new BBApps_ErrorCustomFields(ERR_DELETE_IM_GRANTS)
		);
	}

	/**
	 * Description  : Finish Method to execute post sync logic
	 * Parameters   : Batchable Context instance
	 * Return Type  : None
	 */
	public void finish(Database.BatchableContext ct) {
	}
}