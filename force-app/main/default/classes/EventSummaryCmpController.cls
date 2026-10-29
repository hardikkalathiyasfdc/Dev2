public with sharing class EventSummaryCmpController {
    public static Id listId;
    public static Id listId1;
    public static Boolean hasOrg1;
    public static Map<String, Object> emailParams;
    public static EmailParams parameters;
    public static Integer yesCocktailOnlyCount = 0;
    public static Boolean hasOrg { get; set; }
    public static final String YES_CONDITION = '(RSVPStatus__c = \'Yes\' OR RSVPStatus__c=\'Yes - Cocktails Only\')';
    public static final String YES_INPERSON_CONDITION = 'RSVPStatus__c = \'Yes - In Person\'';
    public static final String YES_VIRTUAL_CONDITION = 'RSVPStatus__c = \'Yes - Virtually\'';
    public static final String NO_CONDITION = 'RSVPStatus__c LIKE \'No%\'';
    public static final String PEND_CONDITION = '(NOT RSVPStatus__c LIKE \'Yes%\') AND (NOT RSVPStatus__c LIKE \'No%\') AND (NOT RSVPStatus__c LIKE \'Waitlist 1%\') AND (NOT RSVPStatus__c LIKE \'Waitlist 2%\')';
    public static final String WAITLIST1_CONDITION = 'RSVPStatus__c = \'Waitlist 1\'';
    public static final String WAITLIST2_CONDITION = 'RSVPStatus__c = \'Waitlist 2\'';
    public static final Integer highlightHours = Integer.valueOf([Select Id, Highlight_Contacts_Updated_Hours__c from List_Edit_Settings__mdt where DeveloperName = 'Pre_Event'].Highlight_Contacts_Updated_Hours__c);
    public static final String NO_SOURCE = 'NoSource';

    @AuraEnabled
    public static string getUserEmail() {
        return [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()].Email;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getHighlightHours() {
        return highlightHours;
    }

    @AuraEnabled
    public static Object sendEmail(String listId, String sendEmail, String params) {
        emailParams = (Map<String, Object>) JSON.deserializeUntyped(params);
        parameters = new EmailParams();
        parameters.isSalutationChecked = (Boolean) emailParams.get('isSalutationChecked');
        parameters.isTitleChecked = (Boolean) emailParams.get('isTitleChecked');
        parameters.isOrgChecked = (Boolean) emailParams.get('isOrgChecked');
        parameters.isCityChecked = (Boolean) emailParams.get('isCityChecked');
        parameters.isStateChecked = (Boolean) emailParams.get('isStateChecked');
        parameters.isCountryChecked = (Boolean) emailParams.get('isCountryChecked');
        parameters.isAddGuestOfChecked = (Boolean) emailParams.get('isAddGuestOfChecked');
        parameters.isAddSourceChecked = (Boolean) emailParams.get('isAddSourceChecked');
        parameters.isAKAChecked = (Boolean) emailParams.get('isAKAChecked');
        parameters.isWaitlistChecked = (Boolean) emailParams.get('isWaitlistChecked');
        parameters.isPreferredNameChecked = (Boolean) emailParams.get('isPreferredNameChecked');
        parameters.isPreferredLastnameChecked = (Boolean) emailParams.get('isPreferredLastnameChecked');
        String fromDate = (String) emailParams.get('fromDate');
        String toDate = (String) emailParams.get('toDate');

        parameters.fromDate = String.isNotBlank(fromDate) ? Datetime.valueOfGmt(fromDate.replace('T',' ')) : null;
        parameters.toDate = String.isNotBlank(toDate) ? Datetime.valueOfGmt(toDate.replace('T',' ')) : null;
        if(emailParams.containsKey('sourceNames')) {
            parameters.sourceNames = (List<Object>)emailParams.get('sourceNames');
        }

        listId1 = listId;

        Map<String, Object> resultMap = new Map<String, Object>();
        String listName = [SELECT Id, Name FROM Campaign WHERE Id = :listId].Name;
        List<CampaignMember> campMembers = [SELECT ContactId, CampaignId,Contact.Restricted__c
                                            FROM CampaignMember
                                            WHERE CampaignId  =:listId AND Contact.Restricted__c = TRUE];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        message.setOrgWideEmailAddressId(EmailUtility.getBRMEmailAddress());
        message.setTargetObjectId(UserInfo.getUserId());
        message.setReplyTo(EmailUtility.getReplyToEmail());
        message.setSubject('Guest Summary for: '+listName);

        message.setHtmlBody(getEmailBody());
        message.setUseSignature(false);
        message.setBccSender(false);
        message.setSaveAsActivity(false);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
        new List<Messaging.SingleEmailMessage>{ message }
        );
        for (Messaging.SendEmailResult result : results) {
            if (!result.isSuccess()) {
                resultMap.put('error', result.getErrors()[0].getMessage());
                return resultMap;
            }
        }
        if(!campMembers.Isempty()){
           resultMap.put('restrictedContact', campMembers.Size());
        }
        resultMap.put('success', UserInfo.getUserEmail());
        return resultMap;
    }

    public static String getEmailBody() {

        String body = '';
        Integer yesCount = getYesCount();
        Integer yesInPersonCount = getYesInPersonCount();
        Integer yesVirtualCount = getYesVirtualCount();
        Integer noCount = getNoCount();
        Integer pendCount = getPendCount();
        yesCocktailOnlyCount = getYesCocktailOnlyCount();

        if(yesCount > 0) body += getSubListBody(YES_CONDITION, 'YES', yesCount)+'</br>';
        if(yesInPersonCount > 0) body += getSubListBody(YES_INPERSON_CONDITION, 'YES - IN PERSON', yesInPersonCount)+'</br>';
        if(yesVirtualCount > 0) body += getSubListBody(YES_VIRTUAL_CONDITION, 'YES - VIRTUALLY', yesVirtualCount)+'</br>';
        if(pendCount > 0) body += getSubListBody(PEND_CONDITION, 'PENDING', pendCount)+'</br>';
        if(noCount > 0) body += getSubListBody(NO_CONDITION, 'NO', noCount)+'</br>';

        if(parameters.isWaitlistChecked) {
            Integer waitList1Count = getWaitList1Count ();
            Integer waitList2Count = getWaitList2Count ();

            if(waitList1Count > 0) body += getSubListBody(WAITLIST1_CONDITION, 'WAITLIST 1', waitList1Count)+'</br>';
            if(waitList2Count > 0) body += getSubListBody(WAITLIST2_CONDITION, 'WAITLIST 2', waitList2Count)+'</br>';
        }
        return body;
    }

    public static String getSubListBody(String condition, String header, Integer count) {
        String body = '<b>' + header + ' (' + count + '):</b> </br>';
        if(condition == YES_CONDITION) {
			body += '<i> Cocktails Only (' + yesCocktailOnlyCount + ' out of ' + count + ')</i>' + ' </br>';
		}
        List<MyEventSummary> myEventSummarys = getList(condition);
        if(parameters.sourceNames != null && !parameters.sourceNames.isEmpty()) {
            Map<String, List<MyEventSummary>> eventSummayBySource = new Map<String, List<MyEventSummary>>();
            eventSummayBySource.put(NO_SOURCE, new List<MyEventSummary>());
            for(MyEventSummary eventSummary : myEventSummarys) {
                if(String.isNotBlank(eventSummary.listMem.Source__c)) {
                    if(!parameters.sourceNames.contains(eventSummary.listMem.Source__c)) {
                        eventSummayBySource.get(NO_SOURCE).add(eventSummary);
                    } else {
                        List<MyEventSummary> eventSummaryList = eventSummayBySource.containsKey(eventSummary.listMem.Source__c)
																? eventSummayBySource.get(eventSummary.listMem.Source__c)
																: new List<MyEventSummary>();
                        eventSummaryList.add(eventSummary);
                        eventSummayBySource.put(eventSummary.listMem.Source__c, eventSummaryList);
                    }
                } else {
                    eventSummayBySource.get(NO_SOURCE).add(eventSummary);
                }
            }
            if(!eventSummayBySource.isEmpty()) {
                //events without any source or source not selected
                List<MyEventSummary> noSourceEventSummary = eventSummayBySource.get(NO_SOURCE);
                for(MyEventSummary eventSummary : noSourceEventSummary) {
                    String style = eventSummary.isRecent ? 'color:black;background:yellow;mso-highlight:yellow' : 'color:black;';
                    body += '<p style="'+style+'">'+eventSummary.Name+'</p>';
                }
                List<String> sortedSourceNames = new List<String>(eventSummayBySource.keySet());
                sortedSourceNames.sort();
                List<MyEventSummary> sourceNotSelectedEventSummary = new List<MyEventSummary>();
                for(String sourceKey : sortedSourceNames) {
                    if(!parameters.sourceNames.contains(sourceKey) && !NO_SOURCE.equalsIgnoreCase(sourceKey)) {
                        sourceNotSelectedEventSummary.addAll(eventSummayBySource.get(sourceKey));
                    }
                }
                for(MyEventSummary eventSummary : sourceNotSelectedEventSummary) {
                    String style = eventSummary.isRecent ? 'color:black;background:yellow;mso-highlight:yellow' : 'color:black;';
                    body += '<p style="'+style+'">'+eventSummary.Name+'</p>';
                }
                for(String sourceKey : sortedSourceNames) {
                    if(parameters.sourceNames.contains(sourceKey)) {
                        List<MyEventSummary> tempEventSummary = eventSummayBySource.get(sourceKey);
                        body += '</br><i> ' + sourceKey + ' (' + tempEventSummary.size() + ')</i>' + ' </br>';
                        for(MyEventSummary eventSummary : tempEventSummary) {
                            String style = eventSummary.isRecent ? 'color:black;background:yellow;mso-highlight:yellow' : 'color:black;';
                            body += '<p style="'+style+'">'+eventSummary.Name+'</p>';
                        }
                    }
                }
            }
        } else {
            for(MyEventSummary eventSummary : myEventSummarys) {
                String style = eventSummary.isRecent ? 'color:black;background:yellow;mso-highlight:yellow' : 'color:black;';
                body += '<p style="'+style+'">'+eventSummary.Name+'</p>';
            }
        }
        return body;
    }

    public static Integer getYesCount () {
        String q =
            'SELECT COUNT() FROM CampaignMember WHERE CampaignId =: listId1 AND ' +
            YES_CONDITION;
        Integer count = Database.countQuery(q);
        return count;
    }
    public static Integer getYesCocktailOnlyCount () {
        String q =
            'SELECT COUNT() FROM CampaignMember WHERE CampaignId =: listId1 AND RSVPStatus__c=\'Yes - Cocktails Only\'';
        Integer count = Database.countQuery(q);
        return count;
    }

    public static Integer getYesInPersonCount () {
        String q =
            'SELECT COUNT() FROM CampaignMember WHERE CampaignId =: listId1 AND ' +
            YES_INPERSON_CONDITION;
        Integer count = Database.countQuery(q);
        return count;
    }

    public static Integer getYesVirtualCount () {
        String q =
            'SELECT COUNT() FROM CampaignMember WHERE CampaignId =: listId1 AND ' +
            YES_VIRTUAL_CONDITION;
        Integer count = Database.countQuery(q);
        return count;
    }

    public static Integer getNoCount () {
        String q =
            'SELECT COUNT() FROM CampaignMember WHERE CampaignId =: listId1 AND ' +
            NO_CONDITION;
        Integer count = Database.countQuery(q);
        return count;
    }

    public static Integer getPendCount () {
        String q =
            'SELECT COUNT() FROM CampaignMember WHERE CampaignId =: listId1 AND ' +
            PEND_CONDITION;
        Integer count = Database.countQuery(q);
        return count;
    }

    public static Integer getWaitList1Count () {
        String q =
            'SELECT COUNT() FROM CampaignMember WHERE CampaignId =: listId1 AND ' +
            WAITLIST1_CONDITION;
        Integer count = Database.countQuery(q);
        return count;
    }

    public static Integer getWaitList2Count () {
        String q =
            'SELECT COUNT() FROM CampaignMember WHERE CampaignId =: listId1 AND ' +
            WAITLIST2_CONDITION;
        Integer count = Database.countQuery(q);
        return count;
    }

    private static List<MyEventSummary> getList(String condition) {
        Boolean hasRestrictedAccess = FeatureManagement.checkPermission('Private_Name_Fields');
        String q = 'SELECT Id, RSVPUpdateDate__c,UB_LastName__c, Contact.Primary_Spouse__c,RSVPStatus__c, GuestOf_Name__c, Source__c, ContactId, Contact.Salutation, Contact.Title, Contact.Preferred_Last_Name__c, Contact.Preferred_First_Name__c,Contact.RestrictedLastName__c,Contact.RestrictedFirstName__c, Contact.MailingCity, Contact.MailingState, Contact.MailingCountry, Contact.Significant_Other__r.Account.Name, Contact.FirstName, Contact.LastName, Contact.Significant_Other__c, Contact.Significant_Other__r.FirstName, Contact.Significant_Other__r.LastName, Contact.Account.Name, Contact.Restricted_Org_Name__c,Contact.Restricted__c, Contact.Account.Restricted__c, Contact.Account.AKA__c FROM CampaignMember WHERE CampaignId =: listId1';
        q += ' AND ' + condition;
        List<MyEventSummary> sumList = new List<MyEventSummary>();
        List<CampaignMember> memList =  (List<CampaignMember>) Database.query(q);
        if (memList.isEmpty()) {
            return sumList;
        }
        Map<Id, CampaignMember> contactMemMap = getContactToMemMap(memList);
        Set<Id> significantOtherSet = new Set<Id>();
        for (CampaignMember mem : memList) {


            if (!significantOtherSet.contains(mem.ContactId) && ( mem.UB_LastName__c != Assets.RESTRICTED_ORG_NAME || (mem.UB_LastName__c == Assets.RESTRICTED_ORG_NAME && hasRestrictedAccess))) {
                MyEventSummary sum = new MyEventSummary(mem);
                Id spouseId = mem.Contact.Significant_Other__c;
                if (spouseId != null && contactMemMap.get(spouseId) != null) {
                    significantOtherSet.add(spouseId);
                    sum.name = sum.getCombinedName(mem, contactMemMap.get(spouseId));
                }
                else if(YES_CONDITION == condition && mem.RSVPStatus__c=='Yes - Cocktails Only')
                {
                    sum.name = sum.name+'<i> (Cocktails Only)</i>';
                }
                sumList.add(sum);
            }
        }
        sumList.sort();
        return sumList;
    }

    public static Map<Id, CampaignMember> getContactToMemMap(
        List<CampaignMember> memList
    ) {
        Map<Id, CampaignMember> contactMap = new Map<Id, CampaignMember>();
        for (CampaignMember mem : memList) {
            contactMap.put(mem.ContactId, mem);
        }
        return contactMap;
    }

    public class MyEventSummary implements Comparable {
        public Boolean isRecent { get; set; }
        public String name { get; set; }
        public String lastName;
        public CampaignMember listMem;

        public MyEventsummary(CampaignMember mem) {
            listMem = mem;
            name = getName(mem, null);
           // lastName = mem.Contact.Restricted__c ? mem.Contact.RestrictedLastName__c : mem.Contact.LastName;
            if (parameters.isPreferredLastnameChecked) {
    if (mem.Contact.Restricted__c) {
        lastName = String.isNotBlank(mem.Contact.Preferred_Last_Name__c)
            ? mem.Contact.Preferred_Last_Name__c
            : mem.Contact.RestrictedLastName__c;
    } else {
        lastName = String.isNotBlank(mem.Contact.Preferred_Last_Name__c)
            ? mem.Contact.Preferred_Last_Name__c
            : mem.Contact.LastName;
    }
} else {
    lastName = mem.Contact.Restricted__c
        ? mem.Contact.RestrictedLastName__c
        : mem.Contact.LastName;
}
            isRecent = false;
            Double hoursInDay = 24;

            if(parameters.fromDate != null && parameters.toDate != null) {
                if(mem.RSVPUpdateDate__c >= parameters.fromDate && mem.RSVPUpdateDate__c <= parameters.toDate){
                    isRecent = true;
                }
            } else if (parameters.fromDate != null) {
                if(mem.RSVPUpdateDate__c >= parameters.fromDate && mem.RSVPUpdateDate__c <= DateTime.now()){
                    isRecent = true;
                }
            } else if (mem.RSVPUpdateDate__c >= (Datetime.now() - (highlightHours/hoursInDay))){
                isRecent = true;
            }
        }

        public String getName(CampaignMember mem, CampaignMember spouse) {
            String n = '';
            if (parameters.isSalutationChecked) {
                String salutation = mem.Contact?.Salutation;
                if(String.isNotBlank(salutation)) n = salutation;
            }

            String firstName;
            if(parameters.isPreferredNameChecked) {
                if(mem.Contact.Restricted__c){

                    firstName =  mem.Contact?.Preferred_First_Name__c != null ? mem.Contact.Preferred_First_Name__c : mem.Contact?.RestrictedFirstName__c;
                } else {
                    firstName = mem.Contact?.Preferred_First_Name__c != null ? mem.Contact.Preferred_First_Name__c : mem.Contact?.FirstName;
                }

                if(spouse != null) firstName += spouse.Contact?.Preferred_First_Name__c != null ? +' & '+ spouse.Contact.Preferred_First_Name__c : +' & '+spouse.Contact?.FirstName;
            } else {
                firstName =  mem.Contact?.Restricted__c ?  mem.Contact?.RestrictedFirstName__c : mem.Contact?.FirstName;
                if(spouse != null) firstName += ' & '+ ((spouse.Contact?.Restricted__c) ?  spouse.Contact?.RestrictedFirstName__c : spouse.Contact?.FirstName);
            }

            String lastName; // = mem.Contact.Restricted__c ? mem.Contact.RestrictedLastName__c : mem.Contact.LastName;
            if(parameters.isPreferredLastnameChecked) {
                 if(mem.Contact.Restricted__c){
        lastName = String.isNotBlank(mem.Contact.Preferred_Last_Name__c)
            ? mem.Contact.Preferred_Last_Name__c
            : mem.Contact.RestrictedLastName__c;
                } else {
        lastName = String.isNotBlank(mem.Contact.Preferred_Last_Name__c)
            ? mem.Contact.Preferred_Last_Name__c
            : mem.Contact.LastName;
                }
} else {
    lastName = mem.Contact.Restricted__c
        ? mem.Contact.RestrictedLastName__c
        : mem.Contact.LastName;
            }

            n = n + ' ' + (firstName != null ? firstName : '');
            n = String.isNotBlank(n) ? n + ' ' : '';
            n += lastName;

            if (parameters.isTitleChecked) {
                String title = mem.Contact?.Title;
                if(String.isNotBlank(title)) n += ', ' + title;
            }

            if (parameters.isOrgChecked) {

                String org = mem.Contact?.Account?.Name;
                if (mem.Contact.Account.Restricted__c && Schema.sObjectType.Contact.fields.Restricted_Org_Name__c.isAccessible()) {
                    org = mem.contact.Restricted_Org_Name__c != null ? mem.contact.Restricted_Org_Name__c : mem.Contact?.Account?.Name;
                }
                if (String.isNotBlank(org) && !'-'.equals(org)) {
                    n += ', ' + org;
                }
            }

            if (parameters.isCityChecked) {
                String city = mem.Contact?.MailingCity;
                if(String.isNotBlank(city)) n += ', ' + city;
            }

            if (parameters.isStateChecked) {
                String state = mem.Contact?.MailingState;
                if(String.isNotBlank(state)) n += ', ' + state;
            }

            if (parameters.isCountryChecked) {
                String country = mem.Contact?.MailingCountry;
                if(String.isNotBlank(country)) n += ', ' + country;
            }

            if (parameters.isAddGuestOfChecked) {
                String addGuestOf = mem.GuestOf_Name__c;
                if(String.isNotBlank(addGuestOf))
                    n += ', Guest Of: ' + addGuestOf;
            }

            if (parameters.isAddSourceChecked) {
                String addSource = mem.Source__c;
                if(String.isNotBlank(addSource))
                    n += ', Source: ' + addSource;
            }
            return n;
        }

        public String getCombinedName(CampaignMember mem, CampaignMember spouse) {
            CampaignMember firstMember = mem;
            CampaignMember secondMember = spouse;
            if(!mem.Contact.Primary_Spouse__c && spouse.Contact.Primary_Spouse__c) {
                firstMember = spouse;
                secondMember = mem;
            }

           // this.lastName = firstMember.Contact.LastName;
            if (parameters.isPreferredLastnameChecked) {
    if (firstMember.Contact.Restricted__c) {
        this.lastName = String.isNotBlank(firstMember.Contact.Preferred_Last_Name__c)
            ? firstMember.Contact.Preferred_Last_Name__c
            : firstMember.Contact.RestrictedLastName__c;
    } else {
        this.lastName = String.isNotBlank(firstMember.Contact.Preferred_Last_Name__c)
            ? firstMember.Contact.Preferred_Last_Name__c
            : firstMember.Contact.LastName;
    }
} else {
    this.lastName = firstMember.Contact.Restricted__c
        ? firstMember.Contact.RestrictedLastName__c
        : firstMember.Contact.LastName;
}

            if(
                mem.Contact.LastName == spouse.Contact.LastName &&
                !parameters.isTitleChecked &&
                !parameters.isOrgChecked &&
                !parameters.isCityChecked &&
                !parameters.isStateChecked &&
                !parameters.isCountryChecked
            ) {
                return getName(firstMember, secondMember);
            }
            String cName= getName(firstMember, null) + ' & ' + getName(secondMember, null);
            if(firstMember.RSVPStatus__c=='Yes - Cocktails Only' || secondMember.RSVPStatus__c=='Yes - Cocktails Only')
            {
                if(firstMember.RSVPStatus__c=='Yes - Cocktails Only' )
                {
                    cName = getName(firstMember, null) + ' <i>(Cocktails Only)</i> & ' ;
                }
                else{
                    cName = getName(firstMember, null) + ' (Yes) & ';
                }
                if(secondMember.RSVPStatus__c=='Yes - Cocktails Only' )
                {
                    cName =   cName + getName(secondMember, null) +' <i>(Cocktails Only)</i>';
                }
                else{
                    cName = cName+ getName(secondMember, null) +' (Yes)';
                }
            }

            return cName;
        }

        public Integer compareTo(Object compareTo) {
            MyEventSummary other = (MyEventSummary) compareTo;

            if (this.isRecent && !other.isRecent) return -1;
            if (!this.isRecent && other.isRecent) return 1;

            String ln1 = (this.lastName == null ? '' : this.lastName).toLowerCase();
            String ln2 = (other.lastName == null ? '' : other.lastName).toLowerCase();
            Integer c = ln1.compareTo(ln2);
            if (c != 0) return c;

            String nm1 = (this.name == null ? '' : this.name).toLowerCase();
            String nm2 = (other.name == null ? '' : other.name).toLowerCase();
            c = nm1.compareTo(nm2);
            if (c != 0) return c;

            String s1 = (this.listMem == null || this.listMem.Id == null) ? '' : String.valueOf(this.listMem.Id);
            String s2 = (other.listMem == null || other.listMem.Id == null) ? '' : String.valueOf(other.listMem.Id);
            return s1.compareTo(s2);
        }
    }

    public class EmailParams {
        public Boolean isSalutationChecked;
        public Boolean isTitleChecked;
        public Boolean isOrgChecked;
        public Boolean isAddressChecked;
        public Boolean isCityChecked;
        public Boolean isStateChecked;
        public Boolean isCountryChecked;
        public Boolean isAddGuestOfChecked;
        public Boolean isAddSourceChecked;
        public Boolean isAKAChecked;
        public Boolean isWaitlistChecked;
        public Boolean isPreferredNameChecked;
        public Boolean isPreferredLastnameChecked;
        public DateTime fromDate;
        public DateTime toDate;
        public List<Object> sourceNames;
    }
}