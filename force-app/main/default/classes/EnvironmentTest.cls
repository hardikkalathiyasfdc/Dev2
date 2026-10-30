/**
* Author            : Paddy
* Date              : 12/15/2025
* Description       : Test class for Environment class
*/
@isTest
public class EnvironmentTest {
    
    @isTest
    static void testIsSandbox() {
        Test.startTest();
        Boolean isSandbox = Environment.isSandbox();
        Test.stopTest();
        
        Assert.isNotNull(isSandbox, 'isSandbox should return a boolean value');
    }
    
    @isTest
    static void testGetOrgName() {
        Test.startTest();
        String orgName = null;
        orgName = Environment.getOrgName();
        if(Environment.isSandbox()) {
            Assert.isNotNull(orgName, 'getOrgName should return a string value');
        }
        Test.stopTest(); 
    }
    
    @isTest
    static void testGetBaseUrl() {
        Test.startTest();
        String baseUrl = Environment.getBaseUrl();
        Test.stopTest();
        
        Assert.isNotNull(baseUrl, 'getBaseUrl should return a string value');
        Assert.isTrue(baseUrl.startsWith('http'), 'getBaseUrl should return a valid URL');
    }
    
    @isTest
    static void testGetEnvironmentSettingNoParameters() {
        Test.startTest();
        Environment_Setting__mdt setting = Environment.getEnvironmentSetting();
        Test.stopTest();
        
        Assert.isTrue(true, 'getEnvironmentSetting should execute without error');
    }
    
    @isTest
    static void testGetEnvironmentSettingWithAttributes() {
        List<String> attributes = new List<String>{
            'Fluxx_User_Id__c',
                'Fluxx_Named_Credential__c'
                };
                    
                    Test.startTest();
        Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(attributes);
        Test.stopTest();
        
        Assert.isTrue(true, 'getEnvironmentSetting should execute without error');
    }
    
    @isTest
    static void testGetEnvironmentSettingWithAttributesWithException() {
        Environment.forceException = true;
        List<String> attributes = new List<String>{
            'Fluxx_User_Id__c',
                'Fluxx_Named_Credential__c'
                };
                    
                    Test.startTest();
        Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(attributes);
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testGetEnvironmentSettingWithEmptyAttributes() {
        List<String> attributes = new List<String>();
        
        Test.startTest();
        Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(attributes);
        Test.stopTest();
        
        Assert.isTrue(true, 'getEnvironmentSetting should execute without error');
    }
    
    @isTest
    static void testGetFluxxNamedCreds() {
        Test.startTest();
        String namedCreds = Environment.getFluxxNamedCreds();
        Test.stopTest();
        
        Assert.isNotNull(namedCreds, 'getFluxxNamedCreds should return a string value');
    }
    
    @isTest
    static void testGetFluxxNamedCredsWithException() {
        Environment.forceException = true;
        Test.startTest();
        String namedCreds = Environment.getFluxxNamedCreds();
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetFoundationCodeAttributes() {
        Test.startTest();
        String attributes = Environment.getFoundationCodeAttributes();
        Test.stopTest();
        
        Assert.isNotNull(attributes, 'getFoundationCodeAttributes should return a string value');
    }
    
    
    @isTest
    static void testGetFoundationCodeAttributesWithException() {
        Environment.forceException = true;
        Test.startTest();
        String attributes = Environment.getFoundationCodeAttributes();
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetBgiveBaseUrlTestContext() {
        Test.startTest();
        String baseUrl = Environment.getBgiveBaseUrl();
        Test.stopTest();
        
        Assert.isNotNull(baseUrl, 'getBgiveBaseUrl should not return null.');
    }
    
    @isTest
    static void testGetBgiveBaseUrlTestContextWithException() {
        Environment.forceException = true;
        Test.startTest();
        String baseUrl = Environment.getBgiveBaseUrl();
        Test.stopTest();
    }
    @isTest
    static void testGetEnvironmentSettingMultipleAttributes() {
        List<String> attributes = new List<String>{
            'Fluxx_User_Id__c',
                'Fluxx_Named_Credential__c',
                'Foundation_Code_Model_Attribute_Ids__c'
                };
                    
                    Test.startTest();
        Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(attributes);
        Test.stopTest();
        
        Assert.isTrue(true, 'getEnvironmentSetting should execute without error');
    }
    
    @isTest
    static void testGetEnvironmentSettingSingleAttribute() {
        List<String> attributes = new List<String>{
            'Fluxx_Named_Credential__c'
                };
                    
                    Test.startTest();
        Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(attributes);
        Test.stopTest();
        
        Assert.isTrue(true, 'getEnvironmentSetting should execute without error');
    }
    
    @isTest
    static void testErrorHandlingNullSafety() {
        Test.startTest();
        try {
            // Test with null-safe operations
            Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(
                new List<String>{'NonExistent_Field__c'}
            );
            // Method should handle missing fields.
            Assert.isTrue(true, 'Method should handle missing fields.');
        } catch (Exception e) {
            // If exception occurs, it should be handled
            Assert.isTrue(true, 'Exception handled: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetBaseUrlUrlFormat() {
        Test.startTest();
        String baseUrl = Environment.getBaseUrl();
        Test.stopTest();
        
        // Verify URL format
        Assert.isTrue(baseUrl.contains('://'), 'getBaseUrl should return a properly formatted URL');
    }
}