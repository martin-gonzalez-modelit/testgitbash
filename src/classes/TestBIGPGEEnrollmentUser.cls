/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentUser class
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentUser {

    private static Application_Enrollment__c app;
    private static BIGPGEEnrollmentTestUtility testData;

    static void initData() {
        // Setup init data.
        BIGPGEEnrollmentTestUtility.TEST_LIST_SIZE = 1;

        createEnrollmentPortalCustomSetting();
    }

    private static void createEnrollmentPortalCustomSetting() {
        PGE_Enrollment_Portal_Settings__c setting =
                PGE_Enrollment_Portal_Settings__c.getInstance('PGEEnrollmentPortalSettings');

        if (setting != null) {
            delete [SELECT Id FROM PGE_Enrollment_Portal_Settings__c WHERE Name = 'PGEEnrollmentPortalSettings'];
        }

        setting = new PGE_Enrollment_Portal_Settings__c();
        setting.Name = 'PGEEnrollmentPortalSettings';
        setting.Username__c = 'jdoe@unittest.com';
        setting.Password__c = 'mypasss';
        setting.EndPointUrl__c = 'http://test.salesforce.com';
        setting.DeadProgramEnrollmentStatuses__c = 'Enrolling;Inactive';
        setting.DeadApplicationProgramEnrollmentStatuses__c = 'Cancelled;Fully Completed;Expired;Rejected;Unused';
        setting.ContactEmail__c = 'joe@doe.com';
        insert setting;
    }

    static testMethod void enrollmentPortalUserName() {
        initData();
        testData = new BIGPGEEnrollmentTestUtility(new List<String> {'Contractor'},
                                        new List<String> {
                                            BIGPGEEnrollmentApplicationUtility.ENROLLMENT_PENDING_STATUS},
                                        new List<String> {
                                           
                                            BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_REQUEST_INFO_STATUS
                                        });

        Test.startTest();
            BIGPGEEnrollmentUser userCtrl = new BIGPGEEnrollmentUser(BIGPGEEnrollmentTestUtility.PORTAL_USER_USERNAME + '@test.com');

            // it should retrieve the enrollment application that has been inserted since it needs to be corrected.
            System.assertNotEquals(null, userCtrl.getAccount());
            System.assertNotEquals(null, userCtrl.getContact());
            System.assertNotEquals(null, userCtrl.getApplicationEnrollment().Id);
            System.assertEquals(false, userCtrl.hasPendingReview());
            System.assertEquals(false, userCtrl.hasError());
            System.assertEquals(false, userCtrl.hasEnrolledAllPrograms());
        Test.stopTest();
    }

    static testMethod void enrollmentPortalAccount() {
        initData();
        testData = new BIGPGEEnrollmentTestUtility(new List<String> {'Contractor'},
                                        new List<String> {
                                            BIGPGEEnrollmentApplicationUtility.ENROLLMENT_COMPLETED_STATUS},
                                        new List<String> {
                                            BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_APPROVED_STATUS
                                        });

        Test.startTest();
            BIGPGEEnrollmentUser userCtrl = new BIGPGEEnrollmentUser(testData.testAccount.Id);

            // it should retrieve the enrollment application that has been inserted since it needs to be corrected.
            System.assertNotEquals(null, userCtrl.getAccount());
            System.assertEquals(null,userCtrl.getContact());
            System.assertEquals(null, userCtrl.getApplicationEnrollment().Id);
            System.assertEquals(testData.testAccount.Id, userCtrl.getApplicationEnrollment().Account__c);
            System.assertEquals(false, userCtrl.hasPendingReview());
            System.assertEquals(false, userCtrl.hasEnrolledAllPrograms());
            System.assertEquals(false, userCtrl.hasError());
            System.assertEquals('', userCtrl.getErrorMsg());
        Test.stopTest();
    }

    static testMethod void enrollmentPortalUserPendingInfo() {
        initData();
        testData = new BIGPGEEnrollmentTestUtility(new List<String> {'Contractor'},
                                        new List<String> {
                                            BIGPGEEnrollmentApplicationUtility.ENROLLMENT_PENDING_STATUS},
                                        new List<String> {
                                           
                                            BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
                                        });

        Test.startTest();
            BIGPGEEnrollmentUser userCtrl = new BIGPGEEnrollmentUser(BIGPGEEnrollmentTestUtility.PORTAL_USER_USERNAME + '@test.com');

            // it should retrieve the enrollment application that has been inserted since it needs to be corrected.
            System.assertNotEquals(null, userCtrl.getAccount());
            System.assertNotEquals(null, userCtrl.getContact());
            System.assertNotEquals(null, userCtrl.getApplicationEnrollment().Id);
            System.assertEquals(true, userCtrl.hasPendingReview());
            System.assertEquals(false, userCtrl.hasError());
            System.assertEquals(false, userCtrl.hasEnrolledAllPrograms());
        Test.stopTest();
    }
}