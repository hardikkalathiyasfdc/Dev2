/**
 * Author            : Ravi Bheemreddy
 * Date              : 10/20/2026
 * Jira              : BRME-7043
 * Description       : This is the handler class for initiativeReadyForApproval component
 * Test              : IMInitiativeReadyForApprovalControllerTest
 */
public with sharing class IMInitiativeReadyForApprovalController {

    private static final String ERR_SUBMIT = 'InitiativeReadyForApprovalController_SUBMIT_FAILED';
    private static final String ERR_UPDATE = 'InitiativeReadyForApprovalController_UPDATE_FAILED';
    private static final String ERR_MESSAGE = 'Error marking initiative Ready for Approval: ';

    @TestVisible
    private static final List<String> YES_FIELDS = new List<String>{
        'Term_Alignment__c',
        'Required_Approval_Docs__c',
        'Initiative_Name_and_Budget_Name_Review__c'
    };

    @TestVisible
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Strategic_Locations_Aligned__c',
        'Budget_Aligns_with_Memo__c',
        'Type_of_Work_Aligns_Memo__c',
        'Overview__c'
    };

    @AuraEnabled
    public static List<String> markReadyForApproval(Id recordId) {
        try {
            IM_Initiative__c record = [
                SELECT Id, Status__c,
                    Term_Alignment__c,
                    Required_Approval_Docs__c,
                    Initiative_Name_and_Budget_Name_Review__c,
                    Strategic_Locations_Aligned__c,
                    Budget_Aligns_with_Memo__c,
                    Type_of_Work_Aligns_Memo__c,
                    Overview__c
                FROM IM_Initiative__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ];

            List<String> invalidFields = getInvalidFields(record);
            if (!invalidFields.isEmpty()) {
                return invalidFields;
            }

            List<IM_Initiative__c> toUpdate = new List<IM_Initiative__c>{
                new IM_Initiative__c(
                    Id = recordId,
                    Status__c = Assets.READY_FOR_APPROVAL
                )
            };
            BBApps_Crud.doUpdateWithHandling(toUpdate, true, ERR_UPDATE);

            return invalidFields;
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SUBMIT);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException(ERR_MESSAGE + e.getMessage());
        }
    }

    @TestVisible
    private static List<String> getInvalidFields(IM_Initiative__c record) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.IM_Initiative__c.fields.getMap();
        List<String> invalidFields = new List<String>();

        for (String fieldName : YES_FIELDS) {
            Object value = record.get(fieldName);
            if (value == null || !Assets.VALUE_YES.equalsIgnoreCase(String.valueOf(value))) {
                invalidFields.add(fieldMap.get(fieldName).getDescribe().getLabel());
            }
        }

        for (String fieldName : REQUIRED_FIELDS) {
            Object value = record.get(fieldName);
            if (value == null || String.isBlank(String.valueOf(value).stripHtmlTags())) {
                invalidFields.add(fieldMap.get(fieldName).getDescribe().getLabel());
            }
        }

        return invalidFields;
    }
}