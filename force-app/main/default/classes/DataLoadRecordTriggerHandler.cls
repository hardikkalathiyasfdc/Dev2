public without sharing class DataLoadRecordTriggerHandler extends TriggerHandler {

    private static final String ERR_BEFORE_INSERT = 'DLRTH_BEFORE_INSERT_FAILED';
    private static final String ERR_BEFORE_UPDATE = 'DLRTH_BEFORE_UPDATE_FAILED';

    public override void beforeInsert(SObject so) {
        try {
            Data_Load_Record__c dlRecord = (Data_Load_Record__c) so;
            if(String.isblank(dlRecord.Converted_LastName__c)){
                dlRecord.Converted_FirstName__c =  dlRecord.First_Name__c ;
                dlRecord.Converted_LastName__c =  dlRecord.Last_Name__c ;
            }
            dlRecord.Converted_FirstName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(dlRecord.First_Name__c,false);
            dlRecord.Converted_LastName__c  = SpecialCharactersHelper.convertSpecialCharToEnglish(dlRecord.Last_Name__c,false);
            dlRecord.Converted_MiddleName__c  = SpecialCharactersHelper.convertSpecialCharToEnglish(dlRecord.Middle_Name__c,false);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BEFORE_INSERT));
        }
    }
    //jlu scan for special characters in names
    public override void beforeUpdate(SObject oldSo, SObject so) {
        try {
            Data_Load_Record__c oldDlRecord = (Data_Load_Record__c) oldSo;
            Data_Load_Record__c curDlRecord = (Data_Load_Record__c) so;
            if(isFieldChanged(curDlRecord, 'First_Name__c') || curDlRecord.Converted_FirstName__c==null ){
                curDlRecord.Converted_FirstName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(curDlRecord.First_Name__c,false);
            }
            if(isFieldChanged(curDlRecord, 'Last_Name__c') || curDlRecord.Converted_LastName__c==null){
                curDlRecord.Converted_LastName__c  = SpecialCharactersHelper.convertSpecialCharToEnglish(curDlRecord.Last_Name__c,false);
            }
            if(isFieldChanged(curDlRecord, 'Converted_MiddleName__c') || curDlRecord.Converted_MiddleName__c ==null){
                curDlRecord.Converted_MiddleName__c  = SpecialCharactersHelper.convertSpecialCharToEnglish(curDlRecord.Middle_Name__c,false);
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BEFORE_UPDATE));
        }
    }
}