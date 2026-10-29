@isTest
public with sharing class InteractionTriggerHandler_Test {

   public class applicationException extends Exception {}

   @isTest static void testContactIsListMember(){
       // Create Data
       Campaign campaignWithMembers = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, true)[0];
       Account a= TestDataFactory.createOrg('Test Account');
       List<Contact> contacts = TestDataFactory.createMultipleContacts(a.Id, 1, true);
       List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(campaignWithMembers,contacts, true);

       //Create Interaction
       RecordType touchpointRecType = [Select Id, Name from Recordtype where DeveloperName='Touchpoint' WITH SYSTEM_MODE];
       Interaction__c interaction =  new Interaction__c();
       interaction.Name = 'Test interaction';
       interaction.RecordTypeId = touchpointRecType.Id;
       interaction.List__c = campaignWithMembers.Id;
       interaction.Contact__c = contacts[0].Id;
    interaction.Teams__c  = TestDataFactory.createTeam('IT').Id;
       Database.insert(interaction);

       System.assertEquals(1, [SELECT count() FROM Interaction__c WHERE Name = 'Test interaction' WITH SYSTEM_MODE]);
   }

    @isTest static void testContactIsNotListMember(){
       // Create Data
        Campaign campaignWithMembers = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, true)[0];
        Account a= TestDataFactory.createOrg('Test Account');
        List<Contact> contacts = TestDataFactory.createMultipleContacts(a.Id, 1, true);
       RecordType touchpointRecType = [Select Id, Name from Recordtype where DeveloperName = 'Recent_Engagement' WITH SYSTEM_MODE];
       //Create Interaction
       Interaction__c interaction =  new Interaction__c();
       interaction.RecordTypeId = touchpointRecType.Id;
       interaction.Name = 'Test interaction';
       interaction.List__c = campaignWithMembers.Id;
       interaction.Contact__c = contacts[0].Id;
        interaction.Teams__c  = TestDataFactory.createTeam('IT').Id;
        try {
            Database.insert(interaction);
            throw new applicationException('An exception should have been thrown by the trigger but was not.');
        } catch(Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Please add this contact to the selected List.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
   }

   @isTest static void testContactIsListMember_BeforeUpdate(){
       // Create Data
        Campaign campaignWithMembers = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, true)[0];
        Account a = TestDataFactory.createOrg('Test Account');
        List<Contact> contacts = TestDataFactory.createMultipleContacts(a.Id, 1, true);
        List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(campaignWithMembers,contacts, true);

       //Create Interaction without List
       Interaction__c interaction =  new Interaction__c();
       interaction.Name = 'Test interaction';
       interaction.Contact__c = contacts[0].Id;
        interaction.Teams__c  = TestDataFactory.createTeam('IT').Id;
       Database.insert(interaction);

        //Update an Interaction set the List
        interaction.List__c = campaignWithMembers.Id;
        Database.update(interaction);

        System.assertNotEquals(interaction.List__c, null);
       	delete interaction;
   }

    @isTest static void testSubmitToCityView(){
       Test.startTest();
           //Create Interaction

           Map<String,Focus_Area__c> focusAreas = TestDataFactory.createFocusAreas(new List<String>{'Education'});

           Foundation_Code__c rootCode = TestDataFactory.createRootFoundationCode();
           Foundation_Code__c code = TestDataFactory.buildFoundationCode('Education','Focus Area',rootCode.Id,focusAreas.get('Education').Id);
           insert code;
        Account a= TestDataFactory.createOrg('Test Account');
        List<Contact> contacts = TestDataFactory.createMultipleContacts(a.Id, 1, true);
           RecordType touchpointRecType = [Select Id, Name from Recordtype where DeveloperName='Touchpoint' WITH SYSTEM_MODE];
           Interaction__c interaction =  new Interaction__c();
           interaction.Name = 'Test interaction';
           interaction.RecordTypeId = touchpointRecType.Id;
           interaction.Contact__c = contacts[0].Id;
          interaction.Teams__c  = TestDataFactory.createTeam('IT').Id;
           interaction.Foundation_Coding__c = code.Id;
           interaction.Add_to_CityView__c   = true;
           Database.insert(interaction);
	   Test.stopTest();
       System.assertEquals(2, [SELECT count() FROM Interaction__c WHERE Name = 'Test interaction' WITH SYSTEM_MODE]);
   }

    @isTest static void testUpdateInteractionSubject() {
        Test.startTest();
        Account a = TestDataFactory.createOrg('Test Account');
        List<Contact> contacts = TestDataFactory.createMultipleContacts(a.Id, 1, true);
        RecordType touchpointRecType = [SELECT Id, Name FROM Recordtype WHERE DeveloperName = 'Touchpoint' WITH SYSTEM_MODE];
        Interaction__c interaction =  new Interaction__c();
        interaction.Name = 'Test interaction';
        interaction.RecordTypeId = touchpointRecType.Id;
        interaction.Contact__c = contacts[0].Id;
        interaction.Teams__c  = TestDataFactory.createTeam('IT').Id;
        interaction.Private_Interaction__c = true;
        Database.insert(interaction);
        Interaction__c updatedInteraction = [SELECT Name FROM Interaction__c WHERE Id = :interaction.Id WITH SYSTEM_MODE];
        Assert.areEqual('Test interaction (Private)', updatedInteraction.Name);
        interaction.Private_Interaction__c = false;
        Database.update(interaction);
        Interaction__c updatedInteraction1 = [SELECT Name FROM Interaction__c WHERE Id = :interaction.Id WITH SYSTEM_MODE];
        Assert.areEqual('Test interaction', updatedInteraction1.Name);
        Test.stopTest();
    }
}