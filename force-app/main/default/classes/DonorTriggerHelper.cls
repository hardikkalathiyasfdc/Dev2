/**
 * Author : Neha Gire
 * Date   : 1/18/2024
 * Jira   : BRME-4946
 * Description : This is helper created for Donor Trigger handler to hold common methods.
 * Test   : DonorTriggerHelperTest
 **/

public class DonorTriggerHelper {
    
    private static final String ERR_UPDATE_PLEDGE_NAME = 'DONOR_HELPER_UPDATE_PLEDGE_NAME_FAILED';
    private static final String ERR_UPDATE_PLEDGES = 'DONOR_HELPER_UPDATE_PLEDGES_FAILED';
    private static final String ERR_UPDATE_COFUNDER = 'DONOR_HELPER_UPDATE_COFUNDER_FAILED';
     
    /**
     * This method will be used to update pledge name when related contact / organizations name is changed or deleted
     * Params : List<Id> recordIds - List of changed contactIds or Organization Ids
     *        : String objectType -  Specifies if recordIds are contacts or organizations
    **/
    public static void updatePledgeName(Set<Id> recordIds , String objectType) {
        try {
            Set<Id> pledgeIds = getPledges(recordIds,objectType);
            if(pledgeIds.isEmpty()) return;
            updatePledges(pledgeIds);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_UPDATE_PLEDGE_NAME);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    private static Set<Id> getPledges(Set<Id> recordIds , String objectType) {
        Set<Id> pledgeIds = new Set<Id>();
        if(!recordIds.isEmpty()) {
            String query = 'SELECT Pledge__c FROM Donor__c';
            if(('Contact').equalsIgnoreCase(objectType)) {
                query += ' WHERE Contact__c IN :recordIds';
            } else if(('Organization').equalsIgnoreCase(objectType)){
                query += ' WHERE Organization__c IN :recordIds';
            }
            List<Donor__c> donors = Database.query(query);
            if(!donors.isEmpty()) {
                for(Donor__c d: donors) {
                    pledgeIds.add(d.Pledge__c);
                }
            }
        }
        return pledgeIds;
    }
    
    /** 
     * This @future method is used to avoid recursive updates on a record 
     * within the trigger context from Donor__c object 
	**/
    @future
    public static void updatePledges(Set<Id> pledgeIds) {
        try {
            Map<Id, Pledge__c> pledgesMap = new Map<Id, Pledge__c>();
            List<Donor__c> donorsToUpdate = new List<Donor__c>();
        for (Donor__c d : [SELECT Id, Pledge__c, Credit_Type__c, Contact__c, Contact__r.Name, Contact__r.Search_Display_Name__c, Organization__r.Search_Display_Name__c, 
                                      Organization__c, Organization__r.Name 
                               FROM Donor__c 
                               WHERE Pledge__c IN :pledgeIds
                               ORDER BY Organization__r.Name, Contact__r.LastName, Contact__r.FirstName ASC]) {

            String donorName = d.Contact__c != null ? d.Contact__r.Search_Display_Name__c : d.Organization__r.Search_Display_Name__c;
                Pledge__c pledgeToUpdate = pledgesMap.containsKey(d.Pledge__c) 
                                           ? pledgesMap.get(d.Pledge__c) 
                                           : new Pledge__c (Id = d.Pledge__c, Soft_Credit_s__c = null);
                if(d.Credit_Type__c == 'Donor - Primary') {
                    pledgeToUpdate.Pledge_Name__c = donorName;
                } else {
                    pledgeToUpdate.Soft_Credit_s__c = pledgeToUpdate.Soft_Credit_s__c == null 
                                                      ? donorName 
                                                      : pledgeToUpdate.Soft_Credit_s__c + ', ' + donorName;
                }
                pledgesMap.put(pledgeToUpdate.Id, pledgeToUpdate);
                donorsToUpdate.add(d);
            }
            if(!donorsToUpdate.isEmpty()) {
                for(Donor__c d : donorsToUpdate) {
                    if(pledgesMap.containsKey(d.Pledge__c)) {
                        d.Soft_Credits_s__c = pledgesMap.get(d.Pledge__c).Soft_Credit_s__c;
                    } else {
                        d.Soft_Credits_s__c = null;
                    }
                }
            }
            if(!pledgesMap.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(pledgesMap.values(), false, ERR_UPDATE_PLEDGES);
            }
            if(!donorsToUpdate.isEmpty()) {
                TriggerFactory.setBypass('DonorTriggerHandler');
                BBApps_Crud.doUpdateWithHandling(donorsToUpdate, false, ERR_UPDATE_PLEDGES);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_UPDATE_PLEDGES);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    public static void updateCoFunderForDonors(Set<Id> donorIds, Set<Id> deletedDonorIds) {
        System.debug('#########updateCoFunderForDonors-donorIds: ' + donorIds);
        System.debug('#########updateCoFunderForDonors-deletedDonorIds: ' + deletedDonorIds);
        try {
            List<Donor__c> donors = [
                SELECT Id, Organization__c, Contact__c 
                FROM Donor__c 
                WHERE Id IN :donorIds OR 
                      Id IN :deletedDonorIds];
            Set<Id> organizationIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            System.debug('#########updateCoFunderForDonors-donors: ' + donors);
            for(Donor__c donor : donors) {
                if(donor.Organization__c != null) organizationIds.add(donor.Organization__c);
                if(donor.Contact__c != null) contactIds.add(donor.Contact__c);
            }
            
            List<Donor__c> allRelatedDonors = [
                SELECT Id, Credit_Type__c, Organization__c, Contact__c, Pledge__c, Anonymous__c, Pledge__r.Exclude_from_Donor_memo__c,
                       Pledge__r.Report_Amount_USD__c, Pledge__r.Status__c, Pledge__r.Pledge_Start_Date__c, Pledge__r.Pledge_End_Date__c,
                       Pledge__r.Fundraising_Effort__c, Pledge__r.Fundraising_Effort__r.Name,
                       Pledge__r.Fundraising_Effort__r.Political__c, Pledge__r.Fundraising_Effort__r.Personal__c
                FROM Donor__c
                WHERE (Organization__c IN :organizationIds OR 
                       Contact__c IN :contactIds) AND
                      Id NOT IN :deletedDonorIds
            ];
            Map<Id, List<Donor__c>> orgToDonors = new Map<Id, List<Donor__c>>();
            Map<Id, List<Donor__c>> contactToDonors = new Map<Id, List<Donor__c>>();
            System.debug('#########updateCoFunderForDonors-allRelatedDonors: ' + allRelatedDonors);
            for(Donor__c donor : allRelatedDonors) {
                if(donor.Organization__c != null) {
                    if(!orgToDonors.containsKey(donor.Organization__c)) {
                        orgToDonors.put(donor.Organization__c, new List<Donor__c>());
                    }
                    orgToDonors.get(donor.Organization__c).add(donor);
                }
                if(donor.Contact__c != null) {
                    if(!contactToDonors.containsKey(donor.Contact__c)) {
                        contactToDonors.put(donor.Contact__c, new List<Donor__c>());
                    }
                    contactToDonors.get(donor.Contact__c).add(donor);
                }
            }
            Map<Id, Account> existingOrgs = organizationIds.isEmpty() ? new Map<Id, Account>() :
                new Map<Id, Account>([SELECT Id, Co_funder__c, Programmatic_Co_Funding_Notes__c FROM Account WHERE Id IN :organizationIds]);

            Map<Id, Contact> existingContacts = contactIds.isEmpty() ? new Map<Id, Contact>() :
                new Map<Id, Contact>([SELECT Id, Co_funder__c, Programmatic_Co_Funding_Notes__c FROM Contact WHERE Id IN :contactIds]);

            List<Account> orgsToUpdate = new List<Account>();
            System.debug('#########updateCoFunderForDonors-organizationIds: ' + organizationIds);
            for(Id orgId : organizationIds) {
                List<Donor__c> qualifiedDonors = getQualifiedDonors(orgToDonors.get(orgId));
                System.debug('#########updateCoFunderForDonors-qualifiedDonors: ' + qualifiedDonors);
                Boolean coFunderValue = !qualifiedDonors.isEmpty();
                String notesValue = buildCoFundingNotes(qualifiedDonors);
                if(existingOrgs.containsKey(orgId) && 
                   (existingOrgs.get(orgId).Co_funder__c != coFunderValue ||
                    existingOrgs.get(orgId).Programmatic_Co_Funding_Notes__c != notesValue)) {
                    orgsToUpdate.add(new Account(Id = orgId, Co_funder__c = coFunderValue, Programmatic_Co_Funding_Notes__c = notesValue));
                }
            }
            List<Contact> contactsToUpdate = new List<Contact>();
            for(Id contactId : contactIds) {
                List<Donor__c> qualifiedDonors = getQualifiedDonors(contactToDonors.get(contactId));
                Boolean coFunderValue = !qualifiedDonors.isEmpty();
                String notesValue = buildCoFundingNotes(qualifiedDonors);
                if(existingContacts.containsKey(contactId) && 
                   (existingContacts.get(contactId).Co_funder__c != coFunderValue ||
                    existingContacts.get(contactId).Programmatic_Co_Funding_Notes__c != notesValue)) {
                    contactsToUpdate.add(new Contact(Id = contactId, Co_funder__c = coFunderValue, Programmatic_Co_Funding_Notes__c = notesValue));
                }
            }
            if(!orgsToUpdate.isEmpty()) {
                TriggerFactory.setBypass('AccountTriggerHandler');
                BBApps_Crud.doUpdateWithHandling(orgsToUpdate, false, ERR_UPDATE_COFUNDER);
                TriggerFactory.removeBypass('AccountTriggerHandler');
            }
            if(!contactsToUpdate.isEmpty()) {
                TriggerFactory.setBypass('ContactTriggerHandler');
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.AllowSave = true;
                BBApps_Crud.doUpdateWithHandling(contactsToUpdate, dml, ERR_UPDATE_COFUNDER);
                TriggerFactory.removeBypass('ContactTriggerHandler');
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_UPDATE_COFUNDER);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    private static List<Donor__c> getQualifiedDonors(List<Donor__c> donorsForParent) {
        List<Donor__c> qualified = new List<Donor__c>();
        if(donorsForParent == null) return qualified;
        for(Donor__c donor : donorsForParent) {
            if(donor.Credit_Type__c == 'Donor - Primary' &&
               donor.Pledge__r.Fundraising_Effort__c != null &&
               donor.Pledge__r.Status__c == 'Pledged' &&
               !donor.Pledge__r.Exclude_from_Donor_memo__c &&
               !donor.Pledge__r.Fundraising_Effort__r.Political__c &&
               !donor.Pledge__r.Fundraising_Effort__r.Personal__c) {
                qualified.add(donor);
            }
        }
        return qualified;
    }

    private static String buildCoFundingNotes(List<Donor__c> qualifiedDonors) {
        System.debug('#########buildCoFundingNotes-qualifiedDonors: ' + qualifiedDonors);
        if(qualifiedDonors == null || qualifiedDonors.isEmpty()) return null;
        Map<Id, String> projectNames = new Map<Id, String>();
        Map<Id, Double> projectTotals = new Map<Id, Double>();
        Map<Id, Set<Integer>> projectYears = new Map<Id, Set<Integer>>();
        Map<Id, Double> projectAnonTotals = new Map<Id, Double>();
        Map<Id, Set<Integer>> projectAnonYears = new Map<Id, Set<Integer>>();
        Map<Id, Double> projectNonAnonTotals = new Map<Id, Double>();
        Map<Id, Set<Integer>> projectNonAnonYears = new Map<Id, Set<Integer>>();
        Double grandTotal = 0;
        for(Donor__c donor : qualifiedDonors) {
            Id projectId = donor.Pledge__r.Fundraising_Effort__c;
            Double amount = 0;
            if(donor.Pledge__r.Report_Amount_USD__c != null) {
                amount = donor.Pledge__r.Report_Amount_USD__c.doubleValue();
            }
            if(!projectTotals.containsKey(projectId)) {
                projectNames.put(projectId, donor.Pledge__r.Fundraising_Effort__r.Name);
                projectTotals.put(projectId, 0.0);
                projectYears.put(projectId, new Set<Integer>());
                projectAnonTotals.put(projectId, 0.0);
                projectAnonYears.put(projectId, new Set<Integer>());
                projectNonAnonTotals.put(projectId, 0.0);
                projectNonAnonYears.put(projectId, new Set<Integer>());
            }
            projectTotals.put(projectId, projectTotals.get(projectId) + amount);
            grandTotal += amount;
            addYears(projectYears.get(projectId), donor);
            System.debug('#########buildCoFundingNotes-addYears: ' + projectYears.get(projectId));
            if(donor.Anonymous__c) {
                projectAnonTotals.put(projectId, projectAnonTotals.get(projectId) + amount);
                addYears(projectAnonYears.get(projectId), donor);
            } else {
                projectNonAnonTotals.put(projectId, projectNonAnonTotals.get(projectId) + amount);
                addYears(projectNonAnonYears.get(projectId), donor);
            }
        }
        List<ProjectLine> lines = new List<ProjectLine>();
        for(Id projectId : projectTotals.keySet()) {
            lines.add(new ProjectLine(projectId, projectNames.get(projectId), projectTotals.get(projectId)));
        }
        lines.sort();
        List<String> output = new List<String>();
        output.add('$' + RoundCurrency.getRoundAmount(grandTotal).formattedAmount + ' for:');
        for(ProjectLine line : lines) {
            Id projectId = line.projectId;
            output.add(projectNames.get(projectId) + ' ($' + RoundCurrency.getRoundAmount(projectTotals.get(projectId)).formattedAmount +
                       ') (' + formatYears(projectYears.get(projectId)) + ')');
            if(projectAnonTotals.get(projectId) > 0) {
                List<SubLine> subs = new List<SubLine>();
                if(projectNonAnonTotals.get(projectId) > 0) {
                    subs.add(new SubLine(projectNonAnonTotals.get(projectId), projectNonAnonYears.get(projectId), false));
                }
                subs.add(new SubLine(projectAnonTotals.get(projectId), projectAnonYears.get(projectId), true));
                subs.sort();
                for(SubLine sub : subs) {
                    output.add('   - $' + RoundCurrency.getRoundAmount(sub.amount).formattedAmount + ' (' + formatYears(sub.years) + ')' +
                               (sub.isAnonymous ? ' (Anonymous)' : ''));
                }
            }
        }
        System.debug('#########buildCoFundingNotes-string: ' + String.join(output, '\n'));
        return String.join(output, '\n');
    }

    private static void addYears(Set<Integer> years, Donor__c donor) {
         System.debug('#########addYears-years: ' + years);
          System.debug('#########addYears-donor: ' + donor);
          System.debug('#########addYears-donor.Pledge__r.Pledge_Start_Date__c: ' + donor.Pledge__r.Pledge_Start_Date__c);
          System.debug('#########addYears-donor.Pledge__r.Pledge_End_Date__c: ' + donor.Pledge__r.Pledge_End_Date__c);
        if(donor.Pledge__r.Pledge_Start_Date__c != null) {
            years.add(donor.Pledge__r.Pledge_Start_Date__c.year());
        }
        if(donor.Pledge__r.Pledge_End_Date__c != null) {
            years.add(donor.Pledge__r.Pledge_End_Date__c.year());
        }
    }

    private static String formatYears(Set<Integer> years) {
        if(years.isEmpty()) return '';
        List<Integer> yearList = new List<Integer>(years);
        yearList.sort();
        if(yearList.size() > 1) {
            return yearList.get(0) + '-' + yearList.get(yearList.size() - 1);
        }
        return String.valueOf(yearList.get(0));
    }

    private class ProjectLine implements Comparable {
        public Id projectId;
        public String name;
        public Double amount;
        public ProjectLine(Id projectId, String name, Double amount) {
            this.projectId = projectId;
            this.name = name;
            this.amount = amount;
        }
        public Integer compareTo(Object compareTo) {
            ProjectLine other = (ProjectLine)compareTo;
            if(amount > other.amount) return -1;
            if(amount < other.amount) return 1;
            if(name == other.name) return 0;
            if(name == null) return -1;
            if(other.name == null) return 1;
            return name > other.name ? 1 : -1;
        }
    }

    private class SubLine implements Comparable {
        public Double amount;
        public Set<Integer> years;
        public Boolean isAnonymous;
        public SubLine(Double amount, Set<Integer> years, Boolean isAnonymous) {
            this.amount = amount;
            this.years = years;
            this.isAnonymous = isAnonymous;
        }
        public Integer compareTo(Object compareTo) {
            SubLine other = (SubLine)compareTo;
            if(amount > other.amount) return -1;
            if(amount < other.amount) return 1;
            if(isAnonymous == other.isAnonymous) return 0;
            return isAnonymous ? 1 : -1;
        }
    }
}