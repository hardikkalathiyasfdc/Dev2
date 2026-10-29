global class DeleteOldDataLoadsBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteOldDataLoadsBatch(), 200);
    }
}