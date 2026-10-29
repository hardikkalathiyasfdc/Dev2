global without sharing class InactiveElectedStatusScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
		//Only get records with not inactive but term date is passed
        String query = 'SELECT ElectedStatus__c, TermEndDate__c FROM ElectedOffice__c WHERE ElectedStatus__c != \'Inactive\' AND TermEndDate__c < TODAY';
        InactiveElectedStatusBatch batch = new InactiveElectedStatusBatch(query);
        Database.executeBatch(batch);        
    }
}