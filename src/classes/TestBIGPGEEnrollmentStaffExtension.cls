/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentStaffExtension
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentStaffExtension {

    private static BIGPGEEnrollmentStaffExtension.StaffEnrollmentWrapper response;
    private static BIGPGEEnrollmentStaffExtension.StaffEnrollmentWrapper staffEnrollmentWrapper;
    private static List<BIGPGEEnrollmentStaffExtension.StaffWrapper> staffsWrapper;
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

    static testMethod void getStaffEnrollmentFailed() {
        app = [SELECT Name, Security_Code__c, Access_Token__c
               FROM Application_Enrollment__c
               WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
               LIMIT 1];

        System.assertNotEquals(null, app.Id);

        Test.startTest();
            BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
            BIGPGEEnrollmentStaffExtension staffCtrl = new BIGPGEEnrollmentStaffExtension(ctrl);

            response = BIGPGEEnrollmentStaffExtension.getStaffEnrollment(app.Id , app.Access_Token__c);

            // Token expired should be true since access token is invalid.
            System.assert(response.isTokenExpired == true);
        Test.stopTest();
    }

    static testMethod void getStaffEnrollmentSuccessfully() {
        app = [SELECT Name, Security_Code__c, Access_Token__c
               FROM Application_Enrollment__c
               WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
               LIMIT 1];

        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        Test.startTest();
            response = BIGPGEEnrollmentStaffExtension.getStaffEnrollment(app.Id , app.Access_Token__c);

            // Check if staffs were successfully retrieved.
            System.assert(response.staffs.size() > 0);
        Test.stopTest();
    }

    static testMethod void saveStaffEnrollmentAccessTokenExpired() {

        Test.startTest();
            response = BIGPGEEnrollmentStaffExtension.saveStaffEnrollment(null, null, '{}');

            // Token expired should be true since access token is invalid.
            System.assert(response.isTokenExpired == true);

        Test.stopTest();
    }

    static testMethod void saveStaffEnrollmentSuccessfully() {
        app = [SELECT Name, Security_Code__c, Access_Token__c
               FROM Application_Enrollment__c
               WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
               LIMIT 1];

        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        BIGPGEEnrollmentStaffExtension.StaffWrapper staffWrapper = createStaff('Joe', 'Doe', 'jdoe@asd.com',
                                                                               'Rebate Administrator', 'ACQC');
        staffEnrollmentWrapper = new BIGPGEEnrollmentStaffExtension.StaffEnrollmentWrapper();
        staffEnrollmentWrapper.staffs.add(staffWrapper);
        String JSONApp = JSON.serialize(staffEnrollmentWrapper);

        Test.startTest();
            response = BIGPGEEnrollmentStaffExtension.saveStaffEnrollment(app.Id, app.Access_Token__c, JSONApp);

            // Check if the staff was successfully inserted.
            System.assertNotEquals(null, response.staffs.get(0).staff.Id);
        Test.stopTest();
    }

    private static BIGPGEEnrollmentStaffExtension.StaffWrapper createStaff(String firstName, String lastName, String email, String role, String prgType) {
        BIGPGEEnrollmentStaffExtension.StaffWrapper staffWrapper;

        Staff__c staff = new Staff__c(First_Name__c = firstName,
                                      Last_Name__c = lastName,
                                      Email__c = email,
                                      Phone__c = '2313213');

        staffWrapper = new BIGPGEEnrollmentStaffExtension.StaffWrapper(staff);
        staffWrapper.roles.add(new BIGPGEEnrollmentStaffExtension.StaffRoleWrapper(role, prgType, true));

        return staffWrapper;
    }

}