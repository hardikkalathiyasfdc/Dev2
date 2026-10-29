/********************************************************************************
 * Class Name  : AddCampaignMemberController
 * Description : This class is used by AddCampaignMember lightning component to
 *               search and add contacts as campaign members.
 * Created By  : Slalom Consulting
 * Change Log  : Created - 5/9/2019
*********************************************************************************/
public with sharing class AddCampaignMemberController {

	private static final String ERR_JOB_FAILED = 'AddCampaignMemberController_BATCH_JOB_FAILED';
    
    // on load of lightning component wrapper class list is calculated for filters
    @AuraEnabled
    public static List<wrapperClass> initMethod() {
		List<wrapperClass> lstWrap = new List<wrapperClass>();
		try {
			for(integer i = 0; i < 4; i++) {
				wrapperClass returnwrapperClass = new  wrapperClass ();
				returnwrapperClass.boardMem = false;
				lstWrap.add(returnwrapperClass);
			}
		} catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
		return lstWrap;
    }
    
    //calculating map for search filter options
    @AuraEnabled
    public static Map<String,String> calcMapFldLabelFldPath() {
		Map<String,String> mapFldLabelFdlApi = new Map<String,String>();
		try {
			mapFldLabelFdlApi.put('--None--', '');
			SObjectType objToken = Schema.getGlobalDescribe().get('Contact');
			Schema.DescribeSObjectResult d = objToken.getDescribe();
			Map<String, Schema.FieldSet> FsMap = d.fieldSets.getMap();
			if(FsMap.containsKey('Contact_Search')) {
				for(Schema.FieldSetMember f : FsMap.get('Contact_Search').getFields()) {
					mapFldLabelFdlApi.put(f.getLabel(),f.getFieldPath());
				}
			}
		} catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
		return mapFldLabelFdlApi;
    }
    
    // method to search contacts on the basis of search filters selected
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts(List<wrapperClass> lstWrap,String pageSize, String pageNumber,String campId) {
		List<Contact> returnList = new List<Contact>();
		try {
			Integer ps = Integer.valueOf(pageSize);
			Integer pn = Integer.valueOf(pageNumber) - 1;
			Set<Id> existingConIds = new Set<Id>();
			for(CampaignMember cm : [SELECT ContactId FROM CampaignMember WHERE CampaignId =: campId]) {
				existingConIds.add(cm.ContactId);
			}
			String conQuery = 'SELECT Account.Name,AccountId,Id,Name,Phone,Email,Title,MobilePhone FROM Contact';
			for(wrapperClass wrap:lstWrap) {
				if(wrap.selectedFldLabel != null && (wrap.selectedFldLabel == 'CreatedDate' || wrap.selectedFldLabel == 'LastModifiedDate')) {
					if(!conQuery.contains('WHERE')) conQuery = conQuery +' WHERE';
					else conQuery = conQuery +' AND';
					if(wrap.startDate != null && wrap.endDate != null) {
						conQuery = conQuery + ' '+wrap.selectedFldLabel+' >= '+wrap.startDate+'T00:00:00Z'+' AND';
					} else if(wrap.startDate != null) {
						conQuery = conQuery + ' '+wrap.selectedFldLabel+' >= '+wrap.startDate+'T00:00:00Z';
					}
					if(wrap.endDate != null) {
						conQuery = conQuery + ' '+wrap.selectedFldLabel+' <= '+wrap.endDate+'T23:59:59Z';
					}
				} else if(wrap.selectedFldLabel != null && wrap.selectedFldLabel == 'Bloomberg_Philanthropies_Board_Member__c') {
					if(!conQuery.contains('WHERE')) conQuery = conQuery +' WHERE';
					else conQuery = conQuery +' AND';
					conQuery = conQuery + ' '+wrap.selectedFldLabel+' = '+wrap.boardMem;
				} else if(wrap.selectedFldLabel != null && wrap.selectedFldLabel == 'AccountId' && wrap.searchTextVal != null) {
					if(!conQuery.contains('WHERE')) conQuery = conQuery +' WHERE';
					else conQuery = conQuery +' AND';
					conQuery = conQuery + ' '+'Account.Name'+' Like \''+wrap.searchTextVal+'%\'';
				} else if(wrap.selectedFldLabel != null && wrap.selectedFldLabel == 'Categories__c' &&
				 	wrap.lstSelectedCategories != null && wrap.lstSelectedCategories.size() > 0) {
					if(!conQuery.contains('WHERE')) conQuery = conQuery +' WHERE';
					else conQuery = conQuery +' AND';
					String catValue = '';
					Integer i = 1;
					for(String str : wrap.lstSelectedCategories) {
						catValue = catValue + '\'' + str + '\'';
						if(i < wrap.lstSelectedCategories.size()) catValue = catValue+',';
						i++;
					}
					conQuery = conQuery + ' '+wrap.selectedFldLabel+' Includes('+catValue+')';
				} else if(wrap.selectedFldLabel != null && wrap.selectedFldLabel != '' && wrap.searchTextVal != null) {
					if(!conQuery.contains('WHERE')) conQuery = conQuery +' WHERE';
					else conQuery = conQuery +' AND';
					conQuery = conQuery + ' '+wrap.selectedFldLabel+' Like \''+wrap.searchTextVal+'%\'';
				}
			}
			conQuery = conQuery + ' ORDER BY Name LIMIT ' + Integer.valueOf(ps) + ' OFFSET ' + ps * pn;
			List<Contact> lstConSearch = Database.query(conQuery);
			// filtering out the contacts FROM the search results those are already added.
			for(Contact con : lstConSearch) {
				if(existingConIds != null && !existingConIds.contains(con.Id)) {
					returnList.add(con);
				}
			}
		} catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
		return returnList;
    }
    
    // to add selected contacts as members via advanced search
    @AuraEnabled
    public static Object addMemContact(List<String> selectedRecords, String campId) {
		List<String> doNotCallContacts = new List<String>();
        List<String> deceasedContacts = new List<String>();
		Map<String, List<String>> result = new Map<String, List<String>>();
		try {
			String statusVal;
			List<CampaignMemberStatus> campMemStatus = [
				SELECT id, isDefault, Label, CampaignId FROM CampaignMemberStatus WHERE CampaignId = :campId];
			for(CampaignMemberStatus campStatus : campMemStatus) {
				if(campStatus.isDefault) statusVal = campStatus.Label;
			}
			if(statusVal == null && campMemStatus != null && campMemStatus.size() > 0) statusVal = campMemStatus[0].Label;
			List<CampaignMember> lstCampMemToInsert = new List<CampaignMember>();
			Set<Id> existingConIds = new Set<Id>();
			for(CampaignMember cm : [SELECT ContactId FROM CampaignMember WHERE CampaignId =: campId]) {
				existingConIds.add(cm.ContactId);
			}
			set<Id> contactIds = new set<Id> ();
			for(String con : selectedRecords) {
				String conIdIns = con.split('-')[0];
				contactIds.add((Id)conIdIns);
				if(existingConIds != null && !existingConIds.contains(conIdIns)) {
					CampaignMember cm = New CampaignMember(CampaignId = campId, ContactId = conIdIns, Status = statusVal);
					lstCampMemToInsert.add(cm);
				}
			}
			if(!contactIds.IsEmpty()){
                 result = validateContacts(contactIds);
		 }
            if(lstCampMemToInsert != null && lstCampMemToInsert.size()>0) insert lstCampMemToInsert;
			 
           
		   return result; 
		}catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
			 return result;
        }
    }
    
    // to add selected contacts as members via basic search
    @AuraEnabled
    public static Object addMemContactBasic(List<Contact> selectedRecords, String campId) {
        List<String> doNotCallContacts = new List<String>();
        List<String> deceasedContacts = new List<String>();
        Map<String, List<String>> result = new Map<String, List<String>>();
		try {
			String statusVal;
			List<CampaignMemberStatus> campMemStatus = [
				SELECT id, isDefault, Label, CampaignId FROM CampaignMemberStatus WHERE CampaignId =: campId];
			for(CampaignMemberStatus campStatus : campMemStatus) {
				if(campStatus.isDefault) {
					statusVal = campStatus.Label;
				}
			}
			if(statusVal == null && campMemStatus != null && campMemStatus.size() > 0)
				statusVal = campMemStatus[0].Label;
			List<CampaignMember> lstCampMemToInsert = new List<CampaignMember>();
			Set<Id> existingConIds = new Set<Id>();
			for(CampaignMember cm : [SELECT ContactId FROM CampaignMember WHERE CampaignId =: campId]) {
				existingConIds.add(cm.ContactId);
			}
            Set<Id> contactIds = new Set<Id>();
			for(Contact con : selectedRecords) {
                contactIds.add(con.Id);
            }
            
            for(Contact tmpContact : [SELECT Id, Email, Alternate_Email__c, Full_Name__c, Business_Email_2__c,
                                      DoNotCall, Deceased__c
                                      FROM Contact
                                      WHERE ID = :contactIds]) {
                                          
                                          if(tmpContact.DoNotCall == true) {
                                              doNotCallContacts.add(tmpContact.Full_Name__c);
                                          } else if(tmpContact.Deceased__c == true) {
                                              deceasedContacts.add(tmpContact.Full_Name__c);
                                          } else {
                                              String conIdIns = tmpContact.Id;
				if(existingConIds != null && !existingConIds.contains(conIdIns)) {
					CampaignMember cm= New CampaignMember(CampaignId=campId, ContactId= conIdIns, Status= statusVal);
					lstCampMemToInsert.add(cm);
				}
			}
           	}
            
            if(doNotCallContacts.size() > 0) {
                result.put(
                    'The following Contacts were not added because they have a Do Not Contact alert', doNotCallContacts
                );
            }
            if(deceasedContacts.size() > 0) {
                result.put(
                    'The following Contacts were not added because they have a Deceased alert', deceasedContacts
                );
            }
            
            if(lstCampMemToInsert != null && lstCampMemToInsert.size() > 0) insert lstCampMemToInsert;
            return result;
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
            return result;
        }
    }

	public static Map<String, List<String>> validateContacts(Set<Id> contactIds) {

    List<String> doNotCallContacts = new List<String>();
    List<String> deceasedContacts = new List<String>();
    Map<String, List<String>> result = new Map<String, List<String>>();

    if(contactIds == null || contactIds.isEmpty()) {
        return result;
    }

    for(Contact con : [SELECT Full_Name__c, DoNotCall, Deceased__c FROM Contact WHERE Id IN :contactIds ]) {
        if(con.DoNotCall) {
            doNotCallContacts.add(con.Full_Name__c);
        } else if(con.Deceased__c) {
            deceasedContacts.add(con.Full_Name__c);
        }
    }

    if(!doNotCallContacts.isEmpty()) {
        result.put(
            'The following Contacts were not added because they have a Do Not Contact alert',
            doNotCallContacts
        );
    }

    if(!deceasedContacts.isEmpty()) {
        result.put(
            'The following Contacts were not added because they have a Deceased alert',
            deceasedContacts
        );
    }

    return result;
}
    
    //getting option for categories multi SELECT picklist in the SELECT filter
    @AuraEnabled
    public static List <String> getMultiPiklistValues() {
		List<String> plValues = new List<String>();
		try {
			//Get the object type FROM object name.
			Schema.SObjectType objType = Schema.getGlobalDescribe().get('Contact');
			//Describe the sObject using its object type.
			Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
			//Get the specific field information FROM field name.
			Schema.DescribeFieldResult objFieldInfo = objDescribe.fields.getMap().get('Categories__c').getDescribe();
			//Get the picklist field values.
			List<Schema.PicklistEntry> picklistvalues = objFieldInfo.getPicklistValues();
			//Add the picklist values to list.
			for(Schema.PicklistEntry plv: picklistvalues) {
				plValues.add(plv.getValue());
			}
			plValues.sort();
		} catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
		return plValues;
    }
    
    // wrapper class with @AuraEnabled properties for search filters.
    public class wrapperClass {
        @AuraEnabled public String selectedFldLabel {get; set;}
        @AuraEnabled public String searchTextVal {get; set;}
        @AuraEnabled public String startDate {get; set;}
        @AuraEnabled public String endDate {get; set;}
        @AuraEnabled public Boolean boardMem {get; set;}
        @AuraEnabled public List<String> lstSelectedCategories {get; set;}
        
        public wrapperClass() {
            this.lstSelectedCategories = new List<String>();
        }
    }
}