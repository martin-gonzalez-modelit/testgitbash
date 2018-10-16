/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentLoginExtension
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentLoginExtension {

    static testMethod void enrollmentLoginMissingParameter() {
        Test.startTest();
            BIGPGEEnrollmentResponseWrapper response =
                    BIGPGEEnrollmentLoginExtension.login('user@domain.pge', null);

            // It should fail since we don't have an enrollment application inserted yet.
            System.assertEquals(false, response.success);
            System.assertEquals(BIGPGEEnrollmentLoginUtility.USERNAME_PASSWORD_REQUIRED_ERROR,
                                response.message);
        Test.stopTest();
    }

    static testMethod void enrollmentLoginFailed() {
        Test.startTest();
            BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
            BIGPGEEnrollmentLoginExtension loginCtrl = new BIGPGEEnrollmentLoginExtension(ctrl);

            BIGPGEEnrollmentResponseWrapper response =
                    BIGPGEEnrollmentLoginExtension.login('user@domain.pge', 'password');

            // It should fail since we don't have an enrollment application inserted yet.
            System.assertEquals(true, response.success);
            System.assertEquals(null, response.message);
        Test.stopTest();
    }
}