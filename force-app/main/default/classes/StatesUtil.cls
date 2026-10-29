public without sharing class StatesUtil {

    private static Map<String, Id> stateName_GroupId_Map;
    private static final String ERR_RECALCULATE_SHARING_FOR_ACCOUNTS_FAILED = 'StatesUtil_recalculateSharingForAccounts_FAILED';
    private static final String ERR_DELETE_FAILED = 'StatesUtil_deleteAccountShares_FAILED';
    private static final String ERR_INSERT_FAILED = 'StatesUtil_insertAccountShares_FAILED';

    private static void initializeStateGroupsMap() {
        if(stateName_GroupId_Map == null) {
            stateName_GroupId_Map = new Map<String, Id>();
            for(Group g : [SELECT Id, DeveloperName 
                           FROM Group 
                           WHERE RelatedId IN (SELECT Id FROM UserRole WHERE Name LIKE 'State___') 
                             AND Type = 'Role']) {
                                
                String gName = g.DeveloperName;
                stateName_GroupId_Map.put(gName.substring(gName.length()-2), g.Id);
            }
        }
    }

    public static void recalculateSharingForAccounts(List<Id> accountIds) {
        try {
            List<Account> accounts = [SELECT Id, BillingStateCode, BillingCountryCode, ShippingStateCode, ShippingCountryCode
                                      FROM Account 
                                      WHERE Id IN :accountIds 
                                        AND Account.RecordType.Name = :Assets.ACCOUNT_RECORDTYPE_COMPANY];
            initializeStateGroupsMap();
            Map<Id, List<String>> accountId_States_Map = new Map<Id, List<String>>();
            for(Account a : accounts) {
                List<String> states = new List<String>();
                if(a.BillingStateCode != null && a.BillingCountryCode == Assets.USA_Code) states.add(a.BillingStateCode);
                if(a.ShippingStateCode != null && a.ShippingCountryCode == Assets.USA_Code) states.add(a.ShippingStateCode);
                accountId_States_Map.put(a.Id, states);
            }
            Map<Id, List<AccountShare>> existingAccountShareMap = new Map<Id, List<AccountShare>>();
            String groupPrefix = Schema.getGlobalDescribe().get('Group').getDescribe().getKeyPrefix();
            for(AccountShare aShare : [SELECT Id, AccountId, UserOrGroupId, AccountAccessLevel, ContactAccessLevel 
                                       FROM AccountShare 
                                       WHERE RowCause = 'Manual' 
                                         AND UserOrGroupId IN (SELECT Id FROM Group WHERE Type = 'Role' AND DeveloperName LIKE 'State___')
                                         AND AccountId IN :accountIds]) {
                if(((String)aShare.UserOrGroupId).startsWith(groupPrefix)) {
                    if(!existingAccountShareMap.containsKey(aShare.AccountId)) existingAccountShareMap.put(aShare.AccountId, new List<AccountShare>());
                    existingAccountShareMap.get(aShare.AccountId).add(aShare);
                }
            }
            List<AccountShare> newAccountShares = new List<AccountShare>();
            List<AccountShare> deleteAccountShares = new List<AccountShare>();
            for(Id accountId : accountId_States_Map.keySet()) {
                for(String state : accountId_States_Map.get(accountId)) {
                    if(stateName_GroupId_Map.containsKey(state)) {
                        Id groupId = stateName_GroupId_Map.get(state);
                        if(existingAccountShareMap.containsKey(accountId)) {
                            List<AccountShare> aShares = existingAccountShareMap.get(accountId);
                            Boolean isFound = false;
                            for(Integer i = 0; i < aShares.size(); i++) {
                                if(aShares[i].UserOrGroupId == groupId) {
                                    isFound = true;
                                    aShares.remove(i);
                                    break;
                                }
                            }
                            if(!isFound) {
                                newAccountShares.add(createAccountShare(accountId, groupId));
                            }
                        } else {
                            newAccountShares.add(createAccountShare(accountId, groupId));
                        }
                    }
                }
                if(existingAccountShareMap.containsKey(accountId)) {
                    deleteAccountShares.addAll(existingAccountShareMap.get(accountId));
                }
            }
            BBApps_Crud.doDeleteWithHandling(deleteAccountShares, true, new BBApps_ErrorCustomFields(ERR_DELETE_FAILED));
            BBApps_Crud.doInsertWithHandling(newAccountShares, true, new BBApps_ErrorCustomFields(ERR_INSERT_FAILED));
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_RECALCULATE_SHARING_FOR_ACCOUNTS_FAILED));
        }
    }

    private static AccountShare createAccountShare(Id aId, Id gId) {
        return new AccountShare(
            AccountId = aId, 
            UserOrGroupId = gId, 
            RowCause = 'Manual', 
            AccountAccessLevel = 'Edit', 
            OpportunityAccessLevel = 'None');
    }

    private static ContactShare createContactShare(Id cId, Id gId) {
        return new ContactShare(
            ContactId = cId, 
            UserOrGroupId = gId, 
            RowCause = 'Manual', 
            ContactAccessLevel = 'Edit');
    }

    private static Interaction__Share createInteractionShare(Id iId, Id gId) {
        return new Interaction__Share(
            ParentId = iId, 
            UserOrGroupId = gId, 
            RowCause = 'Manual', 
            AccessLevel = 'Edit');
    }
}