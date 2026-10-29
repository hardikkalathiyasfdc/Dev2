@isTest
public class EmailUtilityTest {
    
    @isTest
    public static void testEmailUtility() {
        String brmEmailAddress = EmailUtility.getBRMEmailAddress();
        System.assert(String.isNotBlank(brmEmailAddress));
        String dianaEmailAddress = EmailUtility.getBusinessAdminEmailAddress();
        System.assert(String.isNotBlank(dianaEmailAddress));
        String emailContent = EmailUtility.getInitialEmailContent();
        System.assert(String.isNotBlank(emailContent));
        String replyTo = EmailUtility.getReplyToEmail();
        System.assert(String.isNotBlank(replyTo));
        String imEmailAddress = EmailUtility.getIMEmailAddress();
        Assert.areEqual(true, String.isNotBlank(imEmailAddress));
        String bgiveHelpdeskEmail = EmailUtility.getBgiveHelpDeskEmail();
        Assert.areEqual(true, String.isNotBlank(bgiveHelpdeskEmail));
    }
    
    @isTest
    public static void testEmailUtilityWithException() {
        EmailUtility.forceException = true;
        String brmEmailAddress = EmailUtility.getBRMEmailAddress();
        System.assertEquals(  null, brmEmailAddress, 'When exception is forced, method should return null');
        String dianaEmailAddress = EmailUtility.getBusinessAdminEmailAddress();
        System.assertEquals(  null, dianaEmailAddress, 'When exception is forced, method should return null');
        String emailContent = EmailUtility.getInitialEmailContent();
        String replyTo = EmailUtility.getReplyToEmail();
        System.assertEquals(  null, replyTo, 'When exception is forced, method should return null');
    }
}