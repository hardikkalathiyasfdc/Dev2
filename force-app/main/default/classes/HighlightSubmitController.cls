/**
* Author      : Ravi
* Date        : 09/10/2026
* Jira        : BRME-6952
* Description : This class is the controller for highlightSubmitForReview lightning web component.
* Test        : HighlightSubmitControllerTest
*/
public with sharing class HighlightSubmitController {
 
    private static final String ERR_VALIDATE = 'HighlightSubmitController_VALIDATE_FAILED';
    private static final String ERR_SUBMIT = 'HighlightSubmitController_SUBMIT_FAILED';
    private static final String ERR_UPDATE = 'HighlightSubmitController_UPDATE_FAILED';

    private static final String TYPE_CONTACT = 'Contact';
    private static final String TYPE_ORGANIZATION = 'Organization';

    public class ValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public List<String> errors;

        public ValidationResult() {
            this.isValid = true;
            this.errors = new List<String>();
        }

        public void addError(String message) {
            this.isValid = false;
            this.errors.add(message);
        }
    }

    @AuraEnabled
    public static ValidationResult validateHighlight(Id highlightId) {
        try {
            return runValidation(highlightId);
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_VALIDATE);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error validating highlight: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static ValidationResult submitForReview(Id highlightId) {
        try {
            ValidationResult result = runValidation(highlightId);
            if (!result.isValid) {
                return result;
            }

            List<Highlight_Interaction__c> toUpdate = new List<Highlight_Interaction__c>{
                new Highlight_Interaction__c(
                    Id = highlightId,
                    Status__c = Assets.SUBMITTED
                )
            };
            BBApps_Crud.doUpdateWithHandling(toUpdate, true, ERR_UPDATE);

            return result;
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SUBMIT);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error submitting highlight: ' + e.getMessage());
        }
    }

    private static ValidationResult runValidation(Id highlightId) {
        ValidationResult result = new ValidationResult();

        List<Highlight_Interaction__c> highlights = [
            SELECT Id,
                   Include_In_Program_Highlight__c,
                   Include_In_CityView__c,
                   Add_As_Contact_Interaction__c,
                   Submit_Program_Metric__c
            FROM Highlight_Interaction__c
            WHERE Id = :highlightId
            WITH USER_MODE
            LIMIT 1
        ];

        if (highlights.isEmpty()) {
            result.addError('This highlight could not be found.');
            return result;
        }

        Highlight_Interaction__c highlight = highlights[0];

        // BRME-7020: Private__c is reviewer-FLS only; read it only when accessible so requestors without FLS are unaffected.
        Boolean isPrivate = false;
        if (Highlight_Interaction__c.Private__c.getDescribe().isAccessible()) {
            isPrivate = [
                SELECT Private__c
                FROM Highlight_Interaction__c
                WHERE Id = :highlightId
                WITH USER_MODE
                LIMIT 1
            ].Private__c;
        }

        Boolean anySelected = highlight.Include_In_Program_Highlight__c
            || highlight.Include_In_CityView__c
            || highlight.Add_As_Contact_Interaction__c
            || isPrivate;

        if (!anySelected) {
            result.addError(
                'Please select at least one highlight option: Include in Program Highlight, Include in CityView, or Include as Contact Interaction.');
        }

        if (isPrivate && highlight.Include_In_CityView__c) {
            result.addError('Private highlights cannot be submitted to CityView.');
        }

        Map<String, Integer> participantCounts = getParticipantCounts(highlightId);

        if (highlight.Add_As_Contact_Interaction__c
            && participantCounts.get(TYPE_CONTACT) == null) {
            result.addError(
                'Please select at least one Participant - Contact (Mayor, President, Elected official) before submitting the Highlight Request as an Interaction.');
        }

        if (highlight.Include_In_CityView__c
            && participantCounts.get(TYPE_ORGANIZATION) == null) {
            result.addError(
                'Please select at least one Participant - Organization (city/state/country) before submitting the Highlight Request for CityView.');
        }

        if (highlight.Submit_Program_Metric__c) {
            Integer metricValueCount = [
                SELECT COUNT()
                FROM Metric_Value__c
                WHERE Highlight_Interaction__c = :highlightId
                WITH USER_MODE
            ];
            if (metricValueCount == 0) {
                result.addError(
                    'Please provide at least one metric value when ‘Submit Program Metric’ is selected.');
            }
        }

        return result;
    }

    private static Map<String, Integer> getParticipantCounts(Id highlightId) {
        Map<String, Integer> counts = new Map<String, Integer>();

        for (AggregateResult ar : [
            SELECT Type__c participantType, COUNT(Id) total
            FROM Interaction_Participant__c
            WHERE Highlight__c = :highlightId
            WITH USER_MODE
            GROUP BY Type__c
        ]) {
            String participantType = (String) ar.get('participantType');
            Integer total = (Integer) ar.get('total');
            if (participantType != null && total > 0) {
                counts.put(participantType, total);
            }
        }

        return counts;
    }
}