/*
* Test class for Search Building
*
* @author pablo.vigil - pablo.vigil@modelitsoftware.com
* @since 2012-10
*/

@isTest
private class TestBuildingFinderController {

    static testMethod void testAccountObject() {
        List<Account> accs = TestBuildingFinderController.createAccounts(2);
        
        BuildingFinderController bfc = new BuildingFinderController();
        // Select Building from radio button
        bfc.buildingType = bfc.getItems().get(0).getLabel();
        
        // Search for city
        bfc.searchKeyword = 'abcdTestCity';     
        bfc.searchBuildings();
        
        // Should be true since we have 2 accounts with city equal to the search criteria       
        System.assert(bfc.getAccounts().size() == 2);
        
        // First of all we need to sort the accounts since we make a query ordering by name in our logic
        accs.sort();
        for (Integer i = 0; i < accs.size() ; i++) {
            // Check if the inserted accounts are the same as those were retrieved 
            System.assert(accs.get(i).Id == bfc.getAccounts().get(i).Id);
        }
        
        // If we refine a little bit the search
        bfc.searchKeyword = 'abcdTestCity1';        
        bfc.searchBuildings();
        
        // Should be true since we have 1 account with city equal to the search keyword     
        System.assert(bfc.getAccounts().size() == 1);
        
        // Search for building name
        bfc.searchKeyword = 'BIG Test';
        bfc.searchBuildings();
        
        // Should be true since we have 2 accounts with building name equal to the search criteria
        System.assert(bfc.getAccounts().size() == 2);
        
        // Search for account name
        bfc.searchKeyword = 'BuildingBIG';
        bfc.searchBuildings();
        
        // Should be true since we have 2 accounts with building name equal to the search criteria
        System.assert(bfc.getAccounts().size() == 2);
        
        // Search for zip code
        bfc.searchKeyword = '112233';
        bfc.searchBuildings();
        
        // Should be true since we have 2 accounts with zip code equal to the search criteria
        System.assert(bfc.getAccounts().size() == 2);
        
        // Search for state
        bfc.searchKeyword = 'abcdTestState';
        bfc.searchBuildings();
        
        // Should be true since we have 2 accounts with state equal to the search criteria
        System.assert(bfc.getAccounts().size() == 2);
        
        // Search for county
        bfc.searchKeyword = 'Alpine';
        bfc.searchBuildings();
        
        // Should be true since we have 2 accounts with county equal to the search criteria
        System.assert(bfc.getAccounts().size() == 2);
        
        // Search for street address
        bfc.searchKeyword = 'abcdTestAddress';
        bfc.searchBuildings();
        
        // Should be true since we have 2 accounts with street address equal to the search criteria 
        System.assert(bfc.getAccounts().size() == 2);       
    }
    
    static testMethod void testContactObject() {
        List<Account> accs = TestBuildingFinderController.createAccounts(1);
        List<Contact> contacts = TestBuildingFinderController.createContacts(2, accs.get(0).Id);
        
        BuildingFinderController bfc = new BuildingFinderController();
        // Select Homeowner from radio button
        bfc.buildingType = bfc.getItems().get(1).getLabel();        
                
        // Search for first name encrypted field
        bfc.searchKeyword = 'FirstEncrypted';
        bfc.searchBuildings();
        
        // Should be true since we have 2 contacts with first name equal to the search criteria     
        System.assert(bfc.getContacts().size() == 2);
        
        // First of all we need to sort the contacts since we make a query ordering by name in our logic
        contacts.sort();
        for (Integer i = 0; i < contacts.size() ; i++) {
            // Check if the inserted contacts are the same as those were retrieved 
            System.assert(contacts.get(i).Id == bfc.getContacts().get(i).Id);
        }
        
        // If we refine a little bit the search
        bfc.searchKeyword = 'FirstEncrypted1';      
        bfc.searchBuildings();
        
        // Should be true since we have 1 contact with first name equal to the search keyword       
        System.assert(bfc.getContacts().size() == 1);
        
        // Search for last name encrypted field
        bfc.searchKeyword = 'LastEncrypted';
        bfc.searchBuildings();
        
        // Should be true since we have 2 contacts with last name equal to the search criteria      
        System.assert(bfc.getContacts().size() == 2);
        
        // Search for phone number encrypted field
        bfc.searchKeyword = '222333';
        bfc.searchBuildings();
        
        // Should be true since we have 2 contacts with phone number equal to the search criteria       
        System.assert(bfc.getContacts().size() == 2);
        
        // Search for email encrypted field
        bfc.searchKeyword = 'abcdtestemail@domain.com';
        bfc.searchBuildings();
        
        // Should be true since we have 2 contacts with email equal to the search criteria      
        System.assert(bfc.getContacts().size() == 2);   
    }
    
    static testMethod void testNoRecordsFound() {
        List<Account> accs = TestBuildingFinderController.createAccounts(1);
        List<Contact> contacts = TestBuildingFinderController.createContacts(2, accs.get(0).Id);
        
        BuildingFinderController bfc = new BuildingFinderController();      
        // Select Homeowner from radio button
        bfc.buildingType = bfc.getItems().get(1).getLabel();
        bfc.searchKeyword = 'myTestContact';
        bfc.searchBuildings();
        
        System.assert(bfc.getContacts().size() == 0);
        System.assert(bfc.message == 'Number of homeowners found: ' + bfc.getContacts().size());
        
        bfc.searchKeyword = 'myTestAccount';
        // Select Building from radio button
        bfc.buildingType = bfc.getItems().get(0).getLabel();
        bfc.searchBuildings();
        
        System.assert(bfc.getContacts().size() == 0);
        System.assert(bfc.message == 'Number of buildings found: ' + bfc.getAccounts().size());
        
        bfc.searchKeyword = ' ';
        bfc.searchBuildings();
        System.assert(bfc.getContacts().size() == 0);
        System.assert(bfc.message == 'Please enter a keyword. A keyword needs to consist at least 2 characters');
    }
    
    static testMethod void testBulkAccountObject() {
        // Create more than a thousand records for bulk testing purposes
        Test.startTest();
            List<Account> accs = TestBuildingFinderController.createAccounts(1200);
        Test.stopTest();
        
        BuildingFinderController bfc = new BuildingFinderController();
        // Select Building from radio button
        bfc.buildingType = bfc.getItems().get(0).getLabel();
        
        // Search for city
        bfc.searchKeyword = 'abcdTestCity';     
        bfc.searchBuildings();
        
        // Should be true since we set page size to 20 for pagination       
        System.assert(bfc.getAccounts().size() == 20);
        // Should be equal to 60 since totalPages = totalNoOfItems / maxPerPage
        System.assert(bfc.totalPages == 60);
    }
    
    static testMethod void testBulkContactObject() {
        // Create more than a thousand records for bulk testing purposes
        Test.startTest();
            List<Account> accs = TestBuildingFinderController.createAccounts(1);                        
            List<Contact> contacts = TestBuildingFinderController.createContacts(1200, accs.get(0).Id);
        Test.stopTest();
        
        BuildingFinderController bfc = new BuildingFinderController();
        // Select Homeowner from radio button
        bfc.buildingType = bfc.getItems().get(1).getLabel();
        
        // Search for email encrypted field
        bfc.searchKeyword = 'abcdtestemail@domain.com';     
        bfc.searchBuildings();
        
        // Should be true since we set page size to 20 for pagination       
        System.assert(bfc.getContacts().size() == 20);
        // Should be equal to 60 since totalPages = totalNoOfItems / maxPerPage
        System.assert(bfc.totalPages == 60);
    }
        
    private static List<Account> createAccounts(Integer count) {
        Id accRtId = [Select Id from RecordType where name = 'Building' limit 1].Id;
        List<Account> records = new List<Account>();
        
        for(Integer i = 0; i < count; i++) {
            records.add(new Account(name = 'BuildingBIG ' + i,
                                    building_name__c = 'BIG Test ' + i,
                                    zip_code__c = '112233' + i,
                                    phone__c = '222333' + i,
                                    city__c = 'abcdTestCity' + i,
                                    county__c = 'Alpine',
                                    state__c = 'abcdTestState' + i,                                 
                                    street_address__c = 'abcdTestAddress' + i,
                                    recordTypeId = accRtId));
        }
        insert records;        
        // Check if records were properly inserted
        System.assertNotEquals(null, records);
        System.assert(count == records.size());
        
        List<Account> accs = new List<Account>([Select Id from Account where name like 'BuildingBIG%']);
        
        System.assert(count == accs.size());
        return records;
    }
    
    private static List<Contact> createContacts(Integer count, Id accId) {
        Id contactRtId = [Select Id from RecordType where name = 'Homeowner' limit 1].Id;
        List<Contact> records = new List<Contact>();
        
        for(Integer i = 0; i < count; i++) {
            records.add(new Contact(firstname = 'BuildBig' + i,
                                    lastname = 'BuildTest' + i,
                                    first_name__c = 'FirstEncrypted' + i,
                                    last_name__c = 'LastEncrypted' + i,
                                    email__c = 'abcdtestemail@domain.com',
                                    phone_number__c = '222333' + i,
                                    accountId = accId,
                                    recordTypeId = contactRtId));
        }
        insert records;
        // Check if records were properly inserted
        System.assertNotEquals(null, records);
        System.assert(count == records.size());
        
        List<Contact> contacts = new List<Contact>([Select Id from Contact where account.Id =: accId]);
        
        System.assert(count == contacts.size());
        return records;
    }
}