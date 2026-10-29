/**
 * Author            : Paddy
 * Date              : 09/21/2026
 * Jira              : BRME-6957
 * Description       : Test class for InteractionParticipantTriggerHandler.
 */
@isTest
private class InteractionParticipantTriggerHandlerTest {

    @TestSetup
	static void setupData() {
		Team__c artsTeam = TestDataFactory.createTeam('Arts');
        Highlight_Interaction__c highlightInteraction = TestDataFactory.createHighlightInteraction('September Highlights', artsTeam, 'Highlight description text', 'Leadership highlight description');
        Account org = TestDataFactory.createOrg('Highlight Org');
        Contact contact = TestDataFactory.createContact(org.Id, 'Highlight');
        TestDataFactory.createInteractionParticipant(
			highlightInteraction.Id,
			'Contact',
			null,
			contact.Id,
			null
		);
	}
    
    private static void addHistorySettings() {
        FieldHistoryService.testFieldsToTrackOverride = new List<History_Setting__mdt> {
            new History_Setting__mdt(
            	Object__c = 'Interaction_Participant__c',
                Field__c = 'Description__c'
            )
        };
    }

    @isTest
	static void testFieldHistory() {
        Highlight_Interaction__c highlights = [SELECT Id FROM Highlight_Interaction__c 
                                               WHERE Name = 'September Highlights' 
                                               WITH SYSTEM_MODE];
        Interaction_Participant__c participant = [SELECT Description__c FROM Interaction_Participant__c 
                                                  WHERE Highlight__c = :highlights.Id 
                                                  WITH SYSTEM_MODE];
		addHistorySettings();
        Test.startTest();
            participant.Description__c = 'Updated description';
            update as system participant;
        Test.stopTest();
        List<Custom_History__c> customHistory = [SELECT Id, Field_API_Name__c, Old_Value__c,New_Value__c 
                FROM Custom_History__c WHERE Object_API_Name__c = 'Interaction_Participant__c' WITH SYSTEM_MODE];
        Assert.areEqual('Updated description', customHistory[0].New_Value__c);
    }

    @isTest
	static void testConstructors() {
        Highlight_Interaction__c highlights = [SELECT Id FROM Highlight_Interaction__c 
                                               WHERE Name = 'September Highlights'
                                               WITH SYSTEM_MODE];
        Interaction_Participant__c participant = [SELECT Id, Description__c FROM Interaction_Participant__c 
                                                  WHERE Highlight__c = :highlights.Id 
                                                  WITH SYSTEM_MODE];

        Test.startTest();
            Map<Id, Interaction_Participant__c> participantMap = new Map<Id, Interaction_Participant__c>{
                participant.Id => participant
            };

            InteractionParticipantTriggerHandler twoArgHandler = new InteractionParticipantTriggerHandler(
                new List<Interaction_Participant__c>{ participant },
                new List<Interaction_Participant__c>{ participant }
            );
            InteractionParticipantTriggerHandler fourArgHandler = new InteractionParticipantTriggerHandler(
                new List<Interaction_Participant__c>{ participant },
                new List<Interaction_Participant__c>{ participant },
                participantMap,
                participantMap
            );
        Test.stopTest();
        Assert.isNotNull(twoArgHandler);
        Assert.isNotNull(fourArgHandler);
    }

    @isTest
	static void testInteractionDescriptionSyncedFromParticipant() {
        Highlight_Interaction__c highlight = [SELECT Id FROM Highlight_Interaction__c WITH SYSTEM_MODE LIMIT 1];
        Interaction_Participant__c participant = [SELECT Id, Description__c, Interaction__c
                                                  FROM Interaction_Participant__c
                                                  WHERE Highlight__c = :highlight.Id
                                                  WITH SYSTEM_MODE LIMIT 1];
        Contact mayor = TestDataFactory.createMayorContact();
        TestDataFactory.createInteraction(mayor.Id, 'Participant Interaction', 'Arts', null);
        Interaction__c interaction = [SELECT Id, Description__c FROM Interaction__c
                                      WHERE Name = 'Participant Interaction'
                                      WITH SYSTEM_MODE LIMIT 1];

        participant.Interaction__c = interaction.Id;
        update as system participant;

        Test.startTest();
            participant.Description__c = 'Participant updated description';
            update as system participant;
        Test.stopTest();

        Interaction__c updatedInteraction = [SELECT Description__c FROM Interaction__c
                                             WHERE Id = :interaction.Id
                                             WITH SYSTEM_MODE];
        Assert.areEqual(
            'Participant updated description',
            updatedInteraction.Description__c,
            'Interaction description should sync from the participant description'
        );
    }

    @isTest
	static void testInteractionDescriptionNotSyncedWithoutInteractionLink() {
        Highlight_Interaction__c highlight = [SELECT Id FROM Highlight_Interaction__c WITH SYSTEM_MODE LIMIT 1];
        Interaction_Participant__c participant = [SELECT Id, Description__c, Interaction__c
                                                  FROM Interaction_Participant__c
                                                  WHERE Highlight__c = :highlight.Id
                                                  WITH SYSTEM_MODE LIMIT 1];
        Contact mayor = TestDataFactory.createMayorContact();
        TestDataFactory.createInteraction(mayor.Id, 'Unlinked Interaction', 'Arts', null);
        Interaction__c interaction = [SELECT Id, Description__c FROM Interaction__c
                                      WHERE Name = 'Unlinked Interaction'
                                      WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
            participant.Description__c = 'Participant updated description';
            update as system participant;
        Test.stopTest();

        Interaction__c updatedInteraction = [SELECT Description__c FROM Interaction__c
                                             WHERE Id = :interaction.Id
                                             WITH SYSTEM_MODE];
        Assert.isNull(
            updatedInteraction.Description__c,
            'Interaction description should not change when the participant has no Interaction lookup'
        );
    }
}