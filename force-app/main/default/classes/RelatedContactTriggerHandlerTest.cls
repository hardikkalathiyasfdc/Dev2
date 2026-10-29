@isTest
public class RelatedContactTriggerHandlerTest {
    
    private static Contact createContact() {
        Contact c =  TestDataFactory.getContact('Contact');
        c.FirstName = 'Test';
        c.Email = 'testEmail@gmail.com';
        insert as system c;
        return c;
    }
    
    @isTest
    static void allowFirstPrimaryRelatedContact() {
        Contact c = createContact();
        Campaign testCampaign  = TestDataFactory.createCampaign('Test');
        CampaignMember mem = TestDataFactory.createCampaignMember(testCampaign.Id, c.Id);
        Related_Contact__c rc = new Related_Contact__c(
            Main_Contact__c = c.Id,
            Events_Primary_Staff_Contact__c = true,
            Related_Contact__c = c.Id
        );
        
        Test.startTest();
        insert as system rc;
        Test.stopTest();
        
        System.assertNotEquals(null, rc.Id, 'Primary related contact should be inserted.');
    }
    
    @isTest
    static void blockSecondPrimaryOnInsert() {
        Contact c = createContact();
        
        insert as system new Related_Contact__c(
            Main_Contact__c = c.Id,
            Events_Primary_Staff_Contact__c = true
        );
        
        Related_Contact__c secondPrimary = new Related_Contact__c(
            Main_Contact__c = c.Id,
            Events_Primary_Staff_Contact__c = true
        );
        
        Test.startTest();
        try {
            insert as system secondPrimary;
            System.assert(false, 'Second primary insert should fail.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('There is already an Events Primary Staff Contact selected for this contact.'),
                'Expected validation error not thrown.'
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void blockUpdateToPrimary() {
        Contact c = createContact();
        
        insert as system new Related_Contact__c(
            Main_Contact__c = c.Id,
            Events_Primary_Staff_Contact__c = true
        );
        
        Related_Contact__c rc = new Related_Contact__c(
            Main_Contact__c = c.Id,
            Events_Primary_Staff_Contact__c = false
        );
        insert as system rc;
        
        rc.Events_Primary_Staff_Contact__c = true;
        
        Test.startTest();
        try {
            update as system rc;
            System.assert(false, 'Update to primary should fail.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('There is already an Events Primary Staff Contact selected for this contact.'),
                'Expected validation error not thrown.'
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void allowUpdateWhenPrimaryUnchanged() {
        Contact c = createContact();
        
        Related_Contact__c rc = new Related_Contact__c(
            Main_Contact__c = c.Id,
            Events_Primary_Staff_Contact__c = true
        );
        insert as system rc;
        
        rc.Relationship__c = 'Test';
        
        Test.startTest();
        update as system rc;
        Test.stopTest();
        
        System.assert(true, 'Update should succeed when primary flag is unchanged.');
    }
    
    @isTest
    static void afterStaffDelete() {
        Contact c = createContact();
        Campaign testCampaign  = TestDataFactory.createCampaign('Test');
        testCampaign.EventStatus__c  ='Upcoming';
        testCampaign.RecordTypeId  = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(Assets.CAMPAIGN_RECORDTYPE_DEVENAME_EVENT).getRecordTypeId();
        update as system testCampaign;
        CampaignMember mem = TestDataFactory.createCampaignMember(testCampaign.Id, c.Id);
        mem.CC_Addresses__c = 'testEmail@gmail.com';
        update as system mem;
        Related_Contact__c rc = new Related_Contact__c(
            Main_Contact__c = c.Id,
            Events_Primary_Staff_Contact__c = true,
            Related_Contact__c = c.Id
        );
        insert as system rc;
        
        
        Test.startTest();
        delete as system rc;
        Test.stopTest();
        
    }
}