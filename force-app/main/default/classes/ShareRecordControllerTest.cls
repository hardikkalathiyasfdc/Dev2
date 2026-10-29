@isTest
public class ShareRecordControllerTest {
    @testSetup
    public static void createTestData(){
        User user = TestDataFactory.createUser();
        Account account = TestDataFactory.createOrg('Test Organization');
        My_Notes__c myNotes = TestDataFactory.createMyNotes('Test Subject',account.Id);

    }

    @isTest(SeeAllData = false)
    public static void userShareTest(){
        My_Notes__c myNotes = [SELECT Id FROM My_Notes__c with SYSTEM_MODE LIMIT 1];
        User user = [SELECT Id FROM User with SYSTEM_MODE Order By CreatedDate Desc LIMIT 1];

        List<Sobject> initialIdShared = ShareRecordController.getAllSharedRecords(myNotes.Id);

        Test.startTest();

        list<String> userOrDeptList = new list<String>();
        userOrDeptList.add(user.Id);
        ShareRecordController.shareRecord(myNotes.Id,userOrDeptList,'Users', 'Read Only');

        List<Sobject> myNotesShare = ShareRecordController.getAllSharedRecords(myNotes.Id);

        List<ShareRecordController.UpdateShareRecWrapper> updateWrapList= new List<ShareRecordController.UpdateShareRecWrapper>();
        ShareRecordController.UpdateShareRecWrapper updateWrap= new ShareRecordController.UpdateShareRecWrapper();
        updateWrap.recId = myNotesShare[0].Id;
        updateWrap.accessLevel = 'Edit';
        updateWrapList.add(updateWrap);
        String updatedListWrap= JSON.serialize(updateWrapList);
        ShareRecordController.updateRecord(myNotes.Id, updatedListWrap);

        List<string> deletedList = new List<String>();
        deletedList.add(myNotesShare[0].Id);
        ShareRecordController.deleteRecord(myNotes.Id, deletedList);

        Test.stopTest();
        List<Sobject> finalIdShared = ShareRecordController.getAllSharedRecords(myNotes.Id);
        System.assertEquals(finalIdShared[0].Id,
                            initialIdShared[0].Id,
                            'Checking if user inserted has been deleted');
    }

    @isTest
    public static void hasGeneralSharingHierarchyPermission(){
        Test.startTest();
        Boolean hasPermission = ShareRecordController.hasGeneralSharingHierarchyPermission();
        System.assertEquals(hasPermission , false , 'User should not have hierarchy permission');
        Test.stopTest();
    }
}