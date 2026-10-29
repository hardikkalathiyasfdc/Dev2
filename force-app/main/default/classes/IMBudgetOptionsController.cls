/**
 * Author : Gauri Sagane
 * Date   : 02/03/2025
 * Jira   : IM-105
 * Description : This class is used to update Budget Options and corresponding column entries
 * Test : IMBudgetOptionsControllerTest
 */

public with sharing class IMBudgetOptionsController {

	private static final String ERR_GET_BUDGET = 'GET_BUDGET_FAILED';
	private static final String ERR_GET_BUDGET_ROWS = 'GET_BUDGET_ROWS_FAILED';
	private static final String ERR_UPDATE_BUDGET = 'BUDGET_UPDATE_FAILED';
	private static final String ERR_UPDATE_BUDGET_ROWS = 'BUDGET_ROWS_UPDATE_FAILED';
	private static final String ERR_DELETE_BUDGET_CHILDREN  = 'BUDGET_CHILDREN_DELETE_FAILED';
	private static final String ERR_DELETE_BUDGET_ROWS = 'BUDGET_ROWS_DELETE_FAILED';
	private static final String ERR_INSERT_BUDGET_ROWS = 'BUDGET_ROWS_INSERT_FAILED';

	/**
	 * Description : Method to get Budget
	 * Parameters : budgetId String
	 * Return Type : IM_Budget__c
	 */
	@AuraEnabled
	public static IM_Budget__c getBudget(String budgetId) {
		try {
			IM_Budget__c budget = [
				SELECT
					Id,
					Budget_Categories__c,
					Component__c,
					SubComponent__c,
					Geography__c,
					Partner_Partner_Role__c,
					Partner__c,
					Partner_Role__c,
					SubPartner_SubPartner_Type__c,
					Sub_Partner__c,
					Sub_Partner_Type__c,
					Type_of_Work__c,
					Unique_Identifier__c,
					Duration_Run_Rate__c,
					Payee_Fiscal_Sponsor__c,
					Partner_Fund__c,
					Initiative__r.Partner_Funds__c,
					Initiative__r.Approved__c,
					Initiative__r.Initiative_Type__c,
					Initiative__r.Amendment_of__r.Current_Budget__c,
					Disable_Budget_Options__c
				FROM IM_Budget__c
				WHERE Id = :budgetId
				WITH SYSTEM_MODE
			];
			return budget;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_BUDGET));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to update Budget
	 * Parameters : budget IM_Budget__c
	 * Return Type : void
	 */
	@AuraEnabled
	public static void updateBudget(IM_Budget__c budget) {
		try {
			BBApps_Crud.doUpdate(
				budget,
				false
			);
		} catch (DMLException e) {
			String errorMessages = '';
			for (Integer i = 0; i < e.getNumDml(); i++) {
				errorMessages += '' + e.getDmlMessage(i);
			}
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET));
			throw new AuraHandledException(errorMessages);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get Budget rows
	 * Parameters : budgetId String
	 * Return Type : List<IM_Budget_Row__c>
	 */
	@AuraEnabled(cacheable=true)
	public static List<IM_Budget_Row__c> getBudgetRows(String budgetId) {
		try {
			List<IM_Budget_Row__c> budgetRows = [
				SELECT
					Id,
					Component__c,
					SubComponent__c,
					Geography__c,
					Payee_Fiscal_Sponsor__c,
					Partner__c,
					Partner_Role__c,
					Sub_Partner__c,
					Type_of_Work__c,
					Unique_Identifier__c,
					Duration_months__c,
					Partner_Fund__c,
					Description__c,
					Sub_Partner_Type__c
				FROM IM_Budget_Row__c
				WHERE Budget__c = :budgetId
				WITH SYSTEM_MODE
			];
			return budgetRows;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_BUDGET_ROWS));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to update Budget rows
	 * Parameters : budget IM_Budget__c, budgetRows List<IM_Budget_Row__c>, fieldValMap Map<String,Boolean>
	 * Return Type : void
	 */
	@AuraEnabled
	public static void updateBudgetRows(IM_Budget__c budget, List<IM_Budget_Row__c> budgetRows, Map<String, Boolean> fieldValMap) {
		try {
			Boolean isDurationUpdate = false;
			List<String> fieldsToAggregate = new List<String>();
			for (String field : fieldValMap.keySet()) {
				if (!fieldValMap.get(field)) {
					if (field != Assets.DURATION_MONTHS) {
						fieldsToAggregate.add(field);
					}
				}
				if (fieldValMap.get(field) && field != Assets.DURATION_MONTHS) {
					isDurationUpdate = true;
				}
			}
			if (!isDurationUpdate && fieldValMap.get(Assets.DURATION_MONTHS)) {
				List<BBApps_DMLResult> results = BBApps_Crud.doUpdateWithHandling(
                    budgetRows,
                    false,
                    new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET_ROWS)
                );
				if(!processErrors(results)) {
					throw new AuraHandledException('Error while updating budget rows');
				}
			} else {
				createNewBudgetRows(budget.Id, budgetRows, fieldValMap, fieldsToAggregate);
			}
			BBApps_Crud.doUpdateWithHandling(
				budget,
				false,
				new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET)
			);

		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET_ROWS));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to create new Budget rows
	 * Parameters : budgetId String, budgetRows List<IM_Budget_Row__c>, fieldValMap Map<String,Boolean>, fieldsToAggregate List<String>
	 * Return Type : void
	 */
	@AuraEnabled
	public static void createNewBudgetRows(
		String budgetId,
		List<IM_Budget_Row__c> budgetRows,
		Map<String, Boolean> fieldValMap,
		List<String> fieldsToAggregate
	) {
		try {

			Map<String, String> newRowToDescription = new Map<String, String>();
			for (IM_Budget_Row__c row : budgetRows) {
				List<String> keyFields = new List<String>();
				for (String field : fieldsToAggregate) {
					keyFields.add(String.valueOf(row.get(field)));
				}
				String fieldsKey = String.join(keyFields, ',');
				if (newRowToDescription.containsKey(fieldsKey)) {
					newRowToDescription.put(fieldsKey, newRowToDescription.get(fieldsKey) + '. ' + row.Description__c);
				} else {
					newRowToDescription.put(fieldsKey, row.Description__c);
				}
				if (newRowToDescription.get(fieldsKey) != null && newRowToDescription.get(fieldsKey).contains('null')) {
					newRowToDescription.put(fieldsKey, newRowToDescription.get(fieldsKey).remove('null'));
					if (newRowToDescription.get(fieldsKey).startsWith('.')) {
						newRowToDescription.put(fieldsKey, newRowToDescription.get(fieldsKey).remove('.'));
					}
				}
			}

			String query = 'SELECT ';
			if (fieldsToAggregate != null) {
				query += String.join(fieldsToAggregate, ',');
			}
			query +=
				',MAX(Duration_months__c) duration, SUM(Period_1_Amount__c) period1, SUM(Period_2_Amount__c) period2, ' +
				'SUM(Period_3_Amount__c) period3, SUM(Period_4_Amount__c) period4, SUM(Period_5_Amount__c) period5, ' +
				'SUM(Period_6_Amount__c) period6, SUM(Period_7_Amount__c) period7, SUM(Period_8_Amount__c) period8, ' +
				'SUM(Period_9_Amount__c) period9, SUM(Period_10_Amount__c) period10 ' +
				'From IM_Budget_Row__c WHERE Budget__c = :budgetId WITH SYSTEM_MODE GROUP BY ';
			if (fieldsToAggregate != null) {
				query += String.join(fieldsToAggregate, ',');
			}

			List<AggregateResult> groupedResults = new List<AggregateResult>();
			groupedResults = Database.query(query);

			List<IM_Budget_Row__c> budgetRowsToInsert = new List<IM_Budget_Row__c>();
			for (AggregateResult ar : groupedResults) {
				IM_Budget_Row__c budgetRow = new IM_Budget_Row__c();
				budgetRow.Component__c = !fieldValMap.get('Component__c') ? (Id) ar.get('Component__c') : null;
				budgetRow.SubComponent__c = !fieldValMap.get('SubComponent__c') ? (Id) ar.get('SubComponent__c') : null;
				budgetRow.Geography__c = !fieldValMap.get('Geography__c') ? (Id) ar.get('Geography__c') : null;
				budgetRow.Partner__c = !fieldValMap.get('Partner__c') ? (Id) ar.get('Partner__c') : null;
				budgetRow.Partner_Role__c = !fieldValMap.get('Partner_Role__c') ? (String) ar.get('Partner_Role__c') : '';
				budgetRow.Unique_Identifier__c = !fieldValMap.get('Unique_Identifier__c') ? (String) ar.get('Unique_Identifier__c') : '';
				budgetRow.Payee_Fiscal_Sponsor__c = !fieldValMap.get('Payee_Fiscal_Sponsor__c') ? (Id) ar.get('Payee_Fiscal_Sponsor__c') : null;
				budgetRow.Type_of_Work__c = !fieldValMap.get('Type_of_Work__c') ? (String) ar.get('Type_of_Work__c') : '';
				budgetRow.Sub_Partner__c = !fieldValMap.get('Sub_Partner__c') ? (Id) ar.get('Sub_Partner__c') : null;
				budgetRow.Sub_Partner_Type__c = !fieldValMap.get('Sub_Partner_Type__c') ? (String) ar.get('Sub_Partner_Type__c') : '';
				budgetRow.Partner_Fund__c = !fieldValMap.get('Partner_Fund__c') ? (Id) ar.get('Partner_Fund__c') : null;
				budgetRow.Duration_months__c = !fieldValMap.get('Duration_months__c') ? (Decimal) ar.get('duration') : 0;

				budgetRow.Period_1_Amount__c = (Decimal) ar.get('period1');
				budgetRow.Period_2_Amount__c = (Decimal) ar.get('period2');
				budgetRow.Period_3_Amount__c = (Decimal) ar.get('period3');
				budgetRow.Period_4_Amount__c = (Decimal) ar.get('period4');
				budgetRow.Period_5_Amount__c = (Decimal) ar.get('period5');
				budgetRow.Period_6_Amount__c = (Decimal) ar.get('period6');
				budgetRow.Period_7_Amount__c = (Decimal) ar.get('period7');
				budgetRow.Period_8_Amount__c = (Decimal) ar.get('period8');
				budgetRow.Period_9_Amount__c = (Decimal) ar.get('period9');
				budgetRow.Period_10_Amount__c = (Decimal) ar.get('period10');

				budgetRow.Budget__c = budgetId;
				budgetRowsToInsert.add(budgetRow);
			}

			for (IM_Budget_Row__c row : budgetRowsToInsert) {
				List<String> keyFields = new List<String>();
				for (String field : fieldsToAggregate) {
					keyFields.add(String.valueOf(row.get(field)));
				}
				row.Description__c = newRowToDescription.get(String.join(keyFields, ','));
			}
			
			BBApps_Crud.doDeleteWithHandling(
				budgetRows,
				false,
				new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_ROWS)
			);

			List<BBApps_DMLResult> results = BBApps_Crud.doInsertWithHandling(
				budgetRowsToInsert,
				false,
				new BBApps_ErrorCustomFields(ERR_INSERT_BUDGET_ROWS)
			);
			if(!processErrors(results)) {
				throw new AuraHandledException('Error while inserting budget rows');
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_INSERT_BUDGET_ROWS));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to handle errors
	 * Parameters : results List<BBApps_DMLResult>
	 * Return Type : Boolean
	 */
	private static Boolean processErrors(List<BBApps_DMLResult> results) {
		Integer recordsFailed = 0;
		try {
		for (BBApps_DMLResult result : results) {
			if (!result.isSuccess()) {
					recordsFailed++;
					break;
			}
		}
		return recordsFailed > 0 ? false : true;
		} catch (Exception e) {
			throw new AuraHandledException('Error while processing SaveResults: ' + e.getMessage());
		}

	}

	/**
	 * Description 	: Method to delete child records based on Budget Id.
	 * Parameters 	: budget IM_Budget__c
	 * Return Type 	: void
	 */
	@AuraEnabled
	public static void deleteBudgetChildRecords(IM_Budget__c budget, Map<String, Boolean> fieldValMap) {
		String budgetId = budget.Id;
		try {
			Map<Id, SObject> recordsToDelete = new Map<Id, SObject>();
			List<String> innerQueries = new List<String>();
			List<String> componentTypes = new List<String>();
			List<String> orgTypes = new List<String>();

			if(fieldValMap.get('Component__c')) {
				componentTypes.add(Assets.COMPONENT);
			}
			if(fieldValMap.get('SubComponent__c')) {
				componentTypes.add(Assets.SUB_COMPONENT);
			}
			if(fieldValMap.get('Payee_Fiscal_Sponsor__c')) {
				orgTypes.add(Assets.PAYEE);
			}
			if(fieldValMap.get('Partner__c')) {
				orgTypes.add(Assets.PARTNER);
			}
			if(fieldValMap.get('Sub_Partner__c')) {
				orgTypes.add(Assets.SUB_PARTNER);
			}

			if(!componentTypes.isEmpty()) {
				innerQueries.add('(SELECT Id FROM Components__r WHERE Type__c IN :componentTypes)');
			}
			if(fieldValMap.get('Geography__c')) {
				innerQueries.add('(SELECT Id FROM Geography__r)');
			}
			if(!orgTypes.isEmpty()) {
				innerQueries.add('(SELECT Id FROM Budget_Org__r WHERE Type__c IN :orgTypes)');
			}
			if(fieldValMap.get('Partner_Fund__c')) {
				innerQueries.add('(SELECT Id FROM Partner_Funds__r)');
			}
			if(!innerQueries.isEmpty()) {
				String query = 'SELECT Id, ' + String.join(innerQueries, ', ') + ' FROM IM_Budget__c WHERE Id = :budgetId';
				List<IM_Budget__c> budgets = Database.query(query, AccessLevel.SYSTEM_MODE);
				if(!budgets.isEmpty()) {
					IM_Budget__c budgetRecord = budgets[0];

					if(!componentTypes.isEmpty()) {
						recordsToDelete.putAll(budgetRecord.Components__r);
					}
					if(!budget.Geography__c) {
						recordsToDelete.putAll(budgetRecord.Geography__r);
					}
					if(!orgTypes.isEmpty()) {
						recordsToDelete.putAll(budgetRecord.Budget_Org__r);
					}
					if(!budget.Partner_Fund__c) {
						recordsToDelete.putAll(budgetRecord.Partner_Funds__r);
					}
				}
			}
			if(!recordsToDelete.isEmpty()) {
				BBApps_Crud.doDeleteWithHandling(
                    recordsToDelete.values(),
                    false,
                    new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_CHILDREN)
                );
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_CHILDREN));
			throw new AuraHandledException('Error while deleting child records of Budget: ' + e.getMessage());
		}
	}
}