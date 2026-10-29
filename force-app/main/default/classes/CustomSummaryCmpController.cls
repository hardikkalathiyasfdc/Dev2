public with sharing class CustomSummaryCmpController {
    public static Map<String, List<Summary_Settings__mdt>> customSettings = getSettings();
    private static final Map<String, Schema.SObjectType> GLOBAL_SCHEMA = Schema.getGlobalDescribe();
    private static final String ERR_GET_SUMMARIES = 'CUSTOM_SUMMARY_CMP_CONTROLLER_GET_SUMMARIES_FAILED';
    private static final String ERR_HAS_ACCESS = 'CUSTOM_SUMMARY_CMP_CONTROLLER_HAS_ACCESS_FAILED';
    private static final String ERR_GET_COUNT = 'CUSTOM_SUMMARY_CMP_CONTROLLER_GET_COUNT_FAILED';
    private static final String ERR_GET_RECORD_TYPE_ID= 'CUSTOM_SUMMARY_CMP_CONTROLLER_GET_RECORD_TYPE_ID_FAILED';
    private static final String ERR_GET_FILE_COUNT= 'CUSTOM_SUMMARY_CMP_CONTROLLER_GET_FILE_COUNT_FAILED';

    @AuraEnabled
    public static List<Object> getSummaries(Id recordId) {
        try {
            String objName = recordId.getSObjectType().getDescribe().getName();
            List<Summary_Settings__mdt> sumList = customSettings.get(objName);
            List<Map<String, Object>> resultList = new List<Map<String, Object>>();
            for(Summary_Settings__mdt sum : sumList) {
                if(String.isBlank(sum.SObject__c) || hasAccess(sum.SObject__c, sum.Related_Field__c)) {
                    Map<String, Object> sumMap = new Map<String, Object>();
                    sumMap.put('sObject', sum.SObject__c);
                    sumMap.put('icon', sum.Icon__c);
                    sumMap.put('count', getCount(sum, recordId));
                    sumMap.put('label', sum.MasterLabel);
                    sumMap.put('sort', sum.Sort_Order__c);
                    resultList.add(sumMap);
                }
            }
            return resultList;
        } catch(Exception e) {
            BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_SUMMARIES));
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static boolean hasAccess(String objName, String Related_Field) {
        String queryField = 'Id ';
        if(Related_Field != 'Id') queryField = queryField + ',' + Related_Field;
        String q = 'SELECT ' + queryField + ' FROM ' + objName + ' WITH USER_MODE LIMIT 1';
        List<SObject> checkList = Database.query(q);
        return !checkList.isEmpty();
    }

    private static Integer getCount(Summary_Settings__mdt sum, Id recordId) {
        if('Events'.equals(sum.MasterLabel)) return getEventCount(recordId);
        if('Lists'.equals(sum.DeveloperName)) return getListCount(recordId);
        if('Org Engagements'.equals(sum.MasterLabel)) return getEngagementCount(recordId, sum.RecordType__c);
        if('Organization Highlights/CityView'.equals(sum.MasterLabel)) return getOrgHighlightCount(recordId);
        if('Organization Associations'.equals(sum.MasterLabel)) return getOrgAssociationCount(recordId);
        if('Leadership Contacts'.equals(sum.MasterLabel)) return getLeadershipContactCount(recordId);
        if('Tags'.equals(sum.MasterLabel)) return getTagCount(recordId);
        Integer count = 0;
        String objName = sum.SObject__c;
        String q = 'SELECT COUNT() FROM ' + objName + ' WHERE ' + sum.Related_Field__c + ' = :recordId';
        if(!String.isBlank(sum.RecordType__c)) {
            Id recId = getRecordTypeId(objName, sum.RecordType__c);
            if(recId == null) return 0;
            q += recId == null ? '' : ' AND RecordTypeId = ' + '\'' + recId + '\'';
        }
        q += ' WITH SYSTEM_MODE';
        return Database.countQuery(q);
    }

    private static Integer getTagCount(Id recordId) {
        String q = 'SELECT COUNT() FROM Tag_Junction__c WHERE Account__c = :recordId AND RecordType.DeveloperName = \'Account\' WITH SYSTEM_MODE';
        return Database.countQuery(q);
    }

    private static Integer getLeadershipContactCount(Id recordId) {
        String q = 'SELECT COUNT() FROM Contact WHERE AccountId = :recordId AND Leadership_Contact__c = true WITH SYSTEM_MODE';
        return Database.countQuery(q);
    }

    private static Integer getOrgAssociationCount(Id recordId) {
        String q = 'SELECT COUNT() FROM Org_Association__c WHERE Organization__c = :recordId AND Deleted__c = false WITH SYSTEM_MODE';
        return Database.countQuery(q);
    }

    private static Integer getOrgHighlightCount(Id recordId) {
        String q = 'SELECT COUNT() FROM Interaction__c WHERE Organization__c = :recordId AND RecordType.Name = \'Organization Highlight/CityView\' WITH SYSTEM_MODE';
        return Database.countQuery(q);
    }

    private static Integer getEngagementCount(Id recordId, String recordType) {
        Id acctId = [
            SELECT Id
            FROM Account
            WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :recordId)
            WITH SYSTEM_MODE
        ].Id;
        String q = 'SELECT COUNT() FROM Interaction__c WHERE Organization__c = :acctId WITH SYSTEM_MODE';
        return Database.countQuery(q);
    }

    private static Id getRecordTypeId(String objName, String recName) {
        return GLOBAL_SCHEMA.get(objName)
               .getDescribe()
               .getRecordTypeInfosByName()
               .get(recName)
               .getRecordTypeId();
    }

    private static Integer getListCount(Id recordId) {
        return CampaignMembersAuraController.getCampaignMembers(recordId, true).size();
    }

    private static Integer getEventCount(Id recordId) {
        List<EventHistoryAuraCtrl.EventHistory> events =
            (List<EventHistoryAuraCtrl.EventHistory>)JSON.deserialize(EventHistoryAuraCtrl.getEventsByContact(recordId), List<EventHistoryAuraCtrl.EventHistory>.Class);
        return events.size();
    }

    private static Map<String, List<Summary_Settings__mdt>> getSettings() {
        return new SystemController().getSettings();
    }

    private without sharing class SystemController {
        public Map<String, List<Summary_Settings__mdt>> getSettings() {
            List<Summary_Settings__mdt> sumList = [
                SELECT DeveloperName, MasterLabel, RecordType__c, Related_Field__c, SObject__c, Sort_Order__c,
                       ParentField__c, Type__c, Icon__c
                FROM Summary_Settings__mdt
            ];
            Map<String, List<Summary_Settings__mdt>> settingMap = new Map<String, List<Summary_Settings__mdt>>();
            for(Summary_Settings__mdt sum : sumList) {
                List<Summary_Settings__mdt> mapList = settingMap.get(sum.Type__c) != null
                                                      ? settingMap.get(sum.Type__c)
                                                      : new List<Summary_Settings__mdt>();
                mapList.add(sum);
                settingMap.put(sum.Type__c, mapList);
            }
            return settingMap;
        }
    }
}