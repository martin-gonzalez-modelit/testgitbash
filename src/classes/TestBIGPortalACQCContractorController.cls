/**
 * This class contains unit tests for BIGPortalACQCContractorController class.
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2018-02
 */
@isTest
private class TestBIGPortalACQCContractorController {
    private static User portalUser;
    private static Contact portalContact;

    /**
     * Initialize needed data for test methods.
     */
    private static void initData() {
        // Create the Portal User's Account.
        Account portalAccount = BIGPortalTestUtils.createAccount('portalAccount');
        insert portalAccount;
        System.assertNotEquals(null, portalAccount.Id);
        // Create Contact.
        portalContact = BIGPortalTestUtils.createContact('portalContact' , 'portalContact', 'portalContact@test.com',
                '703-555-5555', portalAccount.Id);
        insert portalContact;
        System.assertNotEquals(null, portalContact.Id);
        // Create Portal User
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];
        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = portalContact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);
    }

    /**
     * Test Program Acces behavior when you don't have access to ACQC program.
     */
    static testMethod void testNotACQCPortalProgramAccess() {
        initData();
        portalContact.Program_Enrollment__c = 'HU; AHU';
        update portalContact;

        System.runAs(portalUser) {
            Test.setCurrentPage(Page.BIGACQCContractorServiceTerritory);
            BIGPortalACQCContractorController controller = new BIGPortalACQCContractorController();

            Test.startTest();
            PageReference accessDenied = controller.checkUserAccess();
            Test.stopTest();

            System.assertEquals(Page.AccessDenied.getUrl(), accessDenied.getUrl());
        }
    }
}