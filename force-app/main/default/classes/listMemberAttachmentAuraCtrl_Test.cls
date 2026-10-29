@isTest
private class listMemberAttachmentAuraCtrl_Test {

    @TestSetup
    public static void dataPrep() {
        Account acc = new Account(Name = 'TestAcct');
        insert acc;
        Contact testCon = new Contact(LastName = 'TestCon',AccountId = acc.Id);      
        insert testCon; 
    }

    @isTest
    public static void testSaveConfidentailAttachment() {
        Contact cnt = [SELECT Id FROM Contact LIMIT 1]; 
        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        insert cm;
        CampaignMember member = new CampaignMember();
        member.ContactId = cnt.Id;
        member.CampaignId = cm.Id;
        insert member; 
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = 'test';
        contentVersion.Title = 'test';
        contentVersion.VersionData = EncodingUtil.base64Decode('test file');
        insert contentVersion;
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id AND IsLatest = true LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = cm.Id;
        contentDocumentLink.ShareType = 'I'; // Inferred permission
        insert contentDocumentLink;
        String result = listMemberAttachmentAuraCtrl.saveListMemberAttachment(contentVersion.ContentDocumentId, member.Id, cm.Id);
        System.assertEquals('success', result);
        String docs = listMemberAttachmentAuraCtrl.getListId(member.Id);
        String files = listMemberAttachmentAuraCtrl.getConfidentialFiles(member.Id);
        ListMemberAttachment__c attachment = [SELECT Id FROM ListMemberAttachment__c LIMIT 1];
        String processResult = listMemberAttachmentAuraCtrl.deleteConfidentialFile(attachment.Id);
    }
}