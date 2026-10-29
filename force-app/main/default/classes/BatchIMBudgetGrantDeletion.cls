/**
 * Author : Gauri Sagane
 * Date   : 11/17/2025
 * Jira   : IM-438
 * Description : This is the batch class to hard delete Budget Grants which are marked as soft deleted
 * Test : BatchIMBudgetGrantDeletionTest
 */

public with sharing class BatchIMBudgetGrantDeletion implements Schedulable, Database.Batchable<sObject> {

	private static final String ERR_DELETE_BUDGET_GRANTS = 'DELETE_BUDGET_GRANTS_FAILED';
	String query;
	public BatchIMBudgetGrantDeletion() {
		query = 'SELECT Id FROM IM_Budget_Grant__c WHERE Deleted__c = true';
	}

	/**
	 * Description  : Used to schedule the batch class
	 * Parameters   : Schedulable Context Instance
	 * Return Type  : None
	 */
	public void execute(SchedulableContext sc) {
		Id batchJobId = Database.executeBatch(this);
	}

	/**
	 * Description  : Start Method to run query and get Budget Grants
	 * Parameters   : bc Batchable Context instance
	 * Return Type  : Database.QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query, AccessLevel.SYSTEM_MODE);
	}

	/**
	 * Description  : Execute Method to hard delete Budget Grants
	 * Parameters   : bc Batchable Context instance, List<IM_Budget_Grant__c> budgetGrantsToDelete
	 * Return Type  : None
	 */
	public void execute(Database.BatchableContext bc, List<IM_Budget_Grant__c> budgetGrantsToDelete) {
		BBApps_Crud.doDeleteWithHandling(
			budgetGrantsToDelete,
			false,
			new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_GRANTS)
		);
	}

	/**
	 * Description  : Finish Method to execute post sync logic
	 * Parameters   : Batchable Context instance
	 * Return Type  : None
	 */
	public void finish(Database.BatchableContext ct) {
		Database.executeBatch(new BatchIMGrantDeletion());
	}
}