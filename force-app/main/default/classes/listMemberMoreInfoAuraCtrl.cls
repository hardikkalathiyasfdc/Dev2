public with sharing class listMemberMoreInfoAuraCtrl {

	@AuraEnabled(cacheable=true)
    public static String getContactId(String campaignMemberId) {
    	CampaignMember tmpMember = [SELECT ContactId FROM CampaignMember WHERE Id =: campaignMemberId];

    	return tmpMember.ContactId;
    }

    @AuraEnabled(cacheable=true)
    public static String getContactFields() {
    	Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Contact');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get('List_Member_Fields');

        SObjectType schemaType = Schema.getGlobalDescribe().get('Contact');
            
 		List<FieldWrap> fws = new List<FieldWrap>();
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetObj.getFields()) {
		    FieldWrap fw = new FieldWrap();
		    fw.fieldLabel = fieldSetMemberObj.getLabel();
		    fw.fieldName = fieldSetMemberObj.getFieldPath();

		    SObjectField schemaField = schemaType.getDescribe().fields.getMap().get(fieldSetMemberObj.getFieldPath());
            fw.accessible = schemaField.getDescribe().isAccessible();

            fws.add(fw);
		}


		return JSON.serialize(fws);
    }

    public class FieldWrap {
    	public String fieldName {get;set;}
    	public String fieldLabel {get;set;}
    	public Boolean accessible {get;set;}
    }
}