({
    doInit : function(component) {
        if (!component.get("v.accountId")) {
            // Get account Id
            let action = component.get("c.getAccount");

            action.setCallback(this, function(response) {
                let state = response.getState();

                if (state === "SUCCESS") {
                    component.set("v.accountId", response.getReturnValue());
                }
            });
            $A.enqueueAction(action);
        }
    },

    updateSearch : function(component, event, helper) {
        let addressToSearch = component.get("v.addressToSearch");

        if (addressToSearch) {
            // Show spinner
            let spinner = component.find("spinner");
            $A.util.removeClass(spinner, "slds-hide");
            // Perform search
            helper.searchApplications(component);
        }
    },

    handleKeyPress : function(component, event, helper) {
        let runningTests = component.get("v.runningTests");
        let userInput = !runningTests ? component.get("v.userInput").trim()
                                      : component.find('inputNormal').getElement().value;
        let listBox = component.find("listBox");

        if (userInput.length >= 3) {
            // Show listBox options.
            $A.util.addClass(listBox, 'slds-is-open');
            helper.displayOptions(component, userInput);
        } else {
            // Hide error message.
            let error = component.find('error');
            $A.util.addClass(error, 'slds-hide');
            // Hide listBox options.
            $A.util.removeClass(listBox, 'slds-is-open');
            // Hide paginator.
            let paginator = component.find('paginator');
            $A.util.addClass(paginator, 'slds-hide');
            // Reset options and input.
            component.set("v.addressToSearch", null);
            component.set("v.addresses", null);
            component.set("v.searchResults", null);
        }
    },

    selectAddress : function(component, event) {
        let selectedItem = event.currentTarget.dataset.value;
        let listBox = component.find("listBox");
        let noResultsFound = component.get("v.noResultsFoundMessage");

        if (selectedItem !== noResultsFound) {
            // Set user input and the search address.
            component.set("v.userInput", selectedItem);
            component.set("v.addressToSearch", selectedItem);
            // Hide listBox options.
            $A.util.removeClass(listBox, 'slds-is-open');
        } else {
            // Remove the selection when the no results found message is clicked.
            let selectedElement = document.getElementsByClassName("selected")[0];

            if (selectedElement) {
                selectedElement.classList.remove("selected");
            }
        }
    },

    pageChange : function(component, event, helper) {
        let page = component.get("v.page") || 1;
        let direction = event.getParam("direction");

        page = direction === "previous" ? (page - 1) : (page + 1);
        helper.searchApplications(component, page);
    },

    handleKeyDown : function(component, event) {
        let addresses = component.get("v.addresses");
        let noResultsFound = component.get("v.noResultsFoundMessage");
        // Make sure there are options at the listBox.
        let isOpen = !$A.util.isEmpty(addresses);

        if (isOpen && (event.keyCode === 40 || event.keyCode === 38 || event.keyCode === 13)) {
            // Need this so the cursor doesn't move from its position. It usually moves with ArrowUp.
            event.preventDefault();

            let elements = document.getElementsByClassName("address");
            let firstElement = elements[0];
            let lastElement = elements[elements.length - 1];
            let selectedElement = document.getElementsByClassName("selected")[0];

            // Actions when the user hits Enter.
            if (event.keyCode === 13 && selectedElement) {
                let selectedItem = selectedElement.dataset.value;
                let listBox = component.find("listBox");

                if (selectedItem !== noResultsFound) {
                    // Set user input and the search address.
                    component.set("v.userInput", selectedItem);
                    component.set("v.addressToSearch", selectedItem);
                    // Hide listBox options.
                    $A.util.removeClass(listBox, 'slds-is-open');
                }
            }

            if (!selectedElement && firstElement) {
                // If there are no options selected, select the first one.
                firstElement.classList.add("selected");
                selectedElement = document.getElementsByClassName("selected")[0];
            } else {
                let hovered = document.querySelectorAll("a:hover");

                // Actions when the user hovers over the options.
                if (event.type === 'mouseover') {
                    if (hovered.length > 0) {
                        document.getElementById("listbox-option-unique-id-02").classList.remove("selected");
                        firstElement.classList.remove("selected");
                        selectedElement.classList.remove("selected");
                        hovered[0].classList.add("selected");
                    }
                } else {
                    // Remove the current selection, it could be the first option or some other. 
                    firstElement.classList.remove("selected");
                    selectedElement.classList.remove("selected");

                    if (event.keyCode === 40) {
                        // Actions when the user hits the Down Arrow Key, and selects the next option.
                        let nextElement = selectedElement.nextElementSibling;

                        if (nextElement) {
                            nextElement.classList.add("selected");
                        } else {
                            firstElement.classList.add("selected");
                        }
                    } else if (event.keyCode === 38) {
                        // Actions when the user hits the Up Arrow Key, and selects the previous option.
                        let previousElement = selectedElement.previousElementSibling;

                        if (previousElement) {
                            previousElement.classList.add("selected");
                        } else {
                            lastElement.classList.add("selected");
                        }
                    }
                }
            }
        }
    },

    handleHover : function(component, event) {
        if (event.type === 'mouseover') {
            let hovered = document.querySelectorAll("a:hover");
            let selectedElement = document.getElementsByClassName("selected")[0];

            if (selectedElement) {
                selectedElement.classList.remove("selected");
            }

            if (hovered.length > 0) {
                hovered[0].classList.add("selected");
            }
        }
    }
})