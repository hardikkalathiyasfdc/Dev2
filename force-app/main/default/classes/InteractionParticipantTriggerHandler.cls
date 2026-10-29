/**
 * Author            : Paddy
 * Date              : 09/21/2026
 * Jira              : BRME-6957
 * Description       : This is the handler class for InteractionParticipant object
 * Test              : InteractionParticipantTriggerHandlerTest
 */
public with sharing class InteractionParticipantTriggerHandler extends TriggerHandler {

    public List<Interaction_Participant__c> newParticipants;
    public List<Interaction_Participant__c> oldParticipants;
    public Map<Id, Interaction_Participant__c> oldMap;
    public Map<Id, Interaction_Participant__c> newMap;

    private Map<Id, String> descriptionByInteractionId = new Map<Id, String>();
    private Set<Id> deletedParticipantIds = new Set<Id>();

    private static final String ERR_BULK_AFTER = 'ACCOUNT_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_AND_FINALLY = 'INTERACTION_PARTICIPANT_TRIGGER_AND_FINALLY_FAILED';
    private static final String ERR_INTERACTION_DESC_UPDATE = 'INTERACTION_DESC_UPDATE_FAILED';
    public static final String DELETE_ERROR_MESSAGE = 'You do not have sufficient permissions to delete this record.';

     public InteractionParticipantTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Interaction_Participant__c>)Trigger.oldMap, (Map<Id, Interaction_Participant__c>)Trigger.newMap);
    }

    public InteractionParticipantTriggerHandler(List<Interaction_Participant__c> oldParticipantList, List<Interaction_Participant__c> newParticipantList) {
        newParticipants = newParticipantList;
        oldParticipants = oldParticipantList;
    }

    public InteractionParticipantTriggerHandler(List<Interaction_Participant__c> oldParticipantList, List<Interaction_Participant__c> newParticipantList, Map<Id, Interaction_Participant__c> oldMap, Map<Id, Interaction_Participant__c> newMap) {
        newParticipants = newParticipantList;
        oldParticipants = oldParticipantList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        Interaction_Participant__c newParticipant = (Interaction_Participant__c)so;

        if(isInteractionDescriptionUpdateRequired(newParticipant)) {
            descriptionByInteractionId.put(newParticipant.Interaction__c, newParticipant.Description__c);
        }
    }

    public override void beforeDelete(SObject so) {
        deletedParticipantIds.add(((Interaction_Participant__c) so).Id);
	}

    private Boolean isInteractionDescriptionUpdateRequired(Interaction_Participant__c newParticipant) {
        return newParticipant.Interaction__c != null
            && isFieldChanged(newParticipant, Assets.DESCRIPTION);
    }

    public override void andFinally() {
        try {
            if(Trigger.isAfter && Trigger.isUpdate && !descriptionByInteractionId.isEmpty()) {
                updateInteractionDescriptions();
            } else if(Trigger.isBefore && Trigger.isDelete) {
                if(!deletedParticipantIds.isEmpty()) {
                    checkForDeletion();
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields bbAppsError = new BBApps_ErrorCustomFields(ERR_AND_FINALLY);
            BBApps_ErrorHandler.logErrors(ex, bbAppsError);
        }
    }

    private void updateInteractionDescriptions() {
        List<Interaction__c> interactionsToUpdate = new List<Interaction__c>();

        for(Id interactionId : descriptionByInteractionId.keySet()) {
            interactionsToUpdate.add(
                new Interaction__c(
                    Id = interactionId,
                    Description__c = descriptionByInteractionId.get(interactionId)
                )
            );
        }

        if(!interactionsToUpdate.isEmpty()) {
            BBApps_Crud.doUpdateWithHandling(
                interactionsToUpdate,
                false,
                new BBApps_ErrorCustomFields(ERR_INTERACTION_DESC_UPDATE)
            );
        }
    }

    public override void bulkAfter() {
        try {
            if(!Trigger.isDelete) {
                FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BULK_AFTER);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    /**
	* Description     : Method to prevent deletion.
	* Parameters      : None
	* Return Type     : void
	*/
	public void checkForDeletion() {
        Boolean isRequester = FeatureManagement.checkPermission('Highlights_Metrics_Requestor');
        List<Interaction_Participant__c> deletedParticipants = [SELECT Highlight__r.Status__c FROM Interaction_Participant__c WITH SYSTEM_MODE];
        for(Interaction_Participant__c participant : deletedParticipants) {
            if(isRequester && !Assets.DRAFT.equalsIgnoreCase(participant.Highlight__r.Status__c)) {
                participant.addError(DELETE_ERROR_MESSAGE);
            }
        }
	}
}