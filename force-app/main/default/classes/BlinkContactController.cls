/**
 * Author : Paddy
 * Date   : 09/17/2024
 * Jira   : IM-20
 * Description : This class is a controller class for BlinkContactController LWC.
 * Test : BlinkContactControllerTest
 * Change Log :
   Sai - On Sep 24, 2025 - IM-404.  : Updated the link, unlink methods to separate them into two transactions.
 */
public with sharing class BlinkContactController {
	/**
	 * Description : Method to check if Bgive Org Creation functionality is enabled
	 * Return Type : Boolean
	 */
	@AuraEnabled(cacheable=true)
	public static Boolean isBgiveMasterContactInfoEnabled() {
		Environment_Setting__mdt setting = Environment.getEnvironmentSetting();
		return setting != null && setting.Enable_Blink_Master_Contact_Info__c;
	}

	@AuraEnabled
	public static Map<String, Object> searchContacts(String firstName, String lastName) {
		Map<String, Object> searchResults = new Map<String, Object>();
		BLinkContactService blinkContactService = new BLinkContactService();
		List<Contact> brmContacts = blinkContactService.searchBRM(firstName, lastName);
		searchResults.put('brmContacts', brmContacts);
		List<BLinkContactService.BGiveContact> bgiveContacts = blinkContactService.searchBgive(firstName, lastName);
		searchResults.put('bgiveContacts', bgiveContacts);
		searchResults.put('bgiveBaseURL', Environment.getBgiveBaseUrl());
		return searchResults;
	}

	@AuraEnabled
	public static BLinkContactService.BGiveContact getBgiveContact(String bgiveId) {
		BLinkContactService blinkContactService = new BLinkContactService();
		return blinkContactService.getBgiveContact(bgiveId);
	}

	@AuraEnabled
	public static Contact brmLink(Contact brmContact, String bgiveContact, String enableSolicitorHistory) {
		BLinkContactService blinkContactService = new BLinkContactService();
		try {
			BLinkContactService.BGiveContact bgiveContactDetails = (BLinkContactService.BGiveContact) JSON.deserialize(
				bgiveContact,
				BLinkContactService.BGiveContact.class
			);
			return blinkContactService.brmLink(brmContact, bgiveContactDetails, enableSolicitorHistory);
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static String brmUnlink(Contact brmContact, String enableSolicitorHistory) {
		try {
			return new BLinkContactService().brmUnlink(brmContact, enableSolicitorHistory);
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static Contact getContact(String Id) {
		return new BLinkContactService().getContact(id);
	}
}