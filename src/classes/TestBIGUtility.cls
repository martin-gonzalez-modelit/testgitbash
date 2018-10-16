/*
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 *
 * @author Mauricio Medina <mauricio.medina@modelitsoftware.com>
 * @since 2015-8
 */
@isTest
private class TestBIGUtility {
    
    private static User portalUser;
    private static Account contractor;
    private static Contact contac;

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
        System.assertNotEquals(null, contractor.Id);
        
        // Create Contact
        contac = BIGPortalTestUtils.createContact('portalContact' , 'portalContact',
                                                    'portalContact@test.com', '703-555-5555',
                                                    contractor.Id);
        contac.OwnerId = UserInfo.getUserID();
        insert contac;
        System.assertNotEquals(null, contact.Id);
        
        
        // Create Portal user
        Profile portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser('BIGPortalUserForTest', portalProfile.Id, 'BIGTest');
        portalUser.ContactId = contac.Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);
    }
    
    static testMethod void testIsObjectLastModifiedByUserWithProfile(){
        initData();
        Test.startTest();

        System.runAs(portalUser) {
            Building__c building = new Building__c();
            building.Building_Name__c = 'test name';
            building.Building_Type__c = 'Single Family';
            building.Street_Address__c = 'test street';
            building.City__c = 'test city';
            building.State__c = 'CA';
            building.ZIP_Code__c = '23123';
            building.County__c = 'test country';
            
            insert building;
            
            building.Building_Name__c = 'name edited';
            building.Street_Address__c = 'street edited';
            
            update building;
            
            Profile profile = [ SELECT Id FROM Profile WHERE Name = 'PGE - EUC Portal User' ];
            
            Building__c result = [SELECT LastModifiedById FROM Building__c WHERE Id =: building.Id];
            
            System.assertEquals(true, BIGUtility.isObjectLastModifiedByUserWithProfile(result, profile.Id));
        }
        Test.stopTest();     
    }
    
    /*static testMethod void testIsObjectLastModifiedAfterDate(){
        initData();
        Test.startTest();

        System.runAs(portalUser) {
            Building__c building = new Building__c();
            building.Building_Name__c = 'test name';
            building.Building_Type__c = 'Single Family';
            building.Street_Address__c = 'test street';
            building.City__c = 'test city';
            building.State__c = 'CA';
            building.ZIP_Code__c = '23123';
            building.County__c = 'test country';
            
            insert building;
            
            building.Building_Name__c = 'name edited';
            building.Street_Address__c = 'street edited';
            
            update building;
            
            Building__c result = [SELECT LastModifiedDate FROM Building__c WHERE Id =: building.Id];
            
            Datetime todayDate = Datetime.now();
            
            System.assertEquals(false, BIGUtility.isObjectLastModifiedAfterDate(result, todayDate));
        }
        Test.stopTest();     
    }*/
    
    static testMethod void testGetRecordTyeIdByName() {
        Id homeownerRtId = BIGUtility.getRecordTyeIdByName(Contact.SObjectType, 'Homeowner');
        System.assert(homeownerRtId != null);
    }

    static testMethod void testNullifySObjectFields() {
        // Create Account
        contractor =  BIGPortalTestUtils.createAccount('portalAccount');
        contractor.BillingStreet = 'Test';
        contractor.BillingCity = 'San Jose';
        BIGUtility.nullifySObjectFields(contractor, new Set<String> { 'Name', 'BillingStreet', 'BillingCity' });

        System.assertEquals(null, contractor.Name);
        System.assertEquals(null, contractor.BillingStreet);
        System.assertEquals(null, contractor.BillingCity);
    }
}