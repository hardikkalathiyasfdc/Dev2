/**
 * Author : Ravi Bheemreddy
 * Date   : 11/17/2025
 * Description : Test class for AssociationTriggerHandler
 **/
@isTest
public class AssociationTriggerHandlerTest {
	
    @testSetup
    static void dataSetup () {
        Account org = TestDataFactory.getOrg('Test Org');
        insert org;

        Focus_Area__c focusArea = TestDataFactory.createFocusArea('Arts');
        insert as system focusArea;
        
        Association__c association = TestDataFactory.getAssociation('Test Association');
        association.Focus_Area__c = focusArea.Id;
        insert as system association;
        
        Org_Association__c orgAssociation = new Org_Association__c (
        	Organization__c = org.Id,
            Association__c = association.Id,
            From__c = System.today(),
            To__c = System.today()
        );
        
        insert as system orgAssociation;
    }
    
    @isTest
    static void orgAssociationNameUpdateTest () {
        Association__c association = [Select Id from Association__c where Name = 'Test Association' WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals ('Test Association: Test Org', [Select Id, Name from Org_Association__c WITH SYSTEM_MODE LIMIT 1].Name);
        
        Test.startTest();
        association.Name = 'Test Association Updated';
        update as system association;
        Test.stopTest();
        
        System.assertEquals ('Test Association Updated: Test Org', [Select Id, Name from Org_Association__c WITH SYSTEM_MODE LIMIT 1].Name);
    }
}