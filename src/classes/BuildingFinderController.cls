/* 
* This is the controller to perform the search for searchBuilding page
*
* @author pablo.vigil - pablo.vigil@modelitsoftware.com
* @since 2012-10
*/

public with sharing class BuildingFinderController {
	// Constants
    private static final Integer DEFAULT_PAGE_SIZE = 20;
    private static final String BUILDING = 'Building';
    private static final String HOMEOWNER = 'Homeowner';
    
	private transient List<Account> buildingsAccount;
	private transient List<Contact> buildingsContact;
	
	// Properties
	public String searchKeyword {get;set;}
	public String message {get; set;}
	public String buildingType {get; set;}
	
	// Constructor
	public BuildingFinderController() {
	   // Set radio button by default with value BUILDING
	   buildingType = BUILDING;
	}
	
	public PageReference searchBuildings() {
		if (searchKeyword == null || searchKeyword.trim().length() < 3 ) {
			this.message = Label.PGEBuildingSearchKeywordError;
			con = null;
			return null;
		}
		 
		String soqlQry = 'Select ';
		
		// Build the query depending on the value selected from radio button
		if(buildingType == BUILDING) {
			soqlQry += 'name, building_name__c, county__c, city__c, state__c, street_address__c, zip_code__c ';
			soqlQry += 'From Account Where RecordType.Name = \'Building\' Order by name';
		} else if (buildingType == HOMEOWNER) {
			soqlQry += 'first_name__c, last_name__c, phone_number__c, email__c, account.id, account.name ';
			soqlQry += 'From Contact Where RecordType.Name = \'Homeowner\' Order by name';
		}
		
		// Clean search keyword
		String newKeyword = searchKeyword.trim().toLowerCase();
		buildingsAccount= new List<Account>();
		buildingsContact = new List<Contact>();
		
		// Since we can't filter encrypted fields we need to look for it's value and compare with the search term
		if(buildingType == BUILDING) {			
			for (Account acc : (List<Account>)Database.query(soqlQry)) {
				if (acc.building_name__c != null && acc.building_name__c.containsIgnoreCase(newKeyword)) {				
					buildingsAccount.add(acc);
				} else if (acc.name != null && acc.name.containsIgnoreCase(newKeyword)) {
					buildingsAccount.add(acc);
				} else if (acc.zip_code__c != null && acc.zip_code__c.containsIgnoreCase(newKeyword)) {
					buildingsAccount.add(acc);
				} else if (acc.street_address__c != null && acc.street_address__c.containsIgnoreCase(newKeyword)) {
					buildingsAccount.add(acc);
				} else if (acc.city__c != null && acc.city__c.containsIgnoreCase(newKeyword)) {
					buildingsAccount.add(acc);
				} else if (acc.state__c != null && acc.state__c.containsIgnoreCase(newKeyword)) {
					buildingsAccount.add(acc);
				} else if (acc.county__c != null && acc.county__c.containsIgnoreCase(newKeyword)) {
					buildingsAccount.add(acc);
				}
			}
			
			if(buildingsAccount.size() > 0 ) {
				con = new Apexpages.Standardsetcontroller(buildingsAccount);
				// sets the number of records in each page set
				con.setPageSize(DEFAULT_PAGE_SIZE);
			} else {
				con = null;
			}
			
			this.message = 'Number of buildings found: ' + buildingsAccount.size();
		}
		
		// Since we can't filter encrypted fields we need to look for it's value and compare with the search term
		if(buildingType == HOMEOWNER) {			
			for (Contact c : (List<Contact>)Database.query(soqlQry)) {
				if (c.first_name__c != null && c.first_name__c.containsIgnoreCase(newKeyword)) {
					buildingsContact.add(c);
				} else if (c.last_name__c != null && c.last_name__c.containsIgnoreCase(newKeyword)) {
					buildingsContact.add(c);
				} else if (c.phone_number__c != null && c.phone_number__c.containsIgnoreCase(newKeyword)) {
					buildingsContact.add(c);
				} else if (c.email__c != null && c.email__c.containsIgnoreCase(newKeyword)) {
					buildingsContact.add(c);
				}
			}
			
			if(buildingsContact.size() > 0 ) {
				con = new Apexpages.Standardsetcontroller(buildingsContact);
				// sets the number of records in each page set
				con.setPageSize(DEFAULT_PAGE_SIZE);
			} else {
				con = null;
			}
			
			this.message = 'Number of homeowners found: ' + buildingsContact.size();
		}	
		
		return null;	
	}
	
	// Add options to display with the radio button
	public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption(BUILDING,BUILDING)); 
        options.add(new SelectOption(HOMEOWNER,HOMEOWNER)); 
        return options; 
    }
	
	// Initialize paginator and return a list of accounts
	public List<Account> getAccounts() {
		if(buildingType == BUILDING) {
			if(con.getRecords().size() > 0) {
				return (List<Account>)con.getRecords();
			}
		}
		return new List<Account>();
	}
	
	// Initialize paginator and return a list of contacts
	public List<Contact> getContacts() {
		if(buildingType == HOMEOWNER) {
			if(con.getRecords().size() > 0) {
				return (List<Contact>)con.getRecords();
			}
		}
		return new List<Contact>();
	}
	
	// Instantiate the StandardSetController
	public ApexPages.StandardSetController con {
		get {
			if(con == null) {
				// Fill it with dummy value
				con = new ApexPages.StandardSetController(new List<Account>());
			}
			return con;
		}
		set;
	}
	
	// Returns the total number of the page set
	public Integer totalPages {
		get {
			Integer totalNoOfItems = con.getResultSize();
			Integer maxPerPage = con.getPageSize();
			Integer maxPageNo = totalNoOfItems / maxPerPage;
			if ((maxPerPage * maxPageNo) < totalNoOfItems) {
				maxPageNo += 1;
			}
			return maxPageNo;
		}
		set;	
	}
}