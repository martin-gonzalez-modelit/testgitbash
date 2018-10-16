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
private class testTriggers {


    static testMethod void webLeadTest() {


        List<RecordType> rTypes = [SELECT Name, Id FROM RecordType WHERE sObjectType = 'Lead' and isActive = true];
        Map<String,String> recordTypes = new Map<String,String>{};
        for(RecordType rt: rTypes){
            recordTypes.put(rt.Name, rt.Id);
        }

        
        String fname = 'Firstname';
        String company = 'Required';
        String email = 'foo@foo.com';
        
        Lead Homeowner = new Lead();
        Homeowner.LastName = '1';
        Homeowner.FirstName = fname;
        Homeowner.Company = company;
        Homeowner.Lead_Type__c = 'Homeowner';
        Homeowner.Email = email;
        
        Lead Nonprofit = new Lead();
        Nonprofit.LastName = '2';
        Nonprofit.FirstName = fname;
        Nonprofit.Company = company;
        Nonprofit.Lead_Type__c = 'Nonprofit';
        Nonprofit.Email = Email = email;        
        
        Lead Contractor = new Lead();
        Contractor.LastName = '3';
        Contractor.FirstName = fname;
        Contractor.Company = company;
        Contractor.Lead_Type__c = 'Service Provider';
        Contractor.Email = Email = email;  
        
        Lead Volunteer = new Lead();
        Volunteer.LastName = '4';
        Volunteer.FirstName = fname;
        Volunteer.Company = company;
        Volunteer.Lead_Type__c = 'Volunteer';
        Volunteer.Email = Email = email; 
        
        Lead Presentation = new Lead();
        Presentation.LastName = '5';
        Presentation.FirstName = fname;
        Presentation.Company = company;
        Presentation.Lead_Type__c = 'Presentation';
        Presentation.Email = Email = email; 
        
        Lead TypeException = new Lead();
        TypeException.LastName = '6';
        TypeException.FirstName = fname;
        TypeException.Company = company;
        TypeException.Lead_Type__c = '';
        TypeException.Email = Email = email; 
        
        Test.startTest();
            insert Homeowner;
            
            Lead checkHomeowner = [SELECT RecordTypeId FROM Lead WHERE LastName = :Homeowner.LastName];
            
            System.assertEquals(checkHomeowner.RecordTypeId, recordTypes.get('Homeowner'));
            
        Test.stopTest();

    }
}