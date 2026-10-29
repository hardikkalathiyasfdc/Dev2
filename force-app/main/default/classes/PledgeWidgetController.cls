public class PledgeWidgetController {
    
    private static final String ERR_GET_PREVIOUS_SOFT_CREDITS = 'PLEDGE_WIDGET_GET_PREVIOUS_SOFT_CREDITS_FAILED';
    
    private static final String MSG_GET_PREVIOUS_SOFT_CREDITS = 'Unable to fetch previous soft credits.';
	
    @AuraEnabled (cacheable=true)
    public static DonorsData getPreviousSoftCredits (Id recordId) {
        try {
            DonorsData dData = new DonorsData ();
            
            Map<Id, Donor__c> pledgeDonors = new Map<Id, Donor__c> ([Select Id, Contact__c, Organization__c from Donor__c where Pledge__c =: recordId AND Credit_Type__c = 'Donor - Primary']);
            
            if (!pledgeDonors.isEmpty()) {
                            
                Set<Id> pledgeDonorContacts = new Set<Id> ();
                Set<Id> pledgeDonorOrgs = new Set <Id> ();
                
                for (Donor__c d: pledgeDonors.values()) {
                    if (d.Contact__c != null) {
                        pledgeDonorContacts.add(d.Contact__c);
                    } else if (d.Organization__c != null) {
                        pledgeDonorOrgs.add(d.Organization__c);
                    }
                }
                List<Donor__c> donors = [Select Id, Contact__c, Pledge__c, Credit_Type__c, Organization__c from Donor__c where (Contact__c IN: pledgeDonorContacts OR Organization__c IN: pledgeDonorOrgs) AND Credit_Type__c = 'Donor - Primary'];
                
                Set<Id> pledgeIds = new Set<Id> ();
                
                for (Donor__c d: donors) {
                    pledgeIds.add(d.Pledge__c);
                }
                
                if (!pledgeIds.isEmpty()) {
                    Set<Id> contactIds = new Set<Id> ();
                    Set<Id> orgIds = new Set<Id> ();
                    for (Donor__c d: [Select Id, Contact__c, Pledge__c, Credit_Type__c, Organization__c from Donor__c where Pledge__c IN: pledgeIds AND Credit_Type__c = 'Donor - Soft']) {
                        if (d.Contact__c != null) {
                            contactIds.add(d.Contact__c);
                        } else if (d.Organization__c != null) {
                            orgIds.add(d.Organization__c);
                        }
                    }
                    
                    if (!contactIds.isEmpty()) {
                        dData.donorContacts = new List<DonorContact> ();
                        for (Contact c: [Select Id, Name, Title, AccountId, Account.Name, Email from Contact where Id IN: contactIds]) {
                            dData.donorContacts.add (
                                new DonorContact (c)
                            );
                        }
                        
                        dData.donorContacts.sort();
                    }
                    
                    if (!orgIds.isEmpty()) {
                        dData.donorOrgs = new List<DonorOrganization> ();
                        for (Account a: [Select Id, AKA__c, Organization_Email__c, Name from Account where Id IN: orgIds]) {
                            dData.donorOrgs.add (
                                new Donororganization (a)
                            );
                        }
                        
                        dData.donorOrgs.sort();
                    }
                }
            }
            return dData;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_PREVIOUS_SOFT_CREDITS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_PREVIOUS_SOFT_CREDITS);
        }
    }
    
    public class DonorsData {
        @AuraEnabled public List<DonorContact> donorContacts;
        @AuraEnabled public List<DonorOrganization> donorOrgs;
    }
    
    public Class DonorContact implements comparable {        
        @AuraEnabled public String donorName;
        @AuraEnabled public Id donorId;
        @AuraEnabled public Contact contact;
        
        public DonorContact (Contact c) {
            donorName = c.Name;
            donorId = c.Id;
            contact = c;
        }
        
        public Integer compareTo(Object compareTo) {
            DonorContact con = (DonorContact) compareTo;
            if (donorName == con.donorName) return 0; if (donorName > con.donorName) return 1; return -1;
        }
    }
    
    public Class DonorOrganization implements comparable {        
        @AuraEnabled public String donorName;
        @AuraEnabled public Id donorId;
        @AuraEnabled public Account organization;
        
        public DonorOrganization (Account org) {
            donorName = org.Name;
            donorId = org.Id;
            organization = org;
        }
        
        public Integer compareTo(Object compareTo) {
            DonorOrganization org = (DonorOrganization) compareTo;
            if (donorName == org.donorName) return 0;
            if (donorName > org.donorName) return 1;
            return -1;
        }
    }
}