/**
 * Verifies Pledge Recipient Soft Credit synchronization and Contact receiving data.
 */
@isTest
private class PledgeRecipientSoftCreditServiceTest {
    @isTest
    static void populatesAndReconcilesPledge() {
        Account organization = TestDataFactory.createOrg('Recipient Organization');
        Contact firstRecipient = TestDataFactory.createContact(organization.Id, 'First');
        Contact secondRecipient = TestDataFactory.createContact(organization.Id, 'Second');
        Fundraising_Project__c project = TestDataFactory.createFundraisingProject();
        Pledge__c pledge = TestDataFactory.createPledge(organization.Id, project.Id, 1000);
        Recipient_Organization__c recipient = TestDataFactory.createRecipientOrganization(
            organization.Id,
            project.Id,
            firstRecipient.Id
        );
        pledge = [SELECT Recipient_Soft_Credit__c FROM Pledge__c WHERE Id = :pledge.Id];
        System.assertEquals(firstRecipient.Id, pledge.Recipient_Soft_Credit__c);
        List<Fundraising_Summary.FundArray> receiving = Fundraising_Summary.getFundraisingRecepient(firstRecipient.Id);
        System.assertEquals(1, receiving.size());

        Test.startTest();
        recipient.Recipient_Soft_Credit__c = secondRecipient.Id;
        update recipient;
        Test.stopTest();
        pledge = [SELECT Recipient_Soft_Credit__c FROM Pledge__c WHERE Id = :pledge.Id];
        System.assertEquals(secondRecipient.Id, pledge.Recipient_Soft_Credit__c);

        recipient.Recipient_Soft_Credit__c = null;
        update recipient;
        PledgeRecipientSoftCreditService.reconcileRecipientOrganizationKeys(new Set<String>{
            PledgeRecipientSoftCreditService.key(project.Id, organization.Id)
        });
        pledge = [SELECT Recipient_Soft_Credit__c FROM Pledge__c WHERE Id = :pledge.Id];
        System.assertEquals(null, pledge.Recipient_Soft_Credit__c);
    }

    @isTest
    static void clearsWhenMappingIsDeletedAndReconciliationIsRepeatable() {
        Account organization = TestDataFactory.createOrg('Recipient Organization');
        Contact recipientContact = TestDataFactory.createContact(organization.Id, 'Recipient');
        Fundraising_Project__c project = TestDataFactory.createFundraisingProject();
        Pledge__c pledge = TestDataFactory.createPledge(organization.Id, project.Id, 1000);
        Recipient_Organization__c recipient = TestDataFactory.createRecipientOrganization(
            organization.Id,
            project.Id,
            recipientContact.Id
        );
        delete recipient;
        pledge = [SELECT Recipient_Soft_Credit__c FROM Pledge__c WHERE Id = :pledge.Id];
        System.assertEquals(null, pledge.Recipient_Soft_Credit__c);

        Test.startTest();
        PledgeRecipientSoftCreditService.reconcileRecipientOrganizationKeys(new Set<String>{
            PledgeRecipientSoftCreditService.key(project.Id, organization.Id)
        });
        Test.stopTest();
        pledge = [SELECT Recipient_Soft_Credit__c FROM Pledge__c WHERE Id = :pledge.Id];
        System.assertEquals(null, pledge.Recipient_Soft_Credit__c);
    }
}