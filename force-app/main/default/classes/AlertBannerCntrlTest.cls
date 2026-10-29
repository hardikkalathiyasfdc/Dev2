/*
 * Description: Test class for AlertBannerCntrl
 * Author: Ravi Bheemreddy
*/
@isTest
public class AlertBannerCntrlTest {

    @testSetup
    static void setup() {
        Account acc = TestDataFactory.createOrg('Test Org');
        TestDataFactory.createContact(acc.Id, 'Test');
    }

    @isTest
    static void testGetMessages_WithValidField() {
        Contact con = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
        List<String> messages = AlertBannerCntrl.getMessages('FirstName', 'Contact', con.Id);
        Test.stopTest();

        System.assertEquals(1, messages.size());
    }

    @isTest
    static void testGetMessages_WithSemicolonSeparatedValues() {
        Contact con = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];
        con.Description = 'Message1;Message2;Message3';
        update as system con;

        Test.startTest();
        List<String> messages = AlertBannerCntrl.getMessages('Description', 'Contact', con.Id);
        Test.stopTest();

        System.assertEquals(3, messages.size());
    }

    @isTest
    static void testGetMessages_WithBlankParams() {
        Contact con = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
        List<String> messages = AlertBannerCntrl.getMessages('', '', con.Id);
        Test.stopTest();

        System.assertEquals(0, messages.size());
    }
}