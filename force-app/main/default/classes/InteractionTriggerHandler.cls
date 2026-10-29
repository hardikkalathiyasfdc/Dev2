public without sharing class InteractionTriggerHandler extends TriggerHandler {
    // ---- Error Codes ----
    private static final String ERR_BULK_BEFORE      = 'INTERACTION_BULK_BEFORE_FAILED';
    private static final String ERR_AND_FINALLY      = 'INTERACTION_AND_FINALLY_FAILED';
    private static final String ERR_PERM_CHECK       = 'INTERACTION_PERM_CHECK_FAILED';
    private static final String ERR_VALIDATE_LOCK    = 'INTERACTION_VALIDATE_LOCK_FAILED';
    private static final String ERR_LIST_MEMBERSHIP  = 'INTERACTION_LIST_MEMBERSHIP_FAILED';
    private static final String ERR_CLONE_METHOD     = 'INTERACTION_CLONE_PREP_FAILED';
    private static final String ERR_CLONE_INSERT     = 'INTERACTION_CLONE_INSERT_FAILED';
    private static final String ERR_CONF_FIELDS      = 'INTERACTION_CONF_FIELDS_FAILED';
    private static final String ERR_SUMMARY_BUILD    = 'INTERACTION_SUMMARY_BUILD_FAILED';
    private static final String ERR_SUBJECT_UPDATE   = 'INTERACTION_SUBJECT_UPDATE_FAILED';

    public List<Interaction__c> newInteractions;
    public List<Interaction__c> oldInteractions;
    public Map<Id, Set<Id>> contactCampaignMembership;
    public List<Id> contactIdsForInteractionSharing;
    public Set<Id> accountIdsForOrgEngagementCounts;
    public Map<ID, Schema.RecordTypeInfo> interactionRecordTypesMap = Interaction__c.sObjectType.getDescribe().getRecordTypeInfosById();
    public static final Id CITYVIEW_REC_ID = Schema.SObjectType.Interaction__c.getRecordTypeInfosByDeveloperName().get('Recent_Engagement').getRecordTypeId();
    public static Set<String> cityViewSkipCloneTypes = new Set<String>{'Recent_Engagement', 'X2020', 'MRB_Interaction'};
    public Set<Id> cityViewInteractions;
    public Set<String> confidentialFields = getConfidentialFields();
    private static List<Interaction__c> submitCityViewList;
    private static Map<Id, Id> cityViewConToOrgMap;
    public boolean hasCityViewPermission;
    private static Set<String> cityViewDupes = new Set<String>();

    public InteractionTriggerHandler() {
        this(Trigger.old, Trigger.new);
    }

    public InteractionTriggerHandler(List<Interaction__c> oldInteractionList, List<Interaction__c> newInteractionList) {
        oldInteractions = oldInteractionList;
        newInteractions = newInteractionList;
        contactIdsForInteractionSharing = new List<Id>();
        accountIdsForOrgEngagementCounts = new Set<Id>();
        hasCityViewPermission = getCityViewPermission();
    }

    public override void bulkBefore() {
        try {
            List<Id> contactIds = new List<Id>();
            Set<Id> cityViewContactIds = new Set<Id>();
            submitCityViewList = new List<Interaction__c>();
            cityViewConToOrgMap = new Map<Id, Id>();
            Map<Id, Contact> contactsMap = new Map<Id, Contact>();

            for (Interaction__c interaction : newInteractions) {
                if (String.isNotBlank(interaction.Contact__c)) {
                    contactIds.add(interaction.Contact__c);
                }
                if (isCityViewSubmit(interaction)) {
                    submitCityViewList.add(interaction);
                    cityViewContactIds.add(interaction.Contact__c);
                }
            }

            contactCampaignMembership = new Map<Id, Set<Id>>();
            if (!contactIds.isEmpty()) {
                for (CampaignMember cm : [SELECT Id, CampaignId, ContactId FROM CampaignMember WHERE ContactId IN :contactIds]) {
                    if (!contactCampaignMembership.containsKey(cm.ContactId))
                        contactCampaignMembership.put(cm.ContactId, new Set<Id>());
                    contactCampaignMembership.get(cm.ContactId).add(cm.CampaignId);
                }

                List<Contact> conList = [SELECT Id, AccountId, Account.Name FROM Contact WHERE Id IN :contactIds];
                for (Contact c : conList) {
                    if (cityViewContactIds.contains(c.Id) && c.AccountId != null && c.Account.Name != '-') {
                        cityViewConToOrgMap.put(c.Id, c.AccountId);
                    }
                    contactsMap.put(c.Id, c);
                }
            }

            for (Interaction__c interaction : newInteractions) {
                if (interactionRecordTypesMap.get(interaction.RecordTypeId).DeveloperName != Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME &&
                    (Trigger.isInsert || (Trigger.isUpdate && isFieldChanged(interaction, 'Contact__c')))) {
                        interaction.Contact_Interaction_Organization__c = contactsMap.get(interaction.Contact__c).AccountId;
                    }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_BEFORE));
            throw ex;
        }
    }

    public override void beforeInsert(SObject so) {
		Interaction__c interaction = (Interaction__c)so;
		checkListMembership(interaction);
		validateCityViewLock(interaction);
		updateInteractionSubject(interaction);
        populateInteractionSummary(interaction); // Call the new method to populate Interaction_Summary__c & Interaction_Summary_Source__c
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
		Interaction__c interaction = (Interaction__c)so;
		checkListMembership(interaction);
		validateCityViewLock(interaction);
		if(isFieldChanged(interaction, 'Private_Interaction__c')) updateInteractionSubject(interaction);
        populateInteractionSummary(interaction); // Call the new method to populate Interaction_Summary__c & Interaction_Summary_Source__c
    }

    private void checkListMembership(Interaction__c interaction) {
        try {
            if (interaction.Contact__c != null && interaction.List__c != null) {
                if (!(contactCampaignMembership.containsKey(interaction.Contact__c) &&
                      contactCampaignMembership.get(interaction.Contact__c).contains(interaction.List__c))) {
                    interaction.addError('Please add this contact to the selected List.');
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_LIST_MEMBERSHIP));
            throw ex;
        }
    }

    public override void afterInsert(SObject so) {
		Interaction__c interaction = (Interaction__c)so;
        if (interactionRecordTypesMap.get(interaction.RecordTypeId).Name == Assets.INTERACTION_RECORDTYPE_TOUCHPOINT) {
            contactIdsForInteractionSharing.add(interaction.Contact__c);
        }

        if (interactionRecordTypesMap.get(interaction.RecordTypeId).getDeveloperName() == Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME) {
            accountIdsForOrgEngagementCounts.add(interaction.Organization__c);
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
		Interaction__c interaction = (Interaction__c)so;
        Interaction__c oldInteraction = (Interaction__c)oldSo;
        if (interaction.RecordTypeId != oldInteraction.RecordTypeId &&
            (interactionRecordTypesMap.get(interaction.RecordTypeId).Name == Assets.INTERACTION_RECORDTYPE_TOUCHPOINT || interactionRecordTypesMap.get(oldInteraction.RecordTypeId).Name == Assets.INTERACTION_RECORDTYPE_TOUCHPOINT)) {
            contactIdsForInteractionSharing.add(interaction.Contact__c);
        }
    }

    public override void afterDelete(SObject so) {
		Interaction__c interaction = (Interaction__c)so;

		if (interactionRecordTypesMap.get(interaction.RecordTypeId).getDeveloperName() == Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME) {
			accountIdsForOrgEngagementCounts.add(interaction.Organization__c);
		}
    }

    public override void andFinally() {
        try {
            if (accountIdsForOrgEngagementCounts.size() > 0) {
                UtilityClass.processAccountOrgEngagementCount(accountIdsForOrgEngagementCounts);
            }
            if (Trigger.isAfter)
                cloneCityViewInteractions();
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AND_FINALLY));
            throw ex;
        }
    }

    private void validateCityViewLock(Interaction__c interaction) {
        try {
            if (hasCityViewPermission == true || (!Trigger.isInsert && !Trigger.isUpdate)) {
                return;
            }
            if (interaction.CityView_Review_Status__c == 'Publish to CityView' && (Trigger.isUpdate || Trigger.isInsert)) {
                interaction.addError(Label.City_View_Publish_Error);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_VALIDATE_LOCK));
            throw ex;
        }
    }

    private boolean getCityViewPermission() {
        try {
            Boolean hasPermission = FeatureManagement.checkPermission('City_View_Publish');
            if (!hasPermission) {
                String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
                hasPermission = String.isNotBlank(profileName) && profileName.contains('System Administrator');
            }
            if(hasPermission == true){
                return true;
            }
            return false;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_PERM_CHECK));
            return false;
        }
    }

    private void cloneCityViewInteractions() {
        try {
            if ((!Trigger.isInsert && !Trigger.isUpdate) || submitCityViewList == null || submitCityViewList.isEmpty() || cityViewConToOrgMap.isEmpty()) {
                return;
            }
            List<Interaction__c> cloneList = new List<Interaction__c>();
            for (Interaction__c interaction : submitCityViewList) {
                Id orgId = cityViewConToOrgMap.get(interaction.Contact__c);

            String dupeKey = interaction.Name + '-' + interaction.Interaction_Date__c + '-' + orgId;
                if (orgId != null && !cityViewDupes.contains(dupeKey)) {
                    Interaction__c clone = interaction.clone(false, false, false, false);
                    clone.recordTypeId = CITYVIEW_REC_ID;
                    clone.Organization__c = orgId;
                clone.Contact_Interaction_Organization__c = null;
                    clone.Contact__c = null;
                    for (String field : confidentialFields) {
                        clone.put(field, null);
                    }
                    cloneList.add(clone);
                    cityViewDupes.add(dupeKey);
                }
            }
            if (!cloneList.isEmpty()) {
                BBApps_Crud.doInsertWithHandling(
                    (List<SObject>)cloneList,
                    false,
                    new BBApps_ErrorCustomFields(ERR_CLONE_INSERT)
                );
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CLONE_METHOD));
            throw ex;
        }
    }

    private boolean isCityViewSubmit(Interaction__c interaction) {
        String recDevName = interactionRecordTypesMap?.get(interaction.recordTypeId)?.getDeveloperName();
        if (String.isNotBlank(recDevName) && cityViewSkipCloneTypes.contains(recDevName)) {
            return false;
        }

        return (Trigger.isInsert || Trigger.isUpdate) && interaction.Add_to_CityView__c == true && isFieldChanged(interaction, 'Add_to_CityView__c') && interaction.Contact__c != null;
    }

    private Set<String> getConfidentialFields() {
        try {
            Set<String> confSet = new Set<String>();
            List<Schema.FieldSetMember> fieldList = Schema.SObjectType.Interaction__c.fieldSets.Confidential_Fields.getFields();
            for (Schema.FieldSetMember mem : fieldList) {
                confSet.add(mem.getFieldPath());
            }
            return confSet;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CONF_FIELDS));
            return new Set<String>();
        }
    }

    private void populateInteractionSummary(Interaction__c interactionSummary) {
        try {
            Map<String,Schema.SObjectField> fieldLabels = Schema.Interaction__c.SObjectType.getDescribe().fields.getMap();
            String interactionSourceLabel = '';
            String teamText = interactionSummary.Teams__r != null ? interactionSummary.Teams__r.Name + ': ' : '';

            String interactionSummaryValue = null;
            if (String.isNotBlank(interactionSummary.Background__c)) {
                interactionSummaryValue = interactionSummary.Background__c;
                interactionSourceLabel = (fieldLabels.get('Background__c').getDescribe()).getLabel() ;
            } else if (String.isNotBlank(interactionSummary.Organization_Confidential_Background__c)) {
                interactionSummaryValue = interactionSummary.Organization_Confidential_Background__c;
                interactionSourceLabel = (fieldLabels.get('Organization_Confidential_Background__c').getDescribe()).getLabel();
            }

            if (String.isBlank(interactionSummaryValue)) {
                interactionSummaryValue = interactionSummary.LPLeadershipConfidentialBackground__c;
                interactionSourceLabel = (fieldLabels.get('LPLeadershipConfidentialBackground__c').getDescribe()).getLabel() ;
            }

            if (String.isBlank(interactionSummaryValue)) {
                interactionSummaryValue = interactionSummary.CorrespondenceConfidentialDescription__c;
                interactionSourceLabel = (fieldLabels.get('CorrespondenceConfidentialDescription__c').getDescribe()).getLabel();
            }

            if (String.isBlank(interactionSummaryValue)) {
                interactionSummaryValue = interactionSummary.Description__c;
                interactionSourceLabel = (fieldLabels.get('Description__c').getDescribe()).getLabel();
            }

            if (String.isBlank(interactionSummaryValue)) {
                interactionSummaryValue = interactionSummary.Name;
                interactionSourceLabel = (fieldLabels.get('Name').getDescribe()).getLabel();
            }

            interactionSummary.Interaction_Summary__c = teamText + (interactionSummaryValue != null ? interactionSummaryValue : '');
            interactionSummary.Interaction_Summary_Source__c = interactionSourceLabel;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SUMMARY_BUILD));
            throw ex;
        }
    }

    private void updateInteractionSubject(Interaction__c interaction) {
        try {
            String privateTag = ' (Private)';
            if(interaction.Private_Interaction__c && !interaction.Name.contains(privateTag)) {
                interaction.Original_Subject__c = interaction.Name;
                interaction.Name = interaction.Name.left(70) + privateTag;
            } else if(!interaction.Private_Interaction__c && interaction.Name.contains(privateTag)) {
                interaction.Name = (interaction.Original_Subject__c == null || interaction.Original_Subject__c == '')
                                   ? interaction.Name.replace(privateTag, '')
                                   : interaction.Original_Subject__c;
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SUBJECT_UPDATE));
            throw ex;
        }
    }
}