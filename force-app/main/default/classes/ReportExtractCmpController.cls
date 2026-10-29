/*
 *   test class: ReportExtractCmpControllerTest
 */
public without sharing class ReportExtractCmpController {
    private static Map<Id, Campaign> listMap = new Map<Id, Campaign> ();
    private static Set<Id> listIds = new Set<Id> ();
	private static final String ERR_GETDATA_FAILED = 'ReportExtractCmpController_getData_FAILED';
	private static final String ERR_GETOPTIONS_FAILED = 'ReportExtractCmpController_getOptions_FAILED';
	private static final String ERR_GETREPORTEXTRACT_FAILED = 'ReportExtractCmpController_getReportExtract_FAILED';
	private static final String ERR_GETEVTMAP_FAILED = 'ReportExtractCmpController_getEvtMap_FAILED';
    
    @AuraEnabled(cacheable=true)
    public static Object getData(DateTime startTime, DateTime endTime) {
		Map<String, Object> results = new Map<String, Object>();
		try {
			startTime = startTime != null ? startTime : DateTime.now().addDays(-7);
			endTime = endTime != null ? endTime : DateTime.now();
			results.put('data', getReportExtract(startTime, endTime));
			results.put('startTime', startTime);
			results.put('endTime', endTime);
		} catch(Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GETDATA_FAILED));
		}
		return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
		try {
			Schema.DescribeFieldResult fieldResult = ReportEvent.Operation.getDescribe();
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			for(Schema.PicklistEntry f : ple) {
				options.add(
					new Map<String, String> {
						'val' => f.getValue(),
						'label' => f.getLabel()
					}
				);
			}
		} catch(Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GETOPTIONS_FAILED));		
		}
        return options;
    }
    
    private static List<Object> getReportExtract(DateTime startTime, DateTime endTime) {
		List<Map<String, Object>> extractList = new List<Map<String, Object>>();
		try {
			List<ReportEvent> eventList = [
				SELECT Id, Report.Name, ReportId, EventDate, User.Name, UserId, Operation, RowsProcessed, Records
				FROM ReportEvent
				WHERE EventDate >= :startTime AND EventDate <= :endTime WITH SYSTEM_MODE
				ORDER BY EventDate DESC
				LIMIT 20001
			];
			Set<Id> userIds = new Set<Id> ();
			Map<Id, User> userMap = new Map<Id, User> ();
			
			for(ReportEvent evt : eventList) {
				userIds.add(evt.UserId);
			}
			
			if(!userIds.isEmpty()) {
				userMap = new Map<Id, User> ([SELECT Id, BP_Team__c FROM User WHERE Id IN :userIds WITH SYSTEM_MODE]);
			}
			
			
			for(ReportEvent evt : eventList) {
				extractList.add(getEvtMap(evt, userMap));
			}
			
			if(!listIds.isEmpty()) {
				listMap = new Map<Id, Campaign> ([SELECT Id, Name FROM Campaign WHERE Id IN :listIds WITH SYSTEM_MODE]);
				
				for(Map<String, Object> extract: extractList) {
					if(extract.get('listId') != null) {
						extract.put('listName', listMap.get(String.valueOf(extract.get('listId'))).Name);
					}
				}
			}
		} catch(Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GETREPORTEXTRACT_FAILED));
		}
        return extractList;
    }
    
    @TestVisible
    private static Map<String, Object> getEvtMap(ReportEvent evt, Map<Id, User> userMap) {
        Map<String, Object> evtMap = new Map<String, Object>();
		try {
			evtMap.put('id', evt.Id);
			evtMap.put('reportName', evt.Report.Name);
			evtMap.put('reportId', evt.ReportId);
			evtMap.put('rowsProcessed', evt.RowsProcessed);
			if(!String.isBlank(evt.ReportId)) {
				evtMap.put('reportUrl', '../../' + evt.ReportId);
			}
			if(userMap != null && userMap.get(evt.UserId) != null) {
				evtMap.put('userTeam', userMap.get(evt.UserId).BP_Team__c);
			}
			evtMap.put('userName', evt.User.Name);
			evtMap.put('userId', evt.UserId);
			if(!String.isBlank(evt.UserId)) {
				evtMap.put('userUrl', '../../' + evt.UserId);
			}
			evtMap.put('operation', evt.Operation);
			evtMap.put(
				'eventDate',
				evt.EventDate != null ? evt.EventDate.format() : ''
			);
			evtMap.put(
				'eventDateVal',
				evt.EventDate != null ? evt.EventDate.getTime() : null
			);
			
			if(evt.Records != null && evt.Report.Name == 'List with List Members') {
				ReportEventRecords recordData = (ReportEventRecords)JSON.deserialize(evt.Records,ReportEventRecords.Class);
				if(!recordData.rows.isEmpty() && !recordData.rows[0].dataCells.isEmpty()) {
					evtMap.put('listUrl', '../../' + recordData.rows[0].dataCells[0]);
					evtMap.put('listId', recordData.rows[0].dataCells[0]);
					listIds.add(recordData.rows[0].dataCells[0]);
				}
			}
		} catch(Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GETEVTMAP_FAILED));
		}
        return evtMap;
    }
}