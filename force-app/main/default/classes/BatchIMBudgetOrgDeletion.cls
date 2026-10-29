/**
 * Author : Gauri Sagane
 * Date   : 03/02/2026
 * Jira   : IM-518
 * Description : This is the batch class to hard delete Budget Orgs which are marked as soft deleted
 * Test : BatchIMBudgetOrgDeletionTest
 * ChangeLog :
 */

public with sharing class BatchIMBudgetOrgDeletion implements Schedulable, Database.Batchable<sObject> {

	private static final String ERR_DELETE_BUDGET_ORGS = 'DELETE_BUDGET_ORGS_FAILED';
	String query;

    public BatchIMBudgetOrgDeletion() {
		query = 'SELECT Id FROM IM_Budget_Org__c WHERE Id NOT IN (SELECT Budget_Org__c FROM IM_Budget_Grant__c) AND Deleted__c = true';
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
	 * Description  : Start Method to run query and get Budget Orgs
	 * Parameters   : bc Batchable Context instance
	 * Return Type  : Database.QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query, AccessLevel.SYSTEM_MODE);
	}

	/**
	 * Description  : Execute Method to hard delete Budget Orgs which are marked as soft deleted
	 * Parameters   : bc Batchable Context instance, List<IM_Budget_Org__c> budgetOrgsToDelete
	 * Return Type  : None
	 */
	public void execute(Database.BatchableContext bc, List<IM_Budget_Org__c> budgetOrgsToDelete) {
		BBApps_Crud.doDeleteWithHandling(
			budgetOrgsToDelete,
			false,
			new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_ORGS)
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