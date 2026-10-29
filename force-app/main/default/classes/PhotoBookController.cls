/**
* Date Modified: 08/24/26
* Description : Controller for managing and retrieving contacts and organizations for the PhotoBook application.
* Modified By : Hardik - BRME-5326 : changed code to display Country, State, City for Photobookintern
*                        BRME 5335: Photo Book Department values to include
                Nishant - BRME-6928: Updated Logic to merge the PhotoBooks and drive the generation of the photobook
                                     based on the criteria provided by the user
* Test Class: PhotoBookControllerTest
*/
public without sharing class PhotoBookController {
    private final static Environment_Setting__mdt environmentSettings = Environment.getEnvironmentSetting();
    private final static Set<String> EXCLUDED_DEPARTMENTS = new Set<String>(System.Label.Pricebook_ExcludedDepartments.split(','));
    public static String MYSTERY_PERSON = PageReference.forResource('MysteryPerson').getUrl();
    public String internListName {get; set;}
    public Criteria criteria {get; set;}
    public transient List<List<PhotoBookContact>> contactRows;
    public transient List<List<PhotoBookContact>> headerRows;
    private static List<String> photoBookSettingTypes =
        new List<String>{'BP Org', 'HR Dept Color', 'Org Department', 'HR Org Color', 'Intern List'};
    private final static String BLACK_COLOR_CODE = '000000';
    private final static String BP_ORG_COVER_COLOR = '5D008D';
    private final static String BP_ASSOCIATES_COLOR = 'DE6626';
    private final static String WHITE_COLOR_CODE = 'FFFFFF';

    private static final String ERR_GENERATE_HR_CONTACT = 'PHOTO_BOOK_CONTROLLER_GENERATE_HR_CONTACT_FAILED';
    private static final String ERR_GET_INTERN_CONTACT = 'PHOTO_BOOK_CONTROLLER_GET_INTERN_CONTACT_FAILED';
    private static final String ERR_PROCESS_DEPARTMENTS = 'PHOTO_BOOK_CONTROLLER_PROCESS_DEPARTMENTS_FAILED';
    private static final String ERR_COMPARE_TO = 'PHOTO_BOOK_CONTROLLER_COMPARE_TO_FAILED';
    private static final String ERR_LOAD_CRITERIA = 'PHOTO_BOOK_CONTROLLER_LOAD_CRITERIA_FAILED';
    private static final String ERR_COUNT_MATCHES = 'PHOTO_BOOK_BUILDER_COUNT_MATCHES_FAILED';

    @TestVisible
    private static Boolean forceException = false;

    public class PhotoBookContact implements Comparable {
        public Contact c {get; set;}
        public String color {get; set;}
        public String imageUrl {get; set;}
        public Boolean rendered {get; set;}
        public List<SelectOption> displayFields {get; set;}

        public PhotoBookContact() {
            c = new Contact();
            imageUrl = '';
            color = WHITE_COLOR_CODE;
            rendered = true;
            displayFields = new List<SelectOption>();
        }

        public PhotoBookContact(Contact con, String iUrl) {
            this();
            c = con;
            imageUrl = iUrl;
        }

        public Integer compareTo(Object compareTo) {
            try {
                PhotoBookContact other = (PhotoBookContact) compareTo;
                if(c.Department__c > other.c.Department__c) return 1;
                if(c.Department__c < other.c.Department__c) return -1;
                return 0;
            } catch(Exception ex) {
                BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_COMPARE_TO));
                return 0;
            }
        }
    }

    public class Criteria {
        public String title1 {get; set;}
        public String title2 {get; set;}
        public String coverColor {get; set;}
        public Boolean groupByDepartment {get; set;}
        public List<Id> orgIds {get; set;}
        public List<String> departments {get; set;}
        public Integer startedFromYear {get; set;}
        public String employmentOrg {get; set;}
        public List<Keyword> keywords {get; set;}
        public List<String> cardFields {get; set;}

        public Boolean hasOrgFilter() {
            return orgIds != null && !orgIds.isEmpty();
        }

        public Boolean hasDepartmentFilter() {
            return departments != null && !departments.isEmpty();
        }
    }

    public class Keyword {
        public String field {get; set;}
        public String value {get; set;}
    }

    public PhotoBookController() {
        Map<String, String> params = ApexPages.currentPage() == null
                                     ? new Map<String, String>()
                                     : ApexPages.currentPage().getParameters();
        String requestId = params.get('requestId');
        if(String.isNotBlank(requestId)) {
            criteria = loadFromRequest(requestId);
        }
    }

    public List<List<PhotoBookContact>> getContactRows() {
        buildPageData();
        return contactRows;
    }

    public List<List<PhotoBookContact>> getHeaderRows() {
        buildPageData();
        return headerRows;
    }

    private void buildPageData() {
        if(contactRows == null) build();
    }

    public String getPhotoURL(String htmlString) {
        String domainUrl = environmentSettings.BaseURLPrefix__c;
        if(String.isBlank(htmlString)) return MYSTERY_PERSON;
        Integer startIndex = htmlString.indexOf(domainUrl);
        Integer endIndex = htmlString.indexOf('"', startIndex + 1);
        if(startIndex != -1 && endIndex != -1) {
            return htmlString.substring(startIndex, endIndex).unescapeHtml4();
        }
        return MYSTERY_PERSON;
    }

    public List<PhotoBookContact> getInternContacts() {
        try {
            if(Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<PhotoBookContact> contactList = new List<PhotoBookContact> ();
            Set<Id> listIds = new Set<Id> ();
            for(Photo_Book_Setting__c pbs : [SELECT Id, List__c
                                             FROM Photo_Book_Setting__c
                                             WHERE Type__c IN ('Intern List')
                                             WITH SYSTEM_MODE
                                             ORDER BY Order__c]) {

                listIds.add(pbs.List__c);
            }
            Set<Id> contactIds = new set<Id> ();
            for(CampaignMember m : [SELECT Id, ContactId, Campaign.Name FROM CampaignMember WHERE CampaignId IN :listIds WITH SYSTEM_MODE]) {
                internListName = m.Campaign.Name;
                contactIds.add(m.ContactId);
            }
            String queryString = 'SELECT Id, AccountId, Account.Name, Favorite_Volunteer_Job_Experience__c, What_is_your_dream_job__c, ' +
                                       ' Department__c, Suffix, First_Preferred_First_Name__c, OtherCity, OtherState,OtherCountry, FirstName, ' +
                                       ' LastName, Bio_Photo__c, ReducedImage__c , Employing_Entity__c, Started_In__c, Came_From__c, Key_Projects__c, ' +
                                       ' Key_Contact__c, Key_Contact__r.Name, Phone, Email, SkillKnowledgeArea__c, School_and_Major__c, ' +
                                       ' Skills_developed_during_Internship__c ' +
                                ' FROM Contact ' +
                                ' WHERE Id IN :contactIds ' +
                                ' WITH SYSTEM_MODE ' +
                                ' ORDER BY FirstName, LastName';
            for(Contact c : (List<Contact>)Database.query(queryString)) {
                PhotoBookContact hrc = new PhotoBookContact();
                hrc.c = c;
                hrc.color = BLACK_COLOR_CODE;
                hrc.imageUrl = getPhotoURL(c.Bio_Photo__c);
                contactList.add(hrc);
            }
            return contactList;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_INTERN_CONTACT));
            return null;
        }
    }

    public Criteria loadFromRequest(String requestId) {
        try {
            if(!(requestId instanceof Id)) {
                return defaultCriteria();
            }
            List<PhotoBook_Request__c> requests = [
                SELECT Id, Filter_Criteria_JSON__c
                FROM PhotoBook_Request__c
                WHERE Id = :requestId
                WITH SYSTEM_MODE
                LIMIT 1];
            if(requests.isEmpty()) return defaultCriteria();
            Criteria loaded = parseCriteria(requests[0].Filter_Criteria_JSON__c);
            return loaded == null ? defaultCriteria() : loaded;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_LOAD_CRITERIA));
            return defaultCriteria();
        }
    }

    private static Criteria defaultCriteria() {
        Criteria c = new Criteria();
        c.title1 = 'Bloomberg';
        c.title2 = 'Philanthropies';
        c.coverColor = BP_ORG_COVER_COLOR;
        c.groupByDepartment = true;
        c.orgIds = new List<Id>();
        c.departments = new List<String>();
        c.keywords = new List<Keyword>();
        c.cardFields = new List<String>{
            'Key_Projects__c', 'Key_Contact__c', 'Started_In__c', 'Came_From__c'
        };
        return c;
    }

    private static Criteria parseCriteria(String body) {
        if(String.isBlank(body)) return null;
        Criteria c = (Criteria)JSON.deserialize(body, Criteria.class);
        applyWillettOrgBranding(c);
        Criteria d = defaultCriteria();
        if(String.isBlank(c.title1)) c.title1 = d.title1;
        if(String.isBlank(c.title2)) c.title2 = d.title2;
        if(String.isBlank(c.coverColor)) c.coverColor = d.coverColor;
        if(c.groupByDepartment == null) c.groupByDepartment = d.groupByDepartment;
        if(c.orgIds == null) c.orgIds = d.orgIds;
        if(c.departments == null) c.departments = d.departments;
        if(c.keywords == null) c.keywords = d.keywords;
        if(c.cardFields == null) c.cardFields = d.cardFields;
        return c;
    }

    private static void applyWillettOrgBranding(Criteria c) {
        if(c.orgIds == null || c.orgIds.size() != 1) return;
        if(c.orgIds[0] != environmentSettings.OrgWillet__c) return;
        c.title1 = 'Willett';
        c.title2 = 'Advisors';
        c.coverColor = BLACK_COLOR_CODE;
    }

    //Builds the photo book data based for non-intern photobooks
    private void build() {
        contactRows = new List<List<PhotoBookContact>>();
        headerRows = new List<List<PhotoBookContact>>();
        try {
            if(Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            List<PhotoBookContact> people = selectPeople(criteria);
            for(PhotoBookContact hrc : people) {
                hrc.imageUrl = getPhotoURL(hrc.c.Bio_Photo__c);
                populateDisplayFields(hrc, criteria.cardFields);
            }
            contactRows = chunk(people, 2, BLACK_COLOR_CODE);
            headerRows = buildDepartmentHeaderRows(getUniqueDepartments(people));
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GENERATE_HR_CONTACT));
        }
    }

    private static void populateDisplayFields(PhotoBookContact hrc, List<String> selectedFields) {
        hrc.displayFields = new List<SelectOption>();
        if(hrc.c == null || selectedFields == null || selectedFields.isEmpty()) return;
        Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
        for(String apiName : selectedFields) {
            Schema.DescribeFieldResult dfr = contactFields.get(apiName).getDescribe();
            if(!dfr.isAccessible()) continue;
            Object value = hrc.c.get(apiName);
            if(value == null) continue;
            if(String.isBlank(String.valueOf(value))) continue;
            hrc.displayFields.add(new SelectOption(String.valueOf(value), dfr.getLabel()));
        }
    }

    /**
     * Description: Method to fetch the contacts that will be included in the PhotoBook based on the criteria provided.
     *              It applies filters for organizations, departments, and keywords.
    **/
    private static List<PhotoBookContact> selectPeople(Criteria criteria) {
        Map<String, String> departmentColorMap = new Map<String, String>();
        Map<String, String> orgColorMap = new Map<String, String>();
        Map<String, Set<String>> orgIncludedDeparts = new Map<String, Set<String>>();
        List<Id> orgIds = new List<Id>();
        Boolean onlyWillett = criteria.orgIds != null && criteria.orgIds.size() == 1 &&
                              criteria.orgIds[0] == environmentSettings.OrgWillet__c;
        for(Photo_Book_Setting__c pbs : [
            SELECT Account__c, Account__r.Name, Color__c, Type__c, Department__c
            FROM Photo_Book_Setting__c
            WHERE Type__c IN :photoBookSettingTypes
            WITH SYSTEM_MODE
            ORDER BY Order__c
        ]) {
            if(pbs.Type__c == 'BP Org') {
                orgIds.add(pbs.Account__c);
            } else if(pbs.Type__c == 'HR Dept Color') {
                departmentColorMap.put(pbs.Department__c, pbs.Color__c);
            } else if(pbs.Type__c == 'HR Org Color') {
                if('Bloomberg Associates'.equals(pbs.Account__r.Name)) {
                    orgColorMap.put(pbs.Account__c, pbs.Color__c);
                }
            } else if(pbs.Type__c == 'Org Department') {
                if(!orgIncludedDeparts.containsKey(pbs.Account__c)) {
                    orgIncludedDeparts.put(pbs.Account__c, new Set<String>());
                }
                orgIncludedDeparts.get(pbs.Account__c).add(pbs.Department__c);
            }
        }
        if(criteria.hasOrgFilter()) {
            /*Set<Id> requestedOrgIds = new Set<Id>(criteria.orgIds);
            List<Id> filteredOrgIds = new List<Id>();
            for(Id orgId : orgIds) {
                if(requestedOrgIds.contains(orgId)) filteredOrgIds.add(orgId);
            }*/
            orgIds = new List<Id>(criteria.orgIds);
        }
        Set<String> departmentFilter = criteria.hasDepartmentFilter()
                                       ? new Set<String>(criteria.departments)
                                       : null;
        List<PhotoBookContact> ceoContacts = new List<PhotoBookContact>();
        List<PhotoBookContact> bpaContacts = new List<PhotoBookContact>();
        List<PhotoBookContact> emptyDeptContacts = new List<PhotoBookContact>();
        List<PhotoBookContact> people = new List<PhotoBookContact>();
        Boolean isGroupByDepartment = criteria.groupByDepartment;
        String orderByClause = isGroupByDepartment
            ? ' ORDER BY Department__c, FirstName, LastName'
            : ' ORDER BY FirstName, LastName';
        String queryString = 'SELECT ' + String.join(getPhotoBookQueryFields(), ', ') +
                            ' FROM Contact ' +
                            ' WHERE AccountId IN :orgIds ' +
                              ' AND Exclude_From_Photobook__c = false ' +
                             employmentClause(criteria.startedFromYear, criteria.employmentOrg) +
                            ' WITH SYSTEM_MODE ' +
                             orderByClause;

        for(Contact c : (List<Contact>)Database.query(queryString)) {
            if(EXCLUDED_DEPARTMENTS.contains(c.Department__c)) continue;
            if(departmentFilter != null && !departmentFilter.contains(c.Department__c)) {
                continue;
            }
            if(criteria.keywords != null && !criteria.keywords.isEmpty() && !matchesKeywords(c, criteria.keywords)) {
                continue;
            }
            if(!onlyWillett && orgIncludedDeparts.containsKey(c.AccountId) &&
               !orgIncludedDeparts.get(c.AccountId).contains(c.Department__c)) {

                continue;
            }
            PhotoBookContact hrc = new PhotoBookContact();
            hrc.c = c;
            hrc.color = orgColorMap.get(c.AccountId)
                        ?? departmentColorMap.get(c.Department__c)
                        ?? BLACK_COLOR_CODE;
            if(isGroupByDepartment && 'CEO'.equals(c.Department__c)) {
                ceoContacts.add(hrc);
                continue;
            }
            if(isGroupByDepartment && 'BP Administration'.equals(c.Department__c)) {
                bpaContacts.add(hrc);
                continue;
            }
            Boolean isWillettContact = (c.AccountId == environmentSettings.OrgWillet__c);
            if(isGroupByDepartment && String.isBlank(c.Department__c) && isWillettContact == onlyWillett) {
                emptyDeptContacts.add(hrc);
                continue;
            }
            people.add(hrc);
        }
        if(isGroupByDepartment) {
            List<PhotoBookContact> ordered = new List<PhotoBookContact>();
            ordered.addAll(ceoContacts);
            ordered.addAll(bpaContacts);
            ordered.addAll(people);
            ordered.addAll(emptyDeptContacts);
            people = ordered;
        }
        return people;
    }

    private static List<String> getPhotoBookQueryFields() {
        Set<String> queryFields = new Set<String>{'Id', 'AccountId', 'Account.Name', 'Department__c', 'FirstName', 'Languages_Spoken__c',
                                                  'LastName', 'Bio_Photo__c', 'Employing_Entity__c', 'SkillKnowledgeArea__c'};
        Schema.FieldSet fieldSet = Schema.SObjectType.Contact.fieldSets.getMap().get('PhotoBook_Fields_To_Show');
        if(fieldSet == null) return new List<String>(queryFields);
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Contact.fields.getMap();
        for(Schema.FieldSetMember member : fieldSet.getFields()) {
            String apiName = member.getFieldPath();
            Schema.SObjectField field = fields.get(apiName);
            if(!field.getDescribe().isAccessible()) continue;
            queryFields.add(apiName);
        }
        return new List<String>(queryFields);
    }

    /**
     * Description: Get the SOQL clause for filtering contacts based on the related Employment_History_and_Board_Membership__c records
    **/
    private static String employmentClause(Integer fromYear, String employmentOrg) {
        if(fromYear == null && String.isBlank(employmentOrg)) return '';
        String queryClause = ' AND Id IN (SELECT Contact_Name__c ' +
                                        ' FROM Employment_History_and_Board_Membership__c ' +
                                        ' WHERE Contact_Name__c != null ';
        if(employmentOrg != null && !String.isBlank(employmentOrg)) {
            queryClause += ' AND Organization_Name__c = \'' + employmentOrg + '\' ';
        } else {
            queryClause += ' AND Organization_Name__c IN :orgIds ';
        }
        if(fromYear != null) queryClause += ' AND To__c = null AND From__c >= \'' + fromYear + '\' ';
        return queryClause + ' )';
    }

    /**
    * Description: Returns count to display on the PhotoBookBuilder LWC
    **/
    @AuraEnabled(cacheable=true)
    public static Integer countMatches(String criteriaJson) {
        try {
            Criteria c = parseCriteria(criteriaJson);
            if(c == null) c = defaultCriteria();
            return selectPeople(c).size();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_COUNT_MATCHES));
            throw new AuraHandledException('Unable to count the matching employees.' + ex.getMessage());
        }
    }

    /**
    * Description: Returns a sorted list of PhotoBookContact objects representing the first contact for each unique department
    **/
    private List<PhotoBookContact> getUniqueDepartments(List<PhotoBookContact> people) {
        Set<String> seen = new Set<String>();
        List<PhotoBookContact> result = new List<PhotoBookContact>();
        for(PhotoBookContact hrc : people) {
            if(String.isNotBlank(hrc.c.Department__c) && !seen.contains(hrc.c.Department__c)) {
                seen.add(hrc.c.Department__c);
                result.add(hrc);
            }
        }
        result.sort();
        return result;
    }

    /**
    * Description: Filters matching keywords in Long Text Area fields.
    **/
    private static Boolean matchesKeywords(Contact c, List<Keyword> valid) {
        for(Keyword k : valid) {
            Object raw = c.get(k.field);
            if(raw == null) return false;
            if(!String.valueOf(raw).containsIgnoreCase(k.value)) return false;
        }
        return true;
    }

    /**
    * Description: Splits a list of PhotoBook contacts into rows of a specified size and pads the final row
    *               with non-rendered placeholder contacts to maintain a consistent layout in the generated Photo Book.
    * Parameters: items The list of PhotoBookContact objects to be chunked.
    *             perRow The number of contacts per row.
    *             padColor The color code for the placeholder contacts.
    **/
    private List<List<PhotoBookContact>> chunk(List<PhotoBookContact> items, Integer perRow, String padColor) {
        List<List<PhotoBookContact>> rows = new List<List<PhotoBookContact>>();
        List<PhotoBookContact> row = new List<PhotoBookContact>();
        if(items == null || items.isEmpty()) return rows;
        for(PhotoBookContact hrc : items) {
            if(row.size() == perRow) {
                rows.add(row);
                row = new List<PhotoBookContact>();
            }
            row.add(hrc);
        }
        //Pad empty rows with placeholder PhotoBookContact objects to ensure consistent row sizes in the output
        //and hence has rendered = false
        while(row.size() < perRow) {
            PhotoBookContact pad = new PhotoBookContact();
            pad.c = new Contact();
            pad.color = padColor;
            pad.imageUrl = null;
            pad.rendered = false;
            row.add(pad);
        }
        rows.add(row);
        return rows;
    }

    /**
     * Description: Builds the header rows for the PhotoBook by placing the CEO and BP Admin first,
     *              followed by the rest of the departments sorted alphabetically.
     **/
    private List<List<PhotoBookContact>> buildDepartmentHeaderRows(List<PhotoBookContact> departments) {
        Map<String, String> labelByValue = getLabelByFieldName();
        PhotoBookContact ceo = null;
        PhotoBookContact bpa = null;
        List<PhotoBookContact> rest = new List<PhotoBookContact>();
        for(PhotoBookContact tmp : departments) {
            if('CEO'.equals(tmp.c.Department__c)) {
                ceo = tmp;
            } else if('BP Administration'.equals(tmp.c.Department__c)) {
                bpa = tmp;
            } else {
                String label = labelByValue.get(tmp.c.Department__c);
                if(label != null && label.startsWith('Bloomberg Associates -')) {
                    tmp.color = BP_ASSOCIATES_COLOR;
                }
                rest.add(tmp);
            }
        }
        List<PhotoBookContact> sorted = new List<PhotoBookContact>();
        if(ceo != null) sorted.add(ceo);
        if(bpa != null) sorted.add(bpa);
        sorted.addAll(rest);
        return chunk(sorted, 3, WHITE_COLOR_CODE);
    }

    //Gets the department name Contact.Department__c picklist field
    private Map<String, String> getLabelByFieldName() {
        Map<String, String> values = new Map<String, String>();
        for(Schema.PicklistEntry entry : Contact.Department__c.getDescribe().getPicklistValues()) {
            values.put(entry.getValue(), entry.getLabel());
        }
        return values;
    }
}