public with sharing class ExportUtility {
    
    private static final String ASSISTANT_NAME = 'Assistant Name';
    private static final String ASSISTANT_PERSONNEL_EMAIL_LABEL = 'Assistant Personal Email';
    private static final String ASSISTANT_BUSINESS_EMAIL_LABEL = 'Assistant Business Email';
    private static final String ASSISTANT_BUSINESS_PHONE_LABEL = 'Assistant Business Phone';
    private static final String ASSISTANT_MOBILE_PHONE_LABEL = 'Assistant Mobile Phone';
    private static final String STAFF_ROLE = 'StaffRole';
    private static final String CONTACT_BUSINESS_EMAIL_LABEL = 'Business Email';
    private static final String CONTACT_BUSINESS_PHONE_LABEL = 'Business Phone';
    public static final String BUSINESS_PHONE = 'BusinessPhone';
    public static final String CONTACT_OBJECT = 'Contact';
    public static final String TAG_OBJECT = 'Tag__c';
    public static final String BUSINESS_EMAIL = 'BusinessEmail';
    public static final String STAFF_NAME = 'StaffName';
    public static final String ASSISTANT_BUSINESS_EMAIL = 'AssistantBusinessEmail';
    public static final String ASSISTANT_BUSINESS_PHONE = 'AssistantBusinessPhone';
    public static final String ASSISTANT_MOBILE_PHONE = 'AssistantMobilePhone';
    public static final String STAFF_ROLE_LABEL = 'Staff Role';
    public static final String ASSISTANT_PERSONNEL_EMAIL = 'AssistantPersonalEmail';    
    private static final String ERR_VALIDATE_RECORDTYPE = 'EXPORT_UTILITY_GET_FIELDS_BY_RECORDTYPE_FAILED';
    
    public static final Set<String> NON_API_NAME_FIELDS = new Set<String>{STAFF_NAME, ASSISTANT_PERSONNEL_EMAIL, ASSISTANT_BUSINESS_EMAIL, ASSISTANT_BUSINESS_PHONE, ASSISTANT_MOBILE_PHONE, STAFF_ROLE};
        
        public class AvailableOptionWrapper {
            @AuraEnabled
            public List<OptionWrapper> contactFields {get;set;}
            @AuraEnabled
            public List<OptionWrapper> listMemberFields {get;set;}
            @AuraEnabled
            public List<OptionWrapper> tagFields {get;set;}
            
            public AvailableOptionWrapper(List<OptionWrapper> contactFields, List<OptionWrapper> listMemberFields) {
                this.contactFields = contactFields;
                this.listMemberFields = listMemberFields;
                tagFields = new List<OptionWrapper>();
            }
        }
    
    public class OptionWrapper {
        @AuraEnabled
        public String fieldLabel {get;set;}
        @AuraEnabled
        public String fieldValue {get;set;}
        
        public OptionWrapper(String fieldLabel, String fieldValue) {
            this.fieldLabel = fieldLabel;
            this.fieldValue = fieldValue;
        }
        
        public Boolean equals(Object obj) {
            if(obj != null && obj instanceof OptionWrapper) {
                OptionWrapper tempObj = (OptionWrapper)obj;
                if (tempObj.fieldValue == this.fieldValue) {
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        }
    }
    
    public static List<ExportUtility.OptionWrapper> getFieldsByRecordType(String objectName, String devName) {
        
        List<ExportUtility.OptionWrapper> availableOptions = new List<ExportUtility.OptionWrapper>();
        try{ 
            Schema.SObjectType schemaType = Schema.getGlobalDescribe().get(objectName);
            Schema.DescribeSObjectResult describeSObjectResultObj = schemaType.getDescribe();
            Map<String, SObjectField> allFields = describeSObjectResultObj.fields.getMap();
            
            Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(devName);
            
            List<Schema.FieldSetMember> fields = fieldSetObj.getFields();
            
            for (Schema.FieldSetMember field : fields) {
                if (allFields.get(field.getFieldPath()).getDescribe().isAccessible()) {
                    
                    if (ASSISTANT_NAME.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new ExportUtility.OptionWrapper(field.getLabel(), STAFF_NAME));
                        //comment start
                    } else if (ASSISTANT_PERSONNEL_EMAIL_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new ExportUtility.OptionWrapper(field.getLabel(), ASSISTANT_PERSONNEL_EMAIL));
                    } else if (ASSISTANT_BUSINESS_EMAIL_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new ExportUtility.OptionWrapper(field.getLabel(), ASSISTANT_BUSINESS_EMAIL));
                    } else if (ASSISTANT_BUSINESS_PHONE_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new ExportUtility.OptionWrapper(field.getLabel(), ASSISTANT_BUSINESS_PHONE));
                    } else if (ASSISTANT_MOBILE_PHONE_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new ExportUtility.OptionWrapper(field.getLabel(), ASSISTANT_MOBILE_PHONE));
                    } else if (STAFF_ROLE_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new ExportUtility.OptionWrapper(field.getLabel(), STAFF_ROLE));
                    } else {
                        if (allFields.get(field.getFieldPath()).getDescribe().isAccessible()) {
                            String fieldAPIName = field.getFieldPath();
                            if (CONTACT_OBJECT.equalsIgnoreCase(objectName)) {
                                if (CONTACT_BUSINESS_EMAIL_LABEL.equalsIgnoreCase(field.getLabel())) {
                                    fieldAPIName = BUSINESS_EMAIL;
                                }
                                if (CONTACT_BUSINESS_PHONE_LABEL.equalsIgnoreCase(field.getLabel())) {
                                    fieldAPIName = BUSINESS_PHONE;
                                }
                            }
                            availableOptions.add(new ExportUtility.OptionWrapper(field.getLabel(), fieldAPIName));
                        }
                    }
                }
            }
            return availableOptions;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_VALIDATE_RECORDTYPE) );
            return availableOptions; 
        }
    }
}