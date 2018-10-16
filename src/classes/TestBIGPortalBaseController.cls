/**
 * This class contains unit tests for validating the behavior of BIGPortalBaseController
 * which is used in some components.
 *
 * @author: Matias Medina
 * @since: 2014-08
 */
@isTest
private class TestBIGPortalBaseController {
    private static User portalUser;
    private static Account portalAccount;
    private static Contact portalContact;

    private static void initData() {
        // Create Account
        portalAccount = BIGPortalTestUtils.createAccount('portalAccount');
        insert portalAccount;
        System.assertNotEquals(null, portalAccount.Id);

        // Create Contact
        portalContact = BIGPortalTestUtils.createContact('portalContact' , 'portalContact', 'portalContact@test.com', '703-555-5555', portalAccount.Id);
        insert portalContact;
        System.assertNotEquals(null, portalContact.Id);

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = portalContact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);
    }

    static testMethod void testHasHUProgram() {
        initData();

        Test.startTest();

        //Run As U1
        System.RunAs(portalUser) {
            portalContact.Program_Enrollment__c = 'ACQC; HU';
            upsert portalContact;

            BIGPortalBaseController controller = new BIGPortalBaseController();
            System.assertEquals(true, controller.getHasHUProgram());

            portalContact.Program_Enrollment__c = null;
            upsert portalContact;

            controller = new BIGPortalBaseController();
            System.assertEquals(false, controller.getHasHUProgram());
        }

        Test.stopTest();
    }

    static testMethod void testHasAccountName() {
        initData();

        Test.startTest();

        //Run As U1
        System.RunAs(portalUser) {
            BIGPortalBaseController controller = new BIGPortalBaseController();

            System.assertNotEquals(null, controller.getAccountName());
            System.assertEquals('portalAccount', controller.getAccountName());
        }

        Test.stopTest();
    }
}