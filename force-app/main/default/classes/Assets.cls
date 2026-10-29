/**
* Author      : Sudhir Gunda
* Description : This class is defining constants that are used across multiple classes.
* ChangeLog   :
Sai Bhargav Thotakura on Jan 2025 - IM-49 - Created "BGIVE Initiative" related constants.
**/
public without sharing class Assets {
	public static final String SOURCE_BUSINESS = 'Business';
	public static final String SOURCE_HOME = 'Home';
	public static final String SOURCE_ASSOCIATION = 'Association';
	public static final String USA_Code = 'US';
	public static final String NA = 'N/A';
	public static final String INTERNATIONAL = 'International';
	public static final String DESKTOPVIEW = 'Desktop';
	public static final String DATAIMPORTTOOL ='Data Import Tool';
	//Contact Record Types
	public static final String CONTACT_RECORDTYPE_BBRM = 'BBRM';

	//Contact Endorsement Status
	public static final String CONTACT_ENDORSEMENT_STATUS_ENDORSED = 'Endorsed MRB for President';
	public static final String CONTACT_ENDORSEMENT_STATUS_ENDORSED_NOT_ANNOUNCED = 'Endorsed MRB for President (Not Announced)';

	//Contact Campaign Role
	public static final String CONTACT_CAMPAIGN_ROLE_SURROGATE = 'Surrogate';
	public static final String CONTACT_CAMPAIGN_ROLE_LEADERSHIP_COUNCIL_ALL = 'Leadership Council';

	//Interaction Record Types
	public static final String INTERACTION_RECORDTYPE_TOUCHPOINT = '2020 Touch Point';
	public static final String INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME = 'Recent_Engagement';

	//Related Contact Record Types
	public static final String RELATED_CONTACT_RECORDTYPE_STANDARD = 'Standard';

	//Account Record Types
	public static final String ACCOUNT_RECORDTYPE_COMPANY = 'Company';

	//Campaign Record Types
	public static final String CAMPAIGN_RECORDTYPE_CONSTITUENCIES = 'Constituencies List';
	public static final String CAMPAIGN_RECORDTYPE_TEAM2020 = 'Team_2020';
	public static final String CAMPAIGN_RECORDTYPE_TEAMS = 'State_Campaign';
	public static final String CAMPAIGN_RECORDTYPE_DEVENAME_EVENT = 'Pre_Event';

	//Campaign Member Statuses
	public static final String CAMPAIGN_MEMBER_STATUS_YES = 'Yes';
	public static final String CAMPAIGN_MEMBER_STATUS_NO = 'No';
	public static final String CAMPAIGN_MEMBER_STATUS_MAYBE = 'Maybe';

	//Web Form
	public static final String WEB_FORM_EMAIL_FIELD_NAME = 'Email Address';
	public static final String WEB_FORM_LAST_NAME_FIELD_NAME = 'Last Name';
	public static final String WEB_FORM_FIRST_NAME_FIELD_NAME = 'First Name';
	public static final String WEB_FORM_PHONE_FIELD_NAME = 'Mobile Phone Number';
	public static final String WEB_FORM_CITY_FIELD_NAME = 'City';
	public static final String WEB_FORM_STATE_FIELD_NAME = 'State';
	public static final String WEB_FORM_ZIP_FIELD_NAME = 'Zip Code';
	public static final String WEB_FORM_DATA_SOURCE_FIELD_NAME = 'All Data Sources';
	public static final String WEB_FORM_COALITION_COMMITTEE_FOR_MIKE = 'committee_for_mike';
	public static final String WEB_FORM_CONTACT_FIELD_FOR_STATE = 'MailingStateCode';
	public static final String WEB_FORM_CONTACT_FIELD_FOR_COUNTRY = 'MailingCountryCode';
	public static final String WEB_FORM_CONTACT_FIELD_FOR_CITY = 'MailingCity';
	public static final String WEB_FORM_CONTACT_FIELD_FOR_ZIP = 'MailingPostalCode';
	public static final String WEB_FORM_ACCOUNT_NAME = 'WebForm';

    //Contact Email Notifications
    public static final String BOARD_MEMBER_UPDATE_EMAIL_SUBJECT = 'Board Member Contact Update Notification';

    //Contact Alert Reasons
    public static final String CONTACT_ALERT_REASON_DECEASED = 'Deceased';
    public static final String CONTACT_ALERT_REASON_DO_NOT_CONTACT = 'Do Not Contact';

    //Legacy Source
    public static final String LEGACY_SOURCE_SYSTEM_MOBILE = 'Mobile';

	//Account
	public static final String INDIVIDUAL_ACCOUNT_NAME = '-';
	public static final String BP_ACCOUNT_NAME = 'Bloomberg Philanthropies';

	//Phone - County Code
	public static final String Phone_Country_Code_USA = 'United States(+1)';

	//Constituencies
	public static final String CONSTITUENCIES_COMMITTEE_FOR_MIKE = 'Committee for Mike';

	//Reports
	public static final String BOAD_MEMBER_EMAIL_RECEIVER_REPORT_SETTING_NAME = 'Board Member Email Receiver';
	public static final String INTERACTIONS_MAYOR_CITYVIEW_REPORT_SETTING_NAME = 'Interactions with Mayor & CityView';
	public static final String FUNDRAISING_DONOR_MEMO_REPORT_SETTING_NAME = 'Fundraising Donor Memo';
	public static final String INTERACTIONS_MAYORS_AND_CITYVIEW = 'Interactions with Mayor & CityView';

	// Pledge status
	public static final String PLEDGE_STATUS_PLEDGED = 'Pledged';

	public static final Map<String, String> mapSpecialCharacter  = new Map<String,String>{'’' => '','\'' => '', '-' => '', '&' => '', '!' => '', ' ' => '', '\u00A0' => '', '\t' => '', '\n' => '', '\r' => '',
		'.' => '','Š'=> 'S', 'š'=> 's', 'Ð'=> 'Dj', 'Ž'=> 'Z', 'ž'=> 'z', 'À'=> 'A', 'Á'=> 'A', 'Â'=> 'A', 'Ã'=> 'A', 'Ä'=> 'A', 'Å'=> 'A', 'Æ'=> 'A', 'Ç'=> 'C',
'È'=> 'E', 'É'=> 'E', 'Ê'=> 'E', 'Ë'=> 'E', 'Ì'=> 'I', 'Í'=> 'I', 'Î'=> 'I', 'Ï'=> 'I', 'Ñ'=> 'N', 'Ń'=> 'N', 'Ò'=> 'O', 'Ó'=> 'O', 'Ô'=> 'O',
'Õ'=> 'O', 'Ö'=> 'O', 'Ø'=> 'O', 'Ù'=> 'U', 'Ú'=> 'U', 'Û'=> 'U', 'Ü'=> 'U', 'Ý'=> 'Y', 'Þ'=> 'B', 'ß'=> 'Ss', 'à'=> 'a', 'á'=> 'a', 'â'=> 'a',
'ã'=> 'a', 'ä'=> 'a', 'å'=> 'a', 'æ'=> 'a', 'ç'=> 'c', 'è'=> 'e', 'é'=> 'e', 'ê'=> 'e', 'ë'=> 'e', 'ì'=> 'i', 'í'=> 'i', 'î'=> 'i', 'ï'=> 'i',
'ð'=> 'o', 'ñ'=> 'n', 'ò'=> 'o', 'ó'=> 'o', 'ô'=> 'o', 'õ'=> 'o', 'ö'=> 'o', 'ø'=> 'o', 'ù'=> 'u', 'ú'=> 'u', 'û'=> 'u', 'ü'=> 'u', 'ý'=> 'y',
'þ'=> 'b', 'ÿ'=> 'y', 'ƒ'=> 'f', 'ă'=> 'a', 'ș'=> 's', 'ț'=> 't', 'Ă'=> 'A', 'Î'=> 'I', 'Ș'=> 'S', 'Ț'=> 'T', 'Ā'=> 'A', 'ā'=> 'a', 'Ą'=> 'A',
'ą'=> 'a', 'Ć'=> 'C', 'ć'=> 'c', 'Ĉ'=> 'C', 'ĉ'=> 'c', 'Ċ'=> 'C', 'ċ'=> 'c', 'Č'=> 'C', 'č'=> 'c', 'Ď'=> 'D', 'ď'=> 'd', 'Đ'=> 'D', 'đ'=> 'd',
'Ē'=> 'E', 'ē'=> 'e', 'Ĕ'=> 'E', 'ĕ'=> 'e', 'Ė'=> 'E', 'ė'=> 'e', 'Ę'=> 'E', 'ę'=> 'e', 'Ě'=> 'E', 'ě'=> 'e', 'Ĝ'=> 'G', 'ĝ'=> 'g', 'Ğ'=> 'G',
'ğ'=> 'g', 'Ġ'=> 'G', 'ġ'=> 'g', 'Ģ'=> 'G', 'ģ'=> 'g', 'Ĥ'=> 'H', 'ĥ'=> 'h', 'Ħ'=> 'H', 'ħ'=> 'h', 'Ĩ'=> 'I', 'ĩ'=> 'i', 'Ī'=> 'I', 'ī'=> 'i',
'Ĭ'=> 'I', 'ĭ'=> 'i', 'Į'=> 'I', 'į'=> 'i', 'İ'=> 'I', 'ı'=> 'i', 'Ĳ'=> 'IJ', 'ĳ'=> 'ij', 'Ĵ'=> 'J', 'ĵ'=> 'j', 'Ḱ'=> 'K', 'Ķ'=> 'K', 'ķ'=> 'k', 'Ĺ'=> 'L',
'ĺ'=> 'l', 'Ļ'=> 'L', 'ļ'=> 'l', 'Ľ'=> 'L', 'ľ'=> 'l', 'Ŀ'=> 'L', 'ŀ'=> 'l', 'Ł'=> 'L', 'ł'=> 'l', 'Ņ'=> 'N', 'ņ'=> 'n', 'Ň'=> 'N', 'ň'=> 'n',
'ŉ'=> 'n', 'Ō'=> 'O', 'ō'=> 'o', 'Ŏ'=> 'O', 'ŏ'=> 'o', 'Ő'=> 'O', 'ő'=> 'o', 'Œ'=> 'OE', 'œ'=> 'oe', 'Ŕ'=> 'R', 'ŕ'=> 'r', 'Ŗ'=> 'R', 'ŗ'=> 'r',
'Ř'=> 'R', 'ř'=> 'r', 'Ś'=> 'S', 'ś'=> 's', 'Ŝ'=> 'S', 'ŝ'=> 's', 'Ş'=> 'S', 'ş'=> 's', 'Ţ'=> 'T', 'ţ'=> 't', 'Ť'=> 'T', 'ť'=> 't', 'Ŧ'=> 'T',
'ŧ'=> 't', 'Ũ'=> 'U', 'ũ'=> 'u', 'Ū'=> 'U', 'ū'=> 'u', 'Ŭ'=> 'U', 'ŭ'=> 'u', 'Ů'=> 'U', 'ů'=> 'u', 'Ű'=> 'U', 'ű'=> 'u', 'Ų'=> 'U', 'ų'=> 'u',
'Ŵ'=> 'W', 'ŵ'=> 'w', 'Ŷ'=> 'Y', 'ŷ'=> 'y', 'Ÿ'=> 'Y', 'Ź'=> 'Z', 'ź'=> 'z', 'Ż'=> 'Z', 'ż'=> 'z', 'ſ'=> 's', 'Ə'=> 'E', 'ə'=> 'e', 'Ɓ'=> 'B',
'ɓ'=> 'b', 'Ƃ'=> 'B', 'ƃ'=> 'b', 'Ƅ'=> 'B', 'ƅ'=> 'b', 'Ɔ'=> 'O', 'Ƈ'=> 'C', 'ƈ'=> 'c', 'Ɖ'=> 'D', 'Ɗ'=> 'D', 'Ƌ'=> 'D', 'ƌ'=> 'd', 'ƍ'=> 'e',
'Ǝ'=> 'E', 'Ɛ'=> 'E', 'Ƒ'=> 'F', 'Ɠ'=> 'G', 'Ɣ'=> 'G', 'ƕ'=> 'hv', 'Ɩ'=> 'I', 'Ɨ'=> 'I', 'Ƙ'=> 'K', 'ƙ'=> 'k', 'ƚ'=> 'l', 'ƛ'=> 'l', 'Ɯ'=> 'M',
'Ɲ'=> 'N', 'ƞ'=> 'n', 'Ɵ'=> 'O', 'Ơ'=> 'O', 'ơ'=> 'o', 'Ƥ'=> 'P', 'ƥ'=> 'p', 'Ʀ'=> 'R', 'Ƨ'=> 'S', 'ƨ'=> 's', 'Ʃ'=> 'Esh', 'ƪ'=> 't', 'ƫ'=> 't',
'Ƭ'=> 'T', 'ƭ'=> 't', 'Ʈ'=> 'T', 'Ư'=> 'U', 'ư'=> 'u', 'Ʊ'=> 'U', 'Ʋ'=> 'V', 'Ƴ'=> 'Y', 'ƴ'=> 'y', 'Ƶ'=> 'Z', 'ƶ'=> 'z', 'Ʒ'=> 'EZH', 'Ƹ'=> 'Ezh',
'ƹ'=> 'ezh', 'ƺ'=> 'ezh', 'ƻ'=> '2', 'Ƽ'=> '5', 'ƽ'=> '5', 'ƾ'=> 'ts', 'ƿ'=> 'w', 'ǀ'=> 'I', 'ǁ'=> 'D', 'ǂ'=> 'B', 'ǃ'=> '!', 'Ǎ'=> 'A', 'ǎ'=> 'a',
'Ǐ'=> 'I', 'ǐ'=> 'i', 'Ǒ'=> 'O', 'ǒ'=> 'o', 'Ǔ'=> 'U', 'ǔ'=> 'u', 'Ǖ'=> 'U', 'ǖ'=> 'u', 'Ǘ'=> 'U', 'ǘ'=> 'u', 'Ǚ'=> 'U', 'ǚ'=> 'u', 'Ǜ'=> 'U',
'ǜ'=> 'u', 'ǝ'=> 'e', 'Ǟ'=> 'A', 'ǟ'=> 'a', 'Ǡ'=> 'A', 'ǡ'=> 'a', 'Ǣ'=> 'AE', 'ǣ'=> 'ae', 'Ǥ'=> 'G', 'ǥ'=> 'g', 'Ǧ'=> 'G', 'ǧ'=> 'g', 'Ǩ'=> 'K',
'ǩ'=> 'k', 'Ǫ'=> 'O', 'ǫ'=> 'o', 'Ǭ'=> 'O', 'ǭ'=> 'o', 'Ǯ'=> 'EZH', 'ǯ'=> 'ezh', 'ǰ'=> 'j', 'Ǳ'=> 'DZ', 'ǲ'=> 'Dz', 'ǳ'=> 'dz', 'Ǵ'=> 'G', 'ǵ'=> 'g',
'Ƕ'=> 'H', 'Ƿ'=> 'W', 'Ǹ'=> 'N', 'ǹ'=> 'n', 'Ǻ'=> 'A', 'ǻ'=> 'a', 'Ǽ'=> 'AE', 'ǽ'=> 'ae', 'Ǿ'=> 'O', 'ǿ'=> 'o', 'Ȁ'=> 'A', 'ȁ'=> 'a', 'Ȃ'=> 'A', 'ȃ'=> 'a',
'Ȅ'=> 'E', 'ȅ'=> 'e', 'Ȇ'=> 'E', 'ȇ'=> 'e', 'Ȉ'=> 'I', 'ȉ'=> 'i', 'Ȋ'=> 'I', 'ȋ'=> 'i', 'Ȍ'=> 'O', 'ȍ'=> 'o', 'Ȏ'=> 'O', 'ȏ'=> 'o', 'Ȑ'=> 'R', 'ȑ'=> 'r',
'Ȓ'=> 'R', 'ȓ'=> 'r', 'Ȕ'=> 'U', 'ȕ'=> 'u', 'Ȗ'=> 'U', 'ȗ'=> 'u', 'Ț'=> 'T', 'ț'=> 't', 'Ȝ'=> 'Yogh', 'ȝ'=> 'yogh', 'Ȟ'=> 'H', 'ȟ'=> 'h', 'Ƞ'=> 'N',
'ȡ'=> 'd', 'Ȣ'=> 'OU', 'ȣ'=> 'ou', 'Ȥ'=> 'Z', 'ȥ'=> 'z', 'Ȧ'=> 'A', 'ȧ'=> 'a', 'Ȩ'=> 'E', 'ȩ'=> 'e', 'Ȫ'=> 'O', 'ȫ'=> 'o', 'Ȭ'=> 'O', 'ȭ'=> 'o', 'Ȯ'=> 'O',
		'ȯ'=> 'o', 'Ȱ'=> 'O', 'ȱ'=> 'o', 'Ȳ'=> 'Y', 'ȳ'=> 'y',
		',' => '', ':' => '', ';' => '', '?' => '', '(' => '', ')' => '',
		'[' => '', ']' => '', '#' => '', '@' => '', '%' => '', '*' => '',
		'+' => '', '=' => '', '~' => '', '/' => '', '\\' => '', '|' => '',
		'<' => '', '>' => '', '`' => '', '"' => '',
		'—' => '-', '–' => '-', '"' => '', '"' => '', '…' => '',
		'€' => 'E', '£' => 'L', '¥' => 'Y', '¢' => 'c',
		'©' => '', '®' => '', '™' => ''
	};

	//Environment
	public static final String DEV = 'Dev';
	public static final String PROD = 'Prod';
	public static final String TEST = 'Test';

	//Fluxx
	public static final String FLUXX_API_VERSION = 'v2';

	//Foundation Codes
	public static final String RETIRED = 'Retired';
	public static final String DELETED = 'Deleted';
	public static final String ACTIVE = 'Active';
	public static final String BRM = 'BRM';
	public static final String BGIVE = 'Bgive';
	public static final String PARENT = 'Parent__c';
	public static final String STATUS = 'Status__c';
	public static final String FOUNDATION_CODE = 'Foundation_Code__c';
	public static final String FC_ERROR_TYPE = 'Foundation Code Sync';
	public static final String BGIVE_DESCRIPTION = 'BGive_Description__c';
	public static final String ENABLE_FOR_GRANTS = 'Enabled_for_Grants__c';
	public static final String INITIATIVES = 'Initiatives';
	public static final String NAME_FIELD = 'Name';
	public static final String ROLLUP_IN_REPORTING_FIELD = 'Rollup_In_Reporting__c';
	public static final String SORT_ORDER = 'Sort_Order__c';
	//Department Sharing team
	public static final String DEPT_PUBLICGROUP_PREFIX = 'Team: ';

	//Organization Annual Metrics object
	public static final String YEAR = 'Year__c';
	public static final String ANNUAL_WEBSITE_VISITS = 'Annual_Website_Visits__c';
	public static final String NUMBER_OF_ORGANIATION = 'Number_of_Organization_Memberships__c';
	public static final String ORGANIZATION_ANNUAL_ATTENDANCE = 'Organization_Annual_Attendance__c';
	public static final String POPULATION = 'Population__c';
	public static final String POPULATION_CENSUS_DATA = 'Population_Census_Data_As_of__c';
	public static final String POPULATION_MINORITY_MAJAORITY = 'Population_Minority_is_Majority__c';
	public static final String POPULATION_NON_HISPANIC = 'Population_Non_Hispanic_white__c';
	public static final String REGION = 'Region__c';
	public static final String RESTRICTED_ORG_NAME = '#';

	// Custom Share Component
	public static final String SHARING_HIERARCHY_PERMSET = 'General_Sharing_Hierarchy';
	public static final String ALL_INTERNAL_USERS = 'All Internal Users';
	public static final String RESTRICTED_ACCESS_PERMSET = 'Restricted_Access';
	public static final String PRIVATE_NAME_ACCESS_PERMSET = 'Private_Name_Fields';

	//B-Link Contact
	public static final String BRM_HASH_DELIMITER = '|';
	public static final String BLINK_SYNC_ERROR_TYPE = 'BLink Sync';

	// B-Link Organization
	public static final Integer STRING_MAX_SIZE = 32768;
	public static final String BIDIRECTIONAL_SYNC_MODE = 'Bidirectional';
	public static final String BRM_TO_BGIVE_SYNC_MODE = 'BRM to Bgive';
	public static final String BGIVE_TO_BRM_SYNC_MODE = 'Bgive to BRM';
	public static final String INITIAL_CREATION_SYNC_MODE = 'Initial Creation';
	public static Set<String> systemFields = new Set<String>{
                    'id','isdeleted','masterrecordid','recordtypeid','reportstoid','createddate','createdbyid','lastmodifieddate',
                        'lastmodifiedbyid','systemmodstamp','lastactivitydate','lastcurequestdate','lastcuupdatedate','lastvieweddate',
                        'lastreferenceddate','emailbounceddate','isemailbounced','emailbouncedreason','jigsaw','jigsawcontactid','individualid',
		'ispriorityrecord'
	};
	public static final String BLINK = 'B-Link';
	public static final String ORGGEOAREACULTURALACCESS = 'Cultural Access';
	public static final String ORGGEOAREACULTURALIMPLICIT = 'Cultural Implicit';
	public static final String ORGGEOAREAKEYPARTNER = 'Key Partner';
	public static final String GEOAREARECORDTYPECITY = 'City';
	public static final String GEOAREARECORDTYPECOUNTRY = 'Country';
	public static final String GEOAREARECORDTYPESTATE = 'State';
	public static final String GEO_AREA_RECORDTYPE_STATE = 'State';
	public static final String GEO_AREA_RECORDTYPE_COUNTRY = 'Country';
	public static final String ASSOCIATION_RECORDTYPE_INITIATIVE = 'Initiative';
	public static final String ASSOCIATION_RECORDTYPE_STANDARD = 'Standard';
	public static final String ASSOCIATION_RECORDTYPE_GCOM = 'Gcom';
	public static final String ORG_ASSOCIATION_RECORDTYPE_GRANT = 'Grant';
	public static final String BPWORKFILTER = 'BP Work';
	public static final String BP_WORK_FILTER = 'BP Work';
	public static final String ORG_ASSOCIATION_RECORDTYPE_STANDARD = 'City_View';

	//Chatter Feed Titles
	public static final String ADDED_TITLE = 'Added';
    public static final String REMOVED_TITLE = 'Removed';

	//Object ID Prefixes
	public static final String CONTACT_ID_PREFIX = '003';
	public static final String ACCOUNT_ID_PREFIX = '001';

	public static final String MULTIPLE_ACTIVE_RENEWAL = 'Only one renewal can be active for given Initiative.';

	//Checkout Budget
	public static final String CHECKOUT_ERROR_TYPE = 'Checkout Budget';
	public static final String CHECKIN_ERROR_TYPE = 'Checkin Budget';
	public static final String NO_FILE_PRESENT = 'Template Records present but no files attached, please check!';
	public static final String NO_TEMPLATES_FOUND = 'No Active Template Records found, please check!';
	public static final String NULL_BUDGET = 'Budget Id is NULL or Empty, please check!';
	public static final String NO_BUDGETS_FOUND = 'No Budget Records returned, please check!';
	public static final String SYS_EXCPETION = 'System Exception Occured - ';
	public static final String COMPONENT = 'Component';
	public static final String SUB_COMPONENT = 'SubComponent';
	public static final String PARTNER = 'Partner';
	public static final String SUB_PARTNER = 'SubPartner';
	public static final String PAYEE = 'Payee';
	public static final String IM_IB = 'IM_IB_';
	public static final String BUDGET_CATEGORY_1 = 'Component';
	public static final String BUDGET_CATEGORY_2 = 'Component, Geography';
	public static final String BUDGET_CATEGORY_3 = 'Component, SubComponent';
	public static final String BUDGET_CATEGORY_4 = 'Component, SubComponent, Geography';
	public static final String BUDGET_CATEGORY_5 = 'Geography';
	public static final String BUDGET_CATEGORY_6 = 'Geography, Component';
	public static final String BUDGET_CATEGORY_7 = 'Geography, Component, SubComponent';
	public static final String PLACEHOLDER = 'Placeholder';
	public static final String PENDING_APPROVAL = 'Pending Approval';
	public static final String REGULAR = 'Regular';
	public static final String AMENDMENT_CREATE = 'Amendment Create';
	public static final String AMENDMENT_APPROVAL = 'Amendment Approval';
	public static final String CITYVIEW_INITIATIVE = 'CityView_Initiative__c';

	// Grouping files by categories
	public static final String INITIATIVE = 'Initiative';
	public static final String AMENDMENT = 'Amendment';
	public static final String PARENT_INITIATIVE = 'Parent Initiative';
	public static final String BUDGET_INITIATIVE = 'Budgeted Initiative';
	public static final String FOCUS_AREA_API_NAME = 'Focus_Area__c';
	public static final String MISC_INITIATIVE_TYPE = 'Miscellaneous Initiative';
	public static final String FOCUS_AREA_MISC_TYPE = 'Focus Area Misc';
	public static final String FOCUS_AREA = 'Focus Area';
	public static final String FOUNDATION_CODE_API_NAME = 'Foundation_Code__c';
	public static final String ANNOUNCEMENT = 'Announcement';
	public static final String COMMUNICATIONS = 'Communications';
	public static final String IM_INITIATIVE = 'IM_Initiative__c';
	public static final String IM_ANNOUNCEMENT = 'IM_Announcement__c';
	public static final String TEAM = 'Team__c';
	public static final String APPROVED = 'Approved';
	public static final String APPROVED_FIELD = 'Approved__c';
	public static final String START_DATE = 'Start_Date__c';
	public static final String RENEWAL_OF = 'Renewal_of__c';
	public static final String INITIATIVE_TYPE = 'Initiative_Type__c';
	public static final String RENEWAL = 'Renewal';
	public static final String DECLINED = 'Declined';
	public static final String COMPLETED = 'Completed';
	public static final String ONGOING = 'Ongoing';
	public static final String DRAFT = 'Draft';
	public static final String PERIOD_START_DATE = 'Period_Start_Date__c';
	public static final String PERIOD_END_DATE = 'Period_End_Date__c';

	public static final String ANNOUNCEMENT_DATE = 'Announcement_Date__c';
	public static final String OUTLET = 'Outlet__c';
	public static final String TOTAL_AMOUNT = 'Total_Amount__c';
	public static final String GEOGRAPHY_FIELD = 'Geography__c';
	public static final String COMPONENT_FIELD = 'Component__c';
	public static final String SUB_COMPONENT_FIELD = 'SubComponent__c';
	public static final String BUDGET_FIELD = 'Budget__c';
	public static final String PARTNER_FIELD = 'Partner__c';
	public static final String UNIQUE_IDENTIFIER_FIELD = 'Unique_Identifier__c';
	public static final String PARENT_COMPONENT_FIELD = 'Parent_Component__c';
	public static final String CURRENT_BUDGET_FIELD = 'Current_Budget__c';

	public static final String PARTNER_FUND_FIELD = 'Partner_Fund__c';

	public static final String AMENDMENT_OF_FIELD = 'Amendment_of__c';
	public static final String IN_DEVELOPMENT = 'In Development';

	//BGive Initiative
	public static final String BGIVE_SYNC_ERROR_TYPE = 'IM Sync';
	public static final String BGIVE_OBJECT_NAME = 'concept_initiative';
	public static final String BGIVE_INITIATIVE_STATUS = 'InitiativeStatus';
	public static final String BGIVE_MAPPING_TYPE_PICKLIST = 'Picklist';
	public static final String BGIVE_MAPPING_TYPE_VALUE = 'Value';
	public static final String BGIVE_MAPPING_RELATION_VALUE = 'Relation';
	public static final String BGIVE_MAPPING_TYPE_USER_LOOKUP = 'User Lookup';
	public static final String BGIVE_MAPPING_TYPE_RELATED_LIST = 'Related List';
	public static final String BGIVE_MAPPING_TYPE_SEGMENT = 'Segment';
	public static final String BGIVE_DEFAULT_QUERY = 'SELECT Id,Bgive_Id__c,Initiative_Type__c,Focus_Area__r.Bgive_API_Name__c,Start_Date__c,Original_Approved_Date__c,Approved_Date__c,Name,CityView_Description__c,Program_Contact__c,Approved_Amount__c,Grants_Team_Contact__c,Original_Approved_Amount__c,Segment__r.Name,Team__r.Name,Team__r.Bgive_Id__c,Foundation_Code__r.Parent__r.Initiative__r.Bgive_Id__c,Status__c,CityView_Display_Name__c,End_Date__c,Bgive_IM_Connection__c FROM IM_Initiative__c';
	public static final String BGIVE_SEARCH_FILTER = '{"group_type":"and","conditions":[["brm_id","eq",';
	public static final String BGIVE_ID = 'Bgive_Id__c';
	public static final String BGIVE_PARENT_INITIATIVE_FIELD = 'parent_initiative_1';
	public static final String IM_OWNER = 'IM_Owner';
	public static final String LOCKED_BY_ID = 'locked_by_id';

	//BGive Grant
	public static final String BGIVE_GRANT_NAME = 'grant_request';
	public static final String BGIVE_REQUEST_AMENDMENT = 'request_amendment';
	public static final String DATAJSON = 'Data_JSON__c';
	public static final String SYNCERROR = 'Sync_Error__c';
	public static final String BGIVE_BRM_FIELD_TYPE_FL = 'Field';
	public static final String BGIVE_BRM_FIELD_TYPE_OBJ = 'Object';
	public static final String BGIVE_BRM_FIELD_TYPE_JSON = 'JSON';
	public static final String BGIVE_BRM_FIELD_TYPE_NONE = 'None';
	public static final String BGIVE_SYNC_MODE_ALWAYS = 'BRM To Bgive Always';
	public static final String BGIVE_GRANT_BUSINESS_UNIT = 'bbg_department_on_behalf_of';

	// Non Budgeted Initiative
	public static final String MISC_TEXT = ' Miscellaneous';

	// Budget Options
	public static final String DURATION_MONTHS = 'Duration_months__c';

	// Budget Views
	public static final String BUDGET_VIEWS_TEMPLATE = 'IM_IB_Budget_Views_v1';

	// Can be used for any general operation failures
	public static final String IM_BRM_ERRORS = 'IM_BRM_Errors';

	public static final String VALUE_TRUE = 'True';

	//Payment Rows for Budget
	public static final String IM_GRANT = 'IM_Grant__c';
	public static final String BGIVE_PAYMENT_NAME = 'request_transaction';
	public static final Integer BGIVE_MAX_PAYMENTS = 50;
	public static final String PARTNER_GATES = 'Gates';
	public static final String PARTNER_AGERUP = 'Agerup';
	public static final String PARTNER_DFAT = 'DFAT';
	public static final String PARTNER_BFF = 'Partner-BFF';
	public static final String PARTNER_DAF = 'Partner-DAF';
	public static final String PAYMENT_TYPE = 'Pending';
	public static final String DEFAULT_PAYMENT_STATE = 'new';
	public static final String TOTALAMOUNTSMAP = 'totalAmountsMap';
	public static final String IM_PAYMENT = 'IM_PAYMENT';
	public static final String PERSONAL_SUBFUND = 'Personal_Subfund__c';

	public static final String IM_COMPONENT = 'IM_Component__c';
	public static final String IM_GEOGRAPHY = 'IM_Geography__c';

	//Allocations
	public static final String BGIVE_ALLOCATION_NAME = 'mac_model_type_dyn_allocation';

	// Budget Grant
	public static final String SINGLE_CREATE = 'SINGLE_CREATE';
	public static final String PARTIAL_FIRST_ALLOCATION = 'PARTIAL_FIRST_ALLOCATION';
	public static final String PARTIAL_SUBSEQUENT_ALLOCATION = 'PARTIAL_SUBSEQUENT_ALLOCATION';

	// Program Overview
	public static final Integer DECIMAL_MAX_VALUE = 9999;
	public static final String BREAKOUT = 'Breakout';
	public static final String NON_PROGRAMMATIC_INITIATIVE = 'Non Programmatic Initiative';
	public static final String UTILITY_ANNOUNCEMENT = 'utility:announcement';
	public static final String UTILITY_PAYMENT_GATEWAY = 'utility:payment_gateway';
	public static final String UTILITY_APPLIED_AMOUNT = 'utility:applied_amount';
	public static final String INITIAL_APPROVAL = 'Initial Approval';

	// Strategic Locations
	public static final String REVIEW_STATUS = 'Review_Status__c';
	public static final String PENDING_ADDITION = 'Pending Addition';
	public static final String PENDING_REMOVAL = 'Pending Removal';

	//FileGroup
	public static final String FILE_GROUP_EDIT_PERMISSION = 'File_Group_Edit_Access';

	// Permissioning
	public static final String AMENDMENT_ACCESS_ERROR = 'You do not have access to create Amendment record';
	//Touchpoint Summary Batch
	public static final String CONTACTTOUCHPOINTSUMMARYUPDATEFAILED = 'Contact Touchpoint Summary Update Failed';
	public static final String CONTACTTOUCHPOINTSUMMARYBATCHJOBFAILED = 'Contact Touchpoint Summary Batch Job Failed';

	//Generic Access Error
	public static final String NO_ACCESS = 'You do not have the permission to perform this action';
	public static final String MORE_RECORDS_FOR_DELETE = 'You cannot delete more than {0} records in this transaction';
	public static final String NO_RECORDS_SELECTED = 'No records have been selected for deletion. Please select one or more records';
	public static final String NO_DELETE_ACCESS = 'You do not have the required permissions to delete this record. Please contact your administrator for help.';

	//Segment
	public static final String BFF = 'Bloomberg Family Foundation';

	//Exception Messages
	public static final String LINKING = 'Linking';
	public static final String UNLINKING = 'Unlinking';
	public static final String GENERIC_EXCEPTION = '{0} failed, could not update {1} record. Please contact Administrator for Help.';
    public static String deceasedSuffix = '(Deceased)';
    public static String dncSuffix = '(Do Not Contact)';

	//Staff Roles
	public static final Set<String> EXECUTIVE_ASSISTANT = new Set<String>{ 'executive assistant','ea'};
    public static final Set<String> ASSISTANT = new Set<String>{'assistant','personal assistant','pa'};
    public static final Set<String> SCHEDULER = new Set<String>{'scheduler'};
    public static final Set<String> CHIEF_OF_STAFF = new Set<String>{'chief of staff'};

    // Confidential Briefing RecordTypes
	public static final String ORG_BRIEFING = 'Organization_Briefing';
	public static final String CONTACT_BRIEFING = 'Contact_Briefing';
	public static final String LIST_BRIEFING = 'List_Briefing';
    
	//Program Highlights
	public static final String SUBMITTED = 'Submitted';
	public static final String INCLUDE_AS_MRB_HIGHLIGHT = 'Include_As_MRB_Highlight__c';
	public static final String HIGHLIGHT_INTERACTION = 'Highlight_Interaction__c';
	public static final String HIGHLIGHT = 'Highlight';
	public static final String ORGANIZATION = 'Organization';
	public static final String CONTACT = 'Contact';
	public static final String DESCRIPTION = 'Description__c';
	public static final String REVIEWED = 'Reviewed';
	public static final String PUBLISH_TO_CITYVIEW = 'Publish_To_CityView__c';
	public static final String CITYVIEW_HIGHLIGHT_DESCRIPTION = 'CityView_Highlight_Description__c';
	public static final String INCLUDE_IN_CITYVIEW = 'Include_In_CityView__c';

	public static final String READY_FOR_APPROVAL = 'Ready for Approval';
	public static final String VALUE_YES = 'Yes';
	public static final String VALUE_NO = 'No';
}