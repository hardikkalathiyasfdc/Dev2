global without sharing  class AddCampaignMemberBatch implements Database.batchable<sObject>, Database.Stateful{
    
    global Set<Id> existingListMemberContacts = new Set<Id> ();
       Set<Id> tagRelatedContacts = new Set<Id> ();
    global Set<String> tagNames = new Set<String>();
    global Id newListId;
    global  Integer countOfDeceased=0;
    global  Integer countOfDonotCall=0;
    global  Integer countOfInserted=0;
    global  Integer countOfUpdated=0;
    global AddCampaignMemberBatch(Set<Id> existingListMemberContacts,Set<Id>tagRelatedContacts, Set<String> tagNames, Id newListId) {
        this.tagRelatedContacts = tagRelatedContacts;
        this.existingListMemberContacts = existingListMemberContacts;
        this.tagNames = tagNames;
        this.newListId = newListId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
       String queryString ='Select Id,DonotCall,Deceased__c FROM Contact '+
                                          ' WHERE Id NOT IN :existingListMemberContacts ';
         if(!this.tagRelatedContacts.isEmpty())
         {
             queryString ='Select Id,DonotCall,Deceased__c FROM Contact '+
                                          ' WHERE Id IN :tagRelatedContacts ';
         }
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
         List<CampaignMember> listMembersToInsert = new List<CampaignMember> ();
        system.debug('ContactS :::: '+scope);
        List<String> tempSourceNames = new List<String>(tagNames);
        String sourceName = String.join(tempSourceNames, ',');
        for(Contact c: (List<Contact>)scope) {
            CampaignMember member = new CampaignMember (
                ContactId = c.Id,
                CampaignId = newListId,
              Source__c = sourceName
            );
             if(c.Deceased__c || c.DonotCall)
                {
                    this.countOfDonotCall+=1;  
                    
                }  
            else if(existingListMemberContacts.contains(c.Id)){
                this.countOfUpdated = this.countOfUpdated+1 ;
                }
            else{ 
                listMembersToInsert.add(member);
            }
        }
        
        if(!listMembersToInsert.isEmpty()){
            insert listMembersToInsert;
              this.countOfInserted=this.countOfInserted+ listMembersToInsert.size();
            System.debug('listMembersToInsert>> '+ listMembersToInsert);
        } 
    }

global void finish(Database.BatchableContext BC) {
      Campaign camp = new Campaign();
    camp.Id=newListId;
    camp.Inserted_Member_Count__c=this.countOfInserted;
    camp.Updated_Member_Count__c =this.countOfUpdated;
    camp.Deceased_Count__c=this.countOfDeceased;
    camp.DoNotCall_Count__c=this.countOfDonotCall;
    system.debug('@@camp'+camp);
    update camp;
}
}