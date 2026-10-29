/**
* Author : Gauri Sagane
* Date   : 10/22/2024
* Jira   : IM-31
* Description : This class provides definitions to use BGiveApiService for Organization Table in BGive.
* Test : BGiveAPIOrgTest
*/

public with sharing class BGiveApiOrg extends BGiveApi {
    public BGiveApiOrg() {
        COLS_DEFAULT = '["id","name","acronym","legal_name","tax_class","tax_id","brm_id","contig_id","street_address","city","url"]';
    }

    public override String getModel(){
        return 'organization';
    }
}