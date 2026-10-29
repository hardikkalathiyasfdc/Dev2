/********************************************************************************
* Class Name  : CampaignMembershipBannerController
* Description : This class is used by CampaignMembershipBanner lightning component to
*               show user number of campaigns AND their owners related to contact.    
* Created By  : Slalom Consulting 
* Change Log  : Created - 7/17/2019
********************************************************************************/

public without sharing class CampaignMembershipBannerController {
    
    private static final String ERR_CLASS_FAILED = 'CampaignMembershipBannerController_CLASS_FAILED';

    @AuraEnabled   
    public static String getMyDomain() { 
        try {
            String urlInstance=String.valueof(System.URL.getSalesforceBaseURL().toExternalForm());
            String s2 = urlInstance.removeEndIgnoreCase('.my.salesforce.com');
            return s2;
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return '';
    }

    @AuraEnabled
    public static User getUser(Id userId) {
        User u = new User();
        try {
            User userInfo = [SELECT Id, Name FROM User WHERE Id = :userId]; 
            return userInfo; 
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return u;
    }
    
    @AuraEnabled
    public static Contact getContact(Id recordId) {
        Contact c = new Contact();
        try {
            Contact contactInfo = [SELECT Id, Name FROM Contact WHERE Id = :recordId]; 
            return contactInfo; 
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return c;
    }

    @AuraEnabled
    public static Account getAccount(Id recordId) {
        Account a = new Account();
        try {
            Account accountInfo = [SELECT Id, Name FROM Account WHERE Id = :recordId]; 
            return accountInfo; 
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return a;
    }

    @AuraEnabled
    public static isActiveCampaignMemberReturn isActiveCampaignMember(String recordId, String sObjectName) {
        isActiveCampaignMemberReturn activeCampaignMemberReturn = new isActiveCampaignMemberReturn();
        try {
            activeCampaignMemberReturn.isActiveCampaignMember = false;
            // Get All Contacts related to this organzation
            if(sObjectName == 'Account') {
                List<Contact> contactList =  [SELECT Id FROM Contact WHERE AccountId = :recordId];
                List <CampaignMember> lastCampMem = [
                    SELECT CampaignId,Campaign.Owner.Name 
                    FROM CampaignMember 
                    WHERE ContactId IN :contactList
                      AND Campaign.Enable_Contact_Alert_Banner__c = true];
                if(lastCampMem != null && lastCampMem.size() > 0) {
                    activeCampaignMemberReturn.isActiveCampaignMember = true;
                    activeCampaignMemberReturn.toEmailAddress = Label.CampaignMembershipWarningToEmail;
                }
            } else if(sObjectName == 'Contact') {
                List<CampaignMember> lastCampMem = [
                    SELECT CampaignId,Campaign.Owner.Name 
                    FROM CampaignMember 
                    WHERE ContactId =: recordId 
                      AND Campaign.Enable_Contact_Alert_Banner__c = true];
                if(lastCampMem != null && lastCampMem.size()>0) {
                    activeCampaignMemberReturn.isActiveCampaignMember = true;
                    activeCampaignMemberReturn.toEmailAddress = Label.CampaignMembershipWarningToEmail;
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return activeCampaignMemberReturn;      
    } 

    public class isActiveCampaignMemberReturn {
        @AuraEnabled public Boolean isActiveCampaignMember { get; set; }
        @AuraEnabled public String toEmailAddress { get; set; }
    }
}