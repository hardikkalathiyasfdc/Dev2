public without sharing class UserWithPermissionSetsAuraCtrl {
    public final static Map<String, String> TEAM_LABEL_BY_VALUE = getTeamLabelByValue();
    
    public static Map<Id, Set<Id>> finalUserGroupsMap = new Map<Id, Set<Id>> (); 
    
	public static Map<Id, Set<Id>> directGroupsMap = new Map<Id, Set<Id>> ();
    
    public static Map<Id, Set<Id>> allGroupMembershipsMap = new Map<Id, Set<Id>> ();
    public static Map<Id,Set<Id>> roleBasedGroupsMap = new Map<Id,Set<Id>>();
	public static Set<Id> groupsWithRoles = new Set<Id> ();
	public static Map<Id, Group> groupsMap = new Map<Id, Group> ();
    public static List<GroupMember> allGroupMembers;
    public static Map<Id, List<PermissionSet>> permSetsByGroupId = getPermSetsByGroupId();
    public static Map<Id, String> psgLabelsById;
    public static String IM_PREFIX = 'IM_';
    
    private static final String ERR_GET_ALL_USERS_WITH_PERMISSION_SETS = 'USER_WITH_PERMISSION_SETS_GET_ALL_USERS_FAILED';
    private static final String ERR_DELETE_PERMISSION_SET_ASSIGNMENT = 'USER_WITH_PERMISSION_SETS_DELETE_PERMISSION_SET_ASSIGNMENT_FAILED';
    private static final String ERR_DELETE_PUBLIC_GROUP_MEMBERSHIP = 'USER_WITH_PERMISSION_SETS_DELETE_PUBLIC_GROUP_MEMBERSHIP_FAILED';
    private static final String ERR_SEARCH_PERMISSION_SET = 'USER_WITH_PERMISSION_SETS_SEARCH_PERMISSION_SET_FAILED';
    private static final String ERR_SEARCH_USER = 'USER_WITH_PERMISSION_SETS_SEARCH_USER_FAILED';
    private static final String ERR_REMOVE_TEAM_FROM_PERMISSION_SET = 'USER_WITH_PERMISSION_SETS_REMOVE_TEAM_FROM_PERMISSION_SET_FAILED';
    private static final String ERR_CLONE_PERMISSION = 'USER_WITH_PERMISSION_SETS_CLONE_PERMISSION_FAILED';
    private static final String ERR_SEARCH_TEAMS_BY_PERMISSION = 'USER_WITH_PERMISSION_SETS_SEARCH_TEAMS_BY_PERMISSION_FAILED';
    private static final String ERR_SAVE_PERMISSION_SETS = 'USER_WITH_PERMISSION_SETS_SAVE_PERMISSION_SETS_FAILED';

    @AuraEnabled(cacheable=true)
    public static String getAllUsersWithPermissionSets (Boolean isInitiativeManagement) {
        try {
            Map<Id, User> usersMap = getUsers(isInitiativeManagement);
            Map<Id, UserWrap> userWrap = new Map<Id, UserWrap> ();
            Map<Id, List<Member>> memMap = getPublicGroups (usersMap);
            Map<Id, Set<Id>> usersPermissionSetsMap = new Map<Id, Set<Id>> ();
            Set<Id> allPermissionSetIds = new Set<Id> ();
            Map<Id, String> permSetNameById = new Map<Id, String>();
                    
            for (PermissionSetAssignment assignment : [
                SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSetGroupId
                FROM PermissionSetAssignment
                WHERE AssigneeId IN :usersMap.keyset()
            ]) {
                UserWrap uWrap = new UserWrap();
                if (userWrap.get(assignment.AssigneeId) != null) {
                    uWrap = userWrap.get(assignment.AssigneeId);
                }
                uWrap.u = usersMap.get(assignment.AssigneeId);

                List<PermissionSetAssignment> directAssignments =
                    (uWrap.assignments == null) ? new List<PermissionSetAssignment>() : uWrap.assignments;
                List<PermSetGroupWrap> groupAssignments =
                    (uWrap.permSetGroupAssignments == null) ? new List<PermSetGroupWrap>() : uWrap.permSetGroupAssignments;
                List<AssignmentWrap> allAssignments =
                    (uWrap.allAssignments == null) ? new List<AssignmentWrap>() : uWrap.allAssignments;

                if (assignment.PermissionSetGroupId == null) {
                    directAssignments.add(assignment);
                    if (assignment.PermissionSet.Label == null || !assignment.PermissionSet.Label.startsWith('00e')) {
                        allAssignments.add(new AssignmentWrap(assignment.Id, assignment.PermissionSetId, assignment.PermissionSet.Name, assignment.PermissionSet.Label, true));
                    }
                } else {
                    List<PermissionSet> psInGroup = new List<PermissionSet>();
                    if (permSetsByGroupId.containsKey(assignment.PermissionSetGroupId)) {
                        psInGroup = permSetsByGroupId.get(assignment.PermissionSetGroupId);
                        for (PermissionSet ps : psInGroup) {
                            if (ps.Label == null || !ps.Label.startsWith('00e')) {
                                String lbl = ps.Label;
                                if (psgLabelsById != null && psgLabelsById.containsKey(assignment.PermissionSetGroupId)) {
                                    lbl = ps.Label + ' (PSG: ' + psgLabelsById.get(assignment.PermissionSetGroupId) + ')';
                            }
                                allAssignments.add(new AssignmentWrap(null, ps.Id, ps.Name, lbl, false));
                            }
                        }
                    }
                    groupAssignments.add(new PermSetGroupWrap(assignment, psInGroup));
                }

                Set<Id> permissionSetIds = new Set<Id>();
                if (usersPermissionSetsMap.containskey(assignment.AssigneeId)) {
                    permissionSetIds = usersPermissionSetsMap.get(assignment.AssigneeId);
                }
                permissionSetIds.add(assignment.PermissionSetId);
                allPermissionSetIds.add(assignment.PermissionSetId);
                usersPermissionSetsMap.put(assignment.AssigneeId, permissionSetIds);
                if (assignment.PermissionSetId != null && assignment.PermissionSet != null && assignment.PermissionSet.Label != null) {
                    permSetNameById.put(assignment.PermissionSetId, assignment.PermissionSet.Label);
                }

                uWrap.assignments = directAssignments;
                uWrap.permSetGroupAssignments = groupAssignments;
                uWrap.allAssignments = allAssignments;
                userWrap.put(assignment.AssigneeId, uWrap);
            }

            
            Map<Id, List<Id>> permSetCustomPermissionsMap = new Map<Id, List<Id>> ();
            
            for (SetupEntityAccess s: [SELECT Id, SetupEntityId, ParentId
                                        FROM SetupEntityAccess
                                        WHERE SetupEntityType = 'CustomPermission'
                                        AND ParentId IN: allPermissionSetIds]) 
            {
                if (permSetCustomPermissionsMap.containskey(s.ParentId)) {
                    permSetCustomPermissionsMap.get(s.ParentId).add(s.SetupEntityId);
                } else {
                    permSetCustomPermissionsMap.put (s.ParentId, new List<Id> {s.SetupEntityId});
                }
            }
            
            Map<Id, CustomPermission> customPermissionsMap = new Map<Id, CustomPermission> ([Select Id, MasterLabel from CustomPermission]);
            
            for (Id userId: userWrap.keySet()) {
                List<CustomPermissionWrap> userCustomPermissions = new List<CustomPermissionWrap> ();
                if (usersPermissionSetsMap.containsKey(userId)) {
                    for (Id permSetId: usersPermissionSetsMap.get(userId)) {
                        if (permSetCustomPermissionsMap.containsKey(permSetId)) {
                            for (Id customPermissionId: permSetCustomPermissionsMap.get(permSetId)) {
                                if (customPermissionsMap.get(customPermissionId) != null) {
                                    String psName = permSetNameById.containsKey(permSetId) ? permSetNameById.get(permSetId) : null;
                                    CustomPermission cp = customPermissionsMap.get(customPermissionId);
                                    String lbl = (psName == null ? cp.MasterLabel : cp.MasterLabel + ' (PS: ' + psName + ')');
                                    userCustomPermissions.add(new CustomPermissionWrap(cp.Id, cp.MasterLabel, lbl, psName));
                                }
                            }
                        }
                    }
                }
                
                if (userWrap.containsKey(userId)) userWrap.get(userId).customPermissions = userCustomPermissions;
            }
            
            for (Id userId: memMap.keySet()) {
                UserWrap uWrap = new UserWrap();
                if(userWrap.containsKey(userId) != null) {
                    uWrap = userWrap.get(userId); 
                }
                
                if (memMap.containsKey(userId)) {
                    uWrap.groupMemberships = memMap.get(userId);
                    userWrap.put(userId, uWrap);
                }
            }
            
            return JSON.serialize(userWrap);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_ALL_USERS_WITH_PERMISSION_SETS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void deletePermissionSetAssginment(String recordId) {
        PermissionSetAssignment tmpAssignment = new PermissionSetAssignment(Id=recordId);
        BBApps_Crud.doDeleteWithHandling(tmpAssignment, false, ERR_DELETE_PERMISSION_SET_ASSIGNMENT);
    }
	
    @AuraEnabled
    public static void deletePublicGroupMembership(String recordId) {
        List<String> userIdgroupId = recordId.split(';');
        String userId = userIdgroupId[0];
        String groupId = userIdgroupId[1];
        GroupMember tmpAssignment = [Select Id from GroupMember where UserOrGroupId =: userIdgroupId[0] AND GroupId =: userIdgroupId[1]];
        BBApps_Crud.doDeleteWithHandling(tmpAssignment, false, ERR_DELETE_PUBLIC_GROUP_MEMBERSHIP);
    }
        
    @AuraEnabled(cacheable=true)
    public static String searchPermissionSet(String searchString) {
        try {
            searchString = String.escapeSingleQuotes(searchString);
            String query = 'SELECT Id, Label, Name FROM PermissionSet WHERE Label LIKE \'%'+searchString+'%\' LIMIT 10';
            List<PermissionSet> sets = (List<PermissionSet>)Database.query(query);
            
            return JSON.serialize(sets);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SEARCH_PERMISSION_SET);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String searchUser(String searchString) {
        try {
            searchString = String.escapeSingleQuotes(searchString);
            String query = 'SELECT Id, Name FROM User WHERE Name LIKE \'%'+searchString+'%\' AND IsActive = true LIMIT 10';
            List<User> sets = (List<User>)Database.query(query);
            
            return JSON.serialize(sets);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SEARCH_USER);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void removeTeamFromPermissionSet(String permissionSetId, String team) {
        try {
            List<PermissionSetAssignment> assignments = [SELECT AssigneeId, PermissionSetId
                        FROM PermissionSetAssignment 
                        WHERE PermissionSetId = : permissionSetId
                        AND Assignee.BP_Team__c =: team];
            BBApps_Crud.doDeleteWithHandling(assignments, false, ERR_REMOVE_TEAM_FROM_PERMISSION_SET);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_REMOVE_TEAM_FROM_PERMISSION_SET);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //Method is used to clone permission sets & public groups for selected users
    // the clone action is full clone - by ticket: Develop ability to clone users
    @AuraEnabled
    public static String clonePermission(String copyToUsers, String copyFromUserId) {
        String result = 'success'; 
 
        List<String> copyToUserIds = copyToUsers.split(',');
        List<PermissionSetAssignment> newAssignments = generatePermissionSetAssignments(copyToUserIds, copyFromUserId);
        System.debug(newAssignments.size());
        List<GroupMember> groupMembers = generateGroupMembers(copyToUserIds, copyFromUserId);
        System.debug(groupMembers.size());  
        SavePoint sp = Database.setSavepoint(); 
        try {
            //Delete existing Permission sets & public groups for selected users
            List<PermissionSetAssignment> existingAssignments = [SELECT AssigneeId, PermissionSetId
                    FROM PermissionSetAssignment 
                    WHERE AssigneeId IN : copyToUserIds 
                    AND PermissionSetId IN (SELECT Id 
                                            FROM PermissionSet
                                            WHERE IsOwnedByProfile = false)];
            BBApps_Crud.doDeleteWithHandling(existingAssignments, false, ERR_CLONE_PERMISSION);
            
            List<GroupMember> existingGroupMembers = [SELECT Id, GroupId FROM GroupMember WHERE UserOrGroupId IN: copyToUserIds];
            BBApps_Crud.doDeleteWithHandling(existingGroupMembers, false, ERR_CLONE_PERMISSION);

            //insert new pemission sets & public grpus for selected users
            BBApps_Crud.doInsertWithHandling(newAssignments, false, ERR_CLONE_PERMISSION);
            BBApps_Crud.doInsertWithHandling(groupMembers, false, ERR_CLONE_PERMISSION);
        } catch( Exception ex ) {
            Database.rollback(sp);
            System.debug(ex.getMessage());
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLONE_PERMISSION);
            BBApps_ErrorHandler.logErrors(ex, f);
            result = 'failure';
        }
        
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static String searchTeamsByPermission(String permissionSetId) {
        try {
            Set<String> aws = new Set<String>();
            for( PermissionSetAssignment assignment: [SELECT Assignee.BP_Team__c
                                                       FROM PermissionSetAssignment
                                                       WHERE PermissionSetId =: permissionSetId
                                                       ORDER BY Assignee.BP_Team__c]) {
                if( assignment.Assignee.BP_Team__c != null ) {
                    String team = TEAM_LABEL_BY_VALUE.get(assignment.Assignee.BP_Team__c);
                    String key = team+'|'+assignment.Assignee.BP_Team__c;
                    if( !aws.contains(key) ) {
                        aws.add(key);
                    }
                }
                
            }

            return JSON.serialize(aws);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SEARCH_TEAMS_BY_PERMISSION);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }
    }


    @AuraEnabled
    public static void savePermissionSets(String permissionSet, String teams) {
        try {
            List<String> permissionSetIds = (List<String>)JSON.deserialize(permissionSet, List<String>.class);
            List<String> allTeams = (List<String>)JSON.deserialize(teams, List<String>.class);

            Set<String> existedUserIds = new Set<String>();
            for( PermissionSetAssignment ass: [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSetId IN :permissionSetIds] ) {
                existedUserIds.add( ass.AssigneeId +'-'+ass.PermissionSetId);
            }

            List<PermissionSetAssignment> sets = new List<PermissionSetAssignment>();
            for( User usr: [SELECT Id 
                            FROM User
                            WHERE BP_Team__c IN: allTeams AND ISActive = true
                            ]) {
                for( String permission : permissionSetIds ) {
                    //Check current user with permission is not in existing ones
                    if(!existedUserIds.contains(usr.Id +'-'+permission)){
                        PermissionSetAssignment tmpSet = new PermissionSetAssignment();
                        tmpSet.AssigneeId = usr.Id;
                        tmpSet.PermissionSetId = permission;

                        sets.add(tmpSet);
                    }
                    
                }
            }

            if( sets.size() > 0) {
                BBApps_Crud.doInsertWithHandling(sets, false, ERR_SAVE_PERMISSION_SETS);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SAVE_PERMISSION_SETS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static Map<String, String> getTeamLabelByValue(){
        Map<String, String> pickListValuesList = new Map<String, String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get('User');
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get('BP_Team__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.put(pickListVal.getValue(), pickListVal.getLabel());
        }     
        return pickListValuesList;
    }

    private static List<PermissionSetAssignment> generatePermissionSetAssignments(List<String> copyToUserIds, String copyFromUserId) {
        List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
        PermissionSetAssignment newAssignment = null;
        for( PermissionSetAssignment psa : [SELECT Id, PermissionSetId, PermissionSet.Label,
                                            Assignee.Name
                                            FROM PermissionSetAssignment
                                            WHERE AssigneeId =: copyFromUserId
                                            AND PermissionSetId IN (SELECT Id 
                                                    FROM PermissionSet
                                                    WHERE IsOwnedByProfile = false)] ) {
            for( String assigneeId : copyToUserIds ) {
                newAssignment = new PermissionSetAssignment();
                newAssignment.AssigneeId = assigneeId;
                newAssignment.PermissionSetId = psa.PermissionSetId;
                newAssignments.add(newAssignment);
            }
            
        }

        return newAssignments;
    }

    private static List<GroupMember> generateGroupMembers(List<String> copyToUserIds, String copyFromUserId) {
        List<GroupMember> newAssignments = new List<GroupMember>();
        GroupMember newAssignment = null;
        for( GroupMember gm : [SELECT Id, GroupId
                                FROM GroupMember
                                WHERE UserOrGroupId =: copyFromUserId] ) {
            for( String userId : copyToUserIds ) {
                newAssignment = new GroupMember();
                newAssignment.UserOrGroupId = userId;
                newAssignment.GroupId = gm.GroupId;
                newAssignments.add(newAssignment);
            }
            
        }

        return newAssignments;
    }
    
    public static Map<Id, List<Member>> getPublicGroups (Map<Id, User> usersMap) {
        allGroupMembers = [select id, UserOrGroupId, Groupid, group.Name from GroupMember];
    
        // Identify all role based groups.
        setRoleBasedGroups ();
        
        // Identify all group members that a user is directly part of and add to final map.
        setDirectUserGroups (usersMap);
        
        // Add all the role based groups identified above and add to final map
        consolidateRoleBasedIds (usersMap);
        
        // Identify all group members that a user is not directly part of and add to final map.
        // This would take all the group memberships through hierarchy.
        consolidateIndirectGroupIds (usersMap);
                                                       
        Map<Id, List<Member>> allUserMembersMap = new Map<Id, List<Member>> ();
        
        // Final iteration to consolidate all user based groups
        for (Id userId: finalUserGroupsMap.keySet()) {
            List<Member> allMembers = new List<Member> ();
            for (Id groupId: finalUserGroupsMap.get(userId)) {
                
                // Exclude role based groups
                if (groupsWithRoles.contains(groupId)) {
                    continue;
                }
                
                // Flag groups that a user is directly part of
                Boolean isDirect = false;
                if (directGroupsMap.containsKey(userId) && directGroupsMap.get(userId).contains(groupId)) {
                    isDirect = true;
                }
                
                if (groupsMap.containsKey(groupId)) {
                    Member mem = new Member (groupsMap.get(groupId),userId,isDirect);
                	allMembers.add (mem);
                }
            }
            
            allUserMembersMap.put (userId, allMembers);
        }
        
        return allUserMembersMap;
    }
    
    private static void setRoleBasedGroups () {
        groupsMap = new Map<Id, Group> ([select id,relatedid,name,developername from Group where Type IN ('Regular','Role','RoleAndSubordinates','RoleAndSubordinatesInternal')]);
        for(Group gr : groupsMap.values()){
            if (gr.RelatedId != null) { // If related id is present that means group is for role
                groupsWithRoles.add(gr.Id);
                Set<Id> allIds = new Set<Id> ();
                if(roleBasedGroupsMap.containsKey(gr.relatedId)){
                    allIds = roleBasedGroupsMap.get(gr.relatedId);
                }
                allIds.add(gr.Id);
                roleBasedGroupsMap.put(gr.RelatedId, allIds);
            }
        }
    }
    
    private static void setDirectUserGroups (Map<Id, User> usersMap) {
        for(GroupMember gm: allGroupMembers)
        {
            if (usersMap.containsKey(gm.UserOrGroupId)) {
                Set<Id> groupIds = new Set<Id> ();
                if (finalUserGroupsMap.containsKey(gm.UserOrGroupId)) {
                    groupIds = finalUserGroupsMap.get(gm.UserOrGroupId);
                }
                groupIds.add (gm.groupId);
                finalUserGroupsMap.put(gm.UserOrGroupId, groupIds);
                
                Set<Id> allDirectGroupIds = new Set<Id> ();
                if (directGroupsMap.containsKey(gm.UserOrGroupId)) {
                    allDirectGroupIds = directGroupsMap.get(gm.UserOrGroupId);
                }
                allDirectGroupIds.add (gm.groupId);
                directGroupsMap.put(gm.UserOrGroupId, allDirectGroupIds);
            }
                        
            Set<Id> allgroupIds = new Set<Id> ();
            
            if (allGroupMembershipsMap.containsKey(gm.UserOrGroupId)) {
                allgroupIds = allGroupMembershipsMap.get(gm.UserOrGroupId);
            }
            
            allgroupIds.add (gm.groupId);
			allGroupMembershipsMap.put(gm.UserOrGroupId, allgroupIds);
        }
    }
    
    private static void consolidateIndirectGroupIds (Map<Id, User> usersMap) {
        for(GroupMember gr: allGroupMembers) {
            if (usersMap.keySet().contains(gr.UserOrGroupId)) { // direct ones are already added in finalgroupmap , then no need to add again. hence skipping
                continue;
            }
            Boolean exists = false;
			
            // Add all indirect groups to the final map
            for (Id userId: finalUserGroupsMap.keySet()) {
                Set<Id> allIds = finalUserGroupsMap.get(userId);
                
                if (allIds.contains(gr.UserOrGroupId)) {
                    allIds.add(gr.Groupid);
                    if (allGroupMembershipsMap.containsKey(gr.Groupid)) {
                        allIds.addAll(allGroupMembershipsMap.get(gr.Groupid));
                    }
                    finalUserGroupsMap.put(userId,allIds); 
                }
            }           
        }
    }
    
    private static void consolidateRoleBasedIds (Map<Id, User> usersMap) {
        for(User u: usersMap.values ()) {
            Set<Id> roleBasedIds = new Set<Id> ();
            if(roleBasedGroupsMap.containsKey(u.UserRoleId))
            {
                roleBasedIds.addAll(roleBasedGroupsMap.get(u.UserRoleId));
            }
            
            Set<Id> allIds = new Set<Id> ();
            
            if (finalUserGroupsMap.containsKey(u.Id)) {
                allIds = finalUserGroupsMap.get(u.Id);                
            }
            
            allIds.addAll (roleBasedIds);
            
            finalUserGroupsMap.put (u.Id, allIds);
        }
    }
    
    public class UserWrap {
        public User u {get; set;}
        public List<PermissionSetAssignment> assignments {get;set;}
        public List<PermSetGroupWrap> permSetGroupAssignments {get;set;}
        public List<AssignmentWrap> allAssignments {get;set;}
        public List<CustomPermissionWrap> customPermissions {get; set;}
        public List<Member> groupMemberships {get;set;}
    }
    
    public class Member { 
        public Group userGroup;
        public Id groupId;
        public Boolean isDirect = false;
        public String userIdgroupId;
        public Member (Group gr, Id userId, Boolean direct) {
            userGroup = gr;
            groupId = gr.Id;
            userIdgroupId = userId+';'+groupId;
            isDirect = direct;
        }
    }

    public class AssignmentWrap {
        public Id assignmentId;
        public Id permissionSetId;
        public String permissionSetName;
        public String permissionSetLabel;
        public Boolean isDirect;
        public AssignmentWrap(Id aId, Id psId, String psName, String psLabel, Boolean d) {
            assignmentId = aId;
            permissionSetId = psId;
            permissionSetName = psName;
            permissionSetLabel = psLabel;
            isDirect = d;
        }
    }

    public class PermSetGroupWrap {
        public PermissionSetAssignment groupAssignment { get; set; }
        public List<PermissionSet> permissionSets { get; set; }
        public PermSetGroupWrap() {}
        public PermSetGroupWrap(PermissionSetAssignment a, List<PermissionSet> ps) {
            this.groupAssignment = a;
            this.permissionSets = (ps == null) ? new List<PermissionSet>() : ps;
        }
    }

    public class CustomPermissionWrap {
        public Id id;
        public String masterLabel;
        public String label;
        public String permissionSetName;
        public CustomPermissionWrap(Id i, String ml, String l, String psn) {
            id = i;
            masterLabel = ml;
            label = l;
            permissionSetName = psn;
        }
    }

    private static Map<Id, List<PermissionSet>> getPermSetsByGroupId(){
        Map<Id, List<PermissionSet>> mapRes = new Map<Id, List<PermissionSet>>();
        for (PermissionSetGroupComponent c : [SELECT PermissionSetGroupId, PermissionSetId, PermissionSet.Name, PermissionSet.Label FROM PermissionSetGroupComponent]) {
            List<PermissionSet> lst = mapRes.containsKey(c.PermissionSetGroupId) ? mapRes.get(c.PermissionSetGroupId) : new List<PermissionSet>();
            lst.add(new PermissionSet(Id=c.PermissionSetId, Name=c.PermissionSet.Name, Label=c.PermissionSet.Label));
            mapRes.put(c.PermissionSetGroupId, lst);
        }
        Set<Id> gid = new Set<Id>(mapRes.keySet());
        if (!gid.isEmpty()) {
            psgLabelsById = new Map<Id, String>();
            for (PermissionSetGroup g : [SELECT Id, MasterLabel FROM PermissionSetGroup WHERE Id IN :gid]) {
                psgLabelsById.put(g.Id, g.MasterLabel);
            }
        }
        return mapRes;
    }

    private static Map<Id, User> getUsers(Boolean isInitiativeManagement){
        if (isInitiativeManagement == true) {
            Set<Id> imUserIds = new Set<Id>();
            
            for (PermissionSetAssignment psa : [
                SELECT AssigneeId, PermissionSet.Name
                FROM PermissionSetAssignment
            ]) {
                if (psa.PermissionSet != null && psa.PermissionSet.Name != null && psa.PermissionSet.Name.startsWith(IM_PREFIX)) {
                    imUserIds.add(psa.AssigneeId);
                }
            }
            
            for (GroupMember gm : [
                SELECT UserOrGroupId, Group.DeveloperName
                FROM GroupMember
            ]) {
                if (
                    gm.Group != null &&
                    gm.Group.DeveloperName != null &&
                    gm.Group.DeveloperName.startsWith(IM_PREFIX) &&
                    String.valueOf(gm.UserOrGroupId).startsWith('005')
                ) {
                    imUserIds.add((Id)gm.UserOrGroupId);
                }
            }
            
            if (imUserIds.isEmpty()) {
                return new Map<Id, User>();
            }
            
            List<User> filtered = [
                SELECT Id, Name, BP_Team__c, Sharing_Team__c, UserRoleId, Profile.Name, LastLoginDate
                FROM User
                WHERE IsActive = true
                AND Profile.Name != null
                AND Id IN :imUserIds
            ];
            return new Map<Id, User>(filtered);
        } else {
            return new Map<Id, User>([
                Select Id, Name, BP_Team__c, Sharing_Team__c, UserRoleId, Profile.Name, LastLoginDate 
                from User 
                where IsActive = true and Profile.Name != null
            ]);
        }
    }
}