/********************************************************************************
* Class Name  : NewsCustomController_Test
* Description : Test class for NewsCustomController (LWC - custom news component).
* Created By  : Slalom Consulting
* Change Log  : Created - 9/5/2019
********************************************************************************/
@isTest
private class NewsCustomController_Test {
  	@testSetup static void setup() {
        Account acc = new Account(Name = 'Bloomberg');
        insert acc;

        Contact con = new Contact(LastName = 'Johnson', FirstName = 'Boris', AccountId = acc.Id);
        insert con;
  	}

    @isTest static void testMethod1() {
        Contact con = [Select id, Account.Name, AccountId from Contact where Name Like '%Boris%' WITH SYSTEM_MODE LIMIT 1];
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('NewsMock');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/xml');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        	NewsCustomController.newsGrabber('HomePage');
       		NewsCustomController.newsGrabber(con.Id);
        //jlu
        System.assert(NewsCustomController.getTimeZone() != null, 'failed to get timezone');
        Test.stopTest();
    }
}