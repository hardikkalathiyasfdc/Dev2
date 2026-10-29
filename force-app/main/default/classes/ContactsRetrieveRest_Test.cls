@isTest
private without sharing class ContactsRetrieveRest_Test {
    
    @testSetup
    static void dataSetup() {
        Account acct = new Account(Name = 'TestAcct');
        insert acct;
        
        List<Contact> lstConToInsert = new List<Contact>();
        Contact con1 = new Contact(FirstName='First1', LastName='Last1', AccountId = acct.Id, Bio_Photo__c = 'Bio Photo1', Bio_Confidential_Notes__c = 'Bio Confidential Notes', Confidential_Notes__c='notes', 
                                   Bio_Description__c = 'Bio Description', Team_s__c = 'IT',Categories__c = 'Education;Nonprofit', Office_Phone_Country_Code__c='United States(+1)', Phone='2121231234');
        lstConToInsert.add(con1);
        
        Contact con2 = new Contact(FirstName='First2', LastName='Last2', AccountId = acct.Id, Bio_Photo__c = 'Bio Photo2', Bio_Confidential_Notes__c = 'Bio Confidential Notes', Confidential_Notes__c='notes2',
                                   Bio_Description__c = 'Bio Description', Team_s__c = 'IT', Confidential_Phone_Country_Code__c='United States(+1)', Confidential_Phone__c='2121112222', 
                                   ConfidentialPhoneType__c='Unknown', ReducedImage__c='0290239sfsfs0293203920');
        lstConToInsert.add(con2);
        
        Contact con3 = new Contact(FirstName='First3', LastName='Last3', AccountId = acct.Id, Bio_Photo__c = 'Bio Photo3', Bio_Confidential_Notes__c = 'Bio Confidential Notes', 
                                   Team_s__c = 'IT', Mobile_Phone_Country_Code__c='United States(+1)', MobilePhone='2121231234', ReducedImage__c='02902390293203920');
        lstConToInsert.add(con3);
        
        Insert lstConToInsert;
        
        Campaign camp = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, true)[0]; 
        Campaign camp1 = TestDataFactory.createCampaigns(2, Assets.CAMPAIGN_RECORDTYPE_DEVENAME_EVENT, true)[0];
        camp1.Start_Date_Time__c = System.today().addDays(-2);
        camp1.End_Date_Time__c = System.today().addDays(-1);
        camp1.Private_Campaign__c = true;
        update camp1;
        list <CampaignMember> lstCM = new list<CampaignMember>();
        CampaignMember campMember1 = new CampaignMember(ContactId=lstConToInsert[0].Id, CampaignId=camp.Id );
        lstCM.add(campMember1);
        CampaignMember campMember2= new CampaignMember(ContactId=lstConToInsert[1].Id, CampaignId=camp.Id);
        lstCM.add(campMember2);       
        CampaignMember campMember3 = new CampaignMember(ContactId=lstConToInsert[2].Id, CampaignId=camp1.Id, AttendedStatus__c = 'Yes - Virtually');
        lstCM.add(campMember3);
        CampaignMember campMember4 = new CampaignMember(ContactId=lstConToInsert[1].Id, CampaignId=camp1.Id, RSVPStatus__c ='No');
        lstCM.add(campMember4);
        insert lstCM;
        
        List<RecordType> interactionTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Interaction__c' AND DeveloperName='x2020' WITH SYSTEM_MODE];
        Interaction__c interaction = new Interaction__c();
        interaction.RecordTypeId = interactionTypes[0].Id;
        interaction.Name = 'test interaction';    
        interaction.Teams__c = TestDataFactory.createTeam('IT').Id;
        interaction.Contact__c = con1.Id;
        
        Interaction__c interaction1 = new Interaction__c();
        interaction1.RecordTypeId = interactionTypes[0].Id;
        interaction1.Name = 'test interaction1';
        interaction1.Teams__c = TestDataFactory.createTeam('IT').Id;
        interaction1.Contact__c = con1.Id;
        
        Interaction__c interaction2 = new Interaction__c();
        interaction2.RecordTypeId = interactionTypes[0].Id;
        interaction2.Name = 'test interaction2';
        interaction2.Teams__c = TestDataFactory.createTeam('IT').Id;
        interaction2.Contact__c = con2.Id;
    	insert new List<Interaction__c>{interaction, interaction1, interaction2};
    }

	@isTest
    static void testRestServiceList() {
        Campaign camp = [ SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1 ];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/getContacts';
        req.addParameter('listId', camp.Id);
        req.addParameter('access', 'true');
        req.addParameter('interaction', 'yes');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        List<ContactsRetrieveRest.ContactWrap> resp = ContactsRetrieveRest.doGet();
        Test.stopTest();
        system.assertEquals(resp.size(), 2);       
    }
    
    @isTest
    static void testRestServiceContacts() {
        Map<String,Contact> contacts = new Map<String, Contact>([ SELECT Id FROM Contact WITH SYSTEM_MODE]);
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/getContacts';
        req.addParameter('contactIds', JSON.serialize(new List<String>(contacts.keySet())));
        req.addParameter('access', 'true');
        req.addParameter('interaction', 'yes');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        List<ContactsRetrieveRest.ContactWrap> resp = ContactsRetrieveRest.doGet();
        Test.stopTest();
        system.assertEquals(resp.size(), 3);       
    }
    
    @isTest
    static void testDoGet_Exception() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        
        req.requestURI = '/services/apexrest/getContacts';
        
        // Invalid JSON -> deserialize fail
        req.addParameter('contactIds', 'INVALID_JSON');  
        
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        List<ContactsRetrieveRest.ContactWrap> resp = ContactsRetrieveRest.doGet();
        Test.stopTest();
        
        System.assertEquals(0, resp.size());
    }
    
    @isTest
    static void testGetContactWrap_ExceptionPath() {
        Map<String,Contact> contacts = new Map<String, Contact>([SELECT Id FROM Contact WITH SYSTEM_MODE]);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        
        req.requestURI = '/services/apexrest/getContacts';
        
        req.addParameter('contactIds', JSON.serialize(new List<String>(contacts.keySet())));
        req.addParameter('access', 'true');
        req.addParameter('interaction', 'yes');
        
        req.addParameter('selectedSource', ';;;');  
        
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        List<ContactsRetrieveRest.ContactWrap> resp = ContactsRetrieveRest.doGet();
        Test.stopTest();
        
        System.assert(resp.size() > 0);
    }
}