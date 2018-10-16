/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentRetrieveAppExtension
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentRetrieveAppExtension {

    private static Application_Enrollment__c app {get; set;}

    @testSetup
    static void initData(){
        // Setup init data.
        BIGPGEEnrollmentTestUtility.TEST_LIST_SIZE = 1;
        BIGPGEEnrollmentTestUtility testData =
                new BIGPGEEnrollmentTestUtility(new List<String> {'Contractor'},
                                                new List<String> {
                                                    BIGPGEEnrollmentApplicationUtility.ENROLLMENT_PENDING_STATUS},
                                                new List<String> {
                                                    BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS,
                                                    BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_REQUEST_INFO_STATUS
                                                });
    }

    static testMethod void retrieveEnrollmentApplicationNotFound() {
        Test.startTest();
            BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
            BIGPGEEnrollmentRetrieveAppExtension retrieveAppCtrl = new BIGPGEEnrollmentRetrieveAppExtension(ctrl);
            BIGPGEEnrollmentResponseWrapper response =
                    BIGPGEEnrollmentRetrieveAppExtension.retrieveEnrollmentApplication('ENAPP-00001', 'abcdfe');

            // It should fail since we don't have an enrollment application inserted yet.
            System.assertEquals(false, response.success);
            System.assertEquals(BIGPGEEnrollmentRetrieveAppExtension.ENROLLMENT_APPLICATION_NOT_FOUND_ERROR,
                                response.message);
        Test.stopTest();
    }

    static testMethod void retrieveEnrollmentApplicationNotEditable() {
        app = [SELECT Name, Security_Code__c
               FROM Application_Enrollment__c
               WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
               LIMIT 1];

        Test.startTest();
            BIGPGEEnrollmentResponseWrapper response =
                    BIGPGEEnrollmentRetrieveAppExtension.retrieveEnrollmentApplication(app.Name , app.Security_Code__c);

            // It should fail since the enrollment application inserted has pending review status.
            System.assertEquals(false, response.success);
            System.assertEquals(BIGPGEEnrollmentApplicationUtility.ENROLLMENT_APPLICATION_STATUS_ERROR,
                                response.message);
        Test.stopTest();
    }

    static testMethod void retrieveEnrollmentApplicationSuccessfully() {
        app = [SELECT Name, Security_Code__c
               FROM Application_Enrollment__c
               WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_REQUEST_INFO_STATUS
               LIMIT 1];

        Test.startTest();
            BIGPGEEnrollmentResponseWrapper response =
                    BIGPGEEnrollmentRetrieveAppExtension.retrieveEnrollmentApplication(app.Name , app.Security_Code__c);

            // it should retrieve the enrollment application that has been inserted since it needs to be corrected.
            System.assertEquals(true, response.success);
            System.assertNotEquals(null, response.responseData);

            Application_Enrollment__c appResponse = (Application_Enrollment__c)response.responseData;
            System.assertEquals(app.Id, appResponse.Id);
            System.assert(String.isNotEmpty(appResponse.Access_Token__c));
        Test.stopTest();
    }
}