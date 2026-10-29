@isTest
private class InactiveElectedStatusBatch_Test {

	@testSetup
    static void dataPrep() {
        Account acct = new Account(Name = 'Bloomberg Philanthropies');
        insert acct;

        Contact con1 = new Contact(FirstName='First1', LastName='Last12', AccountId = acct.Id, Bio_Photo__c = 'Bio Photo', Bio_Confidential_Notes__c = 'Bio Confidential Notes', 
                                Bio_Description__c = 'Bio Description', Team_s__c = 'IT',Categories__c = 'Education;Nonprofit', Office_Phone_Country_Code__c='United States(+1)', Phone='2121231234');
        insert con1;

        ElectedOffice__c eo1 = new ElectedOffice__c();
        eo1.Contact__c = con1.Id;
        eo1.ElectedStatus__c = 'Active';
        eo1.TermEndDate__c = Date.today().addDays(-1);

        ElectedOffice__c eo2 = new ElectedOffice__c();
        eo2.ElectedStatus__c = 'Inactive';
        eo2.Contact__c = con1.Id;
        eo2.TermEndDate__c = Date.today().addDays(2);


        ElectedOffice__c eo3 = new ElectedOffice__c();
        eo3.ElectedStatus__c = 'Active';
        eo3.Contact__c = con1.Id;
        eo3.TermEndDate__c = Date.today().addDays(2);

        insert new List<ElectedOffice__c>{eo1, eo2, eo3};
    }

    @isTest
    static void processInactivation() {
    	InactiveElectedStatusScheduler batch = new InactiveElectedStatusScheduler();
    	Test.startTest();

    	batch.execute(null);
    	Test.stopTest();

    	System.assertEquals(2, [SELECT Id FROM ElectedOffice__c WHERE ElectedStatus__c = 'Inactive'].size(), 'Election Status is not updated correctly');
    }
}