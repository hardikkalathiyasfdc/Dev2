/**
* @description Controller class that handles exporting Organization Highlights by retrieving
* Interaction__c records for selected organizations or organization lists using dynamic
* field sets, applying filters such as publish status and date range, validating record
* types, and packaging the results with headers and restricted organization indicators
* for UI or export consumption.
*/
public with sharing class ExportOrganizationHighlightsController {
    
    public static String ONLY_PUBLISHED_CITYVIEW = 'OnlyPublishedCityView';
    public static String ALL_ORG_LIST_FILENAME   = 'Organization_List_Name_Highlights';
    public static String ORGANIZATION_HIGHLIGHTS = 'Organization Highlights';
    
    private static final String ERR_GET_ORG_ORGANIZATIONHIGHLIGHTS_BY_ORGIDS = 'EXPORT_ORGANIZATION_HIGHLIGHT_CONTROLLER_GET_ORG_ORGANIZATIONHIGHLIGHTS_BY_ORGIDS_FAILED';
    private static final String ERR_GET_ORG_ORGANIZATIONHIGHLIGHTS = 'EXPORT_ORGANIZATION_HIGHLIGHT_CONTROLLER_GET_ORG_ORGANIZATIONHIGHLIGHTS_FAILED'; 
    private static final String ERR_VALIDATE_RECORDTYPES = 'EXPORT_ORGANIZATION_HIGHLIGHT_CONTROLLER_VALIDATE_RECORDTYPES_FAILED';
    @TestVisible
    private static Boolean forceException = false;
    
    public List<Campaign> selectedOrganizations;
    public Boolean exportFromList { get; set; }
    public String organizationIdsString { get; set; }
    public Boolean validOrganizationIds { get; set; }
    
    public ExportOrganizationHighlightsController(ApexPages.StandardSetController cntlr) {
        exportFromList = true;
        selectedOrganizations = cntlr.getSelected();
        organizationIdsString = '';
        
        Set<Id> orgIds = new Set<Id>();
        for (Campaign cmp : selectedOrganizations) {
            organizationIdsString += cmp.Id + ',';
            orgIds.add(cmp.Id);
        }
        
        if (String.isNotBlank(organizationIdsString)) {
            organizationIdsString = organizationIdsString.removeEnd(',');
        }
        
        validateRecordTypes(orgIds);
    }
    
    public class OrganizationHighlightWrapper {
        @AuraEnabled
        public String name { get; set; }
        
        @AuraEnabled
        public Map<String, String> headers { get; set; }
        
        @AuraEnabled
        public List<Interaction__c> interactions { get; set; }
        
        @AuraEnabled
        public Boolean hasRestrictedOrgs { get; set; }
        
        @AuraEnabled
        public Integer restrictedOrgCount { get; set; }
        
        public OrganizationHighlightWrapper() {
        }
        
        public OrganizationHighlightWrapper(
            Map<String, String> headers,
            List<Interaction__c> interactions
        ) {
            this.headers = headers;
            this.interactions = interactions;
            this.hasRestrictedOrgs = false;
            this.restrictedOrgCount = 0;
        }
        
        public OrganizationHighlightWrapper(
            Map<String, String> headers,
            List<Interaction__c> interactions,
            String name
        ) {
            this.headers = headers;
            this.interactions = interactions;
            this.name = name;
            this.hasRestrictedOrgs = false;
            this.restrictedOrgCount = 0;
        }
    }
    
    public static OrganizationHighlightWrapper getOrganizationHighlightsByOrgIds(
        Set<String> organizationIds,
        String exportType,
        Date fromDate,
        Date toDate
    ) {
        try{
            System.debug('@@fromDate=' + fromDate + '@@toDate=' + toDate);
            
            Map<String, String> headers = new Map<String, String>();
            List<Interaction__c> interactions = new List<Interaction__c>();
            
            String soql = 'SELECT Id';
            
            for (Schema.FieldSetMember field :
                 SObjectType.Interaction__c.FieldSets.Export_Organization_Highlights.getFields()) {
                     soql += ', ' + field.getFieldPath();
                     headers.put(field.getFieldPath(), field.getLabel());
                 }
            
            soql +=
                ' FROM Interaction__c ' +
                'WHERE Organization__c IN :organizationIds ' +
                'AND RecordType.Name = \'Organization Highlight/CityView\'';
            
            if (ONLY_PUBLISHED_CITYVIEW.equalsIgnoreCase(exportType)) {
                soql += ' AND CityView_Review_Status__c = \'Publish to CityView\'';
            }
            
            if (fromDate != null && toDate != null) {
                soql += ' AND Interaction_Date__c >= :fromDate ' +
                    'AND Interaction_Date__c <= :toDate';
            }
            
            soql += ' ORDER BY Organization_Name__c, Interaction_Date__c DESC';
            
            System.debug('######getOrganizationHighlights-soql: ' + soql);
            
            interactions = Database.query(soql);
            
            List<Account> restrictedOrgs = [
                SELECT Id
                FROM Account
                WHERE Id IN :organizationIds
                AND Restricted__c = true
            ];
            
            OrganizationHighlightWrapper organizationHighlightWrapper =
                new OrganizationHighlightWrapper(headers, interactions);
            
            if (!restrictedOrgs.isEmpty()) {
                organizationHighlightWrapper.hasRestrictedOrgs = true;
                organizationHighlightWrapper.restrictedOrgCount = restrictedOrgs.size();
            }
            
            return organizationHighlightWrapper;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_ORG_ORGANIZATIONHIGHLIGHTS_BY_ORGIDS) ); 
            return null;
        }
    }
    
    @AuraEnabled
    public static OrganizationHighlightWrapper getOrganizationHighlights(
        String organizationId,
        String exportType,
        Date fromDate,
        Date toDate
    ) {
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Account organization = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :organizationId
            ];
            
            String name = organization.Name;
            Set<String> orgIds = new Set<String>{ organizationId };
                
                OrganizationHighlightWrapper organizationHighlightWrapper =
                getOrganizationHighlightsByOrgIds(orgIds, exportType, fromDate, toDate);
            
            organizationHighlightWrapper.name =
                ORGANIZATION_HIGHLIGHTS + '_' + name;
            
            return organizationHighlightWrapper;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_ORG_ORGANIZATIONHIGHLIGHTS) ); 
            return null;
        }
    }
    
    @AuraEnabled
    public static OrganizationHighlightWrapper getAllOrganizationHighlights(
        String exportType,
        String organizationIds,
        Date fromDate,
        Date toDate
    ) {
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<String> campaignIds = organizationIds.split(',');
            
            List<ListOrganization__c> listOrgs = [
                SELECT Id, Organization__c
                FROM ListOrganization__c
                WHERE List__c IN :campaignIds
                AND List__r.RecordType.Name = 'Organization List'
            ];
            
            Set<String> orgIds = new Set<String>();
            for (ListOrganization__c listOrg : listOrgs) {
                orgIds.add(listOrg.Organization__c);
            }
            
            OrganizationHighlightWrapper organizationHighlightWrapper =
                getOrganizationHighlightsByOrgIds(orgIds, exportType, fromDate, toDate);
            
            organizationHighlightWrapper.name = ORGANIZATION_HIGHLIGHTS;
            
            return organizationHighlightWrapper;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_ORG_ORGANIZATIONHIGHLIGHTS) ); 
            return null;
        }
    }
    
    public void validateRecordTypes(Set<Id> orgIds) {
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Set<Id> organizationList = new Set<Id>();
            
            List<Campaign> orgLists = [
                SELECT Id, Name, RecordType.Name
                FROM Campaign
                WHERE Id IN :orgIds
            ];
            
            for (Campaign org : orgLists) {
                if ('Organization List'.equalsIgnoreCase(org.RecordType.Name)) {
                    organizationList.add(org.Id);
                }
            }
            
            validOrganizationIds = (orgIds.size() == organizationList.size());
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_VALIDATE_RECORDTYPES) ); 
        }
    }
}