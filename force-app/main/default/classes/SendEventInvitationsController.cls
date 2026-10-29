public with sharing class SendEventInvitationsController {

  private static final String ERR_SEND_EMAIL = 'EVENTINVITATIONS_SEND_EMAIL_FAILED';
  private static final String ERR_UPDATE_MEMBERS = 'EVENTINVITATIONS_UPDATE_MEMBERS_FAILED';

  private static final String MSG_SEND_EMAIL = 'Unable to send event invitations.';
  private static final String MSG_UPDATE_MEMBERS = 'Unable to update email status for event invitations.';

  public static Map<String, Id> orgEmailMap = getOrgEmailMap();

  @AuraEnabled
  public static Object sendEmail(List<Id> memIds, String emailType) {
    try { 
      if (!isEventUpcoming(memIds.get(0))) {
        throw new MyException('Can only send invitations for upcoming events.');
      }
      String emailField = EventMangementAuraCtrl.EMAIL_TYPE_MAP.get(emailType);
      String statusField = EventMangementAuraCtrl.EMAIL_STATUS_MAP.get(emailType);
      String sentField = EventMangementAuraCtrl.EMAIL_DATETIME_MAP.get(emailType);
      String emailName = EventMangementAuraCtrl.EMAIL_NAME_MAP.get(emailType);
      String emailSubject = EventMangementAuraCtrl.EMAIL_SUBJECT_MAP.get(
        emailType
      );
      Datetime now = DateTime.now();
      TimeZone tz = UserInfo.getTimeZone();
      String curTimeFormat = now.format() + ' ' + tz.getDisplayName();
      List<CampaignMember> memList = getMembers(
        memIds,
        emailField,
        statusField,
        sentField,
        emailSubject
      );
      List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
      List<Map<String, Object>> errList = new List<Map<String, Object>>();

      for (CampaignMember mem : memList) {
        Map<String, Object> errMap = getErrors(mem, emailField, emailSubject);
        if (!errMap.isEmpty()) {
          errList.add(errMap);
          mem.put(statusField, 'Unable to Send');
          mem.put(sentField, now);
          if ('invitation'.equalsIgnoreCase(emailType))
            mem.RSVPStatus__c = '';
          mem.Last_Email_Status__c = 'Error: Unable to Send ' + emailName;
          mem.Last_Email_Sent_Errors__c = getErrorValues(
            emailName,
            (List<String>) errMap.get('errors')
          );
        } else {
          Messaging.SingleEmailMessage myEmail = getMsg(
            mem,
            emailField,
            emailSubject
          );
          emailList.add(myEmail);
          mem.put(statusField, 'Sent');
          mem.put(sentField, now);
          if ('invitation'.equalsIgnoreCase(emailType))
            mem.RSVPStatus__c = 'Pend';
          mem.Last_Email_Status__c = emailName + ' Sent';
          mem.Last_Email_Sent_Errors__c = '';
          mem.EventEmail__c = mem.Guest_Email__c;
        }
      }

      if (emailList.isEmpty()) {
        BBApps_Crud.doUpdateWithHandling(memList, false, ERR_UPDATE_MEMBERS);
        return errList;
      }

      sendEmail(emailList);
      BBApps_Crud.doUpdateWithHandling(memList, false, ERR_UPDATE_MEMBERS);

      return errList;

    } catch (Exception ex) {
      BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SEND_EMAIL);
      BBApps_ErrorHandler.logErrors(ex, f);
      throw new AuraHandledException(MSG_SEND_EMAIL);
    }
  }

  private static Boolean isEventUpcoming(Id memId) {
    Id campId = [
      SELECT Id, CampaignId
      FROM CampaignMember
      WHERE Id = :memId
      LIMIT 1
    ]
    .CampaignId;
    Campaign c = [SELECT Id, EventStatus__c FROM Campaign WHERE Id = :campId];
    return 'upcoming'.equalsIgnoreCase(c.EventStatus__c);
  }

  private static void sendEmail(List<Messaging.SingleEmailMessage> emailList) {
    if (emailList.isEmpty()) {
      return;
    }
    if (emailList.size() <= 100) {
      Messaging.sendEmail(emailList);
      return;
    }

    List<Messaging.SingleEmailMessage> subList = new List<Messaging.SingleEmailMessage>();
    for (Integer i = 0; i < 100; i++) {
      subList.add(emailList.remove(0));
    }
    Messaging.sendEmail(subList);
    sendEmail(emailList);
  }

	private static Messaging.SingleEmailMessage getMsg(CampaignMember mem, String emailField, String subjectField) {
    Messaging.SingleEmailMessage myEmail = new Messaging.SingleEmailMessage();
    Id orgEmailId = getOrgEmailId(mem.Event_From_Email__c);
    myEmail.setOrgWideEmailAddressId(orgEmailId);
    myEmail.setHtmlBody((String) mem.get(emailField));
    myEmail.setToAddresses(new List<String>{ mem.Guest_Email__c });
    myEmail.setSubject(ListEditCmpController.getSubjectLine(mem, subjectField));
		if(!isBlank(mem.CC_Addresses__c)) {
			List<String> ccList = new List<String>();
			for(String addr : mem.CC_Addresses__c .split(',')) {
				addr = addr.trim();
				if(addr != '' && !ccList.contains(addr)) {
					ccList.add(addr);
				}
			}
			myEmail.setCcAddresses(ccList);
		}
		if(!isBlank(mem.BCC_Addresses__c)) {
			List<String> bccList = new List<String>();
			for(String addr : mem.BCC_Addresses__c .split(',')) {
				addr = addr.trim();
				if(addr != '' && !bccList.contains(addr)) {
					bccList.add(addr);
				}
			}
			myEmail.setBccAddresses(bccList);
    }
    return myEmail;
  }

  private static String getErrorValues(String emailType, List<String> errList) {
    String errorSet = '';
    for (String err : errList) {
      errorSet += err + ';';
    }
    return errorSet;
  }

  private static Map<String, Object> getErrors(
    CampaignMember mem,
    String emailField,
    String emailSubject
  ) {
    Map<String, Object> errMap = new Map<String, Object>();
    if (isBlank((String) mem.get(emailSubject))) {
      List<String> errList = errMap.get('errors') != null
        ? (List<String>) errMap.get('errors')
        : new List<String>();
      errList.add('Subject is blank');
      errMap.put('errors', errList);
    }

    String fromEmail = !isBlank(mem.Event_From_Email__c)
      ? mem.Event_From_Email__c
      : '<Blank>';
    Id orgEmailId = getOrgEmailId(mem.Event_From_Email__c);
    if (orgEmailId == null) {
      List<String> errList = errMap.get('errors') != null
        ? (List<String>) errMap.get('errors')
        : new List<String>();
      errList.add(fromEmail + ' is not a valid event from email');
      errMap.put('errors', errList);
    }

    if (isBlank((String) mem.get(emailField))) {
      List<String> errList = errMap.get('errors') != null
        ? (List<String>) errMap.get('errors')
        : new List<String>();
      errList.add('Missing email body');
      errMap.put('errors', errList);
    }
    if (isBlank(mem.Guest_Email__c)) {
      List<String> errList = errMap.get('errors') != null
        ? (List<String>) errMap.get('errors')
        : new List<String>();
      errList.add('Missing email');
      errMap.put('errors', errList);
    }

    if (
      mem.CC_Assistant__c == true &&
      !isBlank(mem.Assistant__c) &&
      isBlank(mem.Assistant_Email__c)
    ) {
      List<String> errList = errMap.get('errors') != null
        ? (List<String>) errMap.get('errors')
        : new List<String>();
      errList.add('No assistant email found for cc');
      errMap.put('errors', errList);
    }

    if (errMap.isEmpty()) {
      return errMap;
    }
    errMap.put('name', mem.Contact.Name);
    return errMap;
  }

  private static boolean isBlank(String val) {
    if (val == null) {
      return true;
    }
    return String.isBlank(val.trim());
  }

  private static Id getOrgEmailId(String email) {
    if (isBlank(email)) {
      return null;
    }

    email = email.toLowerCase();
    return orgEmailMap.get(email);
  }

  private static List<CampaignMember> getMembers(
    List<Id> memIds,
    String emailField,
    String statusField,
    String sentField,
    String emailSubject
  ) {
    String q =
      'SELECT Id, Event_From_Email__c,Guest_Email__c, CC_Assistant__c,Email_Sent_Status__c, Contact.Name, Email, Assistant__c, Assistant_Email__c, BCC_Addresses__c, CC_Addresses__c, UB_FirstName__c, UB_LastName__c, ' +
      emailField +
      ', ' +
      statusField +
      ', ' +
      sentField +
      ', ' +
      emailSubject +
      ' FROM CampaignMember WHERE Id IN :memIds';
    List<CampaignMember> memList = (List<CampaignMember>) Database.query(q);
    return memList;
  }

  private static Map<String, Id> getOrgEmailMap() {
    List<OrgWideEmailAddress> orgEmailList = [
      SELECT Id, Address
      FROM OrgWideEmailAddress
    ];
    Map<String, Id> orgEmailMap = new Map<String, Id>();
    for (OrgWideEmailAddress org : orgEmailList) { 
      orgEmailMap.put(org.Address.toLowerCase(), org.Id);
    }
    return orgEmailMap;
  }

  public class MyException extends Exception {
  }
}