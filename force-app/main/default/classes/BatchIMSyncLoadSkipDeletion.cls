/**
 * Author : Gauri Sagane
 * Date   : 12/22/2025
 * Jira   : IM-471
 * Description : This is the batch class to hard delete IM Sync Load Skip Records (Logs for Reverse Sync Failures)
 * Test : BatchIMSyncLoadSkipDeletionTest
 */

public with sharing class BatchIMSyncLoadSkipDeletion implements Schedulable, Database.Batchable<sObject> {

	private static final String ERR_DELETE_SYNC_LOAD_SKIPS = 'DELETE_SYNC_LOAD_SKIPS_FAILED';
	String query;
	public BatchIMSyncLoadSkipDeletion() {
		query = 'SELECT Id FROM IM_Sync_Load_Skip__c';
	}

	/**
	 * Description  : Used to schedule the batch class
	 * Parameters   : Schedulable Context Instance
	 * Return Type  : None
	 */
	public void execute(SchedulableContext sc) {
		Id batchJobId = Database.executeBatch(this, 2000);
	}

	/**
	 * Description  : Start Method to run query and get IM Sync Load Skip Records
	 * Parameters   : bc Batchable Context instance
	 * Return Type  : Database.QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query, AccessLevel.SYSTEM_MODE);
	}

	/**
	 * Description  : Execute Method to hard delete Sync Load Skip Records
	 * Parameters   : bc Batchable Context instance, List<IM_Sync_Load_Skip__c> syncLoadSkipsToDelete
	 * Return Type  : None
	 */
	public void execute(Database.BatchableContext bc, List<IM_Sync_Load_Skip__c> syncLoadSkipsToDelete) {
		BBApps_Crud.doDeleteWithHandling(
			syncLoadSkipsToDelete,
			false,
			new BBApps_ErrorCustomFields(ERR_DELETE_SYNC_LOAD_SKIPS)
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