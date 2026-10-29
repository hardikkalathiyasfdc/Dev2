/**
* Author : Gauri Sagane
* Date   : 10/25/2024
* Jira   : IM-32
* Description : This class is used to sync BRM orgs based on field changes in Bgive System.
* Test : ScheduleBlinkOrgSyncTest
*/

public with sharing class QueueableBlinkOrgSync implements Queueable, Database.AllowsCallouts {

    /**
    * Description : Method to update BRM Org fields when changed in BGive
    * Parameters : context QueueableContext
    * Return Type : void
    */
    public void execute(QueueableContext context) {
        List<BLinkOrgService.BGiveOrg> bGiveOrgs = new List<BLinkOrgService.BGiveOrg>();
        List<Account> orgsToUpdate = new List<Account>();
        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFieldsMapBGiveToBRM('Account');
        try{
            // Fetch contacts with flag set from BGive
            bGiveOrgs = getModifiedBGiveOrgs();
            
            if(bGiveOrgs != null){
            // Get corresponding BRM Org Ids
            List<Id> orgIds = new List<Id>();
            for(BLinkOrgService.BGiveOrg bgiveOrg : bGiveOrgs){
                orgIds.add((Id)bgiveOrg.brm_id);
            }

            // Get the BRM Orgs
            List<String> syncFields = BLinkUtil.getSyncFieldsBGiveToBRM('Account');
            String query = 'SELECT Id, ';
            if(syncFields != null){
                query += String.join(syncFields, ', ');
            }
            query += ' From Account WHERE Id IN :orgIds';
            Map<Id, Account> brmOrgsMap = new Map<Id, Account>((List<Account>)Database.query(query, AccessLevel.SYSTEM_MODE));
            String orgsNotFound = '';
            // Update BRM orgs with new values
            for(BLinkOrgService.BGiveOrg bgiveOrg : bGiveOrgs){
                Account brmOrg = BLinkUtil.syncBRMOrgFields(brmOrgsMap.get((Id)bgiveOrg.brm_id), bgiveOrg, syncFieldMappings);
                if(brmOrg != null){
                    orgsToUpdate.add(brmOrg);
                }else{
                    orgsNotFound += bgiveOrg.id + ', ';
                }
            }
            orgsNotFound = orgsNotFound.length() > Assets.STRING_MAX_SIZE ? orgsNotFound.substring(0, Assets.STRING_MAX_SIZE) : orgsNotFound;
            if(String.isNotBlank(orgsNotFound))
                UtilityClass.logError('', 'Org Sync Failed: Linked BRM Orgs not found for list of bgive ids: '+orgsNotFound, Assets.BLINK_SYNC_ERROR_TYPE);

            // Update BRM contacts with updated values
            if(!orgsToUpdate.isEmpty()){
                try{
                    Database.SaveResult[] results = Database.update(orgsToUpdate, false, AccessLevel.SYSTEM_MODE);
                    for(Database.SaveResult result : results) {
                        if(!result.isSuccess()) {
                            for(Database.Error error : result.getErrors()) {
                                UtilityClass.logError(result.getId(), 'Organization Object: Failed to Update Orgs in BRM' + error.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
                            }
                        }
                    }
                }catch(Exception e) {
                    UtilityClass.logError('', 'Organization Object: Failed to Update Orgs in BRM' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
                }
            }
            }

        }catch(Exception e){
            UtilityClass.logError('', 'Organization Object: Failed to Update Orgs in BRM' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
        }
    }

    /**
    * Description : Method to create BGive Api filter conditions
    * Parameters : none
    * Return Type : String
    */
    private String getBGiveApiFilter(){
        BGiveFilterCondition brmFlagFilterCondition = new BGiveFilterCondition('update_brm_flag', BGiveFilterCondition.Operator.EQ, 'true');
        BGiveFilterCondition brmIdFilterCondition = new BGiveFilterCondition('brm_id', BGiveFilterCondition.Operator.IS_NOT_NULL, '-');
        BGiveApiFilter filter = new BGiveApiFilter();
        filter.addCondition(brmFlagFilterCondition);
        filter.addCondition(brmIdFilterCondition);
        return filter.getFilterString();
    }

    /**
    * Description : Method to fetch orgs which are modified in BGive
    * Parameters : none
    * Return Type : List<BLinkOrgService.BGiveOrg>
    */
    private List<BLinkOrgService.BGiveOrg> getModifiedBGiveOrgs(){

        String filter = getBGiveApiFilter();

        BGiveApiOrg bao = new BGiveApiOrg();
        bao.setFilters(filter);
        bao.setPageSizeMax();

        try{
            // Fetch contacts with flag set from BGive
            BGiveApi.BGiveAPIListResponse response = (BGiveApi.BGiveAPIListResponse)bao.get();
            if(response.records != null && response.records.size() > 0){
                return (List<BLinkOrgService.BGiveOrg>)JSON.deserialize(JSON.serialize(response.records), List<BLinkOrgService.BGiveOrg>.class);
            }

        }catch(Exception e){
            UtilityClass.logError('', 'Organization Object: Cannot Fetch Orgs from BGive' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
        }
        return null;
    }
}