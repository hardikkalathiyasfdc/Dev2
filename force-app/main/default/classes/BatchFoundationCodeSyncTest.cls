@isTest
public class BatchFoundationCodeSyncTest {

    @testSetup static void setup() {
        Map<String,Focus_Area__c> focusAreas = TestDataFactory.createFocusAreas(new List<String>{'Government Innovation'});

        Foundation_Code__c rootCode = TestDataFactory.createRootFoundationCode();
        rootCode.Last_Sync_All_Job_Id__c = '1234';
        update rootCode;

        Foundation_Code__c code = TestDataFactory.buildFoundationCode('Government Innovation','Focus Area',rootCode.Id,focusAreas.get('Government Innovation').Id);
        code.BGive_ID__c = '{"240765":"10259239","240763":"10259237"}';
        insert code;

        Foundation_Code__c childFC1 = TestDataFactory.buildFoundationCode('Clean Beach','Non Programmatic Initiative',code.Id,null );
        Foundation_Code__c childFC2 = TestDataFactory.buildFoundationCode('Clean Air','Non Programmatic Initiative',code.Id,null);
        List<Foundation_Code__c> childFcs = new List<Foundation_Code__c>{childFC1, childFC2};
        insert childFcs;
    }

    @isTest
    static void testSyncCreate() {
        Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
        Map<Id, Foundation_Code__c> foundationCodes = new Map<Id, Foundation_Code__c>([SELECT Id, Name FROM Foundation_Code__c WHERE Name = 'Government Innovation' with SYSTEM_MODE]);
        Foundation_Code__c fc = [select Id, BGive_ID__c, Status__c, Enabled_for_Grants__c from Foundation_Code__c with SYSTEM_MODE LIMIT 1];
        Map<Id, BBApps_ErrorCustomFields> errors = new Map<Id, BBApps_ErrorCustomFields>();
        errors.put(fc.Id, new BBApps_ErrorCustomFields('Error'));
        Test.startTest();
            Database.executeBatch(new BatchFoundationCodeSync(new List<Id>(foundationCodes.keySet())), 1);
        	FoundationCodeUtil.notifyUser(errors);
        	FoundationCodeUtil.getBGiveIdForCode(fc, 'Test');
        	FoundationCodeUtil.getExtIdForCode(fc, 'Test');
        	FoundationCodeUtil.isCodeRetired(fc);
        	FoundationCodeUtil.createLog(fc.Id, 'Test');
        Test.stopTest();
    }
}