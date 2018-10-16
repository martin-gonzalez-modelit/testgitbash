/**
 * This class contains unit tests for validating the behavior of BIG Portal HPXML Delete Manager Class
 * @author Francisco Cobas <francisco.cobas@modelitsoftware.com>
 * @since 06/2014
 */
@isTest
private class TestBIGPortalHPXMLDeleteManager { 
    
    private static List<Id> preAppsId = new List<Id>();
    private static Set<Id> notDeleted = new Set<Id>();
    
    /*
     * Create data
     */
    private static void initData() {
        Integer counter = 0;
        
        Application__c app = HPXMLDeleteTestUtils.createApplication();
        insert app;
        System.assertNotEquals(null, app.Id); 
        
        List<Sub_Application__c> preApplications = new List<Sub_Application__c>();
        preApplications.add(HPXMLDeleteTestUtils.createSubApplication(app.Id));
        preApplications.add(HPXMLDeleteTestUtils.createSubApplication(app.Id));
        insert preApplications;
        for (Sub_Application__c preApp : preApplications) {
            System.assertNotEquals(null, preApp.Id);
            preAppsId.add(preApp.Id);
        }
        
        // insert headers
        List<HP_XML_Transaction_Header_Information__c> headers = new List<HP_XML_Transaction_Header_Information__c>();
        for (Sub_Application__c preApp : preApplications) {
        	headers.add(HPXMLDeleteTestUtils.createHPHeader(preApp.Id));
        }
        insert headers;
        notDeleted.add(headers.get(1).Id);
        for (HP_XML_Transaction_Header_Information__c header : headers) {
        	System.assertNotEquals(null, header.Id);
        }
        
        // insert buildings
        List<HP_Building__c> buildings = new List<HP_Building__c>();
        counter = 0;
        for (Sub_Application__c preApp : preApplications) {
            buildings.add(HPXMLDeleteTestUtils.createHPBuilding('FC_Test_Building_' + counter, preApplications.get(counter).Id));
            counter++;
        }
        insert buildings;
        notDeleted.add(buildings.get(1).Id);
        for (HP_Building__c building : buildings) {
            System.assertNotEquals(null, building.Id);
        }
        
        // insert projects
        List<HP_Project__c> projects = new List<HP_Project__c>();
        counter = 0;
        for (Sub_Application__c preApp : preApplications) {
            projects.add(HPXMLDeleteTestUtils.createHPProject('FC_Test_Project_' + counter, preApplications.get(counter).Id));
            counter++;
        }
        insert projects;
        notDeleted.add(projects.get(1).Id);
        for (HP_Project__c project : projects) {
            System.assertNotEquals(null, project.Id);   
        }
        
        // insert business info
        List<HP_Business_Info__c> businessesInfo = new List<HP_Business_Info__c>();
        businessesInfo.add(HPXMLDeleteTestUtils.createHPBusinessInfo('FC_Test_Business_Info_1'));
        businessesInfo.add(HPXMLDeleteTestUtils.createHPBusinessInfo('FC_Test_Business_Info_2'));
        insert businessesInfo;
        notDeleted.add(businessesInfo.get(1).Id);
        for (HP_Business_Info__c businessInfo : businessesInfo) {
            System.assertNotEquals(null, businessInfo.Id);
        }
        
        // insert contractors
        List<HP_Contractor__c> contractors = new List<HP_Contractor__c>();
        counter = 0;
        for (HP_Business_Info__c businessInfo : businessesInfo) {
            contractors.add(HPXMLDeleteTestUtils.createHPContractor('FC_Test_Contractor_' + counter, preApplications.get(counter).Id, businessInfo.Id, null));
            counter++;
        }
        insert contractors;
        notDeleted.add(contractors.get(1).Id);
        for (HP_Contractor__c contractor : contractors) {
            System.assertNotEquals(null, contractor.Id);
        }       
        
        // insert subContractors
        List<HP_Contractor__c> subContractors = new List<HP_Contractor__c>();
        counter = 0;
        for (HP_Contractor__c contractor : contractors) {
            subContractors.add(HPXMLDeleteTestUtils.createHPContractor('FC_Test_Sub_Contractor_' + counter , null, null, contractor.Id));
            counter++;
        }
        insert subContractors;
        notDeleted.add(subContractors.get(1).Id);
        for (HP_Contractor__c subContractor : subContractors) {
            System.assertNotEquals(null, subContractor.Id);
        }
        
        // insert another level of subcontractors.
        List<HP_Contractor__c> otherSubContractors = new List<HP_Contractor__c>();
        counter = 0;
        for (HP_Contractor__c contractor : subContractors) {
            otherSubContractors.add(HPXMLDeleteTestUtils.createHPContractor('FC_Test_Other_Sub_Contractor_' + counter , null, null, contractor.Id));
            counter++;
        }
        insert otherSubContractors;
        notDeleted.add(otherSubContractors.get(1).Id);
        for (HP_Contractor__c otherSubContractor : otherSubContractors) {
            System.assertNotEquals(null, otherSubContractor.Id);
        }
        
        // insert measures
        List<HP_Measure__c> measures = new List<HP_Measure__c>();
        counter = 0;
        for (HP_Contractor__c contractor : contractors) {
            measures.add(HPXMLDeleteTestUtils.createHPMeasure('FC_Test_Measure_' + counter, projects.get(counter).Id, contractor.Id));
            counter++;
        }
        insert measures;
        notDeleted.add(measures.get(1).Id);
        for (HP_Measure__c measure : measures) {
            System.assertNotEquals(null, measure.Id);
        }
        
        // insert Energy Saving Info
        List<HP_Energy_Savings_Info__c> energySavings = new List<HP_Energy_Savings_Info__c>();
        counter = 0;
        for (HP_Measure__c measure : measures) {
            energySavings.add(HPXMLDeleteTestUtils.createHPEnergySaving('FC_Test_EnergySavingInfo_' + counter, projects.get(counter).Id, measure.Id));
            counter++;
        } 
        insert energySavings;
        notDeleted.add(energySavings.get(1).Id);
        for (HP_Energy_Savings_Info__c energySaving : energySavings) {
            System.assertNotEquals(null, energySaving.Id);
        }
        
        // insert Water Saving Info
        List<HP_Water_Savings_Info__c> waterSavings = new List<HP_Water_Savings_Info__c>();
        counter = 0;
        for (HP_Measure__c measure : measures) {
            waterSavings.add(HPXMLDeleteTestUtils.createHPWaterSaving(projects.get(counter).Id, measure.Id));
            counter++;
        }
        insert waterSavings;
        notDeleted.add(waterSavings.get(1).Id);
        for (HP_Water_Savings_Info__c waterSaving : waterSavings) {
            System.assertNotEquals(null, waterSaving.Id);
        }
        
        // insert Appliances Type Summary Info
        List<HP_Appliances_Type_Summary_Info__c> appliances = new List<HP_Appliances_Type_Summary_Info__c>();
        appliances.add(HPXMLDeleteTestUtils.createHPApplianceSummaryInfo('FC_Test_Appliance_1'));
        appliances.add(HPXMLDeleteTestUtils.createHPApplianceSummaryInfo('FC_Test_Appliance_2'));
        insert appliances;
        notDeleted.add(appliances.get(1).Id);
        for (HP_Appliances_Type_Summary_Info__c appliance : appliances) {
            System.assertNotEquals(null, appliance.Id);
        }
        
        // insert Utilities
        List<HP_Utility__c> utilities = new List<HP_Utility__c>();
        utilities.add(HPXMLDeleteTestUtils.createHPUtility('FC_Test_Utility_1', businessesInfo.get(0).Id, preApplications.get(0).Id));
        utilities.add(HPXMLDeleteTestUtils.createHPUtility('FC_Test_Utility_2', businessesInfo.get(1).Id, preApplications.get(1).Id));
        insert utilities;
        notDeleted.add(utilities.get(1).Id);
        for (HP_Utility__c utility : utilities) {
            System.assertNotEquals(null, utility.Id);   
        }
        
        
        // insert person
        List<HP_Person__c> persons = new List<HP_Person__c>();
        persons.add(HPXMLDeleteTestUtils.createHPPerson('FC_Test_Person_1', businessesInfo.get(0).Id, contractors.get(0).Id, utilities.get(0).Id, preApplications.get(0).Id, null));
        persons.add(HPXMLDeleteTestUtils.createHPPerson('FC_Test_Person_2', businessesInfo.get(1).Id, contractors.get(1).Id, utilities.get(1).Id, preApplications.get(1).Id, null));
        insert persons;
        notDeleted.add(persons.get(1).Id);
        for (HP_Person__c person : persons) {
            System.assertNotEquals(null, person.Id);
        }
        
        // insert othercontacts
        List<HP_Person__c> otherContacts = new List<HP_Person__c>();
        counter = 0;
        for (HP_Person__c person : persons) {
            otherContacts.add(HPXMLDeleteTestUtils.createHPPerson('FC_Test_Other_Contact_' + counter, businessesInfo.get(counter).Id, contractors.get(counter).Id, utilities.get(counter).Id, preApplications.get(counter).Id, person.Id));
            counter++;
        }
        insert otherContacts;
        notDeleted.add(otherContacts.get(1).Id);
        for (HP_Person__c person : otherContacts) {
            System.assertNotEquals(null, person.Id);
        }
        
        // insert consumption
        List<HP_Consumption__c> consumptions = new List<HP_Consumption__c>();
        counter = 0;
        for (HP_Person__c person : persons) {
            consumptions.add(HPXMLDeleteTestUtils.createHPConsumption('FC_Test_Consumption_' + counter, buildings.get(counter).Id, preApplications.get(counter).Id, person.Id));
            counter++;
        }
        insert consumptions;
        notDeleted.add(consumptions.get(1).Id);
        for (HP_Consumption__c consumption : consumptions) {
            System.assertNotEquals(null, consumption.Id);
        }       
        
        // create utilities objects
        
        // insert clothes dryer
        List<HP_Clothes_Dryer__c> clothesDryers = new List<HP_Clothes_Dryer__c>();
        clothesDryers.add(HPXMLDeleteTestUtils.createHPClothesDryer(buildings.get(0).Id, appliances.get(0).Id));
        clothesDryers.add(HPXMLDeleteTestUtils.createHPClothesDryer(buildings.get(1).Id, appliances.get(1).Id));
        insert clothesDryers;
        for (HP_Clothes_Dryer__c clothesDryer : clothesDryers) {
            System.assertNotEquals(null, clothesDryer.Id);
        }
        
        // insert clothes washers
        List<HP_Clothes_Washer__c> clothesWashers = new List<HP_Clothes_Washer__c>();
        clothesWashers.add(HPXMLDeleteTestUtils.createHPClothesWasher(buildings.get(0).Id, appliances.get(0).Id));
        clothesWashers.add(HPXMLDeleteTestUtils.createHPClothesWasher(buildings.get(1).Id, appliances.get(1).Id));
        insert clothesWashers;
        for (HP_Clothes_Washer__c clothesWasher : clothesWashers) {
            System.assertNotEquals(null, clothesWasher.Id);
        }
        
        // insert cooking range
        List<HP_Cooking_Range__c> cookingRanges = new List<HP_Cooking_Range__c>();
        cookingRanges.add(HPXMLDeleteTestUtils.createHPCookingRange(buildings.get(0).Id, appliances.get(0).Id));
        cookingRanges.add(HPXMLDeleteTestUtils.createHPCookingRange(buildings.get(1).Id, appliances.get(1).Id));
        insert cookingRanges;
        for (HP_Cooking_Range__c cookingRange : cookingRanges) {
            System.assertNotEquals(null, cookingRange.Id);
        }
        
        // insert dehumidifier
        List<HP_Dehumidifier__c> dehumidifiers = new List<HP_Dehumidifier__c>();
        dehumidifiers.add(HPXMLDeleteTestUtils.createHPDehumidifier(buildings.get(0).Id, appliances.get(0).Id));
        dehumidifiers.add(HPXMLDeleteTestUtils.createHPDehumidifier(buildings.get(1).Id, appliances.get(1).Id));
        insert dehumidifiers;
        for (HP_Dehumidifier__c dehumidifier : dehumidifiers) {
            System.assertNotEquals(null, dehumidifier.Id);
        }
        
        // insert dishwashers
        List<HP_Dishwasher__c> dishwashers = new List<HP_Dishwasher__c>();
        dishwashers.add(HPXMLDeleteTestUtils.createHPDishwasher(buildings.get(0).Id, appliances.get(0).Id));
        dishwashers.add(HPXMLDeleteTestUtils.createHPDishwasher(buildings.get(1).Id, appliances.get(1).Id));
        insert dishwashers;
        for (HP_Dishwasher__c dishwasher : dishwashers) {
            System.assertNotEquals(null, dishwasher.Id);
        }
        
        // insert freezers
        List<HP_Freezer__c> freezers = new List<HP_Freezer__c>();
        freezers.add(HPXMLDeleteTestUtils.createHPFreezer(buildings.get(0).Id, appliances.get(0).Id));
        freezers.add(HPXMLDeleteTestUtils.createHPFreezer(buildings.get(1).Id, appliances.get(1).Id));
        insert freezers;
        for (HP_Freezer__c freezer : freezers) {
            System.assertNotEquals(null, freezer.Id);
        }
        
        // insert ovens
        List<HP_Oven__c> ovens = new List<HP_Oven__c>();
        ovens.add(HPXMLDeleteTestUtils.createHPOven(buildings.get(0).Id, appliances.get(0).Id));
        ovens.add(HPXMLDeleteTestUtils.createHPOven(buildings.get(1).Id, appliances.get(1).Id));
        insert ovens;
        for (HP_Oven__c oven : ovens) {
            System.assertNotEquals(null, oven.Id);
        }
        
        // insert refrigerators
        List<HP_Refrigerator__c> refrigerators = new List<HP_Refrigerator__c>();
        refrigerators.add(HPXMLDeleteTestUtils.createHPRefrigerator(buildings.get(0).Id, appliances.get(0).Id));
        refrigerators.add(HPXMLDeleteTestUtils.createHPRefrigerator(buildings.get(1).Id, appliances.get(1).Id));
        insert refrigerators;
        for (HP_Refrigerator__c refrigerator : refrigerators) {
            System.assertNotEquals(null, refrigerator.Id);
        }       
    }
    
    
    /*
     * Test method
     */
    static testMethod void testDeleteMethod() {
        Test.startTest();
        
        initData();
        
        Test.stopTest();
        
        
        BIGPortalHPXMLDeleteManager HPXMLDeleteManager = new BIGPortalHPXMLDeleteManager();
        
        // retrieve and verify if the original elements were inserted successfully
        List<HP_XML_Transaction_Header_Information__c> headers = [SELECT Id FROM HP_XML_Transaction_Header_Information__c];
        System.assertEquals(2, headers.size());
        
        List<HP_Building__c> buildings = [SELECT Id FROM HP_Building__c];
        System.assertEquals(2, buildings.size());
        
        List<HP_Project__c> projects = [SELECT Id FROM HP_Project__c];
        System.assertEquals(2, projects.size());
        
        List<HP_Measure__c> measures = [SELECT Id FROM HP_Measure__c];
        System.assertEquals(2, measures.size());
        
        List<HP_Energy_Savings_Info__c> energySavings = [SELECT Id FROM HP_Energy_Savings_Info__c];
        System.assertEquals(2, energySavings.size());
        
        List<HP_Water_Savings_Info__c> waterSavings = [SELECT Id FROM HP_Water_Savings_Info__c];
        System.assertEquals(2, waterSavings.size());
        
        List<HP_Appliances_Type_Summary_Info__c> appliances = [SELECT Id FROM HP_Appliances_Type_Summary_Info__c];
        System.assertEquals(2, appliances.size());
        
        List<HP_Contractor__c> contractors = [SELECT Id FROM HP_Contractor__c];
        System.assertEquals(6, contractors.size());
        
        List<HP_Utility__c> utilities = [SELECT Id FROM HP_Utility__c];
        System.assertEquals(2, utilities.size());
        
        List<HP_Consumption__c> consumptions = [SELECT Id FROM HP_Consumption__c];
        System.assertEquals(2, consumptions.size());
        
        List<HP_Person__c> persons = [SELECT Id FROM HP_Person__c];
        System.assertEquals(4, persons.size());
        
        // excecute HPXMLDelete method
        HPXMLDeleteManager.deleteHPXmLObjects(preAppsId.get(0));
        
        // query again all list to verify the correct deletion of the objects
       	headers = [SELECT Id FROM HP_XML_Transaction_Header_Information__c];
       	System.assertEquals(1, headers.size());
       	System.assert(notDeleted.contains(headers.get(0).Id));
        
        buildings = [SELECT Id FROM HP_Building__c];
        System.assertEquals(1, buildings.size());
        System.assert(notDeleted.contains(buildings.get(0).Id));
        
        projects = [SELECT Id FROM HP_Project__c];
        System.assertEquals(1, projects.size());
        System.assert(notDeleted.contains(projects.get(0).Id));
        
        measures = [SELECT Id FROM HP_Measure__c];
        System.assertEquals(1, measures.size());
        System.assert(notDeleted.contains(measures.get(0).Id));
        
        energySavings = [SELECT Id FROM HP_Energy_Savings_Info__c];
        System.assertEquals(1, energySavings.size());
        System.assert(notDeleted.contains(energySavings.get(0).Id));
        
        waterSavings = [SELECT Id FROM HP_Water_Savings_Info__c];
        System.assertEquals(1, waterSavings.size());
        System.assert(notDeleted.contains(waterSavings.get(0).Id));
        
        appliances = [SELECT Id FROM HP_Appliances_Type_Summary_Info__c];
        System.assertEquals(1, appliances.size());
        System.assert(notDeleted.contains(appliances.get(0).Id));
        
        contractors = [SELECT Id FROM HP_Contractor__c];
        System.assertEquals(3, contractors.size());
        for (HP_Contractor__c contractor : contractors) {
            System.assert(notDeleted.contains(contractor.Id));
        }
        
        utilities = [SELECT Id FROM HP_Utility__c];
        System.assertEquals(1, utilities.size());
        System.assert(notDeleted.contains(utilities.get(0).Id));
        
        consumptions = [SELECT Id FROM HP_Consumption__c];
        System.assertEquals(1, consumptions.size());
        System.assert(notDeleted.contains(consumptions.get(0).Id));
        
        persons = [SELECT Id FROM HP_Person__c];
        System.assertEquals(2, persons.size());
        for (HP_Person__c person : persons) {
            System.assert(notDeleted.contains(person.Id));
        }
    }
}