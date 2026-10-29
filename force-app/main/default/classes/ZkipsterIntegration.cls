public without sharing class ZkipsterIntegration {
	private final static Environment_Setting__mdt  BP_VARIABLES = Environment.getEnvironmentSetting();
	public final static String FORWARD_EMAIL = System.Label.Zkipster_Forward_Email;//Forward Email address to forward Zkipster invitation email into Salesforce

	private static final String ERR_ZKIPSTER_CALLOUT = 'ZKIPSTER_INTEGRATION_CALLOUT_FAILED';

	public static String syncZkipsterEventCreation(Campaign event) {
		String url = '/v1/events';

		String data = '{"data":{"type": "events","attributes":{  "name":"'+event.Name+'","event-type": "Other","event-types":["'+event.EventType__c+'"],"date-utc":"'+event.StartDateUtc__c+'",';
        data += '"end-date-utc":"'+event.EndDateUtc__c+'","timezone-universal-id":"'+event.TimeZone__c+'",';
        if( event.SetUpEventLocationType__c != 'Virtual' ) {
        	data += '"location":"'+event.LocationName__c+'","location-address":{';
        	data += '"address-line":"'+event.AddressLine__c+'","city":"'+event.City__c+'","state":"'+event.State__c+'",';
        	data += '"country":"'+event.Country__c+'"},';
        }

        data += '"add-ons":{"seating-charts-enabled":true,"picture-source-enabled":true,"badge-print-enabled":true,"rsvp-enabled":true}';
        data += ', "event-location-type": "'+event.SetUpEventLocationType__c+'"';
        if( event.SetUpEventLocationType__c != 'InPlace' ) {
        	data += ',"virtual-event-details": {"virtual-event-type": "Other","virtual-event-url": "'+event.VirtualEventLink__c+'"}';
        }
        data += '}}}';

		String response = zkipsterCallout(url, 'POST', data, 201);
        System.debug('response :::::: '+response);
		String eventId = 'error';
		if( response != 'error') {
			Map<String, Object> guestListResponse = (Map<String,Object>)JSON.deserializeUntyped(response);
			Map<String, Object> guestListData = (Map<String,Object>)guestListResponse.get('data');
			eventId = (String)guestListData.get('id');
		}

		return eventId;
	}

	public static String syncZkipsterEventUpdate(Campaign event) {
		String url = '/v1/events/'+event.ZkipsterEventID__c;

		String data = '{"data":{"type": "events","id": "'+event.ZkipsterEventID__c+'","attributes":{  "name":"'+event.Name+'","event-type": "Other","event-types":["'+event.EventType__c+'"],"date-utc":"'+event.StartDateUtc__c+'",';
        data += '"end-date-utc":"'+event.EndDateUtc__c+'","timezone-universal-id":"'+event.TimeZone__c+'",';
        if( event.SetUpEventLocationType__c != 'Virtual' ) {
        	data += '"location":"'+event.LocationName__c+'","location-address":{';
        	data += '"address-line":"'+event.AddressLine__c+'","city":"'+event.City__c+'","state":"'+event.State__c+'",';
        	data += '"country":"'+event.Country__c+'"},';
        }

        data += '"add-ons":{"seating-charts-enabled":true,"picture-source-enabled":true,"badge-print-enabled":true,"rsvp-enabled":true}';
        data += ', "event-location-type": "'+event.SetUpEventLocationType__c+'"';
        if( event.SetUpEventLocationType__c != 'InPlace' ) {
        	data += ',"virtual-event-details": {"virtual-event-type": "Other","virtual-event-url": "'+event.VirtualEventLink__c+'"}';
        }
        data += '}}}';

		String response = zkipsterCallout(url, 'PATCH', data, 200);
		String eventId = 'error';
		if( response != 'error') {
			Map<String, Object> guestListResponse = (Map<String,Object>)JSON.deserializeUntyped(response);
			Map<String, Object> guestListData = (Map<String,Object>)guestListResponse.get('data');
			eventId = (String)guestListData.get('id');
		}

		return eventId;
	}

	public static String syncZkipsterGuestListCreation(String guestListName, String eventId) {
		String url = '/v1/guest-lists';
		String data = '{"data": {"type": "guest-lists","attributes": {"name": "'+guestListName+'"},"relationships": {"event": {"data": {"type": "events","id": "'+eventId+'"}}}}}';
		String response = zkipsterCallout(url, 'POST', data, 201);
		String guestListId = '';
		if( response != 'error') {
			Map<String, Object> guestListResponse = (Map<String,Object>)JSON.deserializeUntyped(response);
			Map<String, Object> guestListData = (Map<String,Object>)guestListResponse.get('data');
			guestListId = (String)guestListData.get('id');
		}
		return guestListId;

	}

	public static String createZkipsterGuest(CampaignMember guest) {
		return createZkipsterGuest(guest, guest.Campaign != null ? guest.Campaign.ZkipsterGuestListId__c : null);
	}

	public static String createZkipsterGuest(CampaignMember guest, String guestListId) {
		String guestIdx = guest.Id;
		String url = '/v1/guests';
		String organization = guest.Contact.Account.Name == Assets.RESTRICTED_ORG_NAME ? guest.Contact.Account.Restricted_Org_Name__c : guest.Contact.Account.Name ;
		if( organization != null && organization.contains('\"')) {
			organization = organization.replace('\"','\\\"');
		}
		String notes = guest.RSVPNotes__c == null?'':guest.RSVPNotes__c;
		if(notes.length() > 500) {
			notes = notes.substring(0, 500);
		}
        Boolean isRestricted = guest.Contact.Restricted__c;
		String table = String.isNotBlank(guest.Table__c) ? guest.Table__c : '';
		String firstName = String.isNotBlank(guest.First_Preferred_First_Name__c) ? guest.First_Preferred_First_Name__c : '';
		String lastName =  String.isNotBlank(guest.Last_Preferred_Last_Name__c) ? guest.Last_Preferred_Last_Name__c : '';
		String fullName = firstName + ' ' + lastName;
		String data = '{"data": {"type": "guests","attributes": {"first-name": "'+ (isRestricted ? (String.isBlank(guest.Contact.RestrictedFirstName__c) ? '' : guest.Contact.RestrictedFirstName__c) : firstName)+'","last-name": "'+ (isRestricted ? (String.isBlank(guest.Contact.RestrictedLastName__c) ? '' : guest.Contact.RestrictedLastName__c) : lastName) +'",';
		data +='"contact-details": {"organization": "'+organization+'","phone-number": "'+guest.Phone+'","salutation": "'+(isRestricted ? (guest.Contact.RestrictedSalutation__c == null ? '' : guest.Contact.RestrictedSalutation__c) : (guest.Contact.Salutation == null ? '' : guest.Contact.Salutation))+'",';
		data +='"email": "'+FORWARD_EMAIL+'"},"status":"'+getGuestZkipsterStatus(guest.RSVPStatus__c)+'","note":"'+notes+'","total-guests": '+guest.PartySize__c.intValue()+',"custom-field-values": [{"field-name":"Guest Info","value":"----'+guestIdx+'----"}, ';
		data +='{"field-name":"Guest 1","value":"' + fullName + '"},';
		data +='{"field-name":"Party Size","value":"'+(guest.PartySize__c.intValue())+'"},';
		data +='{"field-name":"Guest Email","value":"'+(guest.Guest_Email__c == null?'':guest.Guest_Email__c)+'"},';
        data +='{"field-name":"Guest Preferred First Name","value":"'+(guest.First_Preferred_First_Name__c == null?'':guest.First_Preferred_First_Name__c)+'"},';
		data += '{"field-name":"LP London Dear Line","value":"'+(guest.Contact.CorrespondenceDearLine__c == null?'':guest.Contact.CorrespondenceDearLine__c)+'"},';
        data += '{"field-name":"Title","value":"' + String.valueOf(guest.Title == null?'':guest.Title) + '"},';
        data += '{"field-name":"Dietary","value":"' + String.valueOf(guest.Dietary__c == null?'':guest.Dietary__c) + '"},';
		data +='{"field-name":"Table","value":"'+table+'"}]';
		data +='}, "relationships": {"guest-list": {"data": {"type": "guest-lists","id": "'+guestListId+'"}}}}}';
		String response = zkipsterCallout(url, 'POST', data, 201);
		String guestId = '';
		if( response != 'error') {
			Map<String, Object> guestListResponse = (Map<String,Object>)JSON.deserializeUntyped(response);
			Map<String, Object> guestListData = (Map<String,Object>)guestListResponse.get('data');
			guestId = (String)guestListData.get('id');
		}

		return guestId;
	}

	public static String updateZkipsterGuest(CampaignMember guest) {
		return updateZkipsterGuest(guest, guest.Campaign != null ? guest.Campaign.ZkipsterGuestListId__c : null);
	}

	public static String updateZkipsterGuest(CampaignMember guest, String guestListId) {
		String guestIdx = guest.Id;
		String url = '/v1/guests/'+guest.ZkipsterGuestId__c;
		String organization = guest.Contact.Account.Name == Assets.RESTRICTED_ORG_NAME ? guest.Contact.Account.Restricted_Org_Name__c : guest.Contact.Account.Name ;

		if( organization != null && organization.contains('\"')) {
			organization = organization.replace('\"','\\\"');
		}

		String notes = guest.RSVPNotes__c == null?'':guest.RSVPNotes__c;
		if(notes.length() > 500 ) {
			notes = notes.substring(0, 500);
		}
		Boolean isRestricted = guest.Contact.Restricted__c;
		String table = String.isNotBlank(guest.Table__c) ? guest.Table__c : '';
		String firstName = String.isNotBlank(guest.First_Preferred_First_Name__c) ? guest.First_Preferred_First_Name__c : '';
		String lastName =  String.isNotBlank(guest.Last_Preferred_Last_Name__c) ? guest.Last_Preferred_Last_Name__c : '';
		String fullName = firstName + ' ' + lastName;
		String data = '{"data": {"type": "guests", "id":"'+guest.ZkipsterGuestId__c+'", "attributes": {"first-name": "'+ (isRestricted ? (String.isBlank(guest.Contact.RestrictedFirstName__c) ? '' : guest.Contact.RestrictedFirstName__c) : firstName)+'","last-name": "'+ (isRestricted ? (String.isBlank(guest.Contact.RestrictedLastName__c) ? '' : guest.Contact.RestrictedLastName__c) : lastName)+'",';
		data +='"contact-details": {"organization": "'+organization+'","phone-number": "'+guest.Phone+'","salutation": "'+(isRestricted ? (guest.Contact.RestrictedSalutation__c == null ? '' : guest.Contact.RestrictedSalutation__c) : (guest.Contact.Salutation == null ? '' : guest.Contact.Salutation))+'",';
		data +='"email": "'+FORWARD_EMAIL+'"},"status":"'+getGuestZkipsterStatus(guest.RSVPStatus__c)+'","note":"'+notes+'","total-guests": '+guest.PartySize__c.intValue()+',"custom-field-values": [{"field-name":"Guest Info","value":"----'+guestIdx+'----"}, ';
		data +='{"field-name":"Guest 1","value":"' + fullName + '"},';
		data +='{"field-name":"Party Size","value":"'+(guest.PartySize__c.intValue())+'"},';
		data +='{"field-name":"Guest Email","value":"'+(guest.Guest_Email__c == null?'':guest.Guest_Email__c)+'"},';
        data +='{"field-name":"Guest Preferred First Name","value":"'+(guest.First_Preferred_First_Name__c == null?'':guest.First_Preferred_First_Name__c)+'"},';
		data += '{"field-name":"LP London Dear Line","value":"'+(guest.Contact.CorrespondenceDearLine__c == null?'':guest.Contact.CorrespondenceDearLine__c)+'"},';
        data += '{"field-name":"Title","value":"' + String.valueOf(guest.Title == null?'':guest.Title) + '"},';
        data += '{"field-name":"Dietary","value":"' + String.valueOf(guest.Dietary__c == null?'':guest.Dietary__c) + '"},';
		data +='{"field-name":"Table","value":"'+table+'"}]';
		data +='}, "relationships": {"guest-list": {"data": {"type": "guest-lists","id": "'+guestListId+'"}}}}}';

		String response = zkipsterCallout(url, 'PATCH', data, 200);

		String guestId = '';
		if( response != 'error') {
			Map<String, Object> guestListResponse = (Map<String,Object>)JSON.deserializeUntyped(response);
			Map<String, Object> guestListData = (Map<String,Object>)guestListResponse.get('data');
			guestId = (String)guestListData.get('id');
		}

		return guestId;
	}

    /**
     * @description Updates the RSVP status of an existing zkipster guest (e.g. Declined for No).
     *              Maps the BRM RSVP status to the zkipster status via getGuestZkipsterStatus.
     * @param guestZKId the zkipster GUEST id (not an event id)
     * @param status    the BRM RSVP status (Yes/No/Pend/...)
     * @return the zkipster guest id on success, 'error' otherwise
     */
	public static String updateZkipsterGuestStatus(String guestZKId, String status) {
		String url = '/v1/guests/'+guestZKId;

		String data = '{"data": {"type": "guests", "id":"'+guestZKId+'", "attributes": {"status":"'+getGuestZkipsterStatus(status)+'"';
		data +='}}}';

		String response = zkipsterCallout(url, 'PATCH', data, 200);
		String guestId = '';
		if( response != 'error') {
			Map<String, Object> guestListResponse = (Map<String,Object>)JSON.deserializeUntyped(response);
			Map<String, Object> guestListData = (Map<String,Object>)guestListResponse.get('data');
			guestId = (String)guestListData.get('id');
		}

		return guestId;
	}

	@future(callout=true)
	public static void deleteZkipsterGuest(String guestZKId) {
		String url = '/v1/guests/' + guestZKId;
		zkipsterCallout(url, 'DELETE', null, 204);
	}

	public static String getZkipsterGuestInfo(String guestZKId) {
		String url = '/v1/guests/'+guestZKId+'?include=custom-fields';
		String response = zkipsterCallout(url, 'GET', null, 200);

		if( response != 'error' )  {
			response = response.replace('\"type\":', '\"type_Z\":');
			response = response.replace('field-type_Z', 'field_type');
			response = response.replace('total-records', 'total_records');
			response = response.replace('country-code', 'country_code');
			response = response.replace('first-name', 'first_name');
			response = response.replace('last-name', 'last_name');
			response = response.replace('contact-details', 'contact_details');
			response = response.replace('notification-phone-numbers', 'notification_phone_numbers');
			response = response.replace('phone-number', 'phone_number');
			response = response.replace('notification-emails', 'notification_emails');
			response = response.replace('total-guests', 'total_guests');
			response = response.replace('plus-ones-checked', 'plus_ones_checked');
			response = response.replace('main-guest-checked', 'main_guest_checked');
			response = response.replace('checkin-date', 'checkin_date');
			response = response.replace('seating-map-details', 'seating_map_details');
			response = response.replace('created-date-utc', 'created_date_utc');
			response = response.replace('updated-date-utc', 'updated_date_utc');
			response = response.replace('changed-by', 'changed_by');
			response = response.replace('custom-field-values', 'custom_field_values');
			response = response.replace('qr-code-value', 'qr_code_value');
			response = response.replace('seating-color-rgb', 'seating_color_rgb');
			response = response.replace('seating-color', 'seating_color');
			response = response.replace('table-label', 'table_label');
			response = response.replace('seat-label', 'seat_label');
			response = response.replace('option-id', 'option_id');
			response = response.replace('color-rgb', 'color_rgb');
			response = response.replace('selected-values', 'selected_values');
			response = response.replace('field-name', 'field_name');
			response = response.replace('custom-field-id', 'custom_field_id');
			response = response.replace('qr-code-url', 'qr_code_url');
			response = response.replace('guest-list', 'guest_list');
			response = response.replace('custom-fields', 'custom_fields');
			response = response.replace('field-options', 'field_options');
			response = response.replace('device-id', 'device_id');

		}

		return response;
	}

	/**
	 * @description Fetches all guests in a zkipster guest list and returns a map of
	 *              normalized 'firstname|lastname' (lowercase) to the zkipster guest id.
	 *              Used to match existing zkipster guests before creating duplicates.
	 * @param guestListId the zkipster guest list id
	 * @return Map<String, String> name key to zkipster guest id
	 */
	public static Map<String, String> getAllZkipsterGuestIdsByName(String guestListId) {
		Map<String, String> idsByName = new Map<String, String>();
		if (String.isBlank(guestListId)) {
			return idsByName;
		}
		Integer pageNumber = 1;
		Integer pageSize = 100;
		while (true) {
			String url = '/v1/guest-lists/' + guestListId + '/guests?page[number]=' + pageNumber + '&page[size]=' + pageSize;
			String response = zkipsterCallout(url, 'GET', null, 200);
			if (response == 'error' || response == null) {
				break;
			}
			Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(response);
			List<Object> data = (List<Object>) payload.get('data');
			if (data == null || data.isEmpty()) {
				break;
			}
			for (Object o : data) {
				Map<String, Object> row = (Map<String, Object>) o;
				Map<String, Object> attrs = (Map<String, Object>) row.get('attributes');
				if (attrs == null) {
					continue;
				}
				String firstName = attrs.get('first-name') == null ? '' : String.valueOf(attrs.get('first-name')).trim().toLowerCase();
				String lastName = attrs.get('last-name') == null ? '' : String.valueOf(attrs.get('last-name')).trim().toLowerCase();
				String id = (String) row.get('id');
				if (String.isNotBlank(id) && (String.isNotBlank(firstName) || String.isNotBlank(lastName))) {
					idsByName.put(firstName + '|' + lastName, id);
				}
			}
			if (data.size() < pageSize) {
				break;
			}
			pageNumber++;
		}
		return idsByName;
	}

	public static String zkipsterCallout(String url, String method, String data, Integer responseCode) {
		String result = 'error';

        try {
            // Initialize CalloutService
            CalloutService service = new CalloutService();
            service.setEndpoint('callout:ZkipsterIntegration' + url);
            service.setTimeOut(120000);

            // Set headers
            Map<String, String> headers = new Map<String, String>{
                'Content-Type' => 'application/json'
            };

            // Pick HTTP method
            CalloutService.HTTP_METHOD httpMethod;
            if (method == 'POST') {
                httpMethod = CalloutService.HTTP_METHOD.POST;
            } else if (method == 'PUT') {
                httpMethod = CalloutService.HTTP_METHOD.PUT;
            } else if (method == 'PATCH') {
                httpMethod = CalloutService.HTTP_METHOD.PATCH;
            } else if (method == 'DELETE') {
                httpMethod = CalloutService.HTTP_METHOD.DEL;
            } else {
                httpMethod = CalloutService.HTTP_METHOD.GET;
            }

            // Make the call
            HttpResponse res = service.call(httpMethod, data , headers);

            System.debug('Response Status: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());

            if (responseCode == res.getStatusCode()) {
                result = res.getBody();
            } else {
                BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_ZKIPSTER_CALLOUT);
                BBApps_ErrorHandler.logErrors(
                    new BRMException('ZkipsterIntegration: ' + url +
                                     ' - ' + res.getStatusCode() +
                                     ': ' + res.getBody() + ' | ' + data),
                    f
                );
            }
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_ZKIPSTER_CALLOUT);
            BBApps_ErrorHandler.logErrors(e, f);
        }

        return result;
  }

  private static String getGuestZkipsterStatus(String rsvpStatus) {
  	switch on rsvpStatus {
		when 'Yes' {
			return 'Confirmed';
		}
	   	when 'Yes - In Person' {
			return 'Confirmed';
		}
        when 'Yes - Virtually' {
			return 'Confirmed';
		}
		when 'Yes - Cocktails Only' {
			return 'Confirmed';
		}
		when 'No' {
			return 'Declined';
		}
		when 'Pend' {
			return 'Unconfirmed';
		}
		when else {
			return 'Unconfirmed';
		}
	}
  }
}