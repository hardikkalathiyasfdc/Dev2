@isTest
public with sharing class FileGroupControllerTest {
	@testSetup
	static void setup() {
		User imGrantsTeamUser = TestDataFactory.createUserWithPermissionSetGroup('IM', 'GrantsTeamUser', 'Teams User', 'IM_Grants_Team', 'IM_Grant_Team');
		User imCommsUser = TestDataFactory.createUserWithPermissionSetGroup('IM', 'CommsUser', 'Teams User', 'IM_Comms_Team', 'IM_All_Teams');

		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		List<File_Group__c> fgList = [
			SELECT Id, Category__c
			FROM File_Group__c
			WHERE Parent_Initiative__c = :budgetedInitiative.Id AND Category__c = 'Strategy'
			WITH SYSTEM_MODE
		];
		File_Link__c fl = TestDataFactory.createFileLink('Test File', 'http://testlink.com', fgList[0].Id);
	}

	@isTest
	public static void testGetPermissions() {
		User imGrantsTeamUser = [SELECT Id FROM User WHERE LastName = 'GrantsTeamUser' WITH SYSTEM_MODE];
		PermissionSet fileGroupEditPS = [SELECT Id FROM PermissionSet WHERE Name = 'File_Group_Edit_Access' WITH SYSTEM_MODE];
		PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = imGrantsTeamUser.Id, PermissionSetId = fileGroupEditPS.Id);
		insert as system psa;
		CustomPermission customPerm = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'IM_Final_Doc_Tab_Access' WITH SYSTEM_MODE];
		SetupEntityAccess sea = new SetupEntityAccess(ParentId = fileGroupEditPS.Id, SetupEntityId = customPerm.Id);
		insert as system sea;
		System.runAs(imGrantsTeamUSer) {
			IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
			Test.startTest();
			Boolean isPermission = FileGroupController.getPermissions('IM_Final_Doc_Tab_Access', '', budgetedInitiative.Id);
			Assert.areEqual(false, isPermission);
			Test.stopTest();
		}
	}

	@isTest
	public static void testNullPermissions() {
		Boolean isPermission;
		Test.startTest();
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		isPermission = FileGroupController.getPermissions('', '', initiative.Id);
		Test.stopTest();
		Assert.areEqual(true, isPermission);
	}

	@isTest
	public static void testNoPermissions() {
		Boolean isPermission;
		Test.startTest();
		isPermission = FileGroupController.getPermissions('Dummy_Permission', '', UserInfo.getUserId());
		Test.stopTest();
		Assert.areEqual(true, isPermission);
	}

	@isTest
	public static void testGetFileGroup() {
		List<IM_Initiative__c> initiative = [SELECT Id, Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		List<File_Group__c> fgList = [SELECT Id FROM File_Group__c WITH SYSTEM_MODE LIMIT 1];
		String fgId;
		Test.startTest();
		fgId = FileGroupController.getFileGroup(String.valueOf(initiative[0].Id), 'Strategy', 'IM_Initiative__c');
		Test.stopTest();
		Assert.areEqual(String.valueOf(fgList[0].Id), fgId);
	}

	@isTest
	public static void testGetFileGroupException() {
		try {
			List<IM_Initiative__c> initiative = [SELECT Id, Name FROM IM_Initiative__c WITH SYSTEM_MODE LIMIT 1];
			List<File_Group__c> fgList = [SELECT Id FROM File_Group__c WITH SYSTEM_MODE LIMIT 1];
			String fgId;
			Test.startTest();
			fgId = FileGroupController.getFileGroup(String.valueOf(initiative[0].Id), 'Strategy', 'IM_Announcement__c');
			Test.stopTest();
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
	}

	@isTest
	public static void testUploadFileLink() {
		List<File_Group__c> fgList = [SELECT Id FROM File_Group__c WITH SYSTEM_MODE LIMIT 1];
		Id fgId;
		Test.startTest();
		fgId = FileGroupController.uploadFileLink(String.valueOf(fgList[0].Id), 'Test File', 'http://testlink.com');
		Test.stopTest();
		List<File_Link__c> fl = [SELECT Id, Name FROM File_Link__c WHERE Id = :fgId WITH SYSTEM_MODE LIMIT 1];
		Assert.areEqual('Test File', fl[0].Name);
	}

	@isTest
	public static void testGetAllFiles() {
		Map<String, List<SObject>> filesMap = new Map<String, List<SObject>>();
		List<File_Group__c> fgList = [SELECT Id FROM File_Group__c WITH SYSTEM_MODE LIMIT 1];
		ContentVersion contentVersion = new ContentVersion(
			Title = 'Test File',
			PathOnClient = 'test.txt',
			VersionData = Blob.valueOf('Test Content'),
			IsMajorVersion = true
		);
		insert as system contentVersion;

		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WITH SYSTEM_MODE];
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.LinkedEntityId = fgList[0].Id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.ShareType = 'V';
		cdl.Visibility = 'AllUsers';
		insert as system cdl;

		List<File_Link__c> fl = [SELECT Id, Name, Link_URL__c, File_Group__c FROM File_Link__c WITH SYSTEM_MODE];

		Test.startTest();
		filesMap = FileGroupController.getAllFiles(fgList[0].Id);
		Test.stopTest();
		List<File_Link__c> links = filesMap.get('Links');
		List<ContentDocumentLink> files = filesMap.get('Files');
		Assert.areEqual(fl[0].Name, links[0].Name);
		Assert.areEqual(fgList[0].Id, files[0].LinkedEntityId);
	}

	@isTest
	public static void testDeleteFile() {
		List<File_Group__c> fgList = [SELECT Id FROM File_Group__c WITH SYSTEM_MODE LIMIT 1];
		ContentVersion contentVersion = new ContentVersion(
			Title = 'Test File',
			PathOnClient = 'test.txt',
			VersionData = Blob.valueOf('Test Content'),
			IsMajorVersion = true
		);
		insert as system contentVersion;

		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WITH SYSTEM_MODE];
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.LinkedEntityId = fgList[0].Id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.ShareType = 'V';
		cdl.Visibility = 'AllUsers';
		insert as system cdl;

		List<File_Link__c> fl = [SELECT Id, Name, Link_URL__c, File_Group__c FROM File_Link__c WITH SYSTEM_MODE LIMIT 1];

		Test.startTest();
		FileGroupController.deleteFile(fl[0].Id, 'Link');
		FileGroupController.deleteFile(documents[0].Id, '');
		Test.stopTest();
	}
}