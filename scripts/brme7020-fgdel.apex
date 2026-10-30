Team__c t = [SELECT Id FROM Team__c LIMIT 1];
Highlight_Interaction__c h = new Highlight_Interaction__c(Name='DELTEST', Team__c=t.Id, Description__c='d', Status__c='Draft');
insert h;
List<File_Group__c> fgs = [SELECT Id FROM File_Group__c WHERE Highlight__c=:h.Id];
System.debug('FG_AFTER_INSERT=' + fgs.size());
Database.DeleteResult[] dr = Database.delete(fgs, false);
for (Database.DeleteResult r : dr) { System.debug('DEL ok=' + r.isSuccess() + (r.isSuccess()?'':(' err=' + r.getErrors()[0].getMessage() + ' status=' + r.getErrors()[0].getStatusCode()))); }
System.debug('FG_AFTER_FGDELETE=' + [SELECT COUNT() FROM File_Group__c WHERE Highlight__c=:h.Id]);
delete h;
System.debug('FG_AFTER_HIGHLIGHTDELETE=' + [SELECT COUNT() FROM File_Group__c WHERE Highlight__c=:h.Id]);
