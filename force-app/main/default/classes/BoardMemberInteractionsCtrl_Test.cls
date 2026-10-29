@isTest
private class BoardMemberInteractionsCtrl_Test {

    @testSetup
    static void dataPrep() {
        Account acc = new Account(Name='Test');
        insert acc;

        Contact cnt = new Contact(AccountId=acc.Id, FirstName='Test', LastName='Test', Preferred_First_Name__c= 'test');
        Contact cnt1 = new Contact(AccountId=acc.Id, FirstName='Test1', LastName='Test1', Preferred_First_Name__c= 'test1');
        Contact cnt2 = new Contact(AccountId=acc.Id, FirstName='Test2', LastName='Test2', Preferred_First_Name__c= 'test2');
        insert new List<Contact>{cnt, cnt1, cnt2};

        cnt.BP_Board_Member_Former_Board_Member__c = 'Board Member';
        cnt1.BP_Board_Member_Former_Board_Member__c = 'Board Member';
        cnt2.BP_Board_Member_Former_Board_Member__c = 'Board Member';
        update new List<Contact>{cnt, cnt1, cnt2};

        Interaction__c interaction = new Interaction__c();
        interaction.Contact__c = cnt.Id;
        interaction.Interaction_Date__c = Date.today().addMonths(-1).toStartofMonth().addDays(3);
        interaction.Name = 'interaction 0';
        interaction.Teams__c = TestDataFactory.createTeam('Arts').Id;
        //interaction.Description__c = 'test description';

        Interaction__c interaction1 = new Interaction__c();
        interaction1.Contact__c = cnt.Id;
        interaction1.Interaction_Date__c = Date.today().addMonths(-1).toStartofMonth().addDays(4);
        interaction1.Name = 'interaction 1';
        interaction1.Teams__c = TestDataFactory.createTeam('Arts').Id;
        //interaction1.Background__c = 'test background';

        Interaction__c interaction2 = new Interaction__c();
        interaction2.Contact__c = cnt1.Id;
        interaction2.Interaction_Date__c = Date.today().addMonths(-1).toStartofMonth().addDays(2);
        interaction2.Name = 'interaction 2';
        interaction2.Teams__c = TestDataFactory.createTeam('Arts').Id;

        Interaction__c interaction4 = new Interaction__c();
        interaction4.Name = 'interaction 4';
        interaction4.Contact__c = cnt1.Id;
        interaction4.Background__c = 'test background';
        interaction4.Interaction_Date__c = Date.today().addMonths(-1).toStartofMonth().addDays(4);
        interaction4.Teams__c = TestDataFactory.createTeam('Arts').Id;

        insert new List<Interaction__c>{interaction, interaction1, interaction4, interaction2};
    }

    @isTest
    static void testControllerMethod() {
        Test.startTest();
        BoardMemberInteractionsCtrl ctrl = new BoardMemberInteractionsCtrl();

        ApexPages.currentPage().getParameters().put('last', 'y');
        BoardMemberInteractionsCtrl ctrl1 = new BoardMemberInteractionsCtrl();

        ApexPages.currentPage().getParameters().put('committee', 'ac');
        BoardMemberInteractionsCtrl ctrl2 = new BoardMemberInteractionsCtrl();

        ApexPages.currentPage().getParameters().put('committee', 'pc');
        BoardMemberInteractionsCtrl ctrl3 = new BoardMemberInteractionsCtrl();

        ApexPages.currentPage().getParameters().put('committee', 'ic');
        BoardMemberInteractionsCtrl ctrl4 = new BoardMemberInteractionsCtrl();
        Test.stopTest();

        System.debug(ctrl.interactions.size() > 0 );
    }
}