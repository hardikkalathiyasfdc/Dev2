global without sharing class NewsCustomController {

    private static final String ERR_CLASS_FAILED = 'NewsCustomController_CLASS_FAILED';

    //jlu apply update to use user's locale's settings
    @AuraEnabled(cacheable=true)
    public static string getTimeZone() {
        String timeZone = 'America/New_York';
        try {
            User u = [Select Id, TimeZoneSidKey from User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            timeZone = !String.isBlank(u.TimeZoneSidKey) ? u.TimeZoneSidKey : timeZone;
            return timeZone;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return timeZone;
    }

    @AuraEnabled(cacheable=true)
    public static GoogleNewsRss[] newsGrabber( String recId ) {
        GoogleNewsRss[] newsItemsLstSorted = new GoogleNewsRss[0];
        try {
            //Google news enhancement for contacts without org - moved code to method getUrl
            String endpoint = getUrl(recId);
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            httpReq.setMethod( 'GET' );
            httpReq.setEndpoint( endpoint ); 
            httpRes = http.send( httpReq ); 
            endpoint = httpRes.getHeader('Location');
            if(httpRes.getStatusCode() == 301 || httpRes.getStatusCode() == 302) {    
                httpReq.setEndpoint(endpoint);
                httpRes = new Http().send(httpReq);
            }
            String xmlBody = httpRes.getBody();
            XmlStreamReader readerPass = new XmlStreamReader(xmlBody);
            GoogleNewsRss[] newsItemsLst = parseNewsItems(readerPass);
            //newsItemsLst.sort();
            Integer counter = 0;
            while(counter<10 && counter<newsItemsLst.size()) {
                newsItemsLstSorted.add(newsItemsLst[counter++]);
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return newsItemsLstSorted;
    }

    public static GoogleNewsRss[] parseNewsItems(XmlStreamReader reader) {
        GoogleNewsRss[] newsItems = new GoogleNewsRss[0];
        try {
            Boolean isSafeToGetNextXmlElement = true;
            while(isSafeToGetNextXmlElement) {
                // Start at the beginning of the news and make sure that it is a news
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('item' == reader.getLocalName()) {
                        // Pass the news item to the parseNewsItem method (below) 
                        GoogleNewsRss news = parseNewsItem(reader);
                        newsItems.add(news);
                    }
                }
                if (reader.hasNext()) {
                    reader.next();
                } else {
                    isSafeToGetNextXmlElement = false;
                    break;
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return newsItems;
    }

    // Parse through the XML, determine the start tag and the characters
    static GoogleNewsRss parseNewsItem(XmlStreamReader reader) {
        GoogleNewsRss newsItem = new GoogleNewsRss();
        try {
            String tagName;
            boolean isSafeToGetNextXmlElement = true;
            while(isSafeToGetNextXmlElement) {
                if (reader.getEventType() == XmlTag.END_ELEMENT && 'item' == reader.getLocalName()) {
                    break;
                } else if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    if ('title' == reader.getLocalName()) {
                        tagName = 'title';
                    }else if ('link' == reader.getLocalName()) {
                        tagName = 'link';
                    }else if ('description' == reader.getLocalName()) {
                        tagName = 'description';
                        boolean nextHtmlVal = true;
                        while(nextHtmlVal) {
                            if (reader.getEventType() == XmlTag.END_ELEMENT && 'description' == reader.getLocalName()) {
                                break;
                            } else if (reader.getEventType() == XmlTag.CHARACTERS && 'p' == reader.getText()) {
                                if (reader.hasNext()) {
                                    reader.next();
                                    newsItem.descVal = reader.getText();
                                    break;
                                }                                                   
                            }
                            if (reader.hasNext()) {
                                    reader.next();
                                } else {
                                    nextHtmlVal = false;
                                    break;
                                }
                        }
                    }    
                    else if ('pubDate' == reader.getLocalName()) {
                        tagName = 'pubDate';
                    }
                } else if (reader.getEventType() == XmlTag.CHARACTERS && tagName != null) {
                    if (tagName == 'title') {
                        newsItem.title = reader.getText();
                    }else if (tagName == 'link') {
                        newsItem.link = reader.getText();
                    }else if (tagName == 'description') {
                        newsItem.descVal = reader.getText();
                    }else if (tagName == 'pubDate') {
                        String dateTimeStr = reader.getText();
                        newsItem.pubDate = convertToDateTime(dateTimeStr);
                    }
                    tagName = null;
                }

                if (reader.hasNext()) {
                    reader.next();
                } else {
                    isSafeToGetNextXmlElement = false;
                    break;
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return newsItem;
    } 

    public static DateTime convertToDateTime(String strDateTime) {
        DateTime dateTimeIns;
        try {
            Map <String, Integer> monthNames = new Map <String, Integer> {'Jan'=>1, 'Feb'=>2, 'Mar'=>3, 'Apr'=>4, 'May'=>5, 'Jun'=>6, 'Jul'=>7, 'Aug'=>8, 'Sep'=>9, 'Oct'=>10, 'Nov'=>11, 'Dec'=>12};
            String dateStr = strDateTime.replace(',','');
            List <String> stringParts = dateStr.split(' ');
            List <String> timeParts = stringParts[4].split(':');
            dateTimeIns = DateTime.newInstanceGmt(Integer.valueOf(stringParts[3]), 
                            monthNames.get(stringParts[2]), Integer.valueOf(stringParts[1]), 
                            Integer.valueOf(timeParts[0]), Integer.valueOf(timeParts[1]), 
                            Integer.valueOf(timeParts[2])
                          );           
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }  
        return dateTimeIns;       
    }
    
    //Google news enhancement for contacts without org
    private static String getUrl(String recId) {
        String endpoint = System.Label.Google_News_Endpoint;
        endpoint = endpoint.replace('searchstring', getSearchTerms(recId));
        return endpoint;
    }

    //Google news enhancement for contacts without org
    private static String getSearchTerms(String recId) {
        if(String.isBlank(recId) || 'HomePage'.equals(recId)) {
            return 'Bloomberg Philanthropies';
        }
        String objType = String.valueOf(Id.valueOf(recId).getSobjectType());
        String searchTerms = ''; 
        if('contact'.equalsIgnoreCase(objType)) {
            searchTerms = getContactTerms(recId);
        } else if('account'.equalsIgnoreCase(objType)) {
            searchTerms = getOrgTerms(recId);
        }
        searchTerms = String.isBlank(searchTerms) ? 'Bloomberg Philanthropies' : searchTerms;
        return EncodingUtil.urlEncode(searchTerms, 'UTF-8');
    }

    //Google news enhancement for contacts without org
    private static String getContactTerms(String recId) {
        Contact c = [SELECT FirstName, LastName, AccountId, Account.Name, Title FROM Contact WHERE Id =: recId LIMIT 1];
        String searchTerms = '';
        Boolean hasOrg = !String.isBlank(c.AccountId) && !String.isBlank(c.Account.Name) && !'-'.equals(c.Account.Name);
        Boolean hasTitle = !String.isBlank(c.Title);
        String name = !String.isBlank(c.FirstName) ? c.FirstName+ ' ':'';
        name += c.LastName;
        name = name;
        Set<String> dupeSet = new Set<String>();
        searchTerms = name;
        if(hasOrg || hasTitle) {
            String curTerms = name+' AND ';
            curTerms += hasOrg ? '"'+c.Account.Name+'"' : '"'+c.Title+'"';
            dupeSet.add(c.Account.Name);
            searchTerms = curTerms;
        }
        List<Employment_History_and_Board_Membership__c> historyList = [SELECT Id, Contact_Name__r.Name, Organization_Name__r.Name FROM Employment_History_and_Board_Membership__c WHERE Contact_Name__c =: recId AND Organization_Name__r.Name != NULL LIMIT 20];
        for(Employment_History_and_Board_Membership__c hist : historyList) {
            String curTerms = hist.Organization_Name__r.Name;
            if(!dupeSet.contains(curTerms)) {
                searchTerms += !String.isBlank(searchTerms) ? ' OR ' : '';
                searchTerms += '"'+curTerms+'"';
            }
            dupeSet.add(curTerms);
        }
        return searchTerms;
    }

    //Google news enhancement for contacts without org
    private static String getOrgTerms(String recId) {
        Account acct = [SELECT Id, Name FROM Account WHERE Id = :recId];
        return acct.Name;
    }
    
    global class GoogleNewsRss implements Comparable{
        @AuraEnabled public String title{get;set;}
        @AuraEnabled public String link{get;set;}
        @AuraEnabled public String descVal{get;set;}
        @AuraEnabled public DateTime pubDate{get;set;}
        
        global Integer compareTo(Object compareTo) {
            GoogleNewsRss comparePubDate = (GoogleNewsRss)compareTo;
            if (pubDate == comparePubDate.pubDate) return 0;
            if (pubDate < comparePubDate.pubDate) return 1;
            return -1;     
        }
    }  
}