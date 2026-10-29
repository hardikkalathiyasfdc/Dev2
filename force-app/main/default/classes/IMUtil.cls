/**
 * Author      : Paddy
 * Date        : 11/29/2024
 * Jira        : IM-63
 * Description : This class is Util class for Initiative Management.
 * Modified By :
 * Test        : IMUtilTest
 * ChangeLog   :
 * Sai Bhargav Thotakura on Dec 2024 - IM-50 - Created "getBudgetRows", "getAllComponents" methods for Checkout Budget Implementation
 * Sai Bhargav Thotakura on Jan 2025 - IM-49 - Created "getInitiative", "getSegmentTeamRecord", "getContactList", "getStrategicLocations" methods for Initiative Sync with BGive
 * Paddy on Feb 2025 - IM-116 - Added new fields to the SOQL on getBudgetRowsByBudget method.
 * Paddy on Sep 2025 - IM-374 - Updated showHideTemplateColumns method to check BudgetCategories for empty string instead of 'None'.
 * Gauri on Jan 2026 - IM-500 - Added Method to get Non Budgeted Grants related to an IM Grant
 */
public with sharing class IMUtil {
	//Global Variables
	public static IM_Budget__c triggerBudRec;
	private static final String AMENDMENT_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.AMENDMENT)
		.getRecordTypeId();

	//Returns List<IM_Template_Mapping__mdt> based on Type and SubType
	public static List<IM_Template_Mapping__mdt> fetchTemplatesByTypeAndSubtype(String type, String subtype) {
		return [
			SELECT Id, Label, DeveloperName, Type__c, Sub_Type__c, Template_Name__c
			FROM IM_Template_Mapping__mdt
			WHERE Type__c = :type AND Sub_Type__c = :subtype
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description : Method to get Budget by Id
	 * Parameters  : budgetId Id
	 * Return Type : IM_Budget__c
	 */
	public static IM_Budget__c getBudget(Id budgetId) {
		IM_Budget__c budget = [
			SELECT
				Name,
				Budget_Amount__c,
				Budget_Categories__c,
				Component__c,
				SubComponent__c,
				Geography__c,
				Budget_Term_Years__c,
				Budget_Term_months__c,
				Duration_Run_Rate__c,
				Duration_months__c,
				Run_Rate__c,
				Initiative__c,
				Initiative__r.Partner_Funding_Type__c,
				Initiative__r.Open_Amendment__c,
				Initiative__r.Open_Amendment__r.Amendment_Number__c,
				Initiative__r.Current_Budget__c,
				Initiative__r.Open_Amendment__r.End_Date__c,
				Initiative__r.Start_Date__c,
				Initiative__r.RecordType.Name,
				Initiative__r.Initiative_Type__c,
				Partner__c,
				Partner_Role__c,
				Partner_Partner_Role__c,
				Payee_Fiscal_Sponsor__c,
				Proposed_Amount__c,
				Status__c,
				Sub_Partner__c,
				Sub_Partner_Type__c,
				SubPartner_SubPartner_Type__c,
				Type_of_Work__c,
				Unique_Identifier__c,
				Version__c,
				Partner_Fund__c,
				External_Id__c,
				Checked_Out_At__c,
				Checked_Out_By__c,
				Last_Checked_In_At__c,
				Last_Checked_In_By__c,
				Is_Active__c,
				Total_Budget_Amount__c
			FROM IM_Budget__c
			WHERE Id = :budgetId
			WITH SYSTEM_MODE
			LIMIT 1
		] ?? null;
		return budget;
	}
	
	/**
	 * Description : Method to get Budget Orgs related to a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Budget_Org__c>
	 */
	public static List<IM_Budget_Org__c> getBudgetOrgs(Id budgetId) {
		List<IM_Budget_Org__c> budgetOrgs = [
			SELECT Id, Name, Organization__c, Type__c, Organization__r.Name, External_Id__c, Deleted__c
			FROM IM_Budget_Org__c
			WHERE Budget__c = :budgetId
			WITH SYSTEM_MODE
			ORDER BY CreatedDate ASC
		];
		return budgetOrgs;
	}

	/**
	 * Description : Method to get Budget Orgs related to a Budget which are not marked for deletion
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Budget_Org__c>
	 */
	public static List<IM_Budget_Org__c> getActiveBudgetOrgs(Id budgetId) {
		List<IM_Budget_Org__c> budgetOrgs = [
			SELECT Id, Name, Organization__c, Type__c, Organization__r.Name, External_Id__c, Deleted__c
			FROM IM_Budget_Org__c
			WHERE Budget__c = :budgetId AND Deleted__c = false
			WITH SYSTEM_MODE
			ORDER BY CreatedDate ASC
		];
		return budgetOrgs;
	}

	/**
	 * Description : Method to get Budget Grants related to a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Budget_Grant__c>
	 */
	public static List<IM_Budget_Grant__c> getBudgetGrants(Id budgetId) {
		List<IM_Budget_Grant__c> budgetGrants = [
			SELECT Id, Name, Unique_Identifier__c, Budget_Org__c, Budget_Org__r.Name
			FROM IM_Budget_Grant__c
			WHERE Budget__c = :budgetId
			WITH SYSTEM_MODE
		];
		return budgetGrants;
	}

	/**
	 * Description : Method to get Components related to a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Component__c>
	 */
	public static List<IM_Component__c> getComponents(Id budgetId) {
		List<IM_Component__c> components = [
			SELECT Id, Name, Parent_Component__c, Type__c, External_Id__c
			FROM IM_Component__c
			WHERE Budget__c = :budgetId AND Type__c = 'Component'
			WITH SYSTEM_MODE
			ORDER BY CreatedDate ASC
		];
		return components;
	}

	/**
	 * Description : Method to get SubComponents related to a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Component__c>
	 */
	public static List<IM_Component__c> getSubComponents(Id budgetId) {
		List<IM_Component__c> subComponents = [
			SELECT Id, Name, Parent_Component__c, Type__c, External_Id__c
			FROM IM_Component__c
			WHERE Budget__c = :budgetId AND Type__c = 'SubComponent'
			WITH SYSTEM_MODE
			ORDER BY CreatedDate ASC
		];
		return subComponents;
	}

	/**
	 * Description : Method to get Geography related to a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Geography__c>
	 */
	public static List<IM_Geography__c> getGeography(Id budgetId) {
		List<IM_Geography__c> geography = [
			SELECT Id, Name, External_Id__c
			FROM IM_Geography__c
			WHERE Budget__c = :budgetId
			WITH SYSTEM_MODE
			ORDER BY CreatedDate ASC
		];
		return geography;
	}

	/**
	 * Description : Method to get Budget Periods related to a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Budget_Period__c>
	 */
	public static List<IM_Budget_Period__c> getBudgetPeriods(Id budgetId) {
		List<IM_Budget_Period__c> budgetPeriods = [
			SELECT Id, Name, Period__c, Period_Start_Date__c, Period_End_Date__c, Period_Label__c
			FROM IM_Budget_Period__c
			WHERE Budget__c = :budgetId
			WITH SYSTEM_MODE
		];
		return budgetPeriods;
	}

	/**
	 * Description : Method to get Budget Rows for a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Budget_Row__c>
	 */
	public static List<IM_Budget_Row__c> getBudgetRowsByBudget(Id budgetId) {
		List<IM_Budget_Row__c> budgetRows = [
			SELECT
				Id,
				Name,
				Budget_Grant__c,
				Description__c,
				Duration_months__c,
				Notes__c,
				Partner__c,
				Partner_Role__c,
				Payee_Fiscal_Sponsor__c,
				Sub_Partner__c,
				Sub_Partner_Type__c,
				Type_of_Work__c,
				Unique_Identifier__c,
				Component__c,
				Geography__c,
				SubComponent__c,
				Period_1_Amount__c,
				Period_2_Amount__c,
				Period_3_Amount__c,
				Period_4_Amount__c,
				Period_5_Amount__c,
				Period_6_Amount__c,
				Period_7_Amount__c,
				Period_8_Amount__c,
				Period_9_Amount__c,
				Period_10_Amount__c,
				Partner_Fund__c,
				Is_Locked__c
			FROM IM_Budget_Row__c
			WHERE Budget__c = :budgetId
			WITH SYSTEM_MODE
		];
		return budgetRows;
	}

	/**
	 * Description  : Query all the IM_Components based on the budget id
	 * Parameters   : Accepts BudgetId
	 * Return Type  : Returns List of All Components associated with the BudgetId
	 */
	public static List<IM_Component__c> getAllComponents(Id budgetId) {
		List<IM_Component__c> componentData = [
			SELECT Id, Name, Parent_Component__r.Name, Type__c
			FROM IM_Component__c
			WHERE Budget__c = :budgetId
			WITH SYSTEM_MODE
			ORDER BY Type__c ASC
		];
		return componentData;
	}

	/**
	 * Description  : Query all the IM_Budget_Row__c based on the budget id
	 * Parameters   : Accepts BudgetId
	 * Return Type  : Returns List of All Budget Rows associated with the BudgetId
	 */
	public static List<IM_Budget_Row__c> getBudgetRows(Id budgetId) {
		List<IM_Budget_Row__c> budgetRows = [
			SELECT
				Id,
				Component__r.Name,
				Geography__r.Name,
				SubComponent__r.Name,
				Description__c,
				Duration_months__c,
				Notes__c,
				Partner__r.Name,
				Partner_Role__c,
				Payee_Fiscal_Sponsor__r.Name,
				Run_Rate__c,
				Sub_Partner__r.Name,
				Partner__r.Organization__r.Name,
				Payee_Fiscal_Sponsor__r.Organization__r.Name,
				Sub_Partner__r.Organization__r.Name,
				Total_Amount__c,
				Sub_Partner_Type__c,
				Type_of_Work__c,
				Unique_Identifier__c,
				Partner_Fund__c,
				Partner_Fund__r.Name,
				Period_1_Amount__c,
				Period_2_Amount__c,
				Period_3_Amount__c,
				Period_4_Amount__c,
				Period_5_Amount__c,
				Period_6_Amount__c,
				Period_7_Amount__c,
				Period_8_Amount__c,
				Period_9_Amount__c,
				Period_10_Amount__c,
				Is_Locked__c
			FROM IM_Budget_Row__c
			WHERE Budget__c = :budgetId AND Total_Amount__c != 0
			WITH SYSTEM_MODE
		];
		return budgetRows;
	}

	/**
	 * Description  : Query the template record based on the identifier value received
	 * Parameters   : Accepts String Identifier value
	 * Return Type  : Returns template record.
	 */
	public static Template__c getTemplate(String identifier) {
		Template__c tempRec = [
			SELECT Id, File_Id__c, Active__c, Identifier__c, Metadata__c
			FROM Template__c
			WHERE Active__c = TRUE AND Identifier__c = :identifier
			WITH SYSTEM_MODE
		] ?? null;
		return tempRec;
	}

	/**
	 * Description  : Query the Content Version based on the FileId received.
	 * Parameters   : Accepts String File Id
	 * Return Type  : Returns ContentVersion.
	 */
	public static ContentVersion getContentVersion(String fileId) {
		ContentVersion cv = [
			SELECT VersionData
			FROM ContentVersion
			WHERE ContentDocumentId = :fileId
			WITH SYSTEM_MODE
		] ?? null;
		return cv;
	}

	/**
	 * Description  : Query the Initiative Record based on the Initiative Id received.
	 * Parameters   : Accepts String Initiative Id
	 * Return Type  : IM_Initiative__c record
	 */
	public static IM_Initiative__c getInitiative(String initiativeId) {
		IM_Initiative__c initiativeRec = [
			SELECT
				Id,
				Bgive_Id__c,
				CityView_Display_Name__c,
                CityView_Description__c, 
				Initiative_Type__c,
				Focus_Area__r.Bgive_API_Name__c,
				Start_Date__c,
				Original_Approved_Date__c,
				Approved_Date__c,
				Name,
				Program_Contact__c,
				Approved_Amount__c,
				Grants_Team_Contact__c,
				Original_Approved_Amount__c,
				Segment__r.Name,
				Team__r.Name,
				Team__r.Bgive_Id__c,
				Foundation_Code__r.Parent__r.Initiative__r.Bgive_Id__c,
				Status__c,
				End_Date__c,
				Original_End_Date__c,
				Bgive_IM_Connection__c
			FROM IM_Initiative__c
			WHERE Id = :initiativeId
			WITH SYSTEM_MODE
		] ?? null;
		return initiativeRec;
	}

	/**
	 * Description  : Query the Segment Team Record based on the SegmentTeam Name.
	 * Parameters   : Accepts String SegmentTeam Name
	 * Return Type  : Segment_Team__c record
	 */
	public static Segment_Team__c getSegmentTeamRecord(String segmentTeamName) {
		Segment_Team__c rec = [
			SELECT Id, Bgive_Id__c
			FROM Segment_Team__c
			WHERE Name = :segmentTeamName
			WITH SYSTEM_MODE
			LIMIT 1
		] ?? null;
		return rec;
	}

	/**
	 * Description  : Query the Segment Team Record based on the SegmentTeam Name.
	 * Parameters   : Accepts String SegmentTeam Name
	 * Return Type  : Segment_Team__c record
	 */
	public static Segment_Team__c getSegmentTeam(String segmentId, String teamId) {
		Segment_Team__c rec = [
			SELECT Id, Bgive_Id__c
			FROM Segment_Team__c
			WHERE Segment__c = :segmentId AND Team__c = :teamId
			WITH SYSTEM_MODE
			LIMIT 1
		] ?? null;
		return rec;
	}

	/**
	 * Description  : Query the Contact Record based on the UserId Set.
	 * Parameters   : Accepts UserId Set
	 * Return Type  : Contact List
	 */
	public static List<Contact> getContactList(Set<String> userIds) {
		return [
			SELECT Id, BRM_User__c, Bgive_Id__c
			FROM Contact
			WHERE BRM_User__c IN :userIds AND Bgive_Id__c != NULL
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description  : Query the Strategic Locations associated with initiative id received.
	 * Parameters   : Accepts String Initiative Id
	 * Return Type  : IM_Strategic_Locations__c record
	 */
	public static List<IM_Strategic_Locations__c> getStrategicLocations(String initiativeId) {
		return [
			SELECT Id, Geo_Area__r.DAMA_Id__c
			FROM IM_Strategic_Locations__c
			WHERE Initiative__c = :initiativeId AND Geo_Area__r.DAMA_Id__c != NULL AND Deleted__c = false
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description  : Query the Strategic Locations associated with initiative ids received.
	 * Parameters   : Set<Id> InitiativeIds
	 * Return Type  : Map<Id, IM_Strategic_Locations__c>
	 */
	public static Map<Id, IM_Strategic_Locations__c> getStrategicLocations(Set<Id> initiativeIds) {
		return new Map<Id, IM_Strategic_Locations__c>([
			SELECT Id, Name, Geo_Area__c, Initiative__c, Start_Date__c, End_Date__c, Deleted__c
			FROM IM_Strategic_Locations__c
			WHERE Initiative__c IN :initiativeIds
			WITH SYSTEM_MODE
		]);
	}

	/**
	 * Description  : Query the Strategic Locations associated with initiative id set.
	 * Parameters   : Map of Initiatives with Id
	 * Return Type  : Map<String, List<IM_Strategic_Locations__c>> initiative id and strategic locations list
	 */
	public static List<IM_Strategic_Locations__c> getStrategicLocations(Set<String> initiativeIdSet) {
		return [
			SELECT Id, Name, Geo_Area__c, Initiative__c, Start_Date__c, End_Date__c, Deleted__c
			FROM IM_Strategic_Locations__c
			WHERE Initiative__c IN :initiativeIdSet AND Deleted__c = false
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description  : Query the BGive Sync Field Mapping metadata records for the specified object string
	 * Parameters   : Accepts String object name
	 * Return Type  : List<Bgive_Sync_Field_Mapping__mdt>
	 */
	public static List<Bgive_Sync_Field_Mapping__mdt> getBGiveSyncFieldMapList(String objectName) {
		return [
			SELECT
				Id,
				Label,
				DeveloperName,
				Bgive_Attribute_Name__c,
				Default_Value__c,
				BRM_Field__c,
				BRM_Field_Type__c,
				Mapping_Type__c,
				Sync_Mode__c,
				(
					SELECT
						Id,
						Label,
						DeveloperName,
						BRM_Value__c,
						Bgive_Field_Value__c,
						Bgive_Sync_Field_Mapping__c,
						Bgive_Sync_Field_Mapping__r.BRM_Field__c,
						Bgive_Sync_Field_Mapping__r.Bgive_Attribute_Name__c
					FROM Bgive_Field_Value_Mappings__r
				)
			FROM Bgive_Sync_Field_Mapping__mdt
			WHERE BRM_Object__c = :objectName
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description  : Query the BGive Field value Mapping metadata records for the specified piclist field
	 * Parameters   : Accepts String mappingName
	 * Return Type  : List<Bgive_Field_Value_Mapping__mdt>
	 */
	public static List<Bgive_Field_Value_Mapping__mdt> getBGiveFieldValueMapList(Id picklistMappingId) {
		return [
			SELECT Id, Bgive_Field_Description__c, Bgive_Field_Value__c, BRM_Value__c, Bgive_Sync_Field_Mapping__c
			FROM Bgive_Field_Value_Mapping__mdt
			WHERE Bgive_Sync_Field_Mapping__c = :picklistMappingId
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description   : get Checkout Out information based on the passed Budget Id
	 * Parameters    : Accepts String budget Id
	 * Return Type   : String - Checkout By
	 */
	public static String getCheckoutInformation(String budgetId) {
		String CheckedOutBy = '';
		IM_Budget__c bud = [
			SELECT Id, Checked_Out_At__c, Checked_Out_By__r.Name
			FROM IM_Budget__C
			WHERE Id = :budgetId
			WITH SYSTEM_MODE
		];
		if (bud.Checked_Out_At__c != null && bud.Checked_Out_By__r.Name != null) {
			CheckedOutBy = bud.Checked_Out_By__r.Name;
		}
		return CheckedOutBy;
	}

	/**
	 * Description  : Insert MB_Error__c Records in case of exceptions.
	 * Parameters   : Accepts String - Object Records Id, String - Error Message, String - Type
	 * Return Type  : None
	 */
	public static void insertMBErrors(String id, String errMsg, String type) {
		MB_Error__c errLog = new MB_Error__c(Object_Id__c = id, OwnerId = UserInfo.getUserId(), Type__c = type, Description__c = errMsg);
		insert as system errLog;
	}

	/**
	 * Description    : update the checkboxes to maintain 1:1 mapping for the budget template cols
	 * Parameters     : Accepts IM_Budget__c record
	 * Return Type    : IM_Budget__c record.
	 */
	@AuraEnabled
	public static IM_Budget__c updateCheckboxes(IM_Budget__c budgetRec) {
		//calling helper method to update checkboxes based on values in the passed budget record.
		showHideTemplateColumns(budgetRec);
		return triggerBudRec;
	}

	/**
	 * Description   : Show/Hide Budget and Budget Parameter Columns based on the budget record
	 * Parameters    : Accepts IM_Budget__C record
	 * Return Type   : Void
	 */
	private static void showHideTemplateColumns(IM_Budget__c budgetRecord) {
		triggerBudRec = budgetRecord;
		triggerBudRec.Duration_months__c = triggerBudRec.Run_Rate__c = budgetRecord.Duration_Run_Rate__c;
		triggerBudRec.Partner__c = triggerBudRec.Partner_Role__c = budgetRecord.Partner_Partner_Role__c;
		triggerBudRec.Sub_Partner__c = triggerBudRec.Sub_Partner_Type__c = budgetRecord.SubPartner_SubPartner_Type__c;
		triggerBudRec.Unique_Identifier__c = budgetRecord.Unique_Identifier__c;
		triggerBudRec.Payee_Fiscal_Sponsor__c = budgetRecord.Payee_Fiscal_Sponsor__c;
		triggerBudRec.Partner_Fund__c = budgetRecord.Partner_Fund__c;
		triggerBudRec.Type_of_Work__c = budgetRecord.Type_of_Work__c;
		//Component
		if (budgetRecord.Budget_Categories__c == Assets.BUDGET_CATEGORY_1) {
			//trigger rec
			triggerBudRec.Component__c = true;
			triggerBudRec.SubComponent__c = false;
			triggerBudRec.Geography__c = false;
		}
		//Component,Geography - Geography,Component
		if (budgetRecord.Budget_Categories__c == Assets.BUDGET_CATEGORY_2 || budgetRecord.Budget_Categories__c == Assets.BUDGET_CATEGORY_6) {
			//trigger rec
			triggerBudRec.Component__c = true;
			triggerBudRec.SubComponent__c = false;
			triggerBudRec.Geography__c = true;
		}
		//Component,SubComponent
		if (budgetRecord.Budget_Categories__c == Assets.BUDGET_CATEGORY_3) {
			//trigger rec
			triggerBudRec.Component__c = true;
			triggerBudRec.SubComponent__c = true;
			triggerBudRec.Geography__c = false;
		}
		//Component,SubComponent,Geography - Geography,Component,SubComponent
		if (budgetRecord.Budget_Categories__c == Assets.BUDGET_CATEGORY_4 || budgetRecord.Budget_Categories__c == Assets.BUDGET_CATEGORY_7) {
			//trigger rec
			triggerBudRec.Component__c = true;
			triggerBudRec.SubComponent__c = true;
			triggerBudRec.Geography__c = true;
		}
		//Geography
		if (budgetRecord.Budget_Categories__c == Assets.BUDGET_CATEGORY_5) {
			//trigger rec
			triggerBudRec.Component__c = false;
			triggerBudRec.SubComponent__c = false;
			triggerBudRec.Geography__c = true;
		}
		//None
		if (String.isEmpty(budgetRecord.Budget_Categories__c)) {
			//trigger rec
			triggerBudRec.Component__c = false;
			triggerBudRec.SubComponent__c = false;
			triggerBudRec.Geography__c = false;
		}
	}

	/**
	 * Description : Method to get Initiatives based on RenewalOf and Initiative_Type__c equals 'Renewal'
	 *               and Status not equal to Declined
	 * Parameters  : Set<Id> renewalOfIds Id
	 * Return Type : List<IM_Initiative__c>
	 */
	public static List<IM_Initiative__c> getInitiativesByRenewalIds(Set<Id> renewalOfIds) {
		return [
			SELECT Renewal_of__c
			FROM IM_Initiative__c
			WHERE Renewal_of__c IN :renewalOfIds AND Initiative_Type__c = 'Renewal' AND Status__c != 'Declined'
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description : Method to get partner funds associated with Budget
	 * Parameters  : Budget Id
	 * Return Type : List<IM_Partner_Fund__c>
	 */
	public static List<IM_Funding_Source__c> getPartnerFunds(Id budgetId) {
		return [
			SELECT Name, Partner__c
			FROM IM_Funding_Source__c
			WHERE Budget__c = :budgetId
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description: Method to query and retrieve the IM_Grant__c record
	 * Parameters : Accepts the imgrantRecId
	 * Return Type: IM_Grant__c record
	 */
	public static IM_Grant__c getImGrant(String imGrantId) {
		IM_Grant__c grantRec = [
			SELECT
				Id,
				Amount_Term__c,
				Bgive_Amount_Local__c,
				Bgive_Contig_Id__c,
				Bgive_Id__c,
				Bgive_IM_Connection__c,
				Bgive_Status__c,
				Budget_Amount_Local__c,
				Budget_Amount_USD__c,
				Confirmed_Budget_Amount_Local__c,
				Confirmed_Budget_Amount_USD__c,
				Currency__c,
				Currency__r.Bgive_Id__c,
				Currency__r.Name,
				Data_JSON__c,
				Deleted__c,
				End_Date__c,
				Fund__r.Bgive_Api_Name__c,
				Funded_By_Multiple_Initiatives__c,
				Name,
				OwnerId,
				Sync_Error__c,
				Project_Title_Internal__c,
				Partner_Org__c,
				Partner_Org__r.Name,
				Partner_Org__r.Bgive_Id__c,
				Pending_Action__c,
				Start_Date__c,
				Status__c,
				Tax_Status__c,
				Type_of_Work__c,
				Fund__c,
				Fund__r.Name,
				Amendment_Bgive_Id__c,
				Amendment_Future_Amount_Local__c,
				Amendment_Future_End_Date__c,
				Bgive_Program_Organization_Id__c,
				Bgive_Grantee_Name__c,
				Pending_Action_Alert_Message__c,
				Total_Amount_USD__c,
				Total_Amount_Local__c
			FROM IM_Grant__c
			WHERE Id = :imGrantId
			WITH SYSTEM_MODE
		] ?? null;
		return grantRec;
	}

	/**
	 * Description: get the Budget Rows aggregate result
	 * Parameters : accepts budgetId
	 * Return Type: List<AggregateResult>
	 */
	public static List<AggregateResult> getTotalAmountsByPartner(String budgetId) {
		List<AggregateResult> aggregatedBudgetRows = new List<AggregateResult>();
		if (budgetId != null) {
			aggregatedBudgetRows = [
				SELECT SUM(Total_Amount__c) totalAmount, Partner_Fund__r.Name partnerName
				FROM IM_Budget_Row__c
				WHERE Budget__c = :budgetId
				WITH SYSTEM_MODE
				GROUP BY Partner_Fund__r.Name
			];
		}
		return aggregatedBudgetRows;
	}

	/**
	 * Description : Method to get Funding Partners related to a Budget
	 * Parameters  : budgetId Id
	 * Return Type : List<IM_Funding_Source__c>
	 */
	public static List<IM_Funding_Source__c> getFundingPartners(Id budgetId) {
		List<IM_Funding_Source__c> fundingPartners = [
			SELECT Name, Allocated_Amount__c, Amount__c, Partner__c
			FROM IM_Funding_Source__c
			WHERE Budget__c = :budgetId
			WITH SYSTEM_MODE
			ORDER BY CreatedDate ASC
		];
		return fundingPartners;
	}

	/**
	 * Description : Method to get the initiative records with fields data needed for amendment record creation
	 * Parameters  : initiative Id
	 * Return Type : IM_Initiative__c
	 */
	public static IM_Initiative__c getMainInitiative(String initiativeId) {
		IM_Initiative__c mainInitiative = [
			SELECT
				Name,
				Initiative_Type__c,
				Status__c,
				Team__c,
				Amendment_Number__c,
				Amendment_of__c,
				Approved_Amount__c,
				Original_Approved_Amount__c,
				End_Date__c,
				Program_Contact__c,
				Proposed_Amount__c,
				Start_Date__c,
				Open_Amendment__c,
				Current_Budget__c,
				Segment__c,
				Focus_Area__c,
				External_Milestone_Date__c,
				External_Milestone_Explanation__c,
				Grants_Team_Contact__c,
				Original_End_Date__c,
				Partner_Funds__c,
				Partner_Funding_Type__c,
				Parent_Initiative__c,
				Parent_Initiative_Name__c,
				CityView_Initiative__c
			FROM IM_Initiative__c
			WHERE Id = :initiativeId
			WITH SYSTEM_MODE
			LIMIT 1
		] ?? null;
		return mainInitiative;
	}

	/**
	 * Description : Query Budget Grants based on the initiative id received
	 * Parameters  : String Initiative Id
	 * Return Type : List<IM_Budget_Grant__c> budGrants
	 */
	public static List<IM_Budget_Grant__c> getBudgetGrantsOfCurrBudget(String currentBudgetId) {
		return [
			SELECT
				Bgive_IM_Connection__c,
				Budget__c,
				Budget_Amount_Local__c,
				Budget_Amount_USD__c,
				Budget_Grant_Amount_Term__c,
				Budget_Grant_Name__c,
				Name,
				Budget_Org__c,
				Budget_Org__r.Name,
				Budget_Org__r.Budget__c,
				Budget_Org__r.Organization__c,
				Budget_Org__r.Type__c,
				Confirmed_Budget_Amount_Local__c,
				Confirmed_Budget_Amount_USD__c,
				End_Date__c,
				External_Id__c,
				Fund__c,
				Funded_By_Multiple_Initiatives__c,
				IM_Grant__c,
				Is_Active__c,
				Deleted__c,
				Start_Date__c,
				Status__c,
				Type__c,
				Unique_Identifier__c
			FROM IM_Budget_Grant__c
			WHERE Budget__c = :currentBudgetId AND Deleted__c = FALSE
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description : return budgetOrs using set of budget orgs id
	 * Parameters  : Set<id> budgetOrgId
	 * Return Type : List<IM_Budget_Org__c> budOrgs
	 */
	public static List<IM_Budget_Org__c> getBudgetOrgsUsingIdSet(Set<Id> budOrgIdSet) {
		return [
			SELECT Id, Name, Budget__c, External_Id__c, Organization__c, Type__c
			FROM IM_Budget_Org__c
			WHERE ID IN :budOrgIdSet
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description : return cloned Budget record using the id
	 * Parameters  : String clonedBudgetId
	 * Return Type : IM_Budget__c
	 */
	public static IM_Budget__c getClonedBudget(String clonedBudgetId) {
		IM_Budget__c budgetRec = [
			SELECT
				Id,
				Is_Active__c,
				Initiative__c,
				Initiative__r.Open_Amendment__c,
				Initiative__r.Open_Amendment__r.Amendment_Number__c,
				Initiative__r.Current_Budget__c,
				Initiative__r.Open_Amendment__r.End_Date__c,
				Initiative__r.Start_Date__c
			FROM IM_Budget__c
			WHERE Id = :clonedBudgetId
			WITH SYSTEM_MODE
		] ?? null;
		return budgetRec;
	}

	/**
	 * Description : return list of approvals for the given Initiative Id
	 * Parameters  : String initiativeId
	 * Return Type : List<IM_Approval__c>
	 */
	public static List<IM_Approval__c> getApprovals(String initiativeId) {
		return [
			SELECT Approval_Date__c, Name, Approved_Amount_Term__c, Approver__c, Initiative__c
			FROM IM_Approval__c
			WHERE Initiative__c = :initiativeId
			WITH SYSTEM_MODE
			ORDER BY CreatedDate DESC
		];
	}

	/**
	 * Description  : Query the BGive Field value Mapping metadata records for the Grant object
	 * Parameters   : String objectName
	 * Return Type  : List<Bgive_Field_Value_Mapping__mdt>
	 */
	public static List<Bgive_Field_Value_Mapping__mdt> getBGiveFieldValuesByObject(String label) {
		return [
			SELECT
				Id,
				Label,
				DeveloperName,
				Sort_Order__c,
				BRM_Value__c,
				Bgive_Field_Value__c,
				Bgive_Sync_Field_Mapping__c,
				Bgive_Sync_Field_Mapping__r.BRM_Field__c,
				Bgive_Sync_Field_Mapping__r.Bgive_Attribute_Name__c
			FROM Bgive_Field_Value_Mapping__mdt
			WHERE Label LIKE :label
			WITH SYSTEM_MODE
			ORDER BY Sort_Order__c NULLS LAST, BRM_Value__c
		];
	}

	/**
	 * Description  : Method to query BGive Field value Mapping metadata records and form Map of picklist keys (Bgive value) and values (BRM value)
	 * Parameters   : String objectName
	 * Return Type  : Map<String, Map<String,String>>
	 */
	public static Map<String, Map<String, String>> getPicklistValuesFromMetadata(String objectName) {
		List<Bgive_Field_Value_Mapping__mdt> bgiveFieldValueMapping = new List<Bgive_Field_Value_Mapping__mdt>();
		Map<String, Map<String, String>> picklistValMap = new Map<String, Map<String, String>>();

		switch on objectName {
			when 'IM_Grant__c' {
				bgiveFieldValueMapping = IMUtil.getBGiveFieldValuesByObject('Grant%');
			}
			when 'IM_Initiative__c' {
				bgiveFieldValueMapping = IMUtil.getBGiveFieldValuesByObject('Initiative%');
			}
			when else {
				IMUtil.insertMBErrors('', 'Object not found', Assets.IM_BRM_ERRORS);
			}
		}

		//Fill picklist value map
		for (Bgive_Field_Value_Mapping__mdt valueMapping : bgiveFieldValueMapping) {
			String fieldName = valueMapping.Bgive_Sync_Field_Mapping__r.Bgive_Attribute_Name__c;
			if (picklistValMap.get(fieldName) == null) {
				picklistValMap.put(fieldName, new Map<String, String>());
			}
			picklistValMap.get(fieldName).put(valueMapping.Bgive_Field_Value__c, valueMapping.BRM_Value__c);
		}
		return picklistValMap;
	}

	/**
	 * Description  : Method to query the BGive Field value Mapping metadata records to get list of BRM values for UI
	 * Parameters   : String objectName
	 * Return Type  : Map<String, List<String>>
	 */
	public static Map<String, List<String>> getBgiveFieldToValueMap(String objectName) {
		List<Bgive_Field_Value_Mapping__mdt> bgiveFieldValueMapping = new List<Bgive_Field_Value_Mapping__mdt>();
		Map<String, List<String>> picklistValMap = new Map<String, List<String>>();

		switch on objectName {
			when 'IM_Grant__c' {
				bgiveFieldValueMapping = IMUtil.getBGiveFieldValuesByObject('Grant%');
			}
			when 'IM_Initiative__c' {
				bgiveFieldValueMapping = IMUtil.getBGiveFieldValuesByObject('Initiative%');
			}
			when else {
				IMUtil.insertMBErrors('', 'Object not found', Assets.IM_BRM_ERRORS);
			}
		}

		//Fill picklist value map
		for (Bgive_Field_Value_Mapping__mdt valueMapping : bgiveFieldValueMapping) {
			String fieldName = valueMapping.Bgive_Sync_Field_Mapping__r.Bgive_Attribute_Name__c;
			if (picklistValMap.get(fieldName) == null) {
				picklistValMap.put(fieldName, new List<String>());
			}
			picklistValMap.get(fieldName).add(valueMapping.BRM_Value__c);
		}
		return picklistValMap;
	}

	/**
	 * Description  : Method to get a Foundation Code by Id
	 * Parameters   : String recordId
	 * Return Type  : Foundation_Code__c
	 */
	public static Foundation_Code__c getFoundationCodeById(String recordId) {
		return [
			SELECT
				Id,
				Name,
				Parent__c,
				Type__c,
				Focus_Area__r.Name,
				Initiative__r.Id,
				Initiative__r.Name,
				Initiative__r.RecordTypeId,
				Initiative__r.RecordType.DeveloperName,
				Initiative__r.Total_Committed_Amount_USD__c,
				Initiative__r.Start_Year__c,
				Initiative__r.End_Year__c,
				Initiative__r.Amendment_Number__c,
				Initiative__r.Announcement_Count__c,
				Initiative__r.Program_Overview_Alert__c
			FROM Foundation_Code__c
			WHERE Id = :recordId
			WITH SYSTEM_MODE
		] ?? null;
	}

	/**
	 * Description  : Method to get Initiative Amendment Records which are Approved
	 * Parameters   : Set<Id> recordIds
	 * Return Type  : List<IM_Initiative__c>
	 */
	public static List<IM_Initiative__c> getApprovedAmendments(Set<Id> recordIds) {
		return [
			SELECT
				Id,
				Name,
				Total_Committed_Amount_USD__c,
				Start_Year__c,
				End_Year__c,
				Amendment_Number__c,
				Amendment_of__c,
				Original_Approved_Amount__c,
				Original_End_Date__c
			FROM IM_Initiative__c
			WHERE Amendment_of__c IN :recordIds AND RecordTypeId = :AMENDMENT_RECORD_TYPE_ID AND Approved__c = TRUE
			WITH SYSTEM_MODE
			ORDER BY Amendment_Number__c
		] ?? null;
	}

	/**
	 * Description : Returns the Value by truncating based on the parameters specifications
	 * Parameters  : Integer maxSize, String fieldValue, String prefix, String suffix
	 * Return Type : new sub String with prefix or suffix
	 */
	public static String truncateFieldValue(Integer maxSize, String fieldValue, String prefix, String suffix) {
		//Genric Truncating Logic
		String valueToReturn;
		String truncatedFieldValue = fieldValue.length() > maxSize ? fieldValue.substring(0, maxSize) : fieldValue;
		//Once truncated, attach the prefix, suffix as needed.
		if (String.isNotBlank(prefix)) {
			valueToReturn = prefix + truncatedFieldValue;
		} else {
			valueToReturn = truncatedFieldValue + suffix;
		}
		return valueToReturn;
	}

	/**
	 * Description : Method to get the user access level
	 * Parameters  : recordId Id
	 * Return Type : UserRecordAccess
	 */
	@AuraEnabled(cacheable=true)
	public static UserRecordAccess getUserAccessLevel(Id recordId) {
		return [
			SELECT RecordId, MaxAccessLevel, HasDeleteAccess
			FROM UserRecordAccess
			WHERE UserId = :UserInfo.getUserId() AND RecordId = :recordId
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description : Method to get the user access level
	 * Parameters  : Set<id> recordId
	 * Return Type : List<UserRecordAccess>
	 */
	public static List<UserRecordAccess> getUserAccessLevel(Set<Id> recordId) {
		return [
			SELECT RecordId, MaxAccessLevel, HasDeleteAccess, HasTransferAccess, HasAllAccess
			FROM UserRecordAccess
			WHERE UserId = :UserInfo.getUserId() AND RecordId IN :recordId
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description : Method to get all children (Budget Grants) of an IMGrant
	 * Parameters : imGrantId Id
	 * Return Type : List<IM_Budget_Grant__c>
	 */
	public static List<IM_Budget_Grant__c> getIMGrantChildren(Id imGrantId) {
		return [
			SELECT Id, Deleted__c, Is_Active__c, Budget__c, Budget__r.Checked_Out_By__c
			FROM IM_Budget_Grant__c
			WHERE IM_Grant__c = :imGrantId
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description : Method to handle errors
	 * Parameters : resultsDatabase.SaveResult[]
	 * Return Type : void
	 */
	public static void processErrors(Database.SaveResult[] results) {
		String errors = '';
		for (Database.SaveResult result : results) {
			if (!result.isSuccess()) {
				for (Database.Error error : result.getErrors()) {
					errors += error.toString() + ', ';
				}
			}
		}
		if (!String.isBlank(errors)) {
			IMUtil.insertMBErrors('', errors, Assets.IM_BRM_ERRORS);
		}
	}

	/**
	 * Description : Method to display amounts in Billion, Million, etc. format (eg. 1000000 as 1M, 100000 as 100K, etc.)
	 * Parameters : amount Decimal
	 * Return Type : String
	 */
	public static String formatAmount(Decimal amount) {
		String formattedAmount = '';
		if (amount > 1000000000) {
			formattedAmount += amount.divide(1000000000, 2) + 'B';
		} else if (amount > 1000000) {
			formattedAmount += amount.divide(1000000, 2) + 'M';
		} else if (amount > 1000) {
			formattedAmount += amount.divide(1000, 0) + 'k';
		} else {
			formattedAmount += amount;
		}
		return formattedAmount;
	}

	/**
	 * Description :
	 * Parameters  : Id field - recordId
	 * Return Type : IM_Review__c record
	 */
	@AuraEnabled(cacheable=true)
	public static IM_Review__c fetchReview(Id recordId) {
		return [
			SELECT Id, Initiative__c, CreatedDate
			FROM IM_Review__c
			WHERE Id = :recordId
			WITH SYSTEM_MODE
			LIMIT 1
		];
	}

	/**
	 * Description : query the active budgets list using the id key set
	 * Parameters  : Set<Id> activeBudgetIds
	 * Return Type : List<IM_Budget__c>
	 */
	public static List<IM_Budget__c> getActiveBudgets(Set<Id> activeBudgetIdSet) {
		return [
			SELECT
				Id,
				Partner_Fund__c,
				SubPartner_SubPartner_Type__c,
				Partner_Partner_Role__c,
				Run_Rate__c,
				Duration_months__c,
				Type_of_Work__c,
				Payee_Fiscal_Sponsor__c,
				Duration_Run_Rate__c,
				Unique_Identifier__c,
				Disable_Budget_Options__c
			FROM IM_Budget__c
			WHERE Id IN :activeBudgetIdSet
			WITH USER_MODE
		];
	}

	/**
	 * Description : Method to get all children (Non Budget Grants) of an IMGrant
	 * Parameters : imGrantId Id
	 * Return Type : List<IM_Non_Budget_Grant__c>
	 */
	public static List<IM_Non_Budget_Grant__c> getNonBudgetedGrants(Id imGrantId) {
		return [
			SELECT Id, Non_Budget_Grant_Name__c, Budget_Amount_USD__c, Budget_Amount_Local__c, Initiative__c, Initiative__r.Name
			FROM IM_Non_Budget_Grant__c
			WHERE IM_Grant__c = :imGrantId
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description	: Formats Date as yyyy-MM-dd format.
	 * Parameters	: Date dateValue.
	 * Return Type	: String if its date-only else null.
	 */
	public static String formatDateForApi(Date dateValue) {
		if(dateValue == null) {
			return null;
		}
		return DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day()).format('yyyy-MM-dd');
	}
    
    /**
	 * Description : Method to get Contact record based on Bgive Id.
	 * Parameters  : String bgiveId
	 * Return Type : String
	 */
	public static String getContactNameByBgiveId(String bgiveId) {
		List<Contact> contacts = [SELECT Name
							FROM Contact
							WHERE Bgive_Id__c = :bgiveId
							WITH SYSTEM_MODE
							LIMIT 1
						];
		return contacts.isEmpty() ? bgiveId : contacts[0].Name;
	}
    
    /**
	 * Description : Method to get all children (Budget Grants) of an IMGrant
	 * Parameters : imGrantId Id
	 * Return Type : Map<Id, IM_Budget_Grant__c>
	 */
	public static Map<Id, IM_Budget_Grant__c> getBudgetGrantsByIMGrant(Id imGrantId) {
		Map<Id, IM_Budget_Grant__c> budgetGrantMap = new Map<Id, IM_Budget_Grant__c>([SELECT Id, Deleted__c, Is_Active__c, Budget__c, Budget__r.Checked_Out_By__c, Budget_Org__c, Unique_Identifier__c
			FROM IM_Budget_Grant__c
			WHERE IM_Grant__c = :imGrantId
			WITH SYSTEM_MODE
		]);
		return budgetGrantMap;
	}

	/**
	 * Description : Method to get Organization record based on Id.
	 * Parameters  : Id partnerId
	 * Return Type : Account
	 */
	public static Account getPartnerById(Id partnerId) {
		return [SELECT Name, Bgive_Id__c, AKA__c
					FROM Account
					WHERE Id = :partnerId
					WITH SYSTEM_MODE
					LIMIT 1
				] ?? null;
	}

	/**
	 * Description : Method to get Budget Orgs related to a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Budget_Org__c>
	 */
	public static List<IM_Budget_Org__c> getPartnerBudgetOrgs(List<Id> budgetIds, Id partnerId) {
		List<IM_Budget_Org__c> budgetOrgs = [
			SELECT Id, Name, Organization__c, Type__c, Deleted__c, Budget__c
			FROM IM_Budget_Org__c
			WHERE Budget__c IN :budgetIds AND Organization__c = :partnerId AND Type__c = 'Partner'
			WITH SYSTEM_MODE
		];
		return budgetOrgs;
	}

	/**
	 * Description : Method to get Budget Rows related to a Budget
	 * Parameters : budgetId Id
	 * Return Type : List<IM_Budget_Row__c>
	 */
	public static List<IM_Budget_Row__c> getBudgetRowsByGrant(List<Id> budgetIds, List<Id> budgetGrantIds) {
		List<IM_Budget_Row__c> budgetRows = [
			SELECT
				Id, Unique_Identifier__c, Partner__c, Total_Amount__c, Budget__c
			FROM IM_Budget_Row__c
			WHERE Budget__c IN :budgetIds AND Budget_Grant__c IN :budgetGrantIds
			WITH SYSTEM_MODE
		];
		return budgetRows;
	}

	/**
	 * Description : Method to get Budget Grants related to a Budget
	 * Parameters : budgetIds List<Id>
	 * Return Type : List<IM_Budget_Grant__c>
	 */
	public static List<IM_Budget_Grant__c> getBudgetGrantsByBudgets(List<Id> budgetIds) {
		List<IM_Budget_Grant__c> budgetGrants = [
			SELECT
				Id, Unique_Identifier__c, Budget_Org__c, Budget__c
			FROM IM_Budget_Grant__c
			WHERE Budget__c IN :budgetIds
			WITH SYSTEM_MODE
		];
		return budgetGrants;
	}
}