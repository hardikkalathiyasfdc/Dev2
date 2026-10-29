/*
* test class: DailyChatterEmailBatchTest
*/
global without sharing class ScheduleDailyChatterEmail  implements Schedulable {
    private static final String ERR_EXECUTE= 'SCHEDULE_DAILY_CHATTER_EMAIL_EXECUTE_FAILED';
     @TestVisible
    private static Boolean throwExceptionForTest = false;
    
    global void execute(SchedulableContext sc) {
        try{
             // only for test coverage
            if(Test.isRunningTest() && throwExceptionForTest){
                Integer x = 1 / 0;
            }
            DailyChatterEmailBatch chatterBatch = new DailyChatterEmailBatch();
            database.executebatch(chatterBatch);
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_EXECUTE));
        } 
    }
}