({
	displayAppsWithSubmissionByStatus : function(component, event, helper) {
		var colors = {
            gold: "rgba(255,203,75,.7)",
            silver: "rgba(143,134,132,.7)",
            bronze: "rgba(153,119,61,.7)"
        };

        var appsByStatus = component.get("v.appsByStatus");
        var status = component.get("v.status");

        var labels = [];
        var values = [];
        console.log('appsby');
        console.log(appsByStatus);
        for (var key in appsByStatus) {
            labels.push(key);
            values.push(appsByStatus[key]);
        }
        component.chart.data.labels = labels;
        component.chart.data.datasets[0].label = status + " " + "apps with submission.";
        component.chart.data.datasets[0].data = values;
        component.chart.data.datasets[0].backgroundColor = colors["gold"];
        component.chart.update();
	}
})