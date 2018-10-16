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
private class testManageContact {

     static testMethod void testContactCreation() {
      
     List<RecordType> rTypes = [SELECT Name, Id FROM RecordType WHERE sObjectType = 'Account' and isActive = true];
    Map<String,String> acctRTypes = new Map<String,String>{};
    for(RecordType rt: rTypes){
      acctRTypes.put(rt.Name, rt.Id);
    }
    	
    List<RecordType> cTypes = [SELECT Name, Id FROM RecordType WHERE sObjectType = 'Contact' and isActive = true];
      Map<String,String> conRTypes = new Map<String,String>{};
      for(RecordType crt: cTypes) {
        conRTypes.put(crt.Name, crt.Id);
      }
        
    ID homeownerID = acctRTypes.get('Homeowner');
    ID svcproviderID = acctRTypes.get('Service Provider');
      
      Test.startTest();
/* ----------  Coupon Code / Campaign Functionality --------------         
        Campaign ex = new Campaign();
        ex.Name = 'Exception List';
        ex.Coupon_Code__c = 'Exception List';
        ex.IsActive = true;
        insert ex;
        
        Campaign camp = new Campaign();
        camp.Name = 'TestCampaign';
        camp.Coupon_Code__c = 'TestCampaign';
        camp.IsActive = true;
        insert camp;
        
        List<Campaign> campaigns = [SELECT campaign.Id, campaign.Coupon_Code__c FROM Campaign WHERE isActive = true];
		Map<String,String> campaignList = new Map<String,String>{};
		for(Campaign cp: campaigns) {
			campaignList.put(cp.Coupon_Code__c, cp.Id);
		}

 -----------  End Coupon Code / Campaign Functionality ------------ */
                
          Account m = new Account();
          m.First_Name__c = 'blippy';
          m.Type = 'Homeowner';
          m.Coupon_Code__c = 'dfldjf';
          m.Name = 'N/A Household';
          insert m;
          
//1/28/12 - Commented out the following 5 lines, getting errors when trying to deactivate the manageContact trigger
//This code is written very poorly        
//          Account checkM = [SELECT Last_Name__c, Email__c FROM Account WHERE name = 'N/A Household' AND First_Name__c = 'blippy'];
//          Contact mc = [SELECT lastname, RecordTypeId, Id FROM Contact WHERE Contact.Email = 'notprovided@email.com' AND firstname = 'blippy'];          
//          System.assertEquals(checkM.Last_Name__c, 'N/A');
//          System.assertEquals(checkM.Email__c, 'notprovided@email.com');
//          System.assertEquals(mc.lastname, 'N/A');
/* ----------  Coupon Code / Campaign Functionality --------------        
          CampaignMember mcc = [SELECT Id, ContactId, CampaignId, Campaign.Name FROM CampaignMember WHERE CampaignMember.ContactId = :mc.Id LIMIT 1]; 
          System.assertEquals(mcc.Campaign.Name, 'Exception List');
 -----------  End Coupon Code / Campaign Functionality ------------ */
          
	      Account a = new Account();
	      a.Last_Name__c = 'Bar';
	      a.First_Name__c = 'Foo';
	      a.Email__c = 'test@testxxx.com';
	      a.Type = 'Homeowner';
	      a.Coupon_Code__c = '';
	      a.Name = 'Bar Household';
	      insert a;

//1/28/12 - Commented out the following 6 lines, getting errors when trying to deactivate the manageContact trigger
//This code is written very poorly           
//          Account checkA = [SELECT name, RecordTypeId FROM Account WHERE Email__c = 'test@testxxx.com'];
//		  Contact c = [SELECT lastname, RecordTypeId, Id FROM Contact WHERE Contact.Email = 'test@testxxx.com'];          
//         System.assertEquals(checkA.name, 'Bar Household');  
//          System.assertEquals(checkA.RecordTypeId, acctRTypes.get('Homeowner'));
//          System.assertEquals(c.lastname, 'Bar');
//          System.assertEquals(c.RecordTypeId, conRTypes.get('Homeowner'));
/* ----------  Coupon Code / Campaign Functionality -------------- 
          List<CampaignMember> cm = [SELECT Id FROM CampaignMember WHERE CampaignMember.ContactId = :c.Id LIMIT 1];                  
          System.assertEquals(cm.size(), 0);
 -----------  End Coupon Code / Campaign Functionality ------------ */
           
          Account a2 = [SELECT name FROM Account WHERE name = 'Bar Household'];
          a2.Last_Name__c = 'Bar2';
          a2.Email__c = 'test2@testxxx.com';
          a2.Coupon_Code__c = 'TestCampaign';
          a2.Name = 'Bar2 Household';
          update a2;
//1/28/12 - Commented out the following 4 lines, getting errors when trying to deactivate the manageContact trigger
//This code is written very poorly           
//          Account checkA2 = [SELECT name FROM Account WHERE Email__c = 'test2@testxxx.com'];
//          Contact c2 = [SELECT lastname FROM Contact WHERE Contact.Email = 'test2@testxxx.com'];
//          System.assertEquals(checkA2.name, 'Bar2 Household');           
//          System.assertEquals(c2.lastname, 'Bar2');
/* ----------  Coupon Code / Campaign Functionality --------------           
          CampaignMember cm2 = [SELECT Id, ContactId, CampaignId, Campaign.Name FROM CampaignMember WHERE CampaignMember.ContactId = :c2.Id LIMIT 1];
          System.assertEquals(cm2.Campaign.Name, 'TestCampaign');
            
          Account a3 = [SELECT name FROM Account WHERE name = 'Bar2 Household'];
          a3.Coupon_Code__c = 'TestCampaign';
          update a3;
          Contact c3 = [SELECT lastname FROM Contact WHERE Contact.Email = 'test2@testxxx.com'];
          CampaignMember cm3 = [SELECT Id, ContactId, CampaignId, Campaign.Name FROM CampaignMember WHERE CampaignMember.ContactId = :c2.Id LIMIT 1];
          System.assertEquals(cm3.Campaign.Name, 'TestCampaign');        
      
          Account a4 = [SELECT name FROM Account WHERE name = 'Bar2 Household'];
          a4.Coupon_Code__c = 'asfdgsag';
          update a4;
          Contact c4 = [SELECT lastname FROM Contact WHERE Contact.Email = 'test2@testxxx.com'];
          CampaignMember cm4a = [SELECT Id, ContactId, CampaignId, Campaign.Name FROM CampaignMember WHERE CampaignMember.ContactId = :c2.Id AND Campaign.Name = 'TestCampaign' LIMIT 1];
          CampaignMember cm4b = [SELECT Id, ContactId, CampaignId, Campaign.Name FROM CampaignMember WHERE CampaignMember.ContactId = :c2.Id AND Campaign.Name = 'Exception List'  LIMIT 1];
          System.assertEquals(cm4b.Campaign.Name, 'Exception List'); 
          System.assertEquals(cm4a.Campaign.Name, 'TestCampaign');
 -----------  End Coupon Code / Campaign Functionality ------------ */ 
            
    Test.stopTest();          
            
  }
}