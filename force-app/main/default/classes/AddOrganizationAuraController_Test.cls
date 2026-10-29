@isTest
private class AddOrganizationAuraController_Test {

	@testSetup
	static void dataPrep() {
		Account acc = new Account(Name = 'TestAcct');
        Account acc2 = new Account(Name = 'TestAcct2');
		insert new List<Account>{acc, acc2};

		Campaign camp = new Campaign(Name = 'TestCampaign');
        insert camp;
	}

	@isTest
    static void testCreateListOrganizations() {
        List<Account> accs = [SELECT Id FROM Account WITH SYSTEM_MODE];
        Campaign cam = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();

        AddOrganizationAuraController.createListOrganizations(JSON.serialize(accs), cam.Id);

        Test.stopTest();

        System.assert([SELECT Id FROM ListOrganization__c WITH SYSTEM_MODE].size() == 2);
    }
}