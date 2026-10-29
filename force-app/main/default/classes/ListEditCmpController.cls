/********************************************************************************
* Class Name  : ListEditCmpController
* Description : Apex controller powering the Campaign Member List Edit UI for Events Recordtype, including dynamic columns, data retrieval, inline edits, RSVP/email handling, exports, and significant-other guest logic.
* Test Class   : ListEditCmpControllerTest
*
********************************************************************************/
public without sharing class ListEditCmpController {
    private final static String DEFAULT_REC_TYPE = 'Default';
    private final static String DEFAULT_HEADERS = 'defaultHeaders';
    private final static String UPDATE_FIELDS = 'updateFields';
    private static final String MSG_NO_CAMPAIGN_ACCESS = 'You do not have access to this List.';
    private final static Map<String, SObjectField> MEMBER_FIELD_MAP = CampaignMember.sObjectType.getDescribe().fields.getMap();
    private final static Map<String, Map<String, Object>> SETTINGS = getSettings();
    private final static Map<String, String> ORDER_MAP = new Map<String, String>{
        'contactid' => 'Contact.Name',
        'fundraising_point_of_contact__c' => 'Fundraising_Point_of_Contact__r.Name',
        'fundraising_organization__c' => 'Fundraising_Organization__r.Name'
    };
    private final static Set<String> ATTEND_STATUS = new Set<String>{
        'Yes - In Person',
        'Yes - Virtually',
        'Did Not Attend'
    };

    //used for querying the names of fields with lookup id's, initalized in setLookupCol method
    private static Map<String, Map<Id, String>> nameLookupMap;
    public ListEditCmpController() {
        nameLookupMap = new Map<String, Map<Id, String>>();
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getUserInfo() {
        String userId = UserInfo.getUserId(); // current user
        User user = [SELECT ID, FirstName, LastName, Name, Title, Profile.Name,  Email From User WHERE ID =: userId WITH SYSTEM_MODE LIMIT 1];
        if(user.Profile.Name == 'System Administrator Custom' && Schema.sObjectType.Contact.fields.BoardBioNotes__c.isAccessible()) {
            return true;
        }
        return false;
    }
    @AuraEnabled(cacheable=true)
    public static List<Custom_List_View__c> getUserListView(String view) {
        String userId = UserInfo.getUserId(); // current user
        List<Custom_List_View__c>  records =  [SELECT ID, Name,Column__c From Custom_List_View__c WHERE CreatedById =: userId AND View__c =:view WITH SYSTEM_MODE order by CreatedDate DESC];
        return records;
    }
    @AuraEnabled
    public static void updateListView(String viewId,String selectedOptions) {
        Custom_List_View__c rec = new Custom_List_View__c();
        rec.Id = viewId;
        rec.Column__c = selectedOptions;
        update rec;
    }


    @AuraEnabled
    public static Object getListMembers(
        Id campaignId,
		List<String> fieldsList,
		List<String> exportList,
		Integer pageNum,
		String sortField,
		String sortDir,
		String searchTerm,
		Boolean isExport
    ) {
        if(String.isBlank(campaignId)) {
            throw new AuraHandledException('No campaign Id found');
        }
        System.debug('field list: '+fieldsList);
        ensureCampaignAccess(campaignId);
        Map<String, Object> listMap = new Map<String, Object>();
        Campaign camp = getCampaign(campaignId);
        listMap.put('list', camp);
        String recType = getRecordTypeName(camp);
        fieldsList = getFieldsList(fieldsList, recType, DEFAULT_HEADERS);
        pageNum = pageNum == null ? 0 : pageNum;
        listMap.put(
            'pageSize',
			SETTINGS.get(recType) != null
				? SETTINGS.get(recType).get('pageSize')
				: SETTINGS.get(DEFAULT_REC_TYPE).get('pageSize')
        );
        listMap.put('recType', recType);
        List<CampaignMember> dataList = getAllData(
            campaignId,
			fieldsList,
			sortField,
			sortDir,
			searchTerm,
			listMap
        );
        listMap.put('data', dataList);
        listMap.put('columns', getColumns(fieldsList));
        listMap.put('nameMap', getNameMap(dataList));
        listMap.put('listReportId', getListReportId());
        listMap.put('exportFields', getExportFields(recType));
        return listMap;
    }

    private static void ensureCampaignAccess(Id campaignId) {
        Map<Id, UserRecordAccess> accessByCampaignId = new Map<Id, UserRecordAccess>([
            SELECT RecordId, HasReadAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId()
              AND RecordId = :campaignId
        ]);

        UserRecordAccess access = accessByCampaignId.get(campaignId);
        if (access == null || !access.HasReadAccess) {
            throw new AuraHandledException(MSG_NO_CAMPAIGN_ACCESS);
        }
    }

    @AuraEnabled
    public static void saveListMembers(List<CampaignMember> membersList) {
        update membersList;
    }

    @AuraEnabled
    public static Map<String, Object> getEmailBody(Id recId, String fieldName) {
        try {
            String q = 'SELECT Id, CC_Addresses__c, BCC_Addresses__c, ' + fieldName +
                ' FROM CampaignMember ' +
                ' WHERE Id = :recId WITH SYSTEM_MODE';
            SObject sobj = Database.query(q).get(0);
            Map<String, Object> res = new Map<String, Object>();
            res.put('body', (String)sobj.get(fieldName));
            res.put('cc', (String)sobj.get('CC_Addresses__c'));
            res.put('bcc', (String)sobj.get('BCC_Addresses__c'));
            return res;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getFormattedSubject(Id recId, String subjectField) {
        try {
            if (String.isBlank(subjectField) ||
                !Schema.SObjectType.CampaignMember.fields.getMap().containsKey(subjectField)) {
                throw new AuraHandledException('Invalid subject field');
            }

            String query = 'SELECT UB_FirstName__c, UB_LastName__c, ' + subjectField +
                        ' FROM CampaignMember WHERE Id = :recId LIMIT 1';

            SObject cm = Database.query(query);
            return getSubjectLine(cm,subjectField);
        } catch (Exception e) {
            throw new AuraHandledException('Error while formatting subject: ' + e.getMessage());
        }
    }

    public static String getSubjectLine(SObject cm, String subjectField){

        String firstName = (String) cm.get('UB_FirstName__c');
        String lastName  = (String) cm.get('UB_LastName__c');
        String subject   = (String) cm.get(subjectField);
        if (subject == null) {
            return '';
        }
        String fullName = '';
        if (!String.isBlank(firstName)) {
            fullName = firstName;
        }
        if (!String.isBlank(lastName)) {
            fullName = fullName == '' ? lastName : fullName + ' ' + lastName;
        }
        if(FeatureManagement.checkPermission('Private_Name_Fields')){
            subject = subject.replaceAll('#', fullName);
        }
        return subject;
    }

    @AuraEnabled
    public static void updateRSVPStatus(String memberIds, String status, String attendedStatus) {
        List<CampaignMember> members = new List<CampaignMember>();
        for (
            String memberId : (List<String>) JSON.deserialize(
            memberIds,
        List<String>.class
            )
        ) {
            CampaignMember cm = new CampaignMember();
            cm.Id = memberId;
            if (String.isNotBlank(status)) {
                cm.RSVPStatus__c = 'None'.equalsIgnoreCase(status) ? '' : status;
            }
            if (String.isNotBlank(attendedStatus)) {
                cm.AttendedStatus__c = 'None'.equalsIgnoreCase(attendedStatus) ? '' : attendedStatus;
            }
            members.add(cm);
        }
        if (members.size() > 0) {
            update members;
        }
    }

    private static Id getListReportId() {
        List<Report> reports = [
			SELECT Id
			FROM Report
			WHERE Name = 'List with List Members WITH SYSTEM_MODE'
		];
        if(reports.isEmpty()) {
            return null;
        }
        return reports[0].Id;
    }

    private static Map<String, Map<Id, String>> getNameMap(
        List<CampaignMember> dataList
    ) {
        if(
            dataList == null ||
            dataList.isEmpty() ||
            nameLookupMap == null ||
            nameLookupMap.isEmpty()
        ) {
            return new Map<String, Map<Id, String>>();
        }

        Map<String, Set<Id>> objIdMap = new Map<String, Set<Id>>();
        Map<String, Set<String>> objToFieldMap = new Map<String, Set<String>>();
        for (CampaignMember mem : dataList) {
            for (String field : nameLookupMap.keySet()) {
                Id dataId = (Id) mem.get(field);
                if(dataId != null) {
                    String objName = dataId.getSObjectType().getDescribe().getName();
                    Set<Id> idSet = objIdMap.get(objName) != null
                        ? objIdMap.get(objName)
                        : new Set<Id>();
                    idSet.add(dataId);
                    objIdMap.put(objName, idSet);
                    Set<String> fieldSet = objToFieldMap.get(field) != null
                        ? objToFieldMap.get(field)
                        : new Set<String>();
                    fieldSet.add(field);
                    objToFieldMap.put(objName, fieldSet);
                }
            }
        }

        for (String objName : objIdMap.keySet()) {
            Set<Id> idSet = objIdMap.get(objName);
            String q = 'SELECT Id, ';
            q += 'contact'.equalsIgnoreCase(objName) ? 'Full_Name__c' : 'Name';
            q += ' FROM ' + objName + ' WHERE Id IN:idSet WITH SYSTEM_MODE';
            try {
                List<SObject> queryList = Database.query(q);
                for (Integer i = 0; i < queryList.size(); i++) {
                    SObject query = queryList.get(i);
                    String name = 'contact'.equalsIgnoreCase(objName)
                        ? (String) query.get('Full_Name__c')
                        : (String) query.get('Name');
                    if(!String.isBlank(name)) {
                        Set<String> fieldSet = objToFieldMap.get(objName);
                        if(fieldSet != null && !fieldSet.isEmpty()) {
                            for (String field : fieldSet) {
                                Map<Id, String> nameMap = nameLookupMap.get(field);
                                nameMap.put(query.Id, name);
                                nameLookupMap.put(field, nameMap);
                            }
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(e.getLineNumber() + '-' + e.getMessage());
            }
        }
        return nameLookupMap;
    }

    private static List<CampaignMember> getAllData(
        Id campaignId,
		List<String> fieldsList,
		String sortField,
		String sortDir,
		String searchTerm,
		Map<String, Object> listMap
    ) {
        String q = getQuery(campaignId, fieldsList, sortField, sortDir, searchTerm);
        List<CampaignMember> membersList = Database.query(q);
        listMap.put('dataSize', membersList.size());
        return membersList;
    }

    public static Integer getPageSize(String recType) {
        try {
            return SETTINGS.get(recType) != null
                ? Integer.valueOf(SETTINGS.get(recType).get('pageSize'))
                : Integer.valueOf(SETTINGS.get(DEFAULT_REC_TYPE).get('pageSize'));
        } catch (Exception e) {
            return 20;
        }
    }

    private static String getQuery(Id campaignId, List<String> fieldsList, String sortField, String sortDir, String searchTerm) {
        String q = 'SELECT Id, ContactId, Contact.DoNotCall,Contact.Restricted_Additional_Email__c, Contact.Restricted_Business_Email__c, Contact.Restricted_Name__c,Contact.Restricted__c,Contact.Account.Restricted__c,' +
                          'Contact.Restricted_Org_Name__c, Contact.Restricted_Personal_Email__c, Contact.RestrictedFirstName__c, Contact.RestrictedLastName__c, Contact.RestrictedMiddleName__c, Contact.RestrictedSalutation__c, Contact.RestrictedSuffix__c,' +
                           getFieldsQuery(fieldsList);
        q += ' FROM CampaignMember WHERE CampaignId = \'' + campaignId + '\'';
        if(!String.isBlank(searchTerm)) {
            q += getFilterQuery(fieldsList, searchTerm);
        }
        q += ' WITH SYSTEM_MODE';
        sortField = !String.isBlank(sortField) ? sortField : 'Name';
        sortField = ORDER_MAP.get(sortField.toLowerCase()) != null
                    ? ORDER_MAP.get(sortField.toLowerCase())
                    : sortField;
        sortDir = !String.isBlank(sortDir) ? sortDir : 'ASC';
        q += ' ORDER BY ' + sortField + ' ' + sortDir;
        q += 'ASC'.equalsIgnoreCase(sortDir) ? ' NULLS LAST' : ' NULLS FIRST';// WITH SECURITY_ENFORCED';
        return q;
    }

    public static List<Map<String, String>> getExportFields(String recType){
        Boolean hasPrivateNameFieldsAccess = FeatureManagement.checkPermission('Private_Name_Fields');
        List<Map<String, String>> exportFields = new List<Map<String, String>>();
        if(String.isBlank(recType) || SETTINGS.get(recType) == null){
            return exportFields;
        }
        List<String> fieldsList = (List<String>) SETTINGS.get(recType).get('exportHeaders');
        if(fieldsList == null || fieldsList.isEmpty()) return exportFields;
        for (Integer i = 0; i < fieldsList.size(); i++) {
            String fieldKey = fieldsList[i].trim().toLowerCase();
            if(!'id'.equals(fieldKey) && MEMBER_FIELD_MAP.get(fieldKey) != null &&
				MEMBER_FIELD_MAP.get(fieldKey).getDescribe().isAccessible()) {

                if(fieldKey == ('Contact_Private__c').toLowerCase() && !hasPrivateNameFieldsAccess) {
                    continue;
                }
                Schema.DescribeFieldResult fr = MEMBER_FIELD_MAP.get(fieldKey).getDescribe();
                Map<String, String> temp = new Map<String, String>{'label' => fr.getLabel(), 'value' => fieldsList[i]};
                exportFields.add(temp);
            }
        }
        return exportFields;
    }

    private static String getFieldsQuery(List<String> fieldsList) {
        String q = '';
        Set<String> dupeSet = new Set<String>();
        for (Integer i = 0; i < fieldsList.size(); i++) {
            String fieldKey = fieldsList[i].toLowerCase();
            if(
                !'id'.equals(fieldKey) &&
                !dupeSet.contains(fieldKey) &&
                MEMBER_FIELD_MAP.get(fieldKey) != null
            ) {
                if(!String.isBlank(q)) {
                    q += ',';
                }
                q += fieldsList[i];
                dupeSet.add(fieldKey);
            }
        }

        for (String key : EventMangementAuraCtrl.EMAIL_CB_MAP.keySet()) {
            String field = EventMangementAuraCtrl.EMAIL_CB_MAP.get(key);
            String fieldKey = field.toLowerCase();
            if(!dupeSet.contains(fieldKey)) {
                q += ', ' + field;
                dupeSet.add(fieldKey);
            }
        }

        for (String key : EventMangementAuraCtrl.EMAIL_STATUS_MAP.keySet()) {
            String field = EventMangementAuraCtrl.EMAIL_STATUS_MAP.get(key);
            String fieldKey = field.toLowerCase();
            if(!dupeSet.contains(fieldKey)) {
                q += ', ' + field;
                dupeSet.add(fieldKey);
            }
        }

        for (String key : EventMangementAuraCtrl.EMAIL_DATETIME_MAP.keySet()) {
            String field = EventMangementAuraCtrl.EMAIL_DATETIME_MAP.get(key);
            String fieldKey = field.toLowerCase();
            if(!dupeSet.contains(fieldKey)) {
                q += ', ' + field;
                dupeSet.add(fieldKey);
            }
        }
        return q;
    }

    public static String getFilterQuery(
        List<String> fieldsList,
    String searchTerm
    ) {
        String q = '';
        String likeSearchTerm = '%' + escapeForSoqlLike(searchTerm) + '%';
        List<String> filterClauses = new List<String>();
        for(String field : fieldsList) {
            String fieldKey = field.toLowerCase();
            if(MEMBER_FIELD_MAP.get(fieldKey) != null && 'STRING'.equals(String.valueOf(MEMBER_FIELD_MAP.get(fieldKey).getDescribe().getType()))) {
                filterClauses.add(field + ' LIKE \'' + likeSearchTerm + '\'');
            }
        }
        return filterClauses.isEmpty()
               ? ''
               : ' AND (' + String.join(filterClauses, ' OR ') + ')';
    }

    private static String escapeForSoqlLike(String value) {
        if(String.isBlank(value)) return '';
        String escapedValue = value.trim();
        // Escape single quotes to prevent SOQL breakage/injection.
        escapedValue = String.escapeSingleQuotes(escapedValue);
        // Escape LIKE wildcards so user input is treated as a literal search value.
        escapedValue = escapedValue.replace('%', '\\%');
        escapedValue = escapedValue.replace('_', '\\_');
        return escapedValue;
    }

    public static List<String> getFieldsList(List<String> fieldsList, String recType, String metaDataField) {
		Boolean hasPrivateNameFieldsAccess = FeatureManagement.checkPermission('Private_Name_Fields');
        if(fieldsList != null && !fieldsList.isEmpty()) return fieldsList;
        fieldsList = new List<String>();
        List<String> settingsList = SETTINGS.get(recType) != null
            ? (List<String>) SETTINGS.get(recType).get(metaDataField)
            : (List<String>) SETTINGS.get(DEFAULT_REC_TYPE).get(metaDataField);
        for(String field : settingsList) {
            if(MEMBER_FIELD_MAP.get(field.toLowerCase()) != null &&
               MEMBER_FIELD_MAP.get(field.toLowerCase()).getDescribe().isAccessible()) {

				if(field.toLowerCase() == ('Contact_Private__c').toLowerCase() && !hasPrivateNameFieldsAccess) {
                    continue;
                }
                fieldsList.add(field);
            }
        }
        return fieldsList;
    }

    private static List<Map<String, Object>> getColumns(List<String> fieldsList) {
        List<Map<String, Object>> colList = new List<Map<String, Object>>();
        colList.add(getEditCol());
        for (String field : fieldsList) {
            String key = field.toLowerCase();
            if(MEMBER_FIELD_MAP.get(key) != null && MEMBER_FIELD_MAP.get(key).getDescribe().isAccessible()) {
                colList.add(getCol(field, MEMBER_FIELD_MAP.get(key).getDescribe()));
            }
        }
        colList.add(getActionCol());
        return colList;
    }

    private static Map<String, Object> getEditCol() {
        Map<String, Object> col = new Map<String, Object>();
        col.put('type', 'button-icon');
        col.put('fixedWidth', 40);
        col.put(
            'typeAttributes',
        new Map<String, String>{ 'iconName' => 'utility:edit' }
        );
        return col;
    }

    private static Map<String, Object> getCol(String field, Schema.DescribeFieldResult fr) {
        Map<String, Object> colMap = new Map<String, Object>();
        String label = 'contactid'.equalsIgnoreCase(field)
            ? 'Donor Individual'
            : fr.getLabel();
        colMap.put('label', label);
        String fieldType = fr.getType() + '';
        if('Last_Email_Status__c'.equalsIgnoreCase(field)) {
            setEmailStatusCol(colMap, field);
        } else if('EventEmailBody__c'.equalsIgnoreCase(field)) {
            return getEmailCol();
        } else if('CC_Addresses__c'.equalsIgnoreCase(field) || 'BCC_Addresses__c'.equalsIgnoreCase(field)) {
            setAdditionalEmailColumn(colMap, field);
        } else if('PICKLIST'.equals(fieldType)) {
            setPicklistCol(colMap, field, fr);
        } else if(fr.isHtmlFormatted()) {
            setHtmlCol(colMap, field);
        } else if('REFERENCE'.equals(fieldType)) {
            setLookupCol(colMap, field, fr);
        } else if('MULTIPICKLIST'.equals(fieldType) || fieldType.containsIgnoreCase('DATE')) {
            setDateCol(colMap, field, fr);
        } else if('BOOLEAN'.equals(fieldType)) {
            setCheckboxCol(colMap, field);
        } else if('CURRENCY'.equals(fieldType)) {
            setCurrencyCol(colMap, field, fr);
        } else {
            setTextCol(colMap, field, fr);
        }
        colMap.put('hideDefaultActions', true);
        colMap.put('fieldType', fieldType);
        colMap.put('fieldApi', field);
        colMap.put('fieldName', field);
        colMap.put('sortable', fr.isSortable());
        return colMap;
    }

    private static Map<String, Object> getActionCol() {
        return new Map<String, Object>{
            'type' => 'action',
            'typeAttributes' => new Map<String, Object>{
                'rowActions' => new List<Map<String, String>>{
                    new Map<String, String>{
                        'label' => 'Edit Member',
                        'name' => 'viewMem'
                    }
                },
                'menuAlignment' => 'auto'
            }
        };
    }

    @testVisible
    private static Map<String, Object> getEmailCol() {
        return new Map<String, Object>{
            'type' => 'customIcon',
            'label' => 'Email Preview',
            'fieldApi' => 'EventEmailBody__c',
            'typeAttributes' => new Map<String, Object>{
                'value' => new Map<String, String>{ 'fieldName' => 'Id' },
                'iconId' => 'email',
                'iconName' => 'standard:email',
                'isHide' => true,
                'altText' => 'Email Preview',
                'title' => 'Email Preview',
                'emailMap' => new Map<String, String>{ 'fieldName' => 'myEmailMap' },
                'hasInvitation' => new Map<String, String>{
                    'fieldName' => 'Has_Invite_Email__c'
                },
                'hasReminder' => new Map<String, String>{
                    'fieldName' => 'Has_Reminder_Email__c'
                },
                'hasEmail' => new Map<String, String>{
                    'fieldName' => 'Has_Event_Email__c'
                },
                'saveTheDateStatus' => new Map<String, String>{
                    'fieldName' => 'Save_The_Date_Status__c'
                },
                'saveTheDateSent' => new Map<String, String>{
                    'fieldName' => 'Save_The_Date_Sent__c'
                },
                'invitationStatus' => new Map<String, String>{
                    'fieldName' => 'Invitation_Status__c'
                },
                'invitationSent' => new Map<String, String>{
                    'fieldName' => 'Invitation_Sent__c'
                },
                'reminderStatus' => new Map<String, String>{
                    'fieldName' => 'Reminder_Email_Status__c'
                },
                'reminderSent' => new Map<String, String>{
                    'fieldName' => 'Reminder_Email_Sent__c'
                },
                'emailStatus' => new Map<String, String>{
                    'fieldName' => 'Email_Status__c'
                },
                'emailSent' => new Map<String, String>{ 'fieldName' => 'Email_Sent__c' }
            }
        };
    }

    private static void setLookupCol(
        Map<String, Object> colMap,
    String key,
    Schema.DescribeFieldResult fr
    ) {
        colMap.put('type', 'lookup');
        Map<String, Object> attrMap = new Map<String, Object>();
        attrMap.put('value', new Map<String, String>{ 'fieldName' => key });
        attrMap.put('objectName', 'CampaignMember');
        attrMap.put('fieldName', key);
        attrMap.put('context', new Map<String, String>{ 'fieldName' => 'Id' });
        attrMap.put(
            'isHide',
        new Map<String, String>{ 'fieldName' => 'c__isHide_' + key }
        );
        colMap.put('typeAttributes', attrMap);
        nameLookupMap = nameLookupMap != null
            ? nameLookupMap
            : new Map<String, Map<Id, String>>();
        nameLookupMap.put(key, new Map<Id, String>());
    }

    private static void setTextCol(
        Map<String, Object> colMap,
    String key,
    Schema.DescribeFieldResult fr
    ) {
        colMap.put('fieldName', key);
      if('RSVPNotes__c'.equalsIgnoreCase(key) || 'GuestOf__c'.equalsIgnoreCase(key)) {
            colMap.put('editable', true);
        } else {
            colMap.put('editable', fr.isUpdateable());
        }
    }

    private static void setEmailStatusCol(
        Map<String, Object> colMap,
    String key
    ) {
        colMap.put('type', 'emailStatus');
        colMap.put('fieldName', key);
        colMap.put('editable', false);
        colMap.put(
            'typeAttributes',
        new Map<String, Object>{
            'value' => new Map<String, String>{ 'fieldName' => key }
        }
        );
    }

    private static void setAdditionalEmailColumn(Map<String, Object> colMap, String key) {
        colMap.put('type', 'additionalEmailLookup');
        colMap.put('fieldName', key);
        Map<String, Object> attrMap = new Map<String, Object>();
        attrMap.put('value', new Map<String, String>{ 'fieldName' => key });
        attrMap.put('context', new Map<String, String>{ 'fieldName' => 'Id' });
        attrMap.put('fieldName', key);
        colMap.put('typeAttributes', attrMap);
    }

    private static void setCurrencyCol(
        Map<String, Object> colMap,
    String key,
    Schema.DescribeFieldResult fr
    ) {
        colMap.put('fieldName', key);
        colMap.put('editable', fr.isUpdateable());
        colMap.put('type', 'currency');
        colMap.put(
            'typeAttributes',
        new Map<String, String>{
            'step' => '1',
            'maximumFractionDigits' => '0',
            'minimumFractionDigits' => '0'
        }
        );
    }

    private static void setCheckboxCol(Map<String, Object> colMap, String key) {
        colMap.put('type', 'checkbox');
        Map<String, Object> attrMap = new Map<String, Object>();
        attrMap.put('value', new Map<String, String>{ 'fieldName' => key });
        attrMap.put('context', new Map<String, String>{ 'fieldName' => 'Id' });
        attrMap.put('editable', key!='Contact_Private__c');
        attrMap.put('fieldName', key);
        colMap.put('typeAttributes', attrMap);
    }

    private static void setDateCol(
        Map<String, Object> colMap,
    String key,
    Schema.DescribeFieldResult fr
    ) {
        String frType = String.valueOf(fr.getType());
        frType = frType.toLowerCase();
        colMap.put('type', frType);
        Map<String, Object> attrMap = new Map<String, Object>();
        attrMap.put('value', new Map<String, String>{ 'fieldName' => key });
        attrMap.put('objectName', 'CampaignMember');
        attrMap.put('fieldName', key);
        attrMap.put('fieldType', frType);
        attrMap.put('context', new Map<String, String>{ 'fieldName' => 'Id' });
        colMap.put('typeAttributes', attrMap);
    }

    private static void setHtmlCol(Map<String, Object> colMap, String key) {
        colMap.put('type', 'html');
        Map<String, Object> attrMap = new Map<String, Object>();
        attrMap.put('value', new Map<String, String>{ 'fieldName' => key });
        colMap.put('typeAttributes', attrMap);
    }

    private static void setPicklistCol(
        Map<String, Object> colMap,
    String key,
    Schema.DescribeFieldResult fr
    ) {
        colMap.put('type', 'picklist');
        Map<String, Object> attrMap = new Map<String, Object>();
        attrMap.put('placeholder', 'Choose a value');
        attrMap.put('options', getPickListVals(fr.getPicklistValues()));
        attrMap.put('value', new Map<String, String>{ 'fieldName' => key });
        attrMap.put('context', new Map<String, String>{ 'fieldName' => 'Id' });
        attrMap.put('label', key);
        attrMap.put('showNone', true);
        colMap.put('typeAttributes', attrMap);
    }
    private static List<Map<String, String>> getPickListVals(
        List<Schema.PicklistEntry> listVals
    ) {
        if(listVals.isEmpty()) {
            return null;
        }
        List<Map<String, String>> pickList = new List<Map<String, String>>();
        Integer defaultIdx = 0;
        Integer i = 0;
        for (Schema.PicklistEntry ple : listVals) {
            if(ple.isActive()) {
                pickList.add(
                new Map<String, String>{
                    'label' => ple.getLabel() + '',
                    'value' => ple.getValue() + ''
                }
                );
                if(ple.isDefaultValue()) {
                    defaultIdx = i;
                }
                i++;
            }
        }
        if(defaultIdx != 0 && pickList.size() > 0) {
            Map<String, String> temp = pickList.get(0);
            pickList.add(0, pickList.get(defaultIdx));
            pickList.add(defaultIdx, temp);
        }
        return pickList;
    }

    private static Campaign getCampaign(Id campaignId) {
        return [
            SELECT Id, RecordType.DeveloperName, Name, NumberOfContacts, GuestsinEvent__c,
                   ExpectedAttendance__c, EventStatus__c, Contacts_Missing_Email_Count__c
            FROM Campaign
            WHERE Id = :campaignId WITH USER_MODE
        ];
    }

    private static String getRecordTypeName(Campaign camp) {
        try {
            String recType = camp?.RecordType?.DeveloperName;
            return !String.isBlank(recType) ? recType : '';
        } catch (Exception e) {
            System.debug(e.getLineNumber() + ' - ' + e.getMessage());
            return '';
        }
    }

    private static Map<String, Map<String, Object>> getSettings() {
        List<List_Edit_Settings__mdt> settings = [
			SELECT Id, Default_Headers__c,Export_Headers__c, Record_Type__c, Page_Size__c, Update_Info_Fields__c
			FROM List_Edit_Settings__mdt WITH SYSTEM_MODE
		];
        Map<String, Map<String, Object>> settingsMap = new Map<String, Map<String, Object>>();
        for (List_Edit_Settings__mdt setting : settings) {
            String recType = setting.Record_Type__c;
            Map<String, Object> setMap = settingsMap.get(recType) != null
                ? settingsMap.get(recType)
                : new Map<String, Object>();
            List<String> defaultHeaders = String.isNotBlank(setting.Default_Headers__c)
                ? setting.Default_Headers__c.split(',')
                : new List<String>();
            List<String> exportHeaders = String.isNotBlank(setting.Export_Headers__c)
                ? setting.Export_Headers__c.split(',')
                : new List<String>();
            List<String> updateFields = String.isNotBlank(setting.Update_Info_Fields__c)
            ? setting.Update_Info_Fields__c.split(',')
            : new List<String>();
            if('Pre_Event'.equalsIgnoreCase(recType)) {
				List<Custom_List_View__c> views = getUserListView(Assets.DESKTOPVIEW);
                if(views.size()>0 && String.isNotBlank(views[0].Column__c )) {
                    defaultHeaders = views[0].Column__c.split(',');
                }
            }
            setMap.put('exportHeaders', exportHeaders);
            setMap.put('defaultHeaders', defaultHeaders);
            setMap.put('updateFields', updateFields);
            setMap.put('pageSize', setting.Page_Size__c);
            settingsMap.put(recType, setMap);
        }
        return settingsMap;
    }

    @AuraEnabled
    public static String getMyDomain() {
        String urlInstance = String.valueof(System.URL.getOrgDomainUrl().toExternalForm());
        return urlInstance;
    }

    @AuraEnabled
    public static String addSignificantOther(String listId, List<String> selectedIds) {
        String retValue = '';
        Integer newGuests = 0;
        Integer significantOthersNotExists = 0;
        Map<Id, CampaignMember> campaignMembersMap = new Map<Id, CampaignMember>([Select Id, Name, ContactId, Contact.Significant_Other__c,
		Contact.Significant_Other__r.DoNotCall, Contact.Significant_Other__r.Name from CampaignMember
		where campaignId = :listId and Contact.DoNotCall = false WITH SYSTEM_MODE]);
        Integer totalGuests = campaignMembersMap.size();
        Integer selectedGuestCount = selectedIds.size();
        Set<Id> contactIds = new Set<Id>();
        for (CampaignMember campaignMember : campaignMembersMap.values()) {
            contactIds.add(campaignMember.ContactId);
        }
        Set<Id> significantOtherNotIncluded = new Set<Id>();
        String contactsNotAddedNames = '';
        Integer significantOtherAlreadyExists = 0;
        for (String campaignId : selectedIds) {
            CampaignMember tempCampaignMember = campaignMembersMap.get(campaignId);
            if(tempCampaignMember!= null && tempCampaignMember.Contact.Significant_Other__c != null && !contactIds.contains(tempCampaignMember.Contact.Significant_Other__c) && tempCampaignMember.Contact.Significant_Other__r.DoNotCall == false) {
                significantOtherNotIncluded.add(tempCampaignMember.Contact.Significant_Other__c);
            }
            if(tempCampaignMember!= null && tempCampaignMember.ContactId!=null &&  tempCampaignMember.Contact.Significant_Other__c !=null && tempCampaignMember.Contact.Significant_Other__r.DoNotCall == true) {
                contactsNotAddedNames += tempCampaignMember.Contact.Significant_Other__r.Name + ', ';
            }
            if(tempCampaignMember!= null && contactIds.contains(tempCampaignMember.Contact.Significant_Other__c)) {
                significantOtherAlreadyExists++;
            }
            if(tempCampaignMember!= null && tempCampaignMember.Contact.Significant_Other__c == null) {
                significantOthersNotExists++;
            }
        }
        contactsNotAddedNames = contactsNotAddedNames.removeEnd(', ');
        List<CampaignMember> newMembers = new List<CampaignMember>();
        for (Id contactId : significantOtherNotIncluded) {
            newMembers.add(new CampaignMember(campaignId = listId, ContactId = contactId));
        }
        if(!newMembers.isEmpty()) {
            retValue += newMembers.size() + ' Significant Other(s) have been added to this list.<br><br>';
            insert newMembers;
        }
        if(!String.isEmpty(contactsNotAddedNames)) {
            retValue += contactsNotAddedNames + ' not added due to a Do Not Contact alert.<br><br>';
        }
        if(significantOtherAlreadyExists > 0) {
            retValue += significantOtherAlreadyExists + ' Significant Other(s) are already on this list.<br><br>';
        }
        if(significantOthersNotExists > 0) {
            retValue += significantOthersNotExists + ' Guest(s) does not have a Siginificant Other in BRM.';
        }
        newGuests = newMembers.size();
        if(newGuests == 0) {
            totalGuests += newGuests;
        }
        return retValue;
    }

    public class RelatedContact {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String role { get; set; }
        @AuraEnabled public String org { get; set; }
        @AuraEnabled public String primary { get; set; }

        public RelatedContact(Id id, String email, String name, String role, String org,String primary) {
            this.id = id;
            this.email = email;
            this.name = name;
            this.role = role;
            this.org = org;
            this.primary = primary;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<RelatedContact> fetchStaffContacts(String listMemberId) {
        List<RelatedContact> relatedContactList = new List<RelatedContact>();
        List<CampaignMember> cms = [
			SELECT Id, ContactId, Contact.Significant_Other__r.Preferred_FirstName_LastName__c, Contact.Significant_Other__r.Email,
				   Contact.Significant_Other__r.Organization_Name_formula__c, Contact.Significant_Other__r.Restricted__c,
                   Contact.Significant_Other__r.Restricted_Name__c
			FROM CampaignMember
			WHERE Id = :listMemberId
			  AND Contact.Significant_Other__r.DoNotCall = false WITH SYSTEM_MODE
			LIMIT 1
		];
        Boolean hasPrivateNameFieldsAccess = FeatureManagement.checkPermission('Private_Name_Fields');
        if(!cms.isEmpty()) {
            List<Related_Contact__c> relatedContacts = [
				SELECT Id, Related_Contact__c, Related_Contact__r.Email, Related_Contact__r.Preferred_FirstName_LastName__c, Relationship__c,
                       Events_Primary_Staff_Contact__c, Related_Contact__r.Organization_Name_formula__c, Related_Contact__r.Restricted__c,
                       Related_Contact__r.Restricted_Name__c
				FROM Related_Contact__c
				WHERE Main_Contact__c = :cms[0].ContactId WITH SYSTEM_MODE
            ];
            if((cms[0].Contact.Significant_Other__r.Restricted__c == true && hasPrivateNameFieldsAccess) ||
                cms[0].Contact.Significant_Other__r.Restricted__c == false) {

                if(cms[0].Contact.Significant_Other__r.Email != '' && cms[0].Contact.Significant_Other__r.Email != null) {
                    String name = cms[0].Contact.Significant_Other__r.Restricted__c == true
                                  ? cms[0].Contact.Significant_Other__r.Restricted_Name__c
                                  : cms[0].Contact.Significant_Other__r.Preferred_FirstName_LastName__c;
                    relatedContactList.add(new RelatedContact(
                        cms[0].ContactId,
                        cms[0].Contact.Significant_Other__r.Email,
                        name,
                        'Spouse',
                        cms[0].Contact.Significant_Other__r.Organization_Name_formula__c,''
                    ));
                }
            }
            if(!relatedContacts.isEmpty()) {
                for(Related_Contact__c rc : relatedContacts) {
                    if((rc.Related_Contact__r.Restricted__c == true && hasPrivateNameFieldsAccess) ||
                        rc.Related_Contact__r.Restricted__c == false) {

                        if(rc.Related_Contact__r.Email != '' && rc.Related_Contact__r.Email != null) {
                            String name = rc.Related_Contact__r.Restricted__c == true
                                          ? rc.Related_Contact__r.Restricted_Name__c
                                          : rc.Related_Contact__r.Preferred_FirstName_LastName__c;
                            relatedContactList.add(new RelatedContact(
                                rc.Related_Contact__c,
                                rc.Related_Contact__r.Email,
                                name,
                                rc.Relationship__c,
                                rc.Related_Contact__r.Organization_Name_formula__c,
                                rc.Events_Primary_Staff_Contact__c == TRUE ? 'Primary Staffer' : ''
                            ));
                        }
                    }
                }
            }
        }
        return relatedContactList;
    }

    public class ResponseWrapper {
        @AuraEnabled public List<CampaignMember> members;
        @AuraEnabled public Map<String, Integer> rsvpCounts;
        @AuraEnabled public Map<String, Integer> attendanceCounts;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getCampaignMembers(Id campaignId) {

        if (campaignId == null) {
            throw new AuraHandledException('Campaign Id is required');
        }

        ResponseWrapper res = new ResponseWrapper();

        res.members = [
            SELECT Id,
                   RSVPStatus__c,
                   AttendedStatus__c,
                   UB_FirstName__c,
                   UB_LastName__c,
                   RSVPNotes__c,
                   PartySize__c,
                   Dietary__c,
                   Source__c,
                   GuestOf__c,
                   UB_Company__c,
                   Business_Phone__c,
                   Mobile_Phone__c,Campaign.EventStatus__c,Campaign.Name
            FROM CampaignMember
            WHERE CampaignId = :campaignId WITH SYSTEM_MODE
        ];

        res.rsvpCounts = new Map<String, Integer>();
        res.attendanceCounts = new Map<String, Integer>();

        for (CampaignMember cm : res.members) {

            if (cm.RSVPStatus__c != null) {
                res.rsvpCounts.put(
                    cm.RSVPStatus__c.toUpperCase(),
                    (res.rsvpCounts.get(cm.RSVPStatus__c.toUpperCase()) == null ? 0 : res.rsvpCounts.get(cm.RSVPStatus__c.toUpperCase())) + 1
                );
            }

            if (cm.AttendedStatus__c != null) {
                res.attendanceCounts.put(
                    cm.AttendedStatus__c.toUpperCase(),
                    (res.attendanceCounts.get(cm.AttendedStatus__c.toUpperCase()) == null ? 0 : res.attendanceCounts.get(cm.AttendedStatus__c.toUpperCase())) + 1
                );
            }
        }

        return res;
    }

    /**
	 * Description : BRME-6977: Method to get fields list from custom meta-data
	 * Parameters : String recordType (for the campaign object)
	 * Return Type : List<Map<String, Object>>
	 */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getUpdateFieldList(String recordType) {
        List<String> fieldsList = getFieldsList(null, recordType, UPDATE_FIELDS);
        List<Map<String, Object>> columns = getColumns(fieldsList);
        if(columns.size() >= 2){
            columns.remove(0);
            columns.remove(columns.size() - 1);
        }
        return columns;
    }

    /**
	 * Description : BRME-6977: Method to mass update guests info
	 * Parameters : memberIds String (Guests to update), fieldName String (the field to update), value String (new value for the field)
	 * Return Type : none
	 */
    @AuraEnabled
    public static void updateGuestInfo(String memberIds, String fieldName, String value) {
        List<CampaignMember> members = new List<CampaignMember>();
        for (String memberId : (List<String>) JSON.deserialize(memberIds, List<String>.class)) {
            CampaignMember cm = new CampaignMember();
            cm.Id = memberId;
            if (String.isNotBlank(fieldName)) {
                cm.put(fieldName, value);
            }
            members.add(cm);
        }
        if (members.size() > 0) {
            BBApps_Crud.doUpdate(
                members, true
            );
        }
    }
}