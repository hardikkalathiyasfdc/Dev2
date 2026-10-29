global class BatchStageProcess implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {

    private static final String ERR_START    = 'BSP_START_FAILED';
    private static final String ERR_EXECUTE  = 'BSP_EXECUTE_FAILED';
    private static final String ERR_FINISH   = 'BSP_FINISH_FAILED';
    BBApps_ErrorCustomFields fExecute = new BBApps_ErrorCustomFields(ERR_START);
    BBApps_ErrorCustomFields fStart = new BBApps_ErrorCustomFields(ERR_EXECUTE);
    BBApps_ErrorCustomFields fFinish = new BBApps_ErrorCustomFields(ERR_FINISH);
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(this,1);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query records to process
        try {
            return Database.getQueryLocator([SELECT Id, Email_Subject__c,Email_Reply_To__c,Email_Body__c,Processed__c 
                                             FROM Staging_Area__c 
                                             where Processed__c = false]);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, fExecute);
            return null;
        }
    }

    global void execute(Database.BatchableContext BC, List<Staging_Area__c> listStageRecords) {
        // Process each record
        try {
            for (Staging_Area__c rec : listStageRecords) {
                ZkipsterEmailForward.processEmailBody(rec.Email_Body__c,rec.Email_Subject__c,rec.Email_Reply_To__c);
                rec.Processed__c = true;
            }
            BBApps_Crud.doUpdateWithHandling(listStageRecords, false, ERR_EXECUTE);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, fStart);
        }
    }

       global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
        try {
            recurringScheduleJob();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, fFinish);
        }
    }

    /**
     * [recurringScheduleJob - Method invokes Scheduler again]
     */
	public void recurringScheduleJob() {
		Integer addTime = Integer.valueOf(5);
		DateTime now =  System.now().addMinutes(addTime);
		String day = string.valueOf(now.day());
		String month = string.valueOf(now.month());
		String hour = string.valueOf(now.hour());
		String minute = string.valueOf(now.minute());
		String second = string.valueOf(now.second());
		String year = string.valueOf(now.year());

		String strJobName = 'StageProcessBatch Job : ' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
		String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
		if (!Test.isRunningTest()) {
		System.schedule(strJobName, strSchedule, new BatchStageProcess());
		}
		for ( CronTrigger c : [Select State, Id, EndTime, CronExpression, CronJobDetail.Name From CronTrigger WHERE
		                       NextFireTime = null  AND State = 'DELETED' AND CronJobDetail.Name LIKE  'StageProcessBatch%' Limit 10]) {
			System.abortJob(c.id);
		}
    }

}