/**
* Author : Ravi
* Description : Helper class to retrieve initial filters data for Donor Memo.
* Test : DonorMemoHelper_Test
**/
global with sharing class DonorMemoHelper {
    public static Boolean isPDF = false;
    
    @AuraEnabled(cacheable=true) 
    public static FiltersData getFiltersData () {
        return new FiltersData ();
    }
    

    public static DonorMemoService.DonorMemo getMemo(DonorMemoService.SelectedFilters selectedFilters) {
		DonorMemoService service = new DonorMemoService (selectedFilters);
        return service.memo;
    }
    
    public with sharing class FiltersData {
        @AuraEnabled public List<Fundraising_Project__c> projects = new List<Fundraising_Project__c> ();
        @AuraEnabled public List<Contact> contacts = new List<Contact> ();
        @AuraEnabled public List<Account> organizations = new List<Account> ();
        
        public FiltersData () {
            projects = [SELECT Id, Name FROM Fundraising_Project__c ORDER BY Name ASC];
            getDonorFiltersData ();
        }
        
        private void getDonorFiltersData () {
            contacts = [
                SELECT Id, FirstName, LastName, Preferred_First_Name__c, Preferred_FirstName_LastName__c, Name, 
                       Restricted__c, Restricted_Name__c
                FROM Contact 
                WHERE Id IN (
                    SELECT Contact__c 
                    FROM Donor__c 
                    WHERE Credit_Type__c = 'Donor - Primary' 
                      AND Pledge__r.Fundraising_Effort__c = :projects
                      AND Pledge__r.Exclude_FROM_Donor_memo__c = false
                      AND Pledge__r.Status__c NOT IN ('Prospect', 'Cancelled')
                      AND Pledge__r.Report_Amount_USD__c != null
                ) 
                Order By Name ASC LIMIT 10000
            ];
            organizations = [
                SELECT Id, Name, AKA__c, Restricted__c, Restricted_Org_Name__c 
                FROM Account 
                WHERE Id IN (
                    SELECT Organization__c 
                    FROM Donor__c 
                    WHERE Credit_Type__c = 'Donor - Primary' 
                      AND Pledge__r.Fundraising_Effort__c = :projects
                      AND Pledge__r.Exclude_FROM_Donor_memo__c = false
                      AND Pledge__r.Status__c NOT IN ('Prospect', 'Cancelled')
                      AND Pledge__r.Report_Amount_USD__c != null
                ) 
                Order By Name ASC LIMIT 10000
            ];
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Campaign> searchDonorLists(String searchKey, List<Id> excludedIds) {
        if(String.isBlank(searchKey)) {
            return new List<Campaign>();
        }
        String likeExpr = '%' + searchKey + '%';
        List<Campaign> result = [
            SELECT Id, Name
            FROM Campaign
            WHERE Name LIKE :likeExpr
             AND Id NOT IN :excludedIds
            ORDER BY Name
            LIMIT 200
        ];
        return result;
    }
}