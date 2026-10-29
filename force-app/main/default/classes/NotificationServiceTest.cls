/**
 * Author      : Paddy
 * Date        : 07/21/2026
 * Description : Test class for NotificationService.
 */
@isTest
public class NotificationServiceTest {
    
    private static final String TEST_TEMPLATE_DEV_NAME = 'NS_Test_Email_Template';
	private static final String MISSING_TEMPLATE_DEV_NAME = 'NS_Missing_Template_Does_Not_Exist';
	private static final String UNKNOWN_CONFIG_NAME = 'NS_Config_Does_Not_Exist';
	
    @TestSetup
	static void setup() {
		EmailTemplate template = new EmailTemplate(
			DeveloperName = TEST_TEMPLATE_DEV_NAME,
			Name = 'NES Test Email Template',
			Subject = 'Notification <<oldFoundationCodeName>>',
			Body = 'Plain body <<oldFoundationCodeName>>',
			HtmlValue = '<html><body>Html body <<oldFoundationCodeName>></body></html>',
			TemplateType = 'custom',
			FolderId = UserInfo.getUserId(),
			IsActive = true
		);
		insert template;
	}

	@isTest
	static void testSendNotificationsEarlyReturns() {
		Test.startTest();
            try {
                NotificationService.sendEmail(null, new Set<Id>{UserInfo.getUserId()});
                NotificationService.sendEmail('', new Set<Id>{UserInfo.getUserId()});
                NotificationService.sendEmail(UNKNOWN_CONFIG_NAME, null);
                NotificationService.sendEmail(UNKNOWN_CONFIG_NAME, new Set<Id>());
                NotificationService.sendEmail(UNKNOWN_CONFIG_NAME, new Set<Id>{UserInfo.getUserId()});
                NotificationService.sendEmail(
                    UNKNOWN_CONFIG_NAME,
                    new Set<Id>{UserInfo.getUserId()},
                    new Map<Id, Map<String, String>>()
                );
                NotificationService.sendEmail(
                    UNKNOWN_CONFIG_NAME,
                    new Set<Id>{UserInfo.getUserId()},
                    UserInfo.getUserId()
                );
                NotificationService.sendEmail(
                    UNKNOWN_CONFIG_NAME,
                    new Set<Id>{UserInfo.getUserId()},
                    null,
                    UserInfo.getUserId(), null
                );
            } catch (NotificationService.NotificationServiceException ex) {
				Assert.isTrue(
                    ex.getMessage().contains('Notification config not found:'),
                    'Exception should mention Notification config not found:'
                );
            }
		Test.stopTest();
		Assert.areEqual(0, Limits.getEmailInvocations(), 'No emails should be sent for early-return paths');
	}

	@isTest
	static void testGetConfigNotFound() {
        Test.startTest();
        	try {
                Notification_Config__mdt config = NotificationService.getConfig(UNKNOWN_CONFIG_NAME);
            } catch (NotificationService.NotificationServiceException ex) {
                Assert.isTrue(
                    ex.getMessage().contains('Notification config not found:'),
                    'Exception should mention Notification config not found:'
                );
            }
        Test.stopTest();
	}

	@isTest
	static void testGetConfigWhenPresent() {
		List<Notification_Config__mdt> existingConfigs = [
			SELECT DeveloperName
			FROM Notification_Config__mdt
			LIMIT 1
		];
		if (existingConfigs.isEmpty()) {
			return;
		}
        Test.startTest();
		    Notification_Config__mdt config = NotificationService.getConfig(existingConfigs[0].DeveloperName);
            Assert.isNotNull(config, 'Existing config should be returned');
            Assert.areEqual(existingConfigs[0].DeveloperName, config.DeveloperName);
        Test.stopTest();
	}

	@isTest
	static void testGetRecipientsStructure() {
		Test.startTest();
		    Map<String, List<String>> recipients = NotificationService.getRecipients(null);
		
            Assert.isTrue(recipients.containsKey('toAddresses'), 'toAddresses key expected');
            Assert.isTrue(recipients.containsKey('ccAddresses'), 'ccAddresses key expected');
            Assert.isTrue(recipients.containsKey('bccAddresses'), 'bccAddresses key expected');
            Assert.isNotNull(recipients.get('toAddresses'));
            Assert.isNotNull(recipients.get('ccAddresses'));
            Assert.isNotNull(recipients.get('bccAddresses'));
        Test.stopTest();
	}

	@isTest
	static void testGetRecipientsForExistingConfig() {
		List<Notification_Config__mdt> existingConfigs = [
			SELECT Id, DeveloperName
			FROM Notification_Config__mdt
			LIMIT 1
		];
		if (existingConfigs.isEmpty()) {
			return;
		}
        Test.startTest();
		Map<String, List<String>> recipients = NotificationService.getRecipients(existingConfigs[0].Id);
            Assert.isTrue(recipients.containsKey('toAddresses'));
            Assert.isTrue(recipients.containsKey('ccAddresses'));
            Assert.isTrue(recipients.containsKey('bccAddresses'));
        Test.stopTest();
	}

	@isTest
	static void testProcessNotificationsSuccess() {
		Notification_Config__mdt config = buildActiveConfig(TEST_TEMPLATE_DEV_NAME, false);
		Set<Id> recordIds = new Set<Id>{UserInfo.getUserId()};
		Test.startTest();
            NotificationService.processEmail(config, recordIds, null, UserInfo.getUserId(), null);
            Integer emailCount = Limits.getEmailInvocations();
            Assert.isTrue(emailCount > 0, 'At least one email should be sent');
		Test.stopTest();
	}

	@isTest
	static void testProcessNotificationsWithCustomTokens() {
		Notification_Config__mdt config = buildActiveConfig(TEST_TEMPLATE_DEV_NAME, false);
		Id recordId = UserInfo.getUserId();
		Map<Id, Map<String, String>> customMergeData = new Map<Id, Map<String, String>>{
			recordId => new Map<String, String>{
				'oldFoundationCodeName' => 'Arts',
				'nullToken' => null
			}
		};
		Test.startTest();
            NotificationService.processEmail(config, new Set<Id>{recordId}, customMergeData, recordId, null);
            Integer emailCount = Limits.getEmailInvocations();
            Assert.isTrue(emailCount > 0, 'Email with custom tokens should be sent');
		Test.stopTest();
	}

	@isTest
	static void testProcessNotificationsNullCustomMergeMap() {
		Notification_Config__mdt config = buildActiveConfig(TEST_TEMPLATE_DEV_NAME, false);
		Test.startTest();
            NotificationService.processEmail(
                config,
                new Set<Id>{UserInfo.getUserId()},
                null,
                            UserInfo.getUserId(),
							null
            );
            Integer emailCount = Limits.getEmailInvocations();
            Assert.isTrue(emailCount > 0, 'Email should send when custom merge map is null');
		Test.stopTest();
	}

	@isTest
	static void testProcessNotificationsMissingTemplateThrows() {
		Notification_Config__mdt config = buildActiveConfig(MISSING_TEMPLATE_DEV_NAME, false);
		Test.startTest();
            try {
                NotificationService.processEmail(
                    config,
                    new Set<Id>{UserInfo.getUserId()},
                    null,
                    UserInfo.getUserId(),
					null
                );
            } catch (NotificationService.NotificationServiceException ex) {
                Assert.isTrue(
                    ex.getMessage().contains('Email template not found') ||
                        ex.getMessage().contains('processNotifications failed'),
                    'Exception should mention missing template or process failure'
                );
            }
		Test.stopTest();
	}

	@isTest
	static void testSendNotificationsWithExistingConfig() {
		List<Notification_Config__mdt> configs = [
			SELECT DeveloperName, Active__c, Send_Asynchronously__c, Email_Template_Name__c
			FROM Notification_Config__mdt
			WHERE Active__c = TRUE
			LIMIT 1
		];
		if (configs.isEmpty()) {
			return;
		}
		Notification_Config__mdt config = configs[0];
		Set<Id> recordIds = new Set<Id>{UserInfo.getUserId()};
		Test.startTest();
            try {
                NotificationService.sendEmail(config.DeveloperName, recordIds, UserInfo.getUserId());
                NotificationService.sendEmail(
                    config.DeveloperName,
                    recordIds,
                    new Map<Id, Map<String, String>>{
                        UserInfo.getUserId() => new Map<String, String>{'oldFoundationCodeName' => 'Prior Name'}
                    },
                    UserInfo.getUserId(),
					null
                );
            } catch (NotificationService.NotificationServiceException ex) {
                Assert.isTrue(
                    String.isNotBlank(ex.getMessage()),
                    'Service exception should include a message when send fails'
                );
            }
		Test.stopTest();
	}

	@isTest
	static void testSendNotificationsInactiveOrMissingReturns() {
		List<Notification_Config__mdt> inactiveConfigs = [
			SELECT DeveloperName
			FROM Notification_Config__mdt
			WHERE Active__c = FALSE
			LIMIT 1
		];
		Test.startTest();
        try {
                if (!inactiveConfigs.isEmpty()) {
                    NotificationService.sendEmail(
                        inactiveConfigs[0].DeveloperName,
                        new Set<Id>{UserInfo.getUserId()},
                        UserInfo.getUserId()
                    );
                }
                NotificationService.sendEmail(
                    UNKNOWN_CONFIG_NAME,
                    new Set<Id>{UserInfo.getUserId()},
                    new Map<Id, Map<String, String>>(),
                    UserInfo.getUserId(),
					null
                );
        } catch (NotificationService.NotificationServiceException ex) {
            Assert.isTrue(
                    ex.getMessage().contains('Notification config not found:'),
                    'Exception should mention missing Notification config'
                );
        }
            Assert.areEqual(0, Limits.getEmailInvocations(), 'Inactive/missing config should not send email');
		Test.stopTest();	
	}

	@isTest
	static void testQueueableProcessNotifications() {
		Notification_Config__mdt config = buildActiveConfig(TEST_TEMPLATE_DEV_NAME, true);
		Set<Id> recordIds = new Set<Id>{UserInfo.getUserId()};
		Test.startTest();
            new NotificationQueueable(config, recordIds, null, UserInfo.getUserId(), null).execute(null);
        	Integer emailCount = Limits.getEmailInvocations();
		Test.stopTest();
		Assert.isTrue(emailCount > 0, 'Queueable should send at least one email');
	}
    
    @isTest
	static void testQueueableProcessNotificationsWithTwoParams() {
		Notification_Config__mdt config = buildActiveConfig(TEST_TEMPLATE_DEV_NAME, true);
		Set<Id> recordIds = new Set<Id>{UserInfo.getUserId()};
		Test.startTest();
            new NotificationQueueable(config, recordIds).execute(null);
        	Integer emailCount = Limits.getEmailInvocations();
		Test.stopTest();
		Assert.areEqual(0, emailCount, 'Queueable should skip the email when no recipients are resolved');
	}
    
    @isTest
	static void testQueueableProcessNotificationsWithThreeParams() {
		Notification_Config__mdt config = buildActiveConfig(TEST_TEMPLATE_DEV_NAME, true);
        Id recordId = UserInfo.getUserId();
        Map<Id, Map<String, String>> customMergeData = new Map<Id, Map<String, String>>{
			recordId => new Map<String, String>{
				'oldFoundationCodeName' => 'Arts'
			}
		};
		Set<Id> recordIds = new Set<Id>{UserInfo.getUserId()};
		Test.startTest();
            new NotificationQueueable(config, recordIds, customMergeData).execute(null);
        	Integer emailCount = Limits.getEmailInvocations();
		Test.stopTest();
		Assert.areEqual(0, emailCount, 'Queueable should skip the email when no recipients are resolved');
	}

	@isTest
	static void testProcessNotificationsWithFromAddress() {
		String fromAddress;
		List<OrgWideEmailAddress> orgWideAddresses = [
			SELECT Address, DisplayName
			FROM OrgWideEmailAddress
			LIMIT 1
		];
		if (!orgWideAddresses.isEmpty()) {
			fromAddress = orgWideAddresses[0].Address;
		}
		Notification_Config__mdt config = buildActiveConfig(TEST_TEMPLATE_DEV_NAME, false);
		config.From_Address__c = fromAddress;
		Test.startTest();
            NotificationService.processEmail(
                config,
                new Set<Id>{UserInfo.getUserId()},
                null,
                UserInfo.getUserId(),
				null
            );
            Integer emailCount = Limits.getEmailInvocations();
            Assert.isTrue(emailCount > 0, 'Email should send with optional From Address');
        Test.stopTest();
	}

	@isTest
	static void testGetGroupMemberEmailsResolvesUsersNestedGroupsAndRoles() {
		UserRole parentRole = new UserRole(Name = 'NS Parent Role', DeveloperName = 'NS_Parent_Role_Test');
		insert parentRole;
		UserRole childRole = new UserRole(Name = 'NS Child Role', DeveloperName = 'NS_Child_Role_Test', ParentRoleId = parentRole.Id);
		UserRole directRole = new UserRole(Name = 'NS Direct Role', DeveloperName = 'NS_Direct_Role_Test');
		insert new List<UserRole>{ childRole, directRole };

		Map<String, Id> roleIdByAlias = new Map<String, Id>{
			'nsdir' => null,
			'nsnst' => null,
			'nsrol' => directRole.Id,
			'nspar' => parentRole.Id,
			'nschd' => childRole.Id,
			'nsina' => null
		};
		Map<String, User> usersByAlias = new Map<String, User>();
		for (String alias : roleIdByAlias.keySet()) {
			User usr = TestDataFactory.createUser('Notification', alias);
			usr.UserRoleId = roleIdByAlias.get(alias);
			usr.IsActive = alias != 'nsina';
			usersByAlias.put(alias, usr);
		}
		update as system usersByAlias.values();
		for (User savedUser : [SELECT Id, LastName, Email FROM User WHERE Id IN :usersByAlias.values() WITH SYSTEM_MODE]) {
			usersByAlias.put(savedUser.LastName, savedUser);
		}

		Group outerGroup = new Group(Name = 'NS Outer Test', DeveloperName = 'NS_Outer_Test', Type = 'Regular');
		Group nestedGroup = new Group(Name = 'NS Nested Test', DeveloperName = 'NS_Nested_Test', Type = 'Regular');
		Group middleGroup = new Group(Name = 'NS Middle Test', DeveloperName = 'NS_Middle_Test', Type = 'Regular');
		insert new List<Group>{ outerGroup, nestedGroup, middleGroup };

		Id directRoleGroupId = [SELECT Id FROM Group WHERE RelatedId = :directRole.Id AND Type = 'Role' LIMIT 1].Id;
		Id parentSubordinatesGroupId = [SELECT Id FROM Group WHERE RelatedId = :parentRole.Id AND Type = 'RoleAndSubordinates' LIMIT 1].Id;
		List<GroupMember> members = new List<GroupMember>{
			new GroupMember(GroupId = outerGroup.Id, UserOrGroupId = usersByAlias.get('nsdir').Id),
			new GroupMember(GroupId = outerGroup.Id, UserOrGroupId = usersByAlias.get('nsina').Id),
			new GroupMember(GroupId = outerGroup.Id, UserOrGroupId = nestedGroup.Id),
			new GroupMember(GroupId = outerGroup.Id, UserOrGroupId = directRoleGroupId),
			new GroupMember(GroupId = outerGroup.Id, UserOrGroupId = parentSubordinatesGroupId),
			new GroupMember(GroupId = nestedGroup.Id, UserOrGroupId = usersByAlias.get('nsnst').Id),
			new GroupMember(GroupId = outerGroup.Id, UserOrGroupId = middleGroup.Id),
			new GroupMember(GroupId = middleGroup.Id, UserOrGroupId = nestedGroup.Id)
		};
		for (Group internalGroup : [SELECT Id FROM Group WHERE RelatedId = :parentRole.Id AND Type = 'RoleAndSubordinatesInternal' LIMIT 1]) {
			members.add(new GroupMember(GroupId = nestedGroup.Id, UserOrGroupId = internalGroup.Id));
		}
		insert members;

		Test.startTest();
            Map<String, Set<String>> emailsByGroupName = NotificationService.getGroupMemberEmails(
                new Set<String>{ 'NS_Outer_Test', 'NS_Missing_Group_Test' }
            );
            Map<String, Set<String>> emptyResult = NotificationService.getGroupMemberEmails(new Set<String>());
		Test.stopTest();

		Set<String> emails = emailsByGroupName.get('NS_Outer_Test');
		Assert.isTrue(emptyResult.isEmpty(), 'No group names should resolve nothing');
		Assert.isFalse(emailsByGroupName.containsKey('NS_Missing_Group_Test'), 'Missing group should not resolve');
		Assert.isTrue(emails.contains(usersByAlias.get('nsdir').Email), 'Direct user should be included');
		Assert.isTrue(emails.contains(usersByAlias.get('nsnst').Email), 'Nested group user should be included');
		Assert.isTrue(emails.contains(usersByAlias.get('nsrol').Email), 'Role user should be included');
		Assert.isTrue(emails.contains(usersByAlias.get('nspar').Email), 'Parent role user should be included');
		Assert.isTrue(emails.contains(usersByAlias.get('nschd').Email), 'Subordinate role user should be included');
		Assert.isFalse(emails.contains(usersByAlias.get('nsina').Email), 'Inactive user should be excluded');
	}
    
	private static Notification_Config__mdt buildActiveConfig(String templateDeveloperName, Boolean sendAsync) {
        List<OrgWideEmailAddress> orgWideAddress = [SELECT Address FROM OrgWideEmailAddress LIMIT 1];
		return new Notification_Config__mdt(
			DeveloperName = 'NES_Test_Config',
			MasterLabel = 'NES Test Config',
			Active__c = true,
			Email_Template_Name__c = templateDeveloperName,
			Save_As_Activity__c = false,
			Send_Asynchronously__c = sendAsync,
			From_Address__c = orgWideAddress[0].Address
		);
	}
}