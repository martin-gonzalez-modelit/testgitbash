/**
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
 */
@isTest
private class TestCustomerMeasure {

    static testMethod void addCustomerMeasure() {
        
        PGE_Customer__c customer = new PGE_Customer__c(
        	Name = 'Test Customer',
        	Account_Id__c = 'TESTID',
        	Key__c = 'TESTID123 Fake St.DavisCA95616'
        );
        insert customer;
        
        PGE_Measure_Code__c measure = new PGE_Measure_Code__c(
        	Name = 'Test Code'
        );
        insert measure;
        
        Test.startTest();
        
        Customer_Measure__c cm = new Customer_Measure__c(
        	Key__c = 'TESTID123 Fake St.DavisCA95616;;Test Code'
        );
        insert cm;
        
        Test.stopTest();
        
    }
    
    static testMethod void editCustomerMeasure() {
        
        PGE_Customer__c customer = new PGE_Customer__c(
        	Name = 'Test Customer',
        	Account_Id__c = 'TESTID',
        	Key__c = 'TESTID123 Fake St.DavisCA95616'
        );
        insert customer;
        
        PGE_Measure_Code__c measure = new PGE_Measure_Code__c(
        	Name = 'Test Code'
        );
        insert measure;
        
        Customer_Measure__c cm = new Customer_Measure__c(
        	Key__c = 'temp'
        );
        insert cm;
        
        Test.startTest();
        
        cm.Key__c = 'TESTID123 Fake St.DavisCA95616;;Test Code';
        update cm;
        
        Test.stopTest();
        
    }
    
}