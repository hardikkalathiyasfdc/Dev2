@isTest
public class BatchUpdateAccountCovertedNamesTest {
    @testSetup
    static void setupdata() {
        Account acc = TestDataFactory.getOrg('šurÁ');
        insert acc;
         acc.Converted_Org_Name__c = null;
        update acc;
    }

    @isTest
    private static void test() {
        Test.startTest();
		BatchUpdateAccountCovertedNames batchRollup = new BatchUpdateAccountCovertedNames();
        Database.executebatch(batchRollup);
        Test.stopTest();
        Account acc = [Select Name,Converted_Org_Name__c from Account limit 1 ];
         System.assertEquals('surA', Acc.Converted_Org_Name__c);
    }
}