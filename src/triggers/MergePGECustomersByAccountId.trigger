trigger MergePGECustomersByAccountId on PGE_Customer__c (after insert, after update) {
		
	Set<String> accountKeys = new Set<String>();
	for(PGE_Customer__c customer : Trigger.new){
		if(customer.Key__c != null){
			accountKeys.add(customer.Key__c);
		}
	}

	Map<String, PGE_Customer__c> masterRecordsByCustomerKey = new Map<String, PGE_Customer__c>();
	Set<String> duplicateKeys = new Set<String>();
	List<PGE_Customer__c> customersToDelete = new List<PGE_Customer__c>();
	List<PGE_Customer__c> customersToUpdate = new List<PGE_Customer__c>();
	List<PGE_Customer__c> customers = [SELECT Id, Key__c, Account_Id__c, Electric_SAID__c, Gas_SAID__c FROM PGE_Customer__c WHERE Key__c IN :accountKeys ORDER BY CreatedDate ASC];
	for(PGE_Customer__c customer : customers){
		PGE_Customer__c masterRecord = masterRecordsByCustomerKey.get(customer.Key__c);
		if(masterRecord == null){
			masterRecordsByCustomerKey.put(customer.Key__c, customer);
		}
		else{
			if(customer.Electric_SAID__c != null && customer.Electric_SAID__c != ''){
				masterRecord.Electric_SAID__c = customer.Electric_SAID__c;
			}
			if(customer.Gas_SAID__c != null && customer.Gas_SAID__c != ''){
				masterRecord.Gas_SAID__c = customer.Gas_SAID__c;
			}
			if(!duplicateKeys.contains(masterRecord.Key__c)){
				customersToUpdate.add(masterRecord);
				duplicateKeys.add(masterRecord.Key__c);
			}
			customersToDelete.add(customer);
		}
	}

	delete customersToDelete;
	update customersToUpdate;
	
}