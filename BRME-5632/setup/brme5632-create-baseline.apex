// BRME-5632: synthetic baseline records for the DIT Import error-report ticket.
// Distinctive names prefixed BRME5632; Description marks them for cleanup. No real records touched.
// A safe reproducible Contact save failure = Business Phone populated WITHOUT Business Phone (Country Code)
// (active validation rule Office_Phone_Country_Code, org-verified 2026-10-23). That failure needs NO setup records.
// Below: an org to link, an existing contact to update (update-blocked scenario), and an existing list (Campaign)
// for the list-member scenarios.
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;

Account org = new Account(Name='BRME5632 Org', Description='BRME-5632 synthetic test data');
Database.insert(new List<Account>{org}, dml);
System.debug('ORG ' + org.Id);

Contact existing = new Contact(FirstName='Owen', LastName='BRME5632Update', AccountId=org.Id,
    Email='owen.brme5632@brme5632.invalid', Description='BRME-5632 synthetic test data');
Database.insert(new List<Contact>{existing}, dml);
System.debug('CONTACT ' + existing.Id);

Campaign lst = new Campaign(Name='BRME5632 List', Description='BRME-5632 synthetic test data');
Database.insert(new List<Campaign>{lst}, dml);
System.debug('CAMPAIGN ' + lst.Id);
