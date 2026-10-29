/**
* Author : Gauri Sagane
* Date   : 08/26/2026
* Jira   : BRME-6859
* Description : This class is used to create/update Org Associations when an initiative is approved or a strategic location is added
* Test : OrgAssociationComputationQueueableTest
*/

public with sharing class OrgAssociationComputationQueueable implements Queueable {

    private static final String INITIATIVE_ORG_ASSO_RECORD_TYPE_ID = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName()
		.get(Assets.INITIATIVE)
		.getRecordTypeId();
    private static final String ERR_COMPUTING_ORG_ASSOCIATIONS = 'COMPUTING_ORG_ASSOCIATIONS_FAILED';
    private Map<String, IM_Strategic_Locations__c> locationByOrgAssociation = new Map<String, IM_Strategic_Locations__c>();
    private Map<String, Org_Association__c> existingOrgAssociationMap = new Map<String, Org_Association__c>();
    private Map<Id, IM_Strategic_Locations__c> strategicLocations = new Map<Id, IM_Strategic_Locations__c>();
    private Map<Id, Id> organizationByGeoArea = new Map<Id, Id>();
    private Map<Id, Id> associationByInitiativeId = new Map<Id, Id>();
    private Map<String, Integer> locationCountMap = new Map<String, Integer>();
    private Map<String, Date> startDateMap = new Map<String, Date>();
    private Map<String, Date> endDateMap = new Map<String, Date>();
    private Map<Id, Id> associationsByInitiative = new Map<Id, Id>();

    public OrgAssociationComputationQueueable(Map<Id, IM_Strategic_Locations__c> strategicLocations, Map<Id, Id> associationsByInitiative) {
        this.strategicLocations = strategicLocations;
        this.associationsByInitiative = associationsByInitiative;
    }

    public void execute(QueueableContext context) {
        try{
            Set<Id> geoAreaIds = new Set<Id>();
            Set<Id> initiativeIds = new Set<Id>();
            
            for(IM_Strategic_Locations__c location : strategicLocations.values()){
                geoAreaIds.add(location.Geo_Area__c);
                initiativeIds.add(location.Initiative__c);
            }

            // Query the Initiatives related to the Strategic Locations
            List<IM_Initiative__c> initiatives = [SELECT Id, Approved__c, CityView_Initiative__c 
                                                    FROM IM_Initiative__c 
                                                    WHERE Id IN :initiativeIds 
                                                    WITH SYSTEM_MODE];

            // Query the Orgs related to the Strategic Locations (using the Geo Area on the strategic location)
            List<Account> orgs = [SELECT Id, Government_Geo_Area__c FROM Account 
                                    WHERE Government_Geo_Area__c IN : geoAreaIds 
                                    WITH SYSTEM_MODE];
            for(Account org : orgs) {
                if(org?.Government_Geo_Area__c != null){
                    organizationByGeoArea.put(org.Government_Geo_Area__c, org.Id);
                }
            }
            for(IM_Initiative__c initiative : initiatives) {
                if(initiative?.CityView_Initiative__c != null){
                    associationByInitiativeId.put(initiative.Id, initiative.CityView_Initiative__c);
                }
            }
            // Create a list of pairs that we need to process (a pair contains OrgId & AssociationId in the format 'orgId-associationId')
            for(IM_Strategic_Locations__c location : strategicLocations.values()){
                locationByOrgAssociation.put(organizationByGeoArea.get(location.Geo_Area__c)+'-'+associationByInitiativeId.get(location.Initiative__c), location);
                if(associationsByInitiative != null && !associationsByInitiative.isEmpty()){
                    locationByOrgAssociation.put(organizationByGeoArea.get(location.Geo_Area__c)+'-'+associationsByInitiative.get(location.Initiative__c), location);
                }
            }

            Set<Id> associationIds = new Set<Id>(associationByInitiativeId.values());
            if(associationsByInitiative != null && !associationsByInitiative.isEmpty()){
                associationIds.addAll(associationsByInitiative.values());
            }
            // Query the list of existing Org Associations in the system
            List<Org_Association__c> orgAssociationsExisting = [SELECT Id, Organization__c, Association__c, From__c, To__c, Deleted__c
                                                                FROM Org_Association__c 
                                                                WHERE Organization__c IN :organizationByGeoArea.values() AND Association__c IN :associationIds AND Deleted__c = false
                                                                WITH SYSTEM_MODE];
            for(Org_Association__c orgAssoExisting : orgAssociationsExisting) {
                existingOrgAssociationMap.put(orgAssoExisting.Organization__c+'-'+orgAssoExisting.Association__c, orgAssoExisting);
            }

            // Query the strategic locations in the system with these org and assoications (for Deletion purpose)
            List<AggregateResult> groupedResults = [SELECT Count(Id) locationCount, MIN(Start_Date__c) startDate, MAX(End_Date__c) endDate, Initiative__r.CityView_Initiative__c association, Geo_Area__c 
                                                    FROM IM_Strategic_Locations__c 
                                                    WHERE Geo_Area__c IN :geoAreaIds AND Initiative__r.CityView_Initiative__c IN :associationIds AND Deleted__c = false AND Initiative__r.Approved__c = true
                                                    WITH SYSTEM_MODE
                                                    GROUP BY Geo_Area__c, Initiative__r.CityView_Initiative__c
            ];
            for (AggregateResult ar : groupedResults) {
                Integer locationCount = (Integer)ar.get('locationCount');
                Id geoAreaId = (Id)ar.get('Geo_Area__c');
                Id associationId = (Id)ar.get('association');
                Date startDate = (Date)ar.get('startDate');
                startDateMap.put(organizationByGeoArea.get(geoAreaId)+'-'+associationId, startDate);
                Date endDate = (Date)ar.get('endDate');
                endDateMap.put(organizationByGeoArea.get(geoAreaId)+'-'+associationId, endDate);
                locationCountMap.put(organizationByGeoArea.get(geoAreaId)+'-'+associationId, locationCount);
            }

            // Process the strategic locations i.e create/update corresponding org associations
            processLocations();
        }catch(Exception ex){
            BBApps_ErrorHandler.logErrors(new List<Id>(strategicLocations.keySet()), ex, new BBApps_ErrorCustomFields(ERR_COMPUTING_ORG_ASSOCIATIONS));
        }
    }

    /**
    * Description : Method to process strategic locations
    * Parameters : 
    * Return Type : void
    */
    private void processLocations() {
        // Compare the org associations with existing to identify whether new record needs to be created
        List<Org_Association__c> orgAssociationsToProcess = new List<Org_Association__c>();
        List<Org_Association__c> orgAssociationsToDelete = new List<Org_Association__c>();

        for(String orgAssociation : locationByOrgAssociation.keySet()) {
            IM_Strategic_Locations__c location = locationByOrgAssociation.get(orgAssociation);
            // Adding a strategic location
            if(location != null && !location.Deleted__c) {
                if(existingOrgAssociationMap.containsKey(orgAssociation)){
                    // Org Association exists
                    Org_Association__c existingOrgAssociation = existingOrgAssociationMap.get(orgAssociation);
                    if(locationCountMap.containsKey(orgAssociation) && locationCountMap.get(orgAssociation) > 0 && location != null){
                        existingOrgAssociation.From__c = startDateMap.get(orgAssociation);
                        existingOrgAssociation.To__c = endDateMap.get(orgAssociation);
                    }else{
                        // Org association can be deleted
                        existingOrgAssociation.Deleted__c = true;
                    }
                    orgAssociationsToProcess.add(existingOrgAssociation);
                }else{
                    // Org association doesn't exist so create new one
                    Org_Association__c newOrgAssociation = new Org_Association__c();
                    newOrgAssociation.Organization__c = organizationByGeoArea.get(location.Geo_Area__c);
                    newOrgAssociation.Association__c = associationByInitiativeId.get(location.Initiative__c);
                    newOrgAssociation.From__c = location.Start_Date__c;
                    newOrgAssociation.To__c = location.End_Date__c;
                    newOrgAssociation.RecordTypeId = INITIATIVE_ORG_ASSO_RECORD_TYPE_ID;
                    orgAssociationsToProcess.add(newOrgAssociation);
                }
            }else{
                // Deleting a strategic location
                Org_Association__c existingOrgAssociation = existingOrgAssociationMap?.get(orgAssociation);
                if(locationCountMap.containsKey(orgAssociation) && locationCountMap.get(orgAssociation) > 0) {
                    // The org association has another strategic location don't delete it
                    // Just recompute the start and end dates 
                    existingOrgAssociation.From__c = startDateMap.get(orgAssociation);
                    existingOrgAssociation.To__c = endDateMap.get(orgAssociation);
                }else{
                    // The Org Association can be marked for deletion
                    existingOrgAssociation.Deleted__c = true;
                }
                orgAssociationsToProcess.add(existingOrgAssociation);
            }
        }
        BBApps_Crud.doUpsert(
            orgAssociationsToProcess,
            true
        );
    }
}