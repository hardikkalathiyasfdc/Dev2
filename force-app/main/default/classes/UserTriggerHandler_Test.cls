@isTest
public class UserTriggerHandler_Test {

	@testSetup
    static void dataSetup() {
        User createUser = TestDataFactory.createUser();
    }
    
    @isTest
    static void testDeletePS() {
        User usr = [SELECT Id FROM User WHERE IsActive = true AND LastName = 'Check' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
            usr.IsActive = false;
            update as system usr;
        Test.stopTest();
    }
    
    @isTest 
    public static void testTeamPublicGroups() {
        User user = [SELECT Id, Sharing_Team__c FROM User WHERE IsActive = true AND LastName = 'Check' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
            List<GroupMember> groupMember = [SELECT Group.Name FROM GroupMember WHERE UserOrGroupId = :user.Id WITH SYSTEM_MODE];
            Assert.areEqual(Assets.DEPT_PUBLICGROUP_PREFIX + user.Sharing_Team__c, groupMember[0]?.Group.Name);
            user.Sharing_Team__c = 'Arts';
            update as system user;
            List<GroupMember> groupMemberAfterUpdate = [SELECT Group.Name FROM GroupMember WHERE UserOrGroupId = :user.Id WITH SYSTEM_MODE];
            Assert.areEqual(Assets.DEPT_PUBLICGROUP_PREFIX + 'Arts' , groupMemberAfterUpdate[0]?.Group.Name);
            // Check if group is deleted when user is inactive
            user.IsActive = false;
            update as system user;
        Test.stopTest();
    }
}