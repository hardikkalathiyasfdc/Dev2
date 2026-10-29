/**
 * Author      : Paddy
 * Date        : 02/06/2025
 * Jira        : IM-111
 * Description : Test class for IMAnnouncementTriggerHandler.
 */
@isTest
public class IMAnnouncementTriggerHandlerTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
	}

	@isTest
	public static void testNameOnInsert() {
		IM_Initiative__c initiative = [
			SELECT Name, Term_Years__c, Start_Date__c, Recordtype.name
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
			WITH SYSTEM_MODE
		];

		IM_Announcement__c announcement = TestDataFactory.createAnnouncement(initiative);
		announcement.Announcement_Link__c = 'https://www.google.com/';
		announcement.Announcement_Date__c = System.today();
		Test.startTest();
            insert as system announcement;
            IM_Announcement__c insertedAnnouncement = [SELECT Name FROM IM_Announcement__c WHERE Id = :announcement.Id WITH SYSTEM_MODE];
            Assert.areEqual(System.today().format() + ' Clean Air 1.0', insertedAnnouncement.Name);
		Test.stopTest();
	}
}