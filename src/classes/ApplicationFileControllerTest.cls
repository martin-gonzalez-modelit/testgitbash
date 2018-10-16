/**
* This class contains unit tests for validating the behavior of ApplicationFileController
*
* @author Ian Lopez <ilopez@jway.com>
* @since 2016-01
*/
@isTest
private class ApplicationFileControllerTest {

    private static Account contractor;
    private static Application_File__c apf1;

    private static void initData() {
        // Create Account
        contractor =  BIGPortalTestUtils.createAccount('portalAccount');
        contractor.Tax_ID_Number__c = '123456789';
        contractor.Zip__c = '12345';
        contractor.BillingStreet = 'Test';
        contractor.BillingCity = 'San Jose';
        contractor.BillingState = 'CA';
        contractor.BillingPostalCode = '12345';
        contractor.BillingCountry = 'USA';
        contractor.OwnerId = UserInfo.getUserId();
        insert contractor;

        // Create Application
        String appId = buildApplication(contractor).Id;
        ApexPages.currentPage().getParameters().put('appId', appId);

        // Create Application File
        apf1 = BIGPortalTestUtils.createApplicationFile('f1', 'Home Performance XML', appId);
        insert apf1;
    }

    static Application__c buildApplication(Account pContractor) {
        Site__c st = BIGPortalTestUtils.createSite('Name', 'St', '12345', pContractor);
        insert st;
        Unit__c unit = BIGPortalTestUtils.createUnit('Name', 'Make', 'Model', st);
        insert unit;
        Application__c app = BIGPortalTestUtils.createApplication('Site name', 'address', 'city', 'CA',
                '12345', '(650) 887-0260', 'email@gmail.com', unit);
        insert app;
        return app;
    }

    static testMethod void testGetApplicationFile() {
        initData();

        Test.startTest();
            Application_File__c result = ApplicationFileController.getApplicationFile(apf1.Id);
        Test.stopTest();

        System.assertEquals(apf1.Id, result.Id);
    }

}