/**
* This class contains unit tests for validating the behavior of BIGPortalHVACCustRebateApplicController
* and BIGACQCRebateApplicationReviewController for PG&E SFDC Portal.
*
* @author Pablo Vigil <pvigil@builditgreen.org>
* @since 2015-07
*/
@isTest
public with sharing class TestBIGACQCContractorReviewController {
    private static User portalUser;
    private static Account contractor;
    private static Contact contact;
    private static List<Contact> technicians;
    private static List<Rebate_Type__c> rebateTypes;

    private static void initData() {
        // Create Account
        contractor =  BIGPortalTestUtils.createAccount('portalAccount');
        contractor.Tax_ID_Number__c = '123456789';
        contractor.Zip__c = '12345';
        contractor.BillingStreet = 'Test';
        contractor.BillingCity = 'San Jose';
        contractor.BillingState = 'CA';
        contractor.BillingPostalCode = '12345';
        contractor.BillingCountry = 'USA';
        insert contractor;

        System.assertNotEquals(null, contractor.Id);

        // Create Contact
        contact = BIGPortalTestUtils.createContact('portalContact' , 'portalContact', 'portalContact@test.com',
                '703-555-5555', contractor.Id);
        insert contact;
        System.assertNotEquals(null, contact.Id);

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = contact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);

        technicians = new List<Contact>();
        // Create Technicians
        Contact technician1 = BIGPortalTestUtils.createContact('technician1' , 'technician1',
                'technician1@test.com', '703-555-5555', contractor.Id);
        technician1.Technician__c = true;
        insert technician1;
        System.assertNotEquals(null, technician1.Id);
        technicians.add(technician1);


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
        // Set rowCause to 'manual' for manual sharing.
        // This line can be omitted as 'manual' is the default value for sharing objects.
        //jobShr.RowCause = Schema.AccountShare.RowCause.Manual;

        // Insert the sharing record and capture the save result.
        // The false parameter allows for partial processing if multiple records passed
        // into the operation.
        Database.SaveResult sr = Database.insert(jobShr, false);
        BIGPortalTestUtils.createCustomSetting();
    }

    private static void initRebateApplicationData(BIGPortalHVACCustRebateApplicController controller) {

        // Create Rebate Types
        rebateTypes = new List<Rebate_Type__c>();
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Full ACCA Standard 4 HVAC System Assessment', 50, 'TK07',
                'Full ACCA Standard 4 HVAC System Assessment'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Air Flow Correction', 400, 'TK08',
                'Air Flow Correction'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Refrigerant System Service', 50, 'TK103',
                'Refrigerant System Service'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('Replacement Blower Motor', 300, 'TK10',
                'Replacement Blower Motor'));
        rebateTypes.add(BIGPortalTestUtils.createRebateType('One-year QM Service Agreement', 50, 'TK12',
                'One-year QM Service Agreement'));
        insert rebateTypes;


        Site__c site = new Site__c();
        site.Name = 'Test Site';
        site.Contractor__c = contractor.Id;
        site.Zip__c = '12345';
        site.State__c = 'CA';
        site.City__c = 'San Jose';
        site.Address_1__c = 'Test';
        site.Address_2__c = 'Test';
        insert site;
        System.assertNotEquals(null,site.Id);

        Unit__c unit = new Unit__c();
        unit.Name = 'Test Unit';
        unit.Site__c = site.Id;
        unit.Equipment_Type__c = 'Split';
        unit.Make__c = 'Test';
        unit.Model__c = 'Test';
        unit.Stage_1_Cooling_Capacity__c = 0;
        unit.Stage_2_Cooling_Capacity__c = 0;
        unit.Stage_3_Cooling_Capacity__c = 0;
        unit.Stage_4_Cooling_Capacity__c = 0;
        insert unit;
        System.assertNotEquals(null,unit.Id);

        Inspection__c inspection = new Inspection__c();
        inspection.Name = 'Test Inspection';
        inspection.Log_Time__c = Datetime.now();
        inspection.Site__c = site.Id;
        insert inspection;
        System.assertNotEquals(null,inspection.Id);

        // Get a valid zip code which contains a climate zone and a county.
        String zipCode = BIGPortalTestUtils.getZipCodeWithClimateZoneAndCounty();

        ApexPages.currentPage().getParameters().put('unitId', unit.Id);
        ApexPages.currentPage().getParameters().put('inputName', 'Name');
        ApexPages.currentPage().getParameters().put('j_id0:inputAddress', 'Address');
        ApexPages.currentPage().getParameters().put('j_id0:inputCity', 'San Jose');
        ApexPages.currentPage().getParameters().put('inputState', 'CA');
        ApexPages.currentPage().getParameters().put('j_id0:inputZip', zipCode);
        ApexPages.currentPage().getParameters().put('inputUnit', contact.Id);
        ApexPages.currentPage().getParameters().put('inputPhone', '4082475929');
        ApexPages.currentPage().getParameters().put('j_id0:inputEmail', '');
        ApexPages.currentPage().getParameters().put('inputPayee', 'on');
        ApexPages.currentPage().getParameters().put('j_id0:inputSaid', '1234567890');
        ApexPages.currentPage().getParameters().put('inputStickerNumber', '1234567');
        ApexPages.currentPage().getParameters().put('technician', contact.Id);
        ApexPages.currentPage().getParameters().put('notes', 'Test Notes');
        ApexPages.currentPage().getParameters().put('rebateIdsString', rebateTypes.get(2).Id);
        ApexPages.currentPage().getParameters().put('rebateForm', '');
        ApexPages.currentPage().getParameters().put('costEstimate', '');
        ApexPages.currentPage().getParameters().put('thisContractor', contractor.Id);
        ApexPages.currentPage().getParameters().put('thisSiteFirstName', '');
        ApexPages.currentPage().getParameters().put('thisSiteLastName', '');
        //attachments
        ApexPages.currentPage().getParameters().put('j_id0:rebateForm:inputFile:file', 'Rebate Application Form.txt');
        ApexPages.currentPage().getParameters().put('j_id0:costEstimate:inputFile:file', 'Cost Estimates.txt');
        ApexPages.currentPage().getParameters().put('j_id0:qmAddendum:inputFile:file', 'QM Addendum.txt');
        ApexPages.currentPage().getParameters().put('j_id0:supplementalDoc:inputFile:file',
                'Supplemental Documents.txt');

        Attachment attach1=new Attachment();
        Blob bodyBlob=Blob.valueOf('Rebate Application Form Attachment Body');
        attach1.name='Rebate Application Form Attachment Body';
        attach1.body=bodyBlob;

        Attachment attach2=new Attachment();
        Blob bodyBlob2=Blob.valueOf('Cost Estimate(s) Attachment Body');
        attach2.name='Cost Estimate(s) Attachment Body';
        attach2.body=bodyBlob2;

        Attachment attach3=new Attachment();
        Blob bodyBlob3=Blob.valueOf('QM Addendum');
        attach3.name='QM Addendum';
        attach3.body=bodyBlob3;

        Attachment attach4=new Attachment();
        Blob bodyBlob4=Blob.valueOf('Supplemental Documents');
        attach4.name='Supplemental Documents';
        attach4.body=bodyBlob4;

        controller.attachment1 = attach1;
        controller.attachment2 = attach2;
        controller.attachment3 = attach3;
        controller.attachment4 = attach4;
        controller.att1size = 39;
        controller.att2size = 32;
        controller.att3size = 39;
        controller.att4size = 32;

    }

    static testMethod void testValidateRebateApplication() {
        Test.startTest();
        initData();
        System.runAs(portalUser) {
            PageReference result;
            BIGPortalHVACCustRebateApplicController hvacController = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(hvacController);
            hvacController.checkMessages();
            result = hvacController.submitApplication();

            BIGACQCRebateApplicationReviewController controller = new BIGACQCRebateApplicationReviewController();
            String appId = result.getParameters().get('appId');
            ApexPages.currentPage().getParameters().put('appId',appId);
            ApexPages.currentPage().getParameters().put('id',appId);
            Application__c app = controller.getApplication();
            System.assertNotEquals(null, app.Id);
            Review__c review = controller.getReview();
            System.assertNotEquals(null, review.Id);
            String status = controller.getTechnicianStatus();
            System.assertNotEquals('Not Applicable', status);
            String applicationFormId = controller.getApplicationFormId();
            String applicationFormFileDownload = controller.getApplicationFormFileDownload();
            System.assertNotEquals('', applicationFormId);
            System.assertNotEquals('', applicationFormFileDownload);
            result = controller.validateRebateApplication();
            System.assertEquals(null, result);

        }
        Test.stopTest();
    }

    static testMethod void testReview() {
        Test.startTest();
        initData();
        PageReference result;
        BIGPortalHVACCustRebateApplicController controller;
        System.runAs(portalUser) {
            controller = new BIGPortalHVACCustRebateApplicController();
            initRebateApplicationData(controller);
            controller.checkMessages();
            result = controller.submitApplication();
        }
        BIGACQCRebateApplicationReviewController controller2 = new BIGACQCRebateApplicationReviewController();
        String appId = result.getParameters().get('appId');
        ApexPages.currentPage().getParameters().put('appId',appId);
        ApexPages.currentPage().getParameters().put('id',appId);
        Application__c app = controller2.getApplication();
        System.assertNotEquals(null, app.Id);
        Review__c review = controller2.getReview();
        System.assertNotEquals(null, review.Id);
        String status = controller2.getTechnicianStatus();
        System.assertNotEquals('Not Applicable', status);
        String applicationFormId = controller2.getApplicationFormId();
        String applicationFormFileDownload = controller2.getApplicationFormFileDownload();
        System.assertNotEquals('', applicationFormId);
        System.assertNotEquals('', applicationFormFileDownload);
        List<ACQC_Review_Message__c> reviewMessages = controller2.getReviewMessages();
        Boolean b = controller2.getHasError();
        System.assertEquals(b, false);
        controller.checkMessages();
        controller2.checkAction();
        review.Status__c = 'Rejected';
        update review;
        controller.checkMessages();
        controller2.checkAction();
        review.Status__c = 'Correction Required';
        update review;
        controller.checkMessages();
        controller2.checkAction();
        review.Status__c = 'Approved';
        update review;
        controller.checkMessages();
        controller2.checkAction();
        review.Status__c = 'Rebate Issued';
        update review;
        controller.checkMessages();
        Test.stopTest();
    }

    static testMethod void testValidateRebateApplicationWithErrors() {
        initData();

        Application__c app = new Application__c();
        app.Contractor__c = contractor.Id;
        app.Approval_Override__c = false;
        app.Electric_Account_Number__c = '1234567890';

        Site__c site = BIGPortalTestUtils.createSite('site', 'address', '12345', contractor);
        insert site;
        Unit__c unit = BIGPortalTestUtils.createUnit('unit', 'make', 'model', site);
        insert unit;
        app.Unit__c = unit.Id;
        insert app;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', app.Id);
        BIGACQCRebateApplicationReviewController controller = new BIGACQCRebateApplicationReviewController();
        Test.stopTest();
        System.assertEquals(null, controller.validateRebateApplication());
    }

}