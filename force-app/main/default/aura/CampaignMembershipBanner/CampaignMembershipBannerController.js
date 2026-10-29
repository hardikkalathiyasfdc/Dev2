({
	doInit : function(component, event, helper) {

        helper.getMyDomainURL(component, event, helper);    
        helper.getUserInfo(component, event, helper);
        helper.getRecordInfo(component, event, helper);
        helper.getCampaignBanner(component, event, helper);
    },
    openEmail: function(component, event, helper) {
        
        // Setup email body
        var objectName = component.get("v.sObjectName");
        var subjectText = 'Contact Update Request';
        var recordText = 'Contact Name';

        if (objectName == 'Account') {
            subjectText = 'Organization Update Request';
            recordText = 'Organization Name';
        }

        var recordURL = component.get("v.myDomainURL") + '/' + component.get("v.contactId");
        var emailBody = "Requestor: " + component.get("v.userName") + " \n" + recordText + ": " + component.get("v.contactName") + " (" + recordURL + ")  \nChange Request:";
        var formattedBody = encodeURIComponent(emailBody);

        var mailToLink = "mailto:" + component.get("v.toEmailAddress") + "?subject=" + subjectText + "&HTMLBody=true&body=" + formattedBody;
        window.location.href = mailToLink; 
    }
})