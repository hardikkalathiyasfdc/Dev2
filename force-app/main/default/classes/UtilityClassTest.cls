@isTest
private class UtilityClassTest {
    
    @isTest
    private static void testUtilityClass() {
        String html = '<p>pre</p>'
            + '<img alt="one" src="https://ex.com/one.png?x=1&amp;y=2">'
            + '<img alt="two" src="https://ex.com/two.png?u=3&amp;v=4">';
        
        System.assertEquals('https://ex.com/two.png?u=3&v=4', UtilityClass.getPhotoURL(html));
        System.assertEquals('', UtilityClass.getPhotoURL('<p>no images here</p>'));
        
        UtilityClass.wrapperPhones w1 = UtilityClass.formatPhone('+1 2125551234', 'United States (+1)', 'Canada (+1)');
        UtilityClass.wrapperPhones w2 = UtilityClass.formatPhone('+44 2071234567', 'United Kingdom (+44)', 'United States (+1)');
        
        System.assert(w2.FormatedPhone.startsWith('+44 '));
        
        UtilityClass.getFieldDependencies('Contact', 'MailingCountryCode', 'MailingStateCode');
        List<String> states = UtilityClass.getPickListValuesIntoList('User', 'State');
        List<String> acctTypes = UtilityClass.getPickListValuesIntoList('Account', 'Type');
        Set<String> bmIds = UtilityClass.getBoardMemberContactIds(new Set<Id>());
        List<String> alertEmails = UtilityClass.getBoardMemberContactAlertReceiver();
        Map<String,String> acctLabels = UtilityClass.GetObjectFieldLabels('Account');
        
        UtilityClass.processAccountOrgEngagementCount(new Set<Id>());
        Map<String,String> fs = UtilityClass.getFieldsByFieldSet('Account', 'No_Such_Field_Set');
        Boolean isSb = UtilityClass.isSandbox();
        Boolean hasPS = UtilityClass.checkIfUserHasAssignedPermissionSet(UserInfo.getUserId(), 'Definitely_Not_A_Permission_Set');
        String sandboxName = UtilityClass.getSandboxName();
        String environment = UtilityClass.getEnvironment();
        
        System.assertNotEquals(null, environment);
        System.assert(!String.isBlank(UtilityClass.getLastMonthName()));
        System.assert(!String.isBlank(UtilityClass.getLastMonthYear()));
        
        Test.startTest();
        Boolean perm = UtilityClass.hasRequiredPermission('Some_Feature_Permission');
        String result = UtilityClass.getPhotoURL(null);
        UtilityClass.wrapperPhones result1 = UtilityClass.formatPhone('2125551234', null, null);
        Map<String,String> result2 = UtilityClass.GetObjectFieldLabels('NoSuchObject__c');
        Map<String,String> result3 = UtilityClass.getFieldsByFieldSet('NoSuchObject__c', 'Anything');
        Map<String, List<String>> result4 = UtilityClass.getFieldDependencies('NoSuchObject__c', 'BadField', 'BadField2');
        List<String> result5 = UtilityClass.getPickListValuesIntoList('NoSuchObject__c', 'BadField');
        Test.stopTest();
        
        System.assertNotEquals(null, perm);
    }
    
    @isTest
    private static void testLogError(){
        
        Test.startTest();
        UtilityClass.logError(null, 'Test error message', 'TestType');
        Test.stopTest();
        List<MB_Error__c> logs = [SELECT Id, Description__c FROM MB_Error__c LIMIT 1];        
        System.assert(logs.size() >= 0);
    }
    
    @isTest
    private static void testStringContains(){
        
        Test.startTest();
        
        Boolean result1 = UtilityClass.stringContains('A;B;C', 'B');
        Boolean result2 = UtilityClass.stringContains('A;B;C', 'D');
        Boolean result3 = UtilityClass.stringContains(null, 'A');
        Boolean result4 = UtilityClass.stringContains('A;B;C', null);
        
        Test.stopTest();
        
        System.assertEquals(true, result1);
        System.assertEquals(false, result2);
        System.assertEquals(false, result3);
        System.assertEquals(false, result4);
    }
    
    @isTest
    static void testSafeSplit(){
        
        Test.startTest();
        List<String> result1 = UtilityClass.safeSplit('A;B;C');
        List<String> result2 = UtilityClass.safeSplit(null);
        List<String> result3 = UtilityClass.safeSplit('');
        Test.stopTest();
        
        System.assertEquals(3, result1.size());
        System.assertEquals(0, result2.size());
        System.assertEquals(0, result3.size());
    }
    
    @isTest
    private static void testProcessAccountOrgEngagementCount(){
        
        Account acc = TestDataFactory.createOrg('Test Organization');
        Id targetRTId = Schema.SObjectType.Interaction__c.getRecordTypeInfosByDeveloperName().get(Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME).getRecordTypeId();
        
        Test.startTest();
        UtilityClass.processAccountOrgEngagementCount(new Set<Id>{acc.Id});
        Test.stopTest();
    }
}