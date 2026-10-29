/**
* Author : Ravi
* Date   : 1/4/2024
* Jira   : BRME-4881
* Description : This is the controller class for DonorMemoReport VF page which generated pdf for Donor Memo.
* Test   : DonorMemoReportController_Test
* 
**/
public without sharing class DonorMemoReportController {
    public static DonorMemoService.DonorMemo memo {get;set;}
    public static DonorMemoService.PageSection coverPageSection {get;set;}
    public static List<Donor> donors {get;set;}
    public static Boolean hasData {get; set;}
    public static String totalAmount {get; set;}
    public static Decimal minAmount = getMinAmount ();
    public static String reportTimeFrame {get; set;}
    public String currentDateLocal {get;set;}
    
    public DonorMemoReportController () {
        try {
            reportTimeFrame = getLastMonthAndYear ();
            currentDateLocal =  System.now().format();
            DonorMemoService.SelectedFilters filters = new DonorMemoService.SelectedFilters ();
            filters.minDonorAmount = getMinAmount ();
            filters.isPDF = true;
            filters.includeCoverPage = true;
            memo = DonorMemoHelper.getMemo(filters);
            coverPageSection = memo.coverPageSection;
            hasData = memo.coverPageSection.hasData;
            donors = memo.coverPageSection.donors;
            totalAmount = memo.coverPageSection.totalAmount;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields('DONOR_MEMO_REPORT_CONTROLLER_ERROR');
            BBApps_ErrorHandler.logErrors(ex, f); 
        }
    } 
    
    private static Decimal getMinAmount () {
        return 1000000;
    }
    
    public static String getLastMonthAndYear() {
        try {
            DateTime currentDate = DateTime.now();
            DateTime lastMonth = currentDate.addMonths(-1);
            
            String monthName = lastMonth.format('MMMM');
            Integer year = lastMonth.year();
            
            return monthName + ' ' + year;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields('DONOR_MEMO_REPORT_GET_MONTH_YEAR_ERROR');
            BBApps_ErrorHandler.logErrors(ex, f);
            return null;
        }
    }
}