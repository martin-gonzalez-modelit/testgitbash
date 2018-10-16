/**
 * This class contains unit tests for validating the behavior of BIGPortalUser Class
 * @author Maiquel Cabrera <maiquel.cabrera@modelitsoftware.com>
 */
@isTest
private class TestBIGPortalUser {


	private static User portalUser;
	private static Contact portalContact;
	private static Account portalAccount;

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

    static testMethod void testBIGPortalUser() {
        initData();

        Test.startTest();

        System.runAs(portalUser) {
        	BIGPortalUser portalUserClass = new BIGPortalUser();
        	System.assertEquals(portalUserClass.getContact().Id, portalContact.Id);
        	System.assertEquals(portalUserClass.getAccount().Id, portalAccount.Id);

        	System.assertEquals(true, portalUserClass.hasACQCProgram());
        }

        Test.stopTest();
    }
}