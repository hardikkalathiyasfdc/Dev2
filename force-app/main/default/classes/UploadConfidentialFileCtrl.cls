public with sharing class UploadConfidentialFileCtrl {
    private static final String ERR_UPLOAD_CONFIDENTIAL_FILE_CTRL= 'UPLOAD_CONFIDENTIAL_FILE_CTRL_FAILED';
    
    public String title {get;set;}
    public String currentRecordId {get;set;}
    
    public UploadConfidentialFileCtrl() {
        try{
            currentRecordId  = ApexPages.CurrentPage().getparameters().get('id'); //Get Object Id from URL
            
            String sObjName = Id.valueOf(currentRecordId).getSObjectType().getDescribe().getName(); //Process Id to get related Object Name
            
            //Query object to get object Name
            String query = 'SELECT Name FROM ' + sObjName + ' WHERE Id = \'' + currentRecordId+'\'';
            List<SObject> objs = Database.query(query);
            
            if( objs.size() > 0 ) {
                title = (String)objs[0].get('Name');
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPLOAD_CONFIDENTIAL_FILE_CTRL));
        }
    }
}