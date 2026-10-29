/**
* Author : Gauri Sagane
* Date   : 02/20/2025
* Jira   : IM-109
* Description : This class provides method to sync Initiative with BGive if it fails.
* Test : IMSyncInitiativeControllerTest
*/

public with sharing class IMSyncInitiativeController {

    @AuraEnabled
    public static void syncInitiative(Id initiativeId) {
        Set<Id> initiativeIds = new Set<Id>{initiativeId};
        Database.executeBatch(new BatchIMInitiativeSync(initiativeIds), 1);
    }

}