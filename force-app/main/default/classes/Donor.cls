global without sharing class Donor implements Comparable {
	public String donorName {get; set;}
    public Double amountInteger;
	public String donorNameToSort;
	public String totalAmount {get; set;}
	public List<Project> projects {get; set;}
	public List<Project> latestProjects {get; set;}
	public Boolean hasLatest {get; set;}
        
	global Donor(Id donorId, List<Donor__c> donations, Boolean coverPage) {
		hasLatest = false;
		Donor__c d = donations[0];
		DonorMemoUtility.DonorName dName = new DonorMemoUtility.DonorName (d);
        this.donorName = dName.donorName;
        this.donorNameToSort = dName.donorNameToSort;
		processDonations(donorId, donations, coverPage);
	}
        
	private void processDonations(Id donorId, List<Donor__c> donations, Boolean coverPage) {
            Map<Id, List<Donor__c>> projectIdDonationsMap = new Map<Id, List<Donor__c>> ();
            List<Project> allProjects = new List<Project> ();
            List<Project> allLatestProjects = new List<Project> ();
            Double amount = 0;
            for(Donor__c donation: donations) {
                List<Donor__c> donors = new List<Donor__c> ();
                if(projectIdDonationsMap.get(donation.Pledge__r.Fundraising_Effort__c) != null) {
                    donors = projectIdDonationsMap.get(donation.Pledge__r.Fundraising_Effort__c);
                }
                donors.add(donation);
                projectIdDonationsMap.put(donation.Pledge__r.Fundraising_Effort__c, donors);
            }
            for(Id projectId: projectIdDonationsMap.keySet()) {
                Project project = new Project(projectId, projectIdDonationsMap.get(projectId), coverPage); 
                if((DonorMemoService.selectedFilters.isPdf && project.amountI >= 10000) || !DonorMemoService.selectedFilters.isPdf) {
                    amount += project.amountI;
                    if(project.latest) allLatestProjects.add(project);
                    allProjects.add(project);
                }
            }
            allProjects.sort();
            allLatestProjects.sort();
            if(allLatestProjects.size() > 0) hasLatest = true;
            if(DonorMemoService.selectedFilters.isPDF) {
                RoundCurrency.RoundAmount roundAmount = RoundCurrency.getRoundAmount(amount);
                totalAmount = '$' + roundAmount.formattedAmount;
                amountInteger = roundAmount.roundedAmount;
            } else {
                totalAmount = '$' + amount;
                amountInteger = amount;
            }
            this.projects = allProjects;
            this.latestProjects = allLatestProjects;
	}
        
	public Integer compareTo(Object compareTo) {
        Donor memo = (Donor) compareTo;            
        if(amountInteger > memo.amountInteger) {
            return -1;
        } else if (amountInteger < memo.amountInteger) {
            return 1;
        } else {
            // First value the same, consider second value
            if(donorNameToSort > memo.donorNameToSort) {
                return 1;
            } else if(donorNameToSort < memo.donorNameToSort) {
                return -1;
            } else {
                return 0;
            }          
        }  
	}
    
    global class Project implements Comparable {
        public String projectName;
        public Double amountI;
        public String pledgeAmount;
        public String pledgeTimeFrame;
        public String projectText {get; set;}
        public Boolean anonymous = false;
        public Boolean latest {get; set;}
        public Boolean forCoverPage = false;

        // Numeric breakout for the Word doc JS
        public Double anonAmountI = 0;
        public Double nonAnonAmountI = 0;
        public String anonTimeFrame;
        public String nonAnonTimeFrame;

        // Pre-formatted sub-lines for the PDF/VF cover page
        public List<String> anonBreakoutLines {get; set;}
        public Boolean hasAnonBreakout {
            get { return anonBreakoutLines != null && !anonBreakoutLines.isEmpty(); }
        }

        global Project(Id projectId, List<Donor__c> donations, Boolean coverPage) {
            latest = true;
            forCoverPage = coverPage;
            anonBreakoutLines = new List<String>();
            this.projectName = donations[0].Pledge__r.Fundraising_Effort__r.Name;
            Double amount = 0;
            Double anonAmt = 0;
            Double nonAnonAmt = 0;
            Set<Integer> datesSet = new Set<Integer>();
            Set<Integer> anonDates = new Set<Integer>();
            Set<Integer> nonAnonDates = new Set<Integer>();
            for(Donor__c donation : donations) {
                Double repAmt = donation.Pledge__r.Report_Amount_USD__c;
                amount += repAmt;
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
            pledgeTimeFrame = formatTimeFrame(datesSet);
            anonTimeFrame = formatTimeFrame(anonDates);
            nonAnonTimeFrame = formatTimeFrame(nonAnonDates);
            if(DonorMemoService.selectedFilters.isPDF) {
                RoundCurrency.RoundAmount ra = RoundCurrency.getRoundAmount(amount.round());
                pledgeAmount = '$' + ra.formattedAmount;
                amountI = ra.roundedAmount;
            } else {
                pledgeAmount = '$' + (Double)Math.roundToLong(amount);
                amountI = (Double)Math.roundToLong(amount);
            }
            anonAmountI = (Double)Math.roundToLong(anonAmt);
            nonAnonAmountI = (Double)Math.roundToLong(nonAnonAmt);
            Boolean isMixed = anonAmt > 0 && nonAnonAmt > 0;
            if(forCoverPage) {
                projectText = projectName + ' (' + pledgeAmount + ')';
            } else {
                projectText = projectName + ' (' + pledgeAmount + ')' + ' (' + pledgeTimeFrame + ')';
            }
            if(anonymous && !isMixed) projectText += ' (Anonymous)';
            if(forCoverPage && DonorMemoService.selectedFilters.isPDF && isMixed) {
                String publicLine = '$' + RoundCurrency.getRoundAmount(nonAnonAmt.round()).formattedAmount;
                String anonLine = '$' + RoundCurrency.getRoundAmount(anonAmt.round()).formattedAmount + ' (Anonymous)';
                if(nonAnonAmt >= anonAmt) {
                    anonBreakoutLines.add(publicLine);
                    anonBreakoutLines.add(anonLine);
                } else {
                    anonBreakoutLines.add(anonLine);
                    anonBreakoutLines.add(publicLine);
                }
            }
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
            Project pro = (Project)compareTo;
            if(amountI == pro.amountI) return 0;
            if(amountI > pro.amountI) return -1;
            return 1;
        }
    }
}