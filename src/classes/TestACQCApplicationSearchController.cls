/*
 * This class contains unit tests for validating the behavior of the ACQCApplicationSearchController class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 *
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2017-12
 */
@isTest
private class TestACQCApplicationSearchController {
    private static User portalUser;
    private static Contact portalContact;
    private static Account portalAccount;
    private static Account bigAccount;
    private static PageReference pageRef;
    private static Decimal pageNumber = 1;
    private static Decimal pageSize = 10;

    private static void initData() {
        // Create the Portal User's Account.
        portalAccount = BIGPortalTestUtils.createAccount('portalAccount');
        insert portalAccount;
        System.assertNotEquals(null, portalAccount.Id);
        // Create Build It Green's Account.
        bigAccount = BIGPortalTestUtils.createAccount('Build It Green');
        insert bigAccount;
        System.assertNotEquals(null, bigAccount.Id);
        // Create Contact.
        portalContact = BIGPortalTestUtils.createContact('portalContact' , 'portalContact', 'portalContact@test.com',
                '703-555-5555', portalAccount.Id);
        portalContact.Program_Enrollment__c = 'ACQC';
        insert portalContact;
        System.assertNotEquals(null, portalContact.Id);
        // Create Portal User
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];
        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = portalContact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);
        // Create Sites.
        List<Site__c> sites = new List<Site__c>();
        Site__c siteOne = BIGPortalTestUtils.createSite('Site One', '1234 Street Aven', '90001', portalAccount);
        siteOne.City__c = 'City';
        siteOne.State__c = 'CA';
        sites.add(siteOne);
        Site__c siteTwo = BIGPortalTestUtils.createSite('Site Two', '1234 Kingshighway', '90002', portalAccount);
        siteTwo.City__c = 'Manteca';
        siteTwo.State__c = 'CA';
        sites.add(siteTwo);
        Site__c siteThree = BIGPortalTestUtils.createSite('Site Three', '1233 Zullivan Street', '90003', portalAccount);
        siteThree.City__c = 'San Diego';
        siteThree.State__c = 'CA';
        sites.add(siteThree);
        insert sites;
        // Create Units.
        List<Unit__c> units = new List<Unit__c>();
        Unit__c unitOne = BIGPortalTestUtils.createUnit('Unit One', 'Test Make', 'Test Model', siteOne);
        units.add(unitOne);
        Unit__c unitTwo = BIGPortalTestUtils.createUnit('Unit Two', 'Test Make', 'Test Model', siteTwo);
        units.add(unitTwo);
        Unit__c unitThree = BIGPortalTestUtils.createUnit('Unit Three', 'Test Make', 'Test Model', siteThree);
        units.add(unitThree);
        insert units;
        // Create Applications.
        List<Application__c> applications = new List<Application__c>();
        Application__c appOne = BIGPortalTestUtils.createApplication(
                Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('ACQC').getRecordTypeId());
        appOne.Dwelling_Unit_Name__c = siteOne.Name;
        appOne.Dwelling_Unit_Street_Address__c = siteOne.Address_1__c;
        appOne.Building_Name__c = siteOne.Name;
        appOne.Building_Street_Address__c = siteOne.Address_1__c;
        appOne.Building_City__c = siteOne.City__c;
        appOne.Building_State__c = siteOne.State__c;
        appOne.Building_Zip_Code__c = siteOne.Zip__c;
        appOne.Unit__c = unitOne.Id;
        applications.add(appOne);
        Application__c appTwo = BIGPortalTestUtils.createApplication(
                Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('ACQC').getRecordTypeId());
        appTwo.Dwelling_Unit_Name__c = siteTwo.Name;
        appTwo.Dwelling_Unit_Street_Address__c = siteTwo.Address_1__c;
        appTwo.Building_Name__c = siteTwo.Name;
        appTwo.Building_Street_Address__c = siteTwo.Address_1__c;
        appTwo.Building_City__c = siteTwo.City__c;
        appTwo.Building_State__c = siteTwo.State__c;
        appTwo.Building_Zip_Code__c = siteTwo.Zip__c;
        appTwo.Unit__c = unitTwo.Id;
        applications.add(appTwo);
        Application__c appThree = BIGPortalTestUtils.createApplication(
                Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('ACQC').getRecordTypeId());
        appThree.Dwelling_Unit_Name__c = siteThree.Name;
        appThree.Dwelling_Unit_Street_Address__c = siteThree.Address_1__c;
        appThree.Building_Name__c = siteThree.Name;
        appThree.Building_Street_Address__c = siteThree.Address_1__c;
        appThree.Building_City__c = siteThree.City__c;
        appThree.Building_State__c = siteThree.State__c;
        appThree.Building_Zip_Code__c = siteThree.Zip__c;
        appThree.Unit__c = unitThree.Id;
        applications.add(appThree);
        // Create a fourth application that will contain no measures.
        Application__c appFourth = BIGPortalTestUtils.createApplication(
                Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('ACQC').getRecordTypeId());
        appFourth.Dwelling_Unit_Name__c = siteTwo.Name;
        appFourth.Dwelling_Unit_Street_Address__c = siteTwo.Address_1__c;
        appFourth.Building_Name__c = siteTwo.Name;
        appFourth.Building_Street_Address__c = siteTwo.Address_1__c;
        appFourth.Building_City__c = siteTwo.City__c;
        appFourth.Building_State__c = siteTwo.State__c;
        appFourth.Building_Zip_Code__c = siteTwo.Zip__c;
        appFourth.Unit__c = unitTwo.Id;
        applications.add(appFourth);
        insert applications;
        // Create Rebate Types.
        List<Rebate_Type__c> rebateTypes = new List<Rebate_Type__c>();
        Rebate_Type__c rebateTK10 = BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 250, 'TK10',
                'Replacement Blower Motor');
        rebateTypes.add(rebateTK10);
        Rebate_Type__c rebateTK12 = BIGPortalTestUtils.createRebateType('One-year QM Service Agreement', 50, 'TK12',
                'One-year QM Service Agreement');
        rebateTypes.add(rebateTK12);
        Rebate_Type__c rebateH796 = BIGPortalTestUtils.createRebateType('Enhanced Time Delay Relay', 70, 'H796',
                'Enhanced Time Delay Relay');
        rebateTypes.add(rebateH796);
        insert rebateTypes;
        // Create Measures. Add one measure to appOne, appTwo, and appThree.
        List<Measure__c> measures = new List<Measure__c>();
        Measure__c measureTK10 = BIGPortalTestUtils.createACQCMeasure(rebateTK10.Name, appOne.Id, rebateTK10.Id,
                rebateTK10.Measure_Code__c);
        measures.add(measureTK10);
        Measure__c measureTK12 = BIGPortalTestUtils.createACQCMeasure(rebateTK12.Name, appTwo.Id, rebateTK12.Id,
                rebateTK12.Measure_Code__c);
        measures.add(measureTK12);
        Measure__c measureH796 = BIGPortalTestUtils.createACQCMeasure(rebateH796.Name, appThree.Id, rebateH796.Id,
                rebateH796.Measure_Code__c);
        measures.add(measureH796);
        insert measures;
    }

    static testMethod void testCheckUserAccess() {
        initData();

        System.runAs(portalUser) {
            // Instantiate page Controller.
            ACQCApplicationSearchController controller = new ACQCApplicationSearchController();
            // Set user's program access to Home Upgrade only.
            portalContact.Program_Enrollment__c = 'HU';
            update portalContact;
            pageRef = controller.checkUserAccess();

            Test.startTest();
            System.assertEquals(Page.AccessDenied.getUrl(), pageRef.getUrl());
            Test.stopTest();
        }
    }

    static testMethod void testGetAccount() {
        initData();

        System.runAs(portalUser) {
            Id accountId = ACQCApplicationSearchController.getAccount();

            Test.startTest();
            System.assertEquals(portalContact.AccountId, accountId);
            Test.stopTest();
        }
    }

    static testMethod void testGetAddressesAndGetApplications() {
        initData();

        System.runAs(portalUser) {
            // Instantiate page Controller.
            ACQCApplicationSearchController controller = new ACQCApplicationSearchController();
            pageRef = controller.checkUserAccess();
            Test.startTest();
            // Check that the user has access to the page. There shouldn't be any redirect.
            System.assertEquals(null, pageRef);
            /***** First Case: Search with a generic input. We are expecting three suggested inputs. ******/
            // Simulate user input.
            String userInput = '123';
            List<String> addresses = new List<String>();
            addresses = ACQCApplicationSearchController.getAddresses(userInput);
            System.assertEquals(3, addresses.size());
            // Verify that the suggested addresses are being displayed alphabetically by street address.
            System.assertEquals('1233 Zullivan Street, San Diego 90003', addresses.get(0));
            System.assertEquals('1234 Kingshighway, Manteca 90002', addresses.get(1));
            System.assertEquals('1234 Street Avenue, City 90001', addresses.get(2));

            /***** Second Case: Search with an address that contains a street suffix. We are expecting one suggested
                   address. ******/
            // Simulate user input.
            userInput = '1234 Street Ave';
            addresses = ACQCApplicationSearchController.getAddresses(userInput);
            System.assertEquals(1, addresses.size());
            System.assertEquals('1234 Street Avenue, City 90001', addresses.get(0));
            // Let's simulate that the user selected the only suggested address.
            String address = addresses.get(0);
            ACQCApplicationSearchController.ApplicationListWrapper appWrapper =
                    new ACQCApplicationSearchController.ApplicationListWrapper();
            appWrapper = ACQCApplicationSearchController.getApplications(address, pageNumber, pageSize);
            // Check that there is only one application for the selected address.
            System.assertEquals(1, appWrapper.applications.size());
            System.assertEquals(1, appWrapper.totalRecords);

            /***** Third Case Case: Search with an address that doesn't contain a street suffix. We are expecting to get
                   the same suggested address as in the previous case, but without including the street suffix in the
                   search input. ******/
            userInput = '1234 Street';
            addresses = ACQCApplicationSearchController.getAddresses(userInput);
            System.assertEquals(1, addresses.size());
            System.assertEquals('1234 Street Avenue, City 90001', addresses.get(0));
            // Let's simulate that the user selected the only suggested address.
            address = addresses.get(0);
            appWrapper = ACQCApplicationSearchController.getApplications(address, pageNumber, pageSize);
            // Check that there is only one application for the selected address.
            System.assertEquals(1, appWrapper.applications.size());
            System.assertEquals(1, appWrapper.totalRecords);
            /***** Fourth Case: Search with a city. We are expecting one suggested address. Also verify that we only
                   obtain one result, since the application with no measures will be filtered out. ******/
            userInput = 'Manteca';
            addresses = ACQCApplicationSearchController.getAddresses(userInput);
            System.assertEquals(1, addresses.size());
            System.assertEquals('1234 Kingshighway, Manteca 90002', addresses.get(0));
            // Let's simulate that the user selected the only suggested address.
            address = addresses.get(0);
            appWrapper = ACQCApplicationSearchController.getApplications(address, pageNumber, pageSize);
            // Check that there is only one application for the selected address.
            System.assertEquals(1, appWrapper.applications.size());
            System.assertEquals(1, appWrapper.totalRecords);
            Test.stopTest();
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
            Test.setCurrentPage(Page.ACQCApplicationSearch);
            BIGPortalHVACDashboardController controller = new BIGPortalHVACDashboardController();

            Test.startTest();
            PageReference accessDenied = controller.checkUserAccess();
            Test.stopTest();

            System.assertEquals(Page.AccessDenied.getUrl(), accessDenied.getUrl());
        }
    }

}