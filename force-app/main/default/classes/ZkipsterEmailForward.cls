global without sharing class ZkipsterEmailForward implements Messaging.InboundEmailHandler {
    public static final String BLOOMBERG_ORG = '@bloomberg.org';
    public static final String BLOOMBERG_NET = '@bloomberg.net';
    public static final String INVALID = '.invalid';
	private static final String ERR_HANDLE_INBOUND_EMAIL = 'ZKIPSTER_EMAIL_FORWARD_HANDLE_INBOUND_EMAIL_FAILED';
	private static final String ERR_CREATE_STAGE_RECORDS = 'ZKIPSTER_EMAIL_FORWARD_CREATE_STAGE_RECORDS_FAILED';
	private static final String ERR_PROCESS_EMAIL_BODY = 'ZKIPSTER_EMAIL_FORWARD_PROCESS_EMAIL_BODY_FAILED';
	private static final String ERR_EMAIL_SEND_FAILED = 'ZKIPSTER_EMAIL_FORWARD_EMAIL_SEND_FAILED';
	private static final String ERR_NO_INVITATION_EMAIL = 'ZKIPSTER_EMAIL_FORWARD_NO_INVITATION_EMAIL';
	private static final String ERR_NO_GUEST_INFO_TAG = 'ZKIPSTER_EMAIL_FORWARD_NO_GUEST_INFO_TAG';

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		try {
			String emailBody = email.htmlBody;
			String emailSubject = email.subject;
			String emailReplyTo = email.replyTo;
			createStageRecords(emailBody, emailSubject, emailReplyTo);
		} catch (Exception ex) {
			BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_HANDLE_INBOUND_EMAIL);
			BBApps_ErrorHandler.logErrors(ex, f);
		}
		return result;
	}

    public static void createStageRecords(String emailBody, String emailSubject, String emailReplyTo) {
        Staging_Area__c stage = new Staging_Area__c();
        stage.Email_Body__c = emailBody;
        stage.Email_Reply_To__c = emailReplyTo;
        stage.Email_Subject__c = emailSubject;
        BBApps_Crud.doInsertWithHandling(stage, false, ERR_CREATE_STAGE_RECORDS);
    }

    public static void processEmailBody(String emailBody, String emailSubject, String emailReplyTo) {
        try {
            Matcher imgMatcher = Pattern.compile('----(.+?)----').matcher(emailBody);
            String toEmail = '';
            String ccEmail = '';
            Boolean hasGuestInfo = false;
            CampaignMember guestInfo = null;
            while(imgMatcher.find()) {
                String imageTag = imgMatcher.group();
                String memberId = imageTag.replace('----', '');
                hasGuestInfo = true;
                guestInfo = getGuestInfo(memberId);
                String emailType = getEmailType(emailBody);
                emailBody = getFormattedBody(emailBody);
                Boolean sendEmail = 'confirmation'.equalsIgnoreCase(emailType);
                emailBody = emailBody.replace(imageTag, '');
                if(emailBody.contains('===EventLocation===')) {
                    emailBody = emailBody.replace('===EventLocation===', eventLocationProcess(guestInfo));
                }
				guestInfo = updateEmailTemplateModifiedFields(guestInfo, emailType);
                if(sendEmail == false) {
                    guestInfo = updateEmailFields(guestInfo, emailBody, emailType, emailSubject);
                } else {
                    if(guestInfo != null) {
                        String response = ZkipsterIntegration.getZkipsterGuestInfo(guestInfo.ZkipsterGuestId__c);
                        Boolean guest1Sender = true;
                        Boolean hasConfirmation = false;
                        if(response != 'error') {
                            ZkipsterCallOutInterface.GetGuestResponse resp =
								(ZkipsterCallOutInterface.GetGuestResponse) JSON.deserialize(response, ZkipsterCallOutInterface.GetGuestResponse.class);
                            ZkipsterCallOutInterface.Data data = resp.data;
                            ZkipsterCallOutInterface.Attributes attributes = data.attributes;
                            for(ZkipsterCallOutInterface.CustomFieldValues cfv : attributes.custom_field_values) {
                                if(cfv.field_name == 'Guest 1 Attending') {
                                    if(cfv.selected_values[0].value == 'No') {
                                        guest1Sender = false;
                                    }
                                    hasConfirmation = true;
                                }
                                if(cfv.field_name == 'Guest 1 Response') {
                                    if(cfv.selected_values[0].value == 'No') {
                                        guest1Sender = false;
                                    }
                                    hasConfirmation = true;
                                }
                                if(cfv.field_name == 'Guest 1 Additional Notes' && String.isNotBlank(cfv.value)) {
                                    guestInfo.RSVPNotes__c = String.isNotBlank(guestInfo.RSVPNotes__c)
															 ? guestInfo.RSVPNotes__c + ' | '
															 : '';
                                    guestInfo.RSVPNotes__c += cfv.value;
                                }
                            }
                        }
                        if(guest1Sender == false) {
                            guestInfo.RSVPStatus__c = 'No';
                            String response1 = ZkipsterIntegration.updateZkipsterGuestStatus(guestInfo.ZkipsterGuestId__c, 'No');
                            guestInfo.RSVPUpdateDate__c = DateTime.now();
                        } else {
                            guestInfo.RSVPStatus__c = 'Yes';
                            guestInfo.RSVPUpdateDate__c = DateTime.now();
                        }
                        List<String> toEmails = new List<String>{};
                        List<String> ccEmails = new List<String>();
                        if(String.isNotBlank(guestInfo.Guest_Email__c) && guest1Sender) {
                            toEmails.add(processEmailAddress(guestInfo.Guest_Email__c));
                        }
                        if(String.isNotBlank(guestInfo.AssistantEmail__c) && guest1Sender) {
                            ccEmails.add(processEmailAddress(guestInfo.AssistantEmail__c));
                        }
                        if(toEmails.size() > 0) {
                            if(String.isNotBlank(guestInfo.Campaign.InvitationFromEmail__c)) {
                                List<OrgWideEmailAddress> lstEmailAddress = [
									SELECT Id FROM OrgWideEmailAddress WHERE Address = :guestInfo.Campaign.InvitationFromEmail__c
								];
                                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                                // Set recipients to two contact IDs.
                                message.setReplyTo(EmailUtility.getReplyToEmail());
                                message.setOrgWideEmailAddressId(lstEmailAddress[0].Id);
                                message.setToAddresses(toEmails);
                                if(ccEmails.size() > 0) message.setCcAddresses(ccEmails);
                                message.subject = emailSubject;
                                message.setHtmlBody(emailBody);
                                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{ message };
                                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                                if(!results[0].success) {
									BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EMAIL_SEND_FAILED);
									BBApps_ErrorHandler.logErrors(new BRMException('The email failed to send: ' + results[0].errors[0].message), f);
								}
							} else {
								BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_NO_INVITATION_EMAIL);
								BBApps_ErrorHandler.logErrors(new BRMException('There is no Invitation From Email in Event record.'), f);
							}
                        }
                    }
                }
            }
            if(guestInfo != null) {
                TriggerFactory.setBypass('CampaignTriggerHandler');
                update guestInfo;
                TriggerFactory.removeBypass('CampaignTriggerHandler');
            }
            if(hasGuestInfo == false) {
                BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_NO_GUEST_INFO_TAG);
       			BBApps_ErrorHandler.logErrors(new BRMException('There is no guest info tag in the coming email from Zkipster.'), f);
      		}
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_PROCESS_EMAIL_BODY);
      		BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

	private static CampaignMember updateEmailTemplateModifiedFields(CampaignMember guestInfo, String emailType) {
		if(guestInfo == null) return guestInfo;
		if('invitation'.equalsIgnoreCase(emailType)) {
			guestInfo.Invitation_Last_Modified__c = DateTime.now();
		} else if('reminder'.equalsIgnoreCase(emailType)) {
			guestInfo.Reminder_Last_Modified__c = DateTime.now();
		} else if('savethedate'.equalsIgnoreCase(emailType)) {
			guestInfo.Save_the_Date_Last_Modified__c = DateTime.now();
		} else if('email'.equalsIgnoreCase(emailType)) {
			guestInfo.Email_Last_Modified__c = DateTime.now();
		}
		return guestInfo;
	}

    public static CampaignMember updateEmailFields(CampaignMember guestInfo, String emailBody, String emailType, String subject) {
        if(guestInfo == null) return guestInfo;
        guestInfo.put(EventMangementAuraCtrl.EMAIL_TYPE_MAP.get(emailType), emailBody);
        guestInfo.put(EventMangementAuraCtrl.EMAIL_CB_MAP.get(emailType), true);
        if(!'invitation'.equalsIgnoreCase(emailType)) {
            guestInfo.put(EventMangementAuraCtrl.EMAIL_SUBJECT_MAP.get(emailType), subject);
        }
        guestInfo.Last_Template_Updated__c = emailType;
        return guestInfo;
    }

    public static CampaignMember getGuestInfo(Id guestId) {
        String q = 'SELECT Id, Guest_Email__c, AssistantEmail__c, ZkipsterGuestId__c, Campaign.InvitationFromEmail__c,' +
					     ' AttendedStatus__c, RSVPNotes__c, RSVPUpdateDate__c, Campaign.LocationName__c, Campaign.LocationDetail__c, ' +
						 ' Campaign.AddressLine__c, Campaign.City__c, Campaign.State__c, Campaign.Country__c, Contact.Full_Name__c, ' +
						 ' EmailSubjectLine__c, Contact.Name, Campaign.Name, Save_the_Date_Last_Modified__c, Reminder_Last_Modified__c, ' +
						 ' Invitation_Last_Modified__c, Email_Last_Modified__c ';
        for(String key : EventMangementAuraCtrl.EMAIL_TYPE_MAP.keySet()) {
            q += ', ' + EventMangementAuraCtrl.EMAIL_TYPE_MAP.get(key);
        }
        for(String key : EventMangementAuraCtrl.EMAIL_CB_MAP.keySet()) {
            q += ', ' + EventMangementAuraCtrl.EMAIL_CB_MAP.get(key);
        }
        q += ' FROM CampaignMember WHERE Id = :guestId LIMIT 1';
        try {
            return (CampaignMember)Database.query(q).get(0);
        } catch (Exception e) {
            return null;
        }
    }

    public static String getEmailType(String emailBody) {
        Matcher typeMatcher = Pattern.compile('\\*\\*\\*\\*(.+?)\\*\\*\\*\\*').matcher(emailBody);
        while(typeMatcher.find()) {
            String match = typeMatcher.group();
            String original = match + '';
            try {
                match = match.substringAfter('****').substringBefore('****');
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(match);
                if(jsonMap.get('eventType') != null && !String.isBlank((String) jsonMap.get('eventType'))) {
                    String emailType = ((String) jsonMap.get('eventType')).toLowerCase();
                    if(EventMangementAuraCtrl.EMAIL_TYPE_MAP.containsKey(emailType) || 'confirmation'.equalsIgnoreCase(emailType)) {
                        return emailType;
                    }
                }
            } catch(Exception ex) {
				BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_PROCESS_EMAIL_BODY);
      			BBApps_ErrorHandler.logErrors(ex, f);
			}
        }
        return 'email';
    }

    public static String getFormattedBody(String emailBody) {
        Matcher typeMatcher = Pattern.compile('\\*\\*\\*\\*(.+?)\\*\\*\\*\\*').matcher(emailBody);
        while(typeMatcher.find()) {
            String match = typeMatcher.group();
            String original = match + '';
            try {
                match = match.substringAfter('****').substringBefore('****');
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(match);
                if(jsonMap.get('eventType') != null && !String.isBlank((String)jsonMap.get('eventType'))) {
                    String emailType = ((String) jsonMap.get('eventType')).toLowerCase();
                    if(EventMangementAuraCtrl.EMAIL_TYPE_MAP.containsKey(emailType) || 'confirmation'.equalsIgnoreCase(emailType)) {
                        emailBody = emailBody.replace(original, '');
                        return emailBody;
                    }
                }
            } catch(Exception ex) {
				BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_PROCESS_EMAIL_BODY);
      			BBApps_ErrorHandler.logErrors(ex, f);
			}
        }
        return emailBody;
    }

    public static String eventLocationProcess(CampaignMember guestInfo) {
        List<String> locationInfo = new List<String>();
        if(String.isNotBlank(guestInfo.Campaign.LocationName__c)) {
            locationInfo.add(guestInfo.Campaign.LocationName__c + '<br/>');
        }
        if(String.isNotBlank(guestInfo.Campaign.LocationDetail__c)) {
            locationInfo.add(guestInfo.Campaign.LocationDetail__c + '<br/>');
        }
        if(String.isNotBlank(guestInfo.Campaign.AddressLine__c)) {
            locationInfo.add(guestInfo.Campaign.AddressLine__c + '<br/>');
        }
        List<String> subLocation = new List<String>();
        if(String.isNotBlank(guestInfo.Campaign.City__c)) {
            subLocation.add(guestInfo.Campaign.City__c);
        }
        if(String.isNotBlank(guestInfo.Campaign.State__c)) {
            subLocation.add(guestInfo.Campaign.State__c);
        }
        if(subLocation.size() > 0) {
            String subLocationInfo = String.join(subLocation, ', ');
            locationInfo.add(subLocationInfo + '<br />');
        }
        return String.join(locationInfo, '');
    }

    public static String processEmailAddress(String email) {
        String tmpEmail = email;
        if(!tmpEmail.endsWith(BLOOMBERG_ORG) && !tmpEmail.endsWith(BLOOMBERG_NET) && !tmpEmail.endsWith(INVALID) && UtilityClass.isSandbox()) {
            tmpEmail = tmpEmail + '.invalid';
        }
        return tmpEmail;
    }
}