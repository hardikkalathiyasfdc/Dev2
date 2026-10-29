/**
* @description       : Utility class that determines the current Salesforce org environment (prod/sandbox/dev), 
resolves environment-specific custom metadata settings, and provides related configuration 
values such as named credentials and base URLs for external integrations.
* @author            : Sai Bhargav Thotakura
* @group             : 
* @last modified on  : 10-06-2025
* @last modified by  : Sai Bhargav Thotakura
**/
public with sharing class Environment {
    private static final String ERR_GET_ORG_NAME= 'ENVIRONMENT_GET_ORG_NAME_FAILED'; 
    private static final String ERR_GET_BASE_URL= 'ENVIRONMENT_GET_BASE_URL_FAILED'; 
    private static final String ERR_GET_ENVIRONMENT= 'ENVIRONMENT_GET_ENVIRONMENT_FAILED'; 
    private static final String ERR_GET_ENVIRONMENT_SETTING = 'ENVIRONMENT_GET_ENVIRONMENT_SETTING_FAILED'; 
    private static final String ERR_GET_FLUX_NAME_CREDS= 'ENVIRONMENT_GET_FLUX_NAME_CREDS_FAILED'; 
    private static final String ERR_GET_FOUNDATION_CODE_ATTRIBUTES= 'ENVIRONMENT_GET_FOUNDATION_CODE_ATTRIBUTES_FAILED'; 
    private static final String ERR_GET_BGIVE_BASE_URL= 'ENVIRONMENT_GET_BGIVE_BASE_URL_FAILED'; 
    
    @TestVisible
    private static Boolean forceException = false;
    
    public static Boolean isSandbox() {
        return [Select IsSandbox From Organization Limit 1].IsSandbox;
    }
    
    public static String getOrgName() {
        return DomainParser.parse(DomainCreator.getOrgMyDomainHostname()).getSandboxName();
    }
    
    public static String getBaseUrl(){
        return URL.getOrgDomainUrl().toExternalForm();
    }
    
    public static String getEnvironment(){
        String orgName = getOrgName();
        if(String.isBlank(orgName)){
            return Assets.PROD;
        }else if(orgName.containsIgnoreCase(Assets.DEV)){
            return Assets.DEV;
        }
        return orgName;
    }
    
    // Make method to return setting for given param.
    public static Environment_Setting__mdt getEnvironmentSetting(){
        return Environment_Setting__mdt.getInstance(getEnvironment());
    }
    
    public static Map<String,Object> getEnvironmentSetting(List<String> attributes){
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Environment_Setting__mdt setting = Environment_Setting__mdt.getInstance(getEnvironment());
            if(setting != null){
                Map<String, Object> attributeValueMap = new Map<String, Object>();
                if(!attributes.isEmpty()){
                    for( String attribute : attributes){
                        attributeValueMap.put(attribute , setting.get(attribute));
                    }
                }
                return attributeValueMap;
            }
            
            return null;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_ENVIRONMENT_SETTING) ); 
            return null;
        } 
    }
    public static String getFluxxNamedCreds(){
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Environment_Setting__mdt setting = Environment_Setting__mdt.getInstance(getEnvironment());
            if(setting != null){
                return setting.Fluxx_Named_Credential__c;
            }
            return '';
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_FLUX_NAME_CREDS) ); 
            return null;
        } 
    }
    
    public static String getFoundationCodeAttributes(){
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Environment_Setting__mdt setting = Environment_Setting__mdt.getInstance(getEnvironment());
            if(setting != null){
                return setting.Foundation_Code_Model_Attribute_Ids__c;
            }
            return '';
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_FOUNDATION_CODE_ATTRIBUTES) ); 
            return null;
        } 
    }
    
    public static String getBgiveBaseUrl(){
        try{
             if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
        Map<String, Object> envAttributeMap = getEnvironmentSetting(new List<String>{'Fluxx_Base_URL__c'});
        return String.valueOf(envAttributeMap?.get('Fluxx_Base_URL__c'));
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_BGIVE_BASE_URL) ); 
            return null;
        } 
    }
}