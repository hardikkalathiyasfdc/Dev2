/**
 * @description       :
 * @author            : Sai Bhargav Thotakura
 * @group             :
 * @last modified on  : 05-27-2025
 * @last modified by  : Sai Bhargav Thotakura
 **/
@isTest
public class TestDataFactory {
    private static Id COMPANY_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId();
    private static Id CITY_RECORDTYPE_ID = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
    private static Id BBRM_RECORDTYPE_ID = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Standard_MB2020').getRecordTypeId();
    private static Id ORG_INTERACTION_RECORDTYPE_ID = Schema.SObjectType.Interaction__c.getRecordTypeInfosByName().get('Organization Highlight/CityView').getRecordTypeId();
    public static List<String> STATES = new String[]{'NY','CA','CT','MA','NJ','FL','UT'};
    public static Group createGroup() {
        return new Group(Name = 'Test Group');
    }

    public static Contact getContact(String lastName) {
        return new Contact(LastName = lastName);
    }

    public static Account getOrg(String name) {
        return new Account(Name = name);
    }

    public static Association__c getAssociation(String name) {
        return new Association__c (Name = name, Association_Type__c = 'City View', Active__c = true);
    }

    public static Tag__c getTag(String name) {
        return new Tag__c(Name = name);
    }

    public static Tag_Junction__c getTagJunc(Tag__c tag, Contact c) {
        return new Tag_Junction__c(Tag__c = tag.Id, Contact__c = c.Id);
    }

    public static Campaign getList(String name, String recTypeName) {
        Id recId = !String.isBlank(recTypeName)
        ? Schema.SObjectType.Campaign.getRecordTypeInfosByName()
        .get(recTypeName)
        .getRecordTypeId()
        : null;

        return new Campaign(Name = name, RecordTypeId = recId);
    }

    public static CampaignMember getListMember(Id campId, Id contactId) {
        return new CampaignMember(ContactId = contactId, CampaignId = campId);
    }

    public static Opportunity getOpportunity(Id accId) {
        return new Opportunity(AccountId = accId, Name = 'Test Opp');
    }


	public static File_Group__c getFileGroup(
		String objectName,
		String category
	) {
		return new File_Group__c(
			Object_Type__c = objectName,
			Category__c = category
		);
	}

    public static Contact createMayorContact(){
        Account a = new Account(Name = 'Test City of San Francisco' , AKA__c  = 'City of San Francisco, CA;', RecordTypeId = COMPANY_RECORDTYPE_ID);
        insert as system a;

		Contact c = new Contact(
			AccountId = a.Id,
			FirstName = 'James',
			LastName = 'Bond',
			MailingCountry = 'United States',
			Title = 'Mayor',
			RecordTypeId = BBRM_RECORDTYPE_ID
		);
        insert as system c;

        // Create Employment History
        Employment_History_and_Board_Membership__c history =  new Employment_History_and_Board_Membership__c();
        history.Contact_Name__c = c.Id;
        history.Organization_Name__c = a.Id;
        history.From__c = '2022';
        history.Role__c = 'Mayor';
        insert as system history;
        return c;
    }

	public static void createInteraction(
		Id contactId,
		String subject,
		String team,
		String publishStatus
	) {
        Interaction__c  interaction = new Interaction__c ();
        interaction.Teams__c = getTeamIdByName(team);
        interaction.Interaction_Date__c   = System.Today().addMonths(-1);
        interaction.Name   = subject;
        interaction.Contact__c = contactId;
        interaction.CityView_Review_Status__c = publishStatus;
        insert as system interaction;
    }

	public static Interaction__c createOrgInteraction(
		String orgId,
		String subject,
		String team,
		String publishStatus
	) {
        Interaction__c  interaction = new Interaction__c ();
        interaction.Teams__c = getTeamIdByName(team);
        interaction.Interaction_Date__c   = System.Today().addMonths(-1);
        interaction.Name   = subject;
        interaction.Organization__c = orgId;
        interaction.CityView_Review_Status__c = publishStatus;
        interaction.RecordTypeId = ORG_INTERACTION_RECORDTYPE_ID;
        insert as system interaction;
        return interaction;
    }


    private static Id getTeamIdByName(String teamName) {
		if (String.isBlank(teamName)) {
			return null;
		}
        List<Team__c> teams = [SELECT Id FROM Team__c WHERE Name = :teamName WITH SYSTEM_MODE LIMIT 1];
		return teams.isEmpty() ? createTeam(teamName).Id : teams[0].Id;
    }
    public static List<Focus_Area__c> createFocusAreas() {
        List<Focus_Area__c> focusAreas = new List<Focus_Area__c>{
            new Focus_Area__c(Name = 'Public Health', Color_Code__c = '#FAA626'),
            new Focus_Area__c(Name = 'Arts', Color_Code__c = '#34469D')
        };
        insert as system focusAreas;
        return focusAreas;
    }
    
    public static Account createCityViewOrg(){
         Map<String, Geo_Area__c> createGeoHierarchy = TestDataFactory.createGeoHierarchy();
        // Step 4: Create City Record (Child of State)
         Geo_Area__c geoArea = createGeoHierarchy.get('City');

        Account a = new Account(Name = 'Test City of New York' , AKA__c  = 'City of New York, NY;', RecordTypeId = COMPANY_RECORDTYPE_ID);
        a.Org_Type__c = 'Government - City';
        a.Government_Geo_Area__c = geoArea.id;
        insert as system a;
        return a;
    }

    public static Account createOrg(String name){
        Account a = new Account(Name = name , AKA__c  = name);
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		Database.insert(a, dml, AccessLevel.SYSTEM_MODE);
        return a;
    }

    public static Contact createContact(Id accId , String Name){
		Contact c = new Contact(
			FirstName = Name,
			LastName = 'Contact',
			AccountId = accId
		);
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		Database.insert(c, dml, AccessLevel.SYSTEM_MODE);
        return c;
    }
    
	public static Recipient_Organization__c createRecipientOrganization(Id organizationId, Id projectId, Id softCreditContactId) {
		Recipient_Organization__c recipient = new Recipient_Organization__c(
			Organization__c = organizationId,
			Fundraising_Project__c = projectId,
			Recipient_Soft_Credit__c = softCreditContactId
		);
		insert as system recipient;
		return recipient;
	}

    public static Contact createRestrictedContact(Id accId, String name) {
		Contact contact = new Contact(
			FirstName = name,
			LastName = 'Contact',
			AccountId = accId,
			Restricted__c = true
		);
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		Database.insert(contact, dml, AccessLevel.SYSTEM_MODE);
		return contact;
    }

    public static Contact createContactWithBioPhoto(Id accId, String name, String bioPhoto) {
		Contact contact = new Contact(
			FirstName = name,
			LastName = 'Contact',
			AccountId = accId,
			Bio_Photo__c = bioPhoto
		);
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		Database.insert(contact, dml, AccessLevel.SYSTEM_MODE);
		return contact;
    }

     public static Confidential_Items__c createConfidentialItem(String contactId,String name){
       Confidential_Items__c testConfidentialItem = new Confidential_Items__c(
            Name = name,
            Contact__c = contactId
        );
        insert as system testConfidentialItem;
        return testConfidentialItem;
    }
    
    public static Campaign createCampaign(String name){
       Campaign testCampaign = new Campaign(
            Name = name,
            Event_Start_Date_Time__c = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')
        );
        insert as system testCampaign;
        return testCampaign;
    }
     
    public static CampaignMember createCampaignMember(String campaignId, String contactId){
      CampaignMember testCampaignMember = new CampaignMember(
            CampaignId =campaignId,
            ContactId = contactId,
            Status = 'Sent'
        );
        insert as system testCampaignMember;
        return testCampaignMember;
    }
    
    public static List<Contact> createMultipleContacts(Id aId, Integer numberOfContacts, Boolean doPersist) {
        Id rId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Assets.CONTACT_RECORDTYPE_BBRM).getRecordTypeId();
        List<Contact> contacts = new List<Contact>();
        for (Integer i=0;i<numberOfContacts;i++) {
            Integer mailingStateIndex = i>=STATES.size()?Math.mod(i,STATES.size()):i;
            Integer otherStateIndex = mailingStateIndex==STATES.size()-1?0:mailingStateIndex+1;
         contacts.add(new Contact(FirstName=generateRandomString(7), LastName=generateRandomString(12), AccountId = aId, Bio_Photo__c = 'Bio Photo'
                                , Bio_Confidential_Notes__c = 'Bio Confidential Notes'
                                , Bio_Description__c = 'Bio Description', RecordTypeId=rId
                                , MailingCountryCode=Assets.USA_Code, MailingStateCode=STATES[mailingStateIndex]
                                , OtherCountryCode=Assets.USA_Code, OtherStateCode=STATES[otherStateIndex]
                                ));
        }
        if (doPersist) {
			Database.DMLOptions dmlTest = new Database.DMLOptions();
			dmlTest.DuplicateRuleHeader.allowSave = true;
			Database.insert(contacts, dmlTest, AccessLevel.SYSTEM_MODE);
        }
        return contacts;
    }

    public static Fundraising_Project__c createFundraisingProject(){

		Map<String, Focus_Area__c> focusAreaMap = TestDataFactory.createFocusAreas(new List<String>{ 'Arts' });
		Foundation_Code__c rootFC = TestDataFactory.createRootFoundationCode();
		Foundation_Code__c educationCode = buildFoundationCode('Arts', 'Focus Area', rootFC.Id, focusAreaMap.get('Arts').Id);

        insert as system educationCode;

        Fundraising_Project__c fProject = new Fundraising_Project__c();
        fProject.Name = 'test FEI';
        fProject.Start_Date__c = System.today().addDays(-2);
        fProject.Status__c= 'Draft';
        fProject.Foundation_Coding__c = educationCode.Id;
        fProject.Currency__c = 'USD';
        insert as system fProject;

        Fundraising_Activity__c fa = new Fundraising_Activity__c();
        fa.Name = 'Test FA';
        fa.Fundraising_Effort_Id__c = fProject.Id;
        fa.Date__c = System.today().addDays(-2);
        fa.Type__c = 'Breakfast';
        insert as system fa;
        return fProject;
    }

	public static Pledge__c createPledge(
		Id orgId,
		Id fProjectId,
		Decimal amount
	) {
		Fundraising_Activity__c fa = [
			SELECT Id
			FROM Fundraising_Activity__c
			WITH SYSTEM_MODE
			LIMIT 1
		];
        Pledge__c pledge= new Pledge__c();
        pledge.Fundraising_Effort__c = fProjectId;
        pledge.Fundraising_Mode__c = fa.Id;
        pledge.Pledge_Start_Date__c = System.today();
        pledge.Pledge_Type__c = 'Cash';
        pledge.Status__c = 'Pledged';
        pledge.Organization__c = orgId;
        pledge.Pledge_Amount__c = amount;
        pledge.Report_Amount_USD__c = amount;
        insert as system pledge;
        return pledge;
    }

	public static Donor__c createDonor(
		Id orgId,
		Id contactId,
		Id pledgeId,
		Decimal amount,
		String type
	) {
        Donor__c donor = new Donor__c();
        donor.Contact__c = contactId;
        donor.Amount__c = amount;
        donor.Credit_Type__c = type;//Donor - Primary';
        donor.Organization__c = orgId;
        donor.Pledge__c = pledgeId;
        insert as system donor;
        return donor;
    }

    public static My_Notes__c createMyNotes(String subject,Id accountId){
        My_Notes__c myNotes = new My_Notes__c();
        myNotes.Organization__c = accountId;
        myNotes.Subject__c = subject;
        insert as system myNotes;
        return myNotes;
    }

    public static My_Notes__Share createMyNotesShare(Id recordId,Id userId){
        My_Notes__Share myNotesShare = new My_Notes__Share();
        myNotesShare.ParentId = recordId;
        myNotesShare.UserOrGroupId = userId;
        myNotesShare.RowCause = Schema.My_Notes__Share.RowCause.Manual;
        myNotesShare.AccessLevel = 'Read'; // Change this to 'Edit' if needed
        insert as system myNotesShare;
        system.debug('code check2:'+myNotesShare.Id);
        return myNotesShare;
    }

    public static User createUser(){
		return createUser('Code', 'Check', 'System Administrator');
	}

	public static User createUser(String firstName, String lastName) {
		return createUser(firstName, lastName, 'System Administrator');
	}

	public static User createUser(String firstName, String lastName, String profile) {
		Profile pf = [
			SELECT Id
			FROM Profile
			WHERE Name = :profile
			WITH SYSTEM_MODE
		];

        String orgId = UserInfo.getOrganizationId();
		String dateString = String.valueof(Datetime.now())
			.replace(' ', '')
			.replace(':', '')
			.replace('-', '');
		Integer randomNumber = Integer.valueOf(
			Math.rint(Math.random() * 1000000)
		);

        String uniqueName = orgId + dateString + randomNumber;

        User user = new User(
			firstname = firstName,
			lastName = lastName,
        email = uniqueName + '@test' + orgId + '.org',
        Username = uniqueName + '@test' + orgId + '.org',
        EmailEncodingKey = 'ISO-8859-1',
        Alias = uniqueName.substring(18, 23),
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        LanguageLocaleKey = 'en_US',
        ProfileId = pf.Id,
        Sharing_Team__c = 'System Administration'
		);
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert as system user;
		}
		return user;
	}
    
	public static User createUserWithPermissionSetGroup(String firstName, String lastName, String profileName, 
                                                        String permisionSetGroupName, String groupName) {

		Profile pf = [
			SELECT Id
			FROM Profile
			WHERE Name = :profileName
			WITH SYSTEM_MODE
		];

		String orgId = UserInfo.getOrganizationId();
		String dateString = String.valueof(Datetime.now())
			.replace(' ', '')
			.replace(':', '')
			.replace('-', '');
		Integer randomNumber = Integer.valueOf(
			Math.rint(Math.random() * 1000000)
        );

		String uniqueName = orgId + dateString + randomNumber;

		User user = new User(
			firstname = firstName,
			lastName = lastName,
			email = uniqueName + '@test' + orgId + '.org',
			Username = uniqueName + '@test' + orgId + '.org',
			EmailEncodingKey = 'ISO-8859-1',
			Alias = uniqueName.substring(18, 23),
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			LanguageLocaleKey = 'en_US',
			ProfileId = pf.Id,
			Sharing_Team__c = 'System Administration'
		);
        System.runAs ( new User(Id = UserInfo.getUserId()) ){
            insert as system user;
			if(!String.isBlank(permisionSetGroupName)) {
				PermissionSetGroup permissionSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :permisionSetGroupName WITH SYSTEM_MODE];
				if(Test.isRunningTest()) {
					Test.calculatePermissionSetGroup(permissionSetGroup.Id);
				}
				insert as system new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetGroupId  = permissionSetGroup.Id);
				List<PermissionSetAssignment> psa = [Select Id, PermissionSetGroupId, AssigneeId from PermissionSetAssignment where AssigneeId = :user.Id WITH SYSTEM_MODE];
        }
			if(!String.isBlank(groupName)) {
				Group grp = new Group(Name = groupName);       
        		insert as system grp;
        		GroupMember groupMember= new GroupMember(GroupId = grp.Id, UserOrGroupId = user.Id);
            	insert as system groupMember;
			}
		}
        return user;
    }

    public static Foundation_Code__c createFoundationCode(String name) {
		Foundation_Code__c foundationCode = new Foundation_Code__c(
			Name = name,
			Foundation_Code__c = name,
			Enabled_For_Associations_Interactions__c = true,
			Enabled_for_Grants__c = true,
			Enabled_for_Fundraising__c = true
		);
		return foundationCode;
		}

	public static Foundation_Code__c createFoundationCode(
		String name,
		Foundation_Code__c parentCode
	) {
		Foundation_Code__c foundationCode = new Foundation_Code__c(
			Name = name,
			Foundation_Code__c = name,
			Parent__c = parentCode.Id,
			Enabled_For_Associations_Interactions__c = true,
			Enabled_for_Grants__c = true,
			Enabled_for_Fundraising__c = true
		);
		return foundationCode;
		}

	public static Foundation_Code__c createFoundationCode(
		String name,
		String type
	) {
		Foundation_Code__c foundationCode = new Foundation_Code__c(
			Name = name,
			Foundation_Code__c = name,
			Type__c = type,
			Enabled_For_Associations_Interactions__c = true,
			Enabled_for_Grants__c = true,
			Enabled_for_Fundraising__c = true
		);
		return foundationCode;
	}

	public static Foundation_Code__c createFoundationCode(
		String name,
		String type,
		Foundation_Code__c parentCode
	) {
		Foundation_Code__c foundationCode = new Foundation_Code__c(
			Name = name,
			Foundation_Code__c = name,
			Parent__c = parentCode.Id,
			Type__c = type,
			Enabled_For_Associations_Interactions__c = true,
			Enabled_for_Grants__c = true,
			Enabled_for_Fundraising__c = true
		);
        return foundationCode;
    }

    public static Foundation_Code__c createInitiativeFoundationCode() {
		Foundation_Code__c foundationCode = new Foundation_Code__c(
			Name = 'Initiatives',
			Foundation_Code__c = 'Initiatives',
			Type__c = 'Initiative Root'
		);
		insert as system foundationCode;
		return foundationCode;
	}

    public static Foundation_Code__c createInitiativeFoundationCode(String name) {
		Foundation_Code__c foundationCode = new Foundation_Code__c(
			Name = 'name',
			Foundation_Code__c = 'Initiatives',
			Type__c = 'Initiative Root'
		);
        insert as system foundationCode;
        return foundationCode;
    }

	public static Foundation_Code__c createChildFoundationCode(
		Foundation_Code__c fc,
		String name,
		String status,
		String type
	) {
		Foundation_Code__c foundationCode = new Foundation_Code__c(
			Name = name,
			Foundation_Code__c = name,
			Parent__c = fc.Id,
			Status__c = status,
			Type__c = type,
			Enabled_for_Fundraising__c = true
		);
        return foundationCode;
    }

	public static Organization_Annual_Metrics__c createOrganizationAnnualMetrics(
		String year
	) {
		Date censusDate = Date.newInstance(2024, 1, 1);
		Organization_Annual_Metrics__c oam = new Organization_Annual_Metrics__c(
			Year__c = year,
			Annual_Website_Visits__c = 33,
			Number_of_Organization_Memberships__c = 22,
			Organization_Annual_Attendance__c = 11,
			Population__c = 44,
			Population_Census_Data_As_of__c = censusDate,
			Population_Minority_is_Majority__c = 'Yes',
			Population_Non_Hispanic_white__c = 45,
			Region__c = 'Pacific'
		);
        return oam;
    }

  public static Geo_Area__c createGeoArea(){
        // Retrieve the Record Type for Geo_Area__c named 'Continent'
		RecordType continentRecordType = [
			SELECT Id
			FROM RecordType
			WHERE SObjectType = 'Geo_Area__c' AND Name = 'Continent'
			WITH SYSTEM_MODE
			LIMIT 1
		];
        // Create a Geo Area record with the 'Continent' record type and additional fields
        Geo_Area__c geoArea = new Geo_Area__c(
        Name = 'Test Continent',
        RecordTypeId = continentRecordType.Id,
        BP_Active__c = true,
        BP_Uses_States__c = true,
        Geo_Name__c = 'Test Geo Name',
        Geo_Code__c = 'TC001'
        );
        return geoArea;
    }

	public static Agreement__c createAgreement(
		String aggName,
		String pledgeId,
		String agreementType,
		String Status
	) {
        Agreement__c agg = new Agreement__c();
        agg.Pledge__c = pledgeId;
        agg.Agreement_Type__c = agreementType;
        agg.Name = aggName ;
        agg.Status__c = Status;
        insert as system agg;
        return agg;
    }

	public static ContentDocumentLink createFile(
		String fileName,
		String entityId
	) {
        Blob blobContent = EncodingUtil.base64Decode( 'Testing File' );
        ContentVersion objCV = new ContentVersion(
        Title = fileName,
        PathOnClient = 'test.txt',
        VersionData = blobContent
        );
        insert as system objCV;
        objCV = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id =: objCV.Id
		WITH SYSTEM_MODE
        ];
        ContentDocumentLink objCDL = new ContentDocumentLink(
        ContentDocumentId = objCV.ContentDocumentId,
        LinkedEntityId = entityId,
        Visibility = 'AllUsers'
        );
        insert as system objCDL;
        return objCDL;
    }

     public static List<Campaign> createCampaigns(Integer numberOfCampaigns, String recordTypeName, Boolean doPersist) {
        Id rId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
        List<Campaign> campaigns = new List<Campaign>();
        for (Integer i=0;i<numberOfCampaigns;i++) {
            campaigns.add(new Campaign(Name='Test Campaign ' + i, RecordTypeId=rId));
    }
        if (doPersist) {
			Database.insert(campaigns, AccessLevel.SYSTEM_MODE);
    }
        return campaigns;
    }

    public static List<CampaignMember> createCampaignMembers(Campaign campaign, List<Contact> contacts, Boolean doPersist) {

        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for (Integer i=0;i<contacts.size();i++) {

            campaignMembers.add(new CampaignMember(CampaignId = campaign.Id, ContactId = contacts[i].Id));
    }
        if (doPersist) {
			Database.insert(campaignMembers, AccessLevel.SYSTEM_MODE);
    }
        return campaignMembers;
    }

    public static Data_Load__c createDataLoad() {

        Data_Load__c dataLoad = new Data_Load__c(Name__c = 'Data Load Test Name');
        insert as system dataLoad;
        return dataLoad;
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
    }
        return randStr; 
    }

    public static Map<String, Geo_Area__c> createGeoHierarchy() {
        // Get RecordTypeId without querying
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        Id stateRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('State').getRecordTypeId();
        Id countryRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('Country').getRecordTypeId();
        Id continentRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('Continent').getRecordTypeId();
        // Step 1: Create Continent
        Geo_Area__c continent = new Geo_Area__c(
            Name = 'Test Continent',
            RecordTypeId = continentRecordTypeId,
            BP_Active__c = True,
            Geo_Name__c = 'Test Continent'
        );
        insert as system continent;

        // Step 2: Create Country
        Geo_Area__c country = new Geo_Area__c(
            Name = 'Test Country',
            RecordTypeId = countryRecordTypeId,
            BP_Active__c = True,
            Geo_Name__c = 'Test Country',
            Parent__c = continent.Id
        );
        insert as system country;

        // Step 3: Create State
        Geo_Area__c state = new Geo_Area__c(
            Name = 'Test State',
            RecordTypeId = stateRecordTypeId,
            BP_Active__c = True,
            Geo_Name__c = 'Test State',
            Parent__c = country.Id
        );
        insert as system state;

        // Step 4: Create City
        Geo_Area__c city = new Geo_Area__c(
            Name = 'Test City',
            RecordTypeId = cityRecordTypeId,
            BP_Active__c = True,
            Geo_Name__c = 'Test City',
            Parent__c = state.Id
        );
        insert as system city;
        Geo_Area_Focus_Area__c gfa = new Geo_Area_Focus_Area__c();
        gfa.Geo_Area__c = city.Id;
        insert as system gfa;

        return new Map<String, Geo_Area__c>{
            'Continent' => continent,
                'Country' => country,
                'State' => state,
                'City' => city
                };
    }

    public static Geo_Area__c createGeoAreaByRecordType(String recordType, String name) {
        Id recordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId();
        Geo_Area__c geoArea = new Geo_Area__c(
            Name = name,
            RecordTypeId = recordTypeId,
            BP_Active__c = True,
            Geo_Name__c = name,
            Coordinates__latitude__s = 0.000,
            Coordinates__longitude__s = 0.0001
        );

        return geoArea;
    }

    public static Geo_Area_Focus_Area__c createGAFA() {
        Id recordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('Continent').getRecordTypeId();
        Geo_Area__c geoArea = new Geo_Area__c(
            Name = 'Test Continent',
            RecordTypeId = recordTypeId,
            BP_Active__c = True,
            Geo_Name__c = 'Test Continent'
        );

        insert as system geoArea;

        Geo_Area_Focus_Area__c gafa = new Geo_Area_Focus_Area__c (
        	Geo_Area__c = geoArea.Id
        );

        return gafa;
    }

    public static Bloomberg_Office__c createOffice () {
        return new Bloomberg_Office__c (
        	Name = 'NYC',
            Coordinates__latitude__s = 0.000,
            Coordinates__longitude__s = 0.0001
        );
    }

    public static Org_Geo_Area__c createOrgGeoAreaByType (String orgGeoAreaType, Id orgId, Id geoAreaId) {
        return new Org_Geo_Area__c (
            Type__c = orgGeoAreaType,
            Organization__c = orgId,
            Geo_Area__c = geoAreaId
        );
    }
    
	public static File_Group__c createFileGroup(
		String objectName,
		String category,
		Id recordId
	) {
		File_Group__c fileGroup = new File_Group__c();
		fileGroup.Object_Type__c = objectName;
		fileGroup.Category__c = category;
		fileGroup.Parent_Initiative__c = recordId;
		insert as system fileGroup;
		return fileGroup;
	}

	public static File_Link__c createFileLink(
		String linkName,
		String linkURL,
		String fileGroupId
	) {
		File_Link__c fileLink = new File_Link__c();
		fileLink.Name = linkName;
		fileLink.Link_URL__c = linkURL;
		fileLink.File_Group__c = fileGroupId;
		insert as system fileLink;
		return fileLink;
	}
    
    /**
	 * Description : Method to crate Amentment Initative record.
	 * Parameters  : IM_Initiative__c initiativeOf
	 * Return Type : IM_Initiative__c
	 */
	public static IM_Initiative__c buildAmendmentInitiative(IM_Initiative__c initiativeOf) {


		IM_Initiative__c amendmentInitiative = new IM_Initiative__c();
		amendmentInitiative.Name = initiativeOf.Name + '0';
		amendmentInitiative.Initiative_Type__c = 'Amendment';
		amendmentInitiative.Status__c = 'Draft';
		amendmentInitiative.Amendment_Number__c = 0;
		amendmentInitiative.Amendment_of__c = initiativeOf.Id;
		Team__c team = TestDataFactory.createTeam('Test Team');
		amendmentInitiative.Team__c = team.Id;

		amendmentInitiative.RecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get(Assets.AMENDMENT).getRecordTypeId();
		//insert amendmentInitiative;


		return amendmentInitiative;
	}

	/**
	 * Description : Method to crate IM_Grant__c record.
	 * Return Type : IM_Grant__c
	 */
	public static IM_Grant__c createIMGrant() {
		IM_Grant__c imGrant = new IM_Grant__c();

		insert as system imGrant;
		return imGrant;
	}
    
    /**
	 * Description : Method to create Approval records.
	 * Return Type : IM_Approval__c
	 */
	public static IM_Approval__c buildApproval(String approver, Date approvalDate, Id initiativeId) {
		IM_Approval__c approval = new IM_Approval__c();
		approval.Approver__c = approver;
		approval.Approval_Date__c = approvalDate;
		approval.Initiative__c = initiativeId;
		return approval;
	}
    
	public static IM_Review__c createReview(String type) {
		IM_Review__c review = new IM_Review__c();
		review.Type__c = type;
		return review;
	}

	public static IM_Budget__c createBudget(String name, Id initiativeId) {
		return createBudget(name, initiativeId, 'Draft');
	}
    
    public static IM_Budget__c createBudget(String name, Id initiativeId, String status) {
		IM_Budget__c budget = new IM_Budget__c();
		budget.Initiative__c = initiativeId;
		budget.Budget_Term_months__c = 2;
		budget.Budget_Categories__c = 'Component';
		budget.Name = name;
		//budget.Status__c = 'Pending Approval';
		budget.Status__c = status;
		budget.Proposed_Amount__c = 20000;
		budget.Version__c = 1;
		insert as system budget;
		return budget;
	}

	public static IM_Budget__c createBudget(Id initiativeId) {
		return createBudget('Test Budget', initiativeId, 'Draft');
	}

	public static IM_Budget__c createBudgetWithCat(
		Id initiativeId,
		String category
	) {
		IM_Budget__c budget = new IM_Budget__c();
		budget.Initiative__c = initiativeId;
		budget.Budget_Term_months__c = 2;
		budget.Budget_Categories__c = category;
		budget.Name = 'Test Budget With Category';
		budget.Status__c = 'Pending Approval';
		budget.Proposed_Amount__c = 20000;
		budget.Version__c = 1;
		if (category == '') {
			budget.Type_of_Work__c = true;
		}
		insert as system budget;
		return budget;
	}

	public static IM_Budget__c createBudgetTest(Id initiativeId) {
		IM_Budget__c budget = new IM_Budget__c();
		budget.Initiative__c = initiativeId;
		budget.Budget_Term_months__c = 2;
		budget.Budget_Categories__c = 'Component';
		budget.Name = 'Test';
		budget.Status__c = 'Pending Approval';
		budget.Proposed_Amount__c = 20000;
		budget.Version__c = 1;
		insert as system budget;
		return budget;
	}

	public static Template__c createTemplate(String contentdocId) {
		Template__c templateRec = new Template__c();
		templateRec.Active__c = true;
		templateRec.File_Id__c = contentdocId;
		templateRec.Identifier__c = 'IM_IB_Edit_By_Component_v1';
		templateRec.Metadata__c = '{"Budget": {"ColumnMapping": {"Component": "B","SubComponent": "C","Geography": "D","Partner": "E","UniqueIdentifier": "F","PartnerRole": "G","Payee": "H","SubPartner": "I","SubPartnerType": "J","Duration": "K","TypeOfWork": "L","Description": "M","Year1": "N","Year2": "O","Year3": "P","Year4": "Q","Year5": "R","Year6": "S","Year7": "T","Year8": "U","Year9": "V","Year10": "W","TotalAmount": "X","RunRate": "Y","Notes": "Z"},"DataRowStartIndex": 4,"HeadersIndex": 3},"BudgetParameters": {"ColumnMapping": {"Component": "B","ComponentTotal": "C","SubComponent": "E","SubComponentTotal": "F","Geography": "H","GeographyTotal": "I","Partner": "K","PartnerTotal": "L","SubPartner": "N","SubPartnerTotal": "O","Payee": "Q","PayeeTotal": "R"},"DataRowStartIndex": 4,"HeadersIndex": 2}}';
		insert as system templateRec;
		return templateRec;
	}

	public static Template__c createTemplateForViews(String contentdocId) {
		Template__c templateRec = new Template__c();
		templateRec.Active__c = true;
		templateRec.File_Id__c = contentdocId;
		templateRec.Identifier__c = 'IM_IB_Budget_Views_v1';
		String metadata =
			'{"Tab1": {"ColumnMapping": {"Component__c": "B","SubComponent__c": "C","Geography__c": "D",' +
			'"Partner__c": "E","Partner_Role__c": "F","Type_of_Work__c": "G","Total_Amount__c":"R"},"PeriodColumnMapping": {' +
			'"Period_1_Amount__c": "H","Period_2_Amount__c": "I","Period_3_Amount__c": "J","Period_4_Amount__c": "K",' +
			'"Period_5_Amount__c": "L","Period_6_Amount__c": "M","Period_7_Amount__c": "N",' +
			'"Period_8_Amount__c": "O","Period_9_Amount__c": "P","Period_10_Amount__c": "Q"},"SkipColumnDataMapping": {"Total_Amount__c":"R"},"DataRowStartIndex": 4,"HeadersIndex": 3}}';
		templateRec.Metadata__c = metadata;
		insert as system templateRec;
		return templateRec;
	}

	public static ContentVersion createContentVersion() {
		ContentVersion version = new ContentVersion(
			Title = 'File Name',
			PathOnClient = 'sample.jpg',
			VersionData = EncodingUtil.base64Decode('AA=='),
			Origin = 'H'
		);
		insert as system version;
		return version;
	}

	public static IM_Budget_Period__c createBudgetPeriods(Id budgetId) {
		IM_Budget_Period__c budgetPeriod = new IM_Budget_Period__c();
		budgetPeriod.Budget__c = budgetId;
		budgetPeriod.Period__c = 1;
		budgetPeriod.Period_Label__c = 'Test Period';
		budgetPeriod.Period_Start_Date__c = System.today();
		budgetPeriod.Period_End_Date__c = System.today() + 12;
		insert as system budgetPeriod;
		return budgetPeriod;
	}

	public static List<IM_Budget_Period__c> createBudgetPeriods(
		Id budgetId,
		Integer numberOfPeriods
	) {
		List<IM_Budget_Period__c> budgetPeriods = new List<IM_Budget_Period__c>();
		for (Integer i = 0; i < numberOfPeriods; i++) {
			IM_Budget_Period__c budgetPeriod = new IM_Budget_Period__c();
			budgetPeriod.Budget__c = budgetId;
			budgetPeriod.Period__c = i + 1;
			budgetPeriod.Period_Label__c = 'Period ' + (i + 1);
			budgetPeriods.add(budgetPeriod);
		}
		insert as system budgetPeriods;
		return budgetPeriods;
	}

	public static IM_Geography__c createGeography(Id budgetId) {
		IM_Geography__c geography = new IM_Geography__c();
		geography.Budget__c = budgetId;
		geography.Name = 'Test Geography';
		insert as system geography;
		return geography;
	}

	public static IM_Budget_Org__c createBudgetOrg(Id budgetId, Id orgId) {
		IM_Budget_Org__c budgetOrg = new IM_Budget_Org__c();
		budgetOrg.Budget__c = budgetId;
		budgetOrg.Organization__c = orgId;
		budgetOrg.Type__c = 'Partner';
		insert as system budgetOrg;
		return budgetOrg;
	}

	public static IM_Budget_Row__c createBudgetRow(Id budgetId) {
		IM_Budget_Row__c budgetRow = new IM_Budget_Row__c();
		budgetRow.Budget__c = budgetId;
		budgetRow.Description__c = 'None';
		budgetRow.Duration_months__c = 12;
		budgetRow.Notes__c = 'None';
		budgetRow.Partner_Role__c = 'Evaluation';
		budgetRow.Sub_Partner_Type__c = 'SubContract';
		budgetRow.Type_of_Work__c = 'Charitable';
		budgetRow.Unique_Identifier__c = '1234';
		budgetRow.Period_1_Amount__c = 10000;
		budgetRow.Period_2_Amount__c = 10000;
		budgetRow.Period_3_Amount__c = 10000;
		insert as system budgetRow;
		return budgetRow;
	}

	public static IM_Budget_Row__c createBudgetRow(
		Id budgetId,
		Id budgetGrantId
	) {
		IM_Budget_Row__c budgetRow = new IM_Budget_Row__c();
		budgetRow.Budget__c = budgetId;
		budgetRow.Description__c = 'None';
		budgetRow.Duration_months__c = 12;
		budgetRow.Notes__c = 'None';
		budgetRow.Partner_Role__c = 'Evaluation';
		budgetRow.Sub_Partner_Type__c = 'SubContract';
		budgetRow.Type_of_Work__c = 'Charitable';
		budgetRow.Unique_Identifier__c = '1234';
		budgetRow.Budget_Grant__c = budgetGrantId;
		insert as system budgetRow;
		return budgetRow;
	}

	public static IM_Budget_Row__c createBudgetRowWithData(
		Id budgetId,
		Id componentId,
		Id subComponentId,
		Id partnerId,
		Id geographyId
	) {
		IM_Budget_Row__c budgetRow = new IM_Budget_Row__c();
		budgetRow.Budget__c = budgetId;
		budgetRow.Component__c = componentId;
		budgetRow.SubComponent__c = subComponentId;
		budgetRow.Geography__c = geographyId;
		budgetRow.Partner__c = partnerId;
		budgetRow.Description__c = 'None';
		budgetRow.Duration_months__c = 12;
		budgetRow.Notes__c = 'None';
		budgetRow.Partner_Role__c = 'Evaluation';
		budgetRow.Sub_Partner_Type__c = 'SubContract';
		budgetRow.Type_of_Work__c = 'Charitable';
		budgetRow.Unique_Identifier__c = '1234';
		budgetRow.Period_1_Amount__c = 100000;
		budgetRow.Period_2_Amount__c = 100000;
		insert as system budgetRow;
		return budgetRow;
	}

	public static IM_Budget_Grant__c createBudgetGrant(
		Id budgetId,
		Id budgetOrgId,
		Id imGrantId
	) {
		IM_Budget_Grant__c budgetGrant = new IM_Budget_Grant__c();

		budgetGrant.Budget__c = budgetId;
		budgetGrant.Budget_Org__c = budgetOrgId;
		budgetGrant.IM_Grant__c = imGrantId;
		insert as system budgetGrant;
		return budgetGrant;
	}

	public static IM_Budget_Grant_Period__c createBudgetGrantPeriod(
		Id budgetPeriodId,
		Id budgetGrantId
	) {
		IM_Budget_Grant_Period__c budgetGrantPeriod = new IM_Budget_Grant_Period__c();
		budgetGrantPeriod.Period__c = budgetPeriodId;
		budgetGrantPeriod.Budget_Grant__c = budgetGrantId;
		insert as system budgetGrantPeriod;
		return budgetGrantPeriod;
	}

	public static IM_Component__c createComponent(Id budgetId) {
		IM_Component__c component = new IM_Component__c();
		component.Budget__c = budgetId;
		component.Name = 'Test Component';
		component.Type__c = 'Component';
		insert as system component;
		return component;
	}

	public static IM_Component__c createSubComponent(
		Id budgetId,
		Id parentCompId
	) {
		IM_Component__c subComponent = new IM_Component__c();
		subComponent.Budget__c = budgetId;
		subComponent.Parent_Component__c = parentCompId;
		subComponent.Type__c = 'SubComponent';
		subComponent.Name = 'Test SubComponent';
		insert as system subComponent;
		return subComponent;
	}

    public static Team__c createTeam(String name) {
		Team__c team = new Team__c(Name = name, Enabled_for_BRM__c = true);
        insert as system team;
        return team;
    }

	public static Team__c createTeamWithFocusArea(String name, Id focusAreaId) {
		Team__c team = new Team__c(Name = name, Focus_Area__c = focusAreaId, Enabled_for_BRM__c = true);
		insert as system team;
		return team;
	}

	public static Interaction_Participant__c createInteractionParticipant(Id highlightId, String participantType) {
        Account org = getOrg('Submit Metrics Org');
        insert as system org;
        Interaction_Participant__c participant = new Interaction_Participant__c(
            Highlight__c = highlightId,
            Type__c = participantType,
            Organization__c = org.Id
        );
        insert as system participant;
        return participant;
    }

    public static Metric__c createMetric(String name, Id teamId, String unit, Decimal orderNumber) {
        Metric__c metric = new Metric__c(
            Name = name,
            Team__c = teamId,
            Unit__c = unit,
            Order__c = orderNumber
        );
        insert as system metric;
        return metric;
    }

    public static List<Metric__c> createMetrics(Integer numberOfMetrics, Id teamId, Boolean doPersist) {
        List<Metric__c> metrics = new List<Metric__c>();
        for (Integer i = 0; i < numberOfMetrics; i++) {
            metrics.add(new Metric__c(
                Name = 'Test Metric ' + i,
                Team__c = teamId,
                Unit__c = 'Count',
                Order__c = i + 1
            ));
        }
        if (doPersist) {
			Database.insert(metrics, AccessLevel.SYSTEM_MODE);
        }
        return metrics;
    }

    public static Metric_Value__c createMetricValue(Id metricId, Id highlightId, Decimal value, Date valueDate) {
        Metric_Value__c metricValue = new Metric_Value__c(
            Metric__c = metricId,
            Highlight_Interaction__c = highlightId,
            Value__c = value,
            Date__c = valueDate,
            Notes__c = 'Test Notes'
        );
        insert as system metricValue;
        return metricValue;
    }

    public static Metric_Value__c createLatestMetricValue(Id metricId, Id highlightId, Decimal value, Date valueDate) {
        Metric_Value__c metricValue = createMetricValue(metricId, highlightId, value, valueDate);
		update as system new Metric__c(Id = metricId, Latest_Metric_Value__c = metricValue.Id);
        return metricValue;
    }

    public static Segment__c createSegment(String name) {
        Segment__c segment = new Segment__c(Name = name);
        return segment;
    }

    public static Segment_Team__c createSegmentTeam(
        String teamId,
		String segmentId
	) {
        Segment_Team__c segmentTeam = new Segment_Team__c(
            Team__c = teamId,
            Segment__c = segmentId
        );
        return segmentTeam;
    }
    
	public static Focus_Area__c createFocusArea(String name) {
		Focus_Area__c focusArea = new Focus_Area__c(Name = name);
		return focusArea;
	}

	public static IM_Strategic_Locations__c createStrategicLocation(
		Id initiativeId,
		Id geoAreaId
	) {
		IM_Strategic_Locations__c strategicLocation = new IM_Strategic_Locations__c();
		strategicLocation.Initiative__c = initiativeId;
		strategicLocation.Geo_Area__c = geoAreaId;
		insert as system strategicLocation;
		return strategicLocation;
	}

	public static IM_Announcement__c createAnnouncement(
		IM_Initiative__c initiative
	) {
		IM_Announcement__c announcement = new IM_Announcement__c(
			Initiative__c = initiative.Id,
			Announced_Amount__c = 10000,
			Announcement_Notes__c = 'Test Announcement'
		);

		return announcement;
	}

	public static IM_Funding_Source__c createFundingPartner(Id budgetId) {
		IM_Funding_Source__c fundingPartner = new IM_Funding_Source__c();
		fundingPartner.Budget__c = budgetId;
		fundingPartner.Partner__c = 'Gates';
		fundingPartner.Amount__c = 50000;

		insert as system fundingPartner;
		return fundingPartner;
	}

	public static Currency__c createCurrency(String name) {
		Currency__c currRecord = new Currency__c();
		currRecord.Currency_Code__c = 'USD';
		currRecord.Name = name;
		currRecord.Bgive_Id__c = '1234';
		currRecord.IM_Default__c = false;
		insert as system currRecord;
		return currRecord;
	}

	public static Fund__c createFund(String name) {
		Fund__c fund = new Fund__c();
		fund.Bgive_Api_Name__c = name;
		fund.Name = name;
		insert as system fund;
		return fund;
	}
    
    public static IM_Initiative__c createParentInitiatives(String name) {
		return createParentInitiatives(name, 'Arts');
	}

	public static IM_Initiative__c createParentInitiatives(String name, String teamName) {
		Map<String, Team__c> teams = createTeams();

		IM_Initiative__c initiative = new IM_Initiative__c();
		initiative.Name = name;
		initiative.Initiative_Type__c = 'Parent';
		initiative.Team__c = teams.get(teamName)?.Id;
		initiative.RecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get(Assets.PARENT_INITIATIVE).getRecordTypeId();
		insert as system initiative;
		return initiative;
	}

	public static IM_Initiative__c createBudgetedInitiative(String name, String type) {
		return createBudgetedInitiative(name, type, null);
	}

	/**
	 * Description : Method to crate Budgeted Initative record.
	 * Parameters  : String name, String type, String renewalOf
	 * Return Type : IM_Initiative__c
	 */
	public static IM_Initiative__c createBudgetedInitiative(String name, String type, IM_Initiative__c renewalOf) {
		// Create Base Data
		Map<String, Team__c> teams = createTeams();
		IM_Initiative__c pInitiaitve = createParentInitiatives(name);
		IM_Initiative__c budgetedInitiative = new IM_Initiative__c();
		budgetedInitiative.Name = name + ' 1.0';
		budgetedInitiative.Initiative_Type__c = type;
		budgetedInitiative.Status__c = 'Draft';
		budgetedInitiative.Amendment_Number__c = 0;
		budgetedInitiative.Team__c = teams.get('Arts')?.Id;
		budgetedInitiative.Parent_Initiative__c = pInitiaitve.Id;
		budgetedInitiative.Start_Date__c = System.today();
		budgetedInitiative.End_Date__c = System.today().addMonths(36);
		if (renewalOf != null) {
			budgetedInitiative.Renewal_of__c = renewalOf.Id;
		}
		budgetedInitiative.RecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get(Assets.BUDGET_INITIATIVE).getRecordTypeId();
		insert as system budgetedInitiative;
		return budgetedInitiative;
	}
	
	public static IM_Budget__c createBudget(String name, String initiativeId, String category, String status) {
		IM_Budget__c budget = new IM_Budget__c();
		budget.Initiative__c = initiativeId;
		budget.Budget_Term_months__c = 36;
		budget.Budget_Categories__c = category;
		budget.Name = name;
		budget.Status__c = status;
		budget.Proposed_Amount__c = 2000000;
		budget.Version__c = 1;
		budget.Partner_Partner_Role__c = true;
		budget.Type_of_Work__c = true;

		insert as system budget;
		return budget;
	}

	public static List<IM_Budget_Row__c> createBudgetRows(String budgetId, String orgId) {
		IM_Budget_Org__c budgetOrg = createBudgetOrg(budgetId, orgId);
		List<IM_Budget_Row__c> budgetRows = new List<IM_Budget_Row__c>();

		IM_Budget_Row__c budgetRow = new IM_Budget_Row__c();
		budgetRow.Budget__c = budgetId;
		/*budgetRow.Component__c = componentId;
		budgetRow.SubComponent__c = subComponentId;
		budgetRow.Geography__c = geographyId;*/
		budgetRow.Partner__c = budgetOrg.Id;
		budgetRow.Description__c = 'None';
		budgetRow.Duration_months__c = 12;
		budgetRow.Notes__c = 'None';
		budgetRow.Partner_Role__c = 'Evaluation';
		budgetRow.Sub_Partner_Type__c = 'SubContract';
		budgetRow.Type_of_Work__c = 'Charitable';
		budgetRow.Unique_Identifier__c = 'G-1';
		budgetRow.Period_1_Amount__c = 500000;
		budgetRow.Period_2_Amount__c = 500000;

		budgetRows.add(budgetRow);

		budgetRow = new IM_Budget_Row__c();
		budgetRow.Budget__c = budgetId;
		budgetRow.Partner__c = budgetOrg.Id;
		budgetRow.Description__c = 'None';
		budgetRow.Duration_months__c = 12;
		budgetRow.Notes__c = 'None';
		budgetRow.Partner_Role__c = 'Evaluation';
		budgetRow.Sub_Partner_Type__c = 'SubContract';
		budgetRow.Type_of_Work__c = 'Charitable';
		budgetRow.Unique_Identifier__c = 'G-2';
		budgetRow.Period_1_Amount__c = 500000;
		budgetRow.Period_2_Amount__c = 500000;

		budgetRows.add(budgetRow);
		insert as system budgetRows;
		return budgetRows;
	}

	/**
	 * Description : Method to create base data required for Initiative tests.
	 * 				 Creates Teams, Focus Areas, Foundation Codes, and Segments.
	 * Return Type : void
	 */
	public static void createInitiativeBaseData() {
		Map<String, Team__c> teams = createTeams();
		List<Focus_Area__c> focusAreas = [SELECT Id, Name FROM Focus_Area__c WHERE Name IN :teams.keySet() WITH SYSTEM_MODE];
		Foundation_Code__c rootFoundationCode = createRootFoundationCode();
		List<Foundation_Code__c> foundationCodes = new List<Foundation_Code__c>();
		for (Focus_Area__c focusArea : focusAreas) {
			foundationCodes.add(buildFoundationCode(focusArea.Name, 'Focus Area', rootFoundationCode.Id, focusArea.Id));
		}
		insert as system foundationCodes;
		createSegments(teams.values());
	}

	public static Map<String, Team__c> createTeams() {
		Map<String, Team__c> teamMap = new Map<String, Team__c>();
		List<Team__c> tList = [SELECT Id, Name, Focus_Area__c FROM Team__c WITH SYSTEM_MODE];
		if (!tList.isEmpty()) {
			for (Team__c t : tList) {
				teamMap.put(t.Name, t);
			}
			return teamMap;
		}

		Map<String, String> focusAreaTeamMap = new Map<String, String>();
		focusAreaTeamMap.put('Arts', 'Arts');
		focusAreaTeamMap.put('Education', 'Education');
		focusAreaTeamMap.put('Environment', 'Environment');
		focusAreaTeamMap.put('Government Innovation', 'Government Innovation');
		focusAreaTeamMap.put('Founder\'s Project', 'Founder\'s Project');
		focusAreaTeamMap.put('Greenwood', 'Founder\'s Project');

		Map<String, Focus_Area__c> focusAreaMap = createFocusAreas(focusAreaTeamMap.values());

		for (String t : focusAreaTeamMap.keySet()) {
			String focusAreaName = focusAreaTeamMap.get(t);
			teamMap.put(t, new Team__c(Name = t, Focus_Area__c = focusAreaMap.get(focusAreaName)?.Id));
		}
		insert as system teamMap.values();
		return teamMap;
	}

	public static Map<String, Focus_Area__c> createFocusAreas(List<String> focusAreas) {
		Map<String, Focus_Area__c> focusAreaMap = new Map<String, Focus_Area__c>();
		List<Focus_Area__c> fList = [SELECT Id, Name FROM Focus_Area__c WHERE Name IN :focusAreas WITH SYSTEM_MODE];
		if (!fList.isEmpty()) {
			for (Focus_Area__c f : fList) {
				focusAreaMap.put(f.Name, f);
			}
			return focusAreaMap;
		}

		for (String f : focusAreas) {
			focusAreaMap.put(f, new Focus_Area__c(Name = f));
		}
		insert as system focusAreaMap.values();
		return focusAreaMap;
	}

	public static List<Segment__c> createSegments(List<Team__c> teams) {
		List<Segment__c> segments = [SELECT Id FROM Segment__c WITH SYSTEM_MODE];
		if (!segments.isEmpty())
			return segments;
		segments = new List<Segment__c>();

		segments.add(new Segment__c(Name = Assets.BFF));
		segments.add(new Segment__c(Name = 'Personal'));
		insert as system segments;

		List<Segment_Team__c> segmentTeams = new List<Segment_Team__c>();
		segmentTeams.add(createSegmentTeam(teams[0].Id, segments[0].Id));
		segmentTeams.add(createSegmentTeam(teams[0].Id, segments[1].Id));

		insert as system segmentTeams;
		return segments;
	}

	public static Foundation_Code__c createRootFoundationCode() {
		Foundation_Code__c foundationCode = new Foundation_Code__c(Name = 'Initiatives', Foundation_Code__c = 'Initiatives', Type__c = 'Initiative Root');
		insert as system foundationCode;
		return foundationCode;
	}

	public static Foundation_Code__c buildFoundationCode(String name, String type, String parentId, String focusAreaId) {
		Foundation_Code__c foundationCode = new Foundation_Code__c(
			Name = name,
			Foundation_Code__c = name,
			Type__c = type,
			Enabled_For_Associations_Interactions__c = true,
			Enabled_for_Grants__c = true,
			Enabled_for_Fundraising__c = true,
			Focus_Area__c = focusAreaId,
			Parent__c = parentId
		);
		return foundationCode;
	}
    
	public static DashboardText__c createDashboardText(
        String link,
        Decimal count,
        Boolean doPersist
    ) {
        DashboardText__c dash = new DashboardText__c(
            Link__c = link,
            Count__c = count
        );
        if (doPersist) {
            insert as system dash;
        }
        return dash;
    }
    
    public static Lists_Tags_Tool_Search__c createListTagSavedSearch() {
        Lists_Tags_Tool_Search__c savedSearch = new Lists_Tags_Tool_Search__c ();
        savedSearch.Name = 'Test Search';
        savedSearch.Available_Lists__c = '701V9000027m9pUIAQ';
        savedSearch.List_IDs__c = '701V9000027m9pUIAQ';
        savedSearch.Selected_Additional_Contacts__c = '701V9000027m9pUIAQ';
        savedSearch.Selected_Lists__c = '701V9000027m9pUIAQ';
        savedSearch.Selected_Tags__c = '701V9000027m9pUIAQ';
        
        return savedSearch;
    }
        
	public static Related_Contact__c createRelatedContact(Contact con1, Contact con2){
		Related_Contact__c rc = new Related_Contact__c(
            Main_Contact__c = con1.Id,
            Related_Contact__c = con2.Id,
            Relationship__c = 'Executive Assistant',
            Events_Primary_Staff_Contact__c = true
        );
        insert as system rc;
		return rc;
	}

	/**
	 * Description : Method to create non budget grant
	 * Return Type : IM_Non_Budget_Grant__c
	 */
	public static IM_Non_Budget_Grant__c createNonBudgetGrant(String initiativeId, String imGrantId) {
		IM_Non_Budget_Grant__c nonBG = new IM_Non_Budget_Grant__c();
		nonBG.Initiative__c = initiativeId;
		nonBG.IM_Grant__c = imGrantId;
		insert as system nonBG;
		return nonBG;
	}

	/**
	 * Description : Method to create IM Sync Load Skip record
	 * Return Type : IM_Sync_Load_Skip__c
	 */
	public static IM_Sync_Load_Skip__c createSyncLoadSkip() {
		IM_Sync_Load_Skip__c syncLoadSkip = new IM_Sync_Load_Skip__c();
		syncLoadSkip.IM_Entity__c = 'Initiative';
		syncLoadSkip.BGive_Entity__c = 'Initiative';
		syncLoadSkip.Skip_Code_Category__c = '1.Fatal';
		insert as system syncLoadSkip;
		return syncLoadSkip;
    }
    
    public static ListOrganization__c createListOrganization(Id listId, Id orgId) {
		ListOrganization__c lo = new ListOrganization__c(
			List__c = listId,
			Organization__c = orgId
		);
		insert as system lo;
		return lo;
	}

	public static Highlight_Interaction__c createHighlightInteraction(String subject, Team__c team, String description, String leadershipDesc) {
        Highlight_Interaction__c highlightInteraction = new Highlight_Interaction__c(
           	Name = subject,
			Team__c = team.Id,
			Description__c = description,
			Status__c = Assets.DRAFT,
			Leadership_Highlight_Description__c = leadershipDesc,
			Include_As_MRB_Highlight__c = false
        );
        insert as system highlightInteraction;
        return highlightInteraction;
	}
    
    public static Interaction_Participant__c createInteractionParticipant(Id highlightId, String type, Id orgId, Id contactId, String description) {
        Interaction_Participant__c participant = new Interaction_Participant__c(Highlight__c = highlightId,
                                                  Type__c = type, Organization__c = orgId, Contact__c = contactId, Description__c = description);
        insert as system participant;
        return participant;
    }
}