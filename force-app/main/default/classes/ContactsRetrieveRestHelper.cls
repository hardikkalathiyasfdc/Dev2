public without sharing class ContactsRetrieveRestHelper {
    private static final String ERR_GET_EVENT_BY_CONTACT = 'CONTACT_RETRIEVE_REST_HELPER_GET_EVENT_BY_CONTACT_FAILED';
    private static final String ERR_GET_USER_RECORD_ACCESS = 'CONTACT_RETRIEVE_REST_HELPER_GET_USER_RECORD_ACCESS_FAILED';

	public static Map<String, List<ContactsRetrieveRest.EventWrap>> getEventByContact(List<String> contactIds) {
       
        Map<String, List<ContactsRetrieveRest.EventWrap>> tmp = new Map<String, List<ContactsRetrieveRest.EventWrap>>();
        try{
        List<CampaignMember> allMembers = [SELECT Id, Campaign.Name, Campaign.Start_Date_Time__c,Campaign.Event_Start_Date_Time__c,
                                    		AttendedStatus__c, RSVPStatus__c, ContactId, Campaign.Private_Campaign__c
                                            FROM CampaignMember 
                                            WHERE ContactId = : contactIds AND
                                 			Campaign.RecordType.DeveloperName = 'Pre_Event'
                                            ORDER BY Campaign.Start_Date_Time__c DESC NULLS LAST];
        
        Set<Id> privateCampaignMemberIds = new Set<Id>();
        Set<Id> sharedPrivateCampaignMemberIds = new Set<Id>();
        
        for (CampaignMember cm : allMembers) {
            if (cm.Campaign.Private_Campaign__c) {
                privateCampaignMemberIds.add(cm.CampaignId);                
            }
        }
        List<UserRecordAccess> userRecordAccessList = getUserRecordAccess(privateCampaignMemberIds,UserInfo.getUserId());          
        
        for (UserRecordAccess userRecordAccess : userRecordAccessList) {
            sharedPrivateCampaignMemberIds.add(userRecordAccess.Id);           
        }
        
		for(CampaignMember cm: allMembers) {
            if(cm.AttendedStatus__c == null && cm.RSVPStatus__c == null) {
                continue;
            }
            DateTime eventStartDate = DateTime.parse(cm.Campaign.Event_Start_Date_Time__c);
            if( 
               eventStartDate < System.today() && 
               cm.AttendedStatus__c != 'Yes - Virtually' && cm.AttendedStatus__c != 'Yes - Cocktails Only' &&  cm.AttendedStatus__c != 'Yes - In Person' ) {
                continue;
            }
            
            if(eventStartDate >= System.today() && 
               cm.RSVPStatus__c != 'Yes - In Person' && cm.RSVPStatus__c != 'Yes - Cocktails Only' && cm.RSVPStatus__c != 'Yes - Virtually' && cm.RSVPStatus__c != 'Yes') {
                continue;
            }
            
            if(cm.Campaign.Private_Campaign__c && !sharedPrivateCampaignMemberIds.contains(cm.CampaignId)) {
                continue;
            }
            
            if(tmp.get(cm.ContactId) != null && tmp.get(cm.ContactId).size() == 3) {
                continue;
            }
            
            List<ContactsRetrieveRest.EventWrap> events = new List<ContactsRetrieveRest.EventWrap>();
            
            if(tmp.get(cm.ContactId) != null) {
                events = tmp.get(cm.ContactId);
            }
            
            ContactsRetrieveRest.EventWrap ew = new ContactsRetrieveRest.EventWrap();
            ew.eventSubject = cm.Campaign.Name;
            if(eventStartDate != null){
                ew.eventDate = eventStartDate.date().format();
            }
            
			if(cm.AttendedStatus__c != null) {
				ew.attendedStatus = cm.AttendedStatus__c;
            } else if(cm.RSVPStatus__c != null) {
                ew.attendedStatus = cm.RSVPStatus__c;
            }

            events.add(ew);
            
            tmp.put(cm.ContactId, events);
        }
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_EVENT_BY_CONTACT) );
        }
        return tmp;
    }

     public static List<UserRecordAccess> getUserRecordAccess(Set<Id> recordIds, Id userId) {
         // List to store results
        List<UserRecordAccess> allResults = new List<UserRecordAccess>();
        try{
        
        // Convert Set to List for easier processing
        List<Id> recordIdList = new List<Id>(recordIds);
        Integer batchSize = 200;
        
        // Initialize batch start index
        Integer startIndex = 0;

        // Loop through the list in batches of 200
        while (startIndex < recordIdList.size()) {
            // Create a batch of record IDs
            List<Id> batchIds = new List<Id>();
            for (Integer i = startIndex; i < Math.min(startIndex + batchSize, recordIdList.size()); i++) {
                batchIds.add(recordIdList[i]);
            }
            
            // Query UserRecordAccess for the current batch
            List<UserRecordAccess> batchResults = [
                Select RecordId from UserRecordAccess
                WHERE UserId = :userId AND RecordId IN :batchIds AND HasReadAccess = true
            ];
            
            // Add batch results to the final list
            allResults.addAll(batchResults);
            
            // Update the start index for the next batch
            startIndex += batchSize;
        }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_USER_RECORD_ACCESS) );
        }
         return allResults;
     }
}