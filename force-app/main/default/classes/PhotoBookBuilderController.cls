/**
* Author: Nishant Bakhrey
* Date Modified: 08/24/26
* Description : Controller for Photo Book Builder LWC. It provides methods to get filter options, count matches,
                and create requests for generating photo books
* Test Class: PhotoBookControllerTest
*/
public with sharing class PhotoBookBuilderController {

    private static final String ERR_GET_FILTER_OPTIONS = 'PHOTO_BOOK_BUILDER_GET_FILTER_OPTIONS_FAILED';
    private static final String ERR_CREATE_REQUEST = 'PHOTO_BOOK_BUILDER_CREATE_REQUEST_FAILED';

    private static final Set<String> KEYWORD_FIELDS = new Set<String>{
        'Key_Projects__c', 'SkillKnowledgeArea__c', 'Languages_Spoken__c'
    };

    public class FilterOptions {
        @AuraEnabled public List<Map<String, String>> departments {get; set;}
        @AuraEnabled public List<Map<String, String>> cardFields {get; set;}
        @AuraEnabled public List<String> defaultCardFields {get; set;}
        @AuraEnabled public List<Map<String, String>> keywordFields {get; set;}

        public FilterOptions() {
            departments = new List<Map<String, String>>();
            cardFields = new List<Map<String, String>>();
            keywordFields = new List<Map<String, String>>();
            defaultCardFields = new List<String>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static FilterOptions getFilterOptions() {
        try {
            FilterOptions options = new FilterOptions();
            for(Schema.PicklistEntry entry : Contact.Department__c.getDescribe().getPicklistValues()) {
                if(entry.isActive()) {
                    options.departments.add(new Map<String, String>{'label' => entry.getLabel(), 'value' => entry.getValue()});
                }
            }
            Schema.FieldSet cardFieldSet = Schema.SObjectType.Contact.fieldSets.getMap().get('PhotoBook_Fields_To_Show');
            if(cardFieldSet != null) {
                for(Schema.FieldSetMember member : cardFieldSet.getFields()) {
                    String apiName = member.getFieldPath();
                    if(!isContactFieldAccessible(apiName)) continue;
                    options.cardFields.add(new Map<String, String>{'label' => member.getLabel(), 'value' => apiName});
                    if(options.defaultCardFields.size() < 4) {
                        options.defaultCardFields.add(apiName);
                    }
                }
            }
            for(String apiName : KEYWORD_FIELDS) {
                Schema.SObjectField f = Schema.SObjectType.Contact.fields.getMap().get(apiName);
                if(f == null) continue;
                Schema.DescribeFieldResult dfr = f.getDescribe();
                if(isContactFieldAccessible(apiName)) options.keywordFields.add(new Map<String, String>{'label' => dfr.getLabel(), 'value' => apiName});
            }
            return options;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_FILTER_OPTIONS));
            throw new AuraHandledException('Unable to load the photo book filter options.');
        }
    }

    private static Boolean isContactFieldAccessible(String apiName) {
        Schema.SObjectField f = Schema.SObjectType.Contact.fields.getMap().get(apiName);
        if(f == null) return false;
        Schema.DescribeFieldResult dfr = f.getDescribe();
        return dfr.isAccessible();
    }

    /**
     * Stores the criteria and returns back the Id. The LWC then opens
     * /apex/PhotoBook?requestId={id} which is where the PDF is produced
     */
    @AuraEnabled
    public static Id createRequest(String criteriaJson) {
        try {
            PhotoBookController.Criteria parsed =
                (PhotoBookController.Criteria) JSON.deserialize(criteriaJson, PhotoBookController.Criteria.class);
            PhotoBook_Request__c request = new PhotoBook_Request__c(
                Filter_Criteria_JSON__c = JSON.serialize(parsed)
            );
            BBApps_Crud.doInsertWithHandling(request, ERR_CREATE_REQUEST);
            return request.Id;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CREATE_REQUEST));
            throw new AuraHandledException('Error creating the PhotoBook request. Please try again.');
        }
    }
}