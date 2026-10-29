/**
* Author : Paddy
* Date   : 04/12/2024
* Jira   : BRME-4575
* Description : This class is the controller class for organizationAnnualMetrics LWC.
* Test : OrganizationAnnualMetricsHandlerTest
*/
public with sharing class OrganizationAnnualMetricsController {
    @AuraEnabled
    public static Organization_Annual_Metrics__c getLatestRecord(String organizationId) {
        List<Organization_Annual_Metrics__c> oams = new List<Organization_Annual_Metrics__c>([SELECT Id,
            Annual_Website_Visits__c, Number_of_Organization_Memberships__c, Organization__c,
            Organization_Annual_Attendance__c, Population__c, Population_Census_Data_As_of__c,
            Population_Minority_is_Majority__c, Population_Non_Hispanic_white__c, Region__c,
            Year__c FROM Organization_Annual_Metrics__c WHERE Organization__c = :organizationId
            ORDER BY Year_Numeric__c DESC]);
        if(!oams.isEmpty()) {
            return oams[0];
        }
        return null;	
    }
}