@isTest
public with sharing class SpecialCharactersHelperTest {
    
    @isTest
  public static void validateSpecialCharactersInsert() {
        Contact c = [
			SELECT Id, Has_Special_Char_In_Name__c, Name
			FROM Contact WITH SYSTEM_MODE
			LIMIT 1
        ];
        Account a = [SELECT Id, Has_Special_Char_In_Name__c FROM Account WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(
            c.Has_Special_Char_In_Name__c,
        	true,
        	'failed to determine contact name has special characters'
        );
        System.assertEquals(
            a.Has_Special_Char_In_Name__c,
			true,
			'failed to determine account name has special characters'
        );
    }
    
    @isTest
    public static void validateSpecialCharactersUpdate() {
        Contact c = [
		SELECT Id, Has_Special_Char_In_Name__c, FirstName, LastName, MiddleName
		FROM Contact WITH SYSTEM_MODE
		LIMIT 1
    	];
        c.FirstName = 'ɸ';
        update c;
        Account a = [
			SELECT Id, Has_Special_Char_In_Name__c, Name
			FROM Account WITH SYSTEM_MODE
			LIMIT 1
		];
        a.Name = 'ɸ';
        update a;
        c = [
			SELECT Id, Has_Special_Char_In_Name__c, FirstName, LastName, MiddleName
			FROM Contact WITH SYSTEM_MODE
			LIMIT 1
		];
        a = [SELECT Id, Has_Special_Char_In_Name__c, Name FROM Account LIMIT 1];
        System.assertEquals(
            c.Has_Special_Char_In_Name__c,
			true,
			'failed to determine contact name has special characters'
        );
        System.assertEquals(
            a.Has_Special_Char_In_Name__c,
			true,
			'failed to determine account name has special characters'
        );
    }
    
    @isTest
    static void updateSpecialCharCheckbox_exceptionCoverage() {
        Test.startTest();
        SpecialCharactersHelper.updateSpecialCharCheckbox('abc', null, 'Name');
        Test.stopTest();
    }
    
    @isTest
    static void convertSpecialCharToEnglish_overload_exceptionCoverage() {
        Test.startTest();
        String result = SpecialCharactersHelper.convertSpecialCharToEnglish('abc', null);
        Test.stopTest();
    }
    
    @isTest
    public static void validateSpecialCharactersUpdateNeg() {
        Contact c = [
			SELECT Id, Has_Special_Char_In_Name__c, FirstName, LastName, MiddleName
			FROM Contact WITH SYSTEM_MODE
			LIMIT 1
		];
        c.FirstName = '';
        c.LastName = 'c';
        update c;
        Account a = [
			SELECT Id, Has_Special_Char_In_Name__c, Name
			FROM Account WITH SYSTEM_MODE
			LIMIT 1
    	];
        a.Name = 'a';
        update a;
		c = [
			SELECT Id, Has_Special_Char_In_Name__c, FirstName, LastName, MiddleName
			FROM Contact WITH SYSTEM_MODE
			LIMIT 1
		];
        a = [SELECT Id, Has_Special_Char_In_Name__c, Name FROM Account WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(
            c.Has_Special_Char_In_Name__c,
			false,
			'failed to determine contact name has special characters'
        );
        System.assertEquals(
            a.Has_Special_Char_In_Name__c,
			false,
			'failed to determine account name has special characters'
        );
    }
    
    @TestSetup
    public static void makeData() {
        Contact c = new Contact(LastName = '�');
        insert c;
        Account acct = new Account(Name = '�');
        insert acct;
    }
}