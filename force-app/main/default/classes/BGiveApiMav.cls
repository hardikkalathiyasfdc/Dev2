/**
* Author : Neha Gire
* Date   : 04/12/2024
* Jira   : BRME-5240
* Description : This class provides definitions to use BGiveApiService for Model Atttibute Value table in BGive.
* Test : BGiveApiMavTest
*/
public with sharing class BGiveApiMav extends BGiveApi{
    
    public BGiveApiMav(){
        COLS_DEFAULT = '["id","description","value","retired","migrate_id","migrate_source_name","dependent_model_attribute_value_id","model_attribute_id"]';
        requiredCols = new List<String>{'model_attribute_id','value'};
    }

    public override String getModel(){
        return 'model_attribute_value';
    } 
}