/**
 * Author : Gauri Sagane
 * Date   : 12/24/2025
 * Jira   : IM-473
 * Description : This is the batch class to hard delete Non Budget Grant Periods which have amount zero
 * Test : BatchIMNonBudgetGrantPeriodDeletionTest
 */

public with sharing class BatchIMNonBudgetGrantPeriodDeletion implements Schedulable, Database.Batchable<sObject> {

	private static final String ERR_DELETE_NON_BUDGET_GRANT_PERIODS = 'DELETE_NON_BUDGET_GRANT_PERIODS_FAILED';
	String query;
    
	public BatchIMNonBudgetGrantPeriodDeletion() {
		query = 'SELECT Id FROM IM_Non_Budget_Grant_Period__c WHERE Total_Paid_Amount_Local__c = 0 AND Total_Scheduled_Amount_Local__c = 0 WITH SYSTEM_MODE';
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
	 * Description  : Start Method to run query and get Non Budget Grant Periods
	 * Parameters   : bc Batchable Context instance
	 * Return Type  : Database.QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	/**
	 * Description  : Execute Method to hard delete Non Budget Grant Periods
	 * Parameters   : bc Batchable Context instance, List<IM_Non_Budget_Grant_Period__c> nonBudgetGrantPeriodsToDelete
	 * Return Type  : None
	 */
	public void execute(Database.BatchableContext bc, List<IM_Non_Budget_Grant_Period__c> nonBudgetGrantPeriodsToDelete) {
		BBApps_Crud.doDeleteWithHandling(
			nonBudgetGrantPeriodsToDelete,
			false,
			new BBApps_ErrorCustomFields(ERR_DELETE_NON_BUDGET_GRANT_PERIODS)
		);
	}

	/**
	 * Description  : Finish Method to execute post sync logic
	 * Parameters   : Batchable Context instance
	 * Return Type  : None
	 */
	public void finish(Database.BatchableContext ct) {
		Database.executeBatch(new BatchIMNonBudgetGrantDeletion());
	}
}