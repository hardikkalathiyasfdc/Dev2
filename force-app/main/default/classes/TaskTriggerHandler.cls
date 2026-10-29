public with sharing class TaskTriggerHandler extends TriggerHandler {

    private static final String ERR_BULK_AFTER = 'TTH_BULK_AFTER_FAILED';

    private List<Task> oldTaskList;
    private List<Task> newTaskList;
    public static Boolean isFirstTime = true;

    public TaskTriggerHandler() {
        this(Trigger.old, Trigger.new);
    }

    public TaskTriggerHandler(List<Task> oldList, List<Task> newList) {
        oldTaskList = oldList;
        newTaskList = newList;
    }

    public override void bulkAfter() {
        try {
            Set<Id> whoIds = new Set<Id>();
            Map<Id, Task> taskMap = new Map<Id, Task>(newTaskList);
            Map<Id, Set<Id>> taskWhoRelationMap = new Map<Id, Set<Id>>();
            List<Task> tasks = [Select Id, Subject, (Select RelationId, Type from TaskWhoRelations where Type = 'Contact') 
                from Task where Id IN :taskMap.keySet()];
            System.debug('##########tasks: ' + tasks);
            for (Task t : tasks) {
                Set<Id> tempIds = new Set<Id>();
                for (TaskWhoRelation tWho : t.TaskWhoRelations) {
                    System.debug('##########taskWhoRelattWhoionMap: ' + tWho);
                    whoIds.add(tWho.RelationId);
                    tempIds.add(tWho.RelationId);
                }
                taskWhoRelationMap.put(t.Id, tempIds);
            }
            System.debug('##########taskWhoRelationMap: ' + taskWhoRelationMap);
            Map<Id, Contact> contacts = new Map<Id, Contact>([Select Id, Name from Contact where Id in :whoIds]);
            List<Task> updateTasks = new List<Task>();
            for (Task newTask: newTaskList) {
                Set<Id> taskWhoIds = taskWhoRelationMap.get(newTask.Id);
                System.debug('##########taskWhoIds: ' + taskWhoIds);
                String whoNames = '';
                for (Id whoId : taskWhoIds) {
                    System.debug('##########whoId: ' + whoId);
                    if (contacts.containsKey(whoId)) {
                        whoNames += (contacts.get(whoId)).Name + '; ';
                    }
                }
                whoNames = whoNames.removeEnd('; ');
                System.debug('##########whoNames: ' + whoNames);
                Task updateTask = new Task(Id = newTask.Id);
                updateTask.WhoId_Name__c = whoNames;
                updateTasks.add(updateTask);
            }
            if(!updateTasks.isEmpty()) {
                TaskTriggerHandler.isFirstTime = false;
                BBApps_Crud.doUpdateWithHandling(updateTasks, false, ERR_BULK_AFTER);
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_AFTER));
        }
    }
}