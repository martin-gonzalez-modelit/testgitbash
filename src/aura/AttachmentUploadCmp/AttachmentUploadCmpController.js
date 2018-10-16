({
    doInit: function(component) {
        // Get the attachments URL for further use.
        var action = component.get("c.getAttachmentURL");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                component.set("v.attachmentURL", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    handleFilesChange: function(component, event, helper) {
        var files = component.get("v.fileToBeUploaded");

        if (files && files.length > 0) {
            helper.uploadFiles(component);
        } else {
            component.set("v.filesErrorMessage", "Please select a valid file.");
        }
    },

    openAttachment: function(component, event) {
        event.preventDefault();
        var attachmentId = event.getSource().get('v.name');
        var attachmentURL = component.get("v.attachmentURL");
        // Open the attachment in a new tab using the corresponding org's URL and attachment Id.
        window.open(attachmentURL + attachmentId);
    },

    deleteAppFile: function(component, event) {
        event.preventDefault();
        var action = component.get("c.deleteApplicationFile");
        var appFileId = event.getSource().getLocalId();

        action.setParams({
            applicationFileId: appFileId
        }); 
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
             
            if (state === "SUCCESS") {
                var pill = component.find(result);

                if (pill) {
                    // Remove pill from markup and decrease the counter for total files.
                    component.find(result).destroy();
                    component.set("v.totalUploadedFiles", component.get("v.totalUploadedFiles") - 1); 
                }
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
        // Enqueue the action.
        $A.enqueueAction(action);
    }
})