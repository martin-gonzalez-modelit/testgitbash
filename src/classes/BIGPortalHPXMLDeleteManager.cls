/**
 * 
 * @author Francisco Cobas <francisco.cobas@modelitsoftware.com>
 * @since 2014-06
 */

public with sharing class BIGPortalHPXMLDeleteManager {
	
	private List<HP_XML_Transaction_Header_Information__c> headers = null;
	private List<HP_Building__c> buildings = null;
	private List<HP_Project__c> projects = null;
	private List<HP_Measure__c> measures = null;
	private List<HP_Energy_Savings_Info__c> energySavings = null;
	private List<HP_Water_Savings_Info__c> waterSavings = null;
	private List<HP_Appliances_Type_Summary_Info__c> applianceTypesSummaryInfo = null;
	private List<HP_Contractor__c> contractors = null;
	private Map<Id, HP_Person__c> persons = null;
	private List<HP_Person__c> otherContacts = null;
	private List<HP_Consumption__c> consumptions = null;
	private List<HP_Business_Info__c> bussinessesInfo = null;
	private List<HP_Utility__c> utilities = null;
	 
	private Set<Id> businessesIds = new Set<Id>();
	private Set<Id> personsIds = new Set<Id>();
	private Set<Id> appliancesTypesSummaryInfoIds = new Set<Id>();
	private Set<Id> contractorsIds = new Set<Id>();
	
	/*
	 * Delete all objects related to a sub-application
	 */
	public void deleteHPXmLObjects(Id preAppId) {
		try {
			// get XMLTransacationHeaderInformation
			headers = [SELECT Id, Sub_Application__c FROM HP_XML_Transaction_Header_Information__c WHERE Sub_Application__c =:preAppId];
			
			// get all buildings related to Sub Application with utility related lists.
			buildings = [SELECT Id, Sub_Application__c, HP_Customer__c, (SELECT Id, HP_Appliances_Type_Summary_Info__c FROM Clothes_Dryers__r), 
						(SELECT Id, HP_Appliances_Type_Summary_Info__c FROM Clothes_Washers__r), (SELECT Id, HP_Appliances_Type_Summary_Info__c FROM HP_Cooking_Ranges__r), 
						(SELECT Id, HP_Appliances_Type_Summary_Info__c FROM HP_Dehumidifiers__r), (SELECT Id, HP_Appliances_Type_Summary_Info__c FROM HP_Dishwashers__r), 
						(SELECT Id, HP_Appliances_Type_Summary_Info__c FROM HP_Freezers__r), (SELECT Id, HP_Appliances_Type_Summary_Info__c FROM HP_Ovens__r), 
						(SELECT Id, HP_Appliances_Type_Summary_Info__c FROM HP_Refrigerators__r) FROM HP_Building__c WHERE Sub_Application__c =: preAppId];
			
			if (buildings.size() > 0) {
				for (HP_Building__c building : buildings) {
					
					if (building.HP_Customer__c != null) {
						personsIds.add(building.HP_Customer__c);
					}
									
					if (building.Clothes_Dryers__r.size() > 0 ) {
						for (HP_Clothes_Dryer__c c : building.Clothes_Dryers__r){
							if (c.HP_Appliances_Type_Summary_Info__c != null) {
								appliancesTypesSummaryInfoIds.Add(c.HP_Appliances_Type_Summary_Info__c);
							}
						}
					}
					
					if (building.Clothes_Washers__r.size() > 0 ) {
						for (HP_Clothes_Washer__c c : building.Clothes_Washers__r){
							if (c.HP_Appliances_Type_Summary_Info__c != null) {
								appliancesTypesSummaryInfoIds.Add(c.HP_Appliances_Type_Summary_Info__c);
							}
						}
					}
					
					if (building.HP_Cooking_Ranges__r.size() > 0 ) {
						for (HP_Cooking_Range__c c : building.HP_Cooking_Ranges__r){
							if (c.HP_Appliances_Type_Summary_Info__c != null) {
								appliancesTypesSummaryInfoIds.Add(c.HP_Appliances_Type_Summary_Info__c);
							}
						}
					}
					
					if (building.HP_Dehumidifiers__r.size() > 0 ) {
						for (HP_Dehumidifier__c c : building.HP_Dehumidifiers__r){
							if (c.HP_Appliances_Type_Summary_Info__c != null) {
								appliancesTypesSummaryInfoIds.Add(c.HP_Appliances_Type_Summary_Info__c);
							}
						}
					}
					
					if (building.HP_Dishwashers__r.size() > 0 ) {
						for (HP_Dishwasher__c c : building.HP_Dishwashers__r){
							if (c.HP_Appliances_Type_Summary_Info__c != null) {
								appliancesTypesSummaryInfoIds.Add(c.HP_Appliances_Type_Summary_Info__c);
							}
						}
					}
					
					if (building.HP_Freezers__r.size() > 0) {
						for (HP_Freezer__c c : building.HP_Freezers__r){
							if (c.HP_Appliances_Type_Summary_Info__c != null) {
								appliancesTypesSummaryInfoIds.Add(c.HP_Appliances_Type_Summary_Info__c);
							}
						}
					}
					
					if (building.HP_Ovens__r.size() > 0 ) {
						for (HP_Oven__c c : building.HP_Ovens__r){
							if (c.HP_Appliances_Type_Summary_Info__c != null) {
								appliancesTypesSummaryInfoIds.Add(c.HP_Appliances_Type_Summary_Info__c);
							}
						}
					}
					
					if (building.HP_Refrigerators__r.size() > 0 ) {
						for (HP_Refrigerator__c c : building.HP_Refrigerators__r){
							if (c.HP_Appliances_Type_Summary_Info__c != null) {
								appliancesTypesSummaryInfoIds.Add(c.HP_Appliances_Type_Summary_Info__c);
							}
						}
					}
				}
			}
			
			// get all projects related to sub-application
			projects = [SELECT Id, Sub_Application__c, (SELECT Id FROM HP_Measures__r) FROM HP_Project__c WHERE Sub_Application__c =: preAppId];
					
			// get all measures related to each project 
			measures = [SELECT Id, HP_Project__c, Installing_Contractor__c FROM HP_Measure__c WHERE HP_Project__c IN :projects];
			
			// get all energy savings info related to each project or each measure
			energySavings = [SELECT Id, HP_Measure__c, HP_Project__c FROM HP_Energy_Savings_Info__c WHERE HP_Measure__c IN :measures OR HP_Project__c IN :projects];
			
			// get all water savings info related to each project or each measure
			waterSavings = [SELECT Id, HP_Measure__c, HP_Project__c FROM HP_Water_Savings_Info__c WHERE HP_Measure__c IN :measures OR HP_Project__c IN :projects];
			
			// get all appliances type summary info
			applianceTypesSummaryInfo = [SELECT Id FROM HP_Appliances_Type_Summary_Info__c WHERE Id IN :appliancesTypesSummaryInfoIds];
			
			// get all contractors related to sub-application
			contractors = [SELECT Id, Sub_Application__c, HP_Business_Info__c FROM HP_Contractor__c WHERE Sub_Application__c = :preAppId];
			
			List<HP_Contractor__c> tmp = new List<HP_Contractor__c>();
			
			// load all contractors and sub-contractors in contractors List
			getAllContractors(contractors, tmp);
			
			// clone edited list to contractors list
			contractors = tmp;
			
			if (contractors.size() > 0) {
				for (HP_Contractor__c c : contractors) {
					if (c.HP_Business_Info__c != null) {
						// save business info ids
						businessesIds.add(c.HP_Business_Info__c);
					}
				}
			}
			
			// get all utilities realted to sub-appplication
			utilities = [SELECT Id, Sub_Application__c, HP_Business_Info__c FROM HP_Utility__c WHERE Sub_Application__c =:preAppId];
			
			if (utilities.size() > 0) {
				for (HP_Utility__c utility : utilities) {
					if (utility.HP_Business_Info__c != null) {
						// save business info ids
						businessesIds.Add(utility.HP_Business_Info__c);
					}
				}
			}				
			
			// get all consumption related to sub-application or building
			consumptions = [SELECT Id, HP_Building__c, Sub_Application__c, HP_Person__c FROM HP_Consumption__c WHERE HP_Building__c IN :buildings OR Sub_Application__c = :preAppId];
			
			if (consumptions.size() > 0) {
				for (HP_Consumption__c c : consumptions) {
					if (c.HP_Person__c != null) {
						// save person ids
						personsIds.add(c.HP_Person__c);
					}
				}
			}
	
			// get all person related to sub-application || utilities || contractors || persons
			persons = new Map<Id, HP_Person__c>([SELECT Id, HP_Business_Info__c, Sub_Application__c, (SELECT Id FROM HP_Other_Contacts__r) FROM HP_Person__c WHERE Sub_Application__c =:preAppId OR 
											HP_Utility_Fuel_Provider__c IN :utilities OR HP_Contractor__c IN :contractors OR Id IN :personsIds]);
											
			otherContacts =  new List<HP_Person__c>();
			
			if (persons.size() > 0) {
				for (HP_Person__c person : persons.values()) {
					if (person.HP_Other_Contacts__r.size() > 0) {
						otherContacts.addAll(person.HP_Other_contacts__r);
					}
					if (person.HP_Business_Info__c != null) {
						// save business info ids
						businessesIds.Add(person.HP_Business_Info__c);
					}
				}
			}
			
			if (otherContacts.size() > 0) {
				for (HP_Person__c person : otherContacts) {
					if (persons.containsKey(person.Id)) {
						persons.put(person.Id, person);
					}
				}	
			}
			
			// get all business Info
			bussinessesInfo = [SELECT Id, (SELECT Id FROM HP_Business_Contacts__r) FROM HP_Business_Info__c WHERE Id IN :businessesIds];
			
			if (bussinessesInfo.size() > 0) {
				for (HP_Business_Info__c bi : bussinessesInfo) {
					if (bi.HP_Business_Contacts__r.size() > 0) {
						for (HP_Person__c p : bi.HP_Business_Contacts__r) {
							if (persons.containsKey(p.Id)) {
								persons.put(p.Id, p);
							}
						}
					}
				}
			}		
			
			// get total number of objects found
			Integer totalObjectsFound = bussinessesInfo.size() + persons.size() + consumptions.size() + utilities.size() + contractors.size() + applianceTypesSummaryInfo.size();
			totalObjectsFound += waterSavings.size() + energySavings.size() + measures.size() + projects.size() + buildings.size();
			
			System.debug('### Total number of objects that will be delete: ' +  totalObjectsFound);
			
			// delete lists objects found
			if (bussinessesInfo.size() > 0) {
				delete bussinessesInfo;
			}
			
			if (persons.size() > 0) {
				delete persons.values();
			}
			 
			if (consumptions.size() > 0) {
				delete consumptions;
			}
			
			if (utilities.size() > 0) {
				delete utilities;
			}
			
			if (contractors.size() > 0) {
				delete contractors;
			}
			
			if (applianceTypesSummaryInfo.size() > 0) {
				delete applianceTypesSummaryInfo;
			}
			
			if (waterSavings.size() > 0) {
				delete waterSavings;
			}
			
			if (energySavings.size() > 0) {
				delete energySavings;
			}
			
			if (measures.size() > 0) {
				delete measures;
			}
			
			if (projects.size() > 0) {
				delete projects;
			}
			
			if (buildings.size() > 0) {
				delete buildings;
			}
			
			if (headers.size() > 0) {
				delete headers;
			}			
		} catch (Dmlexception dmlE) {
			System.debug('### DMLException while trying to do a DML operation: ' + dmlE.getMessage());
		} catch (Exception e) {
			System.debug('### Exception while trying to do a DML operation: ' + e.getMessage());
		}
	}
	
	
	/*
	 * Get all contractors and sub-contractors
	 */
	public void getAllContractors(List<HP_Contractor__c> cont, List<HP_Contractor__c> result) {
		if (result == null)
			result = new List<HP_Contractor__c>();
		
		List<HP_Contractor__c> recursiveQueryContractor = [SELECT Id, Sub_Application__c, HP_Business_Info__c, (SELECT Id FROM HP_Sub_Contractors__r) FROM HP_Contractor__c WHERE Id IN :cont];
				
		if (recursiveQueryContractor.size() > 0) {
			for (HP_Contractor__c contractor : recursiveQueryContractor) {
				if (contractor.HP_Sub_Contractors__r.size() > 0) {
					getAllContractors(contractor.HP_Sub_Contractors__r, result);
				} 
				result.add(contractor);
			}
		}
	}
}