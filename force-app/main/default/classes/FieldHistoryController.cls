/**
* FieldHistoryController
*
* Controller class for handling server-side logic for the CustomFieldHistoryTable Lightning Web Component.
* This class is responsible for fetching custom history records from the Custom_History__c object,
* ensuring the user has access to the fields on the parent object, and formatting the field values
* appropriately for display in the LWC.
*
* Author : Ravi Bheemreddy
* Jira   : BRME-5388
* Test   : FieldHistoryControllerTest
*/
public with sharing class FieldHistoryController {

    private static final String ERR_FETCH_HISTORY_RECORDS = 'FIELD_HISTORY_CONTROLLER_FETCH_HISTORY_RECORDS_FAILED';
    private static final String ERR_FORMAT_FIELD_VALUE = 'FIELD_HISTORY_CONTROLLER_FORMAT_FIELD_VALUE_FAILED';
    @TestVisible
    private static Boolean forceException = false;

    @AuraEnabled(cacheable=true)
    public static List<HistoryWrapper> fetchHistoryRecords(String parentId, Integer offset, Integer limitRows) {
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<Custom_History__c> historyRecords = [
                SELECT CreatedDate, Field_API_Name__c, Old_Value__c, New_Value__c, CreatedBy.Name, CreatedById, Object_API_Name__c
                FROM Custom_History__c
                WHERE Record_ID__c = :parentId
                ORDER BY CreatedDate DESC
                LIMIT :limitRows OFFSET :offset
            ];

            List<HistoryWrapper> historyWrappers = new List<HistoryWrapper>();

            Schema.SObjectType sObjectType = Id.valueOf(parentId).getSObjectType();
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();

            for (Custom_History__c history : historyRecords) {
                Schema.SObjectField field = fieldMap.get(history.Field_API_Name__c);
                if (field != null && field.getDescribe().isAccessible()) {
                    historyWrappers.add(new HistoryWrapper(
                        history.CreatedDate,
                        field.getDescribe().getLabel(),
                        history.Old_Value__c,
                        history.New_Value__c,
                        history.CreatedBy.Name,
                        history.CreatedById,
                        field.getDescribe().getType(),
                        field.getDescribe().isHtmlFormatted()
                    ));
                }
            }

            return historyWrappers;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_FETCH_HISTORY_RECORDS));
            return null;
        }
    }

    public class HistoryWrapper {
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String originalValue;
        @AuraEnabled public String newValue;
        @AuraEnabled public String userName;
        @AuraEnabled public String userId;
        @AuraEnabled public Boolean isRichText;

        public HistoryWrapper(DateTime createdDate, String fieldLabel, String originalValue, String newValue, String userName, String userId, Schema.DisplayType fieldType, Boolean isRichText) {
            this.createdDate = createdDate;
            this.fieldLabel = fieldLabel;
            this.originalValue = formatFieldValue(originalValue, fieldType);
            this.newValue = formatFieldValue(newValue, fieldType);
            this.userName = userName;
            this.userId = userId;
            this.isRichText = isRichText;
        }

        private String formatFieldValue(String value, Schema.DisplayType fieldType) {
            try{
                if (Test.isRunningTest() && forceException) {
                    throw new AuraHandledException('Forced exception for test');
                }
                if (value == null) return '';

                if (fieldType != null) {
                    // Check if the field is of type Date or DateTime and format accordingly
                    if (fieldType == Schema.DisplayType.Date) {
                        return formatDateValue(value);
                    } else if (fieldType == Schema.DisplayType.DateTime) {
                        return formatDateTimeValue(value);
                    }
                }
                // Return the original value if it's not a Date or DateTime
                return value;
            } catch (Exception ex) {
                BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_FORMAT_FIELD_VALUE));
                return null;
            }
        }

        private String formatDateValue(String value) {
            Date dateValue = Date.valueOf(value);
            return String.format('{0}/{1}/{2}', new List<Object>{dateValue.month(), dateValue.day(), dateValue.year()});
        }

        private String formatDateTimeValue(String value) {
            Datetime dtValue = Datetime.valueOf(value);
            return dtValue.format('M/d/yyyy, h:mm a');
        }
    }
}