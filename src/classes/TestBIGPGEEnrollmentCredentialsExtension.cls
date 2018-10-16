/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentCredentialsExtension
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentCredentialsExtension {

    private static BIGPGEEnrollmentCredentialsExtension.CredentialsWrapper response;
    private static BIGPGEEnrollmentCredentialsExtension.CredentialsWrapper credsWrapper;
    private static Application_Enrollment__c app;

    @testSetup
    static void initSetupData() {
        // Setup init data.
        BIGPGEEnrollmentTestUtility.TEST_LIST_SIZE = 1;
        BIGPGEEnrollmentTestUtility testData =
                new BIGPGEEnrollmentTestUtility(new List<String> {'Contractor', 'Individual Rater'},
                                                new List<String> {
                                                    BIGPGEEnrollmentApplicationUtility.ENROLLMENT_CREATED_STATUS},
                                                new List<String> {
                                                    BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
                                                });
    }

    static testMethod void getCredentialsEnrollmentFailed() {
        app = [
            SELECT Name, Security_Code__c, Access_Token__c
            FROM Application_Enrollment__c
            WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
            LIMIT 1
            ];
        System.assertNotEquals(null, app.Id);

        Test.startTest();
            BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
            BIGPGEEnrollmentCredentialsExtension staffCtrl = new BIGPGEEnrollmentCredentialsExtension(ctrl);
            response = BIGPGEEnrollmentCredentialsExtension.getCredentialsEnrollment(app.Id , app.Access_Token__c);
            // Token expired should be true since access token is invalid.
            System.assert(response.isTokenExpired == true);
        Test.stopTest();
    }

    static testMethod void getCredentialsEnrollmentSuccessfully() {
        app = [
            SELECT Name, Security_Code__c, Access_Token__c
            FROM Application_Enrollment__c
            WHERE Type__c !=: BIGPGEEnrollmentApplicationUtility.APP_TYPE_INDIVIDUAL_RATER
            LIMIT 1
            ];
        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        Test.startTest();
            response = BIGPGEEnrollmentCredentialsExtension.getCredentialsEnrollment(app.Id , app.Access_Token__c);
            // Check if credentials were successfully retrieved.
            System.assertEquals(false, response.isTokenExpired);
        Test.stopTest();
    }

    static testMethod void getIndividualRaterCredentialsEnrollmentSuccessfully() {
        app = [
            SELECT Name, Security_Code__c, Access_Token__c
            FROM Application_Enrollment__c
            WHERE Type__c =: BIGPGEEnrollmentApplicationUtility.APP_TYPE_INDIVIDUAL_RATER
            LIMIT 1
            ];
        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        Test.startTest();
            response = BIGPGEEnrollmentCredentialsExtension.getCredentialsEnrollment(app.Id , app.Access_Token__c);
            // Check if credentials were successfully retrieved.
            System.assertEquals(false, response.isTokenExpired);
        Test.stopTest();
    }

    static testMethod void saveCredentialsEnrollmentAccessTokenExpired() {
        Test.startTest();
            response = BIGPGEEnrollmentCredentialsExtension.saveCredentialsEnrollment(null, null, '{}');
            // Token expired should be true since access token is invalid.
            System.assert(response.isTokenExpired == true);
        Test.stopTest();
    }

    static testMethod void saveCredentialsEnrollmentSuccessfully() {
        app = [
            SELECT Name, Security_Code__c, Access_Token__c
            FROM Application_Enrollment__c
            WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
            LIMIT 1
            ];
        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        BIGPGEEnrollmentCredentialsExtension.LicenseWrapper licenseWrapper =
                createCredential('B License', '123456', System.now().date(), true, new List<String>{'HU','AHU'});
        credsWrapper = new BIGPGEEnrollmentCredentialsExtension.CredentialsWrapper();
        credsWrapper.licenses.add(licenseWrapper);
        String JSONApp = JSON.serialize(credsWrapper);

        Test.startTest();
            response = BIGPGEEnrollmentCredentialsExtension.saveCredentialsEnrollment(app.Id, app.Access_Token__c, JSONApp);
            // Check if the credential was successfully inserted.
            System.assertNotEquals(null, response.licenses.get(0).license.Id);
            response = BIGPGEEnrollmentCredentialsExtension.getCredentialsEnrollment(app.Id, app.Access_Token__c);
            // Set license doesn't show 2 years of experience.
            for (BIGPGEEnrollmentCredentialsExtension.LicenseWrapper licWrapper : response.licenses) {
                licWrapper.license.Has2YearsExperience__c = false;
            }
            // Add document required to prove 2 years of experience.
            List<BIGPGEEnrollmentCredentialsExtension.DocumentWrapper> docsWrapperList =
                    new List<BIGPGEEnrollmentCredentialsExtension.DocumentWrapper>();
            BIGPGEEnrollmentTestUtility.TEST_LIST_SIZE = 1;
            List<Document__c> docsList = BIGPGEEnrollmentTestUtility.createDocuments(new List<String>{'Copy of BPI Card'});
            docsList = [
                SELECT Id, File_Type__c, File_Name__c,
                    (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                FROM Document__c
                WHERE Id IN : docsList
                ];

            for (Document__c doc : docsList) {
                docsWrapperList.add(createDocumentWrapper(doc));
            }
            response.licenses.get(0).files.addAll(docsWrapperList);
            response = BIGPGEEnrollmentCredentialsExtension.saveCredentialsEnrollment(
                    app.Id, app.Access_Token__c, JSON.serialize(response));
            response = BIGPGEEnrollmentCredentialsExtension.getCredentialsEnrollment(app.Id , app.Access_Token__c);
        Test.stopTest();
        // Verify that we saved and retrieved the credential correctly
        System.assertNotEquals(null, response.licenses.get(0).license.Id);
        System.assertEquals('B License', response.licenses.get(0).license.Type__c);
        System.assertEquals('123456', response.licenses.get(0).license.License_Number__c);
    }

    private static BIGPGEEnrollmentCredentialsExtension.LicenseWrapper createCredential(
            String licsType, String licsNumber, Date licsExpDate, Boolean has2YearExp, List<String> prgs) {
        BIGPGEEnrollmentCredentialsExtension.LicenseWrapper licenseWrapper;
        License__c license = new License__c(Type__c = licsType,
                                            License_Number__c = licsNumber,
                                            Expiration_Date__c = licsExpDate,
                                            Has2YearsExperience__c = has2YearExp);

        for (String prg : prgs) {
            if (licenseWrapper == null) {
                licenseWrapper = new BIGPGEEnrollmentCredentialsExtension.LicenseWrapper(license, prg);
            } else {
                licenseWrapper.programs.add(prg);
            }
        }
        return licenseWrapper;
    }

    private static BIGPGEEnrollmentCredentialsExtension.DocumentWrapper createDocumentWrapper(Document__c doc) {
        BIGPGEEnrollmentCredentialsExtension.DocumentWrapper docWrapper =
                new BIGPGEEnrollmentCredentialsExtension.DocumentWrapper(doc, false);
        return docWrapper;
    }

}