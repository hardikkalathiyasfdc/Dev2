// BRME-5632 cleanup: deletes ONLY the synthetic baseline records created for this ticket.
// See record-manifest.md. Safe to run multiple times. Does NOT touch other tickets' or real records.
delete [SELECT Id FROM Contact WHERE LastName LIKE 'BRME5632%'];
delete [SELECT Id FROM Account WHERE Name = 'BRME5632 Org'];
delete [SELECT Id FROM Campaign WHERE Name = 'BRME5632 List'];
System.debug('BRME-5632 cleanup done');
// Reminder: also delete any Data_Load__c records created during DIT test uploads (cascade to rows),
// plus any Contacts/CampaignMembers created by a DIT Import run during testing.
