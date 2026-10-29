/**
* Author : Neha Gire
* Date   : 09/24/2024
* Jira   : IM-25
* Description : This class provides definitions to use BGiveApiService for User Table in BGive.
* Test : BGiveAPIContactTest
*/

public with sharing class BGiveApiContact extends BGiveApi{


    public BGiveApiContact(){
        COLS_DEFAULT = '["id","first_name","preferred_first_name","last_name","maiden_name","email","salutation","prefix","middle_initial","title","primary_org_sort_name","brm_id","contig_id"]';
    }

    public override String getModel(){
        return 'user';
    }

}