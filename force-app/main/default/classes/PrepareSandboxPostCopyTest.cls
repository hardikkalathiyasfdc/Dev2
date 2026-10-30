/**
 * Author : Ravi Bheemreddy
 * Date   : 11/17/2025
 * JIRA   : BRME-6298
 * Description : Test class for PrepareSandboxPostCopy
 **/
@isTest
public class PrepareSandboxPostCopyTest {

    @isTest
    static void testSandboxPostCopy() {

		Test.startTest();
        PrepareSandboxPostCopy.batchSize = 500;
        try {
            Test.testSandboxPostCopyScript(
            	new PrepareSandboxPostCopy(), 
                UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), 
                UserInfo.getOrganizationName(), 
                true
            );
        } catch (Exception e) {
            
        }
		Test.stopTest();
    }
    
    @isTest
    static void testErrorBlock() {

		Test.startTest();
        PrepareSandboxPostCopy.batchSize = null;
        try {
            Test.testSandboxPostCopyScript(
            	new PrepareSandboxPostCopy(), 
                UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), 
                UserInfo.getOrganizationName(), 
                true
            );
        } catch (Exception e) {
            
        }
		Test.stopTest();
    }
}