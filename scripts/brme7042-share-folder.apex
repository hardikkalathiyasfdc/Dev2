Folder f = [SELECT Id FROM Folder WHERE DeveloperName = 'IMApprovalOverviewReports' AND Type = 'Report' LIMIT 1];
// Share with all internal users (Organization) read-only
FolderShare fs = new FolderShare();
fs.FolderId = f.Id;
fs.UserOrGroupId = UserInfo.getOrganizationId();
fs.AccessLevel = 'Read';
fs.ShareType = 'Group';
insert fs;
System.debug('Shared folder ' + f.Id + ' to all internal users (Read)');
