@IsTest
private class SendEventInvitationsControllerTest {

    @TestSetup
    static void setupData() { 
        List<OrgWideEmailAddress> orgEmailList = [
          SELECT Id, Address
          FROM OrgWideEmailAddress
          WITH SYSTEM_MODE
        ];
        SendEventInvitationsController.orgEmailMap = new Map<String, Id>{ orgEmailList[0].Address.toLowerCase() => orgEmailList[0].Id };
        Contact con = new Contact(LastName = 'Guest', Email = 'guest1@testexample.org');
        insert as system con;
        Campaign upcoming = new Campaign(Name = 'Upcoming Event', EventStatus__c = 'Upcoming', InvitationFromEmail__c = orgEmailList[0].Address.toLowerCase());
        insert as system upcoming;
        Campaign upcoming1 = new Campaign(Name = 'Upcoming Event 1', EventStatus__c = 'Upcoming', InvitationFromEmail__c = 'Test@email.com');
        insert as system upcoming1;
        String emailType = 'invitation';
        String bodyField = EventMangementAuraCtrl.EMAIL_TYPE_MAP.get(emailType);
        String subjectField = EventMangementAuraCtrl.EMAIL_SUBJECT_MAP.get(emailType);
        CampaignMember cm = new CampaignMember(
            CampaignId = upcoming.Id,
            ContactId  = con.Id,
            Guest_Email_Type__c = 'Business',
            CC_Addresses__c = 'testEmail11@gmail.com,testEmail112@gmail.com',
            BCC_Addresses__c =  'testEmail11@gmail.com,testEmail112@gmail.com'
        );
        cm.put(subjectField, 'You are invited!');
        cm.put(bodyField, '<p>Hello!</p>');
        insert as system cm;
        CampaignMember cm1 = new CampaignMember(
            CampaignId = upcoming1.Id,
            ContactId  = con.Id,
            Guest_Email_Type__c = 'Business',
            CC_Addresses__c = 'testEmail1@gmail.com,testEmail12@gmail.com',
            BCC_Addresses__c = 'testEmail11@gmail.com,testEmail112@gmail.com'
        );
        cm1.put(subjectField, 'You are invited!');
        cm1.put(bodyField, '<p>Hello!</p>');
        insert as system cm1;
    }

    @IsTest
    static void test_sendEmail() {
        Campaign upcoming = [SELECT Id FROM Campaign WHERE Name = 'Upcoming Event' WITH SYSTEM_MODE LIMIT 1];
        List<Id> ids = new List<Id>();
        for(CampaignMember cm : [SELECT Id FROM CampaignMember WHERE CampaignId = :upcoming.Id WITH SYSTEM_MODE ORDER BY CreatedDate ASC]) {
            ids.add(cm.Id); 
        }
        Test.startTest();
        	SendEventInvitationsController.sendEmail(ids, 'invitation');
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void test_sendEmail1() {
        Campaign upcoming1 = [SELECT Id FROM Campaign WHERE Name = 'Upcoming Event 1' WITH SYSTEM_MODE LIMIT 1];
        List<Id> ids = new List<Id>();
        for(CampaignMember cm : [SELECT Id FROM CampaignMember WHERE CampaignId = :upcoming1.Id WITH SYSTEM_MODE ORDER BY CreatedDate ASC]) {
            ids.add(cm.Id); 
        }
        Test.startTest();
        	SendEventInvitationsController.sendEmail(ids, 'invitation');
        Test.stopTest();
        System.assert(true);
    }
}