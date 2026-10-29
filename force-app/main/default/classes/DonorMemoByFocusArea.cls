public without sharing class DonorMemoByFocusArea {
    
    public List<FocusArea> focusAreasWithDonors = new List<FocusArea> ();
    
    public DonorMemoByFocusArea(List<Donor__c> donations) {
        Map<String, List<Donor__c>> donationsByFocusArea = new Map<String, List<Donor__c>> ();
        for(Donor__c donor : donations) {
            List<Donor__c> tempDonors = new List<Donor__c> ();
            if(donationsByFocusArea.get(donor.Pledge__r.Fundraising_Effort__r.FC_Focus_Area__c) != null) {
                tempDonors = donationsByFocusArea.get(donor.Pledge__r.Fundraising_Effort__r.FC_Focus_Area__c);
                tempDonors.add(donor);
                donationsByFocusArea.put(donor.Pledge__r.Fundraising_Effort__r.FC_Focus_Area__c, tempDonors);
            } else {
                tempDonors.add(donor);
                donationsByFocusArea.put(donor.Pledge__r.Fundraising_Effort__r.FC_Focus_Area__c, tempDonors);
            }
        }
        for(String focusArea: donationsByFocusArea.keySet()) {
            focusAreasWithDonors.add(new FocusArea(focusArea, donationsByFocusArea.get(focusArea)));
        }
        focusAreasWithDonors.sort();
    }
    
    public class FocusArea implements comparable {
        public String focusArea;
        public List<Donor> donors = new List<Donor> ();
        
        public FocusArea(String focusArea, List<Donor__c> donations) {
            this.focusArea = focusArea;
            processDonations(donations);
        }

        private void processDonations(List<Donor__c> donations) {
            Map<String, List<Donor__c>> donorKeyDonationsMap = new Map<String, List<Donor__c>>();
            for(Donor__c donor : donations) {
                String key = DonorMemoService.getDonorGroupingKey(donor);
                List<Donor__c> donorsList = donorKeyDonationsMap.get(key) != null ? donorKeyDonationsMap.get(key) : new List<Donor__c>();
                donorsList.add(donor);
                donorKeyDonationsMap.put(key, donorsList);
            }
            for(String key: donorKeyDonationsMap.keySet()) {
                List<Donor__c> grouped = donorKeyDonationsMap.get(key);
                Id representativeId = grouped[0].Contact__c != null ? grouped[0].Contact__c : grouped[0].Organization__c;
                Donor d = new Donor(representativeId, grouped, false);
                String ovr = DonorMemoService.getDonorOverrideName(grouped[0]);
                if (ovr != null) { d.donorName = ovr; d.donorNameToSort = ovr; }
                donors.add(d);
            }
            donors.sort();
        }
        
        public Integer compareTo(Object compareTo) {
            FocusArea f = (FocusArea)compareTo;
            if(focusArea == f.focusArea) return 0;
            if(focusArea > f.focusArea) return 1;
            return -1;
        }
    }
}