/**
 * This class contains unit tests for validating apex code in the 
 * AccountServices class.
 *
 * @author Danny Teng - dteng@builditgreen.org
 * @since 2013-03
 */
@istest
private class AccountServicesTest {
	
	private static Account createAccount() {
		Id contractorRt = Label.ContractorRT;
		Account testAccount = new Account();
		testAccount.Name = 'abcdTestCity123';
		testAccount.RecordTypeId = contractorRt;
		testAccount.BillingCity = 'Hayward';
		testAccount.BillingState = 'CA';
		testAccount.County__c = 'Alameda';
		
		List<County__c> counties = new List<County__c>();
		
		County__c countyAlameda = new County__c();
		countyAlameda.Name = 'Alameda';
		countyAlameda.City__c = 'Hayward';
		countyAlameda.State__c = 'CA';
		
		counties.add(countyAlameda);
		
		County__c countyTest = new County__c();
		countyTest.Name = 'Test County Name ';
		countyTest.City__c = 'New York City';
		countyTest.State__c = 'NY';
		
		counties.add(countyTest);
		
		insert counties;
		
		return testAccount;
	}
	
    static testMethod void UpdateContractorCounty() {
        Account account = createAccount();
        
        insert account;
        
        Test.startTest();
        
        Account storeAct = [select county__c from account where name = :account.name];
        
        System.assertEquals(storeAct.County__c,'Alameda');
        
        Test.stopTest();
    }

    static testMethod void TestSetAccountCounty() {
        Account account = createAccount();
        
        insert account;
        
		List<Account> contractors = new List<Account>();
		
        contractors.add(account);
        
        AccountServices.setAccountCounty(contractors);
        
        System.assert(account.County__c.equals('Alameda'));

        Id contractorRt = Label.ContractorRT;
        account = new Account();
        account.Name = 'abcdTestCity123';
        account.RecordTypeId = contractorRt;
        account.BillingCity = null;
        account.BillingState = null;
        contractors = new List<Account>();
        contractors.add(account);
        
        AccountServices.setAccountCounty(contractors);
        
        System.assert(account.County__c == null);
    }
}