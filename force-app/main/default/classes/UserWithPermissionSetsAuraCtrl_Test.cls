@isTest
private class UserWithPermissionSetsAuraCtrl_Test {

	@testSetup
	static void dataPrep() {
		User u = TestDataFactory.createUser();
        User u1 = TestDataFactory.createUser();

        List<PermissionSet> permSetsToCreate = new List<PermissionSet> ();

        PermissionSet pr = new PermissionSet(Label='Case Permisson Set',Name='Case_Permisson_Set');
        permSetsToCreate.add(pr);

        PermissionSet imPr = new PermissionSet(Label='IM Permisson Set',Name='IM_Permisson_Set');
        permSetsToCreate.add(imPr);

		insert permSetsToCreate;

        List<PermissionSetAssignment> assignmentsToCreate = new List<PermissionSetAssignment> ();

		PermissionSetAssignment pm = new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetId=pr.id);
        assignmentsToCreate.add(pm);

        PermissionSetAssignment pm1 = new PermissionSetAssignment(AssigneeId=u1.Id,PermissionSetId=imPr.id);
        assignmentsToCreate.add(pm1);

		insert assignmentsToCreate;
	}

	@isTest
    static void testGetUsers() {
        List<User> usrs = [SELECT Id,Name FROM User WHERE LastName LIKE 'Check%' AND isActive  = true WITH SYSTEM_MODE];

        List<PermissionSet> sets = [SELECT Id FROM PermissionSet WHERE Label = 'Case Permisson Set' WITH SYSTEM_MODE];

        Test.startTest();

        String permisisonSets = UserWithPermissionSetsAuraCtrl.getAllUsersWithPermissionSets(false);
        String searchResults = UserWithPermissionSetsAuraCtrl.searchPermissionSet('Case');

        PermissionSet pr = new PermissionSet(Label='Case Permisson Set1',Name='Case_Permisson_Set1');
        PermissionSet pr2 = new PermissionSet(Label='Case Permisson Set2',Name='Case_Permisson_Set2');
		insert new List<PermissionSet>{pr, pr2};

		UserWithPermissionSetsAuraCtrl.savePermissionSets(JSON.serialize(new List<String>{pr.Id, pr2.Id}), JSON.serialize(new List<String>{'Events'}));

		List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment WHERE permissionSetId = : pr.Id WITH SYSTEM_MODE];

		UserWithPermissionSetsAuraCtrl.deletePermissionSetAssginment(assignments[0].Id);

        String usr = UserWithPermissionSetsAuraCtrl.searchUser('Check');
        System.assert(String.isNotEmpty(usr));

        String teams = UserWithPermissionSetsAuraCtrl.searchTeamsByPermission(sets[0].Id);
        System.assert(String.isNotEmpty(usr));

        UserWithPermissionSetsAuraCtrl.removeTeamFromPermissionSet(sets[0].Id, 'Events');
        UserWithPermissionSetsAuraCtrl.clonePermission(usrs[0].Id, usrs[1].Id);
        Test.stopTest();
    }

    @isTest
    static void testGetIMUsers() {
        Test.startTest();
        String imPermisisonSets = UserWithPermissionSetsAuraCtrl.getAllUsersWithPermissionSets(true);

        Map<String, UserWithPermissionSetsAuraCtrl.UserWrap> imUsersByIdStr =
            (Map<String, UserWithPermissionSetsAuraCtrl.UserWrap>)
            JSON.deserialize(imPermisisonSets, Map<String, UserWithPermissionSetsAuraCtrl.UserWrap>.class);

        System.assertEquals(true, imUsersByIdStr.size() >= 1);
        Test.stopTest();
    }
}