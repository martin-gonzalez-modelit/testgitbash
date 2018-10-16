/**
* This class contains unit tests for validating the behavior of BIGPortalHVACSearchCustController
* for PG&E SFDC Portal.
*
* @author Pablo Vigil <pablo.vigil@modelit.xyz>
* @since 2014-03
*/
@isTest
private class BIGPortalHVACSearchCustTest {

    private static User portalUser;
    private static Account contractor;
    private static Contact contact;
    private static List<Unit__c> units;

    private static void initData() {
        // Create Account
        contractor =  BIGPortalTestUtils.createAccount('portalAccount');
        insert contractor;
        System.assertNotEquals(null, contractor.Id);

        // Create Contact
        contact = BIGPortalTestUtils.createContact('portalContact' , 'portalContact', 'portalContact@test.com',
              '703-555-5555', contractor.Id);
        insert contact;
        System.assertNotEquals(null, contact.Id);

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = contact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);

        // Create Site
        Site__c site = BIGPortalTestUtils.createSite('site','address','12345', contractor);
        insert site;
        System.assertNotEquals(null, site.Id);

        // Create Units
        List<Unit__c> unitsToInsert = new List<Unit__c>();
        for (Integer i = 0; i < 50; i++) {
            unitsToInsert.add(BIGPortalTestUtils.createUnit('unit'+i,'make','model',site));
        }
        insert unitsToInsert;
        System.assertEquals(50, unitsToInsert.size());
    }

    static testMethod void testNoUnits() {
        initData();

        // Run test with portal user privileges.
        System.RunAs(portalUser) {
            Test.startTest();
            BIGPortalHVACSearchCustController controller = new BIGPortalHVACSearchCustController();
            ApexPages.currentPage().getParameters().put('zipcode','12346');
            units = (List<Unit__c>)JSON.deserialize(controller.getJSONUnits(), List<Unit__c>.class);
            Test.stopTest();
        }

        // There's no site with zipcode '12346'.
        System.assertEquals(0, units.size());
    }

    static testMethod void testGetUnits() {
        initData();

        // Run test with portal user privileges.
        System.RunAs(portalUser) {
            Test.startTest();
            BIGPortalHVACSearchCustController controller = new BIGPortalHVACSearchCustController();
            ApexPages.currentPage().getParameters().put('zipcode','12345');
            units = (List<Unit__c>)JSON.deserialize(controller.getJSONUnits(), List<Unit__c>.class);
            Test.stopTest();
        }

        // There're 50 units asociated to the site with zipcode '12345'.
        System.assertEquals(50, units.size());
    }

    static testMethod void testNoZipcodeUnits() {
        initData();

        // Run test with portal user privileges.
        System.RunAs(portalUser) {
            Test.startTest();
            BIGPortalHVACSearchCustController controller = new BIGPortalHVACSearchCustController();
            ApexPages.currentPage().getParameters().put('zipcode', null);
            units = (List<Unit__c>)JSON.deserialize(controller.getJSONUnits(), List<Unit__c>.class);
            Test.stopTest();
        }

        // We pass an empty zipcode as parameter so there shouldn't be any results.
        System.assertEquals(0, units.size());
    }

}