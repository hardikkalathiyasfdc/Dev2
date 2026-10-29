/**
* Author      : Sai Bhargav Thotakura
* Date        : 01/17/2025
* Jira        : IM-49
* Description : This class is used to sync Initiative record in BGive system when the initiative is final approved or updated  after final approved.
* Test        : Yet to be created.
* ChangeLog   :
Sai Bhargav Thotakura on 22 Jan 2025 - IM-49 - Updated logic to address feedback points.
*/

public with sharing class BGiveApiInitiative extends BGiveApi {
    
    /**
    * Description : Overrides abstract class getModel - Object/Table name in BGive
    * Parameters  : None
    * Return Type : Object/Table Name in Bgive
    */
    public override String getModel(){
        return Assets.BGIVE_OBJECT_NAME;
    }
}