public class AccountContactOwnerUpdateBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
        String soql = 'select Id, OwnerId from Account where Restricted__c = false and ';
        soql += 'OwnerId <> \'' + envSetting.Unrestricted_Org_Contact_Owner_Id__c + '\'';
        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
        List<Account> accSet = new List<Account>();
        for(Account c : scope) {
            if(c.OwnerId <> envSetting.Unrestricted_Org_Contact_Owner_Id__c) {
                c.OwnerId = envSetting.Unrestricted_Org_Contact_Owner_Id__c;
                accSet.add(c);
            }
        }
        if(!accSet.isEmpty()) {
            Database.SaveResult[] results = Database.update(accSet, false);
            for(Integer i = 0; i < results.size(); i++) {
                if(!results[i].isSuccess()) {
                    System.debug('Error updating account: ' + accSet[i].Id + ' => ' + results[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}
}