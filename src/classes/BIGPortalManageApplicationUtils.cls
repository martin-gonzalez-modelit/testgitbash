/**
 * This class handles application for PG&E HUP program.
 *
 * @author Maiquel Cabrera <maiquel.cabrera@modelitsoftware.com>
 * @since 2013-9
 */
public with sharing class BIGPortalManageApplicationUtils {

    // Constants
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final String APPLICATION_RECORD_TYPE_NAME = 'HUP';
    private static final Id APPLICATION_RECORD_TYPE_ID;
    private static final Id CONTACT_CONTRACTOR_RECORD_TYPE_ID;
    private static final String ACCOUNT_OF_THE_BUILDING = 'Building__r.Account_del__c';

    // Public Constants
    public static final String HUP = 'HU';
    public static final String AHU_RECORD_TYPE_NAME = 'AHU';
    public static final String ACCREDITATION_CREDENTIAL_TYPE = 'BPI Accreditation';
    public static final String CERTIFICATION_CREDENTIAL_TYPE = 'BPI Certification';
    public static final String HOME_ENERGY_SCORE_ASSESSOR_CREDENTIAL_TYPE = 'Home Energy Score Assessor';
    public static final String CONTRACTOR_RECORD_TYPE_NAME = 'Contractor';
    public static final String RATER_RECORD_TYPE_NAME = 'Rater';
    public static final String BPI_CERTIFIED_PROFESSIONAL = 'BPI Certified Professional';
    public static final String SUPERVISED_BPI_ANALYST = 'Supervised BPI Analyst';
    public static final String PENDING_VERIFICATION_STATUS = 'Pending Verification';
    public static final String BPI_FILE_ERROR = 'Bpi file error. Extension or size is invalid';
    public static final Integer MAX_FILE_SIZE = 5242880;
    public static final String ADDITIONAL_DOCUMENTS_EXT_ERROR =
            'Additional Documents file extension must be pdf, zip, doc, docx, jpg, gif, png';
    public static final String ADDITIONAL_DOCUMENTS_SIZE_ERROR = 'Additional Documents file size is exceeding 5MB.';
    public static final String SOUTHERN_CA_GAS_PROVIDER = 'Southern California Gas Company';
    public static final String CLIENT_SIGNED_CONTRACT_SOW = 'Client-Signed Contract/SOW';
    public static final String TEST_IN_MEASURE_CAS_FORM = 'Test-In Measure CAS Form';
    public static final String TEST_OUT_MEASURE_CAS_FORM = 'Test-Out Measure CAS Form';
    public static final String REBATE_ASSIGNMENT_FORM = 'Rebate Assignment Form';
    public static final String CAS_TEST_ACKNOWLEDGEMENT_FORM = 'CAS Test Acknowledgement Form';
    public static final String BUILDING_PERMIT = 'Building Permit';
    public static final String ADDITIONAL_DOCUMENTS = 'Additional Documents';
    public static final Decimal MAX_INCENTIVE = 2500;


    // INFO MESSAGES
    public static final String MESSAGE_BUILDING_HAS_CHANGED = 'If the Building information has been edited since ' +
            'the initial submission, then these changes will not be applied to this application.';
    public static final String INVALID_BPI_ANALYST_ERROR =
            'There was an error trying to save the bpi analyst. Please try again.';
    public static final String DUPLICATE_BPI_ANALYST_ERROR = 'A BPI Analyst by this name already exists for your ' +
            'Company. Please enter a unique name (first and last) or email jobs@homeupgrade.org for assistance.';
    public static final String DATA_INTEGRITY_ERROR = 'The record you were editing was modified by ' +
            'another user during your edit session.';
    public static final String PROGRAM_ENROLLMENT_SUSPENDED_ERROR = 'Enrollment in this program is currently suspended.'
            + ' The action attempted is prohibited while the suspension is in effect.';

    private static Map<String, String> applicationFileDescriptionToFileType = new Map<String, String> {
            CLIENT_SIGNED_CONTRACT_SOW => 'Client-Signed Contract/SOW',
            REBATE_ASSIGNMENT_FORM => 'Payment Release Authorization',
            TEST_IN_MEASURE_CAS_FORM => 'Test-In Measurements',
            TEST_OUT_MEASURE_CAS_FORM => 'Test-Out Measurements',
            CAS_TEST_ACKNOWLEDGEMENT_FORM => 'Safety & Quality Acknowledgment',
            BUILDING_PERMIT => 'Building Permit',
            ADDITIONAL_DOCUMENTS => 'Supplemental Documents'};

    // Private Properties
    private BIGPortalUser userUtility = null;

    public BIGPortalManageApplicationUtils() {
        userUtility = new BIGPortalUser();
    }

    static {
        APPLICATION_RECORD_TYPE_ID = Schema.SObjectType.Application__c.getRecordTypeInfosByName()
                .get(APPLICATION_RECORD_TYPE_NAME).getRecordTypeId();
        CONTACT_CONTRACTOR_RECORD_TYPE_ID = Schema.SObjectType.Contact.getRecordTypeInfosByName()
                .get(CONTRACTOR_RECORD_TYPE_NAME).getRecordTypeId();
    }

    /**
     * Get BIGPortalUser instance.
     *
     * @return BIGPortalUser instance.
     */
    public BIGPortalUser getUserUtils() {
        return this.userUtility;
    }

    /**
     * Get eligible or not eligible dwelling units depending on the given parameters
     * @param searchTxt used for searching by dwelling unit name, address or zip code
     * @param filterIds makes sure that you are always working with the same records that you got before
     * @param excludeHU indicates if you want to get eligible or not eligible buildings
     * @param typeOfQuery allows to choose the where clause what you want
     * @return a map which allows to find and compare quickly the result retrieved by the query
     */
    public Map<String, Dwelling_Unit__c> getDwellingUnitsToCreateApps(String whereClause) {
        Map<String, Dwelling_Unit__c> dwellingUnitsMap = null;
        List<Dwelling_Unit__c> dwellingUnitList = null;
        Boolean executeQuery = false;

        String query =
                    'SELECT Id, Avg_Ceiling_Height__c, Conditioned_Area__c, Foundation_Type__c, Heating_System__c, ' +
                        'Air_Conditioning__c, Attic_Type__c, Hot_Water_Fuel__c, Hot_Water_System__c,' +
                        'Number_of_Bedrooms__c, Number_of_Occupants__c, Number_of_Stories__c, Pr_Heat_Contrib__c, ' +
                        'Primary_Fuel__c, Secondary_Fuel__c, Unit_Number__c, Year_Built__c, Street_Address__c, ' +
                        'Dwelling_Unit_Name__c, Program_Ineligibility__c, Building__c, Building__r.Building_Type__c, ' +
                        'Building__r.City__c, Building__r.State__c, Building__r.ZIP_Code__c, Building__r.County__c, ' +
                        'Building__r.Building_Name__c, Building__r.Street_Address__c, Property_Owner__c, ' +
                        'Property_Owner__r.Name, Property_Owner__r.FirstName, Property_Owner__r.LastName, ' +
                        'Property_Owner__r.Phone, Property_Owner__r.Email, Property_Owner__r.MailingStreet, ' +
                        'Property_Owner__r.MailingCity, Property_Owner__r.MailingState, ' +
                        'Property_Owner__r.MailingPostalCode, ' +
                        '(SELECT Id, Account_Holder_First_Name__c, Account_Holder_Last_Name__c, Phone__c, ' +
                        'Electric_Provider__c, Electric_Account_Number__c, Gas_Provider__c, Gas_Account_Number__c ' +
                        'FROM Utility_Accounts__r ORDER BY LastModifiedDate DESC LIMIT 1) ' +
                    'FROM Dwelling_Unit__c ' +
                    'WHERE ';

        try {
            query += whereClause;
            dwellingUnitList = Database.query(query);
            dwellingUnitsMap = new Map<String, Dwelling_Unit__c>();
            dwellingUnitsMap.putAll(dwellingUnitList);

            if (query.contains(ACCOUNT_OF_THE_BUILDING)) {
                // Remove the dwelling units that does not meet the criteria
                for (Id dwellingUnitId : dwellingUnitsMap.keySet()) {
                    if (!isDwellingUnitRequiredDataComplete(dwellingUnitsMap.get(dwellingUnitId))) {
                        dwellingUnitsMap.remove(dwellingUnitId);
                    }
                }
            }
        }
        catch (Exception e) {
            System.debug('### Exception while trying to query for Dwelling Units By Name: ' + e.getStackTraceString());
        }
        return dwellingUnitsMap;
    }

    /**
     * Converts a Set to a String
     * @param target the set that will be converted
     * @return a string based on this format: 'A','B'...
     */
    public static String convertSetToString(Set<String> target) {
        return '\'' + String.join(new List<String>(target), '\',\'') + '\'';
    }

    /**
     * Save Dwelling Unit
     * @return void
     */
    public void saveDwelingUnit (Dwelling_Unit__c dwellingUnit) {
       try {
           upsert dwellingUnit;
       } catch (DMLException e) {
           System.debug('### DMLException has occurred while trying to upsert Dwelling Unit: ' + e.getMessage());
       } catch (Exception e) {
           System.debug('### Exception has occurred while trying to upsert Dwelling Unit: ' + e.getMessage());
       }
    }

    /**
     * List Application File records by Id
     */
    public Application_File__c getApplicationFile(Id applicationFileId) {
        Application_File__c applicationFile = null;
        try {
            List<Application_File__c> applicationFiles = [SELECT Id, Application_File_Type__c, Description__c,
                                                                File_Name__c, Latest_Version__c, Application__c
                                                          FROM Application_File__c WHERE Id =: applicationFileId
                                                          AND Application__r.Contractor__c =:
                                                                userUtility.getAccount().Id];
            if (applicationFiles.size() > 0) {
                applicationFile = applicationFiles.get(0);
            }

        } catch (Exception e) {
            System.debug('### Exception while trying to query for application file: ' + e.getMessage());
        }
        return applicationFile;
    }

    /**
     * Get Application By Id
     */
    public Application__c getApplication(Id applicationId) {
        Application__c app = null;
        if (applicationId != null) {
            try {
                List<Application__c> applications = [
                    SELECT Id, Name, Sub_Total__c, Incentive_Total__c, Total_Incentive_Adjustment__c,
                        Rebate_Assignment_Form__c, Test_In_Measure_CAS_Form__c, Test_Out_Measure_CAS_Form__c,
                        CAS_Test_Acknowledgement_Form__c, Building_Permit__c, Rebate_Assignment__c,
                        Additional_Documents__c, Payee_Full_Name__c, Payee_Phone__c, Payee_Street_Address__c,
                        Payee_City__c, Payee_State__c, Payee_ZIP_Code__c, Customer_First_Name__c,
                        Customer_Last_Name__c, Customer_Address__c, Customer_City__c, Customer_State__c,
                        Customer_Zip_Code__c, Customer_Phone__c, Contractor__r.Name, Contractor__r.BillingStreet,
                        Contractor__r.BillingCity, Contractor__r.BillingState, Contractor__r.BillingPostalCode,
                        Contractor__r.Phone, Utility_Account_Holder_Phone__c, Utility_Account_Holder_First_Name__c,
                        LastModifiedDate, Utility_Account_Holder_Last_Name__c, Dwelling_Unit__c, Dwelling_Unit_Name__c,
                        Dwelling_Unit_Number__c, Dwelling_Unit_Street_Address__c, Building_City__c,
                        Building_State__c, Building_ZIP_Code__c, Completed_Cost__c, Status__c, BPI_Analyst__c,
                        BPI_Analyst__r.Name, Work_Start_Date__c, Work_Finish_Date__c, Test_In_Date__c,
                        Test_Out_Date__c, Application_Submission_Date__c, Granted_Exceptions__c,
                        Client_Signed_Contract_SOW__c, Project_Financing_Source__c, Project_Financing_Detail__c,
                        Project_Financing_Description__c,
                        (SELECT Id, Name, Incentive__c, Measure_Type__c, Measure_Code__c, Measure_Code_Abbreviation__c,
                            Measure_Description__c, Upgrade_Measure__c
                        FROM Measures__r)
                    FROM Application__c WHERE Id =: applicationId AND Contractor__c =: userUtility.getAccount().Id
                    AND RecordTypeId =: APPLICATION_RECORD_TYPE_ID];

                if (applications.size() > 0) {
                    app = applications.get(0);
                }
            } catch (Exception e) {
                System.debug('### Exception while trying to query for application: ' + e.getMessage());
            }
        }
        return app;
    }

    /**
     * Get Dwelling Unit By Id
     */
    public Dwelling_Unit__c getDwellingUnit(Id dwellingUnitId) {
        Dwelling_Unit__c dwellingUnit = null;
        if (dwellingUnitId != null) {
            try {
                List<Dwelling_Unit__c> dwellingUnitsList = [
                    SELECT Id, Building__c, Building__r.Id, Building__r.City__c, Building__r.State__c,
                        Building__r.ZIP_Code__c, Building__r.County__c, Building__r.Building_Type__c,
                        Building__r.Building_Name__c, Building__r.Street_Address__c, Avg_Ceiling_Height__c,
                        Conditioned_Area__c, Foundation_Type__c, Heating_System__c, Attic_Type__c, Air_Conditioning__c,
                        Hot_Water_Fuel__c, Hot_Water_System__c, Number_of_Bedrooms__c, Number_of_Occupants__c,
                        Number_of_Stories__c, Pr_Heat_Contrib__c, Primary_Fuel__c, Secondary_Fuel__c, Unit_Number__c,
                        Year_Built__c, Property_Owner__c, Dwelling_Unit_Name__c, Street_Address__c,
                        Property_Owner__r.Email, Property_Owner__r.FirstName, Property_Owner__r.LastName,
                        Property_Owner__r.Name, Property_Owner__r.MailingStreet, Property_Owner__r.MailingCity,
                        Property_Owner__r.MailingState, Property_Owner__r.MailingPostalCode, Property_Owner__r.Phone,
                        (SELECT Id, Account_Holder_First_Name__c, Account_Holder_Last_Name__c, Phone__c,
                            Electric_Provider__c, Electric_Account_Number__c, Gas_Provider__c, Gas_Account_Number__c
                         FROM Utility_Accounts__r ORDER BY LastModifiedDate DESC LIMIT 1)
                    FROM Dwelling_Unit__c
                    WHERE Id =: dwellingUnitId AND Building__r.Account_del__c =: userUtility.getAccount().Id
                    ];

                if (!dwellingUnitsList.isEmpty()) {
                    dwellingUnit = dwellingUnitsList.get(0);
                }
            } catch (QueryException e) {
                System.debug('### Exception while trying to query for Dwelling Unit: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('### Exception while trying to query for Dwelling Unit: ' + e.getMessage());
            }
        }
        return dwellingUnit;
    }

    /**
     * Verify that the dwelling unit has all required fields and that property owner and utility account are not null
     */
    public Boolean isDwellingUnitRequiredDataComplete(Dwelling_Unit__c dwellingUnit) {
        return BIGPortalBuildingInformationUtils.isDwellingUnitRequiredDataComplete(dwellingUnit);
    }

    /**
     * Application Update/Insert
     */
    public void saveApplication(Application__c application, Dwelling_Unit__c dwellingUnit, List<Measure__c> measures,
            List<Attachment> attachments, String status, String notes, String BPIAnalyst, Credential__c credential) {
        Contact auxContact;
        Boolean submitted = false;

        try {
            application.RecordTypeId = APPLICATION_RECORD_TYPE_ID;
            application.Contractor__c = userUtility.getAccount().Id;

            // If user clicks on submit (the first time) and it fails when changing status to 'submitted'
            if (String.isEmpty(application.Status__c)) {
                application.Status__c = ApplicationUtils.CREATED_STATUS;
            }
            // Populate field that will be used to create the application note.
            application.Notes__c = notes;

            application.Dwelling_Unit__c = dwellingUnit.Id;

            if (BPIAnalyst != null && BPIAnalyst != '') {
                application.BPI_Analyst__c = BPIAnalyst;
                auxContact = userUtility.getBPIAnalystById(BPIAnalyst);
                application.BPI_Analyst_License_No__c = auxContact.BPI_License_Number__c;
                application.BPI_Analyst_First_Name__c = auxContact.Name.split(' ')[0];
                application.BPI_Analyst_Last_Name__c = auxContact.Name.split(' ')[1];
            } else {
                application.BPI_Analyst__c = null;
                application.BPI_Analyst_License_No__c = null;
                application.BPI_Analyst_First_Name__c = null;
                application.BPI_Analyst_Last_Name__c = null;
            }

            Decimal incentivesSum = 0;

            // Assign application to measures
            for (Measure__c measure : measures) {
                // Calculate total incentive
                incentivesSum += measure.Incentive__c;
            }

            Integer minimumIncentive = getMinimumIncentive(dwellingUnit);

            if (incentivesSum < minimumIncentive && status == ApplicationUtils.SUBMITTED_STATUS) {
                throw new ApplicationException('To submit the application, the total incentive must be greater or equal '
                        + 'to ' + minimumIncentive);
            }

            if (status == ApplicationUtils.CREATED_STATUS || status == ApplicationUtils.CORRECTION_REQUIRED_STATUS
                    || status == ApplicationUtils.SUBMITTED_STATUS || status == ApplicationUtils.RESUBMITTED_STATUS) {
                application.Sub_Total__c = incentivesSum;
                application.Total_Incentive_Adjustment__c = calculateIncentiveTotal(incentivesSum,
                        application.Completed_Cost__c, minimumIncentive).get('incentiveAdjustment');
                application.Incentive_Total__c = calculateIncentiveTotal(incentivesSum, application.Completed_Cost__c,
                        minimumIncentive).get('incentiveTotal');
            }

            if (application.Completed_Cost__c < application.Incentive_Total__c
                    && status == ApplicationUtils.SUBMITTED_STATUS) {
                throw new ApplicationException('Completed Installation Cost must be greater or equal to Incentive Total.');
            }

            // Populate application fields that will hold the transaction data
            // even when the objects involved have changed (dwelling unit, building, property owner, utility account)
            if (application.Status__c == ApplicationUtils.CREATED_STATUS) {
                setApplicationDetailInformation(application, dwellingUnit);
            }

            // Check for county restriction
            if(isApplicationCountyRestricted(application.Building_ZIP_Code__c)) {
                throw new ApplicationException('Attention: The job site Zipcode entered appears ' +
                                               'to be in a BayREN administrative area county. In order to submit ' +
                                               'this application, please contact BayREN at ' +
                                               '<a href="https://www.bayren.org" target="_blank">www.bayren.org</a> ' +
                                               'or 866-878-6008');
            } else {
                // Upsert application
                upsert application;

                if (application.Status__c != ApplicationUtils.CORRECTION_REQUIRED_STATUS) {
                    // delete measures before inserting
                    deleteMeasures(application.Id);

                    for (Measure__c measure : measures) {
                        // Set application to measures
                        measure.Application__c = application.Id;
                    }
                    // Insert Measures
                    insert measures;
                }

                application.Status__c = status;

                if (status == ApplicationUtils.SUBMITTED_STATUS) {
                    application.Application_Submission_Date__c = Datetime.now();
                    application.Last_Application_Submission_Date__c = Datetime.now();
                } else if (status == ApplicationUtils.RESUBMITTED_STATUS) {
                    application.Last_Application_Submission_Date__c = Datetime.now();
                    application.Desktop_Review_Status__c = ApplicationUtils.CORRECTION_PENDING_REVIEW;
                }

                update application;
                submitted = (status == ApplicationUtils.SUBMITTED_STATUS || status == ApplicationUtils.RESUBMITTED_STATUS);
            }
        } catch (Exception e) {
            System.debug('### Exception while saving application: ' + e.getMessage());
            throw e;
        } finally {
            if (application.Id != null && (!attachments.isEmpty() || submitted)) {
                createAttachments(application.Id, attachments, credential, submitted);
            }
        }
    }

    /**
     * Get the minimum incentive amount required to submit a HU application
     *
     * @param dwellingUnit Determines the minimum incentive based on the building's year built and utility account's gas
     *        provider
     * @return the minimum required incentive
     */
    public static Integer getMinimumIncentive(Dwelling_Unit__c dwellingUnit) {
        Integer minimumIncentive = 1500;

        if (dwellingUnit != null) {
            Utility_Account__c utilityAccount = dwellingUnit.Utility_Accounts__r;
            minimumIncentive = utilityAccount.Gas_Provider__c == SOUTHERN_CA_GAS_PROVIDER
                    ? 650
                    : (Integer.valueOf(dwellingUnit.Year_Built__c) <= 1992 ? 1000 : 1500);
        }

        return minimumIncentive;
    }

    /**
     * Get the maximum required incentive
     *
     * @param application The application object
     * @param minimumIncentive The minimum incentive required to submit
     * @return the maximum incentive amount that is available
     */
    public static Decimal getMaximumIncentive(Application__c application, Integer minimumIncentive) {
        Decimal maximumIncentive;
        Decimal totalCost;

        totalCost = (application != null && application.Completed_Cost__c != null ? application.Completed_Cost__c : 0);

        // Determine maximum incentive based on total cost.
        // Maximum incentive has to be less or equal than 50% of the installation cost.
        if (totalCost/2 > MAX_INCENTIVE) {
            maximumIncentive = MAX_INCENTIVE;
        } else if (totalCost/2 <= MAX_INCENTIVE && totalCost/2 >= minimumIncentive) {
            maximumIncentive = totalCost/2;
        } else {
            maximumIncentive = totalCost != 0 ? minimumIncentive : 0;
        }
        // Set two decimal places
        return maximumIncentive.setScale(2);
    }

    /**
     * Create application detail information
     */
    public void setApplicationDetailInformation(Application__c application, Dwelling_Unit__c dwellingUnit) {
        BIGPortalBuildingInformationUtils buildingInfo = new BIGPortalBuildingInformationUtils();
        // Get Property Owner
        Contact propertyOwner = buildingInfo.getPropertyOwner(dwellingUnit.Property_Owner__c);

        // Get Utility Account
        List<Utility_Account__c> utilityAccList = buildingInfo.getUtilityAccounts(dwellingUnit.Id);
        Utility_Account__c utilityAccount = !utilityAccList.isEmpty() ? utilityAccList.get(0) : null;
        // Set Building Information
        application.Building_Name__c = dwellingUnit.Building__r.Building_Name__c;
        application.Building_Street_Address__c = dwellingUnit.Building__r.Street_Address__c;
        application.Building_Type__c = dwellingUnit.Building__r.Building_Type__c;
        application.Building_City__c = dwellingUnit.Building__r.City__c;
        application.Building_State__c = dwellingUnit.Building__r.State__c;
        application.Building_ZIP_Code__c = dwellingUnit.Building__r.ZIP_Code__c;

        // Set Dwelling Unit Information
        application.Dwelling_Unit_Name__c = dwellingUnit.Dwelling_Unit_Name__c;
        application.Dwelling_Unit_Number__c = dwellingUnit.Unit_Number__c;
        application.Dwelling_Unit_Street_Address__c = dwellingUnit.Street_Address__c;
        application.Air_Conditioning__c = dwellingUnit.Air_Conditioning__c;
        application.Avg_Ceiling_Height__c = dwellingUnit.Avg_Ceiling_Height__c;
        application.Conditioned_Area__c = dwellingUnit.Conditioned_Area__c;
        application.Domestic_Hot_Water__c = dwellingUnit.Hot_Water_System__c;
        application.Foundation_Type__c = dwellingUnit.Foundation_Type__c;
        application.Heating_System__c = dwellingUnit.Heating_System__c;
        application.Hot_Water_Fuel__c = dwellingUnit.Hot_Water_Fuel__c;
        application.Number_of_Bedrooms__c = dwellingUnit.Number_of_Bedrooms__c;
        application.Number_of_Occupants__c = dwellingUnit.Number_of_Occupants__c;
        application.Number_of_Stories__c = dwellingUnit.Number_of_Stories__c;
        application.Pr_Heat_Contrib__c = dwellingUnit.Pr_Heat_Contrib__c;
        application.Primary_Heating_Fuel__c = dwellingUnit.Primary_Fuel__c;
        application.Roof_Attic_Type__c = dwellingUnit.Attic_Type__c;
        application.Secondary_Fuel__c = dwellingUnit.Secondary_Fuel__c;
        application.Year_Built__c = dwellingUnit.Year_Built__c;

        // Set Property Owner Information
        if (propertyOwner != null) {
            application.Customer_First_Name__c = propertyOwner.FirstName;
            application.Customer_Last_Name__c = propertyOwner.LastName;
            application.Customer_Email__c = propertyOwner.Email;
            application.Customer_Phone__c = propertyOwner.Phone;
            application.Customer_Address__c = propertyOwner.MailingStreet;
            application.Customer_City__c = propertyOwner.MailingCity;
            application.Customer_State__c = propertyOwner.MailingState;
            application.Customer_Zip_Code__c = propertyOwner.MailingPostalCode;
        }

        // Set Utility Account Information
        if (utilityAccount != null) {
            application.Gas_Account_Number__c = utilityAccount.Gas_Account_Number__c;
            application.Gas_Provider__c = utilityAccount.Gas_Provider__c;
            application.Electric_Account_Number__c = utilityAccount.Electric_Account_Number__c;
            application.Electric_Provider__c = utilityAccount.Electric_Provider__c;
            application.Utility_Account_Holder_First_Name__c = utilityAccount.Account_Holder_First_Name__c;
            application.Utility_Account_Holder_Last_Name__c = utilityAccount.Account_Holder_Last_Name__c;
            application.Utility_Account_Holder_Phone__c = utilityAccount.Phone__c;
        }

    }

    /**
     * Create Application Attachments/Application File
     *
     * @param applicationId the Id of the Application to update
     * @param attachments the list of attachments to insert
     * @param credential the credential parent of the credential file to upsert
     * @param submitted a boolean indicating if the application is (re)submitted
     */
    public void createAttachments(Id applicationId, List<Attachment> attachments, Credential__c credential,
            Boolean submitted) {
        Application__c application = new Application__c(Id = applicationId);
        Map<String, Attachment> fileDescriptionToAttachments = new Map<String, Attachment>();
        List<Application_File__c> applicationFiles = new List<Application_File__c>();
        List<Application_File__c> applicationFilesToProcess = new List<Application_File__c>();
        List<Application_File__c> applicationFilesToInsert = new List<Application_File__c>();
        List<Application_File__c> applicationFilesToDelete = new List<Application_File__c>();
        List<Attachment> attachmentsToInsert = new List<Attachment>();

        // For each attachment create a new applicationFile
        for (Attachment a : attachments) {
            Application_File__c applicationFile = new Application_File__c();
            applicationFile.Application__c = applicationId;
            applicationFile.Description__c = a.Description;
            applicationFile.File_Name__c = a.Name;
            applicationFile.Submitted__c = submitted;
            applicationFile.Application_File_Type__c = applicationFileDescriptionToFileType.get(a.Description);

            if (a.Description == CERTIFICATION_CREDENTIAL_TYPE) {
                a.ParentId = saveCredentialFile(credential, a.Name);
                if (String.isNotEmpty(a.ParentId)) {
                    attachmentsToInsert.add(a);
                }
            } else {
                fileDescriptionToAttachments.put(a.Description, a);
                applicationFilesToInsert.add(applicationFile);
            }
        }

        // Get all Application Files for Portal Users that weren't submitted yet
        try {
            applicationFiles = [
                SELECT Id, Name, Description__c
                FROM Application_File__c
                WHERE Application__c =: applicationId
                    AND Submitted__c = false
                    AND CreatedBy.ProfileId =: UserInfo.getProfileId()
                ];

            for (Application_File__c appFile : applicationFiles) {
                // If Application File has these descriptions add it to a list, it will be one to be replaced
                if (fileDescriptionToAttachments.containsKey(appFile.Description__c)) {
                    applicationFilesToDelete.add(appFile);
                } else if (submitted) {
                    // If Application was submitted/resubmitted change Submitted__c field to true
                    appFile.Submitted__c = true;
                    applicationFilesToProcess.add(appFile);
                }
            }

            // Delete old Application Files
            delete applicationFilesToDelete;
        } catch (QueryException e) {
            System.debug('Couldn\'t get application files from application. Error: ' + e.getMessage());
        } catch (DmlException e) {
            System.debug('Couldn\'t delete application files. Error: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('There was an error processing application files. Error: ' + e.getMessage());
        }

        try {
            // Add all Application Files (new and old ones) to the list to insert/update below
            applicationFilesToProcess.addAll(applicationFilesToInsert);
            // Insert new Application Files and update the old ones to Submitted to true if it is needed
            upsert applicationFilesToProcess;
        } catch (DmlException e) {
            System.debug('Couldn\'t upsert application files. Error: ' + e.getMessage());
        } catch (ListException e) {
            System.debug('Couldn\'t add application files to the list. Error: ' + e.getMessage());
        }

        // For each new Application File inserted before set Application Files Ids on Application fields
        for (Application_File__c appFile : applicationFilesToInsert) {
            // Set all new application files ids on application fields
            if (appFile.Description__c == REBATE_ASSIGNMENT_FORM) {
                application.Rebate_Assignment_Form__c = appFile.Id;
            } else if (appFile.Description__c == CLIENT_SIGNED_CONTRACT_SOW) {
                application.Client_Signed_Contract_SOW__c = appFile.Id;
            } else if (appFile.Description__c == TEST_IN_MEASURE_CAS_FORM) {
                application.Test_In_Measure_CAS_Form__c = appFile.Id;
            } else if (appFile.Description__c == TEST_OUT_MEASURE_CAS_FORM) {
                application.Test_Out_Measure_CAS_Form__c = appFile.Id;
            } else if (appFile.Description__c == CAS_TEST_ACKNOWLEDGEMENT_FORM) {
                application.CAS_Test_Acknowledgement_Form__c = appFile.Id;
            } else if (appFile.Description__c == BUILDING_PERMIT) {
                application.Building_Permit__c = appFile.Id;
            } else if (appFile.Description__c == ADDITIONAL_DOCUMENTS) {
                application.Additional_Documents__c = appFile.Id;
            }

            // Set Attachment ParentId from Application File created
            Attachment attachment = fileDescriptionToAttachments.get(appFile.Description__c);
            attachment.ParentId = appFile.Id;
            if (String.isNotBlank(attachment.ParentId)) {
                attachmentsToInsert.add(attachment);
            }
        }

        try {
            // Insert all attachments created
            insert attachmentsToInsert;

            // Update an application with the new Application Files Ids
            update application;
        } catch (DmlException e) {
            System.debug('Couldn\'t insert/update. Error: ' + e.getMessage());
        }
    }

    /**
     * Retrieves application files with attachments by application file id
     *
     * @param appFileIds records to be retrieved
     * @return application files by id
     */
    public Map<Id, Application_File__c> getAppFilesMap(Set<Id> appFileIds) {
        Map<Id, Application_File__c> appFilesById = new Map<Id, Application_File__c>();
        if (!appFileIds.isEmpty()) {
            try {
                appFilesById = new Map<Id, Application_File__c>([
                    SELECT Id, File_Name__c, S3_Uploaded__c, S3_File_Name__c,
                        (SELECT Id, Name
                        FROM Attachments
                        WHERE ParentId IN :appFileIds order by CreatedDate desc limit 1)
                    FROM Application_File__c
                    WHERE Id IN : appFileIds AND File_Name__c != null]);

                // If the app file doesn't have attachment and S3 is false the user should upload a new attachment
                for (Id appFileId : appFilesById.keySet()) {
                    if (!appFilesById.get(appFileId).S3_Uploaded__c
                            && appFilesById.get(appFileId).Attachments.isEmpty()) {
                        appFilesById.remove(appFileId);
                    }
                }
            } catch (QueryException e) {
                System.debug('###BIGPortalManageApplicationUtils.getAppFilesMap(): ' + e.getStackTraceString());
            }
        }
        return appFilesById;
    }

    /**
     * Check for Application county restriction
     */
    public Boolean isApplicationCountyRestricted(String zipCode) {
        if (String.isNotBlank(zipCode)) {
            List<Zip_Code__mdt> zipCodes = [SELECT County__c FROM Zip_Code__mdt WHERE Zip_Code__c =: zipCode];
            if (!zipCodes.isEmpty()) {
                // Get restrictions list from custom setting
                PGE_Portal_Settings__c settings =  PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
                if (settings != null && String.isNotBlank(settings.HUP_County_Restriction_List__c)) {
                    for (String countyList : settings.HUP_County_Restriction_List__c.split(';')) {
                        if (countyList.trim().toLowerCase() == zipCodes.get(0).County__c.toLowerCase()) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    /**
     * Get User Account
     */
    public Account getAccount() {
        return userUtility.getAccount();
    }

    public Boolean getHasAdvanceHUProgram() {
        return userUtility.hasAdvanceHUProgram();
    }

    /**
     * Determine if user has ACQC Program
     */
    public Boolean getHasACQCProgram() {
        return userUtility.hasACQCProgram();
    }

    public void saveBuildingAndDwellingUnitFieldsInApplication(Application__c pApp, String thisAddress,
            String thisCity, String thisState, String thisZip, String thisSaid) {
        /* When saving/submiting/resubmiting an application and somebody
        makes changes on the Site__c without reselecting the Mobile Assesment we should make sure
        to populate the application with the latest data from Site__c*/
        String siteName = pApp.Unit__r != null ? pApp.Unit__r.Site__r.Name : null;
        pApp.Building_Name__c = siteName;
        pApp.Dwelling_Unit_Name__c = siteName;
        pApp.Building_Street_Address__c = thisAddress;
        pApp.Dwelling_Unit_Street_Address__c = thisAddress;
        pApp.Building_City__c = thisCity;
        pApp.Building_State__c = thisState;
        pApp.Building_ZIP_Code__c = thisZip;
        pApp.Electric_Account_Number__c = thisSaid;
    }

    /**
     * Declare application exception
     */
    private class ApplicationException extends Exception {}

    public void createReview(Application__c application) {
        Review__c review = new Review__c();
        review.Application__c = application.Id;
        review.Status__c = application.Status__c;
        insert review;
    }

    /**
     * Set a review record related to an application.
     *
     * @param application The application related to the review.
     * @param review The review to set.
     * @return The review with its fields set.
     */
    public Review__c setReview(Application__c application, Review__c review) {
        review = new Review__c(Application__c = application.Id, Status__c = application.Status__c);
        return review;
    }

    private Application__c getNameApp(Id pAppId) {
        List<Application__c> listApp = [select Name from Application__c where Id =: pAppId];
        Application__c app = (listApp != null && listApp.size() > 0) ? listApp.get(0) : null ;
        return app;
    }

    public void deleteMeasures(String appId) {
        List<Measure__c> deleteList = [select Id from Measure__c where Application__c =: appId];
        delete deleteList;
    }

    /**
     * Once all the fields were populated returns the Credential File object's Id
     * which is considered the attachment's parent id.
     * @param credential this object is the master on the master relation between Credential__c and Credential_File__c
     * @param fileName the name of the attachment
     * @return the Credential File object's Id
     */
    public String saveCredentialFile(Credential__c credential, String fileName) {
        Credential_File__c credentialFile = new Credential_File__c();
        try {
            credentialFile.Credential__c = credential.Id;
            credentialFile.File_Name__c = fileName;
            credentialFile.File_Type__c = CERTIFICATION_CREDENTIAL_TYPE;
            upsert credentialFile;
        } catch (Exception e) {
            System.debug('An Exception has ocurred while trying to save Credential/CredentialFile:' +
                    e.getStackTraceString());
        }
        return credentialFile.Id;
    }

    /**
     * Validate if the file has a size less than MAX_FILE_SIZE and its extension
     * is one of the extensions stored in a set
     * @param fileName the name of the attachement containing the extension
     * @param fileSize the size of the attachment
     * @return true if the attachment meets the criteria
     */
    public Boolean validateBpiFile(String fileName, Integer fileSize) {
        return (BIGFileUtils.isFileExtensionIncluded(fileName,
                new Set<String>{'pdf', 'doc', 'docx', 'jpg', 'gif', 'png'})
                && !BIGFileUtils.isFileSizeLarger(fileSize, MAX_FILE_SIZE));
    }

    /**
     * Save/Update the Credential__c object in salesforce which takes data from the bpi analyst record and its account
     * @param credential the main object that will be stored in Salesforce
     * @param newBPIAnalyst the object used to populate the credential record
     * @param isBpiCertified indicates if the BPI Analyst is certified. It is bound to page.
     */
    public String saveBpiAnalyst(Credential__c credential, Contact newBPIAnalyst, Boolean isBpiCertified) {
        try {
            // Insert/Update bpi analyst
            if (String.isEmpty(newBPIAnalyst.Id)) {
                newBPIAnalyst.AccountId = getAccount().Id;
                newBPIAnalyst.RecordTypeId = CONTACT_CONTRACTOR_RECORD_TYPE_ID;
                upsert newBPIAnalyst;
            }

            Map<Id, List<Employee_Program_Enrollment__c>> programEnrollmentToEmployees =
                    new Map<Id, List<Employee_Program_Enrollment__c>>();

            for (Employee_Program_Enrollment__c myEpe : newBPIAnalyst.Employee_Program_Enrollments__r) {
                if (myEpe.Program_Enrollment__c != null && (myEpe.Program_Enrollment__r.RecordType.Name == HUP
                        || myEpe.Program_Enrollment__r.RecordType.Name == AHU_RECORD_TYPE_NAME)) {
                    if (!programEnrollmentToEmployees.containsKey(myEpe.Program_Enrollment__c)) {
                        programEnrollmentToEmployees.put(myEpe.Program_Enrollment__c,
                                new List<Employee_Program_Enrollment__c>());
                        programEnrollmentToEmployees.get(myEpe.Program_Enrollment__c).add(myEpe);
                    } else {
                        // If there is more than one Employee Program Enrollment per Record Type.
                        // Records should be edited manually in SF. This is the only way for reproducing it.
                        programEnrollmentToEmployees.get(myEpe.Program_Enrollment__c).add(myEpe);
                    }
                }
            }

            // If the portal user chose a bpi contact from the picklist on the UI.
            Boolean isChosenContactBpiCertified = isContactBpiCertified(newBpiAnalyst);
            List<Employee_Program_Enrollment__c> employeeProgramEnrollments =
                    new List<Employee_Program_Enrollment__c>();

            if (isBpiCertified || isChosenContactBpiCertified || hasAccountBPIAccreditation()) {
                // Insert/Update credential
                if (!isChosenContactBpiCertified && isBpiCertified) {
                    if (credential.Account__c == null) {
                        credential.Account__c = newBPIAnalyst.AccountId;
                    }
                    credential.Contact__c = newBPIAnalyst.Id;
                    credential.Provider_Issued_ID__c = newBPIAnalyst.BPI_License_Number__c;
                    credential.Expiration_Date__c = newBPIAnalyst.BPI_License_Expiration_Date__c;
                    credential.Status__c = PENDING_VERIFICATION_STATUS;
                    credential.Credential_Type__c = CERTIFICATION_CREDENTIAL_TYPE;
                    upsert credential;
                }

                for (Program_Enrollment__c pe : getAccount().Program_Enrollments__r) {
                    if (pe.RecordType.Name == HUP || pe.RecordType.Name == AHU_RECORD_TYPE_NAME) {
                        if (!programEnrollmentToEmployees.containsKey(pe.Id)) {
                            Employee_Program_Enrollment__c epe = new Employee_Program_Enrollment__c();
                            epe.Contact__c = newBpiAnalyst.Id;
                            epe.Enrollment_Stage__c = 'Active';
                            epe.Program_Enrollment__c = pe.Id;
                            employeeProgramEnrollments.add(epe);
                        } else {
                            //If the employee program enrollment record exist. Add it to the list to be updated.
                            for (Employee_Program_Enrollment__c oneEpe : programEnrollmentToEmployees.get(pe.Id)) {
                                oneEpe.Enrollment_Stage__c = 'Active';
                                employeeProgramEnrollments.add(oneEpe);
                            }
                        }
                    }
                }

                for (Employee_Program_Enrollment__c epe : employeeProgramEnrollments) {
                    if (isBpiCertified || isChosenContactBpiCertified) {
                         if (String.isNotEmpty(epe.Role__c)) {
                            if (!epe.Role__c.contains(BPI_CERTIFIED_PROFESSIONAL)) {
                                epe.Role__c = epe.Role__c + ';' + BPI_CERTIFIED_PROFESSIONAL;
                            }
                        } else {
                            epe.Role__c = BPI_CERTIFIED_PROFESSIONAL;
                        }
                    }
                    if (hasAccountBPIAccreditation()) {
                        if (String.isNotEmpty(epe.Role__c)) {
                            if (!epe.Role__c.contains(SUPERVISED_BPI_ANALYST)) {
                                epe.Role__c = epe.Role__c + ';' + SUPERVISED_BPI_ANALYST;
                            }
                        } else {
                            epe.Role__c = SUPERVISED_BPI_ANALYST;
                        }
                    }
                }
            }

            upsert employeeProgramEnrollments;
        } catch (DmlException e) {
            System.debug('BIGPortalManageApplicationUtils.saveBpiAnalyst():' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('BIGPortalManageApplicationUtils.saveBpiAnalyst():' + e.getStackTraceString());
        }

        return newBPIAnalyst.Id;
    }

    /**
     * Remove a credential file record
     * @param credFileId the id of the record to be deleted
     */
    public void deleteCredentialFile(String credFileId) {
        Boolean hasError = false;
        Credential_File__c credFile = null;
        try {
            credFile = [SELECT Id FROM Credential_File__c WHERE Id =: credFileId];
        } catch (Exception e) {
            System.debug('You can not delete the Credential File:' + e.getStackTraceString());
            hasError = true;
        }
        if (!hasError) {
            delete credFile;
        }
    }

    /**
     * Validate the needed fields for creating/updating a BPI Analyst record
     * @param newBPIAnalyst the contact object bound to the page
     * @param isBpiCertified indicates which fields should be validated
     * @return if the needed fields were filled returns true
     */
    public Boolean validateBpiAnalyst(Contact newBPIAnalyst, Boolean isBpiCertified) {
        Boolean result = false;

        if (String.isNotEmpty(newBPIAnalyst.FirstName) && String.isNotEmpty(newBPIAnalyst.LastName)
                && String.isNotEmpty(newBpiAnalyst.Phone) && String.isNotEmpty(newBpiAnalyst.Email)
                && (String.isEmpty(newBPIAnalyst.Phone_Extension__c)
                || newBPIAnalyst.Phone_Extension__c.isNumeric())) {
            if (!isBpiCertified) {
                result = true;
            } else {
                result = (String.isNotEmpty(newBPIAnalyst.BPI_License_Number__c))
                        && (newBPIAnalyst.BPI_License_Expiration_Date__c != null);
            }
        }
        return result;
    }

    /**
     * Return true if there is any BPI Analyst with the same first and last name on BPI Contact list
     *
     * @param A list of BPI Analysts
     * @param Contact to check the similitude
     * @return True if there is one duplicated or False if there isn't
     */
    public Boolean isBpiAnalystDuplicate(List<Contact> contacts, Contact newBPIAnalyst) {
        Boolean isDuplicate = false;

        for (Contact contact : contacts) {
            if (String.isNotBlank(contact.FirstName) && contact.FirstName.equalsIgnoreCase(newBPIAnalyst.FirstName)
                    && contact.LastName.equalsIgnoreCase(newBPIAnalyst.LastName)) {
                isDuplicate = true;
                break;
            }
        }

        return isDuplicate;
    }

    /**
    * Get the incentive total field from the Application object
    * @param appId. The id of the application that we want to get its incentive total field.
    * @return The value in the Incentive Total field.
    */
    public Decimal getIncentiveTotal(String appId) {
        Decimal incentiveTotal = 0;
        try {
            Application__c app = [SELECT Incentive_Total__c FROM Application__c WHERE Id = :appId];
            incentiveTotal = (app.Incentive_Total__c != null) ? app.Incentive_Total__c : 0;
        } catch (Exception e) {
            System.debug('###' + e.getMessage());
        }
        return incentiveTotal;
    }

    public String buildFilterByNameForDwellingUnits(String dwellingSearchText) {
        List<String> filterCriteria = new List<String>();

        for (String searchText : dwellingSearchText.remove(',').normalizeSpace().split(' ')) {
            filterCriteria.add('Property_Owner__r.Name LIKE \'%' + String.escapeSingleQuotes(searchText) + '%\'');
        }

        return ('(' + String.join(filterCriteria, ' AND ') + ')');
    }

    /**
     * Gets rebate type groups for all the measures, which previously applied for the given unit.
     *
     * @param app The Application to find duplicate Measures (per Unit's FDSI ID) for.
     * @param measures A list of the Application's Measures.
     * @param rebateTypesById A Map of rebate types with its Id as key.
     * @return A list of Rebate Type groups.
     */
    public List<String> getEquivalentMeasures(Application__c app, List<Measure__c> measures,
            Map<Id, Rebate_Type__c> rebateTypesById) {
        List<String> duplicateRebateTypeNames = new List<String>();

        try {
            if (!measures.isEmpty() && app.Unit__r.FDSI_ID__c != null) {
                // Map with Group name as key and Display Sequence as values for measures that we apply for.
                Map<String, Decimal> displaySequenceByGroup = new Map<String, Decimal>();
                Map<String, Date> installationDateByGroup = new Map<String, Date>();

                setDisplaySequenceAndInstallationDateMaps(displaySequenceByGroup, installationDateByGroup,
                        measures, rebateTypesById);

                // Retrieve all other Applications with the same Unit FDSI ID and Measure's Rebate Type Group.
                List<Application__c> applicationsWithEquivalentMeasures = [
                    SELECT Id, Name, Application_Submission_Date__c, CreatedDate,
                        (SELECT Id, Installation_Date__c, Rebate_Type__c, Rebate_Type__r.Group__c,
                            Rebate_Type__r.Display_Sequence__c
                         FROM Measures__r
                         WHERE Rebate_Type__c IN (
                            SELECT Id FROM Rebate_Type__c WHERE Group__c IN :displaySequenceByGroup.keySet()))
                    FROM Application__c
                    WHERE Unit__r.FDSI_ID__c = :app.Unit__r.FDSI_ID__c
                        AND RecordTypeId = :Applicationutils.ACQC_RECORD_TYPE
                        AND Status__c NOT IN (
                            :ApplicationUtils.CANCELED_STATUS,
                            :ApplicationUtils.REJECTED_STATUS,
                            :ApplicationUtils.CREATED_STATUS)
                        AND Id != :app.Id
                    ];

                // Check for double dipping measures.
                if (!applicationsWithEquivalentMeasures.isEmpty()) {
                    Set<String> duplicateGroups = new Set<String>();

                    for (List<String> groups : getEquivalentRebateTypeGroupsByApplication(
                            applicationsWithEquivalentMeasures, displaySequenceByGroup,
                            installationDateByGroup).values()) {
                        duplicateGroups.addAll(groups);
                    }

                    // Loop for all measures we apply for to save display sequence as key and the group as values
                    // for those ones that are double dipping.
                    Map<Decimal, String> duplicateRebateTypeNamesByDisplaySequence = new Map<Decimal, String>();

                    for (Measure__c measure : measures) {
                        String rebateTypeGroup = rebateTypesById.get(measure.Rebate_Type__c).Group__c;
                        if (duplicateGroups.contains(rebateTypeGroup) && !duplicateRebateTypeNamesByDisplaySequence
                                    .containsKey(displaySequenceByGroup.get(rebateTypeGroup))) {
                            duplicateRebateTypeNamesByDisplaySequence.put(
                                    displaySequenceByGroup.get(rebateTypeGroup), rebateTypeGroup);
                        }
                    }

                    // Add duplicate Rebate Type Group values by ascending Display Sequence order.
                    List<Decimal> keys = new List<Decimal>(duplicateRebateTypeNamesByDisplaySequence.keySet());
                    keys.sort();

                    for (Decimal key : keys) {
                        duplicateRebateTypeNames.add(duplicateRebateTypeNamesByDisplaySequence.get(key));
                    }
                }
            }
        } catch (Exception e) {
            System.debug('###Error: Couldn\'t get equivalent measures: ' + e.getStackTraceString());
            System.debug('###Stack Trace: ' + e.getStackTraceString());
        }

        return duplicateRebateTypeNames;
    }

    /**
     * Determine if the application has any potential equivalent measures.
     *
     * @param app The Application to find equivalent Measures (per different Unit's FDSI ID) for.
     * @param measures A list of the Application's Measures.
     * @param rebateTypesById A Map of rebate types with its Id as key.
     * @return True if we find any potential equivalent measures, otherwise return false.
     */
    public Boolean getPotentialEquivalentMeasures(Application__c app, List<Measure__c> measures,
            Map<Id, Rebate_Type__c> rebateTypesById) {
        // Get application names with all Rebate Type Groups that apply for double dipping.
        Map<String, List<String>> groupsByApplication = new Map<String, List<String>>();

        try {
            if (!measures.isEmpty() && app.Unit__r.FDSI_ID__c != null) {
                Set<String> addresses = ACQCApplicationSearchController.normalizeData(app.Building_Street_Address__c);
                // Map with Group name as key and Display Sequence as values for measures that we apply for.
                Map<String, Decimal> displaySequenceByGroup = new Map<String, Decimal>();
                Map<String, Date> installationDateByGroup = new Map<String, Date>();
                List<Application__c> applicationsWithPotentialEquivalentMeasures;

                setDisplaySequenceAndInstallationDateMaps(displaySequenceByGroup, installationDateByGroup,
                        measures, rebateTypesById);

                // Retrieve all other Applications with equivalent addresses and Measure's Rebate Type Group.
                String queryStart = ''
                        + 'SELECT Id, Name, '
                            + '(SELECT Id, Installation_Date__c, Rebate_Type__c, Rebate_Type__r.Group__c '
                            + 'FROM Measures__r '
                            + 'WHERE Rebate_Type__c IN '
                                + '(SELECT Id FROM Rebate_Type__c WHERE Group__c IN (\''
                                + String.join(
                                        new List<String>(displaySequenceByGroup.keySet()), '\', \'') + '\'))) '
                        + 'FROM Application__c '
                        + 'WHERE Unit__r.FDSI_ID__c != \'' + app.Unit__r.FDSI_ID__c + '\' '
                            + 'AND RecordTypeId = \'' + Applicationutils.ACQC_RECORD_TYPE  + '\' '
                            + 'AND Status__c != \'' + ApplicationUtils.CANCELED_STATUS + '\' '
                            + 'AND Status__c != \'' + ApplicationUtils.REJECTED_STATUS + '\' '
                            + 'AND Status__c != \'' + ApplicationUtils.CREATED_STATUS + '\' '
                            + 'AND Id != \'' + app.Id + '\' AND (';

                String queryEnd = '';
                // Check for all equivalent addresses on query.
                for (String address : addresses) {
                    queryEnd += ''
                    + 'OR (Building_Street_Address__c = \'' + String.escapeSingleQuotes(address) + '\' '
                    + 'AND Building_City__c LIKE \'%' + app.Building_City__c + '%\' '
                    + 'AND Building_ZIP_Code__c = \'' + app.Building_ZIP_Code__c + '\' '
                    + 'AND Building_State__c = \'' + app.Building_State__c + '\') ';
                }

                queryStart += queryEnd.removeStart('OR') + ')';
                applicationsWithPotentialEquivalentMeasures = Database.query(queryStart);

                groupsByApplication = getEquivalentRebateTypeGroupsByApplication(
                        applicationsWithPotentialEquivalentMeasures, displaySequenceByGroup, installationDateByGroup);
            }

            if (!groupsByApplication.isEmpty()) {
                String note = 'This application was automatically flagged for desktop review '
                        + 'due to potential double dipping; see application(s) and its measure(s):\n';
                List<String> applicationNamesOrdered = new List<String>(groupsByApplication.keySet());
                // Sort Application Names.
                applicationNamesOrdered.sort();

                for (String appName : applicationNamesOrdered) {
                    // Sort measures related to each Application.
                    // App01: Air Flow Correction, Refrigerant System -> App01: Air Flow Correction, Refrigerant System.
                    groupsByApplication.get(appName).sort();
                    note += appName + ': ' + String.join(groupsByApplication.get(appName), ', ') + '.\n';
                }

                ApplicationUtils.createApplicationNote(app.Id, 'Flag for Desktop', false, note);
            }
        } catch (Exception e) {
            System.debug('###Exception while trying to check potential double dipping measures: '
                    + e.getStackTraceString());
            System.debug('###Stack Trace: ' + e.getStackTraceString());
        }

        return !groupsByApplication.isEmpty();
    }

    /**
     * Set maps to use them as help for double dipping methods.
     *
     * @param displaySequenceByGroup A Map of rebate types group with its display sequence.
     * @param installationDateByGroup A Map of rebate types group with its installation date.
     * @param measures A list of the Application's Measures.
     * @param rebateTypesById A Map of rebate types with its Id as key.
     */
    private void setDisplaySequenceAndInstallationDateMaps(Map<String, Decimal> displaySequenceByGroup,
            Map<String, Date> installationDateByGroup, List<Measure__c> measures,
            Map<Id, Rebate_Type__c> rebateTypesById) {
        for (Measure__c measure : measures) {
            if (rebateTypesById.containsKey(measure.Rebate_Type__c)) {
                displaySequenceByGroup.put(rebateTypesById.get(measure.Rebate_Type__c).Group__c,
                        rebateTypesById.get(measure.Rebate_Type__c).Display_Sequence__c);
                installationDateByGroup.put(rebateTypesById.get(measure.Rebate_Type__c).Group__c,
                        measure.Installation_Date__c);
            }
        }
    }

    /**
     * Gets the rebate type groups for every application that has equivalent measures.
     *
     * @param applications A list of application with its measures.
     * @param displaySequenceByGroup A Map of rebate types group with its display sequence.
     * @param installationDateByGroup A Map of rebate types group with its installation date.
     * @return A Map with Application Name as key and Rebate Type groups that apply for double dipping issue as values.
     */
    public Map<String, List<String>> getEquivalentRebateTypeGroupsByApplication(
            List<Application__c> applications, Map<String, Decimal> displaySequenceByGroup,
            Map<String, Date> installationDateByGroup) {
        Map<String, List<String>> groupsByApplication = new Map<String, List<String>>();

        try {
            // Check for double dipping measures.
            if (!applications.isEmpty()) {
                for (Application__c application : applications) {
                    for (Measure__c duplicatedMeasure : application.Measures__r) {
                        Date installationDateFiveYearsAgo = installationDateByGroup.get(
                                duplicatedMeasure.Rebate_Type__r.Group__c).addYears(-5);
                        // If installation date from measure is null, we have to check for
                        // application submission date, and if it is null too, check for created date.
                        Date measureDate = duplicatedMeasure.Installation_Date__c != null
                                ? duplicatedMeasure.Installation_Date__c
                                : (application.Application_Submission_Date__c != null
                                    ? Date.newinstance(
                                            application.Application_Submission_Date__c.year(),
                                            application.Application_Submission_Date__c.month(),
                                            application.Application_Submission_Date__c.day())
                                    : Date.newinstance(
                                            application.CreatedDate.year(),
                                            application.CreatedDate.month(),
                                            application.CreatedDate.day()));

                        if (measureDate > installationDateFiveYearsAgo
                                && String.isNotBlank(duplicatedMeasure.Rebate_Type__c)) {
                            // Save all group names that are related to double dipping measures.
                            for (String groupName : displaySequenceByGroup.keySet()) {
                                if (duplicatedMeasure.Rebate_Type__r.Group__c == groupName) {
                                    if (!groupsByApplication.containsKey(application.Name)) {
                                        groupsByApplication.put(application.Name, new List<String>());
                                    }

                                    groupsByApplication.get(application.Name).add(groupName);
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('###Error: Couldn\'t gets rebate type groups from equivalent measures: '
                    + e.getStackTraceString());
            System.debug('###Stack Trace: ' + e.getStackTraceString());
        }

        return groupsByApplication;
    }

    /**
     * Checks the contact's account logged in to see if has credential accreditation
     * @return true if has bpi accreditation
     */
    public Boolean hasAccountBPIAccreditation() {
        Account acc = getAccount();
        if (acc.Credentials__r != null) {
            for (Credential__c c : acc.Credentials__r) {
                if (c.Credential_Type__c == ACCREDITATION_CREDENTIAL_TYPE) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Retrieves a list of bpi analysts. The list's content depends on
     * if the account logged in is bpi accredited or not.
     * @param contractorId the contact's account logged in
     * @return A list of BPI analysts
     */
    public List<Contact> getAnalysts(Id contractorId) {

        List<Contact> bpiAnalysts = new List<Contact>();
        try {
            if (hasAccountBPIAccreditation()) {
                bpiAnalysts =  [
                    SELECT Id, Name, FirstName, LastName, Email, Phone, Phone_Extension__c, BPI_License_Number__c,
                        BPI_License_Expiration_Date__c, AccountId,
                        (SELECT Contact__c, Enrollment_Stage__c, Program_Enrollment__c, Role__c,
                            Program_Enrollment__r.RecordType.Name
                        FROM Employee_Program_Enrollments__r)
                    FROM Contact
                    WHERE (RecordType.Name =: CONTRACTOR_RECORD_TYPE_NAME OR RecordType.Name =: RATER_RECORD_TYPE_NAME)
                        AND AccountId =: contractorId order by LastName, FirstName
                    ];
            } else {
                bpiAnalysts =  [
                    SELECT Id, Name, FirstName, LastName, Email, Phone, Phone_Extension__c, BPI_License_Number__c,
                        BPI_License_Expiration_Date__c, AccountId,
                        (SELECT Contact__c, Enrollment_Stage__c, Program_Enrollment__c, Role__c,
                            Program_Enrollment__r.RecordType.Name
                        FROM Employee_Program_Enrollments__r)
                    FROM Contact
                    WHERE (RecordType.Name =: CONTRACTOR_RECORD_TYPE_NAME OR RecordType.Name =: RATER_RECORD_TYPE_NAME)
                        AND AccountId =: contractorId
                        AND Id IN
                        (SELECT Contact__c
                        FROM Credential__c
                        WHERE Credential_Type__c =: CERTIFICATION_CREDENTIAL_TYPE)
                    order by LastName, FirstName
                    ];
            }
         } catch (QueryException e) {
             System.debug('BIGPortalManageApplicationUtils.getAnalysts():' + e.getStackTraceString());
         } catch (Exception e) {
             System.debug('BIGPortalManageApplicationUtils.getAnalysts():' + e.getStackTraceString());
         }

        return bpiAnalysts;
    }

    /**
     * Checks if the contact passed by parameter is a BPI certified.
     * @param bpiContact the contact passed to know if is BPI certified
     * @return true if the bpiContact is certified
     */
    public Boolean isContactBpiCertified(Contact bpiContact) {
        Boolean result = false;
        try {
            if (bpiContact != null) {
                result = ([
                    SELECT count()
                    FROM Credential__c
                    WHERE Credential_Type__c =: CERTIFICATION_CREDENTIAL_TYPE AND Contact__c =: bpiContact.Id
                        AND Account__c =: bpiContact.AccountId
                        AND Contact__c IN
                        (SELECT Id
                        FROM Contact
                        WHERE (RecordType.Name =: CONTRACTOR_RECORD_TYPE_NAME
                            OR RecordType.Name =: RATER_RECORD_TYPE_NAME)
                            AND Id =: bpiContact.Id)
                    ] != 0);
            }
        } catch (QueryException e) {
            System.debug('BIGPortalManageApplicationUtils.isContactBpiCertified():' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('BIGPortalManageApplicationUtils.isContactBpiCertified():' + e.getStackTraceString());
        }
        return result;
    }

    /**
     * Return true if the application was last modified by a portal user after the initial sumbission date.
     */
    public Boolean isDataUpdatedAfterInitialSubmissionByPortalUser(Application__c application) {
        try {
            // Query to get the LastModifiedDate and LastModifiedById fields
            List<Dwelling_Unit__c> dwellingUnitsList = [
                SELECT LastModifiedDate, LastModifiedById
                FROM Dwelling_Unit__c
                WHERE Id =: application.Dwelling_Unit__c
                    AND Building__r.Account_del__c =: userUtility.getAccount().Id
                ];
            if (!dwellingUnitsList.isEmpty()) {
                Dwelling_Unit__c auxDw = dwellingUnitsList.get(0);
                if (BIGUtility.isObjectLastModifiedAfterSubmissionDate(auxDw,
                    application.Application_Submission_Date__c) &&
                    BIGUtility.isObjectLastModifiedByUserWithProfile(auxDw, UserInfo.getProfileId())) {
                    return true;
                }
            }
        } catch (QueryException  e) {
            System.debug('### QueryException while trying to query: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('### Exception while trying to query: ' + e.getMessage());
        }
        return false;
    }

    /**
    * Get a date and format it using the locale of the context user
    *
    * @param dateToFormat date to be formatted
    * @return date formatted as String
    */
    public String formatDate(Date dateToFormat) {
        return dateToFormat != null ? dateToFormat.format() : null;
    }

    /**
     * Calculates the incentive total and the maximum incentive
     *
     * @param incentivesSum The summatory of the measures' incentives
     * @param totalCost The total installation cost
     * @param minimumIncentive The minimum incentive required
     * @return map containing the calculated incentive total and maximum incentive
     */
    public static Map<String, Decimal> calculateIncentiveTotal(Decimal incentivesSum, Decimal totalCost,
            Integer minimumIncentive) {
        Decimal incentiveTotal = 0;
        Decimal maximumIncentive = 0;
        Decimal incentiveAdjustment = 0;

        if (incentivesSum >= minimumIncentive) {
            // Determine maximum incentive based on total cost.
            // Maximum incentive has to be less or equal than 50% of the installation cost.
            if (totalCost/2 >= minimumIncentive) {
                maximumIncentive = Math.min(totalCost/2, BIGPortalManageApplicationUtils.MAX_INCENTIVE);
            }

            // Calculate incentive total and adjustment
            incentiveTotal = Math.min(maximumIncentive, incentivesSum);
            incentiveAdjustment = incentiveTotal == 0 ? 0 : incentiveTotal - incentivesSum;
        }

        return new Map<String, Decimal> {
            // Set two decimal places
            'incentiveTotal' => incentiveTotal.setScale(2),
            'maximumIncentive' => maximumIncentive.setScale(2),
            'incentiveAdjustment' => incentiveAdjustment.setScale(2)
        };
    }

    /**
     * Retrieve list Home Energy Score Contacts.
     */
    public List<Contact> getHomeEnergyScoreContacts() {
        List<Contact> contacts;

        try {
            Id accId = getAccount().Id;
            contacts = [
                SELECT Id, FirstName, LastName,
                    (SELECT Provider_Issued_ID__c
                     FROM Credentials__r
                     WHERE Account__c = :accId
                        AND Credential_Type__c = :HOME_ENERGY_SCORE_ASSESSOR_CREDENTIAL_TYPE
                     ORDER BY Expiration_Date__c DESC LIMIT 1)
                FROM Contact
                WHERE AccountId = :accId
                    AND Id IN (
                        SELECT Contact__c
                        FROM Credential__c
                        WHERE Account__c = :accId
                            AND Credential_Type__c = :HOME_ENERGY_SCORE_ASSESSOR_CREDENTIAL_TYPE)
            ];
        } catch (QueryException e) {
            System.debug('Error: Couldn\'t get Contact. Message: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }

        return contacts;
    }

    /**
     * Converts the value of the Unadjusted_Energy_Savings_Percent__c field from the sub application to a string, and
     * returns it containing the amount of decimals given by parameter (without rounding).
     *
     * @param unadjustedEnergySavingsPercent The value of the Unadjusted_Energy_Savings_Percent__c field from the
     *        sub application.
     * @param decimalPlaces The amount of decimal places that should be included, including the decimal point.
     * @return A string representation of the Unadjusted_Energy_Savings_Percent__c containing the amount of decimals
     *         given by parameter (without rounding).
     */
    public String formatUnadjustedEnergySavingsPercent(Decimal unadjustedEnergySavingsPercent, Integer decimalPlaces) {
        if (unadjustedEnergySavingsPercent != null) {
            String s = String.valueOf(unadjustedEnergySavingsPercent);
            return s.substring(0, s.indexOf('.') + decimalPlaces) + '%';

        }
        return '';
    }
}