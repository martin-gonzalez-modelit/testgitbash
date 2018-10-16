({
    MAX_FILE_SIZE: 4508876, /* 4.3MB */
    CHUNK_SIZE: 3145728, /* 3MB */

    uploadFiles: function(component) {
        var self = this;
        // Get the selected files.
        var files = component.get("v.fileToBeUploaded");
        var extensionsAllowed = ["pdf", "png", "jpg", "jpeg", "gif"];
        var extensionsNotAllowed = "File extension is not allowed: ";
        var extensionIsAllowed = true;
        var filesAllowed = [];
        var errorMessage = '';
        // Show spinner, disable buttons, reset error message and reset counter for files to upload.
        component.set("v.showSpinner", true);
        component.set("v.disabledButtons", true);
        component.set("v.filesErrorMessage", "");
        component.set("v.filesCountPerUpload", 1);

        // Check the selected file size.
        // If the file size is greater than the MAX_FILE_SIZE, then show an alert message to the user.
        for (var i = 0; i < files[0].length; i++) {
            var file = files[0][i];
            var fileSize = file.size;
            // Check if the extension is allowed.
            var fileExtension = file.name.split(".").pop(); 

            if (fileSize > this.MAX_FILE_SIZE) {
                if (errorMessage == '') {
                    errorMessage += 'File size cannot exceed ' + this.convertBytesToMegabytes(this.MAX_FILE_SIZE) + ' MB.\n'
                        + ' Selected file size: ' + this.convertBytesToMegabytes(fileSize) + ' MB ';
                } else {
                    errorMessage += ' & ' + this.convertBytesToMegabytes(fileSize) + ' MB ';
                }
            } else if (!extensionsAllowed.includes(fileExtension.toLowerCase())) {
                if (!extensionsNotAllowed.includes(fileExtension.toLowerCase())) {
                	extensionsNotAllowed += "'" + fileExtension + "', ";
                }
                extensionIsAllowed = false;
            } else {
                filesAllowed.push(file);
            }
        }
        
        // If there is any extension not allowed, then show an alert message to the user.
        if (!extensionIsAllowed) {
            // Remove the last occurrence of ', ' from the error message.
            errorMessage += extensionsNotAllowed.slice(0, -2);
        }
        if (errorMessage != '') {
            component.set("v.filesErrorMessage", errorMessage);
        }

        var totalFilesAllowed = filesAllowed.length;

        if (totalFilesAllowed == 0) {
            component.set("v.showSpinner", false);
            component.set("v.disabledButtons", false);
        } else {
            for (var j = 0; j < totalFilesAllowed; j++) {
                (function(index) {
                    var objFileReader = new FileReader();
                    objFileReader.onload = $A.getCallback(function() {
                        var fileContents = objFileReader.result;
                        var base64 = 'base64,';
                        var dataStart = fileContents.indexOf(base64) + base64.length;
    
                        fileContents = fileContents.substring(dataStart);
                        self.uploadProcess(component, filesAllowed[index], fileContents, totalFilesAllowed);
                    });
                    objFileReader.readAsDataURL(filesAllowed[index]);
                })(j);
            }
        }
    },

    uploadProcess: function(component, file, fileContents, totalFilesAllowed) {
        // Set a default size or startpostiton as 0.
        var startPosition = 0;
        // Calculate the end size or endPostion.
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
        // Start with the initial chunk with the applicaton file id and attachment id as empty values.
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '', '', totalFilesAllowed);
    },

    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, fileId, attachId, totalFilesAllowed) {
        var getchunk = fileContents.substring(startPosition, endPosition);
        var action = component.get("c.saveChunk");

        // If the application file id is an empty value, try to use the existing application file id.
        fileId = fileId == '' ? component.get("v.appFileId") : fileId;

        action.setParams({
            parentId: component.get("v.parentId"),
            fileName: file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
            fileAppId: fileId,
            attachmentId: attachId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            var responseMap = response.getReturnValue();

            if (state === "SUCCESS") {
                var fileApplicationId = Object.keys(responseMap)[0];
                var fileAttachmentId = responseMap[fileApplicationId];
                // Set the application file Id attribute.
                component.set("v.appFileId", fileApplicationId);
                // Update the start position with the end postion.
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                // If the start postion is less than the end postion then call again this method.
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, endPosition, fileApplicationId, fileAttachmentId, totalFilesAllowed);
                } else {
                    $A.createComponent(
                        "lightning:pill",
                        {
                            "aura:id": fileApplicationId,
                            "label": file.name,
                            "name": fileAttachmentId,
                            "media": component.find("iconPhoto"),
                            "onremove": component.getReference("c.deleteAppFile"),
                            "onclick": component.getReference("c.openAttachment"),
                            "href": '#'
                        },
                        function(pill, status, errorMessage) {
                            if (status === "SUCCESS") {
                                var body = component.get("v.body");
                                var filesUploaded = component.get("v.filesCountPerUpload");
                                // Add the new pill to the body array.
                                body.push(pill);
                                component.set("v.body", body);
                                component.set("v.filesCountPerUpload", filesUploaded + 1);
                                // If all files have been uploaded, hide spinner, enable buttons and increase total files counter.
                                if (totalFilesAllowed === filesUploaded) {
                                    component.set("v.showSpinner", false);
                                    component.set("v.disabledButtons", false);
                                    component.set("v.totalUploadedFiles", filesUploaded + component.get("v.totalUploadedFiles"));
                                }
                            } else if (status === "ERROR") {
                                console.log("Error: " + errorMessage);
                            } else if (status === "INCOMPLETE") {
                                console.log("No response from server or client is offline.")
                            }
                        }
                    );
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
        // Set actions as background actions, since the response from the server may take several seconds.
        // This is needed to make sure to deactivate the buttons when all files have been uploaded and
        // all corresponding pills have been created.
        action.setBackground();
        // Enqueue the action.
        $A.enqueueAction(action);
    },
    
    convertBytesToMegabytes: function(bytes) {
    	return (bytes/(Math.pow(1024, 2))).toFixed(2);
    }
})