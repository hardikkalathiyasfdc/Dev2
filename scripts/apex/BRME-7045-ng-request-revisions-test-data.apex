// NG Request Revisions test data
// Run from the project root with: sf apex run --file scripts/apex/ng-request-revisions-test-data.apex
// This creates a record starting with NG that matches the Request Revisions workflow:
// - Status = Ready for Approval
// - Grants Contact assigned
// - Parent + Budgeted initiative created
// - Uses a Grants contact user so the send-back email path can be exercised

String initiativeName = 'NG Request Revisions Demo';
String parentName = initiativeName;
String teamName = 'Arts';
String grantEmail = 'ng.grant.contact+' + System.now().getTime() + '@example.com';

List<Profile> profiles = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'System Administrator') LIMIT 1];
Profile profileToUse = profiles.isEmpty() ? [SELECT Id FROM Profile LIMIT 1] : profiles[0];

// Create a user for the Grants Contact lookup if needed.
List<User> existingUsers = [SELECT Id, Username, Email FROM User WHERE Email = :grantEmail LIMIT 1];
User grantsUser;
if (existingUsers.isEmpty()) {
    grantsUser = new User(
        FirstName = 'NG',
        LastName = 'Grant Contact',
        Email = grantEmail,
        Username = grantEmail,
        Alias = 'nggrant',
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = profileToUse.Id,
        Sharing_Team__c = 'System Administration'
    );
    insert grantsUser;
} else {
    grantsUser = existingUsers[0];
}

System.runAs(grantsUser) {
    // Create or reuse the team used by the initiative.
    List<Team__c> teams = [SELECT Id, Name FROM Team__c WHERE Name = :teamName LIMIT 1];
    Team__c team;
    if (teams.isEmpty()) {
        Focus_Area__c focusArea = new Focus_Area__c(Name = teamName);
        insert focusArea;
        team = new Team__c(Name = teamName, Focus_Area__c = focusArea.Id);
        insert team;
    } else {
        team = teams[0];
    }

    // Create the account and contact representing the Grants Contact on the initiative.
    List<Account> grantOrgs = [SELECT Id FROM Account WHERE Name = 'NG Grants Org' LIMIT 1];
    Account grantOrg;
    if (grantOrgs.isEmpty()) {
        grantOrg = new Account(Name = 'NG Grants Org');
        insert grantOrg;
    } else {
        grantOrg = grantOrgs[0];
    }

    List<Contact> grantContacts = [SELECT Id, BRM_User__c FROM Contact WHERE AccountId = :grantOrg.Id AND Email = :grantEmail LIMIT 1];
    Contact grantsContact;
    if (grantContacts.isEmpty()) {
        grantsContact = new Contact(
            FirstName = 'NG',
            LastName = 'Grant Contact',
            AccountId = grantOrg.Id,
            Email = grantEmail,
            BRM_User__c = grantsUser.Id
        );
        insert grantsContact;
    } else {
        grantsContact = grantContacts[0];
        if (grantsContact.BRM_User__c == null) {
            grantsContact.BRM_User__c = grantsUser.Id;
            update grantsContact;
        }
    }

    // Parent initiative required by the record type rules.
    List<IM_Initiative__c> parentInitiatives = [SELECT Id FROM IM_Initiative__c WHERE Name = :parentName AND Initiative_Type__c = 'Parent' LIMIT 1];
    IM_Initiative__c parentInitiative;
    if (parentInitiatives.isEmpty()) {
        Id parentRecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Parent Initiative').getRecordTypeId();
        parentInitiative = new IM_Initiative__c(
            Name = parentName,
            Initiative_Type__c = 'Parent',
            Team__c = team.Id,
            RecordTypeId = parentRecordTypeId
        );
        insert parentInitiative;
    } else {
        parentInitiative = parentInitiatives[0];
    }

    // Budgeted initiative to test the Request Revisions quick action.
    List<IM_Initiative__c> initiatives = [SELECT Id, Name, Status__c, Grants_Team_Contact__c FROM IM_Initiative__c WHERE Name = :initiativeName + ' 1.0' LIMIT 1];
    IM_Initiative__c initiative;
    if (initiatives.isEmpty()) {
        Id budgetedRecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Budgeted Initiative').getRecordTypeId();
        initiative = new IM_Initiative__c(
            Name = initiativeName + ' 1.0',
            Initiative_Type__c = 'New',
            Status__c = 'Ready for Approval',
            Team__c = team.Id,
            Parent_Initiative__c = parentInitiative.Id,
            Grants_Team_Contact__c = grantsUser.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12),
            RecordTypeId = budgetedRecordTypeId
        );
        insert initiative;
    } else {
        initiative = initiatives[0];
        initiative.Grants_Team_Contact__c = grantsUser.Id;
        initiative.Status__c = 'Ready for Approval';
        update initiative;
    }

    System.debug('Created/updated NG initiative: ' + initiative.Id);
    System.debug('Grants contact user: ' + grantsUser.Id);
    System.debug('Initiative status: ' + initiative.Status__c);
}
