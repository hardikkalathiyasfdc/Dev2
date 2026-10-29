/**
* Author             : Paddy
* Date               : 03/20/2025
* Jira               : IM-128
* Description        : This class provides helper methods for budget period object.
* ChangeLog          :
* Paddy on 03/20/2025: IM-129: Added method to populate BudgetPeriod TotalAmount based on Budget Ids.
* Paddy on 06/15/2026: IM-442: Added logic for error logging framework
* Test Class         : IMBudgetPeriodHelperTest
*/
public with sharing class IMBudgetPeriodHelper {

    private static final String ERR_SET_DATE = 'BUDGET_PERIOD_HELPER_SET_DATE_METHOD_FAILED';
    
    /**
    * Description : Method to set Budget Period Start/End dates based on Initiative Start/End dates.
    * Parameters : initiatives Map<Map<Id, IM_Initiative__c>
    * Return Type : void
    */
    public static void setDates(Map<Id, IM_Initiative__c> initiatives) {
        try {
            Set<Id> currentBudgetIds = new Set<Id>();
            List<IM_Budget_Period__c> updateBudgetPeriods = new List<IM_Budget_Period__c>();

            for (IM_Initiative__c initiative : initiatives.values()) {
                currentBudgetIds.add(initiative.Current_Budget__c);
            }

            Map<String, Integer> totalPeriodsByBudget = new Map<String, Integer>();
            List<AggregateResult> aggregateResults = [SELECT Budget__c, COUNT(NAME) totalPeriods FROM IM_Budget_Period__c WHERE Budget__c in :currentBudgetIds WITH SYSTEM_MODE GROUP BY Budget__c];
            for(AggregateResult ar : aggregateResults) {
                totalPeriodsByBudget.put((String)ar.get('Budget__c'), (Integer)ar.get('totalPeriods'));
            }

            //process only if the initiative has a current budget
            if(!currentBudgetIds.isEmpty()) {
                List<IM_Budget_Period__c> budgetPeriods = [SELECT Id, Budget__c, Period__c, Period_Start_Date__c, Budget__r.Initiative__c,
                    Period_End_Date__c FROM IM_Budget_Period__c WHERE Budget__c in :currentBudgetIds WITH SYSTEM_MODE ORDER BY Budget__c, Period__c];
                    
                Date endDate;
                for(IM_Budget_Period__c budgetPeriod : budgetPeriods) {
                    IM_Initiative__c initiative = initiatives.get(budgetPeriod.Budget__r.Initiative__c);
                    Integer numberOfPeriods = totalPeriodsByBudget.get(budgetPeriod.Budget__c);

                    //populate initiative start date for the first period else add one day from the previos period end date 
                    if(budgetPeriod.Period__c == 1) {
                        budgetPeriod.Period_Start_Date__c = initiative.Start_Date__c;
                    } else {
                        budgetPeriod.Period_Start_Date__c = endDate.addDays(1);
                    }

                    //populate initiative end date for the last period else add 12 months (minus one day) from the start date
                    if(budgetPeriod.Period__c == numberOfPeriods) {
                        budgetPeriod.Period_End_Date__c = initiative.End_Date__c;
                        endDate = null;
                    } else {
                        budgetPeriod.Period_End_Date__c = budgetPeriod.Period_Start_Date__c.addMonths(12).addDays(-1);
                        endDate = budgetPeriod.Period_End_Date__c;
                    }

                    updateBudgetPeriods.add(budgetPeriod);
                }
            }
            if(!updateBudgetPeriods.isEmpty()) {
                BBApps_Crud.doUpdate(updateBudgetPeriods);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SET_DATE));
            throw new AuraHandledException(ex.getMessage());
        }

    }
}