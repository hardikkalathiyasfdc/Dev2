/**
* Author      : Sai Bhargav Thotakura
* Date        : 03/30/2025
* Jira        : IM-134
* Description : This class is used to sync IM Grant record in BGive system when the user clicks on the sync to Bgive button the custom grant UI.
* Test        : Yet to be created.
* ChangeLog   :
*/
public with sharing class BGiveApiGrant extends BGiveApi {
    
    /**
    * Description : Overrides abstract class getModel - Object/Table name in BGive
    * Parameters  : None
    * Return Type : Object/Table Name in Bgive
    */
    public override String getModel(){
        return Assets.BGIVE_GRANT_NAME;
    }
}