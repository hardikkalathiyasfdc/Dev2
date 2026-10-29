/********************************************************************************
* Class Name  : GranteeBannerController
* Description : This class is used by GranteeBanner lightning component to
*               show if current contact Legacy Source is BGIV or GIFTS.    
* Created By  : Slalom Consulting 
* Change Log  : Created - 11/19/2019
********************************************************************************/

public without sharing class GranteeBannerController {
    
    private static final String ERR_CLASS_FAILED = 'GranteeBannerController_CLASS_FAILED';

    @AuraEnabled
    public static Boolean isGranteeContact(String recordId, String sObjectName) {
        Boolean isGranteeContactReturn = false;
        try {
            if(sObjectName == 'Contact') {
                Contact c = [SELECT Id, Legacy_Source_System__c FROM Contact WHERE Id = :recordId WITH SYSTEM_MODE];
                if(c.Legacy_Source_System__c == 'BGIVE' || c.Legacy_Source_System__c == 'GIFTS') {
                    isGranteeContactReturn = true;
                }               
            }  
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return isGranteeContactReturn;      
    } 
}