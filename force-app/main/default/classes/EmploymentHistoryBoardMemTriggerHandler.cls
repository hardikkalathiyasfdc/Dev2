/*********************************************
* Created: October 30, 2019
* Created By: Slalom Consulting
* Business Purpose: Syncs and updates contact fields based on related employment and board membership records during trigger events.
* Updates
* ----------------------------------
* Updated By    Date            Comment
* Hardik		11/26/2024		Moving changes from Trigger to Handler
***********************************************/
public without sharing class EmploymentHistoryBoardMemTriggerHandler extends TriggerHandler {
    public List<Employment_History_and_Board_Membership__c> newEmpHistory;
    public List<Employment_History_and_Board_Membership__c> oldEmpHistory;
    public Map<Id, Employment_History_and_Board_Membership__c> newMap;   
    public Map<Id, Employment_History_and_Board_Membership__c> oldMap;
    
    public Boolean isBeforeTrigger = false;
    public Boolean isAfterTrigger = false;
    public Boolean isUpdateTrigger = false;
    public Boolean isDeleteTrigger = false;
    public Boolean isInsertTrigger = false;
    
    private static final String ERR_BULK_AFTER = 'EMPLOYMENT_HISTORY_BOARD_MEM_BULK_AFTER_FAILED';
    private static final String ERR_UPDATE_BP_BOARD_MEM_VALUE = 'EMPLOYMENT_HISTORY_BOARD_MEM_UPDATE_BP_BOARD_MEM_VALUE_FAILED';
    private static final String ERR_UPDATE_FAILED = 'EMPLOYMENT_HISTORY_BOARD_MEMTRIGGER__UPDATE_FAILED';
    
    public EmploymentHistoryBoardMemTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Employment_History_and_Board_Membership__c>) Trigger.oldMap, (Map<Id, Employment_History_and_Board_Membership__c>) Trigger.newMap);
        
        // Set flags based on the trigger context
        if (Trigger.isBefore) isBeforeTrigger = true;
        if (Trigger.isAfter) isAfterTrigger = true;
        if (Trigger.isUpdate) isUpdateTrigger = true;
        if (Trigger.isDelete) isDeleteTrigger = true; 
        if (Trigger.isInsert) isInsertTrigger = true;       
    }
    
    // Overloaded constructor to initialize lists and maps for old and new records in the trigger
    public EmploymentHistoryBoardMemTriggerHandler(List<Employment_History_and_Board_Membership__c> oldCList, List<Employment_History_and_Board_Membership__c> newCList, 
                                                   Map<Id, Employment_History_and_Board_Membership__c> oldMap, Map<Id, Employment_History_and_Board_Membership__c> newMap) {

        this.oldEmpHistory = oldCList;
        this.newEmpHistory = newCList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    
    public override void bulkBefore() {
        if(isInsertTrigger || isUpdateTrigger) {
            updateYearFields(newEmpHistory, oldMap);
        }
    }
    
    public override void bulkAfter() {
        try {
            if(isInsertTrigger || isUpdateTrigger) {
                updateBPBoardMemValue(newEmpHistory);
            } else if(isDeleteTrigger) {
                updateBPBoardMemValue(oldEmpHistory);
            }
        } catch(Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_AFTER)); 
        }
    }
    
    // method to update back end picklist field on contact with values Board Mem and Former Board Mem when relevant related org record is created,updated or deleted
    public static void updateBPBoardMemValue(List<Employment_History_and_Board_Membership__c> triggerNew) {
        try {
            Set<Id> conNames = new Set<Id>();
            for(Employment_History_and_Board_Membership__c empIns : triggerNew) {
                conNames.add(empIns.Contact_Name__c);
            }
            if(conNames.size() > 0) {
                List<Contact> lstConToUpdate = new List<Contact>();
                for(Contact con : [SELECT Id, BP_Board_Member_Former_Board_Member__c, 
                                          (SELECT Id, createdDate, Role__c 
                                           FROM Employment_History__r 
                                           WHERE Organization_Name__r.Name = 'Bloomberg Philanthropies' 
                                             AND (Role__c = 'Board Member' OR Role__c = 'Former Board Member') 
                                           ORDER BY createdDate DESC) 
                                   FROM Contact 
                                   WHERE Id IN :conNames]) {

                    if(con.Employment_History__r != null && con.Employment_History__r.size() > 0) {
                        // If Employment History exists, update BP_Board_Member_Former_Board_Member__c with the Role from the most recent Employment History record
                        for(Employment_History_and_Board_Membership__c empIns : con.Employment_History__r) {
                            con.BP_Board_Member_Former_Board_Member__c = empIns.Role__c;
                            lstConToUpdate.add(con);
                            break;
                        }
                    } else if(con.BP_Board_Member_Former_Board_Member__c != null) {
                        // If no Employment History exists, clear the field
                        con.BP_Board_Member_Former_Board_Member__c = null;
                        lstConToUpdate.add(con);
                    }
                }
                if(!lstConToUpdate.isEmpty()) BBApps_Crud.doUpdateWithHandling(lstConToUpdate, false, ERR_UPDATE_FAILED);
            }
        } catch(Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_BP_BOARD_MEM_VALUE)); 
        }
    }

    private static void updateYearFields(List<Employment_History_and_Board_Membership__c> triggerNew, Map<Id, Employment_History_and_Board_Membership__c> oldMap) {
        try {
            Boolean hasOldMap = (oldMap != null && !oldMap.isEmpty());
            for(Employment_History_and_Board_Membership__c empIns : triggerNew) {
                Employment_History_and_Board_Membership__c oldRec = hasOldMap ? oldMap.get(empIns.Id) : null;
                Boolean startChanged = (oldRec == null) 
                                       ? true 
                                       : empIns.Employment_Start_Date__c != oldRec.Employment_Start_Date__c;
                if(startChanged && empIns.Employment_Start_Date__c != null) {
                    empIns.From__c = String.valueOf(empIns.Employment_Start_Date__c.year());
                }
                Boolean endChanged = (oldRec == null) 
                                     ? true 
                                     : empIns.Employment_End_Date__c != oldRec.Employment_End_Date__c;
                if(endChanged && empIns.Employment_End_Date__c != null) {
                    empIns.To__c = String.valueOf(empIns.Employment_End_Date__c.year());
                }
            }
        } catch(Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_FAILED)); 
        }
    }
}