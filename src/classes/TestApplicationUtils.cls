/**
 * This class contains unit tests for validating apex code in the Application Utils class
 * @author Camilo Herbert   camilo.herbert@modelitsoftware.com
 * @since 2013-12
 */
@isTest
private class TestApplicationUtils {
    private static Account account;
    private static Application__c application;
    private static List<Application__c> applicationListACQC;
    private static List<Application__c> applicationListHU;
    private static List<Application__c> applicationListAHU;
    private static List<Measure__c> measureList =  new List<Measure__c>();
    private static List<Rebate_Type__c> rebateTypesList = new List<Rebate_Type__c>();
    private static List<Measure_Types__mdt> measureTypesList;
    private static Map<Id, Set<Measure__c>> measuresById;
    private static Map<String, Zip_Code__mdt> zipCodes;
    private static final Integer batchSize = 200;
    private static final Integer batchSizeApps = 1;

    private static testMethod void verifyCaptureSubmissionAndApprovals() {
        account = new Account(Name = 'test account666', ACQC_Last_App_Submission_Date__c = null,
                HU_Last_App_Submission_Date__c = Date.Parse('8/10/2014'),
                AHU_Last_App_Submission_Date__c = Date.Parse('8/10/2014'),
                ACQC_Last_App_Approval_Date__c = Date.Parse('8/10/2014'),
                AHU_Last_App_Approval_Date__c = Date.Parse('8/10/2014'),
                HU_Last_App_Approval_Date__c = Date.Parse('8/10/2014') );
        insert account;

        System.assertNotEquals(account.Id, null);
        Test.startTest();
            createNewApplication();
            account = [
                SELECT Id, Name, ACQC_Last_App_Submission_Date__c, HU_Last_App_Submission_Date__c,
                    AHU_Last_App_Submission_Date__c, ACQC_Last_App_Approval_Date__c, AHU_Last_App_Approval_Date__c,
                    HU_Last_App_Approval_Date__c
                FROM Account
                WHERE Id =: account.Id
                ];

            System.assertEquals(applicationListACQC.get(0).Last_Application_Submission_Date__c,
                    account.ACQC_Last_App_Submission_Date__c);
            System.assertEquals(applicationListHU.get(0).Last_Application_Submission_Date__c,
                    account.HU_Last_App_Submission_Date__c);
            System.assertEquals(applicationListAHU.get(0).Preapplication_Submitted__c,
                    account.AHU_Last_App_Submission_Date__c.dateGMT());

            System.assertEquals(applicationListACQC.get(0).Application_Approval_Date__c,
                    account.ACQC_Last_App_Approval_Date__c);
            System.assertEquals(applicationListHU.get(0).Application_Approval_Date__c,
                    account.HU_Last_App_Approval_Date__c);
            System.assertEquals(applicationListAHU.get(0).Full_Application_Approved__c,
                    account.AHU_Last_App_Approval_Date__c);

        Test.stopTest();
    }

    /**
     * Test method for ApplicationUtils.processZipCode().
     * This method uses applications that have a related ZipCode custom metadata record.
     */
    private static testMethod void testProcessZipCodeWithRelatedRecord() {
        createTestData(true);
        Test.startTest();

        for (Application__c applicationACQC : [
                SELECT Building_County__c, Building_Zip_Code__c, Climate_Zone__c
                FROM Application__c
                WHERE Id IN : applicationListACQC]) {
            // Test that the calculated county and climate zone of every ACQC record is correct after insertion
            System.assertEquals(zipCodes.get(String.valueOf(applicationACQC.Building_Zip_Code__c)).County__c,
                    applicationACQC.Building_County__c);
            System.assertEquals(zipCodes.get(String.valueOf(applicationACQC.Building_Zip_Code__c)).Climate_Zone__c,
                    applicationACQC.Climate_Zone__c);
        }

        for (Application__c applicationHU : [
                SELECT Building_County__c, Building_Zip_Code__c, Climate_Zone__c, Customer_Zip_Code__c,
                    Customer_County__c
                FROM Application__c
                WHERE Id IN : applicationListHU]) {
            // Test that the calculated county and climate zone of every HUP record is correct after insertion
            System.assertEquals(zipCodes.get(String.valueOf(applicationHU.Building_Zip_Code__c)).County__c,
                    applicationHU.Building_County__c);
            System.assertEquals(zipCodes.get(String.valueOf(applicationHU.Building_Zip_Code__c)).Climate_Zone__c,
                    applicationHU.Climate_Zone__c);
            System.assertEquals(zipCodes.get(String.valueOf(applicationHU.Customer_Zip_Code__c)).County__c,
                    applicationHU.Customer_County__c);
        }

        // Get a new zip code to test update logic.
        Zip_Code__mdt newZipCode = [
            SELECT Id, Climate_Zone__c, Zip_Code__c, PGE_Territory__c, County__c
            FROM Zip_Code__mdt
            WHERE County__c != null AND Climate_Zone__c != null
            LIMIT 1
            ];
        System.assertNotEquals(null, newZipCode.Id);

        // Change zipcodes for every ACQC record to test update logic.
        for (Application__c applicationACQC : applicationListACQC) {
            applicationACQC.Building_Zip_Code__c = newZipCode.Zip_Code__c;
        }
        // Change zipcodes for every HUP record to test update logic.
        for (Application__c applicationHU : applicationListHU) {
            applicationHU.Building_Zip_Code__c = newZipCode.Zip_Code__c;
            applicationHU.Customer_Zip_Code__c = newZipCode.Zip_Code__c;
        }
        // Update applications.
        List<Application__c> applications = new List<Application__c>(applicationListACQC);
        applications.addAll(applicationListHU);
        update applications;
        Test.stoptest();

        for (Application__c applicationACQC : [
                SELECT Building_County__c, Climate_Zone__c
                FROM Application__c
                WHERE Id IN : applicationListACQC]) {
            // Now, test that the calculated county and climate zone of every ACQC record is correct after updating
            System.assertEquals(applicationACQC.Building_County__c, newZipCode.County__c);
            System.assertEquals(applicationACQC.Climate_Zone__c, newZipCode.Climate_Zone__c);
        }

        for (Application__c applicationHU : [
                SELECT Building_County__c, Climate_Zone__c, Customer_County__c
                FROM Application__c
                WHERE Id IN : applicationListHU]) {
            // Now, test that the calculated county and climate zone of every HUP record is correct after insertion
            System.assertEquals(applicationHU.Building_County__c, newZipCode.County__c);
            System.assertEquals(applicationHU.Climate_Zone__c, newZipCode.Climate_Zone__c);
            System.assertEquals(applicationHU.Customer_County__c, newZipCode.County__c);
        }
    }

    /**
     * Test method for ApplicationUtils.processZipCode().
     * This method uses applications that don't have any related ZipCode custom metadata record.
     */
    private static testMethod void testProcessZipCodeWithoutRelatedRecord() {
        Test.startTest();
        createTestData(false);
        Test.stoptest();

        for (Application__c application : [
            SELECT Building_County__c, Climate_Zone__c, Customer_County__c, RecordType.Name
            FROM Application__c
            WHERE Id IN :applicationListACQC OR Id IN :applicationListHU]) {
            // Every county and climate zone field should be null as there is no related Zip Code Data record.
            System.assertEquals(null, application.Building_County__c);
            System.assertEquals(null, application.Climate_Zone__c);

            if (application.RecordType.Name == 'HU') {
                System.assertEquals(null, application.Customer_County__c);
            }
        }
    }

    private static testMethod void testPopulateIncentiveTotal() {
        Integer i = 0;
        Measure__c measure;
        Application__c app = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        Test.startTest();
        insert app;
        while (i < 4) {
            Rebate_Type__c rebateType = BIGPortalTestUtils.createRebateType('One-year QM Service Agreement', 25, 'TK12',
                    'One-year QM Service Agreement');
            rebateTypesList.add(rebateType);
            i++;
        }
        insert rebateTypesList;

        i = 0;
        for (Rebate_Type__c rt : rebateTypesList) {
            measure = BIGPortalTestUtils.createMeasure('ACQC Measure ' + i, app.Id);
            measure.Rebate_Type__c = rt.Id;
            measureList.add(measure);
            i++;
        }
        insert measureList;
        // It affects to the inserted app too (there is a trigger on Measure__c).
        // Delete last measured added
        delete measureList.get(measureList.size() - 1);
        Test.stopTest();
        System.assertEquals(75, [SELECT Incentive_Total__c FROM Application__c WHERE Id =: app.Id].Incentive_Total__c);
    }

    private static testMethod void testUpdateFundingSourceOnHUPApps() {
        Application__c app = new Application__c();
        app.RecordTypeId = ApplicationUtils.HUP_RECORD_TYPE;
        insert app;
        System.assertEquals(ApplicationUtils.FUNDING_SOURCE_HU,
                [SELECT Funding_Source__c FROM Application__c WHERE Id =: app.Id LIMIT 1].Funding_Source__c);
    }

    private static testMethod void testUpdateFundingSourceOnAHUApps() {
        Application__c app = new Application__c();
        app.RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE;
        insert app;
        System.assertEquals(ApplicationUtils.FUNDING_SOURCE_AHU,
                [SELECT Funding_Source__c FROM Application__c WHERE Id =: app.Id LIMIT 1].Funding_Source__c);
    }

    private static testMethod void testNullFundingSourceOnApps() {
        Application__c app = new Application__c();
        insert app;
        System.assertEquals(null,
                [SELECT Funding_Source__c FROM Application__c WHERE Id =: app.Id LIMIT 1].Funding_Source__c);
    }

    private static testMethod void testMatchAppWithOnePGECustomer() {
        // Use gasElectricIds[0] for electric id and gasElectricIds[1] for gas id.
        List<String> gasElectricIds = new List<String>(BIGPortalTestUtils.generateRandomString(10, 2));
        PGE_Customer__c pgeCust = new PGE_Customer__c();
        pgeCust.Name = 'PGECustomerTest';
        pgeCust.Electric_SAID__c = gasElectricIds.get(0);
        pgeCust.Gas_SAID__c = gasElectricIds.get(1);
        insert pgeCust;

        Application__c app = BIGPortalTestUtils.createApplication(ApplicationUtils.HUP_RECORD_TYPE);
        app.Electric_Provider__c = ApplicationUtils.PGE_GAS_ELECTRIC_PROVIDER;
        app.Gas_Provider__c = ApplicationUtils.PGE_GAS_ELECTRIC_PROVIDER;
        app.Electric_Account_Number__c = gasElectricIds.get(0);
        app.Gas_Account_Number__c = gasElectricIds.get(1);

        Test.startTest();
        insert app;
        Test.stopTest();

        // Gas/electric ids (both) match with one pge customer record.
        List<PGE_Customer_Application__c> junctions = [
            SELECT Application__c, PGE_Customer__c FROM PGE_Customer_Application__c];
        System.assert(junctions.size() == 1);
        System.assertEquals(app.Id, junctions[0].Application__c);
        System.assertEquals(pgeCust.Id, junctions[0].PGE_Customer__c);
    }

    private static testMethod void testExistingMatchesWithPGECustomers() {
        // Use gasElectricIds[0] for electric id, gasElectricIds[1] for gas id and gasElectricIds[2] for electric id.
        List<String> gasElectricIds = new List<String>(BIGPortalTestUtils.generateRandomString(10, 3));
        PGE_Customer__c pgeCust = new PGE_Customer__c();
        pgeCust.Name = 'PGECustomerTest';
        pgeCust.Electric_SAID__c = gasElectricIds.get(0);
        pgeCust.Gas_SAID__c = gasElectricIds.get(1);
        insert pgeCust;

        Application__c app = BIGPortalTestUtils.createApplication(ApplicationUtils.HUP_RECORD_TYPE);
        app.Electric_Provider__c = ApplicationUtils.PGE_GAS_ELECTRIC_PROVIDER;
        app.Gas_Provider__c = ApplicationUtils.PGE_GAS_ELECTRIC_PROVIDER;
        app.Electric_Account_Number__c = gasElectricIds.get(0);
        app.Gas_Account_Number__c = gasElectricIds.get(1);
        insert app;

        // Change the electric number. It doesn't match with the pge customer gas SAID anymore.
        app.Electric_Account_Number__c = gasElectricIds.get(2);

        Test.startTest();
        update app;
        Test.stopTest();

        // Expected result: Don't delete the junction, keep it.
        List<PGE_Customer_Application__c> junctions = [
            SELECT Application__c, PGE_Customer__c FROM PGE_Customer_Application__c];
        System.assert(junctions.size() == 1);
        System.assertEquals(app.Id, junctions[0].Application__c);
        System.assertEquals(pgeCust.Id, junctions[0].PGE_Customer__c);
    }

    private static testMethod void testMatchAppWithMoreThanOnePGECustomer() {
        // Should create 2 junction records for the same application.
        List<String> gasElectricIds = new List<String>(BIGPortalTestUtils.generateRandomString(10, 4));
        List<PGE_Customer__c> listPGECustomers = new List<PGE_Customer__c>();
        Integer assertJunctions = 0;

        PGE_Customer__c pgeCust1 = new PGE_Customer__c();
        pgeCust1.Name = 'PGECustomerTest';
        pgeCust1.Electric_SAID__c = gasElectricIds.get(0);
        pgeCust1.Gas_SAID__c = gasElectricIds.get(1);
        listPGECustomers.add(pgeCust1);

        PGE_Customer__c pgeCust2 = new PGE_Customer__c();
        pgeCust2.Name = 'PGECustomerTest';
        pgeCust2.Electric_SAID__c = gasElectricIds.get(2);
        pgeCust2.Gas_SAID__c = gasElectricIds.get(3);
        listPGECustomers.add(pgeCust2);

        insert listPGECustomers;

        Application__c app = BIGPortalTestUtils.createApplication(ApplicationUtils.HUP_RECORD_TYPE);
        app.Electric_Provider__c = ApplicationUtils.PGE_GAS_ELECTRIC_PROVIDER;
        app.Gas_Provider__c = ApplicationUtils.PGE_GAS_ELECTRIC_PROVIDER;
        app.Electric_Account_Number__c = gasElectricIds.get(0);
        app.Gas_Account_Number__c = gasElectricIds.get(3);

        Test.startTest();
        insert app;
        Test.stopTest();

        List<PGE_Customer_Application__c> junctions = [
            SELECT Application__c, PGE_Customer__c FROM PGE_Customer_Application__c];
        System.assert(junctions.size() == 2);
        for (PGE_Customer_Application__c ju : junctions) {
            if (ju.Application__c == app.Id && (ju.PGE_Customer__c == listPGECustomers.get(0).Id
                    || ju.PGE_Customer__c == listPGECustomers.get(1).Id)) {
                assertJunctions++;
            }
        }
        System.assertEquals(2, assertJunctions);
    }

    private static testMethod void testDeletePGEApplicationJunctions() {
        List<String> gasElectricIds = new List<String>(BIGPortalTestUtils.generateRandomString(10, 4));

        PGE_Customer__c pgeCust = new PGE_Customer__c();
        pgeCust.Name = 'PGECustomerTest';
        pgeCust.Electric_SAID__c = gasElectricIds.get(0);
        pgeCust.Gas_SAID__c = gasElectricIds.get(2);
        insert pgeCust;

        Application__c app = BIGPortalTestUtils.createApplication(ApplicationUtils.HUP_RECORD_TYPE);
        app.Electric_Provider__c = ApplicationUtils.PGE_GAS_ELECTRIC_PROVIDER;
        app.Gas_Provider__c = ApplicationUtils.PGE_GAS_ELECTRIC_PROVIDER;
        app.Electric_Account_Number__c = gasElectricIds.get(0);
        app.Gas_Account_Number__c = gasElectricIds.get(1);
        insert app;

        // Should retrieve 1 record because the electric id matches with the electric SAID
        Integer junction = [
            SELECT count()
            FROM PGE_Customer_Application__c
            WHERE Application__c =: app.Id AND PGE_Customer__c =: pgeCust.Id
            ];
        Test.startTest();
        // Electric/gas ids don't match with the gas/electric SAID. Junction record will be deleted.
        app.Electric_Account_Number__c = gasElectricIds.get(3);
        update app;
        Test.stopTest();

        System.assertEquals(1, junction);
        System.assertEquals(0, [SELECT count() FROM PGE_Customer_Application__c]);
    }

    /**
     * Verify Measure Combination has one match
     */
    static testMethod void testMeasureHybridCombinationMatch() {
        Map<String, Map<String, decimal>> fieldsToPopulateOnApp = new Map<String, Map<String, decimal>>();
        List<String> measureCombinationAbbreviationToSort;
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();

        // Create a HUP Application and Measure Types
        initMeasureCombinationData();
        // Sort Measure Combination Code Abbreviation to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'ACS15', 'DS10'};
        // Get Metadata info based on climate zone, building vintage and the measure combination
        measureCombinationCodeMdt = getMeasureCombinationCodeMdt('1996', 1, '10% Dct Lkg,SEER15 AC,92 AFUE Furnace');

        Test.startTest();
        // Create Measures with a related measureTypesList
        measureList = BIGPortalTestUtils.createMeasures(new List<Application__c>{application}, measureTypesList);
        Test.stopTest();

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Verify data
        assertMeasureCodeCombinationMatchResults(measureCombinationCodeMdt, application,
                measureCombinationAbbreviationToSort);
    }

    /**
     * Verify when there isn't a Measure Combination Code match
     */
    static testMethod void testMeasureNotCombinationMatch() {
        Map<String, Map<String, decimal>> fieldsToPopulateOnApp = new Map<String, Map<String, decimal>>();
        List<String> measureCodeToSort;
        List<String> measureCombinationAbbreviationToSort;
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();

        // Create a HUP Application
        createHUPApplication();

        try {
            // Create measures
            Set<String> recordNames = new Set<String>{'F92', 'GH76', 'DS10'};
            measureTypesList = BIGPortalTestUtils.getMeasureTypes(recordNames);
        } catch (DmlException e) {
            System.debug('Error: Couldn\'t create measure type. Message: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error: Couldn\'t create measure type. Message: ' + e.getMessage());
        }

        Test.startTest();
        // Create Measures with a related measureTypesList
        measureList = BIGPortalTestUtils.createMeasures(new List<Application__c>{application}, measureTypesList);
        Test.stopTest();

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Sort Measure code to verify later
        measureCodeToSort = new List<String>{'10% Dct Lkg', '76 AFUE Heater', '92 AFUE Furnace'};
        measureCodeToSort.sort();
        // Sort Measure Combination Code Abbreviation to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'GH76', 'DS10'};
        measureCombinationAbbreviationToSort.sort();

        // Verify data
        System.assertEquals(ApplicationUtils.CUSTOM_PACKAGE_TYPE, application.Package_Type__c);
        System.assertEquals(false, application.Override_Package_Type__c);
        System.assertEquals(null, application.Measure_Combination_Code__c);
        System.assertEquals(String.join(measureCodeToSort, ','), application.Measure_Combination__c);
        System.assertEquals(String.join(measureCombinationAbbreviationToSort, ','),
                application.Measure_Combination_Abbreviation__c);
        System.assertEquals(null, application.Measure_Combination_Code__c);
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);
        System.assertEquals(null, application.Therms_Savings_2nd_BL__c);
        System.assertEquals(null, application.Incremental_Measure_Cost__c);
        System.assertEquals(null, application.Incremental_Measure_Cost_2nd_BL__c);
        System.assertEquals(null, application.kWh_Savings_2nd_BL__c);
        System.assertEquals(null, application.kW_Savings_2nd_BL__c);
    }

    /**
     * Verify Application data when change measures from Hybrid to Custom Combination
     */
    static testMethod void testMeasureHybridToCustomCombination() {
        Map<String, Map<String, decimal>> fieldsToPopulateOnApp = new Map<String, Map<String, decimal>>();
        List<String> measureCodeToSort;
        List<String> measureCombinationAbbreviationToSort;
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();

        // Create a HUP Application and Measure Types
        initMeasureCombinationData();
        measureList = BIGPortalTestUtils.createMeasures(new List<Application__c>{application}, measureTypesList);
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Sort Measure Combination Abbreviation code to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'ACS15', 'DS10'};
        // Get Metadata info based on climate zone, building vintage and the measure combination
        measureCombinationCodeMdt = getMeasureCombinationCodeMdt('1996', 1, '10% Dct Lkg,SEER15 AC,92 AFUE Furnace');
        // Verify data
        assertMeasureCodeCombinationMatchResults(measureCombinationCodeMdt, application,
                measureCombinationAbbreviationToSort);

        // Delete one Measure type to change Hybrid to Custom
        Test.startTest();

        for (Measure__c measure : measureList) {
            if (measure.Measure_Code__c == 'SEER 15 AC Split') {
                BIGPortalTestUtils.deleteMeasures(new List<Measure__c>{measure});
                break;
            }
        }

        Test.stopTest();

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Sort Measure code to verify later
        measureCodeToSort = new List<String>{'10% Dct Lkg','92 AFUE Furnace'};
        measureCodeToSort.sort();
        // Sort Measure Combination Abbreviation code to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'DS10'};
        measureCombinationAbbreviationToSort.sort();

        // Verify data
        System.assertEquals(ApplicationUtils.CUSTOM_PACKAGE_TYPE, application.Package_Type__c);
        System.assertEquals(false, application.Override_Package_Type__c);
        System.assertEquals(null, application.Measure_Combination_Code__c);
        System.assertEquals(String.join(measureCodeToSort, ','), application.Measure_Combination__c);
        System.assertEquals(String.join(measureCombinationAbbreviationToSort, ','),
                application.Measure_Combination_Abbreviation__c);
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);
        System.assertEquals(null, application.Therms_Savings_2nd_BL__c);
        System.assertEquals(null, application.Incremental_Measure_Cost__c);
        System.assertEquals(null, application.Incremental_Measure_Cost_2nd_BL__c);
        System.assertEquals(null, application.kWh_Savings_2nd_BL__c);
        System.assertEquals(null, application.kW_Savings_2nd_BL__c);
    }

    /**
     * Verify Application data when change measure from Hybrid to Hybrid combination
     */
    static testMethod void testMeasureHybirdToHybridCombination() {
        Map<String, Map<String, decimal>> fieldsToPopulateOnApp = new Map<String, Map<String, decimal>>();
        List<String> measureCombinationAbbreviationToSort;
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();

        // Create a HUP Application and Measure Types
        initMeasureCombinationData();
        // Create measures based on measureTypesList
        measureList = BIGPortalTestUtils.createMeasures(new List<Application__c>{application}, measureTypesList);
        // Sort Measure Combination Code Abbreviation to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'ACS15', 'DS10'};
        // Get Metadata info based on climate zone, building vintage and the measure combination
        measureCombinationCodeMdt = getMeasureCombinationCodeMdt('1996', 1, '10% Dct Lkg,SEER15 AC,92 AFUE Furnace');
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Verify data
        assertMeasureCodeCombinationMatchResults(measureCombinationCodeMdt, application,
                measureCombinationAbbreviationToSort);
        // Add another measure to get another hybrid combination with this unique identifier --> HV078_1996_01
        try {
            Set<String> recordNames = new Set<String>{'HPW'};
            measureTypesList = BIGPortalTestUtils.getMeasureTypes(recordNames);
        } catch (DmlException e) {
            System.debug('Error: Couldn\'t create measure type. Message: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error: Couldn\'t create measure type. Message: ' + e.getMessage());
        }

        Test.startTest();
        measureList.Add((BIGPortalTestUtils.createMeasures(
                new List<Application__c>{application}, measureTypesList)).get(0));
        Test.stopTest();

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Sort Measure Combination Code Abbreviation to verify later
        measureCombinationAbbreviationToSort.add('HPW');
        // Get Metadata info based on climate zone, building vintage and the measure combination
        measureCombinationCodeMdt =
                getMeasureCombinationCodeMdt('1996', 1, '10% Dct Lkg,HP Window,SEER15 AC,92 AFUE Furnace');
        // Verify data
        assertMeasureCodeCombinationMatchResults(measureCombinationCodeMdt, application,
                measureCombinationAbbreviationToSort);
    }

    /**
     * Verify Application data when change measure from Custom to Custom Combination
     */
    static testMethod void testMeasureCustomToCustomCombination() {
        Map<String, Map<String, decimal>> fieldsToPopulateOnApp = new Map<String, Map<String, decimal>>();
        List<String> measureCodeToSort;
        List<String> measureCombinationAbbreviationToSort;
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();

        // Create a HUP Application
        createHUPApplication();

        // Create measures
        try {
            Set<String> recordNames = new Set<String>{'F92', 'ACS15', 'HPW'};
            measureTypesList = BIGPortalTestUtils.getMeasureTypes(recordNames);
        } catch (DmlException e) {
            System.debug('Error: Couldn\'t create measure type. Message: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error: Couldn\'t create measure type. Message: ' + e.getMessage());
        }

        measureList = BIGPortalTestUtils.createMeasures(new List<Application__c>{application}, measureTypesList);
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Sort Measure code to verify later
        measureCodeToSort = new List<String>{'SEER 15 AC Split','HP Windows','92 AFUE Furnace'};
        measureCodeToSort.sort();
        // Sort Measure Combination Code Abbreviation to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'ACS15', 'HPW'};
        measureCombinationAbbreviationToSort.sort();
        // Verify data
        System.assertEquals(ApplicationUtils.CUSTOM_PACKAGE_TYPE, application.Package_Type__c);
        System.assertEquals(false, application.Override_Package_Type__c);
        System.assertEquals(null, application.Measure_Combination_Code__c);
        System.assertEquals(String.join(measureCodeToSort, ','), application.Measure_Combination__c);
        System.assertEquals(String.join(measureCombinationAbbreviationToSort, ','),
                application.Measure_Combination_Abbreviation__c);
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);
        System.assertEquals(null, application.Therms_Savings_2nd_BL__c);
        System.assertEquals(null, application.Incremental_Measure_Cost__c);
        System.assertEquals(null, application.Incremental_Measure_Cost_2nd_BL__c);
        System.assertEquals(null, application.kWh_Savings_2nd_BL__c);
        System.assertEquals(null, application.kW_Savings_2nd_BL__c);

        // Modify app data to check they are preserved after changes
        application.Measure_Combination_Code__c = 'test';
        application.Therms_Savings__c = 0.5;
        application.Incremental_Measure_Cost__c = 0.4;
        application.kW_Savings_2nd_BL__c = 0.3;
        application.Therms_Savings_2nd_BL__c = 0.1;
        update application;

        // Verify data
        System.assertEquals(ApplicationUtils.CUSTOM_PACKAGE_TYPE, application.Package_Type__c);
        System.assertEquals(false, application.Override_Package_Type__c);
        System.assertEquals('test', application.Measure_Combination_Code__c);
        System.assertEquals(String.join(measureCodeToSort, ','), application.Measure_Combination__c);
        System.assertEquals(String.join(measureCombinationAbbreviationToSort, ','),
                application.Measure_Combination_Abbreviation__c);
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(0.5, application.Therms_Savings__c);
        System.assertEquals(0.1, application.Therms_Savings_2nd_BL__c);
        System.assertEquals(0.4, application.Incremental_Measure_Cost__c);
        System.assertEquals(null, application.Incremental_Measure_Cost_2nd_BL__c);
        System.assertEquals(null, application.kWh_Savings_2nd_BL__c);
        System.assertEquals(0.3, application.kW_Savings_2nd_BL__c);

        // Delete one qualifying measure in order to verify that values are reset
        Test.startTest();

        for (Measure__c measure : measureList) {
            if (measure.Measure_Code__c == '92 AFUE Furnace') {
                BIGPortalTestUtils.deleteMeasures(new List<Measure__c>{measure});
                break;
            }
        }

        Test.stopTest();

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Sort Measure code to verify later
        measureCodeToSort = new List<String>{'SEER 15 AC Split','HP Windows'};
        measureCodeToSort.sort();
        // Sort Measure Combination Code Abbreviation to verify later
        measureCombinationAbbreviationToSort = new List<String>{'ACS15', 'HPW'};
        measureCombinationAbbreviationToSort.sort();

        // Verify data
        System.assertEquals(ApplicationUtils.CUSTOM_PACKAGE_TYPE, application.Package_Type__c);
        System.assertEquals(false, application.Override_Package_Type__c);
        System.assertEquals(null, application.Measure_Combination_Code__c);
        System.assertEquals(String.join(measureCodeToSort, ','), application.Measure_Combination__c);
        System.assertEquals(String.join(measureCombinationAbbreviationToSort, ','),
                application.Measure_Combination_Abbreviation__c);
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);
        System.assertEquals(null, application.Therms_Savings_2nd_BL__c);
        System.assertEquals(null, application.Incremental_Measure_Cost__c);
        System.assertEquals(null, application.Incremental_Measure_Cost_2nd_BL__c);
        System.assertEquals(null, application.kWh_Savings_2nd_BL__c);
        System.assertEquals(null, application.kW_Savings_2nd_BL__c);
    }

    /**
     * Verify Application data when Override_Package_Type__c is set to true
     */
    static testMethod void testApplicationInfoOverridePackageTrue() {
        Map<String, Map<String, decimal>> fieldsToPopulateOnApp = new Map<String, Map<String, decimal>>();
        List<String> measureCombinationAbbreviationToSort;
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();

        // Create a HUP Application and Measure Types
        initMeasureCombinationData();
        measureList = BIGPortalTestUtils.createMeasures(new List<Application__c>{application}, measureTypesList);
        // Sort Measure Combination Code Abbreviation to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'ACS15', 'DS10'};
        // Get Metadata info based on climate zone, building vintage and the measure combination
        measureCombinationCodeMdt = getMeasureCombinationCodeMdt('1996', 1, '10% Dct Lkg,SEER15 AC,92 AFUE Furnace');
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Verify data
        assertMeasureCodeCombinationMatchResults(measureCombinationCodeMdt, application,
                measureCombinationAbbreviationToSort);
        // Set Override_Package_Type__c to true
        application.Override_Package_Type__c = True;
        application.Measure_Combination_Code__c = 'test';
        update application;
        BIGPortalTestUtils.deleteMeasures(measureList);
        // Create measures
        try {
            Set<String> recordNames = new Set<String>{'GSW70', 'AS15'};
            measureTypesList = BIGPortalTestUtils.getMeasureTypes(recordNames);
        } catch (DmlException e) {
            System.debug('Error: Couldn\'t create measure type. Message: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error: Couldn\'t create measure type. Message: ' + e.getMessage());
        }

        Test.startTest();
        measureList = BIGPortalTestUtils.createMeasures(new List<Application__c>{application}, measureTypesList);
        Test.stopTest();

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Verify data doesn't change because Override_Package_Type__c is set to true
        System.assertEquals(ApplicationUtils.HYBRID_PACKAGE_TYPE, application.Package_Type__c);
        System.assertEquals(true, application.Override_Package_Type__c);
        System.assertEquals('test', application.Measure_Combination_Code__c);
        System.assertEquals(measureCombinationCodeMdt.Measure_Combination__c, application.Measure_Combination__c);
        System.assertEquals(String.join(measureCombinationAbbreviationToSort, ','),
                application.Measure_Combination_Abbreviation__c);
        System.assertEquals(measureCombinationCodeMdt.kWh_Savings__c, application.kWh_Savings__c);
        System.assertEquals(measureCombinationCodeMdt.kW_Savings__c, application.kW_Savings__c);
        System.assertEquals(measureCombinationCodeMdt.Therms_Savings__c, application.Therms_Savings__c);
        System.assertEquals(measureCombinationCodeMdt.Therms_Savings_2nd_BL__c, application.Therms_Savings_2nd_BL__c);
        System.assertEquals(measureCombinationCodeMdt.Incremental_Measure_Cost__c,
                application.Incremental_Measure_Cost__c);
        System.assertEquals(measureCombinationCodeMdt.Incremental_Measure_Cost_2nd_BL__c,
                application.Incremental_Measure_Cost_2nd_BL__c);
        System.assertEquals(measureCombinationCodeMdt.kWh_Savings_2nd_BL__c, application.kWh_Savings_2nd_BL__c);
        System.assertEquals(measureCombinationCodeMdt.kW_Savings_2nd_BL__c, application.kW_Savings_2nd_BL__c);
    }

    /**
     * Verify Application data when an Application information is updated
     */
    static testMethod void testApplicationSavingsAfterUpdating() {
        Map<String, Map<String, decimal>> fieldsToPopulateOnApp = new Map<String, Map<String, decimal>>();
        List<String> measureCombinationAbbreviationToSort;
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();

        // Create a HUP Application and Measure Types
        initMeasureCombinationData();

        Test.startTest();
        measureList = BIGPortalTestUtils.createMeasures(new List<Application__c>{application}, measureTypesList);
        Test.stopTest();

        // Sort Measure Combination Code Abbreviation to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'ACS15', 'DS10'};
        // Get Metadata info based on climate zone, building vintage and the measure combination
        measureCombinationCodeMdt = getMeasureCombinationCodeMdt('1996', 1, '10% Dct Lkg,SEER15 AC,92 AFUE Furnace');
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Verify data
        assertMeasureCodeCombinationMatchResults(measureCombinationCodeMdt, application,
                measureCombinationAbbreviationToSort);
        // Modify app data to check they are set as before after update
        application.Therms_Savings__c = 12.9;
        application.Incremental_Measure_Cost_2nd_BL__c = 3.8;
        application.Measure_Combination__c = 'asdfasdfasdf';
        update application;
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Verify data
        assertMeasureCodeCombinationMatchResults(measureCombinationCodeMdt, application,
                measureCombinationAbbreviationToSort);
    }

    /**
     * Verify Application data when a bulk of Application is updated
     */
    static testMethod void testBulkApplicationUpdated() {
        Map<String, Map<String, decimal>> fieldsToPopulateOnApp = new Map<String, Map<String, decimal>>();
        List<String> measureCombinationAbbreviationToSort;
        List<Application__c> applications = new List<Application__c>();
        List<Application__c> applicationsToUpdate = new List<Application__c>();
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();
        Set<Id> appIds = new Set<Id>();

        // Create 20 Applications
        for (integer i = 0; i < 20; i++) {
            Application__c app = BIGPortalTestUtils.createApplication(ApplicationUtils.HUP_RECORD_TYPE);
            applications.add(app);
        }
        insert applications;

        for (Application__c app : applications) {
            // Update app with Building Vintage and Climate Zone (not on insert because it sets both to null)
            app.Climate_Zone__c = 1;
            app.Building_Vintage__c = 'NEW';
            applicationsToUpdate.add(app);
        }
        update applicationsToUpdate;

        // Create measure types to get this unique identifier --> HV076_1996_01
        createMeasureTypesWithUniqueIdentifier();

        Test.startTest();
        measureList = BIGPortalTestUtils.createMeasures(applicationsToUpdate, measureTypesList);

        // Sort Measure Combination Abbreviation code to verify later
        measureCombinationAbbreviationToSort = new List<String>{'F92', 'ACS15', 'DS10'};
        measureCombinationAbbreviationToSort.sort();
        applications = new List<Application__c>();

        for (Application__c applicationToUpdate : applicationsToUpdate) {
            applicationToUpdate.Package_Type__c = null;
            applicationToUpdate.Measure_Combination_Code__c = 'x';
            applicationToUpdate.Measure_Combination__c = null;
            applications.add(applicationToUpdate);
            appIds.add(applicationToUpdate.Id);
        }
        update applications;
        Test.stopTest();

        // Get Metadata info based on climate zone, building vintage and the measure combination
        measureCombinationCodeMdt = getMeasureCombinationCodeMdt('1996', 1, '10% Dct Lkg,SEER15 AC,92 AFUE Furnace');
        applications = BIGPortalTestUtils.getApplicationsById(appIds);

        for (Application__c app : applications) {
            // Verify data
            assertMeasureCodeCombinationMatchResults(measureCombinationCodeMdt, app,
                    measureCombinationAbbreviationToSort);
        }
    }

    /**
     * Verify Last_Application_Submission_Date__c change for last Application_Submission_Date__c related to each
     * Technician.
     */
    static testMethod void testEmployeeProgramEnrollmentDateChangeTechnician() {
        List<Contact> contacts = new List<Contact>();
        List<Application__c> applications = new List<Application__c>();
        List<Employee_Program_Enrollment__c> employeeProgramsEnrollment = new List<Employee_Program_Enrollment__c>();

        // Create Account
        account = BIGPortalTestUtils.createAccount('OneAccount');
        insert account;

        // Create two contacts
        Contact oneTechnician = BIGPortalTestUtils.createContact('OneTechnician', 'OneTechnician', 'one@tech.com',
                '22222222', account.Id);
        Contact twoTechnician = BIGPortalTestUtils.createContact('TwoTechnician', 'TwoTechnician', 'two@tech.com',
                '22222222', account.Id);

        contacts.add(oneTechnician);
        contacts.add(twoTechnician);
        insert contacts;

        // Create a Program Enrollment
        Program_Enrollment__c programEnrollment = BIGPortalTestUtils.createProgramEnrollment(account.Id,
                ApplicationUtils.ACQC_PROGRAM_ENROLLMENT_RECORD_TYPE_ID, 'Full Participation');

        insert programEnrollment;

        // Create two Employee_Program_Enrollment__c with Technician as role
        Employee_Program_Enrollment__c oneEmployee = BIGPortalTestUtils.createEmployeeProgramEnrollment(
                oneTechnician.Id, programEnrollment.Id, 'Technician');
        Employee_Program_Enrollment__c twoEmployee = BIGPortalTestUtils.createEmployeeProgramEnrollment(
                twoTechnician.Id, programEnrollment.Id, 'Technician');

        employeeProgramsEnrollment.add(oneEmployee);
        employeeProgramsEnrollment.add(twoEmployee);

        insert employeeProgramsEnrollment;

        // Create one Application with Technician OneTechnician and submitted date on May
        Application__c appSubmittedOnMay = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        appSubmittedOnMay.Application_Submission_Date__c = Date.valueOf('2016-05-01 00:00:00');
        appSubmittedOnMay.Last_Application_Submission_Date__c = Date.valueOf('2016-05-01 00:00:00');
        appSubmittedOnMay.Technician__c = oneTechnician.Id;
        // Create one Application with Technician TwoTechnician and submitted date on June
        Application__c appSubmittedOnJune = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        appSubmittedOnJune.Application_Submission_Date__c = Date.valueOf('2016-06-01 00:00:00');
        appSubmittedOnJune.Last_Application_Submission_Date__c = Date.valueOf('2016-06-01 00:00:00');
        appSubmittedOnJune.Technician__c = twoTechnician.Id;
        // Create one Application with Technician TwoTechnician and submitted date on July
        Application__c appSubmittedOnJuly = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        appSubmittedOnJuly.Application_Submission_Date__c = Date.valueOf('2016-07-01 00:00:00');
        appSubmittedOnJuly.Last_Application_Submission_Date__c = Date.valueOf('2016-07-01 00:00:00');
        appSubmittedOnJuly.Technician__c = twoTechnician.Id;

        applications.add(appSubmittedOnMay);
        applications.add(appSubmittedOnJune);
        applications.add(appSubmittedOnJuly);
        insert applications;

        Test.startTest();
            appSubmittedOnJuly.Technician__c = oneTechnician.Id;
            update appSubmittedOnJuly;
        Test.stopTest();

        Map<Id, Employee_Program_Enrollment__c> mapEmployeeProgramsEnrollment =
                BIGPortalTestUtils.getEmployeeProgramsEnrollmentById(new Set<Id> {oneEmployee.Id, twoEmployee.Id});

        System.assertEquals(Date.valueOf('2016-07-01 00:00:00'),
                mapEmployeeProgramsEnrollment.get(oneEmployee.Id).Last_Application_Submission_Date__c);
        System.assertEquals(Date.valueOf('2016-06-01 00:00:00'),
                mapEmployeeProgramsEnrollment.get(twoEmployee.Id).Last_Application_Submission_Date__c);
    }

    /**
     * Verify when we delete a technician from Application, Employee Program Enrollment date change to the last
     * submitted date that a Application with this technician has.
     */
    static testMethod void testEmployeeProgramEnrollmentDateTechnicianNull() {
        List<Contact> contacts = new List<Contact>();
        List<Application__c> applications = new List<Application__c>();
        List<Employee_Program_Enrollment__c> employeeProgramsEnrollment = new List<Employee_Program_Enrollment__c>();

        // Create Account
        account = BIGPortalTestUtils.createAccount('OneAccount');
        insert account;

        // Create two contacts
        Contact oneTechnician = BIGPortalTestUtils.createContact('OneTechnician', 'OneTechnician', 'one@tech.com',
                '22222222', account.Id);
        Contact twoTechnician = BIGPortalTestUtils.createContact('TwoTechnician', 'TwoTechnician', 'two@tech.com',
                '22222222', account.Id);

        contacts.add(oneTechnician);
        contacts.add(twoTechnician);
        insert contacts;

        // Create a Program Enrollment
        Program_Enrollment__c programEnrollment = BIGPortalTestUtils.createProgramEnrollment(account.Id,
                ApplicationUtils.ACQC_PROGRAM_ENROLLMENT_RECORD_TYPE_ID, 'Full Participation');

        insert programEnrollment;

        // Create two Employee_Program_Enrollment__c with Technician as role
        Employee_Program_Enrollment__c oneEmployee = BIGPortalTestUtils.createEmployeeProgramEnrollment(
                oneTechnician.Id, programEnrollment.Id, 'Technician');
        Employee_Program_Enrollment__c twoEmployee = BIGPortalTestUtils.createEmployeeProgramEnrollment(
                twoTechnician.Id, programEnrollment.Id, 'Technician');

        employeeProgramsEnrollment.add(oneEmployee);
        employeeProgramsEnrollment.add(twoEmployee);

        insert employeeProgramsEnrollment;

        // Create one Application with Technician OneTechnician and submitted date on May
        Application__c appSubmittedOnMay = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        insert appSubmittedOnMay;

        appSubmittedOnMay.Application_Submission_Date__c = Date.valueOf('2016-05-01 00:00:00');
        appSubmittedOnMay.Last_Application_Submission_Date__c = Date.valueOf('2016-05-01 00:00:00');
        appSubmittedOnMay.Technician__c = oneTechnician.Id;
        // Create one Application with Technician TwoTechnician and submitted date on June
        Application__c appSubmittedOnJune = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        appSubmittedOnJune.Application_Submission_Date__c = Date.valueOf('2016-06-01 00:00:00');
        appSubmittedOnJune.Last_Application_Submission_Date__c = Date.valueOf('2016-06-01 00:00:00');
        appSubmittedOnJune.Technician__c = twoTechnician.Id;
        // Create one Application with Technician TwoTechnician and submitted date on July
        Application__c appSubmittedOnJuly = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        appSubmittedOnJuly.Application_Submission_Date__c = Date.valueOf('2016-07-01 00:00:00');
        appSubmittedOnJuly.Last_Application_Submission_Date__c = Date.valueOf('2016-07-01 00:00:00');
        appSubmittedOnJuly.Technician__c = twoTechnician.Id;

        applications.add(appSubmittedOnMay);
        applications.add(appSubmittedOnJune);
        applications.add(appSubmittedOnJuly);

        upsert applications;

        Test.startTest();
            appSubmittedOnJuly.Technician__c = null;
            update appSubmittedOnJuly;
        Test.stopTest();

        Map<Id, Employee_Program_Enrollment__c> mapEmployeeProgramsEnrollment =
                BIGPortalTestUtils.getEmployeeProgramsEnrollmentById(new Set<Id> {oneEmployee.Id, twoEmployee.Id});

        /* Check Last_Application_Submission_Date__c change to May
        * (Last App Date Submitted for the related oneTechnician)
        */
        System.assertEquals(Date.valueOf('2016-05-01 00:00:00'),
                mapEmployeeProgramsEnrollment.get(oneEmployee.Id).Last_Application_Submission_Date__c);
        /* Check Last_Application_Submission_Date__c change to June
         * (Last App Date Submitted for the related twoTechnician)
         */
        System.assertEquals(Date.valueOf('2016-06-01 00:00:00'),
                mapEmployeeProgramsEnrollment.get(twoEmployee.Id).Last_Application_Submission_Date__c);
    }

    /**
     * Verify Savings population on Application and Measures for ACQC, when Measure Code = TK08 similar to HV287.
     */
    static testMethod void testSavingsMatchForTK08() {
        List<Measure__c> measures = new List<Measure__c>();
        Measure__c measure;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;

        // Creates an ACQC Application
        createACQCApplication();
        application.Climate_Zone__c = 2;
        application.Total_Unit_Capacity__c = 2;
        update application;

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // There isn't any measure so verify savings are null
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);

        // Get map for those combinations we want (Climate_Zone__c = 2 & Measure_Code__c = HV87 or H796)
        Map<String, MeasureUtils.measureSavingsWrapper> measureSavingsMap = MeasureUtils.getMeasureSavingsMetadata(
                new Set<Integer>{2}, new Set<String>{'HV287', 'H796'});

        // NEED TO CHANGE AFTER CHANGE REBATE TYPES TO MEASURE TYPE CUSTOM METADATA
        // Create Rebate types for those measures we want to create
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Air Flow Correction', 25, 'TK08',
                'Air Flow Correction'));
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Enhanced Time Delay Relay', 25, 'H796',
                'Enhanced Time Delay Relay'));

        Test.startTest();
        insert rebateTypesList;
        measure = BIGPortalTestUtils.createMeasure('TK08', application.Id);
        measure.Application__r = application;
        measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
        measure.Rebate_Type__c = rebateTypesList.get(0).Id;
        measure.Measure_Code__c = 'TK08';
        measures.add(measure);
        measure = BIGPortalTestUtils.createMeasure('H796', application.Id);
        measure.Application__r = application;
        measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
        measure.Rebate_Type__c = rebateTypesList.get(1).Id;
        measure.Measure_Code__c = 'H796';
        measures.add(measure);
        insert measures;
        Test.stopTest();

        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{application.Id});
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        String climateZone = (String.valueOf(application.Climate_Zone__c)).leftPad(2, '0');

        // Verify saving populated on measure for Measure Code TK10
        System.assertEquals(measureSavingsMap.get('HV287_' + climateZone).kwSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK08' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('HV287_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK08' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('HV287_' + climateZone).thermsSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK08' + climateZone).Therms_Savings__c);
        // Verify saving populated on measure for Measure Code H796
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwSavings
                * application.Total_Unit_Capacity__c,
                measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c,
                measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).thermsSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Get application savings by summing its measure savings
        sumKwSavings = (measureMap.get('TK08' + climateZone).kW_Savings__c
                + measureMap.get('H796' + climateZone).kW_Savings__c);
        sumKwhSavings = (measureMap.get('TK08' + climateZone).kWh_Savings__c
                + measureMap.get('H796' + climateZone).kWh_Savings__c);
        sumThermSavings = (measureMap.get('TK08' + climateZone).Therms_Savings__c
                + measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Verify application data
        System.assertEquals(sumKwhSavings, application.kWh_Savings__c);
        System.assertEquals(sumKwSavings, application.kW_Savings__c);
        System.assertEquals(sumThermSavings, application.Therms_Savings__c);
    }

    /**
     * Verify savings on the application and its measures after a savings value was entered manually on the measure.
     * It also verifies that savings are populated correctly on the application and its measures, when measures are
     * inserted.
     */
    static testMethod void testSavingsManualEntryOnMeasure() {
        List<Measure__c> measures = new List<Measure__c>();
        Measure__c measure;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;

        // Creates an ACQC Application
        createACQCApplication();
        application.Climate_Zone__c = 2;
        application.Total_Unit_Capacity__c = 2;
        update application;

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // There isn't any measure so verify savings are null
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);

        // Get map for those combinations we want (Climate_Zone__c = 2 & Measure_Code__c = Tk10 or H796)
        Map<String, MeasureUtils.measureSavingsWrapper> measureSavingsMap = MeasureUtils.getMeasureSavingsMetadata(
                new Set<Integer>{2}, new Set<String>{'TK10', 'H796'});

        // NEED TO CHANGE AFTER CHANGE REBATE TYPES TO MEASURE TYPE CUSTOM METADATA
        // Create Rebate types for those measures we want to create
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 25, 'TK10',
                'Replacement Blower Motor'));
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Enhanced Time Delay Relay', 25, 'H796',
                'Enhanced Time Delay Relay'));

        Test.startTest();
        insert rebateTypesList;
        // Create Measures
        measure = BIGPortalTestUtils.createMeasure('TK10', application.Id);
        measure.Application__r = application;
        measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
        measure.Rebate_Type__c = rebateTypesList.get(0).Id;
        measure.Measure_Code__c = 'TK10';
        measures.add(measure);
        measure = BIGPortalTestUtils.createMeasure('H796', application.Id);
        measure.Application__r = application;
        measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
        measure.Rebate_Type__c = rebateTypesList.get(1).Id;
        measure.Measure_Code__c = 'H796';
        measures.add(measure);
        insert measures;

        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{application.Id});
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        String climateZone = (String.valueOf(application.Climate_Zone__c)).leftPad(2, '0');

        // Verify saving populated on measure for Measure Code TK10
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).thermsSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).Therms_Savings__c);
        // Verify saving populated on measure for Measure Code H796
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).thermsSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Get application savings by summing its measure savings
        sumKwSavings = (measureMap.get('TK10' + climateZone).kW_Savings__c
                + measureMap.get('H796' + climateZone).kW_Savings__c);
        sumKwhSavings = (measureMap.get('TK10' + climateZone).kWh_Savings__c
                + measureMap.get('H796' + climateZone).kWh_Savings__c);
        sumThermSavings = (measureMap.get('TK10' + climateZone).Therms_Savings__c
                + measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Verify application data
        System.assertEquals(sumKwSavings, application.kW_Savings__c);
        System.assertEquals(sumKwhSavings, application.kWh_Savings__c);
        System.assertEquals(sumThermSavings, application.Therms_Savings__c);

        // Populate manually savings on measures
        measures = new List<Measure__c>();
        measure = measureMap.get('H796' + climateZone);
        measure.kW_Savings__c = 10;
        measure.kWh_Savings__c = 10;
        measure.Therms_Savings__c = 10;
        measures.add(measure);
        measure = measureMap.get('TK10' + climateZone);
        measure.kW_Savings__c = 5;
        measure.Therms_Savings__c = null;
        measures.add(measure);

        update measures;

        Test.stopTest();

        // Get last data on measures and on application
        measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{application.Id});
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Verify saving populated are we entered manually on measure for Measure Code TK10
        System.assertEquals(5, measureMap.get('TK10' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kWh_Savings__c);
        System.assertEquals(null, measureMap.get('TK10' + climateZone).Therms_Savings__c);
        // Verify saving populated are we entered manually on measure for Measure Code H796
        System.assertEquals(10, measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(10, measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(10, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Get application savings by summing its measure savings
        sumKwSavings = (measureMap.get('TK10' + climateZone).kW_Savings__c
                + measureMap.get('H796' + climateZone).kW_Savings__c);
        sumKwhSavings = (measureMap.get('TK10' + climateZone).kWh_Savings__c
                + measureMap.get('H796' + climateZone).kWh_Savings__c);

        // Verify application data
        System.assertEquals(sumKwSavings, application.kW_Savings__c);
        System.assertEquals(sumKwhSavings, application.kWh_Savings__c);
        System.assertEquals(measureMap.get('H796' + climateZone).Therms_Savings__c, application.Therms_Savings__c);
    }

    /**
     * Verify that savings fields (kW Savings, kWh Savings, Therms Savings) on the application aren't affected when
     * they are manually edited.
     * It also verifies that savings are populated correctly - on the application and its measures - when measures are
     * inserted.
     */
    static testMethod void testSavingsManualEntryOnApplication() {
        List<Measure__c> measures = new List<Measure__c>();
        Measure__c measure;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;

        // Creates an ACQC Application
        createACQCApplication();
        application.Climate_Zone__c = 2;
        application.Total_Unit_Capacity__c = 2;
        update application;

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // There isn't any measure so verify savings are null
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);

        // Get map for those combinations we want (Climate_Zone__c = 2 & Measure_Code__c = Tk10 or H796)
        Map<String, MeasureUtils.measureSavingsWrapper> measureSavingsMap = MeasureUtils.getMeasureSavingsMetadata(
                new Set<Integer>{2}, new Set<String>{'TK10', 'H796'});

        // NEED TO CHANGE AFTER CHANGE REBATE TYPES TO MEASURE TYPE CUSTOM METADATA
        // Create Rebate types for those measures we want to create
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 25, 'TK10',
                'Replacement Blower Motor'));
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Enhanced Time Delay Relay', 25, 'H796',
                'Enhanced Time Delay Relay'));

        Test.startTest();
        insert rebateTypesList;
        // Create Measures
        measure = BIGPortalTestUtils.createMeasure('TK10', application.Id);
        measure.Application__r = application;
        measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
        measure.Rebate_Type__c = rebateTypesList.get(0).Id;
        measure.Measure_Code__c = 'TK10';
        measures.add(measure);
        measure = BIGPortalTestUtils.createMeasure('H796', application.Id);
        measure.Application__r = application;
        measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
        measure.Rebate_Type__c = rebateTypesList.get(1).Id;
        measure.Measure_Code__c = 'H796';
        measures.add(measure);
        insert measures;

        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{application.Id});
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        String climateZone = (String.valueOf(application.Climate_Zone__c)).leftPad(2, '0');

        // Verify saving populated on measure for Measure Code TK10
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).thermsSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).Therms_Savings__c);
        // Verify saving populated on measure for Measure Code H796
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).thermsSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Get application savings by summing its measure savings
        sumKwSavings = (measureMap.get('TK10' + climateZone).kW_Savings__c
                + measureMap.get('H796' + climateZone).kW_Savings__c);
        sumKwhSavings = (measureMap.get('TK10' + climateZone).kWh_Savings__c
                + measureMap.get('H796' + climateZone).kWh_Savings__c);
        sumThermSavings = (measureMap.get('TK10' + climateZone).Therms_Savings__c
                + measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Verify application data
        System.assertEquals(sumKwSavings, application.kW_Savings__c);
        System.assertEquals(sumKwhSavings, application.kWh_Savings__c);
        System.assertEquals(sumThermSavings, application.Therms_Savings__c);

        // Populate manually savings on application
        application.kW_Savings__c = 999;
        application.kWh_Savings__c = 999;
        application.Therms_Savings__c = 999;
        update application;

        Test.stopTest();

        // Get last data on Application
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Verify application data
        System.assertEquals(sumKwSavings, application.kW_Savings__c);
        System.assertEquals(sumKwhSavings, application.kWh_Savings__c);
        System.assertEquals(sumThermSavings, application.Therms_Savings__c);
    }

    /**
     * Verify that savings fields (kW Savings, kWh Savings, Therms Savings) on the application are set to null when
     * all its related measures are deleted.
     * It also verifies that savings are populated correctly - on the application and its measures - when measures are
     * inserted.
     */
    static testMethod void testSavingsOnMeasureDelete() {
        List<Measure__c> measures = new List<Measure__c>();
        Measure__c measure;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;

        // Creates an ACQC Application
        createACQCApplication();
        application.Climate_Zone__c = 2;
        application.Total_Unit_Capacity__c = 2;
        update application;

        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // There isn't any measure so verify savings are null
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);

        // Get map for those combinations we want (Climate_Zone__c = 2 & Measure_Code__c = Tk10 or H796)
        Map<String, MeasureUtils.measureSavingsWrapper> measureSavingsMap = MeasureUtils.getMeasureSavingsMetadata(
                new Set<Integer>{2}, new Set<String>{'TK10', 'H796'});

        // NEED TO CHANGE AFTER CHANGE REBATE TYPES TO MEASURE TYPE CUSTOM METADATA
        // Create Rebate types for those measures we want to create
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 25, 'TK10',
                'Replacement Blower Motor'));
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Enhanced Time Delay Relay', 25, 'H796',
                'Enhanced Time Delay Relay'));

        Test.startTest();

        insert rebateTypesList;
        // Create Measures
        measure = BIGPortalTestUtils.createMeasure('TK10', application.Id);
        measure.Application__r = application;
        measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
        measure.Rebate_Type__c = rebateTypesList.get(0).Id;
        measure.Measure_Code__c = 'TK10';
        measures.add(measure);
        measure = BIGPortalTestUtils.createMeasure('H796', application.Id);
        measure.Application__r = application;
        measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
        measure.Rebate_Type__c = rebateTypesList.get(1).Id;
        measure.Measure_Code__c = 'H796';
        measures.add(measure);
        insert measures;

        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(new Set<Id>{application.Id});
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        String climateZone = (String.valueOf(application.Climate_Zone__c)).leftPad(2, '0');

        // Verify saving populated on measure for Measure Code TK10
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).thermsSavings
                * application.Total_Unit_Capacity__c, measureMap.get('TK10' + climateZone).Therms_Savings__c);
        // Verify saving populated on measure for Measure Code H796
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).kW_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwhSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).kWh_Savings__c);
        System.assertEquals(measureSavingsMap.get('H796_' + climateZone).thermsSavings
                * application.Total_Unit_Capacity__c, measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Get application savings by summing its measure savings
        sumKwSavings = (measureMap.get('TK10' + climateZone).kW_Savings__c
                + measureMap.get('H796' + climateZone).kW_Savings__c);
        sumKwhSavings = (measureMap.get('TK10' + climateZone).kWh_Savings__c
                + measureMap.get('H796' + climateZone).kWh_Savings__c);
        sumThermSavings = (measureMap.get('TK10' + climateZone).Therms_Savings__c
                + measureMap.get('H796' + climateZone).Therms_Savings__c);

        // Verify application data
        System.assertEquals(sumKwSavings, application.kW_Savings__c);
        System.assertEquals(sumKwhSavings, application.kWh_Savings__c);
        System.assertEquals(sumThermSavings, application.Therms_Savings__c);

        // Delete all application's measures
        List<Measure__c> measuresToDelete = application.Measures__r;
        delete measuresToDelete;

        Test.stopTest();

        // Get last data on Application
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);

        // Verify application data
        System.assertEquals(null, application.kW_Savings__c);
        System.assertEquals(null, application.kWh_Savings__c);
        System.assertEquals(null, application.Therms_Savings__c);
    }

    /**
     * Verify Savings population on Application and Measures for ACQC after insert a bulk of applications.
     */
    static testMethod void testSavingsBulkApplications() {
        List<Measure__c> measures = new List<Measure__c>();
        List<Application__c> applications = new List<Application__c>();
        Set<Id> applicationIds = new Set<Id>();
        Measure__c measure;
        Decimal sumKwSavings = 0;
        Decimal sumKwhSavings = 0;
        Decimal sumThermSavings = 0;
        Integer i = 0;

        // Create 20 ACQC Applications
        for (i = 0; i < 20; i++) {
            applications.add(BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE));
        }
        insert applications;

        i = 0;
        for (Application__c app : applications) {
            if (i < 10) {
                app.Climate_Zone__c = 1;
            } else {
                app.Climate_Zone__c = 2;
            }
            app.Total_Unit_Capacity__c = 2;
            applicationIds.add(app.Id);
            i++;
        }
        update applications;

        // Get map for those combinations we want (Climate_Zone__c = 2 & Measure_Code__c = Tk10 or H796)
        Map<String, MeasureUtils.measureSavingsWrapper> measureSavingsMap = MeasureUtils.getMeasureSavingsMetadata(
                new Set<Integer>{2, 1}, new Set<String>{'TK10', 'H796'});

        // NEED TO CHANGE AFTER CHANGE REBATE TYPES TO MEASURE TYPE CUSTOM METADATA
        // Create Rebate types for those measures we want to create
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 25, 'TK10',
                'Replacement Blower Motor'));
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Enhanced Time Delay Relay', 25, 'H796',
                'Enhanced Time Delay Relay'));
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Refrigerant System Service', 25, 'TK103',
                'Refrigerant System Service'));
        Test.startTest();
        insert rebateTypesList;
        for (Application__c app : applications) {
            measure = BIGPortalTestUtils.createMeasure('TK10', app.Id);
            measure.Application__r = app;
            measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
            measure.Rebate_Type__c = rebateTypesList.get(0).Id;
            measure.Measure_Code__c = 'TK10';
            measures.add(measure);
            measure = BIGPortalTestUtils.createMeasure('H796', app.Id);
            measure.Application__r = app;
            measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
            measure.Rebate_Type__c = rebateTypesList.get(1).Id;
            measure.Measure_Code__c = 'H796';
            measures.add(measure);
        }
        insert measures;
        update applications;
        Test.stopTest();

        // Get last data on measures and on the application
        Map<String, Measure__c> measureMap = BIGPortalTestUtils.getMeasures(applicationIds);
        applications = BIGPortalTestUtils.getApplicationsById(applicationIds);
        String climateZone;

        for (Application__c app : applications) {
            climateZone = (String.valueOf(app.Climate_Zone__c)).leftPad(2, '0');
            // Verify saving populated on measure for Measure Code TK103
            System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwSavings * app.Total_Unit_Capacity__c,
                    measureMap.get('TK10' + climateZone).kW_Savings__c);
            System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).kwhSavings * app.Total_Unit_Capacity__c,
                    measureMap.get('TK10' + climateZone).kWh_Savings__c);
            System.assertEquals(measureSavingsMap.get('TK10_' + climateZone).thermsSavings * app.Total_Unit_Capacity__c,
                    measureMap.get('TK10' + climateZone).Therms_Savings__c);
            // Verify saving populated on measure for Measure Code H796
            System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwSavings * app.Total_Unit_Capacity__c,
                    measureMap.get('H796' + climateZone).kW_Savings__c);
            System.assertEquals(measureSavingsMap.get('H796_' + climateZone).kwhSavings * app.Total_Unit_Capacity__c,
                    measureMap.get('H796' + climateZone).kWh_Savings__c);
            System.assertEquals(measureSavingsMap.get('H796_' + climateZone).thermsSavings * app.Total_Unit_Capacity__c,
                    measureMap.get('H796' + climateZone).Therms_Savings__c);

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
    }

    /**
     * Verify that the application's measure combination is populated correctly when a measure in inserted through SF.
     */
    static testMethod void testMeasureCombinationOnManualInsert() {
        List<Measure__c> measures = new List<Measure__c>();
        List<Measure__c> measuresToDelete = new List<Measure__c>();
        List<String> measureCodes = new List<String>();
        Measure__c measure;

        // Create application
        createACQCApplication();
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Create rebate types
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 250, 'TK10',
                'Replacement Blower Motor'));
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Enhanced Time Delay Relay', 50, 'H796',
                'Enhanced Time Delay Relay'));
        insert rebateTypesList;
        // Create measures
        measure = BIGPortalTestUtils.createACQCMeasure('TK10', application.Id, rebateTypesList.get(0).Id, 'TK10');
        measures.add(measure);
        measure = BIGPortalTestUtils.createACQCMeasure('H796', application.Id, rebateTypesList.get(1).Id, 'H796');
        measures.add(measure);

        Test.startTest();
        insert measures;
        // Get the application with its measures.
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Set list of measure codes to verify that the measure combination was populated correctly.
        // It should be (H796, TK10).
        for (Measure__c m : application.Measures__r) {
            measureCodes.add(m.Measure_Code__c);
        }
        measureCodes.sort();
        // Verify that the Measure Combination was populated correctly.
        System.assertEquals(String.join(measureCodes, ','), application.Measure_Combination__c);

        // Insert a new measure manually.
        Rebate_Type__c rebateType = new Rebate_Type__c();
        rebateType = BIGPortalTestUtils.createRebateType('Full ACCA Standard 4 HVAC System Assessment', 75, 'TK07',
                'Full ACCA Standard 4 HVAC System Assessment');
        insert rebateType;
        // Create measures
        measure = BIGPortalTestUtils.createACQCMeasure('TK07', application.Id, rebateType.Id, 'TK07');
        insert measure;
        Test.stopTest();

        // Get the application with its measures.
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Set list of measure codes to verify that the measure combination was re-populated correctly.
        // It should be (H796, TK07, TK10).
        measureCodes = new List<String>();
        for (Measure__c m : application.Measures__r) {
            measureCodes.add(m.Measure_Code__c);
        }
        measureCodes.sort();
        // Verify that the Measure Combination was re-populated correctly.
        System.assertEquals(String.join(measureCodes, ','), application.Measure_Combination__c);
    }

    /**
     * Verify that the application's measure combination is populated correctly when a measure in deleted through SF.
     */
    static testMethod void testMeasureCombinationOnManualDelete() {
        List<Measure__c> measures = new List<Measure__c>();
        List<Measure__c> measuresToDelete = new List<Measure__c>();
        List<String> measureCodes = new List<String>();
        Measure__c measure;

        // Create application
        createACQCApplication();
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Create rebate types
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 250, 'TK10',
                'Replacement Blower Motor'));
        rebateTypesList.add(BIGPortalTestUtils.createRebateType('Enhanced Time Delay Relay', 50, 'H796',
                'Enhanced Time Delay Relay'));
        insert rebateTypesList;
        // Create measures
        measure = BIGPortalTestUtils.createACQCMeasure('TK10', application.Id, rebateTypesList.get(0).Id, 'TK10');
        measures.add(measure);
        measure = BIGPortalTestUtils.createACQCMeasure('H796', application.Id, rebateTypesList.get(1).Id, 'H796');
        measures.add(measure);
        insert measures;
        // Get the application with its measures.
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Set list of measure codes to verify that the measure combination was populated correctly.
        // It should be (H796, TK10).
        for (Measure__c m : application.Measures__r) {
            measureCodes.add(m.Measure_Code__c);
        }
        measureCodes.sort();
        // Verify that the Measure Combination was populated correctly.
        System.assertEquals(String.join(measureCodes, ','), application.Measure_Combination__c);

        // Get the TK10 measure in order to delete it.
        for (Measure__c m : application.Measures__r) {
            if (m.Measure_Code__c == 'TK10') {
                measuresToDelete.add(m);
                break;
            }
        }
        Test.startTest();
        // Delete the TK10 measure.
        delete measuresToDelete;
        // Get the application with its measures.
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Set list of measure codes to verify that the measure combination was re-populated correctly.
        // It should be (H796, TK07).
        measureCodes = new List<String>();
        for (Measure__c m : application.Measures__r) {
            measureCodes.add(m.Measure_Code__c);
        }
        measureCodes.sort();
        // Verify that the Measure Combination was re-populated correctly.
        System.assertEquals(String.join(measureCodes, ','), application.Measure_Combination__c);

        // Get the rest of the measures in order to delete them.
        measuresToDelete = new List<Measure__c>();
        for (Measure__c m : application.Measures__r) {
            measuresToDelete.add(m);
        }
        // Delete all the application's measures.
        delete measuresToDelete;
        Test.stopTest();
        // Get the application with its measures.
        application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{application.Id}).get(0);
        // Verify that the Measure Combination is null.
        System.assertEquals(null, application.Measure_Combination__c);
    }

    // Application generator
    private static void createNewApplication() {
        applicationListACQC = new List<Application__c>();
        applicationListHU = new List<Application__c>();
        applicationListAHU = new List<Application__c>();

        // Create test Applications and insert it into the database
        for(integer i=0 ; i<batchSizeApps ; i++) {
            Application__c testApplicationACQC = new Application__c();
            Application__c testApplicationHUP = new Application__c();
            Application__c testApplicationAHUP = new Application__c();

            // Preparing data, charging lists
            testApplicationACQC.RecordTypeId = ApplicationUtils.ACQC_RECORD_TYPE;
            testApplicationHUP.RecordTypeId = ApplicationUtils.HUP_RECORD_TYPE;
            testApplicationAHUP.RecordTypeId = ApplicationUtils.AHUP_RECORD_TYPE;

            testApplicationACQC.Last_Application_Submission_Date__c = DateTime.parse('8/31/2014 10:49 PM');
            testApplicationHUP.Last_Application_Submission_Date__c = DateTime.parse('8/31/2014 10:49 PM');
            testApplicationAHUP.Preapplication_Submitted__c = Date.parse('8/31/2014');

            testApplicationACQC.Application_Approval_Date__c = Date.parse('8/31/2014');
            testApplicationHUP.Application_Approval_Date__c = Date.parse('8/31/2014');
            testApplicationAHUP.Full_Application_Approved__c = Date.parse('8/31/2014');

            testApplicationACQC.Contractor__c = account.Id;
            testApplicationHUP.Contractor__c = account.Id;
            testApplicationAHUP.Contractor__c = account.Id;
            testApplicationACQC.Customer_Email__c = 'test@test.com' + String.valueOf(i);
            testApplicationHUP.Customer_Email__c = 'test@test.com' + String.valueOf(i);
            testApplicationAHUP.Customer_Email__c = 'test@test.com' + String.valueOf(i);

            applicationListACQC.add(testApplicationACQC);
            applicationListHU.add(testApplicationHUP);
            applicationListAHU.add(testApplicationAHUP);
        }
        List<Application__c> applications = new List<Application__c>(applicationListACQC);
        applications.addAll(applicationListHU);
        applications.addAll(applicationListAHU);
        insert applications;
    }

    private static void createTestData(Boolean relatedZipCodes) {
        applicationListACQC = new List<Application__c>();
        applicationListHU = new List<Application__c>();
        getZipCodes();

        for (Zip_Code__mdt zipCodeMdt : zipCodes.values()) {
            Application__c testApplicationACQC = new Application__c();
            Application__c testApplicationHUP = new Application__c();
            testApplicationACQC.RecordTypeId = ApplicationUtils.ACQC_RECORD_TYPE;
            testApplicationHUP.RecordTypeId = ApplicationUtils.HUP_RECORD_TYPE;
            testApplicationACQC.Customer_Email__c = 'test@test.com' + zipCodeMdt.Zip_Code__c;
            testApplicationHUP.Customer_Email__c = 'test@test.com' + zipCodeMdt.Zip_Code__c;
            testApplicationHUP.Air_Conditioning__c = 'Packaged DX'; // 1940-2014
            testApplicationHUP.Year_Built__c = String.valueOf(Math.round(Math.random() * 74) + 1940);
            testApplicationHUP.Number_of_Stories__c = Math.round(Math.random() * 2) + 1; // 1-3
            testApplicationHUP.Gas_Provider__c = 'Pacific Gas and Electric Company';
            testApplicationHUP.Electric_Provider__c = 'Pacific Gas and Electric Company';

            if (relatedZipCodes) {
                testApplicationACQC.Building_Zip_Code__c = zipCodeMdt.Zip_Code__c;
                testApplicationHUP.Building_Zip_Code__c = zipCodeMdt.Zip_Code__c;
                testApplicationHUP.Customer_Zip_Code__c = zipCodeMdt.Zip_Code__c;
            }
            applicationListACQC.add(testApplicationACQC);
            applicationListHU.add(testApplicationHUP);
        }
        List<Application__c> applications = new List<Application__c>(applicationListACQC);
        applications.addAll(applicationListHU);
        insert applications;
    }

    /**
     * Get Zip Code Data.
     */
    private static void getZipCodes() {
        zipCodes = new Map<String, Zip_Code__mdt>();
        try {
            for (Zip_Code__mdt zipCodeMdt : [
                    SELECT Id, Climate_Zone__c, Zip_Code__c, PGE_Territory__c, County__c
                    FROM Zip_Code__mdt
                    LIMIT :batchSize
                    ]) {
                zipCodes.put(zipCodeMdt.Zip_Code__c, zipCodeMdt);
            }
        } catch(Exception e) {
            System.debug('Couldn\'t get Zip Code data. Error: ' + e.getMessage());
        }
    }

    /**
     * Get Measure Combination Code Metadata based on a buildingVintage, ClimateZone and a MeasureCode.
     *
     * @param buildingVintage string of buildingVintage field to filter by.
     * @param climateZone integer of climateZone field to filter by.
     * @param measureCode string of measureCode to filter by.
     * @return A Measure_Savings__mdt record from metadata obtained from filters.
     */
    private static Measure_Savings__mdt getMeasureCombinationCodeMdt(String buildingVintage, Integer climateZone,
            String measureCode) {
        Measure_Savings__mdt measureCombinationCodeMdt = new Measure_Savings__mdt();
        try {
            measureCombinationCodeMdt = [
                SELECT Label, Measure_Combination__c, kW_Savings__c, kWh_Savings__c, Therms_Savings__c,
                    Incremental_Measure_Cost__c, kW_Savings_2nd_BL__c, kWh_Savings_2nd_BL__c, Therms_Savings_2nd_BL__c,
                    Incremental_Measure_Cost_2nd_BL__c, Measure_Combination_Size__c, Building_Vintage__c,
                    Climate_Zone__c, DeveloperName, MasterLabel
                FROM Measure_Savings__mdt
                WHERE Building_Vintage__c = :buildingVintage
                    AND Climate_Zone__c = :climateZone
                    AND Measure_Combination__c = :measureCode
                ];
        } catch (QueryException e) {
            System.debug('Error: Couldn\'t get Measure_Savings__mdt. Message: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }

        return measureCombinationCodeMdt;
    }

    /**
     * Check if the information populated on application for hybrid type, is the expected.
     *
     * @param Metadata of measures.
     * @param Application which information is populated.
     * @param List sorted of combination abbreviation codes.
     */
    private static void assertMeasureCodeCombinationMatchResults(Measure_Savings__mdt measureCombinationCodeMdt,
            Application__c app, List<String> measureCombinationAbbreviationToSort) {
        measureCombinationAbbreviationToSort.sort();
        System.assertEquals(ApplicationUtils.HYBRID_PACKAGE_TYPE, app.Package_Type__c);
        System.assertEquals(false, app.Override_Package_Type__c);
        System.assertEquals(measureCombinationCodeMdt.MasterLabel, app.Measure_Combination_Code__c);
        System.assertEquals(measureCombinationCodeMdt.Measure_Combination__c, app.Measure_Combination__c);
        System.assertEquals(String.join(measureCombinationAbbreviationToSort, ','),
                app.Measure_Combination_Abbreviation__c);
        System.assertEquals(measureCombinationCodeMdt.kWh_Savings__c, app.kWh_Savings__c);
        System.assertEquals(measureCombinationCodeMdt.kW_Savings__c, app.kW_Savings__c);
        System.assertEquals(measureCombinationCodeMdt.Therms_Savings__c, app.Therms_Savings__c);
        System.assertEquals(measureCombinationCodeMdt.Therms_Savings_2nd_BL__c, app.Therms_Savings_2nd_BL__c);
        System.assertEquals(measureCombinationCodeMdt.Incremental_Measure_Cost__c, app.Incremental_Measure_Cost__c);
        System.assertEquals(measureCombinationCodeMdt.Incremental_Measure_Cost_2nd_BL__c,
                app.Incremental_Measure_Cost_2nd_BL__c);
        System.assertEquals(measureCombinationCodeMdt.kWh_Savings_2nd_BL__c, app.kWh_Savings_2nd_BL__c);
        System.assertEquals(measureCombinationCodeMdt.kW_Savings_2nd_BL__c, app.kW_Savings_2nd_BL__c);
    }

    /**
     * Create a HUP Application with Climate Zone 1 and Building Vintage 'New'.
     */
    private static void createHUPApplication() {
        // Create a HUP Application
        application = BIGPortalTestUtils.createApplication(ApplicationUtils.HUP_RECORD_TYPE);
        insert application;
        // Update app with Building Vintage and Climate Zone (not on insert because it sets both to null)
        application.Climate_Zone__c = 1;
        application.Building_Vintage__c = 'NEW';
        update application;
    }

    /**
     * Initialize the application and the measure types.
     */
    private static void initMeasureCombinationData() {
        // Create a HUP Application
        createHUPApplication();
        // Create measures types, they should form this unique identifier --> HV076_1996_01
        createMeasureTypesWithUniqueIdentifier();
    }

    /**
     * Create measures types, they should form this unique identifier --> HV076_1996_01.
     */
    private static void createMeasureTypesWithUniqueIdentifier() {
        Set<String> recordNames = new Set<String>{'F92', 'ACS15', 'DS10'};
        measureTypesList = BIGPortalTestUtils.getMeasureTypes(recordNames);
    }

    /**
     * Creates an ACQC Application.
     */
    private static void createACQCApplication() {
        // Creates an ACQC Application
        application = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        insert application;
    }
}