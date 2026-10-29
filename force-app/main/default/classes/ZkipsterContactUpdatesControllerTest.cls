/**
 * Description : Test class for ZkipsterContactUpdatesController
 * Author : Nishant Bakhrey
 * Last Modified : 08/03/2026
 * JIRA : BRME-6787
**/
@IsTest
public class ZkipsterContactUpdatesControllerTest {


    @IsTest
    static void testController() {
        Account accountRecord = TestDataFactory.createOrg('Test Account');
        Contact contactRecord = TestDataFactory.createContact(accountRecord.Id, 'Original');
        Campaign campaignRecord = TestDataFactory.createCampaign('Test Campaign');
        List<Zkipster_Contact_Update__c> changes = new List<Zkipster_Contact_Update__c>{
            createChange(campaignRecord.Id, contactRecord.Id, 'FirstName', 'First Name', contactRecord.FirstName, 'Updated'),
            createChange(campaignRecord.Id, contactRecord.Id, 'MobilePhone', 'Mobile Phone', null, '+61124567890'),
            createChange(campaignRecord.Id, contactRecord.Id, 'Mobile_Phone_Country_Code__c', 'Mobile Phone Country Code', null, 'Australia(+61)')
        };
        insert changes;
        List<Id> changeIds = new List<Id>();
        for(Zkipster_Contact_Update__c changeRecord : changes) {
            changeIds.add(changeRecord.Id);
        }
        Test.startTest();
        List<Zkipster_Contact_Update__c> pendingChanges = ZkipsterContactUpdatesController.getPendingChanges(campaignRecord.Id);
        String applyResult = ZkipsterContactUpdatesController.applySelectedChanges(changeIds);
        Test.stopTest();
        Contact updatedContact = [
            SELECT FirstName, MobilePhone, Mobile_Phone_Country_Code__c
            FROM Contact
            WHERE Id = :contactRecord.Id
        ];
        List<Zkipster_Contact_Update__c> updatedChanges = [
            SELECT Status__c
            FROM Zkipster_Contact_Update__c
            WHERE Id IN :changeIds
        ];
        System.assertEquals(3, pendingChanges.size());
        System.assertEquals('3 changes were applied to 1 Contact.', applyResult);
        System.assertEquals('Updated', updatedContact.FirstName);
        System.assertEquals('61124567890', updatedContact.MobilePhone.replaceAll('[^0-9]', ''));
        System.assertEquals('Australia(+61)', updatedContact.Mobile_Phone_Country_Code__c);
        for(Zkipster_Contact_Update__c changeRecord : updatedChanges) {
            System.assertEquals('Accepted', changeRecord.Status__c);
        }
    }

    @IsTest
    static void testRejectChanges() {
        Account accountRecord = TestDataFactory.createOrg('Reject Account');
        Contact contactRecord = TestDataFactory.createContact(accountRecord.Id, 'Reject');
        Campaign campaignRecord = TestDataFactory.createCampaign('Reject Campaign');
        Zkipster_Contact_Update__c changeRecord = createChange(campaignRecord.Id, contactRecord.Id, 'Title', 'Title', null, 'New Title');
        insert changeRecord;
        Test.startTest();
        String result = ZkipsterContactUpdatesController.rejectSelectedChanges(new List<Id>{ changeRecord.Id });
        Test.stopTest();
        changeRecord = [
            SELECT Status__c
            FROM Zkipster_Contact_Update__c
            WHERE Id = :changeRecord.Id
        ];
        System.assertEquals('1 change was rejected.', result);
        System.assertEquals('Rejected', changeRecord.Status__c);
    }

    @IsTest
    static void testGetPendingChangesWithNullCampaign() {
        Test.startTest();
        List<Zkipster_Contact_Update__c> pendingChanges = ZkipsterContactUpdatesController.getPendingChanges(null);
        Test.stopTest();
        System.assertEquals(0, pendingChanges.size());
    }

    @IsTest
    static void testApplyChangesWithoutCountryCode() {
        Account accountRecord = TestDataFactory.createOrg('Phone Account');
        Contact contactRecord = TestDataFactory.createContact(accountRecord.Id, 'Phone');
        Campaign campaignRecord = TestDataFactory.createCampaign('Phone Campaign');
        Zkipster_Contact_Update__c changeRecord = createChange(campaignRecord.Id, contactRecord.Id, 'MobilePhone', 'Mobile Phone', null, '+61124567890');
        insert changeRecord;
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ZkipsterContactUpdatesController.applySelectedChanges(new List<Id>{ changeRecord.Id });
        } catch(AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown);
    }

    @IsTest
    static void testApplyChangesWithNoSelection() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ZkipsterContactUpdatesController.applySelectedChanges(new List<Id>());
        } catch(AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown);
    }

    @IsTest
    static void testRejectChangesWithNoSelection() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ZkipsterContactUpdatesController.rejectSelectedChanges(new List<Id>());
        } catch(AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown);
    }

    @IsTest
    static void testCountryCodeUtility() {
        Test.startTest();
        String countryCode = CountryCodeUtility.getCountryCodePicklistValue('AU');
        String dialingCode = CountryCodeUtility.getDialingCode('AU');
        Test.stopTest();
        System.assertEquals('Australia(+61)', countryCode);
        System.assertEquals('61', dialingCode);
    }

    private static Zkipster_Contact_Update__c createChange(Id campaignId, Id contactId, String fieldApiName, String fieldLabel, String currentValue, String zkipsterValue) {
        return new Zkipster_Contact_Update__c(
            List__c = campaignId,
            Contact__c = contactId,
            Zkipster_Guest_ID__c = 'guest-' + fieldApiName,
            Field_API_Name__c = fieldApiName,
            Field_Label__c = fieldLabel,
            Zkipster_Value__c = zkipsterValue,
            Status__c = 'Pending',
            Unique_Key__c = String.valueOf(campaignId) + '-' + String.valueOf(contactId) + '-' + fieldApiName
        );
    }
}