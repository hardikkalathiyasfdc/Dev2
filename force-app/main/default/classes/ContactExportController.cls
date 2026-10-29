/**
* Author : Hardik Kalathiya
* Date   : 02/03/2025
* Jira   : BRME-5682
* Description : This class provides functionalities to handle dynamic field selection and export contact information from Account Record.
* Test : ContactExportControllerTest
*/
public with sharing class ContactExportController {
    
    public static final String EXPORT_LEADERSHIP_MODE = 'leadership';
    private static final String ERR_GET_FIELD_SET  = 'CONTACT_EXPORT_GET_FIELD_SET_FAILED';
    private static final String ERR_GET_ALL_FIELD_SET  = 'CONTACT_EXPORT_GET_ALL_FIELD_ACCESS_FAILED';
    private static final String ERR_GET_CONTACT  = 'CONTACT_EXPORT_GET_CONTACT_WITH_SELECTED_FIELDS_FAILED';
    private static final String ERR_SET_TAGS  = 'CONTACT_EXPORT_SET_TAGS_FAILED';
    
    @TestVisible
    private static Boolean forceException = false;
    
    @AuraEnabled
    public static Integer getRestrictedContact(String accountId) {
        // Delegate to the without-sharing detector so the count reflects all restricted
        // leadership contacts even when the running user cannot see those Contact records.
        Integer count = RestrictedRecordDetector.countRestrictedLeadershipContacts(accountId);
        system.debug('getRestrictedContact - ' + count);
        return count;
    }

    @AuraEnabled(cacheable=true)
    public static List<OptionWrapper> getFieldSetFields(String fieldSetName) {
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Schema.FieldSet fieldSet = Schema.SObjectType.Contact.fieldSets.getMap().get(fieldSetName);
            if (fieldSet == null) {
                throw new AuraHandledException('Field set not found');
            }
            Schema.SObjectType schemaType = Schema.getGlobalDescribe().get('Contact');
            Schema.DescribeSObjectResult describeSObjectResultObj = schemaType.getDescribe();
            Map<String, SObjectField> allFields = describeSObjectResultObj.fields.getMap();
            List<OptionWrapper> fieldNames = new List<OptionWrapper>();
            for (Schema.FieldSetMember field : fieldSet.getFields()) {
                if (allFields.containsKey(field.getFieldPath()) && allFields.get(field.getFieldPath()).getDescribe().isAccessible()) {
                    
                    fieldNames.add(new OptionWrapper(field.getLabel(),field.getFieldPath()));
                }
            }
            return fieldNames;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_FIELD_SET)); 
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Boolean>> getAllFieldAccess() {
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Map<String, Map<String, Boolean>> fieldAccessMap = new Map<String, Map<String, Boolean>>();
            
            Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Contact.fields.getMap();
            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult fieldDesc = fieldsMap.get(fieldName).getDescribe();
                Map<String, Boolean> accessInfo = new Map<String, Boolean>{
                    'isAccessible' => fieldDesc.isAccessible(),
                        'isUpdateable' => fieldDesc.isUpdateable()
                        };
                            fieldAccessMap.put(fieldName, accessInfo);
            }
            
            return fieldAccessMap;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_ALL_FIELD_SET)); 
            return null;
        }
    }
    
    @AuraEnabled
    public static List<Map<String, String>> getContactsWithSelectedFields(List<String> selectedFields, Id accountId, String mode) {
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            if(selectedFields == null || selectedFields.isEmpty()) {
                return new List<Map<String, String>>();
            }
            Map<String, String> restrictedFieldMap = new Map<String, String>{
                'First_Preferred_First_Name__c' => 'RestrictedFirstName__c',
                    'FirstName'                    => 'RestrictedFirstName__c',
                    'LastName'                     => 'RestrictedLastName__c',
                    'Significant_Name__c'          => 'Significant_Other__r.Restricted_Name__c',
                    'Assistant__c'                 => 'Restricted_Name__c',
                    'Significant_Other_Name_Preferred__c' => 'Significant_Other__r.Restricted_Name__c'
                    };
                        
                        Boolean hasRestrictedAccess = FeatureManagement.checkPermission('Private_Name_Fields');
            Set<String> selectedFieldSet = new Set<String>(selectedFields);
            Boolean isTagSelected = selectedFieldSet.contains('ffTags') || selectedFieldSet.contains('otherTags');
            // Remove special fields that require separate handling
            Set<String> customFields = new Set<String>{ 
                'ffTags', 'otherTags', 'significantOtherAssistantName','AssistantName','Assistant_Business_Email__c','Staff_Role__c'};
                    selectedFieldSet.add('Significant_Other__c');
            selectedFieldSet.removeAll(customFields);
            If(selectedFieldSet.contains('Restricted__c'))  selectedFieldSet.remove('Restricted__c');
            // Construct query field list
            String fieldList = String.join(new List<String>(selectedFieldSet), ',');
            String query = 'SELECT ' + fieldList + ', Restricted__c,RestrictedLastName__c,RestrictedFirstName__c,Restricted_Name__c,Significant_Other__r.Restricted_Name__c, (SELECT Id, Tag__r.Name FROM Tags__r ORDER BY Tag__r.Name ASC) ' +
                'FROM Contact WHERE AccountId = :accountId AND DoNotCall = false';
            if(mode == EXPORT_LEADERSHIP_MODE) {
                query += ' AND Leadership_Contact__c = TRUE ORDER BY Last_Preferred_Last_Name__c ASC';
            } else {
                query += ' ORDER BY Last_Preferred_Last_Name__c ASC';
            }
            List<Contact> contacts = Database.query(query, AccessLevel.SYSTEM_MODE);
            List<Map<String, String>> result = new List<Map<String, String>>();
            Set<Id> contactIds = new Set<Id>();
            for(Contact contact : contacts) {
                contactIds.add(contact.Id);
                contactIds.add(contact.Significant_Other__c);
            }
            selectedFieldSet = new Set<String>(selectedFields);
            selectedFieldSet.add('Restricted__c');
            // Fetch assistant data
            Map<Id, ExportContactsController.AssistantWrapper> assistanceMap = ExportContactsController.getAssistanceData(contactIds, new Set<Id>());
            // Process contacts
            for(Contact contact : contacts) {
                Map<String, String> contactMap = new Map<String, String>();
                for(String field : selectedFieldSet) {
                    if(customFields.contains(field)) {
                        if(field == 'significantOtherAssistantName') {
                            ExportContactsController.AssistantWrapper assistantData = assistanceMap.get(contact.Significant_Other__c);
                            if(assistantData != null) {
                                contactMap.put('significantOtherAssistantName', assistantData.assistantName);
                            }
                            continue;
                        } else if (field == 'AssistantName' || field == 'Assistant_Business_Email__c' || field == 'Staff_Role__c') {
                            ExportContactsController.AssistantWrapper assistantData = assistanceMap.get(contact.Id);
                            if (assistantData != null) {
                                if (field == 'AssistantName') {
                                    contactMap.put('AssistantName', assistantData.assistantName);
                                } else if(field == 'Assistant_Business_Email__c') {
                                    contactMap.put('Assistant_Business_Email__c', assistantData.assistanttBusinessEmail);
                                } else if(field == 'Staff_Role__c') {
                                    contactMap.put('Staff_Role__c', assistantData.staffRole);
                                }
                            }
                            continue;
                        }
                    } else {
                        // Handle parent-child fields
                        List<String> parentFields = field.split('\\.');
                        if (parentFields.size() > 1) {
                            contactMap.put(field, String.valueOf(getParentFieldValue(contact, parentFields[0], parentFields[1])));
                        } else {
                            If(contact.Restricted__c && hasRestrictedAccess){
                                if(field == 'Significant_Name__c' || field == 'Significant_Other_Name_Preferred__c'){
                                    contactMap.put(field, String.valueOf(contact.Significant_Other__r.Restricted_Name__c));
                                } else if(restrictedFieldMap.containskey(field)){
                                    contactMap.put(field, String.valueOf(contact.get(restrictedFieldMap.get(field))));
                                } else {
                                    contactMap.put(field, String.valueOf(contact.get(field)));
                                }  
                            }else{
                                contactMap.put(field, String.valueOf(contact.get(field)));
                            }
                            
                        }
                    }
                }
                // Process tags if needed
                if(isTagSelected) {
                    contactMap = setTags(contact.Tags__r, contactMap);
                }
                result.add(contactMap);
            }
            return result;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_CONTACT)); 
            return null;
        }
    }
    
    public static Object getParentFieldValue(SObject record, String relationshipField, String fieldName) {
        if (record != null && record.getSObject(relationshipField) != null) {
            return record.getSObject(relationshipField).get(fieldName);
        }
        return null;
    }
    
    public static Map<String, String> setTags(List<Tag_Junction__c> tags,  Map<String, String> contactMap) {
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Set<String> ffTags = new Set<String> ();
            Set<String> otherTags = new Set<String> ();
            List<String> ffTagsList = new List<String> ();
            List<String> otherTagsList = new List<String> ();
            
            for(Tag_Junction__c tag: tags) {
                if(tag.Tag__r.Name.containsIgnoreCase('F&F')) {
                    ffTags.add(tag.Tag__r.Name);
                } else {
                    otherTags.add(tag.Tag__r.Name);
                }
            }
            
            otherTagsList.addAll(otherTags);
            ffTagsList.addAll(ffTags);
            contactMap.put('ffTags',String.join(ffTagsList, ', '));
            contactMap.put('otherTags',String.join(otherTagsList, ', '));
            return contactMap;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_SET_TAGS)); 
            return null;
        }
    }
    
    public class OptionWrapper {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}
        
        public OptionWrapper(String fieldLabel, String fieldValue) {
            
            this.label = fieldLabel;
            this.value = fieldValue;
            if(fieldValue=='AssistantName')
            {
                this.label = 'Staff Name';
            }
        }
    }
}