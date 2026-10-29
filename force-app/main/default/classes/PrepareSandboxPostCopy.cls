/**
 * Author : Ravi Bheemreddy
 * Date   : 11/17/2025
 * JIRA   : BRME-6298
 * Description : This class is used for post sandbox refresh activities
 * Test   : PrepareSandboxPostCopyTest
 **/
global without sharing class PrepareSandboxPostCopy implements SandboxPostCopy {
	public static Integer batchSize = 5;
    global void runApexClass(SandboxContext context) {
        try {
            Database.executeBatch(new BatchUsersDeactivation(), batchSize);
        } catch (Exception e) {
            BBApps_ErrorHandler.logErrors('PrepareSandboxPostCopy.runApexClass', e);
        }
    }
}