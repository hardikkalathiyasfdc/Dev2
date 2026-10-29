public without sharing class AccountTriggerHandler  extends TriggerHandler {
    public List<Account> newAccounts;
    public List<Account> oldAccounts;
    public Map<Id, Account> oldMap;
    public Map<Id, Account> newMap;
    private List<Id> mergeWinningRecordIds;
    private Set<Id> orgsWithNameChange = new Set<Id> ();
    List<Id> accountIds;
    private static  List<Id> restrictedAccountIds = new List<Id>() ;
    private static final Map<String, String> BYPASS_MERGE_VALIDATION_FIELDS = UtilityClass.getFieldsByFieldSet('Account', 'Bypass_Merge_Validation_Fields');
    private static SObjectType schemaType = Schema.getGlobalDescribe().get('Account');
    private static Map<String, Schema.SObjectField> fieldMap = schemaType.getDescribe().fields.getMap();
    private static Set<String> systemFields = new Set<String> {
        'id','isdeleted','masterrecordid','recordtypeid','reportstoid','createddate','createdbyid','lastmodifieddate',
        'lastmodifiedbyid','systemmodstamp','lastactivitydate','lastcurequestdate','lastcuupdatedate','lastvieweddate',
        'lastreferenceddate','emailbounceddate','isemailbounced','emailbouncedreason','jigsaw','jigsawcontactid','individualid',
        'ispriorityrecord','sic','ownership','tickersymbol','jigsawcompanyid','sicdesc','ispriorityrecord'
    };
    private List<Id> orgIdsForBLinkSync = new List<Id>();
    private static final String ERR_SET_LAGACY_SOURCE= 'ACCOUNT_TRIGGER_HANDLER_SET_LAGACY_SOURCE_FAILED';
    private static final String ERR_BULK_BEFORE = 'ACCOUNT_TRIGGER_BULK_BEFORE_FAILED';
    private static final String ERR_BULK_AFTER = 'ACCOUNT_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_AND_FINALLY = 'ACCOUNT_TRIGGER_AND_FINALLY_FAILED';
    private static final String ERR_UPDATED_CONVERTED_NAMES = 'ACCOUNT_TRIGGER_UPDATED_CONVERTED_NAMES_FAILED';
    private static final String ERR_UPDATE_CONTACTS_BUSINESS_ADDRESS = 'ACCOUNT_TRIGGER_UPDATE_CONTACTS_BUSINESS_ADDRESS_FAILED';
    private static final String ERR_UPDATE_CONTACT_RESTRICTED_NAME = 'ACCOUNT_TRIGGER_UPDATE_CONTACT_RESTRICTED_NAME_FAILED';
    private static final String ERR_SYNC_ORG_ASSOCIATION_NAMES = 'ACCOUNT_TRIGGER_SYNC_ORG_ASSOCIATION_NAMES_FAILED';
    private static final String ERR_AFTER_MERGE = 'ACCOUNT_TRIGGER_HANDLER_AFTER_MERGE_FAILED';

    public AccountTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Account>)Trigger.oldMap, (Map<Id, Account>)Trigger.newMap);
    }

    public AccountTriggerHandler(List<Account> oldAccountList, List<Account> newAccountList) {
        newAccounts = newAccountList;
        oldAccounts = oldAccountList;
    }

    public AccountTriggerHandler(List<Account> oldAccountList, List<Account> newAccountList, Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        newAccounts = newAccountList;
        oldAccounts = oldAccountList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    //jlu scan for special characters in names
    public override void beforeInsert(SObject so) {
        Account curAcct = (Account)so;
        SpecialCharactersHelper.updateSpecialCharCheckbox(curAcct.Name, curAcct, 'Has_Special_Char_In_Name__c');
        curAcct.Converted_Org_Name__c = SpecialCharactersHelper.convertSpecialCharToEnglish(curAcct.Name);
        curAcct.Converted_AKA__c  = SpecialCharactersHelper.convertSpecialCharToEnglish(curAcct.AKA__c);
        curAcct.Converted_Legal_Name__c = SpecialCharactersHelper.convertSpecialCharToEnglish(curAcct.Legal_Name__c);
        updateRestrictedOrgName(curAcct, null);
    }

    //jlu scan for special characters in names
    public override void beforeUpdate(SObject oldSo, SObject so) {
        Account oldAcct = (Account)oldSo;
        Account curAcct = (Account)so;
        if(isFieldChanged(curAcct, 'Name')) {
            SpecialCharactersHelper.updateSpecialCharCheckbox(curAcct.Name, curAcct, 'Has_Special_Char_In_Name__c');
            curAcct.Converted_Org_Name__c = SpecialCharactersHelper.convertSpecialCharToEnglish(curAcct.Name);
        }
        if(isFieldChanged(curAcct, 'AKA__c')) {
        	curAcct.Converted_AKA__c = SpecialCharactersHelper.convertSpecialCharToEnglish(curAcct.AKA__c);
        }
        if(isFieldChanged(curAcct, 'Legal_Name__c')) {
            curAcct.Converted_Legal_Name__c = SpecialCharactersHelper.convertSpecialCharToEnglish(curAcct.Legal_Name__c);
        }
        if(curAcct.Restricted__c) {
             restrictedAccountIds.add(curAcct.Id);
        }
		updateRestrictedOrgName(curAcct, oldAcct);
    }

    public override void beforeDelete(SObject so) {
        Account acc = (Account)so;
        checkDeletePermision(acc);
        preventDeletionOfLinkedOrg(acc);
    }

    public override void bulkBefore() {
        try {
        if(Trigger.isInsert || Trigger.isupdate) {
            setPhone(newAccounts, oldMap);
            validateGovtOrgForGeoArea(newAccounts, oldMap);
        }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BULK_BEFORE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    public override void bulkAfter() {
        try {
            accountIds = new List<Id>();
            if(!Trigger.isDelete) {
                FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
            }
            if(Trigger.isDelete) {
                mergeWinningRecordIds = new List<Id>();
                for (Account a : oldAccounts) {
                    if(!String.isBlank(a.MasterRecordId)) {
                        mergeWinningRecordIds.add(a.MasterRecordId);
                        orgsWithNameChange.add(a.MasterRecordId);
                    }
                }
                afterMerge(new Set<Id>(mergeWinningRecordIds));
            } else if(Trigger.isInsert) {
                for (Account a : newAccounts) {
                    accountIds.add(a.Id);
                }
                syncWithBgive(newAccounts, newMap);
            } else if(Trigger.isUpdate) {
                for (Account a : newAccounts) {
                    if(a.BillingAddress != oldMap.get(a.Id)?.BillingAddress) {
                        accountIds.add(a.Id);
                    }
                    if(a.Name != oldMap.get(a.Id)?.Name) {
                        orgsWithNameChange.add(a.Id);
                    }
                }
                syncWithBgive(newAccounts,oldMap);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BULK_AFTER);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    // Method added for Blink Org sync
    public void syncWithBgive(List<Account> orgs, Map<Id, Account> oldMap) {
        List<String> fields = BLinkUtil.getBRMSyncFields('Account');
        orgIdsForBLinkSync = new List<Id>();
        if(fields != null && !fields.isEmpty()) {
            for(Account org : orgs) {
                if(org.Bgive_Id__c != null) {
                    if(Trigger.isInsert) {
                        orgIdsForBLinkSync.add(org.Id);
                    } else if(Trigger.isUpdate) {
                        for(String f : fields) {
                            if(org.get(f) != oldMap.get(org.Id)?.get(f)) {
                                orgIdsForBLinkSync.add(org.Id);
                                break;
                            }
                        }
                        // Bgive Id field will not be present in field sync config.
                        // hence adding explicit check for it
                        if(org.Bgive_Id__c != oldMap.get(org.Id)?.Bgive_Id__c) {
                            orgIdsForBLinkSync.add(org.Id);
                        }
                    }
                }
            }
        }
    }

    public override void andFinally() {
        try {
        List<Id> accountIds = new List<Id>();
        if(newAccounts != null) {//Before delete will makes newAccounts to be null, and this should be prevented
            for (Account a : newAccounts) {
                accountIds.add(a.Id);
            }
            StatesUtil.recalculateSharingForAccounts(accountIds);
        }
        if(Trigger.isAfter) {
            if(Trigger.isUpdate) {
                updateContactsBusinessAddress(accountIds);
                updateContactRestrictedName(restrictedAccountIds,newMap);
                if(!orgIdsForBLinkSync.isEmpty()) {
                    Database.executeBatch(new BatchBlinkOrgSync(orgIdsForBLinkSync),1);
                }
            }
            if(Trigger.isInsert) {//After Account newly creation, the Account Hisotry Custom fields should be tracked
                List<Account> oldEmptyAccount = new List<Account>(); //Empty old Account List to fit the logic inside the History tracking logic
                for(Integer i = 0; i < newAccounts.size(); i++) {
                    oldEmptyAccount.add(new Account());
                }
                updateContactsBusinessAddress(accountIds);
                if(!orgIdsForBLinkSync.isEmpty()) {
                    Database.executeBatch(new BatchBlinkOrgSync(orgIdsForBLinkSync),1);
                }
            }

            if(Trigger.isDelete) {
                if(!mergeWinningRecordIds.isEmpty()) {
                    MergeDuplicateRecordDeletion.deleteDuplicateTagJunctionsForAccount(mergeWinningRecordIds);
                }
            }

            if (!orgsWithNameChange.isEmpty()) {
                DonorTriggerHelper.updatePledgeName(orgsWithNameChange , 'Organization');
                syncOrgAssociationNames(orgsWithNameChange);
            }
        }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_AND_FINALLY);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    @future
    public static void afterMerge(Set<Id> masterAccountIds) {
        try {
            if(masterAccountIds == null || masterAccountIds.isEmpty()) return;
            List<Account> masterAccountList = [
                SELECT Id, Name, AKA__c, Legal_Name__c, Report_Record__c, Notes__c
                FROM Account
                WHERE Id = :masterAccountIds
            ];
            if(masterAccountList.isEmpty()) return;
            for(Account masterAccount : masterAccountList) {
                updatedConvertedNames(masterAccount);
                updateReasonField(masterAccount);
            }
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.update(masterAccountList, dml);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AFTER_MERGE));
        }
    }

    public static void updateReasonField(Account masterAccount) {
        masterAccount.Report_Record__c = '';
    }

    public static void updatedConvertedNames(Account masterAccount) {
        masterAccount.Converted_Org_Name__c = SpecialCharactersHelper.convertSpecialCharToEnglish(masterAccount.Name);
        masterAccount.Converted_AKA__c  = SpecialCharactersHelper.convertSpecialCharToEnglish(masterAccount.AKA__c);
        masterAccount.Converted_Legal_Name__c = SpecialCharactersHelper.convertSpecialCharToEnglish(masterAccount.Legal_Name__c);
    }

    //Method to prevent the Account deletion
    //1. Current user doesn't have access of the confidential fields
    //2. Confidential fields have some existing values
    private void checkDeletePermision(Account c) {
        Set<String> allByPassFields = new Set<String> ();
        for (String fieldName : BYPASS_MERGE_VALIDATION_FIELDS.keySet()) {
            allByPassFields.add(fieldName.toLowerCase());
        }
        for (String fieldName : fieldMap.keySet()) {
            SObjectField schemaField = fieldMap.get(fieldName);
            if(
                !systemFields.contains(fieldName) &&
                !allByPassFields.contains(fieldName) &&
                c.get(fieldName) != null &&
                !schemaField.getDescribe().isAccessible() &&
                !schemaField.getDescribe().isCalculated() &&
                !schemaField.getDescribe().isAutoNumber()
            ) {
                if((schemaField.getDescribe().getType() == Schema.DisplayType.Boolean && c.get(fieldName) == true) ||
                   schemaField.getDescribe().getType() != Schema.DisplayType.Boolean) {

                    c.addError(Label.Account_Delete_Error);
                }
            }
        }
    }

    //prevent deletion of Org which has the Bgive_Id__c field populated
    private void preventDeletionOfLinkedOrg(Account acc) {
        if(acc.Bgive_Id__c != null) {
            acc.addError(Label.BGiveLinked_Account_Delete_Error);
        }
    }

    private List<Contact> getContactsWithSameOrgAddress(List<Id> accountIds) {
        return [SELECT AccountId, Use_Same_Address_as_Organization__c
                FROM Contact
                WHERE AccountId IN :accountIds AND
                      Use_Same_Address_as_Organization__c = true];
    }

    private void updateContactsBusinessAddress(List<Id> accountIds) {
        if(!accountIds.isEmpty()) {
            List<Contact> contactList =  getContactsWithSameOrgAddress(accountIds);
            if(!contactList.isEmpty()) {
                for(Contact c : contactList) {
                    ContactTriggerHandler.setContactBusinessAddress(c , newMap.get(c.AccountId));
                }
                BBApps_Crud.doUpdateWithHandling(contactList, false, ERR_UPDATE_CONTACTS_BUSINESS_ADDRESS);
            }
        }
    }

	public void updateRestrictedOrgName(Account curAcct, Account oldAcct) {
        if(curAcct.Restricted__c &&  (isFieldChanged(curAcct, 'Restricted__c') || isFieldChanged(curAcct, 'Name'))) {
            if(oldAcct !=null && oldAcct.Name == Assets.RESTRICTED_ORG_NAME && curAcct.Name != Assets.RESTRICTED_ORG_NAME) {
                curAcct.addError('You cannot change the Organization Name from '+ Assets.RESTRICTED_ORG_NAME +'. Please contact your system administrator to update the Private Org Name.');
            }
            curAcct.Restricted_Org_Name__c = curAcct.Name;
            curAcct.Name = Assets.RESTRICTED_ORG_NAME;
            restrictedAccountIds.add(curAcct.Id);
           } else if(!curAcct.Restricted__c && (String.isNotBlank(curAcct.Restricted_Org_Name__c)) &&
                  (isFieldChanged(curAcct, 'Restricted__c') || isFieldChanged(curAcct, 'Name'))) {
                      curAcct.Name = curAcct.Restricted_Org_Name__c ;
                      curAcct.Restricted_Org_Name__c =null;
                      //restrictedAccountIds.add(curAcct.Id); commented as dont wanted to unrestricted if account is unrestrcited
                  }
    }

    public static void updateContactRestrictedName(List<Id> restrictedAccountIds, Map<Id, Account> newMap) {
        List<Contact> contactList = [SELECT Id, Name, Restricted_Org_Name__c, AccountId, Account.Restricted_Org_Name__c
                                     FROM Contact
                                     WHERE AccountId IN :restrictedAccountIds];
        for(Contact con : contactList) {
            con.Restricted_Org_Name__c = newMap.get(con.AccountId).Restricted_Org_Name__c;
            con.Restricted__c =  newMap.get(con.AccountId).Restricted__c;
        }
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        BBApps_Crud.doUpdateWithHandling(contactList, dml, ERR_UPDATE_CONTACT_RESTRICTED_NAME);

    }

    //This method is used to set phone only field on account by checking the Phone Country code Field
    public static void setPhone(List<Account> triggerNew, Map<Id,Account> triggerOldMap) {
        Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
        String platform = '';
         if(Trigger.isInsert){
              platform = ContactTriggerHandler.getSessionPlatform();
         }
        for (Account a : triggerNew) {
            String oldPhoneCountryCode = null;
            if(triggerOldMap != null) {	//check if old Phone_Country_Code__c from old record
                Account oldOrganization = triggerOldMap.get(a.Id);
                oldPhoneCountryCode = oldOrganization.Phone_Country_Code__c;
            }
            if (a.Phone_Country_Code__c != null && a.Phone != null) {
                UtilityClass.wrapperPhones phones =  new UtilityClass.wrapperPhones();
                phones = UtilityClass.formatPhone(a.Phone, a.Phone_Country_Code__c, oldPhoneCountryCode);
                a.Phone = phones.FormatedPhone;
                a.Phone_Phone_Only__c = phones.PhoneOnly;
            } else if (a.Phone == null) {
                a.Phone_Phone_Only__c = '';
            }
            if(a.Restricted__c && String.isNotBlank(envSetting.Restricted_Org_Contact_Owner_Id__c) &&
               a.OwnerId <> envSetting.Restricted_Org_Contact_Owner_Id__c) {

               a.OwnerId = envSetting.Restricted_Org_Contact_Owner_Id__c;
            } else if(!a.Restricted__c && String.isNotBlank(envSetting.Unrestricted_Org_Contact_Owner_Id__c) &&
                       a.OwnerId <> envSetting.Unrestricted_Org_Contact_Owner_Id__c) {
                a.OwnerId = envSetting.Unrestricted_Org_Contact_Owner_Id__c;
            }
            if(Trigger.isInsert){
                setLegacySource(a,platform);
            }
        }
    }

    // Purpose: Helper method used to set Legacy_Source_System__c
    private static void setLegacySource(Account a, String platform) {
        try{
            if (platform == 'iPhone' || platform == 'iPad') {
                a.Legacy_Source_System__c = Assets.LEGACY_SOURCE_SYSTEM_MOBILE;
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_SET_LAGACY_SOURCE) );
        }
    }

    public static void validateGovtOrgForGeoArea (List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
        Set<Id> geoAreaIds = new Set<Id>();
        Map<String, Account> govGeoAccMap = new Map<String, Account>();
        // Collect Geo Area IDs only when Government_Geo_Area__c is updated
        if(newAccounts != null) {
            for (Account acc : newAccounts) {
                Boolean fieldChanged = (Trigger.isUpdate && oldAccountMap != null ) ?
                                       (acc.Government_Geo_Area__c != oldAccountMap.get(acc.Id).Government_Geo_Area__c) :
                                       false;
                if(acc.Government_Geo_Area__c != null && (Trigger.isInsert || fieldChanged)) {
                    geoAreaIds.add(acc.Government_Geo_Area__c);
                    govGeoAccMap.put(acc.Government_Geo_Area__c,acc);
                }
            }
        }
        // Query for Accounts that already have the same Geo Area ID
        if (!geoAreaIds.isEmpty()) {
            for (Account existingAcc : [SELECT Id, Name, Government_Geo_Area__c,Government_Geo_Area__r.Name
                                        FROM Account
                                        WHERE Government_Geo_Area__c IN :geoAreaIds AND
                                              Id != :newAccounts]) {
                if(govGeoAccMap.containskey(existingAcc.Government_Geo_Area__c)) {
                    Account newAccount = govGeoAccMap.get(existingAcc.Government_Geo_Area__c);
                    newAccount.addError('The Government Geo Area you selected is already used on an existing record. Make sure to check for any potential duplicate records or choose another Government Geo Area value before saving "'
                                        + existingAcc.Government_Geo_Area__r.Name +
                                        '".');
                }
            }
        }
    }

    /**
     * BRME-6325: Updates Org Association names based on changes to related Account Name or Association Name
    **/
    public static void syncOrgAssociationNames(Set<Id> recordIds) {
        if(recordIds == null || recordIds.isEmpty()) {
            return;
        }
        List<Org_Association__c> orgAssociations = queryOrgAssociations(recordIds);
        if(orgAssociations.isEmpty()) {
            return;
        }
        applyOrgAssociationNameUpdates(orgAssociations);
        BBApps_Crud.doUpdateWithHandling(orgAssociations, false, ERR_SYNC_ORG_ASSOCIATION_NAMES);
    }

    private static List<Org_Association__c> queryOrgAssociations(Set<Id> recordIds) {
        String prefix = String.valueOf(recordIds.iterator().next()).substring(0,3);
        Boolean isAccount = prefix == Account.SObjectType.getDescribe().getKeyPrefix();
        Boolean isAssociation = prefix == Association__c.SObjectType.getDescribe().getKeyPrefix();
        Boolean isOrgAssociation = prefix == Org_Association__c.SObjectType.getDescribe().getKeyPrefix();

        String filterField = isAccount ? 'Organization__c' :
                            (isAssociation ? 'Association__c' :
                            (isOrgAssociation ? 'Id' : null));

        if(filterField == null) {
            return new List<Org_Association__c>();
        }

        String soql =
            'SELECT Id, Name, Association__r.Name, Organization__c, Organization__r.Name, ' +
            'Organization__r.Restricted__c, Organization__r.Restricted_Org_Name__c ' +
            'FROM Org_Association__c ' +
            'WHERE ' + filterField + ' IN :recordIds';

        return Database.query(soql);
    }

    private static void applyOrgAssociationNameUpdates(
        List<Org_Association__c> orgAssociations
    ) {
        for (Org_Association__c oa : orgAssociations) {
            String orgName = oa.Organization__r.Restricted__c ?
                oa.Organization__r.Restricted_Org_Name__c :
                oa.Organization__r.Name;

            String fullName = oa.Association__r.Name + ': ' + orgName;

            if (fullName.length() > 80) {
                oa.Name = fullName.substring(0, 77) + '...';
            } else {
                oa.Name = fullName;
            }
        }
    }
}