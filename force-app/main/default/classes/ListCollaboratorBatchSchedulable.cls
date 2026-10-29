global without sharing class ListCollaboratorBatchSchedulable implements Schedulable {
   global void execute(SchedulableContext sc) {
      ListCollaboratorBatch b = new ListCollaboratorBatch();
      Database.executeBatch(b, 200);
   }
}