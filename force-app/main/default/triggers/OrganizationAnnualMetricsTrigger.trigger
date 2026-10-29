/**
* Author : Paddy
* Date   : 04/12/2024
* Jira   : BRME-4575
* Description : Trigger for Organization Annual Metrics object.
* Test : OrganizationAnnualMetricsHandlerTest
*/
trigger OrganizationAnnualMetricsTrigger on Organization_Annual_Metrics__c (after update, before update, before insert, after insert) {
    TriggerFactory.createAndExecuteHandler( OrganizationAnnualMetricsHandler.class);
}