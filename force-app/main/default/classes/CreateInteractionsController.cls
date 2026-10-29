/********************************************************************************
* Class Name  : CreateInteractionsController
* Description : This class is used by CreateInteractions lightning component to
*               auto create Interaction records on all contacts of the campaign.    
* Created By  : Slalom Consulting 
* Change Log  : Created - 5/29/2019
********************************************************************************/
public with sharing class CreateInteractionsController {
    private static final String ERR_AUTO_CREATE_INTERACTIONS= 'CREATE_INTERACTIONS_CONTROLLER_AUTO_CREATE_INTERACTIONS_FAILED';
    private static final String ERR_AUTO_CREATE_ORG_INTERACTIONS= 'CREATE_INTERACTIONS_CONTROLLER_AUTO_CREATE_ORG_INTERACTIONS_FAILED';
    private static final String ERR_GET_fields_by_RECORD_TYPE= 'CREATE_INTERACTIONS_CONTROLLER_GET_fields_by_RECORD_TYPE_FAILED';
	 
	@AuraEnabled
	public static Integer conMembersCount(Id campId){
		Integer arList = [select count() from CampaignMember where CampaignId =: campId and type = 'Contact' WITH SYSTEM_MODE];
		return arList;	
	} 

    @AuraEnabled
    public static Integer restrictedConMembersCount(Id campId){
        Integer arList = [select count() from CampaignMember where CampaignId =: campId and type = 'Contact' AND Contact.Restricted__c = TRUE WITH SYSTEM_MODE];
        return arList;	
    } 
    
    @AuraEnabled
    public static Integer conOrgsCount(Id campId){
        Integer arList = [select count() from ListOrganization__c where List__c =: campId WITH SYSTEM_MODE];
        return arList;
    } 
    
    @AuraEnabled
    public static Integer autoCreateInteractions(Interaction__c interactionIns, Id campId, List<Contact> selectedCons, String recordTypeId) {
        try{
            List<Id> selectedConIds = new List<Id>();
            if(selectedCons != null){
                for(Contact con : selectedCons){
                    if(con.Id != null){
                        selectedConIds.add(con.Id);
                    }
                }
            }

            List<Id> targetContactIds = resolveTargetContactIds(campId, selectedConIds);
            Set<Id> blockedContactIds = getInaccessibleContactIds(targetContactIds);
            List<Interaction__c> lstInteractions = new List<Interaction__c>();
            for(Id contactId : targetContactIds){
                if(blockedContactIds.contains(contactId)){
                    continue;
                }
                Interaction__c interIns = (Interaction__c)JSON.deserialize(JSON.serialize(interactionIns), Interaction__c.class);
                interIns.Contact__c = contactId;
                interIns.RecordTypeId = recordTypeId;
                lstInteractions.add(interIns);
            }
            if(lstInteractions.isEmpty()){
                throw buildAuraException(blockedContactIds.isEmpty()
                    ? 'There are no contacts to create Interactions for.'
                    : 'You do not have access to any of the selected contacts, so no Interactions were created.');
            }
            insert as system lstInteractions;
            return lstInteractions.size();
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AUTO_CREATE_INTERACTIONS));
            throw buildAuraException(describeDmlFailure(ex));
        }
    }

    @AuraEnabled
    public static Integer getInaccessibleContactCount(Id campId, List<Id> contactIds) {
        List<Id> targetContactIds = resolveTargetContactIds(campId, contactIds);
        Set<Id> blockedContactIds = getInaccessibleContactIds(targetContactIds);
        if(blockedContactIds.isEmpty()){
            return 0;
        }
        Integer blocked = 0;
        for(Id contactId : targetContactIds){
            if(blockedContactIds.contains(contactId)){
                blocked++;
            }
        }
        return blocked;
    }

    private static List<Id> resolveTargetContactIds(Id campId, List<Id> contactIds) {
        List<Id> targetContactIds = new List<Id>();
        if(contactIds != null && !contactIds.isEmpty()){
            for(Id contactId : contactIds){
                if(contactId != null){
                    targetContactIds.add(contactId);
                }
            }
            return targetContactIds;
        }
        for(CampaignMember campMem : [Select contactId from CampaignMember where CampaignId =: campId and type = 'Contact' WITH SYSTEM_MODE]){
            if(campMem.contactId != null){
                targetContactIds.add(campMem.contactId);
            }
        }
        return targetContactIds;
    }

    private static Set<Id> getInaccessibleContactIds(List<Id> contactIds) {
        Set<Id> blocked = new Set<Id>(contactIds);
        if(blocked.isEmpty() || hasPrivateNameFieldsAccess()){
            return new Set<Id>();
        }
        for(Contact con : [SELECT Id FROM Contact WHERE Id IN :contactIds]){
            blocked.remove(con.Id);
        }
        return blocked;
    }

    private static AuraHandledException buildAuraException(String message) {
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        return ahe;
    }

    private static String describeDmlFailure(Exception ex) {
        if(!(ex instanceof DmlException)){
            return ex.getMessage();
        }
        DmlException dmlEx = (DmlException)ex;
        Set<String> messages = new Set<String>();
        for(Integer i = 0; i < dmlEx.getNumDml(); i++){
            String fieldNames = String.join(dmlEx.getDmlFieldNames(i), ', ');
            messages.add(String.isBlank(fieldNames)
                ? dmlEx.getDmlMessage(i)
                : fieldNames + ': ' + dmlEx.getDmlMessage(i));
        }
        return messages.isEmpty() ? ex.getMessage() : String.join(new List<String>(messages), '\n');
    }
    
    @AuraEnabled
    public static void autoCreateOrgInteractions(Interaction__c interactionIns, Id campId, String recordTypeId) {
        try{
            List<Interaction__c> lstInteractions = new List<Interaction__c>();
            
            for(ListOrganization__c campMem : [SELECT Organization__c FROM ListOrganization__c WHERE List__c =: campId WITH SYSTEM_MODE]){
                Interaction__c interIns = (Interaction__c)JSON.deserialize(JSON.serialize(interactionIns), Interaction__c.class);
                interIns.Organization__c = campMem.Organization__c;
                interIns.RecordTypeId = recordTypeId;
                lstInteractions.add(interIns);
            }

            insert as system lstInteractions;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AUTO_CREATE_ORG_INTERACTIONS));
        }  
    }
    
    @AuraEnabled(cacheable=true)
    public static String getRecordTypes() {
        Schema.DescribeSObjectResult R = Interaction__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> recordTypes = R.getRecordTypeInfos();
        
        return JSON.serialize(recordTypes);  
    }
    
    @AuraEnabled(cacheable=true)
    public static String getFieldsByRecordType(String devName) {
        try{
            Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Interaction__c');
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(devName);
            return JSON.serialize(fieldSetObj.getFields());
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_FIELDS_BY_RECORD_TYPE));
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkOrgRecentEngagementCreationPermission() {
        return FeatureManagement.checkPermission('OrgEngagementCreation');
    }

    @AuraEnabled
    public static Boolean hasPrivateNameFieldsAccess() {
      return  UtilityClass.hasRequiredPermission('Private_Name_Fields');
    }
}