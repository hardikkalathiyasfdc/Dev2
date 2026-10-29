/*
Author     : Sai Bhargav Thotakura
Date       : 21st March 2025
Jira       : IM-139
Description: Use this class to fetch related budget and non-budget grant records for the given imgrant id
Test Class : IMBudgetGrantListControllerTest
ChangeLog  : Gauri - IM-295: Added isActive condition to query to show only active budget grants
			 Gauri - IM-552: Added method to fetch related non-budget grants for the given imgrant id
*/
public with sharing class IMBudgetGrantListController {

	/**
	 * Description  : Fetch the related budget grant records for the give imgrant id
	 * Parameters   : Accepts Id - imGrant Id
	 * Return Type  : Returns Budget Grant List of records
	 */
	@AuraEnabled
	public static Map<String, Object> getRelatedBudgetGrants(Id imGrantId) {
		Map<String, Object> result = new Map<String, Object>();
		// Query Budget Grants
        List<IM_Budget_Grant__c> budgetGrants = [
            SELECT Id, Budget_Grant_Name__c, Budget_Org__r.Organization__r.Name,
                   Unique_Identifier__c, IM_Grant__r.Currency__r.Name,
                   Budget__r.Initiative__c, Budget__r.Initiative__r.Name,
                   Name, Budget_Amount_USD__c, Budget_Amount_Local__c





            FROM IM_Budget_Grant__c
            WHERE IM_Grant__c = :imGrantId AND Is_Active__c = TRUE AND Deleted__c = FALSE
			WITH SYSTEM_MODE
        ];
        
        // Query Non Budget Grant
		List<IM_Non_Budget_Grant__c> nonBudgetGrants = [
            SELECT Id, Initiative__c, Initiative__r.Name, IM_Grant__r.Currency__r.Name, IM_Grant__r.Partner_Org__c, 
				   IM_Grant__r.Partner_Org__r.Name, Budget_Amount_USD__c, Budget_Amount_Local__c
            FROM IM_Non_Budget_Grant__c
            WHERE IM_Grant__c = :imGrantId
            WITH SYSTEM_MODE
        ];

		result.put('budgetGrants', budgetGrants);
		result.put('nonBudgetGrants', nonBudgetGrants);
		return result;
	}
}