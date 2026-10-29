public without sharing class DonorMemoByProject {
    
    public List<Project> projectsWithDonors = new List<Project> ();
    
    public DonorMemoByProject(List<Donor__c> donations) {
        Map<Id, List<Donor__c>> donationsByProject = new Map<Id, List<Donor__c>> ();
        for(Donor__c donor : donations) {
			List<Donor__c> tempDonors = new List<Donor__c> ();
			if(donationsByProject.get(donor.Pledge__r.Fundraising_Effort__c) != null) {
				tempDonors = donationsByProject.get(donor.Pledge__r.Fundraising_Effort__c);
				tempDonors.add(donor);
				donationsByProject.put(donor.Pledge__r.Fundraising_Effort__c, tempDonors);
			} else {
				tempDonors.add(donor);
				donationsByProject.put(donor.Pledge__r.Fundraising_Effort__c, tempDonors);
			}
		}
        for(Id projectId : donationsByProject.keySet()) {
            Project p = new Project(projectId, donationsByProject.get(projectId));
            if(!p.donors.isEmpty()) projectsWithDonors.add(p);
		}
        projectsWithDonors.sort();
    }
	
    public class Project implements Comparable {
        public String projectName;
        public List<Donor> donors = new List<Donor>();
        public Project(Id projectId, List<Donor__c> donations) {
            projectName = donations[0].Pledge__r.Fundraising_Effort__r.Name;
            Map<String, List<Donor__c>> donorKeyDonationsMap = new Map<String, List<Donor__c>>();
            for(Donor__c donor : donations) {
                String key = DonorMemoService.getDonorGroupingKey(donor);
                List<Donor__c> donorsList = donorKeyDonationsMap.get(key) != null ? donorKeyDonationsMap.get(key) : new List<Donor__c>();
                donorsList.add(donor);
                donorKeyDonationsMap.put(key, donorsList);
            }
            for(Id ignored : new List<Id>()) {}
            for(String key : donorKeyDonationsMap.keySet()) {
                List<Donor__c> grouped = donorKeyDonationsMap.get(key);
                Id representativeId = grouped[0].Contact__c != null ? grouped[0].Contact__c : grouped[0].Organization__c;
                Donor d = new Donor(representativeId, grouped);
                String ovr = DonorMemoService.getDonorOverrideName(grouped[0]);
                if (ovr != null) { d.donorName = ovr; d.donorNameToSort = ovr; }
                donors.add(d);
            }
            donors.sort();
        }
        
        public Integer compareTo(Object compareTo) {
            Project pro = (Project)compareTo;
            if(projectName == pro.projectName) return 0;
            if(projectName > pro.projectName) return 1;
            return -1;
        }
    }
    
    public class Donor implements Comparable {
        public String donorName;
        public String donorNameToSort;
        public Double totalAmount;
        public String timeFrame;
        public Boolean anonymous = false;
        public Double anonAmount = 0;
        public Double nonAnonAmount = 0;
        public String anonTimeFrame;
        public String nonAnonTimeFrame;

        public Donor(Id donorId, List<Donor__c> donations) {
            Set<Integer> datesSet = new Set<Integer>();
            Set<Integer> anonDates = new Set<Integer>();
            Set<Integer> nonAnonDates = new Set<Integer>();
            totalAmount = 0;
            Double anonAmt = 0;
            Double nonAnonAmt = 0;
            DonorMemoUtility.DonorName dName = new DonorMemoUtility.DonorName(donations[0]);
            donorName = dName.donorName;
            donorNameToSort = dName.donorNameToSort;
            for(Donor__c donation: donations) {
                Double repAmt = donation.Pledge__r.Report_Amount_USD__c;
                totalAmount += repAmt;
                Integer startYear = donation.Pledge__r.Pledge_Start_Date__c.year();
                datesSet.add(startYear);
                Integer endYear = null;
                if(donation.Pledge__r.Pledge_End_Date__c != null) {
                    endYear = donation.Pledge__r.Pledge_End_Date__c.year();
                    datesSet.add(endYear);
                }
                if(donation.Anonymous__c) {
                    this.anonymous = true;
                    anonAmt += repAmt;
                    anonDates.add(startYear);
                    if(endYear != null) anonDates.add(endYear);
                } else {
                    nonAnonAmt += repAmt;
                    nonAnonDates.add(startYear);
                    if(endYear != null) nonAnonDates.add(endYear);
                }
            }
            timeFrame = formatTimeFrame(datesSet);
            anonTimeFrame = formatTimeFrame(anonDates);
            nonAnonTimeFrame = formatTimeFrame(nonAnonDates);
            totalAmount = Math.roundToLong(totalAmount);
            anonAmount = Math.roundToLong(anonAmt);
            nonAnonAmount = Math.roundToLong(nonAnonAmt);
        }

        private String formatTimeFrame(Set<Integer> yearSet) {
            if(yearSet == null || yearSet.isEmpty()) return '';
            List<Integer> yrs = new List<Integer>();
            yrs.addAll(yearSet);
            yrs.sort();
            if(yrs.size() > 1) return yrs.get(0) + '-' + yrs.get(yrs.size()-1);
            return String.valueOf(yrs.get(0));
        }

        public Integer compareTo(Object compareTo) {
            Donor d = (Donor)compareTo;
            if (totalAmount > d.totalAmount) return -1;
            else if (totalAmount < d.totalAmount) return 1;
            else {
                if(donorNameToSort > d.donorNameToSort) return 1;
                else if (donorNameToSort < d.donorNameToSort) return -1;
                return 0;
            }
        }
    }
}