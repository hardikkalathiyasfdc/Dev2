/**
 * Author : Ravi Bheemreddy
 * Description : Test class for OrgAssociationTriggerHandler
 **/
@isTest
public class OrgAssociationTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account org = TestDataFactory.getOrg('Test Org');
        insert as system org;
        
        Focus_Area__c focusArea = TestDataFactory.createFocusArea('Arts');
        insert as system focusArea;

        Association__c association = TestDataFactory.getAssociation('Test Association');
        association.Focus_Area__c = focusArea.Id;
        insert as system association;
    }
    
    @isTest
    static void testOrgAssociationNameOnInsert() {
        Account org = [SELECT Id, Name FROM Account WITH SYSTEM_MODE LIMIT 1];
        Association__c association = [SELECT Id, Name FROM Association__c WITH SYSTEM_MODE LIMIT 1];
        
        Test.startTest();
        Org_Association__c orgAssociation = new Org_Association__c(
            Organization__c = org.Id,
            Association__c = association.Id,
            From__c = System.today(),
            To__c = System.today()
        );
        insert as system orgAssociation;
        Test.stopTest();
        
        Org_Association__c insertedOrgAssoc = [
            SELECT Id, Name 
            FROM Org_Association__c 
            WHERE Id = :orgAssociation.Id
            WITH SYSTEM_MODE
        ];
        
        String expectedName = association.Name + ': ' + org.Name;
        System.assertEquals(expectedName, insertedOrgAssoc.Name, 
                           'Org Association name should be set correctly on insert');
    }
    
    @isTest
    static void testOrgAssociationNameOnAssociationChange() {
        Account org = [SELECT Id, Name FROM Account WITH SYSTEM_MODE LIMIT 1];
        Association__c association = [SELECT Id, Name FROM Association__c WITH SYSTEM_MODE LIMIT 1];
        Focus_Area__c focusArea = [SELECT Id FROM Focus_Area__c WITH SYSTEM_MODE LIMIT 1];
        
        Association__c newAssociation = TestDataFactory.getAssociation('New Test Association');
        newAssociation.Focus_Area__c = focusArea.Id;
        insert as system newAssociation;
        
        Org_Association__c orgAssociation = new Org_Association__c(
            Organization__c = org.Id,
            Association__c = association.Id,
            From__c = System.today(),
            To__c = System.today()
        );
        insert as system orgAssociation;
        
        Test.startTest();
        orgAssociation.Association__c = newAssociation.Id;
        update as system orgAssociation;
        Test.stopTest();
        
        Org_Association__c updatedOrgAssoc = [
            SELECT Id, Name 
            FROM Org_Association__c 
            WHERE Id = :orgAssociation.Id
            WITH SYSTEM_MODE
        ];
        
        String expectedName = newAssociation.Name + ': ' + org.Name;
        System.assertEquals(expectedName, updatedOrgAssoc.Name, 
                           'Org Association name should be updated when Association changes');
    }
    
    @isTest
    static void testOrgAssociationNameOnOrganizationChange() {
        Account org = [SELECT Id, Name FROM Account WITH SYSTEM_MODE LIMIT 1];
        Association__c association = [SELECT Id, Name FROM Association__c WITH SYSTEM_MODE LIMIT 1];
        
        Account newOrg = TestDataFactory.getOrg('New Test Org');
        insert as system newOrg;
        
        Org_Association__c orgAssociation = new Org_Association__c(
            Organization__c = org.Id,
            Association__c = association.Id,
            From__c = System.today(),
            To__c = System.today()
        );
        insert as system orgAssociation;
        
        Test.startTest();
        orgAssociation.Organization__c = newOrg.Id;
        update as system orgAssociation;
        Test.stopTest();
        
        Org_Association__c updatedOrgAssoc = [
            SELECT Id, Name 
            FROM Org_Association__c 
            WHERE Id = :orgAssociation.Id
            WITH SYSTEM_MODE
        ];
        
        String expectedName = association.Name + ': ' + newOrg.Name;
        System.assertEquals(expectedName, updatedOrgAssoc.Name, 
                           'Org Association name should be updated when Organization changes');
    }
    
    @isTest
    static void testOrgAssociationNameTruncation() {
        Account org = TestDataFactory.getOrg('This is a very long organization name that will cause truncation');
        insert as system org;

        Focus_Area__c focusArea = [SELECT Id FROM Focus_Area__c WITH SYSTEM_MODE LIMIT 1];
        
        Association__c association = TestDataFactory.getAssociation('This is a very long association name');
        association.Focus_Area__c = focusArea.Id;
        insert as system association;
        
        Test.startTest();
        Org_Association__c orgAssociation = new Org_Association__c(
            Organization__c = org.Id,
            Association__c = association.Id,
            From__c = System.today(),
            To__c = System.today()
        );
        insert as system orgAssociation;
        Test.stopTest();
        
        Org_Association__c insertedOrgAssoc = [
            SELECT Id, Name 
            FROM Org_Association__c 
            WHERE Id = :orgAssociation.Id
            WITH SYSTEM_MODE
        ];
        
        System.assert(insertedOrgAssoc.Name.length() <= 80, 
                     'Org Association name should be truncated to 80 characters');
        System.assert(insertedOrgAssoc.Name.endsWith('...'), 
                     'Truncated name should end with ...');
    }
}