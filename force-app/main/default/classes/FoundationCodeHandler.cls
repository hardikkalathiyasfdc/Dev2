/**
* Author      : Paddy
* Date        : 05/02/2024
* Jira        : BRME-5267
* Description : This class is the handler class for Foundation Code trigger.
* Change Log  : Neha - BRME-5261 : Change code to set full path and level fields when code is moved under
*               different parent or code's name is changed.
*               Neha - BRME-5261 : added setMigrateId() to set BGive Migrate Id.
*               Paddy - IM-103 : added method updateInitiativeFocusArea.
*               Paddy - IM-108 : added logic to update Initiative name when Foundation Code is updated.
*               Paddy - IM-503 : Removed the static declaration from the variable initiativesToUpdate which caused
*                                the Initiative Name not to update due the value persistence across execution.
*               Paddy - IM-550 : Implemented logic to call BatchIMInitiativeSync when FoundationCode is re-parented.
*               Paddy - IM-588 : 07/08/2026 - Send email notification when a Level 2 Foundation Code is created or its name changes (FC_Level_2_Notification template).
*				Paddy - IM-589 : 07/16/2026 - Updated Initiative Name sync logic to use Foundation Code Name instead of Name.
*				Neha  - BRME-6797 : 07/20/2026 - Added method to validate the Projected Total Enablement Change.
* Test        : FoundationCodeHandlerTest
*/
public with sharing class FoundationCodeHandler extends TriggerHandler {

    private static final String RETIRED_ERROR_MESSAGE = 'Foundation Code cannot be retired as child records are active.';
    private static final String DELETED_ERROR_MESSAGE = 'Foundation Code cannot be deleted as child records are not deleted.';
    private static final Integer MISC_SORT_ORDER = 900;
    public List<Foundation_Code__c> newList;
    public List<Foundation_Code__c> oldList;
    public Map<Id,Foundation_Code__c> oldMap;
    public Map<Id,Foundation_Code__c> newMap;

    private static Set<String> foundationCodeUpdateInitiativeIds = new Set<String>();
    private List<IM_Initiative__c> initiativesToUpdate = new List<IM_Initiative__c>();
    private static Map<String, String> foundationCodeNameByInitiativeId = new Map<String, String>();
    private static Map<String, String> fcNameByInitiativeIdOnFCName = new Map<String, String>();

    static Map<String , ChildFoundationCodes> parentToImmediateCodeMap = new Map<String , ChildFoundationCodes>();
    static Map<String,Foundation_Code__c> foundationCodeMap = new Map<String,Foundation_Code__c>();
    static Map<String,Foundation_Code__c> foundationCodeUpdateMap = new Map<String,Foundation_Code__c>();

    private Map<Id, String> notifyActionByFoundationCodeId = new Map<Id, String>();
    private Map<Id, String> oldFoundationCodeNameById = new Map<Id, String>();
    private static final String ACTION_CREATED = 'Created';
    private static final String ACTION_UPDATED = 'Updated';
    private static final String LEVEL_2_CREATE_NOTIFICATION_CONFIG = 'IM_Level_2_FC_Notification_Create';
    private static final String LEVEL_2_UPDATE_NOTIFICATION_CONFIG = 'IM_Level_2_FC_Notification_Update';
    
    private static final String ERR_EMAIL_NOTIFICATION_FAILED = 'EMAIL_NOTIFICATION_FAILED';

    public FoundationCodeHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Foundation_Code__c>) Trigger.oldMap, (Map<Id, Foundation_Code__c>) Trigger.newMap);
    }

    public FoundationCodeHandler(List<Foundation_Code__c> oldList, List<Foundation_Code__c> newList) {
        this.newList = newList;
        this.oldList = oldList;
        initializeData();
    }

    public FoundationCodeHandler(List<Foundation_Code__c> oldList, List<Foundation_Code__c> newList , Map<Id,Foundation_Code__c> oldMap , Map<Id,Foundation_Code__c> newMap){
        this.newList = newList;
        this.oldList = oldList;
        this.oldMap = oldMap;
        this.newMap = newMap;
        initializeData();
    }

    private void initializeData(){
        List<Foundation_Code__c> foundationCodes = [Select Name,Foundation_Code__c,Full_Path__c ,Parent__c,Status__c,Level_0__c,BGive_Migrate_Id__c,Projected_Totals_Set_As__c,Type__c  From Foundation_Code__c WITH SYSTEM_MODE Order By Parent__c ASC];


        for(Foundation_Code__c code : foundationCodes){
            if(!parentToImmediateCodeMap.containsKey(code.Parent__c)){
                 parentToImmediateCodeMap.put(code.Parent__c  , new ChildFoundationCodes());
            }
            parentToImmediateCodeMap.get(code.Parent__c).addFoundationCode(code);
            foundationCodeMap.put(code.Id , code);
         }
    }

    public override void beforeInsert(SObject so) {
        Foundation_Code__c foundationCode = (Foundation_Code__c)so;
        setSortOrder(foundationCode);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Foundation_Code__c fc = (Foundation_Code__c)so;
        if(isFieldChanged(fc, 'Foundation_Code__c')) {
            foundationCodeUpdateInitiativeIds.add(fc.Initiative__c);
            foundationCodeNameByInitiativeId.put(fc.Initiative__c, fc.Foundation_Code__c);
        }
    }

    public override void bulkBefore() {
        if(Trigger.isInsert || Trigger.isUpdate) {
            Set<Id> statusModifiedFCIds = new Set<Id>();
            Set<Id> parentModifiedFCIds = new Set<Id>();
            for (Foundation_Code__c foundationCode : newList) {
                if(Trigger.isInsert) {
                    setFoundationName(foundationCode);
                } else if(Trigger.isUpdate){
                    if(isFieldChanged(foundationCode, Assets.STATUS)) {
                        statusModifiedFCIds.add(foundationCode.Id);
                    }
                    if(isFieldChanged(foundationCode, Assets.FOUNDATION_CODE)) {
                        setFoundationName(foundationCode);
                    }
                }
            }
            if(!statusModifiedFCIds.isEmpty()) {
                for (Foundation_Code__c foundationCode : newList) {
                    ChildFoundationCodes childFoundationCodes = parentToImmediateCodeMap.get(foundationCode.Id);
                    if(childFoundationCodes != null) {
                        if(Assets.RETIRED.equalsIgnoreCase(foundationCode.Status__c) && childFoundationCodes.isActive) {
                            foundationCode.addError(RETIRED_ERROR_MESSAGE);
                        } else if(Assets.DELETED.equalsIgnoreCase(foundationCode.Status__c) &&
                                    (childFoundationCodes.isActive || childFoundationCodes.isRetired)) {
                            foundationCode.addError(DELETED_ERROR_MESSAGE);
                        }
                        }
                    setFoundationName(foundationCode);
                    }
            }
            
            validateProjectedTotalEditability();
            
        }
    }

    public override void bulkAfter() {
        if(Trigger.isAfter ){
            if(Trigger.isInsert){
                updateFullPath(newList);
                syncCodes();
                trackLevel2Notifications(newList, ACTION_CREATED);
         	}else if(Trigger.isUpdate){
                List<Foundation_Code__c> reparentedCodes = new List<Foundation_Code__c>();
                List<Foundation_Code__c> resyncCodes = new List<Foundation_Code__c>();
                List<Foundation_Code__c> reparentedCodesFA = new List<Foundation_Code__c>();
                List<Foundation_Code__c> nameChangedCodes = new List<Foundation_Code__c>();

                // Generate list of code list when parent is changed or name is changed.

                for(Foundation_Code__c code : newList){
                    if(isFieldChanged(code, Assets.PARENT) || isFieldChanged(code, Assets.FOUNDATION_CODE)) {
                        reparentedCodes.add(code);
                    }
                    if(isFieldChanged(code, Assets.PARENT)) {
                        reparentedCodesFA.add(code);
                    }
                    if (isFieldChanged(code, Assets.FOUNDATION_CODE)) {
                        nameChangedCodes.add(code);
                    }
                }
                if(!reparentedCodes.isEmpty()){
                    updateFullPath(reparentedCodes);
                }
                if(!reparentedCodesFA.isEmpty()) {
                    updateInitiativeFocusArea(reparentedCodesFA);
                }

                syncCodes();

                if(!foundationCodeUpdateInitiativeIds.isEmpty()) {
                    updateInitiativeName();
                }
                trackLevel2Notifications(nameChangedCodes, ACTION_UPDATED);
                    }
                }
    }

    public override void andFinally() {
        if(Trigger.isAfter) {
            if(Trigger.isUpdate) {
                update initiativesToUpdate;
            }
            sendLevel2FoundationCodeNotifications();
            }
    }

    private void syncCodes(){


        List<Id> codeIds = new List<Id>();
        for(Foundation_Code__c code : newList){
            if( Trigger.isInsert || ( isFieldChanged(code, Assets.PARENT) || isFieldChanged(code, Assets.FOUNDATION_CODE)
                || isFieldChanged(code,  Assets.STATUS) || isFieldChanged(code, Assets.BGIVE_DESCRIPTION) || isFieldChanged(code, Assets.ENABLE_FOR_GRANTS)
                || isFieldChanged(code, Assets.SORT_ORDER) ) ) {
                    codeIds.add(code.Id);
                }
        }

        if(!codeIds.isEmpty()){
            System.debug(' codeIds'+codeIds);
            Database.executeBatch(new BatchFoundationCodeSync(codeIds), 20);
        }
    }

    // This method will update code and all of its child codes path and level fields.
    private void updateFullPath(List<Foundation_Code__c> codes){

        System.debug(parentToImmediateCodeMap);

        setFullPath(codes);

        if( !foundationCodeUpdateMap.isEmpty()){
            update as system foundationCodeUpdateMap.values();
        }
    }

    /**
     * This method will set full path for changed code and all of its child codes.
     * This method is called recursively to update all child codes for given code.
     * Since number of Foundation Codes is small (in hundreds) and once set up only few records will be updated
     * This method should not run into any performance issue.
     *  */
    private void setFullPath(List<Foundation_Code__c> codes){
        if(!codes.isEmpty()){
            List<Foundation_Code__c> childCodes = new List<Foundation_Code__c>();
            for(Foundation_Code__c code : codes){
                updateCode(code);
                System.debug('>> Child Records' + code.Id+ ' :: ' + parentToImmediateCodeMap.get(code.Id));
                if(parentToImmediateCodeMap.get(code.Id) != null )
                    childCodes.addAll(parentToImmediateCodeMap.get(code.Id).foundationCodes);
            }

            setFullPath(childCodes);
        }else{
            return;
        }
    }

    
    private Foundation_Code__c updateCode(Foundation_Code__c code){
        Foundation_Code__c updateCodeInstance = new Foundation_Code__c(Id = code.Id , Parent__c = code.Parent__c , BGive_Migrate_Id__c = code.BGive_Migrate_Id__c);
        System.debug(code.Parent__c + '::' +foundationCodeMap.get(code.Parent__c));
        if( code.Parent__c == null ){
            updateCodeInstance.Full_Path__c  = code.Foundation_Code__c;
            updateCodeInstance.Level_0__c = code.Foundation_Code__c;
            foundationCodeMap.put(updateCodeInstance.Id , updateCodeInstance);
        }else if(foundationCodeMap.containsKey(code.Parent__c) &&  (foundationCodeMap.get(code.Parent__c)).Parent__c == null ){
            updateCodeInstance.Full_Path__c  = code.Foundation_Code__c;
            updateCodeInstance.Level_0__c = foundationCodeMap.get(code.Parent__c).Level_0__c;
            foundationCodeMap.put(updateCodeInstance.Id , updateCodeInstance);
        }else if(foundationCodeMap.containsKey(code.Parent__c) &&  (foundationCodeMap.get(code.Parent__c)).Parent__c != null){
            updateCodeInstance.Full_Path__c  = foundationCodeMap.get(code.Parent__c).Full_Path__c + ' -> ' + code.Foundation_Code__c;
            updateCodeInstance.Level_0__c = foundationCodeMap.get(code.Parent__c).Level_0__c;
            foundationCodeMap.put(updateCodeInstance.Id , updateCodeInstance);
        }

        updateLevels(updateCodeInstance);

        if(Trigger.isInsert){
            setMigrateId(updateCodeInstance);
        }

        foundationCodeUpdateMap.put(updateCodeInstance.Id , updateCodeInstance);
        return updateCodeInstance;
    }

    private void updateLevels(Foundation_Code__c updateCodeInstance){
        if(updateCodeInstance.Full_Path__c  != null && updateCodeInstance.Parent__c != null){
            String[] pathCodes = updateCodeInstance.Full_Path__c.split(' -> ');
            updateCodeInstance.Level_1__c = updateCodeInstance.Level_2__c =  updateCodeInstance.Level_3__c = updateCodeInstance.Level_4__c  = '';
            if(!pathCodes.isEmpty()){
                updateCodeInstance.Level_1__c = pathCodes[0];
                if(pathCodes.size() > 1){
                    updateCodeInstance.Level_2__c = pathCodes[1];
                }
                if(pathCodes.size() > 2){
                    updateCodeInstance.Level_3__c = pathCodes[2];
                }
                if(pathCodes.size() > 3){
                    updateCodeInstance.Level_4__c = pathCodes[3];
                }
                if(pathCodes.size() > 4){
                    updateCodeInstance.Level_5__c = pathCodes[4];
                }
            }
        }
    }

    private void setFoundationName(Foundation_Code__c fc) {
        if(Assets.ACTIVE.equalsIgnoreCase(fc.Status__c)) {
            fc.Name = fc.Foundation_Code__c;
        } else {
            fc.Name = fc.Foundation_Code__c + ' (' + fc.Status__c.toLowerCase() + ')';
        }
    }

    private void setMigrateId(Foundation_Code__c code) {
            System.debug(' >> BGive_Migrate_Id__c' + code.BGive_Migrate_Id__c);
            if( code.BGive_Migrate_Id__c == null ) {
                code.BGive_Migrate_Id__c = code.Id;
            }
    }

    private void updateInitiativeName() {
        List<IM_Initiative__c> initiatives = [SELECT Name, Focus_Area__c 
                                                FROM IM_Initiative__c 
                                                WHERE Id IN :foundationCodeUpdateInitiativeIds 
                                                WITH SYSTEM_MODE];
        for(IM_Initiative__c initiative : initiatives) {
            if(foundationCodeUpdateInitiativeIds.contains(initiative.Id) && initiative.Name != foundationCodeNameByInitiativeId.get(initiative.Id) && !initiativesToUpdate.contains(initiative)) {
                initiative.Name = foundationCodeNameByInitiativeId.get(initiative.Id);
                initiativesToUpdate.add(initiative);
            }
        }
    }

    private void validateProjectedTotalEditability(){
        for (Foundation_Code__c foundationCode : newList) {
                    ChildFoundationCodes childFoundationCodes = parentToImmediateCodeMap.get(foundationCode.Id);
                    if(childFoundationCodes != null) {
                        if(foundationCode.Projection_Total_Calculated__c == false && childFoundationCodes.isProjectedTotalCalculated){
                             foundationCode.addError('You have chosen a value that is in conflict with another selection. Please review and try again.');
                        }
                        
                    }
              }
        
    }

    public class ChildFoundationCodes {
        public List<Foundation_Code__c> foundationCodes {get; set;}
        public Boolean isActive {get; set;}
        public Boolean isRetired {get; set;}
        public Boolean isDeleted {get; set;}
        // Check if enabled for projected total
        public Boolean isProjectedTotalCalculated {get; set;}


        public ChildFoundationCodes() {
            foundationCodes = new List<Foundation_Code__c>();
            isActive = false;
            isRetired = false;
            isDeleted = false;
            isProjectedTotalCalculated = false;
        }

        public ChildFoundationCodes(List<Foundation_Code__c> foundationCodes) {
            this.foundationCodes = foundationCodes;
        }

        public void addFoundationCode(Foundation_Code__c foundationCode) {
            this.foundationCodes.add(foundationCode);
            if(Assets.ACTIVE.equalsIgnoreCase(foundationCode.Status__c)) {
                this.isActive = true;
            } else if(Assets.RETIRED.equalsIgnoreCase(foundationCode.Status__c)) {
                this.isRetired = true;
            } else if(Assets.DELETED.equalsIgnoreCase(foundationCode.Status__c)) {
                this.isDeleted = true;
            }
            
            if(foundationCode.Projected_Totals_Set_As__c == 'Calculated'){
                this.isProjectedTotalCalculated = true;
            }
        }
    }

    /**
    * Description : Update Focus Area for the related Initiative if Focus Area got changes for the Foundation Code.
    * Parameters : None
    * Return Type : void
    */
    private void updateInitiativeFocusArea(List<Foundation_Code__c> codes) {
        Map<Id, String> initiativeFocusArea = new Map<Id, String>();
        Map<String, Id> focusAreaByNames = new Map<String, Id>();

        for(Foundation_Code__c fc : codes) {
            initiativeFocusArea.put(fc.Initiative__c, foundationCodeUpdateMap.get(fc.Id).Level_1__c);
        }
        for(Focus_Area__c fc : [SELECT Name 
                                FROM Focus_Area__c 
                                WHERE Name IN :initiativeFocusArea.values()
                                WITH SYSTEM_MODE]) {
            focusAreaByNames.put(fc.Name, fc.Id);
        }
        Map<Id, IM_Initiative__c> initiatives = new Map<Id, IM_Initiative__c>(
        												[SELECT Focus_Area__c, Team__r.Focus_Area__c 
                                                        FROM IM_Initiative__c 
                                                        WHERE Id IN :initiativeFocusArea.keySet() 
                                                        WITH SYSTEM_MODE]);
        for(IM_Initiative__c initiative : initiatives.values()) {
            String focusAreaId = focusAreaByNames.get(initiativeFocusArea.get(initiative.Id));
            if(initiative.Focus_Area__c != focusAreaId) {
                initiative.Focus_Area__c = focusAreaId;
                initiativesToUpdate.add(initiative);
            }
        }
        if(!initiatives.isEmpty()) {
            Database.executeBatch(new BatchIMInitiativeSync(initiatives.keySet()), 1);
        }
    }

    /**
    * Description : Set sortorder for Focus Area Misc/Miscellaneous Initiative type.
    * Parameters : Foundation_Code__c foundationCode
    * Return Type : void
    */
    private void setSortOrder(Foundation_Code__c foundationCode) {
        if(Assets.MISC_INITIATIVE_TYPE.equalsIgnoreCase(foundationCode.Type__c) ||
            Assets.FOCUS_AREA_MISC_TYPE.equalsIgnoreCase(foundationCode.Type__c)) {
            foundationCode.Sort_Order__c = MISC_SORT_ORDER;
        }
    }

    /**
    * Description : Tracks Foundation Codes that may qualify for a Level 2 notification.
    *               Level is confirmed in andFinally after path/level fields are persisted.
    * Parameters  : codes List<Foundation_Code__c>, action String
    * Return Type : void
    */
    private void trackLevel2Notifications(List<Foundation_Code__c> codes, String action) {
        if (codes == null || codes.isEmpty()) {
            return;
        }
        for (Foundation_Code__c code : codes) {
            if (!notifyActionByFoundationCodeId.containsKey(code.Id) && isLevel2FoundationCode(code)) {
                notifyActionByFoundationCodeId.put(code.Id, action);
                if (ACTION_UPDATED.equals(action) && oldMap != null && oldMap.containsKey(code.Id)) {
                    oldFoundationCodeNameById.put(code.Id, oldMap.get(code.Id).Foundation_Code__c);
                }
            }
        }
    }

    /**
    * Description : Sends email notifications for Level 2 Foundation Codes that were created or renamed.
    * Parameters  : None
    * Return Type : void
    */
    private void sendLevel2FoundationCodeNotifications() {
        if (notifyActionByFoundationCodeId.isEmpty()) {
            return;
        }
        try {
           	Set<Id> createIds = new Set<Id>();
	        Set<Id> updateIds = new Set<Id>();
           	Map<Id, Map<String, String>> customMergeDataByRecord = new Map<Id, Map<String, String>>();
            for(Id codeId : notifyActionByFoundationCodeId.keySet()) {
                if(ACTION_CREATED.equalsIgnorecase(notifyActionByFoundationCodeId.get(codeId))) {
                    createIds.add(codeId);
                } else {
                    updateIds.add(codeId);
                    if(oldFoundationCodeNameById.containsKey(codeId)) {
                        customMergeDataByRecord.put(
                            codeId, 
                            new Map<String, String>{'oldFoundationCodeName' => oldFoundationCodeNameById.get(codeId)}
                        );
                    }
                }
            }
            if(!createIds.isEmpty()) {
                NotificationService.sendEmail(LEVEL_2_CREATE_NOTIFICATION_CONFIG, createIds);
            }
            if(!updateIds.isEmpty()) {
                NotificationService.sendEmail(LEVEL_2_UPDATE_NOTIFICATION_CONFIG, updateIds, customMergeDataByRecord);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_EMAIL_NOTIFICATION_FAILED));
        }
    }

    /**
    * Description : Returns true when the Foundation Code qualifies as Level 2 for notification.
    * 				On Update, uses Code_Level__c == 2 on the trigger record.
    * 				On Create, prefers foundationCodeUpdateMap (recalculated Level_2__c/Level_3__c)
    * 				because trigger records may not yet reflect path/level changes; a Level 2 code
    * 				has Level_2__c populated and Level_3__c blank.
    * Parameters  : code Foundation_Code__c
    * Return Type : Boolean
    */
    private Boolean isLevel2FoundationCode(Foundation_Code__c code) {
        Foundation_Code__c parentFC = foundationCodeMap.get(code.Parent__c);
        return parentFC != null && Assets.FOCUS_AREA.equalsIgnoreCase(parentFC.Type__c);
    }
}