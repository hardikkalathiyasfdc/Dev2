@isTest
public class CampaignTriggerHandlerTest {

    //This test will verify that when a Campaign Member is created that a Contact's Bio_Photo value is copied to the Campagin Member Record
    @isTest
    static void CampaignMemberCreated() {
        Id eventRecId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
        // Create data
        Campaign camp = new Campaign (Name = 'Test Campaign', RecordTypeId = eventRecId, TimeZone__c = 'America/New_York');
        insert as system camp;

        Account acct = new Account(Name = 'Test Account');
        insert as system acct;
        Contact con = new Contact(FirstName='First', LastName='Last', AccountId = acct.Id, Bio_Photo__c = 'Bio Photo', Team_s__c = 'IT');
        insert as system con;

        // test the trigger, which runs on insert
        Test.StartTest();
        CampaignMember campMember = new CampaignMember(ContactId=con.Id, CampaignId=camp.Id);
        insert as system campMember;
        campMember = [Select Id, Bio_Photo__c from CampaignMember where Id = :campmember.Id Limit 1];
        System.assert(campMember.Bio_Photo__c == con.Bio_Photo__c, 'Campaign Member Bio Photo does Match Contact Bio Photo; campmember -> ' +
                      campMember.Bio_Photo__c + '; Contact -> ' + con.Bio_Photo__c);
        update as system campMember;
        delete as system campMember;
        Test.StopTest();
    }

    @isTest
    static void CampaignUpdate() {
        Id eventRecId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
        // Create data
        Campaign camp = new Campaign (
            Name = 'Test Campaign',
            RecordTypeId = eventRecId,
            Start_Date_Time__c = System.now(),
            End_Date_Time__c = System.now().addDays(1),
            TimeZone__c = 'Europe/London'
        );
        insert as system camp;

        Account acct = new Account(Name = 'Test Account');
        insert as system acct;
        Contact con = new Contact(FirstName='First', LastName='Last', AccountId = acct.Id, Bio_Photo__c = 'Bio Photo', Team_s__c = 'IT');
        insert as system con;

        CampaignMember campMember = new CampaignMember(ContactId=con.Id, CampaignId=camp.Id);
        insert as system campMember;

        // test the trigger, which runs on insert
        Test.StartTest();
        camp.Start_Date_Time__c = System.now();
        camp.End_Date_Time__c = System.now().addDays(1);
        camp.TimeZone__c = 'America/Panama';
        camp.Constituency__c = 'Committee for Mike';
        camp.EventStatus__c = 'Upcoming';
        camp.EmailDefaultSubjectLine__c = 'TestSubject';
        update as system camp;
        Test.StopTest();
    }

    @isTest
    static void testUpdateCampaignSubject() {
        Test.startTest();
        Id eventRecId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
        Campaign camp = new Campaign(
            Name = 'Fundraiser Campaign',
            RecordTypeId = eventRecId,
            TimeZone__c = 'America/New_York',
            Private_Campaign__c = true
        );
        insert as system camp;
        Campaign updatedCampaign = [SELECT Name FROM Campaign WHERE Id = :camp.Id];
        Assert.areEqual('Fundraiser Campaign (Private)', updatedCampaign.Name);
        camp.Private_Campaign__c = false;
        camp.EventStatus__c = 'Upcoming';
        camp.EmailDefaultSubjectLine__c = 'TestSubject';
        update camp;
        Campaign updatedCampaign1 = [SELECT Name FROM Campaign WHERE Id = :camp.Id];
        Assert.areEqual('Fundraiser Campaign', updatedCampaign1.Name);
        Test.stopTest();
    }

    @isTest
    static void testCampaignEndDateAndCoordinator() {
        Datetime customDt = Datetime.newInstance(2026, 5, 29, 18, 0, 0);
        Test.startTest();
            Campaign camp = TestDataFactory.getList('Test Event', 'Events');
            camp.Start_Date_Time__c = customDt;
            insert as system camp;
        Test.stopTest();
        camp = [
            SELECT Id, EventCoordinator__c, End_Date_Time__c
            FROM Campaign
            WHERE Id = :camp.Id 
            WITH SYSTEM_MODE
        ];
        Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
        System.assertEquals(envSetting.Default_Event_Coordinator__c, camp.EventCoordinator__c, 'Default Event Coordinator should be set when Event Coordinator is blank');
        System.assertEquals(customDt.addHours(1).addMinutes(30), camp.End_Date_Time__c, 'End Date should be 1:30 hours after Start Date');
    }

    @isTest
    static void testEmailSubjectLineUpdatesForUpcomingRsvps() {
        Id eventRecId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
        Campaign upcoming = new Campaign(
            Name = 'Upcoming Subject Event',
            RecordTypeId = eventRecId,
            TimeZone__c = 'America/New_York',
            Start_Date_Time__c = System.now(),
            End_Date_Time__c = System.now().addDays(2),
            EmailDefaultSubjectLine__c = 'Old invite {0}'
        );
        Campaign completeEvent = new Campaign(
            Name = 'Complete Subject Event',
            RecordTypeId = eventRecId,
            TimeZone__c = 'America/New_York',
            Start_Date_Time__c = System.now().addDays(-3),
            End_Date_Time__c = System.now().addDays(-1),
            EmailDefaultSubjectLine__c = 'Old invite {0}'
        );
        insert as system new List<Campaign>{ upcoming, completeEvent };

        Account acct = new Account(Name = 'Subject Account');
        insert as system acct;
        Contact blankRsvp = new Contact(FirstName = 'Blank', LastName = 'Guest', AccountId = acct.Id, Team_s__c = 'IT');
        Contact pendRsvp = new Contact(FirstName = 'Pend', LastName = 'Guest', AccountId = acct.Id, Team_s__c = 'IT');
        Contact waitlistOne = new Contact(FirstName = 'Wait', LastName = 'One', Preferred_First_Name__c = 'Pref', AccountId = acct.Id, Team_s__c = 'IT');
        Contact waitlistTwo = new Contact(FirstName = 'Wait', LastName = 'Two', AccountId = acct.Id, Team_s__c = 'IT');
        Contact yesRsvp = new Contact(FirstName = 'Yes', LastName = 'Guest', AccountId = acct.Id, Team_s__c = 'IT');
        Contact completeRsvp = new Contact(FirstName = 'Done', LastName = 'Guest', AccountId = acct.Id, Team_s__c = 'IT');
        insert as system new List<Contact>{ blankRsvp, pendRsvp, waitlistOne, waitlistTwo, yesRsvp, completeRsvp };

        insert as system new List<CampaignMember>{
            new CampaignMember(CampaignId = upcoming.Id, ContactId = blankRsvp.Id),
            new CampaignMember(CampaignId = upcoming.Id, ContactId = pendRsvp.Id, RSVPStatus__c = 'Pend'),
            new CampaignMember(CampaignId = upcoming.Id, ContactId = waitlistOne.Id, RSVPStatus__c = 'Waitlist 1'),
            new CampaignMember(CampaignId = upcoming.Id, ContactId = waitlistTwo.Id, RSVPStatus__c = 'Waitlist 2'),
            new CampaignMember(CampaignId = upcoming.Id, ContactId = yesRsvp.Id, RSVPStatus__c = 'Yes'),
            new CampaignMember(CampaignId = completeEvent.Id, ContactId = completeRsvp.Id, RSVPStatus__c = 'Pend')
        };

        Test.startTest();
        upcoming.EmailDefaultSubjectLine__c = 'New invite {0}';
        completeEvent.EmailDefaultSubjectLine__c = 'New invite {0}';
        update as system new List<Campaign>{ upcoming, completeEvent };
        Test.stopTest();

        Map<Id, CampaignMember> membersByContact = new Map<Id, CampaignMember>();
        for (CampaignMember member : [
            SELECT ContactId, EmailSubjectLine__c
            FROM CampaignMember
            WHERE CampaignId IN :new Set<Id>{ upcoming.Id, completeEvent.Id }
            WITH SYSTEM_MODE
        ]) {
            membersByContact.put(member.ContactId, member);
        }

        Assert.areEqual('New invite Blank Guest', membersByContact.get(blankRsvp.Id).EmailSubjectLine__c);
        Assert.areEqual('New invite Pend Guest', membersByContact.get(pendRsvp.Id).EmailSubjectLine__c);
        Assert.areEqual('New invite Pref One', membersByContact.get(waitlistOne.Id).EmailSubjectLine__c);
        Assert.areEqual('New invite Wait Two', membersByContact.get(waitlistTwo.Id).EmailSubjectLine__c);
        Assert.areEqual('Old invite Yes Guest', membersByContact.get(yesRsvp.Id).EmailSubjectLine__c);
        Assert.areEqual('Old invite Done Guest', membersByContact.get(completeRsvp.Id).EmailSubjectLine__c);
    }
}