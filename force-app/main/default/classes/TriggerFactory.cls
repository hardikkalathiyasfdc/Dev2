/**
 * Class TriggerFactory
 * Used to instantiate and execute Trigger Handlers associated with sObjects.
**/
public with sharing class TriggerFactory {

	/**
    *  This variable is used to hold mapping of trigger class name and respective custom setting field.
    *  This is used to set byPassMap based on custom setting field value.
    */
	static Map<String, String> bypassFieldMapping {
		get {
			if (bypassFieldMapping == null) {
				bypassFieldMapping = new Map<String, String>();
                bypassFieldMapping.put('UserTriggerHandler','User_Trigger__c'); 
				bypassFieldMapping.put('AccountTriggerHandler', 'Account_Trigger__c');
				bypassFieldMapping.put('ContactTriggerHandler', 'Contact_Trigger__c');
				bypassFieldMapping.put('InteractionTriggerHandler', 'Interaction_Trigger__c');
				bypassFieldMapping.put('OrganizationAnnualMetricsHandler', 'Organization_Annual_Metrics_Trigger__c');
				bypassFieldMapping.put('FoundationCodeHandler', 'Foundation_Code_Trigger__c');
				bypassFieldMapping.put('AssociationTriggerHandler', 'Association_Trigger__c');
				bypassFieldMapping.put('FundraisingProjectTriggerHandler', 'Fundraising_Project_Trigger__c');
				bypassFieldMapping.put('CampaignTriggerHandler', 'Campaign_Trigger__c');
				bypassFieldMapping.put('CampaignMemberTriggerHandler', 'Campaign_Member_Trigger__c');
				bypassFieldMapping.put('OpportunityTriggerHandler', 'Opportunity_Trigger__c');
                bypassFieldMapping.put('ContentDocumentLinkHandler','ContentDocumentLink_Trigger__c');
                bypassFieldMapping.put('ContentDocumentHandler','ContentDocument_Trigger__c');
				bypassFieldMapping.put('PledgeTriggerHandler','Pledge_Trigger__c');
                bypassFieldMapping.put('DonorTriggerHandler','Donor_Trigger__c');
                bypassFieldMapping.put('PaymentTriggerHandler','Payment_Trigger__c');
                bypassFieldMapping.put('RecipientOrganizationTriggerHandler','Recipient_Organization_Trigger__c');
                bypassFieldMapping.put('ElectedOfficeTriggerHandler','Elected_Office_Trigger__c');
                bypassFieldMapping.put('GeoAreaTriggerHandler','Geo_Area_Trigger__c');
                bypassFieldMapping.put('TagsTriggerHandler','Tags_Trigger__c');
                bypassFieldMapping.put('OrgAssociationTriggerHandler','Organization_Association_Trigger__c');
                bypassFieldMapping.put('EmploymentHistoryBoardMemTriggerHandler','Employment_Board_Affiliation_Trigger__c');
                bypassFieldMapping.put('FocusAreaTriggerHandler', 'Focus_Area_Trigger__c');
				bypassFieldMapping.put('TeamTriggerHandler', 'Team_Trigger__c');
				bypassFieldMapping.put('SegmentTeamTriggerHandler', 'Segment_Team_Trigger__c');
                bypassFieldMapping.put('IMBudgetedInitiativeHandler', 'IM_Initiative_Trigger__c');
				bypassFieldMapping.put('IMAmendmentInitiativeHandler', 'IM_Initiative_Trigger__c');
				bypassFieldMapping.put('IMParentInitiativeHandler', 'IM_Initiative_Trigger__c');
				bypassFieldMapping.put('IMApprovalTriggerHandler', 'IM_Approval_Trigger__c');
				bypassFieldMapping.put('IMStrategicLocationsTriggerHandler', 'IM_Strategic_Location_Trigger__c');
				bypassFieldMapping.put('IMReviewTriggerHandler', 'IM_Review_Trigger__c');
				bypassFieldMapping.put('IMBudgetTriggerHandler', 'IM_Budget_Trigger__c');
				bypassFieldMapping.put('IMGeographyTriggerHandler', 'IM_Geography_Trigger__c');
				bypassFieldMapping.put('IMBudgetRowTriggerHandler', 'IM_Budget_Row_Trigger__c');
				bypassFieldMapping.put('IMAnnouncementTriggerHandler', 'IM_Announcement_Trigger__c');
				bypassFieldMapping.put('IMPartnerFundTriggerHandler', 'IM_Funding_Source_Trigger__c');
				bypassFieldMapping.put('IMBudgetGrantTriggerHandler', 'IM_Budget_Grant_Trigger__c');
				bypassFieldMapping.put('IMGrantTriggerHandler', 'IM_Grant_Trigger__c');
				bypassFieldMapping.put('IMComponentTriggerHandler', 'IM_Component_Trigger__c');
				bypassFieldMapping.put('IMBudgetOrgTriggerHandler', 'IM_Budget_Org_Trigger__c');
			}
			return bypassFieldMapping;
		}
		set;
	}

	static Bypass_Automation_Setting__c setting {
		get {
			if (setting == null) {
				setting = Bypass_Automation_Setting__c.getInstance();
			}
			return setting;
		}
		set;
	}

	/**
	 *  This variable will hold value for byPassFlag for TriggerHandler Classes.
	 *  Key : TriggerHandlerClass Name e.g AccountTriggerHandler , Value : true / false
	 *  If value is true for given TriggerHandler , class is skipped from execution.
    **/
	static Map<String, Boolean> bypassMap {
		get {
            if(bypassMap == null) initializeBypassFlags();
			return bypassMap;
		}
		set;
	}

	/**
	 * Public static method to create and execute a trigger handler
	 * Arguments:   Type t - Type of handler to instatiate
	 * Throws a TriggerException if no handler has been found.
	 */
	public static void createAndExecuteHandler(Type t) {
		// Get a handler appropriate to the object being processed
		TriggerHandler handler = getHandler(t);
		// Make sure we have a handler registered, new handlers must be registered in the getHandler method.
		if (handler == null) {
			throw new TriggerException('No Trigger Handler found named: ' + t.getName());
		}
		// Execute the handler to fulfil the trigger
		if (!bypassMap.containsKey(t.getName()) && !(handler.getNewRecords().isEmpty() && handler.getOldRecords().isEmpty())){
		    execute(handler);
		}
	}

	/**
	 * private static method to control the execution of the handler
	 * Arguments:   TriggerHandler handler - A Trigger Handler to execute
    **/
	private static void execute(TriggerHandler handler) {
		// Before Trigger
		if (Trigger.isBefore) {
			// Call the bulk before to handle any caching of data and enable bulkification
			handler.bulkBefore();
			// Iterate through the records to be deleted passing them to the handler.
			if (Trigger.isDelete) {
				for (SObject so : handler.oldRecordList) {
					handler.beforeDelete(so);
				}
            } else if(Trigger.isInsert) { // Iterate through the records to be inserted passing them to the handler.
				for (SObject so : handler.newRecordList) {
					handler.beforeInsert(so);
				}
            } else if(Trigger.isUpdate) { // Iterate through the records to be updated passing them to the handler.
				for (SObject so : handler.oldRecordList) {
					handler.beforeUpdate(so, handler.newRecordMap.get(so.Id));
				}
			}
		} else {
			// Call the bulk after to handle any caching of data and enable bulkification
			handler.bulkAfter();
			// Iterate through the records deleted passing them to the handler.
			if (Trigger.isDelete) {
				for (SObject so : handler.oldRecordList) {
					handler.afterDelete(so);
				}
            } else if(Trigger.isInsert) { // Iterate through the records inserted passing them to the handler.
				for (SObject so : handler.newRecordList) {
					handler.afterInsert(so);
				}
            } else if(Trigger.isUpdate) { // Iterate through the records updated passing them to the handler.
				for (SObject so : handler.oldRecordList) {
					handler.afterUpdate(so, handler.newRecordMap.get(so.Id));
				}
			} else if(Trigger.isUndelete) {
				for (SObject so : handler.newRecordList) {
					handler.afterUndelete(so);
				}
			}
		}
		// Perform any post processing
		handler.andFinally();
	}

	/**
	 * private static method to get the named handler.
	 * Arguments:   Type t - Class of handler to instatiate
	 * Returns:     TriggerHandler - A trigger handler if one exists or null.
	 */
	private static TriggerHandler getHandler(Type t) {
		// Instantiate the type
		Object o = t.newInstance();
		// if its not an instance of TriggerHandler return null
        if(!(o instanceOf TriggerHandler)) return null;
		return (TriggerHandler) o;
	}

	private static void initializeBypassFlags() {
		if (setting != null) {
			bypassMap = new Map<String, Boolean>();
			for (String key : bypassFieldMapping.keySet()) {
                if(setting.get(bypassFieldMapping.get(key)) == true) { 
					bypassMap.put(key, Boolean.valueOf(setting.get(bypassFieldMapping.get(key))));
			}
		}
	}
    }

	/**
	 *  static method to set bypass for particular TriggerHandlerClass explicitly from other class.
	 * Arguments:   String triggerName - Class of handler e.g AccountTriggerHandler
    **/
	public static void setBypass(String triggerName) {
		bypassMap.put(triggerName, true);
	}

	/**
	 *  static method to reset bypass for particular TriggerHandlerClass explicitly from other class.
	 * Arguments:   String triggerName - Class of handler e.g AccountTriggerHandler
    **/
	public static void removeBypass(String triggerName) {
		if (bypassFieldMapping.get(triggerName) != null && setting.get(bypassFieldMapping.get(triggerName)) == true)
			bypassMap.put(triggerName, Boolean.valueOf(setting.get(bypassFieldMapping.get(triggerName))));
		else
			bypassMap.remove(triggerName);
	}

    public class TriggerException extends Exception {}
}