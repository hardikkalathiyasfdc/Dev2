/*
 * test class: DailyChatterEmailBatchTest
 * ChangeLog:
 * Paddy - 10/05/2026: BRME-6983: Added logice to skip email notification if the content is empty.
 */
global without sharing class DailyChatterEmailBatch implements Database.Batchable<sObject>, Database.Stateful {
    private static final String ERR_EXECUTE = 'DAILY_CHATTER_EMAIL_BATCH_EXECUTE_FAILED';
    private static final String ERR_FINISH = 'DAILY_CHATTER_EMAIL_BATCH_FINISH_FAILED';

    public static String query = 'SELECT Id, ParentId FROM FeedItem WHERE CreatedDate = LAST_N_DAYS:1';
    public static DateTime now = DateTime.now();
    public Set<Id> usersToNotifySet = new Set<Id>();

    public static Id emailTemplateId = [
		SELECT Id, Name, DeveloperName
		FROM EmailTemplate
		WHERE DeveloperName = 'Daily_Digest'
  	].Id;

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
    try{
        Set<Id> followedSet = getFollowedSet(scope);
        List<EntitySubscription> subList = [
			SELECT Id, ParentId, SubscriberId
			FROM EntitySubscription
			WHERE ParentId IN :followedSet
		];
        for (EntitySubscription sub : subList) {
            usersToNotifySet.add(sub.SubscriberId);
        }
         } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_EXECUTE));
        }	

    }

    global void finish(Database.BatchableContext BC) {
        try{
        sendNotifications();
       } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FINISH));
        }   
    }

    private void sendNotifications() {
        List<User> userList = [
			SELECT Id
			FROM User
			WHERE Chatter_Digest__c = TRUE AND Id IN :usersToNotifySet
		];
        if (userList.isEmpty()) return;
        sendBatchEmails(userList);
    }

    private void sendBatchEmails(List<User> userList) {
        List<User> sendList = new List<User>();
        List<User> nextList = new List<User>();
        for (Integer i = 0; i < userList.size() && i < 100; i++) {
            sendList.add(userList[i]);
        }
        if (userList.size() > 100) {
            for (Integer i = 100; i < userList.size(); i++) {
                nextList.add(userList[i]);
            }
        }
        sendEmails(sendList);
        if (!nextList.isEmpty()) {
            sendBatchEmails(nextList);
        }
    }

    private void sendEmails(List<User> userList) {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for (User myUser : userList) {
            // Skip users with no visible digest content (e.g. only inaccessible field changes)
            if (!DailyDigestVFCmpController.hasDigestContent(myUser.Id)) {
                continue;
            }
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.setOrgWideEmailAddressId(EmailUtility.getBRMEmailAddress());
            message.setTargetObjectId(myUser.Id);
            message.setReplyTo(EmailUtility.getReplyToEmail());
            message.setUseSignature(false);
            message.setBccSender(false);
            message.setSaveAsActivity(false);
            message.setTemplateId(emailTemplateId);
            emailList.add(message);
        }
        if (emailList.isEmpty()) {
        return;
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
        for (Messaging.SendEmailResult result : results) {
            if (!result.isSuccess()) {
                System.debug(result.getErrors()[0].getMessage());
            }
        }
    }

    private Set<Id> getFollowedSet(List<FeedItem> feedList) {
        Set<Id> followedSet = new Set<Id>();
        Set<Id> conSet = new Set<Id>();
        for (FeedItem feed : feedList) {
            if (isCampaign(feed.ParentId)) {
                followedSet.add(feed.ParentId);
            } else if (isContact(feed.ParentId)) {
                followedSet.add(feed.ParentId);
                conSet.add(feed.ParentId);
            }
        }
        if (conSet.isEmpty()) {
            return followedSet;
        }
        List<CampaignMember> memList = [
			SELECT CampaignId
			FROM CampaignMember
			WHERE ContactId IN :conSet
		];
        for (CampaignMember mem : memList) {
            followedSet.add(mem.CampaignId);
        }
        return followedSet;
    }

    private Boolean isContact(Id myId) {
        String check = getPrefix(myId);
        return '003'.equals(check);
    }

    private Boolean isCampaign(Id myId) {
        String check = getPrefix(myId);
        return '701'.equals(check);
    }

    private String getPrefix(Id myId) {
        if (myId == null) {
            return '';
        }
        String check = myId;
        return check.substring(0, 3);
    }
}