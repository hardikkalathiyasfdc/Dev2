/**
 * Author : Neha Gire
 * Date   : 12/21/2023
 * Jira   : BRME-4773
 * Description : This is a controller for BoardInteractionMonthlyReport Page which
 *               renders pdf for Mayor and CityView Interactions.
 * Test   : MayorAndCityViewInteractionCntrlTest
 **/
public with sharing class MayorAndCityViewInteractionCntrl {

    List<String> excludedRecordTypes = new List<String>{ 'Correspondence (2020)' };

    public List<InteractionWrapper> mayorInteractionsList { get; set; }
    public List<InteractionWrapper> cityViewInteractionsList { get; set; }

    public String currentMonth { get; set; }
    public String currentYear { get; set; }
    public Boolean isMayorInteractionsPresent { get; set; }
    public Boolean isCityViewInteractionsPresent { get; set; }
    public DateTime currentDate { get; set; }
    public String currentDateLocal { get; set; }
    public String title { get; set; }

    private Date fromDate;
    private Date toDate;

    public static final String REPORT_SETTING_NAME = 'Interactions with Mayor & CityView';

    private static final String ERR_GET_MAYORS_INTERACTIONS = 'MAYOR_AND_CITY_VIEW_CTRL_GET_MAYORS_INTERACTIONS_FAILED';
    private static final String ERR_GET_CITY_VIEW_INTERACTIONS = 'MAYOR_AND_CITY_VIEW_CTRL_GET_CITY_VIEW_INTERACTIONS_FAILED';

    public MayorAndCityViewInteractionCntrl() {
        currentDate = System.now().addMonths(-1);
        currentDateLocal = System.now().format();
        currentMonth = currentDate.format('MMMM');
        currentYear = currentDate.format('YYYY');

        Map<String, String> params = ApexPages.currentPage() != null ? ApexPages.currentPage().getParameters() : new Map<String, String>();
        String fromParam = params.get('from');
        String toParam = params.get('to');
        if (String.isNotBlank(fromParam) && String.isNotBlank(toParam)) {
            fromDate = Date.newInstance(Integer.valueOf(fromParam.substring(0, 4)), Integer.valueOf(fromParam.substring(4, 6)), Integer.valueOf(fromParam.substring(6, 8)));
            toDate = Date.newInstance(Integer.valueOf(toParam.substring(0, 4)), Integer.valueOf(toParam.substring(4, 6)), Integer.valueOf(toParam.substring(6, 8)));
        } else {
            fromDate = System.today().toStartOfMonth().addMonths(-1);
            toDate = System.today().toStartOfMonth().addDays(-1);
        }

        Report_Email_Setting__mdt setting = ReportEmailHelper.getReportEmailSetting(REPORT_SETTING_NAME);

        if (setting != null && !String.isEmpty(setting.Title__c)) {
            title = setting.Title__c;

            if (setting.Add_Current_Month_To_Report__c) {
                title += ' - ' + currentMonth + ' ' + currentYear;
            }
        }

        mayorInteractionsList = new List<InteractionWrapper>();
        cityViewInteractionsList = new List<InteractionWrapper>();

        getMayorInteractions();
        getCityViewInteractions();

        isMayorInteractionsPresent = mayorInteractionsList.size() > 0;
        isCityViewInteractionsPresent = cityViewInteractionsList.size() > 0;
    }

    private void getMayorInteractions() {
        try {
            String currentYearStr = String.valueOf(Date.today().year());
            List<AggregateResult> mayorInteractionsList = [
                SELECT Id,
                       Teams__r.Name Team,
                       Interaction_Date__c IDate,
                       Contact__r.Name MayorName,
                       Contact__r.LastName,
                       Contact__r.Account.AKA__c CityName,
                       Contact__r.MailingCountry Country,
                       Name Subject,
                       CreatedBy.Name CreatedBy,
                       Contact__r.Id contactId
                FROM Interaction__c
                WHERE Contact__c IN (
                    SELECT Contact_Name__c
                    FROM Employment_History_and_Board_Membership__c
                    WHERE Role__c = 'Mayor'
                    AND (
                        Employment_End_Date__c >= TODAY
                        OR (
                            Employment_End_Date__c = null
                            AND (To__c = null OR To__c >= :currentYearStr)
                        )
                    )
                )
                AND Interaction_Date__c >= :fromDate
                AND Interaction_Date__c <= :toDate
                AND RecordType.Name NOT IN :excludedRecordTypes
                AND Private_Interaction__c = FALSE
                AND Contact__r.Restricted__c = FALSE
                AND Organization__r.Restricted__c = FALSE
                GROUP BY Teams__r.Name,
                         Contact__r.Name,
                         Contact__r.Account.AKA__c,
                         Contact__r.MailingCountry,
                         Interaction_Date__c,
                         Name,
                         CreatedBy.Name,
                         Contact__r.LastName,
                         Contact__r.Id,
                         Id
                ORDER BY Teams__r.Name ASC,
                         Contact__r.LastName ASC,
                         Interaction_Date__c DESC
            ];
            
            Map<String, InteractionWrapper> teamToFirstInteractionMap = new Map<String, InteractionWrapper>();
            Map<String, InteractionWrapper> mayorToFirstInteractionMap = new Map<String, InteractionWrapper>();

            for (AggregateResult aggrRecord : mayorInteractionsList) {
                String contactId = String.valueOf(aggrRecord.get('contactId'));
                InteractionWrapper wrapper =
                    formInteractionWrapper(aggrRecord, true);

                if (!teamToFirstInteractionMap.containsKey(wrapper.team)) {teamToFirstInteractionMap.put(wrapper.team, wrapper);
                } else {
                    teamToFirstInteractionMap.get(wrapper.team).interactionCountByTeam++;
                    wrapper.interactionCountByTeam = 0;
                }

                if (!mayorToFirstInteractionMap.containsKey(wrapper.team + contactId)) {
                    mayorToFirstInteractionMap.put(wrapper.team + contactId, wrapper);
                } else {
                    mayorToFirstInteractionMap.get(wrapper.team + contactId).interactionCountByCity++;
                    wrapper.interactionCountByCity = 0;
                }
                this.mayorInteractionsList.add(wrapper);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_MAYORS_INTERACTIONS));
        }
    }

    private void getCityViewInteractions() {
        try {
            List<AggregateResult> cityViewInteractionsList = [
                SELECT Id,
                       Teams__r.Name Team,
                       Interaction_Date__c IDate,
                       Organization__r.AKA__c CityName,
                       Organization__r.BillingCountry Country,
                       Name Subject,
                       CreatedBy.Name CreatedBy
                FROM Interaction__c
                WHERE Organization__r.Org_Type__c = 'Government - City'
                AND CityView_Review_Status__c = 'Publish to CityView'
                AND Interaction_Date__c >= :fromDate
                AND Interaction_Date__c <= :toDate
                AND RecordType.Name = 'Organization Highlight/CityView'
                AND Private_Interaction__c = FALSE
                AND Organization__r.Restricted__c = FALSE
                GROUP BY Teams__r.Name,
                         Organization__r.AKA__c,
                         Organization__r.BillingCountry,
                         Interaction_Date__c,
                         Name,
                         CreatedBy.Name,
                         Id
                ORDER BY Teams__r.Name ASC,
                         Organization__r.AKA__c ASC,
                         Interaction_Date__c DESC
            ];

            Map<String, InteractionWrapper> teamToFirstInteractionMap = new Map<String, InteractionWrapper>();
            Map<String, InteractionWrapper> cityToFirstInteractionMap = new Map<String, InteractionWrapper>();

            for (AggregateResult aggrRecord : cityViewInteractionsList) {
                InteractionWrapper wrapper =
                    formInteractionWrapper(aggrRecord, false);

                if (!teamToFirstInteractionMap.containsKey(wrapper.team)) {
                    teamToFirstInteractionMap.put(wrapper.team, wrapper);
                } else {
                    teamToFirstInteractionMap.get(wrapper.team)
                        .interactionCountByTeam++;
                    wrapper.interactionCountByTeam = 0;
                }

                if (!cityToFirstInteractionMap.containsKey(
                        wrapper.team + wrapper.city
                    )) {
                    cityToFirstInteractionMap.put(
                        wrapper.team + wrapper.city,
                        wrapper
                    );
                } else {
                    cityToFirstInteractionMap.get(wrapper.team + wrapper.city)
                        .interactionCountByCity++;
                    wrapper.interactionCountByCity = 0;
                }

                this.cityViewInteractionsList.add(wrapper);
                System.debug(wrapper);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_CITY_VIEW_INTERACTIONS));
        }
    }

    private InteractionWrapper formInteractionWrapper (AggregateResult record,Boolean isMayorInteraction) {
        InteractionWrapper wrapper = new InteractionWrapper();
        wrapper.team = String.valueOf(record.get('Team'));
        if (isMayorInteraction) {
            wrapper.mayorName = String.valueOf(record.get('MayorName'));
        }

        wrapper.city = String.valueOf(record.get('CityName'));
        wrapper.country = String.valueOf(record.get('Country'));
        wrapper.subject = String.valueOf(record.get('Subject'));
        wrapper.iDate = Date.valueOf(record.get('IDate'));
        wrapper.createdBy = String.valueOf(record.get('CreatedBy'));
        return wrapper;
    }

    public class InteractionWrapper {
        public String team { get; set; }
        public Integer interactionCountByTeam { get; set; }
        public String mayorName { get; set; }
        public Integer interactionCountByCity { get; set; }
        public String city { get; set; }
        public String state { get; set; }
        public String country { get; set; }
        public String subject { get; set; }
        public Date iDate { get; set; }
        public String createdBy { get; set; }

        public InteractionWrapper() {
            interactionCountByTeam = 1;
            interactionCountByCity = 1;
        }
    }
}