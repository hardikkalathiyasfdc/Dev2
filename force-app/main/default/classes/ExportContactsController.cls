public with sharing class ExportContactsController {
    public List<Tag__c> selectedTags;
    public String tagIdsString {get; set;}
    public static List<ContactWrapper> allContacts{get; set;}
    private static final String CONTACT_RECORDTYPE = 'State_Campaign';
    private static final String CONTACT_LEADERSHIP_RECORDTYPE = 'BP_Campaign';
    private static final String FUNDRAISING_RECORDTYPE = 'Fundraising';
    private static final String EVENTS_RECORDTYPE = 'Pre_Event';
    private static final String GUESTLIST_RECORDTYPE = 'GuestList';
    private static final String CONTACT_FIELDSET_NAME = 'Contact';
    private static final String EVENT_FIELDSET_NAME = 'EventLists';
    private static final String FUNDING_FIELDSET_NAME = 'FundingLists';
    private static final String LIST_MEMBER_OBJECT = 'CampaignMember';
    private static final String CONTACT_OBJECT = 'Contact';
    private static final String BP_LP_CONTACT_FIELD_NAME = 'Via__c';
    private static final String CONTACT_BUSINESS_EMAIL_LABEL = 'Business Email';
    public static final String BUSINESS_EMAIL = 'BusinessEmail';
    private static final String CONTACT_BUSINESS_PHONE_LABEL = 'Business Phone';
    public static final String BUSINESS_PHONE = 'BusinessPhone';
    public static final String ASSISTANT_NAME = 'Staff Name';
    private static final String ASSISTANT_PERSONNEL_EMAIL_LABEL = 'Staff Personal Email';
    private static final String ASSISTANT_BUSINESS_EMAIL_LABEL = 'Staff Business Email';
    private static final String ASSISTANT_BUSINESS_PHONE_LABEL = 'Staff Business Phone';
    private static final String ASSISTANT_MOBILE_PHONE_LABEL = 'Staff Mobile Phone';
    private static final String STAFF_NAME = 'StaffName';
    private static final String ASSISTANT_PERSONNEL_EMAIL = 'AssistantPersonalEmail';
    private static final String ASSISTANT_PERSONNEL_EMAIL1 = 'Assistant_Business_Email__c';
    private static final String ASSISTANT_BUSINESS_EMAIL = 'AssistantBusinessEmail';
    private static final String ASSISTANT_BUSINESS_PHONE = 'AssistantBusinessPhone';
    private static final String ASSISTANT_MOBILE_PHONE = 'AssistantMobilePhone';
    private static final String STAFF_ROLE = 'StaffRole';
    private static final String STAFF_ROLE_LABEL = 'Staff Role';
    private static final String FIRST_OR_PREFERRED_FIRSTNAME = 'firstOrPreferredFirstName';
    private static final String LAST_OR_PREFERRED_LASTNAME = 'lastOrPreferredLastName';
    private static final String ORGANIZATION = 'organization';
    private static final Set<String> ALREADY_SELECTED_FIELDS = new Set<String>{'Primary_Spouse__c', 'Significant_Other__c', 'Preferred_First_Name__c', 'FirstName', 'LastName', 'Salutation', 'Significant_Other__r.FirstName', 'Significant_Other__r.LastName', 'Title', 'Account.Name', 'Priority_Email__c', 'RestrictedLastName__c', 'Restricted__c', 'Restricted_Name__c', 'Restricted_Org_Name__c'};
    public static final Set<String> NON_API_NAME_FIELDS = new Set<String>{STAFF_NAME, ASSISTANT_PERSONNEL_EMAIL, ASSISTANT_BUSINESS_EMAIL, ASSISTANT_BUSINESS_PHONE, ASSISTANT_MOBILE_PHONE, STAFF_ROLE, FIRST_OR_PREFERRED_FIRSTNAME, ORGANIZATION};
            
    private static final String ERR_GET_CONTACTS = 'EXPORT_CONTACT_CONTROLLER_GET_CONTACTS_FAILED';
    private static final String ERR_PROCESS_DND_CONTACTS = 'EXPORT_CONTACT_CONTROLLER_PROCESS_DND_CONTACTS_FAILED';
    private static final String ERR_PROCESS_CONTACTS = 'EXPORT_CONTACT_CONTROLLER_PROCESS_CONTACTS_FAILED';
    private static final String ERR_PROCESS_TAGIDS = 'EXPORT_CONTACT_CONTROLLER_PROCESS_TAGIDS_FAILED';    
    private static final String ERR_GET_AVAILABLE_COLUMNS = 'EXPORT_CONTACT_CONTROLLER_GET_AVAILABLE_COLUMNS_FAILED';   
    private static final String ERR_GET_MEMBER_LIST = 'EXPORT_CONTACT_CONTROLLER_GET_MEMBER_LIST_FAILED'; 
    private static final String ERR_GET_FIELDS_BY_RECORDTYPE = 'EXPORT_CONTACT_CONTROLLER_GET_FIELDS_BY_RECORDTYPE_FAILED';   
    private static final String ERR_GET_ASSISTANCE_DATA = 'EXPORT_CONTACT_CONTROLLER_GET_ASSISTANCE_DATA_FAILED'; 
    @TestVisible
    private static Boolean forceException = false;
    
    public ExportContactsController(ApexPages.StandardSetController cntlr){
        selectedTags = cntlr.getSelected();
        tagIdsString = '';
        Set<Id> tagIds = new Set<Id>();  
        for(Tag__c tag : selectedTags){
            tagIdsString += tag.Id + ',';
            tagIds.add(tag.Id);
        } 
        if(String.IsNotBlank(tagIdsString))
            tagIdsString = tagIdsString.removeEnd(',');
    } 
    
    @AuraEnabled
    public static List<ContactWrapper> getContacts(String tagIds,String typeOfExport){
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Set<Id> tagIdsSet = new Set<Id> ();
            for (String tag: tagIds.split(',')) {
                tagIdsSet.add(tag);
            }
            allContacts = processTagIds(tagIdsSet,typeOfExport);
            return allContacts;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_CONTACTS)); 
            return null;
        }  
    }
    
    @AuraEnabled
    public static List<ContactWrapper> getDNCContacts(Id recordId){
        allContacts = processEmailExportList(recordId, 'DNC');
        return allContacts;
    }

    @AuraEnabled
    public static List<ContactWrapper> getMissingEmailContacts(Id recordId) {
        allContacts = processEmailExportList(recordId, 'MissingEmail');
        return allContacts;
    }
    
    @AuraEnabled
    public static List<ContactWrapper> getContactsFromList(Id listId, String typeOfExport){
        allContacts = processContacts(listId, typeOfExport);
        return allContacts;
    }

    private static List<ContactWrapper> processEmailExportList(Id listId, String typeOfExport) {
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<ContactWrapper> contactWrapper = new List<ContactWrapper> ();
            Map<Id, CampaignMember> contactListMember = new Map<Id, CampaignMember> ();
            Set<Id> contactIds = new Set<Id> ();
            List<Contact> contacts = new List<Contact>();
            Set<Id> significantOtherIds = new Set<Id>();
            Map<String,Related_Contact__c> mapAssistant= new Map<String,Related_Contact__c>();
            List<Contact> contactsToExport = new List<Contact> ();
            for(CampaignMember mem : [SELECT Id, ContactId, Guest_Email__c,Contact.Significant_Other_Name_Preferred__c,
                                             Assistant__c, Assistant__r.FirstName, Assistant__r.LastName,Significant_Other_Name_Preferred__c,
                                             ListMemberOutreachMethod__c, ListMemberPreferredEmail__c,Preferred_Address__c, Guest_Email_Type__c,
                                             AssistantName__c, Assistant_Email__c
                                      FROM CampaignMember
                                      WHERE CampaignId = :listId]) {

                contactIds.add(mem.ContactId);
                contactListMember.put(mem.ContactId, mem);
            }
            String filterQuery, query;
            if(typeOfExport == 'DNC') {
                filterQuery = 'DoNotCall = true';
            } else if(typeOfExport == 'MissingEmail') {
                filterQuery = '(Priority_Email__c = null OR Priority_Email__c = \'\')';
            }
            if(!contactIds.isEmpty()) {
                String restrictedFields = '';
                if(typeOfExport == 'DNC') {
                    restrictedFields = 'RestrictedSalutation__c, RestrictedSuffix__c, RestrictedFirstName__c, RestrictedMiddleName__c, RestrictedLastName__c, Restricted__c, ';
                }
                query = 'SELECT Id, Staff_Role__c, Client__c, Contact_Alert_Reason__c, FirstName, Annual_Report_Salutation__c, CorrespondenceDearLine__c, ' +
                              ' OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, MailingStreet, MailingCity, MailingState, MailingPostalCode,' +
                              ' MailingCountry, Priority_Email__c, LastName, Preferred_First_Name__c, MiddleName, Personal_Email_2__c, Phone,' +
                              ' Office_Phone_Country_Code__c, MobilePhone, Significant_Name__c, Mobile_Phone_Country_Code__c, MailingAddress, OtherAddress, Business_Email_2__c,' +
                              ' Email, Alternate_Email__c, Primary_Spouse__c, Salutation, Significant_Other__c, Significant_Other__r.FirstName, Significant_Other__r.LastName,' +
                              ' Title, Account.Name, Significant_Other__r.Salutation, Significant_Other__r.Annual_Report_Salutation__c, Preferred_Last_Name__c, ' +
                              restrictedFields + 
                              ' (SELECT Id, Tag__r.Name FROM Tags__r ORDER BY Tag__r.Name ASC)' +
                       ' FROM Contact' +
                       ' WHERE Id IN :contactIds' +
                        ' AND ' + filterQuery +
                       ' ORDER BY Primary_Spouse__c DESC, LastName, FirstName ASC';
                contacts = Database.query(query, AccessLevel.SYSTEM_MODE);
                for(Contact con : contacts) {
                    if(typeOfExport == 'DNC') {
                        con = copyRestrictedFields(con);
                    }
                    ContactWrapper wrap = new ContactWrapper(con, '', 'Standard', contactIds, contactListMember.get(con.Id));
                    contactWrapper.add(wrap);
                }
            }
            return contactWrapper;
            
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_PROCESS_DND_CONTACTS)); 
            return null;
        } 
    }
    
    private static List<ContactWrapper> processContacts (Id listId, String typeOfExport) {
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<ContactWrapper> contactWrapper = new List<ContactWrapper> ();
            Map<Id, CampaignMember> contactListMember = new Map<Id, CampaignMember> ();
            Set<Id> contactIds = new Set<Id> ();
            List<Contact> contacts = new List<Contact> ();
            Set<Id> significantOtherIds = new Set<Id> ();
            Map<String,Related_Contact__c> mapAssistant= new Map<String,Related_Contact__c>();
            List<Contact> contactsToExport = new List<Contact> ();
            for(CampaignMember mem: [SELECT Id, ContactId, Guest_Email__c, Assistant__c,Significant_Other_Name_Preferred__c, Assistant__r.FirstName, Assistant__r.LastName, ListMemberOutreachMethod__c, ListMemberPreferredEmail__c,Preferred_Address__c, Guest_Email_Type__c, AssistantName__c, Assistant_Email__c FROM CampaignMember WHERE CampaignId =: listId]) {
                contactIds.add(mem.ContactId);
                contactListMember.put(mem.ContactId, mem);
            }
            if(!contactIds.isEmpty()) {
                
                contacts = [SELECT Id, Staff_Role__c, Client__c, Contact_Alert_Reason__c, FirstName, Annual_Report_Salutation__c, CorrespondenceDearLine__c, 
                            OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                            MailingCountry, Priority_Email__c, LastName, Preferred_First_Name__c, Preferred_Last_Name__c, MiddleName, Personal_Email_2__c, Phone,Significant_Name__c,
                            Office_Phone_Country_Code__c, MobilePhone, Mobile_Phone_Country_Code__c, MailingAddress, OtherAddress, Business_Email_2__c,
                            Email, Alternate_Email__c, Primary_Spouse__c, Salutation, Significant_Other__c, Significant_Other__r.FirstName, Significant_Other__r.LastName,
                            Title, Account.Name, Significant_Other__r.Salutation, Significant_Other__r.Annual_Report_Salutation__c,
                            (SELECT Id, Tag__r.Name FROM Tags__r ORDER BY Tag__r.Name ASC) FROM Contact WHERE Id IN: contactIds WITH SYSTEM_MODE ORDER BY Primary_Spouse__c DESC ,LASTNAME,FIRSTName ASC ];
                for(Contact con: contacts) {
                    if(con.Significant_Other__c != null && con.Primary_Spouse__c) significantOtherIds.add(con.Significant_Other__c);
                }
                
                for(Contact con: contacts) {
                    if(typeOfExport == 'Executive') {
                        if(!significantOtherIds.contains(con.Id)) {
                            ContactWrapper wrap = new ContactWrapper (con, '', typeOfExport, contactIds, contactListMember.get(con.Id));
                            if(mapAssistant.ContainsKey(con.Id)){
                                wrap.assistantName = (mapAssistant.get(con.Id).Related_Contact__c != null) ? mapAssistant.get(con.Id).Related_Contact__r.Name : '';
                            }
                            contactWrapper.add(wrap);
                        }                    
                    } else {
                        ContactWrapper wrap = new ContactWrapper (con, '', typeOfExport, contactIds, contactListMember.get(con.Id));
                        if(mapAssistant.ContainsKey(con.Id)){
                            wrap.assistantName = (mapAssistant.get(con.Id).Related_Contact__c != null) ? mapAssistant.get(con.Id).Related_Contact__r.Name : '';
                        }
                        contactWrapper.add(wrap);
                    }
                }
            }
            
            return contactWrapper;
            
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_PROCESS_CONTACTS)); 
            return null;
        }
    }
    
    private static List<ContactWrapper> processTagIds (Set<id> tagIds,String typeOfExport) {
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<ContactWrapper> contactWrapper = new List<ContactWrapper> ();
            Map<Id,Tag_Junction__c> tagMaptoId = new Map<Id,Tag_Junction__c>();
            Set<Id> contactIds = new Set<Id> ();
            String selectedTags = '';
            Set<Id> significantOtherIds = new Set<Id> ();
            for(Tag__c tag: [SELECT Id, Name,private__c, ownerid FROM Tag__c WHERE Id IN: tagIds WITH SYSTEM_MODE order by Name ASC]) {
                selectedTags += tag.Name + '|';
            }
            for (Tag_Junction__c tag: [SELECT Id, Contact__c, Tag__r.Name,Tag__r.private__c,Tag__r.Owner.Name FROM Tag_Junction__c WHERE Tag__c IN: tagIds WITH SYSTEM_MODE]) {
                contactIds.add(tag.Contact__c);
                tagMaptoId.put(tag.Contact__c,tag);
            }
            
            selectedTags = selectedTags.removeEnd(',');
            Set<ID> signIds = new Set<Id>();   
            if(!contactIds.isEmpty()) {
                Map<Id, AssistantWrapper> assistanceMap = new Map<Id, AssistantWrapper>();

                List<Contact> contacts= [SELECT Id, Staff_Role__c, Client__c, FirstName, Annual_Report_Salutation__c, CorrespondenceDearLine__c, OtherStreet,
                                         OtherCity, OtherState, OtherPostalCode, OtherCountry, MailingStreet, MailingCity, MailingState,
                                         MailingPostalCode, MailingCountry, Priority_Email__c, LastName, Preferred_First_Name__c, Preferred_Last_Name__c,
                                         MiddleName, Personal_Email_2__c, Phone, Office_Phone_Country_Code__c, MobilePhone, Significant_Name__c,
                                         Mobile_Phone_Country_Code__c, MailingAddress,Contact_Alert_Reason__c, OtherAddress, Business_Email_2__c, Email,
                                         Alternate_Email__c, Primary_Spouse__c, Salutation, Significant_Other__c, Significant_Other_Name_Preferred__c, Significant_Other__r.Salutation, Significant_Other__r.Annual_Report_Salutation__c,
                                         Significant_Other__r.FirstName, Significant_Other__r.LastName, Title, Account.Name, ConfidentialAddressType__c, DoNOtCall,
                                         ConfidentialStreet__c, ConfidentialStreet2__c, ConfidentialStreet3__c, ConfidentialCity__c, ConfidentialStateProvice__c, ConfidentialZipPostalCode__c, Confidential_Country__c,
                                         (SELECT Id, Tag__r.Name FROM Tags__r ORDER BY Tag__r.Name ASC) FROM Contact
                                         WHERE Id IN: contactIds and DoNotCall = false WITH SYSTEM_MODE ORDER BY Primary_Spouse__c DESC, LastName,FirstName ASC];
                for(Contact con: contacts) {
                    if(con.Significant_Other__c != null && con.Primary_Spouse__c) significantOtherIds.add(con.Significant_Other__c);
                }
                assistanceMap = getAssistanceData(contactIds,significantOtherIds);
                for(Contact con: contacts) {
                    if(typeOfExport == 'Executive') {
                        if(!significantOtherIds.contains(con.Id) && !signIds.Contains(con.Significant_Other__c)) {
                            ContactWrapper wrap = new ContactWrapper (con, selectedTags,tagMaptoId,typeOfExport,contactIds);
                            
                            if(assistanceMap.ContainsKey(con.Id)) {
                                AssistantWrapper  assistantWrapper=   assistanceMap.get(con.Id);
                                wrap.assistantName = assistantWrapper.assistantName;
                                wrap.assistantEmail = assistantWrapper.assistanttBusinessEmail;
                                wrap.staffRole =assistantWrapper.staffRole;
                            }
                            contactWrapper.add(wrap);   
                            signIds.add(con.Id);
                        }
                    } else {
                        ContactWrapper wrap = new ContactWrapper (con, selectedTags,tagMaptoId,typeOfExport,contactIds);
                        if(assistanceMap.ContainsKey(con.Id)) {
                            AssistantWrapper  assistantWrapper=   assistanceMap.get(con.Id);
                            wrap.assistantName = assistantWrapper.assistantName;
                            wrap.assistantEmail = assistantWrapper.assistanttBusinessEmail;
                            wrap.staffRole =assistantWrapper.staffRole;
                        }
                        contactWrapper.add(wrap);
                    } 
                }
            }
            
            return contactWrapper;
            
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_PROCESS_TAGIDS)); 
            return null;
        }
    }
    
    @AuraEnabled
    public static AvailableOptionWrapper getAvailableColumns(String recordTypeName) {   
        try{  
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<OptionWrapper> contactFields = getFieldsByRecordType(CONTACT_OBJECT, 'Export_List');
            List<OptionWrapper> listMemberFields = new List<OptionWrapper>();
            if (CONTACT_RECORDTYPE.equalsIgnoreCase(recordTypeName) || CONTACT_LEADERSHIP_RECORDTYPE.equalsIgnoreCase(recordTypeName)) {
                listMemberFields = getFieldsByRecordType(LIST_MEMBER_OBJECT, CONTACT_FIELDSET_NAME);
            } else if (EVENTS_RECORDTYPE.equalsIgnoreCase(recordTypeName) || GUESTLIST_RECORDTYPE.equalsIgnoreCase(recordTypeName)) {
                listMemberFields = getFieldsByRecordType(LIST_MEMBER_OBJECT, EVENT_FIELDSET_NAME);
            } else if (FUNDRAISING_RECORDTYPE.equalsIgnoreCase(recordTypeName)) {
                listMemberFields = getFieldsByRecordType(LIST_MEMBER_OBJECT, FUNDING_FIELDSET_NAME);
            }
            AvailableOptionWrapper availableOptions = new AvailableOptionWrapper(contactFields, listMemberFields);       
            return availableOptions;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_AVAILABLE_COLUMNS)); 
            return null;
        }
    }
    
    @AuraEnabled
    public static List<ExportDataWrapper> getMemeberList(
        String campaignId,
        String typeOfExport,
        List<String> fieldAPINames,
        List<String> listMemberFieldAPINames,
        List<String> contactFieldAPINames
    ) {
        try {  
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            
            Set<String> filteredFieldAPINames = new Set<String>(fieldAPINames);
            List<ExportDataWrapper> exportDataWrappers = new List<ExportDataWrapper>();
            List<CampaignMember> campaignMembers = new List<CampaignMember>();
            Map<Id, CampaignMember> contactListMember = new Map<Id, CampaignMember>();
            
            String soql = 'SELECT Id, Significant_Other_Name_Preferred__c, ContactId, Via__r.Name, Contact.Restricted_Name__c ';
            
            for (String apiName : filteredFieldAPINames) {
                if (!NON_API_NAME_FIELDS.contains(apiName)) {
                    if (
                        listMemberFieldAPINames.contains(apiName) &&
                        (!soql.contains(apiName) || soql.contains('.' + apiName) || apiName == 'Type__c')
                    ) {
                        soql += ', ' + apiName;
                    }
                }
            }
            
            soql += ' FROM CampaignMember WHERE CampaignId = :campaignId ' +
                'ORDER BY Contact.Last_Preferred_Last_Name__c, Contact.FIRSTNAME ASC';

            Set<Id> contactIds = new Set<Id>();
            List<CampaignMember> listMembers = (List<CampaignMember>) Database.query(soql, AccessLevel.SYSTEM_MODE);

            for (CampaignMember listMember : listMembers) {
                contactIds.add(listMember.ContactId);
                contactListMember.put(listMember.ContactId, listMember);
            }
            
            String contactSoql =
                'SELECT Id, Name, Primary_Spouse__c, Significant_Other__r.Primary_Spouse__c, ' +
                'Preferred_First_Name__c, Preferred_Last_Name__c, FirstName, LastName, Last_Preferred_Last_Name__c, Significant_Other__c, ' +
                'Significant_Other__r.Salutation, Significant_Other__r.Annual_Report_Salutation__c, ' +
                'Annual_Report_Salutation__c, Salutation, Significant_Other__r.Name, Significant_Name__c, ' +
                'Significant_Other__r.FirstName, Significant_Other__r.LastName, Title, Account.Name, ' +
                'Priority_Email__c, Restricted__c, Account.Restricted__c, RestrictedSalutation__c, ' +
                'RestrictedSuffix__c, RestrictedFirstName__c, RestrictedMiddleName__c, ' +
                'RestrictedLastName__c, Restricted_Name__c, Restricted_Org_Name__c ';
            
            for (String apiName : fieldAPINames) {
                if (
                    contactFieldAPINames.contains(apiName) &&
                    !ALREADY_SELECTED_FIELDS.contains(apiName)
                ) {
                    if (
                        !NON_API_NAME_FIELDS.contains(apiName) &&
                        (!contactSoql.contains(apiName) || !contactSoql.contains('.' + apiName))
                    ) {
                        if (BUSINESS_EMAIL.equalsIgnoreCase(apiName)) {
                            apiName = 'Email';
                        }
                        if (BUSINESS_PHONE.equalsIgnoreCase(apiName)) {
                            apiName = 'Phone';
                        }
                        contactSoql += ', ' + apiName;
                    }
                }
            }
            
            contactSoql +=
                ', (SELECT Id, Tag__r.Name FROM Tags__r ORDER BY Tag__r.Name asc) ' +
                'FROM Contact ' +
                'WHERE Id IN :contactIds AND DoNotCall = false ' +
                //'ORDER BY LASTNAME, FIRSTNAME ASC';
                'ORDER BY LAST_Preferred_Last_Name__c, FIRSTNAME ASC';
            
            List<Contact> contacts = new List<Contact>();
            Set<Id> significantOtherIds = new Set<Id>();
            Set<Id> nonSignificantOtherIds = new Set<Id>();
            Map<Id, String> nonSignificantOtherNames = new Map<Id, String>();
            
            if (!contactIds.isEmpty()) {
                Map<Id, AssistantWrapper> assistanceMap = new Map<Id, AssistantWrapper>();
                assistanceMap = getAssistanceData(contactIds, significantOtherIds);

                contacts = (List<Contact>) Database.query(contactSoql, AccessLevel.SYSTEM_MODE);
                contacts.sort(new ContactRestrictedSort());
                
                for (Contact contact : contacts) {
                    if (contact.Significant_Other__c != null) {
                        if (
                            (contact.Primary_Spouse__c ||
                             !significantOtherIds.contains(contact.Significant_Other__c)) &&
                            !contact.Significant_Other__r.Primary_Spouse__c &&
                            !significantOtherIds.contains(contact.Id)
                        ) {
                            significantOtherIds.add(contact.Significant_Other__c);
                        } else {
                            if (!significantOtherIds.contains(contact.Id)) {
                                nonSignificantOtherIds.add(contact.Significant_Other__c);
                                nonSignificantOtherNames.put(
                                    contact.Significant_Other__c,
                                    contact.Significant_Other__r.Name
                                );
                            }
                        }
                    }
                }
                
                for (Contact contact : contacts) {
                    if (typeOfExport == 'Executive') {
                        if (!significantOtherIds.contains(contact.Id)) {
                            
                            if (nonSignificantOtherIds.contains(contact.Id)) {
                                String tempName = contact.Name;
                                String tempSigName = contact.Significant_Other__r.Name;
                                
                                if (tempName.compareTo(tempSigName) < 0) {
                                    ExportDataWrapper exportDataWrapper =
                                        new ExportDataWrapper(
                                            contactListMember.get(contact.Id),
                                            contact,
                                            assistanceMap.get(contact.Id)
                                        );
                                    
                                    if (!contactIds.contains(contact.Significant_Other__c)) {
                                        exportDataWrapper.significantOther = '';
                                    }
                                    
                                    exportDataWrappers.add(exportDataWrapper);
                                } else {
                                    ExportDataWrapper exportDataWrapper =
                                        new ExportDataWrapper(
                                            contactListMember.get(contact.Id),
                                            contact,
                                            assistanceMap.get(contact.Id)
                                        );
                                    exportDataWrappers.add(exportDataWrapper);
                                }
                            } else {
                                ExportDataWrapper exportDataWrapper =
                                    new ExportDataWrapper(
                                        contactListMember.get(contact.Id),
                                        contact,
                                        assistanceMap.get(contact.Id)
                                    );
                                
                                if (!contactIds.contains(contact.Significant_Other__c)) {
                                    exportDataWrapper.significantOther = '';
                                    exportDataWrapper.SignificantOtherPreferredFirstName = '';
                                }
                                
                                exportDataWrappers.add(exportDataWrapper);
                            }
                        }
                    } else {
                        ExportDataWrapper exportDataWrapper =
                            new ExportDataWrapper(
                                contactListMember.get(contact.Id),
                                contact,
                                assistanceMap.get(contact.Id)
                            );
                        exportDataWrappers.add(exportDataWrapper);
                    }
                }
            }
            
            return exportDataWrappers;
            
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_MEMBER_LIST));
            return null;
        }
    }

    /**
     * @description Counts restricted (Private) contacts in the given list, ignoring
     * record-level sharing, so the export warning fires even for users who cannot see
     * the restricted contact records.
     */
    @AuraEnabled
    public static Integer getRestrictedContactCount(Id campaignId) {
        return RestrictedRecordDetector.countRestrictedContactsInList(campaignId);
    }

    private static List<OptionWrapper> getFieldsByRecordType(String objectName, String devName) {
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Schema.SObjectType schemaType = Schema.getGlobalDescribe().get(objectName);
            Schema.DescribeSObjectResult describeSObjectResultObj = schemaType.getDescribe();
            Map<String, SObjectField> allFields = describeSObjectResultObj.fields.getMap();
            
            Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(devName);
            
            List<Schema.FieldSetMember> fields = fieldSetObj.getFields();
            List<OptionWrapper> availableOptions = new List<OptionWrapper>();
            for (Schema.FieldSetMember field : fields) {
                if (allFields.get(field.getFieldPath()).getDescribe().isAccessible()) {
                    
                    if (ASSISTANT_NAME.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new OptionWrapper(field.getLabel(), STAFF_NAME));
                    } else if (ASSISTANT_PERSONNEL_EMAIL_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new OptionWrapper(field.getLabel(), ASSISTANT_PERSONNEL_EMAIL));
                    } else if (ASSISTANT_BUSINESS_EMAIL_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new OptionWrapper(field.getLabel(), ASSISTANT_BUSINESS_EMAIL));
                    } else if (ASSISTANT_BUSINESS_PHONE_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new OptionWrapper(field.getLabel(), ASSISTANT_BUSINESS_PHONE));
                    } else if (ASSISTANT_MOBILE_PHONE_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new OptionWrapper(field.getLabel(), ASSISTANT_MOBILE_PHONE));
                    } else if (STAFF_ROLE_LABEL.equalsIgnoreCase(field.getLabel())) {
                        availableOptions.add(new OptionWrapper(field.getLabel(), STAFF_ROLE));
                    } else {
                        if (allFields.get(field.getFieldPath()).getDescribe().isAccessible()) {
                            String fieldAPIName = field.getFieldPath();
                            if (CONTACT_OBJECT.equalsIgnoreCase(objectName)) {
                                if (CONTACT_BUSINESS_EMAIL_LABEL.equalsIgnoreCase(field.getLabel())) {
                                    fieldAPIName = BUSINESS_EMAIL;
                                }
                                if (CONTACT_BUSINESS_PHONE_LABEL.equalsIgnoreCase(field.getLabel())) {
                                    fieldAPIName = BUSINESS_PHONE;
                                }
                            }
                            availableOptions.add(new OptionWrapper(field.getLabel(), fieldAPIName));
                        }
                    }
                }
            }
            return availableOptions;
            
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_FIELDS_BY_RECORDTYPE)); 
            return null;
        }
    }
    
    public static Contact copyRestrictedFields(Contact con) {
        System.debug('########ExportContactsController-copyRestrictedFields-con: ' + con);
        // Describe Contact once
        Map<String, SObjectField> fieldMap = Contact.SObjectType.getDescribe().fields.getMap();
        System.debug('########ExportContactsController-copyRestrictedFields-hasAccess: ' + hasAccess(fieldMap, 'RestrictedLastName__c'));
        // Check if this contact is marked as restricted
        if (con.Restricted__c) {
            // Copy values only if FLS allows
            if (hasAccess(fieldMap, 'RestrictedSalutation__c')) {
                con.Salutation = con.RestrictedSalutation__c;
            }
            if (hasAccess(fieldMap, 'RestrictedSuffix__c')) {
                con.Suffix = con.RestrictedSuffix__c;
            }
            if (hasAccess(fieldMap, 'RestrictedFirstName__c')) {
                con.FirstName = con.RestrictedFirstName__c;
            }
            if (hasAccess(fieldMap, 'RestrictedMiddleName__c')) {
                con.MiddleName = con.RestrictedMiddleName__c;
            }
            if (hasAccess(fieldMap, 'RestrictedLastName__c')) {
                con.LastName = con.RestrictedLastName__c;
            }
        }
        return con;
    }
    
    // Helper to check if running user has FLS read access to field
    public static Boolean hasAccess(Map<String, SObjectField> fieldMap, String fieldName) {
        return fieldMap.containsKey(fieldName) && fieldMap.get(fieldName).getDescribe().isAccessible();
    }
    
    public class AvailableOptionWrapper {
        @AuraEnabled
        public List<OptionWrapper> contactFields {get;set;}
        @AuraEnabled
        public List<OptionWrapper> listMemberFields {get;set;}
        
        public AvailableOptionWrapper(List<OptionWrapper> contactFields, List<OptionWrapper> listMemberFields) {
            this.contactFields = contactFields;
            this.listMemberFields = listMemberFields;
        }
    }
    
    public class OptionWrapper {
        @AuraEnabled
        public String fieldLabel {get;set;}
        @AuraEnabled
        public String fieldValue {get;set;}
        
        public OptionWrapper(String fieldLabel, String fieldValue) {
            this.fieldLabel = fieldLabel;
            this.fieldValue = fieldValue;
        }
    }
    
    public class AssistantWrapper {
        @AuraEnabled
        public String assistantName {get;set;}
        @AuraEnabled
        public String assistantPersonnelEmail {get;set;}
        @AuraEnabled
        public String assistanttBusinessEmail {get;set;}
        @AuraEnabled
        public String assistantBusinessPhone {get;set;}
        @AuraEnabled
        public String assistantMobilePhone {get;set;}
        @AuraEnabled
        public String staffRole {get;set;}
        
        public AssistantWrapper(String assistantName, String assistantPersonnelEmail) {
            this.assistantName = assistantName;
            this.assistantPersonnelEmail = assistantPersonnelEmail;
        }
        
        public AssistantWrapper(String assistantName, String assistantPersonnelEmail, String assistanttBusinessEmail, String assistantBusinessPhone, String assistantMobilePhone) {
            this.assistantName = assistantName;
            this.assistantPersonnelEmail = assistantPersonnelEmail;
            this.assistanttBusinessEmail = assistanttBusinessEmail;
            this.assistantBusinessPhone = assistantBusinessPhone;
            this.assistantMobilePhone = assistantMobilePhone;
        }
        
        public AssistantWrapper(String assistantName, String assistantPersonnelEmail, String assistanttBusinessEmail, String assistantBusinessPhone, String assistantMobilePhone, String staffRole) {
            this(assistantName, assistantPersonnelEmail, assistanttBusinessEmail, assistantBusinessPhone, assistantMobilePhone);
            this.staffRole = staffRole;
        }
    }
    
    public class ExportDataWrapper {
        @AuraEnabled
        public CampaignMember listMember {get;set;}
        @AuraEnabled
        public Contact contact {get;set;}
        @AuraEnabled
        public Tag__c tag {get;set;}
        @AuraEnabled
        public String firstOrPreferredFirstName {get;set;}
        @AuraEnabled
        public String lastOrPreferredLastName {get;set;}
        @AuraEnabled
        public String ffTags {get;set;}
        @AuraEnabled
        public String otherTags {get;set;}
        @AuraEnabled
        public String listMemberId {get;set;}
        @AuraEnabled 
        public String significantOther {get;set;}
        @AuraEnabled 
        public String organization {get;set;}
        @AuraEnabled 
        public String bpLpContact {get;set;}
        @AuraEnabled 
        public String BusinessEmail {get;set;}
        @AuraEnabled 
        public String BusinessPhone {get;set;}
        @AuraEnabled 
        public String StaffName {get;set;}
        @AuraEnabled 
        public String AssistantName {get;set;}
        @AuraEnabled 
        public String AssistantPersonalEmail {get;set;}
        @AuraEnabled 
        public String AssistantBusinessEmail {get;set;}
        @AuraEnabled 
        public String AssistantBusinessPhone {get;set;}
        @AuraEnabled 
        public String AssistantMobilePhone {get;set;}
        @AuraEnabled 
        public String StaffRole {get;set;}
        @AuraEnabled 
        public String SignificantOtherPreferredFirstName {get;set;}
        @AuraEnabled 
        public String SignificantSalutation {get;set;}
        @AuraEnabled 
        public String SignificantARSalutation {get;set;}
        @AuraEnabled 
        public String tagSourceResult {get;set;}
        
        public ExportDataWrapper(Tag__c tag) {
            this.tag = tag;
            this.listMember = new CampaignMember();
            this.contact = new Contact();
        }
        
        public ExportDataWrapper(CampaignMember listMember, Contact contact, AssistantWrapper assistantWrapper) {
            if(listMember != null) {
                this.listMember = listMember;
                this.listMemberId = listMember.Id;
                this.bpLpContact = listMember.Via__r.Name;
                this.SignificantOtherPreferredFirstName = listMember.Significant_Other_Name_Preferred__c;
            } else {
                this.listMember = new CampaignMember();
                this.SignificantOtherPreferredFirstName = contact.Significant_Other_Name_Preferred__c;
            }
            if(contact != null) {
                this.contact = copyRestrictedFields(contact);
                this.firstOrPreferredFirstName = contact.Preferred_First_Name__c  != null 
                    ? contact.Preferred_First_Name__c : contact.FirstName != null ? contact.FirstName : '';
                this.lastOrPreferredLastName = contact.Preferred_Last_Name__c  != null
                    ? contact.Preferred_Last_Name__c : contact.LastName != null ? contact.LastName : '';
                this.lastOrPreferredLastName = contact.Last_Preferred_Last_Name__c;
                this.significantOther =  contact.Significant_Name__c != null ? contact.Significant_Name__c : '';
                this.SignificantSalutation = contact.Significant_Other__c!=null && contact.Significant_Other__r.Salutation != null ? contact.Significant_Other__r.Salutation : '';
                this.SignificantARSalutation = Schema.sObjectType.Contact.fields.Annual_Report_Salutation__c.isAccessible() && contact.Significant_Other__c!=null && contact.Significant_Other__r.Annual_Report_Salutation__c != null ? contact.Significant_Other__r.Annual_Report_Salutation__c  : '';
                this.organization = contact.Account.Name;
                if (contact.Account.Restricted__c && Schema.sObjectType.Contact.fields.Restricted_Org_Name__c.isAccessible()) {
                    this.organization= contact.Restricted_Org_Name__c; // assuming custom mapping
                }
                if (contact.isSet('Email')) {
                    this.BusinessEmail = contact.Email;
                }
                if (contact.isSet('Phone')) {
                    this.BusinessPhone = contact.Phone;
                }
                
                if(assistantWrapper != null) {
                    this.StaffName = assistantWrapper.assistantName;
                    this.AssistantName = assistantWrapper.assistantName;
                    this.AssistantPersonalEmail = assistantWrapper.assistantPersonnelEmail;
                    this.AssistantBusinessEmail = assistantWrapper.assistanttBusinessEmail;
                    this.AssistantBusinessPhone = assistantWrapper.assistantBusinessPhone;
                    this.AssistantMobilePhone = assistantWrapper.assistantMobilePhone;
                    this.StaffRole = assistantWrapper.staffRole;
                }
                processTags(contact.Tags__r);
            } else {
                this.contact = new Contact();
            }
        }
        
        public void processTags(List<Tag_Junction__c> tags) {
            Set<String> ffTags = new Set<String> ();
            Set<String> otherTags = new Set<String> ();
            List<String> ffTagsList = new List<String> ();
            List<String> otherTagsList = new List<String> ();
            
            for(Tag_Junction__c tag: tags) {
                if(tag.Tag__r.Name.containsIgnoreCase('F&F')) {
                    ffTags.add(tag.Tag__r.Name);
                } else {
                    otherTags.add(tag.Tag__r.Name);
                }
            }
            
            otherTagsList.addAll(otherTags);
            ffTagsList.addAll(ffTags);
            
            this.ffTags = String.join(ffTagsList, ', ');
            this.otherTags = String.join(otherTagsList, ', ');
        }
    }
    
    public class ContactWrapper {
        @AuraEnabled public Contact contact;
        @AuraEnabled public String id;
        @AuraEnabled public String firstName = '';
        @AuraEnabled public String preferredFirstName = '';
        @AuraEnabled public String firstOrPreferredFirstName = '';  
        @AuraEnabled public String lastOrPreferredLastName = ''; 
        @AuraEnabled public String lastName = '';
        @AuraEnabled public String significantOther = '';
        @AuraEnabled public String title = '';
        @AuraEnabled public String organization = '';
        @AuraEnabled public String ffTags;
        @AuraEnabled public String otherTags;
        @AuraEnabled public String selectedTags;
        @AuraEnabled public String salutation;
        @AuraEnabled public String guestEmail;
        @AuraEnabled public String guestEmailType;
        @AuraEnabled public String businessEmail;
        @AuraEnabled public String personalEmail;
        @AuraEnabled public String additionalEmail;
        @AuraEnabled public String middleName;
        @AuraEnabled public String confidentialEmail;
        @AuraEnabled public String businessPhoneCC;
        @AuraEnabled public String businessPhone;
        @AuraEnabled public String mobilePhoneCC;
        @AuraEnabled public String mobilePhone;
        @AuraEnabled public String businessAddress;
        @AuraEnabled public String homeAddress;
        @AuraEnabled public String assistantName;
        @AuraEnabled public String assistantEmail;
        @AuraEnabled public String correspondenceDearLine;
        @AuraEnabled public String annualReportSalutation;
        @AuraEnabled public String salutationSpouse;
        @AuraEnabled public String listMemberOutreachMethod;
        @AuraEnabled public String listMemberPreferredEmail;
        @AuraEnabled public String listMemberPreferredMailAddress;
        @AuraEnabled public String listMemberId;
        @AuraEnabled public String priorityEmail;
        @AuraEnabled public String tagId;
        @AuraEnabled public String tagsId;
        @AuraEnabled public String tagPrivate;
        @AuraEnabled public String tagOwner;
        @AuraEnabled public String staffRole;
        @AuraEnabled public String client;
        @AuraEnabled public String ContactAlertReason;
        @AuraEnabled public String SignificantOtherPreferredFirstName;
        @AuraEnabled public String SignificantSalutation {get;set;}
        @AuraEnabled public String SignificantARSalutation {get;set;}
        @AuraEnabled public String BusinessStreet {get;set;}
        @AuraEnabled public String BusinessCity {get;set;}
        @AuraEnabled public String BusinesState {get;set;}
        @AuraEnabled public String BusinessPostalCode {get;set;}
        @AuraEnabled public String BusinessCountry {get;set;}
        @AuraEnabled public String HomeStreet {get;set;}
        @AuraEnabled public String HomeCity {get;set;}
        @AuraEnabled public String HomeStateProvince {get;set;}
        @AuraEnabled public String HomePostalCode {get;set;}
        @AuraEnabled public String HomeCountry {get;set;}
        @AuraEnabled public String ConfidentialAddressType {get;set;}
        @AuraEnabled public String ConfidentialStreet {get;set;}
        @AuraEnabled public String ConfidentialStreet2 {get;set;}
        @AuraEnabled public String ConfidentialStreet3 {get;set;}
        @AuraEnabled public String ConfidentialCity {get;set;}
        @AuraEnabled public String ConfidentialStateProvince {get;set;}
        @AuraEnabled public String ConfidentialZipPostalCode {get;set;}
        @AuraEnabled public String ConfidentialCountry {get;set;}
        @AuraEnabled public String DoNotCall {get;set;}
        
        public ContactWrapper(){}
        
        public ContactWrapper (Contact contact, String selectedTags,Map<Id,Tag_Junction__c> mapContactIdtoTag,String typeOfExport, Set<Id> contactIds) {
            this.selectedTags = selectedTags;
            this.contact = contact;
            this.staffRole = contact.Staff_Role__c != null ? contact.Staff_Role__c : '';
            this.client = (Schema.sObjectType.Contact.fields.Client__c.isAccessible() && contact.Client__c != null) ? String.valueOf(contact.Client__c) : '';
            this.firstName = contact.FirstName != null ? contact.FirstName : '';
            this.preferredFirstName = (Schema.sObjectType.Contact.fields.Preferred_First_Name__c.isAccessible() && contact.Preferred_First_Name__c  != null) ? contact.Preferred_First_Name__c  : '';
            this.firstOrPreferredFirstName = (Schema.sObjectType.Contact.fields.Preferred_First_Name__c.isAccessible() && contact.Preferred_First_Name__c != null) ? contact.Preferred_First_Name__c : contact.FirstName != null ? contact.FirstName : '';
             this.lastOrPreferredLastName = (Schema.sObjectType.Contact.fields.Preferred_Last_Name__c.isAccessible() && contact.Preferred_Last_Name__c != null) ? contact.Preferred_Last_Name__c : contact.LastName != null ? contact.LastName : '';
            this.lastName = contact.LastName != null ? contact.LastName : '';
            this.id = contact.Id;
            this.title = contact.Title != null ? contact.Title : '';
            this.tagPrivate = String.valueof(mapContactIdtoTag.get(contact.Id).Tag__r.private__c);
            this.tagOwner = (Schema.sObjectType.Tag__c.fields.OwnerId.isAccessible() && mapContactIdtoTag.get(contact.Id).Tag__r.Owner.Name != null) ? mapContactIdtoTag.get(contact.Id).Tag__r.Owner.Name : '';
            this.tagId = mapContactIdtoTag.get(contact.Id).Tag__c;
            this.tagsId = mapContactIdtoTag.get(contact.Id).Id;
            this.salutation = contact.salutation != null ? contact.salutation : '';
            this.organization = contact.Account.Name != null ? contact.Account.Name : '';
            if((typeOfExport == 'Executive' && mapContactIdtoTag.containsKey(contact.Significant_Other__c)  || typeOfExport == 'Standard') && String.isNotBlank(contact.Significant_Other__c)) {//&&  mapContactIdtoTag.containsKey(contact.Significant_Other__c)
                this.significantOther =  contact.Significant_Name__c != null ? contact.Significant_Name__c : '';
                this.SignificantOtherPreferredFirstName =contact.Significant_Other_Name_Preferred__c;
                this.SignificantSalutation = contact.Significant_Other__c!=null && contact.Significant_Other__r.Salutation != null ? contact.Significant_Other__r.Salutation : '';
                this.SignificantARSalutation = Schema.sObjectType.Contact.fields.Annual_Report_Salutation__c.isAccessible() && contact.Significant_Other__c!=null && contact.Significant_Other__r.Annual_Report_Salutation__c != null ? contact.Significant_Other__r.Annual_Report_Salutation__c  : ''; 
            } 
            this.annualReportSalutation = (Schema.sObjectType.Contact.fields.Annual_Report_Salutation__c.isAccessible() && contact.Annual_Report_Salutation__c != null) ? contact.Annual_Report_Salutation__c : '';          
            this.businessEmail = (Schema.sObjectType.Contact.fields.Email.isAccessible() && contact.Email != null) ? contact.Email : '';
            this.personalEmail = (Schema.sObjectType.Contact.fields.Alternate_Email__c.isAccessible() && contact.Alternate_Email__c != null) ? contact.Alternate_Email__c : '';
            this.additionalEmail = (Schema.sObjectType.Contact.fields.Business_Email_2__c.isAccessible() && contact.Business_Email_2__c != null) ? contact.Business_Email_2__c : '';
            this.priorityEmail = (Schema.sObjectType.Contact.fields.Priority_Email__c.isAccessible() && contact.Priority_Email__c != null) ? contact.Priority_Email__c : '';
            this.middleName = (Schema.sObjectType.Contact.fields.MiddleName.isAccessible() && contact.MiddleName != null) ? contact.MiddleName : '';
            this.confidentialEmail = (Schema.sObjectType.Contact.fields.Personal_Email_2__c.isAccessible() && contact.Personal_Email_2__c != null) ? contact.Personal_Email_2__c : '';
            this.businessPhoneCC = (Schema.sObjectType.Contact.fields.Office_Phone_Country_Code__c.isAccessible() && contact.Office_Phone_Country_Code__c != null) ? contact.Office_Phone_Country_Code__c : '';
            this.businessPhone = (Schema.sObjectType.Contact.fields.Phone.isAccessible() && contact.Phone != null) ? contact.Phone : '';
            this.mobilePhoneCC = (Schema.sObjectType.Contact.fields.Mobile_Phone_Country_Code__c.isAccessible() && contact.Mobile_Phone_Country_Code__c != null) ? contact.Mobile_Phone_Country_Code__c : '';
            this.mobilePhone = (Schema.sObjectType.Contact.fields.MobilePhone.isAccessible() && contact.MobilePhone != null) ? contact.MobilePhone : '';
            this.businessAddress ='';
            if(Schema.sObjectType.Contact.fields.MailingAddress.isAccessible() && contact.MailingAddress != null)
            {
                this.BusinessStreet = String.IsNotBlank(contact.MailingStreet) ? contact.MailingStreet :'';
                this.BusinessCity = String.IsNotBlank(contact.MailingCity) ? contact.MailingCity :'';
                this.BusinesState = String.IsNotBlank(contact.MailingState) ? contact.MailingState :'';
                this.BusinessPostalCode = String.IsNotBlank(contact.MailingPostalCode) ? contact.MailingPostalCode :'';  
                this.BusinessCountry = String.IsNotBlank(contact.MailingCountry) ? contact.MailingCountry :'';
                
                this.HomeStreet = String.IsNotBlank(contact.otherStreet) ? contact.otherStreet :'';
                this.HomeCity = String.IsNotBlank(contact.otherCity) ? contact.otherCity :'';
                this.HomeStateProvince = String.IsNotBlank(contact.OtherState) ? contact.OtherState :''; 
                this.HomePostalCode = String.IsNotBlank(contact.otherPostalCode) ? contact.otherPostalCode :'';  
                this.HomeCountry = String.IsNotBlank(contact.OtherCountry) ? contact.otherCountry :'';
                
                this.ConfidentialAddressType = String.IsNotBlank(contact.ConfidentialAddressType__c) ? contact.ConfidentialAddressType__c :'';
                this.ConfidentialStreet = String.IsNotBlank(contact.ConfidentialStreet__c) ? contact.ConfidentialStreet__c :'';
                this.ConfidentialStreet2 = String.IsNotBlank(contact.ConfidentialStreet2__c) ? contact.ConfidentialStreet2__c :'';
                this.ConfidentialStreet3 = String.IsNotBlank(contact.ConfidentialStreet__c) ? contact.ConfidentialStreet3__c :'';
                this.ConfidentialCity = String.IsNotBlank(contact.ConfidentialCity__c) ? contact.ConfidentialCity__c :'';
                this.ConfidentialStateProvince = String.IsNotBlank(contact.ConfidentialStateProvice__c) ? contact.ConfidentialStateProvice__c :'';
                this.ConfidentialZipPostalCode = String.IsNotBlank(contact.ConfidentialZipPostalCode__c) ? contact.ConfidentialZipPostalCode__c :'';
                this.ConfidentialCountry = String.IsNotBlank(contact.Confidential_Country__c) ? contact.Confidential_Country__c :'';
                
                this.ContactAlertReason = String.IsNotBlank(contact.Contact_Alert_Reason__c) ? contact.Contact_Alert_Reason__c :'';
                this.DoNotCall =  String.valueOf(contact.DoNotCall);
                
                if(String.IsNotBlank(contact.MailingCity))
                    this.businessAddress +=contact.MailingCity+', ';
                if(String.IsNotBlank(contact.MailingState))
                    this.businessAddress +=contact.MailingState+ ' ';
                if(String.IsNotBlank(contact.MailingPostalCode))
                    this.businessAddress +=contact.MailingPostalCode+', ';
                if(String.IsNotBlank(contact.MailingCountry))
                    this.businessAddress += contact.MailingCountry;
            }
            this.homeAddress ='';
            if(Schema.sObjectType.Contact.fields.OtherAddress.isAccessible() && contact.OtherAddress != null)
            {
                if(String.IsNotBlank(contact.OtherStreet))
                    this.homeAddress += contact.OtherStreet+', ';
                if(String.IsNotBlank(contact.OtherCity))
                    this.homeAddress +=contact.OtherCity+', ';
                if(String.IsNotBlank(contact.OtherState))
                    this.homeAddress +=contact.OtherState+' ';
                if(String.IsNotBlank(contact.OtherPostalCode))
                    this.homeAddress +=contact.OtherPostalCode+', ';
                if(String.IsNotBlank(contact.OtherCountry))
                    this.homeAddress +=contact.OtherCountry ;
            } 
            
            this.correspondenceDearLine = (Schema.sObjectType.Contact.fields.CorrespondenceDearLine__c.isAccessible() && contact.CorrespondenceDearLine__c != null) ? contact.CorrespondenceDearLine__c : '';
            this.salutationSpouse = contact.Primary_Spouse__c ? 'TRUE' : 'FALSE';
            getTagsString (contact.Tags__r);
        }
        
        public ContactWrapper (Contact contact, String selectedTags, String typeOfExport, Set<Id> contactIds, CampaignMember mem) {
            this.selectedTags = selectedTags;
            this.contact = contact;
            this.firstName = contact.FirstName != null ? contact.FirstName : '';
            this.preferredFirstName = (Schema.sObjectType.Contact.fields.Preferred_First_Name__c.isAccessible() && contact.Preferred_First_Name__c  != null) ? contact.Preferred_First_Name__c  : '';
            this.firstOrPreferredFirstName = (Schema.sObjectType.Contact.fields.Preferred_First_Name__c.isAccessible() && contact.Preferred_First_Name__c != null) ? contact.Preferred_First_Name__c : contact.FirstName != null ? contact.FirstName : '';
            this.lastOrPreferredLastName = (Schema.sObjectType.Contact.fields.Preferred_Last_Name__c.isAccessible() && contact.Preferred_Last_Name__c != null) ? contact.Preferred_Last_Name__c : contact.LastName != null ? contact.LastName : '';
            this.lastName = contact.LastName != null ? contact.LastName : '';
            this.id = contact.Id;
            this.title = contact.Title != null ? contact.Title : '';
            this.salutation = contact.salutation != null ? contact.salutation : '';
            this.organization = (Schema.sObjectType.Account.fields.Name.isAccessible() && contact.Account.Name != null) ? contact.Account.Name : '';
            if((typeOfExport == 'Executive' && contactIds.contains(contact.Significant_Other__c)) || typeOfExport == 'Standard') {
                this.SignificantOtherPreferredFirstName = (mem.Significant_Other_Name_Preferred__c !=null)? mem.Significant_Other_Name_Preferred__c : mem.contact.Significant_Other_Name_Preferred__c;
                this.significantOther =  contact.Significant_Name__c != null ? contact.Significant_Name__c : '';
                this.SignificantSalutation = contact.Significant_Other__c!=null && contact.Significant_Other__r.Salutation != null ? contact.Significant_Other__r.Salutation : '';
                this.SignificantARSalutation = Schema.sObjectType.Contact.fields.Annual_Report_Salutation__c.isAccessible() && contact.Significant_Other__c!=null && contact.Significant_Other__r.Annual_Report_Salutation__c != null ? contact.Significant_Other__r.Annual_Report_Salutation__c  : '';
            }
            this.annualReportSalutation = (Schema.sObjectType.Contact.fields.Annual_Report_Salutation__c.isAccessible() && contact.Annual_Report_Salutation__c != null) ? contact.Annual_Report_Salutation__c : '';
            this.guestEmail = (Schema.sObjectType.CampaignMember.fields.Guest_Email__c.isAccessible() && mem.Guest_Email__c != null) ? mem.Guest_Email__c : '';
            this.guestEmailType = (Schema.sObjectType.CampaignMember.fields.Guest_Email_Type__c.isAccessible() && mem.Guest_Email_Type__c != null) ? mem.Guest_Email_Type__c : '';
            this.businessEmail = (Schema.sObjectType.Contact.fields.Email.isAccessible() && contact.Email != null) ? contact.Email : '';
            this.personalEmail = (Schema.sObjectType.Contact.fields.Alternate_Email__c.isAccessible() && contact.Alternate_Email__c != null) ? contact.Alternate_Email__c : '';
            this.additionalEmail = (Schema.sObjectType.Contact.fields.Business_Email_2__c.isAccessible() && contact.Business_Email_2__c != null) ? contact.Business_Email_2__c : '';
            this.priorityEmail = (Schema.sObjectType.Contact.fields.Priority_Email__c.isAccessible() && contact.Priority_Email__c != null) ? contact.Priority_Email__c : '';
            this.middleName = (Schema.sObjectType.Contact.fields.MiddleName.isAccessible() && contact.MiddleName != null) ? contact.MiddleName : '';
            this.confidentialEmail = (Schema.sObjectType.Contact.fields.Personal_Email_2__c.isAccessible() && contact.Personal_Email_2__c != null) ? contact.Personal_Email_2__c : '';
            this.businessPhoneCC = (Schema.sObjectType.Contact.fields.Office_Phone_Country_Code__c.isAccessible() && contact.Office_Phone_Country_Code__c != null) ? contact.Office_Phone_Country_Code__c : '';
            this.businessPhone = (Schema.sObjectType.Contact.fields.Phone.isAccessible() && contact.Phone != null) ? contact.Phone : '';
            this.mobilePhoneCC = (Schema.sObjectType.Contact.fields.Mobile_Phone_Country_Code__c.isAccessible() && contact.Mobile_Phone_Country_Code__c != null) ? contact.Mobile_Phone_Country_Code__c : '';
            this.mobilePhone = (Schema.sObjectType.Contact.fields.MobilePhone.isAccessible() && contact.MobilePhone != null) ? contact.MobilePhone : '';
            this.businessAddress = (Schema.sObjectType.Contact.fields.MailingAddress.isAccessible() && contact.MailingAddress != null) ? contact.MailingStreet+','+contact.MailingCity+','+contact.MailingState+','+contact.MailingCountry+' - '+contact.MailingPostalCode : '';
            this.homeAddress = (Schema.sObjectType.Contact.fields.OtherAddress.isAccessible() && contact.OtherAddress != null) ? contact.OtherStreet+','+contact.OtherCity+','+contact.OtherState+','+contact.OtherCountry+' - '+contact.OtherPostalCode : '';
            this.assistantEmail = (Schema.sObjectType.CampaignMember.fields.Assistant_Email__c.isAccessible() && mem.Assistant_Email__c != null) ? mem.Assistant_Email__c : '';
            this.correspondenceDearLine = (Schema.sObjectType.Contact.fields.CorrespondenceDearLine__c.isAccessible() && contact.CorrespondenceDearLine__c != null) ? contact.CorrespondenceDearLine__c : '';
            this.salutationSpouse = contact.Primary_Spouse__c ? 'TRUE' : 'FALSE';
            this.listMemberOutreachMethod = (Schema.sObjectType.CampaignMember.fields.ListMemberOutreachMethod__c.isAccessible() && mem.ListMemberOutreachMethod__c != null) ? mem.ListMemberOutreachMethod__c : '';
            this.listMemberPreferredEmail = (Schema.sObjectType.CampaignMember.fields.ListMemberPreferredEmail__c.isAccessible() && mem.ListMemberPreferredEmail__c != null) ? mem.ListMemberPreferredEmail__c : '';
            this.listMemberPreferredMailAddress = (Schema.sObjectType.CampaignMember.fields.Preferred_Address__c.isAccessible() && mem.Preferred_Address__c != null) ? mem.Preferred_Address__c : '';
            this.listMemberId = mem.Id;
            this.ContactAlertReason = (Schema.sObjectType.Contact.fields.Contact_Alert_Reason__c.isAccessible() && contact.Contact_Alert_Reason__c != null) ? contact.Contact_Alert_Reason__c : '';
            
            getTagsString (contact.Tags__r);
        }
        
        public void getTagsString (List<Tag_Junction__c> tags) {
            Set<String> ffTags = new Set<String> ();
            Set<String> otherTags = new Set<String> ();
            List<String> ffTagsList = new List<String> ();
            List<String> otherTagsList = new List<String> ();
            
            for(Tag_Junction__c tag: tags) {
                if(tag.Tag__r.Name.containsIgnoreCase('F&F')) {
                    ffTags.add(tag.Tag__r.Name);
                } else {
                    otherTags.add(tag.Tag__r.Name);
                }
            }
            
            otherTagsList.addAll(otherTags);
            ffTagsList.addAll(ffTags);
            
            this.ffTags = String.join(ffTagsList, ', ');
            this.otherTags = String.join(otherTagsList, ', ');
        }
    }
    
    public static Map<Id, AssistantWrapper> getAssistanceData(Set<Id> contactIds,Set<Id> significantOtherIds) {
        try{ 
            contactIds.addAll(significantOtherIds);
            Map<String, Related_Contact__c> relatedContacts = new Map<String, Related_Contact__c>();
            
            Map<Id, AssistantWrapper> assistanceMap = new Map<Id, AssistantWrapper>();
            relatedContacts = EventMangementAuraCtrl.getAssistantByContact(new List<Id>(contactIds));
            Boolean hasRestrictedAccess = FeatureManagement.checkPermission('Private_Name_Fields');
            for (String contactId : contactIds) {
                Related_Contact__c relatedContact = relatedContacts.get(contactId);
                if (relatedContact != null) {
                    if(hasRestrictedAccess){
                        assistanceMap.put(contactId, new AssistantWrapper(relatedContact.Related_Contact__r.Restricted_Name__c, relatedContact.Related_Contact__r.Alternate_Email__c, relatedContact.Related_Contact__r.Email,
                                                                          relatedContact.Related_Contact__r.Phone, relatedContact.Related_Contact__r.MobilePhone, relatedContact.Relationship__c));
                    }else { 
                        assistanceMap.put(contactId, new AssistantWrapper(relatedContact.Related_Contact__r.Name, relatedContact.Related_Contact__r.Alternate_Email__c, relatedContact.Related_Contact__r.Email,
                                                                          relatedContact.Related_Contact__r.Phone, relatedContact.Related_Contact__r.MobilePhone, relatedContact.Relationship__c));
                    }
                }
            }
            return assistanceMap;
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_ASSISTANCE_DATA)); 
            return null;
        } 
    }
    
    private static void setAssistants(Map<String, Related_Contact__c> relatedContacts, Map<String, Related_Contact__c> assistants) {
        for (String assist : assistants.keySet()) {
            relatedContacts.put(assist, assistants.get(assist));
        }
    }
    
    public class ContactRestrictedSort implements Comparator<Contact> {
        public Integer compare(Contact a, Contact b) {
            // Pick which name to use based on condition
            //String nameA = (a.LastName == '#') ? a.RestrictedLastName__c : a.LAST_Preferred_Last_Name__c;
            //String nameB = (b.LastName == '#') ? b.RestrictedLastName__c : b.LAST_Preferred_Last_Name__c;
            
            String nameA = a.LAST_Preferred_Last_Name__c;
            String nameB = b.LAST_Preferred_Last_Name__c;
            // Handle nulls
            if (nameA == null && nameB == null) return 0;
            if (nameA == null) return 1;
            if (nameB == null) return -1;
            
            // Convert both to lowercase for case-insensitive compare
            return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        }
    }
}