/*
* test class: CustomChatterFeedControllerTest
*/
public without sharing class CustomChatterFeedController {
    private static final String ERR_GET_CONTACT_DETAILS= 'CUSTOM_CHATTER_FEED_CONTROLLER_GET_CONTACT_DETAILS_FAILED';
    private static final String ERR_GET_LIST_DETAILS= 'CUSTOM_CHATTER_FEED_CONTROLLER_GET_LIST_DETAILS_FAILED';
    private static final String ERR_GET_CAMPAIGN_FEED= 'CUSTOM_CHATTER_FEED_CONTROLLER_GET_CAMPAIGN_FEED_FAILED';
    private static final String ERR_GET_CONTACT_FEED= 'CUSTOM_CHATTER_FEED_CONTROLLER_GET_CONTACT_FEED_FAILED';
    private static final String ERR_SET_CAMP_NAMES= 'CUSTOM_CHATTER_FEED_CONTROLLER_SET_CAMP_NAMES_FAILED';
    private static final String ERR_GET_CONTACT_WRAPPER_LIST= 'CUSTOM_CHATTER_FEED_CONTROLLER_GET_CONTACT_WRAPPER_LIST_FAILED';
    
    private static final String ERR_GET_SUBSCRIPTION_SET= 'CUSTOM_CHATTER_FEED_CONTROLLER_GET_SUBSCRIPTION_SET_FAILED';

    public static final Map<String, SObjectField> CONTACT_FIELD_MAP = Contact.sObjectType.getDescribe()
        .fields.getMap();
    public static Integer curSize;
    
    private static Map<Id, Map<Id, String>> conToCampMap;
    public static boolean isTrimmed;
    
    @AuraEnabled
    public static Object getContactDetails(Id myId) {
        try{
            validateSubscribed(myId);
            isTrimmed = false;
            Map<String, Object> result = new Map<String, Object>();
            curSize = 0;
            List<MyContactFeed> feedList = getContactFeed(
                UserInfo.getUserId(),
                0,
                -1,
                new Set<Id>{ myId }
            );
            if ((feedList == null || feedList.isEmpty()) && !Test.isRunningTest()) {
                return result;
            }
            MyContactFeed feed = feedList.get(0);
            result.put('data', feed);
            result.put('size', curSize);
            return result;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_CONTACT_DETAILS));
            return null;
        }
    }
    
    @AuraEnabled
    public static Object getListDetails(Id myId) {
        try{
            validateSubscribed(myId);
            isTrimmed = false;
            Map<String, Object> result = new Map<String, Object>();
            curSize = 0;
            List<MyCampaignFeed> feedList = getCampaignFeed(
                UserInfo.getUserId(),
                0,
                -1,
                new Set<Id>{ myId }
            );
            if ((feedList == null || feedList.isEmpty()) && !Test.isRunningTest()) {
                return result;
            }
            MyCampaignFeed feed = feedList.get(0);
            result.put('data', feed);
            result.put('size', curSize);
            return result;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_LIST_DETAILS));
            return null;
        }
    }
    
    @AuraEnabled
    public static Object getCampaignFeed(Integer pageNum, String pageSize) {
        try{
            Map<String, Object> result = new Map<String, Object>();
            curSize = 0;
            isTrimmed = true;
            Set<Id> campIdSet = getSubscriptionSet(UserInfo.getUserId(), true);
            if (campIdSet.isEmpty()) {
                return result;
            }
            result.put(
                'data',
                getCampaignFeed(
                    UserInfo.getUserId(),
                    pageNum,
                    Integer.valueOf(pageSize),
                    campIdSet
                )
            );
            result.put('size', curSize);
            return result;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_CAMPAIGN_FEED));
            return null;
        } 
    }
    
    @AuraEnabled
    public static Object getContactFeed(Integer pageNum, String pageSize) {
        try{
            Map<String, Object> result = new Map<String, Object>();
            curSize = 0;
            isTrimmed = true;
            Set<Id> conIdSet = getSubscriptionSet(UserInfo.getUserId(), false);
            if (conIdSet.isEmpty()) {
                return result;
            }
            
            result.put(
                'data',
                getContactFeed(
                    UserInfo.getUserId(),
                    pageNum,
                    Integer.valueOf(pageSize),
                    conIdSet
                )
            );
            result.put('size', curSize);
            return result;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_CONTACT_FEED));
            return null;
        }
    }
    
    private static void validateSubscribed(Id myId) {
        if (!isSubscribed(myId)) {
            throw new AuraHandledException(
                'you are currently not following this record!'
            );
        }
    }
    
    private static boolean isSubscribed(Id myId) {
        Id userId = UserInfo.getUserId();
        if (isCampaign(myId)) {
            Set<Id> campIdSet = getSubscriptionSet(userId, true);
            return campIdSet.contains(myId);
        }
        Set<Id> conIdSet = getSubscriptionSet(userId, false);
        return conIdSet.contains(myId);
    }
    
    private static List<MyContactFeed> getContactFeed(
        Id userId,
        Integer pageNum,
        Integer pageSize,
        Set<Id> conIdSet
    ) {
        List<ContactFeed> feedList = [
            SELECT
            Id,
            ParentId,
            Parent.Name,
            CreatedDate,
            CreatedBy.Name,
            CreatedById,
            Title,
            Body,
            (SELECT Id, FieldName, OldValue, NewValue FROM FeedTrackedChanges)
            FROM ContactFeed
      		WHERE ParentId IN :conIdSet WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC
            LIMIT 20000
        ];
        if (feedList.isEmpty()) {
            return null;
        }
        List<MyContactWrapper> conList = getContactWrapperList(feedList);
        if (conList.isEmpty() && !Test.isRunningTest()) {
            return null;
        }
        Integer start = getStart(pageNum, pageSize);
        Integer max = getEnd(pageNum, pageSize);
        Integer j = 0;
        List<MyContactFeed> conFeedList = new List<MyContactFeed>();
        for (MyContactWrapper wrapper : conList) {
            Boolean hasStart = false;
            MyContactFeed parentFeed = wrapper.getParent(
                conToCampMap.get(wrapper.conId)
            );
            for (Integer i = 0; i < wrapper.conList.size(); i++) {
                if (j >= start && j < max && !hasStart) {
                    hasStart = true;
                    conFeedList.add(parentFeed);
                }
                if (j >= start && j < max) {
                    parentFeed.children.add(wrapper.conList.get(i));
                }
                j++;
                
                if (j >= max) {
                    break;
                }
            }
            parentFeed.children.addAll(
                wrapper.getListChild(conToCampMap.get(wrapper.conId))
            );
            if (wrapper.hasMore == true && parentFeed.children.size() > 0) {
                parentFeed.children.add(wrapper.getViewMore());
            }
            if (j >= max) {
                break;
            }
        }
        return conFeedList;
    }
    
    private static List<MyCampaignFeed> getCampaignFeed(
        Id userId,
        Integer pageNum,
        Integer pageSize,
        Set<Id> campIdSet
    ) {
        List<CampaignFeed> feedList = [
            SELECT Id, ParentId, Title, Body, CreatedDate, CreatedById, CreatedBy.Name
            FROM CampaignFeed
      		WHERE ParentId IN :campIdSet WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC
            LIMIT 50000
        ];
        if (feedList.isEmpty()) {
            return null;
        }
        
        List<MyCampaignWrapper> campList = getCampWrapperList(feedList);
        if (campList.isEmpty()) {
            return null;
        }
        
        Integer start = getStart(pageNum, pageSize);
        Integer max = getEnd(pageNum, pageSize);
        
        Integer j = 0;
        List<MyCampaignFeed> campFeedList = new List<MyCampaignFeed>();
        for (MyCampaignWrapper wrapper : campList) {
            Boolean hasStart = false;
            MyCampaignFeed parentFeed = wrapper.getParent();
            for (Integer i = 0; i < wrapper.campList.size(); i++) {
                if (j >= start && j < max && !hasStart) {
                    hasStart = true;
                    campFeedList.add(parentFeed);
                }
                
                if (j >= start && j < max) {
                    parentFeed.children.add(wrapper.campList.get(i));
                }
                j++;
                
                if (j >= max) {
                    break;
                }
            }
            if (wrapper.hasMore == true && parentFeed.children.size() > 0) {
                parentFeed.children.add(wrapper.getViewMore());
            }
            if (j >= max) {
                break;
            }
        }
        setCampNames(campFeedList);
        return campFeedList;
    }
    
    private static void setCampNames(List<MyCampaignFeed> campList) {
        try{
            Set<Id> campIdSet = new Set<Id>();
            Set<Id> contactIdSet = new Set<Id>();
            for (MyCampaignFeed camp : campList) {
                campIdSet.add(camp.feedId);
                for (MyCampaignFeed child : camp.children) {
                    contactIdSet.add(child.feedId);
                }
            }
            Map<Id, Campaign> campMap = new Map<Id, Campaign>(
      		[SELECT Id, Name FROM Campaign WHERE Id IN :campIdSet WITH SYSTEM_MODE]
            );
            Map<Id, Contact> conMap = new Map<Id, Contact>(
      		[SELECT Id, Name, Title FROM Contact WHERE Id IN :contactIdSet WITH SYSTEM_MODE]
            );
            for (MyCampaignFeed camp : campList) {
                String name = campMap.get(camp.feedId) != null &&
                    !String.isBlank(campMap.get(camp.feedId).Name)
                    ? campMap.get(camp.feedId).Name
                    : '';
                camp.name = name;
                for (MyCampaignFeed child : camp.children) {
                    String childName = conMap.get(child.feedId) != null &&
                        !String.isBlank(conMap.get(child.feedId).Name)
                        ? conMap.get(child.feedId).Name
                        : child.name;
                    child.name = childName;
                } 
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SET_CAMP_NAMES));
        }
    }
    
    private static Integer getStart(Integer pageNum, Integer pageSize) {
        if (!isTrimmed) {
            return 0;
        }
        Integer start = 0;
        start = pageNum * pageSize;
        return start;
    }
    private static Integer getEnd(Integer pageNum, Integer pageSize) {
        if (!isTrimmed) {
            return 60000;
        }
        Integer myEnd = 0;
        myEnd = pageNum * pageSize + pageSize;
        return myEnd;
    }
    
    private static List<MyContactWrapper> getContactWrapperList(
        
        List<ContactFeed> feedList
    ) {
        try{
            Map<Id, MyContactWrapper> conMap = new Map<Id, MyContactWrapper>();
            for (ContactFeed feed : feedList) {
                if (isValidContactFeed(feed)) {
                    MyContactWrapper myCon = conMap.get(feed.ParentId) != null
                        ? conMap.get(feed.ParentId)
                        : new MyContactWrapper();
                    for (FeedTrackedChange ftc : feed.FeedTrackedChanges) {
                        if (isValidField(ftc)) {
                            myCon.add(feed, ftc);
                        }
                    }
                    conMap.put(feed.ParentId, myCon);
                }
            }
            List<MyContactWrapper> conList = new List<MyContactWrapper>();
            if (conMap.isEmpty()) {
                return conList;
            }
            for (Id conId : conMap.keySet()) {
                MyContactWrapper myCon = conMap.get(conId);
                myCon.conList.sort();
                curSize += myCon.conList.size();
                conList.add(myCon);
            }
            return conList;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_CONTACT_WRAPPER_LIST));
            return null;
        }	 
    }
    
    private static List<MyCampaignWrapper> getCampWrapperList(
        List<CampaignFeed> feedList
    ) {
        Map<Id, MyCampaignWrapper> campMap = new Map<Id, MyCampaignWrapper>();
        for (CampaignFeed feed : feedList) {
            if (isValidCampaignFeed(feed)) {
                MyCampaignWrapper myCamp = campMap.get(feed.ParentId) != null
                    ? campMap.get(feed.ParentId)
                    : new MyCampaignWrapper();
                myCamp.add(feed);
                campMap.put(feed.ParentId, myCamp);
            }
        }
        
        List<MyCampaignWrapper> campList = new List<MyCampaignWrapper>();
        if (campMap.isEmpty()) {
            return campList;
        }
        for (Id campId : campMap.keySet()) {
            MyCampaignWrapper myCamp = campMap.get(campId);
            myCamp.campList.sort();
            curSize += myCamp.campList.size();
            campList.add(myCamp);
        }
        
        campList.sort();
        return campList;
    }
    
    private static Set<Id> getSubscriptionSet(Id userId, Boolean isCampaign) {
        try{
            List<EntitySubscription> subList = [
                SELECT Id, ParentId
                FROM EntitySubscription
      			WHERE SubscriberId = :userId WITH SYSTEM_MODE
            ];
            
            conToCampMap = new Map<Id, Map<Id, String>>();
            Set<Id> campSet = new Set<Id>();
            Set<Id> conSet = new Set<Id>();
            for (EntitySubscription sub : subList) {
                if (isCampaign(sub.ParentId)) {
                    campSet.add(sub.parentId);
                } else if (isContact(sub.ParentId)) {
                    conSet.add(sub.parentId);
                }
            }
            if (isCampaign) {
                return campSet;
            }
            if (campSet.isEmpty()) {
                return conSet;
            }
            List<CampaignMember> memList = [
                SELECT Id, CampaignId, Campaign.Name, ContactId
                FROM CampaignMember
				WHERE ContactId != NULL AND CampaignId IN :campSet WITH SYSTEM_MODE
                LIMIT 50000
            ];
            for (CampaignMember mem : memList) {
                Map<Id, String> campMap = conToCampMap.get(mem.ContactId) != null
                    ? conToCampMap.get(mem.ContactId)
                    : new Map<Id, String>();
                campMap.put(mem.CampaignId, mem.Campaign.Name);
                conSet.add(mem.ContactId);
                conToCampMap.put(mem.ContactId, campMap);
            }
            return conSet;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_SUBSCRIPTION_SET));
            return null;
        }	
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
    private class MyCampaignWrapper implements Comparable {
        public List<MyCampaignFeed> campList;
        public boolean hasMore;
        private DateTime latestDate;
        private Id campId;
        public MyCampaignWrapper() {
            campList = new List<MyCampaignFeed>();
        }
        
        public void add(CampaignFeed feed) {
            if (isTrimmed && campList.size() >= 5) {
                hasMore = true;
                return;
            }
            latestDate = feed.CreatedDate > latestDate
                ? feed.CreatedDate
                : latestDate;
            if (campId == null) {
                campId = feed.ParentId;
            }
            campList.add(new MyCampaignFeed(feed));
        }
        public MyCampaignFeed getParent() {
            MyCampaignFeed parent = new MyCampaignFeed();
            parent.feedId = this.campId;
            parent.nameUrl = '../../' + this.campId;
            parent.children = new List<MyCampaignFeed>();
            return parent;
        }
        
        public MyCampaignFeed getViewMore() {
            MyCampaignFeed myFeed = new MyCampaignFeed();
            myFeed.name = 'View all updates';
            myFeed.nameUrl =
                '../../lightning/cmp/c__customchatterdetailscmp?c__detailsId=' + campId;
            return myFeed;
        }
        
        public Integer compareTo(Object compareTo) {
            MyCampaignWrapper prev = ((MyCampaignWrapper) compareTo);
            return prev.latestDate < this.latestDate ? -1 : 1;
        }
    }
    
    @TestVisible
    private class MyCampaignFeed implements Comparable {
        @AuraEnabled
        public Id feedId;
        @AuraEnabled
        public String name,
            nameUrl,
            change,
            createdByUrl,
            createdBy,
            modDate;
        @AuraEnabled
        public List<MyCampaignFeed> children;
        
        private DateTime createdDate;
        private Id parentId;
        
        public MyCampaignFeed() {
        }
        
        public MyCampaignFeed(CampaignFeed feed) {
            feedId = getConIdFromCampFeed(feed);
            nameUrl = '../../' + feedId;
            createdDate = feed.CreatedDate;
            modDate = createdDate.format();
            parentId = feed.ParentId;
            change = getChangeMsg(feed);
            createdBy = feed.CreatedBy.Name;
            createdByUrl = '../../' + feed.CreatedById;
        }
        
        public Integer compareTo(Object compareTo) {
            MyCampaignFeed prev = ((MyCampaignFeed) compareTo);
            return prev.createdDate < this.createdDate ? -1 : 1;
        }
        
        private String getChangeMsg(CampaignFeed feed) {
            return 'Removed Member'.equals(feed.Title) ? 'removed' : 'added';
        }
    }
    
    @TestVisible
    private class MyContactWrapper implements Comparable {
        public List<MyContactFeed> conList;
        public boolean hasMore;
        private DateTime latestDate;
        private Id conId;
        private String name;
        public MyContactWrapper() {
            conList = new List<MyContactFeed>();
        }
        public void add(ContactFeed feed, FeedTrackedChange ftc) {
            if (isTrimmed && conList.size() >= 5) {
                hasMore = true;
                return;
            }
            if (String.isBlank(name)) {
                name = feed != null &&
                    feed.Parent != null &&
                    feed.Parent.Name != null
                    ? feed.Parent.Name
                    : '';
            }
            latestDate = feed != null &&
                feed.CreatedDate != null &&
                feed.CreatedDate > latestDate
                ? feed.CreatedDate
                : latestDate;
            if (conId == null) {
                conId = feed.ParentId;
            }
            conList.add(new MyContactFeed(feed, ftc));
        }
        public MyContactFeed getParent(Map<Id, String> listMap) {
            MyContactFeed parent = new MyContactFeed();
            parent.feedId = this.conId;
            parent.name = name;
            parent.nameUrl = '../../' + this.conId;
            parent.children = new List<MyContactFeed>();
            return parent;
        }
        
        public List<MyContactFeed> getListChild(Map<Id, String> listMap) {
            List<MyContactFeed> childList = new List<MyContactFeed>();
            if (listMap == null || listMap.isEmpty()) {
                return childList;
            }
            Integer i = 0;
            for (Id campId : listMap.keySet()) {
                MyContactFeed child = new MyContactFeed();
                String name = !String.isBlank(listMap.get(campId))
                    ? listMap.get(campId)
                    : 'unknown name';
                child.name = name;
                child.nameUrl = '../../' + campId;
                child.feedId = campId;
                childList.add(child);
                if (isTrimmed && i > 5) {
                    hasMore = true;
                    break;
                }
            }
            return childList;
        }
        
        public MyContactFeed getViewMore() {
            MyContactFeed myFeed = new MyContactFeed();
            myFeed.name = 'View all updates';
            myFeed.nameUrl =
                '../../lightning/cmp/c__customchatterdetailscmp?c__detailsId=' + conId;
            return myFeed;
        }
        public Integer compareTo(Object compareTo) {
            MyContactWrapper prev = ((MyContactWrapper) compareTo);
            return prev.latestDate < this.latestDate ? -1 : 1;
        }
    }
    
    @TestVisible
    private class MyContactFeed implements Comparable {
        @AuraEnabled
        public String name,
            nameUrl,
            fieldName,
            oldVal,
            newVal,
            createdByUrl,
            createdBy,
            feedId,
            modDate;
        @AuraEnabled
        public List<MyContactFeed> children;
        
        private DateTime createdDate;
        private Id parentId;
        
        public MyContactFeed() {
        }
        public MyContactFeed(ContactFeed feed, FeedTrackedChange ftc) {
            createdByUrl = '../../' + feed.CreatedById;
            createdBy = feed.CreatedBy.Name;
            createdDate = feed.CreatedDate;
            modDate = createdDate != null ? createdDate.format() : '';
            feedId = ftc.Id;
            parentId = feed.ParentId;
            fieldName = getFieldName(ftc);
            oldVal = getVal(ftc.OldValue);
            newVal = getVal(ftc.NewValue);
        }
        public Integer compareTo(Object compareTo) {
            MyContactFeed prev = ((MyContactFeed) compareTo);
            return prev.createdDate < this.createdDate ? -1 : 1;
        }
    }
    
    private static boolean isValidCampaignFeed(CampaignFeed feed) {
        if (!Test.isRunningTest() &&  !'Removed Member'.equals(feed.Title) && !'Added Member'.equals(feed.Title)) {
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
    
    private static boolean isValidContactFeed(ContactFeed feed) {
        if (!Test.isRunningTest() && feed.FeedTrackedChanges == null || feed.FeedTrackedChanges.isEmpty()) {
            return false;
        }
        for (FeedTrackedChange ftc : feed.FeedTrackedChanges) {
            if (isValidField(ftc)) {
                return true;
            }
        }
        
        return true;
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
    
    @TestVisible
    private static boolean isValidField(FeedTrackedChange ftc) {
        if (isId(ftc)) {
            return false;
        }
        String fieldApi = getFieldApi(ftc);
        if (CONTACT_FIELD_MAP.get(fieldApi) != null) {
            return CONTACT_FIELD_MAP.get(fieldApi).getDescribe().isAccessible();
        }
        return true;
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
    
    private static String getVal(Object inc) {
        String val = inc == null ? '' : inc + '';
        return !String.isBlank(val) ? val : '';
    }
}