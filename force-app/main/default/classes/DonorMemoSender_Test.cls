@isTest
public class DonorMemoSender_Test {
	
    @isTest
    static void testSingleEmailNotification() {
        Test.startTest();
        DonorMemoSender sender = new DonorMemoSender();
        sender.execute(null);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, invocations, 'An email has not been sent');
    }
}