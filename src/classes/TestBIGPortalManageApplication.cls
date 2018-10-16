/**
 * This class contains unit tests for validating the behavior
 * of Manage Application on PG&E Portal.
 */
@isTest
private class TestBIGPortalManageApplication {

    private static User portalUser;
    private static Dwelling_Unit__c dwellingUnit;
    private static Building__c building;
    private static Account portalAccount;
    private static Contact portalContact;
    private static Utility_Account__c utilityAcc;
    private static Contact propertyOwner;

    private static void initData() {
        // Create Account
        portalAccount = BIGPortalTestUtils.createAccount('portalAccount');
        portalAccount.Phone = '636-233-4444';
        portalAccount.BillingStreet = '123 Lincoln Road';
        portalAccount.BillingCity = 'St. Louis';
        portalAccount.BillingState = 'MO';
        portalAccount.BillingPostalCode = '63303';
        portalAccount.Tax_ID_Number__c = '123456789';
        portalAccount.Tax_Status__c = 'S Corporation';
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

        // Get a valid zip code which contains a climate zone and a county.
        String zipCode = BIGPortalTestUtils.getZipCodeWithClimateZoneAndCounty();

        // Create Building
        building = BIGPortalTestUtils.createBuilding('Joe Doe Building', 'Single Family Detached',
                'Building Street Address', 'Building City', 'CA', zipCode, 'Building County',
                 portalAccount.Id);
        insert building;
        System.assertNotEquals(null, building.Id);

        // Create Contact as Property Owner
        propertyOwner = BIGPortalTestUtils.createContact('Property Owner', 'Property Owner',
                'propertyOwner@test.com', '703-222-2222', portalAccount.Id);

        propertyOwner.MailingStreet = 'test';
        propertyOwner.MailingCity = 'test';
        PropertyOwner.MailingState = 'CA';
        propertyOwner.MailingPostalCode = '12345';
        propertyOwner.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
                .get('Property Owner').getRecordTypeId();
        insert propertyOwner;
        System.assertNotEquals(null, propertyOwner.Id);

        // Create Dwelling Unit
        dwellingUnit = BIGPortalTestUtils.createDwellingUnit('DW Street Address', '10', propertyOwner.Id,
                building.Id, Decimal.valueOf(3), Decimal.valueOf(6), Decimal.valueOf(2), Decimal.valueOf(100),
                '1983', 'Vented Attic', Decimal.valueOf(1000), 'Room AC', Decimal.valueOf(20),
                'Slab-On-Grade', 'Room AC', 'Electricity', 'Storage Water Heater', 'Electricity', 'Solar PV');

        dwellingUnit.Dwelling_Unit_Name__c = 'Test Dwelling Unit';
        insert dwellingUnit;
        System.assertNotEquals(null, dwellingUnit.Id);

        // Create Utility Account
        utilityAcc = BIGPortalTestUtils.createUtilityAccount('the', 'tester', '(123) 123-3242',
                'Pacific Gas and Electric Company', '8998988909', 'Pacific Gas and Electric Company',
                '1231213213', dwellingUnit.Id);

        insert utilityAcc;
        System.assertNotEquals(null, utilityAcc.Id);

        // Assign Contractor to Dwelling Unit
        dwellingUnit.Property_Owner__r = propertyOwner;
        // Assign Building to Dwelling Unit
        dwellingUnit.Building__r = building;

        // Create custom setting
        BIGPortalTestUtils.createCustomSetting();

        // Create BPI Analyst
        Contact BPIAnalyst = BIGPortalTestUtils.createBPIAnalyst('fname', 'lname', 'test@test.com',
                '(234) 234-3243', '1234567', Date.today(), portalAccount);
        insert BPIAnalyst;
        Credential__c cre = BIGPortalTestUtils.createCredential(portalAccount, BPIAnalyst);
        cre.Credential_Type__c = 'BPI Certification';
        insert cre;

        System.assertNotEquals(null, BPIAnalyst);

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
        // Set rowCause to 'manual' for manual sharing.
        // This line can be omitted as 'manual' is the default value for sharing objects.
        //jobShr.RowCause = Schema.AccountShare.RowCause.Manual;

        // Insert the sharing record and capture the save result.
        // The false parameter allows for partial processing if multiple records passed
        // into the operation.
        Database.SaveResult sr = Database.insert(jobShr,false);

    }

    static testMethod void testBIGPortalManageApplication() {
        initData();
        test.startTest();

        System.runAs(portalUser) {

            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set dates for WorkerStartDate and WorkerFinishDate
            appController.application.Work_Start_Date__c = Date.today();
            appController.application.Work_Finish_Date__c = Date.today();
            appController.application.Test_In_Date__c = Date.today();
            appController.application.Test_Out_Date__c = Date.today();
            appController.application.Completed_Cost__c = 3000;
            // Set Application Rebate Type to Account Holder
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(1).getValue();
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = appController.getMeasureTypesAtticInsulation().get(0).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(1).getValue());
            // Add water heater measures
            appController.flexMeasureWaterHeater = appController.getMeasuresFlexWaterHeater().get(0).getValue();
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');

            List<Contact> analysts = appController.getAnalysts();
            Integer result = analysts.size();
            System.assertEquals(result, 1);

            System.currentPageReference().getParameters().put('BPIAnalyst', analysts.get(0).Id);

            String nonAccountOwnerDownloadLink = appController.getNonAccountOwnerDownloadLink();
            System.assertEquals(nonAccountOwnerDownloadLink, '');

            String contractorPayeeDownloadLink = appController.getContractorPayeeDownloadLink();
            System.assertEquals(contractorPayeeDownloadLink, '');

            Boolean hasAdvancedHUProgram = appController.getHasAdvancedHUProgram();
            System.assertEquals(hasAdvancedHUProgram, true);

            appController.submitApplication();
            Application__c createdApp = appController.application;

            // Test Review
            pageRef = Page.BIGHUPApplicationReview;
            Test.setCurrentPage(pageRef);

            BIGHUPApplicationReviewController reviewController = new BIGHUPApplicationReviewController();
            Application__c app = reviewController.getApplication();
            System.assertEquals(null, app.Id);

            ApexPages.currentPage().getParameters().put('id', 'Invalid ID');
            app = reviewController.getApplication();
            Review__c review = reviewController.getReview();
            System.assertEquals(null, app.Id);
            System.assertEquals(null, review.Id);

            ApexPages.currentPage().getParameters().put('id', createdApp.Id);
            review = reviewController.getReview();
            System.assertNotEquals(null, review.Id);
            reviewController.checkAction();
            review.Status__c = 'Correction Required';
            update review;
            reviewController.checkAction();
            review.Status__c = 'Rejected';
            update review;
            reviewController.checkAction();
            review.Status__c = 'Approved';
            update review;
            reviewController.checkAction();
            reviewController.getReviewMessages();
            reviewController.getHasError();
            app = reviewController.getApplication();
            System.assertNotEquals(null, app.Id);

            Map<String, String> params = new Map<String, String> {
                        'recordType' => 'HUP',
                        'status' => null,
                        'startDate' => null,
                        'endDate' => null};

            String paramsHU = JSON.serialize(params);
            String paramsAHU = JSON.serialize(params.clone().put('recordType', 'AHUP'));

            // ### Test Applications List ###
            BIGPortalApplicationsListController appListController = new BIGPortalApplicationsListController();
            appListController.hasAdvancedHUProgram=false;
            appListController.setAccountId(appController.account.Id);
            System.assert(appListController.getAccountId() == appController.account.Id);
            System.assert(appListController.getApplications().size() > 0);
            System.assert(BIGPortalHVACDashboardController.getFilteredApplications(paramsHU).results.size() > 0);
            System.assert(BIGPortalHVACDashboardController.getFilteredApplications(paramsAHU).results.size() == 0);
            System.assert(appListController.getNumberOfPages() > 0);
            System.assert(appListController.getPageItems().size() > 0);
            // Change sorting direction on the list
            appListController.pageNumber = 1;
            appListController.orderBy = 'Dwelling_Unit_Name__c';
            appListController.toggleDirection();
            // Test List Methods
            System.assertEquals(false, appListController.getHasNext());
            System.assertEquals(false, appListController.getHasPrevious());
            System.assertEquals(1, appListController.getPageNumber());
            appListController.first();
            appListController.last();
            appListController.previous();
            appListController.next();
            // Test Tabs.
            System.assertEquals(null, appListController.getProgramTabSelection());
            BIGPortalApplicationsListController.saveProgramTabSelection('Advanced Home Upgrade');
            System.assertEquals('Advanced Home Upgrade', appListController.getProgramTabSelection());

            // ### Test Application Detail/Update ###
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', createdApp.Id);
            appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.getBaseMeasuresList();
            appController.getFlexMeasuresList();
            appController.getFlexMeasuresWaterHeaterList();
            appController.getKickerMeasuresList();
            appController.rebateAssignmetForm.Name = 'rebateAssignmetForm.test';
            appController.rebateAssignmetForm.Body = Blob.valueOf('rebateAssignmetForm BODY');
            appController.buildingPermit.Name = 'buildingPermit.test';
            appController.buildingPermit.Body = Blob.valueOf('buildingPermit BODY');

            // Set Default Payee Information for an Account Holder application
            Application__c accountHolderApp = appController.application;
            auxSetPayeeInformation(accountHolderApp);
            // Set Default Payee Information for a Non Account Holder application
            BIGPortalManageApplicationController newAppController = new BIGPortalManageApplicationController();
            newAppController.init();
            Application__c nonAccountHolderApp = newAppController.application;
            nonAccountHolderApp.Rebate_Assignment__c = newAppController.getRebateTypes().get(1).getValue();
            auxSetPayeeInformation(nonAccountHolderApp);
            // Set Default Payee Information for a Contractor Payee application
            BIGPortalManageApplicationController newNewAppController = new BIGPortalManageApplicationController();
            newNewAppController.init();
            Application__c contractorPayeeApp = newNewAppController.application;
            contractorPayeeApp.Rebate_Assignment__c = newNewAppController.getRebateTypes().get(2).getValue();
            auxSetPayeeInformation(contractorPayeeApp);
        }

    }

    private static void auxSetPayeeInformation(Application__c app) {
        if (app.Rebate_Assignment__c == 'Account Holder') {
            app.Payee_Full_Name__c = utilityAcc.Account_Holder_First_Name__c + ' ' +
                    utilityAcc.Account_Holder_Last_Name__c;
            app.Payee_Phone__c = utilityAcc.Phone__c;
            app.Payee_Street_Address__c = dwellingUnit.Building__r.Street_Address__c;
            app.Payee_City__c = dwellingUnit.Building__r.City__c;
            app.Payee_State__c = dwellingUnit.Building__r.State__c;
            app.Payee_ZIP_Code__c = dwellingUnit.Building__r.ZIP_Code__c;
        } else if (app.Rebate_Assignment__c == 'Non Account Holder') {
            app.Payee_Full_Name__c = dwellingUnit.Property_Owner__r.FirstName + ' ' +
                    dwellingUnit.Property_Owner__r.LastName;
            app.Payee_Phone__c = dwellingUnit.Property_Owner__r.Phone;
            app.Payee_Street_Address__c = dwellingUnit.Property_Owner__r.MailingStreet;
            app.Payee_City__c = dwellingUnit.Property_Owner__r.MailingCity;
            app.Payee_State__c = dwellingUnit.Property_Owner__r.MailingState;
            app.Payee_ZIP_Code__c = dwellingUnit.Property_Owner__r.MailingPostalCode;
        } else if (app.Rebate_Assignment__c == 'Contractor Payee') {
            app.Payee_Full_Name__c = portalAccount.Name;
            app.Payee_Phone__c = portalAccount.Phone;
            app.Payee_Street_Address__c = portalAccount.BillingStreet;
            app.Payee_City__c = portalAccount.BillingCity;
            app.Payee_State__c = portalAccount.BillingState;
            app.Payee_ZIP_Code__c = portalAccount.BillingPostalCode;
        }
    }

    /**
     * Test when application is saved and then change Building Fields on building, Application fields will change too
     */
    static testMethod void testApplicationSave() {
        initData();

        System.runAs(portalUser) {
            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            // Get Project Financing options to check later
            Map<String, List<String>> projectFinancingOptions = appController.getProjectFinancingOptions();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set Application Rebate Type
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Completed Cost
            appController.application.Completed_Cost__c = 3000;
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(0).getValue();
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = appController.getMeasureTypesAtticInsulation().get(0).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(1).getValue());
            appController.flexMeasureWaterHeater = appController.getMeasuresFlexWaterHeater().get(0).getValue();
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');
            // won't be valid
            appController.additionalDocuments.Name = 'testAdditionalDocuments.txt';
            appController.additionalDocuments.Body = Blob.valueOf('testAdditionalDocuments BODY');
            appController.bpiFileIdCard.Name = 'bpiFileTest.txt';
            appController.bpiFileIdCard.Body = Blob.valueOf('bpiFileTest BODY');

            List<Contact> analysts = appController.getAnalysts();
            Integer result = analysts.size();
            System.assertEquals(result, 1);

            String nonAccountOwnerDownloadLink = appController.getNonAccountOwnerDownloadLink();
            System.assertEquals(nonAccountOwnerDownloadLink, '');

            String contractorPayeeDownloadLink = appController.getContractorPayeeDownloadLink();
            System.assertEquals(contractorPayeeDownloadLink, '');

            Boolean hasAdvancedHUProgram = appController.getHasAdvancedHUProgram();
            System.assertEquals(hasAdvancedHUProgram, true);
            // Add Project Financing option
            appController.application.Project_Financing_Source__c =
                    projectFinancingOptions.get('General Options').get(0);
            ApexPages.currentPage().getParameters().put('notes', 'testNotes');
            // Create a BPI Analyst to reach Save Application in controller
            appController.newBpiAnalystContact = BIGPortalTestUtils.createBPIAnalyst('fnamem', 'lnamem', 'test@test.com',
                    '(234) 234-3243', '1234567', Date.today(), portalAccount);
            ApexPages.currentPage().getParameters().put('BPIAnalyst', 'xxx');

            test.startTest();
            appController.saveApplication();
            test.stopTest();

            // Get application with latest changes
            Application__c application = BIGPortalTestUtils.getApplicationsById(
                    new Set<Id>{appController.application.Id}).get(0);
            // Check Financing Option is the same as we entered before
            System.assertEquals(projectFinancingOptions.get('General Options').get(0),
                    application.Project_Financing_Source__c);
            auxSaveApp(application);
            /*
             * If I make changes on the building object, these should be reflected on the Application fields when
             * I save/submit/resubmit the application again
             */
            building.Building_Name__c = 'Papas Manolo';
            building.Street_Address__c = 'My Street';
            building.Type__c = '2-4 Units';
            building.City__c = 'Maldonado city';
            building.State__c = 'MS';
            building.ZIP_Code__c = '20000';
            upsert building;

            // Create a BPI Analyst to reach Save Application in controller
            appController.newBpiAnalystContact = BIGPortalTestUtils.createBPIAnalyst('fnam', 'lnam', 'test@test.com',
                    '(234) 234-3243', '1234567', Date.today(), portalAccount);
            ApexPages.currentPage().getParameters().put('BPIAnalyst', 'xxx');

            // Change Project Financing Option
            appController.application.Project_Financing_Source__c = ApplicationUtils.SECURED_LOAN;
            appController.application.Project_Financing_Detail__c =
                    projectFinancingOptions.get('Secure Options').get(0);

            appController.saveApplication();

            // Get application with latest changes
            application = BIGPortalTestUtils.getApplicationsById(new Set<Id>{appController.application.Id}).get(0);

            auxSaveApp(application);
            // Check Project Financing Option is the same as we entered before
            System.assertEquals(ApplicationUtils.SECURED_LOAN, application.Project_Financing_Source__c);
            System.assertEquals(projectFinancingOptions.get('Secure Options').get(0),
                    application.Project_Financing_Detail__c);
        }
    }


    static testMethod void testIncentiveTotalCappedAtMaximumIcentiveConstant() {
        initData();

        System.runAs(portalUser) {

            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set Application Rebate Type
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Completed Cost
            appController.application.Completed_Cost__c = 6000;
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = getIncentiveAmount(appController.getMeasureTypesDuctImprovement(),
                    '_200').get(0);
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = getIncentiveAmount(appController.getMeasureTypesAtticInsulation(),
                    '_500').get(0);
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = getIncentiveAmount(appController.getMeasureTypesBuildingAirSealing(),
                    '_300').get(0);
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(getIncentiveAmount(appController.getMeasureTypesFlexMeasures(),
                    '_400').get(0));
            appController.flexMeasures.add(getIncentiveAmount(appController.getMeasureTypesFlexMeasures(),
                    '_400').get(1));
            // Set Water Heater
            appController.flexMeasureWaterHeater = getIncentiveAmount(appController.getMeasuresFlexWaterHeater(),
                    '_500').get(0);
            // Set Flex Measure Gas Heating (furnaces & wall heater)
            appController.flexMeasureGasHeating= getIncentiveAmount(appController.getMeasuresFlexGasHeating(),
                    '_400').get(0);

            List<Contact> analysts = appController.getAnalysts();
            Integer result = analysts.size();
            System.assertEquals(result, 1);

            String nonAccountOwnerDownloadLink = appController.getNonAccountOwnerDownloadLink();
            System.assertEquals(nonAccountOwnerDownloadLink, '');

            String contractorPayeeDownloadLink = appController.getContractorPayeeDownloadLink();
            System.assertEquals(contractorPayeeDownloadLink, '');

            Boolean hasAdvancedHUProgram = appController.getHasAdvancedHUProgram();
            System.assertEquals(hasAdvancedHUProgram, true);

            ApexPages.currentPage().getParameters().put('notes', 'testNotes');
            // Create a BPI Analyst to reach Save Application in controller
            appController.newBpiAnalystContact = BIGPortalTestUtils.createBPIAnalyst('fnamem', 'lnamem', 'test@test.com',
                    '(234) 234-3243', '1234567', Date.today(), portalAccount);
            ApexPages.currentPage().getParameters().put('BPIAnalyst', 'xxx');

            test.startTest();
            appController.saveApplication();
            test.stopTest();
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', appController.application.Id);
            appController.init();
            System.assertEquals(2700, appController.application.Sub_Total__c);
            System.assertEquals(2500, appController.application.Incentive_Total__c);
            System.assertEquals(ApplicationUtils.CREATED_STATUS, appController.application.Status__c);
        }
    }

    static testMethod void testIncentiveTotalCappedAtFiftyPercentCompletedCost() {
        initData();

        System.runAs(portalUser) {

            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set Application Rebate Type
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Completed Cost
            appController.application.Completed_Cost__c = 3500;
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = getIncentiveAmount(appController.getMeasureTypesDuctImprovement(),
                    '_200').get(0);
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = getIncentiveAmount(appController.getMeasureTypesAtticInsulation(),
                    '_500').get(0);
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = getIncentiveAmount(appController.getMeasureTypesBuildingAirSealing(),
                    '_300').get(0);
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(getIncentiveAmount(appController.getMeasureTypesFlexMeasures(),
                    '_400').get(0));
            appController.flexMeasures.add(getIncentiveAmount(appController.getMeasureTypesFlexMeasures(),
                    '_400').get(1));

            List<Contact> analysts = appController.getAnalysts();
            Integer result = analysts.size();
            System.assertEquals(result, 1);

            String nonAccountOwnerDownloadLink = appController.getNonAccountOwnerDownloadLink();
            System.assertEquals(nonAccountOwnerDownloadLink, '');

            String contractorPayeeDownloadLink = appController.getContractorPayeeDownloadLink();
            System.assertEquals(contractorPayeeDownloadLink, '');

            Boolean hasAdvancedHUProgram = appController.getHasAdvancedHUProgram();
            System.assertEquals(hasAdvancedHUProgram, true);

            ApexPages.currentPage().getParameters().put('notes', 'testNotes');
            // Create a BPI Analyst to reach Save Application in controller
            appController.newBpiAnalystContact = BIGPortalTestUtils.createBPIAnalyst('fnamem', 'lnamem', 'test@test.com',
                    '(234) 234-3243', '1234567', Date.today(), portalAccount);
            ApexPages.currentPage().getParameters().put('BPIAnalyst', 'xxx');

            test.startTest();
            appController.saveApplication();
            test.stopTest();
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', appController.application.Id);
            appController.init();
            System.assertEquals(1800, appController.application.Sub_Total__c);
            System.assertEquals(1750, appController.application.Incentive_Total__c);
            System.assertEquals(ApplicationUtils.CREATED_STATUS, appController.application.Status__c);
        }
    }

   static testMethod void testErrorCompletedCostLessThanMinimumIncentive() {
       initData();

        System.runAs(portalUser) {
            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            Integer minimumIncentive = appController.getMinimumIncentive();
            // Set dates for WorkerStartDate and WorkerFinishDate
            appController.application.Work_Start_Date__c = Date.today();
            appController.application.Work_Finish_Date__c = Date.today();
            appController.application.Test_In_Date__c = Date.today();
            appController.application.Test_Out_Date__c = Date.today();
            appController.application.Completed_Cost__c = 500;
            // Set Application Rebate Type to Account Holder
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(1).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');

            List<Contact> analysts = appController.getAnalysts();
            Integer result = analysts.size();
            System.assertEquals(result, 1);

            System.currentPageReference().getParameters().put('BPIAnalyst', analysts.get(0).Id);

            String nonAccountOwnerDownloadLink = appController.getNonAccountOwnerDownloadLink();
            System.assertEquals(nonAccountOwnerDownloadLink, '');

            String contractorPayeeDownloadLink = appController.getContractorPayeeDownloadLink();
            System.assertEquals(contractorPayeeDownloadLink, '');

            Boolean hasAdvancedHUProgram = appController.getHasAdvancedHUProgram();
            System.assertEquals(hasAdvancedHUProgram, true);

            Test.startTest();
            appController.submitApplication();
            Test.stopTest();

            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', appController.application.Id);
            appController.init();

            System.assertEquals(
                    'To submit the application, the total incentive must be greater or equal to ' + minimumIncentive,
                    ApexPages.getMessages().get(0).getSummary());
       }
   }

    private static List<String> getIncentiveAmount(List<SelectOption> measureTypeOptions, String searchValue) {
        List<String> measureTypeOptionsResult = new List<String>();
        for (Integer i=0; i < measureTypeOptions.size(); i++) {
            if (measureTypeOptions[i].getValue().contains(searchValue)) {
                measureTypeOptionsResult.add(measureTypeOptions[i].getValue());
            }
        }
        return measureTypeOptionsResult;
    }

    private static void auxSaveApp(Application__c application){
        //check if Application fields were populated
        System.assertEquals(building.Building_Type__c, application.Building_Type__c);
        System.assertEquals(building.City__c, application.Building_City__c);
        System.assertEquals(building.State__c, application.Building_State__c);
        System.assertEquals(building.ZIP_Code__c, application.Building_ZIP_Code__c);
    }

    static testMethod void testGetMeasureFlexAirConditioner() {
        initData();

        System.runAs(portalUser) {

            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();

            Test.startTest();
                appController.init();
            Test.stopTest();

            System.assertEquals(2, appController.getMeasuresFlexAirConditioner().size());
        }
    }

    static testMethod void testGetMeasuresFlexGasHeating() {
        initData();

        test.startTest();

        System.runAs(portalUser) {

            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            System.assert(appController.getMeasuresFlexGasHeating().size() == 3);
        }
       test.stopTest();
    }

    static testMethod void testGetMeasuresFlexAirConditioningList() {
        initData();

        System.runAs(portalUser) {
            Measure__c measure = new Measure__c();

            Measure_Types__mdt measureType = [
                SELECT Id, Measure_Type__c, Measure_Code__c, Upgrade_Measure__c, DeveloperName,
                        Qualifying_Measure_Code__c, Measure_Description__c, Incentive__c, Measure_Code_Abbreviation__c
                FROM Measure_Types__mdt
                WHERE Measure_Type__c = 'Flex Measure'
                    AND Upgrade_Measure__c = 'Air Conditioning' AND Retirement_Date__c = null
                ].get(0);

            Site__c site = BIGPortalTestUtils.createSite('site', 'address', '12345', portalAccount);
            insert site;
            System.assertNotEquals(null, site.Id);

            Unit__c unit = BIGPortalTestUtils.createUnit('unit', 'make', 'model', site);
            insert unit;

            Application__c app = BIGPortalTestUtils.createApplication('Site Name', 'Address', 'City', 'CA',
            '12345', '(831) 758-7214', 'myEmail@gmail.com', unit) ;
            app.RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByName()
                    .get('HUP').getRecordTypeId();
            app.Contractor__c = portalAccount.Id;
            app.Dwelling_Unit__c = dwellingUnit.Id;
            insert app;

            measure.Application__c = app.Id;
            MeasureUtils.setMeasure(measure, measureType);
            insert measure;

            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', app.Id);
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();

            Test.startTest();
            appController.init();
            Test.stopTest();

            System.assert(appController.getFlexMeasuresAirConditioningList().size() == 1);
        }
    }

    static testMethod void testGetFlexMeasuresGasHeatingList() {
        initData();

        test.startTest();

        System.runAs(portalUser) {
            Measure__c measure = new Measure__c();

            Measure_Types__mdt measureType = [
                SELECT Id, Measure_Code__c, Measure_Type__c, Upgrade_Measure__c, DeveloperName,
                        Qualifying_Measure_Code__c, Measure_Description__c, Incentive__c, Measure_Code_Abbreviation__c
                FROM Measure_Types__mdt
                WHERE Measure_Type__c = 'Flex Measure'
                    AND Upgrade_Measure__c = 'Gas Heating (furnaces & wall heater)' AND Retirement_Date__c = null
                ].get(0);

            Site__c site = BIGPortalTestUtils.createSite('site', 'address', '12345', portalAccount);
            insert site;
            System.assertNotEquals(null, site.Id);

            Unit__c unit = BIGPortalTestUtils.createUnit('unit', 'make', 'model', site);
            insert unit;

            Application__c app = BIGPortalTestUtils.createApplication('Site Name', 'Address', 'City', 'CA',
            '12345', '(831) 758-7214', 'myEmail@gmail.com', unit) ;
            app.RecordTypeId = Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('HUP')
                    .getRecordTypeId();
            app.Contractor__c = portalAccount.Id;
            app.Dwelling_Unit__c = dwellingUnit.Id;
            insert app;

            measure.Application__c = app.Id;
            MeasureUtils.setMeasure(measure, measureType);
            insert measure;

            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', app.Id);
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();

            System.assert(appController.getFlexMeasuresGasHeatingList().size() == 1);
        }
       test.stopTest();
    }

    static testMethod void testGetAHUPrePostStatuses() {
        initData();
        test.startTest();

        System.runAs(portalUser) {
            /*
             * Initialize the collection following the order on the custom settings.
             * If you delete some status from the custom settings, you have to delete it from this list too.
             * If you switch the order of the statuses from the custom setting, you have to do the same for this list.
             */
            List<String> ahuPrePostStatuses = new List<String> {ApplicationUtils.PRE_INSTALL_CREATED_STATUS,
                    ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS,
                    ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS,
                    ApplicationUtils.PRE_INSTALL_RESUBMITTED_STATUS, ApplicationUtils.PRE_INSTALL_APPROVED_STATUS,
                    ApplicationUtils.POST_INSTALL_CREATED_STATUS, ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS,
                    ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS,
                    ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS,
                    ApplicationUtils.POST_INSTALL_APPROVED_STATUS, ApplicationUtils.REBATE_ISSUED_STATUS,
                    ApplicationUtils.CANCELED_STATUS, ApplicationUtils.REJECTED_STATUS};

            BIGPortalApplicationsListController appListController = new BIGPortalApplicationsListController();
            System.assertEquals(JSON.serialize(ahuPrePostStatuses), appListController.getAHUPrePostStatuses());

        }
       test.stopTest();
    }

    static testMethod void testGetHUStatuses() {
        initData();
        test.startTest();

        System.runAs(portalUser) {

            List<String> hupStatuses = new List<String> {ApplicationUtils.CREATED_STATUS,
                    ApplicationUtils.SUBMITTED_STATUS, ApplicationUtils.CANCELED_STATUS,
                    ApplicationUtils.CORRECTION_REQUIRED_STATUS, ApplicationUtils.RESUBMITTED_STATUS,
                    ApplicationUtils.APPROVED_STATUS, ApplicationUtils.REBATE_ISSUED_STATUS};

            BIGPortalApplicationsListController appListController = new BIGPortalApplicationsListController();
            System.assertEquals(JSON.serialize(hupStatuses), appListController.getHUStatuses());

        }
       test.stopTest();
    }

    static testMethod void testHasACQCProgram() {
        initData();
        System.runAs(portalUser) {
            Boolean hasAcqc = false;
            portalContact.Program_Enrollment__c = 'ACQC; HU; AHU';
            update portalContact;
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();

            test.startTest();
            hasAcqc = appController.getHasACQCProgram();
            test.stopTest();

            System.assert(hasAcqc);

        }
    }

    static testMethod void testGetNotes() {
        initData();
        System.runAs(portalUser) {
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            Application__c app = BIGPortalTestUtils.createApplication(ApplicationUtils.HUP_RECORD_TYPE);
            insert app;
            Application_Note__c appNote = BIGPortalTestUtils.createApplicationNote(app.Id, 'Test Note', true, false);
            insert appNote;
            ApexPages.currentPage().getParameters().put('id', app.Id);

            test.startTest();
            List<Application_Note__c> listAppNotes1 = appController.getNotes();
            test.stopTest();

            System.assertEquals(1, listAppNotes1.size());
        }
    }

    /*
     * Check error when enter a WorkFinishDate before WorkStartDate
     */
    static testMethod void testWorkFinishDateError() {
        initData();

        System.runAs(portalUser) {

            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set Application Rebate Type to Account Holder
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(0).getValue();
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = appController.getMeasureTypesAtticInsulation().get(0).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(1).getValue());
            // Add water heater measures
            appController.flexMeasureWaterHeater = appController.getMeasuresFlexWaterHeater().get(0).getValue();
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');

            List<Contact> analysts = appController.getAnalysts();
            System.currentPageReference().getParameters().put('BPIAnalyst', analysts.get(0).Id);

            // Set WorkFinishDate before WorkStartDate
            appController.application.Work_Start_Date__c = Date.today();
            appController.application.Work_Finish_Date__c = (Date.today() - 5);

            Test.startTest();
            appController.submitApplication();
            Test.stopTest();

            // Check there isn't any Application created for WorkFinishDate issue
            System.assertEquals(new List<Application__c>(), BIGPortalTestUtils.getApplicationsById(
                    new Set<Id>{appController.application.Id}));
        }
    }

    /*
     * Check when try to add a BPIAnalyst with same first name and last name than other, it won't be saved
     */
    static testMethod void testDuplicatedBPINotSave() {
        // initData() creates the first BPI Analyst with 'fName' and 'lName' as firstName and lastName
        initData();

        System.runAs(portalUser) {
            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set Application Rebate Type
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();

            // Check there is only one BPI created
            System.assertEquals(1, appController.getAnalysts().size());

            // Save Application
            appController.saveApplication();
            // Initialize application
            appController.init();

            // Try to create a duplicated (same firstName and lastName) BPI Analyst and assigned to BPI on controller
            appController.newBpiAnalystContact = BIGPortalTestUtils.createBPIAnalyst('fname', 'lname', 'test@test.com',
                    '(234) 234-3243', '1234567', Date.today(), portalAccount);

            test.startTest();
            // Assigned 'xxx' to BPIAnalyst parameter in order to create a new BPIAnalyst and save Application
            ApexPages.currentPage().getParameters().put('BPIAnalyst', 'xxx');
            appController.saveApplication();
            test.stopTest();

            // Check there is still only one BPI created
            System.assertEquals(1, appController.getAnalysts().size());
        }
    }

    /*
     * Check when try to add a BPIAnalyst with different first name and last name than other, it will be saved
     */
    static testMethod void testNotDuplicatedBPISave() {
        // initData() creates the first BPI Analyst with 'fName' and 'lName' as firstName and lastName
        initData();

        System.runAs(portalUser) {
            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();

            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();

            // Set Application Rebate Type
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();

            // Check there is only one BPI created
            System.assertEquals(1, appController.getAnalysts().size());

            // Save Application
            appController.saveApplication();
            // Initialize application
            appController.init();

            // Create second BPI Analyst with different firstName and lastName and assigned to BPI on controller
            appController.newBpiAnalystContact = BIGPortalTestUtils.createBPIAnalyst('changed', 'changed',
                    'test@test.com', '(234) 234-3243', '1234567', Date.today(), portalAccount);

            test.startTest();
            // Assigned 'xxx' to BPIAnalyst parameter in order to create a new BPIAnalyst and save Application
            ApexPages.currentPage().getParameters().put('BPIAnalyst', 'xxx');
            appController.saveApplication();
            test.stopTest();

            // Check there are 2 BPI created
            System.assertEquals(2, appController.getAnalysts().size());
        }
    }

    /*
     * Check when you change files and click on save, they should be replaced
     */
    static testMethod void testReplaceFilesSaveBtn() {
        // initData() creates the first BPI Analyst with 'fName' and 'lName' as firstName and lastName
        initData();

        System.runAs(portalUser) {
            PageReference pageRef = Page.BIGPortalManageApplication;
            Test.setCurrentPage(pageRef);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set dates for WorkerStartDate and WorkerFinishDate
            appController.application.Work_Start_Date__c = Date.today();
            appController.application.Work_Finish_Date__c = Date.today();
            appController.application.Test_In_Date__c = Date.today();
            appController.application.Test_Out_Date__c = Date.today();
            // Set Completed Cost
            appController.application.Completed_Cost__c = 3000;
            // Set Application Rebate Type to Account Holder
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(0).getValue();
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = appController.getMeasureTypesAtticInsulation().get(0).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(1).getValue());
            // Add water heater measures
            appController.flexMeasureWaterHeater = appController.getMeasuresFlexWaterHeater().get(0).getValue();
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');

            List<Contact> analysts = appController.getAnalysts();
            Integer result = analysts.size();
            System.assertEquals(result, 1);

            System.currentPageReference().getParameters().put('BPIAnalyst', analysts.get(0).Id);

            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');
            List<Application_File__c> applicationFiles = new List<Application_File__c>();

            // Save Application
            appController.saveApplication();

            applicationFiles = BIGPortalTestUtils.getApplicationFiles(appController.application.Id);
            System.assertEquals(4, applicationFiles.size());

            // Initialize application
            ApexPages.currentPage().getParameters().put('action', 'detail');
            ApexPages.currentPage().getParameters().put('id', appController.application.Id);
            appController.init();

            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');

            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');

            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');

            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');

            test.StartTest();
            // Save Application
            appController.saveApplication();
            test.StopTest();

            applicationFiles = new List<Application_File__c>();
            applicationFiles = BIGPortalTestUtils.getApplicationFiles(appController.application.Id);
            System.assertEquals(4, applicationFiles.size());
        }
    }

    /**
     * Test Program Acces behavior when you don't have access to HU program.
     */
    static testMethod void testNotHUPortalProgramAccess() {
        initData();
        portalContact.Program_Enrollment__c = 'ACQC';
        update portalContact;

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGPortalManageApplication);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();

            Test.startTest();
            PageReference accessDenied = appController.init();
            Test.stopTest();

            System.assertEquals(Page.AccessDenied.getUrl(), accessDenied.getUrl());
        }
    }

    /**
    * Portal user should not be able to save a new application when HU program is suspended.
    */
   static testMethod void testHUSuspendedOnSave() {
        initData();
        // Create a new HU Program Enrollment in Suspended status.
        insert BIGPortalTestUtils.createProgramEnrollment(portalAccount.Id,
                Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName()
                .get('HU').getRecordTypeId(), ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS);

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGPortalManageApplication);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            // Get Project Financing options to check later
            Map<String, List<String>> projectFinancingOptions = appController.getProjectFinancingOptions();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set Application Rebate Type
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Completed Cost
            appController.application.Completed_Cost__c = 3000;
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(0).getValue();
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = appController.getMeasureTypesAtticInsulation().get(0).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(1).getValue());
            appController.flexMeasureWaterHeater = appController.getMeasuresFlexWaterHeater().get(0).getValue();
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');
            // won't be valid
            appController.additionalDocuments.Name = 'testAdditionalDocuments.txt';
            appController.additionalDocuments.Body = Blob.valueOf('testAdditionalDocuments BODY');
            appController.bpiFileIdCard.Name = 'bpiFileTest.txt';
            appController.bpiFileIdCard.Body = Blob.valueOf('bpiFileTest BODY');

            System.assertEquals(1, appController.getAnalysts().size());
            System.assertEquals('', appController.getNonAccountOwnerDownloadLink());
            System.assertEquals('', appController.getContractorPayeeDownloadLink());
            System.assertEquals(true, appController.getHasAdvancedHUProgram());

            // Add Project Financing option
            appController.application.Project_Financing_Source__c =
                    projectFinancingOptions.get('General Options').get(0);
            ApexPages.currentPage().getParameters().put('notes', 'testNotes');
            // Create a BPI Analyst to reach Save Application in controller
            appController.newBpiAnalystContact = BIGPortalTestUtils.createBPIAnalyst('fnamem', 'lnamem', 'test@test.com',
                    '(234) 234-3243', '1234567', Date.today(), portalAccount);
            ApexPages.currentPage().getParameters().put('BPIAnalyst', 'xxx');

            Test.startTest();
            appController.saveApplication();
            Test.stopTest();

            System.assertEquals(null, appController.application.Id);
            System.assertEquals(
                    BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR,
                    ApexPages.getMessages().get(0).getSummary());
        }
    }

    /**
    * Portal user should not be able to submit a new application when HU program is suspended.
    */
   static testMethod void testHUSuspendedOnSubmit() {
        initData();
        // Create a new HU Program Enrollment in Suspended status.
        insert BIGPortalTestUtils.createProgramEnrollment(portalAccount.Id,
                Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName()
                .get('HU').getRecordTypeId(), ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS);

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGPortalManageApplication);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set dates for WorkerStartDate and WorkerFinishDate
            appController.application.Work_Start_Date__c = Date.today();
            appController.application.Work_Finish_Date__c = Date.today();
            appController.application.Test_In_Date__c = Date.today();
            appController.application.Test_Out_Date__c = Date.today();
            appController.application.Completed_Cost__c = 3000;
            // Set Application Rebate Type to Account Holder
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(1).getValue();
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = appController.getMeasureTypesAtticInsulation().get(0).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(1).getValue());
            // Add water heater measures
            appController.flexMeasureWaterHeater = appController.getMeasuresFlexWaterHeater().get(0).getValue();
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');

            System.assertEquals(1, appController.getAnalysts().size());
            System.currentPageReference().getParameters().put('BPIAnalyst', appController.getAnalysts().get(0).Id);
            System.assertEquals('', appController.getNonAccountOwnerDownloadLink());
            System.assertEquals('', appController.getContractorPayeeDownloadLink());
            System.assertEquals(true, appController.getHasAdvancedHUProgram());

            Test.startTest();
            appController.submitApplication();
            Test.stopTest();

            System.assertEquals(null, appController.application.Id);
            System.assertEquals(
                    BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR,
                    ApexPages.getMessages().get(0).getSummary());
        }
    }

    /**
     * Portal user should not be able to submit an application already created when HU program is suspended and
     * Rebate Assignment is Contractor.
     */
    static testMethod void testHUSuspendedOnSubmitAsContractor() {
        initData();

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGPortalManageApplication);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assertEquals(true, appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            appController.application.Completed_Cost__c = 3000;
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';

            System.assertEquals(1, appController.getAnalysts().size());
            System.currentPageReference().getParameters().put('BPIAnalyst', appController.getAnalysts().get(0).Id);
            System.assertEquals('', appController.getNonAccountOwnerDownloadLink());
            System.assertEquals('', appController.getContractorPayeeDownloadLink());
            System.assertEquals(true, appController.getHasAdvancedHUProgram());

            // Set dates for WorkerStartDate and WorkerFinishDate
            appController.application.Work_Start_Date__c = Date.today();
            appController.application.Work_Finish_Date__c = Date.today();
            appController.application.Test_In_Date__c = Date.today();
            appController.application.Test_Out_Date__c = Date.today();
            // Set Application Rebate Type to Account Holder
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(1).getValue();
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = appController.getMeasureTypesAtticInsulation().get(0).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(1).getValue());
            // Add water heater measures
            appController.flexMeasureWaterHeater = appController.getMeasuresFlexWaterHeater().get(0).getValue();
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');
            appController.rebateAssignmetForm.Name = 'rebateForm.test';
            appController.rebateAssignmetForm.Body = Blob.valueOf('rebateForm BODY');

            // Create a new HU Program Enrollment in Suspended status.
            insert BIGPortalTestUtils.createProgramEnrollment(portalAccount.Id,
                    Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName()
                    .get('HU').getRecordTypeId(), ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS);

            // Set Application Rebate Type to Contractor
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(2).getValue();

            Test.startTest();
            appController.submitApplication();
            Test.stopTest();

            System.assertNotEquals(null, appController.application.Id);
            System.assertEquals(false, ApexPages.hasMessages());
        }
    }

    /**
     * Portal user should be able to submit an application already created when HU program is suspended and
     * Rebate Assignment is Account Holder.
     */
    static testMethod void testHUSuspendedOnSubmitAsAccountHolder() {
        initData();

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGPortalManageApplication);
            // Set Parameters to new application
            ApexPages.currentPage().getParameters().put('action', 'new');
            BIGPortalManageApplicationController appController = new BIGPortalManageApplicationController();
            appController.init();
            appController.dwellingSearchText = 'Test Dwelling Unit';
            // Search & Assign Dwelling unit
            appController.searchDwellingUnit();
            System.assert(appController.getDwellingUnitsList().size() > 0);
            // Set dwelling unit as we would on the modal search.
            appController.dwellingToAssignId = appController.getDwellingUnitsList().get(0).Id;
            appController.assignDwellingUnit();
            // Set dates for WorkerStartDate and WorkerFinishDate
            appController.application.Work_Start_Date__c = Date.today();
            appController.application.Work_Finish_Date__c = Date.today();
            appController.application.Test_In_Date__c = Date.today();
            appController.application.Test_Out_Date__c = Date.today();
            appController.application.Completed_Cost__c = 3000;
            // Set Application Rebate Type to Account Holder
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();
            // Set Base Measure Duct Improvement
            appController.measureDuctImprovement = appController.getMeasureTypesDuctImprovement().get(1).getValue();
            // Set Base Measure Attic Insulation & Plane Air Sealing
            appController.measureAtticInsulation = appController.getMeasureTypesAtticInsulation().get(0).getValue();
            // Set Base Measure Whole Building Air Sealing
            appController.measureAirSealing = appController.getMeasureTypesBuildingAirSealing().get(0).getValue();
            // Set Flex Measure Air Conditioner and Furnace
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(0).getValue());
            appController.flexMeasures.add(appController.getMeasureTypesFlexMeasures().get(1).getValue());
            // Add water heater measures
            appController.flexMeasureWaterHeater = appController.getMeasuresFlexWaterHeater().get(0).getValue();
            // Set Attachments
            appController.clientSignedContractSOW.Name = 'clientSignedContractSOW.test';
            appController.clientSignedContractSOW.Body = Blob.valueOf('clientSignedContractSOW BODY');
            appController.testInMeasureCASForm.Name = 'testInMeasureCASForm.test';
            appController.testInMeasureCASForm.Body = Blob.valueOf('testInMeasureCASForm BODY');
            appController.testOutMeasureCASForm.Name = 'testOutMeasureCASForm.test';
            appController.testOutMeasureCASForm.Body = Blob.valueOf('testOutMeasureCASForm BODY');
            appController.casTestAcknowledgementForm.Name = 'casTestAcknowledgementForm.test';
            appController.casTestAcknowledgementForm.Body = Blob.valueOf('casTestAcknowledgementForm BODY');

            List<Contact> analysts = appController.getAnalysts();
            System.assertEquals(1, analysts.size());

            ApexPages.currentPage().getParameters().put('BPIAnalyst', analysts.get(0).Id);

            System.assertEquals('', appController.getNonAccountOwnerDownloadLink());
            System.assertEquals('', appController.getContractorPayeeDownloadLink());
            System.assertEquals(true, appController.getHasAdvancedHUProgram());

            PageReference pageref = appController.saveApplication();

            Id appId = appController.application.Id;

            System.assert(appId != null);

            // Create a new HU Program Enrollment in Suspended status.
            insert BIGPortalTestUtils.createProgramEnrollment(portalAccount.Id,
                    Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName()
                    .get('HU').getRecordTypeId(), ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS);

            Test.setCurrentPage(pageref);
            ApexPages.currentPage().getParameters().put('BPIAnalyst', analysts.get(0).Id);
            appController.init();

            // Set Application Rebate Type to Account Holder
            appController.application.Rebate_Assignment__c = appController.getRebateTypes().get(0).getValue();

            Test.startTest();
            pageref = appController.submitApplication();
            Test.stopTest();

            Test.setCurrentPage(pageref);
            appController.init();

            System.assertEquals(
                    'Your Application has been submitted for review. Your Application number is '
                    + appController.application.Name + '.',
                    ApexPages.getMessages().get(1).getSummary());
        }
    }

}