@isTest
public class BatchAccountRollupRecordsTest {
    @testSetup
    static void setupdata() {

        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
        insert cm;

        Account acc = TestDataFactory.getOrg('Test Org');
        insert acc;

        Contact con = TestDataFactory.getContact('TestOrg');
        con.accountId = acc.Id;
        insert con;

        Focus_Area__c focusArea = TestDataFactory.createFocusArea('Arts');
        insert focusArea;

        Association__c asso  = TestDataFactory.getAssociation('TestOrg', focusArea.Id);
        insert asso;

        Tag__c tag = TestDataFactory.getTag('TestOrg');
        insert tag;

        Tag_Junction__c tagJunction =  TestDataFactory.getTagJunc(tag,con);
        tagJunction.Account__c =  acc.Id;
        insert tagJunction;

        Opportunity opp =  TestDataFactory.getOpportunity(acc.Id);
        opp.StageName ='Prospecting';
        insert opp;

        ListOrganization__c listOrg = new ListOrganization__c();
        listOrg.List__c = cm.Id;
        listOrg.Organization__c = acc.Id;
        listOrg.Unique__c = cm.Id+'-'+acc.Id;
        insert listOrg;

        Interaction__c interaction = new Interaction__c();
        interaction.Contact__c = con.Id;
        interaction.Interaction_Date__c = Date.today().addMonths(-1).toStartofMonth().addDays(3);
        interaction.Name = 'interaction 0';
        interaction.Teams__c  = TestDataFactory.createTeam('Arts').Id;
        interaction.Contact_Interaction_Organization__c = acc.Id;
        insert interaction;

        Org_Association__c orgAssociation = new Org_Association__c (
            Organization__c = acc.Id,
            Association__c = asso.Id,
            From__c = System.today(),
            To__c = System.today()
        );
        insert orgAssociation;

        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();

        Pledge__c pledge = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );

        Confidential_Items__c conItem = new Confidential_Items__c();
        conItem.Contact__c = con.Id;
        conItem.Account__c = acc.id;
        insert conItem;

        Donor__c donor = new Donor__c();
        donor.Organization__c = acc.id;
        donor.Pledge__c = pledge.id;
        donor.Recipient_Organization_Lookup__c = acc.id;
        insert donor;


    }

    @isTest
    static void test() {
        Test.startTest();
        String CRON_EXP = '0 0 9 1 * ? *';
        system.schedule('jobName', CRON_EXP, new BatchAccountRollupRecords());
        Database.executebatch(new BatchAccountRollupRecords());
        Test.stopTest();

        Account acc = [SELECT Id,Touchpoint_Summary__c FROM Account with SYSTEM_MODE LIMIT 1];
        system.assertEquals(8,acc.Touchpoint_Summary__c);
    }
}