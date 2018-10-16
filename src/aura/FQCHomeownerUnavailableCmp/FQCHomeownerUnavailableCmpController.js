({
    handleButtonPressed: function(component, event) {
        var buttonClicked = event.getSource().getLocalId();
        var comments = component.find('comments').getElement().value;
        var proceed = true;
        // Set reason attribute, which will be passed back to the flow as output.
        component.set("v.reason", comments);

        if (buttonClicked !== "BACK") {
            // Validate required comments and files.
            if (comments === "") {
                component.set("v.commentsErrorMessage", "Please enter a comment.");
                proceed = false;
            } else {
                component.set("v.commentsErrorMessage", "");
            }
            if (component.get("v.totalUploadedFiles") === 0) {
                component.set("v.filesErrorMessage", "Please upload a file.");
                proceed = false;
            }
        }

        if (proceed) {
            // Fire the button's action.
            var navigate = component.get('v.navigateFlow');
            navigate(buttonClicked);
        }
    }
})