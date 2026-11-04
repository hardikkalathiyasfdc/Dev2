// Renders the Revisions Needed email template exactly as NotificationService does
// (whoId = Grants Contact user, whatId = initiative) to verify subject/body content.
Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'IM_Initiative_Revisions_Needed_Template' LIMIT 1].Id;
Id grantsContactUserId = '0057x00000oANhlAAG';
Id initiativeId = 'a0r7x00002AmKSMAA3';

Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templateId, grantsContactUserId, initiativeId);
System.debug('SUBJECT>>> ' + rendered.getSubject());
System.debug('PLAINTEXT>>> ' + rendered.getPlainTextBody());
System.debug('HTML>>> ' + rendered.getHtmlBody());
