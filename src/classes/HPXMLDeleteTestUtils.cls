public with sharing class HPXMLDeleteTestUtils {
	
	// main objects
	
	public static Application__c createApplication() {
		Application__c app = new Application__c();
		
		return app; 
	}
	
	public static Sub_Application__c createSubApplication(Id appId) {
		Sub_Application__c preApp = new Sub_Application__c();
		preApp.Application__c = appId;

		return preApp;
	}
	
	public static HP_XML_Transaction_Header_Information__c createHPHeader(Id preAppId) {
		HP_XML_Transaction_Header_Information__c header = new HP_XML_Transaction_Header_Information__c();
		header.Sub_Application__c = preAppId;
		
		return header;
	}
	
	public static HP_Building__c createHPBuilding(String systemIdentifier, Id preAppId) {
		HP_Building__c building = new HP_Building__c();
		building.System_Identifier__c = systemIdentifier;
		building.Sub_Application__c = preAppId;
		
		return building;
	}
	
	public static HP_Project__c createHPProject(String systemIdentifier, Id preAppId) {
		HP_Project__c project = new HP_Project__c();
		project.System_Identifier__c = systemIdentifier;
		project.Sub_Application__c = preAppId;
		
		return project;
	}
	
	public static HP_Measure__c createHPMeasure(String systemIdentifier, Id projectId, Id contractorId) {
		HP_Measure__c measure = new HP_Measure__c();
		measure.System_Identifier__c = systemIdentifier;
		measure.HP_Project__c = projectId;
		measure.Installing_Contractor__c = contractorId;
		
		return measure;
	}
	
	public static HP_Energy_Savings_Info__c createHPEnergySaving(String systemIdentifier, Id projectId, Id measureId) {
		HP_Energy_Savings_Info__c energySaving = new HP_Energy_Savings_Info__c();
		energySaving.System_Identifier__c = systemIdentifier;
		energySaving.HP_Project__c = projectId;
		energySaving.HP_Measure__c = measureId;
		
		return energySaving;
	}
	
	public static HP_Water_Savings_Info__c createHPWaterSaving(Id projectId, Id measureId) {
		HP_Water_Savings_Info__c waterSaving = new HP_Water_Savings_Info__c();
		waterSaving.HP_Project__c = projectId;
		waterSaving.HP_Measure__c = measureId;
		
		return waterSaving;
	}
	
	public static HP_Appliances_Type_Summary_Info__c createHPApplianceSummaryInfo(String systemIdentifier) {
		HP_Appliances_Type_Summary_Info__c appliance = new HP_Appliances_Type_Summary_Info__c();
		appliance.System_Identifier__c = systemIdentifier;
		
		return appliance;
	}
	
	public static HP_Contractor__c createHPContractor(String systemIdentifier, Id preAppId, Id businessInfoId, Id subContractorId) {
		HP_Contractor__c contractor = new HP_Contractor__c();
		contractor.System_Identifier__c = systemIdentifier;
		contractor.Sub_Application__c = preAppId;
		contractor.HP_Business_Info__c = businessInfoId;
		contractor.HP_Contractor__c = subContractorId;
				
		return contractor;
	}
	
	public static HP_Utility__c createHPUtility(String systemIdentifier, Id businessInfoId, Id preAppId) {
		HP_Utility__c utility = new HP_Utility__c();
		utility.System_Identifier__c = systemIdentifier;
		utility.HP_Business_Info__c = businessInfoId;
		utility.Sub_Application__c = preAppId;
		
		return utility;
	}
	
	public static HP_Consumption__c createHPConsumption(String systemIdentifier, Id buildingId, Id preAppId, Id personId) {
		HP_Consumption__c consumption = new HP_Consumption__c();
		consumption.System_Identifier__c = systemIdentifier;
		consumption.HP_Building__c = buildingId;
		consumption.Sub_Application__c = preAppId;
		consumption.HP_Person__c = personId;
		
		return consumption;		
	}
	
	public static HP_Person__c createHPPerson(String systemIdentifier, Id businessId, Id contractorId, Id utilityId, Id preAppId, Id otherContactId) {
		HP_Person__c person = new HP_Person__c();
		person.System_Identifier__c = systemIdentifier;
		person.HP_Business_Info__c = businessId;
		person.HP_Contractor__c = contractorId;
		person.HP_Utility_Fuel_Provider__c = utilityId;
		person.Sub_Application__c = preAppId;
		person.HP_Person__c = otherContactId;
		
		return person;
	}
	
	public static HP_Business_Info__c createHPBusinessInfo(String systemIdentifier) {
		HP_Business_Info__c businessInfo = new HP_Business_Info__c();
		businessInfo.System_Identifier__c = systemIdentifier;
		
		return businessInfo;
	}
	
	// utitlities objects 
	
	public static HP_Clothes_Dryer__c createHPClothesDryer(Id buildingId, Id applianceId) {
		HP_Clothes_Dryer__c clothesDryer = new HP_Clothes_Dryer__c();
		clothesDryer.HP_Building__c = buildingId;
		clothesDryer.HP_Appliances_Type_Summary_Info__c = applianceId;
		
		return clothesDryer;
	}
	
	public static HP_Clothes_Washer__c createHPClothesWasher(Id buildingId, Id applianceId) {
		HP_Clothes_Washer__c clothesWasher = new HP_Clothes_Washer__c();
		clothesWasher.HP_Building__c = buildingId;
		clothesWasher.HP_Appliances_Type_Summary_Info__c = applianceId;
		
		return clothesWasher;
	}
	
	public static HP_Cooking_Range__c createHPCookingRange(Id buildingId, Id applianceId) {
		HP_Cooking_Range__c cookingRange = new HP_Cooking_Range__c();
		cookingRange.HP_Building__c = buildingId;
		cookingRange.HP_Appliances_Type_Summary_Info__c = applianceId;
		
		return cookingRange;
	}
	
	public static HP_Dehumidifier__c createHPDehumidifier(Id buildingId, Id applianceId) {
		HP_Dehumidifier__c dehumidifier = new HP_Dehumidifier__c();
		dehumidifier.HP_Building__c = buildingId;
		dehumidifier.HP_Appliances_Type_Summary_Info__c = applianceId;
		
		return dehumidifier;
	}
	
	public static HP_Dishwasher__c createHPDishwasher(Id buildingId, Id applianceId) {
		HP_Dishwasher__c dishwasher = new HP_Dishwasher__c();
		dishwasher.HP_Building__c = buildingId;
		dishwasher.HP_Appliances_Type_Summary_Info__c = applianceId;
		
		return dishwasher;
	}
	
	public static HP_Freezer__c createHPFreezer(Id buildingId, Id applianceId) {
		HP_Freezer__c freezer = new HP_Freezer__c();
		freezer.HP_Building__c = buildingId;
		freezer.HP_Appliances_Type_Summary_Info__c = applianceId;
		
		return freezer;
	}
	
	public static HP_Oven__c createHPOven(Id buildingId, Id applianceId) {
		HP_Oven__c oven = new HP_Oven__c();
		oven.HP_Building__c = buildingId;
		oven.HP_Appliances_Type_Summary_Info__c = applianceId;
		
		return oven;
	}
	
	public static HP_Refrigerator__c createHPRefrigerator(Id buildingId, Id applianceId) {
		HP_Refrigerator__c refrigerator = new HP_Refrigerator__c();
		refrigerator.HP_Building__c = buildingId;
		refrigerator.HP_Appliances_Type_Summary_Info__c = applianceId;
		
		return refrigerator;
	}
}