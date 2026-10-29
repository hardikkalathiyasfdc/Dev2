/*
Author     : Sai Bhargav Thotakura
Date       : 28th May 2025
Jira       : IM-229 : Program Overview UI
Description: Controller class for generating the data for program overview UI.
Change Log : 
Gauri - IM-259 : Changed startYear and endYear variables from Decimal to Integer and added appropriate null checks
Sai - IM-303.  : Updated the createData method to consider Parent inside Parent scenario and update the alert message variable
Gauri - IM-304: Removed the check for Parent RecordType from logic to populate Program Overview Alert field
Gauri - IM-358: Added logic to not create wrapper for zero amount data
Paddy - IM-489: Updated the Apex class to run without sharing and moved getFCAndChildren from IMUtil.
Gauri - IM-543: Added booleans to indicate Totals and Initiative details rows to remove hard coded array access on UI
Test Class : IMProgramOverviewControllerTest
*/
public without sharing class IMProgramOverviewController {


	//Global Variables
	//Record Types
	private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();

	private static final String BUDGETED_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.BUDGET_INITIATIVE)
		.getRecordTypeId();

	private static final String MISC_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.MISC_INITIATIVE_TYPE)
		.getRecordTypeId();

	private static Map<Id, List<Foundation_Code__c>> fcToChildrenMap = new Map<Id, List<Foundation_Code__c>>();
	private static List<InitiativeWrapper> initiativeWrapperList = new List<InitiativeWrapper>();
	private static Map<Id, InitiativeWrapper> budgetedToWrapperMap = new Map<Id, InitiativeWrapper>();
	private static List<List<InitiativeWrapper>> finalResponseList = new List<List<InitiativeWrapper>>();
	private static List<Id> initiativesWithAmendment = new List<Id>();

	private static final String ERR_GET_FOUNDATION_DATA = 'IMPROGRAM_OVERVIEW_CONTROLLER_GET_FOUNDATION_DATA_FAILED';
	private static final String ERR_GET_ALL_FOUNDATION_CODES = 'IMPROGRAM_OVERVIEW_CONTROLLER_GET_ALL_FOUNDATION_CODES_FAILED';
	private static final String ERR_GET_PROGRAM_OVERVIEW_DATA = 'IMPROGRAM_OVERVIEW_CONTROLLER_GET_PROGRAM_OVERVIEW_DATA_FAILED';
	private static final String ERR_CREATE_DATA = 'IMPROGRAM_OVERVIEW_CONTROLLER_CREATE_DATA_FAILED';

	private static final String INCLUDE_FOREIGN_CURRENCY_MSG = 'This initiative includes foreign currency and amounts may be different than multi-year analysis. When giving initiative related numbers use total from BIM.';
	private static final String NOT_IN_BGIVE_MSG = 'This phase includes ${0} funding tracked outside BGive and not included in multi-year analysis. When giving initiative related numbers use total from BIM.';

	/**
	 * Description    : Performs a SOQL to get the record name based on the foundation code record id received.
	 * Parameters     : Accepts String record Id
	 * Return Type    : Foundation_Code__c
	 */
	@AuraEnabled
	public static Foundation_Code__c getFoundationData(String recordId) {
		try {
		return [
			SELECT Id, Name, Type__c, Initiative__r.Focus_Area__r.Name
			FROM Foundation_Code__c
			WHERE Id = :recordId
			WITH SYSTEM_MODE
			LIMIT 1
		];
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_FOUNDATION_DATA));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Description    : Get the Foundation code related to initiative.
	 * Parameters     : Accepts String record Id
	 * Return Type    : Foundation_Code__c
	 */
	@AuraEnabled
	public static Id getFoundationCode(String initiativeId) {
		try {
			IM_Initiative__c initiative = [
				SELECT Id, Name, Foundation_Code__c
				FROM IM_Initiative__c
				WHERE Id = :initiativeId
				WITH SYSTEM_MODE
				LIMIT 1
			];
			return initiative?.Foundation_Code__c;
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_FOUNDATION_DATA));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Description : Method to get base url of current environment
	 * Parameters : none
	 * Return Type : String
	 */
	@AuraEnabled(cacheable=true)
	public static String getBaseUrl() {
		String baseURL = Environment.getBaseUrl();
        return baseURL + '/lightning/n/Program_Overview';
    }

	/**
	 * Description    : Method to get all the Foundation Code data
	 * Parameters     : none
	 * Return Type    : Map<Id, List<Foundation_Code__c>>
	 */
	@AuraEnabled(cacheable=true)
	public static Map<Id, List<Foundation_Code__c>> getAllFoundationCodes() {
		try {
			return getFCAndChildren();
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_ALL_FOUNDATION_CODES));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Description    : Method to get Program Overview Hierarchy Data to render on UI
	 * Parameters     : recordId String, fcToChildrenMap Map<Id, List<Foundation_Code__c>> where recordId is the Foundation Code Id
	 * Return Type    : ProgramOverviewData
	 */
	@AuraEnabled
	public static ProgramOverviewData getProgramOverviewData(String recordId, Map<Id, List<Foundation_Code__c>> fcToChildrenMap) {
		try {
			if (!String.isBlank(recordId)) {
				Foundation_Code__c fc = IMUtil.getFoundationCodeById(recordId);
				fcToChildrenMap = fcToChildrenMap;
				InitiativeWrapper initiativeWrapper;
				// If the record is of type focus area, call the recursive method for each parent
				if (fc.Type__c == Assets.FOCUS_AREA && fcToChildrenMap != null && fcToChildrenMap.get(fc.Id) != null) {
					for (Foundation_Code__c parentInitiativeCode : fcToChildrenMap.get(fc.Id)) {
						ChildrenData data = createData(fcToChildrenMap.get(parentInitiativeCode.Id), fcToChildrenMap);
						// Create wrapper for each child of Focus Area (i.e each child Parent Initiative)
						if (data != null) {
							createFinalInitiativeWrapper(parentInitiativeCode, data);
						}
					}
				}
				// If the record is of type parent initiative, call the recursive method only for this parent
				if (fc.Type__c == Assets.PARENT_INITIATIVE) {
					ChildrenData data = createData(fcToChildrenMap.get(fc.Id), fcToChildrenMap);
					// Create wrapper for the selected Parent Initiative by user
					if (data != null) {
						createFinalInitiativeWrapper(fc, data);
					}
				}

				// Create amendment wrapper for each amendment record in the hierarchy
				createAmendmentWrapper();
			}

			// Method to add Total Amount, Total Budgeted and Total Misc Amonts to the tree grid
			createTotalRows();

			// Create final response wrapper with the treeGridData and budgeted initiative ids
			ProgramOverviewData programOverviewData = new ProgramOverviewData();
			programOverviewData.treeGridData = finalResponseList;
			programOverviewData.budgetedInitiativeIds = new List<Id>(budgetedToWrapperMap.keySet());
			return programOverviewData;
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_PROGRAM_OVERVIEW_DATA));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Description    : Recursive Method to get Initiative data depending on Focus Area/Parent Initiative
	 * Parameters     : codes List<Foundation_Code__c>, fcToChildrenMap Map<Id, List<Foundation_Code__c>>
	 * Return Type    : ChildrenData
	 */
	private static ChildrenData createData(List<Foundation_Code__c> codes, Map<Id, List<Foundation_Code__c>> fcToChildrenMap) {
		try {
			if (!codes.isEmpty()) {
				Decimal totalCommittedAmount = 0;
				Decimal totalBudgetedAmount = 0;
				Decimal miscellaneousAmount = 0;
				Integer startYear = Assets.DECIMAL_MAX_VALUE;
				Integer endYear = 0;
				Integer budgetedStartYear = Assets.DECIMAL_MAX_VALUE;
				Integer budgetedEndYear = 0;
				Integer miscStartYear = Assets.DECIMAL_MAX_VALUE;
				Integer miscEndYear = 0;
				List<InitiativeWrapper> childWrappers = new List<InitiativeWrapper>();
				for (Foundation_Code__c code : codes) {
					InitiativeWrapper initiativeWrapper = createInitiativeWrapper(
						code,
						null,
						code.Initiative__r?.Total_Committed_Amount_USD__c,
						code.Initiative__r?.Start_Year__c != null ? Integer.valueOf(code.Initiative__r?.Start_Year__c) : null,
						code.Initiative__r?.End_Year__c != null ? Integer.valueOf(code.Initiative__r?.End_Year__c) : null,
						null
					);
					childWrappers.add(initiativeWrapper);

					// If the current record is of type Budgeted , then add its amount to total budgeted amount
					if (code.Initiative__r?.RecordTypeId == BUDGETED_INITIATIVE_RECORD_TYPE_ID) {
						if (code.Initiative__r?.Announcement_Count__c > 0) {
							initiativeWrapper.iconName = Assets.UTILITY_ANNOUNCEMENT;
						}
						initiativeWrapper.isBudgeted = true;
						initiativeWrapper.isAmendment = false;
						initiativeWrapper.totalBudgetedValue = code.Initiative__r?.Total_Committed_Amount_USD__c;
						budgetedToWrapperMap.put(code.Initiative__r?.Id, initiativeWrapper);
						totalBudgetedAmount += code.Initiative__r?.Total_Committed_Amount_USD__c;
						if (code.Initiative__r?.Start_Year__c != null) {
							budgetedStartYear = getStartYear(budgetedStartYear, Integer.valueOf(code.Initiative__r?.Start_Year__c));
						} else {
							budgetedStartYear = 0;
						}
						initiativeWrapper.budgetedStartYear = budgetedStartYear;
						if (code.Initiative__r?.End_Year__c != null) {
							budgetedEndYear = getEndYear(budgetedEndYear, Integer.valueOf(code.Initiative__r?.End_Year__c));
						} else {
							budgetedEndYear = 0;
						}
						initiativeWrapper.budgetedEndYear = budgetedEndYear;
					} else {
						initiativeWrapper.totalBudgetedValue = 0;
						initiativeWrapper.budgetedStartYear = Assets.DECIMAL_MAX_VALUE;
						initiativeWrapper.budgetedEndYear = 0;
					}

					// If the current record is of type MISC , then add its amount to total misc amount
					if (code.Initiative__r?.RecordTypeId == MISC_INITIATIVE_RECORD_TYPE_ID) {
						miscellaneousAmount += code.Initiative__r?.Total_Committed_Amount_USD__c;
						initiativeWrapper.totalMiscValue = code.Initiative__r?.Total_Committed_Amount_USD__c;
						if (code.Initiative__r?.Start_Year__c != null) {
							miscStartYear = getStartYear(miscStartYear, Integer.valueOf(code.Initiative__r?.Start_Year__c));
						} else {
							miscStartYear = 0;
						}
						initiativeWrapper.miscStartYear = miscStartYear;
						if (code.Initiative__r?.End_Year__c != null) {
							miscEndYear = getEndYear(miscEndYear, Integer.valueOf(code.Initiative__r?.End_Year__c));
						} else {
							miscEndYear = 0;
						}
						initiativeWrapper.miscEndYear = miscEndYear;
					} else {
						initiativeWrapper.totalMiscValue = 0;
						initiativeWrapper.miscStartYear = Assets.DECIMAL_MAX_VALUE;
						initiativeWrapper.miscEndYear = 0;
					}

					//IM-303: A parent can be inside another parent initiative
					// IM-304: Removed check for Parent Initiative Recordtype
					if(String.isNotBlank(code.Initiative__r.Current_Budget__r.Partner_Fund_Summary__c)) {
						initiativeWrapper.programOverviewAlert += code.Initiative__r.Current_Budget__r.Partner_Fund_Summary__c + '\n';
					}
					if(code.Initiative__r.Current_Budget__r.Include_Foreign_Currency__c) {
						initiativeWrapper.programOverviewAlert += INCLUDE_FOREIGN_CURRENCY_MSG + '\n';
						initiativeWrapper.foriengnCurrencyIcon = Assets.UTILITY_PAYMENT_GATEWAY;
					}
					if(code.Initiative__r.Current_Budget__r.Total_Not_Applicable_Amount__c != null) {
						String msg = String.format(NOT_IN_BGIVE_MSG, new List<String>{IMUtil.formatAmount(code.Initiative__r.Current_Budget__r.Total_Not_Applicable_Amount__c)});
						initiativeWrapper.programOverviewAlert += msg;
						initiativeWrapper.notInBgiveIcon = Assets.UTILITY_APPLIED_AMOUNT;
					}
					initiativeWrapper.programOverviewAlert = initiativeWrapper.programOverviewAlert.replace('\\n$', '');
					
					// Calculate total committed amount
					if (code.Initiative__r?.Total_Committed_Amount_USD__c != null) {
						totalCommittedAmount += code.Initiative__r?.Total_Committed_Amount_USD__c;
					}

					// Calculate the min start year from all children
					if (code.Initiative__r?.Start_Year__c != null) {
						startYear = Integer.valueOf(code.Initiative__r?.Start_Year__c) != 0
							? Math.min(startYear, Integer.valueOf(code.Initiative__r?.Start_Year__c))
							: startYear;
					}

					// Calculate the max end year from all children
					if (code.Initiative__r?.End_Year__c != null) {
						endYear = Integer.valueOf(code.Initiative__r?.End_Year__c) != 0
							? Math.max(endYear, Integer.valueOf(code.Initiative__r?.End_Year__c))
							: endYear;
					}

					// Get all children of current Foundation Code
					List<Foundation_Code__c> childCodes = new List<Foundation_Code__c>();
					if (fcToChildrenMap.get(code.Id) != null) {
						childCodes.addAll(fcToChildrenMap.get(code.Id));
					}

					// Call the recursive method for all the children
					if (!childCodes.isEmpty()) {
						processChildCodes(childCodes, fcToChildrenMap, initiativeWrapper);
						if (code.Initiative__r?.RecordTypeId == PARENT_INITIATIVE_RECORD_TYPE_ID) {
							totalCommittedAmount += initiativeWrapper.amountValue;
							totalBudgetedAmount += initiativeWrapper.totalBudgetedValue;
							miscellaneousAmount += initiativeWrapper.totalMiscValue;
							startYear = initiativeWrapper.startYear != 0 ? Math.min(startYear, initiativeWrapper.startYear) : startYear;
							endYear = initiativeWrapper.endYear != 0 ? Math.max(endYear, initiativeWrapper.endYear) : endYear;
						}
					}
				}
				return new ChildrenData(
					totalCommittedAmount,
					totalBudgetedAmount,
					miscellaneousAmount,
					startYear,
					endYear,
					budgetedStartYear,
					budgetedEndYear,
					miscStartYear,
					miscEndYear,
					childWrappers
				);
			} else {
				return null;
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CREATE_DATA));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Description    : Method to get minimum Start Year from the children
	 * Parameters     : currentStartYear Decimal, initiativeStartYear Decimal
	 * Return Type    : Decimal
	 */
	private static Integer getStartYear(Integer currentStartYear, Integer initiativeStartYear) {
		return initiativeStartYear != 0 && initiativeStartYear != null ? Math.min(currentStartYear, initiativeStartYear) : currentStartYear;
	}

	/**
	 * Description    : Method to get maximum End Year from the children
	 * Parameters     : currentEndYear Decimal, initiativeEndYear Decimal
	 * Return Type    : Decimal
	 */
	private static Integer getEndYear(Integer currentEndYear, Integer initiativeEndYear) {
		return initiativeEndYear != 0 && initiativeEndYear != null ? Math.max(currentEndYear, initiativeEndYear) : currentEndYear;
	}

	/**
	 * Description    : Calling Recursive Method if the current record has children
	 * Parameters     : childCodes List<Foundation_Code__c>, fcToChildrenMap Map<Id, List<Foundation_Code__c>>, initiativeWrapper InitiativeWrapper
	 * Return Type    : void
	 */
	private static void processChildCodes(List<Foundation_Code__c> childCodes, Map<Id, List<Foundation_Code__c>> fcToChildrenMap, InitiativeWrapper initiativeWrapper) {
		ChildrenData childData = createData(childCodes, fcToChildrenMap);
		initiativeWrapper.amountValue = childData.totalCommittedAmount;
		initiativeWrapper.totalBudgetedValue = childData.totalBudgetedAmount;
		initiativeWrapper.totalMiscValue = childData.miscellaneousAmount;
		initiativeWrapper.children = childData.children;
		initiativeWrapper.yearRange =
			(childData.startYear != 0 &&
				childData.startYear != Assets.DECIMAL_MAX_VALUE &&
				childData.startYear != null
				? String.valueOf(childData.startYear)
				: '') +
			' - ' +
			(childData.endYear != 0 && childData.endYear != null ? String.valueOf(childData.endYear) : '');
		initiativeWrapper.startYear = childData.startYear;
		initiativeWrapper.endYear = childData.endYear;
		initiativeWrapper.budgetedStartYear = childData.budgetedStartYear;
		initiativeWrapper.budgetedEndYear = childData.budgetedEndYear;
		initiativeWrapper.miscStartYear = childData.miscStartYear;
		initiativeWrapper.miscEndYear = childData.miscEndYear;
	}

	/**
	 * Description    : Recursive Method to get Initiative data depending on Focus Area/Parent Initiative
	 * Parameters     : codes List<Foundation_Code__c>, fcToChildrenMap Map<Id, List<Foundation_Code__c>>
	 * Return Type    : void
	 */
	private static void createFinalInitiativeWrapper(Foundation_Code__c childFC, ChildrenData data) {
		if (data != null) {
			InitiativeWrapper initiativeWrapper = createInitiativeWrapper(
				childFC,
				null,
				data.totalCommittedAmount,
				data.startYear,
				data.endYear,
				data.children
			);
			Decimal totalAmt = 0;
			Decimal totalBudgetedAmount = 0;
			Decimal miscellaneousAmount = 0;
			Integer startYear = Assets.DECIMAL_MAX_VALUE;
			Integer endYear = 0;
			Integer budgetedStartYear = Assets.DECIMAL_MAX_VALUE;
			Integer budgetedEndYear = 0;
			Integer miscStartYear = Assets.DECIMAL_MAX_VALUE;
			Integer miscEndYear = 0;

			// Calculating total amount, total budgeted amount and mis amount to include Budgeted and Misc initiatives with no children
			for (InitiativeWrapper children : initiativeWrapper.children) {
				children.amountValue = children.amountValue != null ? children.amountValue : 0;
				totalAmt += children.amountValue;
				totalBudgetedAmount += children.totalBudgetedValue;
				miscellaneousAmount += children.totalMiscValue;
				startYear = children.startYear != 0 && children.startYear != null ? Math.min(startYear, children.startYear) : startYear;
				endYear = children.endYear != 0 && children.endYear != null ? Math.max(endYear, children.endYear) : endYear;
				budgetedStartYear = children.budgetedStartYear != 0 &&
					children.budgetedStartYear != null
					? Math.min(budgetedStartYear, children.budgetedStartYear)
					: budgetedStartYear;
				budgetedEndYear = children.budgetedEndYear != 0 &&
					children.budgetedEndYear != null
					? Math.max(budgetedEndYear, children.budgetedEndYear)
					: budgetedEndYear;
				miscStartYear = children.miscStartYear != 0 && children.miscStartYear != null ? Math.min(miscStartYear, children.miscStartYear) : miscStartYear;
				miscEndYear = children.miscEndYear != 0 && children.miscEndYear != null ? Math.max(miscEndYear, children.miscEndYear) : miscEndYear;
			}
			initiativeWrapper.amountValue = totalAmt;
			initiativeWrapper.totalBudgetedValue = totalBudgetedAmount;
			initiativeWrapper.totalMiscValue = miscellaneousAmount;
			initiativeWrapper.yearRange =
				((startYear != 0 && startYear != Assets.DECIMAL_MAX_VALUE && startYear != null) ? String.valueOf(startYear) : '') +
				' - ' +
				(endYear != 0 && endYear != null ? String.valueOf(endYear) : '');
			initiativeWrapper.budgetedStartYear = budgetedStartYear;
			initiativeWrapper.budgetedEndYear = budgetedEndYear;
			initiativeWrapper.miscStartYear = miscStartYear;
			initiativeWrapper.miscEndYear = miscEndYear;
			initiativeWrapper.programOverviewAlert = childFC.Initiative__r?.Program_Overview_Alert__c;
			initiativeWrapperList.add(initiativeWrapper);
		}
	}

	/**
	 * Description    : Method to add Total Amount, Total Budgeted and Total Misc Amonts to the tree grid
	 * Parameters     : none
	 * Return Type    : void
	 */
	private static void createTotalRows() {
		// Add the constant top three rows for each parent initiative (Contains an empty row, total amount, total budgeted and total misc amts)
		for (InitiativeWrapper wrap : initiativeWrapperList) {
			wrap.isDetailRow = true;
			List<InitiativeWrapper> totalRowsWrappers = new List<InitiativeWrapper>();

			InitiativeWrapper topTotalAmount = createTotalAmountWrapper(wrap);
			topTotalAmount.isTotalRow = true;

			InitiativeWrapper topBudgeted = createTotalBudgetedWrapper(wrap);
			topBudgeted.isTotalRow = true;

			InitiativeWrapper topMisc = createTotalMiscWrapper(wrap);
			topMisc.isTotalRow = true;

			InitiativeWrapper emptyRow = new InitiativeWrapper('emptyRow', '', '', null, '', null);
			totalRowsWrappers.addAll(new List<InitiativeWrapper>{ topBudgeted, topMisc, topTotalAmount, emptyRow, wrap });
			finalResponseList.add(totalRowsWrappers);
		}
	}

	/**
	 * Description    : Method to create the top row Total Amount InitiativeWrapper for the Program Overview Grid
	 * Parameters     : wrap InitiativeWrapper
	 * Return Type    : InitiativeWrapper
	 */
	private static InitiativeWrapper createTotalAmountWrapper(InitiativeWrapper wrap) {
		return new InitiativeWrapper(
			'totalAmount',
			'Total Amount',
			wrap.initiativeNameUrl,
			wrap.totalBudgetedValue + wrap.totalMiscValue,
			((wrap.startYear != 0 && wrap.startYear != Assets.DECIMAL_MAX_VALUE && wrap.startYear != null) ? String.valueOf(wrap.startYear) : '') +
				' - ' +
				(wrap.endYear != 0 && wrap.endYear != null ? String.valueOf(wrap.endYear) : ''),
			null
		);
	}

	/**
	 * Description    : Method to create the top row Total Budgeted InitiativeWrapper for the Program Overview Grid
	 * Parameters     : wrap InitiativeWrapper
	 * Return Type    : InitiativeWrapper
	 */
	private static InitiativeWrapper createTotalBudgetedWrapper(InitiativeWrapper wrap) {
		return new InitiativeWrapper(
			'totalBudgetedInitiatives',
			'Total Budgeted Initiatives',
			wrap.initiativeNameUrl,
			wrap.totalBudgetedValue,
			((wrap.budgetedStartYear != 0 &&
					wrap.budgetedStartYear != Assets.DECIMAL_MAX_VALUE &&
					wrap.budgetedStartYear != null)
					? String.valueOf(wrap.budgetedStartYear)
					: '') +
				' - ' +
				(wrap.budgetedEndYear != 0 && wrap.budgetedEndYear != null ? String.valueOf(wrap.budgetedEndYear) : ''),
			null
		);
	}

	/**
	 * Description    : Method to create the top row Total Misc InitiativeWrapper for the Program Overview Grid
	 * Parameters     : wrap InitiativeWrapper
	 * Return Type    : InitiativeWrapper
	 */
	private static InitiativeWrapper createTotalMiscWrapper(InitiativeWrapper wrap) {
		return new InitiativeWrapper(
			'totalMiscellaneous',
			'Total Miscellaneous',
			wrap.initiativeNameUrl,
			wrap.totalMiscValue,
			((wrap.miscStartYear != 0 &&
					wrap.miscStartYear != Assets.DECIMAL_MAX_VALUE &&
					wrap.miscStartYear != null)
					? String.valueOf(wrap.miscStartYear)
					: '') +
				' - ' +
				(wrap.miscEndYear != 0 && wrap.endYear != null ? String.valueOf(wrap.miscEndYear) : ''),
			null
		);
	}

	/**
	 * Description    : Method to create the InitiativeWrapper for the Program Overview Grid
	 * Parameters     : code Foundation_Code__c, amendmentInitiative IM_Initiative__c, totalCommittedAmount Decimal, startYear Decimal, endYear Decimal, childWrappers List<InitiativeWrapper>
	 * Return Type    : InitiativeWrapper
	 */
	private static InitiativeWrapper createInitiativeWrapper(
		Foundation_Code__c code,
		IM_Initiative__c amendmentInitiative,
		Decimal totalCommittedAmount,
		Integer startYear,
		Integer endYear,
		List<InitiativeWrapper> childWrappers
	) {
		InitiativeWrapper initiativeWrapper;
		String yearRange =
			((startYear != 0 && startYear != Assets.DECIMAL_MAX_VALUE && startYear != null) ? String.valueOf(startYear) : '') +
			' - ' +
			(endYear != 0 && endYear != null ? String.valueOf(endYear) : '');
		if (code != null) {
			String url = '/' + code.Initiative__r?.Id;
			initiativeWrapper = new InitiativeWrapper(code.Initiative__r?.Id, code.Initiative__r?.Name, url, totalCommittedAmount, yearRange, null);
		} else if (amendmentInitiative != null) {
			String url = '/' + amendmentInitiative.Id;
			initiativeWrapper = new InitiativeWrapper(amendmentInitiative.Id, amendmentInitiative.Name, url, totalCommittedAmount, yearRange, null);
		}
		if (childWrappers != null) {
			initiativeWrapper.children.addAll(childWrappers);
		}
		initiativeWrapper.startYear = startYear;
		initiativeWrapper.endYear = endYear;
		return initiativeWrapper;
	}

	/**
	 * Description    : Method to create the Amendment Wrapper if amendment is present for budgeted intiatives
	 * Parameters     : none
	 * Return Type    : void
	 */
	private static void createAmendmentWrapper() {
		if (!budgetedToWrapperMap.keySet().isEmpty()) {
			List<IM_Initiative__c> amendmentInitiatives = IMUtil.getApprovedAmendments(budgetedToWrapperMap.keySet());
			if (amendmentInitiatives != null) {
				for (IM_Initiative__c amendmentInitiative : amendmentInitiatives) {
					InitiativeWrapper budgetedWrapper = budgetedToWrapperMap.get(amendmentInitiative.Amendment_of__c);
					if (!initiativesWithAmendment.contains(amendmentInitiative.Amendment_of__c)) {
						InitiativeWrapper initialApprovalWrapper = createInitiativeWrapper(
							null,
							amendmentInitiative,
							amendmentInitiative.Original_Approved_Amount__c,
							amendmentInitiative.Start_Year__c != null ? Integer.valueOf(amendmentInitiative.Start_Year__c) : null,
							amendmentInitiative.Original_End_Date__c.year() != null ? Integer.valueOf(amendmentInitiative.Original_End_Date__c.year()) : null,
							null
						);
						initialApprovalWrapper.initiativeName = Assets.INITIAL_APPROVAL;
						budgetedWrapper.isBudgeted = true;
						budgetedWrapper.children.add(initialApprovalWrapper);
						initiativesWithAmendment.add(amendmentInitiative.Amendment_of__c);
					}
					InitiativeWrapper amendInitiativeWrapper = createInitiativeWrapper(
						null,
						amendmentInitiative,
						amendmentInitiative.Total_Committed_Amount_USD__c,
						amendmentInitiative.Start_Year__c != null ? Integer.valueOf(amendmentInitiative.Start_Year__c) : null,
						amendmentInitiative.End_Year__c != null ? Integer.valueOf(amendmentInitiative.End_Year__c) : null,
						null
					);
					amendInitiativeWrapper.isAmendment = true;
					amendInitiativeWrapper.isBudgeted = false;
					budgetedWrapper.children.add(amendInitiativeWrapper);
				}
			}
		}
	}

	/**
	 * Description    : Builds the Announcements Data Wrapper
	 * Parameters     : Accepts List<Id> budgetedIds
	 * Return Type    : List<AnnouncementRow>
	 */
	@AuraEnabled
	public static List<AnnouncementRow> buildAnnouncementRows(List<Id> budgetedIds) {
		List<AnnouncementRow> rows = new List<AnnouncementRow>();
		for (IM_Announcement__c ann : [
			SELECT Id, Name, Announcement_Date__c, Announcement_Notes__c, Initiative__c, Initiative__r.Name
			FROM IM_Announcement__c
			WHERE Initiative__c IN :budgetedIds
			WITH SYSTEM_MODE
		]) {
			rows.add(
				new AnnouncementRow(
					ann.Id,
					ann.Name,
					ann.Announcement_Date__c,
					ann.Announcement_Notes__c,
					ann.Initiative__c != null ? ann.Initiative__c : '',
					ann.Initiative__r != null ? ann.Initiative__r.Name : ''
				)
			);
		}
		return rows;
	}

	/**
	 * Description  : Method to get all Foundation Codes and their children
	 * Parameters   : none
	 * Return Type  : Map<Id, List<Foundation_Code__c>>
	 */
	private static Map<Id, List<Foundation_Code__c>> getFCAndChildren() {
		Map<Id, List<Foundation_Code__c>> fcToChildMap = new Map<Id, List<Foundation_Code__c>>();
		for (Foundation_Code__c rec : [
			SELECT
				Id,
				Name,
				Parent__c,
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
				Initiative__r.Program_Overview_Alert__c,
				Initiative__r.Current_Budget__c,
				Initiative__r.Current_Budget__r.Partner_Fund_Summary__c,
				Initiative__r.Current_Budget__r.Include_Foreign_Currency__c,
				Initiative__r.Current_Budget__r.Total_Not_Applicable_Amount__c,
				(
					SELECT
						Id,
						Name,
						Parent__c,
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
						Initiative__r.Program_Overview_Alert__c,
						Initiative__r.Current_Budget__c,
						Initiative__r.Current_Budget__r.Partner_Fund_Summary__c,
						Initiative__r.Current_Budget__r.Include_Foreign_Currency__c,
						Initiative__r.Current_Budget__r.Total_Not_Applicable_Amount__c
					FROM Foundation_Codes__r
					WHERE Initiative__c != NULL
					ORDER BY Sort_Order__c, Initiative__r.Start_Year__c, Name
				)
			FROM Foundation_Code__c
			WHERE Type__c = :Assets.FOCUS_AREA OR Initiative__c != NULL
			WITH SYSTEM_MODE
			ORDER BY Sort_Order__c, Name
		]) {
			fcToChildMap.put(rec.Id, rec.Foundation_Codes__r);
		}
		return fcToChildMap;
	}

	/**
	 * Description    : Wrapper defined for the Program Overview UI
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class ProgramOverviewData {
		@AuraEnabled
		public List<List<InitiativeWrapper>> treeGridData;
		@AuraEnabled
		public List<Id> budgetedInitiativeIds;
	}

	/**
	 * Description    : Overview Data Tab1 Wrapper
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class InitiativeWrapper {
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String initiativeName;
		@AuraEnabled
		public Boolean isBudgeted;
		@AuraEnabled
		public Boolean isAmendment;
		@AuraEnabled
		public String initiativeNameUrl;
		@AuraEnabled
		public Decimal amountValue;
		@AuraEnabled
		public Decimal totalBudgetedValue;
		@AuraEnabled
		public Decimal totalMiscValue;
		@AuraEnabled
		public String yearRange;
		@AuraEnabled
		public Integer startYear;
		@AuraEnabled
		public Integer endYear;
		@AuraEnabled
		public Integer budgetedStartYear;
		@AuraEnabled
		public Integer budgetedEndYear;
		@AuraEnabled
		public Integer miscStartYear;
		@AuraEnabled
		public Integer miscEndYear;
		@AuraEnabled
		public String iconName;
		@AuraEnabled
		public String programOverviewAlert;
		@AuraEnabled
		public Boolean isTotalRow;
		@AuraEnabled
		public Boolean isDetailRow;
		@AuraEnabled
		public List<InitiativeWrapper> children;
		@AuraEnabled
		public String foriengnCurrencyIcon;
		@AuraEnabled
		public String notInBgiveIcon;

		public InitiativeWrapper(String name, String initiativeName, String initiativeNameUrl, Decimal amountValue, String yearRange, String iconName) {
			this.name = name;
			this.initiativeName = initiativeName;
			this.initiativeNameUrl = initiativeNameUrl;
			this.amountValue = amountValue;
			this.yearRange = yearRange;
			this.iconName = iconName;
			this.programOverviewAlert = '';
			this.children = new List<InitiativeWrapper>();
		}
	}

	/**
	 * Description    : Announcements Data Wrapper to be shown on the communications tab
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class AnnouncementRow {
		@AuraEnabled
		public String id;
		@AuraEnabled
		public String announcementName;
		@AuraEnabled
		public Date announcementDate;
		@AuraEnabled
		public String notes;
		@AuraEnabled
		public String initiativeId;
		@AuraEnabled
		public String initiativeName;

		public AnnouncementRow(
			String id,
			String announcementName,
			Date announcementDate,
			String notes,
			String initiativeId,
			String initiativeName
		) {
			this.id = id;
			this.announcementName = announcementName;
			this.announcementDate = announcementDate;
			this.notes = notes;
			this.initiativeId = initiativeId;
			this.initiativeName = initiativeName;
		}
	}

	/**
	 * Description    : Recursive Method's Return Type Data Wrapper
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class ChildrenData {
		Decimal totalCommittedAmount;
		Decimal totalBudgetedAmount;
		Decimal miscellaneousAmount;
		Integer startYear;
		Integer endYear;
		Integer budgetedStartYear;
		Integer budgetedEndYear;
		Integer miscStartYear;
		Integer miscEndYear;
		public List<InitiativeWrapper> children;

		public ChildrenData(
			Decimal totalCommittedAmount,
			Decimal totalBudgetedAmount,
			Decimal miscellaneousAmount,
			Integer startYear,
			Integer endYear,
			Integer budgetedStartYear,
			Integer budgetedEndYear,
			Integer miscStartYear,
			Integer miscEndYear,
			List<InitiativeWrapper> children
		) {
			this.totalCommittedAmount = totalCommittedAmount;
			this.totalBudgetedAmount = totalBudgetedAmount;
			this.miscellaneousAmount = miscellaneousAmount;
			this.startYear = startYear;
			this.endYear = endYear;
			this.budgetedStartYear = budgetedStartYear;
			this.budgetedEndYear = budgetedEndYear;
			this.miscStartYear = miscStartYear;
			this.miscEndYear = miscEndYear;
			this.children = children;
		}
	}
}