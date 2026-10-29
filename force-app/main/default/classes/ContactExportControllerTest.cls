@isTest
public class ContactExportControllerTest {

    @testsetup
    public static void createTestData(){
        Account acc = TestDataFactory.createCityViewOrg();
        Contact con = TestDataFactory.createContact(acc.Id,'Test');
        con.Title = 'CEO';
        update con;
        Tag__c tag = TestDataFactory.getTag('Art');
        insert tag;
        Tag_Junction__c tagJunction = TestDataFactory.getTagJunc(tag,con);
        insert tagJunction;
    }

    @isTest
    static void testGetAllFieldAccess() {
        Test.startTest();
        Map<String, Map<String, Boolean>> result = ContactExportController.getAllFieldAccess();
        Test.stopTest();
    }

    @isTest
    public static void exportContact(){
        Account acc = [SELECT ID FROM Account WITH SYSTEM_MODE LIMIT 1];
        list<String> fieldNames = new List<String>{'FirstName','LastName','Assistant_Business_Email__c','Staff_Role__c','Significant_Other__r.Title','ffTags','otherTags','significantOtherAssistantName'};
        List<ContactExportController.OptionWrapper> fieldNamesWrapper = ContactExportController.getFieldSetFields('Export_List');
        Assert.isNotNull(fieldNames, 'fieldNames should not be null');
        List<Map<String, String>> result = ContactExportController.getContactsWithSelectedFields(fieldNames,acc.Id, ContactExportController.EXPORT_LEADERSHIP_MODE);
        Assert.isNotNull(result, 'result should not be null');
    }

    @isTest
    public static void exportContactWithForcedException(){
        ContactExportController.forceException = true;
        Account acc = [SELECT ID FROM Account WITH SYSTEM_MODE LIMIT 1];
        list<String> fieldNames = new List<String>{'FirstName','LastName','Assistant_Business_Email__c','Staff_Role__c','Significant_Other__r.Title','ffTags','otherTags','significantOtherAssistantName'};
        List<ContactExportController.OptionWrapper> fieldNamesWrapper = ContactExportController.getFieldSetFields('Export_List');
        Assert.isNotNull(fieldNames, 'fieldNames should not be null');
        List<Map<String, String>> result = ContactExportController.getContactsWithSelectedFields(fieldNames,acc.Id, ContactExportController.EXPORT_LEADERSHIP_MODE);
        Assert.isNull(result, 'result should be null');
    }
}