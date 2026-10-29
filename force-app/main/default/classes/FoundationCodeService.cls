/**
* Author : Neha Gire
* Date   : 04/12/2024
* Jira   : BRME-5240
* Description : This class provides functionality to sync Foundation Codes between BRM And BGive.
* Test : FoundationCodeServiceTest
*/

public with sharing class FoundationCodeService {
   
    private static final String ERR_RETIRE_BGIVE_CODE = 'FOUNDATION_CODE_SERVICE_RETIRE_BGIVE_CODE_FAILED';
    private static final String ERR_UPDATE_CODES = 'FOUNDATION_CODE_SERVICE_UPDATE_CODES_FAILED';
    private static final String ERR_SET_BGIVE_ID = 'FOUNDATION_CODE_SERVICE_SET_BGIVE_ID_FAILED';
    private static final String ERR_CREATE_BGIVE_CODE = 'FOUNDATION_CODE_SERVICE_CREATE_BGIVE_CODE_FAILED';
   
    String modelAttributeId;
    Map<Id,Foundation_Code__c> updateCodes;
    Map<Id, BBApps_ErrorCustomFields> errors;

    public FoundationCodeService(){
       this.updateCodes = new Map<Id,Foundation_Code__c>();
       this.errors = new Map<Id, BBApps_ErrorCustomFields>();
    }

    public void sync(String modelAttributeId , ModelAttributeValue bgiveCodeByExternalId , ModelAttributeValue bgiveCodeByName , Foundation_Code__c code){
        if(String.isEmpty(modelAttributeId)){
            return ;
        }
        this.modelAttributeId = modelAttributeId;
        try{
            String parentBGiveId = FoundationCodeUtil.getBGiveIdForCode(code.Parent__r , modelAttributeId); 
            if(code.Parent__r.Name != 'Initiatives' && parentBGiveId == null ) { 
                code.Sync_Warning__c += ' For Model Attribute : '+modelAttributeId+' - Parent Code is Not Synced.;';
                code.Is_Sync_Error__c = true;
                updateCodes.put(code.Id , code);
                return;  // add warning message here.
            }

            if(bgiveCodeByExternalId == null && bgiveCodeByName == null && code.Enabled_for_Grants__c && code.Status__c != Assets.DELETED){
                createBGiveCode(code);
            }else if(bgiveCodeByExternalId != null || bgiveCodeByName != null){
                updateBGiveCode( (bgiveCodeByExternalId ?? bgiveCodeByName) , code);
            }  
        }catch(Exception ex){
            code.Sync_Error__c += ' For Model Attribute : '+modelAttributeId+' - Sync Failed. Reason : '+ex.getMessage() + ';';
            code.Is_Sync_Error__c = true;
            updateCodes.put(code.Id , code);
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(code.Id + ':' + modelAttributeId + ' : ' + ex.getMessage()));
            errors.put(code.Id, new BBApps_ErrorCustomFields(code.Id + ':' + modelAttributeId + ' : ' + ex.getMessage()));
        }
    }

    private void updateBGiveCode(ModelAttributeValue bGiveRecord, Foundation_Code__c code ){
        if(isCodeDifferent(bGiveRecord, code)){
            System.debug('>> code are different');
            Map<String,Object>  data = formPaylodData(code);
            System.debug('Data');
            System.debug(data);
            BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiMav().modify(bGiveRecord.id , data , null);
            ModelAttributeValue attributeValue = (ModelAttributeValue)JSON.deserialize(JSON.serialize(updateResponse.record) , ModelAttributeValue.class);
            // update Foundation Code BGiveId
            if(attributeValue != null){
                setBGiveId(code, attributeValue.id);
            }
        }else{
            if(bGiveRecord != null){
                setBGiveId(code, bGiveRecord.id);
        }
        }
    }

    private Boolean isCodeDifferent(ModelAttributeValue bGiveCode, Foundation_Code__c code){
        System.debug('>> isRetired : '+FoundationCodeUtil.isCodeRetired(code));
        System.debug('>> bGiveCode.model_attribute_id'+bGiveCode.model_attribute_id);
        System.debug('>> bGiveCode.model_attribute_id'+FoundationCodeUtil.getBGiveIdForCode(code , modelAttributeId));

        System.debug( bGiveCode.description != code.BGive_Description__c);
        System.debug( bGiveCode.value != code.Foundation_Code__c);
        System.debug( bGiveCode.retired != FoundationCodeUtil.isCodeRetired(code));
        System.debug( bGiveCode.dependent_model_attribute_value_id != FoundationCodeUtil.getBGiveIdForCode(code.Parent__r , modelAttributeId));
        System.debug( bGiveCode.model_attribute_id != FoundationCodeUtil.getBGiveIdForCode(code , modelAttributeId));
        System.debug( bGiveCode.migrate_id != (code.BGive_Migrate_Id__c) );
        System.debug( bGiveCode.description != code.BGive_Description__c );
        return ( bGiveCode.description != code.BGive_Description__c || 
                 bGiveCode.value != code.Foundation_Code__c || 
                 bGiveCode.retired != FoundationCodeUtil.isCodeRetired(code) || 
                 bGiveCode.dependent_model_attribute_value_id != FoundationCodeUtil.getBGiveIdForCode(code.Parent__r , modelAttributeId) || 
                 bGiveCode.model_attribute_id !=  modelAttributeId || 
                 bGiveCode.migrate_id != (code.BGive_Migrate_Id__c) || 
                 bGiveCode.description != code.BGive_Description__c || 
                 bGiveCode.display_order != code.Sort_Order__c);
    }

    private void createBGiveCode(Foundation_Code__c code){
        try {
            Map<String,Object>  data = formPaylodData(code);
            System.debug(' >>> Data <<<');
            System.debug(data);
            BGiveApi.BGiveAPIResponse createResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiMav().create(data , null);
            ModelAttributeValue attributeValue = (ModelAttributeValue)JSON.deserialize(JSON.serialize(createResponse.record) , ModelAttributeValue.class);
            // update Foundation Code BGiveId
            if(attributeValue != null){
                setBGiveId(code, attributeValue.id);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CREATE_BGIVE_CODE));
            throw new AuraHandledException(ex.getMessage());
    }
    }

    private  Map<String,Object> formPaylodData(Foundation_Code__c code ){
        ModelAttributeValue attributeValue = new ModelAttributeValue();
        attributeValue.description = code.BGive_Description__c;
        attributeValue.value = code.Foundation_Code__c;
        attributeValue.retired = FoundationCodeUtil.isCodeRetired(code);
        attributeValue.migrate_id = code.BGive_Migrate_Id__c;
        attributeValue.migrate_source = Assets.BRM;
        attributeValue.model_attribute_id = modelAttributeId;
        attributeValue.dependent_model_attribute_value_id = FoundationCodeUtil.getBGiveIdForCode(code.Parent__r , modelAttributeId);
        attributeValue.display_order = code.Sort_Order__c != null ? Integer.valueOf(code.Sort_Order__c) : null;
        return (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(attributeValue,true));
    }

    private void setBGiveId(Foundation_Code__c code , String bGiveId){
            if(code != null){
                Map<String,Object> bGiveIds = new Map<String,Object>();
                if(!String.isBlank(code.BGive_ID__c)){
                    bGiveIds = (Map<String,Object>) JSON.deserializeUntyped(code.BGive_ID__c);
                }
                // Check if BGive ID is changed before updating the Foundation Code record. 
                // This will avoid updating code if there is no change.
                if( !bGiveIds.containsKey(modelAttributeId) || (bGiveIds.get(modelAttributeId) != bGiveId) ){
                    bGiveIds.put(modelAttributeId , bGiveId);
                    code.BGive_ID__c = JSON.serialize(bgiveIds);
                    updateCodes.put(code.Id,code);
                }
            }
    }

    public void updateCodes(){
        // add skip trigger
        if(!this.updateCodes.isEmpty()){
            TriggerFactory.setBypass('FoundationCodeHandler');
            BBApps_Crud.doUpdate(updateCodes.values());
            TriggerFactory.removeBypass('FoundationCodeHandler');
        }

        if(!errors.isEmpty()) {
            FoundationCodeUtil.notifyUser(errors);

        }
    }

    public void addCodesToUpdateList(Foundation_Code__c code){
        // add skip trigger
        updateCodes.put(code.Id , code);  
    }

    public static void retireBGiveCode(ModelAttributeValue bGiveRecord){
            System.debug('>> code are different');
            Map<String,Object>  data = new Map<String,Object>();
            data.put('retired',1);
            System.debug('Data');
            System.debug(data);
            BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiMav().modify(bGiveRecord.id , data , null);
            ModelAttributeValue attributeValue = (ModelAttributeValue)JSON.deserialize(JSON.serialize(updateResponse.record) , ModelAttributeValue.class);
    }

    public class ModelAttributeValue{
        public String id;
        public String description;
        public String value;
        public Integer retired;
        public String migrate_id;
        public String migrate_source;
        public String model_attribute_id;
        public String dependent_model_attribute_value_id;
        public Integer display_order;
    }
}