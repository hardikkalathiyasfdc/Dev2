/**
* Author : Paddy
* Date   : 04/12/2024
* Jira   : BRME-4575
* Description : This class is the handler class for Organization Annual Metrics trigger.
* Test : OrganizationAnnualMetricsHandlerTest
*/
public with sharing class OrganizationAnnualMetricsHandler extends TriggerHandler {
    private static final String ERR_BULK_BEFORE= 'ORGANIZATION_ANNUAL_METRICS_HANDLER_BULK_BEFORE_FAILED'; 
    private static final String ERR_BULK_AFTER= 'ORGANIZATION_ANNUAL_METRICS_HANDLER_BULK_AFTER_FAILED'; 
    private static final String ERR_POPULATE_ORGANIZATION_DATA= 'ORGANIZATION_ANNUAL_METRICS_HANDLER_POPULATE_ORGANIZATION_DATA_FAILED';
    
    public List<Organization_Annual_Metrics__c> newOrganizationAnnualMetrics;
    public List<Organization_Annual_Metrics__c> oldOrganizationAnnualMetrics;
    public Map<Id,Organization_Annual_Metrics__c> oldMap;
    public Map<Id,Organization_Annual_Metrics__c> newMap;
    
    private static final String DUPLICATE_ERROR_MESSAGE = 'Organization Annual Metrics already exists for the selected year.';
    
    public OrganizationAnnualMetricsHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Organization_Annual_Metrics__c>) Trigger.oldMap, (Map<Id, Organization_Annual_Metrics__c>) Trigger.newMap);
    }
    
    public OrganizationAnnualMetricsHandler(List<Organization_Annual_Metrics__c> oldOrganizationAnnualMetrics, List<Organization_Annual_Metrics__c> newOrganizationAnnualMetrics) {
        this.newOrganizationAnnualMetrics = newOrganizationAnnualMetrics;
        this.oldOrganizationAnnualMetrics = oldOrganizationAnnualMetrics;
    }
    
    public OrganizationAnnualMetricsHandler(List<Organization_Annual_Metrics__c> oldOrganizationAnnualMetrics, List<Organization_Annual_Metrics__c> newOrganizationAnnualMetrics , Map<Id,Organization_Annual_Metrics__c> oldMap , Map<Id,Organization_Annual_Metrics__c> newMap){
        this.newOrganizationAnnualMetrics = newOrganizationAnnualMetrics;
        this.oldOrganizationAnnualMetrics = oldOrganizationAnnualMetrics;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    
    public override void bulkBefore() {
        try{ 
            if(Trigger.isInsert || Trigger.isUpdate) {
                Set<Id> orgIds = new Set<Id>();
                for (Organization_Annual_Metrics__c oam : newOrganizationAnnualMetrics) {
                    if(Trigger.isInsert) {
                        orgIds.add(oam.Organization__c);
                    } else if(Trigger.isUpdate && isFieldChanged(oam, Assets.YEAR)) {
                        orgIds.add(oam.Organization__c);
                    }
                    
                }
                if(!orgIds.isEmpty()) {
                    duplicateRecordCheck(orgIds);
                }
            }
            
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_BEFORE));
        } 
    }
    
    public override void bulkAfter() {
        try{
            if(Trigger.isInsert || Trigger.isUpdate) {
                Set<Id> orgIds = new Set<Id>();
                for (Organization_Annual_Metrics__c oam : newOrganizationAnnualMetrics) {
                    if(Trigger.isInsert) {
                        orgIds.add(oam.Organization__c);
                    } else if(Trigger.isUpdate && (isFieldChanged(oam, Assets.YEAR)
                                                   || isFieldChanged(oam, Assets.ANNUAL_WEBSITE_VISITS) || isFieldChanged(oam, Assets.NUMBER_OF_ORGANIATION)
                                                   || isFieldChanged(oam, Assets.ORGANIZATION_ANNUAL_ATTENDANCE) || isFieldChanged(oam, Assets.POPULATION)
                                                   || isFieldChanged(oam, Assets.POPULATION_CENSUS_DATA) || isFieldChanged(oam, Assets.POPULATION_MINORITY_MAJAORITY)
                                                   || isFieldChanged(oam, Assets.POPULATION_NON_HISPANIC) || isFieldChanged(oam, Assets.REGION))) {
                                                       orgIds.add(oam.Organization__c);
                                                   }
                }
                if(!orgIds.isEmpty()) {
                    populateOrganizationData(orgIds);
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_AFTER));
        }  
    }
    
    private void duplicateRecordCheck(Set<Id> orgIds) {
        Map<Id, Map<Integer, Organization_Annual_Metrics__c>> recordsByOrdIds = getOAMByOrdIds(orgIds);
        for (Organization_Annual_Metrics__c oam : newOrganizationAnnualMetrics) {
            if(recordsByOrdIds.containsKey(oam.Organization__c)) {
                Map<Integer, Organization_Annual_Metrics__c> oamRecords = recordsByOrdIds.get(oam.Organization__c);
                if(oamRecords.containsKey(Integer.valueOf(oam.Year_Numeric__c))) {
                    oam.addError(DUPLICATE_ERROR_MESSAGE);
                }
            }
        }
    }
    
    private void populateOrganizationData(Set<Id> orgIds) {
        try{
            Map<Id, Account> orgsById = new Map<Id, Account>([
                SELECT Id, Annual_Website_Visits__c, Number_of_Organization_Memberships__c,
                Organization_Annual_Attendance__c, Population__c, Asof__c, Region__c 
                FROM Account 
                WHERE Id IN :orgIds]);
            Map<Id, Map<Integer, Organization_Annual_Metrics__c>> recordsByOrdIds = getOAMByOrdIds(orgIds);
            Integer currentYear = Date.today().year();
            List<Account> updatableOrgs = new List<Account>();
            for (Organization_Annual_Metrics__c oam : newOrganizationAnnualMetrics) {
                if(oam.Year__c != null && oam.Year__c.equalsIgnoreCase(String.valueOf(currentYear))) {
                    Account tempOrg = orgsById.get(oam.Organization__c);
                    updateOrganizationData(tempOrg, oam);
                    updatableOrgs.add(tempOrg);
                } else {
                    if(recordsByOrdIds.containsKey(oam.Organization__c)) {
                        Map<Integer, Organization_Annual_Metrics__c> oamRecords = recordsByOrdIds.get(oam.Organization__c);
                        List<Integer> yearValues = new List<Integer>(oamRecords.keySet());
                        yearValues.sort();
                        Account tempOrg = orgsById.get(oam.Organization__c);
                        updateOrganizationData(tempOrg, oamRecords.get(yearValues.get(yearValues.size() - 1)));
                        if(!updatableOrgs.contains(tempOrg)) {
                            updatableOrgs.add(tempOrg);
                        }
                    }
                }
            }
            if(!updatableOrgs.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(updatableOrgs, false, new BBApps_ErrorCustomFields(ERR_POPULATE_ORGANIZATION_DATA));
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_POPULATE_ORGANIZATION_DATA));
        }
    }
    
    private void updateOrganizationData(Account organization, Organization_Annual_Metrics__c oam) {
        organization.Annual_Website_Visits__c = oam.Annual_Website_Visits__c;
        organization.Number_of_Organization_Memberships__c = oam.Number_of_Organization_Memberships__c;
        organization.Organization_Annual_Attendance__c = oam.Organization_Annual_Attendance__c;
        organization.Population__c = oam.Population__c;
        organization.Asof__c = oam.Population_Census_Data_As_of__c;
        organization.Region__c = oam.Region__c;
    }
    
    private Map<Id, Map<Integer, Organization_Annual_Metrics__c>> getOAMByOrdIds(Set<Id> orgIds) {
        Map<Id, Map<Integer, Organization_Annual_Metrics__c>> recordsByOrdIds = new Map<Id, Map<Integer, Organization_Annual_Metrics__c>>();
        
        for(Organization_Annual_Metrics__c oam : [SELECT Id, Year_Numeric__c, Year__c, Organization__c, 
                                                  Annual_Website_Visits__c, Number_of_Organization_Memberships__c, Organization_Annual_Attendance__c,
                                                  Population__c, Population_Census_Data_As_of__c, Population_Minority_is_Majority__c,
                                                  Population_Non_Hispanic_white__c, Region__c FROM Organization_Annual_Metrics__c
                                                  WHERE Organization__c IN :orgIds order by Year_Numeric__c DESC]) {
                                                      
                                                      Map<Integer, Organization_Annual_Metrics__c> tempOAM = recordsByOrdIds.containsKey(oam.Organization__c) ? 
                                                          recordsByOrdIds.get(oam.Organization__c) : new Map<Integer, Organization_Annual_Metrics__c>();
                                                      tempOAM.put(Integer.valueOf(oam.Year_Numeric__c), oam);
                                                      recordsByOrdIds.put(oam.Organization__c, tempOAM);
                                                  }
        return recordsByOrdIds;
    }
}