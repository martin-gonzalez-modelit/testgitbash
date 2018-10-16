/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentAgreementsExtension
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentAgreementsExtension {

    private static BIGPGEEnrollmentAgreementsExtension.AgreementsWrapper response;
    private static BIGPGEEnrollmentAgreementsExtension.AgreementsWrapper agreementsWrapper;
    private static Application_Enrollment__c app;

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

    static testMethod void getAgreementsEnrollmentFailed() {
        app = [
            SELECT Name, Security_Code__c, Access_Token__c
            FROM Application_Enrollment__c
            WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
            LIMIT 1
            ];

        System.assertNotEquals(null, app.Id);

        Test.startTest();
            BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
            BIGPGEEnrollmentAgreementsExtension agreementCtrl = new BIGPGEEnrollmentAgreementsExtension(ctrl);

            response = BIGPGEEnrollmentAgreementsExtension.getAgreementsEnrollment(app.Id , app.Access_Token__c);

            // Token expired should be true since access token is invalid.
            System.assert(response.isTokenExpired == true);
        Test.stopTest();
    }

    static testMethod void getAgreementsEnrollmentSuccessfully() {
        app = [
            SELECT Name, Security_Code__c, Access_Token__c
            FROM Application_Enrollment__c
            WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
            LIMIT 1
            ];

        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        Test.startTest();
            response = BIGPGEEnrollmentAgreementsExtension.getAgreementsEnrollment(app.Id , app.Access_Token__c);

            // Check if agreements were successfully retrieved.
            System.assert(response.agreements.size() > 0);
        Test.stopTest();
    }

    static testMethod void saveAgreementsEnrollmentAccessTokenExpired() {

        Test.startTest();
            response = BIGPGEEnrollmentAgreementsExtension.saveAgreementsEnrollment(null, null, '{}');

            // Token expired should be true since access token is invalid.
            System.assert(response.isTokenExpired == true);

        Test.stopTest();
    }

    static testMethod void saveAgreementsEnrollmentSuccessfully() {
        app = [
            SELECT Name, Security_Code__c, Access_Token__c
            FROM Application_Enrollment__c
            WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
            LIMIT 1
            ];

        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        BIGPGEEnrollmentAgreementsExtension.AgreementWrapper agreementWrapper = createAgreement(new List<String> {'HU','AHU'});
        agreementsWrapper = new BIGPGEEnrollmentAgreementsExtension.AgreementsWrapper();
        agreementsWrapper.agreements.add(agreementWrapper);
        String JSONApp = JSON.serialize(agreementsWrapper);

        Test.startTest();
            response = BIGPGEEnrollmentAgreementsExtension.saveAgreementsEnrollment(app.Id, app.Access_Token__c, JSONApp);

            // Token expired should be false since access token is valid.
            System.assert(response.isTokenExpired == false);
            // Check if the agreement was successfully created.
            System.assert(response.agreements.size() > 0);
            System.assertNotEquals(null, response.agreements.get(0).agreement.Id);
            // Add document required for Contractor Agreement
            BIGPGEEnrollmentTestUtility.TEST_LIST_SIZE = 1;
            Map<Id, List<Document__c>> docs = BIGPGEEnrollmentTestUtility.createDocuments('Contractor Agreement', 'Agreement__c', new Set<Id>{response.agreements.get(0).agreement.Id});
            response = BIGPGEEnrollmentAgreementsExtension.getAgreementsEnrollment(app.Id, app.Access_Token__c);
            // It should retrieve the file that was uploaded for contractor agreement.
            System.assert(response.agreements.get(0).files.size() > 0);
        Test.stopTest();
    }

    static testMethod void submitAgreementsEnrollmentSuccessfully() {
        app = [
            SELECT Name, Security_Code__c, Access_Token__c
            FROM Application_Enrollment__c
            WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
            LIMIT 1
            ];

        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        Test.startTest();
            BIGPGEEnrollmentResponseWrapper result =
                        BIGPGEEnrollmentAgreementsExtension.submitAgreementsEnrollment(app.Id, app.Access_Token__c);

            // Token expired should be false since access token is valid.
            System.assert(result.isTokenExpired == false);
            // Check if the application was successfully updated.
            Application_Enrollment__c appTemp = (Application_Enrollment__c)result.responseData;
            System.assertEquals(BIGPGEEnrollmentApplicationUtility.ENROLLMENT_PENDING_STATUS, appTemp.Enrollment_Status__c);
            System.assertEquals(BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS, appTemp.Company_Info_Status__c);
        Test.stopTest();
    }

    private static BIGPGEEnrollmentAgreementsExtension.AgreementWrapper createAgreement(List<String> programs) {
        Agreement__c agreement = new Agreement__c(Agree_Terms_and_Conditions__c = true,
                                                  Contractor_Agreement__c = true,
                                                  Program_Handbook__c = true,
                                                  EUC_Customer_Collateral__c = true,
                                                  EUC_Graphic_Standards__c = true);

       BIGPGEEnrollmentAgreementsExtension.AgreementWrapper agreementWrapper = new BIGPGEEnrollmentAgreementsExtension.AgreementWrapper(agreement, programs.get(0));
       for (Integer i = 1; i < programs.size(); i++) {
           agreementWrapper.programs.add(programs.get(i));
       }

        return agreementWrapper;
    }
}