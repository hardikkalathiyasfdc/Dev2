PermissionSetGroup psg = [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName = 'IM_Pipeline_Manager' LIMIT 1];
PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'IM_Approval_Overview_Tab_Read_Access' LIMIT 1];

List<PermissionSetGroupComponent> existing = [
    SELECT Id FROM PermissionSetGroupComponent
    WHERE PermissionSetGroupId = :psg.Id AND PermissionSetId = :ps.Id
];
if (existing.isEmpty()) {
    PermissionSetGroupComponent comp = new PermissionSetGroupComponent();
    comp.PermissionSetGroupId = psg.Id;
    comp.PermissionSetId = ps.Id;
    insert comp;
    System.debug('Added ' + ps.Name + ' to ' + psg.DeveloperName);
} else {
    System.debug('Already a member of ' + psg.DeveloperName);
}
