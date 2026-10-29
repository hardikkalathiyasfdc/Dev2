public without sharing class GenerateBioReportAuraCtrl {
    private static final String ERR_GET_CAN_ACCESS_SHORT_BIO = 'GENERATION_BIO_REPORT_AURA_CTRL_GET_CAN_ACCESS_SHORT_BIO_FAILED';

    @AuraEnabled(cacheable=true)
    public static String getExistingList() {
        String orgEngagedId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId();

        return JSON.serialize([SELECT Name, Id, ListMemberCount__c
                               FROM Campaign
                               WHERE RecordTypeId != :orgEngagedId WITH SYSTEM_MODE]);
    }

    @AuraEnabled(cacheable=true)
    public static Integer getContactWithPhotoCount(String listId) {
        Integer count = 0;
        return [SELECT Contact.Bio_Photo__c, Id
                FROM CampaignMember
                WHERE CampaignId = :listId WITH USER_MODE].size();
    }

    @AuraEnabled(cacheable=true)
    public static Integer getRSVPCount(String listId) {
        return [SELECT Contact.Bio_Photo__c, Id
                FROM CampaignMember
                WHERE CampaignId = :listId
                AND (RSVPStatus__c IN ('Yes', 'Yes - In Person', 'Yes - Virtually', 'Yes - Cocktails Only')
                     OR campaign.RecordType.Name!='Events') WITH USER_MODE
               ].size();
    }

    @AuraEnabled
    public static Integer getRestrictedContactCount(String listId) {
        return RestrictedRecordDetector.countRestrictedContactsInList(listId);
    }

    @AuraEnabled
    public static Integer getRestrictedContactCountFromLists(List<String> listIds) {
        return RestrictedRecordDetector.countRestrictedContactsInLists(listIds);
    }


    @AuraEnabled
    public static Integer getRestrictedContactForGenerateBio(List<String> contactIds) {
        return RestrictedRecordDetector.countRestrictedContacts(contactIds);
    }

    @AuraEnabled
    public static Integer getRestrictedOrgCount(List<String> orgIds) {
        return RestrictedRecordDetector.countRestrictedOrgs(orgIds);
    }

    @AuraEnabled
    public static Boolean getRestrictedContact(String contactId) {
        Integer count = [
            SELECT COUNT()
            FROM Contact
            WHERE Id = :contactId
            AND Restricted__c = TRUE
        ];

        // Return true if at least one record is found
        return (count > 0);
    }
    //Method to fetch Contacts based on the input search words.
    // 1. if search contains space, it will be splited to featch Firstname & Lastname individually
    // 2. if search doesn't contain space, it will search key as the whole string
    @AuraEnabled(cacheable=true)
    public static List<Contact> fetchLookUpValues(String searchKeyWord, List<Contact> ExcludeitemsList) {

        List<String> lstSearchWordsSplit = new List<String>();
        for(String str : searchKeyWord.split(' ')){
            String wordStr = '%' + str + '%';
            lstSearchWordsSplit.add(wordStr);
        }
        String searchKey = '%' + searchKeyWord + '%';
        List < Contact > returnList = new List < Contact > ();

        List<String> lstExcludeitems = new List<String>();
        for(Contact item : ExcludeitemsList ){
            lstExcludeitems.add(item.id);
        }

        String sQuery;
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 10 and exclude already selected records
        if(lstSearchWordsSplit != null && lstSearchWordsSplit.size()>1){
            String lastName = lstSearchWordsSplit[1];
            String firstName = lstSearchWordsSplit[0];
            sQuery =  'SELECT id, FirstName, LastName, Preferred_First_Name__c,Name,Title,Account.Name,Email FROM Contact WHERE LastName LIKE: lastName AND (Preferred_First_Name__c LIKE: firstName OR FirstName LIKE: firstName) AND Id NOT IN : lstExcludeitems ORDER BY createdDate DESC limit 10';
        }else{
            sQuery =  'SELECT id, FirstName, LastName, Preferred_First_Name__c,Name,Title,Account.Name,Email FROM Contact WHERE (Name LIKE: searchKey OR Preferred_First_Name__c LIKE: searchKey) AND Id NOT IN : lstExcludeitems ORDER BY createdDate DESC limit 10';
        }

        List<Contact> lstOfRecords = Database.query(sQuery);
        for (Contact obj: lstOfRecords) {
            returnList.add(obj);
        }

        return returnList;
    }

    @AuraEnabled(cacheable=true)
    public static String getBPOrgDefaults() {
        return JSON.serialize(Environment.getEnvironmentSetting());
    }

    @AuraEnabled(cacheable=true)
    public static String getCanAccessShortBio() {
        try {
            List<SetupEntityAccess> setupEntities = [
                SELECT SetupEntityId
                FROM SetupEntityAccess
                WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName='Access_Short_Bio') AND
                      ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId())];
            if(setupEntities.size() > 0) {
                return 'true';
            } else {
                return 'false';
            }
        } catch(Exception e) {
            BBApps_ErrorHandler.logErrors( e,new BBApps_ErrorCustomFields(ERR_GET_CAN_ACCESS_SHORT_BIO));
            return 'false';
        }
    }
}