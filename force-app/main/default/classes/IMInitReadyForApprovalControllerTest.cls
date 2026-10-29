/**
 * Author            : Ravi Bheemreddy
 * Date              : 10/20/2026
 * Jira              : BRME-7043
 * Description       : This is a test class for IMInitiativeReadyForApprovalController
 */
@isTest
private class IMInitReadyForApprovalControllerTest {

    @testSetup
    static void setupTestData() {
        TestDataFactory.createInitiativeBaseData();
    }

    @isTest
    static void testMarkReadyForApprovalReturnsInvalidFields() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');

        Test.startTest();
            List<String> invalidFields = IMInitiativeReadyForApprovalController.markReadyForApproval(initiative.Id);
        Test.stopTest();

        IM_Initiative__c updatedInitiative = [
            SELECT Id, Status__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
            WITH SYSTEM_MODE
        ];

        Assert.isFalse(invalidFields.isEmpty(), 'Invalid fields should be returned');
        Assert.areNotEqual(Assets.READY_FOR_APPROVAL, updatedInitiative.Status__c,
            'Status should not be Ready for Approval');
    }

    @isTest
    static void testGetInvalidFieldsWhenAllCriteriaMet() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'IM_Initiative__c' },
            'Overview__c' => 'Test Overview'
        };
        for (String fieldName : IMInitiativeReadyForApprovalController.YES_FIELDS) {
            fieldValues.put(fieldName, Assets.VALUE_YES);
        }
        for (String fieldName : IMInitiativeReadyForApprovalController.REQUIRED_FIELDS) {
            if (!fieldValues.containsKey(fieldName)) {
                fieldValues.put(fieldName, Assets.VALUE_YES);
            }
        }
        IM_Initiative__c initiative = (IM_Initiative__c) JSON.deserialize(JSON.serialize(fieldValues), IM_Initiative__c.class);

        Test.startTest();
            List<String> invalidFields = IMInitiativeReadyForApprovalController.getInvalidFields(initiative);
        Test.stopTest();

        Assert.isTrue(invalidFields.isEmpty(), 'No fields should be invalid');
    }

    @isTest
    static void testMarkReadyForApprovalThrowsHandledException() {
        Boolean exceptionThrown = false;

        Test.startTest();
            try {
                IMInitiativeReadyForApprovalController.markReadyForApproval(UserInfo.getUserId());
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should be thrown when the initiative is not found');
    }
}