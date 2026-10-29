public with sharing class TagsReportController {
  public String tagsParams;
  public Set<String> objNameSet;
  public static final Map<String, SObjectField> CONTACT_FIELD_MAP = Contact.sObjectType.getDescribe()
    .fields.getMap();
  private static final Set<String> NOT_URL = new Set<String>{
    'masterrecordid'
  };
  public static final Map<String, SObjectField> LIST_FIELD_MAP = Campaign.sObjectType.getDescribe()
    .fields.getMap();
  public static Integer pageSize = 100;
  public static Integer curSize;
  public static final List<String> DEFAULT_CONTACT_FIELDS = new List<String>{
    'FirstName',
    'LastName',
    'Title'
  };

  private static final String ERR_GET_CONFIG = 'TRC_GET_CONFIG_FAILED';
  private static final String ERR_GET_DATA   = 'TRC_GET_DATA_FAILED';

  public TagsReportController(
    ApexPages.StandardSetController stdSetController
  ) {
    List<Tag_Junction__c> tagsList = (List<Tag_Junction__c>) stdSetController.getSelected();
    tagsParams = '';
    tagsParams = '';
    List<Tag_Junction__c> queryList = [
      SELECT Id, Name__c, Related_Id__c, Tag__r.Name
      FROM Tag_Junction__c
      WHERE Id IN :tagsList WITH SYSTEM_MODE
    ];
    Set<String> nameSet = new Set<String>();
    Integer i = 0;
    objNameSet = new Set<String>();
    for (i = 0; i < queryList.size(); i++) {
      Tag_Junction__c tag = queryList.get(i);
      nameSet.add(tag.Tag__r.Name);
      if (!String.isBlank(tag.Related_Id__c)) {
        Id recId = Id.valueOf(tag.Related_Id__c);
        objNameSet.add(recId.getSObjectType().getDescribe().getName());
      }
    }
    i = 0;
    for (String name : nameSet) {
      tagsParams += '"' + name + '"';
      if (i < nameSet.size() - 1) {
        tagsParams += ',';
      }
      i++;
    }
  }

  @AuraEnabled
  public static Object getConfig() {
    try {
      Map<String, Object> configMap = new Map<String, Object>();
      configMap.put('contactOptions', getFieldOptions(CONTACT_FIELD_MAP));
      configMap.put(
        'contactFields',
        getFieldDefault(DEFAULT_CONTACT_FIELDS, CONTACT_FIELD_MAP)
      );
      return configMap;
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_CONFIG));
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Object getData(
    List<String> contactFields,
    List<Id> includeTags,
    List<Id> excludeTags
  ) {
    try {
      Map<String, Object> results = new Map<String, Object>();
      results.put('columns', getColumns(contactFields));
      results.put(
        'data',
        getTableData(contactFields, includeTags, excludeTags)
      );
      return results;
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_DATA));
      throw new AuraHandledException(e.getMessage());
    }
  }

  public PageReference redirectToReport() {
    if (String.isBlank(tagsParams)) {
      return null;
    }
    String reportName = '';
    if (objNameSet.size() > 1) {
      reportName = 'Tags_Report_buM';
    } else {
      String objName = objNameSet.iterator().next();
      reportName = 'Account'.equals(objName)
        ? 'Organizations_with_Tags_Report_B00'
        : 'Contacts_with_Tags_Report_oKi';
    }
    Id reportId = [
      SELECT Id, DeveloperName
      FROM Report
      WHERE DeveloperName = :reportName WITH SYSTEM_MODE
    ]
    .Id;
    String returnUrl =
      '/lightning/r/Report/' +
      reportId +
      '/view?queryScope=userFolders&fv0=' +
      EncodingUtil.urlEncode(tagsParams, 'UTF-8') +
      '&t=' +
      Datetime.now().millisecond();
    PageReference pgReturnPage = new PageReference(returnUrl);
    pgReturnPage.setRedirect(true);
    return pgReturnPage;
  }

  private static List<Object> getTableData(
    List<String> contactFields,
    List<Id> includeTags,
    List<Id> excludeTags
  ) {
    Map<Id, Set<String>> excludeMap = getContactsMap(excludeTags);
    Map<Id, Set<String>> includeMap = getContactsMap(includeTags);
    Set<Id> conIds = new Set<Id>();
    for (Id conId : includeMap.keySet()) {
      if (!excludeMap.keySet().contains(conId)) {
        conIds.add(conId);
      }
    }
    Map<Id, List<String>> conTagsMap = getContactTagsMap(conIds);
    List<Object> dataResult = new List<Object>();
    List<Contact> conList = getContactList(conIds, contactFields);
    for (Contact con : conList) {
      Map<String, Object> valMap = new Map<String, Object>();
      for (String api : contactFields) {
        setValMap(valMap, api, con, CONTACT_FIELD_MAP, 'contact');
      }
      List<String> tagsList = conTagsMap.get(con.Id) != null
        ? conTagsMap.get(con.Id)
        : new List<String>();
      String tagString = '';
      for (String tag : tagsList) {
        tagString += tag + ';';
      }
      valMap.put('tags', tagString.removeEnd(','));
      dataResult.add(valMap);
    }
    return dataResult;
  }
  private static List<Contact> getContactList(
    Set<Id> conSet,
    List<String> contactFields
  ) {
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

  private static void setValMap(
    Map<String, Object> valMap,
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
  private static Boolean isDateTimeField(
    String api,
    Map<String, SObjectField> fieldMap
  ) {
    String fieldType = fieldMap.get(api).getDescribe().getType() + '';
    return 'DATETIME'.equalsIgnoreCase(fieldType);
  }

  private static Map<Id, Set<String>> getContactsMap(List<Id> tagList) {
    Map<Id, Set<String>> conMap = new Map<Id, Set<String>>();
    if (tagList == null || tagList.isEmpty()) {
      return conMap;
    }
    List<Tag_Junction__c> tagsList = [
      SELECT Id, Contact__c, Tag__c, Tag__r.Name
      FROM Tag_Junction__c
      WHERE Tag__c IN :tagList AND Contact__c != NULL WITH SYSTEM_MODE
    ];
    for (Tag_Junction__c tag : tagsList) {
      Set<String> conSet = conMap.get(tag.Contact__c) != null
        ? conMap.get(tag.Contact__c)
        : new Set<String>();
      conSet.add(tag.Tag__r.Name);
      conMap.put(tag.Contact__c, conSet);
    }
    return conMap;
  }

  private static Map<Id, List<String>> getContactTagsMap(Set<Id> conId) {
    Map<Id, List<String>> conMap = new Map<Id, List<String>>();
    if (conId.isEmpty()) {
      return conMap;
    }
    List<Tag_Junction__c> tagsList = [
      SELECT Id, Contact__c, Tag__c, Tag__r.Name
      FROM Tag_Junction__c
      WHERE Contact__c IN :conId WITH SYSTEM_MODE
    ];
    for (Tag_Junction__c tag : tagsList) {
      List<String> conSet = conMap.get(tag.Contact__c) != null
        ? conMap.get(tag.Contact__c)
        : new List<String>();
      conSet.add(tag.Tag__r.Name);
      conMap.put(tag.Contact__c, conSet);
    }

    for (Id cId : conMap.keySet()) {
      List<String> conList = conMap.get(cId);
      conList.sort();
    }
    return conMap;
  }

  private static List<Object> getColumns(List<String> contactFields) {
    List<Object> colList = new List<Object>();
    for (String api : contactFields) {
      if (CONTACT_FIELD_MAP.get(api).getDescribe().isAccessible()) {
        colList.add(getCol(api, CONTACT_FIELD_MAP, 'contact'));
      }
    }

    Map<String, String> tagCol = new Map<String, String>{
      'type' => 'text',
      'fieldName' => 'tags',
      'label' => 'Tags'
    };
    colList.add(tagCol);
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
}