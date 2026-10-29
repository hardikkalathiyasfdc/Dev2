public with sharing class ElectedOfficeTriggerHandler extends TriggerHandler {
    public List<ElectedOffice__c> newOffices;
    public List<ElectedOffice__c> oldOffices;
    
    public Boolean isAfterTrigger = false;
    public Boolean isUpdateTrigger = false;
    public Boolean isInsertTrigger = false;
    private static final String ERR_AND_FINALLY  = 'ELECTED_OFFICE_TRIGGER_AND_FINALLY_FAILED';
    
    public ElectedOfficeTriggerHandler() {
        this(Trigger.old, Trigger.new);
        if (Trigger.isAfter) isAfterTrigger = true;
        if (Trigger.isUpdate) isUpdateTrigger = true;
        if (Trigger.isInsert) isInsertTrigger = true;   
    }
    
    public ElectedOfficeTriggerHandler(List<ElectedOffice__c> oldOfficeList, List<ElectedOffice__c> newOfficeList) {
        newOffices = newOfficeList;
        oldOffices = oldOfficeList;
    }
    
    public override void andFinally() {
        try{ 
            if( isAfterTrigger ) {
                if( isUpdateTrigger ) {
                    FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
                }
                
                if( isInsertTrigger ) {//After Elected Office newly creation, the Elected Office Hisotry Custom fields should be tracked
                    List<ElectedOffice__c> oldEmptyOffice = new List<ElectedOffice__c>(); //Empty old Elected Office List to fit the logic inside the History tracking logic
                    for( Integer i = 0; i < newOffices.size(); i++ ) {
                        oldEmptyOffice.add(new ElectedOffice__c());
                    }
                    FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AND_FINALLY)); }
    }
    
}