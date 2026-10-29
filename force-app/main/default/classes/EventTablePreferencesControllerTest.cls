@IsTest
public without sharing class EventTablePreferencesControllerTest {

    @IsTest
    static void testGetSortPreferences_NoPreferences() {
        User u = TestDataFactory.createUser('Test', 'User');
        String sortJson = '[{"field":"event.EventType__c","direction":"desc","type":"string"}]';
        System.runAs(u) {
            Test.startTest();
            insert as system new Custom_User_Preference__c(User__c = u.Id, Event_Sort_Order_JSON__c = sortJson);
            String result = EventTablePreferencesController.getSortPreferences();
            Test.stopTest();
            System.assertEquals(sortJson, result, 'Should return sortJson array');
        }
    }

    @IsTest
    static void testGetSortPreferences_InvalidUser() {
        User u = TestDataFactory.createUser('Test', 'User');
        Test.startTest();
        String result = EventTablePreferencesController.getSortPreferences();
        Test.stopTest();
        System.assertEquals('[]', result, 'Should return empty array when no preferences exist');
    }

    @IsTest
    static void testSaveSortPreferences() {
        User u = TestDataFactory.createUser('Test', 'User');
        String sortJson = '[{"field":"event.EventType__c","direction":"desc","type":"string"}]';
        System.runAs(u) {
            Test.startTest();
            EventTablePreferencesController.saveSortPreferences(sortJson);
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetSortPreferences_CatchBlock() {
        User u = TestDataFactory.createUser('Test', 'User');
        System.runAs(u) {
            EventTablePreferencesController.forceException = true;
            Test.startTest();
            String result = EventTablePreferencesController.getSortPreferences();
            Test.stopTest();
            System.assertEquals('[]', result);
            EventTablePreferencesController.forceException = false;
        }
    }

    @IsTest
    static void testSaveSortPreferences_CatchBlock() {
        User u = TestDataFactory.createUser('Test', 'User');
        System.runAs(u) {
            EventTablePreferencesController.forceException = true;
            Test.startTest();
            EventTablePreferencesController.saveSortPreferences('invalid');
            Test.stopTest();
            EventTablePreferencesController.forceException = false;
        }
    }
}