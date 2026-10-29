/*********************************************
* Created: April  4, 2017
* Created By: Lewis Blau - Slalom Consulting
* Business Purpose: This is the  test to verify that when a Campaign Member is created that the Bio_Photo value is copied to
                    the Campagin Member Record
* Updates
* ----------------------------------
* Updated By        Date                Comment
* Lewis Blau        04/04/2017          Created
***********************************************/
@isTest
private class CampaignMemberTrigger_Test {

    //This test will verify that when a Campaign Member is created that a Contact's Bio_Photo value is copied to the Campagin Member Record
    @isTest
    static void CampaignMemberCreated() {
        // Create data
        Campaign camp = TestDataFactory.getList('Test Campaign','Events') ;
        camp.Constituency__c = 'Committee for Mike';
        insert as system camp;

        Account a = TestDataFactory.getOrg('test');
        insert as system a;

        Contact con = TestDataFactory.getContact('test');
        con.AccountId = a.Id;
        insert as system con;

        // test the trigger, which runs on insert
        Test.StartTest();
        CampaignMember campMember = TestDataFactory.createCampaignMember(camp.Id, con.Id);
        campMember = [Select Id, Bio_Photo__c from CampaignMember where Id = :campmember.Id WITH SYSTEM_MODE LIMIT 1];
        System.assert(campMember.Bio_Photo__c == con.Bio_Photo__c, 'Campaign Member Bio Photo does Match Contact Bio Photo; campmember -> ' +
                      campMember.Bio_Photo__c + '; Contact -> ' + con.Bio_Photo__c);
        update as system campMember;
        delete as system campMember;
        Test.StopTest();
    }

    @isTest
    static void allowFirstPrimaryRelatedContact() {

        Account a = TestDataFactory.getOrg('test');
        insert as system a;
        Contact c = TestDataFactory.getContact('test');
        c.Email = 'TestEmail112@gmail.com';
        c.AccountId = a.Id;
        insert as system c;

        Contact con = TestDataFactory.getContact('test2');
        con.AccountId = a.Id;
        insert as system con;

        Related_Contact__c rc = TestDataFactory.createRelatedContact(c,con);

        Campaign testCampaign  = TestDataFactory.createCampaign('Test');
        Id eventRecId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
        testCampaign.RecordTypeId = eventRecId;
        testCampaign.EmailDefaultSubjectLine__c = 'ddddd';
        update as system testCampaign;
        CampaignMember mem = TestDataFactory.createCampaignMember(testCampaign.Id, c.Id);
        mem.CC_Assistant__c = true;
        mem.Assistant__c = con.Id;
        update as system mem;
        Test.StartTest();
        mem.Assistant__c = c.Id;
        update as system mem;
        Test.StopTest();
        CampaignMember updatedMem = [
            SELECT Assistant__c, CC_Addresses__c
            FROM CampaignMember
            WHERE Id = :mem.Id
            WITH SYSTEM_MODE
        ];
        System.assertEquals(c.Id, updatedMem.Assistant__c, 'Assistant should be updated');
        System.assertNotEquals(null, updatedMem.CC_Addresses__c, 'CC Address should be populated');
    }
}