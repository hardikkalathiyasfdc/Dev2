@isTest
public class FoundationCodeHandlerTest {

    @testSetup static void setup() {

        TestDataFactory.createInitiativeBaseData();

        Foundation_Code__c artsFoundationCode = [SELECT Id FROM Foundation_Code__c WHERE Name = 'Arts' with SYSTEM_MODE limit 1];
        Focus_Area__c artsFocusArea = [SELECT Id FROM Focus_Area__c WHERE Name = 'Arts' with SYSTEM_MODE limit 1];
        Team__c artsTeam = [SELECT Id FROM Team__c WHERE Name = 'Arts' with SYSTEM_MODE limit 1];

        IM_Initiative__c focusAreaInitiative = new IM_Initiative__c(
        	Name = 'Focus Area Test Initiative',
        	Initiative_Type__c = 'Non Budgeted',
        	Status__c = 'Draft',
        	Focus_Area__c = artsFocusArea.Id,
            Team__c = artsTeam.Id,
        	Start_Date__c = System.today(),
        	End_Date__c = System.today().addMonths(36),
        	RecordTypeID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
                                .get(Assets.FOCUS_AREA_MISC_TYPE)
                                .getRecordTypeId()
        );
        insert focusAreaInitiative;

        Foundation_Code__c artsChildFC = TestDataFactory.buildFoundationCode('Arts', 'Focus Area Misc', artsFoundationCode.Id, null);
        artsChildFC.Initiative__C = focusAreaInitiative.Id;
        insert artsChildFC;
    }

    @isTest
    static void testStatusChange() {
        Foundation_Code__c rootFoundationCode = [SELECT Name FROM Foundation_Code__c WHERE Name = 'Initiatives' with SYSTEM_MODE];
        Foundation_Code__c artsChildFC1 = [SELECT Id, Name, Status__c FROM Foundation_Code__c WHERE Name = 'Arts' AND Parent__c != :rootFoundationCode.Id with SYSTEM_MODE];

        Test.startTest();
            artsChildFC1.Status__c = Assets.RETIRED;
        	update artsChildFC1;
        	Foundation_Code__c updatedFoundationCode = [SELECT Id, Name, Status__c FROM Foundation_Code__c WHERE Id = :artsChildFC1.Id with SYSTEM_MODE];
        	Assert.areEqual('Arts (retired)', updatedFoundationCode.Name);
        Test.stopTest();
    }

    @isTest
    static void testParentChange() {
        Foundation_Code__c initiativeFoundationCode = [SELECT Name FROM Foundation_Code__c WHERE Name = 'Initiatives' with SYSTEM_MODE];
        Foundation_Code__c artsChildFC1 = [SELECT Id, Name, Status__c, Full_Path__c FROM Foundation_Code__c WHERE Foundation_Code__c = 'Arts' AND Parent__c != :initiativeFoundationCode.Id with SYSTEM_MODE];
        Foundation_Code__c parentFC = [SELECT Id, Status__c FROM Foundation_Code__c WHERE Name = 'Government Innovation' with SYSTEM_MODE];
        Test.startTest();
            artsChildFC1.Parent__c = parentFC.Id;
        	update artsChildFC1;
        	Foundation_Code__c updatedFoundationCode = [SELECT Id, Name, Parent__c, Level_1__c, Full_Path__c, Status__c FROM Foundation_Code__c WHERE Id = :artsChildFC1.Id with SYSTEM_MODE];
        	Assert.areEqual(parentFC.Id, updatedFoundationCode.Parent__c);
        Test.stopTest();
    }

    @isTest
    static void testFoundationCodeNameChange() {
        Foundation_Code__c rootFoundationCode = [SELECT Name FROM Foundation_Code__c WHERE Name = 'Initiatives' with SYSTEM_MODE];
        Foundation_Code__c artsChildFC1 = [SELECT Id, Name, Status__c, Foundation_Code__c FROM Foundation_Code__c WHERE Name = 'Arts' AND Parent__c != :rootFoundationCode.Id with SYSTEM_MODE];

        Test.startTest();
        	artsChildFC1.Foundation_Code__c = 'Arts Renamed';
        	update artsChildFC1;
        	Foundation_Code__c updatedFC = [SELECT Name, Initiative__r.Name FROM Foundation_Code__c WHERE Id = :artsChildFC1.Id with SYSTEM_MODE];
        	Assert.areEqual(updatedFC.Name, updatedFC.Initiative__r.Name);
        Test.stopTest();
    }


    @isTest
    static void testFoundationCodeCreateEmailNotification() {
        Test.startTest();
        	TestDataFactory.createParentInitiatives('Test Parent');
        	Assert.isTrue(Limits.getEmailInvocations() > 0, 'Notification email should have been sent.');
        Test.stopTest();
    }

    @isTest
    static void testFoundationCodeUpdateEmailNotification() {
        IM_Initiative__c parentInitiative = TestDataFactory.createParentInitiatives('Test Parent');
        parentInitiative.Name = parentInitiative.Name + ' Rename';
        Test.startTest();
            update parentInitiative;
        	Assert.isTrue(Limits.getEmailInvocations() > 0, 'Notification email should have been sent.');
        Test.stopTest();
    }
}