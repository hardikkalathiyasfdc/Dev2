@isTest
public class DonorMemoReportController_Test {
    
    @isTest
    static void testController () {
        DonorMemoReportController ctrl = new DonorMemoReportController ();
        System.assertEquals(true, DonorMemoReportController.memo != null);
    }
}