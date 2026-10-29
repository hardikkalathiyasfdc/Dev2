/********************************************************************************
* Class Name  : UtilityClass
* Description : This class contains utility methods which can be used by other
*               controller classes.
* Created By  : Slalom Consulting
* Change Log  : 07/24/2019 - Created
                29/1/2020 -  GetObjectFieldLabels method added
********************************************************************************/
public with sharing class UtilityClass {

    private static final String ERR_GET_FIELD_DEPENDENCIES_FAILED = 'UtilityClass_getFieldDependencies_FAILED';
    private static final String ERR_GET_PHOTO_URL_FAILED = 'UtilityClass_getPhotoURL_FAILED';
    private static final String ERR_GET_PICKLIST_VALUES_FAILED = 'UtilityClass_getPickListValuesIntoList_FAILED';
    private static final String ERR_FORMAT_PHONE_FAILED = 'UtilityClass_formatPhone_FAILED';
    private static final String ERR_GET_BOARD_MEMBER_CONTACT_IDS_FAILED = 'UtilityClass_getBoardMemberContactIds_FAILED';
    private static final String ERR_GET_BOARD_MEMBER_CONTACT_ALERT_RECEIVER_FAILED = 'UtilityClass_getBoardMemberContactAlertReceiver_FAILED';
    private static final String ERR_GET_FIELDS_BY_FIELD_SET_FAILED = 'UtilityClass_getFieldsByFieldSet_FAILED';
    private static final String ERR_IS_SANDBOX_FAILED = 'UtilityClass_isSandbox_FAILED';
    private static final String ERR_CHECK_IF_USER_HAS_ASSIGNED_PERMISSION_SET_FAILED = 'UtilityClass_checkIfUserHasAssignedPermissionSet_FAILED';
    private static final String ERR_GET_SANDBOX_NAME_FAILED = 'UtilityClass_getSandboxName_FAILED';
    private static final String ERR_GET_ENVIRONMENT_FAILED = 'UtilityClass_getEnvironment_FAILED';
    private static final String ERR_GET_LAST_MONTH_NAME_FAILED = 'UtilityClass_getLastMonthName_FAILED';
    private static final String ERR_GET_LAST_MONTH_YEAR_FAILED = 'UtilityClass_getLastMonthYear_FAILED';  
    private static final String ERR_LOG_ERROR_INSERT_FAILED = 'UtilityClass_logError_Insert_FAILED';
    private static final String ERR_LOG_ERROR_FAILED = 'UtilityClass_logError_FAILED';
    private static final String ERR_STRING_CONTAINS_FAILED = 'UtilityClass_stringContains_FAILED';
    private static final String ERR_SAFE_SPLIT_FAILED = 'UtilityClass_safeSplit_FAILED';
    private static final String ERR_HAS_REQUIRED_PERMISSION_FAILED = 'UtilityClass_hasRequiredPermission_FAILED'; 
    private static final String ERR_GET_OBJECT_FIELD_LABELS_FAILED = 'UtilityClass_getObjectFieldLabels_FAILED';
    private static final String ERR_PROCESS_ACCOUNT_ORG_ENGAGEMENT_COUNT_FAILED = 'UtilityClass_processAccountOrgEngagementCount_FAILED';
    
    // for serializing and deserializing the picklist values, used in getFieldDependencies method
    public class MyPickListInfo {
        public String validFor;
    }

    // for getting dependent picklist values
    public static Map<String, List<String>> getFieldDependencies(String objectName, String controllingField, String dependentField) {
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            Schema.DescribeSObjectResult describeResult = objType.getDescribe();
            Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
            Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
            List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();//User.Countrycode.getDescribe().getPicklistValues();//
            List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();//User.statecode.getDescribe().getPicklistValues();//
            for(Schema.PicklistEntry currControllingValue : controllingValues) {
                controllingInfo.put(currControllingValue.getLabel(), new List<String>());
            }
            for(Schema.PicklistEntry currDependentValue : dependentValues) {
                String jsonString = JSON.serialize(currDependentValue);
                MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
                String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
                Integer baseCount = 0;
                for(Integer curr : hexString.getChars()) {
                    Integer val = 0;
                    if(curr >= 65) val = curr - 65 + 10;
                    else val = curr - 48;
                    if((val & 8) == 8) {
                        controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                    }
                    if((val & 4) == 4) {
                        controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());
                    }
                    if((val & 2) == 2) {
                        controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());
                    }
                    if((val & 1) == 1) {
                        controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());
                    }
                    baseCount += 4;
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_FIELD_DEPENDENCIES_FAILED));
        }
        return controllingInfo;
    }

    public static String getPhotoURL(String content) {
        // use reluctant regex to match each image tag individually
        // https://docs.oracle.com/javase/tutorial/essential/regex/quant.html
        String decodedURL = '';
        try {
            Matcher imgMatcher = Pattern.compile( '<img(.+?)>' ).matcher( content );
            // iterate each image tag found
            while(imgMatcher.find()) {
                // get the image tag html
                String imageTag = imgMatcher.group();
                // get the value of the src attribute
                // the leading space is significant to avoid other attributes like data-cke-saved-src
                String imageURL = imageTag.substringBetween( ' src="', '"' );
                // if url contained parameters they might be html escaped, unescape them
                // or, more conservatively, replace '&amp;' with '&'
                decodedURL = imageURL.unescapeHtml4();
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_PHOTO_URL_FAILED));
        }
        return decodedURL;
    }

    // utility method to get picklist values into a list of string
    public static List<String> getPickListValuesIntoList(String objectType, String selectedField) {
        List<String> pickListValuesList = new List<String>();
        try {
            Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
            Schema.DescribeSObjectResult res = convertToObj.getDescribe();
            Schema.DescribeFieldResult fieldResult;
            if(selectedField != null && selectedField == 'State') fieldResult = User.statecode.getDescribe();
            else fieldResult = res.fields.getMap().get(selectedField).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry pickListVal : ple) {
                pickListValuesList.add(pickListVal.getLabel());
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_PICKLIST_VALUES_FAILED));
        }
        return pickListValuesList;
    }

    public static wrapperPhones formatPhone(String phone, String longCountryCode, String longOldCountryCode) {
        wrapperPhones phones = new wrapperPhones();
        try {
            // Set Country Codes
            String countryCode = longCountryCode.Substring(longCountryCode.indexof('(')+1,longCountryCode.indexof(')'));
            String oldCountryCode = '';
            if(longOldCountryCode != null) {
                oldCountryCode = longOldCountryCode.Substring(longOldCountryCode.indexof('(')+1,longOldCountryCode.indexof(')'));
            }
            String phoneOnly = phone;
            if(phone.startsWith(countryCode)) {
                phoneOnly = phone.substringAfter(countryCode);
            } else if(oldCountryCode != '' && phone.startsWith(oldCountryCode)) {
                phoneOnly = phone.substringAfter(oldCountryCode);
            }
            String phoneOnlyDigitsOnly = phoneOnly.replaceAll('[^0-9]+', '');
            Integer phoneOnlyDigitsOnlyLenght = phoneOnlyDigitsOnly.length();
            if(phoneOnlyDigitsOnlyLenght == 10) {
                // Phone field is 10 digits only (+1 111-222-3333)
                phones.FormatedPhone = countryCode + ' ' + phoneOnlyDigitsOnly.substring(0,3) + '-' + phoneOnlyDigitsOnly.substring(3,6) + '-' + phoneOnlyDigitsOnly.substring(6,10);
            } else {
                phones.FormatedPhone = countryCode + ' ' + phoneOnlyDigitsOnly;
            }
            phones.phoneOnly = phoneOnlyDigitsOnly;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FORMAT_PHONE_FAILED));
        }
        return phones;
    }

    public class wrapperPhones {
        public String FormatedPhone { get; set; }
        public String PhoneOnly { get; set; }
    }

    public static Set<String> getBoardMemberContactIds(Set<Id> contactIds) {
        Set<String> tmpIds = new Set<String>();
        try {
            for(Contact cnt : [SELECT Id ,(SELECT Id FROM Employment_History__r WHERE Role__c = 'Board Member' AND Organization_Name__r.Name = 'Bloomberg Philanthropies')
                               FROM Contact
                               WHERE Id = :contactIds]) {

                if(cnt.Employment_History__r != null && cnt.Employment_History__r.size() > 0) {
                    tmpIds.add(cnt.Id);
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_BOARD_MEMBER_CONTACT_IDS_FAILED));
        }
        return tmpIds;
    }

    public static List<String> getBoardMemberContactAlertReceiver() {
        List<String> tmpEmailsList = new List<String>();
        try {
            Set<String> tmpEmails = new Set<String>();
            for(BoardMemberAlertReceiver__mdt bmar : [SELECT Email__c FROM BoardMemberAlertReceiver__mdt] ) {
                tmpEmails.add(bmar.Email__c);
            }
            tmpEmailsList = new List<String>(tmpEmails);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_BOARD_MEMBER_CONTACT_ALERT_RECEIVER_FAILED));
        }
        return tmpEmailsList;
    }

    public static Map<String,String> GetObjectFieldLabels(String objectAPIName) {
        Map<String,String> objectFieldMap =  new Map<String,String>();
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(objectAPIName);
            Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
            for (String fieldName: fieldMap.keySet()) {
                fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
                objectFieldMap.put(fieldName,fieldMap.get(fieldName).getDescribe().getLabel());
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_OBJECT_FIELD_LABELS_FAILED));
        }
        return objectFieldMap;
    }

    public static void processAccountOrgEngagementCount(Set<Id> accountIds) {
        try {
            List<Account> accounts = new List<Account>();
            Account acc = null;
            for(Account tmpAccount: [SELECT Id, EngagementCount__c, 
                                            (SELECT Id 
                                             FROM Interactions__r 
                                             WHERE RecordType.DeveloperName = :Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME)
                                     FROM Account
                                     WHERE Id = :accountIds]) {

                // Have to run through the records to get the count of interactions 
                // as the aggregate count using .size() on the child relationship has a limit of 200 records                       
                Integer engagementCount = 0;
                for(Interaction__c interaction : tmpAccount.Interactions__r) {
                    engagementCount++;
                }
                acc = new Account();
                acc.Id = tmpAccount.Id;
                acc.EngagementCount__c = engagementCount;
                accounts.add(acc);
            }
            if(accounts.size() > 0) {
                BBApps_Crud.doUpdateWithHandling(accounts, false, 'Account Org Engagement Count Update Failure');
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_PROCESS_ACCOUNT_ORG_ENGAGEMENT_COUNT_FAILED));
        }
    }

    public static Map<String, String> getFieldsByFieldSet(String objectName, String fieldSet) {
        Map<String,String> fieldApiLabelMap = new Map<String,String>();
        try {
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
            Map<String, Schema.FieldSet> fsMap = objectDescribe.fieldSets.getMap();
            if(fsMap.containsKey(fieldSet)) {
                for(Schema.FieldSetMember fsMember : fsMap.get(fieldSet).getFields()) {
                    fieldApiLabelMap.put(fsMember.getFieldPath(), fsMember.getLabel());
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_FIELDS_BY_FIELD_SET_FAILED));
        }
        return fieldApiLabelMap;
    }

    public static Boolean isSandbox() {
        try {
            return [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_IS_SANDBOX_FAILED));
            return false;   
        }
    }

    public static Boolean checkIfUserHasAssignedPermissionSet(String userId, String permissionSetName) {
        try {
            List<PermissionSetAssignment> permissionSA = 
                [SELECT Id 
                 FROM PermissionSetAssignment 
                 WHERE PermissionSetId IN (SELECT Id 
                                           FROM PermissionSet 
                                           WHERE Name = :permissionSetName) 
                   AND AssigneeId = :userId];
            return !permissionSA.isEmpty();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CHECK_IF_USER_HAS_ASSIGNED_PERMISSION_SET_FAILED));
            return false;   
        }
    }

    public static String getSandboxName() {
        try {
            String sandboxName = DomainParser.parse(DomainCreator.getOrgMyDomainHostname()).getSandboxName();
            return sandboxName;
        } catch(Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_SANDBOX_NAME_FAILED));
            return '';
        }
    }

    public static String getEnvironment() {
        String environment = Assets.DEV;
        try {
            String sandboxName = getSandboxName();
            if(String.isBlank(sandboxName)) {
                environment = Assets.PROD;
            } else if(!sandboxName.containsIgnoreCase(Assets.DEV)) {
                environment = sandboxName;
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_ENVIRONMENT_FAILED));
        }
        return environment;
    }

    public static String getLastMonthName() {
        try {
            Datetime dt = Datetime.now().addMonths(-1);
            return dt.format('MMMM');
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_LAST_MONTH_NAME_FAILED));
            return '';
        }
    }

    public static String getLastMonthYear() {
        try {
            Datetime dt = Datetime.now().addMonths(-1);
            return String.valueOf(dt.year());
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_LAST_MONTH_YEAR_FAILED));
            return '';
        }
    }

    public static void logError(String id, String message, String type) {
        try {
            MB_Error__c log = new MB_Error__c();
            log.Description__c = message;
            log.Object_Id__c = id;
            log.Type__c = type;
            BBApps_Crud.doInsertWithHandling(log, false, ERR_LOG_ERROR_INSERT_FAILED);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_LOG_ERROR_FAILED));     
        }       
    }
    
    // Purpose: Helper method used to string contains as part of the contact trigger processing.
    public static Boolean stringContains(String semiColonString, String value) {
        try {
            return semiColonString != null && (';' + semiColonString + ';').contains(';' + value + ';');
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_STRING_CONTAINS_FAILED));
            return false;
        }
    }
    
    /** Helper: safely split semicolon fields */
    // Purpose: Helper method used to safe split as part of the contact trigger processing.
    public static List<String> safeSplit(String val) {
        try {
            return (String.isNotBlank(val)) ? val.split(';') : new List<String>();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SAFE_SPLIT_FAILED));
            return new List<String>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean hasRequiredPermission(String permissionSet) {
        try {
            return FeatureManagement.checkPermission(permissionSet);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_HAS_REQUIRED_PERMISSION_FAILED));
            return false;
        }
    } 
}