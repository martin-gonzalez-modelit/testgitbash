({
	displayAppsByAccount : function(component, event, helper) {
        var charType = component.get("v.charType");
        var appsByYear = component.get("v.appsWithSubmissionByYear");
        var labels = [];
		var values = [];
        var colors = [];

        for (var key in appsByYear) {
            labels.push(key);
            values.push(appsByYear[key]);
			colors.push(this.getRandomColor());
        }

        var chartdata = {
            labels: labels,
            datasets: [
                {
                    label: 'Applications with submission in the last 5 years',
                    data: values,
                    backgroundColor: colors, // can accept an array of strings (colors: rgb, hexa or just string)
                    borderColor: 'black', // Color/Color[]
                    borderWidth: 1.5, // Number only
                    fill: false,
                    pointBackgroundColor: "#FFFFFF",
                	pointBorderWidth: 4,
                	pointHoverRadius: 8,
                	pointRadius: 6,
                	pointHitRadius: 10
                }
            ]
        }
        
        var ctx = component.find("graph").getElement();
        var chart = new Chart(ctx, {
                type: charType,
            	data: chartdata,
                options: {
                	responsive: true,
                	maintainAspectRatio :false,
                	onClick: function(event) {
                        var elements = chart.getElementAtEvent(event);
                    	if (elements.length === 1) {
                            var year = labels[elements[0]._index];
							var chartEvent = $A.get("e.c:ChartEvent");
                            chartEvent.setParams({
                                data: {year: year}
                            });
                            chartEvent.fire();
                        }
                	}
            	}
            });
    },
    
    // This function will generate colors dynamically 
    getRandomColor : function(component) {
        var letters = '0123456789ABCDEF';
        var color = '#';
        for (var i = 0; i < 6; i++ ) {
            color += letters[Math.floor(Math.random() * 16)];
        }
        return color;
    }
})