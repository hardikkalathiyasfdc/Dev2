/**
 * Author : Gauri Sagane
 * Date   : 09/24/2024
 * Jira   : IM-25
 * Description : This class provides methods needed to B-Link Contact.
 * Test : BLinkContactServiceTest
 * Change Log : 
   Sai - On Sep 24, 2025 - IM-404.  : Updated the link, unlink methods to separate them into two transactions.
 */

public with sharing class BLinkContactService {
	public class ContactSearchException extends Exception {
	}

	// Search Contact in BRM with firstname and lastname
	public List<Contact> searchBRM(String firstName, String lastName) {
		List<Contact> conList = new List<Contact>();
		 Boolean canReadRestricted = Schema.sObjectType.Contact.fields.Restricted__c.isAccessible();
		if (!String.isBlank(firstName) && !String.isBlank(lastName)) {
			// Search contacts that starts with given First Name / Last Name search inputs
			firstName = firstName + '%';
			lastName = lastName + '%';
		} else {
			throw new ContactSearchException('Please provide first Name and Last Name initials to search');
		}
		String soql = 'SELECT Id,Restricted__c,FirstName,LastName,Preferred_First_Name__c,RestrictedFirstName__c,RestrictedLastName__c,RestrictedMiddleName__c,Email,Salutation,MiddleName,title,Phone, ' ;
			soql += 'AccountId,Account.Name,Account.Restricted_Org_Name__c,Account.Restricted__c,Bgive_Contig_Id__c,Bgive_Id__c,Solicitor_History_Status__c FROM Contact';
		if(canReadRestricted){
        	soql += ' WHERE (RestrictedFirstName__c LIKE : firstName  OR  RestrictedLastName__c LIKE :lastName) OR ((FirstName LIKE :firstName OR Preferred_First_Name__c LIKE :firstName) AND LastName LIKE :lastName)';
		}else {
        	soql += ' WHERE (FirstName LIKE :firstName OR Preferred_First_Name__c LIKE :firstName) AND LastName LIKE :lastName';
		}	
	    conList = Database.query(soql, AccessLevel.SYSTEM_MODE);
		return conList;
	}

	// Search Contact in BGive with firstname and lastname
	public List<BGiveContact> searchBgive(String firstName, String lastName) {
		if (!String.isBlank(firstName) && !String.isBlank(lastName)) {
			String filter = BLinkUtil.getSearchFilter(firstName, lastName);
			BGiveApiContact bac = new BGiveApiContact();
			bac.setFilters(filter);
			try {
				BGiveApi.BGiveAPIListResponse response = (BGiveApi.BGiveAPIListResponse) bac.get();
				if (response.records != null && response.records.size() > 0) {
					return (List<BGiveContact>) JSON.deserialize(JSON.serialize(response.records), List<BGiveContact>.class);
				}
			} catch (Exception e) {
				UtilityClass.logError('', 'Contact Object: Cannot Search Contact in BGive' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			}
			return null;
		} else {
			throw new ContactSearchException('Please provide first Name and Last Name initials to search');
		}
	}

	// Link Contact in BRM
	public Contact brmLink(Contact brmContact, BGiveContact bgiveContact, String enableSolicitorHistory) {
		Contact contact = null;
		//check if contact not present in brm, but present in bgive
		if (brmContact == null && bgiveContact != null) {
			//create contact in brm
			contact = BLinkUtil.createBRMContact(bgiveContact, enableSolicitorHistory);
			// update contact id in BGive
			updateBGiveWithContactId(contact.Id);
		} else if (brmContact != null && bgiveContact != null) {
			//contact present at both places
			try {
				contact = updateBRMContact(brmContact, bgiveContact.id, bgiveContact.contig_id, enableSolicitorHistory);
			} catch (DmlException dmlEx) {
				UtilityClass.logError('', 'Contact Object: Could not link Contact in BRM with Bgive Id' + dmlEx.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
				throw new ContactSearchException(String.format(Assets.GENERIC_EXCEPTION, new List<String>{ Assets.LINKING, Assets.BRM }));
			} catch (Exception e) {
				UtilityClass.logError('', 'Contact Object: Could not link Contact' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
				throw new ContactSearchException('Contact Object: Could not link Contact' + e.getMessage());
			}
		}
		return contact;
	}

	// Link Contact in BGive
	@AuraEnabled
	public static String bgiveLink(Contact brmContact, String bgiveContact) {
		String brmId = '';
		BGiveContact bgiveContactDetails = (BGiveContact) JSON.deserialize(bgiveContact, BGiveContact.class);
		try {
			Map<String, Object> data = new Map<String, Object>();
			data.put('brm_id', brmContact.Id);
			BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiContact().modify(bgiveContactDetails.id, data, null);
			BGiveContact conDetails = (BGiveContact) JSON.deserialize(JSON.serialize(updateResponse.record), BGiveContact.class);
			brmId = conDetails.brm_id;
		} catch (CalloutException calloutEx) {
			UtilityClass.logError('', 'Contact Object: Could not link Contact in BGive with BRM Id' + calloutEx.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			throw new AuraHandledException(calloutEx.getMessage());
		} catch (Exception ex) {
			UtilityClass.logError('', 'Contact Object: Could not link Contact' + ex.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			throw new AuraHandledException(ex.getMessage());
		}
		return brmId;
	}

	// Unlink Contact in BRM
	public String brmUnlink(Contact brmContact, String enableSolicitorHistory) {
		String bgiveId = '';
		if (!String.isBlank(brmContact.Bgive_Id__c)) {
			try {
				//IM-344: Separate transactions for BRM and Bgive Update
				Contact updatedContact = updateBRMContact(brmContact, '', '', enableSolicitorHistory);
				bgiveId = updatedContact.Bgive_Id__c;
			} catch (DmlException dmlEx) {
				UtilityClass.logError('', 'Contact Object: Could not unlink Contact in BRM with Bgive Id' + dmlEx.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
				throw new ContactSearchException(String.format(Assets.GENERIC_EXCEPTION, new List<String>{ Assets.UNLINKING, Assets.BRM }));
			} catch (Exception e) {
				UtilityClass.logError('', 'Contact Object: Could not unlink Contact' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
				throw new ContactSearchException('Contact Object: Could not unlink Contact' + e.getMessage());
			}
		} else {
			throw new ContactSearchException('Contact is not linked to any BGive contact');
		}
		return bgiveId;
	}

	// Unlink Contact in Bgive from BRM
	@AuraEnabled
	public static String bgiveUnlink(Contact brmContact) {
		String brmId = '';
		try {
			Map<String, Object> data = new Map<String, Object>();
			data.put('brm_id', '');
			BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiContact().modify(brmContact.Bgive_Id__c, data, null);
			BGiveContact conDetails = (BGiveContact) JSON.deserialize(JSON.serialize(updateResponse.record), BGiveContact.class);
			brmId = conDetails.brm_id;
		} catch (CalloutException calloutEx) {
			UtilityClass.logError('', 'Contact Object: Could not unlink Contact in BGive with BRM Id' + calloutEx.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			throw new ContactSearchException(String.format(Assets.GENERIC_EXCEPTION, new List<String>{ Assets.UNLINKING, Assets.BGIVE }));
		} catch (Exception e) {
			UtilityClass.logError('', 'Contact Object: Could not unlink Contact' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			throw new ContactSearchException('Contact Object: Could not unlink Contact' + e.getMessage());
		}
		return brmId;
	}

	// Get contact from bgive using bgive id
	public BGiveContact getBgiveContact(String bgiveId) {
		if (bgiveId != null) {
			try {
				BGiveApi.BGiveAPIResponse fetchResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiContact().fetch(bgiveId, null);
				if (fetchResponse.record != null) {
					return (BGiveContact) JSON.deserialize(JSON.serialize(fetchResponse.record), BGiveContact.class);
				}
			} catch (Exception e) {
				UtilityClass.logError('', 'Contact Object: Could not fetch Contact from BGive' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
			}
		}
		return null;
	}

	// Get contact from BRM using contact id
	public Contact getContact(Id id) {
		if (id != null) {
			return [
				SELECT
					Id,
					Name,
					FirstName,
					LastName,
					Preferred_First_Name__c,
					Email,
					Salutation,
					MiddleName,
					title,
					Phone,
					AccountId,
					Account.Name,
					Bgive_Contig_Id__c,
					Bgive_Id__c,
					Solicitor_History_Status__c,
					Restricted__c,
					Restricted_Name__c,
					Restricted_Org_Name__c,
					RestrictedFirstName__c,
					RestrictedLastName__c
				FROM Contact
				WHERE Id = :id
				WITH SYSTEM_MODE 
				LIMIT 1
			];
		}
		return null;
	}

	//  Method to update BGive with contact Id after contact is created in BRM
	@future(callout=true)
	private static void updateBGiveWithContactId(Id conId) {
		BLinkContactService bcs = new BLinkContactService();
		Contact con = bcs.getContact(conId);
		Map<String, Object> data = new Map<String, Object>();
		data.put('brm_id', con.Id);
		try {
			BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiContact().modify(con.Bgive_Id__c, data, null);
		} catch (Exception e) {
			UtilityClass.logError('', 'Contact Object: Cannot Update Contact in BGive with BRM Id' + e.getMessage(), Assets.BLINK_SYNC_ERROR_TYPE);
		}
	}

	// Update Contact in BRM with BGive Id and Solicitor History Status
	@AuraEnabled
	public static Contact updateBRMContact(Contact brmContact, String bGiveId, String bGiveContigId, String enableSolicitorHistory) {
		Contact updatedContact = null;
		try {
			if (brmContact != null) {
				brmContact.Bgive_Id__c = bGiveId;
				brmContact.Bgive_Contig_Id__c = bGiveContigId;
				brmContact.Solicitor_History_Status__c = enableSolicitorHistory;
				if(brmContact.Restricted__c){
                    brmContact.FirstName = '';
                    brmContact.LastName = Assets.RESTRICTED_ORG_NAME;
                }
				update as system brmContact;
				updatedContact = [SELECT Id, Bgive_Id__c 
									FROM Contact 
									WHERE Id = :brmContact.Id 
									WITH SYSTEM_MODE];
			}
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
		return updatedContact;
	}

	public class BGiveContact {
		@AuraEnabled
		public String id;
		@AuraEnabled
		public String first_name;
		@AuraEnabled
		public String last_name;
		@AuraEnabled
		public String preferred_first_name;
		@AuraEnabled
		public String email;
		@AuraEnabled
		public String salutation;
		@AuraEnabled
		public String prefix;
		@AuraEnabled
		public String middle_initial;
		@AuraEnabled
		public String title;
		@AuraEnabled
		public String brm_id;
		@AuraEnabled
		public String primary_organization_id;
		@AuraEnabled
		public String primary_org_sort_name;
		@AuraEnabled
		public String contig_id;
		@AuraEnabled
		public String deceased;
		@AuraEnabled
		public String suffix;
		@AuraEnabled
		public String maiden_name;
	}
}