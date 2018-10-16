/**
 * This class contains unit tests for validating the behavior of BIGPortalAHUSurveyController class.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2018-06
 */
@isTest
private class TestBIGPortalAHUSurveyController {
    private static User portalUser;
    private static Account portalAccount;
    private static Contact portalContact;

    private static void initData() {
        // Create Account
        portalAccount = BIGPortalTestUtils.createAccount('portalAccount');
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

        // Insert the sharing record and capture the save result.
        // The false parameter allows for partial processing if multiple records passed
        // into the operation.
        Database.SaveResult sr = Database.insert(jobShr,false);
    }

    static testMethod void testSurveyNotRenderedWhenNoAHUProgramAccess() {
        initData();
        portalContact.Program_Enrollment__c = 'HU; ACQC';
        update portalContact;

        System.runAs(portalUser) {
            // Set BIGPortalManageApplication.page to current test
            PageReference huPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(huPage);

            Test.startTest();
            // Instantiate visualforce component controller
            BIGPortalAHUSurveyController controller = new BIGPortalAHUSurveyController();
            Test.stopTest();

            System.assertEquals(false, controller.render);
        }
    }

    static testMethod void testSurveyRendered() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalManageApplication.page to current test
            PageReference huPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(huPage);

            Test.startTest();
            // Instantiate visualforce component controller
            BIGPortalAHUSurveyController controller = new BIGPortalAHUSurveyController();
            Test.stopTest();

            System.assertEquals(true, controller.render);
        }
    }

    static testMethod void testSurveyNotRenderedCookieHide() {
        initData();

        System.runAs(portalUser) {
            // Set BIGPortalManageApplication.page to current test
            PageReference huPage = Page.BIGPortalAdvancedHUApplication;
            Test.setCurrentPage(huPage);

            String cookieKey = 'ahu_survey_' + EncodingUtil.urlEncode(UserInfo.getSessionId(), 'UTF-8');
            Cookie surveyCookie = new Cookie(cookieKey, 'hide', '/pgeportal', -1, true);
            ApexPages.currentPage().setCookies(new Cookie[] { surveyCookie });

            Test.startTest();
            // Instantiate visualforce component controller
            BIGPortalAHUSurveyController controller = new BIGPortalAHUSurveyController();
            Test.stopTest();
        }
    }
}