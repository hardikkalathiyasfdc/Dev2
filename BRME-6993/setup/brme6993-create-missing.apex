// BRME-6993: create the two missing baseline contacts (Fiona full/chkFalse, Theo chkTrue).
// Org A = 001bc00000kkfowAAA (BRME side).
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;
Id brmId = '001bc00000kkfowAAA';
List<Contact> cons = new List<Contact>{
    new Contact(FirstName='Fiona', LastName='BRME6993Full', AccountId=brmId, Email='fiona.brme6993@brme6993.invalid', Phone='212-555-0101',
                Office_Phone_Country_Code__c='United States(+1)',
                MailingStreet='100 Alpha Way', MailingCity='New York', MailingState='NY', MailingPostalCode='10001', MailingCountry='United States',
                Use_Same_Address_as_Organization__c=false, Description='BRME-6993 synthetic test data'),
    new Contact(FirstName='Theo', LastName='BRME6993ChkTrue', AccountId=brmId, Email='theo.brme6993@brme6993.invalid', Phone='212-555-0102',
                Office_Phone_Country_Code__c='United States(+1)',
                MailingStreet='100 Alpha Way', MailingCity='New York', MailingState='NY', MailingPostalCode='10001', MailingCountry='United States',
                Use_Same_Address_as_Organization__c=true, Description='BRME-6993 synthetic test data')
};
Database.SaveResult[] res = Database.insert(cons, dml);
for (Database.SaveResult r : res) System.debug('INSERT ' + (r.isSuccess() ? 'OK ' + r.getId() : 'FAIL ' + r.getErrors()[0].getMessage()));
