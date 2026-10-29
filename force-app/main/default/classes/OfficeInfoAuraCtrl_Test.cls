@isTest
private class OfficeInfoAuraCtrl_Test {

    @isTest
    static void testMethod1() {
        // Force the exception path
        OfficeInfoAuraCtrl.forceExceptionInTest = true;

        Test.startTest();
            String result = OfficeInfoAuraCtrl.getOfficeInfo();
        Test.stopTest();
    }

    @isTest
    static void testMethod2() {

        Test.startTest();
            String result = OfficeInfoAuraCtrl.getOfficeInfo();
        Test.stopTest();
    }
}