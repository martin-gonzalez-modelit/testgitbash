/**
 * This class contains unit tests for validating the behavior
 * of Dashboards on PG&E Portal.
 */
@isTest
private class TestBIGPortalManageDashboard {

    private static User portalUser;
    private static Account portalAccount;
    private static Contact portalContact;
    private static List<Rebate_Type__c> rebateTypes;
    private static List<Application__c> applications;
    private static List<Program_Announcement__c> programAnnouncements;
    private static Id HUPRecordType = Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('HUP')
            .getRecordTypeId();
    private static Id AHURecordType = Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('AHU')
            .getRecordTypeId();
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';

    private static final String AHU_PRE = 'ahu-pre';
    private static final String AHU_POST = 'ahu-post';
    private static final String HUP = 'hup';

    private static void initData() {
        // Create Account
        portalAccount = BIGPortalTestUtils.createAccount('portalAccount');
        insert portalAccount;
        System.assertNotEquals(null, portalAccount.Id);

        // Create Contact

        portalContact = BIGPortalTestUtils.createContact('portalContact' , 'portalContact', 'portalContact@test.com',
                '703-555-5555', portalAccount.Id);
        insert portalContact;
        System.assertNotEquals(null, portalContact.Id);

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = portalContact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);

        applications = new List<Application__c>();

        programAnnouncements = new List<Program_Announcement__c>();
        programAnnouncements.add(BIGPortalTestUtils.createProgram('Event 1', 'Event', 'Active'));
        programAnnouncements.add(BIGPortalTestUtils.createProgram('Event 2', 'Event', 'Active'));
        programAnnouncements.add(BIGPortalTestUtils.createProgram('Event 3', 'Event', 'Inactive'));
        programAnnouncements.add(BIGPortalTestUtils.createProgram('Announcement 1', 'Announcement', 'Active'));
        programAnnouncements.add(BIGPortalTestUtils.createProgram('Announcement 2', 'Announcement', 'Active'));
        programAnnouncements.add(BIGPortalTestUtils.createProgram('Announcement 3', 'Announcement', 'Inactive'));
        insert programAnnouncements;

        // Create custom setting
        BIGPortalTestUtils.createCustomSetting();
        // Create quick reference setting for dashboard page
        BIGPortalTestUtils.createQuickReferenceSetting();

        // Create custom setting
        BIGPortalTestUtils.createCustomSetting();

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

        // Insert the sharing record and capture the save result.
        // The false parameter allows for partial processing if multiple records passed
        // into the operation.
        Database.SaveResult sr = Database.insert(jobShr, false);

    }

    private static List<BIGPortalManageDashboardController.WrapperApplications> getCustomSettingsByType(String pType) {
        String settingsToProcess;
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        List<BIGPortalManageDashboardController.WrapperApplications> result =
                new List<BIGPortalManageDashboardController.WrapperApplications>();

        if (settings != null) {
            if (pType == AHU_PRE) {
                settingsToProcess = settings.AHU_Pre_Application_Status_List__c;
            } else if (pType == AHU_POST) {
                settingsToProcess = settings.AHU_Post_Application_Status_List__c;
            } else if (pType == HUP) {
                settingsToProcess = settings.HUP_Application_Status_List__c;
            }

            if (settingsToProcess != null && settingsToProcess.trim() != '') {
                List<String> statusColorPair = null;
                for (String s : settingsToProcess.trim().split(';')) {
                    statusColorPair = s.trim().split('\\|');
                    BIGPortalManageDashboardController.WrapperApplications objSetting =
                            new BIGPortalManageDashboardController.WrapperApplications(statusColorPair.get(0),
                                    (statusColorPair.size() > 1) ? statusColorPair.get(1) : '#000000');
                    result.add(objSetting);
                }
            }
        }

        return result;

    }


    static testMethod void testBIGPortalDashboardInspections() {
        initData();
        Test.startTest();

        //Run As U1
        System.RunAs(portalUser) {
            Application__c a = createApplicationWithStatus('Application1', ApplicationUtils.CREATED_STATUS, HUPRecordType);
            Application__c b = createApplicationWithStatus('Application2', ApplicationUtils.CREATED_STATUS, HUPRecordType);
            applications.add(a);
            applications.add(b);
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();
            Map<String,BIGPortalManageDashboardController.WrapperApplications> appsByStatus = controller
                    .getApplicationsByStatus();
            System.assertNotEquals(appsByStatus.isEmpty(), null);
            System.assertEquals(controller.getInspections().size(), applications.size());
        }

        Test.stopTest();
    }

    static testMethod void testBIGPortalDashboardHUPApps() {
        initData();
        portalContact.Program_Enrollment__c = 'HU';
        upsert portalContact;
        Test.startTest();
        //Run As U1
        System.RunAs(portalUser) {
            createApplicationWithStatus('Application1', ApplicationUtils.SUBMITTED_STATUS, HUPRecordType);
            createApplicationWithStatus('Application2', ApplicationUtils.SUBMITTED_STATUS, HUPRecordType);
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();
            BIGPortalManageDashboardController.WrapperApplications waHelp;

            List<BIGPortalManageDashboardController.WrapperApplications> customSettingsHUPList =
                    getCustomSettingsByType('hup');
            List<BIGPortalManageDashboardController.WrapperApplications> HUPApps = controller
                    .getHUPApplicationsByStatus();
            for(BIGPortalManageDashboardController.WrapperApplications wa: HUPApps) {
                if (wa.status == ApplicationUtils.SUBMITTED_STATUS) {
                    waHelp = wa;
                    break;
                }
            }
            System.assertEquals(HUPApps.size(), customSettingsHUPList.size());
            System.assertEquals(2, waHelp.numofApps);
        }

        Test.stopTest();
    }

    static testMethod void testBIGPortalDashboardPreApps() {
        initData();
        portalContact.Program_Enrollment__c = 'AHU';
        upsert portalContact;
        String preAHUPApps;

        Test.startTest();
        //Run as a portal user.
        System.RunAs(portalUser) {
            createApplicationWithStatus('Application1', ApplicationUtils.PRE_INSTALL_CREATED_STATUS, AHURecordType);
            createApplicationWithStatus('Application2', ApplicationUtils.PRE_INSTALL_CREATED_STATUS, AHURecordType);
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();

            preAHUPApps = controller.getAdvancePreApplicationsByStatus();
        }
        Test.stopTest();

        List<BIGPortalManageDashboardController.WrapperApplications> customSettingsPreAHUPList =
                    getCustomSettingsByType('ahu-pre');
        List<BIGPortalManageDashboardController.WrapperApplications> desWrapperApps =
                (List<BIGPortalManageDashboardController.WrapperApplications>)JSON.deserialize(
                        preAHUPApps, List<BIGPortalManageDashboardController.WrapperApplications>.class);
        BIGPortalManageDashboardController.WrapperApplications waHelp;

        // Loop through the result wrapper until finds the wrapper with the 2 applications created before.
        for (BIGPortalManageDashboardController.WrapperApplications wa: desWrapperApps) {
            if (wa.status == ApplicationUtils.PRE_INSTALL_CREATED_STATUS) {
                waHelp = wa;
                break;
            }
        }

        // Check if the numbers of wrapper records coming from the controller does match
        // the one from the custom settings definition.
        System.assertEquals(desWrapperApps.size(), customSettingsPreAHUPList.size());
        // Should match since we have inserted 2 applications with status 'Pre-Install Created' previously.
        System.assertEquals(2, waHelp.numofApps);
    }

    static testMethod void testBIGPortalDashboardPostApps() {
        initData();
        portalContact.Program_Enrollment__c = 'AHU';
        upsert portalContact;
        String postAHUPApps;

        Test.startTest();
        //Run As U1
        System.RunAs(portalUser) {
            createApplicationWithStatus('Application1', ApplicationUtils.POST_INSTALL_CREATED_STATUS, AHURecordType);
            createApplicationWithStatus('Application2', ApplicationUtils.POST_INSTALL_CREATED_STATUS, AHURecordType);
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();

            postAHUPApps = controller.getAdvancePostApplicationsByStatus();
        }
        Test.stopTest();

        List<BIGPortalManageDashboardController.WrapperApplications> customSettingsPostAHUPList =
                getCustomSettingsByType('ahu-post');
        BIGPortalManageDashboardController.WrapperApplications waHelp;
        List<BIGPortalManageDashboardController.WrapperApplications> desWrapperApps =
                (List<BIGPortalManageDashboardController.WrapperApplications>)JSON.deserialize(postAHUPApps,
                        List<BIGPortalManageDashboardController.WrapperApplications>.class);

        for (BIGPortalManageDashboardController.WrapperApplications wa: desWrapperApps) {
            if (wa.status == ApplicationUtils.POST_INSTALL_CREATED_STATUS) {
                waHelp = wa;
                break;
            }
        }

        System.assertEquals(desWrapperApps.size(), customSettingsPostAHUPList.size());
        System.assertEquals(2, waHelp.numofApps);
    }

    static testMethod void testBIGPortalDashboardGroupByStatus() {

        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;
        Test.startTest();
        //Run As U1
        System.RunAs(portalUser) {
            createApplicationWithStatus('Application6', ApplicationUtils.CREATED_STATUS, HUPRecordType);
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();
            BIGPortalManageDashboardController.WrapperApplications aux;

            List<BIGPortalManageDashboardController.WrapperApplications> apps = controller
                    .getHUPApplicationsByStatus();
            system.assertEquals(null, apps);
        }

        Test.stopTest();
    }


    static testMethod void testBIGPortalDashboardEvents() {

        initData();

        Test.startTest();

        //Run As U1
        System.RunAs(portalUser) {
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();
            List<Program_Announcement__c> programs = controller.getEvents();
            // Should be 2 since we've inserted one event inactive
            System.assertEquals(programs.size(), 2);
        }

        Test.stopTest();
    }

    static testMethod void testBIGPortalDashboardAnnouncements() {

        initData();

        Test.startTest();

        //Run As U1
        System.RunAs(portalUser) {
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();
            List<Program_Announcement__c> programs = controller.getProgramAnnouncements();
            // Should be 2 since we've inserted one announcement inactive
            System.assertEquals(programs.size(), 2);
        }

        Test.stopTest();
    }

    static testMethod void testBIGPortalDashboardQuickReferences() {

        initData();

        Test.startTest();

        //Run As U1
        System.RunAs(portalUser) {
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();
            List<Quick_Reference__c> quickReferences = controller.getQuickReferences();
            System.assertEquals(quickReferences.size(), 1);
        }

        Test.stopTest();
    }

    static testMethod void testGetAdvanceApplicationsByStatus() {
        initData();
        portalContact.Program_Enrollment__c = 'AHU';
        upsert portalContact;
        Test.startTest();
        //Run As U1
        System.RunAs(portalUser) {
            Application__c app1 = createApplicationWithStatus('Sample 1', ApplicationUtils.PRE_INSTALL_CREATED_STATUS,
                    AHURecordType);
            Application__c app2 = createApplicationWithStatus('Sample 2', ApplicationUtils.PRE_INSTALL_CREATED_STATUS,
                    AHURecordType);
            Application__c app3 = createApplicationWithStatus('Sample 3', ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS,
                    AHURecordType);

            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();

            Map<String, BIGPortalManageDashboardController.WrapperApplications> res = controller
                    .getAdvanceApplicationsByStatus();

            System.assertEquals(2, res.get(ApplicationUtils.PRE_INSTALL_CREATED_STATUS).numofApps);
            System.assertEquals(1, res.get(ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS).numofApps);
        }

        Test.stopTest();
    }

    static testMethod void testGetAdvanceApplicationsSize() {
        initData();
        portalContact.Program_Enrollment__c = 'AHU';
        upsert portalContact;
        Test.startTest();
        //Run As U1
        System.RunAs(portalUser) {
            Application__c app1 = createApplicationWithStatus('Sample 1', ApplicationUtils.PRE_INSTALL_CREATED_STATUS,
                    AHURecordType);
            Application__c app2 = createApplicationWithStatus('Sample 2', ApplicationUtils.PRE_INSTALL_CREATED_STATUS,
                    AHURecordType);
            Application__c app3 = createApplicationWithStatus('Sample 3', ApplicationUtils.CREATED_STATUS,
                    HUPRecordType);

            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();

            Integer res = controller.getAdvanceApplicationsSize();

            System.assertEquals(2, res);
        }

        Test.stopTest();
    }

    static testMethod void testGetApplicationsSize() {
        initData();
        portalContact.Program_Enrollment__c = 'HU';
        upsert portalContact;
        Test.startTest();
        //Run As U1
        System.RunAs(portalUser) {
            Application__c app3 = createApplicationWithStatus('Sample 1', ApplicationUtils.CREATED_STATUS,
                    HUPRecordType);
            Application__c app2 = createApplicationWithStatus('Sample 2', ApplicationUtils.PRE_INSTALL_CREATED_STATUS,
                    AHURecordType);


            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();

            Integer res = controller.getApplicationsSize();

            System.assertEquals(1, res);
        }

        Test.stopTest();
    }

    static testMethod void testSaveProgramTabSelection() {
        initData();
        Test.startTest();
        //Run As U1
        System.RunAs(portalUser) {

            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();
            controller.programTabSelected = 'Advanced Home Upgrade';
            controller.saveProgramTabSelection();
            Contact ct = [SELECT Id, Program_Tab_Selection__c FROM Contact WHERE Id =: portalContact.Id];

            System.assertEquals(portalContact.Id, ct.Id);
            System.assertEquals('Advanced Home Upgrade', ct.Program_Tab_Selection__c);
        }

        Test.stopTest();
    }

    private static Application__c createApplication(String name) {
        Site__c site = BIGPortalTestUtils.createSite('site','address','12345', portalAccount);
        insert site;
        System.assertNotEquals(null, site.Id);

        Unit__c unit = BIGPortalTestUtils.createUnit('unit','make','model',site);
        insert unit;
        System.assertNotEquals(null, unit.Id);

        Application__c application = BIGPortalTestUtils.createApplication(name,'add','city','CA','zip','phone',
                'email@test.com',unit);
        application.RecordTypeId = HUPRecordType;
        application.Contractor__c = portalAccount.Id;
        application.Building_Street_Address__c = 'Building Madison Avenue';
        application.Building_City__c = 'Madison';
        application.Field_QC_Date_Time__c = System.today();
        insert application;
        System.assertNotEquals(null, application.Id);

        return application;
    }

    private static Application__c createApplicationWithStatus(String name, String st, Id rti) {
        Site__c site = BIGPortalTestUtils.createSite('site','address','12345', portalAccount);
        insert site;
        System.assertNotEquals(null, site.Id);

        Unit__c unit = BIGPortalTestUtils.createUnit('unit','make','model',site);
        insert unit;
        System.assertNotEquals(null, unit.Id);

        Application__c application = BIGPortalTestUtils.createApplication(name,'add','city','CA','zip','phone',
                'email@test.com',unit);
        application.RecordTypeId = rti;
        application.Contractor__c = portalAccount.Id;
        application.Building_Street_Address__c = 'Building Madison Avenue';
        application.Building_City__c = 'Madison';
        application.Field_QC_Date_Time__c = System.today();
        application.Status__c = st;
        application.Field_QC_Verifier_Score__c = 'Passed';
        application.Desktop_Review_Status__c = 'Passed';
        application.Field_QC_Status__c = 'Passed';
        insert application;
        System.assertNotEquals(null, application.Id);

        return application;
    }

    /**
     * Test Program Acces behavior when you don't have access to HU or AHU program.
     */
    static testMethod void testNotHUOrAHUPortalProgramAccess() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        update portalContact;

        System.RunAs(portalUser) {
            // Set BIGPortalManageDashboard.page to current test
            Test.setCurrentPage(Page.BIGPortalManageDashboard);
            BIGPortalManageDashboardController controller = new BIGPortalManageDashboardController();

            Test.startTest();
            PageReference accessDenied = controller.checkUserAccess();
            Test.stopTest();

            System.assertEquals(Page.AccessDenied.getUrl(), accessDenied.getUrl());
        }
    }

}