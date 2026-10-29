// BRME-5632 debug: call createWithList directly on the mixed load to inspect rowErrors/errors.
// Read-only diagnostics (rolls back nothing committed here because contacts already processed).
Id loadId = 'a06bc00000NjpynAAB';
Map<String,String> colMap = new Map<String,String>{
    'First_Name__c'=>'FirstName','Last_Name__c'=>'LastName','Organization_Name__c'=>'Organization_Name__c',
    'Business_Email__c'=>'Email','Business_Phone__c'=>'Phone','Business_Phone_Country_Code__c'=>'Office_Phone_Country_Code__c'
};
Object res = DITCmpController.createWithList(null, null, String.valueOf(loadId), colMap, '0', '20');
System.debug('RESULT=' + JSON.serialize(res));
