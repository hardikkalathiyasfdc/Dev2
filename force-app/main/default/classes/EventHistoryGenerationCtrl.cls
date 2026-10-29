public with sharing class EventHistoryGenerationCtrl {
    public List<EventHistoryAuraCtrl.EventHistory> events {get; set;}
    public String fullName {get; set;}
    public Integer totalYes {get; set;}
    public Integer totalAttended {get; set;}
    public Integer totalNo {get; set;}
    public Integer totalDidNotAttend {get; set;}
    public String currentDate {get; set;}
     private static final String ERR_CLASS_FAILED = 'EventHistoryGenerationCtrl_CLASS_FAILED';

    public EventHistoryGenerationCtrl() {
        try {
            String contactId = ApexPages.currentPage().getParameters().get('id');
            totalYes = 0;
            totalAttended = 0;
            totalNo = 0;
            totalDidNotAttend = 0;
            List<Contact> cnts = [SELECT Full_Name__c FROM Contact WHERE Id =: contactId];
            if(cnts.size() > 0) fullName = cnts[0].Full_Name__c;
            currentDate = Date.today().format();
            events = (List<EventHistoryAuraCtrl.EventHistory>)JSON.deserialize(EventHistoryAuraCtrl.getEventsByContact(contactId), 
                                                                            List<EventHistoryAuraCtrl.EventHistory>.class);
            for(EventHistoryAuraCtrl.EventHistory event : events) {
                if ('Yes'.equals(event.rsvpStatus)) {
                    totalYes += 1;
                } else if('No'.equals(event.rsvpStatus)) {
                    totalNo += 1;
                }
                if (String.isNotBlank(event.attended) && event.attended.contains('Yes')) {
                    totalAttended += 1;
                } else if(String.isNotBlank(event.attended) && 'Did Not Attend'.equals(event.attended)) {
                    totalDidNotAttend += 1;
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}