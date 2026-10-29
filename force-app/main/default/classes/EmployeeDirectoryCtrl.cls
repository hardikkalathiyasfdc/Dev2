/**
 * Description : Controller for the Employee Directory that retrieves office details from custom metadata and employee contacts 
 * 				based on organization settings, with built-in error handling and test support.
 * Test   : EmployeeDirectoryCtrl_Test
 **/
public without sharing class EmployeeDirectoryCtrl {
    private final static Environment_Setting__mdt BP_ORG_VARIABLE = Environment.getEnvironmentSetting();
    private static final String ERR_GET_OFFICE_INFO  = 'EMPLOYEE_DIRECTORY_GET_OFFICE_INFO_FAILED';
    private static final String ERR_GET_CONTACTS = 'EMPLOYEE_DIRECTORY_GET_CONTACTS_FAILED';
    private static final String ERR_GET_CONTACTS_WILLET = 'EMPLOYEE_DIRECTORY_GET_CONTACTS_WILLET_FAILED';
    
    @TestVisible
    private static Boolean forceException = false;
    
    public EmployeeDirectoryCtrl() {
        
    }
    
    public List<BPOfficeInfo__mdt> getOfficeInfo() {
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            return [SELECT OfficeName__c, OfficePhone__c, Email__c, CellPhone__c, Order__c
                    FROM BPOfficeInfo__mdt WITH SYSTEM_MODE
                    ORDER BY Order__c];
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_OFFICE_INFO)); 
            return null;
        }        
    }
    
    public List<Contact> getContacts() {
        try{ 
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            return [SELECT FirstName, LastName, Phone, Email, MobilePhone, Suffix
                    FROM Contact
                    WHERE AccountId IN (SELECT Account__c 
                                        FROM Photo_Book_Setting__c 
                                        WHERE Type__c in ('BP Org')
                                        AND Account__c != : BP_ORG_VARIABLE.OrgWillet__c)
                    AND Exclude_from_Photobook__c = false WITH SYSTEM_MODE
                    ORDER BY FirstName];
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_CONTACTS)); 
            return null;
        }         
    }
    
    public List<Contact> getContactsWillett() {
        try{
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            return [SELECT FirstName, LastName, Phone, Email, MobilePhone, Suffix
                    FROM Contact
                    WHERE AccountId =: BP_ORG_VARIABLE.OrgWillet__c
                    AND Exclude_from_Photobook__c = false WITH SYSTEM_MODE
                    ORDER BY FirstName];
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_CONTACTS_WILLET)); 
            return null;
        }         
    }
}