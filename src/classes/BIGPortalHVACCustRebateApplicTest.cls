/**
* This class contains unit tests for validating the behavior of BIGPortalHVACCustRebateApplicController
* for PG&E SFDC Portal.
*
* @author Pablo Vigil <pvigil@builditgreen.org>
* @since 2014-03
*/
@isTest
private class BIGPortalHVACCustRebateApplicTest {

    private static final String PORTAL_USER_NAME = 'BIGPortalUserForTest@test.com';
    private static final String PORTAL_ACCOUNT_NAME = 'portalAccount';
    private static User portalUser;
    private static Account contractor;
    private static Contact contact;
    private static Application__c application;
    private static List<Rebate_Type__c> rebateTypes;
    private static Unit__c unit;
    private static List<Rebate_Type__c> rebateTypesList = new List<Rebate_Type__c>();

    @testSetup
    private static void initData() {
        // Create Account
        contractor =  BIGPortalTestUtils.createAccount(PORTAL_ACCOUNT_NAME);
        contractor.Tax_ID_Number__c = '123456789';
        contractor.Zip__c = '12345';
        contractor.BillingStreet = 'Test';
        contractor.BillingCity = 'San Jose';
        contractor.BillingState = 'CA';
        contractor.BillingPostalCode = '12345';
        contractor.BillingCountry = 'USA';
        contractor.OwnerId = UserInfo.getUserId();
        insert contractor;
        System.assertNotEquals(null, contractor.Id);

        // Create Contact
        contact = BIGPortalTestUtils.createContact(
                'portalContact' , 'portalContact', 'portalContact@test.com', '703-555-5555', contractor.Id);
        contact.OwnerId = UserInfo.getUserID();
        insert contact;
        System.assertNotEquals(null, contact.Id);

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];
        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = contact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);

        // Insert the sharing record and capture the save result.
        AccountShare jobShr  = new AccountShare();
        // Set the ID of record being shared.
        jobShr.AccountId = contractor.Id;
        // Set the ID of user or group being granted access.
        jobShr.UserOrGroupId = portalUser.Id;

        // Set the access level.
        jobShr.AccountAccessLevel = 'Edit';
        jobShr.OpportunityAccessLevel = 'Edit';
        jobShr.CaseAccessLevel = 'Edit';
        insert jobShr;

        // The false parameter allows for partial processing if multiple records passed into the operation.
        Database.SaveResult sr = Database.insert(jobShr, false);
        BIGPortalTestUtils.createCustomSetting();
    }

    static testMethod void testGetRebateTypes() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initPage(controller);
            List<Rebate_Type__c> result = controller.getRebateTypes();
            Integer size = result.size();
            System.assertEquals(0, size);
        }
        Test.stopTest();
    }

    static testMethod void testGetRebateTypesUser() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            Rebate_Type__c r1 = rebateTypes.get(0);
            Map<String, Integer> result = controller.getRebateTypesUser();
            Integer size = result.size();
            System.assertEquals(7, size);
        }
        Test.stopTest();
    }

    static testMethod void testGetContractor() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            Id result = controller.getContractorId();
            System.assertEquals(contractor.Id, result);
        }
        Test.stopTest();
    }

    static testMethod void testSaveDraft() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            PageReference result = controller.saveDraft();
            String appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId', appId);
            System.assertEquals('1', result.getParameters().get('msg'));
            Application__c app = controller.getApplication();
            system.assertEquals(ApplicationUtils.CREATED_STATUS, app.Status__c);
            Map<String, Integer> types = controller.getApplicationRebateTypes(app.Id);
            System.assertEquals(types.keySet().size(), rebateTypes.size());
        }
        Test.stopTest();
    }

    static testMethod void testSaveRebate() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            PageReference result = controller.saveRebate();
            System.assertEquals('2', result.getParameters().get('msg'));
            System.assertNotEquals(null, result.getParameters().get('appId'));
        }
        Test.stopTest();
    }

    /**
     * Tests the submission of an application from the Portal.
     */
    static testMethod void testSubmit() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            Review__c review = controller.getReview();
            // Verify there isn't a review because application wasn't subbmitted yet
            System.assertEquals(null, review.Id);
            List<Application_Note__c> notes = controller.getNotes();
            System.assertEquals(0, notes.size());
            // Add a comment to the application. This will generate an application note.
            ApexPages.currentPage().getParameters().put('notes', 'notes test');
            // Submit Application
            PageReference result = controller.saveRebate();
            String appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId', appId);
            Application__c app = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId})).get(0);
            // Get all measures related to an application and depending on Equipment Type to check later
            List<Measure__c> measureList = [
                SELECT Measure_Code__c, Make_Model__c
                FROM Measure__c
                WHERE Application__c =: appId
                    AND (Equipment_Type__c = :BIGPortalHVACCustRebateApplicController.EQUIPMENT_TYPE_DELAY
                    OR Equipment_Type__c = :BIGPortalHVACCustRebateApplicController.EQUIPMENT_TYPE_MOTOR)
                ORDER BY Equipment_Type__c ASC
                ];
            // Set list of measure codes to verify that the measure combination was populated correctly.
            List<String> measureCodes = new List<String>();
            for (Measure__c measure : measureList) {
                measureCodes.add(measure.Measure_Code__c);
            }
            measureCodes.sort();
            // Verify Application was successfully submitted
            System.assertEquals(ApplicationUtils.SUBMITTED_STATUS, app.Status__c);
            // Verify the Measures have the correct Make/Model
            System.assertEquals('GreenFan 140X-XX', measureList.get(0).Make_Model__c);
            System.assertEquals('Rescue Ecotech 5552ET', measureList.get(1).Make_Model__c);
            System.assertEquals('H796', measureList.get(0).Measure_Code__c);
            System.assertEquals('TK10', measureList.get(1).Measure_Code__c);
            // Verify that the Measure Combination was populated correctly
            System.assertEquals(String.join(measureCodes, ','), app.Measure_Combination__c);

            review = controller.getReview();
            notes = controller.getNotes();
            System.assertNotEquals(null, review.Id);
            System.assertEquals(1, notes.size());
        }
        Test.stopTest();
    }

    /**
     * Tests the resubmission of an application from the Portal.
     */
    static testMethod void testResubmit() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            controller.checkMessages();
            initRebateApplicationData(controller);
            // Call saveRebate method first time.
            PageReference result = controller.saveRebate();

            System.assertEquals('2', result.getParameters().get('msg'));
            System.assertNotEquals(null, result.getParameters().get('appId'));

            // Get the genereted application Id.
            String appId = result.getParameters().get('appId');
            // Get the application.
            Application__c app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId}).get(0);
            // Change the status of the application simulating the action of the reviewer.
            app.Status__c = ApplicationUtils.CORRECTION_REQUIRED_STATUS;
            update app;

            // Set list of measure codes to verify measure combination population. It should be (H796, TK10).
            List<String> measureCodes = new List<String>();
            for (Measure__c measure : app.Measures__r) {
                measureCodes.add(measure.Measure_Code__c);
            }
            measureCodes.sort();

            // Verify that the Measure Combination was populated correctly.
            System.assertEquals(String.join(measureCodes, ','), app.Measure_Combination__c);

            Test.startTest();
            // Set BIGACQCRebateApplicationForm.page to current test
            PageReference advancedHuPage = Page.BIGACQCRebateApplicationForm;
            Test.setCurrentPage(advancedHuPage);
            ApexPages.currentPage().getParameters().put('appId', app.Id);
            controller = new BIGPortalHVACCustRebateApplicController();
            controller.checkMessages();

            List<Rebate_Type__c> rebateTypes = [
                SELECT Id
                FROM Rebate_Type__c
                WHERE Measure_Code__c IN ('TK10', 'TK12', 'TK103')
                ORDER BY Measure_Code__c ASC
                ];
            // Choose differente measures this time. Re-select TK10, unselect H796, and select TK103 and TK12.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(0).Id + ',' + rebateTypes.get(1).Id + ',' + rebateTypes.get(2).Id);
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.MAKE_MODEL_MOTOR_OPTION,
                    'Rescue Ecotech 5552ET');
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(0).Id,
                    String.valueOf(System.today().addDays(-36)));
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(1).Id,
                    String.valueOf(System.today().addDays(-36)));
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(2).Id,
                    String.valueOf(System.today().addDays(-36)));
            // Keep the rest of the application's information.
            ApexPages.currentPage().getParameters().put('unitId', app.Unit__c);
            ApexPages.currentPage().getParameters().put('inputName', app.Building_Name__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputAddress', app.Building_Street_Address__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputCity', app.Building_City__c);
            ApexPages.currentPage().getParameters().put('inputState', app.Building_State__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputZip', app.Building_ZIP_Code__c);
            ApexPages.currentPage().getParameters().put('inputUnit', app.Unit__r.Name);
            ApexPages.currentPage().getParameters().put('inputPhone', app.Customer_Phone__c);
            ApexPages.currentPage().getParameters().put('inputPayee','on');
            ApexPages.currentPage().getParameters().put('thisContractor', app.Contractor__c);

            // Call saveRebate method second time to resubmit the application.
            result = controller.saveRebate();
            Test.stopTest();

            // Get the application.
            app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId}).get(0);

            System.assertEquals(ApplicationUtils.RESUBMITTED_STATUS, app.Status__c);
            System.assertEquals('3', result.getParameters().get('msg'));

            // Set list of measure codes to verify that the measure combination was re-calculated.
            // It should be (TK10, TK103, TK12).
            measureCodes = new List<String>();
            for (Measure__c measure : app.Measures__r) {
                measureCodes.add(measure.Measure_Code__c);
            }
            measureCodes.sort();
            // Verify that the Measure Combination was populated correctly
            System.assertEquals(String.join(measureCodes, ','), app.Measure_Combination__c);
        }
    }

    /**
     * Test that an application is prevented from submitting when the user selects equivalent measures to those that
     * have already been applied for the application's unit. This should happen if the selected installation date
     * is within the range of five years starting from the previous installation date (for that equivalent measure).
     * Equivalent measures are those that belong to the same rebate type group.
     */
    static testMethod void testEquivalentMeasuresWithInstallationDateEarlierThan5Years() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            // Add a measure with "Refrigerant Service System" group name.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(2).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(2).Id,
                    System.now().addYears(-2).format('MM/dd/yyyy'));
            // Submit an application.
            controller.saveRebate();

            // Save the unitId used in the first application created.
            String unitId = ApexPages.currentPage().getParameters().get('unitId');

            Test.startTest();

            // Initialize another application with the same measures that the recently application created.
            controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Set the unitId and rebate type for the new application.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(6).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(6).Id,
                    System.now().addYears(-1).format('MM/dd/yyyy'));
            ApexPages.currentPage().getParameters().put('unitId', unitId);

            // Submit the new application.
            PageReference result = controller.saveRebate();

            Test.stopTest();

            // Check we get an error message related to double dipping measures.
            System.assertEquals('4', result.getParameters().get('msg'));
            System.assertNotEquals(null, result.getParameters().get('appId'));
        }
    }

    /**
     * Test that an application is allowed to submit when the user selects equivalent measures to those that have
     * already been applied for the same unit if the previous application has been canceled.
     * This should also happen for Created and Rejected applications.
     * Equivalent measures are those that belong to the same rebate type group.
     */
    static testMethod void testEquivalentMeasuresWithInstallationDateEarlierThan5YearsCanceledStatus() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Submit an application.
            PageReference result = controller.saveRebate();

            // Get the genereted application Id.
            String appId = result.getParameters().get('appId');

            // Get the application by Id.
            Application__c app = [SELECT Status__c FROM Application__c WHERE Id=:appId];

            // Change the status of the application simulating the action of the reviewer.
            app.Status__c = ApplicationUtils.CANCELED_STATUS;
            update app;

            // Save the unitId used in the first application created.
            String unitId = ApexPages.currentPage().getParameters().get('unitId');

            Test.startTest();

            // Initialize another application with the same measures of the recently application created.
            controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Set the unitId and rebate type (the same that we added for previous saved application)
            // for the new application.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(3).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(3).Id,
                    System.now().addYears(-2).format('MM/dd/yyyy'));
            ApexPages.currentPage().getParameters().put('unitId', unitId);

            // Submit the new application.
            result = controller.saveRebate();

            Test.stopTest();

            System.assertEquals('2', result.getParameters().get('msg'));
            System.assertNotEquals(null, result.getParameters().get('appId'));
        }
    }

    /**
     * Test that an application is allowed to submit when the user selects equivalent measures to those that have
     * already been applied for the application's unit. This should happen if the selected installation date is NOT
     * within the range of five years starting from the previous installation date (for that equivalent measure).
     * Equivalent measures are those that belong to the same rebate type group.
     */
    static testMethod void testEquivalentMeasuresWithInstallationDateOlderThan5Years() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            // Add a measure with "Refrigerant Service System" group name.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(2).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(2).Id,
                    System.now().addYears(-6).format('MM/dd/yyyy'));
            // Submit an application.
            controller.saveRebate();

            // Save the unitId used in the first application created.
            String unitId = ApexPages.currentPage().getParameters().get('unitId');

            Test.startTest();

            // Initialize another application with the same measures that the recently application created.
            controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Set the unitId and rebate type for the new application.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(6).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(6).Id,
                    System.now().format('MM/dd/yyyy'));
            ApexPages.currentPage().getParameters().put('unitId', unitId);

            // Submit the new application.
            PageReference result = controller.saveRebate();

            Test.stopTest();

            // Check Application was submitted correctly.
            System.assertEquals('2', result.getParameters().get('msg'));
            System.assertNotEquals(null, result.getParameters().get('appId'));
        }
    }

    /**
     * Test that an application is prevented from submitting when the user selects equivalent measures to those that
     * have already been applied for the application's unit. This should happen if the selected installation date
     * is older than the previous installation date (for that equivalent measure).
     * Equivalent measures are those that belong to the same rebate type group.
     */
    static testMethod void testEquivalentMeasureWithOldInstallationDate() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            // Add a measure with "Refrigerant Service System" group name.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(2).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(2).Id,
                    System.now().format('MM/dd/yyyy'));
            // Submit an application.
            controller.saveRebate();

            // Save the unitId used in the first application created.
            String unitId = ApexPages.currentPage().getParameters().get('unitId');

            Test.startTest();

            // Initialize another application with the same measures that the recently application created.
            controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Set the unitId and rebate type for the new application.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(6).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(6).Id,
                    System.now().addYears(-1).format('MM/dd/yyyy'));
            ApexPages.currentPage().getParameters().put('unitId', unitId);

            // Submit the new application.
            PageReference result = controller.saveRebate();

            Test.stopTest();

            // Check we get an error message related to double dipping measures.
            System.assertEquals('4', result.getParameters().get('msg'));
            System.assertNotEquals(null, result.getParameters().get('appId'));
        }
    }

     /**
    * Test that the Flag for Desktop application's field is set to true and an application note is created
    * when the user selects equivalent measures to those that have already been applied to a similar unit.
    * This unit will have an equivalent address to the application's unit.
    * Equivalent measures are those that belong to the same rebate type group.
    */
    static testMethod void testPotentialEquivalentMeasuresWithInstallationDateEarlierThan5years() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            // Add a measure with "Refrigerant Service System" group name.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(2).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(2).Id,
                    System.now().addYears(-2).format('MM/dd/yyyy'));
            // Submit an application.
            controller.saveRebate();

            String applicationName =
                [SELECT Name FROM Application__c WHERE Building_Street_Address__c = '2345 Main Street'].get(0).Name;

            Test.startTest();

            // Initialize another application with the same measures that the recently application created.
            controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Create a new Site and Unit with equivalent address.
            Site__c site2 = BIGPortalTestUtils.createSite('Test Site2', '2345 Main St', 'Test', '95117', 'San Jose',
                    'CA', '2', contractor.Id);
            insert site2;

            Unit__c unit2 = BIGPortalTestUtils.createUnit('Test Unit2', site2.Id, 'Split', 'Test', 'Test', 10, 10, 10,
                    10, '000002');
            insert unit2;

            ApexPages.currentPage().getParameters().put('unitId', unit2.Id);
            // Set the unitId and rebate type for the new application.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(6).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(6).Id,
                    System.now().addYears(-1).format('MM/dd/yyyy'));
            ApexPages.currentPage().getParameters().put('j_id0:inputAddress', site2.Address_1__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputCity', site2.City__c);
            ApexPages.currentPage().getParameters().put('inputState', site2.State__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputZip', site2.Zip__c);

            // Submit the new application.
            PageReference result = controller.saveRebate();
            Test.stopTest();

            Application__c application = [
                SELECT Name, Flag_for_Desktop__c, (SELECT Action_Type__c, Public__c, Note__c FROM Application_Notes__r)
                FROM Application__c
                WHERE Building_Street_Address__c = :site2.Address_1__c].get(0);

            Application_Note__c note = application.Application_Notes__r.get(0);

            // Check Application was submitted correctly, flag for desktop is set to true and a note is created.
            System.assertEquals('2', result.getParameters().get('msg'));
            System.assertEquals(true, application.Flag_for_Desktop__c);
            System.assertEquals('Flag for Desktop', note.Action_Type__c);
            System.assertEquals(false, note.Public__c);
            System.assert(note.Note__c.contains('This application was automatically flagged for desktop review '
                    + 'due to potential double dipping; see application(s) and its measure(s):\n' + applicationName));
            System.assert(note.Note__c.contains(rebateTypes.get(6).Group__c));
        }
    }

    /**
     * Test that Flag for Desktop application's field leave it on false and a note is not created when the user select
     * equivalent measures to those that have already been applied for the application's unit with equivalent addresses
     * but different zipcode. This should happen if the selected installation date is within the range of five years
     * starting from the previous installation date (for that equivalent measure).
     * Equivalent measures are those that belong to the same rebate type group.
     */
    static testMethod void testPotentialEquivalentMeasuresDifferentZipcode() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            // Add a measure with "Refrigerant Service System" group name.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(2).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(2).Id,
                    System.now().addYears(-2).format('MM/dd/yyyy'));
            // Submit an application.
            controller.saveRebate();

            Test.startTest();
            // Initialize another application with the same measures that the recently application created.
            controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Create a new Site and Unit with equivalent address but different zipcode.
            Site__c site2 = BIGPortalTestUtils.createSite('Test Site2', '2345 Main St', 'Test', '22222', 'San Jose',
                    'CA', '2', contractor.Id);
            insert site2;

            Unit__c unit2 = BIGPortalTestUtils.createUnit('Test Unit2', site2.Id, 'Split', 'Test', 'Test', 10, 10, 10,
                    10, '000002');
            insert unit2;

            ApexPages.currentPage().getParameters().put('unitId', unit2.Id);
            // Set the unitId and rebate type for the new application.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(6).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(6).Id,
                    System.now().addYears(-1).format('MM/dd/yyyy'));
            ApexPages.currentPage().getParameters().put('j_id0:inputAddress', site2.Address_1__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputCity', site2.City__c);
            ApexPages.currentPage().getParameters().put('inputState', site2.State__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputZip', site2.Zip__c);

            // Submit the new application.
            PageReference result = controller.saveRebate();
            Test.stopTest();

            Application__c applicationWithNotes = [
                SELECT Flag_for_Desktop__c, (SELECT Id FROM Application_Notes__r)
                FROM Application__c
                WHERE Building_Street_Address__c = '2345 Main St'].get(0);

            // Check Application was submitted correctly, flag for desktop is still on false and there isn't any note.
            System.assertEquals('2', result.getParameters().get('msg'));
            System.assertEquals(false, applicationWithNotes.Flag_for_Desktop__c);
            System.assertEquals(0, applicationWithNotes.Application_Notes__r.size());
        }
    }

    /**
   * Test that the Flag for Desktop application's field is leave it on false and an application note is not created
   * when the user selects equivalent measures to those that have already been applied to a similar unit.
   * This unit will have an equivalent address to the application's unit.
   * Equivalent measures are those that belong to the same rebate type group.
   */
    static testMethod void testPotentialEquivalentMeasuresInstallationDateOlderThan5years() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            // Add a measure with "Refrigerant Service System" group name.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(2).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(2).Id,
                    System.now().addYears(-6).format('MM/dd/yyyy'));
            // Submit an application.
            controller.saveRebate();

            Test.startTest();
            // Initialize another application with the same measures that the recently application created.
            controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Create a new Site and Unit with equivalent address but different zipcode.
            Site__c site2 = BIGPortalTestUtils.createSite('Test Site2', '2345 Main St', 'Test', '95117', 'San Jose',
                    'CA', '2', contractor.Id);
            insert site2;

            Unit__c unit2 = BIGPortalTestUtils.createUnit('Test Unit2', site2.Id, 'Split', 'Test', 'Test', 10, 10, 10,
                    10, '000002');
            insert unit2;

            ApexPages.currentPage().getParameters().put('unitId', unit2.Id);
            // Set the unitId and rebate type for the new application.
            ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                    rebateTypes.get(6).Id);
            ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(6).Id,
                    System.now().addYears(-1).format('MM/dd/yyyy'));
            ApexPages.currentPage().getParameters().put('j_id0:inputAddress', site2.Address_1__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputCity', site2.City__c);
            ApexPages.currentPage().getParameters().put('inputState', site2.State__c);
            ApexPages.currentPage().getParameters().put('j_id0:inputZip', site2.Zip__c);

            // Submit the new application.
            PageReference result = controller.saveRebate();
            Test.stopTest();

            Application__c applicationWithNotes = [
                SELECT Flag_for_Desktop__c, (SELECT Id FROM Application_Notes__r)
                FROM Application__c
                WHERE Building_Street_Address__c = '2345 Main St'].get(0);

            // Check Application was submitted correctly, flag for desktop is still on false and there isn't any note.
            System.assertEquals('2', result.getParameters().get('msg'));
            System.assertEquals(false, applicationWithNotes.Flag_for_Desktop__c);
            System.assertEquals(0, applicationWithNotes.Application_Notes__r.size());
        }
    }

    static testMethod void testInvalidAttachment1() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.RunAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initPage(controller);
            controller.att1size = null;
            controller.att2size = 32;

            System.currentPageReference().getParameters().put('j_id0:rebateForm:inputFile:file',
                    'testAttachment');
            PageReference result = controller.saveRebate();
            System.assertEquals('1', result.getParameters().get('f1'));
            System.assertEquals('err',result.getParameters().get('msg'));
        }
        Test.stopTest();
    }

    static testMethod void testInvalidAttachment2() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.RunAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initPage(controller);
            controller.att1size = 39;
            controller.att2size = null;
            System.currentPageReference().getParameters().put('j_id0:costEstimate:inputFile:file',
                    'testAttachment');
            PageReference result = controller.saveRebate();
            System.assertEquals('1', result.getParameters().get('f2'));
            System.assertEquals('err',result.getParameters().get('msg'));
        }
        Test.stopTest();
    }

    static testMethod void testInvalidAttachment3() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.RunAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initPage(controller);
            ApexPages.currentPage().getParameters().put('j_id0:qmAddendum:inputFile:file',
                    'QM Addendum.txt');
            controller.att3size = null;
            PageReference result = controller.saveRebate();
            System.assertEquals('1', result.getParameters().get('f3'));
            System.assertEquals('err',result.getParameters().get('msg'));
        }
        Test.stopTest();
    }

    static testMethod void testInvalidAttachment4() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.RunAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initPage(controller);
            ApexPages.currentPage().getParameters().put('j_id0:supplementalDoc:inputFile:file',
                    'Supplemental Documents.txt');
            controller.att4size = null;
            PageReference result = controller.saveRebate();
            System.assertEquals('1', result.getParameters().get('f4'));
            System.assertEquals('err',result.getParameters().get('msg'));
        }
        Test.stopTest();
    }

    static testMethod void testInvalidAttachments() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.RunAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initPage(controller);
            controller.att1size = null;
            controller.att2size = null;
            controller.att3size = null;
            controller.att4size = null;
            ApexPages.currentPage().getParameters().put('j_id0:rebateForm:inputFile:file', 'testAttachment');
            ApexPages.currentPage().getParameters().put('j_id0:costEstimate:inputFile:file', 'testAttachment');
            ApexPages.currentPage().getParameters().put('j_id0:qmAddendum:inputFile:file','QM Addendum.txt');
            ApexPages.currentPage().getParameters().put('j_id0:supplementalDoc:inputFile:file',
                    'Supplemental Documents.txt');

            PageReference result = controller.saveRebate();
            System.assertEquals('1', result.getParameters().get('f1'));
            System.assertEquals('1', result.getParameters().get('f2'));
            System.assertEquals('1', result.getParameters().get('f3'));
            System.assertEquals('1', result.getParameters().get('f4'));
            System.assertEquals('err',result.getParameters().get('msg'));
        }
        Test.stopTest();
    }

    static testMethod void testSiteUpdateTrigger() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        Site__c site = BIGPortalTestUtils.createSite('site', 'address', '12345', contractor);
        insert site;
        System.assertNotEquals(null, site.Id);

        unit = BIGPortalTestUtils.createUnit('unit', 'make', 'model', site);
        insert unit;
        System.assertNotEquals(null, unit.Id);

        Application__c app = BIGPortalTestUtils.createApplication('name', 'add', 'city', 'CA', 'zip', 'phone',
                'email@test.com', unit);
        insert app;
        System.assertNotEquals(null, app.Id);

        site.Zip__c = '93309';
        site.Address_2__c = 'Address 2';
        update site;
        Test.stopTest();
    }

    static testMethod void testCreateRebateApplication() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            PageReference result = controller.saveRebate();
            String appId = result.getParameters().get('appId');
            Application__c app = [select Id, Unit__c, Status__c from Application__c where Id=:appId];
            System.AssertNotEquals(null, app.Unit__c);
            System.assertEquals(ApplicationUtils.SUBMITTED_STATUS, app.Status__c);
        }
        Test.stopTest();
    }

    static testMethod void testRebateApplicationForm() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            Integer maxRebateAmount = controller.getMaximumRebate();
            Map<String, Integer> types = controller.getRebateTypesUser();

            System.assertEquals(types.keySet().size(), rebateTypes.size());

            Map<String, String> installationDates = controller.getInstallationDates();
            System.assertEquals(installationDates.keySet().size(), rebateTypes.size());
            PageReference result = controller.saveDraft();
            String appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId', appId);
            types = controller.getRebateTypesUser();
            System.assertEquals(types.keySet().size(), rebateTypes.size());
            installationDates = controller.getInstallationDates();
            System.assertEquals(installationDates.keySet().size(), rebateTypes.size());
            Map<String, Application_File__c> applicationFiles = controller.getApplicationFiles();
            System.assertEquals(3, applicationFiles.keySet().size());
            List<Application_File__c> supplementalDocs = controller.getSupplementalDocs();
            System.assertEquals(1, supplementalDocs.size());
        }
        Test.stopTest();
    }

    static testMethod void testGetCustomer() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            Application__c app = buildApplication(contractor);
            ApexPages.currentPage().getParameters().put('appId', app.Id);
            Application__c result = controller.getApplication();
            System.assertNotEquals(null, result);
        }
        Test.stopTest();
    }

    static testMethod void testGetTechnicians() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);
        contact = BIGPortalTestUtils.getContact('portalContact');

        Test.startTest();

        Program_Enrollment__c pe = new Program_Enrollment__c();
        pe.Account__c = contractor.Id;
        insert pe;

        Employee_Program_Enrollment__c epe = new Employee_Program_Enrollment__c();
        epe.Contact__c = contact.Id;
        epe.Role__c = 'Technician';
        epe.Program_Enrollment__c = pe.Id;
        epe.Enrollment_Stage__c = 'Active';
        insert epe;

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            List<Contact> result = controller.getTechnicians();
            Integer resultCount = result.size();
            System.assertEquals(1, resultCount);
        }
        Test.stopTest();
    }

    static testMethod void testGetApplicationRebateTypes() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();

            //the application is inserted by the method buildApplication
            String appId = buildApplication(contractor).Id;
            Rebate_Type__c rt = BIGPortalTestUtils.createRebateType('Refrigerant System Service', 50, 'TK09',
                    'Refrigerant System Service');
            insert rt;
            Measure__c m = new Measure__c();
            m.Application__c = appId;
            m.Rebate_Type__c = rt.Id;
            m.Rebate_Type__r = rt;
            insert m;

            Map<String, Integer> result = controller.getApplicationRebateTypes(appId);
            Integer size = result.size();
            System.assertEquals(1, size);
        }
        Test.stopTest();
    }

    static testMethod void testGetInstallationDates() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            //the application is inserted by buildApplication method
            String appId = buildApplication(contractor).Id;
            ApexPages.currentPage().getParameters().put('appId', appId);

            Rebate_Type__c rt = BIGPortalTestUtils.createRebateType('Refrigerant System Service', 50, 'TK07',
                    'Refrigerant System Service');
            insert rt;
            Measure__c m = new Measure__c();
            m.Application__c = appId;
            m.Rebate_Type__c = rt.Id;
            m.Rebate_Type__r = rt;
            m.Installation_Date__c = Date.today();
            insert m;
            String thisValue = Datetime.newInstance(m.Installation_Date__c,
                    Time.newInstance(0,0,0,0)).format('MM/dd/yyyy');

            Map<String, String> result = controller.getInstallationDates();
            System.assertEquals(thisValue, result.get('Refrigerant System Service'));
        }
        Test.stopTest();
    }

    static testMethod void testGetApplicationFiles() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();

            String appId = buildApplication(contractor).Id;
            ApexPages.currentPage().getParameters().put('appId', appId);

            Application_File__c apf1 = BIGPortalTestUtils.createApplicationFile('f1', 'HVAC Rebate Application Form',
                    appId);
            Application_File__c apf2 = BIGPortalTestUtils.createApplicationFile('f2', 'HVAC Work - Cost Estimates',
                    appId);
            Application_File__c apf3 = BIGPortalTestUtils.createApplicationFile('f3', 'QM Service Agreement Addendum',
                    appId);

            insert apf1;
            insert apf2;
            insert apf3;

            Map<String, Application_File__c> result = controller.getApplicationFiles();

            System.assertEquals(apf1.Id, result.get('Rebate Form').Id);
            System.assertEquals(apf2.Id, result.get('Cost Estimate').Id);
            System.assertEquals(apf3.Id, result.get('QM Addendum').Id);
        }
        Test.stopTest();
    }

    static testMethod void testGetSupplementalDocs() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();

            String appId = buildApplication(contractor).Id;
            ApexPages.currentPage().getParameters().put('appId', appId);
            Application_File__c apf1 = BIGPortalTestUtils.createApplicationFile('f1', 'Supplemental Documents', appId);
            insert apf1;

            List<Application_File__c> result = controller.getSupplementalDocs();
            System.assertEquals(apf1.Id, result.get(0).Id);
        }
        Test.stopTest();
    }

    static testMethod void testRetiredRebateTypeAfterSubmitting() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            Application__c app;
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Submit Application
            PageReference result = controller.saveRebate();

            String appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId', appId);
            app = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId})).get(0);
            // Verify if application was successfully submitted
            System.assertEquals(ApplicationUtils.SUBMITTED_STATUS, app.Status__c);
            // Deactivate rebate type EQUIPMENT_TYPE_MOTOR one minute after submitting the app with it
            rebateTypes[3].Retirement_Date__c = Datetime.now().addSeconds(60);
            update rebateTypes[3];

            app.Status__c = ApplicationUtils.CORRECTION_REQUIRED_STATUS;
            update app;
            app = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId})).get(0);
            System.assertEquals(ApplicationUtils.CORRECTION_REQUIRED_STATUS, app.Status__c);

            // Checks if the EQUIPMENT_TYPE_MOTOR is on the UI once the app is Correction Required
            Map<Id, Rebate_Type__c> rebateTypesById = new Map<Id, Rebate_Type__c>(controller.getRebateTypes());
            System.assert(rebateTypesById.containsKey(rebateTypes[3].Id));
        }
        Test.stopTest();
    }

    static testMethod void testRetiredRebateTypeBeforeSubmitting() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            // Create rebate types
            initRebateApplicationData(controller);
            // Deactivate rebate type EQUIPMENT_TYPE_MOTOR
            rebateTypes[3].Retirement_Date__c = Datetime.now();
            update rebateTypes[3];
            // Get the rebate types to show them on the UI
            Map<Id, Rebate_Type__c> rebateTypesById = new Map<Id, Rebate_Type__c>(controller.getRebateTypes());
            // The retired rebate type shouldn't appear on the UI
            System.assert(!rebateTypesById.containsKey(rebateTypes[3].Id));
        }
        Test.stopTest();
    }

    static testMethod void testGetMaximumRebate() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initPage(controller);

            Double n1 = 4.1;
            Double n2 = 4.1;

            insert BIGPortalTestUtils.createRebateType('Refrigerant System Service', n1, 'TK07',
                    'Refrigerant System Service');
            insert BIGPortalTestUtils.createRebateType('Refrigerant System Service', n2, 'TK07',
                    'Refrigerant System Service');

            Integer result = controller.getMaximumRebate();
            System.assertEquals(8, result);
        }
        Test.stopTest();
    }

    static testMethod void testGetReview() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            Application__c app = buildApplication(contractor);
            ApexPages.currentPage().getParameters().put('appId', app.Id);

            Review__c rev = new Review__c();
            rev.Application__c = app.Id;
            insert rev;

            Review__c result = controller.getReview();
            System.assertEquals(rev.Id, result.Id);
        }
        Test.stopTest();
    }

    static testMethod void testGetUnits() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            ApexPages.currentPage().getParameters().put('inputName', 'my site');
            Site__c st = BIGPortalTestUtils.createSite('my site', 'address', '12345', contractor);
            insert st;
            Unit__c u = BIGPortalTestUtils.createUnit('unit', 'make', 'model', st);
            insert u;

            System.assertEquals(1, controller.getUnits().size());
            ApexPages.currentPage().getParameters().put('inputName', 'rrrr');
            System.assertEquals(0, controller.getUnits().size());
        }
        Test.stopTest();
    }

    static testMethod void testSearchUnit() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            PageReference pageRef = Page.BIGPortalHVACSearchCust;
            PageReference result = controller.searchUnit();
            System.assertEquals(pageRef.getUrl(), result.getUrl());
        }
        Test.stopTest();
    }

    static testMethod void testGetSearchString() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            ApexPages.currentPage().getParameters().put('inputName','test');
            String result = controller.getSearchString();
            System.assertEquals('test',result);
        }
        Test.stopTest();
    }

    static testMethod void testGetJSONUnits() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            String result = controller.getJSONUnits();
            System.assertNotEquals(null, result);
        }
        Test.stopTest();
    }

    /**
     * Check Rebate Types are getted correctly
     */
    static testMethod void testGetAllRebateTypes() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            Test.startTest();
                Map<Id, Rebate_Type__c> result = controller.getAllRebateTypes();
            Test.stopTest();

            // Check rebate types quantity
            System.assertEquals(rebateTypes.size(), result.size());
        }
    }

    static testMethod void testGetACQCIncentiveTotal() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            Application__c app = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
            app.Incentive_Total__c = 4000;
            insert app;
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            ApexPages.currentPage().getParameters().put('appId', app.Id);
            System.assertEquals(4000, controller.getACQCIncentiveTotal());
        }
        Test.stopTest();
    }

    static testMethod void testGetJSONUnitsSearchCust() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            Site__c st = BIGPortalTestUtils.createSite('site', 'address', '12345', contractor);
            insert st;
            Unit__c u = BIGPortalTestUtils.createUnit('unit', 'make', 'model', st);
            insert u;
            BIGPortalHVACSearchCustController controller = new BIGPortalHVACSearchCustController();
            String result = controller.getJSONUnits();
            System.assertNotEquals(null, result);
        }
        Test.stopTest();
    }

    static Application__c buildApplication(Account pContractor) {
        Site__c st = BIGPortalTestUtils.createSite('Name', 'St', '12345', pContractor);
        insert st;
        unit = BIGPortalTestUtils.createUnit('Name', 'Make', 'Model', st);
        insert unit;
        Application__c app = BIGPortalTestUtils.createApplication('Site name', 'address', 'city', 'CA', '12345',
                '(650) 887-0260', 'email@gmail.com', unit);
        insert app;
        return app;
    }

    /**
    * Instance the app for the controller
    *
    *@param controller the controller class
    */
    private static void initPage(BIGPortalHVACCustRebateApplicController controller) {
        controller.checkMessages();
    }

    /**
     * Verify Savings population on Application and Measures for ACQC.
     */
    static testMethod void testSavingsMatch() {
        String appId;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;

        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            PageReference result = controller.saveDraft();
            appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId', appId);
            System.assertEquals('1', result.getParameters().get('msg'));
        }
        Test.stopTest();

        /* Get map for those combinations we want (Climate_Zone__c = 4 (obtained on zipCode input
         * on initRebateApplicationData method) & Measure_Code__c = Tk10 or H796)
         */
        Map<String, MeasureUtils.measureSavingsWrapper> measureSavingsMap = MeasureUtils.getMeasureSavingsMetadata(
                new Set<Integer>{4}, new Set<String>{'TK10', 'H796'});
        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{appId});
        Application__c app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId}).get(0);
        String climateZone = (String.valueOf(app.Climate_Zone__c)).leftPad(2, '0');

        // Verify saving populated on measure for Measure Code TK10
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwSavings
                * app.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwhSavings
                * app.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).thermsSavings
                * app.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).Therms_Savings__c);
        // Verify saving populated on measure for Measure Code H796
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwSavings
                * app.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwhSavings
                * app.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).thermsSavings
                * app.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Get application savings by summing its measure savings
        sumKwSavings = (measureMap.get('TK10' + climateZone).kW_Savings__c
                + measureMap.get('H796' + climateZone).kW_Savings__c);
        sumKwhSavings = (measureMap.get('TK10' + climateZone).kWh_Savings__c
                + measureMap.get('H796' + climateZone).kWh_Savings__c);
        sumThermSavings = (measureMap.get('TK10' + climateZone).Therms_Savings__c
                + measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Verify application data
        System.assertEquals(sumKwhSavings, app.kWh_Savings__c);
        System.assertEquals(sumKwSavings, app.kW_Savings__c);
        System.assertEquals(sumThermSavings, app.Therms_Savings__c);
    }

    /**
     * Verify Savings population on Application and Measures for ACQC when a combination isn't found, should be all null.
     */
    static testMethod void testSavingsNoMatch() {
        String appId;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;

        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            // Change zip code to one corresponding to climate zone 6
            ApexPages.currentPage().getParameters().put('j_id0:inputZip','93105');
            PageReference result = controller.saveDraft();
            appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId', appId);
            System.assertEquals('1', result.getParameters().get('msg'));
        }
        Test.stopTest();

        // Get map for those combinations we want (Climate_Zone__c = 2 & Measure_Code__c = Tk10 or H796)
        Map<String, MeasureUtils.measureSavingsWrapper> measureSavingsMap = MeasureUtils.getMeasureSavingsMetadata(
                new Set<Integer>{6}, new Set<String>{'TK10', 'H796'});
        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{appId});
        Application__c app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId}).get(0);
        String climateZone = (String.valueOf(app.Climate_Zone__c)).leftPad(2, '0');

        // Verify saving populated on measure for Measure Code TK10
        System.assertEquals(null, measureMap.get('TK10' + climateZone).kW_Savings__c);
        System.assertEquals(null, measureMap.get('TK10' + climateZone).kWh_Savings__c);
        System.assertEquals(null, measureMap.get('TK10' + climateZone).Therms_Savings__c);
        // Verify saving populated on measure for Measure Code H796
        System.assertEquals(null, measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(null, measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(null, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Verify application data
        System.assertEquals(null, app.kWh_Savings__c);
        System.assertEquals(null, app.kW_Savings__c);
        System.assertEquals(null, app.Therms_Savings__c);
    }

    /**
     * Verify Savings population on Application and Measures for ACQC when climate zone is missing, should be all null
     */
    static testMethod void testSavingsNullClimateZone() {
        String appId;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;

        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            // Change zip code to one that doesn't have a climate zone associated
            ApexPages.currentPage().getParameters().put('j_id0:inputZip','93105');
            PageReference result = controller.saveDraft();
            appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId', appId);
            System.assertEquals('1', result.getParameters().get('msg'));
        }
        Test.stopTest();

        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{appId});
        Application__c app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId}).get(0);
        String climateZone = (String.valueOf(app.Climate_Zone__c)).leftPad(2, '0');

        // Verify saving populated on measure for Measure Code TK10
        System.assertEquals(null, measureMap.get('TK10' + climateZone).kW_Savings__c);
        System.assertEquals(null, measureMap.get('TK10' + climateZone).kWh_Savings__c);
        System.assertEquals(null, measureMap.get('TK10' + climateZone).Therms_Savings__c);
        // Verify saving populated on measure for Measure Code H796
        System.assertEquals(null, measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(null, measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(null, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Verify application data
        System.assertEquals(null, app.kWh_Savings__c);
        System.assertEquals(null, app.kW_Savings__c);
        System.assertEquals(null, app.Therms_Savings__c);
    }

    /**
     * Verify Savings population on Application and Measures for ACQC when climate zone is missing, should be all null
     */
    static testMethod void testSavingsNullTotalUnitCapacity() {
        String appId;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;

        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);

        Test.startTest();

        System.runAs(portalUser) {
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            // Set Total_Unit_Capacity__c to null
            unit.Stage_1_Cooling_Capacity__c = null;
            unit.Stage_2_Cooling_Capacity__c = null;
            unit.Stage_3_Cooling_Capacity__c = null;
            unit.Stage_4_Cooling_Capacity__c = null;
            update unit;
            PageReference result = controller.saveDraft();
            appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId', appId);
            System.assertEquals('1', result.getParameters().get('msg'));
        }
        Test.stopTest();

        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{appId});
        Application__c app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{appId}).get(0);
        String climateZone = (String.valueOf(app.Climate_Zone__c)).leftPad(2, '0');

        // Verify saving populated on measure for Measure Code TK10
        System.assertEquals(null, measureMap.get('TK10' + climateZone).kW_Savings__c);
        System.assertEquals(null, measureMap.get('TK10' + climateZone).kWh_Savings__c);
        System.assertEquals(null, measureMap.get('TK10' + climateZone).Therms_Savings__c);
        // Verify saving populated on measure for Measure Code H796
        System.assertEquals(null, measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(null, measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(null, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Verify application data
        System.assertEquals(null, app.kWh_Savings__c);
        System.assertEquals(null, app.kW_Savings__c);
        System.assertEquals(null, app.Therms_Savings__c);
    }

    /**
     * Test Program Acces behavior when you don't have access to ACQC program.
     */
    static testMethod void testNotACQCPortalProgramAccess() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contact = [SELECT Program_Enrollment__c FROM Contact WHERE Email = 'portalContact@test.com'];
        contact.Program_Enrollment__c = 'HU; AHU';
        update contact;

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGACQCRebateApplicationForm);
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();

            Test.startTest();
            PageReference accessDenied = controller.checkMessages();
            Test.stopTest();
            System.assertEquals(Page.AccessDenied.getUrl(), accessDenied.getUrl());
        }
    }

    /**
     * Portal user should not be able to save a new application when ACQC program is suspended.
     */
    static testMethod void testACQCSuspendedOnSave() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        // Create a new ACQC Program Enrollment in Suspended status.
        insert BIGPortalTestUtils.createProgramEnrollment(
                contractor.Id,
                Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName().get('ACQC').getRecordTypeId(),
                ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS);

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGACQCRebateApplicationForm);
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            Test.startTest();
            PageReference result = controller.saveDraft();
            Test.stopTest();

            Test.setCurrentPage(result);
            controller.checkMessages();

            System.assertEquals(null, ApexPages.currentPage().getParameters().get('appId'));
            System.assertEquals('6', ApexPages.currentPage().getParameters().get('msg'));
            System.assertEquals(
                    BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR,
                    ApexPages.getMessages().get(0).getSummary());
        }
    }

    /**
     * Portal user should not be able to submit a new application when ACQC program is suspended.
     */
    static testMethod void testACQCSuspendedOnSubmit() {
        portalUser = BIGPortalTestUtils.getUser(PORTAL_USER_NAME);
        contractor = BIGPortalTestUtils.getAccount(PORTAL_ACCOUNT_NAME);

        // Create a new ACQC Program Enrollment in Suspended status.
        insert BIGPortalTestUtils.createProgramEnrollment(
                contractor.Id,
                Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName().get('ACQC').getRecordTypeId(),
                ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS);

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGACQCRebateApplicationForm);
            BIGPortalHVACCustRebateApplicController controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);

            Test.startTest();
            PageReference result = controller.saveRebate();
            Test.stopTest();

            Test.setCurrentPage(result);
            controller.checkMessages();

            System.assertEquals('6', result.getParameters().get('msg'));
            System.assertEquals(null, result.getParameters().get('appId'));
            System.assertEquals(
                    BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR,
                    ApexPages.getMessages().get(0).getSummary());
        }
    }

    private static void initRebateApplicationData(BIGPortalHVACCustRebateApplicController controller) {
        contractor = [SELECT Id FROM Account LIMIT 1];
        contact = [SELECT Id FROM Contact LIMIT 1];

        // Create Rebate Types
        rebateTypes = new List<Rebate_Type__c>();
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Full ACCA Standard 4 HVAC System Assessment', 50, 'TK07',
                'Full ACCA Standard 4 HVAC System Assessment'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Air Flow Correction', 400, 'TK08',
                'Air Flow Correction'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Refrigerant System Service', 50, 'TK103',
                'Refrigerant System Service'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType(
                BIGPortalHVACCustRebateApplicController.EQUIPMENT_TYPE_MOTOR, 300, 'TK10', 'Replacement Blower Motor'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType(
                BIGPortalHVACCustRebateApplicController.EQUIPMENT_TYPE_DELAY, 200, 'H796',
                'Enhanced Time Delay Relay'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('One-year QM Service Agreement', 50, 'TK12',
                'One-year QM Service Agreement'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Refrigerant System Service: Increase Charge With TXV',
                50, 'HV374', 'Refrigerant System Service'));

        for (Integer i = 0; i < rebateTypes.size(); i++) {
            rebateTypes[i].Display_Sequence__c = i;
        }

        insert rebateTypes;
        // Create site.
        Site__c site = BIGPortalTestUtils.createSite('Test Site', '2345 Main Street', 'Test', '95117', 'San Jose',
                'CA', '2', contractor.Id);
        insert site;
        System.assertNotEquals(null,site.Id);
        // Create unit.
        unit = BIGPortalTestUtils.createUnit('Test Unit', site.Id, 'Split', 'Test', 'Test', 10, 10, 10, 10, '000001');
        insert unit;
        System.assertNotEquals(null,unit.Id);

        // Simulate user selection of the previous created site.
        ApexPages.currentPage().getParameters().put('unitId', unit.Id);
        ApexPages.currentPage().getParameters().put('inputName', site.Name);
        ApexPages.currentPage().getParameters().put('j_id0:inputAddress', site.Address_1__c);
        ApexPages.currentPage().getParameters().put('j_id0:inputCity', site.City__c);
        ApexPages.currentPage().getParameters().put('inputState', site.State__c);
        ApexPages.currentPage().getParameters().put('j_id0:inputZip', site.Zip__c);
        ApexPages.currentPage().getParameters().put('inputUnit',contact.Id);
        ApexPages.currentPage().getParameters().put('inputPhone','4082475929');
        ApexPages.currentPage().getParameters().put('j_id0:inputEmail','');
        ApexPages.currentPage().getParameters().put('inputPayee','on');
        ApexPages.currentPage().getParameters().put('rebateForm','');
        ApexPages.currentPage().getParameters().put('costEstimate','');
        ApexPages.currentPage().getParameters().put('thisContractor', contractor.Id);
        ApexPages.currentPage().getParameters().put('thisSiteFirstName','');
        ApexPages.currentPage().getParameters().put('thisSiteLastName','');
        // Simulate user selection of the following measures: Replacement Blower Motor and Enhanced Time Delay Relay.
        ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.REBATE_ID,
                rebateTypes.get(3).Id + ',' + rebateTypes.get(4).Id);
        ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.MAKE_MODEL_DELAY_OPTION,
                'GreenFan 140X-XX');
        ApexPages.currentPage().getParameters().put(BIGPortalHVACCustRebateApplicController.MAKE_MODEL_MOTOR_OPTION,
                'Rescue Ecotech 5552ET');
        ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(3).Id,
                System.now().addYears(-2).format('MM/dd/yyyy'));
        ApexPages.currentPage().getParameters().put('installationDate' + rebateTypes.get(4).Id,
                System.now().addYears(-2).format('MM/dd/yyyy'));
        // Simulate user upload of all attachments.
        ApexPages.currentPage().getParameters().put('j_id0:rebateForm:inputFile:file','Rebate Application Form.txt');
        ApexPages.currentPage().getParameters().put('j_id0:costEstimate:inputFile:file','Cost Estimates.txt');
        ApexPages.currentPage().getParameters().put('j_id0:qmAddendum:inputFile:file','QM Addendum.txt');
        ApexPages.currentPage().getParameters().put('j_id0:supplementalDoc:inputFile:file',
                'Supplemental Documents.txt');
        Attachment attach1 = new Attachment(Name = 'Rebate Application Form Attachment Body',
                Body = Blob.valueOf('Rebate Application Form Attachment Body'));
        Attachment attach2 = new Attachment(Name = 'Cost Estimate(s) Attachment Body',
                Body = Blob.valueOf('Cost Estimate(s) Attachment Body'));
        Attachment attach3 = new Attachment(Name = 'QM Addendum', Body = Blob.valueOf('QM Addendum'));
        Attachment attach4 = new Attachment(Name = 'Supplemental Documents',
                Body = Blob.valueOf('Supplemental Documents'));
        controller.attachment1 = attach1;
        controller.attachment2 = attach2;
        controller.attachment3 = attach3;
        controller.attachment4 = attach4;
        controller.att1size = 39;
        controller.att2size = 32;
        controller.att3size = 39;
        controller.att4size = 32;

        initPage(controller);
    }
}