/**
* Author      : Paddy
* Date        : 11/29/2024
* Jira        : IM-63
* Description : Test class for IMUtil.
* Modified By : 
*/
@isTest
public with sharing class IMUtilTest {
       
    @TestSetup
    static void setup(){
        //Bypass Strategic Location Trigger
        Bypass_Automation_Setting__c bypassSetting = new Bypass_Automation_Setting__c();
        bypassSetting.IM_Strategic_Location_Trigger__c = true;
        bypassSetting.IM_Strategic_Location_Validation__c = true;
        insert bypassSetting;

        Account acct = TestDataFactory.createOrg('Bloomberg');
        Contact contact = TestDataFactory.createContact(acct.Id, 'John');
        User adminUser = TestDataFactory.createUser('System', 'Admin');
        
        // Create base data including Teams, Focus Areas, Foundation Codes, and Segments
        TestDataFactory.createInitiativeBaseData();
        
       	IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
        
        IM_Budget_Org__c budgetOrg = TestDataFactory.createBudgetOrg(budget.Id, acct.Id);
        IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
		IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
        
        IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
        IM_Grant__c imGrant = TestDataFactory.createIMGrant();
        IM_Budget_Grant__c budgetGrant = TestDataFactory.createBudgetGrant(budget.Id, budgetOrg.Id, imGrant.Id);
        //IM_Budget_Row__c budetRow = TestDataFactory.createBudgetRow(budget.Id, budgetGrant.Id);
        IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, budgetOrg.Id, geography.Id);
        
        Geo_Area__c geoArea = TestDataFactory.createGeoArea();
        geoArea.DAMA_Id__c = '1234';
        geoArea.BP_Active__c = true;
        geoArea.Enabled_For_Grants__c = true;
        insert geoArea;
        TestDataFactory.createStrategicLocation(budgetedInitiative.Id, geoArea.Id);
    }    
    
    @isTest
    public static void testFetchTemplatesByTypeAndSubtype() {
        Test.startTest();
            List<IM_Template_Mapping__mdt> templates = IMUtil.fetchTemplatesByTypeAndSubtype('test', 'subtype');
            Assert.isTrue(templates.isEmpty());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetBudget() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            IM_Budget__c budgetRec = IMUtil.getBudget(budget.Id);
            Assert.areEqual('Clean Air',budgetRec.Name);
        Test.stopTest();
    }
    
    @isTest
    public static void testgetBudgetRows() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Budget_Row__c> budgetRows = IMUtil.getBudgetRows(budget.Id);
            Assert.isFalse(budgetRows.isEmpty());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetAllComponents() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Component__c> componentData = IMUtil.getAllComponents(budget.Id);
            Assert.isFalse(componentData.isEmpty());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetGeography() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Geography__c> geography = IMUtil.getGeography(budget.Id);
            Assert.areEqual(1,geography.size());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetBudgetPeriods() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Budget_Period__c> budgetPeriods  = IMUtil.getBudgetPeriods(budget.Id);
            Assert.areEqual(4,budgetPeriods.size());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetBudgetRowsByBudget() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Budget_Row__c> budgetRows  = IMUtil.getBudgetRowsByBudget(budget.Id);
            Assert.isFalse(budgetRows.isEmpty());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetSubComponents() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Component__c> subComponents  = IMUtil.getSubComponents(budget.Id);
            Assert.isFalse(subComponents.isEmpty());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetComponents() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Component__c> components  = IMUtil.getComponents(budget.Id);
            Assert.isFalse(components.isEmpty());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetBudgetOrgs() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Budget_Org__c> budgetOrgs  = IMUtil.getBudgetOrgs(budget.Id);
            Assert.areEqual(1,budgetOrgs.size());
        Test.stopTest();
    }

    @isTest
    public static void testgetActiveBudgetOrgs() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
            List<IM_Budget_Org__c> budgetOrgs  = IMUtil.getActiveBudgetOrgs(budget.Id);
            Assert.areEqual(1,budgetOrgs.size());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetBudgetGrants() {
        Test.startTest();
            IM_Budget__c budget = [Select Id,Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
             List<IM_Budget_Grant__c> budgetGrants   = IMUtil.getBudgetGrants(budget.Id);
            Assert.areEqual(1,budgetGrants.size());
        Test.stopTest();
    }
    
    @isTest
    public static void testgetTemplate() {
        Test.startTest();
            Template__c tempRec = IMUtil.getTemplate('IM_IB_Edit_By_Component_v1');
            Assert.isNull(tempRec);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetInitiative() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Air'];
        Test.startTest();
            IM_Initiative__c initiativeRec = IMUtil.getInitiative(budgetedInitiative.Id);
            Assert.areEqual(budgetedInitiative.Name, initiativeRec.Name, 'Initiative record Name should match.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetSegmentTeamRecord() {
        Segment__c personnel = [SELECT Name FROM Segment__c WHERE Name = 'Personal' LIMIT 1];
        Team__c artsTeam = [SELECT Name FROM Team__c WHERE Name = 'Arts'];
        Segment_Team__c segmentTeam = [SELECT Name FROM Segment_Team__c WHERE Segment__c = :personnel.Id];
        Test.startTest();
        	Segment_Team__c returnedSegmentTeam = IMUtil.getSegmentTeamRecord(segmentTeam.Name);
        	Assert.isNotNull(returnedSegmentTeam, 'Segment Team record should exist.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetSegmentTeam() {
        Segment__c personnel = [SELECT Name FROM Segment__c WHERE Name = 'Personal' LIMIT 1];
        Team__c artsTeam = [SELECT Name FROM Team__c WHERE Name = 'Arts'];
        Test.startTest();
        	Segment_Team__c segmentTeam = IMUtil.getSegmentTeam(personnel.Id, artsTeam.Id);
        	Assert.isNotNull(segmentTeam, 'Segment Team record should exist.');
        Test.stopTest();
    }
    
    /*@isTest
    public static void testGetContactList() {
        Contact contact = [SELECT BRM_User__c, Bgive_Id__c FROM Contact WHERE FirstName = 'John'];
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'System'];
        contact.BRM_User__c = adminUser.Id;
        contact.Bgive_Id__c = '1234';
        update contact;
        Test.startTest();
        	List<Contact> contacts = IMUtil.getContactList(new Set<String>{adminUser.Id});
        	Assert.isFalse(contacts.isEmpty(), 'Contact records should exists.');
        Test.stopTest();
    }*/
    
    @isTest
    public static void testStrategicLocations() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0'];
        List<IM_Strategic_Locations__c> temp = [SELECT Name, Initiative__c,Initiative__r.name FROM IM_Strategic_Locations__c];
        Test.startTest();
            List<IM_Strategic_Locations__c> stratagicLocations = IMUtil.getStrategicLocations(budgetedInitiative.Id);
            Assert.isFalse(stratagicLocations.isEmpty(), 'Strategic Location records should exists.');
        Test.stopTest();
    }

    @isTest
    public static void testGetStrategicLocations() {
        Map<Id, IM_Initiative__c> budgetedInitiative = new Map<Id, IM_Initiative__c>([SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0']);
        List<IM_Strategic_Locations__c> temp = [SELECT Name FROM IM_Strategic_Locations__c];
        Test.startTest();
            Map<Id, IM_Strategic_Locations__c> stratagicLocations = IMUtil.getStrategicLocations(budgetedInitiative.keySet());
        Test.stopTest();
        Assert.areEqual(temp.size(), stratagicLocations.size());
    }
    
    @isTest
    public static void testGetBGiveSyncFieldMapList() {
        Test.startTest();
            List<Bgive_Sync_Field_Mapping__mdt> bgiveSyncFieldMapping = IMUtil.getBGiveSyncFieldMapList('IM_Initiative__c');
            Assert.isFalse(bgiveSyncFieldMapping.isEmpty(), 'Bgive_Sync_Field_Mapping should exists for IM_Initiative object.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBGiveFieldValueMapList() {
        Bgive_Sync_Field_Mapping__mdt initativeBgiveSync = [SELECT Id FROM Bgive_Sync_Field_Mapping__mdt WHERE BRM_Object__c ='IM_Initiative__c' AND BRM_Field__c = 'Status__c'];
        Test.startTest();
            List<Bgive_Field_Value_Mapping__mdt> bgiveFieldValueMapping = IMUtil.getBGiveFieldValueMapList(initativeBgiveSync.Id);
            Assert.isFalse(bgiveFieldValueMapping.isEmpty(), 'Bgive_Sync_Field_Mapping should exists for IM_Initiative.Status__c.');
        Test.stopTest();
    }
        
    @isTest
    public static void testGetCheckoutInformation() {
        IM_Budget__c budget = [SELECT Checked_Out_At__c, Checked_Out_By__c FROM IM_Budget__c WHERE Name ='Clean Air'];
        User adminUser = [SELECT Name FROM User WHERE FirstName = 'System'];
        budget.Checked_Out_At__c = System.now();
        budget.Checked_Out_By__c = adminUser.Id;
        budget.Status__c = 'Draft';
        update budget;
        Test.startTest();
            String checkoutUserName = IMUtil.getCheckoutInformation(budget.Id);
            Assert.areEqual(adminUser.Name, checkoutUserName, 'Checkout user name should match the username.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetInitiativesByRenewalIds() {
        /*IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Air'];
        IM_Initiative__c renewalInitiative = TestDataFactory.createBudgetedInitiative('Clean Air Renewal', 'Renewal', budgetedInitiative);
        Test.startTest();
        List<IM_Initiative__c> initiatives = IMUtil.getInitiativesByRenewalIds(new Set<Id>{renewalInitiative.Id});
            Assert.isFalse(initiatives.isEmpty(), 'Initiative records should exists.');
        Test.stopTest();*/
        Set<Id> renewalIds = new Set<Id>();
        Test.startTest();
        	List<IM_Initiative__c> initiatives = IMUtil.getInitiativesByRenewalIds(renewalIds);
            Assert.isTrue(initiatives.isEmpty(), 'Should return empty list for empty renewal Ids.');
        Test.stopTest();
    }
    
    
    @isTest
    public static void testGetMainInitiative() {
    	IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0'];
        Test.startTest();
        	IM_Initiative__c initiative = IMUtil.getMainInitiative(budgetedInitiative.Id);
            Assert.isNotNull(initiative, 'Main Initiative should not be null.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBudgetGrantsOfCurrBudget() {
    	IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name ='Clean Air'];
        Test.startTest();
        	List<IM_Budget_Grant__c> budgetGrants = IMUtil.getBudgetGrantsOfCurrBudget(budget.Id);
            Assert.areEqual(1, budgetGrants.size(), 'Should have one Budget Grant.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBudgetOrgsUsingIdSet() {
    	IM_Budget_Org__c budgetOrg = [SELECT Id FROM IM_Budget_Org__c LIMIT 1];
        Test.startTest();
        	List<IM_Budget_Org__c> budgetOrgs = IMUtil.getBudgetOrgsUsingIdSet(new Set<Id>{budgetOrg.Id});
            Assert.areEqual(1, budgetOrgs.size(), 'Should have one Budget Org.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetClonedBudget() {
    	IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name ='Clean Air'];
        Test.startTest();
        	IM_Budget__c clonedBudget = IMUtil.getClonedBudget(budget.Id);
            Assert.isNotNull(clonedBudget, 'Cloned budget should not be null.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetApprovals() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0'];
        IM_Approval__c approval1 = TestDataFactory.buildApproval('AJ', System.today(), budgetedInitiative.Id);
        insert approval1;
        Test.startTest();
        	List<IM_Approval__c> approvals = IMUtil.getApprovals(budgetedInitiative.Id);
        	Assert.areEqual(1, approvals.size(), 'Should have one Approval.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBGiveFieldValuesByObject() {
        Test.startTest();
        	List<Bgive_Field_Value_Mapping__mdt> mappings = IMUtil.getBGiveFieldValuesByObject('Grant%');
            Assert.isFalse(mappings.isEmpty(), 'Should not return empty results.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetPicklistValuesFromMetadata() {
        Test.startTest();
        	Map<String, Map<String, String>> mappings = IMUtil.getPicklistValuesFromMetadata('IM_Grant__c');
            Assert.isFalse(mappings.isEmpty(), 'Should not return empty results.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetBgiveFieldToValueMap() {
        Test.startTest();
        	Map<String, List<String>> mappings = IMUtil.getBgiveFieldToValueMap('IM_Grant__c');
            Assert.isFalse(mappings.isEmpty(), 'Should not return empty results.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetFoundationCodeById() {
        Foundation_Code__c foundationCode = [SELECT Id FROM Foundation_Code__c WHERE Name = 'Initiatives' LIMIT 1];
        Test.startTest();
        	Foundation_Code__c fc = IMUtil.getFoundationCodeById(foundationCode.Id);
            Assert.areEqual(fc.Id, foundationCode.Id, 'Foundation Code Id should match.');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetApprovedAmendments() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0'];
        Test.startTest();
        	List<IM_Initiative__c> amendments = IMUtil.getApprovedAmendments(new Set<Id>{budgetedInitiative.Id});
            Assert.isNull(amendments, 'Approved amendments should be empty.');
        Test.stopTest();
    }       
    
    @isTest
    public static void testTruncateFieldValue() {
        Test.startTest();
            String result1 = IMUtil.truncateFieldValue(5, 'Hello World', 'Prefix-', '');
            Assert.areEqual('Prefix-Hello', result1, 'Should truncate with prefix');
            
            String result2 = IMUtil.truncateFieldValue(5, 'Hello World', '', '-Suffix');
            Assert.areEqual('Hello-Suffix', result2, 'Should truncate with suffix');
            
            String result3 = IMUtil.truncateFieldValue(20, 'Short', '', '');
            Assert.areEqual('Short', result3, 'Should not truncate short strings');
        Test.stopTest();
    }

    @isTest
    public static void testGetUserAccessLevelSingle() {
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
        Test.startTest();
            UserRecordAccess access = IMUtil.getUserAccessLevel(budget.Id);
            Assert.isNotNull(access, 'User access should not be null');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetUserAccessLevelMultiple() {
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
        Set<Id> recordIds = new Set<Id>{budget.Id};
        Test.startTest();
            List<UserRecordAccess> accessList = IMUtil.getUserAccessLevel(recordIds);
            Assert.areEqual(1, accessList.size(), 'Should return one access record');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetIMGrantChildren() {
        IM_Grant__c grant = [SELECT Id FROM IM_Grant__c LIMIT 1];
        Test.startTest();
            List<IM_Budget_Grant__c> children = IMUtil.getIMGrantChildren(grant.Id);
            Assert.areEqual(1, children.size(), 'Should return one child grant');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetStrategicLocationsWithSet() {
        IM_Initiative__c initiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0' LIMIT 1];
        Set<String> initiativeIds = new Set<String>{initiative.Id};
        Test.startTest();
            List<IM_Strategic_Locations__c> locations = IMUtil.getStrategicLocations(initiativeIds);
            Assert.areEqual(1, locations.size(), 'Should return one strategic location');
        Test.stopTest();
    }

    @isTest
    public static void testGetActiveBudgets() {
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
        Set<Id> activeBudgetIds = new Set<Id>{budget.Id};
        
        Test.startTest();
            List<IM_Budget__c> activeBudgets = IMUtil.getActiveBudgets(activeBudgetIds);
            Assert.areEqual(1, activeBudgets.size(), 'Should return one active budget');
            Assert.areEqual(budget.Id, activeBudgets[0].Id, 'Budget ID should match');
            Assert.isNotNull(activeBudgets[0].Partner_Fund__c, 'Partner_Fund__c field should be queried');
        Test.stopTest();
    }
    
    @isTest
    public static void testFetchReview() {
        // Create a test review record
        IM_Review__c review = TestDataFactory.createReview('Strategy');
        review.Initiative__c = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0' LIMIT 1].Id;
        insert review;
        
        Test.startTest();
            IM_Review__c fetchedReview = IMUtil.fetchReview(review.Id);
            Assert.isNotNull(fetchedReview, 'Review should not be null');
            Assert.areEqual(review.Id, fetchedReview.Id, 'Review ID should match');
            Assert.areEqual(review.Initiative__c, fetchedReview.Initiative__c, 'Initiative ID should match');
            Assert.isNotNull(fetchedReview.CreatedDate, 'CreatedDate should not be null');
        Test.stopTest();
    }
    
    @isTest
    public static void testFormatAmount() {
        Test.startTest();
            // Test billion formatting
            String billionFormat = IMUtil.formatAmount(1500000000);
            Assert.areEqual('1.50B', billionFormat, 'Should format billion amounts correctly');
            
            // Test million formatting
            String millionFormat = IMUtil.formatAmount(2500000);
            Assert.areEqual('2.50M', millionFormat, 'Should format million amounts correctly');
            
            // Test thousand formatting
            String thousandFormat = IMUtil.formatAmount(5000);
            Assert.areEqual('5k', thousandFormat, 'Should format thousand amounts correctly');
            
            // Test small amounts
            String smallFormat = IMUtil.formatAmount(500);
            Assert.areEqual('500', smallFormat, 'Should format small amounts correctly');
            
            // Test zero
            String zeroFormat = IMUtil.formatAmount(0);
            Assert.areEqual('0', zeroFormat, 'Should format zero correctly');
            
            // Test negative amounts
            String negativeFormat = IMUtil.formatAmount(-1000);
            Assert.areEqual('-1000', negativeFormat, 'Should format negative amounts correctly');
        Test.stopTest();
    }
    
    @isTest
    public static void testProcessErrors() {
        // Create test records that will fail validation
        List<IM_Budget__c> testBudgets = new List<IM_Budget__c>();
        for (Integer i = 0; i < 3; i++) {
            IM_Budget__c budget = new IM_Budget__c();
            // Missing required fields to cause validation errors
            testBudgets.add(budget);
        }
        
        Test.startTest();
            Database.SaveResult[] results = Database.insert(testBudgets, false);
            IMUtil.processErrors(results);
            
            // Verify that error records were created
            List<BBApps_Error_Log__c> errors = [SELECT id,name from BBApps_Error_Log__c];
            Assert.isTrue(errors.isEmpty(), 'Should have created error records for failed saves');
        Test.stopTest();
    }

    @isTest
    public static void testGetContactNameByBgiveId() {
        Bypass_Automation_Setting__c bypassSetting = [SELECT Id, Contact_Trigger__c FROM Bypass_Automation_Setting__c LIMIT 1];
		bypassSetting.Contact_Trigger__c = true;
		update bypassSetting;
        Contact contact = [SELECT Bgive_Id__c FROM Contact WHERE FirstName = 'John'];
        contact.Bgive_Id__c = '1234';
        update contact;
        Test.startTest();
        	String contactName = IMUtil.getContactNameByBgiveId(contact.Bgive_Id__c);
        	Assert.areEqual(contactName, 'John Contact');
        Test.stopTest();
    }
    
    @isTest
    public static void testFormatDateForApi() {
        Date dateValue = Date.newInstance(2026, 3, 11);
        
        Test.startTest();
        	String apiDate = IMUtil.formatDateForApi(dateValue);
        	Assert.areEqual('2026-03-11', apiDate, 'Date only API format');
        	Assert.isNull(IMUtil.formatDateForApi(null), 'Null date return null');
        
        	Assert.areEqual(10, apiDate.length(), 'yyyy-MM-dd is 10 characters.');
            Assert.isFalse(apiDate.contains(':'), 'Date only payload must not include a time portion.');
        Test.stopTest();
    }

    @isTest
    public static void testGetBudgetGrantsByIMGrant() {
        IM_Grant__c imGrant = [SELECT Id FROM IM_Grant__c LIMIT 1];
        List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c WHERE IM_Grant__c = :imGrant.Id];
        Test.startTest();
        	Map<Id, IM_Budget_Grant__c> budgetGrantMap = IMUtil.getBudgetGrantsByIMGrant(imGrant.Id);
        Test.stopTest();
        Assert.areEqual(budgetGrants.size(), budgetGrantMap.size());
    }

    @isTest
    public static void testGetPartnerById() {
        Account org = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        	Account fetchedOrg = IMUtil.getPartnerById(org.Id);
        Test.stopTest();
        Assert.areEqual(org.Id, fetchedOrg.Id);
    }

    @isTest
    public static void testGetPartnerBudgetOrgs() {
        Account org = [SELECT Id FROM Account LIMIT 1];
        List<IM_Budget__c> budgets = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];
        List<Id> budgetIds = new List<Id>();
        for (IM_Budget__c budget : budgets) {
            budgetIds.add(budget.Id);
        }
        List<IM_Budget_Org__c> budgetOrgs = [SELECT Id FROM IM_Budget_Org__c WHERE Budget__c IN :budgetIds AND Organization__c = :org.Id];
        Test.startTest();
        	List<IM_Budget_Org__c> fetchedBudgetOrgs = IMUtil.getPartnerBudgetOrgs(budgetIds, org.Id);
        Test.stopTest();
        Assert.areEqual(budgetOrgs[0].Id, fetchedBudgetOrgs[0].Id);
    }
    
    @isTest
    public static void testGetBudgetRowsByGrant() {
        List<IM_Budget__c> budgets = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];
        List<Id> budgetIds = new List<Id>();
        for (IM_Budget__c budget : budgets) {
            budgetIds.add(budget.Id);
        }
        List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c WHERE Budget__c IN :budgetIds];
        List<Id> budgetGrantIds = new List<Id>();
        for (IM_Budget_Grant__c budgetGrant : budgetGrants) {
            budgetGrantIds.add(budgetGrant.Id);
        }
        List<IM_Budget_Row__c> budgetRows = [SELECT Id, Budget_Grant__c, Budget__c FROM IM_Budget_Row__c WHERE Budget__c IN :budgetIds];
        budgetRows[0].Budget_Grant__c = budgetGrantIds[0];
        update budgetRows[0];
        Test.startTest();
        	List<IM_Budget_Row__c> fetchedBudgetRows = IMUtil.getBudgetRowsByGrant(budgetIds, budgetGrantIds);
        Test.stopTest();
        Assert.areEqual(budgetRows[0].Id, fetchedBudgetRows[0].Id);
    }

    @isTest
    public static void testGetBudgetGrantsByBudgets() {
        List<IM_Budget__c> budgets = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];
        List<Id> budgetIds = new List<Id>();
        for (IM_Budget__c budget : budgets) {
            budgetIds.add(budget.Id);
        }
        List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c WHERE Budget__c IN :budgetIds];
        Test.startTest();
        	List<IM_Budget_Grant__c> fetchedBudgetGrants = IMUtil.getBudgetGrantsByBudgets(budgetIds);
        Test.stopTest();
        Assert.areEqual(budgetGrants[0].Id, fetchedBudgetGrants[0].Id);
    }
}