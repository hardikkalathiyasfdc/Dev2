/**
* Author            : Paddy
* Date              : 05/28/2025
* Jira              : IM-203
* Description       : Test class for IMBudgetRowHelper.
*/
@isTest
public with sharing class IMBudgetRowHelperTest {
    
    @TestSetup
    static void setup() {
        
        Account org = TestDataFactory.createOrg('Test org');
        
        TestDataFactory.createInitiativeBaseData();
        
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
        
        TestDataFactory.createBudgetPeriods(budget.Id, 3);

        IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
		IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
        IM_Component__c component = TestDataFactory.createComponent(budget.Id);
        IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
        
        IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
        IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, partner.Id, geography.Id);
    }

    @isTest
    public static void testPopulateTotalAmount() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        Map<Id, IM_Geography__c> geographies = new Map<Id, IM_Geography__c>([SELECT Id FROM IM_Geography__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE]);
        
        Test.startTest();
        	IMBudgetRowHelper.populateTotalAmount(new Set<Id>{ budget.Id }, Assets.IM_GEOGRAPHY, new List<String>{ Assets.GEOGRAPHY_FIELD });
        	List<IM_Budget_Row__c> budgetRows = [SELECT Total_Amount__c FROM IM_Budget_Row__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
        	Assert.areEqual(200000, budgetRows[0].Total_Amount__c);
        	IM_Geography__c geography = [SELECT Total_Amount__c FROM IM_Geography__c WHERE Id IN :geographies.keySet() WITH SYSTEM_MODE LIMIT 1];
        	Assert.areEqual(budgetRows[0].Total_Amount__c, geography.Total_Amount__c);
        Test.stopTest();
    }

    @isTest
    public static void testPopulateComponentTotalAmount() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        IM_Budget_Row__c budgetRow = [SELECT Total_Amount__c, Component__c, SubComponent__c FROM IM_Budget_Row__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE LIMIT 1];
        IM_Component__c emptyComponent = new IM_Component__c(Budget__c = budget.Id, Name = 'Empty Component', Type__c = 'Component', External_Id__c = budget.Id + 'Empty Component', Total_Amount__c = 999);
        insert as system emptyComponent;
        update as system new List<IM_Component__c>{
            new IM_Component__c(Id = budgetRow.Component__c, Total_Amount__c = 0),
            new IM_Component__c(Id = budgetRow.SubComponent__c, Total_Amount__c = 0)
        };

        Test.startTest();
        	IMBudgetRowHelper.populateTotalAmount(new Set<Id>{ budget.Id }, Assets.IM_COMPONENT, new List<String>{ Assets.COMPONENT_FIELD, Assets.SUB_COMPONENT_FIELD });
        Test.stopTest();

        Map<Id, IM_Component__c> components = new Map<Id, IM_Component__c>([SELECT Total_Amount__c FROM IM_Component__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE]);
        Assert.areEqual(budgetRow.Total_Amount__c, components.get(budgetRow.Component__c).Total_Amount__c, 'Component should roll up its budget rows');
        Assert.areEqual(budgetRow.Total_Amount__c, components.get(budgetRow.SubComponent__c).Total_Amount__c, 'SubComponent should roll up its budget rows');
        Assert.areEqual(0, components.get(emptyComponent.Id).Total_Amount__c, 'Component without budget rows should be zero');
    }
    
    @isTest
    public static void testPopulatePeriodTotalAmount() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        IM_Budget_Row__c budgetRow = [SELECT Period_1_Amount__c FROM IM_Budget_Row__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
        Test.startTest();
        	budgetRow.Period_1_Amount__c = 200000;
        	update as system budgetRow;
        
        	IM_Budget_Period__c budgetPeriod = [SELECT Period__c, Period_Total_Amount__c
            	FROM IM_Budget_Period__c WHERE Budget__c = :budget.Id AND Period__c = 1 WITH SYSTEM_MODE LIMIT 1];
        Assert.areEqual(200000, budgetPeriod.Period_Total_Amount__c);
        Test.stopTest();
    }
}