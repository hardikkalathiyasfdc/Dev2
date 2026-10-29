// BRME-6993: synthetic baseline Accounts + Contacts in the dev2 sandbox.
// Distinctive names prefixed BRME6993; Description marks them for cleanup. No real records touched.
// Two orgs (BRM side + Excel side) and contacts covering the highlight-condition matrix:
//  C1 full (email+phone+address, checkbox=false), C2 full (checkbox=true), C3 partial (only email),
//  C4 address-only (address, checkbox=false), C5 bare (none populated).
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;

Account brm = new Account(Name='BRME6993 Org A', BillingStreet='100 Alpha Way', BillingCity='New York', BillingState='NY', BillingPostalCode='10001', BillingCountry='United States', Description='BRME-6993 synthetic test data');
Account xl  = new Account(Name='BRME6993 Org B', BillingStreet='200 Beta Blvd', BillingCity='Chicago', BillingState='IL', BillingPostalCode='60601', BillingCountry='United States', Description='BRME-6993 synthetic test data');
Database.insert(new List<Account>{brm, xl}, dml);
System.debug('ACCOUNTS brm=' + brm.Id + ' xl=' + xl.Id);

List<Contact> cons = new List<Contact>{
    new Contact(FirstName='Fiona', LastName='BRME6993Full', AccountId=brm.Id, Email='fiona.brme6993@brme6993.invalid', Phone='212-555-0101',
                MailingStreet='100 Alpha Way', MailingCity='New York', MailingState='NY', MailingPostalCode='10001', MailingCountry='United States',
                Use_Same_Address_as_Organization__c=false, Description='BRME-6993 synthetic test data'),
    new Contact(FirstName='Theo', LastName='BRME6993ChkTrue', AccountId=brm.Id, Email='theo.brme6993@brme6993.invalid', Phone='212-555-0102',
                MailingStreet='100 Alpha Way', MailingCity='New York', MailingState='NY', MailingPostalCode='10001', MailingCountry='United States',
                Use_Same_Address_as_Organization__c=true, Description='BRME-6993 synthetic test data'),
    new Contact(FirstName='Paula', LastName='BRME6993Partial', AccountId=brm.Id, Email='paula.brme6993@brme6993.invalid',
                Use_Same_Address_as_Organization__c=false, Description='BRME-6993 synthetic test data'),
    new Contact(FirstName='Adam', LastName='BRME6993AddrOnly', AccountId=brm.Id,
                MailingStreet='100 Alpha Way', MailingCity='New York', MailingState='NY', MailingPostalCode='10001', MailingCountry='United States',
                Use_Same_Address_as_Organization__c=false, Description='BRME-6993 synthetic test data'),
    new Contact(FirstName='Bianca', LastName='BRME6993Bare', AccountId=brm.Id,
                Use_Same_Address_as_Organization__c=false, Description='BRME-6993 synthetic test data')
};
Database.insert(cons, dml);
for (Contact c : [SELECT Id, FirstName, LastName, Email, Phone, AccountId, Use_Same_Address_as_Organization__c, MailingStreet, MailingCity
                  FROM Contact WHERE LastName LIKE 'BRME6993%' ORDER BY LastName]) {
    System.debug('CONTACT ' + c.Id + ' | ' + c.FirstName + ' ' + c.LastName + ' | org=' + c.AccountId
        + ' | email=' + c.Email + ' | phone=' + c.Phone + ' | addr=' + c.MailingStreet + ',' + c.MailingCity
        + ' | sameAddr=' + c.Use_Same_Address_as_Organization__c);
}
