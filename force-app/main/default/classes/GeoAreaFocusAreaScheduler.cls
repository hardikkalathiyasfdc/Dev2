/**
* Author      : Ravi Bheemreddy
* Description : Scheduler class to invoke the GeoAreaFocusAreaBatch class
* Test        : GeoAreaFocusAreaSchedulerTest
*/
global without sharing class GeoAreaFocusAreaScheduler implements Schedulable {

    private static final String ERR_EXECUTE = 'GEOAREA_FOCUSAREA_SCHEDULER_EXECUTE_FAILED';
    private static final String MSG_EXECUTE = 'Failed while running GeoAreaFocusAreaScheduler.';
    BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);

    global void execute(SchedulableContext SC) {
        try {
            GeoAreaFocusAreaBatch batchJob = new GeoAreaFocusAreaBatch();
            Database.executeBatch(batchJob);
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, f); }
    }
}