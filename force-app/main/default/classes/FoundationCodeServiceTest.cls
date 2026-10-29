@isTest
public class FoundationCodeServiceTest {

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
        Foundation_Code__c foundationCode = [SELECT Id, Name, BGive_Description__c, Foundation_Code__c, BGive_Migrate_Id__c, Enabled_for_Grants__c, Enabled_for_Fundraising__c,
            Sync_Error__c, Status__c, Sync_Warning__c, Parent__r.Name, Parent__r.BGive_ID__c FROM Foundation_Code__c WHERE Name = 'Clean Beach' with SYSTEM_MODE];
        FoundationCodeService foundationCodeService = new FoundationCodeService();
        BGiveApiMav bgiveApi = new BGiveApiMav();
        Test.startTest();
            foundationCodeService.sync('240763', null, null, foundationCode);
        Test.stopTest();
        BGiveApi.BGiveAPIResponse bgiveResponse = (BGiveApi.BGiveAPIResponse)bgiveApi.fetch(foundationCode.Id, new List<String>{'model_attribute_id','value'});
        Object record = bgiveResponse.record;
        Assert.areEqual('Government Innovation', ((Map<String,Object>)record).get('value'));
    }

    @isTest
    static void testSyncUpdate() {
        Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
        Foundation_Code__c foundationCode = [SELECT Id, Name, BGive_Description__c, Foundation_Code__c, BGive_Migrate_Id__c, Enabled_for_Grants__c, Enabled_for_Fundraising__c,
            Sync_Error__c, BGive_ID__c, Status__c, Sync_Warning__c, Parent__r.Name, Parent__r.BGive_ID__c FROM Foundation_Code__c WHERE Name = 'Clean Beach' with SYSTEM_MODE];
        FoundationCodeService foundationCodeService = new FoundationCodeService();
        BGiveApiMav bgiveApi = new BGiveApiMav();
        //foundationCodeService.sync('240763', null, null, foundationCode);
        Test.startTest();
            FoundationCodeService.ModelAttributeValue bgiveCodeByName = new FoundationCodeService.ModelAttributeValue();
            bgiveCodeByName.retired = 1;
            foundationCodeService.sync('240763', null, bgiveCodeByName, foundationCode);
        Test.stopTest();
        BGiveApi.BGiveAPIResponse bgiveResponse = (BGiveApi.BGiveAPIResponse)bgiveApi.fetch(foundationCode.Id, new List<String>{'model_attribute_id','value'});
        Object record = bgiveResponse.record;
        Assert.areEqual(1, ((Map<String,Object>)record).get('retired'));
    }

    @isTest
    static void testSyncRetired() {
        Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
        Foundation_Code__c foundationCode = [SELECT Id, Name, BGive_Description__c, Foundation_Code__c, BGive_Migrate_Id__c, Enabled_for_Grants__c, Enabled_for_Fundraising__c,
            Sync_Error__c, BGive_ID__c, Status__c, Sync_Warning__c, Parent__r.Name, Parent__r.BGive_ID__c FROM Foundation_Code__c WHERE Name = 'Clean Beach' with SYSTEM_MODE];
        BGiveApiMav bgiveApi = new BGiveApiMav();
        Test.startTest();
            FoundationCodeService.ModelAttributeValue bGiveRecord = new FoundationCodeService.ModelAttributeValue();
            bGiveRecord.id = foundationCode.Id;
            FoundationCodeService.retireBGiveCode(bGiveRecord);
        Test.stopTest();
        BGiveApi.BGiveAPIResponse bgiveResponse = (BGiveApi.BGiveAPIResponse)bgiveApi.fetch(foundationCode.Id, new List<String>{'model_attribute_id','value'});
        Object record = bgiveResponse.record;
        Assert.areEqual(1, ((Map<String,Object>)record).get('retired'));
    }

    @isTest
    static void testSyncMatchingBgiveCodeSetsIdWithoutModify() {
        Foundation_Code__c foundationCode = getFoundationCode('Clean Beach');
        foundationCode.BGive_ID__c = '{"240763":"10259237"}';
        update foundationCode;
        foundationCode = getFoundationCode('Clean Beach');
        FoundationCodeService.ModelAttributeValue matchingBgiveCode = buildMatchingBgiveCode(foundationCode, '240763');

        FoundationCodeService foundationCodeService = new FoundationCodeService();
        Test.startTest();
            foundationCodeService.sync('240763', null, matchingBgiveCode, foundationCode);
            foundationCodeService.updateCodes();
        Test.stopTest();
        Map<String, Object> bGiveIds = (Map<String, Object>) JSON.deserializeUntyped(
            [SELECT BGive_ID__c FROM Foundation_Code__c WHERE Id = :foundationCode.Id with SYSTEM_MODE].BGive_ID__c
        );
        Assert.areEqual('10259237', String.valueOf(bGiveIds.get('240763')));

    }

    @isTest
    static void testSyncUpdateByExternalId() {
        Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
        Foundation_Code__c foundationCode = getFoundationCode('Clean Beach');
        FoundationCodeService foundationCodeService = new FoundationCodeService();
        FoundationCodeService.ModelAttributeValue bgiveCodeByExternalId = new FoundationCodeService.ModelAttributeValue();
        bgiveCodeByExternalId.retired = 1;
        Test.startTest();
            foundationCodeService.sync('240763', bgiveCodeByExternalId, null, foundationCode);
            foundationCodeService.updateCodes();
        Test.stopTest();
        Assert.isTrue([SELECT BGive_ID__c FROM Foundation_Code__c WHERE Id = :foundationCode.Id with SYSTEM_MODE].BGive_ID__c.contains('240763'));
    }

    private static Foundation_Code__c getFoundationCode(String name) {
        return [
            SELECT Id, Name, BGive_Description__c, Foundation_Code__c, BGive_Migrate_Id__c, Enabled_for_Grants__c, Enabled_for_Fundraising__c,
                Sync_Error__c, BGive_ID__c, Status__c, Sync_Warning__c, Is_Sync_Error__c, Sort_Order__c, Parent__r.Name, Parent__r.BGive_ID__c
            FROM Foundation_Code__c
            WHERE Name = :name
            WITH SYSTEM_MODE
        ];
    }

    private static FoundationCodeService.ModelAttributeValue buildMatchingBgiveCode(Foundation_Code__c code, String modelAttributeId) {
        FoundationCodeService.ModelAttributeValue mav = new FoundationCodeService.ModelAttributeValue();
        mav.id = '10259237';
        mav.description = code.BGive_Description__c;
        mav.value = code.Foundation_Code__c;
        mav.retired = FoundationCodeUtil.isCodeRetired(code);
        mav.migrate_id = code.BGive_Migrate_Id__c;
        mav.model_attribute_id = modelAttributeId;
        mav.dependent_model_attribute_value_id = FoundationCodeUtil.getBGiveIdForCode(code.Parent__r, modelAttributeId);
        mav.display_order = code.Sort_Order__c != null ? Integer.valueOf(code.Sort_Order__c) : null;
        return mav;
    }
}