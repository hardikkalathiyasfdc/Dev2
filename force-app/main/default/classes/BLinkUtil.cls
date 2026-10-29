/**
* Author : Neha Gire
* Date   : 10/04/2024
* Jira   : IM-25
* Description : This class contains util methods related to Blink Functionality.
* Change Log
  Gauri Sagane on 10/22/2024 - JIRA IM-31 - Methods added for B-Link Org functionality
**/

public with sharing class BLinkUtil {
    public static final String BRM_HASH_DELIMITER = '|';

    /**
    * Description : Method to get sync fields from custom meta data
    * Parameters : objectApi String.
    * Return Type : List<BLink_Sync_Field_Mapping__mdt>
    */
    public static List<BLink_Sync_Field_Mapping__mdt> getSyncFields(String objectApi){
        return [SELECT Bgive_Field__c,BRM_Field__c,Order__c, Sync_Mode__c FROM BLink_Sync_Field_Mapping__mdt
                WHERE Object_API__c =: objectApi 
                WITH SYSTEM_MODE 
                ORDER BY Order__c ASC];
    }

    /**
    * Description : Method to get sync fields from custom meta data for creating Hash
    * Parameters : objectApi String.
    * Return Type : List<BLink_Sync_Field_Mapping__mdt>
    */
    public static List<BLink_Sync_Field_Mapping__mdt> getSyncFieldsForHash(String objectApi){
        return [SELECT Bgive_Field__c, BRM_Field__c, Order__c, Sync_Mode__c FROM BLink_Sync_Field_Mapping__mdt
                WHERE Object_API__c =: objectApi AND Sync_Mode__c != :Assets.INITIAL_CREATION_SYNC_MODE 
                WITH SYSTEM_MODE 
                ORDER BY Order__c ASC];
    }

    /**
    * Description : Method to get sync fields from custom meta data for Org
    * Parameters : objectApi String.
    * Return Type : List<BLink_Sync_Field_Mapping__mdt>
    */
    public static List<BLink_Sync_Field_Mapping__mdt> getSyncFieldsForOrg(String objectApi){
        return [SELECT Bgive_Field__c,BRM_Field__c,Order__c, Sync_Mode__c FROM BLink_Sync_Field_Mapping__mdt
                WHERE Object_API__c =: objectApi AND (Sync_Mode__c = :Assets.BIDIRECTIONAL_SYNC_MODE OR Sync_Mode__c = :Assets.BRM_TO_BGIVE_SYNC_MODE) 
                WITH SYSTEM_MODE 
                ORDER BY Order__c ASC];
    }

    /**
    * Description : Method to get sync fields from custom meta data for Org which are synced Bgive to BRM
    * Parameters : objectApi String.
    * Return Type : List<BLink_Sync_Field_Mapping__mdt>
    */
    public static List<BLink_Sync_Field_Mapping__mdt> getSyncFieldsMapBGiveToBRM(String objectApi){
        return [SELECT Bgive_Field__c,BRM_Field__c,Order__c, Sync_Mode__c FROM BLink_Sync_Field_Mapping__mdt
                WHERE Object_API__c =: objectApi AND (Sync_Mode__c = :Assets.BIDIRECTIONAL_SYNC_MODE OR Sync_Mode__c = :Assets.BGIVE_TO_BRM_SYNC_MODE) 
                WITH SYSTEM_MODE 
                ORDER BY Order__c ASC];
    }

    /**
    * Description : Method to get sync fields from custom meta data
    * Parameters : objectApi String.
    * Return Type : List<String>
    */
    public static List<String> getBRMSyncFields(String objectApi){
        List<BLink_Sync_Field_Mapping__mdt> mappings = [SELECT Bgive_Field__c,BRM_Field__c
                                                        FROM BLink_Sync_Field_Mapping__mdt
                                                        WHERE Object_API__c =: objectApi 
                                                        WITH SYSTEM_MODE 
                                                        ORDER BY Order__c ASC];
        if(!mappings.isEmpty()){
            List<String> fields = new List<String>();
            for(BLink_Sync_Field_Mapping__mdt mapping : mappings){
                fields.add(mapping.BRM_Field__c);
            }

            return fields;

        }
        return null;
    }

    /**
    * Description : Method to get sync fields from custom meta data
    * Parameters : objectApi String.
    * Return Type : List<String>
    */
    public static List<String> getSyncFieldsBRMToBGive(String objectApi){
        List<BLink_Sync_Field_Mapping__mdt> mappings = [SELECT Bgive_Field__c, BRM_Field__c, Sync_Mode__c
                                                        FROM BLink_Sync_Field_Mapping__mdt
                                                        WHERE Object_API__c =: objectApi AND (Sync_Mode__c = :Assets.BIDIRECTIONAL_SYNC_MODE OR Sync_Mode__c = :Assets.BRM_TO_BGIVE_SYNC_MODE) 
                                                        WITH SYSTEM_MODE 
                                                        ORDER BY Order__c ASC];
        if(!mappings.isEmpty()){
            List<String> fields = new List<String>();
            for(BLink_Sync_Field_Mapping__mdt mapping : mappings){
                fields.add(mapping.BRM_Field__c);
            }

            return fields;

        }
        return null;
    }

    /**
    * Description : Method to get sync fields from custom meta data
    * Parameters : objectApi String.
    * Return Type : List<String>
    */
    public static List<String> getSyncFieldsBGiveToBRM(String objectApi){
        List<BLink_Sync_Field_Mapping__mdt> mappings = [SELECT Bgive_Field__c, BRM_Field__c,Sync_Mode__c
                                                        FROM BLink_Sync_Field_Mapping__mdt
                                                        WHERE Object_API__c =: objectApi AND (Sync_Mode__c = :Assets.BIDIRECTIONAL_SYNC_MODE OR Sync_Mode__c = :Assets.BGIVE_TO_BRM_SYNC_MODE) 
                                                        WITH SYSTEM_MODE 
                                                        ORDER BY Order__c ASC];
        if(!mappings.isEmpty()){
            List<String> fields = new List<String>();
            for(BLink_Sync_Field_Mapping__mdt mapping : mappings){
                fields.add(mapping.BRM_Field__c);
            }

            return fields;

        }
        return null;
    }

    /**
    * Description : Method to convert BRM Deceased field value from Boolean to String (as in BGive)
    * Parameters : deceased Boolean.
    * Return Type : String
    */
    private static String getBgiveDeceasedValue(Boolean deceased){
        return deceased ? 'Yes' : '';
    }

    /**
    * Description : Method to form the BRM Hash field value
    * Parameters : con Contact, List<BLink_Sync_Field_Mapping__mdt> mappings.
    * Return Type : String
    */
    public static String getBRMHash(Contact con , List<BLink_Sync_Field_Mapping__mdt> mappings){
        if(!mappings.isEmpty()){

            String brmHash = '';
            for( BLink_Sync_Field_Mapping__mdt mapping : mappings){
                if(('Deceased').equalsIgnoreCase(mapping.Bgive_Field__c )){
                    brmHash = brmHash + getBgiveDeceasedValue(Boolean.valueOf(con.get(mapping.BRM_Field__c))) + BRM_HASH_DELIMITER ;
                }else{
                    brmHash = brmHash + (con.get(mapping.BRM_Field__c) != null ? String.valueOf(con.get(mapping.BRM_Field__c)) : '')  + BRM_HASH_DELIMITER ;
                }
            }

            return brmHash;
        }
        return null;
    }

    /**
    * Description : Method to create contact in BRM
    * Parameters : bgiveContact BLinkContactService.BGiveContact, enableSolicitorHistory String.
    * Return Type : Contact
    */
    public static Contact createBRMContact(BLinkContactService.BGiveContact bgiveContact, String enableSolicitorHistory){
        Contact newContact = new Contact();
        newContact.FirstName = bgiveContact.first_name;
        newContact.LastName = bgiveContact.last_name;
        newContact.MiddleName = bgiveContact.middle_initial;
        newContact.Preferred_First_Name__c = bgiveContact.preferred_first_name;
        newContact.Salutation = bgiveContact.salutation;
        newContact.Email = bgiveContact.email;
        newContact.Bgive_Id__c = bgiveContact.id;
        newContact.Title = bgiveContact.title;
        newContact.Bgive_Contig_Id__c = bgiveContact.contig_id;
        newContact.Solicitor_History_Status__c = enableSolicitorHistory;

        insert as system newContact;
        return newContact;
    }

    /**


























    * Description : Method to convert BGive Deceased field value from String to Boolean (as in BRM)
    * Parameters : deceased String.
    * Return Type : Boolean
    */
    private static Boolean getBRMDeceasedValue(String deceased){
        return ('Yes').equalsIgnoreCase(deceased) ? true : false;
    }

    /**
    * Description : Method to create BGive Api filter conditions for contact
    * Parameters : firstName String, lastName String.
    * Return Type : String
    */
    public static String getSearchFilter(String firstName, String lastName){
        BGiveFilterCondition firstNameFilterCondition = new BGiveFilterCondition('first_name', BGiveFilterCondition.Operator.STARTS_WITH, firstName);
        BGiveFilterCondition preferredNameFilterCondition = new BGiveFilterCondition('preferred_first_name', BGiveFilterCondition.Operator.STARTS_WITH, firstName);
        BGiveApiFilter firstNameFilter = new BGiveApiFilter();
        firstNameFilter.setGroupType('or');
        firstNameFilter.addCondition(firstNameFilterCondition);
        firstNameFilter.addCondition(preferredNameFilterCondition);
        BGiveApiFilter filter = new BGiveApiFilter();
        BGiveFilterCondition lastNameFilterCondition = new BGiveFilterCondition('last_name', BGiveFilterCondition.Operator.STARTS_WITH, lastName);
        filter.addCondition(firstNameFilter);
        filter.addCondition(lastNameFilterCondition);
        return filter.getFilterString();
    }

    /**
    * Description : Method to create org in BRM
    * Parameters : bgiveOrg BLinkOrgService.BGiveOrg.
    * Return Type : Account
    */
    public static Account createBRMOrg(BLinkOrgService.BGiveOrg bgiveOrg){
        Account newOrg = new Account();
        newOrg.Name = bgiveOrg.name;
        newOrg.AKA__c = bgiveOrg.acronym;
        newOrg.Legal_Name__c = bgiveOrg.legal_name;
        newOrg.Tax_Status__c = bgiveOrg.tax_class;
        newOrg.Tax_ID__c = bgiveOrg.tax_id;
        newOrg.Bgive_Id__c = bgiveOrg.id;
        newOrg.Bgive_Contig_Id__c = bgiveOrg.contig_id;
        newOrg.Legacy_Source_System__c = Assets.BLINK;

        insert as system newOrg;
        System.debug('#########createBRMOrg-newOrg: ' + newOrg);
        return newOrg;
    }

    /**
    * Description : Method to create BGive Api filter conditions for organization
    * Parameters : orgName String.
    * Return Type : String
    */
    public static String getOrgSearchFilter(String orgName, String contigId){
        BGiveApiFilter filter = new BGiveApiFilter();
        BGiveFilterCondition orgNameFilterCondition = new BGiveFilterCondition('name', BGiveFilterCondition.Operator.CONTAINS, orgName);
        BGiveFilterCondition orgAKAFilterCondition = new BGiveFilterCondition('acronym', BGiveFilterCondition.Operator.CONTAINS, orgName);
        BGiveFilterCondition orgLegalNameFilterCondition = new BGiveFilterCondition('legal_name', BGiveFilterCondition.Operator.CONTAINS, orgName);

        filter.setGroupType('or');
        if(String.isNotBlank(orgName)) {
            filter.addCondition(orgNameFilterCondition);
            filter.addCondition(orgAKAFilterCondition);
            filter.addCondition(orgLegalNameFilterCondition);
        }
        if(String.isNotBlank(contigId)) {
            BGiveFilterCondition contigIdFilterCondition = new BGiveFilterCondition('contig_id', BGiveFilterCondition.Operator.CONTAINS, contigId);
            filter.addCondition(contigIdFilterCondition);
        }
        return filter.getFilterString();
    }

    /**
    * Description : Method to update BRM org fields if corresponding BGive fields change
    * Parameters : brmOrg Account, bgiveOrg BLinkOrgService.BGiveOrg, mappings List<BLink_Sync_Field_Mapping__mdt>.
    * Return Type : Account
    */
    public static Account syncBRMOrgFields(Account brmOrg , BLinkOrgService.BGiveOrg bgiveOrg , List<BLink_Sync_Field_Mapping__mdt> mappings){
        if(!mappings.isEmpty() && brmOrg != null && bgiveOrg != null){
            Map<String,Object> bgiveOrgFVMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(bgiveOrg));

            for( BLink_Sync_Field_Mapping__mdt mapping : mappings){
                String brmFieldValue = String.valueOf(brmOrg.get(mapping.BRM_Field__c));
                String bGiveFieldValue = String.valueOf(bgiveOrgFVMap.get(mapping.Bgive_Field__c));
                if(brmFieldValue != bGiveFieldValue){
                    String brmFieldName = mapping.BRM_Field__c;
                    brmOrg.put(mapping.BRM_Field__c, bGiveFieldValue);
                }
            }
        }

        return brmOrg;
    }

    /**
    * Description : Method to check if org field values differ in BRM and BGive
    * Parameters : brmOrg Account, bgiveOrg BLinkOrgService.BGiveOrg, mappings List<BLink_Sync_Field_Mapping__mdt>.
    * Return Type : Boolean
    */
    public static Boolean isOrgDiffers(Account brmOrg, BLinkOrgService.BGiveOrg bgiveOrg , List<BLink_Sync_Field_Mapping__mdt> mappings){
        if(!mappings.isEmpty()){
            // Add Comment here
            Map<String,Object> bgiveOrgFVMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(bgiveOrg));
            for( BLink_Sync_Field_Mapping__mdt mapping : mappings){
                String brmFieldValue = String.valueOf(brmOrg.get(mapping.BRM_Field__c));
                String bGiveFieldValue = String.valueOf(bgiveOrgFVMap.get(mapping.Bgive_Field__c));
                if(brmFieldValue != bGiveFieldValue){
                    return true;
                }
            }
        }

        return false;
    }

    /**
    * Description : Method to get BRM Hash for Orgs
    * Parameters : org Account, mappings List<BLink_Sync_Field_Mapping__mdt>.
    * Return Type : String
    */
    public static String getOrgBRMHash(Account org, BLinkOrgService.BGiveOrg bgiveOrg, List<BLink_Sync_Field_Mapping__mdt> mappings){
        if(!mappings.isEmpty()){

            String brmHash = '';
            for( BLink_Sync_Field_Mapping__mdt mapping : mappings){
                if(bgiveOrg == null){
                    brmHash = brmHash + (org.get(mapping.BRM_Field__c) != null ? String.valueOf(org.get(mapping.BRM_Field__c)) : '')  + BRM_HASH_DELIMITER ;
                }else{
                    if(mapping.Sync_Mode__c == Assets.BIDIRECTIONAL_SYNC_MODE || mapping.Sync_Mode__c == Assets.BRM_TO_BGIVE_SYNC_MODE){
                        brmHash = brmHash + (org.get(mapping.BRM_Field__c) != null ? String.valueOf(org.get(mapping.BRM_Field__c)) : '')  + BRM_HASH_DELIMITER ;
                    }
                    else{
                        brmHash = brmHash + (bgiveOrg.get(mapping.Bgive_Field__c) != null ? String.valueOf(bgiveOrg.get(mapping.Bgive_Field__c)) : '')  + BRM_HASH_DELIMITER ;
                    }
                }
            }
            return brmHash.substringBeforeLast('|');
        }
        return null;
    }

    /**
    * Description : Method to form org sync payload using sync fields from custom meta data
    * Parameters : brmOrg Account, bgiveOrg BLinkOrgService.BGiveOrg, mappings List<BLink_Sync_Field_Mapping__mdt>.
    * Return Type : Map<String,Object>
    */
    public static Map<String,Object> formOrgSyncPayload(Account brmOrg, BLinkOrgService.BGiveOrg bgiveOrg , List<BLink_Sync_Field_Mapping__mdt> mappings){
        Map<String,Object> payloadMap = new Map<String,Object>();
        if(!mappings.isEmpty()){
            for( BLink_Sync_Field_Mapping__mdt mapping : mappings){
                String brmFieldValue = String.valueOf(brmOrg.get(mapping.BRM_Field__c));
                payloadMap.put(mapping.Bgive_Field__c , brmFieldValue);
            }
        }
        return payloadMap;
    }
}