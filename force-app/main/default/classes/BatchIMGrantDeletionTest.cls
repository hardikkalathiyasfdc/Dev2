@isTest
public with sharing class BatchIMGrantDeletionTest {
  private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
    .get(Assets.PARENT_INITIATIVE)
    .getRecordTypeId();

  private static final String BUDGETED_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
    .get(Assets.BUDGET_INITIATIVE)
    .getRecordTypeId();

  private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{ 'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c' });
  private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));

  @TestSetup
  static void setup() {
    Account org = TestDataFactory.createOrg('Test org');

    TestDataFactory.createInitiativeBaseData();
    IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
    IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');

    IM_Component__c component = TestDataFactory.createComponent(budget.Id);
    IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
    IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
    IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
    IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, partner.Id, geography.Id);
    IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
    Currency__c usdCurrency = TestDataFactory.createCurrency('USD');
    Fund__c fund = TestDataFactory.createFund('Personal');
  }

  @isTest
  public static void testDeleteGrants() {
    Test.startTest();
    List<IM_Initiative__c> parentInitiative = [
      SELECT Id
      FROM IM_Initiative__c
      WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    IM_Initiative__c initiative = [
      SELECT Id
      FROM IM_Initiative__c
      WHERE Name = 'Clean Beach 1.0'
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    List<IM_Budget__c> budget = [
      SELECT Id
      FROM IM_Budget__c
      WHERE Initiative__c = :initiative.Id
      WITH SYSTEM_MODE
    ];
    initiative.Approved__c = true;
    initiative.Parent_Initiative__c = parentInitiative[0].Id;
    initiative.Status__c = 'Ongoing';
    initiative.Current_Budget__c = budget[0].Id;
    initiative.Approved_Date__c = System.today();
    update as system initiative;
    List<IM_Grant__c> imGrants = [SELECT Id, Deleted__c FROM IM_Grant__c WITH SYSTEM_MODE LIMIT 1];
    imGrants[0].Deleted__c = true;
    update as system imGrants;
    BatchIMGrantDeletion batchGrantDeletion = new BatchIMGrantDeletion();
    new BatchIMGrantDeletion().execute(null);

    Test.stopTest();
    List<IM_Grant__c> imGrantsDeleted = [
      SELECT Id, Deleted__c
      FROM IM_Grant__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Assert.areEqual(true, imGrantsDeleted.isEmpty());
  }
}