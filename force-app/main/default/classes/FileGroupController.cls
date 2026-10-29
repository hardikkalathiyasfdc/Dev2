/**
 * Author      : Gauri Sagane
 * Date        : 11/11/2024
 * Jira        : IM-41
 * Description : This class provides methods to categorize files by category.
 * Test        : FileGroupControllerTest
 * ChangeLog   :
 * Sai Bhargav Thotakura on July 2025 - IM-284 - Updated "getPermissions" method to check for user Access and customPermission assignment
 * Sai Bhargav Thotakura on Oct 2025 - IM-381: Added logic to render as Read Mode if the initiative is marked as completed.
 */

public with sharing class FileGroupController {

	private static final String ERR_GET_FILEGROUP = 'FILE_GROUP_CONTROLLER_GET_FILEGROUP_FAILED';
	private static final String ERR_GET_PERMISSION = 'FILE_GROUP_CONTROLLER_GET_PERMISSION_FAILED';
	private static final String ERR_UPLOAD_FILE_LINK = 'FILE_GROUP_CONTROLLER_UPLOAD_FILE_LINK_FAILED';
	private static final String ERR_GET_ALL_FILES = 'FILE_GROUP_CONTROLLER_GET_ALL_FILES_FAILED';
	private static final String ERR_DELETE_FILE_METHOD = 'FILE_GROUP_CONTROLLER_DELETE_FILE_METHOD_FAILED';

	/**
	 * Description : Method to get user permission for the component
	 * Parameters  : userPermission String, userId String.
	 * Return Type : Boolean
	 */
	@AuraEnabled(cacheable=true)
	public static Boolean getPermissions(String customPermission, String category, String recordId) {
		try {
			System.debug('######FileGroupController-getPermissions-customPermission: ' + customPermission);
			System.debug('######FileGroupController-getPermissions-category: ' + category);
			System.debug('######FileGroupController-getPermissions-recordId: ' + recordId);
			Id recId = recordId;
			if (customPermission != '') {
				//Step 1: Check if the user has the permission set assigned.
				List<PermissionSetAssignment> currentUserPerSet = [
					SELECT AssigneeId, PermissionSetGroupId
					FROM PermissionSetAssignment
					WHERE
						PermissionSetGroupId IN (
							SELECT PermissionSetGroupId
							FROM PermissionSetGroupComponent
							WHERE PermissionSet.Name = :Assets.FILE_GROUP_EDIT_PERMISSION
						)
						AND AssigneeId = :UserInfo.getUserId()
					WITH SYSTEM_MODE
				];
				System.debug('######FileGroupController-currentUserPerSet: ' + currentUserPerSet);
				if (!currentUserPerSet.isEmpty()) {
					//IM-284: Step 2: If the Edit File Group permission set is assigned check if the user has the custom permission specified
					Boolean hasCustomPermission = FeatureManagement.checkPermission(customPermission);
					//If the user has the Custom Permission Assigned
					if (hasCustomPermission) {
						//Check if the Object is Initiative
						if (String.valueOf(recId.getsobjecttype()) == Assets.IM_INITIATIVE) {
							//check if the user has Read Access on the record, if yes then render as Read Mode.
							//IM-381: If the initiative is completed, then render as Read Mode.
							Boolean isInitiativeCompleted = [SELECT Status__c FROM IM_Initiative__c WHERE Id = :recId WITH SYSTEM_MODE]?.Status__c == Assets.COMPLETED;
							if (IMUtil.getUserAccessLevel(recId).MaxAccessLevel == 'Read' || isInitiativeCompleted) {
								return true;
							} else {
								return false;
							}
						}  //Other object specific conditions to follow, in else if blocks later on.
						else {
							return false;
						}
					} else {
						return true;
					}
				}
				return true;
			}
			return true;
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_PERMISSION));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Description : Method to get File Group for a particular record
	 * Parameters : recordId String, category String, objectApiName String.
	 * Return Type : String
	 */
	@AuraEnabled(cacheable=true)
	public static String getFileGroup(String recordId, String category, String objectApiName) {
		System.debug('######FileGroupController-getFileGroup-recordId: ' + recordId);
		System.debug('######FileGroupController-getFileGroup-category: ' + category);
		System.debug('######FileGroupController-getFileGroup-objectApiName: ' + objectApiName);
		String soql = 'SELECT Id FROM File_Group__c WHERE Category__c = :category';
		if (Assets.IM_INITIATIVE.equalsIgnoreCase(objectApiName)) {
			soql += ' AND Parent_Initiative__c = :recordId';
		} else if (Assets.IM_ANNOUNCEMENT.equalsIgnoreCase(objectApiName)) {
			soql += ' AND Announcement__c = :recordId';
		} else if(Assets.HIGHLIGHT_INTERACTION.equalsIgnoreCase(objectApiName)) {
			soql += ' AND Highlight__c = :recordId';
		}
		soql += ' LIMIT 1';
		System.debug('######FileGroupController-getFileGroup-soql: ' + soql);
		try {
			File_Group__c fileGroup = Database.query(soql, AccessLevel.SYSTEM_MODE);
			return fileGroup.Id;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_FILEGROUP));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to upload File links
	 * Parameters : fileGroupId String, filename String, fileLink String.
	 * Return Type : Id (Id of new file link uploaded)
	 */
	@AuraEnabled
	public static Id uploadFileLink(String fileGroupId, String fileName, String fileLink) {
		try {
			File_Link__c fLink = new File_Link__c();
			fLink.Name = fileName;
			fLink.Link_URL__c = fileLink;
			fLink.File_Group__c = fileGroupId;

			BBApps_Crud.doInsert(fLink);
			return fLink.Id;
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPLOAD_FILE_LINK));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
    * Description : Method to get Files and file links
    * Parameters : fileGroupId String, displayReadMode String
    * Return Type : Map<String, List<SObject>> - String can be Files or Links values are all files or links related to given filegroup
                    Example of Map Entries: ('Files', List<ContentDocumentLink>) and ('Links', List<File_Link__c>)
    */
	@AuraEnabled(cacheable=true)
	public static Map<String, List<SObject>> getAllFiles(String fileGroupId) {
		System.debug('######FileGroupController-getAllFiles-fileGroupId: ' + fileGroupId);
		try {
			Map<String, List<SObject>> filesMap = new Map<String, List<SObject>>();
			List<ContentDocumentLink> fileList = [
				SELECT
					Id,
					LinkedEntityId,
					ContentDocumentId,
					ContentDocument.Title,
					ContentDocument.ContentModifiedDate,
					ContentDocument.OwnerId,
					ContentDocument.ContentSize,
					ContentDocument.Owner.Name,
					ContentDocument.FileExtension,
					ContentDocument.LatestPublishedVersion.ContentModifiedById,
					ContentDocument.LatestPublishedVersion.ContentModifiedBy.Name,
					Visibility
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :fileGroupId
				WITH SYSTEM_MODE
				ORDER BY ContentDocument.ContentModifiedDate DESC
			];
System.debug('######FileGroupController-getAllFiles-fileList: ' + fileList);
			List<File_Link__c> fileLinkList = [
				SELECT Id, Name, Link_URL__c, LastModifiedBy.Name, LastModifiedDate
				FROM File_Link__c
				WHERE File_Group__c = :fileGroupId
				WITH SYSTEM_MODE
				ORDER BY LastModifiedDate DESC
			];

			filesMap.put('Files', fileList);
			filesMap.put('Links', fileLinkList);
			return filesMap;
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_ALL_FILES));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Description : Method to delete Files and file links
	 * Parameters : recordId String, fileType String
	 * Return Type : void
	 */
	@AuraEnabled
	public static void deleteFile(String recordId, String fileType) {
		try {
			if (fileType == 'Link') {
				BBApps_Crud.doDelete(
                    [SELECT Id, Name FROM File_Link__c WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1]
                );
			} else {
				BBApps_Crud.doDelete(
                    [SELECT Id FROM ContentDocument WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1]
                );
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_DELETE_FILE_METHOD));
			throw new AuraHandledException(ex.getMessage());
		}
	}
}