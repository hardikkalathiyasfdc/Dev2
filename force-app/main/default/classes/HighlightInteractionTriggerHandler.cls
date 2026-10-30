/**
 * Author            : Paddy
 * Date              : 09/11/2026
 * Jira              : BRME-6957
 * Description       : This is the handler class for HighlightInteraction object
 * Test              : HighlightInteractionTriggerHandlerTest
 */
public without sharing class HighlightInteractionTriggerHandler extends TriggerHandler {

    public List<Highlight_Interaction__c> newHighlights;
    public List<Highlight_Interaction__c> oldHighlights;
    public Map<Id, Highlight_Interaction__c> oldMap;
    public Map<Id, Highlight_Interaction__c> newMap;

    private List<File_Group__c> fileGroupsToInsert = new List<File_Group__c>();
    
    private Set<Id> cityViewHighlightIds = new Set<Id>();
    private Set<Id> metricHighlightIds = new Set<Id>();
    private Set<Id> participantDescriptionHighlightIds = new Set<Id>();
    private Set<Id> fileGroupPrivacySyncIds = new Set<Id>();
    private Set<Id> deletedHighlightIds = new Set<Id>();

    private static final Id CITYVIEW_RECORD_TYPE_ID = Schema.SObjectType.Interaction__c.getRecordTypeInfosByDeveloperName()
        	.get(Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME).getRecordTypeId();
    private static final String ERR_INTERACTION_INSERT = 'INTERACTION_INSERT_FAILED';
    private static final String ERR_INTERACTION_UPDATE = 'INTERACTION_UPDATE_FAILED';
    private static final String ERR_FILEGROUP_INSERT = 'FILEGROUP_INSERT_FAILED';
    private static final String ERR_METRIC_UPDATE = 'METRIC_LATEST_VALUE_UPDATE_FAILED';
    private static final String ERR_BULK_AFTER = 'HIGHLIGHT_INTERACTION_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_UPDATE_INTERACTION_DESC_METHOD = 'ERROR_UPDATE_INTERACTION_DESC_METHOD_FAILED';
    private static final String ERR_PROCESS_INTERACTION_METHOD = 'ERROR_PROCESS_INTERACTION_METHOD_FAILED';
    private static final String ERR_AND_FINALLY = 'HIGHLIGHT_INTERACTION_TRIGGER_AND_FINALLY_FAILED';
    private static final String ERR_PARTICIPANT_DESC_UPDATE = 'INTERACTION_PARTICIPANT_DESC_UPDATE_FAILED';
    private static final String ERR_PARTICIPANT_INTERACTION_UPDATE = 'INTERACTION_PARTICIPANT_INTERACTION_UPDATE_FAILED';
    private static final String ERR_FILEGROUP_PRIVACY_UPDATE = 'FILEGROUP_PRIVACY_UPDATE_FAILED';
    private static final String ERR_FILEGROUP_DELETE = 'FILEGROUP_DELETE_FAILED';

    public HighlightInteractionTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Highlight_Interaction__c>)Trigger.oldMap, (Map<Id, Highlight_Interaction__c>)Trigger.newMap);
    }

    public HighlightInteractionTriggerHandler(List<Highlight_Interaction__c> oldHighlightList, List<Highlight_Interaction__c> newHighlightList) {
        newHighlights = newHighlightList;
        oldHighlights = oldHighlightList;
    }

    public HighlightInteractionTriggerHandler(List<Highlight_Interaction__c> oldHighlightList, List<Highlight_Interaction__c> newHighlightList, Map<Id, Highlight_Interaction__c> oldMap, Map<Id, Highlight_Interaction__c> newMap) {
        newHighlights = newHighlightList;
        oldHighlights = oldHighlightList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    
    public override void afterInsert(SObject so) {
        Highlight_Interaction__c highlight = (Highlight_Interaction__c)so;
        processFileGroups(highlight);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Highlight_Interaction__c oldHighlight = (Highlight_Interaction__c)oldSo;
        Highlight_Interaction__c newHighlight = (Highlight_Interaction__c)so;
        updateDescription(newHighlight, oldHighlight);
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        Highlight_Interaction__c oldHighlight = (Highlight_Interaction__c)oldSo;
        Highlight_Interaction__c newHighlight = (Highlight_Interaction__c)so;

        // BRME-7020: private highlights must never reach CityView, even if the validation rule was bypassed (data load / API).
        if(newHighlight.Status__c == Assets.REVIEWED && newHighlight.Publish_To_CityView__c && newHighlight.Private__c != true &&
            (isFieldChanged(newHighlight, Assets.STATUS) || isFieldChanged(newHighlight, Assets.PUBLISH_TO_CITYVIEW))) {
                cityViewHighlightIds.add(newHighlight.Id);
        }

        if(isFieldChanged(newHighlight, Assets.STATUS) && newHighlight.Status__c == Assets.SUBMITTED
                && newHighlight.Submit_Program_Metric__c == true) {
            metricHighlightIds.add(newHighlight.Id);
        }

        if(isParticipantDescriptionUpdateRequired(newHighlight)) {
            participantDescriptionHighlightIds.add(newHighlight.Id);
        }

        // BRME-7020: keep the child File_Group__c privacy in sync with the highlight (both directions).
        if(isFieldChanged(newHighlight, 'Private__c')) {
            fileGroupPrivacySyncIds.add(newHighlight.Id);
        }
    }

    public override void afterDelete(SObject so) {
        // BRME-7020: cascade-delete the 1:1 attachment container when a highlight is deleted.
        deletedHighlightIds.add(so.Id);
    }

    private Boolean isParticipantDescriptionUpdateRequired(Highlight_Interaction__c newHighlight) {
        return newHighlight.Status__c == Assets.REVIEWED
            && newHighlight.Publish_To_CityView__c == true
            && newHighlight.Private__c != true
            && (isFieldChanged(newHighlight, Assets.STATUS)
                || isFieldChanged(newHighlight, Assets.PUBLISH_TO_CITYVIEW)
                || isFieldChanged(newHighlight, Assets.CITYVIEW_HIGHLIGHT_DESCRIPTION));
    }

    public override void bulkAfter() {
        try {
            if(!Trigger.isDelete) {
                FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields bbAppsError = new BBApps_ErrorCustomFields(ERR_BULK_AFTER);
            BBApps_ErrorHandler.logErrors(ex, bbAppsError);
        }
    }

    public override void andFinally() {
        try {
            if (Trigger.isAfter) {
                if(Trigger.isDelete) {
                    deleteFileGroupsForHighlights(deletedHighlightIds);
                } else if(Trigger.isUpdate) {
                    if(!participantDescriptionHighlightIds.isEmpty()) {
                        updateParticipantDescriptions();
                    }

                    if(!cityViewHighlightIds.isEmpty()) {
                        processInteractions();
                    }
                    
                    if(!metricHighlightIds.isEmpty()) {
                        updateLatestMetricValues();
                    }

                    if(!fileGroupPrivacySyncIds.isEmpty()) {
                        syncFileGroupPrivacy();
                    }
                } else if(Trigger.isInsert) {
                    if(!fileGroupsToInsert.isEmpty()) {
                        BBApps_Crud.doInsertWithHandling(
                            fileGroupsToInsert,
                            false,
                            new BBApps_ErrorCustomFields(ERR_FILEGROUP_INSERT)
                        );
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields bbAppsError = new BBApps_ErrorCustomFields(ERR_AND_FINALLY);
            BBApps_ErrorHandler.logErrors(ex, bbAppsError);
        }
    }

    /**
    * Description : BRME-7020 - sync File_Group__c.Private__c to the highlight's Private__c (both directions).
    */
    private void syncFileGroupPrivacy() {
        try {
            Map<Id, Boolean> privateByHighlight = new Map<Id, Boolean>();
            for (Id highlightId : fileGroupPrivacySyncIds) {
                privateByHighlight.put(highlightId, (Boolean)newMap.get(highlightId).get('Private__c'));
            }
            List<File_Group__c> toUpdate = new List<File_Group__c>();
            for (File_Group__c fg : [SELECT Id, Highlight__c, Private__c FROM File_Group__c WHERE Highlight__c IN :fileGroupPrivacySyncIds WITH SYSTEM_MODE]) {
                Boolean isPrivate = privateByHighlight.get(fg.Highlight__c);
                if (isPrivate != null && fg.Private__c != isPrivate) {
                    toUpdate.add(new File_Group__c(Id = fg.Id, Private__c = isPrivate));
                }
            }
            if (!toUpdate.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(toUpdate, false, new BBApps_ErrorCustomFields(ERR_FILEGROUP_PRIVACY_UPDATE));
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FILEGROUP_PRIVACY_UPDATE));
        }
    }

    /**
    * Description : BRME-7020 - delete the File_Group__c container when its highlight is deleted.
    */
    /**
    * Description : BRME-7020 - delete the File_Group__c container(s) for the given deleted highlights.
    * Parameters  : highlightIds Set<Id> of deleted highlights.
    */
    @TestVisible
    private static void deleteFileGroupsForHighlights(Set<Id> highlightIds) {
        if (highlightIds == null || highlightIds.isEmpty()) {
            return;
        }
        try {
            List<File_Group__c> toDelete = [SELECT Id FROM File_Group__c WHERE Highlight__c IN :highlightIds WITH SYSTEM_MODE];
            if (!toDelete.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(toDelete, false, AccessLevel.SYSTEM_MODE);
                for (Database.DeleteResult r : results) {
                    if (!r.isSuccess()) {
                        BBApps_ErrorHandler.logErrors(new DmlException('BRME-7020 file group delete failed: ' + r.getErrors()), new BBApps_ErrorCustomFields(ERR_FILEGROUP_DELETE));
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FILEGROUP_DELETE));
        }
    }

    private void processInteractions() {
        try {
            List<Interaction_Participant__c> participants = [
                        SELECT Id, Organization__c, Contact__c, Type__c, Description__c, Interaction__c, Highlight__r.Team__c, 
                        Highlight__r.Name, Highlight__r.CityView_Highlight_Description__c, Highlight__r.Start_Date__c, Highlight__c 
                        FROM Interaction_Participant__c
                        WHERE Highlight__c in :cityViewHighlightIds
                        WITH SYSTEM_MODE
                    ];

            List<Interaction__c> interactions = new List<Interaction__c>();
            Map<String, List<Interaction_Participant__c>> participantsByKey = new Map<String, List<Interaction_Participant__c>>();

            for(Interaction_Participant__c participant : participants) {
                interactions.add(buildInteraction(participant));

                String key = buildParticipantKey(
                    participant.Highlight__c,
                    Assets.ORGANIZATION.equalsIgnoreCase(participant.Type__c) ? participant.Organization__c : null,
                    Assets.CONTACT.equalsIgnoreCase(participant.Type__c) ? participant.Contact__c : null
                );

                if(!participantsByKey.containsKey(key)) {
                    participantsByKey.put(key, new List<Interaction_Participant__c>());
                }
                participantsByKey.get(key).add(participant);
            }

            if(!interactions.isEmpty()) {
                BBApps_Crud.doInsertWithHandling(
                    interactions,
                    false,
                    new BBApps_ErrorCustomFields(ERR_INTERACTION_INSERT)
                );
                linkParticipantsToInteractions(participantsByKey, interactions);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields bbAppsError = new BBApps_ErrorCustomFields(ERR_PROCESS_INTERACTION_METHOD);
            BBApps_ErrorHandler.logErrors(ex, bbAppsError);
        }
    }

    private void linkParticipantsToInteractions(Map<String, List<Interaction_Participant__c>> participantsByKey, List<Interaction__c> interactions) {
        List<Interaction_Participant__c> participantsToUpdate = new List<Interaction_Participant__c>();

        for(Interaction__c interaction : interactions) {
            if(interaction.Id == null) {
                continue;
            }

            String key = buildParticipantKey(
                interaction.Highlight_Interaction__c,
                interaction.Organization__c,
                interaction.Contact__c
            );

            List<Interaction_Participant__c> matches = participantsByKey.get(key);
            if(matches == null || matches.isEmpty()) {
                continue;
            }

            Interaction_Participant__c participant = matches.remove(0);
            if(participant.Interaction__c == interaction.Id) {
                continue;
            }

            participantsToUpdate.add(
                new Interaction_Participant__c(
                    Id = participant.Id,
                    Interaction__c = interaction.Id
                )
            );
        }

        if(!participantsToUpdate.isEmpty()) {
            BBApps_Crud.doUpdateWithHandling(
                participantsToUpdate,
                false,
                new BBApps_ErrorCustomFields(ERR_PARTICIPANT_INTERACTION_UPDATE)
            );
        }
    }

    private String buildParticipantKey(Id highlightId, Id organizationId, Id contactId) {
        return String.valueOf(highlightId) + '|' + String.valueOf(organizationId) + '|' + String.valueOf(contactId);
    }

    private void updateParticipantDescriptions() {
        try {
            List<Interaction_Participant__c> participantsToUpdate = new List<Interaction_Participant__c>();

            for(Interaction_Participant__c participant : [
                        SELECT Id, Description__c, Highlight__c,
                        Highlight__r.CityView_Highlight_Description__c
                        FROM Interaction_Participant__c
                        WHERE Highlight__c in :participantDescriptionHighlightIds
                        WITH SYSTEM_MODE
                    ]) {
                String highlightDescription = participant.Highlight__r.CityView_Highlight_Description__c;

                if(participant.Description__c != highlightDescription) {
                    participantsToUpdate.add(
                        new Interaction_Participant__c(
                            Id = participant.Id,
                            Description__c = highlightDescription
                        )
                    );
                }
            }

            if(!participantsToUpdate.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(
                    participantsToUpdate,
                    false,
                    new BBApps_ErrorCustomFields(ERR_PARTICIPANT_DESC_UPDATE)
                );
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields bbAppsError = new BBApps_ErrorCustomFields(ERR_PARTICIPANT_DESC_UPDATE);
            BBApps_ErrorHandler.logErrors(ex, bbAppsError);
        }
    }

    private Interaction__c buildInteraction(Interaction_Participant__c participant) {
        Interaction__c interaction = new Interaction__c(
                    Name = participant.Highlight__r.Name, 
                    Teams__c = participant.Highlight__r.Team__c,
                    Interaction_Date__c = participant.Highlight__r.Start_Date__c, 
                    Interaction_Type__c = 'Program Highlight',
                    CityView_Review_Status__c = 'Publish to CityView', 
                    Highlight_Interaction__c = participant.Highlight__c
                );

        interaction.Description__c = String.isNotBlank(participant.Description__c) 
            ? participant.Description__c 
            : participant.Highlight__r.CityView_Highlight_Description__c;

        if(Assets.ORGANIZATION.equalsIgnoreCase(participant.Type__c)) {
            interaction.recordTypeId = CITYVIEW_RECORD_TYPE_ID;
            interaction.Organization__c = participant.Organization__c;
        }
        if(Assets.CONTACT.equalsIgnoreCase(participant.Type__c)) {
            interaction.Contact__c = participant.Contact__c;
        }
        return interaction;
    }

    private void updateLatestMetricValues() {
        Map<Id, Metric_Value__c> latestByMetric = new Map<Id, Metric_Value__c>();
        Map<Id, Metric__c> metricsById = new Map<Id, Metric__c>();

        for (Metric_Value__c metricValue : [
                    SELECT Id, Metric__c, Date__c,
                    Metric__r.Latest_Metric_Value__c, Metric__r.Latest_Metric_Value__r.Date__c
                    FROM Metric_Value__c
                    WHERE Highlight_Interaction__c in :metricHighlightIds
                    AND Metric__c != null
                    AND Date__c != null
                    WITH SYSTEM_MODE
                    ORDER BY Date__c ASC, CreatedDate ASC
                ]) {
            latestByMetric.put(metricValue.Metric__c, metricValue);
            metricsById.put(metricValue.Metric__c, metricValue.Metric__r);
        }

        List<Metric__c> metricsToUpdate = new List<Metric__c>();
        for (Id metricId : latestByMetric.keySet()) {
            Metric_Value__c candidate = latestByMetric.get(metricId);
            Metric__c metric = metricsById.get(metricId);

            if (metric.Latest_Metric_Value__c == candidate.Id) {
                continue;
            }

            Date existingDate = metric.Latest_Metric_Value__c == null
                ? null
                : metric.Latest_Metric_Value__r.Date__c;

            if (existingDate == null || existingDate <= candidate.Date__c) {
                metricsToUpdate.add(new Metric__c(Id = metricId, Latest_Metric_Value__c = candidate.Id));
            }
        }

        if(!metricsToUpdate.isEmpty()) {
            BBApps_Crud.doUpdateWithHandling(
                metricsToUpdate,
                false,
                new BBApps_ErrorCustomFields(ERR_METRIC_UPDATE)
            );
        }
    }
    
    /**
    * Description : Method to create new FileGroup records after insert.
    * Parameters  : highlight Highlight_Interaction__c
    * Return Type : void
    */
    private void processFileGroups(Highlight_Interaction__c highlight) {
        fileGroupsToInsert.add(
            new File_Group__c(
                Highlight__c  = highlight.Id,
                Object_Type__c = Assets.HIGHLIGHT,
                Category__c = Assets.HIGHLIGHT,
                Private__c = (Boolean)highlight.get('Private__c')
            )
        );
    }

    private void updateDescription(Highlight_Interaction__c newHighlight, Highlight_Interaction__c oldHighlight) {
        if(isFieldChanged(newHighlight, Assets.STATUS) && newHighlight.Status__c == Assets.SUBMITTED) {
            newHighlight.CityView_Highlight_Description__c = newHighlight.Description__c;
            newHighlight.Leadership_Highlight_Description__c = newHighlight.Description__c;
        }

        if(isFieldChanged(newHighlight, Assets.INCLUDE_AS_MRB_HIGHLIGHT) && newHighlight.Include_As_MRB_Highlight__c == true && String.isBlank(newHighlight.MRB_Highlight_Description__c)) {
            newHighlight.MRB_Highlight_Description__c = newHighlight.Leadership_Highlight_Description__c;
        }
    }
}