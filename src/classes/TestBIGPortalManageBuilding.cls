/**
 * This class contains unit tests for validating the behavior
 * of BIGPortalDwellingUnitController.
 */
@isTest
private class TestBIGPortalManageBuilding {

    private static User portalUser;
    private static Contact portalContact;
    private static Building__c building;
    private static Building__c building2To4Units;
    private static Dwelling_Unit__c dwellingUnit;
    private static Utility_Account__c utilityAccount;

    private static void initData() {
        // Create Account
        Account portalAccount = BIGPortalTestUtils.createAccount('portalAccount');
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
        building = BIGPortalTestUtils.createBuilding('Joe Doe Building', 'Single Family', 'Building Street Address',
                'Building City', 'CA', '22180', 'Building County', portalAccount.Id);
        insert building;
        System.assertNotEquals(null, building.Id);

        // Create Building
        building2To4Units = BIGPortalTestUtils.createBuilding('Jhon Doe Building', '2-4 Units',
                'Building Street Address', 'Building City', 'CA', '22180', 'Building County',
                portalAccount.Id);
        insert building2To4Units;
        System.assertNotEquals(null, building2To4Units.Id);

        // Create Contact as Property Owner
        Contact propertyOwner = BIGPortalTestUtils.createContact('Property Owner', 'Property Owner',
                'propertyOwner@test.com', '703-222-2222', portalAccount.Id);
        insert propertyOwner;
        System.assertNotEquals(null, propertyOwner.Id);

        // Create Dwelling Unit
        dwellingUnit = BIGPortalTestUtils.createDwellingUnit('DW Street Address', '10', propertyOwner.Id, building.Id,
                Decimal.valueOf(3), Decimal.valueOf(6), Decimal.valueOf(2), Decimal.valueOf(100),
                '1983', 'Vented Attic', Decimal.valueOf(1000), 'Room AC', Decimal.valueOf(20),
                'Slab-On-Grade', 'Room AC', 'Electricity', 'Storage Water Heater', 'Electricity', 'Solar PV');
        insert dwellingUnit;
        System.assertNotEquals(null, dwellingUnit.Id);

        // Create utility account
        utilityAccount = BIGPortalTestUtils.createUtilityAccount('Utility Account', 'Utility Account', '703-222-3333',
                'Pacific Gas and Electric Company', '1111111', 'Pacific Gas and Electric Company', '2222222',
                dwellingUnit.Id);
        insert utilityAccount;
        System.assertNotEquals(null, utilityAccount.Id);

        // Create custom setting
        BIGPortalTestUtils.createCustomSetting();

    }

    static testMethod void testBIGPortalManageBuilding() {
        initData();

        test.startTest();

        System.runAs(portalUser) {

            PageReference pageRef = Page.BIGPortalManageBuilding;
            Test.setCurrentPage(pageRef);

            // *** BUILDINGS

            // Instantiate the BIGPortalDwellingUnitController
            BIGPortalManageBuildingController controller = new BIGPortalManageBuildingController();

            // Action = detail
            ApexPages.currentPage().getParameters().put('id', building.Id);
            ApexPages.currentPage().getParameters().put('action', 'detail');
            controller = new BIGPortalManageBuildingController();
            controller.init();

            // Test Save Property Owner
            BIGPortalPropertyOwnerController propertyOwnerController = new BIGPortalPropertyOwnerController();
            propertyOwnerController.building = controller.building;
            propertyOwnerController.dwellingUnit = controller.dwellingUnit;
            propertyOwnerController.setpropertyOwner(controller.propertyOwner);
            propertyOwnerController.getStates();
            propertyOwnerController.displayInfo();
            propertyOwnerController.getPropertyOwner().FirstName = 'Test';
            propertyOwnerController.getPropertyOwner().LastName = 'Changed';
            propertyOwnerController.savePropertyOwner();

            // Test Save Utility Account
            BIGPortalUtilityAccountController utilityAccountController = new BIGPortalUtilityAccountController();
            utilityAccountController.building = controller.building;
            utilityAccountController.dwellingUnit = controller.dwellingUnit;
            utilityAccountController.setUtilityAccount(controller.utilityAccount);
            utilityAccountController.getUtilityAccount().Electric_Provider__c = 'Pacific Gas and Electric Company';
            utilityAccountController.getUtilityAccount().Electric_Account_Number__c = '7576575756';
            utilityAccountController.getUtilityAccount().Gas_Provider__c = 'Pacific Gas and Electric Company';
            utilityAccountController.getUtilityAccount().Gas_Account_Number__c = '1231213213';
            utilityAccountController.saveUtilityAccount();

            // Action = edit
            ApexPages.currentPage().getParameters().put('id', building.Id);
            ApexPages.currentPage().getParameters().put('action', 'edit');
            controller = new BIGPortalManageBuildingController();
            controller.init();
            System.debug('##### ' + controller.building);
            System.debug('##### ' + ApexPages.currentPage().getUrl());
            controller.editBuilding();
            System.debug('************************' + controller.saveBuilding());
            System.debug('##################' + ApexPages.getMessages() );

            // Action = new
            ApexPages.currentPage().getParameters().put('id', building.Id);
            ApexPages.currentPage().getParameters().put('action', 'new');
            controller = new BIGPortalManageBuildingController();
            controller.init();
            controller.saveBuilding();

            // *** BUILDINGS 2-4 Units
            // Action = detail
            ApexPages.currentPage().getParameters().put('id', building2To4Units.Id);
            ApexPages.currentPage().getParameters().put('action', 'detail');
            controller = new BIGPortalManageBuildingController();
            controller.init();
            controller.createNewDwellingUnit();
            controller.saveNewDwellingUnit();

            // Action = edit
            ApexPages.currentPage().getParameters().put('id', building2To4Units.Id);
            ApexPages.currentPage().getParameters().put('action', 'edit');
            controller = new BIGPortalManageBuildingController();
            controller.init();
            controller.saveBuilding();

            // Action = new
            ApexPages.currentPage().getParameters().put('id', building2To4Units.Id);
            ApexPages.currentPage().getParameters().put('action', 'new');
            controller = new BIGPortalManageBuildingController();
            controller.init();
            controller.saveBuilding();

            // ### Test Buildings List ###
            BIGPortalBuildingsListController buildingListController = new BIGPortalBuildingsListController();
            buildingListController.setAccountId(controller.accountId);
            System.assert(buildingListController.getAccountId() == controller.accountId);
            System.assertEquals(2, buildingListController.getBuildings().size());
            System.assert(buildingListController.getJSONBuildings() != null);
            System.assert(buildingListController.getNumberOfPages() > 0);
            System.assert(buildingListController.getPageItems().size() > 0);
            // Change sorting direction on the list
            buildingListController.pageNumber = 1;
            buildingListController.orderBy = 'Building_Name__c';
            buildingListController.toggleDirection();

            // Call other public methods
            controller.getShowAdditionalInfo();
        }

        test.stopTest();
    }

    static testMethod void testBIGPortalDwellingUnit() {
        initData();

        test.startTest();

        System.runAs(portalUser) {
            BIGPortalDwellingUnitController controller = new BIGPortalDwellingUnitController();

            controller.building = building;
            controller.setDwellingUnit(dwellingUnit);
            Dwelling_Unit__c testDwellingUnit = controller.getDwellingUnit();

            System.assertNotEquals(testDwellingUnit, null);
            System.assertNotEquals(building, null);
            controller.saveDwellingUnit();
        }

        test.stopTest();
    }

    /**
     * Test Program Acces behavior when you don't have access to HU or AHU program.
     */
    static testMethod void testNotHUOrAHUPortalProgramAccess() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        update portalContact;

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGPortalManageBuilding);
            BIGPortalManageBuildingController controller = new BIGPortalManageBuildingController();

            Test.startTest();
            PageReference accessDenied = controller.init();
            Test.stopTest();

            System.assertEquals(Page.AccessDenied.getUrl(), accessDenied.getUrl());
        }
    }

}