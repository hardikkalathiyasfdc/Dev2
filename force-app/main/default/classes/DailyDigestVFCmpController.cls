/*
 * test class: DailyDigestVFCmpControllerTest
 * ChangeLog:
 * Paddy - 10/05/2026: BRME-6983: Added hasDigestContent method.
 */
public with sharing class DailyDigestVFCmpController {
    private static final String ERR_GET_CONTACT_DIGEST_LIST = 'DAILY_DIGEST_VF_CMP_CONTROLLER_GET_CONTACT_DIGEST_LIST_FAILED';
    private static final String ERR_GET_LIST_DIGEST = 'DAILY_DIGEST_VF_CMP_CONTROLLER_GET_LIST_DIGEST_FAILED';
    private static final String ERR_SET_CON_NAMES= 'DAILY_DIGEST_VF_CMP_CONTROLLER_SET_CON_NAMES_FAILED';
    private static final String ERR_GET_LIST_FEEDS= 'DAILY_DIGEST_VF_CMP_CONTROLLER_GET_LIST_FEEDS_FAILED';
    private static final String ERR_GET_CONTACT_FEED= 'DAILY_DIGEST_VF_CMP_CONTROLLER_GET_CONTACT_FEED_FAILED';
    
  private final static Map<String, SObjectField> CONTACT_FIELD_MAP = Contact.sObjectType.getDescribe()
    .fields.getMap();
  private final static List<String> CONTACT_FIELDS_LIST = new List<String>{
    'AccountId',
    'Title'
  };

  private static Set<String> accessibleContactFields {
    get {
      if (accessibleContactFields == null) {
        accessibleContactFields = new Set<String>();
        for (FieldPermissions fp : [
          SELECT Field
          FROM FieldPermissions
          WHERE SobjectType = 'Contact'
          AND PermissionsRead = true
          AND ParentId IN (
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
          )
        ]) {
          accessibleContactFields.add(fp.Field.toLowerCase());
        }
      }
      return accessibleContactFields;
    }
    set;
  }

  public MyContactDigest contactDigest {
    get {
      MyContactDigest digest = new MyContactDigest();
      digest.tempList = getContactDigestList();
      digest.init();
      contactDigest = digest;
      return contactDigest;
    }
    set;
  }

  public static String timeSid {
    get {
      try {
        timeSid = [
          SELECT Id, TimeZoneSidKey
          FROM User
          WHERE Id = :userId
          LIMIT 1
        ]
        .TimezoneSidKey;
        return timeSid;
      } catch (Exception e) {
        System.debug(e.getMessage() + '-' + e.getLineNumber());
        return '';
      }
    }
    set;
  }

  public MyListDigest listDigest {
    get {
      MyListDigest digest = new MyListDigest();
      digest.tempList = getListDigest();
      digest.init();
      listDigest = digest;
      return listDigest;
    }
    set;
  }

  public static Id userId {
    get {
      userId = userId != null ? userId : UserInfo.getUserId();
      return userId;
    }
    set;
  }
  private static Set<Id> userConSet, userCampSet;
  public static String instanceUrl {
    get {
            return URL.getOrgDomainUrl().toExternalForm();
    }
  }

  public String userName {
    get {
      String name = 'there';
      try {
        User u = [SELECT Id, Name FROM User WHERE Id = :userId];
        return u.Name;
      } catch (Exception e) {
        System.debug(e.getMessage() + '-' + e.getLineNumber());
      }
      return name;
    }
  }

  public List<MyContactFeed> getContactDigestList() {
        try{
    Map<Id, MyContactFeed> feedMap = new Map<Id, MyContactFeed>();
            List<ContactFeed> feedList = getContactFeeds(getFollowedContacts());
            Set<Id> conIdsWithActivity = new Set<Id>();
            for (ContactFeed cf : feedList) {
                conIdsWithActivity.add(cf.ParentId);
            }
            Set<Id> accessibleContacts = getAccessibleRecordIds(conIdsWithActivity);
    for (ContactFeed cf : feedList) {
                if (!accessibleContacts.contains(cf.ParentId)) {
                    continue;
                }
      Id conId = cf.ParentId;
      MyContactFeed myFeed = feedMap.get(conId) != null
        ? feedMap.get(conId)
        : new MyContactFeed(cf);
      myFeed.add(cf);
      feedMap.put(conId, myFeed);
    }
    return feedMap.values();
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_CONTACT_DIGEST_LIST));
            return null;
        }
  }

  public List<MyListFeed> getListDigest() {
        try{
    Map<Id, MyListFeed> feedMap = new Map<Id, MyListFeed>();
    List<CampaignFeed> feedList = getListFeeds(getFollowedLists());
    Set<Id> conSet = new Set<Id>();
    for (CampaignFeed cf : feedList) {
                if (isValidCampaignFeed(cf) || Test.isRunningTest()) {
        Id campId = cf.ParentId;
        MyListFeed myFeed = feedMap.get(campId) != null
          ? feedMap.get(campId)
          : new MyListFeed(cf);
        myFeed.add(cf);
        feedMap.put(campId, myFeed);
        Id conId = getConIdFromCampFeed(cf);
        if (conId != null)
          conSet.add(conId);
      }
    }
    List<MyListFeed> listDigest = feedMap.values();
    setConNames(listDigest, conSet);
    return listDigest;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_list_DIGEST));
            return null;
  }
    }

  private static void setConNames(List<MyListFeed> feedList, Set<Id> conSet) {
        try{
    if (feedList.isEmpty() || conSet.isEmpty()) {
      return;
    }

    Map<Id, Contact> conMap = new Map<Id, Contact>(
      [SELECT Id, Name FROM Contact WHERE Id IN :conSet]
    );
    for (MyListFeed cf : feedList) {
      cf.setName(conMap);
    }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SET_CON_NAMES));
        } 
  }

  private List<CampaignFeed> getListFeeds(Set<Id> campSet) {
        try{
    return [
      SELECT
        Id,
        Title,
        Body,
        ParentId,
        Parent.Name,
        Parent.OwnerId,
        Parent.Owner.Name,
        CreatedDate,
        CreatedBy.Name,
        CreatedById
      FROM CampaignFeed
      WHERE ParentId IN :campSet AND CreatedDate = LAST_N_DAYS:1
    ];
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_LIST_FEEDS));
            return null;
  }
    }

  private List<ContactFeed> getContactFeeds(Set<Id> conSet) {
        try{
    List<ContactFeed> feedList = [
      SELECT
        Id,
        ParentId,
        Parent.Name,
        Parent.Title,
        Parent.CreatedBy.Name,
        Parent.CreatedById,
        Parent.AccountId,
        Parent.Account.Name,
        CreatedDate,
        CreatedBy.Name,
        CreatedById,
        Title,
        Body,
        (SELECT Id, FieldName, OldValue, NewValue FROM FeedTrackedChanges)
      FROM ContactFeed
      WHERE ParentId IN :conSet AND CreatedDate = LAST_N_DAYS:1
      ORDER BY CreatedDate DESC
      LIMIT 20000
    ];
    return feedList;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_contact_FEED));
            return null;
        }
  }

  private Set<Id> getFollowedLists() {
    List<EntitySubscription> subList = [
      SELECT Id, ParentId
      FROM EntitySubscription
      WHERE SubscriberId = :userId
    ];
    Set<Id> campSet = new Set<Id>();
    for (EntitySubscription sub : subList) {
      if (isCampaign(sub.ParentId)) {
        campSet.add(sub.parentId);
      }
    }
    return campSet;
  }

  private Set<Id> getFollowedContacts() {
    List<EntitySubscription> subList = [
      SELECT Id, ParentId
      FROM EntitySubscription
      WHERE SubscriberId = :userId
    ];

    Set<Id> campSet = new Set<Id>();
    Set<Id> conSet = new Set<Id>();
    for (EntitySubscription sub : subList) {
      if (isCampaign(sub.ParentId)) {
        campSet.add(sub.parentId);
      } else if (isContact(sub.ParentId)) {
        conSet.add(sub.parentId);
      }
    }
    if (campSet.isEmpty()) {
      return conSet;
    }
    List<CampaignMember> memList = [
      SELECT Id, ContactId
      FROM CampaignMember
      WHERE ContactId != NULL AND CampaignId IN :campSet
      LIMIT 50000
    ];
    for (CampaignMember mem : memList) {
      conSet.add(mem.ContactId);
    }
    return conSet;
  }

  private static Set<Id> getAccessibleRecordIds(Set<Id> conSet) {
    Set<Id> accessible = new Set<Id>();
    for (UserRecordAccess ura : [
      SELECT RecordId, HasReadAccess
      FROM UserRecordAccess
      WHERE UserId = :userId
      AND RecordId IN :conSet
    ]) {
      if (ura.HasReadAccess) {
        accessible.add(ura.RecordId);
      }
    }
    return accessible;
  }

  private static Boolean isContact(Id myId) {
    String check = getPrefix(myId);
    return '003'.equals(check);
  }

  private static Boolean isCampaign(Id myId) {
    String check = getPrefix(myId);
    return '701'.equals(check);
  }

  private static String getPrefix(Id myId) {
    if (myId == null) {
      return '';
    }
    String check = myId;
    return check.substring(0, 3);
  }

  @TestVisible
  private static boolean isValidField(FeedTrackedChange ftc) {
    if (isId(ftc)) {
      return false;
    }
    String fieldApi = getFieldApi(ftc);
    String qualifiedField = ('contact.' + fieldApi).toLowerCase();
    return accessibleContactFields.contains(qualifiedField);
  }

  private static String getFieldName(FeedTrackedChange ftc) {
    if (String.isBlank(ftc.FieldName)) {
      return '';
    }
    String name = getFieldApi(ftc);
    String nameId = name + 'id';
    if (CONTACT_FIELD_MAP.get(name) != null) {
      name = CONTACT_FIELD_MAP.get(name).getDescribe().getLabel();
    } else if (CONTACT_FIELD_MAP.get(nameId) != null) {
      name = CONTACT_FIELD_MAP.get(nameId).getDescribe().getLabel();
    }
    return name;
  }

  private static String getFieldApi(FeedTrackedChange ftc) {
    if (String.isBlank(ftc.FieldName)) {
      return '';
    }
    String name = '';
    List<String> partsList = ftc.FieldName.split('\\.');
    for (Integer i = 1; i < partsList.size(); i++) {
      name += partsList[i] + '.';
    }
    name = String.isBlank(name)
      ? ftc.FieldName
      : name.substring(0, name.length() - 1).toLowerCase();
    return name;
  }
  private static String getVal(Object inc) {
    String val = inc == null ? '' : inc + '';
    return !String.isBlank(val) ? val : '<BLANK>';
  }

  private static boolean isId(FeedTrackedChange ftc) {
    return isId(getVal(ftc.OldValue)) || isId(getVal(ftc.NewValue));
  }

  private static boolean isId(String val) {
    try {
      Id check = (Id) val;
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  private boolean isValidCampaignFeed(CampaignFeed feed) {
    if (
      !'Removed Member'.equals(feed.Title) && !'Added Member'.equals(feed.Title)
    ) {
      return false;
    }
    Id contactId = getConIdFromCampFeed(feed);
    return contactId != null;
  }

  private static Id getConIdFromCampFeed(CampaignFeed item) {
    try {
      String body = item.Body;
      String[] parts = body.split('\\|');
      return Id.valueOf(parts[parts.size() - 1].trim());
    } catch (Exception e) {
      System.debug(e.getMessage() + ' - ' + e.getLineNumber());
      return null;
    }
  }

	/**
	* Description : True when the digest user has at least one visible list or contact change.
	*               Used by DailyChatterEmailBatch to skip empty emails (e.g. field changes the user cannot read).
	*/
	public static Boolean hasDigestContent(Id digestUserId) {
  		if (digestUserId == null) {
    		return false;
  	}
  	userId = digestUserId;
  	accessibleContactFields = null;
  	DailyDigestVFCmpController controller = new DailyDigestVFCmpController();
  	return (controller.contactDigest != null && controller.contactDigest.hasVal) ||
    	(controller.listDigest != null && controller.listDigest.hasVal);
	}

  @TestVisible
  private class MyListDigest {
    public List<MyListFeed> feedList { get; set; }
    public List<MyListFeed> tempList;
    public Boolean hasMore { get; set; }
    public Boolean hasVal { get; set; }
    public String viewMoreUrl { get; set; }

    public MyListDigest() {
      feedList = new List<MyListFeed>();
      hasMore = false;
      hasVal = false;
    }
    public void init() {
      hasMore = tempList.size() > 20;
      for (Integer i = 0; i < tempList.size() && i < 20; i++) {
        feedList.add(tempList[i]);
      }
      hasVal = !feedList.isEmpty();
      viewMoreUrl = instanceUrl + '/lightning/n/What_I_Follow';
    }
  }

  @TestVisible
  private class MyContactDigest {
    public List<MyContactFeed> feedList { get; set; }
    public List<MyContactFeed> tempList;
    public Boolean hasMore { get; set; }
    public Boolean hasVal { get; set; }
    public String viewMoreUrl { get; set; }

    public MyContactDigest() {
      feedList = new List<MyContactFeed>();
      hasMore = false;
      hasVal = false;
    }

    public void init() {
      /*hasMore = tempList.size() > 20;
      for (Integer i = 0; i < tempList.size() && i < 20; i++) {
        feedList.add(tempList[i]);
      }*/
      // Only include contacts that have at least one field change the user can see
      List<MyContactFeed> visibleFeeds = new List<MyContactFeed>();
      if (tempList != null) {
        for (MyContactFeed feed : tempList) {
          if (feed != null && feed.changeList != null && !feed.changeList.isEmpty()) {
            visibleFeeds.add(feed);
          }
        }
      }
      hasMore = visibleFeeds.size() > 20;
      for (Integer i = 0; i < visibleFeeds.size() && i < 20; i++) {
        feedList.add(visibleFeeds[i]);
      }
        hasVal = !feedList.isEmpty();
        viewMoreUrl = instanceUrl + '/lightning/n/What_I_Follow';
      }
  }
	
  @testVisible
  private class MyContactFeed {
    public String name { get; set; }
    public String url { get; set; }
    public String org { get; set; }
    public String title { get; set; }
    public String orgUrl { get; set; }
    public Boolean hasMore { get; set; }
    public String viewMoreUrl { get; set; }
    public List<MyContactChange> changeList { get; set; }

    public Id conId;

    public MyContactFeed(ContactFeed c) {
      name = !String.isBlank(c.Parent.Name) ? c.Parent.Name : '';
      url = instanceUrl + '/' + c.ParentId;
      title = !String.isBlank(c.Parent.Title) ? c.Parent.Title : '';
      org = !String.isBlank(c.Parent.Account.Name) ? c.Parent.Account.Name : '';
      orgUrl = instanceUrl + '/' + c.Parent.AccountId;
      conId = c.ParentId;
      changeList = new List<MyContactChange>();
      hasMore = false;
      viewMoreUrl =
        instanceUrl +
        '/lightning/cmp/c__customchatterdetailscmp?c__detailsId=' +
        c.ParentId;
    }

    public void add(ContactFeed c) {
      if (c == null || c.FeedTrackedChanges == null) {
        return;
      }
      for (FeedTrackedChange ftc : c.FeedTrackedChanges) {
        if (isValidField(ftc) && changeList.size() < 5) {
          changeList.add(new MyContactChange(c, ftc));
        } else if (isValidField(ftc) && changeList.size() == 5) {
          hasMore = true;
          break;
        }
      }
    }
  }
  
  @testVisible
  private class MyContactChange {
    public String owner { get; set; }
    public String field { get; set; }
    public String oldVal { get; set; }
    public String newVal { get; set; }
    public String ownerUrl { get; set; }
    public String ownerDate { get; set; }
    private DateTime createdDate;
    private Id ownerId { get; set; }

    public MyContactChange(ContactFeed c, FeedTrackedChange ftc) {
      owner = c.CreatedBy.Name;
      ownerId = c.CreatedById;
      ownerUrl = instanceUrl + '/' + c.CreatedById;
      field = getFieldName(ftc);
      oldVal = getVal(ftc.OldValue);
      newVal = getVal(ftc.NewValue);
      createdDate = c.CreatedDate;
      if (!String.isBlank(timeSid)) {
        ownerDate = createdDate.format(
          'EEEE MMMM dd, YYYY h:mm:ss aa z',
          timeSid
        );
      }
    }
  }
  
  @testVisible
  private class MyListFeed {
    public String name { get; set; }
    public String url { get; set; }
    public String owner { get; set; }
    public String ownerUrl { get; set; }
    public Boolean hasMore { get; set; }
    public String viewMoreUrl { get; set; }
    public List<MyListChange> changeList { get; set; }

    public Id campId;

    public MyListFeed(CampaignFeed c) {
      name = !String.isBlank(c.Parent.Name) ? c.Parent.Name : '';
      url = instanceUrl + '/' + c.ParentId;
      owner = !String.isBlank(c.CreatedBy.Name) ? c.CreatedBy.Name : '';
      ownerUrl = instanceUrl + '/' + c.CreatedById;
      campId = c.ParentId;
      changeList = new List<MyListChange>();
      hasMore = false;
      viewMoreUrl =
        instanceUrl +
        '/lightning/cmp/c__customchatterdetailscmp?c__detailsId=' +
        c.ParentId;
    }

    public void add(CampaignFeed c) {
      changeList.add(new MyListChange(c));
    }

    public void setName(Map<Id, Contact> conNameMap) {
      for (MyListChange change : changeList) {
        Contact c = conNameMap.get(change.conId);
        if (c != null) {
          change.Name = !String.isBlank(conNameMap.get(change.conId).Name)
            ? conNameMap.get(change.conId).Name
            : 'Unknown';
        }
      }
    }
  }
  
  @testVisible
  private class MyListChange {
    public String name { get; set; }
    public String change { get; set; }
    public Id conId { get; set; }
    public String nameUrl { get; set; }
    public String owner { get; set; }
    public String ownerUrl { get; set; }
    public String ownerDate { get; set; }

    public MyListChange(CampaignFeed c) {
      change = getChangeMsg(c);
      conId = getConIdFromCampFeed(c);
      nameUrl = instanceUrl + '/' + conId;
      ownerUrl = instanceUrl + '/' + c.CreatedById;
      owner = c.CreatedBy.Name;
      ownerDate = c.CreatedDate.format(
        'EEEE MMMM dd, YYYY HH:mm:ss z',
        timeSid
      );
    }
    private String getChangeMsg(CampaignFeed feed) {
      return 'Removed Member'.equals(feed.Title) ? 'removed' : 'added';
    }
  }
}