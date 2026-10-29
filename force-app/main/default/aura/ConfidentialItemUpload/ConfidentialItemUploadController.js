({
	doSave: function(component, event, helper) {
        var fileUploaded = component.find("fileId").get("v.files");
        let briefingDate = component.find('date').get("v.value");
        if (fileUploaded != null && fileUploaded.length > 0 && briefingDate !== '') {
            helper.uploadItem(component, event);
        } else {
            alert('Please Select a Valid File and input Briefing Date');
        }
    },
 
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },

    doCancel: function(component, event, helper) {
        var recId = component.get("v.recordId");
        sforce.one.navigateToSObject(recId);
    },
})