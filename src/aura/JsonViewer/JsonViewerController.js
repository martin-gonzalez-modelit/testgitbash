({
    doInit : function(cmp) {
        var action = cmp.get("c.getApplicationFile");
        action.setParams({ Id : cmp.get("v.appFileId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var vals = response.getReturnValue();
                cmp.set("v.applicationFile", vals);
                // call function to display json
                visualize(jQuery.parseJSON(vals.JSON__c));
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
        $A.enqueueAction(action);
    }
})