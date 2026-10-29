@RestResource(urlMapping='/getContacts')
global with sharing class ContactsRetrieveRest {

    private static final String ERR_DO_GET = 'CONTACTS_RETRIEVE_REST_DO_GET_FAILED';
    private static final String ERR_GET_INTERACTION_BY_CONTACT = 'CONTACTS_RETRIEVE_REST_GET_INTERACTION_BY_CONTACT_FAILED';
    private static final String ERR_GET_CONTACT_WRAP = 'CONTACTS_RETRIEVE_REST_GET_CONTACT_WRAP_FAILED';

    @HttpGET
    global static List<ContactWrap> doGet() {
        List<ContactWrap> cws = new List<ContactWrap>();
        try{
            List<Contact> result = new List<Contact>();
            String contactIds = RestContext.request.params.get('contactIds');
            String shortBio = RestContext.request.params.get('shortBio');
            String listId = RestContext.request.params.get('listId');
            String showInteraction = RestContext.request.params.get('interaction');
            String showEvent = RestContext.request.params.get('event');
            String showRSVPMembers = RestContext.request.params.get('rsvp');
            String showImage = RestContext.request.params.get('image');
            String access = RestContext.request.params.get('access');
            String actionName = RestContext.request.params.get('actionName');
            String selectedSource = RestContext.request.params.get('selectedSource');
        
            Map<String, List<InteractionWrap>> interactionsByContact = new Map<String, List<InteractionWrap>>();
            Map<String, List<EventWrap>> eventsByContact = new Map<String, List<EventWrap>>();
            Map<Id, Set<String>> mapSourceNames = new Map<Id, Set<String>>();
            
            if(String.isNotEmpty(contactIds)) {
                List<String> tmpContactIds = (List<String>)JSON.deserialize(contactIds, List<String>.class);
                result = [
                    SELECT Id, Full_Name__c, Name, LastName, Title,
                        Restricted_Name__c, Restricted_Org_Name__c,
                        Restricted__c, Bio_Photo__c, Account.Name,
                        Account.Restricted__c, Confidential_Notes__c,
                        BoardBioNotes__c, Bio_Description__c,
                        ReducedImage__c
                    FROM Contact
                    WHERE Id = : tmpContactIds WITH SYSTEM_MODE
                    ORDER BY LastName, FirstName ASC
                ];
                
                for(CampaignMember cm : [
                    SELECT ContactId, Source__c
                    FROM CampaignMember
                    WHERE ContactId IN :tmpContactIds WITH SYSTEM_MODE
                ]) {
                    if(!mapSourceNames.containsKey(cm.ContactId)) {
                        mapSourceNames.put(cm.ContactId, new Set<String>());
                    }
                    if(String.isNotBlank(cm.Source__c)) {
                        mapSourceNames.get(cm.ContactId).add(cm.Source__c);
                    }
                }
                
                interactionsByContact = getInteractionByContact(tmpContactIds);
                eventsByContact = ContactsRetrieveRestHelper.getEventByContact(tmpContactIds);
                
            } else if(String.isNotEmpty(listId)) {
                Set<Id> contactMemberIds = new Set<Id> ();
                List<String> rsvpStatuses = new List<String> {'Yes', 'Yes - Virtually', 'Yes - In Person', 'Yes - Cocktails Only'};
                
                List<CampaignMember> members = [
                    SELECT ContactId,
                        Campaign.RecordType.DeveloperName,
                        RSVPStatus__c,
                        Source__c
                    FROM CampaignMember
                    WHERE CampaignId = :listId WITH SYSTEM_MODE
                ];
                
                for(CampaignMember mem: members) {
                    if (showRSVPMembers == 'yes' && mem.Campaign.RecordType.DeveloperName == 'Pre_Event') { 
                        if (mem.RSVPStatus__c != null && rsvpStatuses.contains(mem.RSVPStatus__c)) {
                            contactMemberIds.add(mem.ContactId);
                        }
                    } else {
                        contactMemberIds.add(mem.ContactId);
                    }
                    if(!mapSourceNames.containsKey(mem.ContactId)) {
                        mapSourceNames.put(mem.ContactId, new Set<String>());
                    }
                    if(String.isNotBlank(mem.Source__c)) {
                        mapSourceNames.get(mem.ContactId).add(mem.Source__c);
                    }
                }
                
                result = [
                    SELECT Id, Full_Name__c, Name, LastName, Title,
                        Restricted_Name__c, Restricted_Org_Name__c,
                        Restricted__c, Bio_Photo__c, Account.Name,
                        Account.Restricted__c, Confidential_Notes__c,
                        BoardBioNotes__c, Bio_Description__c,
                        ReducedImage__c
                    FROM Contact
                    WHERE Id IN :contactMemberIds WITH SYSTEM_MODE
                    ORDER BY LastName, FirstName ASC
                ];
                
                List<String> tmpContactIds = new List<String> ();
                
                for(Contact c: result) {
                    tmpContactIds.add(String.valueOf(c.Id));
                }
                
                interactionsByContact = getInteractionByContact(tmpContactIds);
                eventsByContact = ContactsRetrieveRestHelper.getEventByContact(tmpContactIds);
            }
            
            Set<String> selectedSources = new Set<String>();
            
            if(String.isNotBlank(selectedSource)) {
                selectedSources.addAll(selectedSource.split(';'));
            }
            
            if(result.size() > 0) {
                for(Contact cnt: result) {
                    String sourceName = '';
                    Boolean isMatched = false;
                    Set<String> contactSources = mapSourceNames.get(cnt.Id);
                    
                    if(contactSources != null && !selectedSources.isEmpty()) {
                        for(String source : contactSources) {
                            if(selectedSources.contains(source)) {
                                isMatched = true;
                                sourceName = source;
                                break;
                            }
                        }
                    }
                    
                    if(String.isNotBlank(selectedSource) && isMatched){
                        sourceName = 'Source: '+ sourceName;
                        cws.add(getContactWrap(cnt, interactionsByContact, eventsByContact, showInteraction, showEvent, access, showImage, shortBio, actionName, sourceName));
                    } else{
                        sourceName = String.isNotBlank(selectedSource) ? 'Remaining Contacts': '';
                        cws.add(getContactWrap(cnt, interactionsByContact, eventsByContact, showInteraction, showEvent, access, showImage, shortBio,actionName,sourceName));
                    }
                }
            }
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_DO_GET));
        }
        
        return cws;
    }
    
    //Get Contact interactions with specific contact Ids
    private static Map<String, List<InteractionWrap>> getInteractionByContact(List<String> contactIds) {
        Map<String, List<InteractionWrap>> tmp = new Map<String, List<InteractionWrap>>();
        try{
            for(Interaction__c interaction : [SELECT Contact__c, Interaction_Date__c, Name, 
                                              Background__c, LPLeadershipConfidentialBackground__c,
                                              CorrespondenceConfidentialDescription__c, Description__c
                                              FROM Interaction__c 
                                              WHERE Contact__c = :contactIds WITH SYSTEM_MODE
                                              ORDER BY Interaction_Date__c DESC]) {
                                                  
                                                  if (tmp.get(interaction.Contact__c) == null) {
                                                      tmp.put(interaction.Contact__c, new List<InteractionWrap>());
                                                  } else if (tmp.get(interaction.Contact__c) != null && tmp.get(interaction.Contact__c).size() == 3) {
                                                      continue;
                                                  }
                                                  
                                                  InteractionWrap iw = new InteractionWrap();
                                                  iw.interaction = interaction;
                                                  if (interaction.Interaction_Date__c != null){
                                                      iw.interactionDate = interaction.Interaction_Date__c.format();
                                                  }
                                                  
                                                  if (interaction.Background__c != null && Schema.sObjectType.Interaction__c.fields.Background__c.isAccessible()){
                                                      iw.interactionBackground = interaction.Background__c;
                                                  }
                                                  
                                                  if (interaction.LPLeadershipConfidentialBackground__c != null && Schema.sObjectType.Interaction__c.fields.LPLeadershipConfidentialBackground__c.isAccessible()){
                                                      iw.interactionBackground = interaction.LPLeadershipConfidentialBackground__c;
                                                  }
                                                  
                                                  if (interaction.CorrespondenceConfidentialDescription__c != null && Schema.sObjectType.Interaction__c.fields.CorrespondenceConfidentialDescription__c.isAccessible()){
                                                      iw.interactionBackground = interaction.CorrespondenceConfidentialDescription__c;
                                                  }
                                                  
                                                  if (interaction.Description__c != null && Schema.sObjectType.Interaction__c.fields.Description__c.isAccessible()){
                                                      iw.interactionBackground = interaction.Description__c;
                                                  }
                                                  
                                                  tmp.get(interaction.Contact__c).add(iw);                                                
                                              }
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_INTERACTION_BY_CONTACT) );
        }
        return tmp;
    }
    
    private static ContactWrap getContactWrap(Contact cnt, Map<String, List<InteractionWrap>> interactionsByContact, Map<String, List<EventWrap>> eventsByContact, String interaction, String event, String access, String showImage, String shortBio,String actionName,String sourceName) {
        ContactWrap cw = new ContactWrap();
        try{
            List<String> tmpHeader = new List<String>{cnt.Full_Name__c};
                if( String.isNotBlank(cnt.Title) ) {
                    tmpHeader.add(cnt.Title);
                }
            if( String.isNotBlank(cnt.Account.Name) && !'-'.equals(cnt.Account.Name)) {
                tmpHeader.add(cnt.Account.Name);
                cw.accountName = cnt.Account.Name;
            } else {
                cw.accountName = '';
            }
            cw.title = String.join(tmpHeader, ', ');
            cw.singleTitle = cnt.Title;
            cw.name = cnt.Name;
            if( cnt.ReducedImage__c != null && showImage != 'no') {
                //get Contact Photo from bio
                cw.img = cnt.ReducedImage__c;
            }
            Boolean hasAccess = Schema.SObjectType.Account.fields.Restricted__c.isAccessible();
            if (hasAccess){
                cw.name = cnt.Restricted__c ? cnt.Restricted_Name__c : cw.name;
                cw.accountName = cnt.Account?.Restricted__c ? cnt.Restricted_Org_Name__c :cw.accountName;
            }
            if ( cnt.Bio_Description__c != null && shortBio != 'true' && actionName =='bio' ) {
                cw.description = cnt.Bio_Description__c;
            } else if (cnt.BoardBioNotes__c != null && shortBio == 'true' && actionName =='shortBio'){
                cw.description = cnt.BoardBioNotes__c;
            }
            if (cnt.Confidential_Notes__c != null && access == 'true') {
                cw.confidentialNots = cnt.Confidential_Notes__c;
            }
            
            if (interactionsByContact.get(cnt.Id) != null && interaction == 'yes') {
                cw.interactions = interactionsByContact.get(cnt.Id);
            }
            
            if (eventsByContact.get(cnt.Id) != null && event == 'yes') {
                cw.events = eventsByContact.get(cnt.Id);
            }
            
            if (shortBio != null && shortBio == 'short') {
                cw.bioType = 'Short Bio';
            } else {
                cw.bioType = 'Bio';
            }

            if ( String.isNotBlank(sourceName)){
                cw.sourceName = sourceName;
            } else {
                cw.sourceName = '';
            }
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_CONTACT_WRAP) );
        }
        return cw;
    }
    
    global class ContactWrap {
        public String title {get;set;}
        public String name {get;set;}
        public String singleTitle {get;set;}
        public String img {get;set;}
        public String description {get;set;}
        public String confidentialNots {get;set;}
        public String accountName {get;set;}
        public List<InteractionWrap> interactions {get;set;}
        public List<EventWrap> events {get;set;}
        public String bioType {get;set;}
        public String sourceName {get;set;}
    }
    
    global class InteractionWrap{
        public Interaction__c interaction;
        public String interactionDate;
        public String interactionBackground = '';
    }
    
    global class EventWrap{
        public String eventSubject;
        public String eventDate;
        public String attendedStatus;
    }
}