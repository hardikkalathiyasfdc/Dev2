// BRME-7045: test data for Send Back for Revisions.
// Create/link a Bgive-linked Contact for the current user (Hardik) and set them as
// Grants Team Contact so the Revisions Needed email goes to a real inbox for review.

Id hkUser = [SELECT Id FROM User WHERE Email = 'hkalathiya@bloomberg.org' LIMIT 1].Id;
Id acct = [SELECT Id FROM Account LIMIT 1].Id;

// Find or create a Contact for the user that is Bgive-linked (validation requires Bgive_Id__c)
List<Contact> existing = [SELECT Id, Bgive_Id__c FROM Contact WHERE BRM_User__c = :hkUser LIMIT 1];
Contact c;
if (existing.isEmpty()) {
    c = new Contact(
        FirstName = 'Hardik',
        LastName = 'Kalathiya',
        Email = 'hkalathiya@bloomberg.org',
        AccountId = acct,
        BRM_User__c = hkUser,
        Bgive_Id__c = '999999'
    );
    insert c;
} else {
    c = existing[0];
    if (String.isBlank(c.Bgive_Id__c)) {
        c.Bgive_Id__c = '999999';
        update c;
    }
}

Id init1 = 'a0qbc00000HmnW5AAJ'; // Test - 08/14/2026 1.0 (Ready for Approval, checklist complete)
update new IM_Initiative__c(Id = init1, Grants_Team_Contact__c = hkUser);

System.debug('Contact ' + c.Id + ' linked; Initiative ' + init1 + ' Grants Team Contact = ' + hkUser);
