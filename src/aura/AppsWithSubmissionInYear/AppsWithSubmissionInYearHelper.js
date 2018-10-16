({
	displayAppsWithSubmissionInYear : function(component, event, helper) {
        var colors = {
            gold: "rgba(255,203,75,.7)",
            silver: "rgba(143,134,132,.7)",
            bronze: "rgba(153,119,61,.7)"
        };

        var appsByStatusInYear = component.get("v.appsInYear");
        var year = component.get("v.year");
        component.set("v.title", "Apps With Submission by Status in: " + year);

        var labels = [];
        var values = [];
        console.log('appsby');
        console.log(appsByStatusInYear);
        for (var key in appsByStatusInYear) {
            labels.push(key);
            values.push(appsByStatusInYear[key]);
        }
        component.chart.data.labels = labels;
        component.chart.data.datasets[0].label = "Apps";
        component.chart.data.datasets[0].data = values;
        component.chart.data.datasets[0].backgroundColor = colors["silver"];
        component.chart.update();
	}
})