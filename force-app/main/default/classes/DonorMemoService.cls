/**
* Author : Ravi
* Description : Service class to retrieve and process the data needed for Donor Memo.
* Test : DonorMemosRetrieveRest_Test, DonorMemoReportController_Test
**/

global without sharing class DonorMemoService {
    public static SelectedFilters selectedFilters;
    public DonorMemo memo;

    global DonorMemoService(SelectedFilters filters) {
        selectedFilters = filters;
        getMemo();
    }

    private void getMemo() {
        try {
            memo = new DonorMemo();
            memo.selectedFilters = selectedFilters;
            memo.coverPageSection = new PageSection();
            memo.mainPageSection = new PageSection();

            if(!memo.selectedFilters.isPDF) {
                List<Donor__c> allDonors = queryDonors(false);
                List<Donor__c> donorsWithMinAmount = new List<Donor__c>();

                donorsWithMinAmount = validateMinimumDonationAmount(allDonors);

                if(!donorsWithMinAmount.isEmpty()) {
                    formatDonors(donorsWithMinAmount, false);
                }
            }

            if(selectedFilters.includeCoverPage) {
                List<Donor__c> coverPageDonors = queryDonors(true);
                if(!coverPageDonors.isEmpty()) {
                    formatDonors(coverPageDonors, true);
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields('DONORMEMO_GETMEMO_FAILED');
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    private List<Donor__c> validateMinimumDonationAmount(List<Donor__c> donors) {
        List<Donor__c> donorsWithMinAmount = new List<Donor__c>();
        Map<Id, Double> donorIdAmountMap = new Map<Id, Double>();
        for(Donor__c d: donors) {
            Id donorId = d.Contact__c != null ? d.Contact__c : d.Organization__c;
            Double totalAmount = 0;
            if(donorIdAmountMap.get(donorId) != null) {
                totalAmount = donorIdAmountMap.get(donorId);
            }

            totalAmount += d.Pledge__r.Report_Amount_USD__c;

            if((Double)Math.roundToLong(totalAmount) >= selectedFilters.minDonorAmount) {
                donorsWithMinAmount.add(d);
            }
        }

        return donorsWithMinAmount;
    }

    private void formatDonors(List<Donor__c> donorsToFormat, Boolean forCoverPage) {
        PageSection section = memo.mainPageSection;

        if(forCoverPage) {
            section = memo.coverPageSection;
            section.donors = getDonors(donorsToFormat, forCoverPage);

            if (!section.donors.isEmpty()) {
                section.hasData = true;

                Decimal rawTotal = 0;
                for (Donor d : section.donors) {
                    rawTotal += d.amountInteger;
            	}

                RoundCurrency.RoundAmount ra = RoundCurrency.getRoundAmount((Double)rawTotal);
                section.totalAmount = ra.formattedAmount;
            }
            return;
        }

        if(selectedFilters.sortBy == 'Donor') {
            section.donors = getDonors(donorsToFormat, forCoverPage);
        }

        if(selectedFilters.sortBy == 'Focus Area') {
            section.focusAreasWithDonors = getFocusAreasWithDonors(donorsToFormat);
        }

        if(selectedFilters.sortBy == 'Project') {
            section.projectsWithDonors = getProjectsWithDonors(donorsToFormat);
        }
    }

    private List<Donor> getDonors(List<Donor__c> donorsData, Boolean forCoverPage) {
        List<Donor> allDonors = new List<Donor>();
        Map<String, List<Donor__c>> donorKeyDonationsMap = new Map<String, List<Donor__c>>();
        for(Donor__c donor: donorsData) {
            String key = getDonorGroupingKey(donor);
            List<Donor__c> donorsList = donorKeyDonationsMap.get(key) != null ? donorKeyDonationsMap.get(key) : new List<Donor__c>();
            donorsList.add(donor);
            donorKeyDonationsMap.put(key, donorsList);
        }
        if(!donorKeyDonationsMap.isEmpty()) {
            for(String key : donorKeyDonationsMap.keySet()) {
                List<Donor__c> grouped = donorKeyDonationsMap.get(key);
                Id representativeId = grouped[0].Contact__c != null ? grouped[0].Contact__c : grouped[0].Organization__c;
                Donor d = new Donor(representativeId, grouped, forCoverPage);
                String ovr = getDonorOverrideName(grouped[0]);
                if (ovr != null) { d.donorName = ovr; d.donorNameToSort = ovr; }
                if((DonorMemoService.selectedFilters.isPdf && d.amountInteger >= 10000) || !DonorMemoService.selectedFilters.isPdf) {
                    allDonors.add(d);
                }
            }
        }
        allDonors.sort();
        return allDonors;
    }

    private List<DonorMemoByFocusArea.FocusArea> getFocusAreasWithDonors(List<Donor__c> donorsData) {
        List<DonorMemoByFocusArea.FocusArea> focusAreas = new List<DonorMemoByFocusArea.FocusArea>();
        if(!donorsData.isEmpty()) {
            DonorMemoByFocusArea memoByFocusArea = new DonorMemoByFocusArea(donorsData);
            focusAreas = memoByFocusArea.focusAreasWithDonors;
        }

        return focusAreas;
    }

    private List<DonorMemoByProject.Project> getProjectsWithDonors(List<Donor__c> donorsData) {
        List<DonorMemoByProject.Project> projects = new List<DonorMemoByProject.Project>();

        if(!donorsData.isEmpty()) {
            DonorMemoByProject memoByProject = new DonorMemoByProject(donorsData);
            projects = memoByProject.projectsWithDonors;
        }

        return projects;
    }

    private List<Donor__c> filterCoverPageDonors(List<Donor__c> allDonors) {
        List<Donor__c> filteredDonors = new List<Donor__c>();

        for(Donor__c d: allDonors) {
            if(d.Pledge__r.Pledge_Start_Date__c > System.today().addDays(-30)) {
                filteredDonors.add(d);
            }
        }

        return filteredDonors;
    }

    public static List<Donor__c> queryDonors(Boolean forCoverPage) {
        List<String> focusAreas = new List<String>();

        if(selectedFilters.selectedFocusAreas != null && selectedFilters.selectedFocusAreas != '') {
            selectedFilters.selectedFocusAreas = selectedFilters.selectedFocusAreas.replace('Founders','Founder\'s');
        	focusAreas = selectedFilters.selectedFocusAreas.split(',');
        }

        List<Id> contactIds = new List<Id>();

        if(selectedFilters.selectedContacts != null && selectedFilters.selectedContacts != '') {
            contactIds = selectedFilters.selectedContacts.split(',');
        }

        List<Id> orgIds = new List<Id>();

        if(selectedFilters.selectedOrganizations != null && selectedFilters.selectedOrganizations != '') {
            orgIds = selectedFilters.selectedOrganizations.split(',');
        }

        List<Id> listIds = new List<Id>();
        if (selectedFilters.selectedLists != null && selectedFilters.selectedLists != '') {
            listIds = selectedFilters.selectedLists.split(',');
        }

        if (!listIds.isEmpty()) {
            processListMembers(contactIds, orgIds);

                }
        
        List<Id> projectIds = new List<Id>();

        if(selectedFilters.selectedProjects != null && selectedFilters.selectedProjects != '') {
            projectIds = selectedFilters.selectedProjects.split(',');
        }

        String query =  'SELECT Id, Amount__c, Pledge__c, Anonymous__c, Contact__c, Pledge__r.Report_Amount_USD__c, ' +
                               'Pledge__r.Pledge_Amount__c, Pledge__r.Fundraising_Effort__r.Name, Pledge__r.Fundraising_Effort__c, ' +
                               'Organization__c, Pledge__r.Pledge_Start_Date__c, Contact__r.Name, Contact__r.LastName, Organization__r.Name,' +
            'Contact__r.Restricted__c,Contact__r.Restricted_Name__c,Contact__r.RestrictedLastName__c,Contact__r.Donor_Memo_Override_Name__c, Contact__r.Deceased__c, Organization__r.Donor_Memo_Override_Name__c,' +
            	               'Pledge__r.Fundraising_Effort__r.FC_Focus_Area__c, Organization__r.Restricted__c, Organization__r.Restricted_Org_Name__c,' +
                               'Pledge__r.Pledge_End_Date__c, Pledge__r.Fundraising_Effort__r.FC_Initiative__c ' +
                        'FROM Donor__c ' +
            	        'WHERE Credit_Type__c = \'Donor - Primary\' ' +
                              'AND Pledge__r.Status__c = \'Pledged\' ' +
                              'AND Pledge__r.Exclude_from_Donor_memo__c = false ' +
                              'AND Pledge__r.Report_Amount_USD__c != null ';

		if(!forCoverPage) {
            if(selectedFilters.startDate != null && selectedFilters.endDate != null && !selectedFilters.getActiveDonors) {

                Date start = Date.valueOf(selectedFilters.startDate);
                Date endD = Date.valueOf(selectedFilters.endDate);

                query += 'AND Pledge__r.Pledge_Start_Date__c >=: start ';
                query += 'AND Pledge__r.Pledge_Start_Date__c <=: endD ';
            }

            if(selectedFilters.getActiveDonors) {
                Date firstDayOfYear = Date.newInstance(System.today().year(), 1, 1);
                query += 'AND ( ' +
                            'Pledge__r.Pledge_Start_Date__c >= :firstDayOfYear ' +
                            'OR Pledge__r.Pledge_End_Date__c >= :firstDayOfYear ' +
                            'OR Pledge__r.Pledge_End_Date__c = null ' +
                         ') ';
            }

            if(!focusAreas.isEmpty()) {
                query += 'AND Pledge__r.Fundraising_Effort__r.FC_Focus_Area__c IN: focusAreas ';
            }

            if(!projectIds.isEmpty()) {
                query += 'AND Pledge__r.Fundraising_Effort__c IN: projectIds ';
            }

            query = addContactsAndOrgsFilter(contactIds, orgIds, query);
		} else {
			query += 'AND Pledge__r.Pledge_Start_Date__c = LAST_MONTH ';
		}

		query += 'ORDER BY Pledge__r.Report_Amount_USD__c DESC ';
		query += 'LIMIT 50000';
        List<Donor__c> donors = Database.query(query);
        return donors;
    }

    private static String addContactsAndOrgsFilter(List<Id> contactIds, List<Id> orgIds, String query) {
        if(!contactIds.isEmpty() && !orgIds.isEmpty()) {
            query += 'AND(Contact__c IN: contactIds OR Organization__c IN: orgIds) ';
            return query;
        }

        if(!contactIds.isEmpty()) {
            query += 'AND Contact__c IN: contactIds ';
            return query;
        }

        if(!orgIds.isEmpty()) {
            query += 'AND Organization__c IN: orgIds ';
            return query;
        }

        return query;
    }

    private static void processListMembers(List<Id> contactIds, List<Id> orgIds) {
        List<Id> listIds = new List<Id>();
        if (selectedFilters.selectedLists != null && selectedFilters.selectedLists != '') {
            listIds = selectedFilters.selectedLists.split(',');
        }

        if (listIds.isEmpty()) {
            return;
        }

        Map<Id, Campaign> campaignMap = new Map<Id, Campaign>([
            SELECT Id, RecordType.DeveloperName
            FROM Campaign
            WHERE Id IN :listIds
        ]);

        List<Id> orgListIds = new List<Id>();
        List<Id> contactListIds = new List<Id>();

        for (Id listId : listIds) {

            Campaign c = campaignMap.get(listId);
            if (c != null && c.RecordType.DeveloperName == 'Organization') {


                orgListIds.add(listId);
            } else if (c != null) {
                contactListIds.add(listId);
            }
        }

        if (!orgListIds.isEmpty()) {
            for (ListOrganization__c lo : [
                SELECT Organization__c
                FROM ListOrganization__c
                WHERE List__c IN :orgListIds
                AND Organization__c != null
            ]) {
                if (!orgIds.contains(lo.Organization__c)) {
                    orgIds.add(lo.Organization__c);
                }
            }
        }

        if (!contactListIds.isEmpty()) {
            for (CampaignMember cm : [
                SELECT ContactId
                FROM CampaignMember
                WHERE CampaignId IN :contactListIds
                AND ContactId != null
            ]) {
                if (!contactIds.contains(cm.ContactId)) {
                    contactIds.add(cm.ContactId);
                }
            }
        }
    }

    public static String getDonorOverrideName(Donor__c d) {
        if (DonorMemoUtility.isHiddenDonor(d)) return null;
        String overrideName;
        if(d.Contact__c != null) {
            overrideName = d.Contact__r.Donor_Memo_Override_Name__c;
        } else if (d.Organization__c != null) {
            overrideName = d.Organization__r.Donor_Memo_Override_Name__c;
        }
        return String.isNotBlank(overrideName) ? overrideName.trim() : null;
    }

    public static String getDonorGroupingKey(Donor__c d) {
        String overrideName = getDonorOverrideName(d);
        if (overrideName != null) return overrideName;
        return d.Contact__c != null ? String.valueOf(d.Contact__c) : String.valueOf(d.Organization__c);
    }

    global class DonorMemo {
        public PageSection coverPageSection;
        public PageSection mainPageSection;
        public SelectedFilters selectedFilters;
        public String coverPageTimeFrame;

        public DonorMemo() {
            coverPageTimeFrame = getLastMonthAndYear();
        }

        private String getLastMonthAndYear() {
            DateTime currentDate = DateTime.now();
            DateTime lastMonth = currentDate.addMonths(-1);

            String monthName = lastMonth.format('MMMM');
            Integer year = lastMonth.year();

            return monthName + ' ' + year;
        }
    }

    global class PageSection {
        public List<Donor> donors;
        public List<DonorMemoByFocusArea.FocusArea> focusAreasWithDonors;
        public List<DonorMemoByProject.Project> projectsWithDonors;
        public Boolean hasData = false;
        public String totalAmount;


        public PageSection() {
            donors = new List<Donor>();
            focusAreasWithDonors = new List<DonorMemoByFocusArea.FocusArea>();
            projectsWithDonors = new List<DonorMemoByProject.Project>();
            hasData = false;
            totalAmount = null;
        }

    }

    global class SelectedFilters {
        public Decimal minDonorAmount = 1;
        public Boolean isPDF = false;
        public Boolean includeCoverPage = false;
        public String sortBy = 'Donor';
        public String selectedFocusAreas;
        public String selectedContacts;
        public String selectedOrganizations;
        public String selectedLists;
        public String selectedProjects;
        public String startDate;
        public String endDate;
        public Boolean getActiveDonors = false;
    }
}