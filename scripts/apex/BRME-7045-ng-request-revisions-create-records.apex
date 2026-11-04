String ticketTag = ' BRME-7045';
String baseName = 'NG Request Revisions Demo';
String initiativeName = baseName + ticketTag;
String parentName = initiativeName;
String budgetedName = baseName + ' 1.0' + ticketTag;
String teamName = 'Arts';
String grantEmail = 'ng.grant.contact@bimtest.example';

// Use the generated user created in the previous transaction, if not found then create a fallback.
List<User> userMatches = [SELECT Id, Email FROM User WHERE FirstName = 'NG' AND LastName = 'Grant Contact' ORDER BY CreatedDate DESC LIMIT 1];
User grantsUser = userMatches.isEmpty() ? [SELECT Id, Email FROM User WHERE Email = 'ng.grant.contact@bimtest.example' LIMIT 1] : userMatches[0];
if (grantsUser == null) {
    throw new AuraHandledException('No NG grants user exists. Run ng-request-revisions-create-user.apex first.');
}

// Reuse same email name if user exists.
grantEmail = grantsUser.Email;

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
        BRM_User__c = grantsUser.Id,
        Bgive_Id__c = '6891'
    );
    insert grantsContact;
} else {
    grantsContact = grantContacts[0];
    if (grantsContact.BRM_User__c == null || String.isBlank(grantsContact.Bgive_Id__c)) {
        grantsContact.BRM_User__c = grantsUser.Id;
        grantsContact.Bgive_Id__c = '6891';
        update grantsContact;
    }
}

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

List<IM_Initiative__c> initiatives = [SELECT Id, Name, Status__c, Grants_Team_Contact__c FROM IM_Initiative__c WHERE Name = :budgetedName LIMIT 1];
IM_Initiative__c initiative;
if (initiatives.isEmpty()) {
    Id budgetedRecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Budgeted Initiative').getRecordTypeId();
    initiative = new IM_Initiative__c(
        Name = budgetedName,
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

System.debug('NG initiative: ' + initiative.Id);
System.debug('NG grants user: ' + grantsUser.Id);
System.debug('NG status: ' + initiative.Status__c);
