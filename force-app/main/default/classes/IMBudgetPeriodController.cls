/**
* Author : Gauri Sagane
* Date   : 12/04/2024
* Jira   : IM-53
* Description : This class provides methods for budget period object.
* ChangeLog   :
* Paddy 	  : 06/15/2026: IM-442: Added logic for error logging framework
* Test 		  : BudgetPeriodControllerTest
*/

public with sharing class IMBudgetPeriodController {

    private static final String ERR_BUDGET_PERIOD_METHOD = 'BUDGET_PERIOD_CONTROLLER_UPDATE_BUDGET_PERIOD_METHOD_FAILED';

    /**
    * Description : Method to get Budget Periods
    * Parameters : budgetId String.
    * Return Type : List<IM_Budget_Period__c>
    */
    @AuraEnabled(cacheable=true)
    public static List<IM_Budget_Period__c> getBudgetPeriods(String budgetId){
        return [SELECT Id, Name, Period__c, Period_Start_Date__c, Period_End_Date__c, Period_Label__c, Period_Total_Amount__c  
                FROM IM_Budget_Period__c
                WHERE Budget__c = :budgetId WITH SYSTEM_MODE
                ORDER BY Period__c];
    }

    /**
    * Description : Method to update Budget Periods
    * Parameters : periodsToUpdate List<IM_Budget_Period__c>.
    * Return Type : void
    */
    @AuraEnabled
    public static void updateBudgetPeriods(List<IM_Budget_Period__c> periodsToUpdate) {
        try {
           BBApps_Crud.doUpdate(periodsToUpdate);







        } catch (Exception e) {
            BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_BUDGET_PERIOD_METHOD));
            throw new AuraHandledException(e.getMessage());
        }
    }
}