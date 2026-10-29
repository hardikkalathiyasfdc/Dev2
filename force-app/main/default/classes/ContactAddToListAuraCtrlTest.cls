@IsTest
private class ContactAddToListAuraCtrlTest {

    private static Map<String, Id> createBaseData() {
        Contact con = new Contact(
            LastName = 'TestContact'
        );
        insert as system con;

        Campaign camp = new Campaign(
            Name = 'Test Campaign'
        );
        insert as system camp;

        return new Map<String, Id>{
            'contactId' => con.Id,
            'campaignId' => camp.Id
        };
    }

    @IsTest
    static void testCheckGuestInList_ReturnsTrue_WhenMemberExists() {
        Map<String, Id> ids = createBaseData();
        Id contactId = ids.get('contactId');
        Id campaignId = ids.get('campaignId');
        CampaignMember cm = new CampaignMember(
            ContactId  = contactId,
            CampaignId = campaignId
        );
        insert as system cm;
        Test.startTest();
        Boolean result = ContactAddToListAuraCtrl.checkGuestInList(contactId, campaignId);
        Test.stopTest();
        System.assertEquals(true, result, 'Method should return true when CampaignMember exists.');
    }

    @IsTest
    static void testCheckGuestInList_ReturnsFalse_WhenMemberDoesNotExist() {
        Map<String, Id> ids = createBaseData();
        Id contactId = ids.get('contactId');
        Id campaignId = ids.get('campaignId');
        Test.startTest();
        Boolean result = ContactAddToListAuraCtrl.checkGuestInList(contactId, campaignId);
        Test.stopTest();
        System.assertEquals(false, result, 'Method should return false when CampaignMember does not exist.');
    }

    @IsTest
    static void testCreateListMember_InsertsCampaignMember() {
        Map<String, Id> ids = createBaseData();
        Id contactId = ids.get('contactId');
        Id campaignId = ids.get('campaignId');
        Test.startTest();
        ContactAddToListAuraCtrl.createListMember(contactId, campaignId);
        Test.stopTest();
        List<CampaignMember> members = [
            SELECT Id, ContactId, CampaignId
            FROM CampaignMember
            WHERE ContactId = :contactId
              AND CampaignId = :campaignId
            WITH SYSTEM_MODE
        ];

        System.assertEquals(1, members.size(), 'A CampaignMember should have been inserted.');
        System.assertEquals(contactId, members[0].ContactId, 'ContactId should match.');
        System.assertEquals(campaignId, members[0].CampaignId, 'CampaignId should match.');
    }
    
    @IsTest
    static void testCheckGuestInList_TriggersCatchBlock_OnInvalidIds() {
        String invalidContactId = 'notAnId';
        String invalidCampaignId = 'alsoBad';
        Test.startTest();
        Boolean result = ContactAddToListAuraCtrl.checkGuestInList(invalidContactId, invalidCampaignId);
        Test.stopTest();
        System.assertEquals(false, result, 'Method should safely return false when query fails and hits catch.');
    }

    @IsTest
    static void testCreateListMember_TriggersCatchBlock_OnInvalidCampaignId() {
        Contact con = new Contact(LastName = 'ForErrorTest');
        insert as system con;

        Id validContactId = con.Id;
        String invalidCampaignId = 'badId';
        Test.startTest();
        ContactAddToListAuraCtrl.createListMember(validContactId, invalidCampaignId);
        Test.stopTest();
        List<CampaignMember> members = [
            SELECT Id FROM CampaignMember WHERE ContactId = :validContactId WITH SYSTEM_MODE
        ];
        System.assertEquals(
            0,
            members.size(),
            'No CampaignMember should be inserted when invalid CampaignId is passed.'
        );
    }
}