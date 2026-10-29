/**
* Author             : Paddy
* Date               : 04/11/2025
* Jira               : IM-129
* Description        : This class provides helper methods for budget row object.
* Test Class         : IMBudgetRowHelperTest
* ChangeLog          :
* Paddy on 07/01/2025: IM-249: updated populateTotalAmount method to include budgetids as param 
                       and query child records based on budget ids.
*/
public with sharing class IMBudgetRowHelper {

    /**
    * Description : Method to set Total Amount based on Budget Row's Total Amount.
    * Parameters  : Set<Id> budgetIds, String objectName, String fieldName
    * Return Type : void
    */
   public static void populateTotalAmount(Set<Id> budgetIds, String objectName, List<String> fieldNames) {
        Map<Id, sObject> recordsToUpdate = new Map<Id, sObject>();
        String soql = 'SELECT Id FROM ' + objectName + ' WHERE Budget__c IN :budgetIds';
        Map<Id, sObject> childRecords = new Map<Id, sObject>(Database.query(soql, AccessLevel.SYSTEM_MODE));
        Set<Id> recordIds = childRecords.keySet();
        String groupByFields = String.join(fieldNames, ', ');
    
        soql = 'SELECT ' + groupByFields + ', SUM(Total_Amount__c) totalAmount FROM IM_Budget_Row__c ';
        soql += 'WHERE Budget__c IN :budgetIds GROUP BY ' + groupByFields;

        List<AggregateResult> aggregateResults = Database.query(soql, AccessLevel.SYSTEM_MODE);

        for(AggregateResult ar : aggregateResults) {
            Decimal amount = (Decimal)ar.get('totalAmount') ?? 0;
            for(String fieldName : fieldNames) {
                Id recordId = (Id)ar.get(fieldName);
                if(recordId == null || !recordIds.contains(recordId)) {
                    continue;
                }
                SObject dataRecord = recordsToUpdate.get(recordId);
                if(dataRecord == null) {
                    dataRecord = recordId.getSobjectType().newSObject(recordId);
                    dataRecord.put('Total_Amount__c', 0);
                    recordsToUpdate.put(recordId, dataRecord);
                }
                dataRecord.put('Total_Amount__c', (Decimal)dataRecord.get('Total_Amount__c') + amount);
            }
        }
        for(Id recordId : recordIds) {
            if(!recordsToUpdate.containsKey(recordId)) {
                SObject dataRecord = recordId.getSobjectType().newSObject(recordId);
                dataRecord.put('Total_Amount__c', 0); //Amount has been removed during Checkin i.e. Amount is zero for TBD.
                recordsToUpdate.put(recordId, dataRecord);
            }
        }
        BBApps_Crud.doUpdate(
            recordsToUpdate.values(),
            false
        );
    }

    /**
    * Description : Method to set Period_Total_Amount__c based on Budget Rows(Budget Id).
    * Parameters : Set<Id> budgetIds
    * Return Type : void
    */
    public static void populatePeriodTotalAmount(Set<Id> budgetIds) {
        List<IM_Budget_Period__c> budgetPeriodsToUpdate = new List<IM_Budget_Period__c>();
        Map<Id, Map<Integer, Decimal>> budgetPeriodAmounts = new Map<Id, Map<Integer, Decimal>>();

        List<AggregateResult> aggregateResults = [SELECT Budget__c, SUM(Period_1_Amount__c),
            SUM(Period_2_Amount__c), SUM(Period_3_Amount__c), 
            SUM(Period_4_Amount__c), SUM(Period_5_Amount__c), 
            SUM(Period_6_Amount__c), SUM(Period_7_Amount__c), 
            SUM(Period_8_Amount__c), SUM(Period_9_Amount__c), SUM(Period_10_Amount__c) 
            FROM IM_Budget_Row__c WHERE Budget__c in :budgetIds WITH SYSTEM_MODE GROUP BY Budget__c];

        for(AggregateResult ar : aggregateResults) {
            Map<Integer, Decimal> periodAmounts = new Map<Integer, Decimal>();
            periodAmounts.put(1, (Decimal)ar.get('expr0'));
            periodAmounts.put(2, (Decimal)ar.get('expr1'));
            periodAmounts.put(3, (Decimal)ar.get('expr2'));
            periodAmounts.put(4, (Decimal)ar.get('expr3'));
            periodAmounts.put(5, (Decimal)ar.get('expr4'));
            periodAmounts.put(6, (Decimal)ar.get('expr5'));
            periodAmounts.put(7, (Decimal)ar.get('expr6'));
            periodAmounts.put(8, (Decimal)ar.get('expr7'));
            periodAmounts.put(9, (Decimal)ar.get('expr8'));
            periodAmounts.put(10, (Decimal)ar.get('expr9'));

            budgetPeriodAmounts.put((Id)ar.get('Budget__c'), periodAmounts);
        }

        List<IM_Budget_Period__c> budgetPeriods = [SELECT Period__c, Period_Total_Amount__c, Budget__c
            FROM IM_Budget_Period__c WHERE Budget__c in :budgetIds WITH SYSTEM_MODE ORDER BY Budget__c, Period__c];

        for (IM_Budget_Period__c period : budgetPeriods) {
            Map<Integer, Decimal> periodAmounts = budgetPeriodAmounts.get(period.Budget__c);
            period.Period_Total_Amount__c = periodAmounts.get(period.Period__c.intValue());
            budgetPeriodsToUpdate.add(period);
        }
        BBApps_Crud.doUpdate(
            budgetPeriodsToUpdate,
            false
        );
    }
}