/****
@Description: THis class is used to generate data for word generation
**/
public with sharing class DocGenerationCtrl {
    public String createdByUser { get; set; }
    public String createdDateTime { get; set; }
    public String retURL { get; set; }
    public String shortListId { get; set; }
    public String docGenerateType { get; set; }
    public String contactIds { get; set; }
    public String listId { get; set; }
    public String access { get; set; }
    public String listName { get; set; }
    public String shortBio { get; set; }
    public String interaction { get; set; }
    public String rsvp { get; set; }
    public String event { get; set; }
    public String bioHeader { get; set; }
    public String actionName { get; set; }
    public String startDate { get; set; }
    public String endDate { get; set; }
    public String selectedFocusAreas { get; set; }
    public String selectedDonorContacts { get; set; }
    public String selectedDonorOrgs { get; set; }
    public String selectedDonorLists { get; set; }
    public String selectedProjects { get; set; }
    public String minAmount { get; set; }
    public String coverPage { get; set; }
    public String getActiveDonors { get; set; }
    public String sortBy { get; set; }
    public Boolean isFromQuickAction { get; set; }

    // New property to track if the current contact is restricted
    public Boolean isCurrentContactRestricted { get; set; }
    public integer restrictedContactCount { get; set; } 
    public String selectedSource { get; set; }

    private static final String ERR_CHECK_IF_CONTACT_IS_RESTRICTED = 'DOC_GENERATION_CTRL_CHECK_IF_CONTACT_IS_RESTRICTED_FAILED';

    public DocGenerationCtrl() {
    	String cntId = ApexPages.currentPage().getParameters().get('id');
        String tmpShortBio = ApexPages.currentPage().getParameters().get('short');
        actionName = ApexPages.currentPage().getParameters().get('actionName');
        listId = ApexPages.currentPage().getParameters().get('listId');
        retURL = ApexPages.currentPage().getParameters().get('retURL');
        docGenerateType = ApexPages.currentPage().getParameters().get('docGenerateType');
        String showInteraction = ApexPages.currentPage().getParameters().get('showInteraction');
        String includeListsEvents = ApexPages.currentPage().getParameters().get('includeListsEvents');
        String includeRSVPMembers = ApexPages.currentPage().getParameters().get('includeRSVPMembers');
        startDate = ApexPages.currentPage().getParameters().get('startDate');
        endDate = ApexPages.currentPage().getParameters().get('endDate');
        selectedFocusAreas = ApexPages.currentPage().getParameters().get('selectedOptions');
        selectedDonorContacts = ApexPages.currentPage().getParameters().get('selectedContacts');
        selectedDonorOrgs = ApexPages.currentPage().getParameters().get('selectedOrganizations');
        selectedDonorLists = ApexPages.currentPage().getParameters().get('selectedLists');
        selectedProjects = ApexPages.currentPage().getParameters().get('selectedProjects');
        minAmount = ApexPages.currentPage().getParameters().get('minAmount');
        coverPage = ApexPages.currentPage().getParameters().get('coverPage');
        getActiveDonors = ApexPages.currentPage().getParameters().get('getActiveDonors');
        sortBy = ApexPages.currentPage().getParameters().get('sortBy');
        selectedSource = ApexPages.currentPage().getParameters().get('selectedSource');
        String sourceParam = ApexPages.currentPage().getParameters().get('source');
        isFromQuickAction = (sourceParam != null && sourceParam.equalsIgnoreCase('quickaction')) ? true : false;
        if(includeListsEvents != null && includeListsEvents == 'yes') {
            interaction = 'yes';
            event = 'yes';
        } else {
            interaction = 'no';
            event = 'no';
        }

        if (includeRSVPMembers != null && includeRSVPMembers == 'yes') {
            rsvp = 'yes';
        } else {
            rsvp = 'no';
        }
        
        access = String.valueOf(Schema.sObjectType.Contact.fields.Confidential_Notes__c.isAccessible());
        
        if (String.isBlank(tmpShortBio)) {
            shortBio = 'false';
            bioHeader = 'Bio:';
        } else {
            shortBio = tmpShortBio == 'true' && Schema.sObjectType.Contact.fields.BoardBioNotes__c.isAccessible() ? 'true' : 'false';
            if(shortBio == 'true') bioHeader = 'Short Bio:';
        }
        
        if (actionName == 'bio') {
            bioHeader = 'Bio:';
        }
        
        if (String.isNotEmpty(listId) && listId != null) {
            shortListId = Id.valueOf(listId).to15();
            Campaign cam = [SELECT Name FROM Campaign WHERE Id = :listId WITH SYSTEM_MODE];
            listName = cam.Name;
        }
        
        if (String.isNotBlank(cntId)) {
            contactIds = JSON.serialize(cntId.split(';'));
            restrictedContactCount = GenerateBioReportAuraCtrl.getRestrictedContactForGenerateBio(cntId.split(';'));
        }
        else{
            restrictedContactCount = GenerateBioReportAuraCtrl.getRestrictedContactCount(listId);
        }
        
        createdByUser = getCreatedByUser();
        createdDateTime = getCreatedDate();
        // Check if the current contact is restricted
        isCurrentContactRestricted = checkIfContactIsRestricted(cntId);
        
    }
    
    
    private String getCreatedByUser() {
        User usr = [SELECT FirstName, LastName
            FROM User
                    WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE];
        return usr.FirstName + ' ' + usr.LastName;
    }
    
    private String getCreatedDate() {
        return Datetime.now().format();
    }
    
    // New method to check if the current contact is restricted
    private Boolean checkIfContactIsRestricted(String cntId) {
        try {
            if (String.isNotBlank(cntId)) {
            List<Contact> restrictedContacts = [SELECT Id, Restricted__c FROM Contact WHERE Id = :cntId AND Restricted__c = true  WITH SYSTEM_MODE LIMIT 1];
                
                // Check if the query returned any contacts
                if (!restrictedContacts.isEmpty()) {
                    Contact restrictedContact = restrictedContacts[0];
                    return restrictedContact.Restricted__c == true;
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_CHECK_IF_CONTACT_IS_RESTRICTED) );
        }
        return false; // Return false if cntId is blank or no restricted contact is found
    }
}