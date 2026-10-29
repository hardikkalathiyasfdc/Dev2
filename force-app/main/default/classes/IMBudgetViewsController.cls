/**
* Author : Gauri Sagane
* Date   : 02/26/2025
* Jira   : IM-117
* Description : This class is used to download different Budget Views and corresponding column entries
* Test : IMBudgetViewsControllerTest
*/

public with sharing class IMBudgetViewsController {

    public static BudgetWrapper budgetDataRecord = new BudgetWrapper();
    public static TemplateWrapper templateWrapperRec;
    public static Map<String, List<AggregateResult>> aggregateDataMap = new Map<String, List<AggregateResult>>();
    private static final String ERR_GET_BUDGET = 'GET_BUDGET_FAILED';
    private static final String ERR_GET_BUDGET_TEMPLATE = 'GET_BUDGET_TEMPLATE_FAILED';
    private static final String ERR_GET_DATA = 'GET_DATA_FAILED';

    /**
    * Description : Method to get Budget
    * Parameters : budgetId String
    * Return Type : IM_Budget__c
    */
    @AuraEnabled(cacheable=true)
    public static IM_Budget__c getBudget(String budgetId){
        try{
            IM_Budget__c budget = [SELECT Id, Name, Component__c, SubComponent__c, Geography__c, Partner_Partner_Role__c,
                                    Partner__c, Unique_Identifier__c, Partner_Role__c, Type_of_Work__c, Budget_Term_Years__c
                                    FROM IM_Budget__c
                                    WHERE Id = :budgetId
                                    WITH SYSTEM_MODE];
            return budget;
        }catch(Exception e){
            BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_BUDGET));
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * Description : Method to get Budget views template
    * Parameters : budgetId String
    * Return Type : TemplateWrapper
    */
    @AuraEnabled
    public static TemplateWrapper getBudgetTemplate(String budgetId){
        try {

            Template__c tempRec = IMUtil.getTemplate(Assets.BUDGET_VIEWS_TEMPLATE);
            if(tempRec!=null){
                templateWrapperRec = new TemplateWrapper();
                templateWrapperRec.metadata = tempRec.Metadata__c ?? null;
                if(tempRec.File_Id__c!=null){
                    ContentVersion cv = IMUtil.getContentVersion(tempRec.File_Id__c);
                    templateWrapperRec.template = EncodingUtil.base64Encode(cv.VersionData);
                }else{
                    throw new AuraHandledException(Assets.NO_FILE_PRESENT);
                }
            }else{
                throw new AuraHandledException(Assets.NO_TEMPLATES_FOUND);
            }
        } catch (Exception error) {
            BBApps_ErrorHandler.logErrors(error, new BBApps_ErrorCustomFields(ERR_GET_BUDGET_TEMPLATE));
            throw new AuraHandledException(Assets.SYS_EXCPETION+error.getMessage());
        }
        return templateWrapperRec;
    }

    /**
    * Description : Method to get aggregate data for each tab
    * Parameters : budgetId String, tabToColsMapping String
    * Return Type : BudgetWrapper
    */
    @AuraEnabled(cacheable=true)
    public static BudgetWrapper getData(String budgetId, String tabToColsMapping){
        try{

            List<IM_Budget_Period__c> budgetPeriods = IMUtil.getBudgetPeriods(budgetId);
            fillBudgetPeriodData(budgetPeriods);

            Map<String, List<String>> tabToColsMap = (Map<String, List<String>>) JSON.deserialize(tabToColsMapping, Map<String, List<String>>.class);

            for(String tabName : tabToColsMap.keySet()){
                List<String> selectedColumns = tabToColsMap.get(tabName);
                String query = 'SELECT ';
                for(Integer i=0; i<selectedColumns.size(); i++){
                    Integer colNumber = i+1;
                    String columnAlias = ' column' + colNumber;
                    query += selectedColumns[i] + columnAlias + ', ';
                }
                query += ' SUM(Period_1_Amount__c) period1, SUM(Period_2_Amount__c) period2, '
                        +'SUM(Period_3_Amount__c) period3, SUM(Period_4_Amount__c) period4, SUM(Period_5_Amount__c) period5, '
                        +'SUM(Period_6_Amount__c) period6, SUM(Period_7_Amount__c) period7, SUM(Period_8_Amount__c) period8, '
                        +'SUM(Period_9_Amount__c) period9, SUM(Period_10_Amount__c) period10, SUM(Total_Amount__c) totalAmount '
                        +'From IM_Budget_Row__c WHERE Budget__c = :budgetId GROUP BY ';
                if(selectedColumns != null){
                    query += String.join(selectedColumns, ',');
                }
                query += ' ORDER BY SUM(Total_Amount__c) DESC';
                List<AggregateResult> groupedResults = new List<AggregateResult>();
                groupedResults = Database.query(query, AccessLevel.SYSTEM_MODE);
                aggregateDataMap.put(tabName, groupedResults);
            }
            budgetDataRecord.aggregateDataMap = aggregateDataMap;
            return budgetDataRecord;
        }catch(Exception e){
            BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_DATA));
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * Description : Method to fill budget period data
    * Parameters : budgetPeriods List<IM_Budget_Period__c>
    * Return Type : void
    */
    private static void fillBudgetPeriodData(List<IM_Budget_Period__c> budgetPeriods){
        Map<String, String> budgetPeriodMap = new Map<String, String>();
        if(budgetPeriods.size()>0){
            for(IM_Budget_Period__c budgetPeriod : budgetPeriods){
                if(!budgetPeriodMap.containsKey(String.valueOf(budgetPeriod.Period__c))){
                    budgetPeriodMap.put(String.valueOf(budgetPeriod.Period__c), budgetPeriod.Period_Label__c);
                }
            }
        }
        budgetDataRecord.budgetPeriodsMap = budgetPeriodMap;
    }

    /**
    * Description    : BudgetWrapper contains the data to fill the Budget Excel
    * Parameters     : None
    * Return Type    : None
    */
    public class BudgetWrapper {
        // Stores the excel sheet name and corresponding aggregate result to be filled in sheet
        // Example <'Sheet 1', List<AggregateResult>>
        @AuraEnabled public Map<String, List<AggregateResult>> aggregateDataMap;

        // Stores the budget period and corresponding label
        // Example <'1', '2025-2026'>
        @AuraEnabled public Map<String, String> budgetPeriodsMap;
    }

    /**
    * Description    : TemplateWrapper contains the budget Template details
    * Parameters     : None
    * Return Type    : None
    */
    public class TemplateWrapper {
        @AuraEnabled public String metadata;
        @AuraEnabled public String template;
    }
}