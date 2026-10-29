@isTest
public with sharing class OrgAssociationComputationQueueableTest {
  private static final String INITIATIVE_ASSO_RECORD_TYPE_ID = Schema.SObjectType.Association__c.getRecordTypeInfosByDeveloperName()
		.get(Assets.INITIATIVE)
		.getRecordTypeId();

    private static final String INITIATIVE_ORG_ASSO_RECORD_TYPE_ID = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName()
		.get(Assets.INITIATIVE)
		.getRecordTypeId();

  @testSetup
  static void setup() {
    //Bypass Strategic Location Trigger
    Bypass_Automation_Setting__c bypassSetting = new Bypass_Automation_Setting__c();
    bypassSetting.IM_Strategic_Location_Trigger__c = true;
    bypassSetting.IM_Strategic_Location_Validation__c = true;
    insert bypassSetting;

    Account org = TestDataFactory.createCityViewOrg();
    Geo_Area__c geoArea = [SELECT Id, Enabled_For_Grants__c FROM Geo_Area__c WHERE Id = :org.Government_Geo_Area__c WITH SYSTEM_MODE LIMIT 1];
    geoArea.Enabled_For_Grants__c = true;
    update as system geoArea;
    TestDataFactory.createInitiativeBaseData();
    Focus_Area__c focusArea = [SELECT Id FROM Focus_Area__c WHERE NAME = 'Arts' WITH SYSTEM_MODE LIMIT 1];
    Association__c association = TestDataFactory.getAssociation('Clean Air', focusArea.Id);
    association.RecordTypeId = INITIATIVE_ASSO_RECORD_TYPE_ID;
    insert as system association;
    IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
    budgetedInitiative.CityView_Initiative__c = association.Id;
    update as system budgetedInitiative;
    IM_Budget__c budget = TestDataFactory.createBudget('Clean Air 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
    IM_Strategic_Locations__c strategicLocation = TestDataFactory.createStrategicLocation(budgetedInitiative.Id, org.Government_Geo_Area__c);
  }

  @isTest
  public static void testOrgAssociationComputationQueueable() {
    Test.startTest();
        Map<Id, IM_Strategic_Locations__c> strategicLocations = new Map<Id, IM_Strategic_Locations__c>([SELECT Id, Geo_Area__c, Start_Date__c, End_Date__c, Initiative__c, Deleted__c FROM IM_Strategic_Locations__c WITH SYSTEM_MODE]);
        ID jobID = System.enqueueJob(new OrgAssociationComputationQueueable(strategicLocations, null));
    Test.stopTest();
    List<Org_Association__c> orgAssociation = [SELECT Id FROM Org_Association__c WITH SYSTEM_MODE];
    Assert.areEqual(false, orgAssociation.isEmpty());
  }

  @isTest
  public static void testDeleteOrgAssociationQueueable() {
    Test.startTest();
        Map<Id, IM_Strategic_Locations__c> strategicLocations = new Map<Id, IM_Strategic_Locations__c>([SELECT Id, Geo_Area__c, Start_Date__c, End_Date__c, Initiative__c, Deleted__c FROM IM_Strategic_Locations__c WITH SYSTEM_MODE]);
        for(Id stlId : strategicLocations.keySet()){
          IM_Strategic_Locations__c stl = strategicLocations.get(stlId);
          stl.Deleted__c = true;
        }
        update as system strategicLocations.values();
        List<Account> orgs = [SELECT Id FROM Account WITH SYSTEM_MODE LIMIT 1];
        List<Association__c> associations = [SELECT Id FROM Association__c WITH SYSTEM_MODE LIMIT 1];
        TestDataFactory.createOrgAssociation(orgs[0], associations[0], INITIATIVE_ORG_ASSO_RECORD_TYPE_ID);
        ID jobID = System.enqueueJob(new OrgAssociationComputationQueueable(strategicLocations, null));
    Test.stopTest();
    List<Org_Association__c> orgAssociation = [SELECT Id, Deleted__c FROM Org_Association__c WITH SYSTEM_MODE];
    Assert.areEqual(true, orgAssociation[0].Deleted__c);
  }
}