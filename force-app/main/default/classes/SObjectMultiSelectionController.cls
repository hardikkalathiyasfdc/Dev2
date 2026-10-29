public with sharing class SObjectMultiSelectionController {

    private static final String CAMPAIGN = 'Campaign';
    private static final String TAGS = 'Tag__c';
    private static final String CONTACT = 'Contact';
    private static final String ASSOCIATION = 'Association__c';
    private static final String ERR_CLASS_FAILED = 'SObjectMultiSelectionController_CLASS_FAILED';
 
    public class SelectedItem {
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public String label {get; set;}
    }

    public class ResultWrapper {
        @AuraEnabled
        public String Id {get; set;}
        @AuraEnabled
        public String Name {get; set;}
        @AuraEnabled
        public String subtitle {get; set;}
        @AuraEnabled
        public Contact contact {get; set;}
        @AuraEnabled
        public Association__c association {get; set;}

        public ResultWrapper(String id, String name) {
            this.Id = id;
            this.Name = name;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchFilterLookUpValues(String searchKeyWord, String excludeIds, String objectAPIName, String recordTypeId) {
        List<ResultWrapper> reultWrapper = new List<ResultWrapper>();
        try {
            String searchKey = '%' + searchKeyWord + '%';
            Set<String> excludeitems = new Set<String>();
            List<SelectedItem> selectedItems = (List<SelectedItem>)JSON.deserialize(excludeIds, List<SelectedItem>.class);
            for(SelectedItem item : selectedItems) {
                excludeitems.add(item.value);
            }
            String soqlQuery;
            if(String.isNotBlank(objectAPIName)) {
                String extraFields = '';
                if (CAMPAIGN.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ', ListMemberCount__c ';
                }
                if (TAGS.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ', Member_Count__c ';
                }           
                if (String.isBlank(searchKeyWord)) {
                    soqlQuery = 'Select Id, Name ' + extraFields + 'from ' + objectAPIName + ' order by Name limit 1000';
                } else if (String.isNotBlank(objectAPIName) && String.isNotBlank(searchKey)) {                            
                    String whereCondition = 'Name like :searchKey';
                    if(String.isNotBlank(recordTypeId)) {
                        whereCondition = ' Name like :searchKey and recordTypeId = \'' + recordTypeId + '\'';
                    }
                    if (CONTACT.equalsIgnoreCase(objectAPIName)) {
                        searchKey = searchKeyWord + '%';
                        extraFields = ', Title, Organization_Name_formula__c ';
                        whereCondition = '(Name like :searchKey or Preferred_First_Name__c like :searchKey or Preferred_Last_Name__c like :searchKey or FirstName_LastName__c like :searchKey or Preferred_FirstName_LastName__c like :searchKey or FirstName like :searchKey or LastName like :searchKey)';
                    }
                    if (excludeIds != null && !excludeitems.isEmpty()) {
                        soqlQuery = 'Select Id, Name ' + extraFields + 'from ' + objectAPIName + ' where ' + whereCondition + ' and Id not in :excludeitems order by Name limit 1000';
                    } else {
                        soqlQuery = 'Select Id, Name ' + extraFields + 'from ' + objectAPIName + ' where ' + whereCondition + ' order by Name limit 1000';
                    }            
                }
            }
            List<sObject> returnList = Database.query(soqlQuery);
            for (sObject obj : returnList) {
                String id = (String)obj.get('Id');
                String name = (String)obj.get('Name');
                if (CAMPAIGN.equalsIgnoreCase(objectAPIName)) {
                    name += ' (' + obj.get('ListMemberCount__c') + ')';
                }
                if (TAGS.equalsIgnoreCase(objectAPIName)) {
                    name += ' (' + obj.get('Member_Count__c') + ')';
                }
                ResultWrapper rw = new ResultWrapper(id, name);
                if (CONTACT.equalsIgnoreCase(objectAPIName)) {
                    String title = (String)obj.get('Title');
                    String orgName = (String)obj.get('Organization_Name_formula__c');
                    rw.subtitle =  String.isNotBlank(title) ? title + (String.isNotBlank(orgName) ? '-' + orgName : '') : String.isNotBlank(orgName) ? orgName : '';
                }
                reultWrapper.add(rw);            
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return reultWrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchLookUpValues(String searchKeyWord, List<sObject> excludeIds, String objectAPIName, String recordTypeId, String filterData) {
        List<ResultWrapper> reultWrapper = new List<ResultWrapper>();
        try {
            String searchKey = '%' + searchKeyWord + '%';
            Set<String> excludeitems = new Set<String>();
            for(sObject item : excludeIds) {
                excludeitems.add(item.Id);
            }
            String soqlQuery;
            if (String.isNotBlank(objectAPIName)) {
                String extraFields = '';
                if (CAMPAIGN.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ', ListMemberCount__c ';
                }
                if (TAGS.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ', Member_Count__c ';
                } 
                if (ASSOCIATION.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ',AKA__c, FC_Focus_Area__c ';
                } 
                if (String.isBlank(searchKeyWord)) {
                    soqlQuery = 'Select Id, Name ' + extraFields + 'from ' + objectAPIName;
                    if(String.isNotBlank(filterData)) {
                        soqlQuery += ' where '+ filterData ;
                    }
                soqlQuery += ' order by Name limit 1000';
                } else if (String.isNotBlank(objectAPIName) && String.isNotBlank(searchKey)) {   
                    String whereCondition = 'Name like :searchKey';
                    if(String.isNotBlank(recordTypeId)) {
                        whereCondition = ' Name like :searchKey and recordTypeId = \'' + recordTypeId + '\'';
                    }
                    if (CONTACT.equalsIgnoreCase(objectAPIName)) {
                        searchKey = searchKeyWord + '%';
                        extraFields = ', Title, Account.Name, Organization_Name_formula__c, FirstName, LastName, Preferred_First_Name__c, Email ';
                        whereCondition = '(Name like :searchKey or Preferred_First_Name__c like :searchKey or Preferred_Last_Name__c like :searchKey or FirstName_LastName__c like :searchKey or Preferred_FirstName_LastName__c like :searchKey or FirstName like :searchKey or LastName like :searchKey)';
                    }
                    if(String.isNotBlank(filterData)) {
                        whereCondition += ' and '+ filterData ;
                    }
                    if (excludeIds != null && !excludeIds.isEmpty()) {
                        soqlQuery = 'Select Id, Name ' + extraFields + 'from ' + objectAPIName + ' where ' + whereCondition + ' and Id not in :excludeitems order by Name limit 1000';
                    } else {
                        soqlQuery = 'Select Id, Name ' + extraFields + 'from ' + objectAPIName + ' where ' + whereCondition + ' order by Name limit 1000';
                    }            
                }
            }
            List<sObject> returnList = Database.query(soqlQuery);
            for (sObject obj : returnList) {
                String id = (String)obj.get('Id');
                String name = (String)obj.get('Name');
                if (CAMPAIGN.equalsIgnoreCase(objectAPIName)) {
                    name += ' (' + obj.get('ListMemberCount__c') + ')';
                }
                if (TAGS.equalsIgnoreCase(objectAPIName)) {
                    name += ' (' + obj.get('Member_Count__c') + ')';
                }
                ResultWrapper rw = new ResultWrapper(id, name);
                if (ASSOCIATION.equalsIgnoreCase(objectAPIName)) {
                    rw.association = (Association__c)obj;
                }
                if (CONTACT.equalsIgnoreCase(objectAPIName)) {
                    rw.contact = (Contact)obj;
                }
                reultWrapper.add(rw);            
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return reultWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchLookUpAllValues(String objectAPIName, String recordTypeId, String filterData) {
        List<ResultWrapper> reultWrapper = new List<ResultWrapper>();
        try {
            String soqlQuery;
            if (String.isNotBlank(objectAPIName) && !CONTACT.equalsIgnoreCase(objectAPIName)) {
                String extraFields = '';
                if (CAMPAIGN.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ', ListMemberCount__c ';
                }
                if (TAGS.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ', Member_Count__c ';
                }
                if (ASSOCIATION.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ',AKA__c, FC_Focus_Area__c ';
                } 
                soqlQuery = 'Select Id, Name ' + extraFields + ' from ' + objectAPIName;
                if(String.isNotBlank(recordTypeId)) {
                    soqlQuery += ' where recordTypeId = \'' + recordTypeId + '\'';
                    if(String.isNotBlank(filterData)) {
                        soqlQuery += ' and ' + filterData;
                    }
                } else if(String.isNotBlank(filterData)) {
                    soqlQuery += ' where ' + filterData;
                } 
                soqlQuery += ' order by Name';
                List<sObject> returnList = Database.query(soqlQuery);
                for (sObject obj : returnList) {
                    String id = (String)obj.get('Id');
                    String name = (String)obj.get('Name');
                    if (CAMPAIGN.equalsIgnoreCase(objectAPIName)) {
                        name += ' (' + obj.get('ListMemberCount__c') + ')';
                    }
                    if (TAGS.equalsIgnoreCase(objectAPIName)) {
                        name += ' (' + obj.get('Member_Count__c') + ')';
                    }
                    ResultWrapper rw = new ResultWrapper(id, name);
                    if (ASSOCIATION.equalsIgnoreCase(objectAPIName)) {
                        rw.association = (Association__c)obj;
                    }
                    reultWrapper.add(rw);
                }
            }  
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }      
        return reultWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchLookUpAllValuesWithExcludeValues(String objectAPIName, String recordTypeId, String excludeIds) {
        List<ResultWrapper> reultWrapper = new List<ResultWrapper>();
        try {
            Set<String> excludeitems = new Set<String>();
            List<SelectedItem> selectedItems = (List<SelectedItem>)JSON.deserialize(excludeIds, List<SelectedItem>.class);
            for(SelectedItem item : selectedItems) {
                excludeitems.add(item.value);
            }
            String soqlQuery;
            if (String.isNotBlank(objectAPIName) && !CONTACT.equalsIgnoreCase(objectAPIName)) {
                String extraFields = '';
                if (CAMPAIGN.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ', ListMemberCount__c ';
                }
                if (TAGS.equalsIgnoreCase(objectAPIName)) {
                    extraFields = ', Member_Count__c ';
                }        
                soqlQuery = 'Select Id, Name ' + extraFields + ' from ' + objectAPIName;
                if(String.isNotBlank(recordTypeId)) {
                    soqlQuery += ' where recordTypeId = \'' + recordTypeId + '\'';
                }
                if (excludeIds != null && !excludeitems.isEmpty() && String.isNotBlank(recordTypeId)) {
                    soqlQuery += ' and Id not in :excludeitems';
                }
                if (excludeIds != null && !excludeitems.isEmpty() && String.isBlank(recordTypeId)) {
                    soqlQuery += ' where Id not in :excludeitems';
                }
                soqlQuery += ' order by Name';
                List<sObject> returnList = Database.query(soqlQuery);
                for (sObject obj : returnList) {
                    String id = (String)obj.get('Id');
                    String name = (String)obj.get('Name');
                    if (CAMPAIGN.equalsIgnoreCase(objectAPIName)) {
                        name += ' (' + obj.get('ListMemberCount__c') + ')';
                    }
                    if (TAGS.equalsIgnoreCase(objectAPIName)) {
                        name += ' (' + obj.get('Member_Count__c') + ')';
                    }    
                    reultWrapper.add(new ResultWrapper(id, name));
                }
            }   
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }     
        return reultWrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchLookUpAllSouceValues(String campaignId) {
        List<ResultWrapper> reultWrapper = new List<ResultWrapper>();
        try {
            Set<String> sourceNames = new Set<String>();
            List<CampaignMember> listMembers = [Select Id, Source__c from CampaignMember where campaignId = :campaignId];
            for (CampaignMember listMember : listMembers) {
                String source = listMember.Source__c;
                if (String.isNotEmpty(source)) {
                    source = source.remove('Tag(s):').remove('List(s):');
                    List<String> tempSources = source.split('; ');
                    sourceNames.addAll(tempSources);
                }
            }
            for (String source : sourceNames) {
                reultWrapper.add(new ResultWrapper(source, source));
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return reultWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> fetchLookUpAllSouceValuesWithExcludeValues(String campaignId, String excludeIds) {
        List<ResultWrapper> reultWrapper = new List<ResultWrapper>();
        try {
            Set<String> excludeitems = new Set<String>();
            Set<String> sourceNames = new Set<String>();
            List<SelectedItem> selectedItems = (List<SelectedItem>)JSON.deserialize(excludeIds, List<SelectedItem>.class);
            for(SelectedItem item : selectedItems) {
                excludeitems.add(item.value);
            }
            List<CampaignMember> listMembers = [Select Id, Source__c from CampaignMember where campaignId = :campaignId];
            for (CampaignMember listMember : listMembers) {
                String source = listMember.Source__c;
                if (String.isNotEmpty(source)) {
                    source = source.remove('Tag(s):').remove('List(s):');
                    List<String> tempSources = source.split('; ');
                    sourceNames.addAll(tempSources);
                }
            }
            sourceNames.removeAll(excludeitems);
            List<String> sortedSources = new List<String>(sourceNames);
            sortedSources.sort();
            for (String source : sortedSources) {
                reultWrapper.add(new ResultWrapper(source, source));
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return reultWrapper;
    }
}