/**
* Author      : Ravi
* Date        : 09/10/2026
* Jira        : BRME-6952
* Description : Test class for HighlightMetricsController.
*/
@IsTest
private class HighlightMetricsControllerTest { 

    @TestSetup
    static void setupTestData() {
        Team__c team = TestDataFactory.createTeam('Program Highlights Team');
        TestDataFactory.createMetric('People served', team.Id, 'Count', 1);
        TestDataFactory.createMetric('Volunteer hours', team.Id, 'Hours', 2);
        TestDataFactory.createHighlightInteraction(
            'Q1 Program Highlight', team, 'Test highlight description', 'Test leadership description');
    }

    private static Highlight_Interaction__c getHighlight() {
        return [SELECT Id, Team__c FROM Highlight_Interaction__c LIMIT 1];
    }

    private static Metric__c getMetricByOrder(Decimal orderNumber) {
        return [SELECT Id, Name FROM Metric__c WHERE Order__c = :orderNumber LIMIT 1];
    }

    @IsTest
    static void testGetMetricRowsReturnsTeamMetricsWhenNothingEntered() {
        Test.startTest();
        HighlightMetricsController.MetricsWrapper wrap =
            HighlightMetricsController.getMetricRows(getHighlight().Id);
        Test.stopTest();

        System.assertNotEquals(null, wrap);
        System.assertNotEquals(null, wrap.teamId);
        System.assertEquals(2, wrap.rows.size());
        for (HighlightMetricsController.MetricRow row : wrap.rows) {
            System.assertEquals(false, row.submitted);
            System.assertEquals(null, row.metricValueId);
            System.assertEquals(null, row.previousValue);
        }
    }

    @IsTest
    static void testGetMetricRowsSortsSubmittedFirstWithPreviousValue() {
        Highlight_Interaction__c highlight = getHighlight();
        Metric__c second = getMetricByOrder(2);
        TestDataFactory.createLatestMetricValue(second.Id, highlight.Id, 99.50, Date.today());

        Test.startTest();
        HighlightMetricsController.MetricsWrapper wrap =
            HighlightMetricsController.getMetricRows(highlight.Id);
        Test.stopTest();

        System.assertEquals(2, wrap.rows.size());
        System.assertEquals(second.Id, wrap.rows[0].metricId);
        System.assertEquals(true, wrap.rows[0].submitted);
        System.assertEquals(99.50, wrap.rows[0].value);
        System.assertEquals(true, wrap.rows[0].previousValue.contains('99.5 Hours as of'));
        System.assertEquals(false, wrap.rows[1].submitted);
    }

    @IsTest
    static void testSaveMetricValuesInsertsThenUpdates() {
        Highlight_Interaction__c highlight = getHighlight();
        Metric__c metric = getMetricByOrder(1);

        Test.startTest();
        HighlightMetricsController.saveMetricValues(
            new List<Metric_Value__c>{
                new Metric_Value__c(
                    Metric__c = metric.Id,
                    Highlight_Interaction__c = highlight.Id,
                    Value__c = 15,
                    Date__c = Date.today(),
                    Notes__c = 'Q1 total'
                )
            },
            new List<Id>()
        );

        Metric_Value__c inserted = [
            SELECT Id, Value__c, Notes__c FROM Metric_Value__c WHERE Metric__c = :metric.Id LIMIT 1
        ];
        inserted.Value__c = 25;

        HighlightMetricsController.saveMetricValues(
            new List<Metric_Value__c>{ inserted }, new List<Id>());
        Test.stopTest();

        List<Metric_Value__c> saved = [
            SELECT Value__c, Notes__c FROM Metric_Value__c WHERE Metric__c = :metric.Id
        ];
        System.assertEquals(1, saved.size());
        System.assertEquals(25, saved[0].Value__c);
        System.assertEquals('Q1 total', saved[0].Notes__c);
    }

    @IsTest
    static void testSaveMetricValuesRemovesAndIgnoresEmptyPayload() {
        Highlight_Interaction__c highlight = getHighlight();
        Metric__c metric = getMetricByOrder(1);
        Metric_Value__c existing =
            TestDataFactory.createMetricValue(metric.Id, highlight.Id, 10, Date.today());

        Test.startTest();
        HighlightMetricsController.saveMetricValues(
            new List<Metric_Value__c>(), new List<Id>{ existing.Id });
        HighlightMetricsController.saveMetricValues(new List<Metric_Value__c>(), new List<Id>());
        HighlightMetricsController.saveMetricValues(null, null);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Metric_Value__c]);
    }

    @IsTest
    static void errorHandlingLogicTest() {
        try {
            HighlightMetricsController.getMetricRows(null);
        } catch (Exception e) {
        }

        try {
            HighlightMetricsController.saveMetricValues(
                new List<Metric_Value__c>{ new Metric_Value__c() }, new List<Id>());
        } catch (Exception e) {
        }
    }
}