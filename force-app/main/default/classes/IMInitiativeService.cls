/**
* Author      : Sai Bhargav Thotakura
* Date        : 01/31/2025
* Jira        : IM-49
* Description : This class is used to sync Initiative record in BGive system when the initiative is final approved or updated  after final approved.
* Test        : IMSyncInitiativeControllerTest.
* ChangeLog   :
* Sai Bhargav Thotakura on 22 Jan 2025 - IM-49 - Updated logic to address feedback points.
* Paddy IM-523: Added logic to check whether record is locked in Bgive.
*/

public with sharing class IMInitiativeService {

    //metadata BGive and brm field mapping
    private static IM_Initiative__c initiativeRec;
    public class IMInitiativeServiceException extends Exception{}

    /**
    * Description : create BRM Final Approved Initiative record in BGive/Fluxx System
    * Parameters  : None
    * Return Type : Void
    */
    public static void sync(String initiativeId){
        try {
        initiativeRec = IMUtil.getInitiative(initiativeId);
            Map<String,Object> syncResults = BGiveApiSync.sync(initiativeRec, Assets.IM_INITIATIVE, null);
            if(syncResults.get('Errors') != null) {
                String error = (String)syncResults.get('Errors');
                error = error.remove('BGiveApiSyncException:[]:').trim();
                initiativeRec.Sync_Error__c = String.valueOf(error);
            } else {
                initiativeRec.Sync_Error__c = '';
                if(String.isBlank(String.valueOf(initiativeRec.get(Assets.BGIVE_ID)))) {
                	initiativeRec.Bgive_Id__c = (String)syncResults.get('BgiveId') ?? null;
                }
            }
            BBApps_Crud.doUpdate(
                initiativeRec
            );
        } catch (Exception ex) {
            //Exception - update sync error field.
            BBApps_ErrorHandler.logErrors(initiativeRec.Id, ex, new BBApps_ErrorCustomFields(Assets.BGIVE_SYNC_ERROR_TYPE));
            initiativeRec.Sync_Error__c = String.valueOf(ex);
            BBApps_Crud.doUpdate(
                initiativeRec
            );
        }
    }
}