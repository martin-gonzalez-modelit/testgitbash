({
    setAddress : function(component) {
        let appStreet = this.formatStringFirstUppercase(component.get("v.application.Dwelling_Unit_Street_Address__c"));
        let appCity = this.formatStringFirstUppercase(component.get("v.application.Building_City__c"));
        let appZipCode = this.formatStringFirstUppercase(component.get("v.application.Building_ZIP_Code__c"));
        let appAddress = appStreet + ', ' + appCity + ' ' + appZipCode;

        component.set("v.appAddress", appAddress);
    },

    formatStringFirstUppercase : function(string) {
        string = string.toLowerCase().split(' ');

        for (let i = 0; i < string.length; i++) {
            string[i] = string[i].charAt(0).toUpperCase() + string[i].slice(1); 
        }

        return string.join(' ');
    },

    setDates : function(component) {
        let appDate = component.get("v.application.Application_Submission_Date__c");
        // Set the appDate attribute with either the Application Submission Date or the Created Date.
        // This attribute has to have a valid value if not the lightning:formattedDateTime component complains.
        if (!appDate) {
            appDate = component.get("v.application.CreatedDate");
            component.set("v.appDateLabel", "Created Date");
        }
        component.set("v.appDate", appDate);
        // Set the installDate with either the measure's installation date or a default date.
        // This value needs to be valid (!= null and != undefined and != '') if not the lightning:formattedDateTime
        // component complains.
        let appMeasures = component.get("v.application.Measures__r");
        let measures = [];
        let hasMeasureInstallDate = false;

        for (let i = 0; i < appMeasures.length; i++) {
            let measure = appMeasures[i];

            if (!measure.Installation_Date__c) {
                measure.InstallDate = component.get("v.application.appDate");
            } else {
                measure.InstallDate = measure.Installation_Date__c;
                hasMeasureInstallDate = true;
            }
            measures.push(measure);
        }
        // Display the appDate when none of the measures have an installation date.
        if (!hasMeasureInstallDate) {
            component.set("v.showAppDate", true);
        }

        component.set("v.measures", measures);
    }
})