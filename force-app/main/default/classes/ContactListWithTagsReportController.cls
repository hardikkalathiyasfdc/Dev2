public with sharing class ContactListWithTagsReportController {

    private static final String CONTACT_FIELDSET_NAME = 'Contact';
    private static final String EVENT_FIELDSET_NAME = 'EventLists';
    private static final String FUNDING_FIELDSET_NAME = 'FundingLists';
    private static final String LIST_MEMBER_OBJECT = 'CampaignMember';
    private static final String CONTACT_OBJECT = 'Contact'; 
    private static final Set<String> ALREADY_SELECTED_FIELDS = new Set<String>{
        'Primary_Spouse__c', 'Significant_Other__c', 'Preferred_First_Name__c', 
        'FirstName', 'LastName', 'Salutation', 'Significant_Other__r.FirstName', 
        'Significant_Other__r.LastName', 'Title', 'Account.Name', 'Priority_Email__c'};
    private static final String ERR_CLASS_FAILED = 'ContactListWithTagsReportController_CLASS_FAILED';
    
    public class ContactListTagWrapper {
        @AuraEnabled public List<OptionValues> contacts {get; set;}
        @AuraEnabled public List<OptionValues> lists {get; set;}
        @AuraEnabled public List<OptionValues> tags {get; set;}

        public ContactListTagWrapper() {
            this.contacts = new List<OptionValues>();
            this.lists = new List<OptionValues>();
            this.tags = new List<OptionValues>();
        }

        public ContactListTagWrapper(List<OptionValues> contacts, List<OptionValues> lists, List<OptionValues> tags) {
            this.contacts = contacts;
            this.lists = lists;
            this.tags = tags;
        }
    }

    public class OptionValues {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}

        public OptionValues(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class ContactListTagDataWrapper {
        @AuraEnabled public Contact contact {get; set;}
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String firstName {get; set;}
        @AuraEnabled public String firstPreferredName {get; set;}
        @AuraEnabled public String lastName {get; set;}
        @AuraEnabled public String title {get; set;}
        @AuraEnabled public String organization {get; set;}
        @AuraEnabled public String significantOther {get; set;}
        @AuraEnabled public String primaryEmail {get; set;}        
        @AuraEnabled public String listName {get; set;}
        @AuraEnabled public String tagName {get; set;}
        @AuraEnabled public String source {get; set;}
        @AuraEnabled public String preferredName {get; set;}
        @AuraEnabled public Map<String, String> listSource {get; set;}
        @AuraEnabled public String tagSource {get; set;}
        @AuraEnabled public String contactSource {get; set;}
        @AuraEnabled public String priorityEmail {get; set;}
        @AuraEnabled public Boolean restrictedContact {get; set;}
        @AuraEnabled public Boolean doNotContact {get; set;}
        @AuraEnabled public String significantOtherNamePreferred {get; set;}

        public ContactListTagDataWrapper() {}        

        public ContactListTagDataWrapper(String firstName, String firstPreferredName, String lastName, String title, String organization) {
            this.firstName = firstName;
            this.firstPreferredName = firstPreferredName;
            this.lastName = lastName;
            this.title = title;
            this.organization = organization;
            this.preferredName = this.firstName;
            if(String.isNotBlank(firstPreferredName)) preferredName = firstPreferredName;
            }
        
       public ContactListTagDataWrapper(String id, String firstName, String firstPreferredName, String lastName, 
                                        String title, String organization, String significantOtherNamePreferred, 
                                        String primaryEmail, String source, Map<String, String> listSource, String tagSource, 
                                        String contactSource, Boolean restrictedContact, Boolean doNotContact) {
            this.id = id;
            this.firstName = String.isBlank(firstName) ? '' : firstName;
            this.firstPreferredName = String.isBlank(firstPreferredName) ? '' : firstPreferredName;
            this.lastName = String.isBlank(lastName) ? '' : lastName;
            this.title = String.isBlank(title) ? '' : title;
            this.organization = String.isBlank(organization) ? '' : organization;
            this.significantOtherNamePreferred = String.isBlank(significantOtherNamePreferred) ? 
                                                 '' : significantOtherNamePreferred;
            this.priorityEmail = String.isBlank(primaryEmail) ? '' : primaryEmail;
            this.preferredName = this.firstName;
            this.source = String.isBlank(source) ? '' : source;
            if(String.isNotBlank(firstPreferredName)) preferredName = firstPreferredName;
            this.listSource = listSource;
            this.tagSource = tagSource;
            this.contactSource = contactSource;
            this.restrictedContact = restrictedContact;   
            this.doNotContact = doNotContact; 
        }

        public ContactListTagDataWrapper(String id, String firstName, String firstPreferredName, 
                                         String lastName, String title, String organization, 
                                         String significantOtherNamePreferred, String primaryEmail) {
                                            
            this(firstName, firstPreferredName, lastName, title, organization, significantOtherNamePreferred, primaryEmail, '');
        }

        public ContactListTagDataWrapper(String id, String firstName, String firstPreferredName, 
                                         String lastName, String title, String organization, 
                                         String significantOtherNamePreferred, String primaryEmail, String source) {

            this(id, firstName, firstPreferredName, lastName, title, organization, significantOtherNamePreferred, 
                 primaryEmail, source, new Map<String, String>(), '', '');
        }

        public ContactListTagDataWrapper(String id, String firstName, String firstPreferredName, String lastName, String title, 
                                         String organization, String significantOtherNamePreferred, String primaryEmail, 
            String source, Map<String, String> listSource, String tagSource, String contactSource) {
             
            this(id, firstName, firstPreferredName, lastName, title, organization, significantOtherNamePreferred, 
                 primaryEmail, source, listSource, tagSource, contactSource, false, false);
        }
    }

        @AuraEnabled
        public static ContactListTagWrapper getAllContactListTags(String listIdsCSV, String tagIdsCSV, String contactIdsCSV) {    
            List<OptionValues> lists = new List<OptionValues>();
            List<OptionValues> tags = new List<OptionValues>();
            List<OptionValues> contacts = new List<OptionValues>();

            List<String> listIds = (listIdsCSV != null && listIdsCSV != '') ? listIdsCSV.split(',') : new List<String>();
            List<String> tagIds = (tagIdsCSV != null && tagIdsCSV != '') ? tagIdsCSV.split(',') : new List<String>();
            List<String> contactIds = (contactIdsCSV != null && contactIdsCSV != '') ? contactIdsCSV.split(',') : new List<String>();

            if(!listIds.isEmpty()) {
                for(Campaign campaign : [SELECT Id, Name FROM Campaign WHERE Id IN :listIds ORDER BY Name]) {
                    lists.add(new OptionValues(campaign.Name, campaign.Id));
                }
            }

            if(!tagIds.isEmpty()) {
                for(Tag__c tag : [SELECT Id, Name FROM Tag__c WHERE Id IN :tagIds ORDER BY Name]) {
                    tags.add(new OptionValues(tag.Name, tag.Id));
                }
            }

            if(!contactIds.isEmpty()) {
                for(Contact contact : [SELECT Id, FirstName, LastName FROM Contact WHERE Id IN :contactIds ORDER BY LastName]) {
                    contacts.add(new OptionValues(contact.FirstName + ' ' + contact.LastName, contact.Id));
                }
            }

            ContactListTagWrapper contactListTagWrapper = new ContactListTagWrapper(contacts, lists, tags);
            return contactListTagWrapper;
        }


    @AuraEnabled
    public static List<ContactListTagDataWrapper> getContactListTagData(List<String> contactIds, List<String> listIds, List<String> tagIds) {
        Map<Id, ContactListTagDataWrapper> dataWrapperMap = new Map<Id, ContactListTagDataWrapper>();
    	try {
            Set<Id> allContactIds = new Set<Id>();
            Map<Id, Map<String, String>> listByContactMap = new Map<Id, Map<String, String>>(); 
            if (!listIds.isEmpty()) {
                List<CampaignMember> campaignMemberList = [
                    SELECT Id, Name, CampaignId, ContactId, Campaign.Name, Contact.Name, Contact.Priority_Email__c, 
                           Contact.Email, Contact.FirstName, Contact.Preferred_First_Name__c, Contact.LastName, 
                           Contact.Title, Contact.Significant_Other_Name_Preferred__c, Contact.Significant_Other__r.Name, 
                           Contact.Organization_Name_formula__c, Contact.DoNotCall, Contact.Restricted__c
                    FROM CampaignMember 
                    WHERE CampaignId IN :listIds];
                for(CampaignMember cm : campaignMemberList) {
                    allContactIds.add(cm.ContactId);
                    Map<String, String> tempMap = listByContactMap.containsKey(cm.ContactId) ? 
                                                  listByContactMap.get(cm.ContactId) : new Map<String, String>();
                    tempMap.put(cm.CampaignId, cm.Campaign.Name);
                    listByContactMap.put(cm.ContactId, tempMap);
                }
                for(CampaignMember cm : campaignMemberList) {
                    if(!dataWrapperMap.containsKey(cm.ContactId)) {
                        dataWrapperMap.put(cm.ContactId, 
                                           new ContactListTagDataWrapper(cm.ContactId, cm.Contact.FirstName, cm.Contact.Preferred_First_Name__c, 
                                                                         cm.Contact.LastName, cm.Contact.Title, cm.Contact.Organization_Name_formula__c,
                                                                         cm.Contact.Significant_Other_Name_Preferred__c, cm.Contact.Priority_Email__c, 
                                                                         '', listByContactMap.get(cm.ContactId), '', '',
                                                                         cm.Contact.Restricted__c, cm.Contact.DoNotCall));
                    } else {
                        dataWrapperMap.get(cm.ContactId).listSource.put(cm.CampaignId, cm.Campaign.Name);
                    }
                }
            }
            if(contactIds != null && !contactIds.isEmpty()) {
                List<Contact> contactList = [
                    SELECT Id, Name, Priority_Email__c, Email, FirstName, Preferred_First_Name__c, LastName, Title, 
                           Significant_Other_Name_Preferred__c, Significant_Other__r.Name, Organization_Name_formula__c, 
                           DoNotCall, Restricted__c 
                    FROM Contact 
                    WHERE Id IN :contactIds];
                Map<Id, String> mapContactIdWithNames = new Map<Id, String>();
                for(Contact contactRecord : contactList) {
                    mapContactIdWithNames.put(contactRecord.Id, contactRecord.Name);
                }
                for(Contact contactRecord : contactList) {
                    allContactIds.add(contactRecord.Id);
                    String contactName = mapContactIdWithNames.containsKey(contactRecord.Id) ? 
                                         mapContactIdWithNames.get(contactRecord.Id) : '';
                    if(!dataWrapperMap.containsKey(contactRecord.Id)) {
                        dataWrapperMap.put(contactRecord.Id, 
                                           new ContactListTagDataWrapper(contactRecord.Id, contactRecord.FirstName, contactRecord.Preferred_First_Name__c, 
                                                                         contactRecord.LastName, contactRecord.Title, contactRecord.Organization_Name_formula__c,
                                                                         contactRecord.Significant_Other_Name_Preferred__c, contactRecord.Priority_Email__c, 
                                                                         '', new Map<String, String>(), '', contactName, contactRecord.Restricted__c, contactRecord.DoNotCall));
                }
            }
            }
            if (!tagIds.isEmpty()) {
                Map<Id, String> tagsourceByContact = new Map<Id, String>();
                List<Tag_Junction__c> tjList = [
                    SELECT Id, Tag__r.Name, Contact__c, Contact__r.Name, Contact__r.Priority_Email__c, 
                           Contact__r.Email, Contact__r.FirstName, Contact__r.Preferred_First_Name__c, Contact__r.LastName, 
                           Contact__r.Title, Contact__r.Significant_Other_Name_Preferred__c, Contact__r.Significant_Other__r.Name, 
                           Contact__r.Organization_Name_formula__c, Contact__r.DoNotCall, Contact__r.Restricted__c 
                    FROM Tag_Junction__c
                    WHERE Tag__c IN :tagIds AND
                          Contact__c != null];
                for(Tag_Junction__c tagJunction : tjList) {
                    allContactIds.add(tagJunction.Contact__c);
                    String tempTagSource = tagsourceByContact.containsKey(tagJunction.Contact__c) ? 
                                           tagsourceByContact.get(tagJunction.Contact__c) : '';
                    tempTagSource += tagJunction.Tag__r.Name + '; ';
                    tagsourceByContact.put(tagJunction.Contact__c, tempTagSource);
                }
                for(Tag_Junction__c tagJunction : tjList) {
                    if(!dataWrapperMap.containsKey(tagJunction.Contact__c)) {
                        dataWrapperMap.put(tagJunction.Contact__c, 
                            new ContactListTagDataWrapper(tagJunction.Contact__c, tagJunction.Contact__r.FirstName, tagJunction.Contact__r.Preferred_First_Name__c, 
                                                          tagJunction.Contact__r.LastName, tagJunction.Contact__r.Title, tagJunction.Contact__r.Organization_Name_formula__c,
                                                          tagJunction.Contact__r.Significant_Other_Name_Preferred__c, tagJunction.Contact__r.Priority_Email__c, 
                                                          '', new Map<String, String>(), tagsourceByContact.get(tagJunction.Contact__c), '',
                                                          tagJunction.Contact__r.Restricted__c, tagJunction.Contact__r.DoNotCall));
            
                    } else {
                        dataWrapperMap.get(tagJunction.Contact__c).tagSource = tagsourceByContact.get(tagJunction.Contact__c);
            }
                    }
                }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return dataWrapperMap.values();
    }

    @AuraEnabled
    public static List<ContactListTagDataWrapper> getUpdatedData(String dataWrapperJSON, List<String> orderedList, Boolean isRemoveDuplicates) {
        List<ContactListTagDataWrapper> updatedDataWrapper = 
            (List<ContactListTagDataWrapper>)JSON.deserialize(dataWrapperJSON, List<ContactListTagDataWrapper>.class);
        try {
            if (isRemoveDuplicates) {
                Map<String, Integer> orderedListMap = new Map<String, Integer>();
                Integer i = 1;
                for(String listId : orderedList) orderedListMap.put(listId, i++);
                for (ContactListTagDataWrapper tempWrapper : updatedDataWrapper) {
                    Map<String, String> listSource = tempWrapper.listSource;
                    if (listSource != null && !listSource.isEmpty()) {
                        String highrankedListId = new List<String>(listSource.keySet()).get(0);
                        for (String key : listSource.keySet()) {
                            highrankedListId = orderedListMap.get(key) < orderedListMap.get(highrankedListId) ? 
                                               key : highrankedListId;
                        }
                        tempWrapper.source = 'List: ' + listSource.get(highrankedListId) + '\n';
                    }
                    if(!String.isBlank(tempWrapper.tagSource) && !tempWrapper.source.contains(tempWrapper.tagSource.remove('\n'))) {
                        tempWrapper.source += String.isBlank(tempWrapper.tagSource) ? '' : 'Tag(s): ' + tempWrapper.tagSource;
                    }
                    tempWrapper.source += String.isBlank(tempWrapper.contactSource) ? '' : 'Contact: ' + tempWrapper.contactSource;
                }
            } else {
                for (ContactListTagDataWrapper tempWrapper : updatedDataWrapper) {
                    Map<String, String> listSource = tempWrapper.listSource;
                    tempWrapper.source = '';
                    if (listSource != null && !listSource.isEmpty()) {
                        tempWrapper.source += 'List(s): ';
                        List<String> listSourceList = new List<String>(listSource.values());
                        listSourceList.sort();
                        tempWrapper.source += String.join(listSourceList, '; ');
                        }
                    tempWrapper.source += String.isBlank(tempWrapper.tagSource) ? '' : '\n Tag(s): ' + tempWrapper.tagSource;
                    tempWrapper.source += String.isBlank(tempWrapper.contactSource) ? '' : '\n Contact: ' + tempWrapper.contactSource;
                    }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return updatedDataWrapper;
    }

    @AuraEnabled
    public static ExportUtility.AvailableOptionWrapper getAvailableColumns() {        
        List<ExportUtility.OptionWrapper> contactFields = ExportUtility.getFieldsByRecordType(CONTACT_OBJECT, 'Export_List');
        Set<ExportUtility.OptionWrapper> listMemberFieldsSet = new Set<ExportUtility.OptionWrapper>();
        listMemberFieldsSet.addAll(ExportUtility.getFieldsByRecordType(LIST_MEMBER_OBJECT, CONTACT_FIELDSET_NAME));
        listMemberFieldsSet.addAll(ExportUtility.getFieldsByRecordType(LIST_MEMBER_OBJECT, EVENT_FIELDSET_NAME));
        List<ExportUtility.OptionWrapper> listMemberFields = new List<ExportUtility.OptionWrapper>(listMemberFieldsSet);
        ExportUtility.AvailableOptionWrapper availableOptions = new ExportUtility.AvailableOptionWrapper(contactFields, listMemberFields);
        return availableOptions;
    }

    @AuraEnabled
    public static List<ExportContactsController.ExportDataWrapper> getMemberList(List<String> campaignIds, List<String> additionalContactIds, List<String> tagIds, List<String> contactIds,
                                                                                 String typeOfExport, List<String> fieldAPINames, List<String> listMemberFieldAPINames, 
                                                                                 List<String> contactFieldAPINames, Boolean isRemoveDuplicates) {
        List<ExportContactsController.ExportDataWrapper> exportDataWrappers = new List<ExportContactsController.ExportDataWrapper>();
        try {
            Set<String> filteredFieldAPINames = new Set<String>(fieldAPINames);
             Map<Id, CampaignMember> contactListMember = new Map<Id, CampaignMember> ();
             Map<Id, String> listByContact = new Map<Id, String>();       
             Map<Id, List<String>> mapContactIdWithSourceList = new Map<Id, List<String>>(); 
             Map<Id, List<String>> mapContactIdWithTags = new Map<Id, List<String>>(); 
            //Fetch all Campaign Members from the campaign IDs provided
            String soql = 'SELECT Id, Name, Significant_Other_Name_Preferred__c, ContactId, Via__r.Name, Campaign.Name, Campaign.Id, Source__c,Contact.Restricted__c';
            for(String apiName : filteredFieldAPINames) {
                if(!ExportContactsController.NON_API_NAME_FIELDS.contains(apiName) && listMemberFieldAPINames.contains(apiName) && 
                   (!soql.contains(apiName) || soql.contains('.' + apiName) || apiName == 'Type__c')) {
    
                        soql += ', ' + apiName;
                    }            
                }
            soql += ' FROM CampaignMember ' + 
                    ' WHERE CampaignId IN :campaignIds AND Contact.DoNotCall = false AND ContactId IN :contactIds' +
                    ' ORDER BY Contact.LASTNAME, Contact.FIRSTNAME ASC';
            Set<Id> tempContactIds = new Set<Id>();
            List<CampaignMember> listMembers = (List<CampaignMember>)Database.query(soql);
               Map<String, Integer> orderedListMap = new Map<String, Integer>();
                Integer i = 1;
            for(String listId : campaignIds) orderedListMap.put(listId, i++);
             Integer highRank = campaignIds.size();
            String sourceName = '';
             for (CampaignMember listMember : listMembers) {
                if(campaignIds.Size() > 0 && listMember.CampaignId == campaignIds[0] && 
                   sourceName == '' && String.IsNotBlank(listMember.Source__c)) {
    
                     sourceName = listMember.Source__c;
                 } 
                Id contactId = listMember.ContactId;
                tempContactIds.add(contactId);
                List<String> lstSource = mapContactIdWithSourceList.containsKey(contactId) ? 
                                         mapContactIdWithSourceList.get(contactId) : new List<String>();
               if(isRemoveDuplicates ){  
                    if((orderedListMap.containsKey(listMember.Campaign.Id) && orderedListMap.get(listMember.Campaign.Id) <= highRank) || lstSource.isEmpty()) {
                             highRank = orderedListMap.get(listMember.Campaign.Id);
                             lstSource = new List<String>{listMember.Campaign.Name};
                        contactListMember.put(contactId, listMember);
                        }
                    listMember.Source__c = contactListMember.containsKey(contactId) ? 
                                           contactListMember.get(contactId).Source__c : listMember.Source__c; 
                } else {
                    if((orderedListMap.containsKey(listMember.Campaign.Id) && orderedListMap.get(listMember.Campaign.Id) <= highRank) || lstSource.isEmpty()) {
                            highRank = orderedListMap.get(listMember.Campaign.Id);
                        contactListMember.put(contactId, listMember);
                    }
                    listMember.Source__c = contactListMember.containsKey(contactId) ? 
                                           contactListMember.get(contactId).Source__c : listMember.Source__c ; 
                    lstSource.add(listMember.Campaign.Name);
                 }
                mapContactIdWithSourceList.put(contactId, lstSource);
                contactListMember.put(contactId, listMember);
            }
            for(String contactId: mapContactIdWithSourceList.keySet()) {
                List<String> lstSource = mapContactIdWithSourceList.get(contactId);
                String firstListName = !lstSource.isEmpty() ? 'List: ' +lstSource[0] : ''; 
                lstSource.sort();
                String sourceResult = 'List(s): ' + String.join(lstSource,'; ');    
                if(isRemoveDuplicates && !lstSource.isEmpty()){
                    sourceResult = firstListName ;
                }
                listByContact.put(contactId, sourceResult);
            }
            //Fetch all contacts related to the Tags selected
             if(tagIds != null && !tagIds.isEmpty()) {
                String tagJunctionSoql = 'SELECT Id, Tag__c, Tag__r.Name, Tag__r.Owner.Name, Tag__r.Private__c, Contact__c ';
                tagJunctionSoql += 'FROM Tag_Junction__c ' + 
                                   'WHERE Tag__c IN :tagIds AND Contact__c IN :contactIds';
                for(Tag_Junction__c tagJunction : (List<Tag_Junction__c>)Database.query(tagJunctionSoql)) {
                     tempContactIds.add(tagJunction.Contact__c);
                    List<String> tagList = mapContactIdWithTags.containsKey(tagJunction.Contact__c) ? 
                                           mapContactIdWithTags.get(tagJunction.Contact__c) : new List<String>();
                         tagList.add(tagJunction.Tag__r.Name);
                     mapContactIdWithTags.put(tagJunction.Contact__c,tagList);
                 }
             }
            for(String contactId: mapContactIdWithTags.keySet()) {
                List<String> tagList = mapContactIdWithTags.get(contactId);
                tagList.sort();
                String tagResult = 'Tags(s): ' + String.join(tagList,'; ');
                String listNames = listByContact.containsKey(contactId) ? listByContact.get(contactId) : '';
                listByContact.put(contactId, String.isBlank(listNames) ? tagResult : listNames + '; ' +  tagResult);
            }
            if(additionalContactIds != null && !additionalContactIds.isEmpty()) {
                Map<Id, Contact> mapContactIdWithNames = new Map<Id, Contact>();
                List<Contact> additionalContactList = [
                    SELECT Id, Name 
                    FROM Contact 
                    WHERE Id IN :additionalContactIds AND 
                          Id IN :contactIds];
                for(Contact contact : additionalContactList) {
                    mapContactIdWithNames.put(contact.Id, contact);
                    String contactName = 'Contact: ' + mapContactIdWithNames.get(contact.Id).Name; 
                    String sourceResult = listByContact.containsKey(contact.Id) ? 
                                          listByContact.get(contact.Id) : '';
                    listByContact.put(contact.Id, String.isBlank(sourceResult) ? 
                                                  contactName : 
                                                  sourceResult + '; ' + contactName);
                    tempContactIds.add(contact.Id);
                }
            }
            String contactSoql = 'SELECT Id, Name, Contact_Alert_Reason__c, Primary_Spouse__c, Phone, Email, ' + 
                                        'Significant_Other__r.Primary_Spouse__c, Preferred_First_Name__c, Preferred_Last_Name__c, Last_Preferred_Last_Name__c, ' + 
                                        'FirstName, LastName, Significant_Other__c, Significant_Other__r.Salutation, ' + 
                                        'Significant_Other__r.Annual_Report_Salutation__c, Salutation, ' + 
                                        'Significant_Other_Name_Preferred__c, Significant_Other__r.Name, ' + 
                                        'Significant_Other__r.FirstName, Significant_Other__r.LastName, Title, ' + 
                                    'Account.Name, Priority_Email__c, Significant_Name__c, ' +
                                    'Account.Restricted__c,Contact.Restricted__c,  RestrictedSalutation__c, RestrictedSuffix__c, ' +
                                    'RestrictedFirstName__c, RestrictedMiddleName__c, RestrictedLastName__c, ' +
                                    'Restricted_Name__c, Restricted_Org_Name__c ';
            for(String apiName : fieldAPINames) {
                if(contactFieldAPINames.contains(apiName) && !ALREADY_SELECTED_FIELDS.contains(apiName) && 
                   !ExportContactsController.NON_API_NAME_FIELDS.contains(apiName) && 
                   (!contactSoql.contains(apiName) || contactSoql.contains('.' + apiName)) && apiName != 'Restricted__c') {
                        system.debug('Step 1 - '+apiName);
                        if(ExportContactsController.BUSINESS_EMAIL.equalsIgnoreCase(apiName)) {
                            apiName = 'Email';
                        }
                        if(ExportContactsController.BUSINESS_PHONE.equalsIgnoreCase(apiName)) {
                            apiName = 'Phone';
                        }
                        contactSoql += ', ' + apiName;
                    }
                }            
            contactSoql += ', (SELECT Id, Tag__r.Name FROM Tags__r ORDER BY Tag__r.Name asc) ' + 
                           'FROM Contact ' + 
                           'WHERE Id IN :tempContactIds AND DoNotCall = false ' + 
                           'ORDER BY LASTNAME, FIRSTName ASC';
            Set<Id> significantOtherIds = new Set<Id>();
            Set<Id> nonSignificantOtherIds = new Set<Id>();
            Map<Id, String> nonSignificantOtherNames = new Map<Id, String>();
            List<Contact> contacts = (List<Contact>)Database.query(contactSoql);
            if(!tempContactIds.isEmpty()) {
                Map<Id, ExportContactsController.AssistantWrapper> assistanceMap = new Map<Id, ExportContactsController.AssistantWrapper>();
                    assistanceMap = ExportContactsController.getAssistanceData(tempContactIds,significantOtherIds);
                for(Contact contact: contacts) {
                    if(contact.Significant_Other__c != null) {
                        if((contact.Primary_Spouse__c || !significantOtherIds.contains(contact.Significant_Other__c)) && 
                           !contact.Significant_Other__r.Primary_Spouse__c && !significantOtherIds.contains(contact.Id)) {
    
                            significantOtherIds.add(contact.Significant_Other__c);
                        } else if(!significantOtherIds.contains(contact.Id)) {
                            nonSignificantOtherIds.add(contact.Significant_Other__c);
                            nonSignificantOtherNames.put(contact.Significant_Other__c, contact.Significant_Other__r.Name);
                            }
                        }
                    }
               for(Contact contact: contacts) {
                    ExportContactsController.ExportDataWrapper exportDataWrapper = new ExportContactsController.ExportDataWrapper(
                        contactListMember.containsKey(contact.Id) ? contactListMember.get(contact.Id) : null, 
                        contact, 
                        assistanceMap.containsKey(contact.Id) ? assistanceMap.get(contact.Id) : null
                    );
                    exportDataWrapper.tagSourceResult = listByContact.containskey(contact.Id) ? listByContact.get(contact.Id) : '';
                    if(typeOfExport == 'Executive' ){
                            if(!significantOtherIds.contains(contact.Id)) {
                                if (nonSignificantOtherIds.contains(contact.Id)) {
                                    String tempName = contact.Name;
                                    String tempSigName = contact.Significant_Other__r?.Name;
                                    if(tempName.compareTo(tempSigName) < 0 && !tempContactIds.contains(contact.Significant_Other__c)) {
                                        exportDataWrapper.significantOther ='';
                                        }
                                } else if(!tempContactIds.contains(contact.Significant_Other__c)) {
                                                exportDataWrapper.significantOther ='';
                                                exportDataWrapper.SignificantOtherPreferredFirstName='';
                                }
                                exportDataWrappers.add(exportDataWrapper);
                            }
                        }
                        else{
                            exportDataWrappers.add(exportDataWrapper);
                        }                          
                    }                
                }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return exportDataWrappers;
    }
}