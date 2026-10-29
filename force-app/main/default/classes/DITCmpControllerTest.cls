@isTest
public class DITCmpControllerTest {
  @testSetup
  static void setup() {
    Account newAccount = new Account(Name = 'Slalom');
    insert as system newAccount;
    Data_Load__c dataload = new Data_Load__c();
    dataload.Name__c = 'Test.csv';
    dataload.Column_Map__c =
      '[{"cells":[{"value":"FirstName","type":"STRING","isEdit":false},{"class":"","originalOptions":[{"value":"Notes ","label":"Notes "},{"value":"Home Country","label":"Home Country"},' +
      '{"value":"Home Postal Code","label":"Home Postal Code"},{"value":"Home State","label":"Home State"},{"value":"Home City","label":"Home City"},{"value":"Home Street Line3","label":"Home Street Line3"},{"value":"Home Street Line2","label":"Home Street Line2"},' +
      '{"value":"Home Street Line1","label":"Home Street Line1"},{"value":"Business Country","label":"Business Country"},{"value":"Business Postal Code","label":"Business Postal Code"},{"value":"Business State","label":"Business State"},' +
      '{"value":"Business City","label":"Business City"},{"value":"Business Street Address 3","label":"Business Street Address 3"},{"value":"Business Street Address 2","label":"Business Street Address 2"},{"value":"Business Street Address 1","label":"Business Street Address 1"},' +
      '{"value":"Additional Phone","label":"Additional Phone"},{"value":"Additional Phone (Country Code)","label":"Additional Phone (Country Code)"},{"value":"Mobile Phone","label":"Mobile Phone"},{"value":"Mobile Phone (Country Code)","label":"Mobile Phone (Country Code)"},' +
      '{"value":"Business Phone","label":"Business Phone"},{"value":"Business Phone (Country Code)","label":"Business Phone (Country Code)"},{"value":"Additional Email","label":"Additional Email"},{"value":"Personal Email","label":"Personal Email"},' +
      '{"value":"Business Email","label":"Business Email"},{"value":"Company","label":"Company"},{"value":"Title","label":"Title"},{"value":"Preferred FirstName","label":"Preferred FirstName"},{"value":"Suffix","label":"Suffix"},{"value":"Last Name","label":"Last Name"},' +
      '{"value":"Middle Name","label":"Middle Name"},{"value":"FirstName","label":"FirstName"},{"value":"Salutation","label":"Salutation"}],"options":[' +
      '{"value":"Notes ","label":"Notes "},{"value":"Home Country","label":"Home Country"},{"value":"Home Street Line3","label":"Home Street Line3"},{"value":"Home Street Line2","label":"Home Street Line2"},' +
      '{"value":"Home Street Line1","label":"Home Street Line1"},{"value":"Business Street Address 3","label":"Business Street Address 3"},{"value":"Business Street Address 2","label":"Business Street Address 2"},{"value":"Business Street Address 1","label":"Business Street Address 1"},' +
      '{"value":"Additional Phone (Country Code)","label":"Additional Phone (Country Code)"},{"value":"Business Phone","label":"Business Phone"},{"value":"Business Phone (Country Code)","label":"Business Phone (Country Code)"},{"value":"FirstName","label":"FirstName"}],' +
      '"isRequired":true,"value":"FirstName","type":"PICKLIST","colName":"FirstName","api":"First_Name__c","isEdit":true}],"id":0},{"cells":[{"value":"Last Name","type":"STRING","isEdit":false},{"class":"","originalOptions":[' +
      '{"value":"Home Country","label":"Home Country"},{"value":"Home Postal Code","label":"Home Postal Code"},{"value":"Home State","label":"Home State"},{"value":"Home City","label":"Home City"},{"value":"Home Street Line3","label":"Home Street Line3"},{"value":"Home Street Line2","label":"Home Street Line2"},' +
      '{"value":"Home Street Line1","label":"Home Street Line1"},{"value":"Business Country","label":"Business Country"},{"value":"Business Postal Code","label":"Business Postal Code"},{"value":"Business State","label":"Business State"},{"value":"Business City","label":"Business City"},' +
      '{"value":"Business Street Address 3","label":"Business Street Address 3"},{"value":"Business Street Address 2","label":"Business Street Address 2"},{"value":"Business Street Address 1","label":"Business Street Address 1"},{"value":"Additional Phone","label":"Additional Phone"},' +
      '{"value":"Additional Phone (Country Code)","label":"Additional Phone (Country Code)"},{"value":"Mobile Phone","label":"Mobile Phone"},{"value":"Mobile Phone (Country Code)","label":"Mobile Phone (Country Code)"},{"value":"Business Phone","label":"Business Phone"},' +
      '{"value":"Business Phone (Country Code)","label":"Business Phone (Country Code)"},{"value":"Additional Email","label":"Additional Email"},{"value":"Personal Email","label":"Personal Email"},{"value":"Business Email","label":"Business Email"},{"value":"Company","label":"Company"},' +
      '{"value":"Title","label":"Title"},{"value":"Preferred FirstName","label":"Preferred FirstName"},{"value":"Suffix","label":"Suffix"},{"value":"Last Name","label":"Last Name"},{"value":"Middle Name","label":"Middle Name"},{"value":"FirstName","label":"FirstName"},' +
      '{"value":"Salutation","label":"Salutation"}],"options":[{"value":"Notes ","label":"Notes "},{"value":"Home Country","label":"Home Country"},' +
      '{"value":"Home Street Line3","label":"Home Street Line3"},{"value":"Home Street Line2","label":"Home Street Line2"},{"value":"Home Street Line1","label":"Home Street Line1"},{"value":"Business Street Address 3","label":"Business Street Address 3"},{"value":"Business Street Address 2","label":"Business Street Address 2"},' +
      '{"value":"Business Street Address 1","label":"Business Street Address 1"},{"value":"Additional Phone (Country Code)","label":"Additional Phone (Country Code)"},{"value":"Business Phone","label":"Business Phone"},{"value":"Business Phone (Country Code)","label":"Business Phone (Country Code)"},' +
      '{"value":"Last Name","label":"Last Name"}],"isRequired":true,"value":"Last Name","type":"PICKLIST","colName":"Last Name","api":"Last_Name__c","isEdit":true}],"id":1}]';

    dataload.Excel_Columns__c =
      '{"notes":"Notes ","home country":"Home Country","home postal code":"Home Postal Code","home state":"Home State","home city":"Home City","home street line3":"Home Street Line3","home street line2":"Home Street Line2","home street line1":"Home Street Line1","business country":"Business Country",' +
      '"business postal code":"Business Postal Code","business state":"Business State","business city":"Business City","business street address 3":"Business Street Address 3","business street address 2":"Business Street Address 2","business street address 1":"Business Street Address 1","additional phone":"Additional Phone",' +
      '"additional phone (country code)":"Additional Phone (Country Code)","mobile phone":"Mobile Phone","mobile phone (country code)":"Mobile Phone (Country Code)","business phone":"Business Phone","business phone (country code)":"Business Phone (Country Code)","additional email":"Additional Email","personal email":"Personal Email",' +
      '"business email":"Business Email","company":"Company","title":"Title","preferred first name":"Preferred First Name","suffix":"Suffix","last name":"Last Name","middle name":"Middle Name","first name":"First Name","salutation":"Salutation"}';

    dataload.Stage__c = 'preview';
    insert as system dataload;

    Campaign camp = new Campaign();
    camp.Name = 'test';
    insert as system camp;

    Data_Load_Record__c DLrec = new Data_Load_Record__c(
      IsConfirmed__c = true,
      Data_Load__c = dataload.Id,
      Last_Name__c = 'Test Thomson',
      Organization_Name__c = 'Slalom',
      Business_State__c = 'NY',
      Home_State__c = 'NY',
      Assistant_1_Last_Name__c = 'Ass Name 1',
      Assistant_1_Email__c = 'test1@test.com',
      Assistant_1_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Office__c = '+1 212 123 1212',
      Assistant_1_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Cell__c = '+1 212 4444 5555',
      Assistant_2_Last_Name__c = 'Ass Name 2',
      Assistant_2_Email__c = 'test3@test.com',
      Assistant_2_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Office__c = '+1 212 222 333',
      Assistant_2_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Cell__c = '+1 212 444 5555',
      Status__c = 'In Progress',
      Row_Index__c = 1
    );
    insert as system DLrec;
  }

  @isTest
  static void testGeneralMethods() {
    Test.startTest();
    DITCmpController.getColumns();

    // Create Data
    Account newAccount = new Account(Name = 'Company');
    insert as system newAccount;
    Data_Load__c dataLoad = TestDataFactory.createDataLoad();
    List<Data_Load_Record__c> dlrs = new List<Data_Load_Record__c>();

    Contact c = new Contact();
    c.FirstName = 'FirstName1';
    c.LastName = 'LastName1';
    c.Email = 'Test1@Email.com';
    insert as system c;

    Map<String, Object> fields = new Map<String, Object>();
    Map<String, Object> excel = new Map<String, Object>();
    fields.put('contactId', c.Id);
    fields.put('excel', new Map<String, Object>{ 'isSelected' => 'true' });
    fields.put('api', 'Organization_Name__c');
    fields.put('isSelected', 'true');
    fields.put('isShow', false);
    fields.put('isCreate', true);

    List<Map<String, Object>> recmaplst = new List<Map<String, Object>>();
    recmaplst.add(fields);
    Map<String, Object> recc = new Map<String, Object>();
    recc.put('fields', recmaplst);

    dlrs.add(
      new Data_Load_Record__c(
        Contact_Data__c = json.serialize(recc),
        Data_Load__c = dataLoad.Id,
        Last_Name__c = 'Test Thomson',
        Organization_Name__c = 'Company',
        Business_State__c = 'NY',
        Home_State__c = 'NY',
        Assistant_1_Last_Name__c = 'Ass Name 1',
        Assistant_1_Email__c = 'test1@test.com',
        Assistant_1_Office_Phone_Country_Code__c = 'United States(+1)',
        Assistant_1_Office__c = '+1 212 123 1212',
        Assistant_1_Mobile_Phone_Country_Code__c = 'United States(+1)',
        Assistant_1_Cell__c = '+1 212 4444 5555',
        Assistant_2_Last_Name__c = 'Ass Name 2',
        Assistant_2_Email__c = 'test3@test.com',
        Assistant_2_Office_Phone_Country_Code__c = 'United States(+1)',
        Assistant_2_Office__c = '+1 212 222 333',
        Assistant_2_Mobile_Phone_Country_Code__c = 'United States(+1)',
        Assistant_2_Cell__c = '+1 212 444 5555',
        Status__c = 'In Progress'
      )
    );

    dlrs.add(
      new Data_Load_Record__c(
        Contact_Data__c = json.serialize(recc),
        Data_Load__c = dataLoad.Id,
        Last_Name__c = 'Test Smith',
        Organization_Name__c = newAccount.Name,
        Organization_Id__c = newAccount.Id,
        Business_State__c = 'NY',
        Home_State__c = 'NY',
        Assistant_2_Last_Name__c = 'Ass Name',
        Assistant_2_Office_Phone_Country_Code__c = 'United States(+1)',
        Assistant_2_Office__c = '+1 212 123 1212',
        Assistant_2_Mobile_Phone_Country_Code__c = 'United States(+1)',
        Assistant_2_Cell__c = '+1 212 4444 5555',
        Status__c = 'In Progress'
      )
    );

    dlrs.add(
      new Data_Load_Record__c(
        Contact_Data__c = json.serialize(recc),
        Data_Load__c = dataLoad.Id,
        Last_Name__c = 'Test 123',
        Organization_Name__c = '',
        Business_State__c = '',
        Home_State__c = '',
        Status__c = 'In Progress'
      )
    );

    dlrs.add(
      new Data_Load_Record__c(
        Contact_Data__c = json.serialize(recc),
        Data_Load__c = dataLoad.Id,
        Last_Name__c = 'TestDuplicate',
        Organization_Name__c = newAccount.Name,
        Organization_Id__c = newAccount.Id,
        Business_State__c = 'New York',
        Home_State__c = 'NY',
        Status__c = 'In Progress'
      )
    );

    insert as system dlrs;

    DITCmpController.getColumns();
    DITCmpController.getSetupColumns(dataLoad.Id);
    DITCmpController.createOrg('test', dataLoad.Id);
    Object obj = DITCmpController.createContact(
      'First',
      'Last',
      'Email@Email.com',
      null,
      null,
      null
    );
    System.Assert(obj != null); // added

    c = new Contact();
    c.FirstName = 'test';
    c.LastName = 'test';
    c.Email = 'Test@Email.com';
    insert as system c;

    DITCmpController.getValidateDupes('test', '1', '1', 'Contact');
    DITCmpController.getValidateDupes('test test', '1', '1', 'Contact');
    DITCmpController.getValidateDupes('test', '1', '1', 'Account');

    String str = DITCmpController.createList('test');
    System.Assert(str != null); // added

    Campaign camp = new Campaign();
    camp.Name = 'test';
    insert as system camp;

    Object results = DITCmpController.createWithList(
      String.valueOf(camp.Id),
      camp.Name,
      String.valueOf(dataLoad.Id),
      new Map<String, String>{ 'First_Name__c' => 'FirstName' },
      '1',
      '1'
    );
    Map<String, Object> resp = (Map<String, Object>) results;
    Map<String, Object> errorMap = (Map<String, Object>) resp;
    system.assertEquals(1, Integer.valueOf(errorMap.get('createdTotal')));

    resp = (Map<String, Object>) DITCmpController.getContactsSummary(
      dataLoad.Id,
      new Map<String, String>{ 'First_Name__c' => 'FirstName' }
    );
    DITCmpController.getImportedDetail(
      new List<String>(),
      new List<String>(),
      new List<String>(),
      new List<String>(),
      dataLoad.Id,
      new Map<String, String>{ 'First_Name__c' => 'FirstName' }
    );
    system.assert(resp.get('recordList') != null);

    for (Data_Load_Record__c rec : dlrs) {
      rec.Contact_Data__c = null;
      recmaplst = new List<Map<String, Object>>();
      recmaplst.add(fields);
      recc = new Map<String, Object>();
      recc.put('fields', recmaplst);
      Map<String, String> columns = new Map<String, String>();
      columns = new Map<String, String>();
      rec.Excel_Row__c = json.serialize(columns);
      rec.Contact_Data__c = json.serialize(recc);
    }
    update as system dlrs;

    Object objRec = DITCmpController.getImportedDetail(
      new List<String>(),
      new List<String>(),
      new List<String>(),
      new List<String>(),
      dataLoad.Id,
      new Map<String, String>{ 'First_Name__c' => 'FirstName' }
    );
    Test.stopTest();
    System.Assert(objRec != null); // added
  }

  @isTest
  static void testCreateNewDataLoad() {
    Test.startTest();
    Map<String, String> columns = new Map<String, String>();
    columns.put('FirstName', 'FirstName');
    DITCmpController.createNewDataLoad('Test', columns);
    Data_Load__c rec = [SELECT Id FROM Data_Load__c WITH SYSTEM_MODE LIMIT 1];
    List<Map<String, String>> excelRows = new List<Map<String, String>>();
    excelRows.add(columns);
    List<Data_Load_Record__c> result = (List<Data_Load_Record__c>) DITCmpController.createNewExcelRows(
      rec.Id,
      excelRows,
      '0'
    );
    Test.stopTest();
    system.assertEquals(1, result.size());
  }

  // BRME-5632: cover the structured per-row error capture + report persistence + member upsert.
  @isTest
  static void testErrorReport_BRME5632() {
    Test.startTest();
    // a contact that will FAIL (Business Phone without Country Code -> validation rule)
    List<Contact> badCreate = new List<Contact>{
      new Contact(FirstName = 'Bad', LastName = 'Row', Phone = '2125550100')
    };
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    dml.optAllOrNone = false;
    List<Database.SaveResult> sr = Database.insert(badCreate, dml);
    // member upsert with errors (valid + the structured variant)
    List<CampaignMember> members = new List<CampaignMember>();
    Map<String, Object> memResult = DITCmpController.upsertMemberRecordsWithErrors(
      members,
      members
    );
    System.assert(
      memResult.containsKey('successCount'),
      'member result should include successCount'
    );
    System.assert(
      memResult.containsKey('rowErrors'),
      'member result should include rowErrors'
    );
    // persist a report file against a Data_Load__c
    Data_Load__c dl = new Data_Load__c(
      Name__c = 'BRME5632 Test',
      Stage__c = 'preview'
    );
    insert as system dl;
    String docId = DITCmpController.saveErrorReport(
      dl.Id,
      'BRME5632_Errors.xlsx',
      EncodingUtil.base64Encode(Blob.valueOf('test'))
    );
    System.assertNotEquals(
      null,
      docId,
      'saveErrorReport should return a ContentDocumentId'
    );
    Test.stopTest();
  }

  @isTest
  static void testPermissionChecksAndMemberUpserts() {
    Map<String, Boolean> permissions = DITCmpController.fetchCustomPermission();
    System.assert(permissions.containsKey('Confidential_Info'));
    System.assert(permissions.containsKey('Contact_Home_Address'));
    System.assert(permissions.containsKey('Contact_UUID'));
    System.assert(
      permissions.containsKey('Contact_Home_Phone_Personal_Email')
    );
    DITCmpController.checkUUIDPermission();
    DITCmpController.checkConfidentialPermission();

    Campaign campaign = [
      SELECT Id
      FROM Campaign
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Contact firstContact = new Contact(
      FirstName = 'Member',
      LastName = 'Create'
    );
    Contact secondContact = new Contact(
      FirstName = 'Member',
      LastName = 'Structured'
    );
    insert as system new List<Contact>{ firstContact, secondContact };

    CampaignMember memberToCreate = new CampaignMember(
      CampaignId = campaign.Id,
      ContactId = firstContact.Id,
      Status = 'Sent'
    );
    Test.startTest();
    Integer createdCount = DITCmpController.upsertMemberRecords(
      new List<CampaignMember>{ memberToCreate },
      new List<CampaignMember>()
    );
    System.assertEquals(1, createdCount);

    Integer updatedCount = DITCmpController.upsertMemberRecords(
      new List<CampaignMember>(),
      new List<CampaignMember>{ memberToCreate }
    );
    System.assertEquals(1, updatedCount);

    Map<String, Object> structuredUpdate = DITCmpController.upsertMemberRecordsWithErrors(
      new List<CampaignMember>(),
      new List<CampaignMember>{ memberToCreate }
    );
    System.assertEquals(1, structuredUpdate.get('successCount'));
    System.assertEquals(0, ((List<Object>) structuredUpdate.get('rowErrors')).size());

    CampaignMember structuredMember = new CampaignMember(
      CampaignId = campaign.Id,
      ContactId = secondContact.Id,
      Status = 'Sent'
    );
    Map<String, Object> structuredCreate = DITCmpController.upsertMemberRecordsWithErrors(
      new List<CampaignMember>{ structuredMember },
      new List<CampaignMember>()
    );
    System.assertEquals(1, structuredCreate.get('successCount'));
    System.assertEquals(0, ((List<Object>) structuredCreate.get('rowErrors')).size());

    CampaignMember invalidMember = new CampaignMember(
      CampaignId = campaign.Id,
      ContactId = secondContact.Id,
      Status = 'Invalid BRME5632 Status'
    );
    Map<String, Object> structuredFailure = DITCmpController.upsertMemberRecordsWithErrors(
      new List<CampaignMember>{ invalidMember },
      new List<CampaignMember>()
    );
    System.assertEquals(0, structuredFailure.get('successCount'));
    List<Object> memberErrors = (List<Object>) structuredFailure.get(
      'rowErrors'
    );
    System.assertEquals(1, memberErrors.size());
    Map<String, Object> memberError = (Map<String, Object>) memberErrors[0];
    System.assertEquals(secondContact.Id, memberError.get('contactId'));
    System.assertEquals(campaign.Id, memberError.get('listId'));
    System.assertEquals(null, memberError.get('listMemberId'));
    Test.stopTest();
  }

  @isTest
  static void testgetValidateDupes() {
    Test.startTest();
    String dupeName = 'LastName';
    String row = '1';
    String col = '1';
    String objName = 'Contact';
    DITCmpController.createContact(
      'FirstName',
      'LastName',
      'Test@Email.com',
      null,
      null,
      null
    );
    system.assertEquals(
      1,
      [SELECT Id FROM Contact WHERE Title = 'FirstName' WITH SYSTEM_MODE].size()
    );
    DITCmpController.getValidateDupes(dupeName, row, col, objName);
    objName = 'Account';
    DITCmpController.getValidateDupes(dupeName, row, col, objName);
    Test.stopTest();
  }

  @isTest
  static void tesgetDupes() {
    Test.startTest();
    Map<String, Map<String, String>> contactMap = new Map<String, Map<String, String>>();

    Map<String, String> recordmap = new Map<String, String>();
    recordmap.put('FirstName', 'firstname');
    recordmap.put('LastName', 'lastname');
    recordmap.put('First_Name__c', 'firstname');
    recordmap.put('Last_Name__c', 'lastname');
    recordmap.put('Converted_Full_Name__c', 'firstnamelastname');
    recordmap.put('Business_Email__c', 'Test@Email.com');

    Map<String, String> columns = new Map<String, String>();
    columns.put('FirstName', 'firstname');
    columns.put('LastName', 'lastname');
    columns.put('Business_Email__c', 'Email');
    columns.put('Alternate_Email__c', 'Email');
    columns.put('Preferred_First_Name__c', 'Preferred_First_Name__c');
    contactMap.put('firstname-lastname', recordmap);

    recordmap = new Map<String, String>();
    recordmap.put('FirstName', 'newcontactdupf');
    recordmap.put('LastName', 'newcontactdupl');
    recordmap.put('Business_Email__c', 'newcontactdup@Email.com');
    recordmap.put('Alternate_Email__c', 'newcontactdup@Email.com');
    contactMap.put('newcontactdupf2-newcontactdupl', recordmap);

    DITCmpController.createContact(
      'firstname',
      'lastname',
      'Test@Email.com',
      null,
      null,
      null
    );
    Contact c = (Contact) DITCmpController.createContact(
      'newcontactdupf',
      'newcontactdupl',
      'newcontactdup@Email.com',
      null,
      null,
      null
    );
    c.Preferred_First_Name__c = 'newcontactdupf2';
    update as system c;

    List<Contact> lstContact = (List<Contact>) DITCmpController.getDupes(
      contactMap,
      columns
    );
    Test.stopTest();
    system.assertEquals(0, lstContact.size());
  }

  // BRME-7012: DIT Compare Potential Duplicates must surface an existing Contact whose
  // Preferred_First_Name__c equals the imported First Name when Last Name matches, even with no email match.
  // These tests pin the getDupes retrieval contract that the Aura row-assignment (prepareResult) relies on.
  // NOTE: createContact(title, firstName, lastName, email, ...) takes title as the first argument.

  private static Map<String, String> ditRow(
    String firstName,
    String lastName,
    String email
  ) {
    Map<String, String> row = new Map<String, String>();
    row.put('FirstName', firstName);
    row.put('LastName', lastName);
    row.put('First_Name__c', firstName);
    row.put('Last_Name__c', lastName);
    row.put('Converted_Full_Name__c', (firstName + lastName).toLowerCase());
    if (email != null)
      row.put('Business_Email__c', email);
    return row;
  }

  private static Map<String, String> ditColumns() {
    return new Map<String, String>{
      'FirstName' => 'FirstName',
      'LastName' => 'LastName',
      'Business_Email__c' => 'Email',
      'Preferred_First_Name__c' => 'Preferred_First_Name__c'
    };
  }

  @isTest
  static void testGetDupesPreferredFirstName_BRME7012() {
    // Imported Patti (no email) must match existing Patricia with Preferred First Name Patti, same last name.
    Contact patricia = (Contact) DITCmpController.createContact(
      null,
      'Patricia',
      'BRME7012PrefLN',
      'patricia.brme7012pref@brme7012.invalid',
      null,
      null
    );
    patricia.Preferred_First_Name__c = 'Patti';
    update as system patricia;

    Map<String, Map<String, String>> contactMap = new Map<String, Map<String, String>>{
      'patti-brme7012prefln' => ditRow('Patti', 'BRME7012PrefLN', null)
    };
    Test.startTest();
    List<Contact> result = (List<Contact>) DITCmpController.getDupes(
      contactMap,
      ditColumns()
    );
    Test.stopTest();
    Set<Id> ids = new Map<Id, Contact>(result).keySet();
    System.assert(
      ids.contains(patricia.Id),
      'preferred-first-name match should retrieve the contact'
    );
  }

  @isTest
  static void testGetDupesExactFirstNamePreserved_BRME7012() {
    // Exact first-name + last-name match must still work.
    Contact patti = (Contact) DITCmpController.createContact(
      null,
      'Patti',
      'BRME7012ExactLN',
      'patti.brme7012exact@brme7012.invalid',
      null,
      null
    );

    Map<String, Map<String, String>> contactMap = new Map<String, Map<String, String>>{
      'patti-brme7012exactln' => ditRow('Patti', 'BRME7012ExactLN', null)
    };
    Test.startTest();
    List<Contact> result = (List<Contact>) DITCmpController.getDupes(
      contactMap,
      ditColumns()
    );
    Test.stopTest();
    Set<Id> ids = new Map<Id, Contact>(result).keySet();
    System.assert(
      ids.contains(patti.Id),
      'exact first-name match should still retrieve the contact'
    );
  }

  @isTest
  static void testGetDupesMultipleCandidates_BRME7012() {
    // Both a preferred-name match and an exact-name match must be returned; neither replaces the other.
    Contact patricia = (Contact) DITCmpController.createContact(
      null,
      'Patricia',
      'BRME7012MultiLN',
      'patricia.brme7012multi@brme7012.invalid',
      null,
      null
    );
    patricia.Preferred_First_Name__c = 'Patti';
    update as system patricia;
    Contact patti = (Contact) DITCmpController.createContact(
      null,
      'Patti',
      'BRME7012MultiLN',
      'patti.brme7012multi@brme7012.invalid',
      null,
      null
    );

    Map<String, Map<String, String>> contactMap = new Map<String, Map<String, String>>{
      'patti-brme7012multiln' => ditRow('Patti', 'BRME7012MultiLN', null)
    };
    Test.startTest();
    List<Contact> result = (List<Contact>) DITCmpController.getDupes(
      contactMap,
      ditColumns()
    );
    Test.stopTest();
    Set<Id> ids = new Map<Id, Contact>(result).keySet();
    System.assert(
      ids.contains(patricia.Id),
      'preferred-name candidate must be returned'
    );
    System.assert(
      ids.contains(patti.Id),
      'exact-name candidate must also be returned'
    );
    System.assertEquals(
      ids.size(),
      result.size(),
      'candidate list must not contain duplicate contact IDs'
    );
  }

  @isTest
  static void testGetDupesDifferentLastNameNegative_BRME7012() {
    // Preferred-name match on a different last name with no email must NOT match.
    Contact patricia = (Contact) DITCmpController.createContact(
      null,
      'Patricia',
      'BRME7012OtherLN',
      'patricia.brme7012other@brme7012.invalid',
      null,
      null
    );
    patricia.Preferred_First_Name__c = 'Patti';
    update as system patricia;

    Map<String, Map<String, String>> contactMap = new Map<String, Map<String, String>>{
      'patti-brme7012nomatchln' => ditRow('Patti', 'BRME7012NoMatchLN', null)
    };
    Test.startTest();
    List<Contact> result = (List<Contact>) DITCmpController.getDupes(
      contactMap,
      ditColumns()
    );
    Test.stopTest();
    Set<Id> ids = new Map<Id, Contact>(result).keySet();
    System.assert(
      !ids.contains(patricia.Id),
      'different last name without email must not match'
    );
  }

  @isTest
  static void testGetDupesEmailMatchingPreserved_BRME7012() {
    // Existing email matching (here via Alternate_Email__c) must keep working.
    Contact randy = (Contact) DITCmpController.createContact(
      null,
      'Randy',
      'BRME7012EmailLN',
      'randy.primary.brme7012@brme7012.invalid',
      null,
      null
    );
    randy.Alternate_Email__c = 'randy.alt.brme7012@brme7012.invalid';
    update as system randy;

    Map<String, Map<String, String>> contactMap = new Map<String, Map<String, String>>{
      'randall-brme7012emailln' => ditRow(
        'Randall',
        'BRME7012EmailLN',
        'randy.alt.brme7012@brme7012.invalid'
      )
    };
    Test.startTest();
    List<Contact> result = (List<Contact>) DITCmpController.getDupes(
      contactMap,
      ditColumns()
    );
    Test.stopTest();
    Set<Id> ids = new Map<Id, Contact>(result).keySet();
    System.assert(
      ids.contains(randy.Id),
      'email (Alternate_Email__c) match should still retrieve the contact'
    );
  }

  @isTest
  static void testGetDupesBlankPreferredName_BRME7012() {
    // A contact with a blank Preferred First Name must not be matched by an unrelated first name.
    Contact bob = (Contact) DITCmpController.createContact(
      null,
      'Bob',
      'BRME7012BlankLN',
      'bob.brme7012blank@brme7012.invalid',
      null,
      null
    );

    Map<String, Map<String, String>> contactMap = new Map<String, Map<String, String>>{
      'patti-brme7012blankln' => ditRow('Patti', 'BRME7012BlankLN', null)
    };
    Test.startTest();
    List<Contact> result = (List<Contact>) DITCmpController.getDupes(
      contactMap,
      ditColumns()
    );
    Test.stopTest();
    Set<Id> ids = new Map<Id, Contact>(result).keySet();
    System.assert(
      !ids.contains(bob.Id),
      'blank preferred first name must not match an unrelated first name'
    );
  }

  @isTest
  static void tesgetPreviousDataLoads() {
    Test.startTest();
    Map<String, String> columns = new Map<String, String>();
    columns.put('FirstName', 'FirstName');
    Data_Load__c dataLoad = new Data_Load__c();
    dataLoad.Name__c = 'fileName';
    dataLoad.Column_Map__c = JSON.serialize(columns);
    dataLoad.Stage__c = 'preview';
    insert as system dataLoad;
    List<Map<String, String>> dataList = (List<Map<String, String>>) DITCmpController.getPreviousDataLoads();
    system.assertEquals(2, dataList.size());
    DITCmpController.updateData(dataLoad);
    Test.stopTest();
  }

  @isTest
  static void TestCreateWithList() {
    Test.startTest();
    Data_Load__c dataLoad = [
      SELECT Id, Column_Map__c
      FROM Data_Load__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    system.debug('@@dataLoad' + dataLoad);
    Data_Load_Record__c DLrec = [
      SELECT Id
      FROM Data_Load_Record__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Campaign camp = [SELECT Id, Name FROM Campaign WITH SYSTEM_MODE LIMIT 1];

    DITCmpController.createWithList(
      String.valueOf(camp.Id),
      camp.Name,
      String.valueOf(dataload.Id),
      new Map<String, String>{ 'First_Name__c' => 'FirstName' },
      '1',
      '1'
    );
    DITCmpController.createWithList(
      String.valueOf(camp.Id),
      camp.Name,
      String.valueOf(dataload.Id),
      new Map<String, String>{ 'First_Name__c' => 'FirstName' },
      '1',
      '1'
    );
    DITCmpController.getExcelColumns(dataLoad.Id);

    List<Object> excelColumns = (List<Object>) json.deserializeUntyped(
      dataLoad.Column_Map__c
    );
    try {
      DITCmpController.updateRecords(dataLoad.Id, excelColumns, '1', '1');
    } catch (Exception e) {
    }
    Test.stopTest();
  }

  @isTest
  static void testCreateWithListMemberErrorContext_BRME5632() {
    Data_Load__c dataLoad = [
      SELECT Id
      FROM Data_Load__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Campaign campaign = [
      SELECT Id
      FROM Campaign
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Data_Load_Record__c stagedRow = new Data_Load_Record__c(
      Data_Load__c = dataLoad.Id,
      First_Name__c = 'MemberContext',
      Last_Name__c = 'BRME5632',
      Status__c = 'In Progress',
      IsConfirmed__c = false,
      Row_Index__c = 2,
      Excel_Row__c = '{"First Name":"MemberContext","Last Name":"BRME5632"}'
    );
    insert as system stagedRow;

    Test.startTest();
    Map<String, Object> result = (Map<String, Object>) DITCmpController.createWithList(
      String.valueOf(campaign.Id),
      null,
      String.valueOf(dataLoad.Id),
      new Map<String, String>{
        'First_Name__c' => 'FirstName',
        'Last_Name__c' => 'LastName'
      },
      '1',
      '1'
    );
    Test.stopTest();

    Map<String, Object> memberContext = (Map<String, Object>) result.get(
      'memberErrorContext'
    );
    List<CampaignMember> members = (List<CampaignMember>) result.get(
      'memListToCreate'
    );
    System.assertEquals(1, members.size());
    Map<String, Object> sourceContext = (Map<String, Object>) memberContext.get(
      String.valueOf(members[0].ContactId)
    );
    System.assertNotEquals(null, sourceContext);
    System.assertEquals(stagedRow.Id, sourceContext.get('rowId'));
    System.assertEquals(2, sourceContext.get('rowIndex'));
    System.assertEquals(stagedRow.Excel_Row__c, sourceContext.get('excelRow'));
  }

  @isTest
  static void TestloadPreviewData() {
    Test.startTest();
    Data_Load__c dataLoad = [
      SELECT Id, Column_Map__c
      FROM Data_Load__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    dataload.Stage__c = 'preview';
    update as system dataload;
    Data_Load_Record__c DLrec = [
      SELECT Id
      FROM Data_Load_Record__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Campaign camp = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];
    DITCmpController.loadPreviewData(dataLoad.Id);
    try {
      DITCmpController.updateUploadData(dataLoad.Id, new List<Object>());
    } catch (Exception e) {
      System.debug('e>> ' + e);
    }
    Test.stopTest();
  }

  @isTest
  static void TestgetUpdateContact() {
    Test.startTest();
    Data_Load__c dataLoad = [
      SELECT Id, Column_Map__c
      FROM Data_Load__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Data_Load_Record__c DLrec = [
      SELECT Id
      FROM Data_Load_Record__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Campaign camp = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];
    Account newAccount = [
      SELECT Id, Name
      FROM Account
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    Contact c = new Contact();
    c.FirstName = 'FirstName';
    c.LastName = 'LastName';
    c.Email = 'Test@Email.com';
    insert as system c;

    Map<String, Object> fields = new Map<String, Object>();
    fields.put('contactId', c.Id);
    fields.put('api', 'FirstName');
    fields.put('isShow', false);
    List<Map<String, Object>> recmaplst = new List<Map<String, Object>>();
    recmaplst.add(fields);
    Map<String, Object> recc = new Map<String, Object>();
    recc.put('fields', recmaplst);
    Map<String, String> columns = new Map<String, String>();
    columns.put('First_Name__c', 'First_Name__c');

    DITCmpController.getColMap(dataload.Id);
    DLrec = new Data_Load_Record__c(
      Organization_Id__c = newAccount.Id,
      Data_Load__c = dataload.Id,
      Last_Name__c = 'Test Thomson',
      Organization_Name__c = 'Company',
      Business_State__c = 'NY',
      Home_State__c = 'NY',
      Assistant_1_Last_Name__c = 'Ass Name 1',
      Assistant_1_Email__c = 'test1@test.com',
      Assistant_1_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Office__c = '+1 212 123 1212',
      Assistant_1_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Cell__c = '+1 212 4444 5555',
      Assistant_2_Last_Name__c = 'Ass Name 2',
      Assistant_2_Email__c = 'test3@test.com',
      Assistant_2_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Office__c = '+1 212 222 333',
      Assistant_2_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Cell__c = '+1 212 444 5555',
      Status__c = 'In Progress',
      Row_Index__c = 2
    );
    DLrec.Excel_Row__c = json.serialize(columns);
    DLrec.Contact_Data__c = json.serialize(recc);
    insert as system DLrec;
    DITCmpController.getNewRecord(DLrec, columns);

    fields = new Map<String, Object>();
    fields.put('contactId', c.Id);
    fields.put('api', 'Organization_Name__c');
    fields.put('excel', new Map<String, Object>{ 'isSelected' => 'true' });
    fields.put('isShow', true);
    recmaplst = new List<Map<String, Object>>();
    recmaplst.add(fields);
    recc = new Map<String, Object>();
    recc.put('fields', recmaplst);
    columns = new Map<String, String>();
    columns.put('First_Name__c', 'First_Name__c');
    columns.put('Organization_Name__c', 'Organization_Name__c');
    DLrec.Excel_Row__c = json.serialize(columns);
    DLrec.Contact_Data__c = json.serialize(recc);
    update as system DLrec;

    DITCmpController.getUpdateContact(
      DLrec,
      new Map<Id, Data_Load_Record__c>(),
      columns
    );
    DITCmpController.isUpdate(DLrec);
    DITCmpController.isCreate(DLrec);
    DITCmpController.updateDataRecords(
      new List<Data_Load_Record__c>{ DLrec },
      true
    );
    Data_Load_Record__c rec = DITCmpController.updateDataRecord(DLrec);
    System.assert(rec != null);
    recmaplst = new List<Map<String, Object>>();
    recmaplst.add(fields);
    recc = new Map<String, Object>();
    recc.put('fields', recmaplst);
    columns = new Map<String, String>();
    columns.put('First_Name__c', 'First_Name__c');
    DLrec.Excel_Row__c = json.serialize(columns);
    DLrec.Contact_Data__c = json.serialize(recc);
    update as system DLrec;

    DITCmpController.getUpdateContact(
      DLrec,
      new Map<Id, Data_Load_Record__c>(),
      columns
    );

    DLrec.Contact_Data__c = null;
    DLrec.isConfirmed__c = true;
    DLrec.Contact_ID__c = c.Id;

    Boolean resp = DITCmpController.isUpdate(DLrec);
    system.assertEquals(resp, true);
    Test.stopTest();
  }

  @isTest
  static void TestSetContact() {
    Test.startTest();
    Data_Load__c dataLoad = [
      SELECT Id, Column_Map__c
      FROM Data_Load__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Data_Load_Record__c DLrec = [
      SELECT Id
      FROM Data_Load_Record__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Campaign camp = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];
    Account newAccount = [
      SELECT Id, Name
      FROM Account
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    Contact c = new Contact();
    c.FirstName = 'FirstName';
    c.LastName = 'LastName';
    c.Email = 'Test@Email.com';
    insert as system c;

    Map<String, Object> fields = new Map<String, Object>();
    fields.put('contactId', c.Id);
    fields.put('api', 'FirstName');
    fields.put('isShow', false);
    List<Map<String, Object>> recmaplst = new List<Map<String, Object>>();
    recmaplst.add(fields);
    Map<String, Object> recc = new Map<String, Object>();
    recc.put('fields', recmaplst);
    Map<String, String> columns = new Map<String, String>();
    columns.put('First_Name__c', 'First_Name__c');

    DITCmpController.getColMap(dataload.Id);
    DLrec = new Data_Load_Record__c(
      Organization_Id__c = newAccount.Id,
      Data_Load__c = dataload.Id,
      Last_Name__c = 'Test Thomson',
      Organization_Name__c = 'Company',
      Business_State__c = 'NY',
      Home_State__c = 'NY',
      Assistant_1_Last_Name__c = 'Ass Name 1',
      Assistant_1_Email__c = 'test1@test.com',
      Assistant_1_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Office__c = '+1 212 123 1212',
      Assistant_1_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Cell__c = '+1 212 4444 5555',
      Assistant_2_Last_Name__c = 'Ass Name 2',
      Assistant_2_Email__c = 'test3@test.com',
      Assistant_2_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Office__c = '+1 212 222 333',
      Assistant_2_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Cell__c = '+1 212 444 5555',
      Status__c = 'In Progress',
      Row_Index__c = 2
    );
    DLrec.Excel_Row__c = json.serialize(columns);
    DLrec.Contact_Data__c = json.serialize(recc);
    insert as system DLrec;

    Map<Id, String> conmap = new Map<Id, String>{ c.Id => 'dummy' };
    columns.put('Organization_Name__c', newAccount.Id);
    Map<String, Map<Id, String>> contactMap = new Map<String, Map<Id, String>>();
    contactMap.put('company', conmap);
    contactMap.put('assistent name', conmap);

    DITCmpController.setContacts(
      new List<Data_Load_Record__c>{ DLrec },
      contactMap,
      'Organization_Name__c'
    );
    DITCmpController.setOrgs(
      new List<Data_Load_Record__c>{ DLrec },
      contactMap
    );
    DITCmpController.setContacts(
      new List<Data_Load_Record__c>{ DLrec },
      contactMap,
      'Assistant_Name__c'
    );
    Test.stopTest();
  }

  @isTest
  static void TestGetOrgMap() {
    Test.startTest();
    Data_Load__c dataLoad = [
      SELECT Id, Column_Map__c
      FROM Data_Load__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Data_Load_Record__c DLrec = [
      SELECT Id
      FROM Data_Load_Record__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Campaign camp = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];
    Account newAccount = [
      SELECT Id, Name
      FROM Account
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    Contact c = new Contact();
    c.FirstName = 'FirstName';
    c.LastName = 'LastName';
    c.Email = 'Test@Email.com';
    insert as system c;

    Map<String, Object> fields = new Map<String, Object>();
    fields.put('contactId', c.Id);
    fields.put('api', 'FirstName');
    fields.put('isShow', false);
    List<Map<String, Object>> recmaplst = new List<Map<String, Object>>();
    recmaplst.add(fields);
    Map<String, Object> recc = new Map<String, Object>();
    recc.put('fields', recmaplst);
    Map<String, String> columns = new Map<String, String>();
    columns.put('FirstName', 'firstname');
    columns.put('LastName', 'lastname');
    columns.put('Business_Email__c', 'Email');

    Object obj = DITCmpController.getColMap(dataload.Id);
    System.Assert(obj != null); // added

    DLrec = new Data_Load_Record__c(
      Organization_Id__c = '',
      Data_Load__c = dataload.Id,
      First_Name__c = 'Test FirstName',
      Last_Name__c = 'Test Thomson',
      Organization_Name__c = 'company',
      Business_State__c = 'NY',
      Home_State__c = 'NY',
      Assistant_1_Last_Name__c = 'Ass Name 1',
      Assistant_1_Email__c = 'test1@test.com',
      Assistant_1_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Office__c = '+1 212 123 1212',
      Assistant_1_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Cell__c = '+1 212 4444 5555',
      Assistant_2_Last_Name__c = 'Ass Name 2',
      Assistant_2_Email__c = 'test3@test.com',
      Assistant_2_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Office__c = '+1 212 222 333',
      Assistant_2_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Cell__c = '+1 212 444 5555',
      Status__c = 'In Progress',
      Row_Index__c = 2,
      Cell__c = 'Cell__c'
    );
    DLrec.Excel_Row__c = json.serialize(columns);
    DLrec.Contact_Data__c = json.serialize(recc);
    insert as system DLrec;

    DITCmpController.getOrgMap(new List<Data_Load_Record__c>{ DLrec });
    DITCmpController.getPreviousDataLoads();
    Map<String, Object> result = (Map<String, Object>) DITCmpController.loadPreviewData(
      dataLoad.Id
    );
    system.assert(result.get('records') != null);
    DITCmpController.updateSetupColumns(dataLoad.Id, recmaplst);
    Data_Load__c res = DITCmpController.updateStage(dataLoad.Id, null);
    System.Assert(res != null); // added

    c = new Contact();
    c.LastName = 'Cell__c';
    c.Email = 'Test@Email.com';
    insert as system c;

    c = new Contact();
    c.FirstName = 'simple';
    c.LastName = 'one';
    c.Email = 'Test@Email.com';
    insert as system c;

    DITCmpController.getContactMap(
      new List<Data_Load_Record__c>{ DLrec },
      'Cell__c'
    );
    DITCmpController.getContactMap(
      new List<Data_Load_Record__c>{ DLrec },
      'Cell__c'
    );

    Test.stopTest();
    system.assert(result.get('contacts') != null);
    system.assert(result.get('contacts') != null); // ADDED
  }

  @isTest
  static void testCheckPermissions() {
    DITCmpController.fetchCustomPermission();
    DITCmpController.checkUUIDPermission();
    DITCmpController.checkConfidentialPermission();
    DITCmpController.getPickLists('Account', 'Type');
  }

  @isTest
  static void testLoadUnconfirmedData() {
    Data_Load__c dataLoad = [
      SELECT Id, Column_Map__c
      FROM Data_Load__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Data_Load_Record__c DLrec = [
      SELECT Id
      FROM Data_Load_Record__c
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Campaign camp = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];
    Account newAccount = [
      SELECT Id, Name
      FROM Account
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    Contact c = new Contact();
    c.FirstName = 'FirstName';
    c.LastName = 'LastName';
    c.Email = 'Test@Email.com';
    insert as system c;

    Map<String, Object> fields = new Map<String, Object>();
    fields.put('contactId', c.Id);
    fields.put('api', 'FirstName');
    fields.put('isShow', false);
    List<Map<String, Object>> recmaplst = new List<Map<String, Object>>();
    recmaplst.add(fields);
    Map<String, Object> recc = new Map<String, Object>();
    recc.put('fields', recmaplst);
    Map<String, String> columns = new Map<String, String>();
    columns.put('FirstName', 'firstname');
    columns.put('LastName', 'lastname');
    columns.put('Business_Email__c', 'Email');

    Object obj = DITCmpController.getColMap(dataload.Id);
    System.Assert(obj != null); // added

    DLrec = new Data_Load_Record__c(
      Organization_Id__c = '',
      Data_Load__c = dataload.Id,
      First_Name__c = 'Test FirstName',
      Last_Name__c = 'Test Thomson',
      Organization_Name__c = 'company',
      Business_State__c = 'NY',
      Home_State__c = 'NY',
      Assistant_1_Last_Name__c = 'Ass Name 1',
      Assistant_1_Email__c = 'test1@test.com',
      Assistant_1_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Office__c = '+1 212 123 1212',
      Assistant_1_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_1_Cell__c = '+1 212 4444 5555',
      Assistant_2_Last_Name__c = 'Ass Name 2',
      Assistant_2_Email__c = 'test3@test.com',
      Assistant_2_Office_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Office__c = '+1 212 222 333',
      Assistant_2_Mobile_Phone_Country_Code__c = 'United States(+1)',
      Assistant_2_Cell__c = '+1 212 444 5555',
      Status__c = 'In Progress',
      Row_Index__c = 2,
      Cell__c = 'Cell__c'
    );
    DLrec.Excel_Row__c = json.serialize(columns);
    DLrec.Contact_Data__c = json.serialize(recc);
    insert as system DLrec;

    DITCmpController.loadUnconfirmedData(dataload.Id);
    DITCmpController.getUUIDMap(new List<Data_Load_Record__c>{ DLrec });
    DITCmpController.getContactMap(new List<Data_Load_Record__c>{ DLrec });
  }
}