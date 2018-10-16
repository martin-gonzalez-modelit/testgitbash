@isTest
public class TestAdvancedHuAppController {
    private static User portalUser;
    private static String BPIAnalystId;
    private static Dwelling_Unit__c dwellingUnit;
    private static Account portalAccount;
    private static Contact portalContact;
    public static Boolean isCalloutTesting = false;

    static testMethod void testPreAdvancedApplication() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            Test.startTest();
            // Save Pre-Application without building (will receive error)
            controller.savePreApplication();
            System.assertEquals(controller.preApplication.Id, null);

            // Search and assign building
            controller.dwellingSearchText = 'Test Dwelling Unit';
            controller.searchDwellingUnit();
            List<Dwelling_Unit__c> dwellingUnits = controller.getDwellingUnitsList();
            System.assert(dwellingUnits.size() > 0);
            // Set dwelling unit as we would on the modal search.
            controller.dwellingToAssignId = dwellingUnits.get(0).Id;
            controller.assignDwellingUnit();
            System.assert(controller.dwellingUnit != null);

            // Save Pre-Application will success now
            controller.savePreApplication();
            System.assertNotEquals(controller.preApplication.Id, null);

            // Setting invalid extensions. It'll fail.
            controller.contractProposalSOW = BIGPortalTestUtils.createAttachment('testFile.xls');
            List<String> fillers = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testFile.xml', fillers);
            controller.homePerformanceSystemFile = BIGPortalTestUtils.createAttachment('testFile.xls');
            controller.testInMeasurements = BIGPortalTestUtils.createAttachment('testFile.xls');
            controller.additionalDocuments = BIGPortalTestUtils.createAttachment('testFile.xls');
            controller.paymentReleaseAuthorization = BIGPortalTestUtils.createAttachment('testFile.xls');

            // Go next without completing Pre App required fields (will receive error)
            controller.preAppNext();
            System.assertEquals(true, ApexPages.hasMessages());
            // Complete required fields for pre application
            controller.preApplication.Proposed_Package_Cost__c = 4000;
            controller.preApplication.Total_Incentive__c = 2000;
            controller.setFormattedTestInDate(Date.today());
            controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(1).getValue();
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'Yes';
            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Create attachments
            createPreAppAttachments(controller, null);
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testFile.xml', fillers);

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            // Set HPHI data.
            setHPHI(controller, controller.getHPHIPractitioners().get(0).getValue(), false);

            controller.preAppNext();
            // If the page with this paremeters, simulate the step 2 in the pre-application.
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'true');

            // Execute the init method with the new parameters
            controller.init();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(3, controller.application.Application_Step__c);
            System.assertEquals('',controller.getContractorPayeeDownloadLink());
            System.assertEquals('',controller.getNonAccountOwnerDownloadLink());

            // Add Test Note and submit for review
            controller.appNotes = 'Test Note';
            controller.submitPreApplicationReview();
            Test.stopTest();

            /**
             * As we don't query the Total_Incentive_Adjustment__c through the action init we need to do it here
             * in order to compare this value against its relative on the sub application.
             */
            Application__c app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{controller.application.Id}).get(0);
            Sub_Application__c preApp = app.Sub_Applications__r.get(0);
            String expectedPractitioner = controller.getHPHIPractitioners().get(0).getValue();

            System.assert(app.kW_Savings__c != null && app.kW_Savings__c != 0);
            System.assertEquals(app.kW_Savings__c, app.Sub_Applications__r.get(0).Demand_Savings_kW__c);
            System.assert(controller.preApplication.Total_Incentive_Adjustment__c != null);
            System.assertEquals(controller.preApplication.Total_Incentive_Adjustment__c,
                    app.Total_Incentive_Adjustment__c);
            // Validate HPHI Data.
            System.assertEquals('Yes', controller.application.Has_HPHI__c);
            System.assert(String.isNotBlank(controller.application.HPHI_Practitioner__c));
            System.assertEquals(expectedPractitioner, app.HPHI_Practitioner__c);
            System.assertEquals('Yes', preApp.Has_HPHI__c);
            System.assertEquals(expectedPractitioner, preApp.HPHI_Practitioner__c);
            System.assertEquals(1200, preApp.HPHI_Bonus__c);

            System.assertEquals('Yes', controller.application.Has_Pre_Install_HES__c);
            System.assertEquals(ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS, controller.application.Status__c);
        }
    }

    static testMethod void testPreAdvancedSubmissionUserSessionCollision() {
        initData();
        BIGPortalAdvancedHuAppController controller;

        System.RunAs(portalUser) {
            Test.startTest();
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            controller = new BIGPortalAdvancedHUAppController();
            controller.init();
            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            searchBuildingAndRequiredFields(controller);
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'No';

            // Create attachments
            createPreAppAttachments(controller, null);

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.preAppNext();

            // Simulates when user clicks Next in the portal.
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'true');
            // Execute the init method with the new parameters
            controller.init();

            Test.stopTest();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(3, controller.application.Application_Step__c);
        }

        // Put this thread to sleep. (Apex does not have this functionality so we have to make this workaround)
        Long startingTime = System.now().getTime(); // Num milliseconds since Jan 1 1970
        Integer delayInMilliseconds = 3000; // One-second delay
        while (System.now().getTime() - startingTime < delayInMilliseconds)  {
            // Do nothing until desired delay has passed
        }

        // Updates the application out of the portal user context so the last modified by field will not match with
        // what the controller has in memory. Emulating an update into the record from an internal user.
        update controller.application;

        System.RunAs(portalUser) {
            controller.submitPreApplicationReview();

            Boolean hasSessionError = false;
            for (Apexpages.Message msg : ApexPages.getMessages()) {
                if (msg.getDetail().contains(BIGPortalManageApplicationUtils.DATA_INTEGRITY_ERROR)) {
                    hasSessionError = true;
                }
            }
            System.assert(hasSessionError);
        }
    }

    static testMethod void testPreAdvancedSaveUserSessionCollision() {
        initData();
        BIGPortalAdvancedHuAppController controller;

        System.RunAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            controller = new BIGPortalAdvancedHUAppController();
            controller.init();
            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            searchBuildingAndRequiredFields(controller);

            // Create attachments
            createPreAppAttachments(controller, null);
            // Fill place holder where there are curly brackets
            List<String> fillers = new List<String>{'4624.96', '191.9349077', '579.5676239',
                    '379.0218463', '420.96', '17.9349077', '57.5639', '35.0218463'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testHpxml.xml', fillers);
            controller.savePreApplication();

            // Simulates when user clicks Edit in the portal.
            ApexPages.currentPage().getParameters().put('action', 'edit');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            // Execute the init method with the new parameters
            controller.init();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(2, controller.application.Application_Step__c);

            Test.startTest();
            // Create a new controller to test when the same portal user opens a new tab and performs some operations
            // over the same application.
            BIGPortalAdvancedHuAppController controllerDuplicate = new BIGPortalAdvancedHUAppController();
            controllerDuplicate.init();

            // Fill place holder where there are curly brackets
            controllerDuplicate.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testHpxml.xml',
                    fillers);
            controllerDuplicate.application.Has_Pre_Install_HES__c = 'Yes';
            controllerDuplicate.application.Has_HPHI__c = 'No';

            createHomeEnergyScoreData(controllerDuplicate, true);
            setHomeEnergyScoreAssessor(controllerDuplicate, true,
                    controller.getHomeEnergyScoreContacts().get(0).getValue());

            controllerDuplicate.preAppNext();

            // Simulates the view when user is at the last step (Review & Submit).
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            completeBuildingOnApplication(controllerDuplicate);
            // Submits the application in the most recently opened tab.
            controllerDuplicate.submitPreApplicationReview();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS,
                    controllerDuplicate.application.Status__c);

            // Save the application with an old portal session. If everything goes well the latest data
            // should not get overwritten.
            controller.savePreApplication();
            ApexPages.currentPage().getParameters().put('action', 'view');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            controller.init();

            Test.stopTest();
            System.assertEquals(ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS, controller.application.Status__c);
        }
    }

    static testMethod void testPreAdvanceTotalEnergySavingsPercentPreventSumbission() {
        initData();
        BIGPortalAdvancedHuAppController controller;
        System.runAs(portalUser) {
            Test.startTest();
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            controller = new BIGPortalAdvancedHUAppController();
            controller.init();
            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            searchBuildingAndRequiredFields(controller);

            // Create attachments
            createPreAppAttachments(controller, null);
            // Create a pre hpxml with the needed conditions to get a total energy savings percent(Sub_Application__c)
            // less than the minimum lower limit (from Rebate Tiers custom settings)
            List<String> fillers = new List<String>{'100', '100', '0', '0', '95', '95', '0', '0'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testHpxml.xml', fillers);
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'No';

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.preAppNext();
            // Simulates when user clicks Next in the portal.
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'true');
            // Execute the init method with the new parameters
            controller.init();

            Test.stopTest();

            Integer structure = BIGPortalAdvanceHUApplicationUtils.getStructureDependingOnDates(controller.application,
                    controller.preApplication, false);
            Decimal minimumLowerLimit = BIGPortalAdvanceHUApplicationUtils.getMinimumLowerLimit(structure);

            Boolean containsMessage = false;
            for (Apexpages.Message msg: ApexPages.getMessages()) {
                if (msg.getDetail().contains(String.format(
                        BIGPortalAdvanceHuApplicationUtils.TOTAL_ENERGY_SAVINGS_PERCENT_ERROR,
                        new List<String>{minimumLowerLimit.round(System.RoundingMode.CEILING).format()}))) {
                    containsMessage = true;
                    break;
                }
            }
            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assert(containsMessage);
        }
    }

    static testMethod void testReviewPreApplication() {
        initData();
        system.RunAs(portalUser) {
            Test.startTest();
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();
            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            searchBuildingAndRequiredFields(controller);
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'No';

            // Create attachments
            createPreAppAttachments(controller, null);

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.preAppNext();

            // If the page with this paremeters, simulate the step 2 in the pre-application.
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'true');
            controller.selectedBpiAnalyst = BPIAnalystId;
            controller.preApplication.BPI_Analyst__c = BPIAnalystId;

            // Execute the init method with the new parameters
            controller.init();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(3, controller.application.Application_Step__c);

            // set application to Pre-Install correction required
            controller.application.Status__c = ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS;
            update controller.application;

            // create review object
            /*Review__c review = new Review__c();
            review.Sub_Application__c = controller.preApplication.Id;
            review.Comments__c = 'This is my comment';
            review.Additional_Comments__c = 'This is my additional comment';
            insert review;

            ApexPages.currentPage().getParameters().put('action', 'view');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            controller = new BIGPortalAdvancedHUAppController();
            controller.init();*/

            Test.stopTest();
        }
    }

    static testMethod void testSelectAccreditedBPIAnalyst() {
        initData();

        Credential__c c = [
            SELECT Credential_Type__c
            FROM Credential__c
            WHERE Account__c =: portalAccount.Id limit 1
            ];

        c.Credential_Type__c = 'BPI Accreditation';
        update c;

        System.runAs(portalUser) {
            Test.startTest();
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            // Search and assign building
            controller.dwellingSearchText = 'Test Dwelling Unit';
            controller.searchDwellingUnit();
            System.assertEquals(true, controller.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            controller.dwellingToAssignId = controller.getDwellingUnitsList().get(0).Id;
            controller.assignDwellingUnit();
            System.assert(controller.dwellingUnit != null);

            // Create Accredited BPI Analyst
            createBpiAnalyst(controller);
            controller.newBPIAnalyst.BPI_License_Number__c = null;
            controller.newBPIAnalyst.BPI_License_Expiration_Date__c = null;
            controller.isBpiCertified = false;
            controller.saveBPIAnalyst();
            System.assert(controller.selectedBPIAnalyst != null);

            // Save Pre-Application will success now
            controller.savePreApplication();
            System.assertNotEquals(controller.preApplication.Id, null);

            // Execute the init method with the new parameters
            ApexPages.currentPage().getParameters().put('action', 'edit');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            // Someone edits the employee program enrollment manually in Salesforce
            List<Employee_Program_Enrollment__c> employees = [
                SELECT Role__c FROM Employee_Program_Enrollment__c WHERE Contact__c =: controller.selectedBPIAnalyst
                ];
            for (Employee_Program_Enrollment__c epe : employees) {
                epe.Role__c = 'Emergency Contact';
            }
            update employees;

            // Refresh page and load the bpi analysts
            controller.init();
            controller.getAnalysts();

            controller.savePreApplication();

            Test.stopTest();

            System.assert(controller.selectedBPIAnalyst != null);
            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(2, controller.application.Application_Step__c);

            Contact contact = [
                SELECT (SELECT Role__c, Program_Enrollment__r.RecordType.Name FROM Employee_Program_Enrollments__r),
                    (SELECT Credential_Type__c FROM Credentials__r)
               FROM Contact WHERE Id =: controller.selectedBPIAnalyst
               ];
            System.assertEquals(0, contact.Credentials__r.size());
            System.assertEquals(2, contact.Employee_Program_Enrollments__r.size());
            // Don't delete the the previous role, add Supervised BPI Analyst as a new one.
            for (Employee_Program_Enrollment__c epe : contact.Employee_Program_Enrollments__r) {
                System.assert(epe.Role__c.contains('Emergency Contact;Supervised BPI Analyst'));
                System.assert(epe.Program_Enrollment__r.RecordType.Name == 'AHU'
                        || epe.Program_Enrollment__r.RecordType.Name == 'HU');
            }
        }
    }

    static testMethod void testSelectCertifiedBPIAnalyst() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            // Search and assign building
            controller.dwellingSearchText = 'Test Dwelling Unit';
            controller.searchDwellingUnit();
            System.assertEquals(true, controller.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            controller.dwellingToAssignId = controller.getDwellingUnitsList().get(0).Id;
            controller.assignDwellingUnit();
            System.assert(controller.dwellingUnit != null);

            // Create BPI Analyst
            controller.BPI_IdCardFileName = 'test.pdf';
            controller.BPI_IdCardFileSize = 100000; // 1KB
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();
            System.assert(controller.selectedBPIAnalyst != null);

            // Save Pre-Application will success now
            controller.savePreApplication();
            System.assertNotEquals(controller.preApplication.Id, null);

            // Execute the init method with the new parameters
            ApexPages.currentPage().getParameters().put('action', 'edit');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            // Someone edits the employee program enrollments manually in Salesforce
            List<Employee_Program_Enrollment__c> employees = [
                SELECT Role__c FROM Employee_Program_Enrollment__c WHERE Contact__c =: controller.selectedBPIAnalyst
                ];
            for (Employee_Program_Enrollment__c epe : employees) {
                epe.Role__c = 'Emergency Contact';
            }
            update employees;

            // Refresh page and load the bpi analysts
            controller.init();
            controller.getAnalysts();

            controller.savePreApplication();

            Test.stopTest();

            System.assert(controller.selectedBPIAnalyst != null);
            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(2, controller.application.Application_Step__c);

            Contact c = [
                SELECT (SELECT Role__c, Program_Enrollment__r.RecordType.Name FROM Employee_Program_Enrollments__r),
                    (SELECT Credential_Type__c FROM Credentials__r)
               FROM Contact WHERE Id =: controller.selectedBPIAnalyst
               ];
            System.assertEquals(1, c.Credentials__r.size());
            System.assertEquals(2, c.Employee_Program_Enrollments__r.size());
            System.assertEquals('BPI Certification', c.Credentials__r.get(0).Credential_Type__c);
            for (Employee_Program_Enrollment__c epe : c.Employee_Program_Enrollments__r) {
                System.assert(epe.Role__c
                        .contains('Emergency Contact;BPI Certified Professional'));
                System.assert(epe.Program_Enrollment__r.RecordType.Name == 'AHU'
                        || epe.Program_Enrollment__r.RecordType.Name == 'HU');
            }
        }
    }

    static testMethod void testSaveBPIAnalystCertified() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller

            BIGPortalAdvancedHUAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // BPI certified
            controller.BPI_IdCardFileName = 'test.pdf';
            controller.BPI_IdCardFileSize = 100000; // 1KB
            createBpiAnalyst(controller);

            Test.startTest();
            controller.saveBpiAnalyst();

            Test.stopTest();

            Integer validRecords = 0;
            Integer invalidRecords = 0;
            for (Employee_Program_Enrollment__c epe :[
                    SELECT Role__c, Program_Enrollment__r.RecordType.Name
                    FROM Employee_Program_Enrollment__c]) {

                if ((epe.Program_Enrollment__r.RecordType.Name == 'HU'
                        || epe.Program_Enrollment__r.RecordType.Name == 'AHU')
                        && epe.Role__c != null
                        && epe.Role__c.contains('BPI Certified Professional')) {
                    validRecords++;
                } else {
                    invalidRecords++;
                }
            }

            // As bpi analyst should be the only one because the portal contact is has Homeowner as recordtype.
            List<Contact> contacts = [
                SELECT Id, (SELECT Credential_Type__c FROM Credentials__r)
                FROM Contact
                WHERE RecordTypeId =:
                    Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contractor').getRecordTypeId()];

            System.assertEquals(4, contacts.size());
            System.assertEquals(2, contacts.get(0).Credentials__r.size());
            System.assertEquals('BPI Certification', contacts.get(0).Credentials__r.get(1).Credential_Type__c);
            System.assertEquals(2, validRecords);
            System.assertEquals(0, invalidRecords);
        }
    }

    static testMethod void testGetAccreditedBpiAnalysts() {
        initData();
        Credential__c c = [
            SELECT Credential_Type__c
            FROM Credential__c
            WHERE Account__c =: portalAccount.Id limit 1
            ];
        c.Credential_Type__c = 'BPI Accreditation';
        update c;

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHUAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // BPI Accredited
            createBpiAnalyst(controller);
            controller.newBPIAnalyst.BPI_License_Number__c = null;
            controller.newBPIAnalyst.BPI_License_Expiration_Date__c = null;
            controller.isBpiCertified = false;
            controller.saveBpiAnalyst();

            Test.startTest();
            List<SelectOption> options = controller.getAnalysts();
            Test.stopTest();
            // Even though the portalConctact has bpi accreditation won't be in the list 'cause its rtype is Homeowner.
            // If no recordType is set when a new contact is added, it'll be Homeowner by default.
            System.assertEquals(4, options.size());
        }
    }

    static testMethod void testSaveBPIAnalystAccredited() {
        initData();

        Credential__c c = [
            SELECT Credential_Type__c
            FROM Credential__c
            WHERE Account__c =: portalAccount.Id limit 1
            ];

        c.Credential_Type__c = 'BPI Accreditation';
        update c;

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHUAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // BPI Accredited
            createBpiAnalyst(controller);
            controller.newBPIAnalyst.BPI_License_Number__c = null;
            controller.newBPIAnalyst.BPI_License_Expiration_Date__c = null;
            controller.isBpiCertified = false;

            Test.startTest();
            controller.saveBpiAnalyst();
            Test.stopTest();

            List<Credential__c> credentials = [SELECT Id FROM Credential__c WHERE Credential_Type__c = 'BPI Accreditation'];
            // The credentials list should contain only the credential associated to portal account.
            // When a bpi accredited is added, no credentials records are created.
            System.assertEquals(1, credentials.size());
            System.assertEquals(c.Id, credentials.get(0).Id);

            Integer validRecords = 0;
            Integer invalidRecords = 0;
            for (Employee_Program_Enrollment__c epe :[
                    SELECT Role__c, Program_Enrollment__r.RecordType.Name
                    FROM Employee_Program_Enrollment__c]) {

                if ((epe.Program_Enrollment__r.RecordType.Name == 'HU'
                        || epe.Program_Enrollment__r.RecordType.Name == 'AHU')
                        && epe.Role__c != null
                        && epe.Role__c.contains('Supervised BPI Analyst')) {
                    validRecords++;
                } else {
                    invalidRecords++;
                }
            }
            System.assertEquals(2, validRecords);
            System.assertEquals(0, invalidRecords);

        }
    }

    static testMethod void testPostAdvancedApplication() {
        initData();

        System.runAs(portalUser) {
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            helperInitDataForPostAdvanced(advancedHuPage, controller);
            // Get Project Financing options to check later
            Map<String, List<String>> projectFinancingOptions = controller.getProjectFinancingOptions();
            // Set the app with propane since the hpxml contains that energyType and we don't want to get that issue.
            controller.dwellingUnit.Utility_Accounts__r.get(0).Gas_Provider__c =
                    BIGPortalBuildingInformationUtils.PROPANE;
            controller.application.Gas_Provider__c = 'Propane';
            update controller.dwellingUnit.Utility_Accounts__r.get(0);
            update controller.application;
            // One workflow will copy this value to the Application__c.Test_In_Date__c after updating the sub app.
            controller.preApplication.Test_In_Date__c = Date.today() - 121;
            update controller.preApplication;

            Test.startTest();

            // <<<<<<<<<<<<<<<<< start TEST >>>>>>>>>>>>>>>>>>>>>>
            advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);

            // Simulate clicking on Edit button and does a page reload (Detail)
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            controller.init();
            // insert post application
            controller.postApplication.Application__c = controller.application.Id;

            System.assertEquals(true, controller.getPostAppTabEnabled());
            System.assertEquals(true, controller.getDisplayPostAppTab());
            System.assertEquals(true, controller.getDisplayPostAppNewSection());
            System.assertEquals(false, controller.getDisplayPreAppDetailSection());
            System.assertEquals(false, controller.getDisplayPostAppDetailSection());

            // Check rebate assignment and payment release is copied from pre-application to post-application
            System.assertEquals(controller.preApplication.Rebate_Assignment__c,
                    controller.postApplication.Rebate_Assignment__c);
            System.assertEquals(controller.postPaymentReleaseAuthorization.Name,
                    controller.paymentReleaseAuthorization.Name);

            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 5500;
            controller.setFormattedTestOutDate(Date.today());
            controller.formattedPostWorkStartDate = Date.today().format();
            controller.formattedPostWorkFinishDate = Date.today().format();
            controller.application.Has_Post_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'Yes';
            controller.application.Has_Conditioned_Area_Changed__c = 'No';
            controller.application.Project_Financing_Source__c = ApplicationUtils.SECURED_LOAN;
            controller.application.Project_Financing_Detail__c =
                    projectFinancingOptions.get('Secure Options').get(3);
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            List<String> fillers = new List<String>{'74628.96', '7195.9349077', '632.6325894',
                    '764.222735', '2004.6', '1031.6', '3800.392503', '579.5676239', '359.0218463', '163.50543',
                    '163.50543', '2450.9', '2350.1', '632.6325894', '764.222735', '2004.6', '1031.6', '3800.392503',
                    '570.5676239','350.0218463', '163.50543', '163.50543'};
            controller.postHomePerformanceXML = BIGPortalTestUtils.createAttachmentPostHPXML('postHpxml.xml', fillers);

            createHomeEnergyScoreData(controller, false);
            setHomeEnergyScoreAssessor(controller, false, controller.getHomeEnergyScoreContacts().get(0).getValue());

            // Set HPHI data.
            setHPHI(controller, controller.getHPHIPractitioners().get(0).getValue(), true);

            // Add Test Note and submit for review
            controller.appNotes = 'Test Note';
            // Post-App go next
            ApexPages.currentPage().getParameters().put('postHpxml', 'true');
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            controller.postAppNext();

            // Execute the init method with the new parameters set on postAppNext(). Reloads page.
            controller.init();

            System.assertEquals(ApplicationUtils.POST_INSTALL_CREATED_STATUS, controller.application.Status__c);

            controller.submitPostApplicationReview();

            Test.stopTest();

            /**
             * As we don't query the Total_Incentive_Adjustment__c, Test_In_Date__c and Test_Out_Date__c
             * through the action init we need to do it here in order to compare this value against its relative on
             * the sub application.
             */
            Application__c app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{controller.application.Id}).get(0);
            Sub_Application__c postApp = app.Sub_Applications__r.get(0);
            String expectedPractitioner = controller.getHPHIPractitioners().get(0).getValue();

            // There are 2 workflows to populate these fields, both on the Sub_Application: Test-In Date Updated
            // and Test Out Date Updated.
            // When we execute helperInitDataForPostAdvanced a sub (pre) application is created
            // so, these fields will be filled.
            System.assert(app.kW_Savings__c != null && app.kW_Savings__c != 0);
            System.assertEquals(app.kW_Savings__c, app.Sub_Applications__r.get(0).Demand_Savings_kW__c);
            System.assert(controller.postApplication.Total_Incentive_Adjustment__c != null);
            System.assertEquals(controller.postApplication.Total_Incentive_Adjustment__c,
                    app.Total_Incentive_Adjustment__c);
            System.AssertNotEquals(null, app.Test_In_Date__c);
            System.AssertNotEquals(null, app.Test_Out_Date__c);
            System.assertEquals('Yes', controller.application.Has_Post_Install_HES__c);
            // Validate HPHI Data.
            System.assertEquals('Yes', controller.application.Has_HPHI__c);
            System.assertEquals(expectedPractitioner, app.HPHI_Practitioner__c);
            System.assertEquals('Yes', postApp.Has_HPHI__c);
            System.assertEquals(expectedPractitioner, postApp.HPHI_Practitioner__c);
            System.assertEquals(1200, postApp.HPHI_Bonus__c);
            System.assertEquals(0.1, controller.application.Delivered_Sensible_EER__c);
            System.assert(String.isNotBlank(controller.postDeliveredSensibleEERScoresheet.Id));
            System.assertEquals(Date.today(), controller.application.Delivered_Sensible_EER_Assessment_Date__c);
            // Check Project Financing Option is the same as we entered before
            System.assertEquals(ApplicationUtils.SECURED_LOAN, app.Project_Financing_Source__c);
            System.assertEquals(projectFinancingOptions.get('Secure Options').get(3),
                    app.Project_Financing_Detail__c);
            System.AssertEquals(ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS, app.Status__c);
        }
    }

    static testMethod void testPostAdvancedApplication2() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();

            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            helperInitDataForPostAdvanced(advancedHuPage, controller);

            // <<<<<<<<<<<<<<<<< start TEST >>>>>>>>>>>>>>>>>>>>>>
            advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);

            // Simulate clicking on Edit button and does a page reload (Detail)
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            controller.init();
            // insert post application
            controller.postApplication.Application__c = controller.application.Id;

            System.assertEquals(true, controller.getPostAppTabEnabled());
            System.assertEquals(true, controller.getDisplayPostAppTab());
            System.assertEquals(true, controller.getDisplayPostAppNewSection());
            System.assertEquals(false, controller.getDisplayPreAppDetailSection());
            System.assertEquals(false, controller.getDisplayPostAppDetailSection());

            // Check rebate assignment and payment release is copied from pre-application to post-application
            System.assertEquals(controller.preApplication.Rebate_Assignment__c,
                    controller.postApplication.Rebate_Assignment__c);
            System.assertEquals(controller.postPaymentReleaseAuthorization.Name,
                    controller.paymentReleaseAuthorization.Name);

            // Click next on post-application without required fields (will fail)
            controller.postAppNext();
            System.assertEquals(ApplicationUtils.PRE_INSTALL_APPROVED_STATUS, controller.application.Status__c);

            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 5500;
            controller.setFormattedTestOutDate(Date.today());
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            controller.savePostApplication();
            // Execute the init method with the new parameters set on savePostApplication(). Reloads page.
            controller.init();
            Test.stopTest();
            System.assertEquals(ApplicationUtils.POST_INSTALL_CREATED_STATUS, controller.application.Status__c);
        }
    }

    static testMethod void testPostAdvancedApplication3() {
        initData();

        System.runAs(portalUser) {
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            // Get Project Financing options to check later
            Map<String, List<String>> projectFinancingOptions = controller.getProjectFinancingOptions();
            helperInitDataForPostAdvanced(advancedHuPage, controller);  // Test_In_Date__c = Date.today() - 1

            advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);

            // Simulate clicking on Edit button and does a page reload (Detail)
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            Test.startTest();
            controller.init();
            // insert post application
            controller.postApplication.Application__c = controller.application.Id;

            System.assertEquals(true, controller.getPostAppTabEnabled());
            System.assertEquals(true, controller.getDisplayPostAppTab());
            System.assertEquals(true, controller.getDisplayPostAppNewSection());
            System.assertEquals(false, controller.getDisplayPreAppDetailSection());
            System.assertEquals(false, controller.getDisplayPostAppDetailSection());

            // Check rebate assignment and payment release is copied from pre-application to post-application
            System.assertEquals(controller.preApplication.Rebate_Assignment__c,
                    controller.postApplication.Rebate_Assignment__c);
            System.assertEquals(controller.postPaymentReleaseAuthorization.Name,
                    controller.paymentReleaseAuthorization.Name);

            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 5500;
            controller.setFormattedTestOutDate(Date.today());
            controller.formattedPostWorkStartDate = Date.today().format();
            controller.formattedPostWorkFinishDate = Date.today().format();
            controller.application.Has_Post_Install_HES__c = 'Yes';
            controller.application.Has_Conditioned_Area_Changed__c = 'No';
            controller.application.Project_Financing_Source__c = ApplicationUtils.UNSECURED_LOAN;
            controller.application.Project_Financing_Detail__c =
                    projectFinancingOptions.get('Unsecure Options').get(0);
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            List<String> fillers = new List<String>{'5644.96', '191.9349077', '579.5676239', '459.0218463', '4624.96',
                    '191.9349077', '579.5676239', '359.0218463'};
            controller.postHomePerformanceXML = BIGPortalTestUtils.createAttachmentPostHPXML('postHpxml.xml', fillers);

            createHomeEnergyScoreData(controller, false);
            setHomeEnergyScoreAssessor(controller, false, controller.getHomeEnergyScoreContacts().get(0).getValue());

            // Add Test Note and submit for review
            controller.appNotes = 'Test Note';

            // Post-App go next
            ApexPages.currentPage().getParameters().put('postHpxml', 'true');
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            controller.postAppNext();

            // Execute the init method with the new parameters set on postAppNext(). Reloads page.
            controller.init();
            controller.submitPostApplicationReview();

            Test.stopTest();

            ApexPages.currentPage().getParameters().put('action', 'confirmPost');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            // Clear this parameter. For some reason it's being kept from previous page references
            ApexPages.currentPage().getParameters().put('postHpxml', '');
            controller.init();

            // Get application with latest changes
            Application__c application =
                    BIGPortalTestUtils.getApplicationsById(new Set<Id>{controller.application.Id}).get(0);
            // Check Project Financing Option is the same as we entered before
            System.assertEquals(ApplicationUtils.UNSECURED_LOAN, application.Project_Financing_Source__c);
            System.assertEquals(projectFinancingOptions.get('Unsecure Options').get(0),
                    application.Project_Financing_Detail__c);
            System.assertEquals(ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS, application.Status__c);
            System.assertEquals('Test Note', controller.getPostApplicationNotes().get(0).Note__c);
        }
    }

    static testMethod void testPostAdvancedAppInvalidXmlVersion() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();

            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();

            // <<<<<<<<<<<<<<<<< start TEST >>>>>>>>>>>>>>>>>>>>>>
            clickOnEditButton(advancedHuPage, controller);

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 5500;
            controller.setFormattedTestOutDate(Date.today());
            controller.formattedPostWorkStartDate = Date.today().format();
            controller.formattedPostWorkFinishDate = Date.today().format();
            controller.application.Has_Post_Install_HES__c = 'Yes';
            controller.application.Has_Conditioned_Area_Changed__c = 'No';
            controller.application.Has_HPHI__c = 'No';
            // Populate Post-Application attachments
            // The Software_Version__c custom setting determines the minimum and maximum version of the xml
            createPostAppAttachments(controller, '7.0');

            controller.savePostApplication();
            // Execute the init method with the new parameters set on savePostApplication(). Reloads page.
            controller.init();

            createHomeEnergyScoreData(controller, false);
            setHomeEnergyScoreAssessor(controller, false, controller.getHomeEnergyScoreContacts().get(0).getValue());

            // Post-App go next
            controller.postAppNext();

            // Execute the init method with the new parameters set on postAppNext(). Reloads page.
            controller.init();
            System.assertEquals('edit', ApexPages.currentPage().getParameters().get('action'));
            System.assertEquals(ApplicationUtils.POST_INSTALL_CREATED_STATUS, controller.application.Status__c);

            Test.stopTest();
        }
    }

    static testMethod void testPostAdvancedAppNext() {
        initData();

        System.runAs(portalUser) {
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            // Get Project Financing options to check later
            Map<String, List<String>> projectFinancingOptions = controller.getProjectFinancingOptions();
            clickOnEditButton(advancedHuPage, controller);

            // Save Post-Application
            controller.savePostApplication();
            System.assertEquals(ApplicationUtils.POST_INSTALL_CREATED_STATUS, controller.application.Status__c);
            controller.init();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 6000;
            controller.setFormattedTestOutDate(Date.today());
            controller.formattedPostWorkStartDate = Date.today().format();
            controller.formattedPostWorkFinishDate = Date.today().format();
            controller.application.Has_Post_Install_HES__c = 'Yes';
            controller.application.Has_Conditioned_Area_Changed__c = 'No';
            controller.application.Has_HPHI__c = 'No';
            controller.application.Project_Financing_Source__c = projectFinancingOptions.get('General Options').get(6);
            controller.application.Project_Financing_Description__c = 'Description Test';
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            createHomeEnergyScoreData(controller, false);
            setHomeEnergyScoreAssessor(controller, false, controller.getHomeEnergyScoreContacts().get(0).getValue());

            // Post-App go next (Click on Next without pressing on Save before)
            controller.postAppNext();

            Test.startTest();

            // Execute the init method with the new parameters set on postAppNext(). Reloads page.
            ApexPages.currentPage().getParameters().put('postHpxml', 'true');
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            controller.init();
            Test.stopTest();

            // Get application with latest changes
            Application__c application =
                    BIGPortalTestUtils.getApplicationsById(new Set<Id>{controller.application.Id}).get(0);
            System.assertEquals(ApplicationUtils.POST_INSTALL_CREATED_STATUS, application.Status__c);
            System.assertEquals(5, application.Application_Step__c);
            System.assertEquals(projectFinancingOptions.get('General Options').get(6),
                    application.Project_Financing_Source__c);
            System.assertEquals('Description Test', application.Project_Financing_Description__c);
        }
    }

    static testMethod void testPostAdvancedInvalidExtensions() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();

            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            clickOnEditButton(advancedHuPage, controller);

            // Save Post-Application
            controller.savePostApplication();
            System.assertEquals(ApplicationUtils.POST_INSTALL_CREATED_STATUS, controller.application.Status__c);
            controller.init();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 5500;
            controller.setFormattedTestOutDate(Date.today());
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            // Post-App go next (Click on Next without pressing on Save before)
            controller.postAppNext();

            Test.stopTest();
            // It'll fail because of the attachment's extensions
            System.assertEquals(ApplicationUtils.POST_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(4, controller.application.Application_Step__c);
        }
    }

    static testMethod void testPreAppNextEnergyProXML() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            searchBuildingAndRequiredFields(controller);
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'No';

            // Populate Pre-Application attachments
            createPreAppAttachments(controller, null);

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.preAppNext();
            // If the page with this paremeters, simulate the step 2 in the pre-application.
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'true');

            // Execute the init method with the new parameters
            controller.init();

            Test.stopTest();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(3, controller.application.Application_Step__c);
        }
    }

    static testMethod void testPreAppNextInvalidXmlVersion() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // Search and assign building
            searchBuildingAndRequiredFields(controller);
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'No';

            // Populate Pre-Application attachments
            createPreAppAttachments(controller, '7.0');

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.preAppNext();

            // If the page with this paremeters, simulate the step 2 in the pre-application.
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'true');

            // Execute the init method with the new parameters
            controller.init();

            Test.stopTest();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(2, controller.application.Application_Step__c);
            System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
        }
    }

    static testMethod void testSaveCredentialFile() {
        initData();
        System.runAs(portalUser) {
            BIGPortalAdvancedHUAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();
            controller.BPI_IdCardFileName = 'test.pdf';
            controller.BPI_IdCardFileSize = 100000; // 1KB
            String bpiIdCard1 = null;
            String bpiIdCard2 = null;
            createBpiAnalyst(controller);

            Test.startTest();
            controller.saveBpiAnalyst();
            bpiIdCard1 = controller.BPI_IdCard;
            System.assert(bpiIdCard1 != null);
            // For now we don't edit the bpi analyst anymore for ahu. So, Creating a new one is needed.
            createBpiAnalyst(controller);
            // Duplicate bpi analysts can't be saved, so... change the name of the new bpi
            controller.newBPIAnalyst.FirstName = 'test bpi';
            controller.saveBpiAnalyst();
            bpiIdCard2 = controller.BPI_IdCard;
            Test.stopTest();

            System.assert(bpiIdCard2 != null);
            System.assert(bpiIdCard1 != bpiIdCard2);
        }
    }

    static testMethod void testGetPreApplicationNotes() {
        initData();
        System.runAs(portalUser) {
            BIGPortalAdvancedHUAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();
            insert controller.application;
            controller.preApplication.Application__c = controller.application.Id;
            insert controller.preApplication;

            Application_Note__c appNote = BIGPortalTestUtils.createApplicationNote(controller.application.Id,
                    'testNote', true, false);
            insert appNote;
            appNote.Sub_Application__c = controller.preApplication.Id;
            update appNote;
            Test.startTest();
            List<Application_Note__c> listAppNotes = controller.getPreApplicationNotes();
            Test.stopTest();
            System.assertEquals(1, listAppNotes.size());

        }
    }

    /*
     * Check error when enter a WorkStartDate before Test-InDate
     */
    static testMethod void testWorkStartDateError(){
        initData();

        System.runAs(portalUser) {
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            helperInitDataForPostAdvanced(advancedHuPage, controller);

            advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);

            // Simulate clicking on Edit button and does a page reload (Detail)
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            controller.init();
            // insert post application
            controller.postApplication.Application__c = controller.application.Id;

            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 5500;
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            // Set WorkStartDate before Test-InDate previously set on helperInitDataForPostAdvanced
            controller.formattedPostWorkStartDate = (Date.today() - 4).format();
            controller.formattedPostWorkFinishDate = Date.today().format();
            controller.setFormattedTestOutDate(Date.today());

            Test.startTest();
            // Post-App go next
            controller.postAppNext();
            Test.stopTest();

            controller.init();

            // Check there isn't any data populated because SubbApplication wasn't created for the WorkStartDate issue
            System.assertNotEquals(null, controller.application.Work_Start_Date__c);
            System.assertNotEquals(null, controller.application.Work_Finish_Date__c);
            System.assertEquals(null, controller.postApplication.Id);
        }
    }

    /*
     * Check error when enter a WorkFinishDate before WorkStartDate
     */
    static testMethod void testWorkFinishDateError(){
        initData();

        System.runAs(portalUser) {
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            helperInitDataForPostAdvanced(advancedHuPage, controller);
            // One workflow will copy this value to the Application__c.Test_In_Date__c after updating the sub app.
            controller.preApplication.Test_In_Date__c = Date.today() - 121;
            update controller.preApplication;

            advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);

            // Simulate clicking on Edit button and does a page reload (Detail)
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            controller.init();
            // insert post application
            controller.postApplication.Application__c = controller.application.Id;

            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 5500;
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            // Set WorkFinishDate before WorkStartDate
            controller.formattedPostWorkStartDate = Date.today().format();
            controller.formattedPostWorkFinishDate = Date.today().format();
            controller.setFormattedTestOutDate(Date.today() - 4);

            Test.startTest();
            // Post-App go next
            controller.postAppNext();
            Test.stopTest();

            controller.init();

            // Check there isn't any data populated because SubbApplication wasn't created for the WorkFinishDate issue
            System.assertNotEquals(null, controller.application.Work_Start_Date__c);
            System.assertNotEquals(null, controller.application.Work_Finish_Date__c);
            System.assertEquals(null, controller.postApplication.Id);
        }
    }

    /*
     * Check error when enter a Test-OutDate before WorkFinishDate
     */
    static testMethod void testTestOutDateError(){
        initData();

        System.runAs(portalUser) {
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            helperInitDataForPostAdvanced(advancedHuPage, controller);
            // One workflow will copy this value to the Application__c.Test_In_Date__c after updating the sub app.
            controller.preApplication.Test_In_Date__c = Date.today() - 121;
            update controller.preApplication;

            advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);

            // Simulate clicking on Edit button and does a page reload (Detail)
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            controller.init();
            // insert post application
            controller.postApplication.Application__c = controller.application.Id;

            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 5500;
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            // Set Test-OutDate before WorkFinishDate
            controller.formattedPostWorkStartDate = Date.today().format();
            controller.formattedPostWorkFinishDate = Date.today().format();
            controller.setFormattedTestOutDate(Date.today() - 2);

            Test.startTest();
            // Post-App go next
            controller.postAppNext();
            Test.stopTest();

            controller.init();
            // Should have the dates from the preApplication
            System.assertNotEquals(null, controller.application.Work_Start_Date__c);
            System.assertNotEquals(null, controller.application.Work_Finish_Date__c);
            // Check there isn't any data populated because SubbApplication wasn't created for the Test-OutDate issue
            System.assertEquals(null, controller.postApplication.Id);
        }
    }

    /*
     * Check when try to add a BPIAnalyst with same first name and last name than other, it won't be saved
     */
    static testMethod void testDuplicatedBPINotSaved() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // It creates a BPI with 'firstN' and 'lastN' as firstName and lastName
            saveBpiAnalyst(controller);
            // Verify there is only one BPI Analyst created
            System.assertEquals(2, controller.getAnalysts().size());

            // Try to create a duplicated BPI Analyst and assigned to BPI on controller
            controller.newBPIAnalyst = BIGPortalTestUtils.createBPIAnalyst('firstN', 'lastN', 'test@test.com',
                    '(234) 234-3243', '1234567', Date.today(), portalAccount);

            test.startTest();
            controller.saveBPIAnalyst();
            test.stopTest();

            // Check there is still only one BPI created
            System.assertEquals(2, controller.getAnalysts().size());
        }
    }

    /*
     * Check when try to add a BPIAnalyst with different first name and last name than other, it will be saved
     */
    static testMethod void testNotDuplicatedBPISave() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // It creates a BPI with 'firstN' and 'lastN' as firstName and lastName and save it
            saveBpiAnalyst(controller);
            // Verify there is only one BPI Analyst created
            System.assertEquals(2, controller.getAnalysts().size());

            // Create a BPI Analyst with different firstName and lastName and assigned to BPI on controller
            controller.newBPIAnalyst = BIGPortalTestUtils.createBPIAnalyst('changed', 'changed', 'test@test.com',
                    '(234) 234-3243', '1234567', Date.today(), portalAccount);

            test.startTest();
            controller.saveBPIAnalyst();
            test.stopTest();

            // Check there are 2 BPI created
            System.assertEquals(3, controller.getAnalysts().size());
        }
    }

    static testMethod void testPreAHUAppNaturalGasEnergyTypeError() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            Test.startTest();
            // Search and assign building
            controller.dwellingSearchText = 'Test Dwelling Unit';
            controller.searchDwellingUnit();
            List<Dwelling_Unit__c> dwellingUnits = controller.getDwellingUnitsList();
            System.assert(dwellingUnits.size() > 0);
            // Set Gas Provider to get a hpxml error related to that.
            dwellingUnits.get(0).Utility_Accounts__r.get(0).Gas_Provider__c = 'Propane';
            update dwellingUnits.get(0).Utility_Accounts__r.get(0);
            controller.dwellingToAssignId = dwellingUnits.get(0).Id;
            // Set dwelling unit as we would on the modal search.
            controller.assignDwellingUnit();
            System.assert(controller.dwellingUnit != null);

            List<String> fillers = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};

            // Complete required fields for pre application
            controller.preApplication.Proposed_Package_Cost__c = 4000;
            controller.preApplication.Total_Incentive__c = 2000;
            controller.setFormattedTestInDate(Date.today());
            controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(1).getValue();
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'No';
            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Create attachments
            createPreAppAttachments(controller, null);
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testFile.xml', fillers);

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.preAppNext();
            // If the page with this paremeters, simulate the step 2 in the pre-application.
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'true');

            // Execute the init method with the new parameters
            controller.init();
            Test.stopTest();
            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(2, controller.application.Application_Step__c);
            System.assert(BIGPortalTestUtils.searchErrorMessage(ApexPages.getMessages(),
                    HPXMLParser.GAS_ENERGY_TYPE_ERROR));

        }
    }

    static testMethod void testPreAHUAppPropaneEnergyTypeError() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            Test.startTest();
            // Search and assign building
            controller.dwellingSearchText = 'Test Dwelling Unit';
            controller.searchDwellingUnit();
            List<Dwelling_Unit__c> dwellingUnits = controller.getDwellingUnitsList();
            System.assert(dwellingUnits.size() > 0);
            // Set dwelling unit as we would on the modal search.
            controller.dwellingToAssignId = dwellingUnits.get(0).Id;
            controller.assignDwellingUnit();
            System.assert(controller.dwellingUnit != null);

            List<String> fillers = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};

            // Complete required fields for pre application
            controller.preApplication.Proposed_Package_Cost__c = 4000;
            controller.preApplication.Total_Incentive__c = 2000;
            controller.setFormattedTestInDate(Date.today());
            controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(1).getValue();
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'No';
            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();

            // Create attachments
            createPreAppAttachments(controller, null);
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXMLEnergyTypePropane(
                    'testFile.xml', fillers);

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.preAppNext();
            // If the page with this paremeters, simulate the step 2 in the pre-application.
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'true');

            // Execute the init method with the new parameters
            controller.init();
            Test.stopTest();
            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(2, controller.application.Application_Step__c);
            System.assert(BIGPortalTestUtils.searchErrorMessage(ApexPages.getMessages(),
                    HPXMLParser.GAS_ENERGY_TYPE_ERROR));
        }
    }

    /**
     * Test Program Acces behavior when you don't have access to AHU program.
     */
    static testMethod void testNotAHUPortalProgramAccess() {
        initData();
        portalContact.Program_Enrollment__c = 'HU; ACQC';
        update portalContact;

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            Test.setCurrentPage(Page.BIGPortalAdvancedHUApplication);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();

            Test.startTest();
            PageReference accessDenied = controller.init();
            Test.stopTest();

            System.assertEquals(Page.AccessDenied.getUrl(), accessDenied.getUrl());
        }
    }

    /**
     * Portal user should not be able to submit a new application when AHU program is suspended.
     */
    static testMethod void testAHUSuspendedOnSubmit() {
        initData();

        List<Program_Enrollment__c> programsEnrollment = [
            SELECT Enrollment_Status__c
            FROM Program_Enrollment__c
            WHERE Account__c =: portalAccount.id
                AND (RecordType.Name = 'AHU' OR RecordType.Name = 'HU')
            LIMIT 2];

        programsEnrollment.get(0).Enrollment_Status__c = ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS;
        programsEnrollment.get(1).Enrollment_Status__c = ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS;

        update programsEnrollment;

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            Test.setCurrentPage(Page.BIGPortalAdvancedHUApplication);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // Search and assign building
            controller.dwellingSearchText = 'Test Dwelling Unit';
            controller.searchDwellingUnit();
            List<Dwelling_Unit__c> dwellingUnits = controller.getDwellingUnitsList();
            System.assert(dwellingUnits.size() > 0);
            // Set dwelling unit as we would on the modal search.
            controller.dwellingToAssignId = dwellingUnits.get(0).Id;
            controller.assignDwellingUnit();
            System.assert(controller.dwellingUnit != null);

            // Complete required fields for pre application
            controller.preApplication.Proposed_Package_Cost__c = 4000;
            controller.preApplication.Total_Incentive__c = 2000;
            controller.setFormattedTestInDate(Date.today());
            controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(2).getValue();
            controller.application.Rebate_Assignment__c = controller.getRebateTypes().get(2).getValue();
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();
            // Create attachments
            createPreAppAttachments(controller, null);
            List<String> fillers = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testFile.xml', fillers);

            Test.startTest();
            // Click on Next
            controller.preAppNext();
            Test.stopTest();

            System.assertEquals(null, controller.preApplication.Id);
            System.assertEquals(
                    BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR,
                    ApexPages.getMessages().get(0).getSummary());
        }
    }

    /**
     * Portal user should not be able to submit an application already created when AHU program is suspended
     * and Rebate Assignment is a Contractor.
     */
    static testMethod void testAHUSuspendedOnSubmitAsContractor() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            Test.setCurrentPage(Page.BIGPortalAdvancedHUApplication);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // Search and assign building
            controller.dwellingSearchText = 'Test Dwelling Unit';
            controller.searchDwellingUnit();
            List<Dwelling_Unit__c> dwellingUnits = controller.getDwellingUnitsList();
            System.assert(dwellingUnits.size() > 0);
            // Set dwelling unit as we would on the modal search.
            controller.dwellingToAssignId = dwellingUnits.get(0).Id;
            controller.assignDwellingUnit();
            System.assert(controller.dwellingUnit != null);

            // Complete required fields for pre application
            controller.preApplication.Proposed_Package_Cost__c = 4000;
            controller.preApplication.Total_Incentive__c = 2000;
            controller.setFormattedTestInDate(Date.today());
            controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(2).getValue();
            controller.application.Rebate_Assignment__c = controller.getRebateTypes().get(2).getValue();
            controller.application.Has_Pre_Install_HES__c = 'Yes';

            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();
            // Create attachments
            createPreAppAttachments(controller, null);
            List<String> fillers = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testFile.xml', fillers);

            // Save Pre-Application will success now
            controller.savePreApplication();
            System.assert(controller.preApplication.Id != null);

            List<Program_Enrollment__c> programsEnrollment = [
                SELECT Enrollment_Status__c
                FROM Program_Enrollment__c
                WHERE Account__c =: portalAccount.id
                LIMIT 2];

            programsEnrollment.get(0).Enrollment_Status__c = ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS;
            programsEnrollment.get(1).Enrollment_Status__c = ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS;

            update programsEnrollment;

            // If the page with this paremeters, simulate the step 2 in the pre-application.
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'Edit');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'false');
            controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            Test.startTest();
            // Click on Next
            controller.preAppNext();
            Test.stopTest();

            System.assertEquals(
                    BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR,
                    ApexPages.getMessages().get(1).getSummary());
        }
    }

    /**
     * Portal user should be able to submit an application already created when AHU program is suspended
     * and Rebate Assignment is Account Holder.
     */
    static testMethod void testAHUSuspendedOnSubmitAsAccountHolder() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            Test.setCurrentPage(Page.BIGPortalAdvancedHUApplication);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            // Search and assign building
            controller.dwellingSearchText = 'Test Dwelling Unit';
            controller.searchDwellingUnit();
            List<Dwelling_Unit__c> dwellingUnits = controller.getDwellingUnitsList();
            System.assert(dwellingUnits.size() > 0);
            // Set dwelling unit as we would on the modal search.
            controller.dwellingToAssignId = dwellingUnits.get(0).Id;
            controller.assignDwellingUnit();
            System.assert(controller.dwellingUnit != null);

            // Complete required fields for pre application
            controller.preApplication.Proposed_Package_Cost__c = 4000;
            controller.preApplication.Total_Incentive__c = 2000;
            controller.setFormattedTestInDate(Date.today());
            controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(0).getValue();
            controller.application.Rebate_Assignment__c = controller.getRebateTypes().get(0).getValue();
            controller.application.Has_Pre_Install_HES__c = 'Yes';

            // Create BPI Analyst
            createBpiAnalyst(controller);
            controller.saveBPIAnalyst();
            // Create attachments
            createPreAppAttachments(controller, null);
            List<String> fillers = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testFile.xml', fillers);

            // Save Pre-Application will success now
            controller.savePreApplication();
            System.assert(controller.preApplication.Id != null);

            List<Program_Enrollment__c> programsEnrollment = [
                SELECT Enrollment_Status__c
                FROM Program_Enrollment__c
                WHERE Account__c =: portalAccount.id
                    AND (RecordType.Name = 'AHU' OR RecordType.Name = 'HU')
                LIMIT 2];

            programsEnrollment.get(0).Enrollment_Status__c = ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS;
            programsEnrollment.get(1).Enrollment_Status__c = ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS;

            update programsEnrollment;

            // If the page with this paremeters, simulate the step 2 in the pre-application.
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'Edit');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);
            ApexPages.currentPage().getParameters().put('executeNext', 'false');
            controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            Test.startTest();
            // Click on Next
            controller.preAppNext();
            Test.stopTest();

            System.assertEquals(
                    BIGPortalAdvanceHUApplicationUtils.PRE_SAVE_MESSAGE,
                    ApexPages.getMessages().get(0).getSummary());
        }
    }

    static testMethod void testSavePreAdvancedApplicationWithoutHomeEnergyScore() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHUAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();
            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            searchBuildingAndRequiredFields(controller);

            // Create attachments
            createPreAppAttachments(controller, null);
            // Fill place holder where there are curly brackets
            List<String> fillers = new List<String>{'4624.96', '191.9349077', '579.5676239',
                    '379.0218463', '420.96', '17.9349077', '57.5639', '35.0218463'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testHpxml.xml', fillers);

            Test.startTest();
            // If we fill the Home Energy Score fields on the front end and then we hide the HES section
            // the server is going to skip that data when we save the application.
            controller.application.Has_Pre_Install_HES__c = 'No';
            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.savePreApplication();

            // Simulates when user clicks Edit in the portal.
            ApexPages.currentPage().getParameters().put('action', 'edit');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            // Execute the init method with the new parameters
            controller.init();
            Test.stopTest();

            // Assert Home Energy Score fields.
            System.assert(String.isBlank(controller.application.Pre_Home_Energy_Score__c));
            System.assert(controller.application.Pre_HES_Assessment_Date__c == null);
            System.assert(String.isBlank(controller.application.Pre_HES_Assessor__c));

            // Assert Home Energy Score attachments.
            System.assert(String.isBlank(controller.homeEnergyScoreReportInputFile.Id));
            System.assert(String.isBlank(controller.greenBuildingRegistryOptIn.Id));
            System.assert(String.isBlank(controller.homeEnergyScoreAdditionalDocuments.Id));
        }
    }

    static testMethod void testSavePreAdvancedApplicationRemovingHomeEnergyScore() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHUAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();
            System.assert(controller.application != null);
            System.assert(controller.preApplication != null);
            System.assertEquals(controller.getDisplayPreAppNew(), true);
            System.assertEquals(controller.getDisplayPreAppDetailSection(), false);

            searchBuildingAndRequiredFields(controller);

            // Create attachments
            createPreAppAttachments(controller, null);
            // Fill place holder where there are curly brackets
            List<String> fillers = new List<String>{'4624.96', '191.9349077', '579.5676239',
                    '379.0218463', '420.96', '17.9349077', '57.5639', '35.0218463'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testHpxml.xml', fillers);

            controller.application.Has_Pre_Install_HES__c = 'Yes';
            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());

            controller.savePreApplication();

            // Simulates when user clicks Edit in the portal.
            ApexPages.currentPage().getParameters().put('action', 'edit');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            // Execute the init method with the new parameters
            controller.init();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(2, controller.application.Application_Step__c);

            // Assert Home Energy Score fields.
            System.assertEquals('1', controller.application.Pre_Home_Energy_Score__c);
            System.assertEquals(Date.today(), controller.application.Pre_HES_Assessment_Date__c);
            System.assert(String.isNotBlank(controller.application.Pre_HES_Assessor__c));

            // Assert Home Energy Score attachments.
            System.assert(String.isNotBlank(controller.homeEnergyScoreReportInputFile.Id));
            System.assert(String.isNotBlank(controller.greenBuildingRegistryOptIn.Id));
            System.assert(String.isNotBlank(controller.homeEnergyScoreAdditionalDocuments.Id));

            Test.startTest();
            controller.application.Has_Pre_Install_HES__c = 'No';
            controller.savePreApplication();
            // Execute the init method with the new parameters
            controller.init();
            Test.stopTest();

            // Assert Home Energy Score fields.
            System.assert(String.isBlank(controller.application.Pre_Home_Energy_Score__c));
            System.assert(controller.application.Pre_HES_Assessment_Date__c == null);
            System.assert(String.isBlank(controller.application.Pre_HES_Assessor__c));

            // Assert Home Energy Score attachments.
            System.assert(String.isBlank(controller.homeEnergyScoreReportInputFile.Id));
            System.assert(String.isBlank(controller.greenBuildingRegistryOptIn.Id));
            System.assert(String.isBlank(controller.homeEnergyScoreAdditionalDocuments.Id));
        }
    }

    /**
     * Verifies that if an application (on pre phase) has been saved with a selected HPHI Practitioner,
     * if the user decides to save it again by selecting 'No' for the Has_HPHI__c field,
     * then the value for the HPHI Practitioner is set back to null.
     */
    static testMethod void testSavePreAdvancedApplicationRemovingHPHI() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHUAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            searchBuildingAndRequiredFields(controller);

            // Create attachments
            createPreAppAttachments(controller, null);
            // Fill place holder where there are curly brackets
            List<String> fillers = new List<String>{'4624.96', '191.9349077', '579.5676239',
                    '379.0218463', '420.96', '17.9349077', '57.5639', '35.0218463'};
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testHpxml.xml', fillers);

            controller.application.Has_HPHI__c = 'Yes';
            // Set HPHI.
            setHPHI(controller, controller.getHPHIPractitioners().get(0).getValue(), false);

            controller.savePreApplication();

            // Simulates when user clicks Edit in the portal.
            ApexPages.currentPage().getParameters().put('action', 'edit');
            ApexPages.currentPage().getParameters().put('id', controller.application.Id);

            // Execute the init method with the new parameters
            controller.init();

            System.assertEquals(ApplicationUtils.PRE_INSTALL_CREATED_STATUS, controller.application.Status__c);
            System.assertEquals(2, controller.application.Application_Step__c);

            // Assert pre HPHI practitioner fields.
            System.assertEquals('Yes', controller.application.Has_HPHI__c);
            System.assert(String.isNotBlank(controller.application.HPHI_Practitioner__c));

            Test.startTest();
            controller.application.Has_HPHI__c = 'No';
            controller.savePreApplication();
            Test.stopTest();
            // Assert HPHI practitioner fields.
            Application__c app = BIGPortalTestUtils.getApplicationsById(new Set<Id>{controller.application.Id}).get(0);
            Sub_Application__c preApp = app.Sub_Applications__r.get(0);
            System.assertEquals('No', controller.application.Has_HPHI__c);
            System.assert(String.isBlank(controller.application.HPHI_Practitioner__c));
            System.assertEquals('No', preApp.Has_HPHI__c);
            System.assert(String.isBlank(preApp.HPHI_Practitioner__c));
            System.assertEquals(null, preApp.HPHI_Bonus__c);
        }
    }

    /**
     * Verifies that if the user clicks next on an application (on pre phase) that has set the Has_HPHI__c field
     * to 'Yes', but not the HPHI Practitioner then the app won't proceed to the submission phase.
     */
    static testMethod void testPreAppNextWithHPHIWithoutSuppliedData() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalAdvanceHUApplication.page to current test
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(advancedHuPage);
            // Set parameters to page
            ApexPages.currentPage().getParameters().put('action', 'new');
            // Instantiate page Controller
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            controller.init();

            searchBuildingAndRequiredFields(controller);

            // Save Pre-Application will success now
            controller.savePreApplication();
            System.assertNotEquals(null, controller.preApplication.Id);

            // Complete required fields for pre application
            controller.preApplication.Proposed_Package_Cost__c = 4000;
            controller.preApplication.Total_Incentive__c = 2000;
            controller.setFormattedTestInDate(Date.today());
            controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(1).getValue();
            controller.application.Has_Pre_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'Yes';

            // Create attachments
            List<String> fillers = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};
            createPreAppAttachments(controller, null);
            controller.homePerformanceXML = BIGPortalTestUtils.createAttachmentPreHPXML('testFile.xml', fillers);

            createHomeEnergyScoreData(controller, true);
            setHomeEnergyScoreAssessor(controller, true, controller.getHomeEnergyScoreContacts().get(0).getValue());
            Test.startTest();
            // Go next without completing Pre App required fields (will receive error)
            controller.preAppNext();
            Test.stopTest();

            System.assertEquals(true, ApexPages.hasMessages());
            Boolean hasHPHIRequiredErrorMessage = false;
            for (Apexpages.Message msg : ApexPages.getMessages()) {

                if (msg.getDetail().contains('HPHI Practitioner is required.')) {
                    hasHPHIRequiredErrorMessage = true;
                    break;
                }
            }
            // Verify that an error message is displayed when Has_HPHI__c is 'Yes',
            // but no HPHI Practitioner has been selected.
            System.assert(hasHPHIRequiredErrorMessage);
        }
    }

    /**
     * Verifies that if the user clicks next on an application (on post phase) that has set the Has_HPHI__c field
     * to 'Yes', but not the HPHI Practitioner then the app won't proceed to the submission phase.
     */
    static testMethod void testPostAppNextWithHPHIWithoutSuppliedData() {
        initData();

        System.runAs(portalUser) {
            PageReference advancedHuPage = Page.BIGPortalAdvancedHUApplication;
            BIGPortalAdvancedHuAppController controller = new BIGPortalAdvancedHUAppController();
            // Get Project Financing options to check later
            Map<String, List<String>> projectFinancingOptions = controller.getProjectFinancingOptions();
            clickOnEditButton(advancedHuPage, controller);

            // Save Post-Application
            controller.savePostApplication();
            System.assertEquals(ApplicationUtils.POST_INSTALL_CREATED_STATUS, controller.application.Status__c);
            controller.init();

            // Complete Post-Application required fields
            controller.postApplication.Completed_Package_Cost__c = 6000;
            controller.setFormattedTestOutDate(Date.today());
            controller.formattedPostWorkStartDate = Date.today().format();
            controller.formattedPostWorkFinishDate = Date.today().format();
            controller.application.Has_Post_Install_HES__c = 'Yes';
            controller.application.Has_HPHI__c = 'Yes';
            controller.application.Has_Conditioned_Area_Changed__c = 'No';
            controller.application.Project_Financing_Source__c = projectFinancingOptions.get('General Options').get(6);
            controller.application.Project_Financing_Description__c = 'Description Test';
            // Populate Post-Application attachments
            createPostAppAttachments(controller, null);

            createHomeEnergyScoreData(controller, false);
            setHomeEnergyScoreAssessor(controller, false, controller.getHomeEnergyScoreContacts().get(0).getValue());

            Test.startTest();
            // Post-App go next (Click on Next without pressing on Save before)
            controller.postAppNext();
            Test.stopTest();

            Boolean hasHPHIRequiredErrorMessage = false;
            for (Apexpages.Message msg : ApexPages.getMessages()) {

                if (msg.getDetail().contains('HPHI Practitioner is required.')) {
                    hasHPHIRequiredErrorMessage = true;
                    break;
                }
            }
            // Verify that an error message is displayed when Has_HPHI__c is 'Yes',
            // but no HPHI Practitioner has been selected.
            System.assert(hasHPHIRequiredErrorMessage);
        }
    }

    private static void initData() {
        // Create Account
        portalAccount = BIGPortalTestUtils.createAccount('portalAccount');
        insert portalAccount;
        System.assertNotEquals(null, portalAccount.Id);

        // Create Contact
        portalContact = BIGPortalTestUtils.createContact('portalContact' , 'portalContact',
                'portalContact@test.com', '703-555-5555', portalAccount.Id);
        insert portalContact;
        System.assertNotEquals(null, portalContact.Id);

        // Create a new AHU and HU Program Enrollment in Full Participation status.
        insert BIGPortalTestUtils.createProgramEnrollment(portalAccount.Id,
                Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName()
                .get('AHU').getRecordTypeId(), 'Full Participation');
        insert BIGPortalTestUtils.createProgramEnrollment(portalAccount.Id,
                Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName()
                .get('HU').getRecordTypeId(), 'Full Participation');

        Credential__c bpiCredential = BIGPortalTestUtils.createCredential(portalAccount, portalContact);
        bpiCredential.Credential_Type__c = 'BPI Certification';
        insert bpiCredential;

        Credential__c hesCredential = BIGPortalTestUtils.createCredential(portalAccount, portalContact);
        hesCredential.Credential_Type__c = 'Home Energy Score Assessor';
        insert hesCredential;

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = portalContact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);

        // Create Building
        Building__c building = BIGPortalTestUtils.createBuilding('Joe Doe Building', 'Single Family Detached',
                'Building Street Address', 'Building City', 'CA', '22180', 'Building County',
                portalAccount.Id);

        insert building;
        System.assertNotEquals(null, building.Id);

        // Create Contact as Property Owner
        Contact propertyOwner = BIGPortalTestUtils.createContact('Property Owner', 'Property Owner',
                'propertyOwner@test.com', '703-222-2222', 'Street Avenue', 'Palo Alto', 'CA', '12345',
                portalAccount.Id);
        insert propertyOwner;
        System.assertNotEquals(null, propertyOwner.Id);

        // Create Dwelling Unit
        dwellingUnit = BIGPortalTestUtils.createDwellingUnit('DW Street Address', '10', propertyOwner.Id, building.Id,
                Decimal.valueOf(3), Decimal.valueOf(6), Decimal.valueOf(2), Decimal.valueOf(800),
                '1983', 'Vented Attic', Decimal.valueOf(10), 'Room AC', Decimal.valueOf(20),
                'Slab-On-Grade', 'Room AC', 'Electricity', 'Storage Water Heater', 'Electricity', 'Solar PV');
        dwellingUnit.Dwelling_Unit_Name__c = 'Test Dwelling Unit';
        insert dwellingUnit;
        System.assertNotEquals(null, dwellingUnit.Id);

        // Create Utility Account
        Utility_Account__c utilityAcc = BIGPortalTestUtils.createUtilityAccount('the', 'tester', '(123) 123-3242',
                'Pacific Gas and Electric Company', '8099898890', 'Pacific Gas and Electric Company', '0123121321',
                dwellingUnit.Id);
        insert utilityAcc;
        System.assertNotEquals(null, utilityAcc.Id);

        BIGPortalTestUtils.createHPHIPractitioner(portalAccount);

        // Create custom setting
        BIGPortalTestUtils.createCustomSetting();
        BIGPortalTestUtils.createRebateTiersCustomSettings();

        AccountShare jobShr  = new AccountShare();
        // Set the ID of record being shared.
        jobShr.AccountId = portalAccount.Id;

        // Set the ID of user or group being granted access.
        jobShr.UserOrGroupId = portalUser.Id;

        // Set the access level.
        jobShr.AccountAccessLevel = 'Edit';
        jobShr.OpportunityAccessLevel = 'Edit';
        jobShr.CaseAccessLevel = 'Edit';
        insert jobShr;

        BIGPortalTestUtils.createSoftwareVersionCustomSetting(BIGPortalTestUtils.PGE_ENERGY_PRO_SETTINGS, '5.0',
                '5.9.9.9');
        BIGPortalTestUtils.createSoftwareVersionCustomSetting(BIGPortalTestUtils.PGE_SNUGG_PRO_SETTINGS, '1.0.0',
                '2.0.0');

        // Create Kickers for KWh and Therm
        BIGPortalTestUtils.createKickersCustomSetting();

        List<Zip_Code__mdt> zipCodeData = BIGPortalTestUtils.getZipCodeData(new List<String> {'93240'});
        // Insert the sharing record and capture the save result.
        // The false parameter allows for partial processing if multiple records passed
        // into the operation.
        Database.SaveResult sr = Database.insert(jobShr,false);
    }

    /**
     * Sets the application's HPHI Practitioner when the value of Has_HPHI__c is 'Yes'. If the user is in the post
     * application phase, it sets the Delivered_Sensible_EER__c, Delivered_Sensible_EER_Assessment_Date__c, and creates
     * the corresponding Delivered Sensible EER Scoresheet attachment.
     *
     * @param controller Instance of AdvanceHuAppController.
     * @param contactId HPHI Practitioner contact.
     * @param isPost True if it's in the post application phase. Otherwise, it's false.
     */
    private static void setHPHI(BIGPortalAdvancedHUAppController controller, Id contactId, Boolean isPost) {
        controller.application.HPHI_Practitioner__c = contactId;
        controller.selectedHPHIPractitioner = contactId;

        if (isPost) {
            controller.application.Delivered_Sensible_EER__c = 0.1;
            controller.application.Delivered_Sensible_EER_Assessment_Date__c = Date.today();
            controller.postDeliveredSensibleEERScoresheet = BIGPortalTestUtils.createAttachment('testFile.xls');
        }
    }

    static void createBpiAnalyst(BIGPortalAdvancedHUAppController controller) {
        controller.newBPIAnalyst.FirstName = 'firstN';
        controller.newBPIAnalyst.LastName = 'lastN';
        controller.newBPIAnalyst.Phone = '(703)-555-5555';
        controller.newBPIAnalyst.Email = 'firstN@lastN.com';
        controller.newBPIAnalyst.BPI_License_Number__c = '1234567';
        controller.newBPIAnalyst.BPI_License_Expiration_Date__c = Date.today();
        controller.newBPIAnalyst.AccountId = portalAccount.Id;
        controller.newBPIAnalyst.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contractor')
                .getRecordTypeId();
    }

    private static void helperInitDataForPostAdvanced(PageReference advancedHuPage,
            BIGPortalAdvancedHUAppController controller) {
        //<<<<<<<<<<<<<<<<<< INIT DATA FOR POST APPLICATION >>>>>>>>>>>>>>>>>>>>>
        // Set BIGPortalAdvanceHUApplication.page to current test
        Test.setCurrentPage(advancedHuPage);
        // create a new application
        controller.application = new Application__c();
        controller.application.Status__c = ApplicationUtils.PRE_INSTALL_APPROVED_STATUS;
        controller.application.RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByName()
                .get('AHU').getRecordTypeId();
        controller.application.Contractor__c = portalAccount.Id;
        controller.application.Work_Start_Date__c = Date.today();
        controller.application.Work_Finish_Date__c = Date.today();
        controller.application.Has_Pre_Install_HES__c = 'No';
        controller.application.Has_HPHI__c = 'No';
        controller.application.Conditioned_Area__c = Decimal.valueOf(800);

        insert controller.application;

        // create pre application
        controller.preApplication = new Sub_Application__c();
        controller.preApplication.Application__c = controller.application.Id;
        controller.preApplication.RecordTypeId = BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID;
        controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(1).getValue();
        controller.preApplication.Test_In_Date__c = Date.today() - 1;
        controller.preApplication.Work_Start_Date__c = Date.today();
        controller.preApplication.Work_Finish_Date__c = Date.today();

        insert controller.preApplication;

        // Asign dwelling unit
        controller.dwellingSearchText = 'Test Dwelling Unit';
        controller.searchDwellingUnit();
        System.assertEquals(true, !controller.getDwellingUnitsList().isEmpty());
        // Set dwelling unit as we would on the modal search.
        controller.dwellingToAssignId = controller.getDwellingUnitsList().get(0).Id;
        controller.assignDwellingUnit();
        controller.application.Dwelling_Unit__c = controller.dwellingUnit.Id;

        // Because we skip the pre-application phase we don't have the building fields populated on the Application__c
        completeBuildingOnApplication(controller);

        update controller.application;
    }

    private static void completeBuildingOnApplication(BIGPortalAdvancedHUAppController controller) {
        controller.application.Building_Name__c = 'Test Dwelling Unit';
        controller.application.Building_City__c = 'Test City';
        controller.application.Building_Street_Address__c = 'Test Address';
        controller.application.Building_State__c = 'CA';
        controller.application.Building_ZIP_Code__c = '12345';
        controller.application.Building_Type__c = 'Single Family';
        controller.application.Conditioned_Area__c = Decimal.valueOf(800);
        controller.application.Avg_Ceiling_Height__c = 4;
        controller.application.Number_of_Stories__c = 4;
        controller.application.Year_Built__c = '2010';
        controller.application.Primary_Heating_Fuel__c = 'Natural Gas';
        controller.application.Hot_Water_Fuel__c = 'Propane';
        controller.application.Heating_System__c = 'Radiant';
        controller.application.Air_Conditioning__c = 'Heat Pump';
        controller.application.Domestic_Hot_Water__c = 'Storage Water Heater';
        controller.application.Foundation_Type__c = 'Conditioned Basement';
        controller.application.Roof_Attic_Type__c = 'Vented Attic';
        controller.application.Customer_First_Name__c = 'Test Name';
        controller.application.Customer_Last_Name__c = 'Test Last Name';
        controller.application.Customer_Email__c = 'testMan@gmail.com';
        controller.application.Customer_Phone__c = '(234) 234-2343';
        controller.application.Customer_Address__c = 'Test Address';
        controller.application.Customer_City__c = 'Test City';
        controller.application.Customer_State__c = 'CA';
        controller.application.Customer_Zip_Code__c = '12345';
        controller.application.Utility_Account_Holder_First_Name__c = 'Test Name';
        controller.application.Utility_Account_Holder_Last_Name__c = 'Test Last Name';
        controller.application.Utility_Account_Holder_Phone__c = '(234) 234-2343';
        controller.application.Electric_Provider__c = 'Pacific Gas and Electric Company';
        controller.application.Gas_Provider__c = 'Pacific Gas and Electric Company';
        controller.application.Electric_Account_Number__c = '8099898890';
        controller.application.Gas_Account_Number__c = '0123121321';
    }

    /*
     * Create attachments based on controller for Pre Install Application
     *
     * @param Instance of AdvanceHuAppController
     * @param Xml version
     */
    private static void createPreAppAttachments(BIGPortalAdvancedHUAppController controller, String version){
        controller.contractProposalSOW = BIGPortalTestUtils.createAttachment('testFile.doc');
        controller.homePerformanceXML =  BIGPortalTestUtils.createEnergyProAttachment('testFile.xml', version);
        controller.homePerformanceSystemFile = BIGPortalTestUtils.createAttachment('testFile.pdf');
        controller.testInMeasurements = BIGPortalTestUtils.createAttachment('testFile.pdf');
        controller.additionalDocuments = BIGPortalTestUtils.createAttachment('testFile.zip');
        controller.paymentReleaseAuthorization = BIGPortalTestUtils.createAttachment('testFile.pdf');
    }

    /*
     * Create attachments based on controller for Post Install Application
     *
     * @param Instance of AdvanceHuAppController
     * @param Xml version
     */
    private static void createPostAppAttachments(BIGPortalAdvancedHUAppController controller, String version){
        controller.clientSignedContractSOW = BIGPortalTestUtils.createAttachment('testFile.doc');
        controller.postHomePerformanceXML = BIGPortalTestUtils.createEnergyProAttachment('testFile.xml', version);
        controller.postHomePerformanceSystemFile = BIGPortalTestUtils.createAttachment('testFile.pdf');
        controller.testOutMeasurements = BIGPortalTestUtils.createAttachment('testFile.pdf');
        controller.safetyQualityAcknowledgment = BIGPortalTestUtils.createAttachment('testFile.pdf');
        controller.buildingPermit = BIGPortalTestUtils.createAttachment('testFile.pdf');
        controller.postAdditionalDocuments = BIGPortalTestUtils.createAttachment('testFile.zip');
        controller.postPaymentReleaseAuthorization = BIGPortalTestUtils.createAttachment('testFile.pdf');
    }

    /**
     * Create attachments for Home Energy Score section
     *
     * @param controller Instance of AdvanceHuAppController
     * @param pre If app is in pre or post phase
     */
    private static void createHomeEnergyScoreData(BIGPortalAdvancedHUAppController controller, Boolean pre) {
        if (pre) {
            controller.application.Pre_Home_Energy_Score__c = '1';
            controller.application.Pre_HES_Assessment_Date__c = Date.today();
            controller.homeEnergyScoreReportInputFile = BIGPortalTestUtils.createAttachment('testFile.pdf');
            controller.greenBuildingRegistryOptIn = BIGPortalTestUtils.createAttachment('testFile.pdf');
            controller.homeEnergyScoreAdditionalDocuments = BIGPortalTestUtils.createAttachment('testFile.pdf');
        } else {
            controller.application.Post_Home_Energy_Score__c = '1';
            controller.application.Post_HES_Assessment_Date__c = Date.today();
            controller.postHomeEnergyScoreReportInputFile = BIGPortalTestUtils.createAttachment('testFile.pdf');
            controller.postGreenBuildingRegistryOptIn = BIGPortalTestUtils.createAttachment('testFile.pdf');
            controller.postHomeEnergyScoreAdditionalDocuments = BIGPortalTestUtils.createAttachment('testFile.pdf');
        }
    }

    /**
     * Set Hes Assessor contact.
     *
     * @param controller Instance of AdvanceHuAppController
     * @param pre If app is in pre or post phase
     * @param contactId Home Energy Score contact
     */
    private static void setHomeEnergyScoreAssessor(BIGPortalAdvancedHUAppController controller, Boolean pre,
            Id contactId) {
        if (pre) {
            controller.application.Pre_HES_Assessor__c = contactId;
        } else {
            controller.application.Post_HES_Assessor__c = contactId;
        }
        controller.selectedHESAssessor = contactId;
    }

    private static void searchBuildingAndRequiredFields(BIGPortalAdvancedHuAppController controller) {
        // Search and assign building
        controller.dwellingSearchText = 'Test Dwelling Unit';
        controller.searchDwellingUnit();
        System.assertEquals(true, controller.getDwellingUnitsList().size() > 0);
        // Set dwelling unit as we would on the modal search.
        controller.dwellingToAssignId = controller.getDwellingUnitsList().get(0).Id;
        controller.assignDwellingUnit();
        System.assert(controller.dwellingUnit != null);

        // Complete required fields for pre application
        controller.preApplication.Proposed_Package_Cost__c = 6000;
        controller.preApplication.Total_Incentive__c = 2000;
        controller.setFormattedTestInDate(Date.today());
        controller.preApplication.Rebate_Assignment__c = controller.getRebateTypes().get(1).getValue();
        // Create BPI Analyst
        saveBpiAnalyst(controller);
    }

    private static void clickOnEditButton(PageReference advancedHuPage, BIGPortalAdvancedHUAppController controller) {
        helperInitDataForPostAdvanced(advancedHuPage, controller);
        // Simulate clicking on Edit button and does a page reload (Detail)
        ApexPages.currentPage().getParameters().put('action', 'detail');
        ApexPages.currentPage().getParameters().put('id', controller.application.Id);

        controller.init();
        // insert post application
        controller.postApplication.Application__c = controller.application.Id;

        System.assertEquals(true, controller.getPostAppTabEnabled());
        System.assertEquals(true, controller.getDisplayPostAppTab());
        System.assertEquals(true, controller.getDisplayPostAppNewSection());
        System.assertEquals(false, controller.getDisplayPreAppDetailSection());
        System.assertEquals(false, controller.getDisplayPostAppDetailSection());

        // Check rebate assignment and payment release is copied from pre-application to post-application
        System.assertEquals(controller.preApplication.Rebate_Assignment__c,
                controller.postApplication.Rebate_Assignment__c);
        System.assertEquals(controller.postPaymentReleaseAuthorization.Name,
                controller.paymentReleaseAuthorization.Name);

        saveBpiAnalyst(controller);
    }

    private static void saveBpiAnalyst(BIGPortalAdvancedHUAppController controller) {
        // Create BPI Analyst
        createBpiAnalyst(controller);
        controller.saveBPIAnalyst();
    }

}