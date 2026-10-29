/**
 * Author      : Paddy
 * Date        : 07/16/2026
 * Jira   	   : IM-588
 * Description : ReusableGeneric email notification framework that centralizes email generation and delivery using configurable metadata and templates. 
 *               Config is driven by Notification_Config__mdt records.
 * Test Class  : NotificationServiceTest
 */
public with sharing class NotificationService {
    
    //To do - invoke from flow
    //To do - Add email body as an option to the custom meta data config
    //To do - Add option for email attachment

    private static final String ERR_PROCESS_NOTIFICATIONS_FAILED = 'EMAIL_PROCESS_NOTIFICATIONS_FAILED';
    private static final String EMAIL_TEMPLATE_NAME_REQUIRED = 'Email template name is requried.';
    private static final String NOTIFICATION_CONFIG_NAME_REQUIRED = 'Notification config name is requried.';
    private static final String ORGWIDE_ADDRESS_REQUIRED = 'OrgWide address is requried.';
    private static final String ERR_NO_RECIPIENTS = 'EMAIL_NO_RECIPIENTS';
    private static final String NO_RECIPIENTS = 'No recipients resolved for records: ';
    private static final String OBJECT_API_NAME_REQUIRED = 'Object API name is required for record field recipients.';
    private static final String PUBLIC_GROUP_NOT_FOUND = 'Public group not found: ';
    private static final String SOURCE_RECORD_FIELD = 'Record Field';
    private static final String SOURCE_PUBLIC_GROUP = 'Public Group';
    private static final String TO_ADDRESSES = 'toAddresses';
    private static final String CC_ADDRESSES = 'ccAddresses';
    private static final String BCC_ADDRESSES = 'bccAddresses';
    private static final String FIELDS_SUFFIX = 'Fields';
    private static final String PORTAL_TYPE_NONE = 'None';
    private static final String GROUP_TYPE_REGULAR = 'Regular';
    private static final String GROUP_TYPE_ROLE = 'Role';
    private static final String GROUP_TYPE_ROLE_AND_SUBORDINATES = 'RoleAndSubordinates';
    private static final String GROUP_TYPE_ROLE_AND_SUBORDINATES_INTERNAL = 'RoleAndSubordinatesInternal';
    private static final Map<String, String> RECIPIENT_KEYS = new Map<String, String>{
        'To' => TO_ADDRESSES,
        'Cc' => CC_ADDRESSES,
        'Bcc' => BCC_ADDRESSES
    };

    private class ResolvedGroup {
        Set<Id> userIds = new Set<Id>();
        Set<Id> roleIds = new Set<Id>();
        Set<Id> subordinateRoleIds = new Set<Id>();
        Set<Id> internalSubordinateRoleIds = new Set<Id>();
    }

    public class NotificationServiceException extends Exception {}

    /**
    * Description : Entry point. Looks up config, decides sync vs async, and dispatches.
    * Parameters  : String configDeveloperName, Set<Id> recordIds.
    * Return Type : void
    */
    public static void sendEmail(String configDeveloperName, Set<Id> recordIds) {
        sendEmail(configDeveloperName, recordIds, new Map<Id, Map<String, String>>(), null, null);
    }

    /**
    * Description : Entry point. Looks up config, decides sync vs async, and dispatches.
    * Parameters  : String configDeveloperName, Set<Id> recordIds, User currentUser
    * Return Type : void
    */
    public static void sendEmail(String configDeveloperName, Set<Id> recordIds, User currentUser) {
        sendEmail(configDeveloperName, recordIds, new Map<Id, Map<String, String>>(), null, currentUser);
    }

    /**
    * Description : Entry point. Looks up config, decides sync vs async, and dispatches.
    * Parameters  : String configDeveloperName, Set<Id> recordIds, Map<Id, Map<String, String>> customMergeFields.
    * Return Type : void
    */
    public static void sendEmail(String configDeveloperName, Set<Id> recordIds, Map<Id, Map<String, String>> customMergeFields) {
        sendEmail(configDeveloperName, recordIds, customMergeFields, null, null);
    }

    /**
    * Description : Entry point. Looks up config, decides sync vs async, and dispatches.
    * Parameters  : String configDeveloperName, Set<Id> recordIds, Id targetObjectId.
    * Return Type : void
    */
    public static void sendEmail(String configDeveloperName, Set<Id> recordIds, Id targetObjectId) {
        sendEmail(configDeveloperName, recordIds, new Map<Id, Map<String, String>>(), targetObjectId, null);
    }

    /**
    * Description : Entry point. Looks up config, decides sync vs async, and dispatches.
    *               Sends an email notification using the configured template, recipients, and merge field data/
    *               customMergeFields maps each record Id to token key/value pairs. Keys must match
    *               placeholders in the Email template using the <<tokenName>> format.
    *
    *               Example (Foundation Code rename notification):
    *               Map<Id, Map<String, String>> customeMergeFields = new Map<Id, Map<String, String>> {
    *                   foundationCodeId => new Map<String, String> {
    *                                           'oldFoundationCodeName' => 'Arts'
    *                                       }
    *               };
    *               If the template subject/body contains "<<oldFoundationCodeName>>", replaceMergeTokens
    *               replaces it with "Arts" before the email is sent.
    * Parameters  : String configDeveloperName, Set<Id> recordIds, 
                    Map<Id, Map<String, String>> customMergeFields, Id targetObjectId.
    * Return Type : void
    */
    public static void sendEmail(String configDeveloperName, Set<Id> recordIds, 
                Map<Id, Map<String, String>> customMergeFields, Id targetObjectId, User currentUser) {
        if(recordIds == null || recordIds.isEmpty() || String.isBlank(configDeveloperName)) {
            return;
        }
        
        if(customMergeFields == null) {
            customMergeFields = new Map<Id, Map<String, String>>();
        }

        Notification_Config__mdt config = getConfig(configDeveloperName);
        if(config.Active__c == false) {
            return;
        }

        Boolean alreadyAsyncContext = System.isFuture() || System.isBatch() || System.isQueueable();
        if(config.Send_Asynchronously__c == true && !alreadyAsyncContext && !Test.isRunningTest()) {
            System.enqueueJob(new NotificationQueueable(config, recordIds, customMergeFields, targetObjectId, currentUser));
        } else {
            processEmail(config, recordIds, customMergeFields, targetObjectId, currentUser);
        }
    }

    /**
    * Description : Builds and sends one email per record Id using the Notification Config.
    *
    *               Steps:
    *                   1. Resolve the Email Template and Org-Wide From address from config.
    *                   2. Load To/Cc/Bcc recipients from related recipents CMDT.
    *                   3. For each record, call buildEmailFromTemplate with that record's custom tokens
                            from customMergeFields (<<tokenName>> placeholders).
                        4. Set SaveAsActivity, recipients (or targetObjectId), and From address.
                        5. Send all messages via Messaging.sendEmail
    * Parameters  : Notification_Config__mdt config, Set<Id> recordIds,
                    Map<Id, Map<String, String>> customMergeFields, Id targetObjectId, User currentUser
    * Return Type : void
    */ 
    public static void processEmail(Notification_Config__mdt config, Set<Id> recordIds,
                    Map<Id, Map<String, String>> customMergeFields, Id targetObjectId, User currentUser) {
        try {                
            if(customMergeFields == null) {
                customMergeFields = new Map<Id, Map<String, String>>();
            }
    
            Id emailTemplateId = getTemplateId(config.Email_Template_Name__c);
    
            Id fromAddressId = getOrgWideEmailAddressId(config.From_Address__c);

            Map<String, List<String>> recipients = getRecipients(config.Id);
            if(currentUser != null){
                List<String> toRecipients = recipients.get('toAddresses');
                toRecipients.add(currentUser.Email);
            }

            Map<String, List<String>> dynamicRecipients = getDynamicRecipients(config.Id);
            Map<Id, Map<String, List<String>>> recordRecipients = getRecordRecipients(config.Object_API_Name__c, recordIds, dynamicRecipients);

            Boolean hasTarget = targetObjectId != null;
    
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<String> skippedRecordIds = new List<String>();
    
            for(Id recordId : recordIds) {
    
                List<String> toAddresses = mergeAddresses(recipients.get(TO_ADDRESSES), dynamicRecipients.get(TO_ADDRESSES), recordRecipients.get(recordId), TO_ADDRESSES);
                List<String> ccAddresses = mergeAddresses(recipients.get(CC_ADDRESSES), dynamicRecipients.get(CC_ADDRESSES), recordRecipients.get(recordId), CC_ADDRESSES);
                List<String> bccAddresses = mergeAddresses(recipients.get(BCC_ADDRESSES), dynamicRecipients.get(BCC_ADDRESSES), recordRecipients.get(recordId), BCC_ADDRESSES);
                if(!hasTarget && toAddresses.isEmpty() && ccAddresses.isEmpty() && bccAddresses.isEmpty()) {
                    skippedRecordIds.add(String.valueOf(recordId));
                    continue;
                }
                Map<String, String> customTokens = customMergeFields.get(recordId);
                Messaging.SingleEmailMessage email = buildEmailFromTemplate(emailTemplateId, recordId, customTokens, targetObjectId);
                email.setSaveAsActivity(config.Save_As_Activity__c);
                if(hasTarget) {
                    email.setTargetObjectId(targetObjectId);
                } else {
                    email.setToAddresses(recipients.get('toAddresses'));
                    email.setToAddresses(toAddresses);
                    email.setTreatTargetObjectAsRecipient(false);
                }

                email.setCcAddresses(recipients.get('ccAddresses'));
                email.setBccAddresses(recipients.get('bccAddresses'));
                email.setCcAddresses(ccAddresses);
                email.setBccAddresses(bccAddresses);
    
                if(fromAddressId != null) {
                    email.setOrgWideEmailAddressId(fromAddressId);
                }
                emails.add(email);
            }
            if(!skippedRecordIds.isEmpty()) {
                BBApps_ErrorHandler.logErrors(new NotificationServiceException(NO_RECIPIENTS + String.join(skippedRecordIds, ', ')), new BBApps_ErrorCustomFields(ERR_NO_RECIPIENTS));
            }
            if(emails.isEmpty()) {
                return;
            }
            Messaging.sendEmail(emails, false);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_PROCESS_NOTIFICATIONS_FAILED));
            throw new NotificationServiceException('NotificationEmailService-processNotifications failed: ' + ex.getMessage());
        }
    }

    /**
    * Description : Get email template based on developer name.
    * Parameters  : String templateDeveloperName
    * Return Type : Id
    */ 
    private static Id getTemplateId(String templateDeveloperName) {
        if(String.isBlank(templateDeveloperName)) {
            throw new NotificationServiceException(EMAIL_TEMPLATE_NAME_REQUIRED);
        }
        List<EmailTemplate> emailTemplates = [
            SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateDeveloperName LIMIT 1
        ];

        if(emailTemplates.isEmpty()) {
           throw new NotificationServiceException('Email template not found: ' + templateDeveloperName);
        }
        return emailTemplates[0].Id;
    }

    /**
    * Description : Get email ocnfiguration meta data based on developer name.
    * Parameters  : String developerName
    * Return Type : Notification_Config__mdt
    */ 
    public static Notification_Config__mdt getConfig(String developerName) {
        if(String.isBlank(developerName)) {
            throw new NotificationServiceException(NOTIFICATION_CONFIG_NAME_REQUIRED);
        }
        
        List<Notification_Config__mdt> configs = [
            SELECT Id, DeveloperName, Active__c, From_Address__c,
                    Email_Template_Name__c, Object_API_Name__c,
                    Save_As_Activity__c,
                    Send_Asynchronously__c
            FROM Notification_Config__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        if(configs.isEmpty()) {
            throw new NotificationServiceException('Notification config not found: ' + developerName);
        }
        return configs[0];
    }

    /**
    * Description : Get Org wide email address Id based on address or display name.
    * Parameters  : String addressOrName
    * Return Type : Id
    */
    private static Id getOrgWideEmailAddressId(String emailAddress) {
        if(String.isBlank(emailAddress)) {
            throw new NotificationServiceException(ORGWIDE_ADDRESS_REQUIRED);
        }
        List<OrgWideEmailAddress> orgWideAddress = [
            SELECT Id FROM OrgWideEmailAddress 
            WHERE Address = :emailAddress 
            LIMIT 1
        ];
        if(orgWideAddress.isEmpty()) {
            throw new NotificationServiceException('OrgWide address not found: ' + emailAddress);
        }
        return orgWideAddress[0].Id;
    }

    /**
    * Description : Get email recipients meta data based on email notification config.
    * Parameters  : String emailConfig
    * Return Type : IMap<String, List<String>>
    */
    public static Map<String, List<String>> getRecipients(String emailConfig) {
        List<Notification_Receipient__mdt> emailRecipients = [
            SELECT Notification_Config__c, Recipient_Email__c, Recipient_Type__c
            FROM Notification_Receipient__mdt
            WHERE Notification_Config__c = :emailConfig
            AND Environment__c = :Environment.getEnvironment()
        ];
        Map<String, List<String>> recipients = new Map<String, List<String>>();
		List<String> toRecipients = new List<String>();
		List<String> ccRecipients = new List<String>();
		List<String> bccRecipients = new List<String>();
		for(Notification_Receipient__mdt emailRecipient : emailRecipients){
            if(emailRecipient.Recipient_Type__c == 'To'){
                toRecipients.add(emailRecipient.Recipient_Email__c);
            }
            if(emailRecipient.Recipient_Type__c == 'Cc'){
                ccRecipients.add(emailRecipient.Recipient_Email__c);
            }
            if(emailRecipient.Recipient_Type__c == 'Bcc'){
                bccRecipients.add(emailRecipient.Recipient_Email__c);
            }
		}
        recipients.put('toAddresses', toRecipients);
        recipients.put('ccAddresses', ccRecipients);
        recipients.put('bccAddresses', bccRecipients);
		return recipients;
    }

    /**
    * Description : Builds a SingleEmailMessage from a stored Email Template for one related record.
    *
    *               Renders the template with Messaging.renderStoreEmailTemplate using:
    *                   -whoId: targetObjectId when provided, otherwise the running user
    *                   -whatId: the related record Id (merge-field context)
    *
    * Parameters  : Id emailTemplateId, Id whatId, Map<String, String> customTokens, Id targetObjectId
    * Return Type : Messaging.SingleEmailMessage
    */ 
    private static Messaging.SingleEmailMessage buildEmailFromTemplate(Id emailTemplateId, Id whatId, Map<String, String> customTokens, Id targetObjectId) {
        Id whoId = targetObjectId != null ? targetObjectId : UserInfo.getUserId();
        Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(emailTemplateId, whoId, whatId);
        Boolean hasCustomTokens = customTokens != null && !customTokens.isEmpty();
        
        String subject = rendered.getSubject();
        String htmlBody = rendered.getHtmlBody();
        String plainTextBody = rendered.getPlainTextBody();
        
        if(hasCustomTokens) {
           	subject = replaceMergeTokens(subject, customTokens, false);
        	htmlBody = replaceMergeTokens(htmlBody, customTokens, false);
        	plainTextBody = replaceMergeTokens(plainTextBody, customTokens, false);
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(subject != null) {
            email.setSubject(subject);
        }
        if(htmlBody != null) {
            email.setHtmlBody(htmlBody);
        }
        if(plainTextBody != null) {
            email.setPlainTextBody(plainTextBody);
        }
        return email;
    }

    /**
    * Description : Replaces custom <<tokenName>> placeholders in template text with values from tokens.
    *               Placeholder format in the Email Template: <<key>>
    *               Replacement: tokens.get(key)
    *               Example:
    *                   text = "Previous name was <<oldFoundationCodeName>>."
    *                   tokens = {'oldFoundationCodeName' => 'Arts'}
    *                   result = "Previous name was Arts."
    *
    *               When isHtml is ture, token value are HTML-escaped before replacement.
    *               Null token values are replaced with an empty string. Missing tokens leave
    *               the corresponding <<key>> placeholder unchanged.
    * Parameters  : String text, Map<String, String> tokens, Boolean isHtml
    * Return Type : String
    */ 
    private static String replaceMergeTokens(String text, Map<String, String> tokens, Boolean isHtml) {
        if(text == null || tokens == null || tokens.isEmpty()) {
            return text;
        }
        for(String key : tokens.keySet()) {
            String value = tokens.get(key) == null ? '' : tokens.get(key);
            String safeValue = isHtml ? value.escapeHtml4() : value;
            text = text.replace('<<' + key + '>>', safevalue);
        }
        return text;
    }

    @TestVisible
    private static Map<String, List<String>> getDynamicRecipients(String emailConfig) {
        Map<String, List<String>> dynamicRecipients = new Map<String, List<String>>();
        for(String recipientKey : RECIPIENT_KEYS.values()) {
            dynamicRecipients.put(recipientKey, new List<String>());
            dynamicRecipients.put(recipientKey + FIELDS_SUFFIX, new List<String>());
        }

        Map<String, Set<String>> groupNamesByKey = new Map<String, Set<String>>();
        for(Notification_Receipient__mdt emailRecipient : [
            SELECT Recipient_Type__c, Recipient_Source__c, Recipient_Field_API_Name__c, Public_Group_API_Name__c
            FROM Notification_Receipient__mdt
            WHERE Notification_Config__c = :emailConfig
            AND Environment__c = :Environment.getEnvironment()
        ]) {
            String recipientKey = RECIPIENT_KEYS.get(emailRecipient.Recipient_Type__c);
            if(recipientKey == null) {
                continue;
            }
            if(emailRecipient.Recipient_Source__c == SOURCE_PUBLIC_GROUP && String.isNotBlank(emailRecipient.Public_Group_API_Name__c)) {
                if(!groupNamesByKey.containsKey(recipientKey)) {
                    groupNamesByKey.put(recipientKey, new Set<String>());
                }
                groupNamesByKey.get(recipientKey).add(emailRecipient.Public_Group_API_Name__c);
            }
            if(emailRecipient.Recipient_Source__c == SOURCE_RECORD_FIELD && String.isNotBlank(emailRecipient.Recipient_Field_API_Name__c)) {
                dynamicRecipients.get(recipientKey + FIELDS_SUFFIX).add(emailRecipient.Recipient_Field_API_Name__c);
            }
        }

        if(!groupNamesByKey.isEmpty()) {
            Set<String> allGroupNames = new Set<String>();
            for(Set<String> groupNames : groupNamesByKey.values()) {
                allGroupNames.addAll(groupNames);
            }
            Map<String, Set<String>> emailsByGroupName = getGroupMemberEmails(allGroupNames);
            for(String recipientKey : groupNamesByKey.keySet()) {
                for(String groupName : groupNamesByKey.get(recipientKey)) {
                    if(!emailsByGroupName.containsKey(groupName)) {
                        throw new NotificationServiceException(PUBLIC_GROUP_NOT_FOUND + groupName);
                    }
                    dynamicRecipients.get(recipientKey).addAll(emailsByGroupName.get(groupName));
                }
            }
        }
        return dynamicRecipients;
    }

    @TestVisible
    private static Map<String, Set<String>> getGroupMemberEmails(Set<String> groupDeveloperNames) {
        Map<String, Set<String>> emailsByGroupName = new Map<String, Set<String>>();
        if(groupDeveloperNames == null || groupDeveloperNames.isEmpty()) {
            return emailsByGroupName;
        }

        Map<Id, Group> groupsById = new Map<Id, Group>([
            SELECT Id, DeveloperName, Type, RelatedId
            FROM Group
            WHERE Type IN :new Set<String>{
                GROUP_TYPE_REGULAR, GROUP_TYPE_ROLE, GROUP_TYPE_ROLE_AND_SUBORDINATES, GROUP_TYPE_ROLE_AND_SUBORDINATES_INTERNAL
            }
        ]);

        Map<Id, List<Id>> memberIdsByGroupId = new Map<Id, List<Id>>();
        for(GroupMember member : [
            SELECT GroupId, UserOrGroupId
            FROM GroupMember
            WHERE Group.Type = :GROUP_TYPE_REGULAR
        ]) {
            if(!memberIdsByGroupId.containsKey(member.GroupId)) {
                memberIdsByGroupId.put(member.GroupId, new List<Id>());
            }
            memberIdsByGroupId.get(member.GroupId).add(member.UserOrGroupId);
        }

        Map<String, ResolvedGroup> resolvedByGroupName = new Map<String, ResolvedGroup>();
        Boolean hasSubordinateRoles = false;
        for(Group grp : groupsById.values()) {
            if(grp.Type == GROUP_TYPE_REGULAR && groupDeveloperNames.contains(grp.DeveloperName)) {
                ResolvedGroup resolved = new ResolvedGroup();
                collectGroupMembers(grp.Id, groupsById, memberIdsByGroupId, resolved, new Set<Id>());
                resolvedByGroupName.put(grp.DeveloperName, resolved);
                hasSubordinateRoles = hasSubordinateRoles
                    || !resolved.subordinateRoleIds.isEmpty()
                    || !resolved.internalSubordinateRoleIds.isEmpty();
            }
        }

        if(hasSubordinateRoles) {
            Map<Id, List<UserRole>> childRolesByParentId = new Map<Id, List<UserRole>>();
            for(UserRole role : [SELECT Id, ParentRoleId, PortalType FROM UserRole]) {
                if(!childRolesByParentId.containsKey(role.ParentRoleId)) {
                    childRolesByParentId.put(role.ParentRoleId, new List<UserRole>());
                }
                childRolesByParentId.get(role.ParentRoleId).add(role);
            }
            for(ResolvedGroup resolved : resolvedByGroupName.values()) {
                resolved.roleIds.addAll(expandRoles(resolved.subordinateRoleIds, childRolesByParentId, false));
                resolved.roleIds.addAll(expandRoles(resolved.internalSubordinateRoleIds, childRolesByParentId, true));
            }
        }

        Set<Id> allUserIds = new Set<Id>();
        Set<Id> allRoleIds = new Set<Id>();
        for(ResolvedGroup resolved : resolvedByGroupName.values()) {
            allUserIds.addAll(resolved.userIds);
            allRoleIds.addAll(resolved.roleIds);
        }

        Map<Id, String> emailByUserId = new Map<Id, String>();
        Map<Id, Set<String>> emailsByRoleId = new Map<Id, Set<String>>();
        if(!allUserIds.isEmpty() || !allRoleIds.isEmpty()) {
            for(User usr : [
                SELECT Id, Email, UserRoleId
                FROM User
                WHERE IsActive = true
                AND (Id IN :allUserIds OR UserRoleId IN :allRoleIds)
            ]) {
                emailByUserId.put(usr.Id, usr.Email);
                if(usr.UserRoleId != null) {
                    if(!emailsByRoleId.containsKey(usr.UserRoleId)) {
                        emailsByRoleId.put(usr.UserRoleId, new Set<String>());
                    }
                    emailsByRoleId.get(usr.UserRoleId).add(usr.Email);
                }
            }
        }

        for(String groupName : resolvedByGroupName.keySet()) {
            ResolvedGroup resolved = resolvedByGroupName.get(groupName);
            Set<String> emails = new Set<String>();
            for(Id userId : resolved.userIds) {
                if(emailByUserId.containsKey(userId)) {
                    emails.add(emailByUserId.get(userId));
                }
            }
            for(Id roleId : resolved.roleIds) {
                if(emailsByRoleId.containsKey(roleId)) {
                    emails.addAll(emailsByRoleId.get(roleId));
                }
            }
            emailsByGroupName.put(groupName, emails);
        }
        return emailsByGroupName;
    }

    private static void collectGroupMembers(Id groupId, Map<Id, Group> groupsById, Map<Id, List<Id>> memberIdsByGroupId,
                ResolvedGroup resolved, Set<Id> visitedGroupIds) {
        if(visitedGroupIds.contains(groupId) || !groupsById.containsKey(groupId)) {
            return;
        }
        visitedGroupIds.add(groupId);

        Group grp = groupsById.get(groupId);
        if(grp.Type == GROUP_TYPE_ROLE) {
            resolved.roleIds.add(grp.RelatedId);
        } else if(grp.Type == GROUP_TYPE_ROLE_AND_SUBORDINATES) {
            resolved.subordinateRoleIds.add(grp.RelatedId);
        } else if(grp.Type == GROUP_TYPE_ROLE_AND_SUBORDINATES_INTERNAL) {
            resolved.internalSubordinateRoleIds.add(grp.RelatedId);
        }

        if(!memberIdsByGroupId.containsKey(groupId)) {
            return;
        }
        for(Id memberId : memberIdsByGroupId.get(groupId)) {
            if(memberId.getSObjectType() == User.SObjectType) {
                resolved.userIds.add(memberId);
            } else {
                collectGroupMembers(memberId, groupsById, memberIdsByGroupId, resolved, visitedGroupIds);
            }
        }
    }

    private static Set<Id> expandRoles(Set<Id> rootRoleIds, Map<Id, List<UserRole>> childRolesByParentId, Boolean internalOnly) {
        Set<Id> roleIds = new Set<Id>(rootRoleIds);
        List<Id> rolesToVisit = new List<Id>(rootRoleIds);
        while(!rolesToVisit.isEmpty()) {
            Id parentRoleId = rolesToVisit.remove(rolesToVisit.size() - 1);
            if(!childRolesByParentId.containsKey(parentRoleId)) {
                continue;
            }
            for(UserRole childRole : childRolesByParentId.get(parentRoleId)) {
                if(internalOnly && childRole.PortalType != PORTAL_TYPE_NONE) {
                    continue;
                }
                if(roleIds.add(childRole.Id)) {
                    rolesToVisit.add(childRole.Id);
                }
            }
        }
        return roleIds;
    }

    @TestVisible
    private static Map<Id, Map<String, List<String>>> getRecordRecipients(String objectApiName, Set<Id> recordIds,
                Map<String, List<String>> dynamicRecipients) {
        Map<Id, Map<String, List<String>>> recordRecipients = new Map<Id, Map<String, List<String>>>();
        Set<String> fieldNames = new Set<String>();
        for(String recipientKey : RECIPIENT_KEYS.values()) {
            if(dynamicRecipients.containsKey(recipientKey + FIELDS_SUFFIX)) {
                fieldNames.addAll(dynamicRecipients.get(recipientKey + FIELDS_SUFFIX));
            }
        }
        if(fieldNames.isEmpty()) {
            return recordRecipients;
        }
        if(String.isBlank(objectApiName)) {
            throw new NotificationServiceException(OBJECT_API_NAME_REQUIRED);
        }

        Map<String, String> queryPaths = new Map<String, String>();
        for(String fieldName : fieldNames) {
            if(fieldName.trim().toLowerCase() != 'id') {
                queryPaths.put(fieldName.trim().toLowerCase(), fieldName.trim());
            }
        }
        String query = 'SELECT Id' + (queryPaths.isEmpty() ? '' : ', ' + String.join(queryPaths.values(), ', '))
            + ' FROM ' + objectApiName + ' WHERE Id IN :recordIds';
        List<SObject> records = Database.queryWithBinds(query, new Map<String, Object>{ 'recordIds' => recordIds }, AccessLevel.SYSTEM_MODE);

        for(SObject record : records) {
            Map<String, List<String>> addressesByKey = new Map<String, List<String>>();
            for(String recipientKey : RECIPIENT_KEYS.values()) {
                List<String> addresses = new List<String>();
                if(dynamicRecipients.containsKey(recipientKey + FIELDS_SUFFIX)) {
                    for(String fieldName : dynamicRecipients.get(recipientKey + FIELDS_SUFFIX)) {
                        Object value = getFieldValue(record, fieldName.trim());
                        if(value != null && String.isNotBlank(String.valueOf(value))) {
                            addresses.add(String.valueOf(value));
                        }
                    }
                }
                addressesByKey.put(recipientKey, addresses);
            }
            recordRecipients.put(record.Id, addressesByKey);
        }
        return recordRecipients;
    }

    private static Object getFieldValue(SObject record, String queryPath) {
        List<String> pathParts = queryPath.split('\\.');
        SObject current = record;
        for(Integer i = 0; i < pathParts.size() - 1; i++) {
            current = current.getSObject(pathParts[i]);
            if(current == null) {
                return null;
            }
        }
        return current.get(pathParts[pathParts.size() - 1]);
    }

    @TestVisible
    private static List<String> mergeAddresses(List<String> baseAddresses, List<String> groupAddresses,
                Map<String, List<String>> addressesByKey, String recipientKey) {
        List<String> allAddresses = new List<String>();
        if(baseAddresses != null) {
            allAddresses.addAll(baseAddresses);
        }
        if(groupAddresses != null) {
            allAddresses.addAll(groupAddresses);
        }
        if(addressesByKey != null && addressesByKey.containsKey(recipientKey)) {
            allAddresses.addAll(addressesByKey.get(recipientKey));
        }
        Map<String, String> uniqueAddresses = new Map<String, String>();
        for(String address : allAddresses) {
            if(String.isNotBlank(address) && !uniqueAddresses.containsKey(address.trim().toLowerCase())) {
                uniqueAddresses.put(address.trim().toLowerCase(), address.trim());
            }
        }
        return uniqueAddresses.values();
    }
}