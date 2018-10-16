/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentResendEmailExtension
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentResendEmailExtension {

    static testMethod void resendEmailFailed() {
        Test.startTest();
            BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
            BIGPGEEnrollmentResendEmailExtension resendEmailCtrl = new BIGPGEEnrollmentResendEmailExtension(ctrl);

            BIGPGEEnrollmentResponseWrapper response =
                    BIGPGEEnrollmentResendEmailExtension.sendEmailToRecipient('jdoe@mail.com');

            // It should fail since we don't have an enrollment application set.
            System.assertEquals(false, response.success);
            System.assertEquals(BIGPGEEnrollmentResendEmailExtension.EMAIL_ADDRESS_NOT_FOUND_ERROR, response.message);
            System.assertEquals(null, response.responseData);
        Test.stopTest();
    }

    static testMethod void resendEmailSuccessfully() {
        // Setup init data.
        BIGPGEEnrollmentTestUtility.TEST_LIST_SIZE = 1;
        BIGPGEEnrollmentTestUtility testData = new BIGPGEEnrollmentTestUtility(new List<String> {'Contractor'});

        Test.startTest();
            BIGPGEEnrollmentResponseWrapper response =
                    BIGPGEEnrollmentResendEmailExtension.sendEmailToRecipient('jdoe@mail.com');

            System.assert(response.success);
            System.assertEquals(BIGPGEEnrollmentResendEmailExtension.EMAIL_CONFIRMATION_MESSAGE, response.message);
            System.assertNotEquals(null, response.responseData);
        Test.stopTest();
    }
}