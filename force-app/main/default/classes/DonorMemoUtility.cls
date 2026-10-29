public class DonorMemoUtility {

    private static final Boolean HAS_PRIVATE_NAME_ACCESS = FeatureManagement.checkPermission('Private_Name_Fields');

    public class DonorName {
        public String donorName;
        public String donorNameToSort;

        public DonorName(Donor__c donorRecord) {
            String overrideName = DonorMemoService.getDonorOverrideName(donorRecord);
            if (isHiddenDonor(donorRecord)) {
                donorName = '#';
                donorNameToSort = '#';
            } else if (overrideName != null) {
                donorName = overrideName;
                donorNameToSort = overrideName;
            } else if (donorRecord.Contact__c != null) {
                Boolean isRestricted = donorRecord.Contact__r.Restricted__c == true;
                donorName = isRestricted ? donorRecord.Contact__r.Restricted_Name__c : donorRecord.Contact__r.Name;
                donorNameToSort = isRestricted ? donorRecord.Contact__r.RestrictedLastName__c : donorRecord.Contact__r.LastName;
            } else {
                Boolean isRestricted = donorRecord.Organization__r.Restricted__c == true;
                donorName = isRestricted ? donorRecord.Organization__r.Restricted_Org_Name__c : donorRecord.Organization__r.Name;
                donorNameToSort = donorName;
            }
        }
    }

    public static Boolean isHiddenDonor(Donor__c d) {
        Boolean isRestricted = d.Contact__c != null ? d.Contact__r.Restricted__c : d.Organization__r.Restricted__c;
        return isRestricted == true && !HAS_PRIVATE_NAME_ACCESS;
    }
}