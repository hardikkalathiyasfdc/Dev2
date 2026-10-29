/**
 * Author      : Sai Bhargav Thotakura
 * Date        : Jun 24th 2025
 * Jira        : IM-134
 * Description : Test Class for BGiveApiSync
 */
@IsTest
public class BGiveApiSyncTest {
	//Mock Respons for grant_request
	public class GrantMockResponseGenerator implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse resp = new HttpResponse();
			resp.setHeader('Content-Type', 'application/json');
			resp.setStatusCode(200);
			List<Object> existingRecords = new List<Object>{ new Map<String, Object>{ 'id' => 'a1' }, new Map<String, Object>{ 'id' => 'a2' } };
			String mockJson = JSON.serialize(new Map<String, Object>{ 'records' => new Map<String, Object>{ 'grant_request' => existingRecords } });
			resp.setBody(mockJson);
			return resp;
		}
	}

	//Mock Respons for concept_initative
	public class InitiativeMockResponseGenerator implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse resp = new HttpResponse();
			resp.setHeader('Content-Type', 'application/json');
			resp.setStatusCode(200);
			List<Object> existingRecords = new List<Object>{ new Map<String, Object>{ 'id' => 'a1' }, new Map<String, Object>{ 'id' => 'a2' } };
			String mockJson = JSON.serialize(new Map<String, Object>{ 'records' => new Map<String, Object>{ 'concept_initiative' => existingRecords } });
			resp.setBody(mockJson);
			return resp;
		}
	}

	@TestSetup
	static void setup() {
		//Bypass SegmentTeam Validation
		Bypass_Automation_Setting__c bypassSetting = new Bypass_Automation_Setting__c();
		bypassSetting.Segment_Team_Validation__c = true;
		bypassSetting.Foundation_Code_Validation__c = true;
		insert bypassSetting;
        
        TestDataFactory.createInitiativeBaseData();
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
        
		IM_Grant__c imGrantRec = TestDataFactory.createIMGrant();
	}

	@IsTest
	private static void testSyncForGrant() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new GrantMockResponseGenerator());
		List<String> columns = new List<String>{
			'contig_id',
			'state',
			'amount_recommended_local',
			'project_title_internal',
			'grant_begins_at',
			'grant_closed_at'
		};
		String syncRecordId = [SELECT Id FROM IM_Grant__c LIMIT 1]?.Id;
		SObject syncRecord = IMUtil.getImGrant(syncRecordId);
		syncRecord.put(
			'Data_JSON__c',
			JSON.serialize(
				new Map<String, Object>{
					'IM_Grant__c' => new Map<String, Object>{
						'grant_agreement_required' => (Object) 'No',
						'type_of_agreement' => (Object) 'BFF Invoice',
						'Funded_By_Multiple_Initiatives__c' => (Object) 'No',
						'Start_Date__c' => (Object) '12/31/2021',
						'Budget_Amount_Local__c' => (Object) '100000',
						'bbg_department_on_behalf_of' => (Object) '78BF - Philanthropies',
						'End_Date__c' => (Object) '12/31/2024',
						'Currency__r.Bgive_Id__c' => (Object) 'a123b4',
						'foundation_initiatives' => (Object) 'b265181',
						'Fund__r.Bgive_Api_Name__c' => (Object) 'Partner',
						'Id' => (Object) '0056g000002P9vwAAC',
						'initiative_relationship' => (Object) 'Partial',
						'fiscal_organization_exists' => (Object) 'No',
						'fiscal_organization_id' => (Object) 'bcdisoa',
						'lobbying_advocacy' => (Object) 'No',
						'political_campaign_expenses' => (Object) 'No',
						'is_this_grant_restricted' => (Object) 'Restricted',
						'program_id' => (Object) '3sbauos',
						'program_lead_id' => (Object) '0056g000002P9vwAAC',
						'Partner_Org__r.Bgive_Id__c' => (Object) 'ydsi1719',
						'project_summary' => (Object) 'This is a project summary',
						'Project_Title_Internal__c' => (Object) 'This is an Internal Project Title',
						'request_type' => (Object) 'Service Provider',
						'operations_contact' => (Object) '0056g000002P9vwAAC',
						'segment_id' => (Object) 'Partial',
						'Bgive_Status__c' => (Object) 'Draft',
						'Bgive_IM_Connection__c' => (Object) 'IM Managed',
						'model_theme_id' => (Object) 'BP Grant/SPA',
						'type_of_support' => (Object) 'Mission Support'
					}
				}
			)
		);
		Map<String, Object> result = BGiveApiSync.sync(syncRecord, 'IM_Grant__c', columns);
		Assert.isTrue(result != null);
		Test.stopTest();
	}

	@IsTest
	private static void testSyncForInitiative() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new InitiativeMockResponseGenerator());
		String syncRecordId = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0']?.Id;
		SObject syncRecord = IMUtil.getInitiative(syncRecordId);
		String teamId = [SELECT Id FROM Team__c LIMIT 1]?.Id;
		String segmentId = [SELECT Id FROM Segment__c LIMIT 1]?.Id;
		syncRecord.put('Segment__c', JSON.serialize(segmentId));
		syncRecord.put('Team__c', JSON.serialize(teamId));
		Map<String, Object> result = BGiveApiSync.sync(syncRecord, 'IM_Initiative__c');
		Assert.isNotNull(result);
		Test.stopTest();
	}
}