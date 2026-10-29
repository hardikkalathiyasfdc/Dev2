/***
 * Description: This class has methods being used to fetch events for the Event Management Page used by
 *              eventsManagement and eventsManagementMobileView lwc
 * Test Class: EventMangementControllerTest
 ***/
public with sharing class EventMangementController {
    
    public static final String EVENT_RECORD_TYPE_ID = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
        .get('Pre_Event').getRecordTypeId();
    private static final String EVENT_START_DATE_FIELD = 'Event_Start_Date_Time__c';
    private static final String START_DATE_UTC_FIELD = 'StartDateUtc__c';
    private static final String EQUALS = '=';
    private static final String GEATER_THAN = '>';
    private static final String LESS_THAN = '<';
    private static final String ERR_CLASS_FAILED = 'EventHistoryGenerationCtrl_CLASS_FAILED';
    
    @AuraEnabled
    public static String getEvents(String fieldName, String filter, String keyValue, String eventStatus, boolean programmatic, boolean includeGalas) {
        List<Event> events = new List<Event>();
        try {
            Date filterDate;
            User currentUser;
            List<Campaign> campaigns = new List<Campaign>();
            String soql = 'SELECT Id, Name, Programmatic__c, TotalYes__c, TotalNo__c, TotalGuests__c, TotalPend__c, TotalAttend__c, ' +
                                 'TotalNotAttend__c, End_Date_Time__c, Start_Date_Time__c, Event_Start_Date_Time__c, Event_End_Date_Time__c, ' +
                                 'TimeZone__c, EventStatus__c, EventCoordinator__c, EventCoordinator__r.Name, EventType__c, StartDateUtc__c, ' +
                                 'HowMRBAttended__c, HowPHAttending__c ' +
                         ' FROM Campaign WHERE RecordTypeId = :EVENT_RECORD_TYPE_ID';
            if(!(String.isEmpty(keyValue) && String.isEmpty(filter) && String.isEmpty(fieldName))) {
                String nextDate = null;
                if(String.isEmpty(keyValue)) keyValue = '';
                if(EVENT_START_DATE_FIELD.equalsIgnoreCase(fieldName)) {
                    filterDate = Date.valueOf(keyValue);
                    fieldName = START_DATE_UTC_FIELD;
                    Date tempDate = Date.valueOf(keyValue).addDays(1);
                    keyValue += 'T00:00:00Z';
                    nextDate = Datetime.newInstance(tempDate.year(), tempDate.month(), tempDate.day()).format('YYYY-MM-dd') + 'T00:00:00Z';
                }
                if(!String.isEmpty(fieldName)) {
                    soql += ' AND ' + fieldName;
                }
                if(!String.isEmpty(filter) && !String.isEmpty(fieldName)) {
                    if('Contains'.equalsIgnoreCase(filter)) {
                        soql += ' LIKE \'%' + keyValue + '%\'';
                    } else if('Equals'.equalsIgnoreCase(filter)) {
                        if('Yes'.equalsIgnoreCase(keyValue)){
                            soql += ' = ' + True;
                        } else if('No'.equalsIgnoreCase(keyValue)){
                            soql += ' = ' + False;
                        } else {
                            soql += ' = \'' + keyValue + '\'';
                        }
                    } else {
                        if(START_DATE_UTC_FIELD.equalsIgnoreCase(fieldName) && EQUALS.equalsIgnoreCase(filter)) {
                            soql += ' ' + GEATER_THAN + ' ' + keyValue + ' AND ' + fieldName + ' ' + LESS_THAN + ' ' + nextDate;
                        } else {
                            soql += ' ' + filter + ' ' + keyValue;
                        }
                    }
                }
            }
            if(!String.isEmpty(eventStatus)) {
                soql += ' AND eventStatus__c = \'' + eventStatus + '\'';
            }
            if((FeatureManagement.checkPermission('Events_Access_Custom_Permission') && !programmatic)) {
                soql += ' AND Programmatic__c = ' + programmatic;  
            }
            if(FeatureManagement.checkPermission('Events_Access_Custom_Permission') && !includeGalas) {
                soql += ' AND EventType__c != \'Staff Event - Employee Engagement - Gala\'';
            }
            soql += ' ORDER BY Start_Date_Time__c DESC limit 50000';
            if(START_DATE_UTC_FIELD.equalsIgnoreCase(fieldName)) {
                currentUser = [Select Id, TimeZoneSidKey from User where Id = :UserInfo.getUserId()];
            }
            campaigns = Database.query(soql);
            Set<Id> coordinatorUserIds = new Set<Id>();
            for(Campaign c : campaigns) {
                if(c.EventCoordinator__c != null) coordinatorUserIds.add(c.EventCoordinator__c);
            }
            // Query for contact with their Bio Photo
            Map<Id, String> userIdToBioPhoto = new Map<Id, String>();
            if(!coordinatorUserIds.isEmpty()) {
                for(Contact c : [
                    SELECT Id, Bio_Photo__c, BRM_User__c
                    FROM Contact
                    WHERE BRM_User__c IN :coordinatorUserIds
                ]) {
                    if(c.BRM_User__c != null && c.Bio_Photo__c != null) {
                        userIdToBioPhoto.put(c.BRM_User__c, c.Bio_Photo__c);
                    }
                }
            }
            for(Campaign event : campaigns) {
                Event evt = new Event();
                evt.event = event;
                evt.programatic = event.Programmatic__c; 
                if(event.Event_Start_Date_Time__c != null) {
                    evt.startDate = event.Event_Start_Date_Time__c;
                }
                if(event.Event_End_Date_Time__c != null) {
                    evt.endDate = event.Event_End_Date_Time__c;
                }
                if(event.TimeZone__c != null) {
                    evt.timeZone = event.TimeZone__c;
                }
                if(event.EventCoordinator__c != null) {
                    evt.coordinatorBioPhotoRichText = userIdToBioPhoto.get(event.EventCoordinator__c);
                }
                if(START_DATE_UTC_FIELD.equalsIgnoreCase(fieldName)) {
                    String localDateString = event.StartDateUtc__c.format('MM/dd/yyyy', currentUser.TimeZoneSidKey);
                    Date localDate = Date.parse(localDateString);
                    if((GEATER_THAN.equalsIgnoreCase(filter) && localDate >= filterDate) 
                    || (LESS_THAN.equalsIgnoreCase(filter) && localDate <= filterDate)
                    || (EQUALS.equalsIgnoreCase(filter) && localDate == filterDate) ) {
                        
                        events.add(evt);
                    }
                } else {
                    events.add(evt);
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }
        return JSON.serialize(events);
    }

    public class Event {
		public Campaign event { get; set; }
		public Boolean programatic { get; set; }
		public String startDate { get; set; }
		public String endDate { get; set; }
		public String timeZone { get; set; }
		public String coordinatorBioPhotoRichText { get; set; } 
	}
}