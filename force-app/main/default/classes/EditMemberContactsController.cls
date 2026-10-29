/********************************************************************************
* Class Name  : EditMemberContactsController
* Description : This class is used by EditMemberContacts lightning component to
*               edit contacts data those are added as campaign members.    
* Created By  : Slalom Consulting 
* Change Log  : Created - 6/24/2019
********************************************************************************/
public with sharing class EditMemberContactsController {
    
    private static final String ERR_GET_CONTACT_INFO = 'EDIT_MEMEBER_CONTACT_CONTROLLER_GET_CONTACT_INFO_FAILED';
    private static final String ERR_VALIDATE_CREATE_INTERACTION_ACCESS = 'EDIT_MEMBER_CONTACT_CONTROLLER_VALIDATE_CREATE_INTERACTION_ACCESS_FAILED';
    private static final String ERR_UPDATE_CONTACTS = 'EDIT_MEMBER_CONTACT_CONTROLLER_UPDATE_CONTACTS_FAILED'; 
    private static final String ERR_VALIDATE_CONTACTS = 'EDIT_MEMBER_CONTACT_CONTROLLER_VALIDATE_CONTACTS_FAILED'; 
    @TestVisible
    private static Boolean forceException = false;
    
    
    // method to search contacts on the basis of search filters selected
    @AuraEnabled
    public static List < Contact > getContactsToEdit(String campId){
        try{ 
            
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List < Contact > returnList = new List < Contact > ();
            Set<Id> existingConIds = new Set<Id>();
            for(CampaignMember cm : [Select ContactId from CampaignMember where CampaignId =: campId]){
                existingConIds.add(cm.ContactId);
            }
            returnList = [Select Account.Name,AccountId,Id,Name,Phone,Email,Title,MobilePhone,Salutation,FirstName,LastName,
                          Preferred_First_Name__c,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode from Contact where Id IN: existingConIds];
            
            return returnList;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_CONTACT_INFO) ); 
            return null;
        }  
    }
    
    // method to validate create access on Interaction object
    @AuraEnabled
    public static Boolean validateCreateInteractionAccess(){
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Boolean noCreateAccess = false;
            noCreateAccess = Schema.sObjectType.Interaction__c.isCreateable();
            return noCreateAccess;
            
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex, new BBApps_ErrorCustomFields( ERR_VALIDATE_CREATE_INTERACTION_ACCESS ) );
            return false; 
        }
    }
    
    // updating inline edited contacts
    @AuraEnabled
    public static List < Contact > updateContacts(List<Contact> lstCon,String campId){     
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Map<String, List<String>> mapRetValue = UtilityClass.getFieldDependencies('User', 'Countrycode', 'Statecode');
            
            for(Contact con : lstCon){
                Boolean toBreak = false;
                if(con.MailingState != null && con.MailingState != ''){
                    for(String countryVal : mapRetValue.keyset()){
                        for(String stateVal : mapRetValue.get(countryVal)){
                            if(con.MailingState == stateVal){
                                con.MailingCountry = countryVal;
                                toBreak = true;
                                break;
                            }
                        }
                        if(toBreak)
                            break;
                    }
                }else if(con.MailingState != null && con.MailingState == ''){
                    con.MailingCountry = '';
                }
            }
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            BBApps_Crud.doUpdateWithHandling(lstCon,dml);
            List < Contact > returnList = getContactsToEdit(campId);
            return returnList;
        } catch (Exception ex) {
            
            BBApps_ErrorHandler.logErrors( ex, new BBApps_ErrorCustomFields(ERR_UPDATE_CONTACTS) );
            
            return new List<Contact>(); 
        }

    }
    
    //to validate contacts for invalid salutation or state values and check for duplication
    @AuraEnabled
    public static String validateContacts(List<Contact> updatedCon){
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<String> salValues = UtilityClass.getPickListValuesIntoList('Contact','Salutation');
            List<String> mailStateValues = UtilityClass.getPickListValuesIntoList('Contact','State');
            String message;
            for(Contact con : updatedCon){
                if(con.Salutation != null && con.Salutation != '' && !salValues.contains(con.Salutation)){
                    message = System.Label.Invalid_Salutation;
                    return message;
                }else if(con.MailingState != null && con.MailingState != '' && !mailStateValues.contains(con.MailingState)){
                    message = System.Label.Invalid_State;
                    return message;
                }
            }
            Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(updatedCon);
            for (Datacloud.FindDuplicatesResult findDupeResult : results) {
                for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                    for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                        for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                            system.debug('inside the dupe logic >>>> '+matchRecord);
                            if(message == null)
                                message = System.Label.Duplicate_Record;
                        }
                    }
                }
            }
            system.debug('message >>>> '+message);
            return message;
        } catch (Exception ex) {
            
            BBApps_ErrorHandler.logErrors( ex, new BBApps_ErrorCustomFields(ERR_VALIDATE_CONTACTS) );
            return null; 
        }


    }
}