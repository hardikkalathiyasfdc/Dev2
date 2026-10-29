/**
 * @description       : Class to handle sync from Zkipster to BRM
 * @author            : Ravi Bheemreddy
 * Last Modified      : 03/02/2026
 * JIRA               : BRME-4751
**/
public without sharing class ZkipsterGetAllGuestsAsync implements Queueable, Database.AllowsCallouts {

    String guestListId;
    String eventId;
    public Map<Id,CampaignMember> guests = new Map<Id,CampaignMember>();
    public List<UnplannedGuest__c> unplannedGuests = new List<UnplannedGuest__c>();
    public List<Zkipster_Contact_Update__c> pendingContactChanges = new List<Zkipster_Contact_Update__c>();
    public Map<String, Zkipster_Contact_Update__c> pendingContactChangeMap = new Map<String, Zkipster_Contact_Update__c>();
    string campName;

    private static final String ERR_EXECUTE = 'ZKIPSTER_GET_ALL_GUESTS_ASYNC_EXECUTE_FAILED';

    public ZkipsterGetAllGuestsAsync (String guestListId, String eventId, String campName) {
        this.guestListId = guestListId;
        this.eventId = eventId;
        this.campName = campName;
    }

    public void execute(QueueableContext ctx) {
        try {
            Integer batchsize = Integer.valueof(Application_Properties__mdt.getInstance('Zkipster_Async_batch_size').Value__c);
            Integer pageNumber = 1;
            String response;
            decimal totalRecords  = 0;
            while(true) {
                String url = '/v1/guest-lists/' + guestListId + '/guests?page[number]=' + pageNumber + '&page[size]=' + batchsize;
                response = zkipsterIntegration.zkipsterCallout(url, 'GET', null, 200);
                if( response != 'error' && response != null )  {
                    pageNumber++;
                    processGuestBatch(response, eventId);
                    if(totalRecords == 0) {
                        totalRecords = getTotalGuestCount(response);
                    }
                    if(pageNumber > (totalRecords/batchsize).round(roundingMode.CEILING)) {
                        break;
                    }
                } else {
                    break;
                }
            }
            Boolean hasFailed = false;
            List<BBApps_DMLResult> guestResults = BBApps_Crud.doUpdateWithHandling(guests.values(), false, ERR_EXECUTE);
            if(hasFailure(guestResults)) { hasFailed = true; }
            List<BBApps_DMLResult> upsertResults = BBApps_Crud.doUpsertWithHandling(unplannedGuests, UnplannedGuest__c.ZkipserGuestId__c, false, ERR_EXECUTE);
            if(hasFailure(upsertResults)) { hasFailed = true; }
            pendingContactChanges.addAll(pendingContactChangeMap.values());
            List<BBApps_DMLResult> contactResults = BBApps_Crud.doUpsertWithHandling(pendingContactChanges, Zkipster_Contact_Update__c.Unique_Key__c, false, ERR_EXECUTE);
            if(hasFailure(contactResults)) { hasFailed = true; }

            if(hasFailed) {
                sendEmailAlerts('failed', campName);
            } else {
                sendEmailAlerts('success', campName);
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);
            BBApps_ErrorHandler.logErrors(ex, f);
            sendEmailAlerts('failed', campName);
        }
    }

    /**
     * Returns true if any DML result in the list is a failure. Null/empty list = no failure.
     */
    private static Boolean hasFailure(List<BBApps_DMLResult> results) {
        if(results == null) {
            return false;
        }
        for(BBApps_DMLResult r : results) {
            if(!r.isSuccess()) {
                return true;
            }
        }
        return false;
    }
    
    public static void sendEmailAlerts(String statusType, String listname) {
        String listId = [SELECT Id, Name FROM Campaign WHERE Name = :listname WITH SYSTEM_MODE LIMIT 1]?.Id;
        String listLink = '<a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + listId + '">' + listname + '</a>';
        String subject = statusType == 'success'
                         ? ' Finished syncing Zkipster guests to: ' + listname
                         : ' Unable to sync zkipster guests to BRM: ' + listname;
        String htmlBody = '';
        if(statusType == 'success') {
            htmlBody = 'Hello ' + UserInfo.getFirstName() +
                       ',<br/><br/> Your request to sync guests information from Zkipster is now complete (' +
                       listLink + '). <br/><br/> All Zkipster guest attendance is now updated in BRM.';
        } else {
            htmlBody = 'Hello ' + UserInfo.getFirstName() +
                       ',<br/><br/> Your request to sync guests information from Zkipster was unsuccessful (' +
                       listLink + '). <br/><br/> Please reach out to a member of the BRM team at salesforcehelp@bloomberg.org to resolve.';
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {UserInfo.getUserEmail()};
        if(statusType == 'failed') toAddresses.add('salesforcehelp@bloomberg.org');
        mail.setOrgWideEmailAddressId(EmailUtility.getBRMEmailAddress());
		mail.setToAddresses(toAddresses);
        mail.setReplyTo(EmailUtility.getReplyToEmail());
        mail.setSubject(subject);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setHtmlBody(htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public void processGuestBatch(String response, String eventId) {
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
        deserialiseGuestResponse(response, eventId);
    }

    public void deserialiseGuestResponse(String response, String eventId) {
        Campaign camp = [
            SELECT ZkipsterGuestListId__c, SetUpEventLocationType__c
            FROM Campaign
            WHERE Id = :eventId WITH SYSTEM_MODE
        ];
        if(response != 'error') {
            ZkipsterCallOutInterface.GetGuestsResponse resp = (ZkipsterCallOutInterface.GetGuestsResponse) JSON.deserialize(
                response,
                ZkipsterCallOutInterface.GetGuestsResponse.class
            );
            List<ZkipsterCallOutInterface.Data> allGuests = resp != null ? resp.data : null;
            Map<String, String> zkipterIds = new Map<String, String>();
            if(allGuests != null) {
                for(ZkipsterCallOutInterface.Data guest : allGuests) {
                    zkipterIds.put(guest.id, '');
                }
            }
            Map<String, CampaignMember> memMap = new Map<String, CampaignMember>();
            for(CampaignMember member : [
                SELECT Id, ZkipsterGuestId__c, RSVPStatus__c, Table__c, Seat__c, ContactId, Contact.Name, Contact.Salutation, Contact.Full_Name__c,
                       Contact.FirstName, Contact.LastName, Contact.Title, Contact.MobilePhone, Contact.Mobile_Phone_Country_Code__c
                FROM CampaignMember
                WHERE ZkipsterGuestId__c IN :zkipterIds.keySet() WITH SYSTEM_MODE
            ]) {
                if(zkipterIds.get(member.ZkipsterGuestId__c) == '') {
                    zkipterIds.put(member.ZkipsterGuestId__c, member.Id);
                }
                memMap.put(member.ZkipsterGuestId__c, member);
            }
            if(allGuests != null) {
                for(ZkipsterCallOutInterface.Data guest : allGuests) {
                    String zkipsterTitle;
                    String zkipsterTable;
                    String zkipsterSeat;
                    List<String> additionalNotes = new List<String>();
                    ZkipsterCallOutInterface.Attributes attributes = guest.attributes;
                    if(attributes != null && attributes.custom_field_values != null) {
                        for(ZkipsterCallOutInterface.CustomFieldValues cfv : attributes.custom_field_values) {
                            if('Title'.equalsIgnoreCase(cfv.field_name) && String.isNotBlank(cfv.value)) {
                                zkipsterTitle = cfv.value.trim();
                            }
                            if('table'.equalsIgnoreCase(cfv.field_name) && String.isNotBlank(cfv.value)) {
                                zkipsterTable = cfv.value;
                            }
                            if('seat'.equalsIgnoreCase(cfv.field_name) && String.isNotBlank(cfv.value)) {
                                zkipsterSeat = cfv.value;
                            }
                            if(('Guest 1 Additional Notes'.equalsIgnoreCase(cfv.field_name) ||
                                'Guest 2 Additional Notes'.equalsIgnoreCase(cfv.field_name)) &&
                                String.isNotBlank(cfv.value)) {

                                additionalNotes.add(cfv.value);
                            }
                        }
                    }
                    if(zkipterIds.get(guest.id) != '') {
                        CampaignMember member = new CampaignMember();
                        member.ZkipsterGuestId__c = guest.id;
                        CampaignMember existingMember = memMap.get(guest.id);
                        if(existingMember != null && existingMember.ContactId != null && attributes != null) {
                            createPendingContactChanges(eventId, existingMember, guest, zkipsterTitle);
                        }
                        String rsvpStatus = EventMangementAuraCtrl.getRSVPStatus(guest);
                        String status = attributes.status;
                        if(String.isBlank(rsvpStatus)) {
                            rsvpStatus = memMap.get(guest.id) != null
                                         ? memMap.get(guest.id).RSVPStatus__c
                                         : '';
                            rsvpStatus = rsvpStatus != null ? rsvpStatus : '';
                        }
                        if('CheckedIn'.equals(status)) {
                            member.AttendedStatus__c = 'Virtual'.equalsIgnoreCase(camp.SetUpEventLocationType__c) ||
                                                       ('Hybrid'.equalsIgnoreCase(camp.SetUpEventLocationType__c) && rsvpStatus.containsIgnoreCase('Virtual'))
                                                       ? 'Yes - Virtually'
                                                       : 'Yes - In Person';
                        }
                        if(attributes.checkin_date != null) {
                            member.CheckedInDate__c = (DateTime)JSON.deserialize(
                                '"' + attributes.checkin_date + '"',
                                DateTime.class
                            );
                        }
                        List<String> notes = new List<String>();
                        if(String.isNotBlank(attributes.note)) notes.add(attributes.note);
                        notes.addAll(additionalNotes);
                        member.Table__c = zkipsterTable;
                        member.Seat__c = zkipsterSeat;
                        if(!notes.isEmpty()) member.UB_Notes__c = String.join(notes, ' | ');
                        member.Id = zkipterIds.get(guest.id);
                        guests.put(member.Id, member);
                    } else {
                        UnplannedGuest__c tmpGuest = new UnplannedGuest__c();
                        tmpGuest.Event__c = eventId;
                        tmpGuest.FirstName__c = attributes.first_name;
                        tmpGuest.LastName__c = attributes.last_name;
                        tmpGuest.Organization__c = attributes.contact_details.organization;
                        tmpGuest.Salutation__c = attributes.contact_details.salutation;
                        tmpGuest.Email__c = (String.isNotBlank(attributes.contact_details.email) && attributes.contact_details.email.length()>80) ? null : attributes.contact_details.email;
                        tmpGuest.Phone__c = attributes.contact_details.phone_number;
                        tmpGuest.ZkipserGuestId__c = guest.id;
                        tmpGuest.Notes__c = attributes.note;
                        String rsvpStatus = EventMangementAuraCtrl.getRSVPStatus(guest);
                        String status = attributes.status;
                        if('CheckedIn'.equals(status)) {
                            tmpGuest.AttendedStatus__c = 'Virtual'.equalsIgnoreCase(camp.SetUpEventLocationType__c) ||
                                ('Hybrid'.equalsIgnoreCase(camp.SetUpEventLocationType__c) && rsvpStatus.containsIgnoreCase('Virtual'))
                                ? 'Yes - Virtually'
                                : 'Yes - In Person';
                        }
                        if(attributes.checkin_date != null) {
                            tmpGuest.CheckedInDate__c = (DateTime)JSON.deserialize(
                                '"' +
                                attributes.checkin_date +
                                '"',
                                DateTime.class
                            );
                        }
                        tmpGuest.Table__c = zkipsterTable;
                        tmpGuest.Seat__c = zkipsterSeat;
                        unplannedGuests.add(tmpGuest);
                    }
                }
            }
        }
    }

    private void createPendingContactChanges(String eventId, CampaignMember existingMember, ZkipsterCallOutInterface.Data guest, String zkipsterTitle) {
        ZkipsterCallOutInterface.Attributes attributes = guest.attributes;
        addPendingContactChange(eventId, existingMember.Contact, guest.id, 'Salutation', 'Salutation',
                                attributes.contact_details != null ? attributes.contact_details.salutation : null, false);
        addPendingContactChange(eventId, existingMember.Contact, guest.id, 'FirstName', 'First Name', attributes.first_name, false);
        addPendingContactChange(eventId, existingMember.Contact, guest.id, 'LastName', 'Last Name', attributes.last_name, false);
        addPendingContactChange(eventId, existingMember.Contact, guest.id, 'Title', 'Title', zkipsterTitle, false);
        String zkipsterPhone = attributes.contact_details != null
                               ? buildZkipsterPhone(attributes.contact_details.country_code, attributes.contact_details.phone_number)
                               : null;
        addPendingContactChange(eventId, existingMember.Contact, guest.id, 'MobilePhone', 'Mobile Phone', zkipsterPhone, true);
        String zkipsterCountryCode = attributes.contact_details != null
                                     ? CountryCodeUtility.getCountryCodePicklistValue(attributes.contact_details.country_code)
                                     : null;
        addPendingContactChange(eventId, existingMember.Contact, guest.id, 'Mobile_Phone_Country_Code__c', 'Mobile Phone Country Code',
                                zkipsterCountryCode, false);
    }

    /**
     * Description: Creates a pending Zkipster contact change when the value received from
     *              Zkipster differs from the current value stored on the Salesforce Contact.
     *              Blank Zkipster values are ignored so that blank values from Zkipster do not
     *              overwrite existing BRM data. Values are normalized before comparison to avoid
     *              creating changes for differences caused only by formatting, spacing, casing,
     *              or phone number formatting.
     * @param eventId           Campaign/List associated with the Zkipster guest.
     * @param contact           Existing Salesforce Contact.
     * @param zkipsterGuestId   Zkipster guest identifier.
     * @param fieldApiName      API name of the Contact field being compared.
     * @param fieldLabel        Display label of the Contact field.
     * @param zkipsterValue     Value received from Zkipster.
     * @param isPhone           Indicates whether phone normalization should be used.
    **/
    private void addPendingContactChange(String eventId, Contact contact, String zkipsterGuestId, String fieldApiName,
                                         String fieldLabel, String zkipsterValue, Boolean isPhone) {

        if(String.isBlank(zkipsterValue)) return;
        String currentValue = (String)contact.get(fieldApiName);
        String trimmedZkipsterValue = zkipsterValue.trim();
        String normalizedCurrentValue = isPhone ? normalizePhone(currentValue) : normalizeText(currentValue);
        String normalizedZkipsterValue = isPhone ? normalizePhone(trimmedZkipsterValue) : normalizeText(trimmedZkipsterValue);
        if(normalizedCurrentValue == normalizedZkipsterValue) return;
        String uniqueKey = String.valueOf(eventId) + '-' + String.valueOf(contact.Id) + '-' + fieldApiName;
        Zkipster_Contact_Update__c changeRecord = new Zkipster_Contact_Update__c();
        changeRecord.List__c = eventId;
        changeRecord.Contact__c = contact.Id;
        changeRecord.Zkipster_Guest_ID__c = zkipsterGuestId;
        changeRecord.Field_API_Name__c = fieldApiName;
        changeRecord.Field_Label__c = fieldLabel;
        changeRecord.Zkipster_Value__c = trimmedZkipsterValue;
        changeRecord.Status__c = 'Pending';
        changeRecord.Unique_Key__c = uniqueKey;
        pendingContactChangeMap.put(uniqueKey, changeRecord);
    }

    /**
     * Description: Normalizes text values before comparison between BRM and Zkipster.
     *              Removes leading/trailing whitespace, converts multiple whitespace characters
     *              into a single space, and performs a case-insensitive comparison by converting
     *              the value to lowercase.
    **/
    private static String normalizeText(String value) {
        if(String.isBlank(value)) return '';
        return value.trim().replaceAll('\\s+', ' ').toLowerCase();
    }

    /**
     * Description: Normalizes phone numbers before comparison between BRM and Zkipster.
     *              Removes all non-numeric characters so formatting differences such as spaces,
     *              parentheses, dashes, and plus signs do not cause a false change. For US phone
     *              numbers, a leading country code of 1 is removed when the resulting number
     *              contains 11 digits.
    **/
    private static String normalizePhone(String value) {
        if(String.isBlank(value)) return '';
        String digits = value.replaceAll('[^0-9]', '');
        if(digits.length() == 11 && digits.startsWith('1')) {
            digits = digits.substring(1);
        }
        return digits;
    }

    /**
     * Description: Builds a standardized international phone number using the country code and
     *              phone number received from Zkipster.
     *              Existing numbers beginning with "+" are returned as-is. Otherwise, the
     *              country's dialing code is retrieved and prepended to the phone number.
     *              A leading domestic zero is removed before adding the international dialing
     *              code when applicable. If the phone number is blank, null is returned. If the country code or dialing
     *              code cannot be resolved, the original trimmed phone number is returned.
    **/
    private static String buildZkipsterPhone(String countryCode, String phoneNumber) {
        if(String.isBlank(phoneNumber)) return null;
        String trimmedPhone = phoneNumber.trim();
        if(trimmedPhone.startsWith('+')) return trimmedPhone;
        String phoneDigits = trimmedPhone.replaceAll('[^0-9]', '');
        if(String.isBlank(phoneDigits)) return null;
        if(String.isBlank(countryCode)) return trimmedPhone;
        String dialingCode = CountryCodeUtility.getDialingCode(countryCode);
        if(String.isBlank(dialingCode)) return trimmedPhone;
        if(phoneDigits.startsWith(dialingCode)) return '+' + phoneDigits;
        if(phoneDigits.startsWith('0') && phoneDigits.length() > 1) {
            phoneDigits = phoneDigits.substring(1);
        }
        return '+' + dialingCode + phoneDigits;
    }

    public Integer getTotalGuestCount(String parsedResp) {
        Map<String,Object> parsedResponse  = (Map<String,Object>) JSON.deserializeUntyped(parsedResp);
        Integer totalCount = 0;
        if(parsedResponse.containskey('meta') && parsedResponse.containskey('meta') != null) {
            Map<String,Object> meta =  (Map<String,Object>) parsedResponse.get('meta');
            if(meta.containskey('total-records') && meta.containskey('total-records') != null) {
                totalCount = Integer.valueof(meta.get('total-records'));
            }
        }
        return totalCount;
    }
}