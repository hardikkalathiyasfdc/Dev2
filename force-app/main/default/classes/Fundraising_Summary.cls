/**
* Author : Dilip
* Date   : 04/12/2022
* Description : This is the controller class for Fundraising Summary widget - contactFundSummeryTab
* Test : Fundraising_Summary_Test
*/
public with sharing class Fundraising_Summary {

    private static final String ERR_GET_FUNDRAISING_LIST = 'FUNDRAISING_SUMMARY_GET_LIST_FAILED';
    private static final String ERR_GET_ASK_FUNDRAISING_LIST = 'FUNDRAISING_SUMMARY_GET_ASK_LIST_FAILED';
    private static final String ERR_GET_FUNDRAISING_RECIPIENT = 'FUNDRAISING_SUMMARY_GET_RECIPIENT_FAILED';
    private static final String ERR_GET_RECORD_DETAILS = 'FUNDRAISING_SUMMARY_GET_RECORD_DETAILS_FAILED';
    private static final String MSG_GET_FUNDRAISING_LIST = 'Unable to fetch fundraising list.';
    private static final String MSG_GET_ASK_FUNDRAISING_LIST = 'Unable to fetch asks list.';
    private static final String MSG_GET_FUNDRAISING_RECIPIENT = 'Unable to fetch fundraising recipient data.';
    private static final String MSG_GET_RECORD_DETAILS = 'Unable to fetch record details.';

    @AuraEnabled
    public static List<FundArray> getFundraisingList(Id recordId) {
        try {
            List<FundArray> fundArrayList = new List<FundArray>();
            String objName = recordId.getsobjecttype().getDescribe().getName();
            List<Donor__c> donors = queryDonors(recordId);
            if(!donors.isEmpty()) {
                fundArrayList = processDonors(donors, true);
            }
            return fundArrayList;
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_FUNDRAISING_LIST);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_FUNDRAISING_LIST);
        }
    }

    @AuraEnabled
    public static List<FundArray> getAskFundraisingList(Id recordId) {
        try {
            List<FundArray> fundArrayList = new List<FundArray>();
            List<Donor__c> donors = queryDonors(recordId);
            if(!donors.isEmpty()) {
                fundArrayList = processDonors(donors, false);
            }
            return fundArrayList;
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_ASK_FUNDRAISING_LIST);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_ASK_FUNDRAISING_LIST);
        }
    }

    private static List<Donor__c> queryDonors(Id recordId) {
        String objName = recordId.getsobjecttype().getDescribe().getName();
        List<Donor__c> donors = new List<Donor__c>();
        if('Contact'.equalsIgnoreCase(objName)) {
            donors = [SELECT Id, Pledge__r.Fundraising_Effort__r.Id FROM Donor__c WHERE Contact__c = :recordId WITH SYSTEM_MODE];
        } else {
            donors = [SELECT Id, Pledge__r.Fundraising_Effort__r.Id FROM Donor__c WHERE Organization__c = :recordId WITH SYSTEM_MODE];
        }
        return donors;
    }

    private static List<FundArray> processDonors(List<Donor__c> donors, Boolean isPledged) {
        List<FundArray> fundArrayList = new List<FundArray>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> donorIds = new Set<Id>();
        Map<Id, List<Donor__c>> projectDonorsMap = new Map<Id, List<Donor__c>>();
        for(Donor__c d : donors) {
            projectIds.add(d.Pledge__r.Fundraising_Effort__r.Id);
            donorIds.add(d.Id);
        }
        Map<Id, Fundraising_Project__c> projectsMap;
        if(isPledged) {
            projectsMap = new Map<Id, Fundraising_Project__c>([
                SELECT Id, Name, FC_Focus_Area__c, Focus_Area_Initiative__c, FC_Initiative__c,
                       (SELECT Id, Pledge_Start_Date__c, Report_Amount_USD__c, Anonymous__c, Pledge_End_Date__c, Status__c
                        FROM Pledge__r
                        WHERE Report_Amount_USD__c != null
                          AND Status__c = :Assets.PLEDGE_STATUS_PLEDGED
                          AND Id IN (SELECT Pledge__c FROM Donor__c WHERE Id IN :donorIds))
                FROM Fundraising_Project__c WHERE Id IN :projectIds WITH SYSTEM_MODE
            ]);
        } else {
            projectsMap = new Map<Id, Fundraising_Project__c>([
                SELECT Id, Name, FC_Focus_Area__c, Focus_Area_Initiative__c, FC_Initiative__c,
                       (SELECT Id, Pledge_Start_Date__c, Report_Amount_USD__c, Anonymous__c, Pledge_End_Date__c, Status__c
                        FROM Pledge__r
                        WHERE Report_Amount_USD__c != null
                          AND Status__c != 'Pledged'
                          AND Id IN (SELECT Pledge__c FROM Donor__c WHERE Id IN :donorIds))
                FROM Fundraising_Project__c WHERE Id IN :projectIds WITH SYSTEM_MODE
            ]);
        }
        for(Fundraising_Project__c pr : projectsMap.values()) {
            if(!pr.Pledge__r.isEmpty()) {
                FundArray fa = new FundArray(pr, pr.Pledge__r);
            	fundArrayList.add(fa);
            }
        }
        fundArrayList.sort();
        return fundArrayList;
    }

    public class FundArray implements Comparable {
        @AuraEnabled public String Name {get; set;}
        @AuraEnabled public String Revenue {get; set;}
        @AuraEnabled public String totlAmont {get; set;}
        @AuraEnabled public String startDate {get; set;}
        @AuraEnabled public String FundId {get; set;}
        @AuraEnabled public String Fundr {get; set;}
        @AuraEnabled public String FocusInt {get; set;}
        @AuraEnabled public String InitiaT {get; set;}
        @AuraEnabled public String givingDisplay {get; set;}
        @AuraEnabled public String anonGivingDisplay {get; set;}

        public FundArray(Fundraising_Project__c project, List<Pledge__c> pledges) {
            FundId = project.Id;
			Name = project.name;
			Fundr = project.FC_Focus_Area__c;
			FocusInt = project.Focus_Area_Initiative__c;
			InitiaT = project.FC_Initiative__c;
            processPledges(pledges);
        }

        private void processPledges(List<Pledge__c> pledges) {
            List<Integer> ueayList = new List<Integer>();
			Boolean anonymous = false;
            Decimal amount = 0;
            // Anonymous / public breakout
            Decimal givingAmt = 0;
            Decimal anonAmt = 0;
            Set<Integer> givingYears = new Set<Integer>();
            Set<Integer> anonYears = new Set<Integer>();
            for(Pledge__c pledgeRecord : pledges) {
                amount += pledgeRecord.Report_Amount_USD__c;
                if(pledgeRecord.Anonymous__c) anonymous = true;
                ueayList.add(pledgeRecord.Pledge_Start_Date__c.year());
                if(pledgeRecord.Pledge_End_Date__c != NULL) {
                    ueayList.add(pledgeRecord.Pledge_End_Date__c.year());
                }
                Integer startYr = pledgeRecord.Pledge_Start_Date__c.year();
                Integer endYr = pledgeRecord.Pledge_End_Date__c != null
                                ? pledgeRecord.Pledge_End_Date__c.year()
                                : null;
                if(pledgeRecord.Anonymous__c) {
                    anonAmt += pledgeRecord.Report_Amount_USD__c;
                    anonYears.add(startYr);
                    if(endYr != null) anonYears.add(endYr);
                } else {
                    givingAmt += pledgeRecord.Report_Amount_USD__c;
                    givingYears.add(startYr);
                    if(endYr != null) givingYears.add(endYr);
                }
            }
            ueayList.sort();
            Integer earliestYear = ueayList.get(0);
            Integer latestYear = ueayList.get(ueayList.size() - 1);
            startDate = earliestYear != latestYear ? earliestYear + '-' + latestYear : String.valueOf(earliestYear);


            Integer totalAmount = 0;
            Object totalAmountObject = amount;
            String objType = String.valueOf(totalAmountObject);
            Decimal strToDec = decimal.valueOf(objType);
            strToDec = strToDec.setScale(2);
            totalAmount = totalAmount + strToDec.intValue();
            Revenue = objType;
            totlAmont = totalAmount.format();
            givingDisplay = formatMoneyYears(givingAmt, givingYears);
            anonGivingDisplay = formatMoneyYears(anonAmt, anonYears);
        }

        public Integer compareTo(Object compareTo) {
            FundArray ar = (FundArray)compareTo;
            if(Name > ar.Name) return 1;
            else if(Name < ar.Name) return -1;
            else return 0;




        }
    }

    private static String formatMoneyYears(Decimal amount, Set<Integer> yearSet) {
        if(yearSet == null || yearSet.isEmpty()) return '';
        List<Integer> yrs = new List<Integer>(yearSet);
        yrs.sort();
        String years = yrs.size() > 1
                       ? yrs.get(0) + '-' + yrs.get(yrs.size()-1)
                       : String.valueOf(yrs.get(0));
        Long whole = Math.roundToLong(amount);
        String formatted = Decimal.valueOf(whole).format();
        return '$' + formatted + ' (' + years + ')';
    }

    @AuraEnabled(cacheable=false)
    public static List<FundArray> getFundraisingRecepient(Id recordId) {
        List<FundArray> fundArrayList= new List<FundArray>();
        try {
            AggregateResult[] groupedResults;
            String objName = recordId.getsobjecttype().getDescribe().getName();
            Decimal totalAmount = 0;
            if('Account'.equalsIgnoreCase(objName) || 'Contact'.equalsIgnoreCase(objName)) {
                Map<Id, SObject> projectsMap = new Map<Id, SObject>();
                Map<Id, List<Pledge__c>> projectPledgesMap = new Map<Id, List<Pledge__c>>();
                List<Pledge__c> allPledges;
                if('Contact'.equalsIgnoreCase(objName)) {
                    allPledges = [
                        SELECT Id, Report_Amount_USD__c, Pledge_Start_Date__c, Anonymous__c, Pledge_End_Date__c, Fundraising_Effort__c, Status__c,
                               Fundraising_Effort__r.Name, Fundraising_Effort__r.FC_Focus_Area__c, Fundraising_Effort__r.Focus_Area_Initiative__c,
                               Fundraising_Effort__r.FC_Initiative__c
                        FROM Pledge__c
                        WHERE Recipient_Soft_Credit__c = :recordId
                          AND Report_Amount_USD__c != null
                                                    AND Status__c = :Assets.PLEDGE_STATUS_PLEDGED
                                                WITH USER_MODE
                    ];
                } else {
                    allPledges = [
                        SELECT Id, Report_Amount_USD__c, Pledge_Start_Date__c, Anonymous__c, Pledge_End_Date__c, Fundraising_Effort__c, Status__c,
                               Fundraising_Effort__r.Name, Fundraising_Effort__r.FC_Focus_Area__c, Fundraising_Effort__r.Focus_Area_Initiative__c,
                               Fundraising_Effort__r.FC_Initiative__c
                        FROM Pledge__c
                        WHERE Id IN (SELECT Pledge__c FROM Donor__c WHERE Recipient_Organization_Lookup__c = :recordId)
                          AND Report_Amount_USD__c != null
                                                    AND Status__c = :Assets.PLEDGE_STATUS_PLEDGED
                    ];
                }
                for(Pledge__c p: allPledges) {
                    if(!projectsMap.containsKey(p.Fundraising_Effort__c)) {
                        projectsMap.put(
                            p.Fundraising_Effort__c,
                            p.Fundraising_Effort__r
                        );
                    }
                    List<Pledge__c> pledges = new List<Pledge__c>();
                    if(projectPledgesMap.containsKey(p.Fundraising_Effort__c)) {
                        pledges = projectPledgesMap.get(p.Fundraising_Effort__c);
                    }
                    pledges.add(p);
                    projectPledgesMap.put(p.Fundraising_Effort__c, pledges);
                }
                if(!projectPledgesMap.isEmpty()) {
                    for(Id projectId: projectPledgesMap.keySet()) {
                        FundArray fa = new FundArray((Fundraising_Project__c)(projectsMap.get(projectId)), projectPledgesMap.get(projectId));
                        fundArrayList.add(fa);
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_FUNDRAISING_RECIPIENT);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_FUNDRAISING_RECIPIENT);
        }
        return fundArrayList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Pledge__c> getContactReceivingDetails(Id contactId) {
        try {
            if (contactId == null || contactId.getSObjectType() != Contact.SObjectType) {
                return new List<Pledge__c>();
            }
            return [
                SELECT Id, Name, Status__c, Report_Amount_USD__c, Pledge_Start_Date__c,
                       Pledge_End_Date__c, Pledge_Name_Amount__c, Pledge_Year_s__c,
                       Fundraising_Effort__c, Fundraising_Effort__r.Name,
                       Fundraising_Effort__r.Focus_Area_Initiative__c
                FROM Pledge__c
                WHERE Recipient_Soft_Credit__c = :contactId
                  AND Report_Amount_USD__c != null
                  AND Status__c = :Assets.PLEDGE_STATUS_PLEDGED
                WITH USER_MODE
                ORDER BY Pledge_Start_Date__c DESC, Name
            ];
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_FUNDRAISING_RECIPIENT);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_FUNDRAISING_RECIPIENT);
        }
    }

    @AuraEnabled
    public static RecordDetails getRecordDetails(Id recordId) {
        RecordDetails detail = new RecordDetails();
        try {
            String objName = recordId.getsobjecttype().getDescribe().getName();
            if(objName == 'Contact') {
                Contact c = [SELECT Id, Name FROM Contact WHERE Id = :recordId WITH SYSTEM_MODE];
                detail.name = c.Name;
                detail.recordId = c.Id;
            } else if(objName == 'Account') {
                Account a = [SELECT Id, Name FROM Account WHERE Id = :recordId WITH SYSTEM_MODE];
                detail.name = a.Name;
                detail.recordId = a.Id;
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_RECORD_DETAILS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_RECORD_DETAILS);
        }
        return detail;
    }

    public class RecordDetails {
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String recordId {get; set;}
    }
}