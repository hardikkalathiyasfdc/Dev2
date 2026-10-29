@isTest
public class BatchUpdateContactCovertedNamesTest {
    @testSetup
    static void setupdata() {
        Contact ct = TestDataFactory.getContact('šurÁ');
        insert ct;
        ct.Converted_LastName__c = null;
        update ct;
    }

    @isTest
    private static void test() {
        Test.startTest();
		BatchUpdateContactCovertedNames batchRollup = new BatchUpdateContactCovertedNames();
        Database.executebatch(batchRollup);
        Test.stopTest();
        Contact contact = [Select lastName,Converted_LastName__c from Contact limit 1 ];
         System.assertEquals('surA', contact.Converted_LastName__c);
    }
}