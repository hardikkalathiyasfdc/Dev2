/**
* Author : Nishant Bakhrey
* Description : Helper class to fetch all the Chatter Feed Items displayed in the customChildObjectChangeLog LWC
* Created Date : 09/30/25
* Test : ChildObjectChangeLogControllerTest
**/
public without sharing class ChildObjectChangeLogController {

    @AuraEnabled(cacheable=true)
    public static Boolean hasRequiredPermission(String permissionSet) {
        try {
            return FeatureManagement.checkPermission(permissionSet);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields('CHILD_OBJ_CHANGE_LOG_PERM_CHECK_FAILED'));
            return false;
        }
    }
    
    public class LogItem {
        @AuraEnabled public String action;
        @AuraEnabled public String actionBy;
        @AuraEnabled public String timestamp;
        @AuraEnabled public String relatedRecordId;
        @AuraEnabled public String name;
        @AuraEnabled public Map<String, String> fieldValues;
    }

    @AuraEnabled(cacheable=true)
    public static List<LogItem> getFeedForParent(Id parentId, String objectApiName, String fieldsToFetch, String nameField, Boolean checkForRecordAccess) {
        try {
            List<FeedItem> feedItems = [
                SELECT Id, Body, CreatedDate, CreatedBy.Name, Title
                FROM FeedItem
                WHERE ParentId = :parentId
                WITH SYSTEM_MODE
                ORDER BY CreatedDate DESC
            ];
            Set<Id> childIds = new Set<Id>();
            for(FeedItem fi : feedItems) { 
                String recordId = getRecordId(fi.Body);
                if(recordId == null) continue;
                Id rId = (Id)recordId;
                String api = rId.getSObjectType().getDescribe().getName();
                if(!String.isBlank(objectApiName) && !String.isBlank(api) && objectApiName == api) {
                    childIds.add(rId);
                }
            }
            if(childIds.isEmpty()) return new List<LogItem>();
            Map<Id, UserRecordAccess> accessByRecordId = new Map<Id, UserRecordAccess>();
            if(checkForRecordAccess) {
                accessByRecordId = new Map<Id, UserRecordAccess>([
                    SELECT RecordId, HasReadAccess
                    FROM UserRecordAccess
                    WHERE UserId = :UserInfo.getUserId()
                      AND RecordId IN :childIds
                    WITH SYSTEM_MODE
                ]);
            }
            Map<Id, SObject> recordsById = new Map<Id, SObject>();
            String soql = 'SELECT Id, ' + fieldsToFetch + 
                         ' FROM ' + objectApiName + 
                         ' WHERE Id IN :childIds';
            for(SObject sob : Database.query(soql, AccessLevel.SYSTEM_MODE)) {
                recordsById.put((Id)sob.get('Id'), sob);
            }
            List<LogItem> result = new List<LogItem>();
            for(FeedItem fi : feedItems) {
                String rid = getRecordId(fi.Body);
                if(rid == null) continue;
                Id childId = (Id)rid;
                UserRecordAccess ura = accessByRecordId.get(childId);
                if((ura == null || !ura.HasReadAccess) && checkForRecordAccess) continue;
                SObject rec = recordsById.get(childId);
                if(rec == null) continue;
                LogItem row = new LogItem();
                row.relatedRecordId = rid;
                row.actionBy = fi.CreatedBy.Name;
                row.timestamp = fi.CreatedDate.format();
                row.action = (fi.Title.contains('Added')) ? 'Added' : 
                             (fi.Title.contains('Removed')) ? 'Removed' : null;
                row.name = (String)rec.get(nameField);
                Map<String, String> vals = new Map<String, String>();
                if(fieldsToFetch != null) {
                    for(String f : fieldsToFetch.split(',')) {
                        Object v = rec.get(f);
                        vals.put(f, (v == null) ? null : String.valueOf(v));
                    }
                }
                row.fieldValues = vals;
                result.add(row);
            }
            return result;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields('CHILD_OBJ_CHANGE_LOG_FETCH_FAILED'));
            return new List<LogItem>();
        }
    }

    private static String getRecordId(String body) {
        if(String.isBlank(body)) return null;
        List<String> parts = body.split('\\|');
        if(parts.size() >= 2) {
            String id = parts[1].trim();
            if(id != null && id.length() >= 15) return id;
        }
        return null;
    }
}