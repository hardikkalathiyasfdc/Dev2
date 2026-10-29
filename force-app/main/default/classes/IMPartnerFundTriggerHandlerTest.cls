@isTest
public with sharing class IMPartnerFundTriggerHandlerTest {

    @testSetup static void setup() {
        TestDataFactory.createInitiativeBaseData();
        
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
        IM_Budget_Row__c budRow = TestDataFactory.createBudgetRow(budget.Id);
        budgetedInitiative.Current_Budget__c = budget.Id;
        budgetedInitiative.Approved__c = true;
        budgetedInitiative.Approved_Date__c = System.today();
        budgetedInitiative.Status__c = 'Ongoing';
        budgetedInitiative.Partner_Funds__c = true;
        update budgetedInitiative;
    }

    @isTest
    public static void testBeforeInsert() {
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
        Test.startTest();
        IM_Funding_Source__c parnterFund = new IM_Funding_Source__c(Partner__c = 'Gates', Amount__c = 1000, Budget__c = budget.Id);
        insert parnterFund;
        IM_Funding_Source__c pf = [SELECT Name FROM IM_Funding_Source__c WHERE Id = :parnterFund.Id];
        Test.stopTest();
        Assert.areEqual('Gates', pf.Name);
    }


    @isTest
    public static  void testBeforeUpdate() {
        List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
        Test.startTest();
        IM_Funding_Source__c parnterFund = new IM_Funding_Source__c(Partner__c = 'Gates', Amount__c = 1000, Budget__c = budget[0].Id);
        insert parnterFund;

        parnterFund.Partner__c = 'Agerup';
        update parnterFund;

        IM_Funding_Source__c pf = [SELECT Name FROM IM_Funding_Source__c WHERE Id = :parnterFund.Id];
        Test.stopTest();
        Assert.areEqual('Agerup', pf.Name);
    }
    
    @isTest
    public static  void testPartnerFundSummary() {
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
        IM_Funding_Source__c parnterFund = new IM_Funding_Source__c(Partner__c = 'Gates', Allocated_Amount__c = 1000, Amount__c = 1000, Budget__c = budget.Id);
        insert parnterFund;	
        Test.startTest();
        	parnterFund.Allocated_Amount__c = 2000;
        	update parnterFund;
        	IM_Budget__c updatedBudget = [SELECT Partner_Fund_Summary__c FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
        	Assert.areEqual('$2k from Gates is included in the number.', updatedBudget.Partner_Fund_Summary__c);
        Test.stopTest();
    }
}