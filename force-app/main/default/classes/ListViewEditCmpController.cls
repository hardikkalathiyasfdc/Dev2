public with sharing class ListViewEditCmpController {

  private static final String ERR_GET_MEMBERS = 'LISTVIEWEDIT_GET_MEMBERS_FAILED';
  private static final String ERR_SAVE_MEMBERS = 'LISTVIEWEDIT_SAVE_MEMBERS_FAILED';

  private static final String MSG_GET_MEMBERS = 'Unable to fetch list members.';
  private static final String MSG_NO_CAMPAIGN_ACCESS = 'You do not have access to this List.';

  public static List<ListViewEditCmpSettings__mdt> settingsList;
  private static Map<String, Object> config;
  private final static Map<String, SObjectField> MEMBER_FIELD_MAP = CampaignMember.sObjectType.getDescribe()
    .fields.getMap();

  @AuraEnabled
  public static Object getListMembers(
    Id campaignId,
    Integer pageNum,
    String sortField,
    String sortDir
  ) {
    try {
      if (campaignId == null) {
        throw new MyException('No campaign Id found');
      }

      ensureCampaignAccess(campaignId, false);
      pageNum = pageNum == null ? 0 : pageNum;

      Map<String, Object> listMap = new Map<String, Object>();
      config = new MyConfig().getConfig();
      listMap.put('config', config);
      listMap.put(
        'data',
        getData(campaignId, pageNum, sortField, sortDir, listMap)
      );
      listMap.put('campaignName', getCampaignName(campaignId));
      return listMap;
    } catch (AuraHandledException ex) {
      throw ex;
    } catch (Exception ex) {
      BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_MEMBERS);
      BBApps_ErrorHandler.logErrors(ex, f);
      throw new AuraHandledException(MSG_GET_MEMBERS);
    }
  }

  @AuraEnabled
  public static void saveListMembers(List<CampaignMember> membersList) {
    if (membersList == null || membersList.isEmpty()) {
      return;
    }
    BBApps_Crud.doUpdateWithHandling(membersList, false, ERR_SAVE_MEMBERS);
  }

  private static String getCampaignName(Id campaignId) {
    return [SELECT Id, Name FROM Campaign WHERE Id = :campaignId WITH USER_MODE].Name;
  }

  private static void ensureCampaignAccess(Id campaignId, Boolean requireEditAccess) {
    if (campaignId == null) {
      throw new AuraHandledException('No campaign Id found');
    }
    ensureCampaignAccess(new Set<Id>{ campaignId }, requireEditAccess);
  }

  private static void ensureCampaignAccess(Set<Id> campaignIds, Boolean requireEditAccess) {
    if (campaignIds == null || campaignIds.isEmpty()) {
      throw new AuraHandledException('No campaign Id found');
    }

    Map<Id, UserRecordAccess> accessByCampaignId = new Map<Id, UserRecordAccess>([
      SELECT RecordId, HasReadAccess, HasEditAccess
      FROM UserRecordAccess
      WHERE UserId = :UserInfo.getUserId()
        AND RecordId IN :campaignIds
    ]);

    for (Id campaignId : campaignIds) {
      UserRecordAccess access = accessByCampaignId.get(campaignId);
      if (access == null || !access.HasReadAccess || (requireEditAccess && !access.HasEditAccess)) {
        throw new AuraHandledException(MSG_NO_CAMPAIGN_ACCESS);
      }
    }
  }

  private static List<CampaignMember> getData(
    Id campaignId,
    Integer pageNum,
    String sortField,
    String sortDir,
    Map<String, Object> listMap
  ) {
    List<CampaignMember> membersList = Database.query(
      getQuery(campaignId, sortField, sortDir)
    );
    List<CampaignMember> filteredList = new List<CampaignMember>();
    if (membersList.isEmpty()) {
      listMap.put('dataSize', 0);
      return filteredList;
    }
    listMap.put('dataSize', membersList.size());
    Integer pageSize = Integer.valueOf(config.get('pageSize'));
    Integer start = pageNum * pageSize;
    Integer max = Math.min(start + pageSize, membersList.size());
    for (Integer i = start; i < max; i++) {
      filteredList.add(membersList.get(i));
    }
    return filteredList;
  }

  private static String getQuery(
    Id campaignId,
    String sortField,
    String sortDir
  ) {
    String q = 'SELECT ';
    Set<String> dupeCheck = new Set<String>();
    dupeCheck.add('id');
    Map<String, Map<String, Object>> fieldMap = (Map<String, Map<String, Object>>) config.get(
      'fields'
    );
    for (String field : fieldMap.keySet()) {
      String check = field.toLowerCase();
      if (!dupeCheck.contains(check) && MEMBER_FIELD_MAP.get(field) != null) {
        q += field + ',';
        dupeCheck.add(check);
      }
    }
    q += 'Id FROM CampaignMember WHERE CampaignId =\'' + campaignId + '\' WITH USER_MODE';
    if (!String.isBlank(sortField) && !String.isBlank(sortDir)) {
      q += ' ORDER BY ' + sortField + ' ' + sortDir;
    }
    return q;
  }

  private class MyException extends Exception {
  }

  private without sharing class MyConfig {
    public Map<String, Object> getConfig() {
      Map<String, Object> configMap = new Map<String, Object>();
      List<ListViewEditCmpSettings__mdt> settings = settingsList != null
        ? settingsList
        : [
            SELECT Id, Api__c, IsEditable__c, MasterLabel, IsField__c, Val__c
            FROM ListViewEditCmpSettings__mdt WITH SYSTEM_MODE
          ];
      Map<String, Map<String, Object>> configFieldMap = new Map<String, Map<String, Object>>();
      for (ListViewEditCmpSettings__mdt setting : settings) {
        if (setting.IsField__c) {
          Map<String, Object> setMap = getSettingMap(setting);
          if (setMap != null) {
            configFieldMap.put(setting.Api__c, setMap);
          }
        } else {
          configMap.put(setting.MasterLabel, setting.Val__c);
        }
      }

      configMap.put('fields', configFieldMap);
      return configMap;
    }

    private Map<String, Object> getSettingMap(
      ListViewEditCmpSettings__mdt setting
    ) {
      String field = setting.Api__c;
      if (MEMBER_FIELD_MAP.get(field) == null) {
        return null;
      }
      DescribeFieldResult fieldDesc = MEMBER_FIELD_MAP.get(field).getDescribe();
      if (fieldDesc.isAccessible() == false) {
        return null;
      }
      Map<String, Object> setMap = new Map<String, Object>();
      setting.IsEditable__c = setting.IsEditable__c && fieldDesc.isUpdateable();
      setMap.put('setting', setting);
      setMap.put('label', fieldDesc.getLabel());
      String fieldType = String.valueOf(fieldDesc.getType());
      setMap.put('type', fieldType.toLowerCase());
      setMap.put('isSortable', fieldDesc.isSortable());
      if ('picklist'.equalsIgnoreCase(fieldType)) {
        setMap.put('listVals', getPickListVals(fieldDesc.getPicklistValues()));
      }
      return setMap;
    }

    private List<String> getPickListVals(List<Schema.PicklistEntry> listVals) {
      if (listVals.isEmpty()) {
        return null;
      }
      List<String> pickList = new List<String>();
      Integer defaultIdx = 0;
      Integer i = 0;
      for (Schema.PicklistEntry ple : listVals) {
        if (ple.isActive()) {
          pickList.add(ple.getValue() + '');
          if (ple.isDefaultValue()) {
            defaultIdx = i;
          }
          i++;
        }
      }
      if (defaultIdx != 0 && pickList.size() > 0) {
        String temp = pickList.get(0);
        pickList.add(0, pickList.get(defaultIdx));
        pickList.add(defaultIdx, temp);
      }
      return pickList;
    }
  }
}