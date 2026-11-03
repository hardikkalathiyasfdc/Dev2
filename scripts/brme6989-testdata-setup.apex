// BRME-6989 test-data setup: create missing File_Group__c records for
// initiative 'Test - 08/14/2026 1.0' (a0qbc00000HmnW5AAJ), which was created
// without them (trigger did not fire), and remove the stray user-linked uploads.

Id initiativeId = 'a0qbc00000HmnW5AAJ';

// 1. Delete stray ContentDocuments that got linked to the running User instead of the file group
List<ContentDocument> stray = [
	SELECT Id, Title FROM ContentDocument WHERE Title LIKE 'BRME-6989-Test-%'
];
if (!stray.isEmpty()) {
	delete stray;
	System.debug('Deleted stray docs: ' + stray.size());
}

// 2. Create the Final Docs and Private Docs file groups if missing
List<File_Group__c> existing = [
	SELECT Id, Category__c FROM File_Group__c WHERE Parent_Initiative__c = :initiativeId
];
Set<String> cats = new Set<String>();
for (File_Group__c fg : existing) { cats.add(fg.Category__c); }

List<File_Group__c> toInsert = new List<File_Group__c>();
if (!cats.contains('Final Docs')) {
	toInsert.add(new File_Group__c(Parent_Initiative__c = initiativeId, Object_Type__c = 'Initiative', Category__c = 'Final Docs'));
}
if (!cats.contains('Private Docs')) {
	toInsert.add(new File_Group__c(Parent_Initiative__c = initiativeId, Object_Type__c = 'Initiative', Category__c = 'Private Docs'));
}
if (!toInsert.isEmpty()) {
	insert toInsert;
}
System.debug('Existing categories: ' + cats);
System.debug('Inserted: ' + toInsert.size());

// 3. Confirm
for (File_Group__c fg : [SELECT Id, Name, Category__c FROM File_Group__c WHERE Parent_Initiative__c = :initiativeId]) {
	System.debug('FG: ' + fg.Name + ' / ' + fg.Category__c + ' / ' + fg.Id);
}
