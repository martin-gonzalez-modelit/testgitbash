/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
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
 */
@isTest
private class HPXMLTest {

    private static User portalUser;
    private static Account contractor;
    private static Contact contact;
    private static Application__c application;
    private static Sub_Application__c subApplication;
    private static Utility_Account__c utilityAccount;
    private static Application_File__c applicationFile;
    private static Attachment attachment;
    private static Boolean isPostApplication;
    public static HPXML entry;
    // Fill place holder where there are curly brackets
    private static String[] fillers = new String[]{'5644.96', '191.9349077', '632.6325894', '764.222735', '2004.6',
            '1031.6', '3800.392503', '579.5676239', '459.0218463', '163.50543', '163.50543',
            '4624.96', '191.9349077', '632.6325894', '764.222735', '2004.6', '1031.6', '3800.392503', '579.5676239',
            '359.0218463', '163.50543', '163.50543'};

    /**
     * Initialize Data for the tests
     */
    private static void initData() {
        // Create Account
        contractor =  BIGPortalTestUtils.createAccount('portalAccount');
        contractor.Tax_ID_Number__c = '123456789';
        contractor.Zip__c = '93240';
        contractor.BillingStreet = 'Test';
        contractor.BillingCity = 'San Jose';
        contractor.BillingState = 'CA';
        contractor.BillingPostalCode = '12345';
        contractor.BillingCountry = 'USA';
        contractor.OwnerId = UserInfo.getUserId();
        insert contractor;
        System.assertNotEquals(null, contractor.Id);

        // Create Contact
        contact = BIGPortalTestUtils.createContact('portalContact' , 'portalContact',
                                                    'portalContact@test.com', '703-555-5555',
                                                    contractor.Id);
        contact.OwnerId = UserInfo.getUserID();
        insert contact;
        System.assertNotEquals(null, contact.Id);

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = contact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);

        // Create Supported Software
        Software_Version__c newSW = new Software_Version__c();
        newSW.Name = 'Snugg Pro';
        insert newSW;

        Software_Version__c softwareVersion = new Software_Version__c();
        softwareVersion.Name='CakeSystems';
        insert softwareVersion;

        // Create Building
        Building__c building = BIGPortalTestUtils.createBuilding('Joe Doe Building', 'Single Family Detached',
                'Building Street Address', 'Building City', 'CA', '22180', 'Building County',
                contractor.Id);

        insert building;

        // Create Contact as Property Owner
        Contact propertyOwner = BIGPortalTestUtils.createContact('Property Owner', 'Property Owner',
                'propertyOwner@test.com', '703-222-2222', 'Street Avenue', 'Palo Alto', 'CA', '12345',
                contractor.Id);
        insert propertyOwner;

        // Create Dwelling Unit
        Dwelling_Unit__c dwelling = BIGPortalTestUtils.createDwellingUnit('DW Street Address', '10', propertyOwner.Id,
                building.Id, Decimal.valueOf(3), Decimal.valueOf(6), Decimal.valueOf(2), Decimal.valueOf(4),
                '2000', 'Vented Attic', Decimal.valueOf(10), 'Room AC', Decimal.valueOf(20),
                'Slab-On-Grade', 'Room AC', 'Electricity', 'Storage Water Heater', 'Electricity', 'Solar PV');
        insert dwelling;

        // Create Utility Account with Gas provider = Pacific Gas and Electric Company
        utilityAccount = BIGPortalTestUtils.createUtilityAccount('the', 'tester', '(123) 123-3242',
                'Pacific Gas and Electric Company', '8998988909', 'Pacific Gas and Electric Company',
                '1231213213', dwelling.Id);
        insert utilityAccount;

        application = new Application__c();
        BIGPortalTestUtils.setApplicationSubmittedRequiredFields(application);
        application.RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE;
        application.Dwelling_Unit__c = dwelling.Id;
        application.Has_Conditioned_Area_Changed__c = 'Yes';
        application.Post_Conditioned_Area__c = Decimal.valueOf(800);
        insert application;

        // Create Sub Application
        subApplication = new Sub_Application__c();
        subApplication.Application__c = application.Id;
        subApplication.RecordTypeId = Schema.SObjectType.Sub_Application__c.getRecordTypeInfosByName().get(
                'POST-APP').getRecordTypeId();
        subApplication.Completed_Package_Cost__c = 9000;
        subApplication.Proposed_Package_Cost__c = 9000;
        insert subApplication;

        // Create Application File
        applicationFile = new Application_File__c();
        applicationFile.Application__c = application.Id;
        applicationFile.Sub_Application__c = subApplication.Id;
        insert applicationFile;

        // Create Attachment
        attachment = new Attachment();
        attachment.Name = 'HPXML file';
        attachment.Body = Blob.valueOf('Unit Test Attachment Body');
        attachment.parentid = applicationFile.Id;
        insert attachment;

        // Create Kickers for KWh and Therm
        List<Kickers__c> kickersCustom = new List<Kickers__c>();
        kickersCustom.add(new Kickers__c(Name='kWh Kicker', Value__c=0.75));
        kickersCustom.add(new Kickers__c(Name='Therm Kicker', Value__c=2.00));
        insert kickersCustom;

        List<Zip_Code__mdt> zipCodeData = BIGPortalTestUtils.getZipCodeData(new List<String> {'93240'});
        BIGPortalTestUtils.createCustomSetting();
        BIGPortalTestUtils.createRebateTiersCustomSettings();
    }

    /**
     * Verify that Incentive Amounts are positive values or zero for XML End Uses. For XML End Use incentive amounts
     * that result into negative values after the XML parsing, these values should be set to zero.
     */
    static testMethod void testXMLEndUseIncentiveAmounts() {
        initData();

        System.runAs(portalUser) {
            application.Gas_Provider__c = 'Propane';
            application.Status__c = ApplicationUtils.POST_INSTALL_CREATED_STATUS;
            update application;
            // Set Gas Provider to SoCalGas
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            fillers = new String[]{'12782.41', '202.9562314', '7225.583534', '1981.243768', '2274.45', '1098.176467',
                    '5353.870235', '562.8056307', '423.3767539', '139.4288768', '139.4288768', '7241.569159',
                    '207.8862202', '1679.812704', '1981.243768', '2274.45', '1098.177308', '5353.871076',
                    '583.8310742', '444.4021974', '139.4288768', '139.4288768'};

            Test.startTest();
            // Process HPXML that has negative values for incentive amount and set isPostApp to true
            XMLStreamReader xmlReader = new XMLStreamReader(BIGPortalTestUtils.returnHPXMLPostBody(fillers));
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            List<XML_End_Use__c> xmlEndUses = [
                SELECT Item_Incentive_Amount__c, Adjusted_Energy_Savings_Percent__c
                FROM XML_End_Use__c
                WHERE Sub_Application__r.Id = :subApplication.Id
                ];

            /* Check for each Xml End Use that Incentive Amount was changed into 0
             * for Adjusted_Energy_Savings_Percent__cor negative, and greater than it if it is positive
             */
            for (XML_End_Use__c xmlEndUse :xmlEndUses) {
                if (xmlEndUse.Adjusted_Energy_Savings_Percent__c < 0) {
                    System.assert(xmlEndUse.Item_Incentive_Amount__c == 0);
                } else {
                    System.assert(xmlEndUse.Item_Incentive_Amount__c >= 0);
                }
            }
        }
    }

    /**
     * Check it use structure 1 for Gas Provider = SoCalGas. Before the Pre/Post-install structure change
     */
    static testMethod void testStructureGasProviderSoCalGasBeforeAugPrePost() {
        initData();

        System.runAs(portalUser) {
            application.Gas_Provider__c = 'Southern California Gas Company';
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('6/24/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('7/25/2016');
            update subApplication;
            // Set Gas Provider to SoCalGas
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            Test.startTest();
            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillers));
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            // Get last update from application and subApplication
            application = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id})).get(0);
            subApplication = (BIGPortalTestUtils.getSubApplicationsById(new Set<Id>{subApplication.Id})).get(0);

            // Check that structure used was 1 for that the Rebate_from_Tier__c and Total_Incentive_from_Tier__c = 350
            System.assertEquals(350.00, application.Rebate_from_Tier__c);
            System.assertEquals(350.00, subApplication.Total_Incentive_from_Tier__c);
        }
    }

    /**
     * Check it use structure 2 for Gas Provider = SoCalGas. After the Pre-install structure change
     */
    static testMethod void testStructureGasProviderSoCalGasAfterAugPrePost() {
        initData();

        System.runAs(portalUser) {
            application.Gas_Provider__c = 'Southern California Gas Company';
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('9/24/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('9/25/2016');
            update subApplication;
            // Set Gas Provider to SoCalGas
            utilityAccount.Gas_Provider__c = 'Southern California Gas Company';
            update utilityAccount;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            Test.startTest();
            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillers));
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            // Get last update from application and subApplication
            application = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id})).get(0);
            subApplication = (BIGPortalTestUtils.getSubApplicationsById(new Set<Id>{subApplication.Id})).get(0);

            // Check that structure used was 2 for that the Rebate_from_Tier__c and Total_Incentive_from_Tier__c = 200
            System.assertEquals(200.00, application.Rebate_from_Tier__c);
            System.assertEquals(200.00, subApplication.Total_Incentive_from_Tier__c);
        }
    }

    /**
     * Check it use structure 2 for Gas Provider = SoCalGas. Before the Pre-install structure change and
     * after the Post-install structure change
     */
    static testMethod void testStructureGasProviderSoCalGasBeforAugAfterNovPrePost() {
        initData();

        System.runAs(portalUser) {
            application.Gas_Provider__c = 'Southern California Gas Company';
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('6/24/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('11/25/2016');
            update subApplication;
            // Set Gas Provider to SoCalGas
            utilityAccount.Gas_Provider__c = 'Southern California Gas Company';
            update utilityAccount;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            Test.startTest();
            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillers));
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            // Get last update from application and subApplication
            application = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id})).get(0);
            subApplication = (BIGPortalTestUtils.getSubApplicationsById(new Set<Id>{subApplication.Id})).get(0);

            // Check that structure used was 2 for that the Rebate_from_Tier__c and Total_Incentive_from_Tier__c = 200
            System.assertEquals(200.00, application.Rebate_from_Tier__c);
            System.assertEquals(200.00, subApplication.Total_Incentive_from_Tier__c);
        }
    }

    /**
     * Check it use structure 1 for Gas Provider = SoCalGas. Before the Pre/Post-install structure change
     */
    static testMethod void testStructureGasProviderSoCalGasBeforAugBeforeNovPrePost() {
        initData();

        System.runAs(portalUser) {
            application.Gas_Provider__c = 'Southern California Gas Company';
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('6/24/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('10/25/2016');
            update subApplication;
            // Set Gas Provider to SoCalGas
            utilityAccount.Gas_Provider__c = 'Southern California Gas Company';
            update utilityAccount;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            Test.startTest();
            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillers));
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            // Get last update from application and subApplication
            application = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id})).get(0);
            subApplication = (BIGPortalTestUtils.getSubApplicationsById(new Set<Id>{subApplication.Id})).get(0);

            // Check that structure used was 1 for that the Rebate_from_Tier__c and Total_Incentive_from_Tier__c = 350
            System.assertEquals(350.00, application.Rebate_from_Tier__c);
            System.assertEquals(350.00, subApplication.Total_Incentive_from_Tier__c);
        }
    }

    /**
     * Check it use structure 1, before the Pre-install structure change
     */
    static testMethod void testStructureAppSubmissionDateBeforeMay() {
        initData();

        System.runAs(portalUser) {
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('4/25/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('4/25/2016');
            update subApplication;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            Test.startTest();
            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillers));
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            // Get last update from Application and SubApplication
            application = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id})).get(0);
            subApplication = (BIGPortalTestUtils.getSubApplicationsById(new Set<Id>{subApplication.Id})).get(0);

            // Check that structure used was 1 for that the Rebate_from_Tier__c and Total_Incentive_from_Tier__c = 350
            System.assertEquals(350.00, application.Rebate_from_Tier__c);
            System.assertEquals(350.00, subApplication.Total_Incentive_from_Tier__c);
        }
    }

    /**
     * Check it use structure 2, after the Pre-install structure change
     */
    static testMethod void testStructureAppSubmissionDateAfterMay() {
        initData();

        System.runAs(portalUser) {
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('5/25/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('5/25/2016');
            update subApplication;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            Test.startTest();
            // Process HPXML and set isPostApp to false
            XmlStreamReader xmlReader = new xmlStreamReader(BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillers));
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            // Get last update from Application and SubApplication
            application = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id})).get(0);
            subApplication = (BIGPortalTestUtils.getSubApplicationsById(new Set<Id>{subApplication.Id})).get(0);

            // Check that structure used was 2 for that the Rebate_from_Tier__c and Total_Incentive_from_Tier__c = 200
            System.assertEquals(200.00, application.Rebate_from_Tier__c);
            System.assertEquals(200.00, subApplication.Total_Incentive_from_Tier__c);
        }
    }

    /**
     * Check it use structure 1, before the Pre/Post-install structure change
     */
    static testMethod void testStructureAppSubmissionDateBeforeAugust() {
        initData();

        System.runAs(portalUser) {
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('4/25/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('6/25/2016');
            update subApplication;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            Test.startTest();
            // Process HPXML and set isPostApp to true
            List<String> errors = controller.processHPXML(
                    new XMLStreamReader(BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillers)), true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            // Get last update from Application and SubApplication
            application = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id})).get(0);
            subApplication = (BIGPortalTestUtils.getSubApplicationsById(new Set<Id>{subApplication.Id})).get(0);

            // Check that structure used was 1 for that the Rebate_from_Tier__c and Total_Incentive_from_Tier__c = 350
            System.assertEquals(350.00, application.Rebate_from_Tier__c);
            System.assertEquals(350.00, subApplication.Total_Incentive_from_Tier__c);
        }
    }

    /**
     * Check it use structure 2, before the Pre-install structure change and after the Post-install structure change
     */
    static testMethod void testStructureAppSubmissionDateAfterAugustPost() {
        initData();

        System.runAs(portalUser) {
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('4/25/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('9/25/2016');
            update subApplication;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            Test.startTest();
            // Process HPXML and set isPostApp to true
            List<String> errors = controller.processHPXML(
                    new XMLStreamReader(BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillers)), true);
            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            // Get last update from Application and SubApplication
            application = (BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id})).get(0);
            subApplication = (BIGPortalTestUtils.getSubApplicationsById(new Set<Id>{subApplication.Id})).get(0);

            // Check that structure used was 2 for that the Rebate_from_Tier__c and Total_Incentive_from_Tier__c = 200
            System.assertEquals(200.00, application.Rebate_from_Tier__c);
            System.assertEquals(200.00, subApplication.Total_Incentive_from_Tier__c);
        }
    }

    /**
     * Check processHPXML method
     */
    static testMethod void testProcessHPXML() {
        initData();

        System.runAs(portalUser) {
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;
            Boolean isPostAppStatus = false;

            // Fill place holder where there are curly brackets
            List<String> fillerForPlaceHolders = new List<String>{'4624.96', '191.9349077', '579.5676239',
                    '359.0218463', '4620.96', '187.9349077', '574.5676239', '354.0218463'};
            String xmlString = String.format(BIGPortalTestUtils.returnHPXMLPreBody(fillerForPlaceHolders),
                    fillerForPlaceHolders);

            //create a stream reader
            XMLStreamReader xmlReader = new XMLStreamReader(xmlString);

            Test.startTest();
            List<String> errors = controller.processHPXML(xmlReader, isPostAppStatus);
            Test.stopTest();

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());
        }
    }

    /**
     * Check for a SoftwareProgramUsed that is not inserted as Software version
     */
    static testMethod void testInvalidSupportedSoftware() {
        initData();

        System.runAs(portalUser) {
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;
            Boolean isPostAppStatus = false;

            // Create a xml that has A1SoftwareProgramUsedAA as SoftwareProgramUsed, it is not in software version
            String xmlString = '<?xml version="1.0" encoding="utf-8"?><!--========================= Base ===========' +
                    '===============--><HPXML schemaVersion="2.1" xmlns="http://hpxmlonline.com/2014/6">' +
                    '<XMLTransactionHeaderInformation><XMLType>HPXML</XMLType><XMLGeneratedBy>OptiMiser 2.0.0/4510' +
                    '</XMLGeneratedBy><CreatedDateAndTime>2015-04-20T14:26:54</CreatedDateAndTime><Transaction>' +
                    'create</Transaction></XMLTransactionHeaderInformation><SoftwareInfo><SoftwareProgramUsed>' +
                    'A1SoftwareProgramUsedAA</SoftwareProgramUsed><SoftwareProgramVersion>2</SoftwareProgramVersion>' +
                    '</SoftwareInfo></HPXML>';

            // create a stream reader
            XMLStreamReader xmlReader = new XMLStreamReader(xmlString);

            Test.startTest();
            List<String> errors = controller.processHPXML(xmlReader, isPostAppStatus);
            Test.stopTest();

            // errors should have only one value added for invalid supported software
            System.assertEquals('Software is not supported.', errors.get(0));
        }
    }

    /**
     * Check for a SoftwareProgramUsed that is inserted as Software version
     */
    static testMethod void testValidSupportedSoftware() {
        initData();

        System.runAs(portalUser) {
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;
            Boolean isPostAppStatus = false;

            // Fill place holder where there are curly brackets
            List<String> fillerForPlaceHolders = new List<String>{'4624.96', '191.9349077', '579.5676239',
                    '359.0218463', '4620.96', '187.9349077', '574.5676239', '354.0218463'};
            String xmlString = String.format(BIGPortalTestUtils.returnHPXMLPreBody(fillerForPlaceHolders),
                    fillerForPlaceHolders);

            // create a stream reader
            XMLStreamReader xmlReader = new XMLStreamReader(xmlString);

            Test.startTest();
            List<String> errors = controller.processHPXML(xmlReader, isPostAppStatus);
            Test.stopTest();

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());
        }
    }

    static testMethod void testVersionCompare() {
        initData();

        System.runAs(portalUser) {
            HPXMLParser controller = new HPXMLParser();
            String string1 = '1.0';
            String string2 = '1.0';

            Test.startTest();
            Integer result = controller.versionCompare(string1, string2);
            Test.stopTest();

            System.assertEquals(result, 0);
        }
    }

    /**
     * CHeck validateHPXML method
     */
    static testMethod void testValidateHPXML() {
        initData();

        System.runAs(portalUser) {
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            application = new Application__c();
            subApplication = new Sub_Application__c();
            Boolean isPostAppStatus = true;

            // Create a new HPXML and set all data
            entry = new HPXML(application, subApplication, isPostAppStatus, false);
            entry.customer = new HPXML.Customer();
            entry.customer.FirstName = NULL;
            entry.customer.LastName = NULL;

            entry.businesscontact = new HPXML.BusinessContact();
            entry.businesscontact.FirstName = NULL;
            entry.businesscontact.LastName = NULL;
            entry.businesscontact.Email = NULL;

            entry.software = new HPXML.Software();
            entry.software.SoftwareProgramUsed = 'Snugg Pro';
            entry.software.SoftwareProgramVersion = '5.0.0';

            List<HPXML.Building> buildings = new List<HPXML.Building>();

            entry.building = new HPXML.Building();
            entry.building.SystemIdentifier = 'Bldg1';
            entry.building.Address1 = NULL;
            entry.building.CityMunicipality = NULL;
            entry.building.StateCode = NULL;
            entry.building.ZipCode = NULL;
            entry.building.ProjectStatus = 'audit';
            entry.building.NumberofResidents = 0;
            entry.building.YearBuilt = 1995;
            entry.building.ResidentialFacilityType = NULL;
            entry.building.NumberOfBedrooms = 0;
            entry.building.ConditionedFloorArea = 0;
            entry.building.NumberofStoriesAboveGrade = 0;
            entry.building.AverageCeilingHeight = 0;
            buildings.add(entry.building);
            entry.buildings.add(entry.building);

            entry.building = new HPXML.Building();
            entry.building.SystemIdentifier = 'Bldg2';
            entry.building.Address1 = NULL;
            entry.building.CityMunicipality = NULL;
            entry.building.StateCode = NULL;
            entry.building.ZipCode = NULL;
            entry.building.ProjectStatus = 'retrofit';
            entry.building.NumberofResidents = 0;
            entry.building.YearBuilt = 1995;
            entry.building.ResidentialFacilityType = NULL;
            entry.building.NumberOfBedrooms = 0;
            entry.building.ConditionedFloorArea = 0;
            entry.building.NumberofStoriesAboveGrade = 0;
            entry.building.AverageCeilingHeight = 0;
            buildings.add(entry.building);
            entry.buildings.add(entry.building);
            entry.aim = new HPXML.AirInfiltrationMeasurement();
            entry.aim.BuildingId = 'Bldg1';
            entry.aim.TypeOfInfiltrationMeasurement = NULL;
            entry.xmltransactionheaderinfo = new HPXML.XMLTransactionHeaderInfo();

            Test.startTest();

            HPXMLParser.ValidateHPXMLWrapper validateHpxml = new HPXMLParser.ValidateHPXMLWrapper();

            validateHPXML.customer = entry.customer;
            validateHPXML.businesscontact = entry.businesscontact;
            validateHPXML.software = entry.software;
            validateHPXML.buildings = buildings;
            validateHPXML.aims = new List<HPXML.AirInfiltrationMeasurement>();
            validateHPXML.attics = new List<HPXML.Attic>();
            validateHPXML.foundations = new List<HPXML.Foundation>();
            validateHPXML.measures = new List<HPXML.Measure>();
            validateHPXML.modeledusages = new List<HPXML.ModeledUsage>();
            validateHPXML.heatingsystems = new List<HPXML.HeatingSystem>();
            validateHPXML.coolingsystems = new List<HPXML.CoolingSystem>();
            validateHPXML.waterheatings = new List<HPXML.WaterHeating>();
            validateHPXML.hvaccontrols = new List<HPXML.HVACControl>();
            validateHPXML.lightinggroups = new List<HPXML.LightingGroup>();
            validateHPXML.lightingcontrols = new List<HPXML.LightingControl>();
            validateHPXML.wallinsulations = new List<HPXML.WallInsulation>();
            validateHPXML.componentsList = new List<String>();
            validateHPXML.programsList = new List<String>();
            validateHPXML.fuelsavings = new List<HPXML.FuelSavings>();
            validateHPXML.heatpumps = new List<HPXML.HeatPump>();
            validateHPXML.windows = new List<HPXML.Window>();
            validateHPXML.ducts = new List<HPXML.Duct>();
            validateHPXML.roofs = new List<HPXML.Roof>();
            validateHPXML.ductleakagemeasurements = new List<HPXML.DuctLeakageMeasurement>();
            validateHPXML.pools = new List<HPXML.Pool>();
            validateHPXML.poolpumps = new List<HPXML.PoolPump>();
            validateHPXML.refrigerators = new List<HPXML.Refrigerator>();
            validateHPXML.ventilationfans = new List<HPXML.VentilationFan>();
            validateHPXML.hvacdistributions = new List<HPXML.HVACDistribution>();
            validateHPXML.projects = new List<HPXML.Project>();
            validateHPXML.buildingMap = new Map<String, Set<String>>();
            validateHPXML.hasRetrofit = 0;
            entry.energySavingsInfo = new HPXML.EnergySavingsInfo();
            entry.energySavingsInfo.DemandSavings = '1.25';
            validateHPXML.energySavingsInfo = entry.energySavingsInfo;
            validateHPXML.isPostApp = true;

            List<String> errors = controller.validateHPXML (validateHPXML);

            Test.stopTest();

            // errors should have one value for an error comes up
            System.assertEquals('Building with retrofit status is required.', errors.get(0));
        }
    }

    /**
     * Test 50% cap is not applied to Total Incentive when it is under the cap
     */
    static testMethod void testIncentiveUnderCap50PercentPre() {
        initData();

        System.runAs(portalUser) {
            application.Status__c = ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('9/24/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('9/25/2016');
            // Set Proposed_Package_Cost__c over incentive total (5389.53)
            subApplication.Proposed_Package_Cost__c = 12000;
            update subApplication;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            // Fill place holder where there are curly brackets
            List<String> fillerForPlaceHolders = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};
            String xmlString = BIGPortalTestUtils.returnHPXMLPreBody(fillerForPlaceHolders);

            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(xmlString);
            List<String> errors = controller.processHPXML(xmlReader, false);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            Test.startTest();
            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            subApplication = BIGPortalTestUtils.getSubApplicationsById(new Set<Id> {subApplication.Id}).get(0);

            // Check if there is an adjustment due Proposed_Package_Cost__c
            // is under incentive total for that last one is modified.
            System.assertEquals(5389.53, subApplication.Total_Incentive__c);
            System.assertEquals(0, subApplication.Total_Incentive_Adjustment__c);
        }
    }

    /**
     * Test 50% cap is applied to Total Incentive when it is over the cap
     */
    static testMethod void testIncentiveOverCap50PercentPre() {
        initData();

        System.runAs(portalUser) {
            application.Status__c = ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('9/24/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('9/25/2016');
            // Set Proposed_Package_Cost__c under incentive total (5389.53)
            subApplication.Proposed_Package_Cost__c = 1000;
            update subApplication;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            // Fill place holder where there are curly brackets
            List<String> fillerForPlaceHolders = new List<String>{'74628.96', '7195.9349077', '579.5676239',
                    '359.0218463', '4.9', '1.9','582.5676239','362.0218463'};
            String xmlString = BIGPortalTestUtils.returnHPXMLPreBody(fillerForPlaceHolders);

            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(xmlString);
            List<String> errors = controller.processHPXML(xmlReader, false);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            Test.startTest();
            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            subApplication = BIGPortalTestUtils.getSubApplicationsById(new Set<Id> {subApplication.Id}).get(0);

            // Check if there is an adjustment due Proposed_Package_Cost__c
            // is under incentive total for that last one is modified.
            System.assertEquals(500, subApplication.Total_Incentive__c);
            System.assertEquals(-4889.53, subApplication.Total_Incentive_Adjustment__c);
        }
    }

    /**
     * Test 50% cap is not applied to Total Incentive when it is under the cap
     */
    static testMethod void testIncentiveUnderCap50PercentPost() {
        initData();

        System.runAs(portalUser) {
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('9/24/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('9/25/2016');
            // Set Completed_Package_Cost__c over incentive total (5389.53)
            subApplication.Completed_Package_Cost__c = 12000;
            update subApplication;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            List<String> fillerForPlaceHolders = new List<String>{'74628.96', '7195.9349077', '632.6325894',
                    '764.222735', '2004.6', '1031.6', '3800.392503', '579.5676239', '359.0218463', '163.50543',
                    '163.50543', '4.9', '1.9', '632.6325894', '764.222735', '2004.6', '1031.6', '3800.392503',
                    '582.5676239','362.0218463', '163.50543', '163.50543'};
            String xmlString = BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillerForPlaceHolders);

            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(xmlString);
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            Test.startTest();
            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            subApplication = BIGPortalTestUtils.getSubApplicationsById(new Set<Id> {subApplication.Id}).get(0);

            // Check if there is an adjustment due Completed_Package_Cost__c
            // is under incentive total for that last one is modified.
            System.assertEquals(5389.53, subApplication.Total_Incentive__c);
            System.assertEquals(0, subApplication.Total_Incentive_Adjustment__c);
        }
    }

    /**
     * Test 50% cap is applied to Total Incentive when it is over the cap
     */
    static testMethod void testIncentiveOverCap50PercentPost() {
        initData();

        System.runAs(portalUser) {
            application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
            application.Application_Submission_Date__c = Date.parse('9/24/2016');
            update application;
            subApplication.Initial_Submission_Date__c = Date.parse('9/25/2016');
            // Set Proposed_Package_Cost__c under incentive total (5389.53)
            subApplication.Completed_Package_Cost__c = 1000;
            update subApplication;
            HPXMLParser controller = new HPXMLParser();
            // Set Application and SubApplication on hpxml
            controller.application = application;
            controller.subApplication = subApplication;

            List<String> fillerForPlaceHolders = new List<String>{'74628.96', '7195.9349077', '632.6325894',
                    '764.222735', '2004.6', '1031.6', '3800.392503', '579.5676239', '359.0218463', '163.50543',
                    '163.50543', '2450.9', '2350.1', '632.6325894', '764.222735', '2004.6', '1031.6', '3800.392503',
                    '570.5676239','350.0218463', '163.50543', '163.50543'};
            String xmlString = BIGPortalTestUtils.returnHPXMLPostBodyNaturalGas(fillerForPlaceHolders);

            // Process HPXML and set isPostApp to false
            XMLStreamReader xmlReader = new XMLStreamReader(xmlString);
            List<String> errors = controller.processHPXML(xmlReader, true);

            // Verify that the HPXML was processed correctly
            System.assertEquals(0, errors.size());

            Test.startTest();
            // Here is when XML End Use are created
            controller.entry.analyzeData();
            Test.stopTest();

            subApplication = BIGPortalTestUtils.getSubApplicationsById(new Set<Id> {subApplication.Id}).get(0);

            // Check if there is an adjustment due Completed_Package_Cost__c
            // is under incentive total for that last one is modified.
            System.assertEquals(500, subApplication.Total_Incentive__c);
            System.assertEquals(-3152.38, subApplication.Total_Incentive_Adjustment__c);
        }
    }
}