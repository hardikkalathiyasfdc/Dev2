/**
* Author : Ravi
* Description : This is the class for DonorMemo UI version.
* Test : DonorMemosRetrieveRest_Test
**/

@RestResource(urlMapping='/getDonorMemos')
global without sharing class DonorMemosRetrieveRest {
	 
    public static String selectedFocusAreas = RestContext.request.params.get('selectedFocusAreas');
    public static String selectedContacts = RestContext.request.params.get('selectedDonorContacts');
    public static String selectedDonorOrgs = RestContext.request.params.get('selectedDonorOrgs');
    public static String selectedDonorLists = RestContext.request.params.get('selectedDonorLists');
    public static String selectedProjects = RestContext.request.params.get('selectedProjects');
    public static String startDate = RestContext.request.params.get('startDate');
    public static String endDate = RestContext.request.params.get('endDate');
    public static String sortBy = RestContext.request.params.get('sortBy');
    public static Decimal minAmount = Decimal.valueOf(RestContext.request.params.get('minAmount'));
    public static String includeCoverPage = RestContext.request.params.get('coverPage');
    public static String getActiveDonors = RestContext.request.params.get('getActiveDonors');
    
	@HttpGET
    global static DonorMemoService.DonorMemo doGet() {
        try {
            DonorMemoService.SelectedFilters filters = new DonorMemoService.SelectedFilters();
            filters.startDate = startDate;
            filters.endDate = endDate;
            filters.minDonorAmount = minAmount;
            filters.isPDF = false;
            filters.selectedFocusAreas = selectedFocusAreas;
            filters.selectedProjects = selectedProjects;
            filters.selectedContacts = selectedContacts;
            filters.selectedOrganizations = selectedDonorOrgs;
            filters.selectedLists = selectedDonorLists;
            filters.sortBy = sortBy;
            filters.includeCoverPage = includeCoverPage == 'true' ? true : false;
            filters.getActiveDonors = getActiveDonors == 'true' ? true : false;
            DonorMemoService.DonorMemo memo = DonorMemoHelper.getMemo(filters);
            return memo;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields('DONOR_MEMO_REST_FAILED');
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException('Failed while retrieving donor memo.');
        }
    } 
}