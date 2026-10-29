global without sharing class CampaignCloneWithMembersBatch implements Database.batchable<sObject>, Database.Stateful{

    global String newCampId;
    global String campId;
    global Integer doNotContactCount = 0;
    global Integer totalContactCount = 0;
    global Integer insertedContactCount = 0;
    global Campaign newCampaign;
    global string recordTypeName;
    global string objectname;
    global string fieldString;
    private static final String ERR_BATCH_JOB_FAILED = 'CampaignCloneWithMembersBatch_BATCH_JOB_FAILED';
    private static final String ERR_INSERT_FAILED = 'CampaignCloneWithMembersBatch_INSERT_FAILED';

    global CampaignCloneWithMembersBatch(String campId, String newCampId) {
        this.campId = campId;
        this.newCampId = newCampId;
    }

    global CampaignCloneWithMembersBatch(String campId, Campaign newCampaign,string recordTypeName,string objectName) {
        this.campId = campId;
        this.newCampId = newCampaign.Id;
        this.newCampaign = newCampaign;
        String fieldString = CampaignCloneWithMembersController.getFieldsToClone(recordTypeName,objectName);
        this.fieldString = fieldString;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String queryString = 'SELECT ' + this.fieldString + ',Campaign.Name FROM CampaignMember WHERE CampaignId =: campId';
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        try {
            List<CampaignMember> newLstCampMem = new List<CampaignMember>();
            totalContactCount += scope.size();
            for(CampaignMember campMem : (List<CampaignMember>)scope) {
                if(campMem.contact.Deceased__c || campMem.contact.DonotCall) {
                    doNotContactCount++;
                } else {
                    CampaignMember campMemIns = campMem.clone(false, true, false, false);
                    campMemIns.CampaignId = newCampId;
                    campMemIns.Source__c = campMem.Campaign.Name;
                    insertedContactCount++;
                    newLstCampMem.add(campMemIns);
                }
            }
            if(!newLstCampMem.isEmpty()) {
                BBApps_Crud.doInsertWithHandling(newLstCampMem, false, new BBApps_ErrorCustomFields(ERR_INSERT_FAILED));
            }

        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    global void finish(Database.BatchableContext BC) {
        String emailSubject = 'All Contacts Loaded to newly cloned list ' + newCampaign.Name;
        if(doNotContactCount == totalContactCount) {
            emailSubject = 'No Contacts Loaded to newly cloned list ' + newCampaign.Name;
        } else if (doNotContactCount > 0) {
            emailSubject = 'Partial Contacts Loaded to newly cloned list ' + newCampaign.Name;
        }
        sendEmail(newCampaign, emailSubject);
    }

    private void sendEmail(Campaign campaign, String emailSubject) {
        try {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setOrgWideEmailAddressId(EmailUtility.getBRMEmailAddress());
            message.setTargetObjectId(UserInfo.getUserId());
            message.setReplyTo(EmailUtility.getReplyToEmail());
            message.setSubject(emailSubject);
            String emailContent = 'Hello ' + UserInfo.getFirstName() + ',<br/><br/>';
            emailContent += insertedContactCount + ' new members have been added to the list ' + campaign.Name + '.';
            if (doNotContactCount > 0) {
                emailContent += '<br/><br/>' + doNotContactCount +
                                ' members were not added to the list because they are marked as Do Not Contact and/or Deceased.';
            }
            message.setHtmlBody(emailContent);
            message.setUseSignature(false);
            message.setBccSender(false);
            message.setSaveAsActivity(false);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ message }
            );
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}