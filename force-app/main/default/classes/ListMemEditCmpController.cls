public class ListMemEditCmpController {
  private final static String DEFAULT_REC_TYPE = 'Default';
  private final static String DEFAULT_HEADER_KEY = 'defaultHeaders';
  private final static Map<String, SObjectField> MEMBER_FIELD_MAP = CampaignMember.sObjectType.getDescribe()
    .fields.getMap();
  private final static Map<String, Map<String, Object>> SETTINGS = getSettings();
  @AuraEnabled
  public static Object getListMembers(String campaignId) {
    Map<String, Object> listMap = new Map<String, Object>();
    setCampaign(listMap, campaignId);
    String recType = '';
    Map<String, Object> settings = SETTINGS.get(recType) != null
      ? SETTINGS.get(recType)
      : SETTINGS.get(DEFAULT_REC_TYPE);
    setColumns(listMap, settings);
    setData(listMap);
    return listMap;
  }

  private static void setCampaign(Map<String, Object> listMap, Id campaignId) {
    Campaign camp = [
      SELECT Id, RecordTypeId, RecordType.Name, Name, NumberOfContacts
      FROM Campaign
      WHERE Id = :campaignId
    ];
    listMap.put('campaign', camp);
  }

  private static String getRecType(Map<String, Object> listMap) {
    Campaign camp = (Campaign) listMap.get('campaign');
    return camp.RecordTypeId != null && String.isNotBlank(camp.RecordType.DeveloperName)
      ? camp.RecordType.DeveloperName
      : '';
  }

  private static void setColumns(
    Map<String, Object> listMap,
    Map<String, Object> settings
  ) {
    List<String> fieldsList = (List<String>) settings.get(DEFAULT_HEADER_KEY);
    List<Object> columns = new List<Object>();
    Map<String, Integer> colMap = new Map<String, Integer>();
    Integer i = 0;
    for (String field : fieldsList) {
      Schema.DescribeFieldResult dfr = MEMBER_FIELD_MAP.get(
          field.toLowerCase()
        ) != null
        ? MEMBER_FIELD_MAP.get(field.toLowerCase()).getDescribe()
        : null;
      if (dfr != null) {
        columns.add(getCol(dfr));
        colMap.put(dfr.getName(), i);
        i++;
      }
    }
    listMap.put('columns', columns);
    listMap.put('colMap', colMap);
  }

  private static void setData(Map<String, Object> listMap) {
    List<Object> columns = (List<Object>) listMap.get('columns');
    Set<String> fieldSet = new Set<String>();
    String q = 'SELECT Id';
    for (Object col : columns) {
      Map<String, Object> colMap = (Map<String, Object>) col;
      String api = (String) colMap.get('api');
      String apiLower = api.toLowerCase();
      if (!String.isBlank(api) && !fieldSet.contains(apiLower)) {
        q += ',' + api;
        fieldSet.add(apiLower);
      }
    }
    Campaign camp = (Campaign) listMap.get('campaign');
    q += ' FROM CampaignMember WHERE CampaignId = '+'\''+camp.Id+'\'';
    System.debug(q);
    listMap.put('data', Database.query(q));
  }

  private static Map<String, Object> getCol(Schema.DescribeFieldResult dfr) {
    Map<String, Object> colMap = new Map<String, Object>();
    colMap.put('api', dfr.getName() + '');
    colMap.put('label', dfr.getLabel() + '');
    colMap.put('maxLen', dfr.getLength());
    colMap.put('isUpdateable', dfr.isUpdateable());
    String fieldType = dfr.isHtmlFormatted() ? 'HTML' : dfr.getType() + '';
    colMap.put('type', fieldType);
    if (fieldType.contains('PICKLIST')) {
      colMap.put('picklist', getPicklistVals(dfr.getPicklistValues()));
    }
    return colMap;
  }
  private static List<Map<String, String>> getPickListVals(
    List<Schema.PicklistEntry> listVals
  ) {
    if (listVals.isEmpty()) {
      return null;
    }
    List<Map<String, String>> pickList = new List<Map<String, String>>();
    Integer defaultIdx = 0;
    Integer i = 0;
    for (Schema.PicklistEntry ple : listVals) {
      if (ple.isActive()) {
        pickList.add(
          new Map<String, String>{
            'label' => ple.getLabel() + '',
            'value' => ple.getValue() + ''
          }
        );
        if (ple.isDefaultValue()) {
          defaultIdx = i;
        }
        i++;
      }
    }
    if (defaultIdx != 0 && pickList.size() > 0) {
      Map<String, String> temp = pickList.get(0);
      pickList.add(0, pickList.get(defaultIdx));
      pickList.add(defaultIdx, temp);
    }
    return pickList;
  }
  private static Map<String, Object> getSetting(String recType) {
    return SETTINGS.get(recType) != null
      ? SETTINGS.get(recType)
      : SETTINGS.get(DEFAULT_REC_TYPE);
  }

  private static Map<String, Map<String, Object>> getSettings() {
    List<List_Edit_Settings__mdt> settings = [
      SELECT Id, Default_Headers__c, Record_Type__c, Page_Size__c
      FROM List_Edit_Settings__mdt
    ];
    Map<String, Map<String, Object>> settingsMap = new Map<String, Map<String, Object>>();
    for (List_Edit_Settings__mdt setting : settings) {
      String recType = setting.Record_Type__c;
      Map<String, Object> setMap = settingsMap.get(recType) != null
        ? settingsMap.get(recType)
        : new Map<String, Object>();
      List<String> defaultHeaders = String.isNotBlank(
          setting.Default_Headers__c
        )
        ? setting.Default_Headers__c.split(',')
        : new List<String>();
      setMap.put(DEFAULT_HEADER_KEY, defaultHeaders);
      setMap.put('pageSize', setting.Page_Size__c);
      settingsMap.put(recType, setMap);
    }
    return settingsMap;
  }
}