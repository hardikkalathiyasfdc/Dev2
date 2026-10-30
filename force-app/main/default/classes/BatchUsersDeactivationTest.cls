/**
 * Author : Ravi Bheemreddy
 * Date   : 11/17/2025
 * JIRA   : BRME-6298
 * Description : Test class for BatchUsersDeactivation
 **/
@isTest
public class BatchUsersDeactivationTest {

    @testSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Teams User' WITH SYSTEM_MODE LIMIT 1];
        Group g = [Select Id from Group where DeveloperName =: BatchUsersDeactivation.EXCLUDED_GROUP_NAME WITH SYSTEM_MODE LIMIT 1];
        
        List<User> usersToInsert = new List<User> ();
        User runningUser = new User(
            ProfileId = p.Id,
            LastName = 'RunningUser',
            Email = 'runninguser@testbbph.com',
            Username = 'runninguser@testbbph.com',
            Alias = 'runusr',
            Sharing_Team__c = 'Arts',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        usersToInsert.add(runningUser);

        User excludedUser = new User(
            ProfileId = p.Id,
            LastName = 'Excluded',
            Email = 'excluded@testbbph.com',
            Username = 'excluded@testbbph.com',
            Alias = 'exclu',
            Sharing_Team__c = 'Arts',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        usersToInsert.add(excludedUser);

        User normalUser = new User(
            ProfileId = p.Id,
            LastName = 'Normal',
            Email = 'normal@testbbph.com',
            Username = 'normal@testbbph.com',
            Alias = 'norml',
            Sharing_Team__c = 'Other',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        usersToInsert.add(normalUser);
        insert as system usersToInsert;
                
        insert as system new GroupMember(GroupId = g.Id, UserOrGroupId = excludedUser.Id);
    }

    @isTest
    static void testBatchDeactivation() {
        User runAsUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() WITH SYSTEM_MODE LIMIT 1];

        System.runAs(runAsUser) {
            Test.startTest();
            Database.executeBatch(new BatchUsersDeactivation(), 500);
            Test.stopTest();
        }

        User excluded = [SELECT IsActive FROM User WHERE Username = 'excluded@testbbph.com' WITH SYSTEM_MODE LIMIT 1];
        User normal  = [SELECT IsActive FROM User WHERE Username = 'normal@testbbph.com' WITH SYSTEM_MODE LIMIT 1];
        
        System.assert(excluded.IsActive, 'Excluded user should be active');
        System.assert(!normal.IsActive, 'Normal user should be deactivated');
        
    }
}