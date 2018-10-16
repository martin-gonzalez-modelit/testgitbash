/**
 * This class contains unit tests for batch process in RebateApplicationsEnergyInsightBatch class.
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2017-08
 */
@isTest
private class TestRebateApplicationsEnergyInsightBatch {
    private static List<Rebate_Application__c> rebateApplications = new List<Rebate_Application__c>();
    private static String sessionIdResponseBody = '<soapenv:Envelope xmlns:soapenv='
            + '"http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:partner.soap.sforce.com" xmlns:xsi='
            + '"http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><loginResponse><result><serverUrl>'
            + 'https://na30.salesforce.com/services/Soap/u/40.0/00D36000000ol6I</serverUrl><sessionId>123456789'
            + '</sessionId></result></loginResponse></soapenv:Body></soapenv:Envelope>';

    /**
     * Create Application and 2 Rebate Applications.
     */
    @TestSetup
    private static void initData() {
        Rebate_Application__c rebateApplication;
        Application__c application = BIGPortalTestUtils.createApplication(ApplicationUtils.AHU_RECORD_TYPE);
        insert application;

        // Create 2 Rebate Applications.
        for (Integer i = 0; i < 2; i++) {
            rebateApplication = new Rebate_Application__c();
            rebateApplication.RecordTypeId =
                    Schema.SObjectType.Rebate_Application__c.getRecordTypeInfosByName().get('AHU').getRecordTypeId();
            rebateApplication.Application__c = application.Id;
            rebateApplication.Project_Name__c = 'APP1005664';
            rebateApplication.Customer_First_Name__c = 'Randolph';
            rebateApplication.Customer_Last_Name__c = 'Carter';
            rebateApplication.Site_Notes__c = 'phnglui mglwnafh Cthulhu Rlyeh wgahnagl fhtagn';
            rebateApplication.Inspection_Date__c = Date.valueOf('1890-08-20 00:00:00');
            rebateApplication.Rebate_Status__c = 'Dream-Quest';
            rebateApplication.Check__c = '6';
            rebateApplication.Check_Date__c = Date.valueOf('1890-08-20 00:00:00');
            rebateApplications.add(rebateApplication);
        }

        insert rebateApplications;
    }

    /**
     * Test a complete match (Opportunity/Project Name, Project Id, Measure Code and Project Measure Id)
     * between Rebate Application and EI data.
     */
    public static testMethod void testCompleteMatch() {
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;

        // Set Measure Code, Project Id and Project Measure Id for each Rebate Application.
        rebateApplications.set(0, setRebateApplicationFields(rebateApplications.get(0),
                createValueByFieldMap('CRR11', 'APP1005664_1', 'PM - 02717680')));
        rebateApplications.set(1, setRebateApplicationFields(rebateApplications.get(1),
                createValueByFieldMap('CRR12', 'APP1005664_1', 'PM - 02717681')));
        update rebateApplications;

        String responseBody = createResponseBody('null', 'null', '"CRR11"', '"2010-01-01"', '"123456"', 'APP1005664',
                'APP1005664_1', 'null', 'null', '"CRR12"', '"2010-01-01"', '"654321"', 'APP1005664', 'APP1005664_1');
        Test.setMock(HttpCalloutMock.class, createRequestMock(responseBody));

        Test.startTest();
            Database.executeBatch(new RebateApplicationsEnergyInsightBatch(), 100);
        Test.stopTest();

        // Get Rebate Applications processed from database
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;
        for (Rebate_Application__c rebateApplication : rebateApplications) {
            if (rebateApplication.Project_Measure_Id__c == 'PM - 02717680') {
                assertRebateApplicationIsUpdated(rebateApplication, 'CRR11', 'APP1005664_1',
                        Date.valueOf('2010-01-01 00:00:00'), '123456', 'PM - 02717680');
                assertRebateApplicationFieldsAreIgnored(rebateApplication);
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 02717681') {
                assertRebateApplicationIsUpdated(rebateApplication, 'CRR12', 'APP1005664_1',
                        Date.valueOf('2010-01-01 00:00:00'), '654321', 'PM - 02717681');
                assertRebateApplicationFieldsAreIgnored(rebateApplication);
            }
        }
    }

    /**
     * Test a match  with Opportunity/Project Name, Project Id, Measure Code and Project Measure Id are differents
     * between PG&E abd EI). At the end we should have 4 Rebate Applications.
     */
    public static testMethod void testMatchExceptProjectMeasureId() {
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;

        // Set Measure Code, Project Id and Project Measure Id for each Rebate Application.
        rebateApplications.set(0, setRebateApplicationFields(rebateApplications.get(0),
                createValueByFieldMap('CRR11', 'APP1005664_1', 'PM - 04717680')));
        rebateApplications.set(1, setRebateApplicationFields(rebateApplications.get(1),
                createValueByFieldMap('CRR12', 'APP1005664_1', 'PM - 04717681')));
        update rebateApplications;

        String responseBody = createResponseBody('"2010-01-01"', '"123456"', '"CRR11"', 'null', 'null', 'APP1005664',
                'APP1005664_1', '"2010-01-01"', '"654321"', '"CRR12"', 'null', 'null', 'APP1005664', 'APP1005664_1');
        Test.setMock(HttpCalloutMock.class, createRequestMock(responseBody));

        Test.startTest();
            Database.executeBatch(new RebateApplicationsEnergyInsightBatch(), 100);
        Test.stopTest();

        // Get Rebate Applications processed from database
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;
        for (Rebate_Application__c rebateApplication : rebateApplications) {
            if (rebateApplication.Project_Measure_Id__c == 'PM - 02717680') {
                assertRebateApplicationIsUpdated(rebateApplication, 'CRR11', 'APP1005664_1',
                        Date.valueOf('2010-01-01 00:00:00'), '123456', 'PM - 02717680');
                assertRebateApplicationIsInserted(rebateApplication);
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 02717681') {
                assertRebateApplicationIsUpdated(rebateApplication, 'CRR12', 'APP1005664_1',
                        Date.valueOf('2010-01-01 00:00:00'), '654321', 'PM - 02717681');
                assertRebateApplicationIsInserted(rebateApplication);
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 04717680') {
                assertRebateApplicationIsNotProcessed(rebateApplication, 'CRR11', 'APP1005664_1',
                        Date.valueOf('1890-08-20 00:00:00'), '6', 'PM - 04717680');
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 04717681') {
                assertRebateApplicationIsNotProcessed(rebateApplication, 'CRR12', 'APP1005664_1',
                        Date.valueOf('1890-08-20 00:00:00'), '6', 'PM - 04717681');
            }
        }
    }

    /**
     * Test a complete match (Opportunity/Project Name, Project Id, Measure Code but Project Measure Id = null
     * on PG&E Side) between Rebate Application and EI data.
     */
    public static testMethod void testMatchProjectMeasureIdNull() {
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;

        // Set Measure Code, Project Id and Project Measure Id for each Rebate Application.
        rebateApplications.set(0, setRebateApplicationFields(rebateApplications.get(0),
                createValueByFieldMap('CRR11', 'APP1005664_1', '')));
        rebateApplications.set(1, setRebateApplicationFields(rebateApplications.get(1),
                createValueByFieldMap('CRR12', 'APP1005664_1', '')));
        update rebateApplications;

        String responseBody = createResponseBody('"2010-01-01"', '"123456"', 'CRR11', 'null', 'null', 'APP1005664',
                'APP1005664_1', '"2010-01-01"', '"654321"', 'CRR12', 'null', 'null', 'APP1005664', 'APP1005664_1');
        Test.setMock(HttpCalloutMock.class, createRequestMock(responseBody));

        Test.startTest();
            Database.executeBatch(new RebateApplicationsEnergyInsightBatch(), 100);
        Test.stopTest();

        // Get Rebate Applications processed from database
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;
        for (Rebate_Application__c rebateApplication : rebateApplications) {
            if (rebateApplication.Project_Measure_Id__c == 'PM - 02717680') {
                assertRebateApplicationIsUpdated(rebateApplication, 'CRR11', 'APP1005664_1',
                        Date.valueOf('2010-01-01 00:00:00'), '123456', 'PM - 02717680');
                assertRebateApplicationFieldsAreIgnored(rebateApplication);
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 02717681') {
                assertRebateApplicationIsUpdated(rebateApplication, 'CRR12', 'APP1005664_1',
                        Date.valueOf('2010-01-01 00:00:00'), '654321', 'PM - 02717681');
                assertRebateApplicationFieldsAreIgnored(rebateApplication);
            }
        }
    }

    /**
     * Test a complete match (Opportunity/Project Name, Project Id, Measure Code and Project Measure Id)
     * between Rebate Application and EI data, where Measure Code is null in both sides.
     */
    public static testMethod void testMatchMeasureCodeNull() {
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;

        // Set Measure Code, Project Id and Project Measure Id for each Rebate Application.
        rebateApplications.set(0, setRebateApplicationFields(rebateApplications.get(0),
                createValueByFieldMap('null', 'APP1005664_1', 'PM - 02717680')));
        rebateApplications.set(1, setRebateApplicationFields(rebateApplications.get(1),
                createValueByFieldMap('null', 'APP1005664_1', 'PM - 02717681')));
        update rebateApplications;

        String responseBody = createResponseBody('"2010-01-01"', '"123456"', 'null', 'null', 'null', 'APP1005664',
                'APP1005664_1', '"2010-01-01"', '"654321"', 'null', 'null', 'null', 'APP1005664', 'APP1005664_1');
        Test.setMock(HttpCalloutMock.class, createRequestMock(responseBody));

        Test.startTest();
            Database.executeBatch(new RebateApplicationsEnergyInsightBatch(), 100);
        Test.stopTest();

        // Get Rebate Applications processed from database
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;
        for (Rebate_Application__c rebateApplication : rebateApplications) {
            if (rebateApplication.Project_Measure_Id__c == 'PM - 02717680') {
                assertRebateApplicationIsUpdated(rebateApplication, 'null', 'APP1005664_1',
                        Date.valueOf('2010-01-01 00:00:00'), '123456', 'PM - 02717680');
                assertRebateApplicationFieldsAreIgnored(rebateApplication);
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 02717681') {
                assertRebateApplicationIsUpdated(rebateApplication, 'null', 'APP1005664_1',
                        Date.valueOf('2010-01-01 00:00:00'), '654321', 'PM - 02717681');
                assertRebateApplicationFieldsAreIgnored(rebateApplication);
            }
        }
    }

    /**
     * Test there's no match between Project Id from EI and Project Id from PG&E.
     * It creates a new Rebate Application.
     */
    public static testMethod void testNotMatchOnProjectId() {
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;

        // Set Measure Code, Project Id and Project Measure Id for each Rebate Application.
        rebateApplications.set(0, setRebateApplicationFields(rebateApplications.get(0),
                createValueByFieldMap('CRR11', 'APP1005664_1', 'PM - 04717680')));
        rebateApplications.set(1, setRebateApplicationFields(rebateApplications.get(1),
                createValueByFieldMap('CRR12', 'APP1005664_1', 'PM - 04717681')));
        update rebateApplications;

        String responseBody = createResponseBody('"2010-01-01"', '"123456"', '"CRR11"', 'null', 'null', 'APP1005664',
                'APP1005664_2', '"2010-01-01"', '"654321"', '"CRR12"', 'null', 'null', 'APP1005664', 'APP1005664_2');
        Test.setMock(HttpCalloutMock.class, createRequestMock(responseBody));

        Test.startTest();
            Database.executeBatch(new RebateApplicationsEnergyInsightBatch(), 100);
        Test.stopTest();

        // Get Rebate Applications processed from database
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;
        for (Rebate_Application__c rebateApplication : rebateApplications) {
            if (rebateApplication.Project_Measure_Id__c == 'PM - 02717680') {
                assertRebateApplicationIsUpdated(rebateApplication, 'CRR11', 'APP1005664_2',
                        Date.valueOf('2010-01-01 00:00:00'), '123456', 'PM - 02717680');
                assertRebateApplicationIsInserted(rebateApplication);
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 02717681') {
                assertRebateApplicationIsUpdated(rebateApplication, 'CRR12', 'APP1005664_2',
                        Date.valueOf('2010-01-01 00:00:00'), '654321', 'PM - 02717681');
                assertRebateApplicationIsInserted(rebateApplication);
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 04717680') {
                assertRebateApplicationIsNotProcessed(rebateApplication, 'CRR11', 'APP1005664_1',
                        Date.valueOf('1890-08-20 00:00:00'), '6', 'PM - 04717680');
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 04717681') {
                assertRebateApplicationIsNotProcessed(rebateApplication, 'CRR12', 'APP1005664_1',
                        Date.valueOf('1890-08-20 00:00:00'), '6', 'PM - 04717681');
            }
        }
    }

    /**
     * Test there is not match on Opportunity/Pojrect Name from EI and Opportunity/Project Name from PG&E.
     */
    public static testMethod void testNotMatchOnOpportunityProjectName() {
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;

        // Set Measure Code, Project Id and Project Measure Id for each Rebate Application.
        rebateApplications.set(0, setRebateApplicationFields(rebateApplications.get(0),
                createValueByFieldMap('CRR11', 'APP1005664_1', 'PM - 02717680')));
        rebateApplications.set(1, setRebateApplicationFields(rebateApplications.get(1),
                createValueByFieldMap('CRR12', 'APP1005664_1', 'PM - 02717681')));
        update rebateApplications;

        Test.setMock(HttpCalloutMock.class, createRequestMock(''));

        Test.startTest();
            Database.executeBatch(new RebateApplicationsEnergyInsightBatch(), 100);
        Test.stopTest();

        // Get Rebate Applications processed from database
        rebateApplications = BIGPortalTestUtils.getRebateApplicationsByApplicationId().get(0).Rebate_Applications__r;
        for (Rebate_Application__c rebateApplication : rebateApplications) {
            if (rebateApplication.Project_Measure_Id__c == 'PM - 02717680') {
                assertRebateApplicationIsNotProcessed(rebateApplication, 'CRR11', 'APP1005664_1',
                        Date.valueOf('1890-08-20 00:00:00'), '6', 'PM - 02717680');
            } else if (rebateApplication.Project_Measure_Id__c == 'PM - 02717681') {
                assertRebateApplicationIsNotProcessed(rebateApplication, 'CRR12', 'APP1005664_1',
                        Date.valueOf('1890-08-20 00:00:00'), '6', 'PM - 02717681');
            }
        }
    }

    /**
     * Create fake response for callout, it should be the data obtained from EI. We create 2 OpportunityLineItem
     * with 1 Opportunity related to each one.
     *
     * @param ph01 The place holder related to Check Date for first OpportunityLineItem.
     * @param ph02 The place holder related to Check Number for first OpportunityLineItem.
     * @param ph03 The place holder related to Measure Code for first OpportunityLineItem.
     * @param ph04 The place holder related to Migrated Check Date for first OpportunityLineItem.
     * @param ph05 The place holder related to Migrated Check Number for first OpportunityLineItem.
     * @param ph06 The place holder related to Opportunity/Project Name for first Opportunity.
     * @param ph07 The place holder related to Project Id for first Opportunity.
     * @param ph08 The place holder related to Check Date for second OpportunityLineItem.
     * @param ph09 The place holder related to Check Number for second OpportunityLineItem.
     * @param ph010 The place holder related to Measure Code for second OpportunityLineItem.
     * @param ph011 The place holder related to Migrated Check Date for second OpportunityLineItem.
     * @param ph012 The place holder related to Migrated Check Number for second OpportunityLineItem.
     * @param ph013 The place holder related to Opportunity/Project Name for second Opportunity.
     * @param ph014 The place holder related to Project Id for second Opportunity.
     */
    public static String createResponseBody(String ph01, String ph02, String ph03,  String ph04, String ph05,
            String ph06, String ph07, String ph08, String ph09, String ph10, String ph11, String ph12, String ph13,
             String ph14) {
        String attributeSection = '{"attributes":{';
        String responseBodyResult = '{"totalSize":2,"done":true,"records":[';
        String secondLineOppLineItemsFromEI = '"type":"OpportunityLineItem",'
                + '"url":"/services/data/v39.0/sobjects/OpportunityLineItem/00k3600003QYS6WAAX"},'
                + '"Id":"00k3600003QYS6WAAX","Check_Issue_Date_EI":{0},"Check_Number_EI":{1},'
                + '"CIP_Actual_Insp_Date_EI":"2016-12-08",'
                + '"Install_Date_EI":"2016-12-08",'
                + '"Site_Con_F_Name_EI":"Joseph","Site_Con_L_Name_EI":"Ruelas","Site_Contact_Phone_EI":"5592888714",'
                + '"Site_Address_EI":"1374 W TENAYA WAY","Site_City_EI":"FRESNO","Site_State_EI":"CA",'
                + '"F_Site_Zip_Code_EI":"93711","Payee_Mailing_Add_EI":"1374 W TENAYA WAY",'
                + '"Payee_Mailing_City_EI":"Fresno","Payee_Mailing_State":"CA","Payee_Mailing_Zip_EI":"93711",'
                + '"Payee_Phone_EI":"5592888714","Measure_Code_EI":{2},"Measure_Comments_EI":"MeasureComments",'
                + '"Site_Bldg_Type_EI":"SFm","Materials_Cost_EI":8400,"Provided_Incentive_EI":2,'
                + '"Measure_App_Type_EI":"Replace on Burnout","Payee_Tax_ID_enc_EI":"TaxId",'
                + '"Payee_Tax_Status_EI":"Paid","Project_Measure_Id_EI":"PM - 02717680","Site_Vintage_Year_EI":"1965",'
                + '"Payee_EI":"Joseph Ruelas",'
                + '"Migrated_Check_Date":{3},"Migrated_Check_Number":{4},"Mandatory_CIP_EI":true,"Opportunity":';
        String thirdLineOppLineItemsFromEI = '"type":"Opportunity",'
                + '"url":"/services/data/v39.0/sobjects/Opportunity/0063600000GtGMBAA3"},"Id":"0063600000GtGMBAA3",'
                + '"Name":"{0}","CreatedDate":"2017-01-26T02:27:14.000+0000","StageName":"Rejected",'
                + '"Main_Project_ID_EI":"{1}"}},';
        String fourthLineOppLineItemsFromEI = '"type":"OpportunityLineItem",'
                + '"url":"/services/data/v39.0/sobjects/OpportunityLineItem/00k3600003QYS6XAAX"},'
                + '"Id":"00k3600003QYS6XAAX","Check_Issue_Date_EI":{0},"Check_Number_EI":{1},'
                + '"CIP_Actual_Insp_Date_EI":"2016-12-08",'
                + '"Install_Date_EI":"2016-12-08",'
                + '"Site_Con_F_Name_EI":"Joseph","Site_Con_L_Name_EI":"Ruelas","Site_Contact_Phone_EI":"5592888714",'
                + '"Site_Address_EI":"1374 W TENAYA WAY","Site_City_EI":"FRESNO","Site_State_EI":"CA",'
                + '"F_Site_Zip_Code_EI":"93711","Payee_Mailing_Add_EI":"1374 W TENAYA WAY",'
                + '"Payee_Mailing_City_EI":"Fresno","Payee_Mailing_State":"CA","Payee_Mailing_Zip_EI":"93711",'
                + '"Payee_Phone_EI":"5592888714","Measure_Code_EI":{2},"Measure_Comments_EI":"MeasureComments",'
                + '"Site_Bldg_Type_EI":"SFm","Materials_Cost_EI":8400,"Provided_Incentive_EI":2,'
                + '"Measure_App_Type_EI":"Replace on Burnout","Payee_Tax_ID_enc_EI":"TaxId",'
                + '"Payee_Tax_Status_EI":"Paid","Project_Measure_Id_EI":"PM - 02717681",'
                + '"Site_Vintage_Year_EI":"1965","Payee_EI":"Joseph Ruelas",'
                + '"Migrated_Check_Date":{3},"Migrated_Check_Number":{4},"Mandatory_CIP_EI":true,"Opportunity":';
        String fifthLineOppLineItemsFromEI = '"type":"Opportunity",'
                + '"url":"/services/data/v39.0/sobjects/Opportunity/0063600000GtGMBAA3"},"Id":"0063600000GtGMBAA3",'
                + '"Name":"{0}","CreatedDate":"2017-01-26T02:27:14.000+0000","StageName":"Rejected",'
                + '"Main_Project_ID_EI":"{1}"}}]}';

        responseBodyResult += attributeSection + String.format(secondLineOppLineItemsFromEI, new String[]{ph01, ph02,
                ph03, ph04, ph05});
        responseBodyResult += attributeSection + String.format(thirdLineOppLineItemsFromEI, new String[]{ph06, ph07});
        responseBodyResult += attributeSection + String.format(fourthLineOppLineItemsFromEI, new String[]{ph08, ph09,
                ph10, ph11, ph12});
        responseBodyResult += attributeSection + String.format(fifthLineOppLineItemsFromEI, new String[]{ph13, ph14});

        return responseBodyResult;
    }

    /**
     * Set values for Measure Code, Project Id and Project Measure Id on a Rebate Application.
     *
     * @param rebateApp The Rebate Application that is going to be populated.
     * @param apiNameToValues A Map with API names as key and its values.
     * @return Rebate_Application__c with fields changed.
     */
    private static Rebate_Application__c setRebateApplicationFields(Rebate_Application__c rebateApp,
            Map<String, String> apiNameToValues) {
        for (String fieldName : apiNameToValues.keySet()) {
            rebateApp.put(fieldName, apiNameToValues.get(fieldName));
        }

        return rebateApp;
    }

    /**
     * Create a Map with API Name as key, and field value as value.
     *
     * @param measureCode The Measure Code is going to be populated on Rebate Application.
     * @param projectId The Project Id is going to be populated on Rebate Application.
     * @param projectMeasureId The Project Measure Id is going to be populated on Rebate Application.
     * @return Map with fields and its values created.
     */
    private static Map<String, String> createValueByFieldMap(String measureCode, String projectId,
            String projectMeasureId) {
        return new Map<String, String> {
            'Measure_Code__c' => measureCode,
            'Vendor_Transaction_ID__c' => projectId,
            'Project_Measure_Id__c' => projectMeasureId};
    }

    /**
     * Assert to check Rebate Applications is precessed.
     *
     * @param rebateApplication inserted/updated.
     * @param measureCode related to this rebateApplication.
     * @param projectId related to this rebateApplication.
     * @param checkDate related to this rebateApplication.
     * @param checkNumber related to this rebateApplication.
     * @param projectMeasureId related to this rebateApplication.
     */
    private static void assertRebateApplicationDataUpdated(Rebate_Application__c rebateApplication, String measureCode,
            String projectId, Date checkDate,  String checkNumber, String projectMeasureId) {
        System.assertEquals(measureCode, rebateApplication.Measure_Code__c);
        System.assertEquals(checkDate, rebateApplication.Check_Date__c);
        System.assertEquals(checkNumber, rebateApplication.Check__c);
        System.assertEquals(projectMeasureId, rebateApplication.Project_Measure_Id__c);
        System.assertEquals(projectId, rebateApplication.Vendor_Transaction_ID__c);
        System.assertEquals('APP1005664', rebateApplication.Project_Name__c);
    }

    /**
     * Assert to check when Rebate Application is updated on batch.
     *
     * @param rebateApplication updated.
     */
    private static void assertRebateApplicationIsUpdated(Rebate_Application__c rebateApplication, String measureCode,
            String projectId, Date checkDate,  String checkNumber, String projectMeasureId) {
        System.assertEquals(Date.valueOf('2016-12-08 00:00:00'), rebateApplication.Inspection_Date__c);
        System.assertEquals('Rejected', rebateApplication.Rebate_Status__c);
        assertRebateApplicationDataUpdated(rebateApplication, measureCode, projectId, checkDate, checkNumber,
                projectMeasureId);
    }

    /**
     * Assert to check when Rebate Application is inserted.
     *
     * @param rebateApplication inserted.
     */
    private static void assertRebateApplicationIsInserted(Rebate_Application__c rebateApplication) {
        System.assertEquals('Joseph', rebateApplication.Customer_First_Name__c);
        System.assertEquals('Ruelas', rebateApplication.Customer_Last_Name__c);
        System.assertEquals('MeasureComments', rebateApplication.Site_Notes__c);
    }

    /**
     * Assert to check when Rebate Application is not processed on batch.
     *
     * @param rebateApplication not processed.
     */
    private static void assertRebateApplicationIsNotProcessed(Rebate_Application__c rebateApplication,
            String measureCode, String projectId, Date checkDate,  String checkNumber, String projectMeasureId) {
        System.assertEquals(Date.valueOf('1890-08-20 00:00:00'), rebateApplication.Inspection_Date__c);
        System.assertEquals('Dream-Quest', rebateApplication.Rebate_Status__c);
        assertRebateApplicationFieldsAreIgnored(rebateApplication);
        assertRebateApplicationDataUpdated(rebateApplication, measureCode, projectId, checkDate, checkNumber,
                projectMeasureId);
    }

    /**
     * Assert to check when Rebate Application fields are Ignored.
     *
     * @param rebateApplication inserted or ignored.
     */
    private static void assertRebateApplicationFieldsAreIgnored(Rebate_Application__c rebateApplication) {
        System.assertEquals('Randolph', rebateApplication.Customer_First_Name__c);
        System.assertEquals('Carter', rebateApplication.Customer_Last_Name__c);
        System.assertEquals('phnglui mglwnafh Cthulhu Rlyeh wgahnagl fhtagn', rebateApplication.Site_Notes__c);
    }

    /**
     * Create fake response for call outs.
     *
     * @param responseBody The fake response body for 2nd callout.
     * @return RequestMock created with fake responses inside.
     */
    private static RequestMock createRequestMock(String responseBody){
        RequestMock reqMock = new RequestMock();

        // Create fake response for Session Id callout.
        reqMock.addResponse(RequestMock.createResponse(HttpConstants.STATUS_CODE_OK, HttpConstants.STATUS_OK,
                sessionIdResponseBody, null));
        // Create fake response for Rest Api callout to get records from EI.
        reqMock.addResponse(RequestMock.createResponse(HttpConstants.STATUS_CODE_OK, HttpConstants.STATUS_OK,
                responseBody, null));

        return reqMock;
    }

}