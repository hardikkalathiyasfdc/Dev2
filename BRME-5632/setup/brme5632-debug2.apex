// BRME-5632 debug 2: reproduce upsertContactsList create path against the mixed load rows (read-only intent).
// Build the same contacts DIT would and attempt the insert with the same DML options, capturing errors.
Map<String,String> colMap = new Map<String,String>{
    'First_Name__c'=>'FirstName','Last_Name__c'=>'LastName','Organization_Name__c'=>'Organization_Id__c',
    'Business_Email__c'=>'Email','Business_Phone__c'=>'Phone','Business_Phone_Country_Code__c'=>'Office_Phone_Country_Code__c'
};
List<Data_Load_Record__c> rows = [SELECT Id, Row_Index__c, First_Name__c, Last_Name__c, Organization_Name__c, Organization_Id__c, Business_Email__c, Business_Phone__c, Business_Phone_Country_Code__c FROM Data_Load_Record__c WHERE Data_Load__c='a06bc00000NjpynAAB' ORDER BY Row_Index__c];
System.debug('rows=' + rows.size());
for (Data_Load_Record__c r : rows) System.debug('  row ' + r.Row_Index__c + ' ' + r.First_Name__c + ' ' + r.Last_Name__c + ' phone=' + r.Business_Phone__c + ' code=' + r.Business_Phone_Country_Code__c + ' orgId=' + r.Organization_Id__c);
