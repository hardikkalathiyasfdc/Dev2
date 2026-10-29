/***
 * Description: This class has methods being used to fetch data for addGuest, contactCreation, contactSearch, eventCreation lwcs.
 * 				It also has the method to sync data from Zkipster being referenced in SyncGuestInfoToZkipster and SyncGuestInfoFromZkipster
 * 				Aura Components.
 * Test Class: EventMangementAuraCtrl_Test
 ***/
public with sharing class EventMangementAuraCtrl {

	public static Boolean isFromEventsTab = false;
	public final static String EVENT_RECORD_TYPE_ID = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
		.get('Pre_Event')
		.getRecordTypeId();
	public final static String GUEST_RECORD_TYPE_ID = Schema.SObjectType.CampaignMember.getRecordTypeInfosByDeveloperName()
		.get('Event')
		.getRecordTypeId();
	public final static Map<String, String> EMAIL_NAME_MAP = new Map<String, String>{
		'savethedate' => 'Save the Date',
		'invitation' => 'Invitation',
		'reminder' => 'Reminder',
		'email' => 'Email'
	};

	public final static Map<String, String> EMAIL_SUBJECT_MAP = new Map<String, String>{
		'savethedate' => 'Save_The_Date_Subject__c',
		'invitation' => 'EmailSubjectLine__c',
		'reminder' => 'Reminder_Subject__c',
		'email' => 'Email_Subject__c'
	};

	public final static Map<String, String> EMAIL_TYPE_MAP = new Map<String, String>{
		'savethedate' => 'Save_The_Date_Email_Body__c',
		'invitation' => 'Invite_Email_Body__c',
		'reminder' => 'Reminder_Email_Body__c',
		'email' => 'EventEmailBody__c'
	};

	public final static Map<String, String> EMAIL_CB_MAP = new Map<String, String>{
		'savethedate' => 'Has_Save_The_Date__c',
		'invitation' => 'Has_Invite_Email__c',
		'reminder' => 'Has_Reminder_Email__c',
		'email' => 'Has_Event_Email__c'
	};

	public final static Map<String, String> EMAIL_DATETIME_MAP = new Map<String, String>{
		'savethedate' => 'Save_The_Date_Sent__c',
		'invitation' => 'Invitation_Sent__c',
		'reminder' => 'Reminder_Email_Sent__c',
		'email' => 'Email_Sent__c'
	};

	public final static Map<String, String> EMAIL_STATUS_MAP = new Map<String, String>{
		'savethedate' => 'Save_The_Date_Status__c',
		'invitation' => 'Invitation_Status__c',
		'reminder' => 'Reminder_Email_Status__c',
		'email' => 'Email_Status__c'
	};

	@AuraEnabled(cacheable=true)
	public static String getCurrentUser(String userId) {
		if(userId == '' || userId == null) {
			userId = UserInfo.getUserId();
		}
		return JSON.serialize([SELECT Id, BP_Team__c FROM User WHERE Id = :userId WITH SYSTEM_MODE]);
	}

	@AuraEnabled(cacheable=true)
	public static String getCurrentTiemZone() {
		User usr = [
			SELECT TimeZoneSidKey
			FROM User
			WHERE id = :USerInfo.getUserId() WITH SYSTEM_MODE
		];
		return usr.TimeZoneSidKey;
	}

	@AuraEnabled(cacheable=true)
	public static String getEventRecordTypeId() {
		return EVENT_RECORD_TYPE_ID;
	}

	@AuraEnabled
	public static void deleteUnplannedGuest(String guestId) {
		delete [SELECT Id FROM UnplannedGuest__c WHERE Id = :guestId WITH SYSTEM_MODE];
	}

	@AuraEnabled
	public static String syncEvent(String listId) {
		String result = 'success';
		Campaign camp = [
			SELECT
				Id,
				Name,
				EventStatus__c,
				EventType__c,
				Is_Zkipster_Sync__c,
				Start_Date_Time__c,
				End_Date_Time__c,
				LocationDetail__c,
				LocationName__c,
				Venue__c,
				VirtualEventLink__c,
				SetUpEventLocationType__c,
				TimeZone__c,
				AddressLine__c,
				City__c,
				State__c,
				StartDateUtc__c,
				EndDateUtc__c,
				ZkipsterEventID__c,
				ZkipsterGuestListId__c,
				KeepZKipsterSync__c,
				Country__c
			FROM Campaign
			WHERE Id = :listId WITH SYSTEM_MODE
		];
		if(camp.EventStatus__c == 'Cancelled' || camp.EventStatus__c == 'Complete') {
			return 'Cancelled';
		}
		if(camp.Is_Zkipster_Sync__c == true) {
			throw new AuraHandledException(
				'There is already a zkipster sync in progress, please wait for sync to complete.'
			);
		}
		if(camp.StartDateUtc__c < Datetime.now()) {
			throw new AuraHandledException(
				'Unable to sync Cancelled or Complete events to zkipster.'
			);
		} else if(camp.End_Date_Time__c < camp.Start_Date_Time__c) {
			throw new AuraHandledException(
				'Unable to sync Cancelled or Complete events to zkipster.'
			);
		}
		if((camp.SetUpEventLocationType__c == 'Virtual' ||
			camp.SetUpEventLocationType__c == 'Hybrid') &&
			String.isBlank(camp.VirtualEventLink__c)) {

			camp.VirtualEventLink__c = 'TBD';
		}
		if(camp.ZkipsterEventID__c == null) {
			String eventId = ZkipsterIntegration.syncZkipsterEventCreation(camp);
			if(eventId != '' && eventId != 'error') {
				String guestListId = ZkipsterIntegration.syncZkipsterGuestListCreation(
					camp.Name,
					eventId
				);
				if(guestListId != '') {
					camp.ZkipsterGuestListId__c = guestListId;
				}
				camp.ZkipsterEventID__c = eventId;
				camp.KeepZKipsterSync__c = true;
			}
			update camp;
		} else {
			String eventId = ZkipsterIntegration.syncZkipsterEventUpdate(camp);
			// Callout errors are logged via BBApps_ErrorHandler inside zkipsterCallout; surface failure to the caller
			if(eventId == 'error') {
				result = 'error';
			}
		}
		syncZkipsterGuests(camp.Id);
		return result;
	}

	@AuraEnabled(cacheable=true)
	public static Boolean checkEventList(String recordId) {
		Campaign camp = [
			SELECT RecordType.DeveloperName
			FROM Campaign
			WHERE Id = :recordId WITH SYSTEM_MODE
		];
		Boolean isEventList = false;
		if(camp.RecordType.DeveloperName == 'Pre_Event') {
			isEventList = true;
		}
		return isEventList;
	}

	@AuraEnabled(cacheable=true)
	public static String getOrgEmails() {
		return JSON.serialize(
			[SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where Address LIKE '%e.bloomberg.org%' WITH SYSTEM_MODE]
		);
	}

	@AuraEnabled(cacheable=true)
	public static String getOrgEmailsByEvent(String eventId) {
		Campaign cm = [
			SELECT InvitationFromEmail__c
			FROM Campaign
			WHERE Id = :eventId WITH SYSTEM_MODE
		];
		return JSON.serialize([SELECT Id, Address, DisplayName
			 				   FROM OrgWideEmailAddress
							   WHERE Address = :cm.InvitationFromEmail__c WITH SYSTEM_MODE]);
	}

	@AuraEnabled
	public static String updateOrgEmails(String updatedEmails, String eventId) {
		OrgWideEmailAddress email = (OrgWideEmailAddress) JSON.deserialize(
			updatedEmails,
			OrgWideEmailAddress.class
		);
		Campaign cm = new Campaign(Id = eventId);
		cm.InvitaitonEmailFromName__c = email.DisplayName;
		cm.InvitationFromEmail__c = email.Address;
		update cm;
		processOrgEamilsUpdate(new List<String>{ updatedEmails });
		return 'success';
	}

	@future(callout=true)
	public static void processOrgEamilsUpdate(List<String> orgEmails) {
		OrgWideEmailAddress email = (OrgWideEmailAddress) JSON.deserialize(
			orgEmails[0],
			OrgWideEmailAddress.class
		);
		HttpResponse res = updateOrgEmail(email.DisplayName, email.Id);
		if(res.getStatusCode() != 200) {
			BBApps_ErrorHandler.logErrors(
				new BRMException('EventMangementAuraCtrl.processOrgEamilsUpdate: ' + res.getStatusCode() + ': ' + res.getBody()),
				new BBApps_ErrorCustomFields('EVENT_MANAGEMENT_ORG_EMAIL_UPDATE_FAILED')
			);
		}
	}

	@AuraEnabled(cacheable=true)
	public static String getUnplannedGuests(String eventId) {
		return JSON.serialize([
			SELECT Id, FirstName__c, LastName__c, Phone__c, Notes__c, Email__c, Attended__c, Organization__c, Salutation__c
			FROM UnplannedGuest__c
			WHERE Event__c = :eventId WITH SYSTEM_MODE
		]);
	}

	@AuraEnabled
	public static String startSyncFromZkipster(String eventId) {
		List<CampaignMember> guests = new List<CampaignMember>();
		List<UnplannedGuest__c> unplannedGuests = new List<UnplannedGuest__c>();
		Campaign camp = [
			SELECT ZkipsterGuestListId__c,Name,EventStatus__c, SetUpEventLocationType__c
			FROM Campaign
			WHERE Id = :eventId WITH SYSTEM_MODE
		];
		if(camp.EventStatus__c == 'Cancelled') {
			return 'Cancelled';
		}
		Id jobId = System.enqueueJob(new zkipsterGetAllGuestsAsync(camp.ZkipsterGuestListId__c,eventId,camp.Name));
		return  jobId;
	}

    @AuraEnabled
    public static void updateAssistants(List<Id> memIdList, boolean ccVal, List<String> selectedEmailFields,List<String> destinationFields, boolean removeEmails) {
        List<CampaignMember> memList = [
            SELECT Id, CC_Assistant__c, ContactId, Additional_Email__c, Contact_Personal_Email__c, CC_Addresses__c, BCC_Addresses__c
            FROM CampaignMember
            WHERE Id IN :memIdList WITH SYSTEM_MODE
        ];
        Set<String> contactIds = new Set<String>();
        for(CampaignMember mem : memList) {
            mem.CC_Assistant__c = ccVal;
            if(mem.ContactId != null) {
                contactIds.add(mem.ContactId);
            }
        }
        if(!contactIds.isEmpty()) {
            Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id,Email,Alternate_Email__c,Business_Email_2__c, Personal_Email_2__c FROM Contact WHERE Id IN :contactIds]);
            Map<String, Related_Contact__c> assistants = getAssistantByContact(new List<String>(contactIds));
            for(CampaignMember mem : memList) {
				List<String> selectedEmails = new List<String>();
                if(assistants.get(mem.ContactId) != null && assistants.get(mem.ContactId).Related_Contact__c != null) {
                    mem.AssistantEmail__c = assistants.get(mem.ContactId)
                        .Related_Contact__r.Email;
                    mem.Assistant__c = assistants.get(mem.ContactId).Related_Contact__c;
                }
                Contact con = contactMap.get(mem.ContactId);
                if (con != null) {
                    for (String fieldApi : selectedEmailFields) {

                        if (fieldApi != null) {
                            String email = (String)con.get(fieldApi);

                            if (String.isNotBlank(email)) {
                                selectedEmails.add(email);
                            }
                        }
                    }
                }
                Set<String> destinationSet = new Set<String>(destinationFields);
                if(destinationSet.contains('CC_Addresses__c')) {
                    if(removeEmails) {
                        mem.CC_Addresses__c = removeEmails(mem.CC_Addresses__c, selectedEmails);
                    } else {
                        mem.CC_Addresses__c = appendEmails(mem.CC_Addresses__c, selectedEmails);
                    }
                }
                if(destinationSet.contains('BCC_Addresses__c')) {
                    if(removeEmails){
                        mem.BCC_Addresses__c = removeEmails(mem.BCC_Addresses__c, selectedEmails);
                    } else {
                        mem.BCC_Addresses__c = appendEmails(mem.BCC_Addresses__c, selectedEmails);
                    }
                }
            }
        }
        update memList;
    }
    
    public static String appendEmails(String existingEmails, List<String> newEmails) {
        Set<String> emailSet = new Set<String>();
        // Existing emails
        if (String.isNotBlank(existingEmails)) {
            for (String email : existingEmails.split(',')) {
                if (String.isNotBlank(email)) {
                    emailSet.add(email.trim().toLowerCase());
                }
            }
        }
        // New emails
        for (String email : newEmails) {
            if (String.isNotBlank(email)) {
                emailSet.add(email.trim().toLowerCase());
            }
        }
        return String.join(new List<String>(emailSet), ',');
    }

    public static String removeEmails(String existingEmails, List<String> emailsToRemove) {
        Set<String> emailSet = new Set<String>();
        // Existing emails
        if (String.isNotBlank(existingEmails)) {
            for (String email : existingEmails.split(',')) {
                if (String.isNotBlank(email)) {
                    emailSet.add(email.trim().toLowerCase());
                }
            }
        }
        // Remove selected emails
        for (String email : emailsToRemove) {
            if (String.isNotBlank(email)) {
                emailSet.remove(email.trim().toLowerCase());
            }
        }
        return String.join(new List<String>(emailSet), ',');
    }

	@AuraEnabled
	public static Object saveContactGuests(String campaignId, String cntIds, String option, String recommendedBy,
										   String rsvpValue, String attendanceValue) {

		Boolean hasPrivateNameAccess = isUserInPublicGroup(UserInfo.getUserId(), 'Restricted_Orgs_Contacts');
		List<String> contactIds = cntIds.split(',');
		Map<String, List<String>> result = new Map<String, List<String>>();
		Set<String> existedContactIds = new Set<String>();
		for(CampaignMember member : [SELECT ContactId FROM CampaignMember WHERE CampaignId = :campaignId WITH SYSTEM_MODE]) {
			existedContactIds.add(member.ContactId);
		}
		Map<String, Related_Contact__c> assistants = getAssistantByContact(new List<String>(new Set<String>(contactIds)));
		List<CampaignMember> members = new List<CampaignMember>();
		List<String> existingContactNameList = new List<String>();
		List<String> doNotCallContacts = new List<String>();
		List<String> deceasedContacts = new List<String>();
		List<String> restrictedContactIds = new List<String>();
		for(Contact tmpContact : [SELECT Id, Email, Alternate_Email__c, Full_Name__c, Business_Email_2__c, Restricted__c,
										 DoNotCall, Deceased__c, Restricted_Name__c
								  FROM Contact
								  WHERE ID = :contactIds WITH SYSTEM_MODE]) {

			if(!existedContactIds.contains(tmpContact.Id)) {
				if(tmpContact.DoNotCall == false && tmpContact.Deceased__c == false) {
					CampaignMember tmp = new CampaignMember();
					tmp.CampaignId = campaignId;
					tmp.ContactId = tmpContact.Id;
					tmp.Guest_Email_Type__c = getEmailType(tmpContact);
					if(String.isNotBlank(recommendedBy)) {
						tmp.Source__c = recommendedBy;
					}
					if(String.isNotBlank(rsvpValue)) {
						tmp.RSVPStatus__c = rsvpValue;
					}
					if(String.isNotBlank(attendanceValue)) {
						tmp.AttendedStatus__c = attendanceValue;
					}
					if(option.contains('waitingList')) {
						tmp.EventTier__c = 'Waiting';
					}
					if(option.contains('as')) {
						tmp.CC_Assistant__c = true;
					}
					if(assistants.get(tmpContact.Id) != null &&
					assistants.get(tmpContact.Id).Related_Contact__c != null) {

						tmp.AssistantEmail__c = assistants.get(tmpContact.Id).Related_Contact__r.Email;
						tmp.Assistant__c = assistants.get(tmpContact.Id).Related_Contact__c;
					}
					members.add(tmp);
				} else if(tmpContact.DoNotCall == true) {
					doNotCallContacts.add(tmpContact.Full_Name__c);
				} else if(tmpContact.Deceased__c == true) {
					deceasedContacts.add(tmpContact.Full_Name__c);
				}
			} else {
				String existingName = resolveExistingContactName(tmpContact.Restricted__c, hasPrivateNameAccess, tmpContact.Full_Name__c, tmpContact.Restricted_Name__c);
				if(existingName != null) existingContactNameList.add(existingName);
			}
		}
		if(members.size() > 0) {
			Database.insert(members, false);
		}
		if(existingContactNameList.size() > 0) {
			result.put(
				'The following Contacts are already on the list', existingContactNameList
			);
		}
		if(doNotCallContacts.size() > 0) {
			result.put(
				'The following Contacts were not added because they have a Do Not Contact alert', doNotCallContacts
			);
		}
		if(deceasedContacts.size() > 0) {
			result.put(
				'The following Contacts were not added because they have a Deceased alert', deceasedContacts
			);
		}
		return result;
	}

	private static String resolveExistingContactName(Boolean isRestricted, Boolean hasPrivateAccess, String fullName, String restrictedContactName) {
		if(!isRestricted) return fullName;
		if(!hasPrivateAccess) return null;
		String privateName = restrictedContactName == null ? '' : restrictedContactName.trim();
		return String.isNotBlank(privateName) ? privateName : null;
	}

	private static Boolean isUserInPublicGroup(Id userId, String publicGroupName) {
		System.debug('userId: ' + userId + ', publicGroupName: ' + publicGroupName);
		System.debug('GroupMember count: ' + [SELECT COUNT() FROM GroupMember WHERE Group.DeveloperName = :publicGroupName AND UserOrGroupId = :userId]);
		return [SELECT COUNT() FROM GroupMember WHERE Group.DeveloperName = :publicGroupName AND UserOrGroupId = :userId] > 0;
	}

	private static String getEmailType(Contact c) {
		if(String.isNotBlank(c.Email)) {
			return 'Business';
		}
		if(String.isNotBlank(c.Alternate_Email__c)) {
			return 'Personal';
		}
		if(String.isNotBlank(c.Business_Email_2__c)) {
			return 'Additional';
		}
		return '';
	}


	@AuraEnabled
    public static Object saveListGuests(String campaignIds, String campaignId, String option, String rsvpValue, String attendanceValue) {
		Boolean hasPrivateNameAccess = isUserInPublicGroup(UserInfo.getUserId(), 'Restricted_Orgs_Contacts');
        List<Campaign> campaigns = (List<Campaign>) JSON.deserialize(campaignIds, List<Campaign>.class);
        Map<Id, Campaign> campaignByIds = new Map<Id, Campaign>(campaigns);
        Set<String> existedContactIds = new Set<String>();
        for(CampaignMember member : [SELECT ContactId FROM CampaignMember WHERE CampaignId = :campaignId WITH SYSTEM_MODE]) {
            existedContactIds.add(member.ContactId);
        }
        List<CampaignMember> campMembers = [SELECT ContactId, CampaignId, Contact.Email, Contact.Alternate_Email__c,
                                                   Contact.Full_Name__c, Contact.DoNotCall, Contact.Deceased__c, Contact.Restricted__c,
												   Contact.Restricted_Name__c
                                            FROM CampaignMember
                                            WHERE CampaignId IN :campaignByIds.keySet() WITH SYSTEM_MODE];
        if(campMembers.size() > 900) {
            throw new AuraHandledException(
                'The guests are more than 900 in selected List(s). Please reach out to Data Team for help.'
            );
        }
        Set<String> contactIds = new Set<String>();
        for(CampaignMember member : campMembers) {
            contactIds.add(member.ContactId);
        }
        Map<String, Related_Contact__c> assistants = getAssistantByContact(new List<String>(contactIds));
        Map<String, List<String>> contactToSources = new Map<String, List<String>>();
        for(CampaignMember member : campMembers) {
            String contactId = member.ContactId;
            if(!contactToSources.containsKey(contactId)) {
                contactToSources.put(contactId, new List<String>());
            }
            contactToSources.get(contactId).add(campaignByIds.get(member.CampaignId).Name);
        }
        Map<String, Set<String>> result = new Map<String, Set<String>>();
        List<CampaignMember> members = new List<CampaignMember>();
        Set<String> existingContactNameList = new Set<String>();
        Set<String> doNotCallContacts = new Set<String>();
        Set<String> deceasedContacts = new Set<String>();
        Set<String> processedContactIds = new Set<String>();
		for(CampaignMember member : campMembers) {
            if(processedContactIds.contains(member.ContactId)) {
                continue;
            }
            processedContactIds.add(member.ContactId);
            if(!existedContactIds.contains(member.contactId)) {
                if(member.Contact.DoNotCall == false && member.Contact.Deceased__c == false) {
                    CampaignMember tmp = new CampaignMember();
                    tmp.CampaignId = campaignId;
                    tmp.ContactId = member.contactId;
                    tmp.Source__c = String.join(contactToSources.get(member.ContactId), ', ');
                    if(String.isNotBlank(rsvpValue)) {
                        tmp.RSVPStatus__c = rsvpValue;
                    }
                    if(String.isNotBlank(attendanceValue)) {
                        tmp.AttendedStatus__c = attendanceValue;
                    }
					if(option.contains('as')) {
						tmp.CC_Assistant__c = true;
					}
                    if(option.contains('as') && assistants.get(member.ContactId) != null &&
                       assistants.get(member.ContactId).Related_Contact__c != null) {
                        tmp.AssistantEmail__c = assistants.get(member.ContactId).Related_Contact__r.Email;
                        tmp.Assistant__c = assistants.get(member.ContactId).Related_Contact__c;
                    }
                    members.add(tmp);
                } else if(member.Contact.DoNotCall == true) {
                    doNotCallContacts.add(member.Contact.Full_Name__c);
                } else if(member.Contact.Deceased__c == true) {
                    deceasedContacts.add(member.Contact.Full_Name__c);
                }
            } else {
				String existingName = resolveExistingContactName(member.Contact.Restricted__c, hasPrivateNameAccess, member.Contact.Full_Name__c, member.Contact.Restricted_Name__c);
				if(existingName != null) existingContactNameList.add(existingName);
			}
        }
		if(members.size() > 0) {
			Database.insert(members, false);
		}
        if(existingContactNameList.size() > 0) {
			result.put('The following Contacts are already on the list', existingContactNameList);
        }
        if(doNotCallContacts.size() > 0) {
            result.put(
				'The following Contacts were not added because they have a Do Not Contact alert', doNotCallContacts
            );
        }
        if(deceasedContacts.size() > 0) {
            result.put(
				'The following Contacts were not added because they have a Deceased alert', deceasedContacts
            );
        }
        return result;
    }

	@AuraEnabled
	public static void deleteGuests(String guestIds) {
		List<String> guests = (List<String>) JSON.deserialize(guestIds, List<String>.class);
		delete [SELECT Id FROM CampaignMember WHERE Id IN :guests WITH SYSTEM_MODE];
	}

	@AuraEnabled
	public static Object searchList(String listSearch, String searchId) {
		String query = 'SELECT Id, Name, RecordType.DeveloperName FROM Campaign ';
		if(String.isNotBlank(listSearch)) {
			query += 'WHERE Name LIKE \'%' + listSearch + '%\' WITH SYSTEM_MODE ORDER BY NAME LIMIT 200';
		} else {
			query += ' WITH SYSTEM_MODE ORDER BY Name LIMIT 200';
		}
		Map<String, Object> result = new Map<String, Object>();
		result.put('results', Database.query(query));
		result.put('input', listSearch);
		result.put('searchId', searchId);
		return result;
	}

	@AuraEnabled
	public static void createEvent(Campaign newEvent) {
		isFromEventsTab = true;
		newEvent.RecordTypeId = EVENT_RECORD_TYPE_ID;
		insert newEvent;
	}

	@AuraEnabled
	public static Object searchContact(String cntSearch) {
		String searchString = String.isNotBlank(cntSearch) ? cntSearch : '';
		List<String> lstSearchWordsSplit = new List<String>();
		for(String str : searchString.split(' ')) {
			String wordStr = str + '%';
			lstSearchWordsSplit.add(wordStr);
		}
		String query;
		// Create a Dynamic SOQL Query For Fetch Record List with LIMIT 10 and exclude already selected records
		if(lstSearchWordsSplit != null && lstSearchWordsSplit.size() > 1) {
		String lastName = lstSearchWordsSplit[1];
		String firstName = lstSearchWordsSplit[0];
		query = 'SELECT Id, Name, FirstName, LastName, Email_Org_Name__c, Event_Count__c, Preferred_First_Name__c, Account.Name, Deceased__c, ' +
					   'DoNotCall, Email, Title, Significant_Name__c ' +
				'FROM Contact ' +
				'WHERE LastName LIKE: lastName AND ' +
					  '(Preferred_First_Name__c LIKE: firstName OR FirstName LIKE: firstName) ' +
				' WITH SYSTEM_MODE ORDER BY lastName DESC LIMIT 10';
		} else {
			query =
				'SELECT Id, Name, FirstName, LastName, Email_Org_Name__c, Event_Count__c, Preferred_First_Name__c, Account.Name, Deceased__c, ' +
					   'DoNotCall, Email, Title, Significant_Name__c ' +
				'FROM Contact WHERE Name LIKE \'%' + searchString + '%\' OR Preferred_First_Name__c LIKE \'' +
				searchString +'%\' ' +
				' WITH SYSTEM_MODE ORDER BY lastName DESC limit 10';
		}
		Map<String, Object> result = new Map<String, Object>();
		result.put('results', Database.query(query));
		result.put('input', searchString);
		return result;
	}

	@AuraEnabled(cacheable=true)
	public static String getContactInfo(String guestId) {
		Map<String, String> eventFields = UtilityClass.getFieldsByFieldSet('Contact', 'EventFields');
		String query = 'SELECT Id, Significant_Other__c, FirstName, Dietary_Restrictions_Text__c, Salutation, Full_Name__c, ';
		String fields = '';
		for(String fieldName : eventFields.keySet()) {
			fields += fieldName + ', ';
		}
		fields = fields.removeEnd(', ');
		query +=
		fields +
		' FROM Contact WHERE Id IN (SELECT ContactId FROM CampaignMember WHERE Id =: guestId) WITH SYSTEM_MODE';
		List<Contact> cnts = (List<Contact>) Database.query(query);
		if(cnts.size() > 0) {
			Contact cnt = cnts[0];
			return generateContactInfo(cnt, eventFields, fields);
		}
		return '';
	}

	private static String generateContactInfo(Contact cnt, Map<String, String> eventFields, String fields) {
		ContactInfo tmpInfo = new ContactInfo();
		Map<String, String> guestInfo = new Map<String, String>();
		for(String fieldName : eventFields.keySet()) {
			guestInfo.put(eventFields.get(fieldName), String.valueOf(cnt.get(fieldName)));
		}
		guestInfo.put('Salutation', cnt.Salutation);
		guestInfo.put('Event Confidential Notes', cnt.Dietary_Restrictions_Text__c);
		tmpInfo.guestName = cnt.FirstName;
		tmpInfo.guestFullName = cnt.Full_Name__c;
		tmpInfo.guestId = cnt.Id;
		tmpInfo.guest = guestInfo;
		tmpInfo.guestContacts = [SELECT Id, Related_Contact__c, Related_Contact_Office_Phone__c, Related_Contact_Business_Email__c,
										Related_Contact__r.Name, Relationship__c
								 FROM Related_Contact__c
								 WHERE Main_Contact__c = :cnt.Id WITH SYSTEM_MODE];
		if(String.isNotBlank(cnt.Significant_Other__c)) {
			String significantId = cnt.Significant_Other__c;
			String soQuery =
				'SELECT Id, FirstName, Salutation, Dietary_Restrictions_Text__c, Full_Name__c, ' +
				fields +
				' FROM Contact WHERE Id = \'' +
				significantId +
				'\' WITH SYSTEM_MODE ';
			List<Contact> soCnts = (List<Contact>) Database.query(soQuery);
			Map<String, String> significantInfo = new Map<String, String>();
			for(String fieldName : eventFields.keySet()) {
				significantInfo.put(eventFields.get(fieldName), String.valueOf(soCnts[0].get(fieldName)));
			}
			significantInfo.put('Salutation', soCnts[0].Salutation);
			significantInfo.put('Event Confidential Notes', soCnts[0].Dietary_Restrictions_Text__c);
			tmpInfo.significantOtherName = soCnts[0].FirstName;
			tmpInfo.significantOtherFullName = soCnts[0].Full_Name__c;
			tmpInfo.significantOther = significantInfo;
			tmpInfo.significantOtherContacts = [SELECT Id, Related_Contact__c, Related_Contact_Office_Phone__c,
													   Related_Contact_Business_Email__c, Related_Contact__r.Name, Relationship__c
												FROM Related_Contact__c
												WHERE Main_Contact__c = :significantId WITH SYSTEM_MODE];
		}
		return JSON.serialize(tmpInfo);
	}

	public static String getRSVPStatus(ZkipsterCallOutInterface.Data guest) {
		ZkipsterCallOutInterface.Attributes attributes = guest.attributes;
		if(attributes == null) return '';
		List<ZkipsterCallOutInterface.CustomFieldValues> fieldList = attributes.custom_field_values;
		if(fieldList == null || fieldList.isEmpty()) {
			return '';
		}
		for(ZkipsterCallOutInterface.CustomFieldValues field : fieldList) {
			if('Guest 1 Response'.equalsIgnoreCase(field.field_name) ||
			   'Guest 1 Attending'.equalsIgnoreCase(field.field_name)) {

				List<ZkipsterCallOutInterface.SelectedValues> selList = field.selected_values;
				for(ZkipsterCallOutInterface.SelectedValues sel : selList) {
					String val = sel.value;
					return String.isNotBlank(val) ? val : '';
				}
			}
		}
		return '';
	}

	private static void syncZkipsterGuests(String eventId) {
		String query = 'SELECT Id, CreatedBy.Email, Table__c, Seat__c, UB_FirstName__c, Title, Dietary__c, ' +
					  		  'First_Preferred_First_Name__c, Email, SpouseInvited__c, RSVPNotes__c, ' +
							  'UB_LastName__c, Contact.Full_Name__c, Contact.Account.Name, Guest_Email__c, ' +
							  'RSVPStatus__c, ZkipsterGuestId__c, PartySize__c, Phone, Last_Preferred_Last_Name__c, Contact.Salutation, Contact.RestrictedSalutation__c, ' +
              				  'Contact.Restricted__c, Contact.RestrictedFirstName__c, Contact.RestrictedLastName__c, Contact.CorrespondenceDearLine__c, Contact.Account.Restricted_Org_Name__c, ' +
							  'Contact.Significant_Other__r.Full_Name__c, Campaign.ZkipsterGuestListId__c, Synced_With_Zkipster__c ' +
					  ' FROM CampaignMember ' +
					  ' WHERE Synced_With_Zkipster__c = False ' +
					    ' AND CampaignId = \'' + eventId + '\' ' +
						' AND RSVPStatus__c != \'Waitlist 1\' ' +
						' AND RSVPStatus__c != \'Waitlist 2\' WITH SYSTEM_MODE';
		SyncGuestsToZkipster sync = new SyncGuestsToZkipster();
		sync.query = query;
		sync.campId = eventId;
		lockCampaign(eventId);
		Database.executeBatch(sync, 100);
	}

	private static void lockCampaign(String eventId) {
		if(String.isBlank(eventId)) {
			return;
		}
		Campaign c = new Campaign();
		c.Id = eventId;
		c.Is_Zkipster_Sync__c = true;
		update c;
	}

	@AuraEnabled
	public static Map<String, Related_Contact__c> getAssistantByContact(List<String> contactIds) {
		Map<String, Related_Contact__c> relatedContacts = new Map<String, Related_Contact__c>();
		Map<String, Related_Contact__c> execAssistants = new Map<String, Related_Contact__c>();
		Map<String, Related_Contact__c> assistants = new Map<String, Related_Contact__c>();
		Map<String, Related_Contact__c> scheduler = new Map<String, Related_Contact__c>();
		Map<String, Related_Contact__c> chiefOfStaff = new Map<String, Related_Contact__c>();
		Map<String, Related_Contact__c> others = new Map<String, Related_Contact__c>();
		for(Related_Contact__c tmp : [SELECT Id, Name, Related_Contact__r.Restricted_Name__c, Related_Contact__c, Related_Contact__r.Email, Relationship__c,
											 Related_Contact__r.Name, Related_Contact__r.Alternate_Email__c, Main_Contact__c, Related_Contact__r.Phone,
                                      		 Related_Contact__r.MobilePhone, Events_Primary_Staff_Contact__c, CreatedDate
									  FROM Related_Contact__c
									  WHERE Main_Contact__c = :contactIds WITH SYSTEM_MODE order by Events_Primary_Staff_Contact__c, CreatedDate ASC]) {

			String relation = tmp.Relationship__c != null ? tmp.Relationship__c.trim().toLowerCase()  : '';
			if(Assets.EXECUTIVE_ASSISTANT.contains(relation) || tmp.Events_Primary_Staff_Contact__c) {
				execAssistants.put(tmp.Main_Contact__c, tmp);
			} else if(Assets.ASSISTANT.contains(relation)) {
				assistants.put(tmp.Main_Contact__c, tmp);
			} else if(Assets.SCHEDULER.contains(relation)) {
				scheduler.put(tmp.Main_Contact__c, tmp);
			} else if(Assets.CHIEF_OF_STAFF.contains(relation)) {
				chiefOfStaff.put(tmp.Main_Contact__c, tmp);
			}
			else {
				others.put(tmp.Main_Contact__c, tmp);
			}
		}
		setAssistants(relatedContacts, others);
		setAssistants(relatedContacts, chiefOfStaff);
		setAssistants(relatedContacts, scheduler);
		setAssistants(relatedContacts, assistants);
		setAssistants(relatedContacts, execAssistants);
		return relatedContacts;
	}

	@AuraEnabled
	public static Contact getSearchContactInfo(Id conId) {
		try {
			return [SELECT Id, Name FROM Contact WHERE Id =: conId WITH SYSTEM_MODE];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	private static void setAssistants(Map<String, Related_Contact__c> relatedContacts, Map<String, Related_Contact__c> assistants) {
		for(String assist : assistants.keySet()) {
			relatedContacts.put(assist, assistants.get(assist));
		}
	}

	private static HttpResponse updateOrgEmail(String displayName, String orgEmailId) {
		String soapBody = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
						  'xmlns:urn="urn:enterprise.soap.sforce.com" xmlns:urn1="urn:sobject.enterprise.soap.sforce.com" ' +
						  'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
		soapBody += '<soapenv:Header><urn:SessionHeader><urn:sessionId>' +
					UserInfo.getSessionId() +
					'</urn:sessionId>';
		soapBody += '</urn:SessionHeader></soapenv:Header><soapenv:Body><urn:update>';
		soapBody += '<urn:sObjects xsi:type="urn1:OrgWideEmailAddress"><DisplayName>' +
					displayName +
					'</DisplayName><Id>' +
					orgEmailId +
					'</Id></urn:sObjects>';
		soapBody += '</urn:update></soapenv:Body></soapenv:Envelope>';
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/c/50.0');
		req.setHeader('SOAPAction', '""');
		req.setHeader('content-type', 'text/xml; charset=utf-8');
		req.setBody(soapBody);
		req.setMethod('POST');
		HttpResponse res = new http().send(req);
		return res;
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, List<String>> getCountryStateCodes() {
		Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
		controllingInfo = UtilityClass.getFieldDependencies('Contact', 'MailingCountryCode', 'MailingStateCode');
		return controllingInfo;
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, String> getCountryPickLists(String objectType, String selectedField) {
		Map<String, String> pickListValuesMap = new Map<String, String>();
		Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
		Schema.DescribeSObjectResult res = convertToObj.getDescribe();
		Schema.DescribeFieldResult fieldResult;
		if(selectedField != null && selectedField == 'State') fieldResult = User.statecode.getDescribe();
		else fieldResult = res.fields.getMap().get(selectedField).getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for(Schema.PicklistEntry pickListVal : ple) {
			pickListValuesMap.put(pickListVal.getValue(), pickListVal.getLabel());
		}
		return pickListValuesMap;
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Map<String, String>> getStatePickLists(String objectName, String controllingField, String dependentField) {
		Map<String, Map<String, String>> controllingInfo = new Map<String, Map<String, String>>();
		Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
		Schema.DescribeSObjectResult describeResult = objType.getDescribe();
		Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
		Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
		List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();//User.Countrycode.getDescribe().getPicklistValues();//
		List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();//User.statecode.getDescribe().getPicklistValues();//
		for(Schema.PicklistEntry currControllingValue : controllingValues) {
			controllingInfo.put(currControllingValue.getValue(), new Map<String, String>());
		}
		for(Schema.PicklistEntry currDependentValue : dependentValues) {
			String jsonString = JSON.serialize(currDependentValue);
			UtilityClass.MyPickListInfo info = (UtilityClass.MyPickListInfo) JSON.deserialize(jsonString, UtilityClass.MyPickListInfo.class);
			String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
			Integer baseCount = 0;
			for(Integer curr : hexString.getChars()) {
				Integer val = 0;
				if(curr >= 65) {
					val = curr - 65 + 10;
				} else {
					val = curr - 48;
				}
				if((val & 8) == 8) {
					controllingInfo.get(controllingValues[baseCount + 0].getValue()).put(currDependentValue.getValue(), currDependentValue.getLabel());
				}
				if((val & 4) == 4) {
					controllingInfo.get(controllingValues[baseCount + 1].getValue()).put(currDependentValue.getValue(), currDependentValue.getLabel());
				}
				if((val & 2) == 2) {
					controllingInfo.get(controllingValues[baseCount + 2].getValue()).put(currDependentValue.getValue(), currDependentValue.getLabel());
				}
				if((val & 1) == 1) {
					controllingInfo.get(controllingValues[baseCount + 3].getValue()).put(currDependentValue.getValue(), currDependentValue.getLabel());
				}
				baseCount += 4;
			}
		}
		return controllingInfo;
	}

	@AuraEnabled
	public static AddContactWrapper findDuplicates(Contact contactRecord) {
		contactRecord.Converted_FirstName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(contactRecord.FirstName);
		contactRecord.Converted_LastName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(contactRecord.LastName);
		AddContactWrapper addContact = new AddContactWrapper();
		List<Contact> contacts = new List<Contact>{contactRecord};
		List<Datacloud.FindDuplicatesResult> duplicateResults = Datacloud.FindDuplicates.findDuplicates(contacts);
		if(!duplicateResults.isEmpty()) {
			for(Datacloud.FindDuplicatesResult findDupeResult : duplicateResults) {
				for(Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
					Datacloud.MatchResult[] matchResults = dupeResult.getMatchResults();
					Datacloud.MatchResult matchResult = matchResults[0];
					Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
					if(!matchRecords.isEmpty()) {
					addContact.isDuplicateFound = true;
					for(Datacloud.MatchRecord matchRecord : matchRecords) {
						addContact.addDuplicateRecordId(matchRecord.getRecord().Id);
					}
					}
				}
			}
		}
		return addContact;
	}

	@AuraEnabled
	public static AddContactWrapper saveContact(Contact contactRecord, Boolean allowDuplicate) {
		AddContactWrapper addContact = new AddContactWrapper();
		try {
			Database.DMLOptions dml = new Database.DMLOptions();
			if(allowDuplicate) {
				//Allow ContactCreation on Second Click of Create button as like standard behavior
				dml.DuplicateRuleHeader.allowSave = true;
			} else {
				dml.DuplicateRuleHeader.allowSave = false;
			}
			Database.SaveResult sr = Database.insert(contactRecord, dml);
			if(sr.isSuccess()) {
				addContact.contactId = sr.getId();
			} else {
				for(Database.Error err : sr.getErrors()) {
					addContact.errorMessage = err.getMessage();
					if(err instanceof Database.DuplicateError) {
					addContact.isDuplicateFound = true;
					Database.DuplicateError duplicateError = (Database.DuplicateError)err;
					Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
					Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
					Datacloud.MatchResult matchResult = matchResults[0];
					Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
					for(Datacloud.MatchRecord matchRecord : matchRecords) {
						addContact.addDuplicateRecordId(matchRecord.getRecord().Id);
						addContact.addDuplicateRecord(matchRecord.getRecord());
					}
					}
				}
			}
		} catch(Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
		return addContact;
	}

	@AuraEnabled
	public static List<Contact> getContacts(List<String> contactIds) {
		List<Contact> contacts = new List<Contact>();
		contacts = [SELECT Id, Name, Email, Phone, MobilePhone, Title, Organization_Name_formula__c,
						   Significant_Name__c, Touchpoint_sum__c
					FROM Contact
					WHERE Id IN :contactIds WITH SYSTEM_MODE];
		return contacts;
	}

    @AuraEnabled(cacheable=true)
    public static Id getDefaultAccountId() {
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name = '-'
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0].Id;
    }

	 @AuraEnabled(cacheable=true)
    public static List<Id> getContactIdsByTagIds(List<String> tagIds) {

        if (tagIds == null || tagIds.isEmpty()) {
            return new List<Id>();
        }

        Set<Id> contactIdSet = new Set<Id>();

        for (Tag_Junction__c  ct : [ SELECT Contact__c FROM Tag_Junction__c  WHERE Tag__c IN :tagIds AND Contact__c != NULL WITH SYSTEM_MODE]) {
            contactIdSet.add(ct.Contact__c);
        }

        return new List<Id>(contactIdSet);
    }

	public class ContactInfo {
		public String guestName { get; set; }
		public String guestFullName { get; set; }
		public String guestId { get; set; }
		public String significantOtherName { get; set; }
		public String significantOtherFullName { get; set; }
		public Contact cntInfo { get; set; }
		public Contact significantOtherInfo { get; set; }
		public Map<String, String> significantOther { get; set; }
		public Map<String, String> guest { get; set; }
		public List<Related_Contact__c> guestContacts { get; set; }
		public List<Related_Contact__c> significantOtherContacts { get; set; }
    }
    
    public class AddContactWrapper {
        @AuraEnabled public Boolean isDuplicateFound { get; set; }
        @AuraEnabled public String contactId { get; set; }
        @AuraEnabled public List<SObject> duplicateRecords { get; set; }
        @AuraEnabled public Set<String> duplicateRecordIds { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        
        public AddContactWrapper() {
            this.isDuplicateFound = false;
            this.duplicateRecords = new List<SObject>();
            this.duplicateRecordIds = new Set<String>();
        }
        
        public void addDuplicateRecord(SObject duplicateRecord) {
            this.duplicateRecords.add(duplicateRecord);
        }
        
        public void addDuplicateRecordId(String duplicateRecordId) {
            this.duplicateRecordIds.add(duplicateRecordId);
        }
    }
}