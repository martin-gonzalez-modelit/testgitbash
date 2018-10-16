/**
 * Utility class for advanced home upgrade applications.
 *
 * @author Maiquel Cabrera <maiquel.cabrera@modelitsoftware.com>
 * @since 2014-03
 */
public with sharing class BIGPortalAdvanceHUApplicationUtils {

    // Public Constants
    public static final String APPLICATION_RECORD_TYPE_NAME = 'AHU';
    public static final String SUBAPP_PRE_RECORD_TYPE_NAME = 'PRE-APP';
    public static final String SUBAPP_POST_RECORD_TYPE_NAME = 'POST-APP';
    public static final String EP_SUBAPP_PRE_RECORD_TYPE_NAME = 'EnergyPro Pre-Installation';
    public static final String EP_SUBAPP_POST_RECORD_TYPE_NAME = 'EnergyPro Post-Installation';
    public static Id APPLICATION_RECORD_TYPE_ID;
    public static Id SUBAPP_PRE_RECORD_TYPE_ID;
    public static Id SUBAPP_POST_RECORD_TYPE_ID;
    public static Id EP_SUBAPP_PRE_RECORD_TYPE_ID;
    public static Id EP_SUBAPP_POST_RECORD_TYPE_ID;
    public static String TOTAL_ENERGY_SAVINGS_PERCENT_ERROR = 'This application is not eligible because it did not ' +
            'meet the minimum {0}% modeled savings incentive requirement.';
    public static final String YES = 'Yes';
    public static final String NO = 'No';

    // Pre-Application
    public static final String PRE_CONTRACT_SOW_FILE = 'Contract (Proposal)/SOW';
    public static final String PRE_HOME_PERFORMANCE_XML = 'Home Performance XML (HPXML)';
    public static final String PRE_HOME_PERFORMANCE_SYS = 'Home Performance System File';
    public static final String PRE_TEST_IN_MEASUREMENTS = 'Test-In Measurements (CAS) Form';
    public static final String PRE_ADDITIONAL_DOCUMENTS = 'Additional Documents (Zip)';
    public static final String PRE_PAYMENT_RELEASE_AUTH = 'Payment Release Authorization';
    public static final String PRE_HOME_ENERGY_SCORE_REPORT_INPUT_FILE = 'Home Energy Score Report / Input File';
    public static final String PRE_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS =
            'Additional / Supplemental Home Energy Score Documents';
    public static final String PRE_GREEN_BUILDING_REGISTRY_OPT_IN = 'Green Building Registry Opt-In';
    public static final String PRE_ACTION_NEXT = 'next';
    public static final String PRE_SAVE_MESSAGE = 'Your Pre-Installation Application is saved.';
    public static final String POST_SAVE_MESSAGE = 'Your Post-Installation Application is saved.';

    // Post-Application
    public static final String POST_CLIENT_SIGNED_SOW_FILE = 'Client-Signed Contract/SOW';
    public static final String POST_HOME_PERFORMANCE_XML = 'POST-APP Home Performance XML (HPXML)';
    public static final String POST_HOME_PERFORMANCE_SYS = 'POST-APP Home Performance System File';
    public static final String POST_TEST_OUT_MEASUREMENTS = 'Test-Out Measurements (CAS) Form';
    public static final String POST_ADDITIONAL_DOCUMENTS = 'POST-APP Additional Documents';
    public static final String POST_PAYMENT_RELEASE_AUTH = 'POST-APP Payment Release Authorization';
    public static final String POST_QUALITY_ACKNOWLEDGMENT = 'Safety & Quality Acknowledgment';
    public static final String POST_BUILDING_PERMIT = 'Building Permit';
    public static final String POST_HOME_ENERGY_SCORE_REPORT_INPUT_FILE =
            'POST-APP Home Energy Score Report / Input File';
    public static final String POST_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS =
            'POST-APP Additional / Supplemental Home Energy Score Documents';
    public static final String POST_GREEN_BUILDING_REGISTRY_OPT_IN = 'POST-APP Green Building Registry Opt-In';
    public static final String POST_DELIVERED_SENSIBLE_EER_SCORESHEET = 'Delivered Sensible EER Scoresheet';
    public static final String HIGH_PERFORMANCE_HVAC_INSTALLER = 'High Performance HVAC Installer';
    public static final String POST_ACTION_NEXT = 'next';
    public static final String ESTIMATED_INCENTIVE_TOTAL_ERROR = 'The Estimated Incentive Total, ${0}, may not ' +
            'exceed the Proposed/Completed Installation Cost';
    public static final String ESTIMATED_50_PERCENT_INCENTIVE_TOTAL_ERROR = 'The Estimated Incentive Total, ' +
            '${0}, may not exceed the 50% of Proposed/Completed Installation Cost';
    public static final String TAX_INFO_REQUIRED_ERROR = 'Tax information is required for rebate assignment to ' +
            'contractor payee. Please contact jobs@homeupgrade.org or fax W-9 to (510) 590-3361.';

    // Private Constants
    private static final String NATURAL_GAS = 'natural gas';
    private static final String ELECTRICITY = 'electricity';
    private static final String CONTRACTOR_PAYEE = 'Contractor Payee';
    private static final String XML_PROCESSING_ERROR = 'There was an error completing your request. Please try again.';
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final String OVERRIDE_REBATE_TIER_SECOND_STRUCTURE = 'Pre-August 1 Tier Structure';
    private static PGE_Portal_Settings__c settings;

    public HPXML hpxmlEntry {get; set;}
    // Private Properties
    private BIGPortalUser userUtility;

    public  BIGPortalAdvanceHUApplicationUtils() {
        userUtility = new BIGPortalUser();
    }

    static {
        populateRecordsTypes();
        initCustomSetting();
    }

    /*
     * Set record types into constants
     */
    private static void populateRecordsTypes() {
        // pupulate the application id recordtype
        APPLICATION_RECORD_TYPE_ID = Schema.SObjectType.Application__c.getRecordTypeInfosByName()
                .get(APPLICATION_RECORD_TYPE_NAME).getRecordTypeId();

        // generate a map to reuse in sub applications record types
        Map<String, Schema.RecordTypeInfo> subAppSchema = Schema.SObjectType.Sub_Application__c
                .getRecordTypeInfosByName();
        // assign sub applications record types
        SUBAPP_PRE_RECORD_TYPE_ID = subAppSchema.get(SUBAPP_PRE_RECORD_TYPE_NAME).getRecordTypeId();
        SUBAPP_POST_RECORD_TYPE_ID = subAppSchema.get(SUBAPP_POST_RECORD_TYPE_NAME).getRecordTypeId();
        EP_SUBAPP_PRE_RECORD_TYPE_ID = subAppSchema.get(EP_SUBAPP_PRE_RECORD_TYPE_NAME).getRecordTypeId();
        EP_SUBAPP_POST_RECORD_TYPE_ID = subAppSchema.get(EP_SUBAPP_POST_RECORD_TYPE_NAME).getRecordTypeId();
    }

    private static void initCustomSetting() {
        settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);

        if (settings == null || settings.AHU_Pre_Structure_Change_DateTime__c == null
                || settings.AHU_Post_Structure_Change_DateTime__c == null
                || settings.AHU_Pre_Structure_Change_DateTime_SoCal__c == null
                || settings.AHU_Post_Structure_Change_DateTime_SoCal__c == null) {
            System.debug('Please define all the fields for the Custom Setting PGE Portal Settings.');
        }
    }
    private HPXMLResponseWrapper processHupXml(Attachment hupxmlFile, Application__c app, Sub_Application__c subApp,
            Boolean isPostAppStatus) {
        String xmlBody = null;
        String returnXMLResult = null;
        HPXMLResponseWrapper response = null;
        try {
            String result = null;
            List<Attachment> hupxmlFiles = [SELECT Id, Body FROM Attachment WHERE Id =: hupxmlFile.Id];
            if (!hupxmlFiles.isEmpty()) {
                hupxmlFile = hupxmlFiles.get(0);
                if (hupxmlFile.Body != null) {
                    xmlBody = hupxmlFile.Body.toString();
                    response = new HPXMLResponseWrapper();
                    response.setSuccess(true);

                    HPXMLParser parser = new HPXMLParser();
                    parser.application = app;
                    parser.subApplication = subApp;

                    XmlStreamReader reader = new XmlStreamReader(xmlBody);
                    List<String> parserResult = parser.processHPXML(reader, isPostAppStatus);
                    if (!parserResult.isEmpty()) {
                        String message = '';
                        for (String errorMessage : parserResult) {
                            if (message != '') {
                                message += '<br/>';
                            }
                            message += errorMessage;
                        }
                        message += '<br/>';
                        String origMessage = response.getErrorMessage();
                        if (origMessage != null && origMessage != '') {
                            origMessage += ';';
                            origMessage += message;
                        } else {
                            origMessage = message;
                        }
                        response.setSuccess(false);
                        response.setErrorMessage(origMessage);
                    } else {
                        hpxmlEntry = parser.entry;
                        hpxmlEntry.isPostApplication = isPostAppStatus;
                        hpxmlEntry.analyzeData();
                    }
                }
            }
        } catch (HPXML.HPXMLException e) {
            response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
        } catch (HPXML.TaxInfoException e) {
            response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
        } catch (HPXML.TotalEnergySavingsPercentException e) {
            response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
        } catch (Exception e) {
            System.debug('### Exception while processing HUPXML: ' + e.getStackTraceString());
            response = deserializeJsonResponse('{"success":false, "errorMessage":"' + XML_PROCESSING_ERROR +
                            '", "exceptionMessage":""}');
        }
        return response;
    }

    /*
     * Deserialize response JSON to an object
     * @param string response string
     * @return XMLResponseWrapper object
     */
    private HPXMLResponseWrapper deserializeJsonResponse(string responseString) {
        HPXMLResponseWrapper response = (HPXMLResponseWrapper) JSON.deserialize(responseString,
                HPXMLResponseWrapper.Class);
        return response;
    }

    /*
     * Convert a number from Therms to Kbtu
     */
    private Double convertThermsTokBtu(Decimal thermValue) {
        return thermValue * 1000;
    }

    /*
     * Convert a number from Therms to Kbtu
     */
    private Double convertKwhTokBtu(Decimal thermValue) {
        return thermValue * 3.412;
    }

    /*
     * Log the HPXML error if exist
     * @param HPXMLResponseWrapper JSON Response
     * @return void
     */
    private void logHPXMLError(HPXMLResponseWrapper hupXMLResult, Id preAppId) {
        PGELogHandlingUtil errorHandling = PGELogHandlingUtil.getInstance();

        if (hupXMLResult.getErrorMessage() != null && !hupXMLResult.getSuccess()) {
            errorHandling.logError(BIGPortalAdvanceHUApplicationUtils.Class.getName(), 'Generate HPXML Fails',
                    hupXMLResult.getErrorMessage(), preAppId);

            errorHandling.logMessage();
        }
    }

    /*
     * Get APPLICATION by ID
     */
    public Application__c getApplication(Id applicationId) {
        Application__c app;

        if (String.isNotBlank(applicationId)) {
            try {
                List<Application__c> applications = [
                    SELECT Id, Name, RecordType.Name, Sub_Total__c, Rebate_Assignment_Form__c,
                        Test_In_Measure_CAS_Form__c, Test_Out_Measure_CAS_Form__c, CAS_Test_Acknowledgement_Form__c,
                        Building_Permit__c, Building_City__c, Building_State__c, Building_ZIP_Code__c,
                        Building_Name__c, Building_Street_Address__c, Building_Type__c, Dwelling_Unit_Name__c,
                        Dwelling_Unit_Number__c, Dwelling_Unit_Street_Address__c, Dwelling_Unit__c,
                        Customer_First_Name__c, Customer_Last_Name__c, Customer_Address__c, Customer_City__c,
                        Customer_Phone__c, Customer_State__c, Customer_Zip_Code__c, Payee_Full_Name__c, Payee_Phone__c,
                        Payee_Street_Address__c, Payee_City__c, Payee_State__c, Payee_ZIP_Code__c,
                        Utility_Account_Holder_First_Name__c, Utility_Account_Holder_Last_Name__c,
                        Utility_Account_Holder_Phone__c, Contractor__r.Name, Contractor__r.BillingStreet,
                        Contractor__r.BillingCity, Contractor__r.BillingState, Contractor__r.BillingPostalCode,
                        Contractor__r.Phone, Contractor__c, Rebate_Assignment__c, Work_Start_Date__c,
                        Work_Finish_Date__c, Status__c, Notes__c, Application_Step__c, Application_Submission_Date__c,
                        LastModifiedDate, LastModifiedById, Granted_Exceptions__c, Gas_Provider__c,
                        Has_Pre_Install_HES__c, Has_Post_Install_HES__c, Final_Incentive_Total__c,
                        Project_Financing_Source__c, Project_Financing_Detail__c, Project_Financing_Description__c,
                        Pre_Home_Energy_Score__c, Post_Home_Energy_Score__c, Pre_HES_Assessment_Date__c,
                        Post_HES_Assessment_Date__c, Pre_HES_Assessor__c, Post_HES_Assessor__c,
                        Pre_HES_Assessor__r.Name, Post_HES_Assessor__r.Name, Conditioned_Area__c,
                        Post_Conditioned_Area__c, Has_Conditioned_Area_Changed__c, Has_HPHI__c, HPHI_Practitioner__c,
                        HPHI_Practitioner__r.Name, Delivered_Sensible_EER__c, Delivered_Sensible_EER_Assessment_Date__c,
                        Delivered_Sensible_EER_Scoresheet__c,
                        (SELECT Id, Application__c, Test_In_Date__c, Work_Start_Date__c, Work_Finish_Date__c,
                            Test_Out_Date__c, Customer_Cost__c, Total_Incentive_from_Tier__c, Modeling_Type__c,
                            Proposed_Package_Cost__c, Rebate_Assignment__c, Contract_Proposal_SOW__c,
                            Home_Performance_System_File__c, Home_Performance_XML__c, Payment_Release_Authorization__c,
                            Additional_Documents__c, Test_In_Measurements__c, Client_Signed_Contract_SOW__c,
                            Test_Out_Measurements__c, Safety_Quality_Acknowledgment__c, Completed_Package_Cost__c,
                            BPI_Analyst__c, BPI_Analyst__r.Name, RecordTypeId, Has_HPXML__c,
                            Total_Energy_Savings_Percent__c, Unadjusted_Energy_Savings_Percent__c,
                            Total_Adjusted_Savings_kWh__c, Total_Energy_Savings_kWh__c, Total_Energy_Savings_therms__c,
                            Total_Energy_Savings_BTUs__c, Total_Adjusted_Savings_therms__c, Total_Incentive__c,
                            Total_Incentive_Adjustment__c, Software_Version__c, Software__c,
                            PGE_Payable_Modeled_Savings_Incentive__c, Stage__c, Application__r.Status__c,
                            Air_Conditioning_Present__c, Building_Street_Address__c, Building_City__c,
                            Building_State__c, Building_ZIP_Code__c, Number_of_Stories__c, Number_of_Dwelling_Units__c,
                            Pre_Install_Electricity_Use_kWh__c, Pre_Install_Gas_Use_therms__c, RecordType.Name,
                            Building_Permit__c, HES_Report_Input_File__c, HES_Additional_Documents__c, GBR_Opt_In__c,
                            Application__r.Delivered_Sensible_EER_Scoresheet__c, Has_HPHI__c, HPHI_Bonus__c,
                            HPHI_Practitioner__r.Name
                        FROM Sub_Applications__r ORDER BY CreatedDate ASC)
                    FROM Application__c
                    WHERE Id = :applicationId
                        AND Contractor__c = :userUtility.getAccount().Id
                        AND RecordTypeId = :APPLICATION_RECORD_TYPE_ID
                    ];

                if (!applications.isEmpty()) {
                    app = applications.get(0);
                }
            } catch (Exception e) {
                System.debug('### Exception while trying to query for application: ' + e.getMessage());
            }
        }

        return app;
    }

    /**
     * Get Application with Status__c field
     */
    public Application__c getApplicationStatus(Id applicationId) {
        Application__c app;
        if (String.isNotBlank(applicationId)) {
            List<Application__c> applications = [
                SELECT Id, Name, Status__c FROM Application__c WHERE Id = :applicationId
                ];

            if (!applications.isEmpty()) {
                app = applications.get(0);
            }
        }
        return app;
    }

    /**
     * Get PRE-Application by ID
     */
    public Sub_Application__c getPreApplication(String preApplicationId, String applicationId) {
        Sub_Application__c subApp;
        List<Sub_Application__c> l = [
            SELECT Id, Application__c, Test_In_Date__c, Customer_Cost__c, Total_Incentive_from_Tier__c,
                Modeling_Type__c, Proposed_Package_Cost__c, Rebate_Assignment__c, Contract_Proposal_SOW__c,
                Home_Performance_System_File__c, Home_Performance_XML__c, Payment_Release_Authorization__c,
                Additional_Documents__c, Test_In_Measurements__c, RecordTypeId, Total_Incentive_Adjustment__c
            FROM Sub_Application__c
            WHERE Id = :preApplicationId
                AND Application__c = :applicationId
                AND Application__r.Contractor__c = :userUtility.getAccount().Id
                AND RecordTypeId = :SUBAPP_PRE_RECORD_TYPE_ID
            ];

        if (!l.isEmpty()) {
            subApp = l.get(0);
        }
        return subApp;
    }

    /**
     * Get the list of XML End Use related to a Sub Application
     * @param Sub Application Id.
     * @return XML End Use related to subApplication
     */
    public List<XML_End_Use__c> getXMLEndUse(Id subAppId) {
        return [
            SELECT Id, End_Use__c, Item_Incentive_Amount__c FROM XML_End_Use__c WHERE Sub_Application__c = :subAppId
            ];
    }

    /**
     * Gets all contacts that have an HPHI credential with an "Active - Verified" status, for a specific account.
     *
     * @param accountId The account id related to the practitioners.
     * @return A list of active contacts with HPHI credentials.
     */
    public List<Contact> getHPHIPractitioners(Id accountId) {
        List<Contact> contacts = new List<Contact>();

        try {
            contacts = [
                SELECT Id, FirstName, LastName
                FROM Contact
                WHERE AccountId = :accountId
                    AND Id IN (
                        SELECT Contact__c
                        FROM Credential__c
                        WHERE Account__c = :accountId
                            AND Credential_Type__c = :HIGH_PERFORMANCE_HVAC_INSTALLER
                            AND Status__c = :ApplicationUtils.CREDENTIAL_ACTIVE_VERIFIED_STATUS)
                ];
        } catch (QueryException e) {
            System.debug('###Error: Couldn\'t get Contact. Message: ' + e.getStackTraceString());
        }

        return contacts;
    }

    /**
     * Save Pre-Application
     * @return void
     */
    public HPXMLResponseWrapper savePreApplication(Application__c app, Dwelling_Unit__c dwellingUnit,
            Sub_Application__c preApplication, List<Attachment> attachments,
            BIGPortalManageApplicationUtils applicationUtility, String action, Attachment hupxmlFile) {

        HPXMLResponseWrapper response = new HPXMLResponseWrapper();
        app.Dwelling_Unit__c = dwellingUnit.Id;
        app.Contractor__c = userUtility.getAccount().Id;
        Integer step = 2;

        if (preApplication.Id != null && action == PRE_ACTION_NEXT && hupxmlFile != null) {
            //determine software type
            EnergyProXMLParser ep = new EnergyProXMLParser(app, preApplication, false, hupxmlFile);
            String software = ep.getSoftwareName();

            if (software == 'EnergyPro') {
                try {
                    //parse XML
                    ep.parseEnergyProXML();

                    step = 3;
                    response = deserializeJsonResponse('{"success":true, "errorMessage":"", "exceptionMessage":""}');

                } catch (EnergyProXMLParser.EnergyProXMLParserException e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
                }  catch (EnergyProXML.TaxInfoException e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
                } catch (EnergyProXML.EnergyProXMLException e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
                } catch (EnergyProXML.TotalEnergySavingsPercentException e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
                } catch (Exception e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + XML_PROCESSING_ERROR +
                            '", "exceptionMessage":""}');
                    system.debug('###Exception while processing EnergyPro file:' + e.getMessage());
                }
            } else {
                // Process HUPXML
                response = processHupXml(hupxmlFile, app, preApplication, false);

                if (response.getSuccess() != null) {
                    if (response.getSuccess()) {
                        preApplication.Has_HPXML__c = true;
                        step = 3;
                    } else {
                        if (response.getErrorMessage() != null) {
                            System.debug('### HUPXML Process Error: ' + response.getErrorMessage());

                            // if the error has description, set only the description
                            if (response.getErrorMessage().split('\n').size() == 10) {
                                response.setErrorMessage(response.getErrorMessage().split('\n').get(2));
                            }
                        }

                        if (response.getExceptionMessage() != null) {
                            System.debug('### HUPXML Exception : ' + response.getExceptionMessage());
                        }

                        // If has an error, change status tu keep in the step #2
                        logHPXMLError(response, preApplication.Id);
                    }
                }
            }
        }

        try {
            app.Application_Step__c = step;
            populateWorkStartFinishDates(preApplication, app);
            processHomeEnergyScore(app, preApplication);
            upsert app;

            // if it's new pre application then
            if (preApplication.Application__c == null) {
                preApplication.Application__c = app.Id;
            }

            //get updated app and pre-app instances
            app = getApplication(app.Id);

            if (getSubApplication(app, preApplication) != null) {
                // We don't want to lose the values that comes from the page (binded to the preApplication)
                Map<String, Object> fieldsToValue = preApplication.getPopulatedFieldsAsMap();
                preApplication = getSubApplication(app, preApplication);
                //Populating the binded values after getting the latest postApplication
                populateSubAppicationFields(preApplication, fieldsToValue);
            }

            upsert preApplication;
        } catch (DMLException e) {
            System.debug('### DMLException when trying to update Application: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('### Exception when trying to update Application: ' + e.getMessage());
        }
        // Insert Pre-Application files
        insertSubApplicationFiles(app.Id, preApplication, attachments);

        return response;
    }

    public void saveSubApplicationBPIAnalyst (Sub_Application__c subApp) {
        try {
            upsert subApp;
        } catch (DMLException e) {
            System.debug('### A DML Exception has ocurred trying to save PreApplication :' + e.getMessage());
        } catch (Exception ex) {
            System.debug('### A Generic Exception has ocurred trying to save PreApplication :' + ex.getMessage());
        }
    }

    /**
     * Perform calculations and get Modeled Total Energy Consumption value
     * @param preApplicationId
     * @return Modeled Total Energy Consumption value
     */
    public Double getModeledTotalEnergyConsumption (Id preAppId) {
        Double returnCalculation = 0;
        if (preAppId != null) {
            List<HP_Consumption__c> consumptions = [
                SELECT Id, Sub_Application__c,
                    (SELECT Id, Consumption_Type__c, Energy_Fuel_Type__c, Total_Consumption__c
                    FROM HP_Consumptions_Info__r
                    WHERE Consumption_Type__c = 'Consumption'
                        AND (Energy_Fuel_Type__c =:NATURAL_GAS OR Energy_Fuel_Type__c =:ELECTRICITY))
                FROM HP_Consumption__c
                WHERE Sub_Application__c =: preAppId
                ];

            for (HP_Consumption__c consumption : consumptions) {
                List<HP_Consumption_Info__c> consumptionInfos =  consumption.HP_Consumptions_Info__r;

                for (HP_Consumption_Info__c consumptionInfo : consumptionInfos) {
                    if (consumptionInfo.Energy_Fuel_Type__c == NATURAL_GAS) {
                        // natural gas use therms. We need to convert to kBtu.
                        returnCalculation += convertThermsTokBtu(consumptionInfo.Total_Consumption__c);

                    } else if (consumptionInfo.Energy_Fuel_Type__c == ELECTRICITY) {
                        // electricity use Kwh. We need to convert to kBtu.
                        returnCalculation += convertKwhTokBtu(consumptionInfo.Total_Consumption__c);
                    }
                }
            }
        }
        return returnCalculation;
    }

    /*
     * Perform calculation and get Modeled Energy Savings value
     * @param preApplicationId
     * @return Modeled Energy Saving value
     */
    public Double getModeledEnergySavings (Id preAppId) {
        Double returnCalculation = 0;
        Set<Id> energySavingInfoIds = new Set<Id>();
        if (preAppId != null) {
            List<HP_Project__c> projects = [
                SELECT Id, Sub_Application__c,
                    (SELECT Id FROM HP_Energy_Savings_Info__r)
                FROM HP_Project__c
                WHERE Sub_Application__c =: preAppId
            ];

            for (HP_Project__c project : projects) {
                List<HP_Energy_Savings_Info__c> energySavingInfos = project.HP_Energy_Savings_Info__r;

                if (energySavingInfos.size() > 0) {
                    energySavingInfoIds.addAll(new Map<Id, HP_Energy_Savings_Info__c>(energySavingInfos).keySet());
                }
            }

            if (energySavingInfoIds.size() > 0) {
                List<HP_Fuel_Saving__c> fuelSavings = [
                    SELECT Id, Fuel__c, Units__c, HP_Energy_Savings_Info__c, Total_Savings__c
                    FROM HP_Fuel_Saving__c
                    WHERE HP_Energy_Savings_Info__c
                        IN :energySavingInfoIds AND (Fuel__c =:NATURAL_GAS
                        OR Fuel__c =:ELECTRICITY)
                    ];

                for (HP_Fuel_Saving__c fuelSaving : fuelSavings) {
                    if (fuelSaving.Fuel__c == NATURAL_GAS) {
                        // natural gas use therms. We need to convert to kBtu.
                        returnCalculation += convertThermsTokBtu(fuelSaving.Total_Savings__c);

                    } else if (fuelSaving.Fuel__c == ELECTRICITY) {
                        // electricity use Kwh. We need to convert to kBtu.
                        returnCalculation += convertKwhTokBtu(fuelSaving.Total_Savings__c);
                    }
                }
            }
        }
        return returnCalculation;
    }

    /*
     * Perform calculation and get Total Rebate Value value.
     * @param preApplicationId
     * @return totalRebateValue in $
     */
    public Double getTotalRebateValue(Id preAppId) {
        Double totalRebateValue = 0;
        Double modeledEnergySavingsPercentage = 0;

        Double modeledTotalEnergyConsumption = getModeledTotalEnergyConsumption(preAppId);
        Double modeledEnergySavings = getModeledEnergySavings(preAppId);
        if (modeledTotalEnergyConsumption != 0) {
            modeledEnergySavingsPercentage = modeledEnergySavings / modeledTotalEnergyConsumption;
        }

        if (modeledEnergySavingsPercentage < 14.5) {
            totalRebateValue = 0;
        } else if (modeledEnergySavingsPercentage >= 14.5 && modeledEnergySavingsPercentage < 19.5) {
            totalRebateValue = 1500;
        } else if (modeledEnergySavingsPercentage >= 19.5 && modeledEnergySavingsPercentage < 24.5) {
            totalRebateValue = 2000;
        } else if (modeledEnergySavingsPercentage >= 24.5 && modeledEnergySavingsPercentage < 29.5) {
            totalRebateValue = 2500;
        } else if (modeledEnergySavingsPercentage >= 29.5 && modeledEnergySavingsPercentage < 34.5) {
            totalRebateValue = 3000;
        } else if (modeledEnergySavingsPercentage >= 34.5 && modeledEnergySavingsPercentage < 39.5) {
            totalRebateValue = 3500;
        } else if (modeledEnergySavingsPercentage >= 39.5) {
            totalRebateValue = 4000;
        }

        return totalRebateValue;
    }

    /*
     * Delete all objects related to a sub-application
     * @param preApplicationId
     * @return void
     */
    public void deleteOldHPXMLData (Sub_Application__c preApp) {

        BIGPortalHPXMLDeleteManager deleteManagerClass = new BIGPortalHPXMLDeleteManager();

        deleteManagerClass.deleteHPXmLObjects(preApp.Id);

        uncheckHasHPXMLCheckbox(preApp);
    }

    /*
     * Get XMLGeneratedBy text
     * @param preApplication Id
     * @return XMLGeneratedBy text from XMLTransactionHeaderInformation
     */
    public String getSoftwareInfo(Id preAppId) {
        String text = '';
        List<HP_Software_Info__c> softwares = [
            SELECT Id, Software_Program_Used__c, Software_Program_Version__c, Sub_Application__c
            FROM HP_Software_Info__c
            WHERE Sub_Application__c = :preAppId
            ];

        if (softwares.size() == 1) {
            HP_Software_Info__c software = softwares.get(0);
            if (software.Software_Program_Used__c != null) {
                 text = software.Software_Program_Used__c;
            }
            if (software.Software_Program_Version__c != null) {
                text += ' ' + software.Software_Program_Version__c;
            }
        }
        return text;
    }

    /**
     * Save Post-Application
     * @return void
     */
    public HPXMLResponseWrapper savePostApplication(Application__c app, Sub_Application__c postApplication,
            List<Attachment> attachments, String action, Attachment hupxmlFile) {
        Integer step = 4;

        HPXMLResponseWrapper response = new HPXMLResponseWrapper();

        if (postApplication.Id != null && action == POST_ACTION_NEXT && hupxmlFile != null) {
            //determine software type
            EnergyProXMLParser ep = new EnergyProXMLParser(app, postApplication, true, hupxmlFile);
            String software = ep.getSoftwareName();

            if (software == 'EnergyPro') {
                try {
                    //parse XML
                    ep.parseEnergyProXML();
                    step = 5;
                    response = deserializeJsonResponse('{"success":true, "errorMessage":"", "exceptionMessage":""}');

                } catch (EnergyProXMLParser.EnergyProXMLParserException e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
                } catch (EnergyProXML.TaxInfoException e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
                } catch (EnergyProXML.EnergyProXMLException e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
                } catch (EnergyProXML.TotalEnergySavingsPercentException e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + e.getMessage() +
                            '", "exceptionMessage":""}');
                } catch (Exception e) {
                    response = deserializeJsonResponse('{"success":false, "errorMessage":"' + XML_PROCESSING_ERROR +
                            '", "exceptionMessage":""}');
                    system.debug('###Exception while processing EnergyPro file:' + e.getMessage());
                }
            } else {
                // Process HUPXML
                response = processHupXml(hupxmlFile, app,  postApplication, true);

                if (response.getSuccess() != null) {
                    if (response.getSuccess()) {
                        postApplication.Has_HPXML__c = true;
                        step = 5;
                    } else {

                        if (response.getErrorMessage() != null) {
                            System.debug('### HUPXML Process Error: ' + response.getErrorMessage());

                            // if the error has description, set only the description
                            if (response.getErrorMessage().split('\n').size() == 10) {
                                response.setErrorMessage(response.getErrorMessage().split('\n').get(2));
                            }
                        }

                        if (response.getExceptionMessage() != null) {
                            System.debug('### HUPXML Exception : ' + response.getExceptionMessage());
                        }
                        logHPXMLError(response, postApplication.Id);

                    }
                } else {
                    System.debug('### Error parsing JSON response');
                }
            }
        }

        try {
            app.Application_Step__c = step;
            populateWorkStartFinishDates(postApplication, app);
            processHomeEnergyScore(app, postApplication);
            processConditionedArea(app);
            update app;

            // If post-application is not related to the application
            // then create the relation
            if (postApplication.Application__c == null) {
                postApplication.Application__c = app.Id;
            }

            //get updated app and post-app instances
            app = getApplication(app.Id);
            if (getSubApplication(app, postApplication) != null) {
                // We don't want to lose the values that comes from the page (binded to the postApplication)
                Map<String, Object> fieldsToValue = postApplication.getPopulatedFieldsAsMap();
                postApplication = getSubApplication(app, postApplication);
                //Populating the binded values after getting the latest postApplication
                populateSubAppicationFields(postApplication, fieldsToValue);
            }

            upsert postApplication;

            insertSubApplicationFiles(app.Id, postApplication, attachments);
        } catch (DMLException e) {
            System.debug('### DMLException when trying to update Application' + e.getMessage());
        } catch (Exception e) {
            System.debug('### Exception when trying to update Application ' + e.getMessage());
        }

        return response;
    }

    /**
     * Get the Review__c objects related to a Sub Application
     * @param Sub Application Id
     * @return The list of reviews.
     */
    public List<Review__c> getReviewObjects(Id subApplicationId) {
        return [
            SELECT Id, Comments__c, Additional_Comments__c, Status__c, Sub_Application__c, CreatedDate FROM Review__c
                WHERE Sub_Application__c =: subApplicationId order By CreatedDate desc
        ];
    }

    /**
     * Inserts Sub Application files and their attachments.
     *
     * @param The id of the application, which is parent of the sub application.
     * @param attachments A list of attachments to be inserted.
     */
    public void insertSubApplicationFiles(Id applicationId, Sub_Application__c subApplication,
            List<Attachment> attachments) {
        List<Application_File__c> appFilesToInsert = new List<Application_File__c>();
        Map<String, Attachment> attachmentByDescription = new Map<String, Attachment>();
        Application_File__c applicationFile = null;

        try {
            for (Attachment a : attachments) {
                if (a.Body != null) {
                    // If there is no application file created, then create a new one.
                    applicationFile = new Application_File__c(
                            Application__c = applicationId,
                            Sub_Application__c = subApplication.Id,
                            Description__c = a.Description,
                            File_Name__c = a.Name,
                            Latest_Version__c = '1');

                    if (a.Description == PRE_CONTRACT_SOW_FILE) {
                        applicationFile.Application_File_Type__c = PRE_CONTRACT_SOW_FILE;
                    } else if (a.Description == PRE_HOME_PERFORMANCE_XML || a.Description == POST_HOME_PERFORMANCE_XML) {
                        applicationFile.Application_File_Type__c = 'Home Performance XML';
                    } else if (a.Description == PRE_HOME_PERFORMANCE_SYS || a.Description == POST_HOME_PERFORMANCE_SYS) {
                        applicationFile.Application_File_Type__c = PRE_HOME_PERFORMANCE_SYS;
                    } else if (a.Description == PRE_TEST_IN_MEASUREMENTS) {
                        applicationFile.Application_File_Type__c = 'Test-In Measurements';
                    } else if (a.Description == PRE_ADDITIONAL_DOCUMENTS || a.Description == POST_ADDITIONAL_DOCUMENTS) {
                        applicationFile.Application_File_Type__c = 'Supplemental Documents';
                    } else if (a.Description == PRE_PAYMENT_RELEASE_AUTH || a.Description == POST_PAYMENT_RELEASE_AUTH) {
                        applicationFile.Application_File_Type__c = PRE_PAYMENT_RELEASE_AUTH;
                    } else if (a.Description == PRE_HOME_ENERGY_SCORE_REPORT_INPUT_FILE
                            || a.Description == POST_HOME_ENERGY_SCORE_REPORT_INPUT_FILE) {
                        applicationFile.Application_File_Type__c = PRE_HOME_ENERGY_SCORE_REPORT_INPUT_FILE;
                    } else if (a.Description == PRE_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS
                            || a.Description == POST_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS) {
                        applicationFile.Application_File_Type__c = PRE_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS;
                    } else if (a.Description == PRE_GREEN_BUILDING_REGISTRY_OPT_IN
                            || a.Description == POST_GREEN_BUILDING_REGISTRY_OPT_IN) {
                        applicationFile.Application_File_Type__c = PRE_GREEN_BUILDING_REGISTRY_OPT_IN;
                    } else if (a.Description == POST_CLIENT_SIGNED_SOW_FILE) {
                        applicationFile.Application_File_Type__c = POST_CLIENT_SIGNED_SOW_FILE;
                    } else if (a.Description == POST_TEST_OUT_MEASUREMENTS) {
                        applicationFile.Application_File_Type__c = 'Test-Out Measurements';
                    } else if (a.Description == POST_QUALITY_ACKNOWLEDGMENT) {
                        applicationFile.Application_File_Type__c = POST_QUALITY_ACKNOWLEDGMENT;
                    } else if (a.Description == POST_BUILDING_PERMIT) {
                        applicationFile.Application_File_Type__c = POST_BUILDING_PERMIT;
                    } else if (a.Description == POST_DELIVERED_SENSIBLE_EER_SCORESHEET) {
                        applicationFile.Application_File_Type__c = POST_DELIVERED_SENSIBLE_EER_SCORESHEET;
                    }

                    appFilesToInsert.add(applicationFile);
                    attachmentByDescription.put(applicationFile.Description__c, a);
                }
            }
            // Insert application files.
            insert appFilesToInsert;

            // Set parent ids to attachments.
            for (Application_File__c appF : appFilesToInsert) {
                if (attachmentByDescription.get(appF.Description__c) != null) {
                    attachmentByDescription.get(appF.Description__c).ParentId = appF.Id;
                }
                if (appF.Description__c == PRE_CONTRACT_SOW_FILE) {
                    subApplication.Contract_Proposal_SOW__c = appF.Id;
                } else if (appF.Description__c == PRE_HOME_PERFORMANCE_XML
                        || appF.Description__c == POST_HOME_PERFORMANCE_XML) {
                    subApplication.Home_Performance_XML__c = appF.Id;
                } else if (appF.Description__c == PRE_HOME_PERFORMANCE_SYS
                        || appF.Description__c == POST_HOME_PERFORMANCE_SYS) {
                    subApplication.Home_Performance_System_File__c = appF.Id;
                } else if (appF.Description__c == PRE_TEST_IN_MEASUREMENTS) {
                    subApplication.Test_In_Measurements__c = appF.Id;
                } else if (appF.Description__c == PRE_ADDITIONAL_DOCUMENTS
                        || appF.Description__c == POST_ADDITIONAL_DOCUMENTS) {
                    subApplication.Additional_Documents__c = appF.Id;
                } else if (appF.Description__c == PRE_PAYMENT_RELEASE_AUTH
                        || appF.Description__c == POST_PAYMENT_RELEASE_AUTH) {
                    subApplication.Payment_Release_Authorization__c = appF.Id;
                } else if (appF.Description__c == PRE_HOME_ENERGY_SCORE_REPORT_INPUT_FILE
                        || appF.Description__c == POST_HOME_ENERGY_SCORE_REPORT_INPUT_FILE) {
                    subApplication.HES_Report_Input_File__c = appF.Id;
                } else if (appF.Description__c == PRE_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS
                        || appF.Description__c == POST_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS) {
                    subApplication.HES_Additional_Documents__c = appF.Id;
                } else if (appF.Description__c == PRE_GREEN_BUILDING_REGISTRY_OPT_IN
                        || appF.Description__c == POST_GREEN_BUILDING_REGISTRY_OPT_IN) {
                    subApplication.GBR_Opt_In__c = appF.Id;
                } else if (appF.Description__c == POST_DELIVERED_SENSIBLE_EER_SCORESHEET) {
                    Application__c application = new Application__c(Id = applicationId);
                    application.Delivered_Sensible_EER_Scoresheet__c = appF.Id;
                    update application;
                } else if (appF.Description__c == POST_CLIENT_SIGNED_SOW_FILE) {
                    subApplication.Client_Signed_Contract_SOW__c = appF.Id;
                } else if (appF.Description__c == POST_TEST_OUT_MEASUREMENTS) {
                    subApplication.Test_Out_Measurements__c = appF.Id;
                } else if (appF.Description__c == POST_QUALITY_ACKNOWLEDGMENT) {
                    subApplication.Safety_Quality_Acknowledgment__c = appF.Id;
                } else if (appF.Description__c == POST_BUILDING_PERMIT) {
                    subApplication.Building_Permit__c = appF.Id;
                }
            }
            // Update Sub Application.
            update subApplication;
            // Insert attachments.
            insert attachmentByDescription.values();
        } catch (Exception e) {
            System.debug('###Error: Couldn´t insert application files and attachments for sub application. Message: '
                    + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }
    }

    /**
     * Delete the application files and the attachments related to them.
     *
     * @param parentIds The list containing the application files ids to delete.
     * @param subApp The record to be updated.
     */
    public void deleteApplicationFiles(Set<Id> parentIds, Sub_Application__c subApp) {
        List<Application_File__c> toDelete = new List<Application_File__c>();

        try {
            for (Application_File__c f : [
                    SELECT Id, Submitted__c, Description__c FROM Application_File__c WHERE Id IN :parentIds]) {
                if (f.Description__c == PRE_CONTRACT_SOW_FILE) {
                    subApp.Contract_Proposal_SOW__c = null;
                } else if (f.Description__c == PRE_HOME_PERFORMANCE_XML
                        || f.Description__c == POST_HOME_PERFORMANCE_XML) {
                    subApp.Home_Performance_XML__c = null;
                } else if (f.Description__c == PRE_HOME_PERFORMANCE_SYS
                        || f.Description__c == POST_HOME_PERFORMANCE_SYS) {
                    subApp.Home_Performance_System_File__c = null;
                } else if (f.Description__c == PRE_TEST_IN_MEASUREMENTS) {
                    subApp.Test_In_Measurements__c = null;
                } else if (f.Description__c == PRE_ADDITIONAL_DOCUMENTS
                        || f.Description__c == POST_ADDITIONAL_DOCUMENTS) {
                    subApp.Additional_Documents__c = null;
                } else if (f.Description__c == PRE_PAYMENT_RELEASE_AUTH
                        || f.Description__c == POST_PAYMENT_RELEASE_AUTH) {
                    subApp.Payment_Release_Authorization__c = null;
                } else if (f.Description__c == PRE_HOME_ENERGY_SCORE_REPORT_INPUT_FILE
                        || f.Description__c == POST_HOME_ENERGY_SCORE_REPORT_INPUT_FILE) {
                    subApp.HES_Report_Input_File__c = null;
                } else if (f.Description__c == PRE_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS
                        || f.Description__c == POST_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS) {
                    subApp.HES_Additional_Documents__c = null;
                } else if(f.Description__c == PRE_GREEN_BUILDING_REGISTRY_OPT_IN
                        || f.Description__c == POST_GREEN_BUILDING_REGISTRY_OPT_IN) {
                    subApp.GBR_Opt_In__c = null;
                } else if (f.Description__c == POST_CLIENT_SIGNED_SOW_FILE) {
                    subApp.Client_Signed_Contract_SOW__c = null;
                } else if (f.Description__c == POST_TEST_OUT_MEASUREMENTS) {
                    subApp.Test_Out_Measurements__c = null;
                } else if (f.Description__c == POST_QUALITY_ACKNOWLEDGMENT) {
                    subApp.Safety_Quality_Acknowledgment__c = null;
                } else if (f.Description__c == POST_BUILDING_PERMIT) {
                    subApp.Building_Permit__c = null;
                }

                // Check if the attachment has been already submitted. If so, we want keep it for history records.
                if (!f.Submitted__c) {
                    toDelete.add(f);
                }
            }

            if (!toDelete.isEmpty()) {
                // Delete Application files
                delete toDelete;
            }

            // Update Application File Ids on Sub-Application
            update subApp;
        } catch (Exception e) {
            System.debug('###Error: Couldn´t delete application files. Message: ' + e.getMessage());
        }
    }

    /*
     * Uncheck Has HPXML checkbox from SubApplication
     * @param SubApplication object
     * @return void
     */
    public void uncheckHasHPXMLCheckbox(Sub_Application__c subApp) {
        subApp.Has_HPXML__c = false;
        try {
            update subApp;
        } catch (Exception e) {
            System.debug('Exception while trying to update Has_HPXML__c field in Sub Application' + e.getMessage());
        }
    }

    /**
     * It checks the submitted field on the Application File object once the user submits or resubmits the application.
     *
     * @param subAppId The Sub Application to which the files are related to.
     */
     public void checkSubmittedApplicationFiles(Id subAppId) {
        List<Application_File__c> appFilesToUpdate = new List<Application_File__c>();

        for (Application_File__c appFile : [SELECT Id FROM Application_File__c
                                            WHERE Sub_Application__c =: subAppId AND Submitted__c = false]) {
            appFile.Submitted__c = true;
            appFilesToUpdate.add(appFile);
        }

        if (!appFilesToUpdate.isEmpty()) {
            try {
                update appFilesToUpdate;
            } catch (Exception e) {
                System.debug('Exception while trying to update Submitted field on Application File ' + e.getMessage());
            }
        }
     }

    /**
    * Retrieves application files with attachments by application file id
    *
    * @param appFileIds a set of application file ids
    * @return a map of application files with attachments by application file id
    */
    public Map<Id, Application_File__c> getApplicationFilesMap(Set<Id> appFileIds) {
        Map<Id, Application_File__c> results = new Map<Id, Application_File__c>();
        if (!appFileIds.isEmpty()) {
            try {
                results = new Map<Id, Application_File__c>([
                    SELECT Id, S3_Uploaded__c, File_Name__c,
                        (SELECT Id, Name, ParentId
                        FROM Attachments
                        WHERE ParentId IN :appFileIds order by CreatedDate desc limit 1)
                    FROM Application_File__c
                    WHERE Id IN : appFileIds AND File_Name__c != null
                ]);

               // for ids not in results key set, put key/value with new application files so a value exists for
               // the page
               appFileIds.removeAll(results.keySet());
               for (Id appFileId : appFileIds) {
                   results.put(appFileId, new Application_File__c());
               }

            } catch (QueryException e) {
                System.debug('###BIGPortalAdvanceHUApplicationUtils.getApplicationFilesMap():' +
                        e.getStackTraceString());
            }
        }

        return results;
    }

    /*
     * Retrieves a list of application notes for a SubApplication
     */
    public List<Application_Note__c> listApplicationNotes(Id applicationId, Id subApplicationId) {
        return [
            SELECT Note__c, CreatedDate, Note_Created_By__c
            FROM Application_Note__c
            WHERE Application__c = :applicationId
                AND Sub_Application__c = :subApplicationId
                AND Public__c = true
                AND Temporary__c = false
            ORDER BY CreatedDate DESC
            ];
    }

    public void processTemporaryNote(Id applicationId, Id subAppId, String note) {
        List<Application_Note__c> tempNotes = getTemporaryNotes(applicationId);

        if (String.isNotBlank(note)) {
            Application_Note__c appNote = !tempNotes.isEmpty()
                    ? tempNotes.get(0)
                    : new Application_Note__c(Public__c = true, Application__c = applicationId,
                          Temporary__c = true, Sub_Application__c = subAppId);

             appNote.Note__c = note;
             upsert appNote;
        } else if (!tempNotes.isEmpty()) {
            delete tempNotes.get(0);
        }
    }

    public void processFinalNote(Id applicationId) {
        List<Application_Note__c> tempNotes = getTemporaryNotes(applicationId);

        if (!tempNotes.isEmpty()) {
            Application_Note__c note = tempNotes.get(0);
            note.Temporary__c = false;
            update note;
        }
    }

    public List<Application_Note__c> getTemporaryNotes(Id applicationId) {
        return [
            SELECT Id, Note__c FROM Application_Note__c WHERE Application__c = :applicationId AND Temporary__c = true
            ];
    }

    /**
     * Get BIGPortalUser instance.
     *
     * @return BIGPortalUser instance
     */
    public BIGPortalUser getUserUtils() {
        return this.userUtility;
    }

    /**
     * Copies Payment Release Authorization from Pre-App to Post-App
     */
    public void copyPaymentReleaseAuthorization(Application__c application, Sub_Application__c preApplication,
            Sub_Application__c postApplication) {
        List<Application_File__c> appFiles = [
            SELECT Id FROM Application_File__c WHERE Id =: preApplication.Payment_Release_Authorization__c
            ];
        if (appFiles.size() > 0) {
            // Get pre-app payment release attachments
            List<Attachment> paymentReleaseAttachments = [
                SELECT Id, Name, Description, Body FROM Attachment WHERE ParentId =: appFiles.get(0).Id
                ];
            if (paymentReleaseAttachments.size() > 0) {
                try {
                    // Check if post app is created, otherwise create it
                    if (postApplication.Id == null) {
                        postApplication.Application__c = application.Id;
                        insert postApplication;

                        // Create Post-App Attachment
                        Attachment a = new Attachment(Name = paymentReleaseAttachments.get(0).Name,
                                                      Description = POST_PAYMENT_RELEASE_AUTH,
                                                      Body = paymentReleaseAttachments.get(0).Body);
                        // Create Post-App Application File
                        Application_File__c newAppFile = new Application_File__c(Application__c = application.Id,
                                Sub_Application__c = postApplication.Id, Description__c = a.Description,
                                File_Name__c = a.Name, Latest_Version__c = '1');
                        insert newAppFile;
                        // Set Attachment to Application File
                        a.ParentId = newAppFile.Id;
                        insert a;
                        // Set Application File to Payment Release Authorization Field of Post-App
                        postApplication.Payment_Release_Authorization__c = newAppFile.Id;
                        update postApplication;
                    }
                } catch (Exception e) {
                    System.debug('An exception has occurred while trying to copy attachments');
                }
            }
        }
    }

    /**
     * Compares the subApp.Total_Incentive__c with the proposed/completed cost.
     * The subApp.Total_Incentive is calculated by the HPXML or EnergyPro class
     * @param subApp. The object that contains the needed data to perform the comparisons
     * @return result. True if the subApp.Total_Incentive__c not exceed the proposed/completed cost
     */
    public static Boolean isValidEstimatedIncentive(Sub_Application__c subApp) {
        Boolean result = false;
        if (subApp.RecordTypeId == SUBAPP_PRE_RECORD_TYPE_ID || subApp.RecordTypeId == EP_SUBAPP_PRE_RECORD_TYPE_ID) {
                result = (subApp.Proposed_Package_Cost__c >= subApp.Total_Incentive__c);
        } else if (subApp.RecordTypeId == SUBAPP_POST_RECORD_TYPE_ID
                || subApp.RecordTypeId == EP_SUBAPP_POST_RECORD_TYPE_ID) {
            result = (subApp.Completed_Package_Cost__c >= subApp.Total_Incentive__c);
        }
        return result;
    }

    /**
     * Checks if the app which is being processed has an account that requires tax info
     * @param subApp. Contains the Rebate_Assignment__c that is needed to perform comparisons
     * @param app. Contains the account needed to perform comparisons
     * @return. True if the account of the app needs to be updated
     */
    public static Boolean isContractorTaxInfoRequired(Sub_Application__c subApp, Application__c app) {
        Boolean result = false;

        if (app != null && subApp != null) {
            if (String.isNotEmpty(app.Contractor__c) && String.isNotEmpty(subApp.Rebate_Assignment__c)) {
                try {
                    Account acc = [SELECT Tax_ID_Number__c, Tax_Status__c FROM Account WHERE Id =: app.Contractor__c];
                    if (subApp.Rebate_Assignment__c == CONTRACTOR_PAYEE &&
                            (String.isEmpty(acc.Tax_ID_Number__c) || String.isEmpty(acc.Tax_Status__c))) {
                        result = true;
                    }
                } catch (Exception e) {
                    system.debug('There is an error with this Account:' + e.getStackTraceString());
                }
            }
        }
        return result;
    }

    /**
     * Looks for a sub-application object into the related list of an app.
     *
     * @param app The object when we want to look for sub-applications.
     * @param subApp The sub-application that we want to look for into the app.
     * @return The sub-application found or null if it's not there.
     */
    public Sub_Application__c getSubApplication(Application__c app, Sub_Application__c subApp) {
        Sub_Application__c result;
        for (Sub_Application__c sa : app.Sub_Applications__r) {
            if (sa.Id == subApp.Id) {
                result = sa;
                break;
            }
        }
        return result;
    }

    /**
     * Looks for a sub-application object into the related list of an app.
     *
     * @param application to check the Application_Submission_Date__c and get Dwelling_Unit__c related to it
     * @param subApplication to check the Initial_Submission_Date__c
     * @return Structure option that we have to use
     */
    public static Integer getStructureDependingOnDates(Application__c application, Sub_Application__c subApplication,
            Boolean isPostApplication) {
        Integer structure;
        String gasProvider;
        DateTime preStructureChangeDatetime;
        DateTime postStructureChangeDatetime;

        if (application.Application_Submission_Date__c == null) {
            try {
                // Get Account Utility Gas Provider information
                Utility_Account__c utilityAccount = [
                    SELECT Id, Gas_Provider__c
                    FROM Utility_Account__c
                    WHERE Dwelling_Unit__c =: application.Dwelling_Unit__c
                    ];
                gasProvider = utilityAccount.Gas_Provider__c;
            } catch (QueryException e) {
                System.debug('Error: Couldn\'t get Utility Account. Message: ' + e.getMessage());
            }
        } else {
            gasProvider = application.Gas_Provider__c;
        }

        // If Gas Provider is or is not Southern California Gas Company, assign related dates
        if (gasProvider != BIGPortalManageApplicationUtils.SOUTHERN_CA_GAS_PROVIDER) {
            preStructureChangeDatetime = settings.AHU_Pre_Structure_Change_DateTime__c;
            postStructureChangeDatetime = settings.AHU_Post_Structure_Change_DateTime__c;
        } else {
            preStructureChangeDatetime = settings.AHU_Pre_Structure_Change_DateTime_SoCal__c;
            postStructureChangeDatetime = settings.AHU_Post_Structure_Change_DateTime_SoCal__c;
        }

        /*
         * if  Pre and Post were submitted before preDate assign structure 1
         * if  Pre and Post were submitted after preDate assign structure 2
         * or If Pre was submitted before preDate and Post was submitted after postDate assign 2
         */
        if ((String.isNotBlank(application.Granted_Exceptions__c)
                && application.Granted_Exceptions__c.contains(OVERRIDE_REBATE_TIER_SECOND_STRUCTURE))) {
            // Exception to pre/post-install deadlines granted
            structure = 1;
        } else if (application.Application_Submission_Date__c < preStructureChangeDatetime
                || (application.Application_Submission_Date__c == null
                && DateTime.now() < preStructureChangeDatetime)) {
            // Pre-install initially submitted before pre-install structure change deadline
            structure = 1;
            if (isPostApplication
                    && ((subApplication.Initial_Submission_Date__c > postStructureChangeDatetime)
                    || (subApplication.Initial_Submission_Date__c == null
                    && DateTime.now() > postStructureChangeDatetime))) {
                // Post-install initially submitted after post-install structure change deadline (cut-off point)
                structure = 2;
            }
        } else {
            // Pre-install initially submitted after pre-install structure change deadline
            structure = 2;
        }

        return structure;
    }

    /**
     * Get the minimum percentage saving for a structure given
     *
     * @param structure determines what kind of records will retrieve the query.
     * @return the value from the record that contains the minimum lower limit
     */
    public static Decimal getMinimumLowerLimit(Integer structure) {
        Decimal minLowerLimit = null;
        try {
            minLowerLimit = (Decimal)[
                SELECT MIN(Lower_Limit__c)minLowerLimit FROM Rebate_Tiers__c WHERE Structure__c =: structure
                ].get(0).get('minLowerLimit');

        } catch (QueryException e) {
            System.debug('BIGPortalAdvanceHUApplicationUtils.getMinimumPercentageSaving():' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('BIGPortalAdvanceHUApplicationUtils.getMinimumPercentageSaving():' + e.getStackTraceString());
        }
        return minLowerLimit;
    }

    /**
     * Determines if the total energy savings percent (from the Sub_Application__c) is valid
     *
     * @totalEnergySavingsPercent the value to be compared against the minimum lower limit
     * @minLowerLimit the lowest value for Rebate_Tiers__c.Lower_Limit__c (custom setting) for a given structure
     * @return true for a energy savings percent greater or equeal than minimum lower limit
     */
    public static Boolean isTotalEnergySavingsPercentValid(Decimal totalEnergySavingsPercent, Decimal minLowerLimit) {
        return totalEnergySavingsPercent >= minLowerLimit;
    }

    /**
     * Populate the work start/finish date with values from sub application record.
     *
     * @param subApp The object(pre/post) that supplies the data to be populated on the application.
     * @param app The object to be updated.
     */
    public void populateWorkStartFinishDates(Sub_Application__c subApp, Application__c app) {
        app.Work_Start_Date__c = subApp.Work_Start_Date__c;
        app.Work_Finish_Date__c = subApp.Work_Finish_Date__c;
    }

    /**
     * Populate sub application fields that are shared by both record types: pre/post.
     *
     * @param subApp The object with the fields to be populated.
     * @param fieldsToValue The map that supplies the data to be stored in the subApp
     */
    private void populateSubAppicationFields(Sub_Application__c subApp, Map<String, Object> fieldsToValue) {
        subApp.BPI_Analyst__c = (Id) fieldsToValue.get('BPI_Analyst__c');
        subApp.Rebate_Assignment__c = (String) fieldsToValue.get('Rebate_Assignment__c');
        subApp.Work_Start_Date__c = (Date) fieldsToValue.get('Work_Start_Date__c');
        subApp.Work_Finish_Date__c = (Date) fieldsToValue.get('Work_Finish_Date__c');
        subApp.Has_HPHI__c = (String) fieldsToValue.get('Has_HPHI__c');
        subApp.HPHI_Practitioner__c = (Id) fieldsToValue.get('HPHI_Practitioner__c');

        if (subApp.RecordTypeId == SUBAPP_PRE_RECORD_TYPE_ID || subApp.RecordTypeId == EP_SUBAPP_PRE_RECORD_TYPE_ID) {
            subApp.Proposed_Package_Cost__c = (Decimal) fieldsToValue.get('Proposed_Package_Cost__c');
            subApp.Test_In_Date__c = (Date) fieldsToValue.get('Test_In_Date__c');
        } else if (subApp.RecordTypeId == SUBAPP_POST_RECORD_TYPE_ID
                || subApp.RecordTypeId == EP_SUBAPP_POST_RECORD_TYPE_ID) {
            subApp.Completed_Package_Cost__c = (Decimal) fieldsToValue.get('Completed_Package_Cost__c');
            subApp.Test_Out_Date__c = (Date) fieldsToValue.get('Test_Out_Date__c');
        }
    }

    /**
     * Determines if the portal user selected 'Yes' on installation HES on the portal.
     *
     * @param app Application record.
     * @param subApp Sub application record.
     * @return True if the Home Energy Score fields need to be reset.
     */
    private Boolean shouldHomeEnergyScoreBeProcessed(Application__c app, Sub_Application__c subApp) {
        return (((subApp.RecordType.Name == SUBAPP_PRE_RECORD_TYPE_NAME
                       || subApp.RecordType.Name == EP_SUBAPP_PRE_RECORD_TYPE_NAME
                       || app.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS)
                       && app.Has_Pre_Install_HES__c != YES)
               || ((subApp.RecordType.Name == SUBAPP_POST_RECORD_TYPE_NAME
                       || subApp.RecordType.Name == EP_SUBAPP_POST_RECORD_TYPE_NAME
                       || app.Status__c == ApplicationUtils.POST_INSTALL_CREATED_STATUS)
                       && app.Has_Post_Install_HES__c != YES));
    }

    /**
     * Process all related to Home Energy Score when user select 'Yes' on installation HES on portal.
     *
     * @app Application record
     * @subApp subApp Sub application record.
     */
    private void processHomeEnergyScore(Application__c app, Sub_Application__c subApp) {
        if (shouldHomeEnergyScoreBeProcessed(app, subApp)) {
            Set<String> objFields;
            if (subApp.RecordType.Name == SUBAPP_PRE_RECORD_TYPE_NAME
                    || subApp.RecordType.Name == EP_SUBAPP_PRE_RECORD_TYPE_NAME
                    || app.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS) {
                objFields = new Set<String> {
                        'Pre_HES_Assessor__c',
                        'Pre_Home_Energy_Score__c',
                        'Pre_HES_Assessment_Date__c',
                        'Pre_HES_Assessor_ID__c'};
            } else {
                objFields = new Set<String> {
                        'Post_HES_Assessor__c',
                        'Post_Home_Energy_Score__c',
                        'Post_HES_Assessment_Date__c',
                        'Post_HES_Assessor_ID__c'};
            }
            BIGUtility.nullifySObjectFields(app, objFields);
            // Don't need to go through deletion process since application files have not been inserted.
            if (subApp.Id != null) {
                // Create new instance of the sub application record so we don't overwrite what it saved previously
                // to database. For instance the hpxml parser updates.
                Sub_Application__c subAppToProcess = new Sub_Application__c(Id=subApp.Id);
                deleteApplicationFiles(
                        new Set<Id> {
                            subApp.GBR_Opt_In__c,
                            subApp.HES_Report_Input_File__c,
                            subApp.HES_Additional_Documents__c},
                        subAppToProcess);

                // Synchronize the sub application in memory with the one with the fields updated.
                objFields = subAppToProcess.getPopulatedFieldsAsMap().keySet();
                objFields.remove('Id');
                BIGUtility.nullifySObjectFields(subApp, objFields);
            }
        }
    }

    /**
     * Checks if the conditioned area has changed and copy the value from the application conditioned area
     * field that takes the value from the building.
     *
     * @param app Application record
     */
    private void processConditionedArea(Application__c app) {
        if (app.Has_Conditioned_Area_Changed__c == NO) {
            app.Post_Conditioned_Area__c = app.Conditioned_Area__c;
        }
    }

}