/**
 * Author : Paddy
 * Date   : 12/13/2024
 * Jira   : IM-73
 * Description : This class is a controller class for BlinkContactController LWC.
 * Test : BlinkOrganizationControllerTest
 * Change Log :
   Sai - On Sep 24, 2025 - IM-404.  : Updated the link, unlink methods to separate them into two transactions.
 */
public with sharing class BlinkOrganizationController {
	/**
	 * Description : Method to check if Bgive Org Creation functionality is enabled
	 * Return Type : Boolean
	 */
	@AuraEnabled(cacheable=true)
	public static Boolean isBgiveOrgCreationEnabled() {
		return FeatureManagement.checkPermission('B_Link_Organization_Create_in_Bgive_Access');
	}

	/**
	 * Description : Method to search Org in BRM using org name
	 * Parameters  : String orgName
	 * Return Type : Map<String, Object>
	 */
	@AuraEnabled
	public static Map<String, Object> searchOrganization(String orgName, String contigId) {
		Map<String, Object> searchResults = new Map<String, Object>();
		BLinkOrgService blinkOrgService = new BLinkOrgService();
		List<Account> brmOrgs = blinkOrgService.searchBRM(orgName, contigId);
		searchResults.put('brmOrgs', brmOrgs);
		List<BLinkOrgService.BGiveOrg> bgiveOrgs = blinkOrgService.searchBgive(orgName, contigId);
		if (bgiveOrgs == null) {
			searchResults.put('bgiveOrgs', new List<BLinkOrgService.BGiveOrg>());
		} else {
			searchResults.put('bgiveOrgs', bgiveOrgs);
		}
        searchResults.put('bgiveBaseURL', Environment.getBgiveBaseUrl());
		return searchResults;
	}

	/**
	 * Description : Method to create org in BRM and link with Bgive
	 * Parameters  : String bgiveOrg
	 * Return Type : Account
	 */
	@AuraEnabled
	public static Account createInBrmAndLink(String bgiveOrg) {
		try {
			BLinkOrgService.BGiveOrg bgiveOrgDetails = (BLinkOrgService.BGiveOrg) JSON.deserialize(bgiveOrg, BLinkOrgService.BGiveOrg.class);
			return new BLinkOrgService().createInBrmAndLink(bgiveOrgDetails);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to create Org in Bgive and Link with BRM
	 * Parameters  : Account brmOrg
	 * Return Type : Account
	 */
	@AuraEnabled
	public static Account createInBgiveAndLink(Account brmOrg) {
		try {
			return new BLinkOrgService().createInBgiveAndLink(brmOrg);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to link Org in BRM with BGive
	 * Parameters  : Account brmOrg, String bgiveOrg
	 * Return Type : Boolean
	 */
	@AuraEnabled
	public static Account brmLink(Account brmOrg, String bgiveOrg) {
		try {
			BLinkOrgService.BGiveOrg bgiveOrgDetails = (BLinkOrgService.BGiveOrg) JSON.deserialize(bgiveOrg, BLinkOrgService.BGiveOrg.class);
			return new BLinkOrgService().brmLink(brmOrg, bgiveOrgDetails);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to unlink Orgs in BRM and BGive
	 * Parameters  : Account brmOrg.
	 * Return Type : void
	 */
	@AuraEnabled
	public static String brmUnlink(Account brmOrg) {
		try {
			return new BLinkOrgService().brmunlink(brmOrg);
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Description : Method to get organization from BRM using org id
	 * Parameters  : String orgId.
	 * Return Type : Account
	 */
	@AuraEnabled(cacheable=true)
	public static Account getOrganization(String ordId) {
		return new BLinkOrgService().getOrganization(ordId);
	}

	/**
	 * Description : Method to get org from bgive using bgive id
	 * Parameters : orgBGiveId String.
	 * Return Type : BLinkOrgService.BGiveOrg
	 */
	@AuraEnabled(cacheable=true)
	public static BLinkOrgService.BGiveOrg getBgiveOrg(String orgBGiveId) {
		return new BLinkOrgService().getBgiveOrg(orgBGiveId);
	}
}