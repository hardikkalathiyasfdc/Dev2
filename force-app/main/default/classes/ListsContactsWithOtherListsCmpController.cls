/*
 * test class: ListsContactsWithOtherListsCmpTest
 */
public without sharing class ListsContactsWithOtherListsCmpController {

  private static final String ERR_GET_CONFIG = 'LISTSCONTACTS_GET_CONFIG_FAILED';
  private static final String ERR_GET_DATA = 'LISTSCONTACTS_GET_DATA_FAILED';
  private static final String ERR_GET_CSV = 'LISTSCONTACTS_GET_CSV_FAILED';

  private static final String MSG_GET_CONFIG = 'Unable to fetch configuration.';
  private static final String MSG_GET_DATA = 'Unable to fetch contact/list data.';
  private static final String MSG_GET_CSV = 'Unable to generate CSV data.';

  public static final Map<String, SObjectField> CONTACT_FIELD_MAP = Contact.sObjectType.getDescribe()
    .fields.getMap();
  public static final Map<String, SObjectField> LIST_FIELD_MAP = Campaign.sObjectType.getDescribe()
    .fields.getMap();
  public static Integer pageSize = 100;
  public static Integer curSize;
  public static final List<String> DEFAULT_CONTACT_FIELDS = new List<String>{
    'FirstName',
    'LastName',
    'Title',
    'AccountId',
    'Email',
    'Alternate_Email__c',
    'Personal_Email_2__c',
    'Business_Email_2__c',
    'DoNotCall',
    'Contact_Alert_Reason__c'
  };
  public static final List<String> DEFAULT_LIST_FIELDS = new List<String>{
    'Name',
    'Private_Campaign__c',
    'IsActive',
    'OwnerId',
    'RecordTypeId'
  };

  @AuraEnabled(Cacheable=true)
  public static Object getConfig() {
    try { 
      validateCustomPermission();
      Map<String, Object> configMap = new Map<String, Object>();
      configMap.put('contactOptions', getFieldOptions(CONTACT_FIELD_MAP));
      configMap.put('listOptions', getFieldOptions(LIST_FIELD_MAP));
      configMap.put(
        'contactFields',
        getFieldDefault(DEFAULT_CONTACT_FIELDS, CONTACT_FIELD_MAP)
      );
      configMap.put(
        'listFields',
        getFieldDefault(DEFAULT_LIST_FIELDS, LIST_FIELD_MAP)
      );
      return configMap;
    } catch (Exception ex) {
      BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_CONFIG);
      BBApps_ErrorHandler.logErrors(ex, f);
      throw new AuraHandledException(MSG_GET_CONFIG);
    }
  }

  @AuraEnabled(Cacheable=true)
  public static Object getData(
    Id listId,
    List<String> contactFields,
    List<String> listFields,
    Integer curPage
  ) {
    try {
      validateCustomPermission();
      Map<String, Object> results = new Map<String, Object>();
      curSize = 0;
      results.put('columns', getColumns(contactFields, listFields));
      results.put(
        'data',
        getTableData(listId, contactFields, listFields, curPage)
      );
      results.put('name', getListName(listId));
      results.put('size', curSize);
      results.put('pageSize', pageSize);
      return results;
    } catch (Exception ex) {
      BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_DATA);
      BBApps_ErrorHandler.logErrors(ex, f);
      throw new AuraHandledException(MSG_GET_DATA);
    }
  }

  @AuraEnabled(Cacheable=true)
  public static Object getCSV(
    Id listId,
    List<String> contactFields,
    List<String> listFields
  ) {
    try {
      List<Object> dataList = getTableData(listId, contactFields, listFields, -1);
      Map<String, Object> result = new Map<String,Object>();
      result.put('cols', getCSVColumns(contactFields, listFields));
      result.put('data', dataList);
      return result;
    } catch (Exception ex) {
      BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_CSV);
      BBApps_ErrorHandler.logErrors(ex, f);
      throw new AuraHandledException(MSG_GET_CSV);
    }
  }

  private static void validateCustomPermission() {
    if (
      !FeatureManagement.checkPermission('ViewListsContactsCmp') &&
      !Test.isRunningTest()
    ) {
      throw new BRMException('You do not have permission to use this page.');
    }
  }

  private static String getCSVColumns(
    List<String> contactFields,
    List<String> listFields
  ) {
    String cols = '';
    for (String field : contactFields) {
      if (CONTACT_FIELD_MAP.get(field).getDescribe().isAccessible()) {
        cols +=
          getCSVVal(CONTACT_FIELD_MAP.get(field).getDescribe().getLabel()) +
          ',';
      }
    }
    for (String field : listFields) {
      if (LIST_FIELD_MAP.get(field).getDescribe().isAccessible()) {
        cols +=
          getCSVVal(LIST_FIELD_MAP.get(field).getDescribe().getLabel()) + ',';
      }
    }

    return !String.isBlank(cols)
      ? cols.substring(0, cols.length() - 1) + '\n'
      : '';
  }

  private static String getCSVVal(Object val) {
    if (val == null) {
      return '';
    }
    return getCSVVal(val + '');
  }

  private static String getCSVVal(String val) {
    return !String.isBlank(val) ? '"' + val.replaceAll('"', '\"') + '"' : '';
  }

  private static String getListName(Id listId) {
    return [SELECT Id, Name FROM Campaign WHERE Id = :listId WITH SYSTEM_MODE].Name;
  }

  private static List<Object> getTableData(
    Id listId,
    List<String> contactFields,
    List<String> listFields,
    Integer curPage
  ) {
    List<Object> dataList = new List<Object>();
    Set<Id> conSet = getCampContacts(listId);
    List<Contact> conList = getContactList(conSet, contactFields);
    Map<Id, List<Campaign>> conToCampMap = getConToCampMap(conList, listFields);
    List<MyContactWrapper> combinedList = new List<MyContactWrapper>();
    for (Contact c : conList) {
      List<Campaign> campList = conToCampMap.get(c.Id);
      for (Campaign camp : campList) {
        MyContactWrapper wrap = new MyContactWrapper(
          c,
          camp,
          contactFields,
          listFields
        );
        combinedList.add(wrap);
      }
    }
    curSize = combinedList.size();
    Integer start = curPage != -1 ? curPage * pageSize : 0;
    Integer max = curPage * pageSize + pageSize;
    max = curPage != -1
      ? Math.min(combinedList.size(), max)
      : combinedList.size();
    for (Integer i = start; i < max; i++) {
      dataList.add(combinedList.get(i).valMap);
    }
    return dataList;
  }

  private static Map<Id, List<Campaign>> getConToCampMap(
    List<Contact> conList,
    List<String> listFields
  ) {
    Map<Id, List<Campaign>> conToCampMap = new Map<Id, List<Campaign>>();
    Set<Id> campSet = new Set<Id>();
    Map<Id, Set<Id>> conToCampIds = new Map<Id, Set<Id>>();
    List<CampaignMember> memList = [
      SELECT ContactId, CampaignId
      FROM CampaignMember
      WHERE ContactId IN :conList WITH SYSTEM_MODE
    ];
    for (CampaignMember mem : memList) {
      campSet.add(mem.CampaignId);
      Set<Id> temp = conToCampIds.get(mem.ContactId) != null
        ? conToCampIds.get(mem.ContactId)
        : new Set<Id>();
      temp.add(mem.CampaignId);
      conToCampIds.put(mem.ContactId, temp);
    }

    String selQuery = getSelQuery(listFields, LIST_FIELD_MAP);
    if (String.isBlank(selQuery)) {
      return conToCampMap;
    }
    String q = selQuery + ' FROM Campaign WHERE Id IN: campSet';
    Map<Id, Campaign> campMap = new Map<Id, Campaign>(
      (List<Campaign>) Database.query(q)
    );
    for (Id conId : conToCampIds.keySet()) {
      Set<Id> campIds = conToCampIds.get(conId);
      List<Campaign> campList = new List<Campaign>();
      for (Id myId : campIds) {
        campList.add(campMap.get(myId));
      }
      conToCampMap.put(conId, campList);
    }
    return conToCampMap;
  }

  private static List<Contact> getContactList(
    Set<Id> conSet,
    List<String> contactFields
  ) {
    Map<Id, MyContactWrapper> conMap = new Map<Id, MyContactWrapper>();
    String selQuery = getSelQuery(contactFields, CONTACT_FIELD_MAP);
    if (String.isBlank(selQuery)) {
      return new List<Contact>();
    }
    String q = selQuery + ' FROM Contact WHERE Id IN: conSet WITH SYSTEM_MODE';
    return Database.query(q);
  }

  private static String getSelQuery(
    List<String> fields,
    Map<String, SObjectField> fieldMap
  ) {
    String q = '';
    for (String field : fields) {
      if (fieldMap.get(field).getDescribe().isAccessible()) {
        q += field + ',';
        if (isUrlType(field, fieldMap)) {
          q += field.substring(0, field.length() - 2) + '.Name' + ',';
        }
      }
    }
    return !String.isBlank(q) ? 'SELECT ' + q.substring(0, q.length() - 1) : '';
  }

  private static Set<Id> getCampContacts(Id listId) {
    Set<Id> conSet = new Set<Id>();
    List<CampaignMember> memList = [
      SELECT ContactId
      FROM CampaignMember
      WHERE campaignId = :listId AND ContactId != NULL WITH SYSTEM_MODE
    ];
    for (CampaignMember mem : memList) {
      conSet.add(mem.ContactId);
    }
    return conSet;
  }

  private static List<Object> getColumns(
    List<String> contactFields,
    List<String> listFields
  ) {
    List<Object> colList = new List<Object>();
    for (String api : contactFields) {
      if (CONTACT_FIELD_MAP.get(api).getDescribe().isAccessible()) {
        colList.add(getCol(api, CONTACT_FIELD_MAP, 'contact'));
      }
    }
    for (String api : listFields) {
      if (LIST_FIELD_MAP.get(api).getDescribe().isAccessible()) {
        colList.add(getCol(api, LIST_FIELD_MAP, 'list'));
      }
    }
    return colList;
  }

  private static Object getCol(
    String api,
    Map<String, SObjectField> fieldMap,
    String objType
  ) {
    if (isUrlType(api, fieldMap)) {
      return getUrlCol(api, fieldMap, objType);
    } else {
      return getTextCol(api, fieldMap, objType);
    }
  }
  private static final Set<String> NOT_URL = new Set<String>{
    'masterrecordid'
  };
  private static Boolean isUrlType(
    String api,
    Map<String, SObjectField> fieldMap
  ) {
    if (NOT_URL.contains(api)) {
      return false;
    }
    String fieldType = fieldMap.get(api).getDescribe().getType() + '';
    return 'REFERENCE'.equalsIgnoreCase(fieldType) && api.endsWith('id');
  }

  private static Boolean isDateTimeField(
    String api,
    Map<String, SObjectField> fieldMap
  ) {
    String fieldType = fieldMap.get(api).getDescribe().getType() + '';
    return 'DATETIME'.equalsIgnoreCase(fieldType);
  }

  private static Map<String, Object> getUrlCol(
    String api,
    Map<String, SObjectField> fieldMap,
    String objType
  ) {
    Map<String, Object> urlCol = new Map<String, Object>();
    String objTag = objType + '.' + api;
    urlCol.put('type', 'url');
    urlCol.put('fieldName', objTag + 'Url');
    urlCol.put('label', fieldMap.get(api).getDescribe().getLabel());
    Map<String, Map<String, String>> attrMap = new Map<String, Map<String, String>>{
      'label' => new Map<String, String>{ 'fieldName' => objTag + 'Name' }
    };
    urlCol.put('typeAttributes', attrMap);
    return urlCol;
  }

  private static Map<String, String> getTextCol(
    String api,
    Map<String, SObjectField> fieldMap,
    String objType
  ) {
    String objTag = objType + '.' + api;
    Map<String, String> textCol = new Map<String, String>();
    textCol.put('type', 'text');
    textCol.put('fieldName', objTag);
    textCol.put('label', fieldMap.get(api).getDescribe().getLabel());
    return textCol;
  }

  private static List<Map<String, String>> getFieldOptions(
    Map<String, SObjectField> fieldMap
  ) {
    List<Map<String, String>> configList = new List<Map<String, String>>();
    List<String> labelList = new List<String>();
    Map<String, List<Map<String, String>>> configMap = new Map<String, List<Map<String, String>>>();
    for (String key : fieldMap.keySet()) {
      if (fieldMap.get(key).getDescribe().isAccessible()) {
        Map<String, String> cMap = new Map<String, String>();
        String label = fieldMap.get(key).getDescribe().getLabel();
        cMap.put('label', label);
        cMap.put('value', key);
        List<Map<String, String>> cList = configMap.get(label) != null
          ? configMap.get(label)
          : new List<Map<String, String>>();
        cList.add(cMap);
        if (configMap.get(label) == null) {
          labelList.add(label);
        }
        configMap.put(label, cList);
      }
    }

    labelList.sort();
    for (String label : labelList) {
      List<Map<String, String>> cList = configMap.get(label);
      for (Map<String, String> config : cList) {
        configList.add(config);
      }
    }
    return configList;
  }

  private static List<String> getFieldDefault(
    List<String> fieldList,
    Map<String, SObjectField> fieldMap
  ) {
    List<String> defList = new List<String>();
    for (String api : fieldList) {
      if (fieldMap.get(api).getDescribe().isAccessible()) {
        defList.add(api.toLowerCase());
      }
    }
    return defList;
  }

  private static String getName(SObject myObj, String api) {
    String name = api.substring(0, api.length() - 2);
    if (
      myObj.getSobject(name) != null &&
      myObj.getSobject(name).get('Name') != null
    ) {
      return myObj.getSobject(name).get('Name') + '';
    }
    return null;
  }

  private class MyContactWrapper {
    public Map<String, Object> valMap;
    public MyContactWrapper(
      Contact con,
      Campaign camp,
      List<String> contactFields,
      List<String> listFields
    ) {
      valMap = new Map<String, Object>();
      for (String api : contactFields) {
        setValMap(api, con, CONTACT_FIELD_MAP, 'contact');
      }

      for (String api : listFields) {
        setValMap(api, camp, LIST_FIELD_MAP, 'list');
      }
    }

    private void setValMap(
      String api,
      SObject myObj,
      Map<String, SObjectField> fieldMap,
      String objType
    ) {
      String objTag = objType + '.' + api;
      if (isUrlType(api, fieldMap)) {
        valMap.put(objTag + 'Name', getName(myObj, api));
        valMap.put(objTag + 'Url', '../../' + myObj.get(api));
      } else if (isDateTimeField(api, fieldMap)) {
        DateTime temp = (DateTime) myObj.get(api);
        if (temp != null) {
          valMap.put(objTag, temp.format());
        }
      } else {
        valMap.put(objTag, myObj.get(api));
      }
    }
  }
}