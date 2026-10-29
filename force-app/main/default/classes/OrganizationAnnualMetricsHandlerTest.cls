@isTest
public class OrganizationAnnualMetricsHandlerTest {

    @testSetup static void setup() {
        Account organization = TestDataFactory.createOrg('Metrics Inc');
        Organization_Annual_Metrics__c oam = TestDataFactory.createOrganizationAnnualMetrics('2022');
        oam.Organization__c = organization.Id;
        Organization_Annual_Metrics__c oam1 = TestDataFactory.createOrganizationAnnualMetrics('2023');
        oam1.Number_of_Organization_Memberships__c = 88;
        oam1.Organization__c = organization.Id;
        List<Organization_Annual_Metrics__c> oams = new List<Organization_Annual_Metrics__c>{oam, oam1};
        insert oams;
    }

    @isTest
    static void testOrgDataPopulation() {
        Account organization = [SELECT Id FROM Account WHERE Name = 'Metrics Inc' with SYSTEM_MODE limit 1];

        Organization_Annual_Metrics__c oam = [
            SELECT Id, Annual_Website_Visits__c, Number_of_Organization_Memberships__c, Region__c, Year__c,
                   Organization__c, Organization_Annual_Attendance__c, Population__c, Population_Census_Data_As_of__c
            FROM Organization_Annual_Metrics__c
            WHERE Organization__c = :organization.Id AND
                  Year__c = '2022'];

        Test.startTest();
            oam.Year__c = '2024';
            update oam;
            Account organizationAfterUpdate = [
                SELECT Id, Annual_Website_Visits__c, Number_of_Organization_Memberships__c,
                       Organization_Annual_Attendance__c, Population__c, Asof__c, Region__c
                FROM Account
                WHERE Name = 'Metrics Inc' with SYSTEM_MODE limit 1];
            Assert.areEqual(organizationAfterUpdate.Annual_Website_Visits__c, oam.Annual_Website_Visits__c);
        Test.stopTest();
    }

    @isTest
    static void testForControllerClass() {
        Account organization = [SELECT Id FROM Account WHERE Name = 'Metrics Inc' with SYSTEM_MODE limit 1];

        Organization_Annual_Metrics__c oam = [
            SELECT Id, Annual_Website_Visits__c, Number_of_Organization_Memberships__c, Region__c, Year__c,
                   Organization__c, Organization_Annual_Attendance__c, Population__c, Population_Census_Data_As_of__c
            FROM Organization_Annual_Metrics__c
            WHERE Organization__c = :organization.Id AND
                  Year__c = '2023' with SYSTEM_MODE];

        Test.startTest();
            Organization_Annual_Metrics__c oamRecord = OrganizationAnnualMetricsController.getLatestRecord(organization.Id);
            Assert.areEqual(oam.Number_of_Organization_Memberships__c, oamRecord.Number_of_Organization_Memberships__c);
        Test.stopTest();
    }
}