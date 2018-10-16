({
    doInit : function(component, event, helper) {
        var action = component.get("c.getAppsInLastFiveYears");
        action.setParams({
            acc: component.get("v.recordId")
    	});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                component.set("v.appsWithSubmissionByYear", response.getReturnValue());
                helper.displayAppsByAccount(component, event, helper);
            }
        });
        $A.enqueueAction(action);
    }
})