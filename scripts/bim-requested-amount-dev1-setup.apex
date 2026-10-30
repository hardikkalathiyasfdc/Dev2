// BIM Requested Amount fix — E2E test data setup (Dev1 / BBDev1Backup10162026v1)
// Preps grant a0oOz000004YgAbIAK (IMGRANT-289879) for "Push to Bgive" (SINGLE_CREATE):
// amounts on its active budget grant (BG-08741) so Budget/Total rollups = 100,000,
// partner org NG Delivery Partner (Bgive 24013), dates, title, and Data_JSON__c
// with real Bgive reference ids from this org.
// NOTE: CMDT GrantRequestedBudgetAmountLocal (None/0) was already deployed to Dev1 via Flosum by the user.

Id grantId = 'a0oOz000004YgAbIAK';
Id budgetGrantId = 'a0ROz0000075RefMAE'; // BG-08741, active

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
g.Partner_Org__c = '001Oz000010SkxNIAS'; // NG Delivery Partner — Bgive program org id 24013
g.Currency__c = 'a0FOz000005w6fXMAQ'; // USD — Bgive fx_type_id 1 (required by Bgive on create)
g.Bgive_IM_Connection__c = 'IM Managed';
g.Start_Date__c = Date.today();
g.End_Date__c = Date.today().addYears(1);
g.Project_Title_Internal__c = 'BIM Requested Amount E2E TEST (Dev1)';
g.Data_JSON__c = JSON.serialize(
	new Map<String, Object>{
		'IM_Grant__c' => new Map<String, Object>{
			'program_id' => '2', // Team Arts (Bgive id 2)
			'program_sfid' => 'a0MOz00000DFjQLMA1', // Team Arts SF id (segment/team resolution)
			'segment_id' => 'a0LOz00000DqObRMAV', // Segment SF id -> Segment_Team Bgive id 20
			'program_lead_id' => '0054v00000FUmZOAA1', // user -> Contact Gauri Sagane (Bgive 64545)
			'operations_contact' => '0054v00000FUmZOAA1',
			'project_summary' => 'BIM requested-amount E2E test - safe to delete in Bgive',
			'foundation_initiatives' => '2357', // BB Engg Arts initiative Bgive id
			'initiative_relationship' => '2357',
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
System.debug('SETUP DONE (Dev1): Total_Amount_Local__c=' + checkRec.Total_Amount_Local__c
	+ ' Budget_Amount_Local__c=' + checkRec.Budget_Amount_Local__c
	+ ' Sync_Error__c=' + checkRec.Sync_Error__c);
