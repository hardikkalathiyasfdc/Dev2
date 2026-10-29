@isTest
private class MetricValueTriggerHandlerTest {

	@TestSetup
	static void setupData() {
		Team__c artsTeam = TestDataFactory.createTeam('Arts');
		TestDataFactory.createHighlightInteraction('September Highlights', artsTeam, 'Highlight description text', 'Leadership highlight description');
		TestDataFactory.createMetric('People Served', artsTeam.Id, 'Participants', 1);
	}

	private static Highlight_Interaction__c getHighlight() {
		return [SELECT Id FROM Highlight_Interaction__c WITH SYSTEM_MODE LIMIT 1];
	}

	private static Metric__c getMetric() {
		return [SELECT Id FROM Metric__c WITH SYSTEM_MODE LIMIT 1];
	}

	private static Boolean hasTrackedFields() {
		return ![
			SELECT Id
			FROM History_Setting__mdt
			WHERE Object__c = 'Metric_Value__c' AND Field__c != null
		].isEmpty();
	}

	private static Integer countHistory(Id recordId) {
		return [
			SELECT COUNT()
			FROM Custom_History__c
			WHERE Record_ID__c = :recordId
			WITH SYSTEM_MODE
		];
	}

	@isTest
	static void testTrackHistoryOnInsert() {
		Test.startTest();
			Metric_Value__c metricValue = TestDataFactory.createMetricValue(getMetric().Id, getHighlight().Id, 10, Date.today());
		Test.stopTest();

		Assert.isNotNull(metricValue.Id, 'Metric Value should be inserted');
	}

	@isTest
	static void testTrackHistoryOnUpdate() {
		Metric_Value__c metricValue = TestDataFactory.createMetricValue(getMetric().Id, getHighlight().Id, 10, Date.today());
		Integer historyBefore = countHistory(metricValue.Id);

		Test.startTest();
			metricValue.Value__c = 25;
			metricValue.Date__c = Date.today().addDays(1);
			metricValue.Notes__c = 'Updated notes';
			update as system metricValue;
		Test.stopTest();

		Metric_Value__c updatedValue = [
			SELECT Value__c, Notes__c
			FROM Metric_Value__c
			WHERE Id = :metricValue.Id
			WITH SYSTEM_MODE
		];
		Assert.areEqual(25, updatedValue.Value__c, 'Metric Value should be updated');
		Assert.areEqual('Updated notes', updatedValue.Notes__c, 'Notes should be updated');
	}

	@isTest
	static void testNoHistoryTrackedOnDelete() {
		Metric_Value__c metricValue = TestDataFactory.createMetricValue(getMetric().Id, getHighlight().Id, 10, Date.today());
		Integer historyBefore = countHistory(metricValue.Id);

		Test.startTest();
			delete as system metricValue;
		Test.stopTest();

		Assert.areEqual(0, [SELECT COUNT() FROM Metric_Value__c WHERE Id = :metricValue.Id WITH SYSTEM_MODE], 'Metric Value should be deleted');
		Assert.areEqual(historyBefore, countHistory(metricValue.Id), 'No history should be tracked on delete');
	}
}