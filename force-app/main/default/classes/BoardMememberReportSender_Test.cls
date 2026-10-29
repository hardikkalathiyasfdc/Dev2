@isTest
private class BoardMememberReportSender_Test {

	@isTest
    static void testSingleEmailNotification() {
        Test.startTest();

        BoardMememberReportSender sender = new BoardMememberReportSender();
        sender.execute(null);
        
        Integer invocations = Limits.getEmailInvocations();

        Test.stopTest();

        Assert.areEqual(1, invocations, 'An email has not been sent');
        
    }
    
    @isTest
    static void errorBlockTest () {
        try {
            Test.startTest();
                BoardMememberReportSender.settingName = 'Test Report';
                BoardMememberReportSender sender = new BoardMememberReportSender();
                sender.execute(null);
            Test.stopTest();
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Report Email Setting does not exist'));
        }
    }
}