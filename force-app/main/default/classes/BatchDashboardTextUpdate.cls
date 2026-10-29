public without sharing class BatchDashboardTextUpdate implements Database.Batchable<sObject>, Schedulable {

    private static final String ERR_START         = 'BDTU_START_FAILED';
    private static final String ERR_EXECUTE       = 'BDTU_EXECUTE_FAILED';
    private static final String ERR_DML_UPDATE    = 'BDTU_UPDATE_FAILED';
    private static final String ERR_FINISH        = 'BDTU_FINISH_FAILED';

    private static final String MSG_START         = 'Unable to start BatchDashboardTextUpdate.';
    private static final String MSG_EXECUTE       = 'Failed while executing BatchDashboardTextUpdate chunk.';
    private static final String MSG_DML_UPDATE    = 'Failed to update DashboardText__c records.';
    private static final String MSG_FINISH        = 'Failed while finishing BatchDashboardTextUpdate.';

    public static String query = 'SELECT Id, Link__c, Count__c FROM DashboardText__c WHERE (Link__c LIKE \'%701%\' OR Link__c LIKE \'%00O%\')';

    public void execute(System.SchedulableContext sc) {
        Database.executeBatch(new BatchDashboardTextUpdate(), 1);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator(query);
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_START));
            throw new AuraHandledException(MSG_START);
        }
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        if (scope.isEmpty()) return;

        try {
            Map<Id, Id> reportMap = new Map<Id, Id>();
            Map<Id, Id> listMap   = new Map<Id, Id>();
            List<DashboardText__c> dashList = (List<DashboardText__c>) scope;

            setMap(dashList, reportMap, '00O'); // Reports
            setMap(dashList, listMap,   '701'); // Campaigns (Lists)

            if (!reportMap.isEmpty()) setReportCount(dashList, reportMap);
            if (!listMap.isEmpty())   setListCount(dashList, listMap);

            if (!dashList.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(dashList, false, new BBApps_ErrorCustomFields(ERR_DML_UPDATE));
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_EXECUTE));
            throw new AuraHandledException(MSG_EXECUTE);
        }
    }

    public void finish(Database.BatchableContext BC) {
        
    }

    public void setReportCount(List<DashboardText__c> dashList, Map<Id, Id> reportMap) {
        for (DashboardText__c dash : dashList) {
            Id reportId = reportMap.get(dash.Id);
            if (reportId == null) continue;

            Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
            Decimal count = 0;
            Reports.ReportFactWithDetails factDetails =
                (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');

            if (factDetails != null && factDetails.getAggregates() != null) {
                for (Reports.SummaryValue sumVal : factDetails.getAggregates()) {
                    count = Math.max(count, (Decimal) sumVal.getValue());
                }
            }
            dash.Count__c = count;
        }
    }

    private void setListCount(List<DashboardText__c> dashList, Map<Id, Id> listMap) {
        Set<Id> listIds = new Set<Id>(listMap.values());
        if (listIds.isEmpty()) return;

        Map<Id, Campaign> campMap = new Map<Id, Campaign>(
            [SELECT Id, NumberOfContacts FROM Campaign WHERE Id IN :listIds]
        );

        for (DashboardText__c dash : dashList) {
            Id listId = listMap.get(dash.Id);
            Campaign c = (listId != null) ? campMap.get(listId) : null;
            if (c != null) {
                dash.Count__c    = c.NumberOfContacts;
                dash.Campaign__c = c.Id;
            }
        }
    }

    private void setMap(List<DashboardText__c> scope, Map<Id, Id> myMap, String myType) {
        for (DashboardText__c text : scope) {
            Id myId = getLinkId(text.Link__c, myType);
            if (myId != null) {
                myMap.put(text.Id, myId);
            }
        }
    }

    private Id getLinkId(String link, String myType) {
        if (String.isBlank(link) || String.isBlank(myType)) return null;

        String myId = link.substringAfter(myType);
        if (String.isBlank(myId)) return null;

        myId = myType + myId;
        myId = removeEnd(myId);

        try {
            return Id.valueOf(myId);
        } catch (Exception e) {
            return null;
        }
    }

    private String removeEnd(String myId) {
        List<String> tempArray = myId.split('');
        String temp = '';
        for (String c : tempArray) {
            if (c == '/') break;
            temp += c;
        }
        return temp;
    }
}