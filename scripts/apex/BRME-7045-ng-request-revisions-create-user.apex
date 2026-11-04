String grantEmail = 'ng.grant.contact@bimtest.example';
List<Profile> profiles = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'System Administrator') LIMIT 1];
Profile profileToUse = profiles.isEmpty() ? [SELECT Id FROM Profile LIMIT 1] : profiles[0];
List<User> existingUsers = [SELECT Id, Email FROM User WHERE Email = :grantEmail LIMIT 1];
if (existingUsers.isEmpty()) {
    User grantsUser = new User(
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
    System.debug('Created NG grants user: ' + grantsUser.Id + ' / ' + grantEmail);
} else {
    System.debug('NG grants user already exists: ' + existingUsers[0].Id + ' / ' + grantEmail);
}