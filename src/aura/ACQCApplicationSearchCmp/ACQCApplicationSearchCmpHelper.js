({
    displayOptions : function(component, userInput) {
        let action = component.get("c.getAddresses");

        action.setParams({
            "input": userInput
        });
        action.setCallback(this, function(response) {
            let state = response.getState();

            if (state === "SUCCESS") {
                let addresses = response.getReturnValue();

                if (addresses.length > 0) {
                    component.set("v.addresses", addresses);
                } else {
                    component.set("v.addresses", component.get("v.noResultsFoundMessage"));
                }
            }
        });
        $A.enqueueAction(action);
    },

    searchApplications : function(component, page) {
        let addressToSearch = component.get("v.addressToSearch");
        let action = component.get("c.getApplications");

        page = page || 1;
        // Perform search
        action.setParams({
            input: addressToSearch,
            pageNumber: page,
            pageSize: component.get("v.pageSize")
        });
        action.setCallback(this, function(response) {
            this.doLayout(response, component, page);
        });
        $A.enqueueAction(action);
    },

    doLayout : function(response, component, page) {
        let state = response.getState();
        let paginator = component.find('paginator');
        let error = component.find('error');

        if (state === "SUCCESS") {
            let results = response.getReturnValue();
            // Hide error.
            $A.util.addClass(error, 'slds-hide');
            // Show paginator.
            $A.util.removeClass(paginator, 'slds-hide');
            // Set current page number, total number of pages, and total number of results.
            component.set("v.page", page);
            component.set("v.total", results.totalRecords);
            component.set("v.pages", Math.ceil(results.totalRecords/component.get("v.pageSize")));
            // Set the application list with the results of the search.
            component.set("v.searchResults", results.applications);
        } else {
            // Show error message.
            $A.util.removeClass(error, 'slds-hide');
            // Hide paginator.
            $A.util.addClass(paginator, 'slds-hide');
        }
        // Hide Spinner
        let spinner = component.find('spinner');
        $A.util.addClass(spinner, "slds-hide");
    }
})