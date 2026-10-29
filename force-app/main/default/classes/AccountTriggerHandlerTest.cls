@isTest
private class AccountTriggerHandlerTest {
    @isTest
    static  void testBeforeInsert() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
       // System.assertEquals(false, acc.Has_Special_Char_In_Name__c, 'Special character checkbox should be false');
    }
    @isTest
    static  void testBeforeUpdate() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        acc.Name = 'Test Account &';
        update acc;

        Account updatedAcc = [SELECT Has_Special_Char_In_Name__c FROM Account WHERE Id = :acc.Id with SYSTEM_MODE];
        //System.assertEquals(true, updatedAcc.Has_Special_Char_In_Name__c, 'Special character checkbox should be true');
    }
    @isTest
    static  void testBeforeDelete() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Test.startTest();
        delete acc;
        Test.stopTest();

        List<Account> remainingAccounts = [SELECT Id FROM Account WHERE Id = :acc.Id with SYSTEM_MODE];
        //System.assertNotEquals(0, remainingAccounts.size(), 'Account should not be deleted');
    }
    @isTest
    static  void testAndFinally() {
        // Create test data and perform trigger operations

        // Verify the expected outcomes based on trigger logic
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            accList.add(new Account(Name = 'Test Account ' + i));
        }
        insert accList;

        // Update some accounts
        accList[0].Name = 'Updated Account';
        accList[1].BillingStreet = '123 Test St';
        accList[1].BillingCity = 'Test City';
        accList[1].BillingCountry = 'United States';
        accList[1].BillingState = 'AK';
        accList[1].BillingPostalCode = '413607';
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        dml.optAllOrNone = false;
        Database.update(accList, dml);

        // Delete an account
        delete accList[2];

        // Verify the trigger logic outcomes
        List<Account> updatedAccList = [SELECT Id, Name, BillingStreet FROM Account WHERE Id IN :accList with SYSTEM_MODE];
        System.assertEquals('Updated Account', updatedAccList[0].Name, 'Name should be updated');
        System.assertEquals('123 Test St', updatedAccList[1].BillingStreet, 'Billing Address should be updated');
        System.assertNotEquals(0, updatedAccList.size(), 'Account should not be deleted');

        // Perform additional verifications as needed based on your trigger logic
    }

    @isTest
    static void updatedConvertedNamesTest() {
        Account act = TestDataFactory.getOrg('šurÁ');
        insert act;
        Test.startTest();
        AccountTriggerHandler.updatedConvertedNames(act);
        AccountTriggerHandler.updateReasonField(act);
        Test.stopTest();
        Account account = [SELECT Converted_Org_Name__c FROM Account WHERE Id = :act.Id with SYSTEM_MODE limit 1];
        System.assertEquals('surA', account.Converted_Org_Name__c);
    }

    @isTest
    static void updateContactRestrictedNameTest() {
        Account act = TestDataFactory.getOrg('Test Org');
        insert act;
        Contact con = new Contact(FirstName = 'First', LastName = 'No Validation', AccountId = act.Id);
        insert con;
        Test.startTest();
        AccountTriggerHandler.updateContactRestrictedName(new List<Id>{act.Id}, new Map<Id, Account>{act.Id => act});
        Test.stopTest();
    }

    @isTest
    static  void testUpdateRestrictedOrgName() {
        Account acc = new Account(Name = 'Test Account',Restricted__c = true);
        insert acc;
        Contact con = new Contact (FirstName='First', LastName='No Validation',AccountId=acc.Id);
        insert con;
        Test.startTest();
        acc = [Select Id,Name, Restricted_Org_Name__c from Account where Id =:acc.Id with SYSTEM_MODE];
        System.assertEquals('Test Account',acc.Restricted_Org_Name__c);
        System.assertEquals(Assets.RESTRICTED_ORG_NAME,acc.Name);

        acc.Restricted__c = false;
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        dml.optAllOrNone = false;
        Database.update(acc, dml);
        acc = [Select Id,Name, Restricted_Org_Name__c from Account where Id =:acc.Id with SYSTEM_MODE];
        System.assertEquals(null,acc.Restricted_Org_Name__c);
        System.assertEquals('Test Account',acc.Name);

        acc.Restricted__c = true;
        acc.Restricted_Org_Name__c ='Test Restricted';
        Database.update(acc, dml);

        Test.stopTest();

        acc = [Select Id,Name, Restricted_Org_Name__c,OwnerId from Account where Id =:acc.Id with SYSTEM_MODE];
        System.assertEquals('Test Account',acc.Restricted_Org_Name__c);
        System.assertEquals(Assets.RESTRICTED_ORG_NAME,acc.Name);
        Environment_Setting__mdt envSetting =Environment.getEnvironmentSetting();
        System.assertEquals(envSetting.Restricted_Org_Contact_Owner_Id__c, acc.OwnerId);

    }
    @isTest
    static void ValidateGovtOrgForGeoArea() {
        Map<String, Geo_Area__c> createGeoHierarchy = TestDataFactory.createGeoHierarchy();
        // Step 4: Create City Record (Child of State)
         Geo_Area__c geoArea = createGeoHierarchy.get('City');
        // Create an Account with that Geo Area
        Account existingAccount =   TestDataFactory.getOrg('United States');
        existingAccount.Government_Geo_Area__c = geoArea.Id;
        existingAccount.Org_Type__c ='Government - City';
        insert existingAccount;
        Geo_Area__c newGeoArea =  createGeoHierarchy.get('State');
        // Create another Account with the same Geo Area
        Account newConflictingAccount =  TestDataFactory.getOrg('United Kingdom');
        newConflictingAccount.Government_Geo_Area__c = newGeoArea.Id;
        newConflictingAccount.Org_Type__c ='Government - State';
        insert newConflictingAccount;
        Test.startTest();
        Account existingAccount2 = [SELECT Id, Government_Geo_Area__c FROM Account WHERE Name = 'United States' with SYSTEM_MODE LIMIT 1];
        existingAccount2.Government_Geo_Area__c = newGeoArea.Id;
        try {
            update existingAccount2;
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('The Government Geo Area you selected'), 'Expected error message not found.');
        }
        Test.stopTest();
    }

    @isTest
    static void orgAssociationNameUpdateTest () {
        Account org = TestDataFactory.getOrg('Test Org');
        insert org;

        Focus_Area__c focusArea = TestDataFactory.createFocusArea('Arts');
        insert focusArea;

        Association__c association = TestDataFactory.getAssociation('Test Association', focusArea.Id);
        insert association;

        Org_Association__c orgAssociation = new Org_Association__c (
        	Organization__c = org.Id,
            Association__c = association.Id,
            From__c = System.today(),
            To__c = System.today()
        );

        insert orgAssociation;

        System.assertEquals ('Test Association: Test Org', [Select Id, Name from Org_Association__c with SYSTEM_MODE LIMIT 1].Name);

        Test.startTest();
        org.Name = 'Test Org Updated';
        update org;
        Test.stopTest();
    }
}