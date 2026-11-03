// BRME-6989: assign IM: Final Doc Tab Delete Access to BIM Super Users
// Kelly Mehlenbacher and Sara Ginsberg.
Id psId = '0PSbc000001GzQLGA0'; // IM_Final_Doc_Tab_Delete_Access
Set<Id> assignees = new Set<Id>{
	'0054v00000FUkMcAAL', // Kelly Mehlenbacher
	'0056g000002O6LtAAK'  // Sara Ginsberg
};

// Skip any already assigned
Set<Id> already = new Set<Id>();
for (PermissionSetAssignment a : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :psId AND AssigneeId IN :assignees]) {
	already.add(a.AssigneeId);
}

List<PermissionSetAssignment> toInsert = new List<PermissionSetAssignment>();
for (Id uid : assignees) {
	if (!already.contains(uid)) {
		toInsert.add(new PermissionSetAssignment(AssigneeId = uid, PermissionSetId = psId));
	}
}
if (!toInsert.isEmpty()) {
	insert toInsert;
}
System.debug('Assigned ' + toInsert.size() + ' / skipped (already): ' + already.size());
