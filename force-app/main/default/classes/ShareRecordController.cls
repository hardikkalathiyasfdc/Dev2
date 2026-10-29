/**
 * Author : Lahari AnumalaSetty
 * Date   : 03/12/2023
 * Jira   : BRME-5073/BRME-5113
 * Description : This class is used to insert, update and delete the shared object based on user preference 
 * Test   : ShareRecordControllerTest
 **/
public without sharing class ShareRecordController {
    private static final String ERR_GET_SHARE_OBJECT_NAME= 'SHARE_RECORD_CONTROLLER_GET_SHARE_OBJECT_NAME_FAILED'; 
    private static final String ERR_SHARE_RECORD= 'SHARE_RECORD_CONTROLLER_SHARE_RECORD_FAILED';
    private static final String ERR_GET_SHARE_RECORD= 'SHARE_RECORD_CONTROLLER_GET_SHARE_RECORD_FAILED'; 
    private static final String ERR_DELETE_RECORD= 'SHARE_RECORD_CONTROLLER_DELETE_RECORD_FAILED'; 
    private static final String ERR_UPDATE_RECORD= 'SHARE_RECORD_CONTROLLER_UPDATE_RECORD_FAILED'; 
    
    public static String getShareObjectName(String recordId) {
        try{
            String sObjName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            if(sObjName.right(3) == '__c') {
                sObjName = sObjName.replace('__c','__Share');
            } else {
                sObjName = sObjName + 'Share';
            }
            return sObjName;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_SHARE_OBJECT_NAME));
            return null;
        }
    }
    
    @AuraEnabled
    public static String shareRecord(String recordId, List<String> userOrGroupList, String shareOptionValue, String accessLevel) {
        try {
            if(recordId != null) {
                String sobjectName = getShareObjectName(recordId);
                String accessLevelValue = (accessLevel == 'Read Only') ? 'Read' : 'Edit';
                List<Sobject> shareRecordList = new List<Sobject>();
                
                if(shareOptionValue == 'Users' || shareOptionValue == 'Groups') {
                    for(String userOrGroupId : userOrGroupList) {
                        shareRecordList.add(getShareRecord(sobjectName, recordId, Id.valueOf(userOrGroupId), accessLevelValue));
                    }
                } 
                System.debug(shareRecordList);
                if(!shareRecordList.isEmpty()) {
                    insert shareRecordList;
                    return shareRecordList.size() + ' record shares were created.';
                }
                return null;
            } else {
                return null;
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SHARE_RECORD));
            throw new AuraHandledException('Error sharing record: ' + ex);
        }
    }
    
    public static SObject getShareRecord(String sobjectName, Id recordId, Id userOrGroupId, String accessLevelValue) {
        try{
            SObject sobjectRec = Schema.getGlobalDescribe().get(sobjectName).newSObject();
            Map<String, String> shareRecordFieldNames = getShareRecordFieldNames(sobjectName);
            sobjectRec.put(shareRecordFieldNames.get('ParentId'), recordId);
            sobjectRec.put(shareRecordFieldNames.get('AccessLevel'), accessLevelValue);
            sobjectRec.put('UserOrGroupId', userOrGroupId);
            return sobjectRec;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_SHARE_RECORD));
            return null;
        } 
    }
    
    @AuraEnabled
    public static List<Sobject> getAllSharedRecords(String recId) {
        String sobjectName = getShareObjectName(recId);
        Map<String, String> shareRecordFieldNames = getShareRecordFieldNames(sobjectName);
        String parentIdField = shareRecordFieldNames.get('ParentId');
        String accessLevelField = shareRecordFieldNames.get('AccessLevel');
        String querySharedUsers = 'SELECT Id,' + parentIdField + ', UserOrGroupId, UserOrGroup.Name, UserOrGroup.Type,' + accessLevelField + 
                                 ' FROM ' + sobjectName + 
                                 ' WHERE ' + parentIdField + ' = :recId AND ' + accessLevelField + '!=  \'All\' ' + 
                                  'ORDER BY UserOrGroup.Name ASC ';
        List<Sobject> sobjectRecListSharedUsers = Database.query(querySharedUsers);
        String queryOwner = 'SELECT Id,' + parentIdField + ', UserOrGroupId, UserOrGroup.Name, UserOrGroup.Type,' + accessLevelField + 
                           ' FROM ' + sobjectName + 
                           ' WHERE ' + parentIdField + ' = :recId AND ' + accessLevelField + ' =  \'All\' ';
        List<Sobject> sobjectRecOwner = Database.query(queryOwner);
        sobjectRecListSharedUsers.addAll(sobjectRecOwner);
        return sobjectRecListSharedUsers;
    }

    public static Map<String, String> getShareRecordFieldNames(String sobjectName) {
        Map<String, String> shareRecordFieldNames = new Map<String, String>();
        if(sobjectName.contains('__Share')) {
            shareRecordFieldNames.put('ParentId', 'ParentId');
            shareRecordFieldNames.put('AccessLevel', 'AccessLevel');
        } else {
            String standardObjectName = sobjectName.substringBefore('Share');
            shareRecordFieldNames.put('ParentId', standardObjectName + 'Id');
            shareRecordFieldNames.put('AccessLevel', standardObjectName + 'AccessLevel');
        }
        return shareRecordFieldNames;
    }
    
    @AuraEnabled
    public static String deleteRecord(String recordId, List<String> shareRecDeletionIds) {
        try {
            String sobjectName = getShareObjectName(recordId);
            List<Sobject> shareRecDeleteList = new List<Sobject>();
            for(String recDeletionId : shareRecDeletionIds) {
                SObject SObjectRec = Schema.getGlobalDescribe().get(sobjectName).newSObject();
                SObjectRec.Id = Id.valueOf(recDeletionId);
                shareRecDeleteList.add(SObjectRec);
            }
            if(!shareRecDeleteList.isEmpty()) {
                delete shareRecDeleteList;
            }
            String successMsg = shareRecDeleteList.size() + ' record shares were deleted.';
            return successMsg;
        } catch (Exception excep) {
            BBApps_ErrorHandler.logErrors(excep, new BBApps_ErrorCustomFields(ERR_DELETE_RECORD)); 
            throw new AuraHandledException('Error deleting record: ' + excep);
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static boolean hasGeneralSharingHierarchyPermission() {
        List<PermissionSetAssignment> permAssignment = [
            SELECT PermissionSet.Name 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId() AND 
                  PermissionSet.Name = :Assets.SHARING_HIERARCHY_PERMSET];
         return (permAssignment != null && permAssignment.size() > 0);
    }
    
    @AuraEnabled
    public static String updateRecord(String recordId, String shareRecUpdateList) {
        try {
            String sobjectName = getShareObjectName(recordId);
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sobjectName);
            List<Sobject> shareRecUpdateFinalList = new List<Sobject>();
            List<UpdateShareRecWrapper> shareRecordUpdateList = 
                (List<UpdateShareRecWrapper>)JSON.deserialize(shareRecUpdateList, List<UpdateShareRecWrapper>.Class);
         
            for(UpdateShareRecWrapper wrapperObj : shareRecordUpdateList) {
                SObject sobj = sObjectType.newSObject(); 
                sobj.put('Id', Id.valueOf(wrapperObj.recId));
                Map<String, String> shareRecordFieldNames = getShareRecordFieldNames(sobjectName);
                String accessLevelFieldName = shareRecordFieldNames.get('AccessLevel');
                sobj.put(accessLevelFieldName, (wrapperObj.accessLevel == 'Read Only') ? 'Read' : 'Edit');
                shareRecUpdateFinalList.add(sobj);
            }
            
            if(!shareRecUpdateFinalList.isEmpty()) {
                 BBApps_Crud.doUpdateWithHandling(shareRecUpdateFinalList, false, new BBApps_ErrorCustomFields(ERR_UPDATE_RECORD));
            }
            return shareRecUpdateFinalList.size()+' record shares were updated.';
        } catch (Exception excep) {
            BBApps_ErrorHandler.logErrors(excep, new BBApps_ErrorCustomFields(ERR_UPDATE_RECORD)); 
            throw new AuraHandledException('Error updating record: ' + excep);
        }
    }

    public Class UpdateShareRecWrapper {
        @AuraEnabled public String recId;
        @AuraEnabled public String accessLevel;
    }
}