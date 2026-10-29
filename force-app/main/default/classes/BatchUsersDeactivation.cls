/**
 * Author : Ravi Bheemreddy
 * Date   : 11/17/2025
 * JIRA   : BRME-6298
 * Description : This class is used to deactivate users post sandbox refresh
 * Test   : BatchUsersDeactivationTest
 **/
public without sharing class BatchUsersDeactivation implements Database.Batchable<SObject>, Database.Stateful {

    public static final String EXCLUDED_GROUP_NAME = Application_Properties__mdt.getInstance('User_Deactivation_Excluded_Public_Group').Value__c;
    private static final String ERR_USER_DEACTIVATE = 'ERR_USER_DEACTIVATE';

    Set<Id> excludedUserIds;
    Id runningUserId;

    public BatchUsersDeactivation() {
        try {
            runningUserId = UserInfo.getUserId();
            excludedUserIds = getAllUsersFromGroupHierarchy(EXCLUDED_GROUP_NAME);
        } catch (Exception e) {
            BBApps_ErrorHandler.logErrors('UsersDeactivationBatch constructor', e);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        String baseQuery = 
            'SELECT Id, IsActive, Username ' +
            'FROM User ' +
            'WHERE IsActive = true ' +
            'AND Profile.Name != null ' +
            'AND Id != \'' + runningUserId + '\' ';
    
        if (!excludedUserIds.isEmpty()) {
            baseQuery += 'AND Id NOT IN :excludedUserIds ';
        }
    
        if (Test.isRunningTest()) {
            baseQuery += ' ORDER BY CreatedDate DESC LIMIT 10';
        }
    
        return Database.getQueryLocator(baseQuery, AccessLevel.SYSTEM_MODE);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            List<User> usersToDeactivate = (List<User>)scope;
            
            for (User u : usersToDeactivate) {
                u.IsActive = false;
            }

            if (!usersToDeactivate.isEmpty()) {
                List<BBApps_DMLResult> result = BBApps_Crud.doUpdateWithHandling(
                    (List<SObject>)usersToDeactivate,
                    false,
                    new BBApps_ErrorCustomFields(ERR_USER_DEACTIVATE)
                );
            }

        } catch (Exception e) {
            BBApps_ErrorHandler.logErrors('UsersDeactivationBatch.execute', e);
        }
    }

    public void finish(Database.BatchableContext bc) {
        
    }

    private static Set<Id> getAllUsersFromGroupHierarchy(String groupName) {
        Group topGroup = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :groupName
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        Set<Id> visitedGroups = new Set<Id>();
        Set<Id> userIds = new Set<Id>();

        collectGroupUsers(topGroup.Id, visitedGroups, userIds);
        return userIds;
    }

    private static void collectGroupUsers(Id groupId, Set<Id> visitedGroups, Set<Id> userIds) {
        if (visitedGroups.contains(groupId)) return;
        visitedGroups.add(groupId);

        for (GroupMember gm : [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE GroupId = :groupId
            WITH SYSTEM_MODE
        ]) {
            if (gm.UserOrGroupId.getSObjectType() == User.sObjectType) {
                userIds.add(gm.UserOrGroupId);
            }
            else if (gm.UserOrGroupId.getSObjectType() == Group.sObjectType) {
                collectGroupUsers(gm.UserOrGroupId, visitedGroups, userIds);
            }
        }
    }
}