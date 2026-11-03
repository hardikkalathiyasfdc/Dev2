// BRME-6989 fix: assign delete perm set to the correct Kelly (Mehlenbacher) and remove
// the mistaken Sarah Singletary assignment.
Id psId = '0PSbc000001GzQLGA0';

// Remove mistaken assignment
List<PermissionSetAssignment> wrong = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :psId AND AssigneeId = '0054v00000FUkMcAAL'];
if (!wrong.isEmpty()) { delete wrong; System.debug('Removed Sarah Singletary: ' + wrong.size()); }

// Add Kelly Mehlenbacher if not present
Id kellyId = '0054v00000DyUBGAA3';
Integer cnt = [SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetId = :psId AND AssigneeId = :kellyId];
if (cnt == 0) {
	insert new PermissionSetAssignment(AssigneeId = kellyId, PermissionSetId = psId);
	System.debug('Added Kelly Mehlenbacher');
}

for (PermissionSetAssignment a : [SELECT Assignee.Name FROM PermissionSetAssignment WHERE PermissionSetId = :psId]) {
	System.debug('Assignee: ' + a.Assignee.Name);
}
