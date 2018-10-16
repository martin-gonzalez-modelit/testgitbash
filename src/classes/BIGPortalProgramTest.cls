@isTest
public with sharing class BIGPortalProgramTest {

    private static User portalUser;
    private static Account contractor;
    private static Contact contact;

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
        Profile portalProfile = [SELECT Id, Name FROM Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = contact.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);

    }

    static testMethod void testCheckPortal(){
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
        initData();

        //Run As U1
        System.RunAs(portalUser){
            controller.checkPortal();
        }
        Test.stopTest();
    }

    static testMethod void testCheckPortalWithAcqcParameter(){
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
		initData();

        //Run As U1
        System.RunAs(portalUser){
	        ApexPages.currentPage().getParameters().put('p','ACQC');
	        controller.checkPortal();
        }
        Test.stopTest();
    }

    static testMethod void testCheckPortalWithHupParameter(){
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
        initData();

        //Run As U1
        System.RunAs(portalUser){
            ApexPages.currentPage().getParameters().put('p','HU');
            controller.checkPortal();
        }
        Test.stopTest();
    }

    static testMethod void testCheckPortalWithHUPContact(){
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
        initData();
        // Set up user
        contact.Program_Enrollment__c = 'HU';
        update contact;
        System.RunAs(portalUser){
            controller.checkPortal();
        }
        Test.stopTest();
    }

    static testMethod void testCheckPortalWithAcqcContact(){
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
        initData();
        // Set up user
        contact.Program_Enrollment__c = 'ACQC';
        update contact;
        System.RunAs(portalUser){
            controller.checkPortal();
        }
        Test.stopTest();
    }

    static testMethod void testCheckPortalWithAcqcAndHupContact() {
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
        initData();
        // Set up user
        contact.Program_Enrollment__c = 'ACQC; HU';
        update contact;
        System.RunAs(portalUser) {
            controller.checkPortal();
            system.assertEquals(null, contact.Default_Program__c);
        }
        Test.stopTest();
    }

    static testMethod void testCheckPortalWithDefaultAcqcProgram() {
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
        initData();
        // Set up user
        contact.Program_Enrollment__c = 'ACQC; HU';
        contact.Default_Program__c = 'ACQC';
        update contact;
        System.RunAs(portalUser) {
            PageReference destiny = controller.checkPortal();
            system.assertEquals('ACQC', contact.Default_Program__c);
            system.assertEquals(Page.BIGACQCDashboard.getUrl(), destiny.getUrl());
        }
        Test.stopTest();
    }

    static testMethod void testCheckPortalWithDefaultHupProgram() {
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
        initData();
        // Set up user
        contact.Program_Enrollment__c = 'ACQC; HU';
        contact.Default_Program__c = 'HU';
        update contact;
        System.RunAs(portalUser) {
            PageReference destiny = controller.checkPortal();
            system.assertEquals('HU', contact.Default_Program__c);
            system.assertEquals(Page.BIGPortalManageDashboard.getUrl(), destiny.getUrl());
        }
        Test.stopTest();
    }

    static testMethod void testCheckAdvanceHuProgramEnrollment() {
        BIGPortalProgramController controller = new BIGPortalProgramController();
        Test.startTest();
        initData();
        // Set up user
        contact.Program_Enrollment__c = 'AHU';
        update contact;
        System.RunAs(portalUser) {
            PageReference destiny = controller.checkPortal();
            system.assertEquals(null, contact.Default_Program__c);
            system.assertEquals(Page.BIGPortalManageDashboard.getUrl(), destiny.getUrl());
        }
        Test.stopTest();
    }

}