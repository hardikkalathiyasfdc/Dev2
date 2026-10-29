import { LightningElement, api } from 'lwc';
import YEAR_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Year__c';
import REGION_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Region__c';
import POPULATION_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Population__c';
import POPULATION_MINORITY_MAJAORITY_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Population_Minority_is_Majority__c';
import POPULATION_NON_HISPANIC_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Population_Non_Hispanic_white__c';
import POPULATION_CENSUS_DATA_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Population_Census_Data_As_of__c';
import ORGANIZATION_ANNUAL_ATTENDANCE_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Organization_Annual_Attendance__c';
import NUMBER_OF_ORGANIATION_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Number_of_Organization_Memberships__c';
import ANNUAL_WEBSITE_VISITS_FIELD from '@salesforce/schema/Organization_Annual_Metrics__c.Annual_Website_Visits__c';
import getLatestRecord from '@salesforce/apex/OrganizationAnnualMetricsController.getLatestRecord';

export default class OrganizationAnnualMetrics extends LightningElement {
    @api recordId;
    objectApiName = 'Organization_Annual_Metrics__c';
    organizationAnnualMetrics;
    yearField = YEAR_FIELD;
    regionField = REGION_FIELD;
    populationField = POPULATION_FIELD;
    populationMinorityMajorityField = POPULATION_MINORITY_MAJAORITY_FIELD;
    populationNonHispanicField = POPULATION_NON_HISPANIC_FIELD;
    populationCensusDataField = POPULATION_CENSUS_DATA_FIELD;
    organizationAnnualAttendanceField = ORGANIZATION_ANNUAL_ATTENDANCE_FIELD;
    numberOfOrganizationField = NUMBER_OF_ORGANIATION_FIELD;
    annualWebsiteVisitsField = ANNUAL_WEBSITE_VISITS_FIELD;

    connectedCallback() {
        getLatestRecord({'organizationId' : this.recordId}).then(result=>{ 
            this.organizationAnnualMetrics = result;
        });
    }
}