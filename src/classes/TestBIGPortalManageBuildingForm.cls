/**
 * This class contains unit tests for validating the behavior of BIGPortalManageBuildingFormController
 */
@isTest
private class TestBIGPortalManageBuildingForm {
    private static User portalUser = null;
    private static String BPIAnalystId = null;
    private static Account portalAccount = null;
    private static Contact portalContact = null;

    private static Building__c building = null;
    private static Dwelling_Unit__c dwellingUnit = null;
    private static Contact propertyOwner = null;
    private static Utility_Account__c utilityAccount = null;

    private static Id AHURecordType = Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('AHU')
            .getRecordTypeId();
    private static Id PREAppRecordType = Schema.SObjectType.Sub_Application__c
            .getRecordTypeInfosByName().get('PRE-APP').getRecordTypeId();

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

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = portalContact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);

        // Create Building
        building = BIGPortalTestUtils.createBuilding('Joe Doe Building', 'Single Family',
                'Building Street Address', 'Building City', 'CA', '22180', 'Building County',
                portalAccount.Id);

        // Create Contact as Property Owner
        propertyOwner = BIGPortalTestUtils.createContact('Property Owner', 'Property Owner',
                'propertyOwner@test.com', '703-222-2222', portalAccount.Id);

        // Create Dwelling Unit
        dwellingUnit = BIGPortalTestUtils.createDwellingUnit('DW Street Address', '10', propertyOwner.Id, building.Id,
                Decimal.valueOf(3), Decimal.valueOf(6), Decimal.valueOf(2), Decimal.valueOf(100),
                '1983', 'Vented Attic', Decimal.valueOf(1000), 'Room AC', Decimal.valueOf(20),
                'Slab-On-Grade', 'Room AC', 'Electricity', 'Storage Water Heater', 'Electricity', 'Solar PV');
        dwellingUnit.Dwelling_Unit_Name__c = 'Test Dwelling Unit';

        utilityAccount = new Utility_Account__c();

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
        Database.SaveResult sr = Database.insert(jobShr,false);
        BIGPortalTestUtils.createCustomSetting();
    }

    static testMethod void testSaveBuildingInfo() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();

            BIGPortalManageBuildingFormController controller = new BIGPortalManageBuildingFormController();
            controller.building = building;
            controller.dwellingUnit = dwellingUnit;
            controller.propertyOwner = propertyOwner;
            controller.utilityAccount = utilityAccount;

            System.assert(controller.building.Id == null);
            System.assert(controller.dwellingUnit.Id == null);
            System.assert(controller.propertyOwner.Id == null);
            System.assert(controller.utilityAccount.Id == null);

            controller.saveBuildingInfo();

            Test.stopTest();

            System.assert(controller.building.Id != null);
            System.assert(controller.dwellingUnit.Id != null);
            System.assert(controller.propertyOwner.Id != null);
            System.assert(controller.utilityAccount.Id != null);
        }
    }

    static testMethod void testInitBIGPortalManageBuildingForm() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();

            insert building;
            insert propertyOwner;
            dwellingUnit.Building__c = building.Id;
            dwellingUnit.Property_Owner__c = propertyOwner.Id;
            insert dwellingUnit;
            utilityAccount.Dwelling_Unit__c = dwellingUnit.Id;
            insert utilityAccount;

            Application__c application = new Application__c();
            application.Contractor__c = portalAccount.Id;
            application.RecordTypeId = AHURecordType;
            application.Dwelling_Unit__c = dwellingUnit.Id;
            insert application;

            Sub_Application__c preApp = BIGPortalTestUtils.createSubApplication(application.Id, PREAppRecordType);

            Contact BPIAnalyst = BIGPortalTestUtils.createBPIAnalyst('fname', 'lname', 'test@test.com',
                '(234) 234-3243', '1234567', Date.today(), portalAccount);
            insert BPIAnalyst;

            preApp.BPI_Analyst__c = BPIAnalyst.Id;
            insert preApp;

            BIGPortalManageBuildingFormController controller = new BIGPortalManageBuildingFormController();
            ApexPages.currentPage().getParameters().put('action', 'new');
            ApexPages.currentPage().getParameters().put('id', application.Id);

            controller.init();
             Test.stopTest();
            System.assertEquals(dwellingUnit.Id, controller.dwellingUnit.Id);
            System.assertEquals(utilityAccount.Id, controller.utilityAccount.Id);
            System.assertEquals(building.Id, controller.building.Id);
            System.assertEquals(propertyOwner.Id, controller.dwellingUnit.Property_Owner__c);
        }
    }

    static testMethod void testSaveBuildingInfoWithApplication() {
        initData();

        System.runAs(portalUser) {
            Test.startTest();

            BIGPortalManageBuildingFormController controller = new BIGPortalManageBuildingFormController();
            controller.building = building;
            controller.dwellingUnit = dwellingUnit;
            controller.propertyOwner = propertyOwner;
            controller.utilityAccount = utilityAccount;

            System.assert(controller.building.Id == null);
            System.assert(controller.dwellingUnit.Id == null);
            System.assert(controller.propertyOwner.Id == null);
            System.assert(controller.utilityAccount.Id == null);

            // One application is created
            controller.saveBuildingInfo();

            controller.building.Building_Name__c = 'TestBuilding';
            controller.saveBuildingInfo();

            Test.stopTest();

            System.assertEquals('TestBuilding',
                    [SELECT Building_Name__c FROM Building__c WHERE Id =: controller.building.Id].Building_Name__c);
            System.assert(controller.dwellingUnit.Id != null);
            System.assert(controller.propertyOwner.Id != null);
            System.assert(controller.utilityAccount.Id != null);
        }
    }

    static testMethod void testGetStates() {
        initData();
        System.runAs(portalUser) {
            Test.startTest();
            List<SelectOption> selectOptionList = null;
            BIGPortalManageBuildingFormController controller = new BIGPortalManageBuildingFormController();
            selectOptionList = controller.getStates();
            Test.stopTest();
            System.assert(selectOptionList.size() > 0);
        }
    }

    static testMethod void testHasAHU() {
        initData();
        System.runAs(portalUser) {
            Test.startTest();
            portalContact.Program_Enrollment__c = 'AHU; ACQC';
            update portalContact;
            BIGPortalManageBuildingFormController controller = new BIGPortalManageBuildingFormController();
            Test.stopTest();
            System.assert(controller.getHasAdvancedHUPProgram());
            System.assert(controller.getHasACQCProgram());
        }
    }
}