/**
 * Author : Neha Gire
 * Date   : 01-06-2025
 * Jira   : IM-86
 * Description : This class provides methods needed for doing DML operatoins on Projection.
 * Test :
 * ChangeLog   : Sai on Jul 2025 : IM-319: Update Projections Amount value to match the proposed amount value
 * 			   : Paddy on 09/24/2025: IM-392: Added logic to create Projections for Amendment.
 */
public without sharing class IMProjections {

	private static final String ERR_DELETE_PROJECTIONS = 'IMPROJECTIONS_DELETE_FAILED';
	private static final String ERR_UPSERT_PROJECTIONS = 'IMPROJECTIONS_UPSERT_FAILED';

	private static final String AMENDMENT_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.AMENDMENT)
		.getRecordTypeId();

	//Global Variables
	static List<IM_Projections__c> deleteList = new List<IM_Projections__c>();
	static List<IM_Projections__c> upsertList = new List<IM_Projections__c>();

	/**
	 * Description : calls the remove method with the list of ids
	 * Parameters  : Accepts Set<Id> initiativeIds
	 * Return Type : void
	 */
	public static void remove(Set<Id> initiativeIds) {
		remove(new List<Id>(initiativeIds));
	}

	/**
	 * Description : queries the projections to be deleted using the list of Ids received.
	 * Parameters  : Accepts List<Id> initiativeIds
	 * Return Type : void
	 */
	public static void remove(List<Id> initiativeIds) {
		deleteList = [SELECT Id FROM IM_Projections__c WHERE Initiative__c IN :initiativeIds WITH SYSTEM_MODE];
	}

	/**
	 * Description : creates the projections records for the initiatives
	 * Parameters  : Accepts List<IM_Initiative__c> initiatives for which the projections needs to be created/inserted.
	 * Return Type : List<IM_Projections__c> to be inserted/updated
	 */
	public static List<IM_Projections__c> create(List<IM_Initiative__c> initiatives) {
		for (IM_Initiative__c initiative : initiatives) {
			Integer startYear = initiative.Start_Date__c.year();
			Integer endYear = initiative.End_Date__c.year();

			if(initiative.RecordTypeId == AMENDMENT_RECORD_TYPE_ID) {
				 startYear = Date.today().year();
			}

			Long termYear = (endYear - startYear) + 1;
			Decimal amount = initiative.RecordTypeId == AMENDMENT_RECORD_TYPE_ID ? initiative.Change_Total_Amount__c
				: initiative.Proposed_Amount__c;
            
            //Check for division by zero - if termYear is 0, skip creating projections
            if (termYear <= 0) {
                continue;
            }
			Decimal baseAmountPerYear = (amount / termYear).setScale(2, System.RoundingMode.HALF_UP);
			//IM-319: Update Projections Amount value to match the proposed amount value
			Decimal remainderAmount = amount - (baseAmountPerYear * (termYear - 1));
	
			for (Integer i = 0; i < termYear; i++) {
				Decimal yearAmount = baseAmountPerYear;
				if(i == termYear - 1) {
					yearAmount = remainderAmount.setScale(2, System.RoundingMode.HALF_UP);
				}
				upsertList.add(
					new IM_Projections__c(
						Initiative__c = initiative.Id,
						Year__c = String.valueOf(startYear + i),
						Amount__c = yearAmount
					)
				);
			}
		}
		return upsertList;
	}

	/**
	 * Description : Initiates the save DML operation
	 * Parameters  : None
	 * Return Type : void
	 */
	public static void save() {
		BBApps_Crud.doDeleteWithHandling(deleteList, false, ERR_DELETE_PROJECTIONS);
		BBApps_Crud.doUpsertWithHandling(upsertList, false, ERR_UPSERT_PROJECTIONS);
	}
}