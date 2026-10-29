public with sharing class AlertBannerCntrl {

    private static final String ERR_GET_MESSAGES = 'ABC_GET_MESSAGES_FAILED';
    
    @AuraEnabled(cacheable=true)
    public static List<String> getMessages(String fieldApiName , String objectApiName , String recordId){
        List<String> messages = new List<String>();

        try {
            
            if( !String.isBlank(objectApiName) && !String.isBlank(fieldApiName)){
                String query = 'SELECT ' + fieldApiName + ' FROM '+objectApiName +' WHERE Id = :recordId';
                List<SObject> queryResults = Database.query(query);
                if(!queryResults.isEmpty() && queryResults.size() > 0){
                    SObject record = queryResults[0];
                    String fieldValue = (String)record.get(fieldApiName);
                    if(!String.isBlank(fieldValue)){
                        messages = fieldValue.split(';');
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_MESSAGES);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }

        return messages;
    }
}