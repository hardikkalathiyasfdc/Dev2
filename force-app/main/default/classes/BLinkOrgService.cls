/**
 * Author : Gauri Sagane
 * Date   : 10/22/2024
 * Jira   : IM-31
 * Description : This class provides methods needed to B-Link Org.
 * Test : BLinkOrgServiceTest
 * Change Log :
   Sai - On Sep 24, 2025 - IM-404.  : Updated the link, unlink methods to separate them into two transactions.
 */

public with sharing class BLinkOrgService {
	public class BLinkException extends Exception {
	}

	/**
	 * Description : Method to search Org in BRM using org name
	 * Parameters : orgName String.
	 * Return Type : List<Account>
	 */
	public List<Account> searchBRM(String orgName, String contigId) {
		List<Account> orgs = new List<Account>();
        Boolean canReadRestricted = Schema.sObjectType.Account.fields.Restricted__c.isAccessible();
		String soql = 'SELECT Id, Name, Restricted_Org_Name__c, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Id__c, Bgive_Contig_Id__c, ';
		soql += 'Website, BillingStreet, BillingCity, BillingState, BillingCountry, Restricted__c ';
		soql += 'FROM Account';
        
		  
 
		List<String> filters = new List<String>();
		if (String.isNotBlank(orgName)) {
			// Search orgs that starts with the name given in search inputs
			orgName = '%' + orgName + '%';
			if (canReadRestricted) {
        	filters.add(' (Restricted_Org_Name__c LIKE :orgName AND Restricted__c = true) ');
			}
			filters.add('(( Name LIKE :orgName OR Legal_Name__c LIKE :orgName OR AKA__c LIKE :orgName ) AND Restricted__c = false)');
		}
		if (String.isNotBlank(contigId)) {
			filters.add('Bgive_Contig_Id__c LIKE :contigId');
		}
		if (!filters.isEmpty()) {
			soql += ' WHERE ' + String.join(filters, ' OR ');
		}
		soql += ' ORDER BY Name ASC';
		if (!filters.isEmpty()) {
			orgs = Database.query(soql, AccessLevel.SYSTEM_MODE);
		}
		return orgs;
	}
	/**
	 * Description : Method to search Org in BGive with the name given in search inputs
	 * Parameters : orgName String.
	 * Return Type : List<BGiveOrg>
	 */
	public List<BGiveOrg> searchBgive(String orgName, String contigId) {
		if (String.isBlank(orgName) && String.isBlank(contigId)) {
			throw new BLinkException('Please provide Org Name initials or Contig Id to search');
		}
		Map<String, Object> relationshipFieldMap = new Map<String, Object>();
		List<String> fields = new List<String>();
		fields.add('name');
		relationshipFieldMap.put('geo_country_id', fields);
		relationshipFieldMap.put('geo_state_id', fields);
		String filter = BLinkUtil.getOrgSearchFilter(orgName, contigId);
		BGiveApiOrg bao = new BGiveApiOrg();
		bao.setFilters(filter);
		bao.setRelationColumns(relationshipFieldMap);
		try {
			BGiveApi.BGiveAPIListResponse response = (BGiveApi.BGiveAPIListResponse) bao.get();
			if (response.records != null && response.records.size() > 0) {
				return (List<BGiveOrg>) JSON.deserialize(JSON.serialize(response.records), List<BGiveOrg>.class);
			}
		} catch (Exception e) {
			UtilityClass.logError('', 'Organization Object: Cannot Search Org in BGive' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
		}
		return null;
	}

	/**
	 * Description : Method to create org in BRM and link with Bgive
	 * Parameters  : String bgiveOrg
	 * Return Type : Account
	 */
	public Account createInBrmAndLink(BGiveOrg bgiveOrg) {
		Account newOrg = null;
		try {
			newOrg = BLinkUtil.createBRMOrg(bgiveOrg);
			// update org id in BGive - Future call
			updateBGiveWithBRMOrgId(newOrg.Id, bgiveOrg.id);
		} catch (Exception ex) {
			UtilityClass.logError('', 'Organization Object: Cannot Create Org in BRM' + ex.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			throw new BLinkException('Organization Object: Cannot Create Org in BRM' + ex.getMessage());
		}
		return newOrg;
	}

	/**
	 * Description : Method to create Org in Bgive and Link with BRM
	 * Parameters  : Account brmOrg
	 * Return Type : Account
	 */
	public Account createInBgiveAndLink(Account brmOrg) {
		Account updatedAcc = null;
		List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');

		try {
			Map<String, Object> data = BLinkUtil.formOrgSyncPayload(brmOrg, null, syncFieldMappings);
			data.put('brm_id', brmOrg.Id);
			data.put('acronym', brmOrg.AKA__c);
			data.put('brm_sync_hash', BLinkUtil.getOrgBRMHash(brmOrg, null, syncFieldMappings));

			BGiveApi.BGiveAPIResponse createResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiOrg().create(data, null);
			BGiveOrg orgDetails = (BGiveOrg) JSON.deserialize(JSON.serialize(createResponse.record), BGiveOrg.class);

			if (orgDetails != null) {
				//update the brm org with bgive id
				updatedAcc = updateBRMOrg(brmOrg, orgDetails);
			} else {
				UtilityClass.logError('', 'Organization Object: Cannot Create Org in BGive', Assets.BLINK_SYNC_ERROR_TYPE);
				throw new BLinkException('Organization Object: Cannot Create Org in BGive');
			}
		} catch (Exception ex) {
			UtilityClass.logError('', 'Organization Object: Cannot Create Org in BGive' + ex.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			throw new BLinkException('Organization Object: Cannot Create Org in BGive' + ex.getMessage());
		}
		return updatedAcc;
	}

	/**
	 * Description : Method to link Org in BRM with BGive
	 * Parameters  : brmOrg Account, bgiveOrg BGiveOrg.
	 * Return Type : Account
	 */
	public Account brmLink(Account brmOrg, BGiveOrg bgiveOrg) {
		Account updatedOrg = null;
		if (brmOrg != null && bgiveOrg != null) {
			if (brmOrg.Bgive_Id__c != null && bgiveOrg.brm_id != null) {
				throw new BLinkException('Org is already linked to a BGive org');
			} else {
				try {
					updatedOrg = updateBRMOrg(brmOrg, bgiveOrg);
				} catch (DmlException dmlEx) {
					UtilityClass.logError(
						'',
						'Organization Object: Could not link Org in BRM with Bgive Org Id' + dmlEx.getMessage(),
						Assets.BLINK_SYNC_ERROR_TYPE
					);
					throw new BLinkException(String.format(Assets.GENERIC_EXCEPTION, new List<String>{ Assets.LINKING, Assets.BRM }));
				} catch (Exception ex) {
					UtilityClass.logError('', 'Organization Object: Could not link Org' + ex.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
					throw new BLinkException('Organization Object: Could not unlink Org' + ex.getMessage());
				}
			}
		}
		return updatedOrg;
	}

	/**
	 * Description : Method to link Org in Bgive with Brm
	 * Parameters  : brmOrg Account, bgiveOrg BGiveOrg.
	 * Return Type : Account
	 */
	@AuraEnabled
	public static String bgiveLink(Account brmOrg, String bgiveOrg) {
		List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');
		BGiveOrg bgiveOrgDetails = (BGiveOrg) JSON.deserialize(bgiveOrg, BGiveOrg.class);
		if (brmOrg != null && bgiveOrgDetails != null) {
			if (brmOrg.Bgive_Id__c != null && bgiveOrgDetails.brm_id != null) {
				throw new BLinkException('Org is already linked to a BGive org');
			} else {
				try {
					Map<String, Object> data = new Map<String, Object>();
					data.put('brm_id', brmOrg.id);
					data.put('brm_sync_hash', BLinkUtil.getOrgBRMHash(brmOrg, bgiveOrgDetails, syncFieldMappings));
					BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiOrg().modify(bgiveOrgDetails.id, data, null);
					BGiveOrg orgDetails = (BGiveOrg) JSON.deserialize(JSON.serialize(updateResponse.record), BGiveOrg.class);
					if (orgDetails != null) {
						return orgDetails.brm_id;
					} else {
						UtilityClass.logError('', 'Organization Object: Could not link Org', Assets.BLINK_SYNC_ERROR_TYPE);
						throw new AuraHandledException('Organization Object: Could not link Org');
					}
				} catch (CalloutException calloutEx) {
					UtilityClass.logError(
						'',
						'Organization Object: Could not link Org in BGive with BRM Org Id' + calloutEx.getMessage(),
						Assets.BLINK_SYNC_ERROR_TYPE
					);
					throw new AuraHandledException(calloutEx.getMessage());
				} catch (Exception ex) {
					UtilityClass.logError('', 'Organization Object: Could not link Org' + ex.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
					throw new AuraHandledException(ex.getMessage());
				}
			}
		}
		return null;
	}

	/**
	 * Description : Method to unlink Org in BRM
	 * Parameters  : brmOrg Account.
	 * Return Type : Account
	 */
	public String brmUnlink(Account brmOrg) {
		if (!String.isBlank(brmOrg.Bgive_Id__c)) {
			try {
				Account updatedAccount = updateBRMOrg(brmOrg, null);
				return updatedAccount.Bgive_Id__c;
			} catch (DmlException dmlEx) {
				UtilityClass.logError('', 'Organization Object: Could not unlink Org from BGive Org' + dmlEx.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
				throw new BLinkException(String.format(Assets.GENERIC_EXCEPTION, new List<String>{ Assets.UNLINKING, Assets.BRM }));
			} catch (Exception ex) {
				UtilityClass.logError('', 'Organization Object: Could not unlink Org' + ex.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
				throw new BLinkException('Organization Object: Could not unlink Org' + ex.getMessage());
			}
		} else {
			throw new BLinkException('Org is not linked to any BGive org');
		}
	}

	/**
	 * Description : Method to unlink Org in BGive
	 * Parameters  : brmOrg Account.
	 * Return Type : String
	 */
	@AuraEnabled
	public static String bgiveUnlink(Account brmOrg) {
		if (!String.isBlank(brmOrg.Bgive_Id__c)) {
			try {
				Map<String, Object> data = new Map<String, Object>();
				data.put('brm_id', '');
				BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiOrg().modify(brmOrg.Bgive_Id__c, data, null);
				BGiveOrg orgDetails = (BGiveOrg) JSON.deserialize(JSON.serialize(updateResponse.record), BGiveOrg.class);
				if (orgDetails != null) {
					return orgDetails.brm_id;
				} else {
					UtilityClass.logError('', 'Organization Object: Could not unlink Org', Assets.BLINK_SYNC_ERROR_TYPE);
					throw new BLinkException('Organization Object: Could not unlink Org');
				}
			} catch (CalloutException calloutEx) {
				UtilityClass.logError('', 'Organization Object: Could not unlink Org from BGive Org' + calloutEx.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
				throw new BLinkException(String.format(Assets.GENERIC_EXCEPTION, new List<String>{ Assets.UNLINKING, Assets.BRM }));
			} catch (Exception ex) {
				UtilityClass.logError('', 'Organization Object: Could not unlink Org' + ex.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
				throw new BLinkException('Organization Object: Could not unlink Org' + ex.getMessage());
			}
		} else {
			throw new BLinkException('Org is not linked to any BGive org');
		}
	}

	/**
	 * Description : Method to get org from bgive using bgive id
	 * Parameters : orgBGiveId String.
	 * Return Type : BGiveOrg
	 */
	public BGiveOrg getBgiveOrg(String orgBGiveId) {
		if (orgBGiveId != null) {
			try {
				BGiveApi.BGiveAPIResponse fetchResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiOrg().fetch(orgBGiveId, null);
				if (fetchResponse.record != null) {
					return (BGiveOrg) JSON.deserialize(JSON.serialize(fetchResponse.record), BGiveOrg.class);
				}
			} catch (Exception e) {
				UtilityClass.logError('', 'Organization Object: Could not fetch Org from BGive' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			}
		}
		return null;
	}

	/**
	 * Description : Method to get organization from BRM using org id
	 * Parameters : orgId Id.
	 * Return Type : Account
	 */
	public Account getOrganization(Id orgId) {
		if (orgId != null) {
			return [
				SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Id__c, Bgive_Contig_Id__c, Restricted__c, Restricted_Org_Name__c
				FROM Account
				WHERE Id = :orgId
				WITH SYSTEM_MODE 
				LIMIT 1
			];
		}
		return null;
	}

	/**
	 * Description : Method to sync BRM Org with BGive
	 * Parameters : brmOrg Account.
	 * Return Type : void
	 */
	public void sync(Account brmOrg) {
		try {
			if (brmOrg.Bgive_Id__c != null) {
				List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFieldsForOrg('Account');
				List<BLink_Sync_Field_Mapping__mdt> syncFieldMappingsForHash = BLinkUtil.getSyncFields('Account');
				BLinkOrgService.BGiveOrg bgiveOrg = getBgiveOrg(brmOrg.Bgive_Id__c);
				if (bgiveOrg != null) {
					Map<String, Object> payload = new Map<String, Object>();
					if (BLinkUtil.isOrgDiffers(brmOrg, bgiveOrg, syncFieldMappings)) {
						// set Bgive Fields
						payload = BLinkUtil.formOrgSyncPayload(brmOrg, bgiveOrg, syncFieldMappings);
					}
					payload.put('brm_sync_hash', BLinkUtil.getOrgBRMHash(brmOrg, bgiveOrg, syncFieldMappingsForHash));
					new BGiveApiOrg().modify(brmOrg.Bgive_Id__c, payload, null);
				} else {
					UtilityClass.logError(brmOrg.Id, 'No Matching Bgive Org Found', Assets.BLINK_SYNC_ERROR_TYPE);
				}
			}
		} catch (BGiveApi.BGiveCalloutException e) {
			UtilityClass.logError(brmOrg.Id, 'Error in Bgive Callout: ' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
		} catch (Exception e) {
			UtilityClass.logError(brmOrg.Id, 'Error: ' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
		}
	}

	/**
	 * Description : Method to update BGive with org Id after org is created in BRM
	 * Parameters : orgId Id.
	 * Return Type : void
	 */
	@future(callout=true)
	private static void updateBGiveWithBRMOrgId(Id orgId, String bgiveOrgId) {
		BLinkOrgService bos = new BLinkOrgService();
		Account org = bos.getOrganization(orgId);
		BGiveOrg bgiveOrg = bos.getBgiveOrg(bgiveOrgId);
		List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');
		Map<String, Object> data = new Map<String, Object>();
		data.put('brm_id', org.Id);
		data.put('name', org.Name);
		data.put('brm_sync_hash', BLinkUtil.getOrgBRMHash(org, bgiveOrg, syncFieldMappings));
		try {
			BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiOrg().modify(org.Bgive_Id__c, data, null);
		} catch (Exception e) {
			UtilityClass.logError('', 'Organization Object: Cannot Update Org in BGive with BRM Id' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
		}
	}

	/**
	 * Description : Method to update Organization in BRM with BGive Id
	 * Parameters  : brmOrg Account, BGiveOrg orgDetails.
	 * Return Type : Account
	 */
	public Account updateBRMOrg(Account brmOrg, BGiveOrg orgDetails) {
		if (brmOrg != null) {
			if (orgDetails != null) {
				brmOrg.Bgive_Id__c = orgDetails.id;
				brmOrg.Bgive_Contig_Id__c = orgDetails.contig_id;
				brmOrg.Legal_Name__c = orgDetails.legal_name;
				brmOrg.Tax_ID__c = orgDetails.tax_id;
				brmOrg.Tax_Status__c = orgDetails.tax_class;
			} else {
				brmOrg.Bgive_Id__c = null;
				brmOrg.Bgive_Contig_Id__c = null;
			}
			update as system brmOrg;
			return [SELECT Id, Bgive_Id__c FROM Account WHERE Id = :brmOrg.Id WITH SYSTEM_MODE];
		}
		return null;
	}

	public class BGiveOrg {
		@AuraEnabled
		public String id;
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String acronym;
		@AuraEnabled
		public String legal_name;
		@AuraEnabled
		public String tax_class;
		@AuraEnabled
		public String tax_id;
		@AuraEnabled
		public String brm_id;
		@AuraEnabled
		public String contig_id;
		@AuraEnabled
		public String street_address;
		@AuraEnabled
		public String city;
		@AuraEnabled
		public String url;
		@AuraEnabled
		public List<GeoFields> geo_country_id;
		@AuraEnabled
		public List<GeoFields> geo_state_id;

		public String get(String fieldName) {
			switch on fieldName {
				when 'name' {
					return this.name;
				}
				when 'legal_name' {
					return this.legal_name;
				}
				when 'tax_class' {
					return this.tax_class;
				}
				when 'tax_id' {
					return this.tax_id;
				}
				when 'brm_id' {
					return this.brm_id;
				}
				when 'contig_id' {
					return this.contig_id;
				}
				when else {
					return '';
				}
			}
		}
	}

	public class GeoFields {
		@AuraEnabled
		public Integer id;
		@AuraEnabled
		public String name;
	}
}