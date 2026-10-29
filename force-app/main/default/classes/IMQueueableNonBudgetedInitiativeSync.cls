/**
* Author : Gauri Sagane
* Date   : 01/27/2025
* Jira   : IM-97
* Description : This class is used to create and sync Non Budgeted Initiative with BGive along with Foundation code.
* Change Log  : Paddy - IM-108 : Added default value for Rollup_In_Reporting__c to true while creating non budgeted Foundation Code.
*               Paddy - IM-144 : Removed code to create Non budgeted Initiaitve in Bgive
*               Gauri - IM-215 : Removed logic to set Rollup_In_Reporting__c to true for MISC Initiative
*               Sai   - IM-422 : Changed Misc Initiative and FC Name to Miscellaneous 
*               Paddy - IM-593 : Fix Misc FC rename to use Parent Foundation_Code__c (not Name) so
                                 retired parents do not produce "Parent (retired) Miscellaneous (retired)".
* Test :
*/

public with sharing class IMQueueableNonBudgetedInitiativeSync implements Queueable, Database.AllowsCallouts {

    private static final String ERR_UPDATE_NON_BUDGET_FC = 'UPDATE_NON_BUDGET_FC_FAILED';
    private static final String ERR_UPDATE_NON_BUDGETED_INITIATIVES = 'UPDATE_NON_BUDGETED_INITIATIVES_FAILED';
    private static final String ERR_INSERT_NON_BUDGETED_INITIATIVES = 'INSERT_NON_BUDGETED_INITIATIVES_FAILED';
    private static final String ERR_INSERT_NON_BUDGETED_FC = 'INSERT_NON_BUDGETED_FC_FAILED';

    private Set<Id> initiativeIds = new Set<Id>();
    private List<IM_Initiative__c> nonBudgetedToInsert = new List<IM_Initiative__c>();
    private List<Foundation_Code__c> nonBudgetedFCToInsert = new List<Foundation_Code__c>();
    private Map<Id,Foundation_Code__c> initiativeToFCMap = new Map<Id,Foundation_Code__c>();
    private List<IM_Initiative__c> nonBudgetedToUpdate = new List<IM_Initiative__c>();
    private final String MISC_INITIATIVE_RECORD_TYPE_ID =
    Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get(Assets.MISC_INITIATIVE_TYPE).getRecordTypeId();


    public IMQueueableNonBudgetedInitiativeSync(Set<Id> initiativeIds){
        this.initiativeIds = initiativeIds;
    }

    /**
    * Description : Method to create Non Budgeted Initiatives
    * Parameters : context QueueableContext
    * Return Type : void
    */
    public void execute(QueueableContext context) {
        try{
            List<IM_Initiative__c> parentInitiatives = [SELECT Id, Name, Focus_Area__c, Team__c, Segment__c
                                                        FROM IM_Initiative__c
                                                        WHERE Id IN : initiativeIds
                                                        WITH SYSTEM_MODE];

            Map<Id, Foundation_Code__c> parentFCs = new Map<Id, Foundation_Code__c>([SELECT Id, Name
                                                                                    FROM Foundation_Code__c
                                                                                    WHERE Initiative__c IN :initiativeIds
                                                                                    WITH SYSTEM_MODE]);

            List<Foundation_Code__c> nonBudgetedFCs = [SELECT Id, Name, Parent__r.Name, Parent__r.Foundation_Code__c, Parent__r.Focus_Area__c, Foundation_Code__c
                                                        FROM Foundation_Code__c
                                                        WHERE Parent__c IN :parentFCs.keySet() AND Type__c = :Assets.MISC_INITIATIVE_TYPE
                                                        WITH SYSTEM_MODE];

            if(!nonBudgetedFCs.isEmpty()){
                List<IM_Initiative__c> nonBudgetedInitiatives = [SELECT Id, Team__c, Focus_Area__c, Parent_Initiative__r.Team__c,
                                                                Parent_Initiative__r.Focus_Area__c
                                                                FROM IM_Initiative__c
                                                                WHERE Foundation_Code__c IN :nonBudgetedFCs
                                                                WITH SYSTEM_MODE];
                try{
                    for(Foundation_Code__c nonBudgetedFC : nonBudgetedFCs){
                        String parentCode = String.isNotBlank(nonBudgetedFC.Parent__r.Foundation_Code__c)
                            ? nonBudgetedFC.Parent__r.Foundation_Code__c : nonBudgetedFC.Parent__r.Name;
                        String fcNewName = IMUtil.truncateFieldValue(66, parentCode, null, Assets.MISC_TEXT);
                        if(nonBudgetedFC.Foundation_Code__c != fcNewName) {
                            nonBudgetedFC.Name = fcNewName;
                            nonBudgetedFC.Foundation_Code__c = fcNewName;
                        }
                    }

                    BBApps_Crud.doUpdateWithHandling(
                        nonBudgetedFCs,
                        false,
                        new BBApps_ErrorCustomFields(ERR_UPDATE_NON_BUDGET_FC)
                    );
                }catch(Exception ex) {
                    BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_NON_BUDGET_FC));
                }

                try{
                    for(IM_Initiative__c nonBudgetedInitiative : nonBudgetedInitiatives){
                        if(nonBudgetedInitiative.get(Assets.TEAM) != nonBudgetedInitiative.Parent_Initiative__r.Team__c){
                            nonBudgetedInitiative.Team__c = nonBudgetedInitiative.Parent_Initiative__r.Team__c;
                            nonBudgetedToUpdate.add(nonBudgetedInitiative);
                        }
                        else if(nonBudgetedInitiative.get(Assets.FOCUS_AREA_API_NAME) != nonBudgetedInitiative.Parent_Initiative__r.Focus_Area__c){
                            nonBudgetedInitiative.Focus_Area__c = nonBudgetedInitiative.Parent_Initiative__r.Focus_Area__c;
                            nonBudgetedToUpdate.add(nonBudgetedInitiative);
                        }
                    }
                    if(!nonBudgetedToUpdate.isEmpty()){
                        BBApps_Crud.doUpdateWithHandling(
                            nonBudgetedToUpdate,
                            false,
                            new BBApps_ErrorCustomFields(ERR_UPDATE_NON_BUDGETED_INITIATIVES)
                        );
                    }
                }catch(Exception ex) {
                    BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_NON_BUDGETED_INITIATIVES));
                }
            }else{
                createNonBudgetedInitiative(parentInitiatives);

                if(!nonBudgetedToInsert.isEmpty()){
                    try{
                        BBApps_Crud.doInsertWithHandling(
                            nonBudgetedToInsert,
                            false,
                            new BBApps_ErrorCustomFields(ERR_INSERT_NON_BUDGETED_INITIATIVES)
                        );
                    }catch(Exception ex) {
                        BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_INSERT_NON_BUDGETED_INITIATIVES));
                    }
                }

                createNonBudgetedFoundationCode(nonBudgetedToInsert);

                if(!nonBudgetedFCToInsert.isEmpty()){
                    try{
                        BBApps_Crud.doInsertWithHandling(
                            nonBudgetedFCToInsert,
                            false,
                            new BBApps_ErrorCustomFields(ERR_INSERT_NON_BUDGETED_FC)
                        );
                    }catch(Exception ex) {
                        BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_INSERT_NON_BUDGETED_FC));
                    }
                }

                updateNonBudgetedInitiative(nonBudgetedToInsert);

                if(!nonBudgetedToInsert.isEmpty()){
                    try{
                        BBApps_Crud.doUpdateWithHandling(
                            nonBudgetedToInsert,
                            false,
                            new BBApps_ErrorCustomFields(ERR_INSERT_NON_BUDGETED_INITIATIVES)
                        );
                    }catch(Exception ex) {
                        BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_INSERT_NON_BUDGETED_INITIATIVES));
                    }
                }
            }
        }catch(Exception ex){
            BBApps_ErrorHandler.logErrors('IMQueueableNonBudgetedInitiativeSync.execute', ex);
        }
    }

    /**
    * Description : Method to create non budgeted initiative when parent is created
    * Parameters : parentInitiatives List<IM_Initiative__c>
    * Return Type : void
    */
    private void createNonBudgetedInitiative(List<IM_Initiative__c> parentInitiatives){
        for(IM_Initiative__c parentInitiative : parentInitiatives){
            IM_Initiative__c nonBudgeted = new IM_Initiative__c();
            nonBudgeted.Name = IMUtil.truncateFieldValue(66, parentInitiative.Name, null, Assets.MISC_TEXT);
            nonBudgeted.RecordTypeId = MISC_INITIATIVE_RECORD_TYPE_ID;
            nonBudgeted.Focus_Area__c = parentInitiative.Focus_Area__c;
            nonBudgeted.Team__c = parentInitiative.Team__c;
            nonBudgeted.Segment__c = parentInitiative.Segment__c;
            nonBudgeted.Parent_Initiative__c = parentInitiative.Id;
            nonBudgetedToInsert.add(nonBudgeted);
        }
    }

    /**
    * Description : Method to create non budgeted foundation code
    * Parameters : initiatives List<IM_Initiative__c>
    * Return Type : void
    */
    private void createNonBudgetedFoundationCode(List<IM_Initiative__c> initiatives){

        List<IM_Initiative__c> nonBudgetedInitiatives = [SELECT Id, Name, RecordType.Name, Parent_Initiative__r.Foundation_Code__c
                                                        FROM IM_Initiative__c
                                                        WHERE Id IN :initiatives
                                                        WITH SYSTEM_MODE];
        for(IM_Initiative__c nonBudgetedInitiative : nonBudgetedInitiatives){
            Foundation_Code__c foundationCode = new Foundation_Code__c(
                Status__c = Assets.ACTIVE,
                Parent__c = nonBudgetedInitiative.Parent_Initiative__r.Foundation_Code__c,
                System_Triggered__c = true,
                Type__c = Assets.MISC_INITIATIVE_TYPE,
                Foundation_Code__c = nonBudgetedInitiative.Name,
                Initiative__c = nonBudgetedInitiative.Id
            );
            nonBudgetedFCToInsert.add(foundationCode);
            initiativeToFCMap.put(nonBudgetedInitiative.Id, foundationCode);
        }
    }

    /**
    * Description : Method to update non budgeted initiative with foundation code
    * Parameters : initiatives List<IM_Initiative__c>
    * Return Type : void
    */
    private void updateNonBudgetedInitiative(List<IM_Initiative__c> initiatives){
        for(IM_Initiative__c initiative : initiatives){
            initiative.Foundation_Code__c = initiativeToFCMap.get(initiative.Id).Id;
        }
    }


}