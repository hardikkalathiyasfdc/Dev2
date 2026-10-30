public with sharing class DITCmpController {
  private final static Map<String, SObjectField> FIELD_MAP = Data_Load_Record__c.sObjectType.getDescribe()
    .fields.getMap();
  private static List<Schema.FieldSetMember> ditFieldsList = Schema.SObjectType.Data_Load_Record__c.fieldSets.Data_Import_Fields.getFields();
  private static List<Schema.FieldSetMember> ditRequiredList = Schema.SObjectType.Data_Load_Record__c.fieldSets.Data_Import_Required_Fields.getFields();
  private static Map<String, String> tetheredFieldMap = new Map<String, String>{
    'Organization_Name__c' => 'Organization_Id__c'
  };
  private static Set<String> emailFields = new Set<String>{
    'Email',
    'Alternate_Email__c',
    'Business_Email_2__c'
  };
  private static final String ERR_FETCH_CUSTOM_PERMISSION = 'DITCC_FETCH_CUSTOM_PERMISSION_FAILED';
  private static final String ERR_CHECK_UUID_PERMISSION = 'DITCC_CHECK_UUID_PERMISSION_FAILED';
  private static final String ERR_CHECK_CONFIDENTIAL_PERMISSION = 'DITCC_CHECK_CONFIDENTIAL_PERMISSION_FAILED';
  private static final String ERR_GET_COLUMNS = 'DITCC_GET_COLUMNS_FAILED';
  private static final String ERR_GET_SETUP_COLUMNS = 'DITCC_GET_SETUP_COLUMNS_FAILED';
  private static final String ERR_GET_PICKLISTS = 'DITCC_GET_PICKLISTS_FAILED';
  private static final String ERR_CREATE_ORG = 'DITCC_CREATE_ORG_FAILED';
  private static final String ERR_CREATE_CONTACT = 'DITCC_CREATE_CONTACT_FAILED';
  private static final String ERR_CREATE_NEW_DATA_LOAD = 'DITCC_CREATE_NEW_DATA_LOAD_FAILED';
  private static final String ERR_CHECK_IF_CONTACT_EXISTS = 'DITCC_CHECK_IF_CONTACT_EXISTS_FAILED';
  private static final String ERR_CREATE_NEW_EXCEL_ROWS = 'DITCC_CREATE_NEW_EXCEL_ROWS_FAILED';
  private static final String ERR_GET_VALIDATE_DUPES = 'DITCC_GET_VALIDATE_DUPES_FAILED';
  private static final String ERR_GET_CONTACTS_SUMMARY = 'DITCC_GET_CONTACTS_SUMMARY_FAILED';
  private static final String ERR_GET_IMPORTED_DETAIL = 'DITCC_GET_IMPORTED_DETAIL_FAILED';
  private static final String ERR_CREATE_WITH_LIST = 'DITCC_CREATE_WITH_LIST_FAILED';
  private static final String ERR_CREATE_LIST = 'DITCC_CREATE_LIST_FAILED';
  private static final String ERR_UPSERT_CONTACTS_LIST = 'DITCC_UPSERT_CONTACTS_LIST_FAILED';
  private static final String ERR_GET_DUPES = 'DITCC_GET_DUPES_FAILED';
  private static final String ERR_GET_PREVIOUS_DATA_LOADS = 'DITCC_GET_PREVIOUS_DATA_LOADS_FAILED';
  private static final String ERR_GET_EXCEL_COLUMNS = 'DITCC_GET_EXCEL_COLUMNS_FAILED';
  private static final String ERR_UPDATE_RECORDS = 'DITCC_UPDATE_RECORDS_FAILED';
  private static final String ERR_GET_COL_MAP = 'DITCC_GET_COL_MAP_FAILED';
  private static final String ERR_GET_DATA_LOAD = 'DITCC_GET_DATA_LOAD_FAILED';
  private static final String ERR_LOAD_UNCONFIRMED_DATA = 'DITCC_LOAD_UNCONFIRMED_DATA_FAILED';
  private static final String ERR_LOAD_PREVIEW_DATA = 'DITCC_LOAD_PREVIEW_DATA_FAILED';
  private static final String ERR_UPDATE_UPLOAD_DATA = 'DITCC_UPDATE_UPLOAD_DATA_FAILED';
  private static final String ERR_UPDATE_STAGE = 'DITCC_UPDATE_STAGE_FAILED';
  private static final String ERR_UPDATE_SETUP_COLUMNS = 'DITCC_UPDATE_SETUP_COLUMNS_FAILED';
  private static final String ERR_UPDATE_DATA = 'DITCC_UPDATE_DATA_FAILED';
  private static final String ERR_CHECK_SIGN_OTHER = 'DITCC_CHECK_SIGN_OTHER_FAILED';
  private static final String ERR_UPDATE_DATA_RECORD = 'DITCC_UPDATE_DATA_RECORD_FAILED';
  private static final String ERR_GET_MAP_SIGNIFICANT_OTHER = 'DITCC_GET_MAP_SIGNIFICANT_OTHER_FAILED';
  private static final String ERR_UPDATE_DATA_RECORDS = 'DITCC_UPDATE_DATA_RECORDS_FAILED';
  private static final String ERR_UPDATE_DIT_MEMBER = 'DITCC_UPDATE_DIT_MEMBER_FAILED';
  private static final String ERR_SAVE_ERROR_REPORT = 'DITCC_SAVE_ERROR_REPORT_FAILED';
  private static final String ERR_ERROR_REPORT_EMAIL = 'DITCC_ERROR_REPORT_EMAIL_FAILED';
  private static final String ERR_SET_CONTACT_DUPES = 'DITCC_SET_CONTACT_DUPES_FAILED';
  private static final String ERR_SET_ORG_DUPES = 'DITCC_SET_ORG_DUPES_FAILED';
  private static final String ERR_GET_ORG_MAP = 'DITCC_GET_ORG_MAP_FAILED';
  private static final String ERR_GET_CONTACT_MAP = 'DITCC_GET_CONTACT_MAP_FAILED';
  private static final String ERR_SET_ORGS = 'DITCC_SET_ORGS_FAILED';
  private static final String ERR_SET_CONTACTS = 'DITCC_SET_CONTACTS_FAILED';

  @AuraEnabled
  public static Map<String, boolean> fetchCustomPermission() {
    try {
      Map<String, boolean> mapCustomPermission = new Map<String, boolean>();
      mapCustomPermission.put(
        'Confidential_Info',
        FeatureManagement.checkPermission('Confidential_Info')
      );
      mapCustomPermission.put(
        'Contact_Home_Address',
        FeatureManagement.checkPermission('Contact_Home_Address')
      );
      mapCustomPermission.put(
        'Contact_UUID',
        FeatureManagement.checkPermission('Contact_UUID')
      );
      mapCustomPermission.put(
        'Contact_Home_Phone_Personal_Email',
        FeatureManagement.checkPermission('Contact_Home_Phone_Personal_Email')
      );
      return mapCustomPermission;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_FETCH_CUSTOM_PERMISSION)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }
  @AuraEnabled
  public static boolean checkUUIDPermission() {
    try {
      String userId = UserInfo.getUserId();
      return [
          SELECT PermissionSet.Name
          FROM PermissionSetAssignment
          WHERE
            AssigneeId = :userId
            AND PermissionSet.Name = 'Contact_Legacy_Source_System_access'
          WITH SYSTEM_MODE
        ]
        .size() > 0
        ? true
        : false;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_CHECK_UUID_PERMISSION)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }
  @AuraEnabled
  public static boolean checkConfidentialPermission() {
    try {
      String userId = UserInfo.getUserId();
      return [
          SELECT PermissionSet.Name
          FROM PermissionSetAssignment
          WHERE
            AssigneeId = :userId
            AND PermissionSet.Name = 'Contact_Confidential_Phone_Email'
          WITH SYSTEM_MODE
        ]
        .size() > 0
        ? true
        : false;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_CHECK_CONFIDENTIAL_PERMISSION)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }
  @AuraEnabled
  public static Object getColumns() {
    try {
      List<Map<String, Object>> colList = new List<Map<String, Object>>();
      Set<String> requiredSet = getRequiredFieldSet();
      for (Schema.FieldSetMember mem : ditFieldsList) {
        String api = mem.getFieldPath();
        if (isFieldValid(api)) {
          Map<String, Object> colMap = getColMap(mem, requiredSet);
          if (
            api == 'UUID__c' &&
            FeatureManagement.checkPermission('Contact_UUID')
          ) {
            colList.add(colMap);
          } else if (
            api == 'Personal_Email_2__c' &&
            FeatureManagement.checkPermission('Confidential_Info')
          ) {
            colList.add(colMap);
          } else if (
            api.StartsWith('Home') &&
            FeatureManagement.checkPermission('Contact_Home_Address')
          ) {
            colList.add(colMap);
          } else if (
            api == 'Personal_Email__c' &&
            FeatureManagement.checkPermission(
              'Contact_Home_Phone_Personal_Email'
            )
          ) {
            colList.add(colMap);
          } else if (
            api != 'UUID__c' &&
            api != 'Personal_Email_2__c' &&
            api != 'Personal_Email__c' &&
            !api.StartsWith('Home')
          ) {
            colList.add(colMap);
          }
        }
      }
      return colList;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_COLUMNS)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object getSetupColumns(String dataId) {
    try {
      Data_Load__c data = [
        SELECT Id, Column_Map__c
        FROM Data_Load__c
        WHERE Id = :dataId
        WITH SYSTEM_MODE
      ];
      return String.isNotBlank(data.Column_Map__c)
        ? JSON.deserializeUntyped(data.Column_Map__c)
        : null;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_SETUP_COLUMNS)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, String> getPickLists(
    String objectType,
    String selectedField
  ) {
    try {
      Map<String, String> pickListValuesMap = new Map<String, String>();
      Schema.SObjectType convertToObj = Schema.getGlobalDescribe()
        .get(objectType);
      Schema.DescribeSObjectResult res = convertToObj.getDescribe();
      Schema.DescribeFieldResult fieldResult;
      fieldResult = res.fields.getMap().get(selectedField).getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      for (Schema.PicklistEntry pickListVal : ple) {
        pickListValuesMap.put(pickListVal.getValue(), pickListVal.getLabel());
      }
      return pickListValuesMap;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_PICKLISTS)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }
  @AuraEnabled
  public static Object createOrg(String orgName, String dataLoaderId) {
    try {
      Account a = new Account();
      a.Legacy_Source_System__c = Assets.DATAIMPORTTOOL;
      a.DataLoadId__c = dataLoaderId;
      a.Name = orgName;
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;
      Database.insert(a, dml);
      return a;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_CREATE_ORG)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object createContact(
    String title,
    String firstName,
    String lastName,
    String myEmail,
    String assistantPhone,
    String assistantPhoneCode
  ) {
    try {
      Contact c = new Contact();
      c.Title = title;
      c.FirstName = firstName;
      c.LastName = lastName;
      c.Email = myEmail;
      c.AssistantPhone = assistantPhone;
      c.Phone = assistantPhone;
      c.Office_Phone_Country_Code__c = assistantPhoneCode;

      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;
      Database.SaveResult resultData = Database.insert(c, dml);
      if (!resultData.isSuccess()) {
        Database.Error error = resultData.getErrors().get(0);
        String failedDML = error.getMessage();
      }
      return c;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_CREATE_CONTACT)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object createNewDataLoad(
    String fileName,
    Map<String, String> columns
  ) {
    try {
      Data_Load__c dataLoad = new Data_Load__c();
      dataLoad.Name__c = fileName;
      dataLoad.Excel_Columns__c = JSON.serialize(columns);
      BBApps_Crud.doInsertWithHandling(
        new List<SObject>{ dataLoad },
        false,
        ERR_CREATE_NEW_DATA_LOAD
      );
      return dataLoad;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_CREATE_NEW_DATA_LOAD)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }
  @AuraEnabled
  public static Boolean checkIfContactExistInBRM(String UUID) {
    try {
      return [SELECT Id FROM Contact WHERE UUID__C = :UUID WITH SYSTEM_MODE]
        .Size() > 0;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_CHECK_IF_CONTACT_EXISTS)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object createNewExcelRows(
    String dataLoaderId,
    List<Map<String, String>> excelRows,
    String offset
  ) {
    try {
      Integer rowOffset = Integer.valueOf(offset);
      List<Data_Load_Record__c> recordList = new List<Data_Load_Record__c>();
      for (Integer i = 0; i < excelRows.size(); i++) {
        Map<String, String> row = excelRows.get(i);

        Data_Load_Record__c record = new Data_Load_Record__c();
        record.Data_Load__c = dataLoaderId;
        record.Excel_Row__c = JSON.serialize(row);
        record.Row_Index__c = i + rowOffset;
        recordList.add(record);
      }
      BBApps_Crud.doInsertWithHandling(
        recordList,
        false,
        ERR_CREATE_NEW_EXCEL_ROWS
      );
      return recordList;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_CREATE_NEW_EXCEL_ROWS)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object getValidateDupes(
    String dupeName,
    String row,
    String col,
    String objName
  ) {
    try {
      List<Map<String, Object>> result = new List<Map<String, Object>>();
      if (String.isBlank(dupeName)) {
        return result;
      }
      Integer rowNum = Integer.valueOf(row);
      Integer colNum = Integer.valueOf(col);
      if ('contact'.equalsIgnoreCase(objName)) {
        setContactDupes(dupeName, result, rowNum, colNum);
      } else {
        setOrgDupes(dupeName, result, rowNum, colNum);
      }

      return result;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_VALIDATE_DUPES)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  private static void setContactDupes(
    String contactName,
    List<Map<String, Object>> result,
    Integer row,
    Integer col
  ) {
    try {
      contactName = contactName.trim().normalizeSpace();
      List<String> nameParts = contactName.split(' ');
      String firstName = '';
      String lastName = '';
      if (nameParts.size() == 1) {
        lastName = nameParts[0];
      } else {
        firstName = nameParts[0];
        lastName = nameParts[nameParts.size() - 1];
      }
      String q = 'SELECT Id, Name, Email, FirstName_LastName__c, Title, Converted_Full_Name__c FROM Contact WHERE Converted_LastName__c LIKE: lastName';
      if (String.isNotBlank(firstName)) {
        q += ' AND (Converted_FirstName__c LIKE: firstName OR Preferred_First_Name__c LIKE: firstName)';
      }
      q += ' LIMIT 100';
      List<Contact> conList = (List<Contact>) Database.query(q);
      if (conList.isEmpty()) {
        return;
      }
      for (Contact c : conList) {
        Map<String, Object> dupeMap = new Map<String, Object>();
        dupeMap.put('name', c.FirstName_LastName__c);
        dupeMap.put('description', c.Email);
        dupeMap.put('id', c.Id);
        dupeMap.put('row', row);
        dupeMap.put('col', col);
        dupeMap.put('idx', result.size());
        result.add(dupeMap);
      }
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(
        e,
        new BBApps_ErrorCustomFields(ERR_SET_CONTACT_DUPES)
      );
    }
  }

  private static void setOrgDupes(
    String orgName,
    List<Map<String, Object>> result,
    Integer row,
    Integer col
  ) {
    try {
      orgName =
        '%' +
        String.escapeSingleQuotes(
          SpecialCharactersHelper.convertSpecialCharToEnglish(orgName)
        ) +
        '%';
      List<Account> orgList = [
        SELECT
          Id,
          Name,
          AKA__c,
          BillingStreet,
          BillingCity,
          BillingState,
          BillingPostalCode,
          BillingCountry,
          Converted_AKA__c,
          Converted_Org_Name__c
        FROM Account
        WHERE
          Converted_Org_Name__c LIKE :orgName
          OR Converted_AKA__c LIKE :orgName
        WITH SYSTEM_MODE
        ORDER BY NAME ASC
        LIMIT 200
      ];

      if (orgList.isEmpty()) {
        return;
      }
      for (Account org : orgList) {
        Map<String, Object> dupeMap = new Map<String, Object>();
        dupeMap.put('name', org.Name);
        dupeMap.put('description', org.AKA__c);
        dupeMap.put('street', org.BillingStreet);
        dupeMap.put('city', org.BillingCity);
        dupeMap.put('state', org.BillingState);
        dupeMap.put('postalcode', org.BillingPostalCode);
        dupeMap.put('country', org.BillingCountry);
        dupeMap.put('id', org.Id);
        dupeMap.put('row', row);
        dupeMap.put('col', col);
        dupeMap.put('idx', result.size());
        result.add(dupeMap);
      }
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(
        e,
        new BBApps_ErrorCustomFields(ERR_SET_ORG_DUPES)
      );
    }
  }

  /*
   *createList-  Method to create list view
   * @param: string listName : Listview Name
   * @return: name of the listview created
   * */
  @AuraEnabled
  public static String createList(String listName) {
    Campaign camp = new Campaign();
    camp.Name = listName;
    BBApps_Crud.doInsertWithHandling(
      new List<SObject>{ camp },
      false,
      ERR_CREATE_LIST
    );
    return camp.Id;
  }

  /*
   *getContactsSummary-  Method to query and seprate the differnt record we are going to create or update or use existing record
   * @param: string dataLoaderId :Dataload Record Id
   * @return: Map for all the different type of table data that we are showing in Summary table
   * */
  @AuraEnabled
  public static Object getContactsSummary(
    String dataLoaderId,
    Map<String, String> columnMap
  ) {
    try {
      Map<String, Object> result = new Map<String, Object>();

      Set<String> fieldSet = new Set<String>(columnMap.keySet());
      fieldSet.add('Id');
      fieldSet.add('Contact_Data__c');
      fieldSet.add('Contact_ID__c');
      fieldSet.add('Organization_Id__c');
      fieldSet.add('Organization_Name__c');
      fieldSet.add('Status__c');
      fieldSet.add('IsConfirmed__c');
      fieldSet.add('Source__c');
      fieldSet.add('Dietary__c');
      fieldSet.add('RSVP__c');
      fieldSet.add('Attendance__c');
      fieldSet.add('List_Member_Notes__c');
      fieldSet.add('Converted_FirstName__c');
      fieldSet.add('Converted_LastName__c');
      fieldSet.add('isAlredaySignificantOther__c');
      String q = 'SELECT ';
      Integer i = 0;
      Integer max = fieldSet.size() - 1;
      for (String field : fieldSet) {
        q += field;
        if (i < max) {
          q += ',';
        }
        i++;
      }
      q +=
        ' FROM Data_Load_Record__c WHERE Data_Load__c =: dataLoaderId AND Status__c NOT IN (\'Completed\') WITH SYSTEM_MODE ORDER BY Row_Index__c ASC LIMIT ' +
        1000;

      result.put('recordList', Database.query(q));
      result.put(
        'orgsList',
        [SELECT Id, Name FROM Account WHERE DataLoadId__c = :dataLoaderId]
      );
      return result;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_CONTACTS_SUMMARY)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object getImportedDetail(
    List<String> deletedContactIds,
    List<String> contactModifiedIds,
    List<String> contactIds,
    List<String> createIdList,
    String dataLoaderId,
    Map<String, String> columnMap
  ) {
    try {
      Map<String, Object> result = new Map<String, Object>();

      Set<String> fieldSet = new Set<String>(columnMap.keySet());
      fieldSet.add('Id');
      fieldSet.add('Contact_Data__c');
      fieldSet.add('Contact_ID__c');
      fieldSet.add('Organization_Id__c');
      fieldSet.add('Organization_Name__c');
      fieldSet.add('Status__c');
      fieldSet.add('IsConfirmed__c');
      fieldSet.add('Source__c');
      fieldSet.add('Dietary__c');
      fieldSet.add('Converted_FirstName__c');
      fieldSet.add('Converted_LastName__c');
      fieldSet.add('isAlredaySignificantOther__c');
      fieldSet.add('RSVP__c');
      fieldSet.add('Attendance__c');
      fieldSet.add('List_Member_Notes__c');
      String q = 'SELECT ';
      Integer i = 0;
      Integer max = fieldSet.size() - 1;
      for (String field : fieldSet) {
        q += field;
        if (i < max) {
          q += ',';
        }
        i++;
      }
      q +=
        ' FROM Data_Load_Record__c WHERE Data_Load__c =: dataLoaderId AND Status__c NOT IN (\'Completed\') WITH SYSTEM_MODE ORDER BY Row_Index__c ASC LIMIT ' +
        1000;

      List<Contact> createList = new List<Contact>();
      List<Contact> updateList = new List<Contact>();
      List<Contact> doNotContactList = new List<Contact>();
      List<Contact> deceasedContactList = new List<Contact>();
      List<Contact> deleteContactList = new List<Contact>();
      List<Contact> contactModifiedList = new List<Contact>();
      Map<String, String> mapDLRWithOrg = new Map<String, String>();
      Map<ID, Contact> conactMap = new Map<ID, Contact>(
        [
          SELECT Id, DoNotCall, Deceased__c
          FROM Contact
          WHERE Id IN :contactIds AND (DoNotCall = TRUE OR Deceased__c = TRUE)
          WITH SYSTEM_MODE
        ]
      );

      result.put('recordList', Database.query(q));
      result.put('conactMap', conactMap);
      result.put('createList', createList);
      result.put('updateList', updateList);
      result.put('doNotContactList', doNotContactList);
      result.put('deceasedContactList', deceasedContactList);
      result.put('deleteContactList', deleteContactList);
      result.put('contactModifiedList', contactModifiedList);
      return result;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_IMPORTED_DETAIL)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  /*
   *createWithList-  Method to create or update or use existing record
   * @param: string dataLoaderId :Dataload Record Id
   * @param: string listName :listName
   * @param: string batchSize :batchSize to insert record
   * @param: string offset :offset to insert record
   * */
  @AuraEnabled
  public static Object createWithList(
    String listId,
    String listName,
    String dataLoaderId,
    Map<String, String> columnMap,
    String offset,
    String batchSize
  ) {
    SavePoint sp = Database.setSavepoint();
    try {
      Map<String, Object> result = new Map<String, Object>();
      List<Data_Load_Record__c> dataList = getCreateDataRecords(
        dataLoaderId,
        offset,
        batchSize,
        columnMap
      );
      if (dataList.isEmpty()) {
        result.put('done', true);
        return result;
      }
      List<String> errList = upsertContactsList(
        dataList,
        offset,
        batchSize,
        columnMap,
        result,
        listId,
        listName
      );
      result.put('errors', errList);
      return result;
    } catch (Exception e) {
      Database.rollback(sp);
      BBApps_ErrorHandler.logErrors(
        e,
        new BBApps_ErrorCustomFields(ERR_CREATE_WITH_LIST)
      );
      throw new AuraHandledException(e.getMessage());
    }
  }

  /*
   *upsertContactsList-  Method to create or update or use existing record
   * @param: string dataLoaderId :Dataload Record Id
   * @param: string listName :listName
   * @param: string batchSize :batchSize to insert record
   * @param: string offset :offset to insert record
   * */
  private static List<String> upsertContactsList(
    List<Data_Load_Record__c> dataList,
    String offset,
    String batchSize,
    Map<String, String> columnMap,
    Map<String, Object> resultMap,
    String listId,
    String listName
  ) {
    List<Contact> createList = new List<Contact>();
    List<ContactDataLoadWrapper> createWrappers = getCreateContactWrapper(
      dataList,
      columnMap
    );
    for (ContactDataLoadWrapper cdw : createWrappers) {
      createList.add(cdw.contact);
    }
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    dml.DuplicateRuleHeader.runAsCurrentUser = true;
    dml.optAllOrNone = false;
    List<Database.SaveResult> contactCreateResults = Database.insert(
      createList,
      dml
    );
    List<String> createErrors = saveWithErrors(contactCreateResults);
    // BRME-5632: structured per-row errors for the report (maps each failure to its Data_Load_Record__c row).
    List<Map<String, Object>> rowErrors = saveWithRowErrors(
      contactCreateResults,
      (List<SObject>) createList,
      createWrappers,
      'Create'
    );
    if (String.isBlank(listId) && String.isNotBlank(listName)) {
      Campaign camp = new Campaign();
      camp.Name = listName;
      BBApps_Crud.doInsertWithHandling(
        new List<SObject>{ camp },
        false,
        ERR_UPSERT_CONTACTS_LIST
      );
      listId = camp.Id;
    }
    resultMap.put('createdTotal', createList.size());
    resultMap.put('createdSuccess', createList.size() - createErrors.size());
    List<ContactDataLoadWrapper> updateWrappers = getUpdateContactWrapper(
      dataList,
      columnMap
    );
    List<Contact> updateList = new List<Contact>();
    for (ContactDataLoadWrapper udw : updateWrappers) {
      updateList.add(udw.contact);
    }
    List<Database.SaveResult> updateListResult = Database.update(
      updateList,
      dml
    );
    List<String> updateErrors = saveWithErrors(updateListResult);
    // BRME-5632: structured per-row errors for the report.
    rowErrors.addAll(
      saveWithRowErrors(
        updateListResult,
        (List<SObject>) updateList,
        updateWrappers,
        'Update'
      )
    );
    resultMap.put('updatedTotal', updateList.size());
    resultMap.put('updatedSuccess', updateList.size() - updateErrors.size());
    createErrors.addAll(updateErrors);
    // BRME-5632: expose structured per-row errors for the client-side report.
    resultMap.put('rowErrors', rowErrors);
    if (String.isBlank(listId) && String.isBlank(listName))
      return createErrors;
    Map<Id, ContactDataLoadWrapper> successfulWrappersByContactId = new Map<Id, ContactDataLoadWrapper>();
    for (ContactDataLoadWrapper ctx : createWrappers) {
      if (ctx.contact.Id != null) {
        successfulWrappersByContactId.put(ctx.contact.Id, ctx);
      }
    }
    for (ContactDataLoadWrapper ctx : updateWrappers) {
      if (ctx.contact.Id != null) {
        successfulWrappersByContactId.put(ctx.contact.Id, ctx);
      }
    }
    Map<Id, CampaignMember> existingMembersByContactId = new Map<Id, CampaignMember>();
    for (CampaignMember cm : [
      SELECT
        Id,
        ContactId,
        CampaignId,
        Source__c,
        Dietary__c,
        RSVPStatus__c,
        AttendedStatus__c
      FROM CampaignMember
      WHERE
        CampaignId = :listId
        AND ContactId IN :successfulWrappersByContactId.keySet()
      WITH SYSTEM_MODE
    ]) {
      existingMembersByContactId.put(cm.ContactId, cm);
    }
    List<CampaignMember> membersToInsert = new List<CampaignMember>();
    List<CampaignMember> membersToUpdate = new List<CampaignMember>();
    for (Id contactId : successfulWrappersByContactId.keySet()) {
      ContactDataLoadWrapper cdw = successfulWrappersByContactId.get(contactId);
      Contact c = cdw.contact;
      Data_Load_Record__c data = cdw.dataLoadRecord;
      if (existingMembersByContactId.containsKey(contactId)) {
        CampaignMember existingCm = existingMembersByContactId.get(contactId);
        Boolean changed = false;
        if (
          String.isNotBlank(existingCm.Source__c) &&
          String.isNotBlank(data.Source__c) &&
          !existingCm.Source__c.endsWith(data.Source__c)
        ) {
          existingCm.Source__c = existingCm.Source__c + '; ' + data.Source__c;
          changed = true;
        } else if (String.isNotBlank(data.Source__c)) {
          existingCm.Source__c = data.Source__c;
          changed = true;
        }
        if (String.isNotBlank(data.Dietary__c)) {
          existingCm.Dietary__c = data.Dietary__c;
          changed = true;
        }
        if (
          String.isNotBlank(data.RSVP__c) &&
          String.isBlank(existingCm.RSVPStatus__c)
        ) {
          existingCm.RSVPStatus__c = data.RSVP__c;
          changed = true;
        }
        if (
          String.isNotBlank(data.Attendance__c) &&
          String.isBlank(existingCm.AttendedStatus__c)
        ) {
          existingCm.AttendedStatus__c = data.Attendance__c;
          changed = true;
        }
        if (String.isNotBlank(data.List_Member_Notes__c)) {
          existingCm.UB_Notes__c = data.List_Member_Notes__c;
          changed = true;
        }
        if (changed)
          membersToUpdate.add(existingCm);
      } else {
        CampaignMember newCM = new CampaignMember();
        newCM.CampaignId = listId;
        newCM.ContactId = contactId;
        newCM.Source__c = data.Source__c;
        newCM.Dietary__c = data.Dietary__c;
        newCM.RSVPStatus__c = data.RSVP__c;
        newCM.AttendedStatus__c = data.Attendance__c;
        newCM.UB_Notes__c = data.List_Member_Notes__c;
        membersToInsert.add(newCM);
      }
    }
    // BRME-5632: map each list-member operation back to its source DIT row for the error workbook.
    Set<Id> memberContactIds = new Set<Id>();
    for (CampaignMember member : membersToInsert) {
      memberContactIds.add(member.ContactId);
    }
    for (CampaignMember member : membersToUpdate) {
      memberContactIds.add(member.ContactId);
    }
    Set<Id> memberDataLoadRecordIds = new Set<Id>();
    for (Id memberContactId : memberContactIds) {
      ContactDataLoadWrapper wrapper = successfulWrappersByContactId.get(
        memberContactId
      );
      if (wrapper != null && wrapper.dataLoadRecord != null) {
        memberDataLoadRecordIds.add(wrapper.dataLoadRecord.Id);
      }
    }
    Map<Id, Data_Load_Record__c> memberDataLoadRecords = new Map<Id, Data_Load_Record__c>();
    if (!memberDataLoadRecordIds.isEmpty()) {
      memberDataLoadRecords = new Map<Id, Data_Load_Record__c>([
        SELECT Id, Row_Index__c, Excel_Row__c
        FROM Data_Load_Record__c
        WHERE Id IN :memberDataLoadRecordIds
        WITH SYSTEM_MODE
      ]);
    }
    Map<String, Object> memberErrorContext = new Map<String, Object>();
    for (Id memberContactId : memberContactIds) {
      ContactDataLoadWrapper wrapper = successfulWrappersByContactId.get(
        memberContactId
      );
      Data_Load_Record__c sourceRow = wrapper != null &&
        wrapper.dataLoadRecord != null
        ? memberDataLoadRecords.get(wrapper.dataLoadRecord.Id)
        : null;
      if (sourceRow != null) {
        memberErrorContext.put(
          String.valueOf(memberContactId),
          new Map<String, Object>{
            'rowId' => sourceRow.Id,
            'rowIndex' => sourceRow.Row_Index__c,
            'excelRow' => sourceRow.Excel_Row__c
          }
        );
      }
    }
    resultMap.put('memberErrorContext', memberErrorContext);
    resultMap.put('listTotal', membersToInsert.size() + membersToUpdate.size());
    resultMap.put('memListToCreate', membersToInsert);
    resultMap.put('memListToUpdate', membersToUpdate);
    for (Data_Load_Record__c rec : dataList) {
      if (!'Deleted'.equalsIgnoreCase(rec.Status__c))
        rec.Status__c = 'Completed';
    }
    BBApps_Crud.doUpdateWithHandling(dataList, false, ERR_UPSERT_CONTACTS_LIST);
    return createErrors;
  }

  private class ContactDataLoadWrapper {
    public Contact contact;
    public Data_Load_Record__c dataLoadRecord;

    public ContactDataLoadWrapper(
      Contact contact,
      Data_Load_Record__c dataLoadRecord
    ) {
      this.contact = contact;
      this.dataLoadRecord = dataLoadRecord;
    }
  }

  @AuraEnabled
  public static Integer upsertMemberRecords(
    List<CampaignMember> listMembersToCreate,
    List<CampaignMember> listMembersToUpdate
  ) {
    Integer successCount = 0;
    try {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;
      dml.optAllOrNone = false;
      if (!listMembersToUpdate.isEmpty()) {
        List<Database.SaveResult> updateListResult = Database.update(
          listMembersToUpdate,
          dml
        );
        successCount = (listMembersToUpdate.size() -
        saveWithErrors(updateListResult).size());
      }
      if (!listMembersToCreate.isEmpty()) {
        List<Database.SaveResult> createListResult = Database.insert(
          listMembersToCreate,
          dml
        );
        successCount += (listMembersToCreate.size() -
        saveWithErrors(createListResult).size());
      }
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_UPDATE_DIT_MEMBER)
      );
    }
    return successCount;
  }

  // BRME-5632: member upsert that ALSO returns structured per-row errors (previously swallowed). Maps each
  // failed CampaignMember back to its Contact via ContactId so the client can link it to the source row.
  @AuraEnabled
  public static Map<String, Object> upsertMemberRecordsWithErrors(
    List<CampaignMember> listMembersToCreate,
    List<CampaignMember> listMembersToUpdate
  ) {
    Map<String, Object> result = new Map<String, Object>();
    List<Map<String, Object>> rowErrors = new List<Map<String, Object>>();
    Integer successCount = 0;
    try {
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;
      dml.optAllOrNone = false;
      if (!listMembersToUpdate.isEmpty()) {
        List<Database.SaveResult> res = Database.update(
          listMembersToUpdate,
          dml
        );
        rowErrors.addAll(
          saveWithRowErrors(
            res,
            (List<SObject>) listMembersToUpdate,
            null,
            'List Member'
          )
        );
        successCount += (listMembersToUpdate.size() - rowErrors.size());
      }
      if (!listMembersToCreate.isEmpty()) {
        List<Database.SaveResult> res = Database.insert(
          listMembersToCreate,
          dml
        );
        Integer before = rowErrors.size();
        rowErrors.addAll(
          saveWithRowErrors(
            res,
            (List<SObject>) listMembersToCreate,
            null,
            'List Member'
          )
        );
        successCount += (listMembersToCreate.size() -
        (rowErrors.size() - before));
      }
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_UPDATE_DIT_MEMBER)
      );
    }
    result.put('successCount', successCount);
    result.put('rowErrors', rowErrors);
    return result;
  }

  // BRME-5632: persist the generated error-report .xlsx as a ContentVersion attached to the Data_Load__c
  // (so it is re-downloadable from the record), then email it to the importing user. Returns the ContentDocumentId.
  @AuraEnabled
  public static String saveErrorReport(
    Id dataLoadId,
    String fileName,
    String base64Data
  ) {
    try {
      Blob reportBody = EncodingUtil.base64Decode(base64Data);
      ContentVersion cv = new ContentVersion(
        Title = fileName,
        PathOnClient = fileName,
        VersionData = reportBody,
        FirstPublishLocationId = dataLoadId
      );
      insert cv;
      String docId = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
      ]
      .ContentDocumentId;
      // BRME-5632: email the importing user with the report attached (best-effort — never rolls back the insert above)
      sendErrorReportEmail(fileName, reportBody);
      return docId;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_SAVE_ERROR_REPORT)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  // BRME-5632: send the "Action Required: DIT Import Errors Detected" email to the user who ran the import,
  // with the generated error report attached. From the BP Salesforce Team org-wide address when one exists in
  // this org (sandboxes may not have a verified one — falls back to the running user). No CC/BCC is sent.
  // Best-effort: failures are logged, never thrown, so the already-saved ContentVersion is not rolled back.
  private static void sendErrorReportEmail(String fileName, Blob reportBody) {
    try {
      EmailTemplate tpl = [
        SELECT Id
        FROM EmailTemplate
        WHERE DeveloperName = 'DIT_Import_Errors_Template'
        LIMIT 1
      ];
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setTemplateId(tpl.Id);
      mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() }); // BRME-5632: To the importing user only — no CC/BCC during initial testing
      mail.setTargetObjectId(UserInfo.getUserId()); // {!User.*} merge fields resolve to the importing user
      mail.setSaveAsActivity(false); // activities cannot be logged against a User recipient
      List<OrgWideEmailAddress> owea = [
        SELECT Id
        FROM OrgWideEmailAddress
        WHERE Address LIKE 'bpsalesforceteam@%'
        LIMIT 1
      ];
      if (!owea.isEmpty()) {
        mail.setOrgWideEmailAddressId(owea[0].Id);
      }
      Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
      att.setFileName(fileName);
      att.setBody(reportBody);
      att.setContentType(
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      );
      mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ att });
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_ERROR_REPORT_EMAIL)
      );
    }
  }

  private static List<String> saveWithErrors(Database.SaveResult[] srList) {
    List<String> errList = new List<String>();
    for (Database.SaveResult sr : srList) {
      if (sr.isSuccess() == false) {
        for (Database.Error err : sr.getErrors()) {
          String msg = err.getStatusCode() + ': ' + err.getMessage();
          errList.add(msg);
        }
      }
    }
    return errList;
  }

  // BRME-5632: structured per-row error capture. Maps each failed Database.SaveResult back to its source
  // Data_Load_Record__c (via the parallel input list index) so every import error is attributable to the
  // correct original upload row. Returns a list of maps: {rowId, rowIndex, operation, recordId, fields, statusCode, message}.
  private static List<Map<String, Object>> saveWithRowErrors(
    Database.SaveResult[] srList,
    List<SObject> inputRecords,
    List<ContactDataLoadWrapper> wrappers,
    String operation
  ) {
    List<Map<String, Object>> rowErrors = new List<Map<String, Object>>();
    // BRME-5632: collect the failed row Ids first so we can reliably pull each original Excel_Row__c JSON
    // (the wrapper's in-memory record may not have been queried with that field).
    Set<Id> failedRowIds = new Set<Id>();
    for (Integer i = 0; i < srList.size(); i++) {
      if (srList[i].isSuccess())
        continue;
      if (
        wrappers != null &&
        i < wrappers.size() &&
        wrappers[i].dataLoadRecord != null
      ) {
        failedRowIds.add(wrappers[i].dataLoadRecord.Id);
      }
    }
    Map<Id, String> excelRowById = new Map<Id, String>();
    if (!failedRowIds.isEmpty()) {
      for (Data_Load_Record__c r : [
        SELECT Id, Excel_Row__c
        FROM Data_Load_Record__c
        WHERE Id IN :failedRowIds
      ]) {
        excelRowById.put(r.Id, r.Excel_Row__c);
      }
    }
    for (Integer i = 0; i < srList.size(); i++) {
      Database.SaveResult sr = srList[i];
      if (sr.isSuccess())
        continue;
      SObject inputRecord = (inputRecords != null && i < inputRecords.size())
        ? inputRecords[i]
        : null;
      Data_Load_Record__c dlr = (wrappers != null &&
        i < wrappers.size())
        ? wrappers[i].dataLoadRecord
        : null;
      // Row_Index__c may not be on the wrapper's record (unqueried field) — read defensively.
      Object rowIdx = null;
      if (dlr != null) {
        try {
          rowIdx = dlr.get('Row_Index__c');
        } catch (Exception ignore) {
          rowIdx = null;
        }
      }
      for (Database.Error err : sr.getErrors()) {
        Map<String, Object> e = new Map<String, Object>();
        e.put('operation', operation);
        e.put('statusCode', String.valueOf(err.getStatusCode()));
        e.put('message', err.getMessage());
        e.put(
          'fields',
          err.getFields() != null ? String.join(err.getFields(), ',') : ''
        );
        e.put('recordId', sr.getId());
        Object contactId = inputRecord != null ? inputRecord.Id : sr.getId();
        Object listMemberId;
        Object listId;
        if (
          operation == 'List Member' &&
          inputRecord != null &&
          inputRecord.getSObjectType() == CampaignMember.SObjectType
        ) {
          CampaignMember failedMember = (CampaignMember) inputRecord;
          contactId = failedMember.ContactId;
          listMemberId = failedMember.Id != null ? failedMember.Id : sr.getId();
          listId = failedMember.CampaignId;
        }
        e.put('contactId', contactId);
        e.put('listMemberId', listMemberId);
        e.put('listId', listId);
        e.put('rowId', dlr != null ? dlr.Id : null);
        e.put('rowIndex', rowIdx);
        // BRME-5632: include the original uploaded Excel row JSON so the error report lists all DIT columns
        String excelRow = (dlr != null) ? excelRowById.get(dlr.Id) : null;
        e.put('excelRow', excelRow);
        rowErrors.add(e);
      }
    }
    return rowErrors;
  }

  private static List<ContactDataLoadWrapper> getUpdateContactWrapper(
    List<Data_Load_Record__c> dataList,
    Map<String, String> columnMap
  ) {
    List<ContactDataLoadWrapper> updateWrapper = new List<ContactDataLoadWrapper>();
    Set<Id> conIds = new Set<Id>();
    Map<Id, Data_Load_Record__c> mapDatLROrg = new Map<Id, Data_Load_Record__c>(
      [
        SELECT
          Id,
          Significant_Other_Link__c,
          Dietary__c,
          Source__c,
          Significant_Other__c,
          Organization_Id__c,
          RSVP__c,
          Attendance__c,
          List_Member_Notes__c
        FROM Data_Load_Record__c
        WHERE Id IN :dataList
        WITH SYSTEM_MODE
      ]
    );
    for (Data_Load_Record__c data : dataList) {
      if (isUpdate(data)) {
        Contact c = String.isNotBlank(data.Contact_Data__c)
          ? getUpdateContact(data, mapDatLROrg, columnMap)
          : new Contact(Id = data.Contact_ID__c);
        if (c != null && !conIds.contains(c.Id)) {
          conIds.add(c.Id);
          updateWrapper.add(new ContactDataLoadWrapper(c, data));
        }
      }
    }
    return updateWrapper;
  }

  private static List<ContactDataLoadWrapper> getCreateContactWrapper(
    List<Data_Load_Record__c> dataList,
    Map<String, String> columnMap
  ) {
    List<ContactDataLoadWrapper> createWrapper = new List<ContactDataLoadWrapper>();
    for (Data_Load_Record__c data : dataList) {
      if (isCreate(data)) {
        Contact c = getDataContact(data, columnMap);
        c.Legacy_Source_System__c = Assets.DATAIMPORTTOOL;
        createWrapper.add(new ContactDataLoadWrapper(c, data));
      }
    }
    return createWrapper;
  }

  /*
   *getUpdateContact-  Method to get records to update
   * @param: string dataList :dataList data load Record list to update
   * @param: string columnMap :columnMap map of field from data laod record and contact
   * */
  public static Contact getUpdateContact(
    Data_Load_Record__c data,
    Map<ID, Data_Load_Record__c> mapDatLROrg,
    Map<String, String> columnMap
  ) {
    Contact c = new Contact();

    Map<String, Object> conMap = (Map<String, Object>) JSON.deserializeUntyped(
      data.Contact_Data__c
    );
    List<Object> fieldList = (List<Object>) conMap.get('fields');
    String conId = '';
    Boolean hasUpdate = false;
    for (Object field : fieldList) {
      Map<String, Object> fieldMap = (Map<String, Object>) field;
      if (String.isBlank(conId)) {
        conId = (String) fieldMap.get('contactId');
      }

      Boolean isShow = Boolean.valueOf(fieldMap.get('isShow'));
      String fieldApi = (String) fieldMap.get('api');
      if (isShow) {
        Map<String, Object> excelMap = (Map<String, Object>) fieldMap.get(
          'excel'
        );
        Map<String, Object> sfMap = (Map<String, Object>) fieldMap.get('sf');
        Boolean isExcelSelected = false;
        if (excelMap.get('isSelected') != null)
          isExcelSelected = Boolean.valueOf(excelMap.get('isSelected'));
        if (isExcelSelected == true) {
          hasUpdate = true;
          String value = (String) fieldMap.get('id');
          value = String.isBlank(value)
            ? (String) excelMap.get('value')
            : value;

          if (fieldApi == 'Organization_Name__c') {
            value = mapDatLROrg.ContainsKey(data.Id)
              ? mapDatLROrg.get(data.Id).Organization_Id__c
              : '';
            c.put('AccountId', value);
          } else if (fieldApi == 'Significant_Other__c') {
            value = mapDatLROrg.ContainsKey(data.Id)
              ? mapDatLROrg.get(data.Id).Significant_Other_Link__c
              : data.Significant_Other_Link__c;
            c.put(columnMap.get(fieldApi), value);
          } else
            c.put(columnMap.get(fieldApi), value);
        }
      }
    }

    c.Id = conId;
    return c;
  }

  private static Contact getDataContact(
    Data_Load_Record__c data,
    Map<String, String> columnMap
  ) {
    Contact c = new Contact();
    for (String field : columnMap.keySet()) {
      String conField = columnMap.get(field);
      field = tetheredFieldMap.containsKey(field)
        ? tetheredFieldMap.get(field)
        : field;
      c.put(conField, data.get(field));
    }
    return c;
  }

  public static Boolean isUpdate(Data_Load_Record__c data) {
    Boolean isUpdate = false;
    if (String.isNotBlank(data.Contact_Data__c)) {
      Map<String, Object> conMap = (Map<String, Object>) JSON.deserializeUntyped(
        data.Contact_Data__c
      );
      isUpdate =
        !'true'.equalsIgnoreCase(String.valueOf(conMap.get('isDeleted'))) &&
        !'true'.equalsIgnoreCase(String.valueOf(conMap.get('isCreate'))) &&
        data.IsConfirmed__c;
    } else if (data.IsConfirmed__c && data.Contact_ID__c != null) {
      isUpdate = true;
    }
    return isUpdate;
  }

  public static Boolean isCreate(Data_Load_Record__c data) {
    if ('Skipped'.equalsIgnoreCase(data.Status__c)) {
      return false;
    }
    if (String.isBlank(data.Contact_Data__c) && !data.IsConfirmed__c) {
      return true;
    }
    if (String.isNotBlank(data.Contact_Data__c)) {
      Map<String, Object> conMap = (Map<String, Object>) JSON.deserializeUntyped(
        data.Contact_Data__c
      );
      if ('true'.equalsIgnoreCase(String.valueOf(conMap.get('isDeleted'))))
        return false;
      return 'true'.equalsIgnoreCase(String.valueOf(conMap.get('isCreate'))) ||
        !data.IsConfirmed__c;
    } else {
      return false;
    }
  }

  private static List<Data_Load_Record__c> getCreateDataRecords(
    String dataLoaderId,
    String offset,
    String batchSize,
    Map<String, String> columnMap
  ) {
    Integer rowOffset = Integer.valueOf(offset);
    Integer maxSize = Integer.valueOf(batchSize) + rowOffset;
    Set<String> fieldSet = new Set<String>(columnMap.keySet());
    fieldSet.add('Id');
    fieldSet.add('Contact_Data__c');
    fieldSet.add('Contact_ID__c');
    fieldSet.add('IsConfirmed__c');
    fieldSet.add('Organization_Id__c');
    fieldSet.add('Organization_Name__c');
    fieldSet.add('Status__c');
    fieldSet.add('Significant_Other__c');
    fieldSet.add('Significant_Other_Link__c');
    fieldSet.add('Source__c');
    fieldSet.add('Dietary__c');
    fieldSet.add('Converted_FirstName__c');
    fieldSet.add('Converted_LastName__c');
    fieldSet.add('isAlredaySignificantOther__c');
    fieldSet.add('RSVP__c');
    fieldSet.add('Attendance__c');
    fieldSet.add('List_Member_Notes__c');

    String q = 'SELECT ';
    Integer i = 0;
    Integer max = fieldSet.size() - 1;
    for (String field : fieldSet) {
      q += field;
      if (i < max) {
        q += ',';
      }
      i++;
    }
    q +=
      ' FROM Data_Load_Record__c WHERE Data_Load__c =: dataLoaderId AND Status__c NOT IN ( \'Deleted\') WITH SYSTEM_MODE ORDER BY Row_Index__c ASC LIMIT ' +
      batchSize +
      ' OFFSET ' +
      offset;
    return (List<Data_Load_Record__c>) Database.query(q);
  }

  /*
   *getDupes-  Method to get duplicate records
   * @param: string dataList :dataList data load Record list to update
   * @param: string columnMap :columnMap map of field from data laod record and contact
   * */
  @AuraEnabled
  public static Object getDupes(
    Map<String, Map<String, String>> contactMap,
    Map<String, String> columnMap
  ) {
    try {
      Map<String, List<Contact>> dupeMap = new Map<String, List<Contact>>();
      List<Contact> contactList = getDupeContactList(contactMap, columnMap);
      return contactList;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_DUPES)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  private static List<Contact> getDupeContactList(
    Map<String, Map<String, String>> contactMap,
    Map<String, String> columnMap
  ) {
    String q = 'SELECT Id';
    Set<String> firstNames = new Set<String>();
    Set<String> emails = new Set<String>();
    Set<String> lastNames = new Set<String>();
    Set<String> businessEmails = new Set<String>();
    Set<String> fields = new Set<String>();
    Set<String> uuids = new Set<String>();
    Set<String> ConvertedFullName = new Set<String>();
    for (String key : contactMap.keySet()) {
      Map<String, String> contact = contactMap.get(key);
      if (String.isNotBlank(contact.get('First_Name__c'))) {
        firstNames.add(contact.get('First_Name__c').trim());
      }
      if (String.isNotBlank(contact.get('Last_Name__c'))) {
        lastNames.add(contact.get('Last_Name__c').trim());
      }
      if (String.isNotBlank(contact.get('Business_Email__c'))) {
        emails.add(contact.get('Business_Email__c'));
      }
      if (String.isNotBlank(contact.get('Converted_Full_Name__c'))) {
        ConvertedFullName.add(contact.get('Converted_Full_Name__c'));
      }
      if (String.isNotBlank(contact.get('UUID__c'))) {
        uuids.add(contact.get('UUID__c'));
      }
    }
    for (String key : columnMap.keySet()) {
      String field = columnMap.get(key);
      fields.add(field);
    }
    fields.add('Email');
    fields.add('Alternate_Email__c');
    fields.add('Personal_Email_2__c');
    fields.add('Web_Email__c');
    fields.add('Business_Email_2__c');
    fields.add('Significant_Name__c');
    fields.add('Converted_LastName__c');
    fields.add('Converted_FirstName__c');
    fields.add('Converted_Full_Name__c');
    fields.add('UUID__c');
    // BRME-6993: read-only additions so the Compare stage can evaluate the different-organization
    // warning + conditional highlight conditions (existing BRM values only). No logic change.
    fields.add('Phone');
    fields.add('Use_Same_Address_as_Organization__c');
    fields.add('MailingStreet');
    fields.add('MailingCity');
    fields.add('MailingState');
    fields.add('MailingPostalCode');
    fields.add('MailingCountry');
    for (String f : fields) {
      q += ',' + f;
    }
    q +=
      ' , Name_Hyperlink__c, Touchpoint_sum__c, Account.Name ' +
      'FROM Contact ' +
      'WHERE ' +
      '(UUID__c IN :uuids) ' +
      'OR (Personal_Email_2__c IN :emails) ' +
      'OR (Business_Email_2__c IN :emails) ' +
      'OR (Alternate_Email__c IN :emails) ' +
      'OR (Email IN :emails) ' +
      'OR (Name IN :ConvertedFullName) ' +
      'OR (Converted_Full_Name__c IN :ConvertedFullName) ' +
      'OR ( ' +
      '      (Converted_FirstName__c LIKE :firstNames OR Preferred_First_Name__c LIKE :firstNames) ' +
      '      AND Converted_LastName__c LIKE :lastNames ' +
      '   ) ' +
      'OR ( ' +
      '      (FirstName LIKE :firstNames OR Preferred_First_Name__c LIKE :firstNames) ' +
      '      AND LastName LIKE :lastNames ' +
      '   ) ' +
      'ORDER BY Name ASC ' +
      'LIMIT 10000';
    List<Contact> contactList = (List<Contact>) Database.query(q);
    return contactList;
  }

  @AuraEnabled
  public static Object getPreviousDataLoads() {
    try {
      List<Map<String, String>> prevList = new List<Map<String, String>>();
      List<Data_Load__c> dataList = [
        SELECT Id, Name__c, Stage__c, CreatedBy.Name, LastModifiedDate
        FROM Data_Load__c
        WHERE Stage__c != 'Complete' AND Stage__c != NULL
        WITH SYSTEM_MODE
        ORDER BY LastModifiedDate DESC
        LIMIT 100
      ];
      for (Data_Load__c data : dataList) {
        Map<String, String> optMap = new Map<String, String>();
        String myLabel = getFileLabel(data.Name__c, '');
        myLabel += getFileLabel(data.Stage__c, myLabel);
        myLabel += getFileLabel(data.CreatedBy.Name, myLabel);
        myLabel += getFileLabel(data.LastModifiedDate.format(), myLabel);
        optMap.put('label', myLabel);
        optMap.put('value', data.Id);
        prevList.add(optMap);
      }
      return prevList;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_PREVIOUS_DATA_LOADS)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object getExcelColumns(String dataId) {
    try {
      Data_Load__c data = [
        SELECT Id, Excel_Columns__c
        FROM Data_Load__c
        WHERE Id = :dataId
        WITH SYSTEM_MODE
      ];
      return JSON.deserializeUntyped(data.Excel_Columns__c);
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_EXCEL_COLUMNS)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object updateRecords(
    String dataId,
    List<Object> excelColumns,
    String offset,
    String batchSize
  ) {
    Integer rowOffset = Integer.valueOf(offset);
    Integer maxSize = Integer.valueOf(batchSize) + rowOffset;
    Map<String, String> colMap = getSFtoExcelColMap(excelColumns);
    List<Data_Load_Record__c> records = [
      SELECT Id, Row_Index__c, Excel_Row__c, Organization_Id__c
      FROM Data_Load_Record__c
      WHERE
        Data_Load__c = :dataId
        AND Row_Index__c >= :rowOffset
        AND Row_Index__c < :maxSize
      WITH SYSTEM_MODE
      ORDER BY Row_Index__c ASC
    ];
    if (records.isEmpty())
      return null;
    List<Data_Load_Record__c> updateRecords = new List<Data_Load_Record__c>();
    for (Integer i = 0; i < records.size(); i++) {
      Data_Load_Record__c newRec = getNewRecord(records[i], colMap);
      updateRecords.add(newRec);
    }
    update updateRecords;
    return updateRecords;
  }

  private static Map<String, String> getSFtoExcelColMap(
    List<Object> excelColumns
  ) {
    Map<String, String> colMap = new Map<String, String>();
    for (Object excelObj : excelColumns) {
      Map<Object, Object> excelMap = getExcelMap(excelObj);
      List<Object> cells = (List<Object>) excelMap.get('cells');
      Map<Object, Object> excelCell = getExcelMap(cells.get(1));
      String api = (String) excelCell.get('api');
      String val = (String) excelCell.get('value');
      if (String.isNotBlank(val)) {
        colMap.put(api, val);
      }
    }
    return colMap;
  }

  private static Map<Object, Object> getExcelMap(Object excelObj) {
    try {
      Map<Object, Object> excelMap = (Map<Object, Object>) excelObj;
      return excelMap;
    } catch (Exception e) {
      Map<Object, Object> excelMap = new Map<Object, Object>();
      Map<String, Object> temp = (Map<String, Object>) excelObj;
      for (String key : temp.keySet()) {
        excelMap.put((Object) key, temp.get(key));
      }
      return excelMap;
    }
  }

  public static Data_Load_Record__c getNewRecord(
    Data_Load_Record__c record,
    Map<String, String> colMap
  ) {
    Map<String, Object> excelRow = (Map<String, Object>) JSON.deserializeUntyped(
      record.Excel_Row__c
    );
    Data_Load_Record__c newRec = new Data_Load_Record__c();
    newRec.Id = record.Id;
    for (String api : colMap.keySet()) {
      String valKey = colMap.get(api);
      String val = excelRow.get(valKey) != null
        ? String.valueOf(excelRow.get(valKey))
        : '';
      if (String.isNotBlank(api)) {
        newRec.put(api, val);
      }
    }
    return newRec;
  }

  @AuraEnabled
  public static Object getColMap(String dataId) {
    try {
      Data_Load__c data = [
        SELECT Id, Column_Map__c
        FROM Data_Load__c
        WHERE Id = :dataId
        WITH SYSTEM_MODE
      ];
      return String.isNotBlank(data.Column_Map__c)
        ? JSON.deserializeUntyped(data.Column_Map__c)
        : null;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_COL_MAP)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Data_Load__c getDataLoad(Id dataId) {
    try {
      return [
        SELECT
          Id,
          Name__c,
          Stage__c,
          Column_Map__c,
          CreatedBy.Name,
          LastModifiedDate
        FROM Data_Load__c
        WHERE Stage__c != 'Complete' AND Stage__c != NULL AND Id = :dataId
        WITH SYSTEM_MODE
        ORDER BY LastModifiedDate DESC
        LIMIT 100
      ];
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_DATA_LOAD)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  private static String getFileLabel(String input, String label) {
    String myLabel = String.isNotBlank(input) ? input : '';
    if (String.isNotBlank(myLabel) && String.isNotBlank(label)) {
      myLabel = ' | ' + myLabel;
    }
    return myLabel;
  }

  @AuraEnabled
  public static Object loadUnconfirmedData(String dataLoadId) {
    try {
      Map<String, Object> result = new Map<String, Object>();
      Data_Load__c dataLoad = getDataLoad(dataLoadId);
      Map<String, String> colMap = getSFtoExcelColMap(
        (List<Object>) JSON.deserializeUntyped(dataLoad.Column_Map__c)
      );
      result.put('colMap', colMap);
      List<Data_Load_Record__c> records = getPreviewRecords(colMap, dataLoadId);
      Map<String, Map<Id, String>> orgMap = getOrgMap(records);
      result.put('orgs', orgMap);
      result.put('UUIDList', getUUIDMap(records));
      setOrgs(records, orgMap);
      Map<String, Map<Id, String>> contactMap = getContactMap(records);
      result.put('contacts', contactMap);
      result.put('records', records);
      return result;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_LOAD_UNCONFIRMED_DATA)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object loadPreviewData(String dataLoadId) {
    return loadPreviewCore(dataLoadId, false);
  }

  // BRME-4862: Preview-stage load that returns only rows with validation errors,
  // so large files don't serialize/render rows that need no action.
  @AuraEnabled
  public static Object loadPreviewErrorData(String dataLoadId) {
    return loadPreviewCore(dataLoadId, true);
  }

  private static Object loadPreviewCore(String dataLoadId, Boolean errorsOnly) {
    try {
      Map<String, Object> result = new Map<String, Object>();
      Data_Load__c dataLoad = getDataLoad(dataLoadId);
      Map<String, String> colMap = getSFtoExcelColMap(
        (List<Object>) JSON.deserializeUntyped(dataLoad.Column_Map__c)
      );
      result.put('colMap', colMap);
      List<Data_Load_Record__c> records = getPreviewRecords(colMap, dataLoadId);
      if (errorsOnly) {
        records = filterPreviewErrorRecords(records);
      }
      Map<String, Map<Id, String>> orgMap = new Map<String, Map<Id, String>>();
      result.put('orgs', orgMap);
      Map<String, Map<Id, String>> contactMap = new Map<String, Map<Id, String>>();
      result.put('contacts', contactMap);
      result.put('records', records);
      return result;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_LOAD_PREVIEW_DATA)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  // BRME-4862: mirrors the client-side Preview validation
  // (DITValidationCmpHelper.getCell + DITWorker.validateCell) so only rows that
  // would surface an error in Preview are returned.
  private static List<Data_Load_Record__c> filterPreviewErrorRecords(
    List<Data_Load_Record__c> records
  ) {
    List<Map<String, Object>> columns = (List<Map<String, Object>>) getColumns();
    List<Data_Load_Record__c> errorRecords = new List<Data_Load_Record__c>();
    for (Data_Load_Record__c record : records) {
      if (hasPreviewError(record, columns)) {
        errorRecords.add(record);
      }
    }
    return errorRecords;
  }

  private static Boolean hasPreviewError(
    Data_Load_Record__c record,
    List<Map<String, Object>> columns
  ) {
    Set<String> columnApis = new Set<String>();
    for (Map<String, Object> col : columns) {
      columnApis.add((String) col.get('api'));
    }
    // Phone-without-country-code rule from DITValidationCmpHelper.getCell.
    Map<String, String> phoneToCode = new Map<String, String>{
      'HomePhone__c' => 'HomePhoneCountryCode__c',
      'Cell__c' => 'Mobile_Phone_Country_Code__c',
      'Business_Phone__c' => 'Business_Phone_Country_Code__c',
      'AdditionalPhone__c' => 'AdditionalPhoneCountryCode__c'
    };
    for (String phoneApi : phoneToCode.keySet()) {
      String codeApi = phoneToCode.get(phoneApi);
      if (
        columnApis.contains(codeApi) &&
        String.isNotBlank(safeGetString(record, phoneApi)) &&
        String.isBlank(safeGetString(record, codeApi))
      ) {
        return true;
      }
    }
    for (Map<String, Object> col : columns) {
      String api = (String) col.get('api');
      String value = safeGetString(record, api);
      Boolean isBlank = String.isBlank(value);
      if (api == 'Last_Name__c' && isBlank) {
        return true;
      }
      Boolean colRequired = (Boolean) col.get('isRequired');
      if (colRequired == true && isBlank) {
        return true;
      }
      if (isBlank) {
        continue;
      }
      String colType = (String) col.get('type');
      if (colType == 'PICKLIST' && !picklistContains(col.get('options'), value)) {
        return true;
      }
      if (colType == 'EMAIL' && !isValidEmail(value)) {
        return true;
      }
      if (colType == 'STRING') {
        Integer maxLen = (Integer) col.get('maxLength');
        if (maxLen != null && maxLen > 0 && value.length() > maxLen) {
          return true;
        }
      }
    }
    return false;
  }

  // BRME-4862: mirror DITWorker.validateEmail (local@domain.tld).
  private static Boolean isValidEmail(String value) {
    return Pattern.matches('^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$', value);
  }

  private static Boolean picklistContains(Object optionsObj, String value) {
    if (optionsObj == null) {
      return true;
    }
    for (Object opt : (List<Object>) optionsObj) {
      Map<String, Object> option = (Map<String, Object>) opt;
      String optionValue = (String) option.get('value');
      // case-sensitive to mirror DITWorker.validatePicklist (opt.value == cell.value)
      if (optionValue != null && value.equals(optionValue)) {
        return true;
      }
    }
    return false;
  }

  private static String safeGetString(SObject record, String api) {
    try {
      Object val = record.get(api);
      return val == null ? null : String.valueOf(val);
    } catch (Exception ex) {
      return null; // field not queried / not accessible
    }
  }

  private static String normalizeOrgNameForCompare(String value) {
    if (String.isBlank(value))
      return '';
    String normalized = value.trim().normalizeSpace();
    normalized = normalized.replaceFirst('(?i)^the\\s+', '');
    normalized = SpecialCharactersHelper.convertSpecialCharToEnglish(
      normalized,
      false
    );
    return normalized.toLowerCase();
  }

  public static void setOrgs(
    List<Data_Load_Record__c> records,
    Map<String, Map<Id, String>> orgMap
  ) {
    try {
      if (orgMap.isEmpty())
        return;
      List<Data_Load_Record__c> updateList = new List<Data_Load_Record__c>();
      for (Data_Load_Record__c record : records) {
        String orgName = record.Organization_Name__c;
        String orgKey = String.isNotBlank(orgName)
          ? orgName.toLowerCase().trim()
          : '';
        String orgCompareKey = normalizeOrgNameForCompare(orgName);
        String orgId = record.Organization_Id__c;
        if (
          String.isNotBlank(orgName) &&
          String.isBlank(orgId) &&
          orgMap.get(orgKey) != null &&
          orgMap.get(orgKey).keySet().size() == 1
        ) {
          String newOrgId = '';
          Map<Id, String> idMap = orgMap.get(orgKey);
          for (Id keyId : idMap.keySet()) {
            String matchedCompareName = normalizeOrgNameForCompare(
              idMap.get(keyId)
            );
            if (matchedCompareName == orgCompareKey) {
              newOrgId = keyId;
            }
          }
          if (String.isNotBlank(newOrgId)) {
            updateList.add(
              new Data_Load_Record__c(
                Id = record.Id,
                Organization_Id__c = newOrgId
              )
            );
            record.Organization_Id__c = newOrgId;
          }
        }
      }
      if (!updateList.isEmpty()) {
        BBApps_Crud.doUpdateWithHandling(updateList, false, ERR_SET_ORGS);
      }
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_SET_ORGS)
      );
    }
  }

  public static void setContacts(
    List<Data_Load_Record__c> records,
    Map<String, Map<Id, String>> contactMap,
    String field
  ) {
    try {
      if (records == null || records.isEmpty() || contactMap.isEmpty()) {
        return;
      }
      String idField = tetheredFieldMap.get(field);
      List<Data_Load_Record__c> updateList = new List<Data_Load_Record__c>();
      for (Data_Load_Record__c record : records) {
        String name = (String) record.get(field);
        String nameKey = String.isNotBlank(name) ? name.toLowerCase() : '';
        String conId = (String) record.get(idField);
        Boolean hasUpdate = false;
        if (
          String.isNotBlank(name) &&
          String.isBlank(conId) &&
          contactMap.get(nameKey) != null &&
          contactMap.get(nameKey).keySet().size() == 1
        ) {
          String newConId = '';
          Map<Id, String> idMap = contactMap.get(nameKey);
          for (Id keyId : idMap.keySet()) {
            newConId = keyId;
          }
          record.put(idField, newConId);
          hasUpdate = true;
        }
        if (hasUpdate) {
          updateList.add(record);
        }
      }
      if (updateList.isEmpty()) {
        return;
      }
      BBApps_Crud.doUpdateWithHandling(updateList, false, ERR_SET_CONTACTS);
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_SET_CONTACTS)
      );
    }
  }

  public static Map<String, Map<Id, String>> getOrgMap(
    List<Data_Load_Record__c> records
  ) {
    Map<String, Map<Id, String>> orgMap = new Map<String, Map<Id, String>>();
    Map<String, String> compareNameToOriginalName = new Map<String, String>();
    try {
      for (Data_Load_Record__c r : records) {
        if (String.isNotBlank(r.Organization_Name__c)) {
          String originalName = r.Organization_Name__c.trim();
          String compareName = SpecialCharactersHelper.convertSpecialCharToEnglish(
              r.Organization_Name__c,
              false
            )
            .toLowerCase();
          compareNameToOriginalName.put(compareName, originalName);
        }
      }
      if (compareNameToOriginalName.isEmpty())
        return orgMap;
      List<String> compareKeys = new List<String>(
        compareNameToOriginalName.keySet()
      );
      Integer chunkSize = 20;
      for (Integer i = 0; i < compareKeys.size(); i += chunkSize) {
        String whereClause = '';
        for (Integer j = i; j < i + chunkSize && j < compareKeys.size(); j++) {
          String n = compareKeys[j];
          String pattern = '%' + String.escapeSingleQuotes(n) + '%';
          if (whereClause != '')
            whereClause += ' OR ';
          whereClause +=
            '(' +
            'AKA__c LIKE \'' +
            pattern +
            '\' OR ' +
            'Legal_Name__c LIKE \'' +
            pattern +
            '\' OR ' +
            'Name LIKE \'' +
            pattern +
            '\' OR ' +
            'Converted_AKA__c LIKE \'' +
            pattern +
            '\' OR ' +
            'Converted_Legal_Name__c LIKE \'' +
            pattern +
            '\' OR ' +
            'Converted_Org_Name__c LIKE \'' +
            pattern +
            '\'' +
            ')';
        }
        List<Account> accounts = Database.query(
          'SELECT Id, Name FROM Account WHERE ' +
            whereClause +
            ' WITH SYSTEM_MODE ORDER BY LastModifiedDate DESC LIMIT 5000'
        );
        for (Account acc : accounts) {
          if (String.isBlank(acc.Name))
            continue;
          String accNameNormalised = SpecialCharactersHelper.convertSpecialCharToEnglish(
              acc.Name,
              false
            )
            .toLowerCase();
          for (
            Integer j = i; j < i + chunkSize && j < compareKeys.size(); j++
          ) {
            String key = compareKeys[j];
            String originalName = compareNameToOriginalName.get(key);

            // Check whether the original Excel value starts with "The"
            Boolean keyStartsWithThe =
              originalName != null &&
              (originalName.trim().equalsIgnoreCase('The') ||
              originalName.trim().toLowerCase().startsWith('the '));

            // Check whether the Account Name starts with "The"
            Boolean accountStartsWithThe =
              acc.Name != null &&
              (acc.Name.trim().equalsIgnoreCase('The') ||
              acc.Name.trim().toLowerCase().startsWith('the '));

            // Skip when Account starts with "The" but Excel key doesn't
            if (accountStartsWithThe && !keyStartsWithThe) {
              continue;
            }

            if (accNameNormalised.contains(key)) {
              originalName = originalName.toLowerCase();

              if (!orgMap.containsKey(originalName)) {
                orgMap.put(originalName, new Map<Id, String>());
              }

              orgMap.get(originalName).put(acc.Id, accNameNormalised);
            }
          }
        }
      }
      return orgMap;
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(
        e,
        new BBApps_ErrorCustomFields(ERR_GET_ORG_MAP)
      );
      throw new AuraHandledException(
        'Unable to proceed to the next stage. Results exceed the Data Import Tool limit. Please upload a smaller Excel file.'
      );
    }
  }

  public static Set<String> getUUIDMap(List<Data_Load_Record__c> records) {
    Set<String> UUIDSet = new Set<String>();
    for (Data_Load_Record__c record : records) {
      String val = record.UUID__c;
      if (String.isNotBlank(val)) {
        UUIDSet.add(val);
      }
    }
    if (UUIDSet.isEmpty()) {
      return new Set<String>();
    }

    List<Contact> UUIDList = [
      SELECT Id, Name, UUID__c
      FROM Contact
      WHERE UUID__c IN :UUIDSet
      WITH SYSTEM_MODE
    ];

    UUIDSet = new Set<String>();
    for (Contact con : UUIDList) {
      if (String.isNotBlank(con.UUID__c))
        UUIDSet.add(con.UUID__c);
    }
    return UUIDSet;
  }

  public static Map<String, Map<Id, String>> getContactMap(
    List<Data_Load_Record__c> records
  ) {
    Map<String, Map<Id, String>> contactMap = new Map<String, Map<Id, String>>();
    Map<String, Set<Id>> contactSetMap = new Map<String, Set<Id>>();
    try {
      Set<String> firstNames = new Set<String>();
      Set<String> lastNames = new Set<String>();
      Set<String> bEmail = new Set<String>();
      for (Data_Load_Record__c record : records) {
        String firstName = record.Converted_FirstName__c;
        String lastName = record.Converted_LastName__c;
        if (String.isNotBlank(firstName)) {
          firstNames.add(firstName.trim());
        }
        if (String.isNotBlank(record.Business_Email__c)) {
          bEmail.add(record.Business_Email__c);
        }
        if (String.isNotBlank(lastName)) {
          lastNames.add(lastName.trim());
        }
      }
      if (firstNames.isEmpty() || lastNames.isEmpty()) {
        return contactMap;
      }
      List<Contact> contactList = [
        SELECT
          Id,
          FirstName,
          LastName,
          Email,
          Preferred_First_Name__c,
          Account.Name,
          AccountId,
          HomePhone,
          MobilePhone,
          Phone,
          Converted_LastName__c,
          Converted_FirstName__c,
          Converted_Full_Name__c
        FROM Contact
        WHERE
          (Converted_FirstName__c IN :firstNames
          OR Preferred_First_Name__c IN :firstNames
          OR Email IN :bEmail)
          AND Converted_LastName__c IN :lastNames
        WITH SYSTEM_MODE
      ];
      for (Contact c : contactList) {
        String firstName = c.Converted_FirstName__c;
        String prefFirstName = c.Preferred_First_Name__c;
        String lastName = c.Converted_LastName__c;
        String key = firstName + ' ' + lastName;
        key = key.toLowerCase();
        Map<Id, String> tempMap = contactMap.get(key) != null
          ? contactMap.get(key)
          : new Map<Id, String>();
        tempMap.put(c.Id, firstName + ' ' + lastName);
        contactMap.put(key, tempMap);
      }
      return contactMap;
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(
        e,
        new BBApps_ErrorCustomFields(ERR_GET_CONTACT_MAP)
      );
    }
    return contactMap;
  }

  public static Map<String, List<Id>> getContactMap(
    List<Data_Load_Record__c> records,
    String field
  ) {
    Map<String, List<Id>> contactMap = new Map<String, List<Id>>();
    try {
      Set<String> contactSet = new Set<String>();
      for (Data_Load_Record__c record : records) {
        String val = (String) record.get(field);

        if (
          String.isNotBlank(val) &&
          String.isBlank((String) record.get(tetheredFieldMap.get(field)))
        ) {
          contactSet.add(val);
        }
      }
      if (contactSet.isEmpty()) {
        return contactMap;
      }
      List<Contact> contactList = [
        SELECT Id, Name, FirstName_LastName__c
        FROM Contact
        WHERE Name IN :contactSet
        WITH SYSTEM_MODE
      ];
      for (Contact con : contactList) {
        List<Id> idList = contactMap.get(con.FirstName_LastName__c) != null
          ? contactMap.get(con.FirstName_LastName__c)
          : new List<Id>();
        idList.add(con.Id);
        contactMap.put(con.FirstName_LastName__c, idList);
      }
      return contactMap;
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(
        e,
        new BBApps_ErrorCustomFields(ERR_GET_CONTACT_MAP)
      );
    }
    return contactMap;
  }

  @AuraEnabled
  public static void updateUploadData(
    String dataLoaderId,
    List<Object> uploadData
  ) {
    try {
      Data_Load__c dataLoad = [
        SELECT Id, Uploaded_Data__c
        FROM Data_Load__c
        WHERE Id = :dataLoaderId
        WITH SYSTEM_MODE
      ];
      List<Object> curData = (List<Object>) JSON.deserializeUntyped(
        dataLoad.Uploaded_Data__c
      );
      curData.addAll(uploadData);
      dataLoad.Uploaded_Data__c = JSON.serialize(curData);
      BBApps_Crud.doUpdateWithHandling(
        new List<SObject>{ dataLoad },
        false,
        ERR_UPDATE_UPLOAD_DATA
      );
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_UPDATE_UPLOAD_DATA)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Data_Load__c updateStage(String dataRecordId, String stage) {
    Data_Load__c data = new Data_Load__c(Id = dataRecordId, Stage__c = stage);
    BBApps_Crud.doUpdateWithHandling(
      new List<SObject>{ data },
      false,
      ERR_UPDATE_STAGE
    );
    return data;
  }

  @AuraEnabled
  public static Data_Load__c updateSetupColumns(
    String dataRecordId,
    List<Map<String, Object>> colMap
  ) {
    Data_Load__c data = new Data_Load__c(
      Id = dataRecordId,
      Column_Map__c = JSON.serialize(colMap)
    );
    BBApps_Crud.doUpdateWithHandling(
      new List<SObject>{ data },
      false,
      ERR_UPDATE_SETUP_COLUMNS
    );
    return data;
  }

  @AuraEnabled
  public static boolean checkIfAlredaySignOther(String contactName) {
    try {
      List<contact> lstContacts = new List<contact>();
      lstContacts = [
        SELECT Id
        FROM Contact
        WHERE Significant_Other__r.FirstName_LastName__c = :contactName
        WITH SYSTEM_MODE
      ];
      return lstContacts.size() > 0;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_CHECK_SIGN_OTHER)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }
  @AuraEnabled
  public static Data_Load_Record__c updateDataRecord(
    Data_Load_Record__c dataRecord
  ) {
    try {
      List<contact> lstContacts = new List<contact>();
      if (String.isNotBlank(dataRecord.Significant_Other_Link__c)) {
        lstContacts = [
          SELECT Id
          FROM Contact
          WHERE Significant_Other__c = :dataRecord.Significant_Other_Link__c
          WITH SYSTEM_MODE
        ];
        dataRecord.isAlredaySignificantOther__c = lstContacts.size() > 0;
      }
      if (
        String.isNotBlank(dataRecord.Organization_Id__c) &&
        dataRecord.Organization_Id__c.startsWith('001')
      ) {
        dataRecord.Organization_Name__c = [
          SELECT Id, Name
          FROM Account
          WHERE Id = :dataRecord.Organization_Id__c
          WITH SYSTEM_MODE
        ]
        ?.Name;
      }

      BBApps_Crud.doUpdateWithHandling(
        new List<SObject>{ dataRecord },
        false,
        ERR_UPDATE_DATA_RECORD
      );
      return [
        SELECT
          Id,
          isAlredaySignificantOther__c,
          Organization_Id__c,
          RSVP__c,
          Attendance__c,
          List_Member_Notes__c
        FROM Data_Load_Record__c
        WHERE Id = :dataRecord.Id
        WITH SYSTEM_MODE
      ];
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_UPDATE_DATA_RECORD)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String, String> getMapSignificantOther(
    List<Data_Load_Record__c> dataRecords
  ) {
    try {
      Map<String, String> mapSign = new Map<String, String>();
      List<String> signNames = new List<String>();
      for (Data_Load_Record__c dl : dataRecords) {
        if (String.isNotBlank(dl.Significant_Other__c))
          signNames.add(dl.Significant_Other__c);
      }
      if (!signNames.isEmpty()) {
        for (Contact con : [
          SELECT
            Id,
            Name,
            Significant_Other__c,
            Significant_Other__r.FirstName_LastName__c
          FROM Contact
          WHERE
            Significant_Other__r.FirstName_LastName__c LIKE :signNames
            AND Significant_Other__c != NULL
          WITH SYSTEM_MODE
        ]) {
          mapSign.put(
            con.Significant_Other__r.FirstName_LastName__c,
            con.Significant_Other__c
          );
        }
      }
      return mapSign;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_GET_MAP_SIGNIFICANT_OTHER)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static List<Contact> updateDataRecords(
    List<Data_Load_Record__c> dataRecords,
    Boolean isSignficantOther
  ) {
    try {
      List<contact> lstContacts = new List<contact>();
      if (isSignficantOther) {
        List<String> lstIds = new List<String>();
        for (Data_Load_Record__c dl : dataRecords) {
          if (String.isNotBlank(dl.Significant_Other_Link__c))
            lstIds.add(dl.Significant_Other_Link__c);
        }
        if (!lstIds.isEmpty()) {
          lstContacts = [
            SELECT Id
            FROM Contact
            WHERE Significant_Other__c IN :lstIds
            WITH SYSTEM_MODE
          ];
        }
      }
      if (!dataRecords.isEmpty()) {
        dataRecords[0].isAlredaySignificantOther__c = lstContacts.size() > 0;
        BBApps_Crud.doUpdateWithHandling(
          dataRecords,
          false,
          ERR_UPDATE_DATA_RECORDS
        );
      }
      return lstContacts;
    } catch (Exception ex) {
      BBApps_ErrorHandler.logErrors(
        ex,
        new BBApps_ErrorCustomFields(ERR_UPDATE_DATA_RECORDS)
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Data_Load__c updateData(Data_Load__c data) {
    BBApps_Crud.doUpdateWithHandling(
      new List<SObject>{ data },
      false,
      ERR_UPDATE_DATA
    );
    return data;
  }

  private static List<SObject> getPreviewRecords(
    Map<String, String> colMap,
    Id dataId
  ) {
    String q = 'SELECT Id';
    Set<String> fieldSet = new Set<String>();
    for (String field : colMap.keySet()) {
      fieldSet.add(field);
    }
    for (Schema.FieldSetMember mem : ditFieldsList) {
      String api = mem.getFieldPath();
      fieldSet.add(api);
    }
    for (String field : tetheredFieldMap.keySet()) {
      fieldSet.add(field);
      fieldSet.add(tetheredFieldMap.get(field));
    }
    fieldSet.add('IsReviewValidate__c');
    fieldSet.add('Is_Create__c');
    fieldSet.add('Row_Index__c');
    fieldSet.add('Organization_Id__c');
    fieldSet.add('Contact_Data__c');
    fieldSet.add('Business_Email__c');
    fieldSet.add('IsConfirmed__c');
    fieldSet.add('Significant_Other_Link__c');
    fieldSet.add('isAlredaySignificantOther__c');
    fieldSet.add('Source__c');
    fieldSet.add('Dietary__c');
    fieldSet.add('Converted_FirstName__c');
    fieldSet.add('Converted_LastName__c');
    fieldSet.add('Converted_Full_Name__c');
    fieldSet.add('RSVP__c');
    fieldSet.add('Attendance__c');
    fieldSet.add('List_Member_Notes__c');
    fieldSet.add('Contact_Alert_Reason__c');
    for (String field : fieldSet) {
      q += ',' + field;
    }
    q += ' FROM Data_Load_Record__c WHERE Data_Load__c =:dataId WITH SYSTEM_MODE';
    return Database.query(q);
  }

  private static Set<String> getRequiredFieldSet() {
    Set<String> required = new Set<String>();
    for (Schema.FieldSetMember mem : ditRequiredList) {
      String api = mem.getFieldPath();
      if (isFieldValid(api)) {
        required.add(api.toLowerCase());
      }
    }
    return required;
  }

  private static Boolean isFieldValid(String api) {
    if (String.isBlank(api)) {
      return false;
    }
    String apiKey = String.isNotBlank(api) ? api.toLowerCase() : '';
    return String.isNotBlank(apiKey) &&
      FIELD_MAP.get(apiKey) != null &&
      FIELD_MAP.get(apiKey).getDescribe().isAccessible();
  }

  private static Map<String, Object> getColMap(
    Schema.FieldSetMember mem,
    Set<String> requiredFields
  ) {
    Map<String, Object> colMap = new Map<String, Object>();
    colMap.put('label', mem.getLabel());
    String api = mem.getFieldPath();
    colMap.put('api', api);
    colMap.put('isRequired', requiredFields.contains(api.toLowerCase()));
    String fieldType = getFieldtype(mem);
    colMap.put('type', fieldType);
    colMap.put('isSortable', true);
    Schema.DescribeFieldResult fr = mem.getSObjectField().getDescribe();
    colMap.put('isEdit', fr.isUpdateable());
    colMap.put('maxLength', fr.getLength());
    if ('PICKLIST'.equals(fieldType)) {
      setPicklistVals(colMap, mem, api);
    }
    return colMap;
  }

  private static void setPicklistVals(
    Map<String, Object> colMap,
    Schema.FieldSetMember mem,
    String api
  ) {
    List<Map<String, Object>> options = new List<Map<String, Object>>();
    List<Schema.PicklistEntry> ple = mem.getSObjectField()
      .getDescribe()
      .getPicklistValues();
    for (Schema.PicklistEntry pickListVal : ple) {
      if (pickListVal.isActive()) {
        Map<String, Object> pickMap = new Map<String, Object>();
        pickMap.put('label', pickListVal.getLabel());
        pickMap.put('value', pickListVal.getValue());
        pickMap.put('isDefault', pickListVal.isDefaultValue());
        options.add(pickMap);
      }
    }

    colMap.put('options', options);
  }

  private static String getFieldType(Schema.FieldSetMember mem) {
    String myType = mem.getType() + '';
    return myType;
  }

  @AuraEnabled
  public static Map<String, String> normalizeOrgNames(List<String> names) {
    Map<String, String> result = new Map<String, String>();

    for (String name : names) {
      result.put(
        name,
        SpecialCharactersHelper.convertSpecialCharToEnglish(name, false)
          .toLowerCase()
      );
    }

    return result;
  }
}