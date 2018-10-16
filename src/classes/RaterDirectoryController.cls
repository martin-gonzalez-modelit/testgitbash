/* 
* This is the controller to display raters information 
*
* @author Danny Teng dteng@salesforce.com
* @since 2012-12
*/

public with sharing class RaterDirectoryController {
	// Constants
    private static final Integer DEFAULT_PAGE_SIZE = 20;
    private static final String RATER = 'Rater';
	private List<Account> raters;
	
	// Constructor
	public RaterDirectoryController() {
	   	// Set radio button by default with value BUILDING
	   	String soqlQry = 'SELECT name, phone, Email__c, Description_of_Services__c, additional_services__c, BillingStreet, BPI_Accredited__c, ';
	   	soqlQry += 'Company_Licenses__c, Company_Licenses2__c, Company_Licenses3__c, Company_Licenses4__c, ';
		soqlQry += 'BillingCity, BillingState, BillingPostalCode, language_spoken__c, website ';
		soqlQry += 'FROM account where RecordType.Name = \'Rater\' AND Display_in_Rater_Directory__c=true Order by name';	 
		raters = new List<Account>();
		raters = Database.query(soqlQry);
	}
		
	// Initialize paginator and return a list of accounts
	public List<Account> getRaters() {
		return raters;
	}
}