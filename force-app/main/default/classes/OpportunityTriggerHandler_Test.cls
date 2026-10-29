@isTest
public class OpportunityTriggerHandler_Test {
	
    @testSetup
    static void dataSetup () {
        Account acc = TestDataFactory.getOrg('Test');
        insert as system acc;
        
        Opportunity opp = TestDataFactory.getOpportunity(acc.Id);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Bloomberg_Connects').getRecordTypeId();
        opp.StageName = OpportunityTriggerHandler.OPPORTUNITY_STAGE_PROSPECTING;
        insert as system opp;
    }
    
    @isTest
    static void taskCreationPositiveTest () {
        Opportunity opp = [Select Id from Opportunity WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(3, [Select Id from Task where WhatId =: opp.Id WITH SYSTEM_MODE].size());
        
        Test.startTest();
        opp.StageName = OpportunityTriggerHandler.OPPORTUNITY_STAGE_ONBOARDING;
        update as system opp;
        Test.stopTest();
        
        System.assertEquals(6, [Select Id from Task where WhatId =: opp.Id WITH SYSTEM_MODE].size());
    }
    
    @isTest
    static void taskCreationNegativeTest () {
        Opportunity opp = [Select Id from Opportunity WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(3, [Select Id from Task where WhatId =: opp.Id WITH SYSTEM_MODE].size());
        
        Test.startTest();
        opp.Target_Date__c = System.today();
        update as system opp;
        Test.stopTest();
        
        System.assertEquals(3, [Select Id from Task where WhatId =: opp.Id WITH SYSTEM_MODE].size());
    }
    
    @isTest
    static void goLiveTest () {
        Opportunity opp = [Select Id from Opportunity WITH SYSTEM_MODE LIMIT 1];      

        Test.startTest();
        opp.StageName = OpportunityTriggerHandler.OPPORTUNITY_STAGE_GO_LIVE;
        update as system opp;
        Test.stopTest();     
        Opportunity updatedOpp = [SELECT StageName  FROM Opportunity WHERE Id = :opp.Id WITH SYSTEM_MODE];
        System.assertEquals( OpportunityTriggerHandler.OPPORTUNITY_STAGE_GO_LIVE, updatedOpp.StageName, 'Opportunity Stage should be updated to Go-Live' );
    }
}