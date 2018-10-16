({
	doInit : function(component, event, helper) {
		var ctx = component.find("graphStatus").getElement();
        component.chart = new Chart(ctx,{
            type: 'bar',
            data: {
                labels: [],
                datasets: [
                    {
                        label: "",
                        data: [],
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                onClick: function(event) {
                    
                 },
				scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero:true
                        }
                    }]
                }
            }
        });
	},
    
    chartChange: function(component, event, helper) {
        var filters = event.getParam("data");
        if (!filters || !filters.status) {
            return;
        };
        component.set("v.status", filters.status);
        var action = component.get("c.getStatusInLastFiveYears");
        action.setParams({
        	status : filters.status,
            acc: component.get("v.recordId")
    	});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.appsByStatus", response.getReturnValue());
                helper.displayAppsWithSubmissionByStatus(component, event, helper);
            }
        });
        $A.enqueueAction(action);
    }
})