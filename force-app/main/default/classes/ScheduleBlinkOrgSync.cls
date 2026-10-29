/**
* Author : Gauri Sagane
* Date   : 10/25/2024
* Jira   : IM-32
* Description : This scheduled job is scheduled to sync orgs in BRM based on Bgive changes. Schedule Frequency is to run every 15 mins.
* Test : ScheduleBlinkOrgSyncTest
*/

public with sharing class ScheduleBlinkOrgSync implements Schedulable {

    /**
    * Description : Method to call QueueableBlinkOrgSync
    * Parameters : SC SchedulableContext
    * Return Type : void
    */
    public void execute(SchedulableContext SC) {
        ID jobID = System.enqueueJob(new QueueableBlinkOrgSync());
    }
}