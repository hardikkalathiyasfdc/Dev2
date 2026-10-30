// BIM Requested Amount fix — E2E test data setup (dev2Current)
// Preps grant a0obc000003FE49AAG (IMGRANT-288227) for a "Push to Bgive" (SINGLE_CREATE):
// activates its budget grant with amounts so Budget/Total rollups = 100,000,
// links partner org (JHU, Bgive 14523), dates, title, and builds Data_JSON__c
// with real Bgive reference ids found in this sandbox.

Id grantId = 'a0obc000003FE49AAG';
Id budgetGrantId = 'a0Rbc000006iqc9EAA';

IM_Budget_Grant__c bg = [
	SELECT Id, Is_Active__c, Budget_Amount_Local__c, Confirmed_Budget_Amount_Local__c
	FROM IM_Budget_Grant__c
	WHERE Id = :budgetGrantId
];
bg.Is_Active__c = true;
bg.Budget_Amount_Local__c = 100000;
bg.Confirmed_Budget_Amount_Local__c = 100000;
update bg;

IM_Grant__c g = [
	SELECT Id, Partner_Org__c, Bgive_IM_Connection__c, Start_Date__c, End_Date__c, Project_Title_Internal__c, Data_JSON__c
	FROM IM_Grant__c
	WHERE Id = :grantId
];
g.Partner_Org__c = '001bc00000hFflXAAS'; // JHU — Bgive program org id 14523
g.Bgive_IM_Connection__c = 'IM Managed';
g.Start_Date__c = Date.today();
g.End_Date__c = Date.today().addYears(1);
g.Project_Title_Internal__c = 'BIM Requested Amount E2E TEST';
g.Data_JSON__c = JSON.serialize(
	new Map<String, Object>{
		'IM_Grant__c' => new Map<String, Object>{
			'program_id' => '2', // Team Arts (Bgive id 2)
			'program_sfid' => 'a0Mbc000001aFmLEAU', // Team Arts SF id (segment/team resolution)
			'segment_id' => 'a0Lbc000008zk3SEAQ', // Segment SF id -> Segment_Team Bgive id 20
			'program_lead_id' => '0054v00000DzYzgAAF', // user -> Contact Jenny Kane (Bgive 38267)
			'operations_contact' => '0054v00000DzYzgAAF',
			'project_summary' => 'BIM requested-amount E2E test - safe to delete in Bgive',
			'foundation_initiatives' => '1966', // Engg Arts initiative Bgive id
			'initiative_relationship' => '1966',
			'fiscal_organization_exists' => 'No',
			'type_of_agreement' => 'BFF Invoice',
			'bbg_department_on_behalf_of' => '78BF - Philanthropies',
			'lobbying_advocacy' => 'No',
			'political_campaign_expenses' => 'No',
			'is_this_grant_restricted' => 'Not Restricted',
			'request_type' => 'Service Provider',
			'model_theme_id' => 'BP Grant/SPA',
			'type_of_support' => 'Mission Support'
		}
	}
);
update g;

IM_Grant__c checkRec = [
	SELECT Id, Total_Amount_Local__c, Budget_Amount_Local__c, Sync_Error__c
	FROM IM_Grant__c
	WHERE Id = :grantId
];
System.debug('SETUP DONE: Total_Amount_Local__c=' + checkRec.Total_Amount_Local__c
	+ ' Budget_Amount_Local__c=' + checkRec.Budget_Amount_Local__c
	+ ' Sync_Error__c=' + checkRec.Sync_Error__c);
