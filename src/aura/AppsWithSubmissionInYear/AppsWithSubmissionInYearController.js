({
	scriptsLoaded : function(component, event, helper) {

		var ctx = component.find("chart").getElement();
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
                    console.log('aaa');
                    var elements = component.chart.getElementAtEvent(event);
                    console.log(elements);
                    console.log('bbb');
                	if (elements.length === 1) {
                        var status = elements[0]._chart.config.data.labels[elements[0]._index];
                        console.log('status:' + status);
						var chartEvent = $A.get("e.c:ChartEvent");
                        chartEvent.setParams({
                            data: {status: status}
                        });
                        chartEvent.fire();
                    }
                 },
				scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero:true
                           
                        }
                    }],
                    xAxes: [{
                        ticks: {
                            autoSkip:false
                           
                        }
                    }]
                }
            }
        });
	},

    chartChange: function(component, event, helper) {
        var filters = event.getParam("data");
        if (!filters || !filters.year) {
            return;
        };
        component.set("v.year", filters.year);
        var action = component.get("c.getAppsWithSubmissionInYear");
        action.setParams({
        	year : filters.year,
            acc : component.get("v.recordId")
    	});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.appsInYear", response.getReturnValue());
                helper.displayAppsWithSubmissionInYear(component, event, helper);
            }
        });
        $A.enqueueAction(action);
    }
    
})