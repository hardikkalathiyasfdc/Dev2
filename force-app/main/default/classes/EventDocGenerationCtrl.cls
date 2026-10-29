public with sharing class EventDocGenerationCtrl {
    public String events {set;get;}
    public String lastMeeting {set;get;}

    public final static String EVENT_RECORD_TYPE_ID = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
    private static final String ERR_EVENT_DOC_GENERATION_CTRL= 'EVENT_DOC_GENERATION_CTRL_FAILED';

    public EventDocGenerationCtrl() {
        try{

        lastMeeting = ApexPages.currentPage().getParameters().get('last');
        Map<Integer, List<EventInfo>> eventsByYear = new Map<Integer, List<EventInfo>>();
        List<EventInfo> tmpEvents = new List<EventInfo>();
        List<Campaign> cms =    [SELECT Id, Name, Start_Date_Time__c,  End_Date_Time__c, LocationDetail__c, LocationName__c, 
                                    ExpectedAttendance__c, HowMRBAttended__c, SetUpEventLocationType__c, VirtualEventLink__c, EventCoordinator__r.Name,
                                    CreatedDate, Description, EventCoordinator__r.Phone, EventCoordinator__r.Email
                                  FROM Campaign
                                  WHERE Start_Date_Time__c >= TODAY
                                  AND RecordTypeId =: EVENT_RECORD_TYPE_ID WITH SYSTEM_MODE
                                  ORDER BY Start_Date_Time__c];
        Set<String> cntEmails = new Set<String>();
        for( Campaign tmp: cms) {
            String tmpEmail = tmp.EventCoordinator__r.Email;
            if( tmpEmail != null && tmpEmail.contains('.invalid') ) {
                tmpEmail = tmpEmail.replace('.invalid', '');
            }
            if(!String.isBlank(tmpEmail)){
            	cntEmails.add(tmpEmail);
            }
        } 
        
        Map<String, String> phoneByCnt = new Map<String, String>();
        for( Contact cnt: [SELECT Phone, Full_Name__c, Name, Email
                           FROM Contact
                           WHERE Email IN: cntEmails WITH SYSTEM_MODE]) {
            phoneByCnt.put(cnt.Email, cnt.Phone);
        }
       
        for( Campaign tmp: cms) {
            Integer eventYear = tmp.Start_Date_Time__c.year();
            if( eventsByYear.get(eventYear) == null ) {
                eventsByYear.put(eventYear, new List<EventInfo>());
            }

            EventInfo info = new EventInfo();
            info.workDay =  tmp.Start_Date_Time__c.format('EEEE');
            info.startDate = tmp.Start_Date_Time__c.format('MMMM') + ' ' + tmp.Start_Date_Time__c.day();
            info.event = tmp;

            String tmpEmail = tmp.EventCoordinator__r.Email;
            if( tmpEmail != null && tmpEmail.contains('.invalid') ) {
                tmpEmail = tmpEmail.replace('.invalid', '');
            }
            if( phoneByCnt.get(tmpEmail) != null ) {
                info.contactPhone = phoneByCnt.get(tmpEmail);
            }
            
            if(tmp.Start_Date_Time__c != null ) {
                info.startDateTime = tmp.Start_Date_Time__c.format();
            }
            if(tmp.End_Date_Time__c != null ) {
                info.endDateTime = tmp.End_Date_Time__c.format();
            }

            eventsByYear.get(eventYear).add(info);
        }
            
            events = JSON.serialize(eventsByYear);
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_EVENT_DOC_GENERATION_CTRL) );
        }
    }

    public class EventInfo {
        public String workDay {get;set;}
        public String startDate {get;set;}
        public Campaign event {get;set;}
        public String startDateTime {get;set;}
        public String endDateTime {get;set;}
        public String contactPhone {get;set;}
    }
}