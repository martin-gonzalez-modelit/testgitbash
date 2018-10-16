/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentCompanyExtension
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentCompanyExtension {

    private static BIGPGEEnrollmentCompanyExtension.ApplicationEnrollmentWrapper response;
    private static BIGPGEEnrollmentCompanyExtension.ApplicationEnrollmentWrapper appWrapper;
    private static BIGPGEEnrollmentCompanyExtension.ApplicationProgramWrapper prgWrapper;
    private static Application_Enrollment__c app;
    private static Staff__c owner;
    private static Staff__c primaryContact;

    @testSetup
    static void initSetupData() {
        // Setup init data.
        BIGPGEEnrollmentTestUtility.TEST_LIST_SIZE = 1;
        BIGPGEEnrollmentTestUtility testData =
                new BIGPGEEnrollmentTestUtility(new List<String> {'Contractor'},
                                                new List<String> {
                                                    BIGPGEEnrollmentApplicationUtility.ENROLLMENT_CREATED_STATUS},
                                                new List<String> {
                                                    BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS,
                                                    BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_REQUEST_INFO_STATUS
                                                });
    }

    private static void initData() {
        appWrapper = new BIGPGEEnrollmentCompanyExtension.ApplicationEnrollmentWrapper(null, null);
        prgWrapper = new BIGPGEEnrollmentCompanyExtension.ApplicationProgramWrapper(null, false);
        app = new Application_Enrollment__c(Company_Name__c = 'Acme Inc.',
                                            Address__c = 'Acme Avenue',
                                            City__c = 'Acme city',
                                            Zip_Code__c = '12345',
                                            EIN_or_SSN__c = '123456788',
                                            Type__c = 'Contractor');
        owner = new Staff__c(First_Name__c = 'John',
                             Last_Name__c = 'Doe',
                             Email__c = 'joedoe@mail.com',
                             Phone__c = '2313213');
        primaryContact = new Staff__c(First_Name__c = 'Kyle',
                                      Last_Name__c = 'Smith',
                                      Email__c = 'ksmith@mail.com',
                                      Phone__c = '44555877');
        appWrapper.app = app;
        appWrapper.owner = owner;
    }

    static testMethod void enrollmentCompanyGetApplicationFailed() {
        Test.startTest();
            BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
            BIGPGEEnrollmentCompanyExtension companyCtrl = new BIGPGEEnrollmentCompanyExtension(ctrl);
            response = BIGPGEEnrollmentCompanyExtension.getApplicationEnrollment('', '');
            // Application Id will be null since the application Id and access token are invalid.
            System.assert(response.app.Id == null);
        Test.stopTest();
    }

    static testMethod void enrollmentCompanyGetApplicationSuccessfully() {
        // Retrieve inserted Enrollment Application.
        app = [
            SELECT Name, Security_Code__c
            FROM Application_Enrollment__c
            WHERE Enrollment_Status__c =: BIGPGEEnrollmentApplicationUtility.ENROLLMENT_CREATED_STATUS
            LIMIT 1
            ];
        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        Test.startTest();
            BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
            BIGPGEEnrollmentCompanyExtension companyCtrl = new BIGPGEEnrollmentCompanyExtension(ctrl);
            response = BIGPGEEnrollmentCompanyExtension.getApplicationEnrollment(app.Id, app.Access_Token__c);
            // Check if the enrollment application was successfully retrieved.
            System.assertEquals(app.Id, response.app.Id);
        Test.stopTest();
    }

    static testMethod void enrollmentCompanySaveApplicationAccessTokenExpired() {
        initData();

        prgWrapper.checked = true;
        appWrapper.programs.put(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME, prgWrapper);
        String JSONApp = JSON.serialize(appWrapper);

        Test.startTest();
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(null, null, JSONApp);
            // Check if the enrollment application was successfully inserted.
            System.assertNotEquals(null, response.app.Id);
            System.assertNotEquals(null, response.app.Access_Token__c);
            System.assertNotEquals(null, response.programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME).appPrg);
            // Retrieve Enrollment Application and delete Access Token to emulate time dependent workflow.
            app = new Application_Enrollment__c(Id = response.app.Id, Access_Token__c = null);
            update app;

            JSONApp = JSON.serialize(response);
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(response.app.Id,
                    response.app.Access_Token__c, JSONApp);
            // Should be true, since we deleted the value in order to emulate that 1 hour has passed
            // since the token was generated.
            System.assert(response.isTokenExpired == true);
        Test.stopTest();
    }

    static testMethod void enrollmentCompanySaveApplicationDuplicateTaxNumber() {
        initData();

        // Retrieve an existing account so we can test the duplicate tax number flow.
        Account acc = [SELECT Tax_ID_Number__c FROM Account WHERE Tax_ID_Number__c != null LIMIT 1];
        // Set the enrollment application with a duplicate ein/ssn number.
        appWrapper.app.EIN_or_SSN__c = acc.Tax_ID_Number__c;
        prgWrapper.checked = true;
        appWrapper.programs.put(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME, prgWrapper);
        String JSONApp = JSON.serialize(appWrapper);

        Test.startTest();
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(null, null, JSONApp);
            System.assert(response.hasDuplicate == true);
        Test.stopTest();
    }

    static testMethod void enrollmentCompanySaveApplication() {
        initData();

        prgWrapper.checked = true;
        // Add ACQC and HU program enrollments
        appWrapper.programs.put(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME, prgWrapper);
        appWrapper.programs.put(BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_NAME, prgWrapper);
        String JSONApp = JSON.serialize(appWrapper);

        Test.startTest();
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(null, null, JSONApp);
            // Check if the enrollment application was successfully inserted.
            System.assertNotEquals(null, response.app.Id);
            System.assertNotEquals(null, response.programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME).appPrg);
            System.assertNotEquals(null, response.programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_NAME).appPrg);
            // Remove ACQC program enrollment
            response.programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME).checked = false;
            JSONApp = JSON.serialize(response);
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(response.app.Id,
                    response.app.Access_Token__c, JSONApp);
            // Verify that the ACQC program was removed
            System.assertEquals(null,
                    response.programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME).appPrg.Status__c);
            // Add ACQC program enrollment back
            response.programs.put(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME, prgWrapper);
            JSONApp = JSON.serialize(response);
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(response.app.Id,
                    response.app.Access_Token__c, JSONApp);
            // Verify that the ACQC program status changed to Pending Review
            System.assertEquals('Pending Review',
                    response.programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME).appPrg.Status__c);
            // Change company type to Individual Rater
            response.app.Type__c = 'Individual Rater';
            // Simulate behavior at front-end for cases when Company Type changes from Contractor to Rater
            response.programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME).checked = false;
            JSONApp = JSON.serialize(response);
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(response.app.Id,
                    response.app.Access_Token__c, JSONApp);
            // Verify that the programs were deleted
            System.assertEquals(null, response.programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME).appPrg);
            // Set primary contact different than owner.
            response.app.Different_Contact__c = true;
            response.contact = primaryContact;
            JSONApp = JSON.serialize(response);
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(response.app.Id,
                    response.app.Access_Token__c, JSONApp);
            // Check if the primary contact was successfully inserted.
            System.assertNotEquals(null, response.contact.Id);
            // Rollback and makes owner be the primary contact as well.
            response.app.Different_Contact__c = false;
            JSONApp = JSON.serialize(response);
            response = BIGPGEEnrollmentCompanyExtension.saveApplicationEnrollment(response.app.Id,
                    response.app.Access_Token__c, JSONApp);
            // Check if the primary contact was successfully deleted.
            System.assertEquals(null, response.contact.Id);
        Test.stopTest();
    }
}