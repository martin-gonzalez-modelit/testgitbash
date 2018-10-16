/**
 * This controller handles Application creation & modification
 * @author (Original Author) Maiquel Cabrera <maiquel.cabrera@modelitsoftware.com>
 * @author (Collaborator) Camilo Herbert <camilo.herbert@modelitsoftware.com>
 * @since 2013-6
 */

public with sharing class BIGPortalManageApplicationController extends BIGPortalPaginationUtils {

    // Constants
    private static final String ACTION_DETAIL = 'detail';
    private static final String ACTION_NEW = 'new';
    private static final String REBATE_ASSIGNMENT_RATE_PAYEE = 'Account Holder';
    private static final String REBATE_ASSIGNMENT_NOT_RATE_PAYEE = 'Non Account Holder';
    private static final String REBATE_ASSIGNMENT_CONTRACTOR_PAYEE = 'Contractor Payee';
    private static final String MEASURE_TYPE_BASE = 'Base Measure';
    private static final String MEASURE_TYPE_FLEX = 'Flex Measure';
    private static final String MEASURE_TYPE_KICKER = 'Kicker Measure';
    private static final String MEASURE_UPGRADE_DUCT = 'Duct Improvement';
    private static final String MEASURE_UPGRADE_BUILDING_AIR_SEALING = 'Whole Building Air Sealing';
    private static final String MEASURE_UPGRADE_ATTIC_INSULATION = 'Attic Insulation & Plane Air Sealing';
    private static final String MEASURE_UPGRADE_AIR_COND = 'Air Conditioning';
    private static final String MEASURE_UPGRADE_GAS_HEATING = 'Gas Heating (furnaces & wall heater)';
    private static final String MEASURE_UPGRADE_WATER_HEATER = 'Water Heater';
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final String ERROR_MEASURES =
            'A minimum of 1 Base measure, ${0} incentive total, and 3 measures are required.';
    private static final String APP_SAVED_SUCCESS = 'Application saved successfully!';
    private static final String APP_SUBMITTED_SUCCESS =
            'Your Application has been submitted for review. Your Application number is ';
    private static final String APP_RESUBMITTED_SUCCESS =
            'Your Application has been resubmitted for review. Your Application number is ';
    private static final String COMMENTS_FIELD_NAME = 'Issues';
    private static final String ADDITIONAL_COMMENTS_FIELD_NAME = 'Comments';

    // Private Properties
    private BIGPortalManageApplicationUtils applicationUtility;
    private Map<String, Dwelling_Unit__c> dwellingUnitsMap;
    private Map<Id, Measure_Types__mdt> measureTypesById;
    private List<Measure_Types__mdt> measureTypesListOrdered;
    private List<Measure__c> measures;
    private String applicationId;
    private String dwellingUnitId;
    private Credential__c credential;
    private Map<Id, Contact> bpiAnalystsMap = new Map<Id, Contact>();
    // Map with Project_Financing_Source__c as a key and all Project_Financing_Detail__c dependent options of it
    private static Map<String, List<String>> projectFinancing = PicklistUtility.getDependentOptions('Application__c',
            'Project_Financing_Source__c', 'Project_Financing_Detail__c');

    // Public Properties
    public String action { get; set; }
    public Account account { get; set; }
    public Application__c application { get; set; }
    public String dwellingSearchText { get; set; }
    public String dwellingToAssignId { get; set; }
    public Boolean multipleResultsFound { get; set; }
    public Dwelling_Unit__c dwellingUnit { get; set; }
    public Contact propertyOwner { get; set; }
    public Utility_Account__c utilityAccount { get; set; }
    public String measureDuctImprovement { get; set; }
    public String measureAirSealing { get; set; }
    public String measureAtticInsulation { get; set; }
    public String flexMeasureAirConditioning { get; set; }
    public String flexMeasureGasHeating { get; set; }
    public String flexMeasureWaterHeater { get; set; }
    public String[] flexMeasures { get; set; }
    public String[] kickerMeasures { get; set; }
    public Attachment clientSignedContractSOW { get; set; }
    public Attachment rebateAssignmetForm { get; set; }
    public Attachment testInMeasureCASForm { get; set; }
    public Attachment testOutMeasureCASForm { get; set; }
    public Attachment casTestAcknowledgementForm { get; set; }
    public Attachment buildingPermit { get; set; }
    public Attachment additionalDocuments { get; set; }
    //bpi attachment
    public Attachment bpiFileIdCard { get; set; }
    // To hold uploaded attachments on edit
    public Application_File__c uploadedClientSignedContractSOW { get; set; }
    public Application_File__c uploadedRebateAssignmetForm { get; set; }
    public Application_File__c uploadedTestInMeasureCASForm { get; set; }
    public Application_File__c uploadedTestOutMeasureCASForm { get; set; }
    public Application_File__c uploadedCasTestAcknowledgementForm { get; set; }
    public Application_File__c uploadedBuildingPermit { get; set; }
    public Application_File__c uploadedAdditionalDocuments { get; set; }
    public String zipCodeErrors { get; set; }
    public Contact newBpiAnalystContact {get; set;}
    // Checkbox on the BPI Modal. All fields are required if it's true.
    public Boolean isBPICertified { get; set;}
    public BIGPortalManageApplicationController injectedController { get; set; }

    public Boolean hasAccountBPIAccreditation {
        get {
            return applicationUtility.hasAccountBPIAccreditation();
        }
    }

    public Boolean isHuTerminated {
        get {
            return applicationUtility.getUserUtils().isHuTerminated();
        }
    }

    /**
     * Get Project Financing Source picklist values and its corresponding dependant values from the Project Financing
     * Detail picklist.
     *
     * @return Map containing the Label Group as key and its corresponding picklist values.
     */
    public Map<String, List<String>> getProjectFinancingOptions() {
        Map<String, List<String>> financingOptions = new Map<String,List<String>>();
        Schema.DescribeFieldResult fieldResult = Application__c.Project_Financing_Source__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        // Set disabled values that will be used as titles.
        financingOptions.put('General Options', new List<String>());
        financingOptions.put('Secure Options', projectFinancing.get(ApplicationUtils.SECURED_LOAN));
        financingOptions.put('Unsecure Options', projectFinancing.get(ApplicationUtils.UNSECURED_LOAN));

        // Get values from controlling picklist.
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            if (picklistValue.getLabel() != ApplicationUtils.SECURED_LOAN
                    && picklistValue.getLabel() != ApplicationUtils.UNSECURED_LOAN) {
                financingOptions.get('General Options').add(picklistValue.getLabel());
            }
        }

        return financingOptions;
    }

    public BIGPortalManageApplicationController() {
        // Instantiate application utility
        applicationUtility = new BIGPortalManageApplicationUtils();
        // Set account
        account = applicationUtility.getAccount();
        // Flex Mesures selection list
        flexMeasures = new String[]{};
        kickerMeasures = new String[]{};
        newBpiAnalystContact = new Contact();
        isBpiCertified = !hasAccountBPIAccreditation;
        injectedController = this;
    }

    /**
     * Checks if user has access and then initialize the data model.
     *
     * @return The current page if the user has access to HU/AHU programs, or a redirect to the Access Denied page.
     */
    public PageReference init() {
        PageReference redirect = BIGUtility.checkHUOrAHUContactAccess(applicationUtility.getUserUtils());
        if (redirect == null) {
            validateParameters();
            application = new Application__c();
            dwellingUnitsMap = new Map<String, Dwelling_Unit__c>();

            if (action == ACTION_NEW) {

                // Redirect to view-only page.
                if (String.isNotBlank(applicationId)) {
                    redirect = Page.BIGPortalManageApplication;
                    redirect.getParameters().put('action', ACTION_DETAIL);
                    redirect.getParameters().put('id', applicationId);
                    redirect.setRedirect(true);
                } else {
                    measureTypesListOrdered = MeasureTypeUtils.getNonRetiredMeasureTypes();
                    measureTypesById = new Map<Id, Measure_Types__mdt>(measureTypesListOrdered);
                    // Measures List
                    measures = new List<Measure__c>();
                    // Assign dwelling unit if it's specified by parameter
                    if (dwellingUnitId != null) {
                        dwellingUnit = applicationUtility.getDwellingUnit(dwellingUnitId);
	
                        dwellingUnit = applicationUtility.isDwellingUnitRequiredDataComplete(dwellingUnit)
                                           ? dwellingUnit
                                           : null;
                        if (dwellingUnit != null) {
                            dwellingSearchText = dwellingUnit.Dwelling_Unit_Name__c;
                            // Set Utility Account
                            utilityAccount = dwellingUnit.Utility_Accounts__r;
                            // Set zipCodeErrors
                            validateZipCode(dwellingUnit.Building__r.ZIP_Code__c);
                        }
                    }
                }
            } else if (action == ACTION_DETAIL) {
                application = applicationUtility.getApplication(applicationId);

                if (application != null) {
                    measureTypesListOrdered = application.Status__c == ApplicationUtils.CREATED_STATUS
                            ? MeasureTypeUtils.getNonRetiredMeasureTypes()
                            : MeasureTypeUtils.getMeasureTypes();
                    measureTypesById = new Map<Id, Measure_Types__mdt>(measureTypesListOrdered);
                    // Assign application measures
                    measures = application.Measures__r;
                    flexMeasures = new String[]{};
                    kickerMeasures = new String[]{};

                    for (Id measureTypeId : measureTypesById.keySet()) {
                        for (Measure__c measure : measures) {
                            Measure_Types__mdt measureType = measureTypesById.get(measureTypeId);
                            String measureTypeName = measureType.DeveloperName;

                            if (measure.Measure_Code_Abbreviation__c == measureTypeName) {
                                String measureIdIncentive = measureTypeId + '_' + measureType.Incentive__c.intValue();

                                if (measureType.Measure_Type__c == MEASURE_TYPE_BASE) {
                                    if (String.isNotBlank(measureType.Upgrade_Measure__c)) {
                                        if (measureType.Upgrade_Measure__c == MEASURE_UPGRADE_DUCT) {
                                            measureDuctImprovement = measureIdIncentive;
                                        }
                                        if (measureType.Upgrade_Measure__c == MEASURE_UPGRADE_BUILDING_AIR_SEALING) {
                                            measureAirSealing = measureIdIncentive;
                                        }
                                        if (measureType.Upgrade_Measure__c == MEASURE_UPGRADE_ATTIC_INSULATION) {
                                            measureAtticInsulation = measureIdIncentive;
                                        }
                                    }
                                }

                                if (measureType.Measure_Type__c == MEASURE_TYPE_FLEX) {
                                    if (String.isBlank(measureType.Upgrade_Measure__c)) {
                                        flexMeasures.add(measureIdIncentive);
                                    }
                                    if (measureType.Upgrade_Measure__c == MEASURE_UPGRADE_AIR_COND) {
                                        flexMeasureAirConditioning = measureIdIncentive;
                                    }
                                    if (measureType.Upgrade_Measure__c == MEASURE_UPGRADE_GAS_HEATING) {
                                        flexMeasureGasHeating = measureIdIncentive;
                                    }
                                    if (measureType.Upgrade_Measure__c == MEASURE_UPGRADE_WATER_HEATER) {
                                        flexMeasureWaterHeater = measureIdIncentive;
                                    }
                                }

                                if (measureType.Measure_Type__c == MEASURE_TYPE_KICKER) {
                                    kickerMeasures.add(measureIdIncentive);
                                }
                            }
                        }
                    }

                    // Assign application dwelling unit
                    dwellingUnit = applicationUtility.getDwellingUnit(application.Dwelling_Unit__c);
                    // Set utility account
                    utilityAccount = dwellingUnit.Utility_Accounts__r;

                    Set<Id> uploadedAttachmentIds = BIGUtility.getValidSFDCIds(
                            new Set<String>{application.Rebate_Assignment_Form__c,
                            application.Test_In_Measure_CAS_Form__c, application.Test_Out_Measure_CAS_Form__c,
                            application.CAS_Test_Acknowledgement_Form__c, application.Client_Signed_Contract_SOW__c,
                            application.Building_Permit__c, application.Additional_Documents__c});

                    // Get the application files and their attachments
                    Map<Id, Application_File__c> uploadedAppFilesMap = applicationUtility
                            .getAppFilesMap(uploadedAttachmentIds);

                    if (uploadedAppFilesMap.containsKey(application.Client_Signed_Contract_SOW__c)) {
                        uploadedClientSignedContractSOW = uploadedAppFilesMap.get(
                                application.Client_Signed_Contract_SOW__c);
                    }
                    if (uploadedAppFilesMap.containsKey(application.Rebate_Assignment_Form__c)) {
                        uploadedRebateAssignmetForm = uploadedAppFilesMap.get(application.Rebate_Assignment_Form__c);
                    }
                    if (uploadedAppFilesMap.containsKey(application.Test_In_Measure_CAS_Form__c)) {
                        uploadedTestInMeasureCASForm = uploadedAppFilesMap.get(application.Test_In_Measure_CAS_Form__c);
                    }
                    if (uploadedAppFilesMap.containsKey(application.Test_Out_Measure_CAS_Form__c)) {
                        uploadedTestOutMeasureCASForm = uploadedAppFilesMap.get(
                                application.Test_Out_Measure_CAS_Form__c);
                    }
                    if (uploadedAppFilesMap.containsKey(application.CAS_Test_Acknowledgement_Form__c)) {
                        uploadedCasTestAcknowledgementForm = uploadedAppFilesMap.get(
                                application.CAS_Test_Acknowledgement_Form__c);
                    }
                    if (uploadedAppFilesMap.containsKey(application.Building_Permit__c)) {
                        uploadedBuildingPermit = uploadedAppFilesMap.get(application.Building_Permit__c);
                    }
                    if (uploadedAppFilesMap.containsKey(application.Additional_Documents__c)) {
                        uploadedAdditionalDocuments = uploadedAppFilesMap.get(application.Additional_Documents__c);
                    }
                }
            }

            checkMessages();
            // Instantiate atachments
            clearViewState();

        }

        return redirect;
    }

    /**
     * Validate parameters recived
     */
    private void validateParameters() {
        String pAction = ApexPages.currentPage().getParameters().get('action');
        String pId = ApexPages.currentPage().getParameters().get('id');
        String pDwellingId = ApexPages.currentPage().getParameters().get('dwellingId');
        if (pAction != null) {
            if(pAction == ACTION_DETAIL || pAction == ACTION_NEW) {
                 action = pAction;
            }
            if (pId !=null) {
                applicationId = String.escapeSingleQuotes(pId);
            }
            if (action == ACTION_NEW) {
                if (pDwellingId != null) {
                    dwellingUnitId = String.escapeSingleQuotes(pDwellingId);
                }
            }
        }
    }

    /**
     * Search for dwelling units
     */
    public void searchDwellingUnit() {
        Set<String> setPrograms = new Set<String>{BIGPortalManageApplicationUtils.HUP};
        String excludePrograms = BIGPortalManageApplicationUtils.convertSetToString(setPrograms);

        String accId = account.Id;
        String filter = 'Building__r.Account_del__c = \'' + accId +
                '\' AND Program_Ineligibility__c NOT IN (' + excludePrograms + ')';

        if (String.isNotEmpty(dwellingSearchText)) {
            String strToFind = '\'%' + String.escapeSingleQuotes(dwellingSearchText) + '%\'';
            String nameFilter = applicationUtility.buildFilterByNameForDwellingUnits(dwellingSearchText);

            filter += ' AND (Dwelling_Unit_Name__c LIKE '
                    + strToFind + ' OR Street_Address__c LIKE ' + strToFind + ' OR Building__r.ZIP_Code__c '
                    + 'LIKE ' + strToFind + ' OR ' + nameFilter + ')';
        }

        dwellingUnitsMap = applicationUtility.getDwellingUnitsToCreateApps(filter);
        this.setRecords(dwellingUnitsMap.values());
    }

    /**
     * Assigns Dwelling
     * This method can be invoked by an action function setting the parameter dwellingToAssignId
     */
    public void assignDwellingUnit() {
        if (dwellingToAssignId != null) {
            if (dwellingUnitsMap.get(dwellingToAssignId) != null) {
                dwellingUnit = dwellingUnitsMap.get(dwellingToAssignId);
                //Set utility account
                utilityAccount = dwellingUnit.Utility_Accounts__r;
                validateZipCode(dwellingUnit.Building__r.ZIP_Code__c);
            }
        }
    }

    public PageReference saveApplication() {
        Boolean success = true;
        PageReference returnPage = null;
        Application__c app = getHUPApplication();

        if (applicationUtility.getUserUtils().isHUSuspended() && app.Status__c == null) {
            application.addError(BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR);
            clearViewState();

            return returnpage;
        }

        // Clear viewstate if there are errors
        String measureDuctImprovementId = (measureDuctImprovement != null)
                                          ? measureDuctImprovement.split('_')[0]
                                          : null;

        String measureAirSealingId = (measureAirSealing != null) ? measureAirSealing.split('_')[0] : null;

        String measureAtticInsulationId = (measureAtticInsulation != null)
                                          ? measureAtticInsulation.split('_')[0]
                                          : null;

        List<String> baseMeasures = new List<String>();
        if (measureDuctImprovementId != null) {
            baseMeasures.add(measureDuctImprovementId);
        }
        if (measureAirSealingId != null) {
            baseMeasures.add(measureAirSealingId);
        }
        if (measureAtticInsulationId != null) {
            baseMeasures.add(measureAtticInsulationId);
        }

        if (!validateDwellingUnit()) {
            clearViewState();
            return returnPage;
        }

        String status = (app.Status__c == ApplicationUtils.CORRECTION_REQUIRED_STATUS)
                ? ApplicationUtils.CORRECTION_REQUIRED_STATUS
                : ApplicationUtils.CREATED_STATUS;

        return processApplication(status, baseMeasures, APP_SAVED_SUCCESS);
    }

    /**
     * Create application record
     */
    public PageReference submitApplication() {
        Boolean success = true;
        PageReference returnPage = null;
        Application__c app = getHUPApplication();

        if (applicationUtility.getUserUtils().isHUSuspended() && String.isBlank(app.Status__c)) {
            application.addError(BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR);
            clearViewState();

            return returnPage;
        }

        // Validate Rebate asignment
        if (application.Rebate_Assignment__c == null || application.Rebate_Assignment__c == '') {
            success = false;
            application.addError('One rebate assignment must be selected.');
        }
        if (application.Work_Start_Date__c == null) {
            success = false;
            application.addError('Work Start Date is required');
        }
        if (application.Work_Finish_Date__c == null) {
            success = false;
            application.addError('Work Finish Date is required');
        }
        if (application.Work_Start_Date__c != null && application.Work_Finish_Date__c != null
                && application.Work_Start_Date__c > application.Work_Finish_Date__c) {
            success = false;
            application.addError('Work Finish Date cannot be before Work Start Date.');
        }
        if (application.Test_In_Date__c == null) {
            success = false;
            application.addError('Test In Date is required.');
        }
        if (application.Test_Out_Date__c == null) {
            success = false;
            application.addError('Test Out Date is required.');
        }
        // Set Base Measures Id
        String measureDuctImprovementId = (measureDuctImprovement != null)
                                          ? measureDuctImprovement.split('_')[0]
                                          : null;

        String measureAirSealingId = (measureAirSealing != null) ? measureAirSealing.split('_')[0] : null;

        String measureAtticInsulationId = (measureAtticInsulation != null)
                                          ? measureAtticInsulation.split('_')[0]
                                          : null;

        List<String> baseMeasures = new List<String>();
        if (measureDuctImprovementId != null) {
            baseMeasures.add(measureDuctImprovementId);
        }
        if (measureAirSealingId != null) {
            baseMeasures.add(measureAirSealingId);
        }
        if (measureAtticInsulationId != null) {
            baseMeasures.add(measureAtticInsulationId);
        }

        if (baseMeasures.size() > 0) {
            Integer equipFlexMeasureCount = 0;

            if (String.isNotEmpty(flexMeasureWaterHeater)) {
                equipFlexMeasureCount = equipFlexMeasureCount + 1;
            }
            if (String.isNotEmpty(flexMeasureAirConditioning)) {
                equipFlexMeasureCount = equipFlexMeasureCount + 1;
            }
            if (String.isNotEmpty(flexMeasureGasHeating)) {
                equipFlexMeasureCount = equipFlexMeasureCount + 1;
            }

            if ((baseMeasures.size() + flexMeasures.size() + equipFlexMeasureCount) < 3) {
                success = false;
                application.addError(getMeasureError());
            }

        } else {
            success = false;
            application.addError(getMeasureError());
        }
        // Validate Dwelling Unit
        if (!validateDwellingUnit()) {
            success = false;
        }

        // Validate Attachments
        if (!validateAttachments()) {
            success = false;
        }
        // Clear viewstate if there are errors
        if (!success) {
            clearViewState();
            return returnPage;
        }

        String status = app.Status__c == ApplicationUtils.CORRECTION_REQUIRED_STATUS
                ? ApplicationUtils.RESUBMITTED_STATUS
                : ApplicationUtils.SUBMITTED_STATUS;

        return processApplication(status, baseMeasures, APP_SUBMITTED_SUCCESS);
    }

    public PageReference processApplication(String status, List<String> baseMeasures, String successMessage) {
        PageReference returnPage = null;
        Id dwAux;
        Integer totalMeasures = 0;
        Boolean measureSuccess = true;
        try {
            if (application.Status__c != ApplicationUtils.CORRECTION_REQUIRED_STATUS) {
                // Measures List
                measures = new List<Measure__c>();
                // Create Base Measures
                createBaseMeasures(baseMeasures);
                // Create Flex Measures
                createFlexMeasures();
                // Create Flex Measures Air Conditioning
                createFlexMeasuresAirConditioning();
                // Create Flex Measures Gas Heating
                createFlexMeasuresGasHeating();
                // Create Water Heater Measures
                createFlexMeasuresWaterHeater();
                // Create Kicker Measures
                createKickerMeasures();

                if (successMessage == APP_SUBMITTED_SUCCESS) {
                    for (Measure__c m : measures) {
                        totalMeasures += m.Incentive__c.intValue();
                    }
                }
            }
            // Create attachments list
            List<Attachment> attachmentsToSave = createAttachmentsList();

            if (measureSuccess == true || successMessage == APP_SAVED_SUCCESS) {
                String notes = System.currentPageReference().getParameters().get('notes');
                String BPIAnalyst = System.currentPageReference().getParameters().get('BPIAnalyst');

                if (String.isNotBlank(BPIAnalyst)) {
                    // A BPI Analyst was selected from the picklist.
                    if (BPIAnalyst != 'xxx') {
                        newBpiAnalystContact = bpiAnalystsMap.get(BPIAnalyst);
                        applicationUtility.saveBpiAnalyst(new Credential__c(), newBpiAnalystContact, false);
                    } else {
                        // If BPIAnalyst is xxx it means that a new bpi is being added.
                        BPIAnalyst = saveBPIAnalyst();
                    }
                }

                if (String.isNotBlank(BPIAnalyst)) {
                    /*
                    * If somebody make changes on the Dwelling_Unit_c and this one is the same
                    * that was selected for the user, it should make sure that populated data is the most current
                    */
                    dwellingUnit = applicationUtility.getDwellingUnit(dwellingUnit.Id);
                    // Save Application
                    applicationUtility.saveApplication(application, dwellingUnit, measures, attachmentsToSave, status,
                            notes, BPIAnalyst, credential);
                    if (status == ApplicationUtils.SUBMITTED_STATUS || status == ApplicationUtils.RESUBMITTED_STATUS) {
                        applicationUtility.createReview(application);
                        ApplicationUtils.createApplicationNote(application);
                    }
                    // Redirect
                    returnPage = Page.BIGPortalManageApplication;
                    returnPage.getParameters().put('action', ACTION_DETAIL);
                    returnPage.getParameters().put('id', application.Id);
                    if (status == ApplicationUtils.CREATED_STATUS) {
                        returnPage.getParameters().put('msg', '2');
                    }
                    if (status == ApplicationUtils.CORRECTION_REQUIRED_STATUS) {
                        returnPage.getParameters().put('msg', '3');
                    }
                    if (status == ApplicationUtils.SUBMITTED_STATUS) {
                        returnPage.getParameters().put('msg', '4');
                    }
                    if (status == ApplicationUtils.RESUBMITTED_STATUS) {
                        returnPage.getParameters().put('msg', '5');
                    }
                    returnPage.setRedirect(true);
                }
            }
        } catch (Exception e) {
            returnPage = Page.BIGPortalManageApplication;
            ApexPages.addMessages(e);
            // Leaves the view state as it was before failing
            returnPage.getParameters().put('action', ACTION_DETAIL);
            returnPage.getParameters().put('id', application.Id);

            if (application.Status__c == ApplicationUtils.CREATED_STATUS) {
                returnPage.getParameters().put('msg', '2');
            } else if (application.Status__c == ApplicationUtils.CORRECTION_REQUIRED_STATUS
                    || application.Status__c == ApplicationUtils.SUBMITTED_STATUS
                    || application.Status__c == ApplicationUtils.RESUBMITTED_STATUS) {
                returnPage.getParameters().put('msg', '3');
            }
            System.debug('### Exception while saving the application: ' + e.getStackTraceString());
        } finally {
            clearViewState();
        }
        return returnPage;
    }

    private Boolean validateDwellingUnit() {
        Boolean success = true;
        // Check for dwelling unit
        if (dwellingUnit == null) {
            if (dwellingSearchText != null && dwellingSearchText.trim() != '') {
                // Search for dwelling unit
                searchDwellingUnit();
                // Check if dwelling unit was found
                if (dwellingUnit == null) {
                    if (dwellingUnitsMap.size() > 0) {
                        multipleResultsFound = true;
                        success = false;
                        application.addError('Multiple building/dwelling units were found. Please select one from ' +
                                'the list.');
                    } else {
                        success = false;
                        application.addError('No building/dwelling unit was found. Please use the search button for ' +
                                'better results.');
                    }
                }
            } else {
                success = false;
                application.addError('You must enter building/dwelling unit name. Please use the search button for ' +
                        'better results.');
            }
        }
        return success;
    }

    /**
     * Gets a formatted error message based on the minimum incentive required.
     *
     * @return The error message properly formatted.
     */
    private String getMeasureError() {
        return String.format(ERROR_MEASURES, new List<String> {getMinimumIncentive().format()});
    }

    /**
     * Gets the minimum incentive required for the building year built.
     *
     * @return The minimum incentive.
     */
    public Integer getMinimumIncentive() {
        return BIGPortalManageApplicationUtils.getMinimumIncentive(dwellingUnit);
    }

    /**
     * Gets the minimum incentives required for the building year built.
     *
     * @return The minimum incentives.
     */
    public Decimal getMaximumIncentive() {
        return BIGPortalManageApplicationUtils.getMaximumIncentive(application, getMinimumIncentive());
    }

     // Create attachments list
    private List<Attachment> createAttachmentsList() {
        List<Attachment> attachmentsToSave = new List<Attachment>();
        if (clientSignedContractSOW != null && clientSignedContractSOW.Body != null
                && String.isNotBlank(clientSignedContractSOW.Name)) {
            clientSignedContractSOW.Description = BIGPortalManageApplicationUtils.CLIENT_SIGNED_CONTRACT_SOW;
            attachmentsToSave.add(clientSignedContractSOW);
        }
        if (rebateAssignmetForm != null && rebateAssignmetForm.Body != null
                && String.isNotBlank(rebateAssignmetForm.Name)) {
            rebateAssignmetForm.Description = BIGPortalManageApplicationUtils.REBATE_ASSIGNMENT_FORM;
            attachmentsToSave.add(rebateAssignmetForm);
        }
        if (testInMeasureCASForm != null && testInMeasureCASForm.Body != null
                && String.isNotBlank(testInMeasureCASForm.Name)) {
            testInMeasureCASForm.Description = BIGPortalManageApplicationUtils.TEST_IN_MEASURE_CAS_FORM;
            attachmentsToSave.add(testInMeasureCASForm);
        }
        if (testOutMeasureCASForm != null && testOutMeasureCASForm.Body != null
                && String.isNotBlank(testOutMeasureCASForm.Name)) {
            testOutMeasureCASForm.Description = BIGPortalManageApplicationUtils.TEST_OUT_MEASURE_CAS_FORM;
            attachmentsToSave.add(testOutMeasureCASForm);
        }
        if (casTestAcknowledgementForm != null && casTestAcknowledgementForm.Body != null
                && String.isNotBlank(casTestAcknowledgementForm.Name)) {
            casTestAcknowledgementForm.Description = BIGPortalManageApplicationUtils.CAS_TEST_ACKNOWLEDGEMENT_FORM;
            attachmentsToSave.add(casTestAcknowledgementForm);
        }
        if (buildingPermit != null && buildingPermit.Body != null && String.isNotBlank(buildingPermit.Name)) {
            buildingPermit.Description = BIGPortalManageApplicationUtils.BUILDING_PERMIT;
            attachmentsToSave.add(buildingPermit);
        }
        if (additionalDocuments != null && additionalDocuments.Body != null
                && String.isNotEmpty(additionalDocuments.Name)) {

            Boolean hasError = false;

            if (BIGFileUtils.isFileSizeLarger(additionalDocuments.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                hasError = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        BIGPortalManageApplicationUtils.ADDITIONAL_DOCUMENTS_SIZE_ERROR));
            }
            if (!BIGFileUtils.isFileExtensionIncluded(additionalDocuments.Name,
                    new Set<String>{'pdf', 'zip', 'doc', 'docx', 'jpg', 'gif', 'png'})) {
                hasError = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        BIGPortalManageApplicationUtils.ADDITIONAL_DOCUMENTS_EXT_ERROR));
            }

            if (!hasError) {
                additionalDocuments.Description = BIGPortalManageApplicationUtils.ADDITIONAL_DOCUMENTS;
                attachmentsToSave.add(additionalDocuments);
            }

        }
        if (bpiFileIdCard != null && bpiFileIdCard.Body != null
                && String.isNotEmpty(bpiFileIdCard.Name) && isBpiCertified) {
            if (applicationUtility.validateBpiFile(bpiFileIdCard.Name, bpiFileIdCard.BodyLength)) {
                bpiFileIdCard.Description = BIGPortalManageApplicationUtils.CERTIFICATION_CREDENTIAL_TYPE;
                attachmentsToSave.add(bpiFileIdCard);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        BIGPortalManageApplicationUtils.BPI_FILE_ERROR));
            }
        }
        return attachmentsToSave;
    }

    /**
     * Validate application attachments
     */
    private Boolean validateAttachments() {
        Boolean success = true;
        // REQUIRED
        // Test-In Measurements (CAS) Form
        // Test-Out Measurements (CAS) Form
        // CAS Test Acknowledgement Form
        // Client-Signed Contract/SOW
        if (uploadedClientSignedContractSOW == null && (clientSignedContractSOW == null
                || clientSignedContractSOW.Body == null || String.isBlank(clientSignedContractSOW.Name))) {
            success = false;
            application.addError('Client-Signed Contract/SOW file is required.');
        }
        if (uploadedTestInMeasureCASForm == null && (testInMeasureCASForm == null
                || testInMeasureCASForm.Body == null || String.isBlank(testInMeasureCASForm.Name))) {
            success = false;
            application.addError('Test-In Measurements (CAS) Form is required.');
        }
        if (uploadedTestOutMeasureCASForm == null && (testOutMeasureCASForm == null
                || testOutMeasureCASForm.Body == null || String.isBlank(testOutMeasureCASForm.Name))) {
            success = false;
            application.addError('Test-Out Measurements (CAS) Form is required.');
        }
        if (uploadedCasTestAcknowledgementForm == null && (casTestAcknowledgementForm == null
                || casTestAcknowledgementForm.Body == null || String.isBlank(casTestAcknowledgementForm.Name))) {
            success = false;
            application.addError('CAS Test Acknowledgement Form is required.');
        }
        // Rebate Assignment Form REQUIRED ONLY IF Rebate_Assignment ==
        // Not Rate Payee (Landlord/Property Owner) OR
        // Contractor Payee
        if (application.Rebate_Assignment__c == REBATE_ASSIGNMENT_NOT_RATE_PAYEE
                || application.Rebate_Assignment__c == REBATE_ASSIGNMENT_CONTRACTOR_PAYEE) {
            if (uploadedRebateAssignmetForm==null && (rebateAssignmetForm == null || rebateAssignmetForm.Body == null
                    || rebateAssignmetForm.Name == '')) {
                success = false;
                application.addError('Rebate Assignment Form is required.');
            }
        }
        return success;
    }

    /**
     * Clears ViewState
     */
    private void clearViewState() {
        clientSignedContractSOW =  new Attachment();
        rebateAssignmetForm = new Attachment();
        testInMeasureCASForm = new Attachment();
        testOutMeasureCASForm = new Attachment();
        casTestAcknowledgementForm = new Attachment();
        buildingPermit = new Attachment();
        bpiFileIdCard = new Attachment();
        additionalDocuments = new Attachment();
    }

    /**
     * Creates Base Measures
     */
    private void createBaseMeasures(List<String> baseMeasures) {
        Measure__c measure;
        for (String baseMeasure : baseMeasures) {
            if (String.isNotBlank(baseMeasure) && measureTypesById.get(baseMeasure) != null) {
                Measure_Types__mdt measureType = measureTypesById.get(baseMeasure);
                measure = new Measure__c();
                MeasureUtils.setMeasure(measure, measureType);
                // add to measures list
                measures.add(measure);
            }
        }
    }

    /**
     * Creates Flex Measures
     */
    private void createFlexMeasures() {
        Measure__c measure;
        String measureId;

        for (String flexMeasure : flexMeasures) {
            measureId = flexMeasure.split('_')[0];
            if (String.isNotBlank(measureId) && measureTypesById.get(measureId) != null) {
                Measure_Types__mdt measureType = measureTypesById.get(measureId);
                measure = new Measure__c();
                MeasureUtils.setMeasure(measure, measureType);
                // add to measures list
                measures.add(measure);
            }
        }
    }

    /**
     * Creates Flex Measures Air Conditioning
     */
    private void createFlexMeasuresAirConditioning() {
        Measure__c measure;
        String measureId;

        if (String.isNotBlank(flexMeasureAirConditioning)) {
            measureId = flexMeasureAirConditioning.split('_')[0];
            if (String.isNotBlank(measureId) && measureTypesById.get(measureId) != null) {
                Measure_Types__mdt measureType = measureTypesById.get(measureId);
                measure = new Measure__c();
                MeasureUtils.setMeasure(measure, measureType);
                // add to measures list
                measures.add(measure);
            }
        }
    }

    /**
     * Creates Flex Measures Gas Heating
     */
    private void createFlexMeasuresGasHeating() {
        Measure__c measure;
        String measureId;

        if (String.isNotBlank(flexMeasureGasHeating)) {
            measureId = flexMeasureGasHeating.split('_')[0];
            if (String.isNotBlank(measureId) && measureTypesById.get(measureId) != null) {
                Measure_Types__mdt measureType = measureTypesById.get(measureId);
                measure = new Measure__c();
                MeasureUtils.setMeasure(measure, measureType);
                // add to measures list
                measures.add(measure);
            }
        }
    }

    /**
     * Create Water Heater Measures
     */
    private void createFlexMeasuresWaterHeater() {
        Measure__c measure;
        String measureId;
        Measure_Types__mdt measureType;

        if (String.isNotBlank(flexMeasureWaterHeater)) {
            measureId = flexMeasureWaterHeater.split('_')[0];
            if (String.isNotBlank(measureId) && measureTypesById.get(measureId) != null) {
                measureType = measureTypesById.get(measureId);
                measure = new Measure__c();
                MeasureUtils.setMeasure(measure, measureType);
                // add to measures list
                measures.add(measure);
            }
        }
    }

    /**
     * Create Kicker Measures
     */
    private void createKickerMeasures() {
        Measure__c measure;
        String measureId;
        Measure_Types__mdt measureType;

        for (String kickerMeasure : kickerMeasures) {
            measureId = kickerMeasure.split('_')[0];
            if (String.isNotBlank(measureId) && measureTypesById.get(measureId) != null) {
                measureType = measureTypesById.get(measureId);
                measure = new Measure__c();
                MeasureUtils.setMeasure(measure, measureType);
                // add to measures list
                measures.add(measure);
            }
        }
    }

    /**
     * List all Dwelling Units
     */
    public List<Dwelling_Unit__c> getDwellingUnitsList() {
        if (dwellingUnitsMap != null && stdController != null) {
            return (List<Dwelling_Unit__c>) stdController.getRecords();
        }
        return null;
    }

    /**
     * List Rebate Types For Rebate assignment
     */
    public List<SelectOption> getRebateTypes() {
        List<SelectOption> options = new List<SelectOption>();
        if (String.isEmpty(application.Rebate_Assignment__c)) {
            application.Rebate_Assignment__c = REBATE_ASSIGNMENT_RATE_PAYEE;
        }
        options.add(new SelectOption(REBATE_ASSIGNMENT_RATE_PAYEE,'Account Holder (PG&E Utility Service Account)'));
        options.add(new SelectOption(REBATE_ASSIGNMENT_NOT_RATE_PAYEE,
                'Non Account Holder (Landlord/Property Owner)'));
        options.add(new SelectOption(REBATE_ASSIGNMENT_CONTRACTOR_PAYEE,'Contractor Payee'));
        return options;
    }

    /**
     * List Measure Types -> Base Measures -> Duct Improvement
     */
    public List<SelectOption> getMeasureTypesDuctImprovement() {
        List<SelectOption> options = new List<SelectOption>();

        for (Measure_Types__mdt measure : measureTypesListOrdered) {
            if (measure.Measure_Type__c == MEASURE_TYPE_BASE && measure.Upgrade_Measure__c == MEASURE_UPGRADE_DUCT) {
                options.add(new SelectOption(measure.Id + '_' + measure.Incentive__c.intValue(),
                        measure.Measure_Description__c));
            }
        }

        return options;
    }

    /**
     * List Measure Types -> Base Measures -> Whole Building Air Sealing
     */
    public List<SelectOption> getMeasureTypesBuildingAirSealing() {
        List<SelectOption> options = new List<SelectOption>();

        for (Measure_Types__mdt measure : measureTypesListOrdered) {
            if (measure.Measure_Type__c == MEASURE_TYPE_BASE
                    && measure.Upgrade_Measure__c == MEASURE_UPGRADE_BUILDING_AIR_SEALING) {
                options.add(new SelectOption(measure.Id + '_' + measure.Incentive__c.intValue(),
                        measure.Measure_Description__c));
            }
        }

        return options;
    }

    /**
     * List Measure Types -> Base Measures -> Attic Insulation & Plane Air Sealing
     */
    public List<SelectOption> getMeasureTypesAtticInsulation() {
        List<SelectOption> options = new List<SelectOption>();

        for (Measure_Types__mdt measure : measureTypesListOrdered) {
            if (measure.Measure_Type__c == MEASURE_TYPE_BASE
                    && measure.Upgrade_Measure__c == MEASURE_UPGRADE_ATTIC_INSULATION) {
                options.add(new SelectOption(measure.Id + '_' + measure.Incentive__c.intValue(),
                        measure.Measure_Description__c));
            }
        }

        return options;
    }

    /**
     * List Measure Types -> Flex Measures
     */
    public List<SelectOption> getMeasureTypesFlexMeasures() {
        List<SelectOption> options = new List<SelectOption>();

        for (Measure_Types__mdt measure : measureTypesListOrdered) {
            if (measure.Measure_Type__c == MEASURE_TYPE_FLEX && String.isBlank(measure.Upgrade_Measure__c)) {
                options.add(new SelectOption(measure.Id + '_' + measure.Incentive__c.intValue(),
                        measure.Measure_Description__c));
            }
        }

        return options;
    }


    /**
     * List Measure Types -> Flex Measures -> Air Conditioning
     */
    public List<SelectOption> getMeasuresFlexAirConditioner() {
        List<SelectOption> options = new List<SelectOption>();

        for (Measure_Types__mdt measure : measureTypesListOrdered) {
            if (measure.Measure_Type__c == MEASURE_TYPE_FLEX
                    && measure.Upgrade_Measure__c == MEASURE_UPGRADE_AIR_COND) {
                options.add(new SelectOption(measure.Id + '_' + measure.Incentive__c.intValue(),
                        measure.Measure_Description__c));
            }
        }

        return options;
    }

    /**
     * List Measure Types -> Flex Measures -> Gas Heating
     */
    public List<SelectOption> getMeasuresFlexGasHeating() {
        List<SelectOption> options = new List<SelectOption>();

        for (Measure_Types__mdt measure : measureTypesListOrdered) {
            if (measure.Measure_Type__c == MEASURE_TYPE_FLEX
                    && measure.Upgrade_Measure__c == MEASURE_UPGRADE_GAS_HEATING) {
                options.add(new SelectOption(measure.Id + '_' + measure.Incentive__c.intValue(),
                        measure.Measure_Description__c));
            }
        }

        return options;
    }

    /**
     * List Measure Types -> Flex Measures -> Water Heater
     */
     public List<SelectOption> getMeasuresFlexWaterHeater() {
        List<SelectOption> options = new List<SelectOption>();

        for (Measure_Types__mdt measure : measureTypesListOrdered) {
            if (measure.Measure_Type__c == MEASURE_TYPE_FLEX
                    && measure.Upgrade_Measure__c == MEASURE_UPGRADE_WATER_HEATER) {
                options.add(new SelectOption(measure.Id + '_' + measure.Incentive__c.intValue(),
                        measure.Measure_Description__c));
            }
        }

        return options;
     }

    /**
     * List Measure Types -> Kicker
     */
     public List<SelectOption> getMeasureTypesKicker() {
        List<SelectOption> options = new List<SelectOption>();

        for (Measure_Types__mdt measure : measureTypesListOrdered) {
            if (measure.Measure_Type__c == MEASURE_TYPE_KICKER) {
                options.add(new SelectOption(measure.Id + '_' + measure.Incentive__c.intValue(),
                        measure.Measure_Description__c));
            }
        }

        return options;
     }

    /**
     * List Base Measures
     */
    public List<Measure__c> getBaseMeasuresList() {
        List<Measure__c> measuresList = new List<Measure__c>();

        for (Measure__c measure : measures) {
            if (measure.Measure_Type__c == MEASURE_TYPE_BASE) {
                measuresList.add(measure);
            }
        }

        return measuresList;
    }

    /**
     * List Flex Measures
     */
    public List<Measure__c> getFlexMeasuresList() {
        List<Measure__c> measuresList = new List<Measure__c>();

        for (Measure__c measure : measures) {
            if (measure.Measure_Type__c == MEASURE_TYPE_FLEX && String.isBlank(measure.Upgrade_Measure__c)) {
                measuresList.add(measure);
            }
        }

        return measuresList;
    }


    /**
     * List Air Conditioning Flex Measures
     */
    public List<Measure__c> getFlexMeasuresAirConditioningList() {
        List<Measure__c> measuresList = new List<Measure__c>();

        for (Measure__c measure : measures) {
            if (measure.Measure_Type__c == MEASURE_TYPE_FLEX
                    && measure.Upgrade_Measure__c == MEASURE_UPGRADE_AIR_COND) {
                measuresList.add(measure);
            }
        }

        return measuresList;
    }

    /**
     * List Gas Heating Flex Measures
     */
    public List<Measure__c> getFlexMeasuresGasHeatingList() {
        List<Measure__c> measuresList = new List<Measure__c>();

        for (Measure__c measure : measures) {
            if (measure.Measure_Type__c == MEASURE_TYPE_FLEX
                    && measure.Upgrade_Measure__c == MEASURE_UPGRADE_GAS_HEATING) {
                measuresList.add(measure);
            }
        }

        return measuresList;
    }

    /**
     * List Water Heater Flex Measures
     */
    public List<Measure__c> getFlexMeasuresWaterHeaterList() {
        List<Measure__c> measuresList = new List<Measure__c>();

        for (Measure__c measure : measures) {
            if (measure.Measure_Type__c == MEASURE_TYPE_FLEX
                    && measure.Upgrade_Measure__c == MEASURE_UPGRADE_WATER_HEATER) {
                measuresList.add(measure);
            }
        }

        return measuresList;
    }

    /**
     * List Kicker Measures
     */
    public List<Measure__c> getKickerMeasuresList() {
        List<Measure__c> measuresList = new List<Measure__c>();

        for (Measure__c measure : measures) {
            if (measure.Measure_Type__c == MEASURE_TYPE_KICKER) {
                measuresList.add(measure);
            }
        }

        return measuresList;
    }

    /**
     * Determine if user has ACQC Program
     */
    public Boolean getHasACQCProgram() {
        return applicationUtility.getHasACQCProgram();
    }

    public void checkMessages() {
        if (System.currentPageReference().getParameters().get('msg') == '1') {
            //do nothing
        } else if (System.currentPageReference().getParameters().get('msg') == '2') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, APP_SAVED_SUCCESS));
        } else if (System.currentPageReference().getParameters().get('msg') == '4') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, APP_SUBMITTED_SUCCESS +
                    application.Name + '.'));
        } else if (System.currentPageReference().getParameters().get('msg') == '5') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, APP_RESUBMITTED_SUCCESS +
                    application.Name + '.'));
        } else {
            String appId = System.currentPageReference().getParameters().get('id');
            if (appId != null) {
                Application__c app = getHUPApplication();
                Review__c review = getReview();
                String comments = '';
                String additionalComments = '';
                // Retrieve issues.
                if (String.isNotBlank(review.Comments__c)) {
                    comments = review.Comments__c.replaceAll('\\n', '</br>');
                }
                // Retrieve comments to the applicant.
                if (String.isNotBlank(review.Additional_Comments__c)) {
                    additionalComments = review.Additional_Comments__c.replaceAll('\\n', '</br>');
                }

                if (app.Status__c == ApplicationUtils.CORRECTION_REQUIRED_STATUS) {
                    // Display issues.
                    String message = '<label class="strong">This Application requires Contractor action. '
                            + 'Please see the following feedback for your action: </label> '
                            + '<label class="strong indented">' + COMMENTS_FIELD_NAME
                            + '<p>' + comments + '</p></label>';
                    // Add message when the building has had changes after the initial application's submision.
                    if (applicationUtility.isDataUpdatedAfterInitialSubmissionByPortalUser(app)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                BIGPortalManageApplicationUtils.MESSAGE_BUILDING_HAS_CHANGED));
                    }

                    if (String.isNotBlank(additionalComments)) {
                        // Display comments to the applicant.
                        message += '<label class="strong indented">' + ADDITIONAL_COMMENTS_FIELD_NAME
                                + '<p>' + additionalComments + '</p></label>';
                    }
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
                }
                if (!ApexPages.hasMessages(ApexPages.Severity.INFO)) {
                    if (app.Status__c == ApplicationUtils.REJECTED_STATUS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                'This Application has been rejected.'));
                    }
                    if (app.Status__c == ApplicationUtils.APPROVED_STATUS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                'This Application has been approved.'));
                    }
                    if(app.Status__c == ApplicationUtils.SUBMITTED_STATUS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                'This Application has been submitted.'));
                    }
                    if (app.Status__c == ApplicationUtils.RESUBMITTED_STATUS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                'This Application has been submitted.'));
                    }
                    if (app.Status__c == ApplicationUtils.CANCELED_STATUS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                ApplicationUtils.CANCELED_MESSAGE));
                    }
                    if (app.Status__c == ApplicationUtils.REBATE_ISSUED_STATUS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                'The Rebate has been issued for this Application.'));
                    }
                }
            }
        }
    }

    public Application__c getHUPApplication() {
        String appId = System.currentPageReference().getParameters().get('id');
        if (appId!=null && appId!='') {
            List<Application__c> custs = [
                SELECT Id, Status__c, Notes__c, Application_Submission_Date__c, Dwelling_Unit__c
                FROM Application__c
                WHERE Id =: appId
                ];
            if (custs.size()>0) {
                return custs.get(0);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        'Application record does not exist.'));
            }
        }
        Application__c thisCustomer = new Application__c();

        return thisCustomer;
    }

    public Review__c getReview() {
        String appId = System.currentPageReference().getParameters().get('id');

        List<Review__c> reviews = [
            SELECT Id, Comments__c, Additional_Comments__c
            FROM Review__c
            WHERE Application__c = :appId ORDER BY CreatedDate DESC
            ];

        return !reviews.isEmpty() ? reviews.get(0) : new Review__c();
    }

    public List<Application_Note__c> getNotes() {
        String appId = System.currentPageReference().getParameters().get('id');
        return ACQCRebateApplicationService.getNotes(appId);
    }

    /**
     * Get Non-Account Owner Download Form Link
     */
    public String getNonAccountOwnerDownloadLink() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        if (settings != null && settings.HUP_Non_Account_Owner_Download_Link__c != null) {
            return settings.HUP_Non_Account_Owner_Download_Link__c;
        }
        return '';
    }

    /**
     * Get Contractor Payee Download Form Link
     */
    public String getContractorPayeeDownloadLink() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        if (settings != null && settings.HUP_Contractor_Payee_Download_Link__c != null) {
            return settings.HUP_Contractor_Payee_Download_Link__c;
        }
        return '';
    }

    public List<Contact> getAnalysts() {
        bpiAnalystsMap.putAll(applicationUtility.getAnalysts(account.Id));
        return bpiAnalystsMap.values();
    }

    /*
     * Save BPI Analyst Contact
     *
     * @return the Id of the BPI Analyst's Contact
     */
    private Id saveBPIAnalyst() {
        credential = new Credential__c();
        Id result = null;
        String errorMessage;

        // Check if BPI Analyst information is valid
        if (applicationUtility.validateBpiAnalyst(newBpiAnalystContact, isBpiCertified)) {
            // Check if there is a BPI Analyst with the same first name and last name
            if (!applicationUtility.isBpiAnalystDuplicate(bpiAnalystsMap.values(), newBpiAnalystContact)) {
                    result = applicationUtility.saveBpiAnalyst(credential, newBpiAnalystContact, isBpiCertified);
            } else {
                // If BPI Analyst is duplicated add an error message
                errorMessage = BIGPortalManageApplicationUtils.DUPLICATE_BPI_ANALYST_ERROR;
            }
        } else {
            // If BPI Analyst information is not valid add an error message
            errorMessage = BIGPortalManageApplicationUtils.INVALID_BPI_ANALYST_ERROR;
        }

        if (String.isNotBlank(errorMessage)) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage);
            ApexPages.addMessage(msg);
        }

        return result;
    }

    public Boolean getHasAdvancedHUProgram() {
        return applicationUtility.getHasAdvanceHUProgram();
    }

    public void validateZipCode(String zipCode) {
        if (applicationUtility.isApplicationCountyRestricted(zipCode)) {
            zipCodeErrors = 'Attention: The job site Zipcode entered appears to be in a BayREN administrative ' +
                    'area county. In order to submit this application, please contact BayREN at ' +
                    '<a href="https://www.bayren.org" target="_blank">www.bayren.org</a> or 866-878-6008';
        } else {
            zipCodeErrors = '';
        }
    }

    @RemoteAction
    public static Map<String, Decimal> calculateIncentiveTotal(Decimal incentivesSum, Decimal totalCost,
            Integer minimumIncentive) {
        return BIGPortalManageApplicationUtils.calculateIncentiveTotal(incentivesSum, totalCost, minimumIncentive);
    }
}