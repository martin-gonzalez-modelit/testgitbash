trigger CustomerMeasure on Customer_Measure__c (before insert, before update) {

	Set<String> acctKeys = new Set<String>();
	Set<String> measureCodes = new Set<String>();
	for(Customer_Measure__c cm : Trigger.new){
		
		String[] parts = cm.Key__c.split(';;');
		if(parts.size() == 2){
			
			String acctKey = parts[0];
			acctKeys.add(acctKey);
			
			String measureCode = parts[1];
			measureCodes.add(measureCode);
			
		}
		
	}
	
	List<PGE_Customer__c> customers = [SELECT Id, Key__c FROM PGE_Customer__c WHERE Key__c IN :acctKeys];
	Map<String, PGE_Customer__c> customersByAccountKey = new Map<String, PGE_Customer__c>();
	for(PGE_Customer__c customer : customers){
		customersByAccountKey.put(customer.Key__c, customer);
	}
	
	List<PGE_Measure_Code__c> measures = [SELECT Id, Name FROM PGE_Measure_Code__c WHERE Name IN :measureCodes];
	Map<String, PGE_Measure_Code__c> measuresByName = new Map<String, PGE_Measure_Code__c>();
	for(PGE_Measure_Code__c measure : measures){
		measuresByName.put(measure.Name, measure);
	}
	
	for(Customer_Measure__c cm : Trigger.new){
		
		String[] parts = cm.Key__c.split(';;');
		if(parts.size() == 2){
			
			String acctKey = parts[0];
			PGE_Customer__c customer = customersByAccountKey.get(acctKey);
			if(customer != null){
				cm.PGE_Customer__c = customer.Id;
			}
			
			String measureCode = parts[1];
			PGE_Measure_Code__c measure = measuresByName.get(measureCode);
			if(measure != null){
				cm.PGE_Measure_Code__c = measure.Id;
			}
			
		}
		
	}

}