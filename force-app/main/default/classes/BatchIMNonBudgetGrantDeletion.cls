/**
 * Author : Gauri Sagane
 * Date   : 12/19/2025
 * Jira   : IM-438
 * Description : This is the batch class to hard delete Non Budget Grants which have amount zero
 * Test : BatchIMNonBudgetGrantDeletionTest
 */

public with sharing class BatchIMNonBudgetGrantDeletion implements Schedulable, Database.Batchable<sObject> {

	private static final String ERR_DELETE_NON_BUDGET_GRANTS = 'DELETE_NON_BUDGET_GRANTS_FAILED';
	String query;
    
	public BatchIMNonBudgetGrantDeletion() {
		query = 'SELECT Id FROM IM_Non_Budget_Grant__c WHERE Id NOT IN (SELECT Non_Budget_Grant__c FROM IM_Non_Budget_Grant_Period__c)';
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
	 * Description  : Start Method to run query and get Non Budget Grants
	 * Parameters   : bc Batchable Context instance
	 * Return Type  : Database.QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query, AccessLevel.SYSTEM_MODE);
	}

	/**
	 * Description  : Execute Method to hard delete Non Budget Grants
	 * Parameters   : bc Batchable Context instance, List<IM_Non_Budget_Grant__c> budgetGrantsToDelete
	 * Return Type  : None
	 */
	public void execute(Database.BatchableContext bc, List<IM_Non_Budget_Grant__c> nonBudgetGrantsToDelete) {
		BBApps_Crud.doDeleteWithHandling(
			nonBudgetGrantsToDelete,
			false,
			new BBApps_ErrorCustomFields(ERR_DELETE_NON_BUDGET_GRANTS)
		);
	}

	/**
	 * Description  : Finish Method to execute post sync logic
	 * Parameters   : Batchable Context instance
	 * Return Type  : None
	 */
	public void finish(Database.BatchableContext ct) {
		Database.executeBatch(new BatchIMBudgetGrantDeletion());
	}
}