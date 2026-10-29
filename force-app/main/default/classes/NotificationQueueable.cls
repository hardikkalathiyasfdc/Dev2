public with sharing class NotificationQueueable implements Queueable {
    
    private Notification_Config__mdt config;
    private Set<Id> recordIds;
    private Map<Id, Map<String, String>> customMergeFields;
    private Id targetObjectId;
    private User currentUser;

    public NotificationQueueable(Notification_Config__mdt config, Set<Id> recordIds) {
        this(config, recordIds,  new Map<Id, Map<String, String>>(), null, null);
    }

    public NotificationQueueable(Notification_Config__mdt config, Set<Id> recordIds, Map<Id, Map<String, String>> customMergeFields) {
        this(config, recordIds,  customMergeFields, null, null);
    }

    public NotificationQueueable(Notification_Config__mdt config, Set<Id> recordIds, 
            Map<Id, Map<String, String>> customMergeFields, Id targetObjectId, User currentUser) {
        this.config = config;
        this.recordIds = recordIds;
        this.customMergeFields = customMergeFields;
        this.targetObjectId = targetObjectId;
        this.currentUser = currentUser;
    }

    public void execute(QueueableContext context) {
        NotificationService.processEmail(config, recordIds, customMergeFields, targetObjectId, currentUser);
    }
}