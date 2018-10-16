/**
 * This test suite contains specs for c:ACQCApplicationSearchCmp, which use the Lightning Testing Service (LTS)
 * <https://github.com/forcedotcom/LightningTestingService>
 *
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2018-01
 */
describe('ACQC Application Search Testing', function(){

    afterEach(function() {
        // Each spec (test) renders its components into the same div, so we need to clear that div out at the end of 
        // each spec.
        $T.clearRenderedTestComponents();
    });

    /**
     * Component under test: 'c:ACQCApplicationSearchCmp':
     * This spec creates a component, adds it to the body, waits for the rendering to complete,
     * and then ensures that the expected content has been added to the DOM.
     * NOTE: The spec and the component under test are in same locker (same namespace),
     *       so the spec is able to see the DOM owned by the component.
     */
    describe('c:ACQCApplicationSearchCmp', function() {
        let attributes = {
            applicationUrl: "/pgeportal/BIGACQCRebateApplicationForm",
            accountId: "001g000001isWgVAAU",
            runningTests: true
        }

        let addresses = [];
        addresses.push("123 Apple Avenue, Austin 11111");
        addresses.push("123 Banana Boulevard, Burzaco 22222");
        addresses.push("123 Chester Cliff, City 33333");
        addresses.push("123 Donatello Drive, Denmark 44444");
        addresses.push("123 Elm Estate, Eastside 55555");
        addresses.push("123 Foo Falls, Friburg 66666");
        addresses.push("123 Goodwill Grove, Glade 77777");
        addresses.push("123 Oak Street, City 12345");
        addresses.push("123 Strawberry Street, City 88888");
        addresses.push("1234 Zeta Valley, Zion 99999");

        let apps = [];
        let measures = [];

        for (let i = 0; i < 3; i++) {
            let measure = {"sObjectType":"Measures__c", "Name":"Measure"+i};
            measures.push(measure);
        }

        for (let i = 0; i < 22; i++) {
            // Insert applications that correspond to the same address, but are from different contractors.
            let application = {};

            if (i < 10) {
                application = {"sObjectType":"Application__c", "Dwelling_Unit_Street_Address__c":"123 Oak Street" ,
                                   "Building_City__c":"City", "Building_ZIP_Code__c":"12345",
                                   "Application_Submission_Date__c":new Date(), "Measures__r":measures, "Name":"App"+i,
                                   "Contractor__c":"001g000001isWgVAAU"};
            } else {
                application = {"sObjectType":"Application__c", "Dwelling_Unit_Street_Address__c":"123 Oak Str." ,
                                   "Building_City__c":"City", "Building_ZIP_Code__c":"12345",
                                   "Application_Submission_Date__c":new Date(), "Measures__r":measures, "Name":"App"+i,
                                   "Contractor__c":"001g000001isWgBEEZ"};
            }
            apps.push(application);
        }

        let wrapper = {
            applications: apps,
            totalRecords: apps.length
        };

        /**
         * This test verifies that addresses are suggested and displayed correctly.
         */
        it('verifies that addresses are being suggested and displayed correctly', function(done) {
            $T.createComponent("c:ACQCApplicationSearchCmp", attributes, true)
            .then(function(component) {
                console.log('test1 start');
                console.log(attributes);
                // Mocking out the server-side action response.
                let res = {getState : function(){return "SUCCESS";}, getReturnValue: function(){return addresses;}};
                spyOn($A, "enqueueAction").and.callFake(function(action) {
                    let cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [res]);

                });
                // Simulate the action of the user of entering "123" in the search input.
                component.set("v.userInput", "123");
                component.getAddresses();
                // Verify that we get 10 suggested addresses.
                expect(component.get("v.addresses").length).toBe(10);
                // End this spec successfully.
                done();
            }).catch(function(e) {
                // End this spec as a failure.
                done.fail(e);
            });
            console.log('test1 end');
            console.log(attributes);
        });

        /**
         * This test checks that a message is displayed when there are no suggested addresses for a given input.
         */
        it('verifies that a message is displayed when there are no suggested addresses for the given input', function(done) {
            $T.createComponent("c:ACQCApplicationSearchCmp", attributes, true)
            .then(function(component) {
                console.log('test2 start');
                console.log(attributes);
                // Mocking out the server-side action response.
                let res = {getState : function(){return "SUCCESS";}, getReturnValue: function(){return [];}};
                spyOn($A, "enqueueAction").and.callFake(function(action) {
                    let cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [res]);

                });
                // Simulate the action of the user of entering "12345" in the search input.
                component.set("v.userInput", "12345");
                component.getAddresses();
                // Verify that a generic message is displayed indicating that there are no suggested addresses.
                expect(component.get("v.addresses").length).toBe(1);
                expect(component.get("v.addresses")).toContain(component.get("v.noResultsFoundMessage"));
                // End this spec successfully.
                done();
            }).catch(function(e) {
                // End this spec as a failure.
                done.fail(e);
            });
            console.log('test2 end');
            console.log(attributes);
        });

        /**
         * This test verifies that when an address is selected by the user, that the lightning component performs the
         * search correctly, and the applications are displayed according to the requirements. It also verifies that
         * pagination works as expected.
         */
        it('performs the search and displays a list of corresponding applications', function(done) {
            // Instantiate and render the c:ACQCApplicationSearchCmp Lightning component into the renderInto element.
            // The second parameter is the list of component attribute values to set.
            // The third parameter, requiresRendering, is set to true.
            $T.createComponent("c:ACQCApplicationSearchCmp", attributes, true)
            // The component here is the instance of c:ACQCApplicationSearchCmp.
            .then(function(component) {
                // Verify that the spinner is hidden.
                let spinner = component.find('spinner');
                expect($A.util.hasClass(spinner, "slds-hide")).toBe(true);
                // Mocking out the server-side action response.
                let res = {getState : function(){return "SUCCESS";}, getReturnValue: function(){return wrapper;}};
                spyOn($A, "enqueueAction").and.callFake(function(action) {
                    let cb = action.getCallback("SUCCESS")
                    cb.fn.apply(cb.s, [res]);

                });
                // Simulate the action of the user of selecting an address.
                component.set("v.addressToSearch", "123 Oak Street, City 12345");
                component.getApplications();
                // Verify that the search returned 22 applications.
                expect(component.get("v.searchResults").length).toBe(22);

                let resultList = component.find('resultList');
                // Verify that the corresponding addresses were returned.
                expect(resultList[0].get("v.appAddress")).toBe("123 Oak Street, City 12345");
                expect(resultList[10].get("v.appAddress")).toBe("123 Oak Str., City 12345");

                // Verify that a link is rendered for the first 10 applications, which belong to the user's account.
                // Verify that a link is not rendered for the following 12 applications.
                for (let i = 0; i < 22; i++) {
                    let accountId = resultList[i].get("v.accountId");
                    let application = resultList[i].get("v.application");

                    if (i < 10) {
                        let link = resultList[i].find("applicationLink");
                        expect(link.getElements().length).toBe(1);
                        expect(link.getElement().innerHTML).toBe("App"+i);
                        expect(accountId).toBe(application.Contractor__c);
                    } else {
                        expect(resultList[i].find("applicationLink")).toBeUndefined();
                        expect(accountId).not.toBe(application.Contractor__c);
                    }
                }

                let paginator = component.find('paginatorCmp');
                let nextPage = paginator.find("nextPage");
                let previousPage = paginator.find("previousPage");
                // Verify that we are currently in the first page of the results.
                expect(paginator.get("v.page")).toBe(1);
                // Verify that there are 3 pages in total.
                expect(paginator.get("v.pages")).toBe(3);
                // Verify that there are 22 applications in total.
                expect(paginator.get("v.total")).toBe(22);
                // Click the Next button, and verify that it leads to the second page of the results.
                nextPage.getElement().click();
                expect(paginator.get("v.page")).toBe(2);
                expect(paginator.get("v.pages")).toBe(3);
                expect(paginator.get("v.total")).toBe(22);
                // Click the Next button, and verify that it leads to the third page of the results.
                nextPage.getElement().click();
                expect(paginator.get("v.page")).toBe(3);
                expect(paginator.get("v.pages")).toBe(3);
                expect(paginator.get("v.total")).toBe(22);
                // Click the Next button, and verify that nothing happens. We stay on the third page.
                nextPage.getElement().click();
                expect(paginator.get("v.page")).toBe(3);
                expect(paginator.get("v.pages")).toBe(3);
                expect(paginator.get("v.total")).toBe(22);
                // Click the Prev button, and verify that it leads to the second page of the results.
                previousPage.getElement().click();
                expect(paginator.get("v.page")).toBe(2);
                expect(paginator.get("v.pages")).toBe(3);
                expect(paginator.get("v.total")).toBe(22);
                // End this spec successfully.
                done();
            }).catch(function(e) {
                // End this spec as a failure.
                done.fail(e);
            });
        });


        /**
         * This test verifies that an error message is displayed whenever an error occurs when retrieving the applications.
         */
        it('verifies that the error message is displayed when an error occurs when performing the search', function(done) {
            $T.createComponent("c:ACQCApplicationSearchCmp", attributes, true)
            .then(function(component) {
                let error = component.find('error');
                // Verify that the error message is not being displayed.
                expect($A.util.hasClass(error, "slds-hide")).toBe(true);
                // Mocking out the server-side action response.
                let res = {getState : function(){return "ERROR";}, getReturnValue: function(){return wrapper;}};
                spyOn($A, "enqueueAction").and.callFake(function(action) {
                    let cb = action.getCallback("ERROR")
                    cb.fn.apply(cb.s, [res]);

                });
                // Simulate the action of the user of selecting an address.
                component.set("v.addressToSearch", "123 Oak Street, City 12345");
                component.getApplications();
                // Verify that the error message is displayed.
                expect($A.util.hasClass(error, "slds-hide")).toBe(false);
                done();
            }).catch(function(e) {
                // End this spec as a failure.
                done.fail(e);
            });
        });
    });
});
