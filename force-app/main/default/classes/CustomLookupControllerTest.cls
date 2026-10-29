@isTest
public without sharing class CustomLookupControllerTest {
  @isTest
  public static void validateFetch() {
    Test.startTest();
    Contact c = [SELECT Id FROM Contact WITH SYSTEM_MODE ];
    Map<String, Object> result = (Map<String, Object>) CustomLookupController.fetchLookupValues(
      'test',
      'Contact',
      '',
        ''
    );
    List<SObject> results = (List<Sobject>) result.get('list');
    result = (Map<String, Object>) CustomLookupController.fetchLookupValues(
      'test',
      'Account',
      '',
        ''
    );
   results = (List<Sobject>) result.get('list');
       result = (Map<String, Object>) CustomLookupController.fetchLookupValues(
      'test',
      'User',
      '',
        ''
    );
   results = (List<Sobject>) result.get('list');
      result = (Map<String, Object>) CustomLookupController.fetchLookupValues(
      'test',
      'Tag__c',
      '',
        ''
    );
   results = (List<Sobject>) result.get('list');
     // CustomLookupController.getAllPublicTags();
    Tag__c t = [SELECT Id FROM Tag__c WITH SYSTEM_MODE ];
    result = (Map<String, Object>) CustomLookupController.fetchLookupValues(
      '',
      'Tag__c',
      '',''
    );
    results = (List<Sobject>) result.get('list');
    System.assert(results.get(0).Id == t.Id, 'failed to get tags');
    Test.stopTest();
  }
  @TestSetup
  private static void makeData() {
    Contact c = TestDataFactory.getContact('test');
    insert c;
    Tag__c tag = TestDataFactory.getTag('test');
    insert tag;
  }
}