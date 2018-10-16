@isTest
public with sharing class BIGPortalHVACDashboardTest {

    private static User portalUser;
    private static Account portalAccount;
    private static Contact portalContact;
    private static List<Rebate_Type__c> rebateTypes;
    private static Id ACQCRecordType = Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('ACQC')
            .getRecordTypeId();

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

        // Create Rebate Types
        rebateTypes = new List<Rebate_Type__c>();
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Full ACCA Standard 4 HVAC System Assessment', 50, 'TK07',
                'Full ACCA Standard 4 HVAC System Assessment'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Air Flow Correction', 400, 'TK08',
                'Air Flow Correction'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Refrigerant System Service', 50, 'TK09',
                'Refrigerant System Service'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 300, 'TK10',
                'Replacement Blower Motor'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('One-year QM Service Agreement', 50, 'TK12',
                'One-year QM Service Agreement'));
        insert rebateTypes;

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

    private static Application__c createApplicationWithStatus(String name, Id rti, String status) {
        Site__c site = BIGPortalTestUtils.createSite('site','address','12345', portalAccount);
        insert site;
        System.assertNotEquals(null, site.Id);

        Unit__c unit = BIGPortalTestUtils.createUnit('unit','make','model',site);
        insert unit;
        System.assertNotEquals(null, unit.Id);

        Application__c application = BIGPortalTestUtils.createApplication(name,'add','city','CA','zip','phone',
                'email@test.com',unit);
        application.Contractor__c = portalAccount.Id;
        application.Status__c = status;
        application.RecordTypeId = rti;
        insert application;
        System.assertNotEquals(null, application.Id);

        return application;
    }

    static testMethod void testGetApplications() {
        initData();
        portalContact.Program_Enrollment__c = null;
        update portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            List<BIGPortalHVACDashboardController.WrapperApplications> result = controller.getACQCApplications();
            System.assertEquals(null, result);
        }
        Test.stopTest();
    }

     static testMethod void testGetACQCapplicationsWithoutACQCPermission() {
        initData();
        portalContact.Program_Enrollment__c = 'HU';
        update portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            List<BIGPortalHVACDashboardController.WrapperApplications> result = controller.getACQCApplications();
            System.assertEquals(null, result);
            // Since portal user don't have ACQC program has been redirected to HUP portal.
            System.assertEquals(Page.AccessDenied.getUrl(), controller.checkUserAccess().getUrl());
        }
        Test.stopTest();
    }

    static testMethod void testGetACQCapplications() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType,
                    ApplicationUtils.CANCELED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType,
                    ApplicationUtils.CANCELED_STATUS);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            BIGPortalHVACDashboardController.WrapperApplications waHelp;

            for (BIGPortalHVACDashboardController.WrapperApplications wa: controller.getACQCApplications()) {
                if(wa.status == ApplicationUtils.CANCELED_STATUS) {
                    waHelp = wa;
                    break;
                }
            }

            System.assertEquals(2, waHelp.numofApps);
        }

        Test.stopTest();
    }

    static testMethod void testNumberACQCAppsByStatus() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType, ApplicationUtils.CANCELED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType, ApplicationUtils.CANCELED_STATUS);
            Application__c c = createApplicationWithStatus('sample3', ACQCRecordType, ApplicationUtils.CREATED_STATUS);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            Map<String, Integer> result = new Map<String, Integer>();
            for(BIGPortalHVACDashboardController.WrapperApplications wa: controller.getACQCApplications()){
                result.put(wa.status, wa.numofApps);
            }
            System.assertEquals(2, result.get(ApplicationUtils.CANCELED_STATUS));
            System.assertEquals(1, result.get(ApplicationUtils.CREATED_STATUS));
        }

        Test.stopTest();
    }

    static testMethod void testACQCInspections() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType, ApplicationUtils.CANCELED_STATUS);
            a.Field_QC_Date_Time__c = datetime.now();
            a.Field_QC_Verifier_Score__c = 'Passed';
            a.Desktop_Review_Status__c = 'Passed';
            a.Field_QC_Status__c = 'Passed';
            a.Building_County__c ='San Bernardino';
            a.Climate_Zone__c = 15;
            a.Building_ZIP_Code__c = '92304';
            upsert a;

            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType, ApplicationUtils.CANCELED_STATUS);
            b.Field_QC_Date_Time__c = datetime.now();
            b.Field_QC_Verifier_Score__c = 'Passed';
            b.Desktop_Review_Status__c = 'Passed';
            b.Field_QC_Status__c = 'Passed';
            b.Building_County__c ='San Bernardino';
            b.Climate_Zone__c = 15;
            b.Building_ZIP_Code__c = '92304';
            upsert b;

            Application__c c = createApplicationWithStatus('sample3', ACQCRecordType, ApplicationUtils.CREATED_STATUS);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            List<Application__c> result = controller.getInspections();
            System.assertEquals(2, result.size());
        }

        Test.stopTest();
    }

    static testMethod void testProgramAnnouncementsEvents() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            Program_Announcement__c a = BIGPortalTestUtils.createProgram('Sample1', 'Announcement', 'Active');
            insert a;
            Program_Announcement__c b = BIGPortalTestUtils.createProgram('Sample2', 'Announcement', 'Active');
            insert b;
            Program_Announcement__c c = BIGPortalTestUtils.createProgram('Sample2', 'Event', 'Active');
            insert c;
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            List<Program_Announcement__c> result = controller.getProgramAnnouncements();
            System.assertEquals(2, result.size());

            List<Program_Announcement__c> otherResult = controller.getEvents();
            System.assertEquals(1, otherResult.size());
        }

        Test.stopTest();
    }

    static testMethod void testQuickReferences() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            BIGPortalTestUtils.createQuickReferenceSetting();
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            List<Quick_Reference__c> result = controller.getQuickReferences();
            System.assertEquals(1, result.size());
        }

        Test.stopTest();
    }

    static testMethod void testGetACQCStatuses() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            List<String> statuses = new List<String>();
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();

            for (BIGPortalHVACDashboardController.WrapperApplications wa : controller.acqcApps) {
                statuses.add(wa.status);
            }
            System.assertEquals(JSON.serialize(statuses), controller.getACQCStatuses());
        }
        Test.stopTest();
    }

    static testMethod void testGetFilteredApplications() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;
        Test.startTest();

        System.RunAs(portalUser) {
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType, ApplicationUtils.CREATED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType, ApplicationUtils.CREATED_STATUS);
            List<Application__c> appsSorted = new List<Application__c> {a,b};

            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            String params = JSON.serialize(new Map<String, String> {
                        'recordType' => 'ACQC',
                        'status' => ApplicationUtils.CREATED_STATUS,
                        'startDate' => null,
                        'endDate' => null});
            ResponseWrapper response = BIGPortalHVACDashboardController.getFilteredApplications(params);
            System.assertEquals(appsSorted.size(), response.results.size());
        }
        Test.stopTest();
    }

    /**
     * Test getRebateTypeGroups() method which retrieves the rebate type groups for all issued rebate applications
     * within the past six months.
     */
    static testMethod void testGetRebateTypeGroups() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;

        System.RunAs(portalUser) {
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();

            Date myDate = BIGPortalTestUtils.getDateFiveMonthsAgoFromToday();

            Test.startTest();
            Rebate_Application__c ra1 = BIGPortalTestUtils.createRebateApplication(a, myDate, myDate, ACQCRecordType,
                    'TK07', 2000, 'Paid');
            Rebate_Application__c ra2 = BIGPortalTestUtils.createRebateApplication(b, myDate, myDate, ACQCRecordType,
                    'TK10', 2000, 'Paid');
            List<Rebate_Application__c> itemsRebateApp = new List<Rebate_Application__c> {ra1, ra2};
            insert itemsRebateApp;
            Test.stopTest();

            System.assert(controller.getRebateTypeGroups().contains('Full ACCA Standard 4 HVAC System Assessment'));
            System.assert(controller.getRebateTypeGroups().contains('Replacement Blower Motor'));
        }
    }

    /**
     * Test getRebateTypeGroups() method for the case where the Initial_VRS_Submission_Date__c is not within
     * the past six months. In this case, we expect to retrieve an empty list.
     */
    static testMethod void testGetRebateTypeGroupsWithDateOlderThanSixMonths() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;

        System.RunAs(portalUser) {
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();

            Date myDate = BIGPortalTestUtils.getDateFiveMonthsAgoFromToday().addMonths(-7);

            Test.startTest();
            Rebate_Application__c ra1 = BIGPortalTestUtils.createRebateApplication(a, myDate, myDate, ACQCRecordType,
                    'TK07', 2000, 'Paid');
            Rebate_Application__c ra2 = BIGPortalTestUtils.createRebateApplication(b, myDate, myDate, ACQCRecordType,
                    'TK10', 2000, 'Paid');
            List<Rebate_Application__c> itemsRebateApp = new List<Rebate_Application__c> {ra1, ra2};
            insert itemsRebateApp;
            Test.stopTest();

            System.assertEquals(0, controller.getRebateTypeGroups().size());
        }
    }

    /**
     * Test getLastSixMonthsWithYear() method which retrieves a list of the last six months with year.
     */
    static testMethod void testGetLastSixMonthsWithYear() {
        initData();

        System.RunAs(portalUser) {
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();

            Test.startTest();
            List<String> ls = controller.getLastSixMonthsWithYear();
            Test.stopTest();

            System.assert(ls.size() == 6);
        }
    }

    /**
     * Test to get the sum of Final Rebate Amount field from Rebate Applications, when its status is paid or
     * 11A - Paid - D&C and Measure Status is not Rejected.
     */
    static testMethod void testGetTotalRebatePaidByRecordTypeGroup() {
        initData();

        System.RunAs(portalUser) {
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();

            Date myDate = BIGPortalTestUtils.getDateFiveMonthsAgoFromToday();

            Test.startTest();
            Rebate_Application__c ra1 = BIGPortalTestUtils.createRebateApplication(a, myDate, myDate, ACQCRecordType,
                    'TK07', 2000, 'Paid');
            Rebate_Application__c ra2 = BIGPortalTestUtils.createRebateApplication(b, myDate, myDate, ACQCRecordType,
                    'TK10', 1000, 'Paid');
            List<Rebate_Application__c> itemsRebateApp = new List<Rebate_Application__c> {ra1, ra2};
            insert itemsRebateApp;
            Test.stopTest();

            System.assertEquals(2000, controller.getTotalRebatePaidByRecordTypeGroup().get(
                    'Full ACCA Standard 4 HVAC System Assessment'));
            System.assertEquals(1000, controller.getTotalRebatePaidByRecordTypeGroup().get(
                    'Replacement Blower Motor'));
        }
    }

    /**
     * Test to get the month and the quantity of Applications that its Rebate Applications' data were already sent to EI
     * per each last 6 months.
     */
    static testMethod void testGetTotalApplicationsSubmittedByMonth() {
        initData();

        System.RunAs(portalUser) {
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            List<Rebate_Application__c> itemsRebateApp = new List<Rebate_Application__c>();
            List<Application__c> apps = new List<Application__c>();

            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            DateTime myDateTime = DateTime.now();
            String submissionMonthWithYear = myDateTime.format('MMM') + ' ' + myDateTime.year();

            Test.startTest();
            Rebate_Application__c ra1 = BIGPortalTestUtils.createRebateApplication(
                    a, myDateTime.date(), myDateTime.date(), ACQCRecordType, 'TK07', 2000, 'Paid');
            Rebate_Application__c ra2 = BIGPortalTestUtils.createRebateApplication(
                    b, myDateTime.date(), myDateTime.date(), ACQCRecordType, 'TK10', 2000, 'Paid');
            itemsRebateApp.add(ra1);
            itemsRebateApp.add(ra2);
            insert itemsRebateApp;
            Test.stopTest();

            for (String monthWithYear : controller.getTotalApplicationsSubmittedByMonth().keySet()) {
                if (monthWithYear == submissionMonthWithYear) {
                    System.assertEquals(2, controller.getTotalApplicationsSubmittedByMonth().get(monthWithYear));
                } else {
                    System.assertEquals(0, controller.getTotalApplicationsSubmittedByMonth().get(monthWithYear));
                }
            }
        }
    }

    /**
     * Test to get the number of Application that its Rebate Applications' data were already sent to EI.
     */
    static testMethod void testGetTotalApplicationsSubmitted() {
        initData();

        System.RunAs(portalUser) {
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            List<Rebate_Application__c> itemsRebateApp = new List<Rebate_Application__c>();
            List<Application__c> apps = new List<Application__c>();

            Test.startTest();
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);

            Date myDate = System.today();
            Rebate_Application__c ra1 = BIGPortalTestUtils.createRebateApplication(a, myDate, myDate, ACQCRecordType,
                    'TK07', 2000, 'Paid');
            Rebate_Application__c ra2 = BIGPortalTestUtils.createRebateApplication(b, myDate, myDate, ACQCRecordType,
                    'TK10', 2000, 'Paid');
            itemsRebateApp.add(ra1);
            itemsRebateApp.add(ra2);
            insert itemsRebateApp;
            Test.stopTest();

            System.assertEquals(2, controller.getTotalApplicationsSubmitted());
        }
    }

    /**
     * Test the getTotalRebatePaidMonthly() method, which retrieves the total rebate amount paid per month
     * for the last six months.
     */
    static testMethod void testGetTotalRebatePaidMonthly() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;

        System.RunAs(portalUser) {
            List<Rebate_Application__c> itemsRebateApp = new List<Rebate_Application__c>();
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);

            Test.startTest();
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            Date myDate = BIGPortalTestUtils.getDateFiveMonthsAgoFromToday();
            Rebate_Application__c ra1 = BIGPortalTestUtils.createRebateApplication(a, myDate, myDate, ACQCRecordType,
                    'TK07', 2000, 'Paid');
            Rebate_Application__c ra2 = BIGPortalTestUtils.createRebateApplication(b, myDate, myDate, ACQCRecordType,
                    'TK07', 2000, 'Paid');
            itemsRebateApp.add(ra1);
            itemsRebateApp.add(ra2);
            insert itemsRebateApp;
            Test.stopTest();

            String month = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day()).format('MMM');
            System.assertEquals(4000, controller.getTotalRebatePaidMonthly().get(month + ' ' + myDate.year()));
        }
    }

    /**
     * Test the getTotalRebatePaid() method, which retrieves the total rebate amount paid for all
     * the issued rebate applications.
     */
    static testMethod void testGetTotalRebatePaid() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        upsert portalContact;

        System.RunAs(portalUser) {
            List<Rebate_Application__c> itemsRebateApp = new List<Rebate_Application__c>();
            Application__c a = createApplicationWithStatus('sample1', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            Application__c b = createApplicationWithStatus('sample2', ACQCRecordType,
                    ApplicationUtils.REBATE_ISSUED_STATUS);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();
            Date myDate = BIGPortalTestUtils.getDateFiveMonthsAgoFromToday();

            Test.startTest();
            Rebate_Application__c ra1 = BIGPortalTestUtils.createRebateApplication(a, myDate, myDate, ACQCRecordType,
                    'TK07', 2000, 'Paid');
            Rebate_Application__c ra2 = BIGPortalTestUtils.createRebateApplication(b, myDate, myDate, ACQCRecordType,
                    'TK07', 2000, 'Paid');
            itemsRebateApp.add(ra1);
            itemsRebateApp.add(ra2);
            insert itemsRebateApp;
            Test.stopTest();

            System.assertEquals(4000, controller.getTotalRebatePaid());

        }
    }

    /**
     * Test Program Acces behavior when you don't have access to ACQC program.
     */
    static testMethod void testNotACQCPortalProgramAccess() {
        initData();
        portalContact.Program_Enrollment__c = 'HU; AHU';
        update portalContact;

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGACQCDashboard);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();

            Test.startTest();
            PageReference accessDenied = controller.checkUserAccess();
            Test.stopTest();

            System.assertEquals(Page.AccessDenied.getUrl(), accessDenied.getUrl());
        }
    }

}