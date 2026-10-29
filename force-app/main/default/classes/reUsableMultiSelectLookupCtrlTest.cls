@isTest
public class reUsableMultiSelectLookupCtrlTest {
    
  @TestSetup
  private static void makeData() {
    Contact c = TestDataFactory.getContact('test');
    insert as system c;
    Account acct = TestDataFactory.getOrg('test');
    insert as system acct;
  }

  @isTest
  public static void validateFetch() {
  	Test.startTest();
    Contact c = [Select Id from Contact WITH SYSTEM_MODE];
    List<SObject> results = reUsableMultiSelectLookupCtrl.fetchLookupValues('test', 'Contact', new List<sObject>());
    String accts = reUsableMultiSelectLookupCtrl.fetchAccountsByKeyword('test');
  }
}