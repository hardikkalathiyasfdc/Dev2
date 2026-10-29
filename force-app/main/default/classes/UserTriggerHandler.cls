/**
* Author : Neha
* Date   : 05/02/2024
* Jira   : BRME-5205
* Description : This class is the handler class for User trigger.
* Test : UserTriggerHandler_Test
*/

public without sharing class UserTriggerHandler extends TriggerHandler {
    public List<User> newUsers;
    public List<User> oldUsers;
    public Map<Id, User> oldUsersMap;
    public Map<Id, User> newUsersmap;
    public Boolean isBeforeTrigger = false;
    public Boolean isAfterTrigger = false;
    public Boolean isUpdateTrigger = false;
    public Boolean isDeleteTrigger = false;
    public Boolean isInsertTrigger = false;
    private static List<PermissionSetAssignment> permissionSetsAssignmentTBD = new List<PermissionSetAssignment>();
    private static List<GroupMember> groupMemberTBD = new List<GroupMember>();
    private List<GroupMember> groupMembersInsertList = new List<GroupMember>();
    private List<GroupMember> groupMembersDeleteList = new list<GroupMember> ();
    
    private static final String ERR_BULK_AFTER = 'USER_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_AND_FINALLY = 'USER_TRIGGER_AND_FINALLY_FAILED';

    public UserTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, User>) Trigger.oldMap, (Map<Id, User>) Trigger.newMap);
        if (Trigger.isBefore) isBeforeTrigger = true;
        if (Trigger.isAfter)  isAfterTrigger = true;
        if (Trigger.isUpdate) isUpdateTrigger = true;
        if (Trigger.isDelete) isDeleteTrigger = true; 
        if (Trigger.isInsert) isInsertTrigger = true;       
    }

    public UserTriggerHandler (List<User> oldUserList, List<User> newUserList, Map<Id, User> oldMap, Map<Id, User> newMap) {
        oldUsers = oldUserList;
        newUsers = newUserList;
        oldUsersMap = oldMap;
        newUsersMap = newMap;
    }

    public override void bulkAfter() {
        try {
            if(isAfterTrigger) {
                if(isUpdateTrigger) {
                    processBulkAfterUpdateOperations();
                    processTeamsPublicGroups();
                }
                if(isInsertTrigger) {
                    processTeamsPublicGroups();
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BULK_AFTER);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    private void processTeamsPublicGroups() {
        Map<Id, String> newUserTeamsMap = new Map<Id, String>();
        Map<Id, String> oldUserTeamsMap = new Map<Id, String>();
        //New user is created
        if(isInsertTrigger){
            for(User u : newUsers) {
                if(u.IsActive) {                  
                    newUserTeamsMap.put(u.Id, Assets.DEPT_PUBLICGROUP_PREFIX + u.Sharing_Team__c);                    
                }
            }
        } else if(isUpdateTrigger) {
            for(User u : newUsers) {
                //Sharing_team of active user is updated
                if( (u.Sharing_Team__c != oldUsersMap.get(u.Id).Sharing_Team__c) && u.IsActive) {
                    newUserTeamsMap.put(u.Id, (Assets.DEPT_PUBLICGROUP_PREFIX + u.Sharing_Team__c));
                    oldUserTeamsMap.put(u.Id, (Assets.DEPT_PUBLICGROUP_PREFIX + oldUsersMap.get(u.Id).Sharing_Team__c));
                } else if( u.IsActive && (!oldUsersMap.get(u.Id).IsActive)) {
                    //Inactive user is made active
                    newUserTeamsMap.put(u.Id, (Assets.DEPT_PUBLICGROUP_PREFIX + u.Sharing_Team__c) );
                }   
                //when user is made inactive, public group for the user is automatically removed from GroupMember
            }

            if(!oldUserTeamsMap.isEmpty()) {
                groupMembersDeleteList = [SELECT Id 
                                          FROM GroupMember 
                                          WHERE Group.Name In :oldUserTeamsMap.values() AND 
                                                UserOrGroupId In :oldUserTeamsMap.keyset()];
            }
        }
        createTeamGroupMembers(newUserTeamsMap);
    }

    private void createTeamGroupMembers(Map<Id, String> newUserTeamsMap) {
        if(!newUserTeamsMap.isEmpty()) {
            Map<String, Id> publicGroupMap = new Map<String, Id>();
            for(Group grp : [SELECT Name FROM Group WHERE Name In : newUserTeamsMap.Values()]){
                publicGroupMap.put(grp.Name, grp.Id);
            }
            for(Id usrId : newUserTeamsMap.keySet()) {
                if(publicGroupMap.containsKey(newUserTeamsMap.get(usrId))) {
                    GroupMember gm = new GroupMember();
                    gm.GroupId = publicGroupMap.get(newUserTeamsMap.get(usrId));
                    gm.UserOrGroupId = usrId;
                    groupMembersInsertList.add(gm);
                }
            }
            
        }
    }

    private void processBulkAfterUpdateOperations () {
        List<Id> usrlst = new List<Id>();
        for(User o : newUsers){
            if(o.IsActive != oldUsersMap.get(o.Id).IsActive && o.IsActive == false) {
                usrlst.add(o.Id);
            }
        }
        if(!usrlst.isEmpty()) deleteRelatedpermissionSets(usrlst);
    }

    public override void andFinally() {
        try {
            if(isAfterTrigger) {
                if(isUpdateTrigger) {
                    if(!permissionSetsAssignmentTBD.isEmpty()) BBApps_Crud.doDeleteWithHandling(permissionSetsAssignmentTBD, false, ERR_AND_FINALLY);
                    if(!groupMemberTBD.isEmpty()) BBApps_Crud.doDeleteWithHandling(groupMemberTBD, false, ERR_AND_FINALLY);
                    if(groupMembersInsertList.size() > 0) {
                        BBApps_Crud.doInsertWithHandling(groupMembersInsertList, false, ERR_AND_FINALLY);
                    }
                    if(groupMembersDeleteList.size() > 0) {
                        BBApps_Crud.doDeleteWithHandling(groupMembersDeleteList, false, ERR_AND_FINALLY);
                    }
                }
                if(isInsertTrigger) {
                    if(groupMembersInsertList.size() > 0) {
                        BBApps_Crud.doInsertWithHandling(groupMembersInsertList, false, ERR_AND_FINALLY);
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_AND_FINALLY);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    private void deleteRelatedpermissionSets(List<Id> usrId) {        
        permissionSetsAssignmentTBD = [SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name, PermissionSet.Label
                                       FROM PermissionSetAssignment 
                                       WHERE AssigneeId IN :usrId AND 
                                             PermissionSet.IsOwnedByProfile = false];
        groupMemberTBD = [SELECT Id, UserOrGroupId, Group.Name
                          FROM GroupMember
                          WHERE UserOrGroupId IN :usrId];
    }
}