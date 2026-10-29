@isTest
public class MayorAndCityViewInteractionCntrlTest {


    @TestSetup
    public static void makeData() {
        Contact c = TestDataFactory.createMayorContact();
        TestDataFactory.createInteraction(c.Id, 'Test Report 1 (Email)', 'Arts',null);
        TestDataFactory.createInteraction(c.Id,'Test Report (Email)', 'Arts',null);

        Account a = TestDataFactory.createCityViewOrg();
        TestDataFactory.createOrgInteraction(a.Id,'Test Report 1 (Email)', 'Arts','Publish to CityView');
        TestDataFactory.createOrgInteraction(a.Id, 'Test Report (Email)', 'Arts','Publish to CityView');
    }

    @isTest
    public static void testIfMayorInteractionsPresent() {

        Test.startTest();
        MayorAndCityViewInteractionCntrl cntlr = new MayorAndCityViewInteractionCntrl();
        Test.stopTest();

        System.assertEquals(cntlr.mayorInteractionsList.size(), 2, 'Two mayor interactions should exist');
        System.assertEquals(cntlr.mayorInteractionsList[0].interactionCountByTeam, 2, 'Two interactions for mayor should exist');
        System.assertEquals(cntlr.mayorInteractionsList[0].team, 'Arts', 'Interaction team should be Arts');
    }

    @isTest
    public static void testIfMayorInteractionsNotPresent() {
        delete [Select Id From Interaction__c with SYSTEM_MODE];
        Test.startTest();
        MayorAndCityViewInteractionCntrl cntlr = new MayorAndCityViewInteractionCntrl();
        Test.stopTest();

        System.assertEquals(cntlr.mayorInteractionsList.size(), 0, 'Mayor interactions should not exists');
        System.assertEquals(cntlr.isMayorInteractionsPresent, false, 'Mayor interactions should not exists');
    }

    @isTest
    public static void testIfCityViewInteractionsPresent() {

        Test.startTest();
        MayorAndCityViewInteractionCntrl cntlr = new MayorAndCityViewInteractionCntrl();
        Test.stopTest();

        System.assertEquals(cntlr.cityViewInteractionsList.size(), 2, 'Two mayor interactions should exist');
        System.assertEquals(cntlr.cityViewInteractionsList[0].interactionCountByTeam, 2, 'Two interactions for mayor should exist');
        System.assertEquals(cntlr.cityViewInteractionsList[0].team, 'Arts', 'Interaction team should be Arts');
    }

    @isTest
    public static void testIfCityViewInteractionsNotPresent() {
        delete [Select Id From Interaction__c Where CityView_Review_Status__c = 'Publish to CityView' with SYSTEM_MODE];
        Test.startTest();
        MayorAndCityViewInteractionCntrl cntlr = new MayorAndCityViewInteractionCntrl();
        Test.stopTest();

        System.assertEquals(cntlr.cityViewInteractionsList.size(), 0, 'Mayor interactions should not exists');
        System.assertEquals(cntlr.isCityViewInteractionsPresent, false, 'Mayor interactions should not exists');
    }

    @isTest
    public static void testSchedulerMayorAndCityViewReport() {
        Test.startTest();
        String CRON_EXP = '0 0 9 1 * ? *';
        String jobId = System.schedule('SchedulerMayorAndCityViewReport',CRON_EXP, new SchedulerMayorAndCityViewReport());
        CronTrigger ct = [Select Id, State, CronExpression, TimesTriggered, NextFireTime
                          From CronTrigger Where id = :jobId with SYSTEM_MODE];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Assert that the job is scheduled and not in an error state
        System.assertEquals('WAITING', ct.State);

        Test.stopTest();
    }

    @isTest
    static void testExecuteException() {

        SchedulerMayorAndCityViewReport.throwExceptionForTest = true;

        Test.startTest();

        SchedulerMayorAndCityViewReport job = new SchedulerMayorAndCityViewReport();
        job.execute(null);

        Test.stopTest();

    }
}