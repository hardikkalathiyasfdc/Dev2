({
	MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    
    uploadItem: function(component,event) {
        component.set("v.showLoadingSpinner", true);
        var fileInput = component.find("fileId").get("v.files");
        // get the first file using array index[0]  
        var file = fileInput[0];
        var self = this;
        // check the selected file size, if select file size greter then MAX_FILE_SIZE,
        // then show a alert msg to user,hide the loading spinner and return from function  
        if (file.size > self.MAX_FILE_SIZE) {
            component.set("v.showLoadingSpinner", false);
            component.set("v.fileName", 'Alert : File size cannot exceed ' + self.MAX_FILE_SIZE + ' bytes.\n' + ' Selected file size: ' + file.size);
            return;
        }
        // create a FileReader object 
        var objFileReader = new FileReader();
        // set onload function of FileReader object   
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length; 
            fileContents = fileContents.substring(dataStart);
            self.uploadItemSave(component,event,file,fileContents);
        });
        objFileReader.readAsDataURL(file);        
    },

    uploadItemSave: function(component,event,file,fileContents) {
        var action = component.get("c.saveChunk");
        action.setParams({
            parentId: component.get("v.recordId"),
            fileName: file.name,
            base64Data: encodeURIComponent(fileContents),
            contentType: file.type,
            itemDesc : '',
            dateOfBriefing : component.find('date').get('v.value')
        });
 
        // set call back 
        action.setCallback(this, function(response) {
            // store the response / Attachment Id   
            var attachId = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {                
                //alert('your File is uploaded successfully');
                /*var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "File has been uploaded successfully."
                });
                toastEvent.fire();*/
                console.log(' inside new logic >>>>> ');
                component.set("v.showLoadingSpinner", false);
                var recId = component.get("v.recordId");
                sforce.one.navigateToSObject(recId);
                sforce.one.navigateToSObject(recId);
                // handel the response errors        
            } else if (state === "INCOMPLETE") {
                alert("From server: " + response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    }
})