@isTest
private class listMemberMoreInfoAuraCtrl_Test {

	@isTest
    static void testGetFields() {
    	Contact cnt = new Contact(FirstName='Test', LastName='Last');
    	insert cnt;

    	Campaign camp = new Campaign();
    	camp.Name = 'test';
    	insert camp;

    	CampaignMember cm = new CampaignMember();
    	cm.ContactId = cnt.Id;
    	cm.CampaignId = camp.Id;
    	insert cm;

       
       Test.startTest();

       String fields = listMemberMoreInfoAuraCtrl.getContactFields();

       System.assert(String.isNotBlank(fields));

       String contactId = listMemberMoreInfoAuraCtrl.getContactId(cm.Id);
        System.assert(String.isNotBlank(contactId));

       Test.stopTest();
    }
}