/**
 * This controller handles Advance Home Upgrade Application.
 *
 * @author Maiquel Cabrera <maiquel.cabrera@modelitsoftware.com>
 * @since 2014-03
 */
public with sharing class BIGPortalAdvancedHUAppController extends BIGPortalPaginationUtils {

    // Private Constants
    private static final String ACTION_DETAIL = 'detail';
    private static final String ACTION_EDIT = 'edit';
    private static final String ACTION_NEW = 'new';
    private static final String ACTION_VIEW = 'view';
    private static final String ACTION_PRE_CONFIRM = 'confirmPre';
    private static final String ACTION_POST_CONFIRM = 'confirmPost';
    private static final String REBATE_ASSIGNMENT_RATE_PAYEE = 'Account Holder';
    private static final String REBATE_ASSIGNMENT_NOT_RATE_PAYEE = 'Non Account Holder';
    private static final String REBATE_ASSIGNMENT_CONTRACTOR_PAYEE = 'Contractor Payee';
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final String EXECUTE_NEXT = 'executeNext';
    private static final String EXECUTE_POST_NEXT = 'executePostNext';
    private static final String PRE_APP_ACTION_SAVE = 'save';
    private static final String PRE_APP_ACTION_NEXT = 'next';
    private static final String PRE_APP_STATUS_HPXML = 'preHpxml';
    private static final String PRE_APP_SUBMIT_RESUBMIT = 'Your Pre-Installation Application has been {0} for ' +
            'review. Your Application number is {1}.';
    private static final String POST_APP_STATUS_HPXML = 'postHpxml';
    private static final String POST_APP_SUBMIT_RESUBMIT = 'Your Post-Installation Application has been {0} for ' +
            'review. Your Application number is {1}.';
    // POST APP ACTIONS
    private static final String POST_APP_ACTION_SAVE = 'save';
    private static final String POST_APP_ACTION_NEXT = 'next';

    private static final Integer MAX_HPXML_FILE_SIZE = 2936012;

    // Private properties
    private Boolean hasPostInstallSubApp = false;
    private String dwellingUnitId;
    private Map<String, Dwelling_Unit__c> dwellingUnitsMap;
    private BIGPortalManageApplicationUtils applicationUtility;
    private BIGPortalAdvanceHUApplicationUtils advanceApplicationUtility;
    private Date formattedTestInDate = null;
    private Date formattedTestOutDate = null;
    private Boolean isPreAppNext = false;
    private Credential__c credential;
    private Map<Id, Contact> bpiAnalystsMap = new Map<Id, Contact>();
    private Map<Id, Contact> homeEnergyScoreContactsMap = new Map<Id, Contact>();
    // Map with Project_Financing_Source__c as a key and all Project_Financing_Detail__c dependent options of it
    private static Map<String, List<String>> projectFinancing = PicklistUtility.getDependentOptions('Application__c',
            'Project_Financing_Source__c', 'Project_Financing_Detail__c');

    // Public properties
    public String action { get; set; }
    public String ispre { get; set; }
    public Boolean isBuildingApplication { get; set; }
    public String applicationId { get; set; }
    public Boolean showMessages { get; set; }
    public Double splitTerritoryAdjustmentPre { get; set; }
    public Double splitTerritoryAdjustmentPost { get; set; }
    public Account account { get; set; }
    public Utility_Account__c utilityAccount { get; set; }

    /* ### SEARCH BUILDING PROPERTIES ### */
    public String dwellingSearchText { get; set; }
    public Boolean multipleResultsFound { get; set; }
    public String dwellingToAssignId { get; set; }
    public String applicationToAssignId { get; set; }
    public Dwelling_Unit__c dwellingUnit { get; set; }
    public Boolean isDwellingUnitRequiredDataComplete { get; set; }
    /* -- SEARCH BUILDING PROPERTIES -- */

    public String attachToDelete { get; set; }
    public String AppNotes { get; set; }
    public Application__c application { get; set; }
    public Sub_Application__c preApplication { get; set; }
    public Sub_Application__c postApplication { get; set; }
    public Contact newBPIAnalyst { get; set; }
    public String selectedBPIAnalyst { get; set; }
    public String selectedHESAssessor { get; set; }
    public String selectedHPHIPractitioner { get; set; }
    public Boolean hasHPHIPractitioner { get; set; }
    public Boolean isBpiCertified { get; set; }

    //to expose the credential file id
    public String BPI_IdCard { get; set; }
    public String BPI_IdCardFileName { get; set; }
    public Integer BPI_IdCardFileSize { get; set; }

    public Map<String, XML_End_Use__c> preXmlEndUseMap { get; set; }
    public Map<String, XML_End_Use__C> postXMLEndUSeMap { get; set; }

    public Map<Id, Application_File__c> loadedApplicationFiles { get; set; }
    public Map<Id, Application_File__c> loadedPostApplicationFiles { get; set; }

    // Pre-Application Attachments
    public Attachment contractProposalSOW { get; set; }
    public Attachment homePerformanceXML { get; set; }
    public Attachment homePerformanceSystemFile { get; set; }
    public Attachment testInMeasurements { get; set; }
    public Attachment additionalDocuments { get; set; }
    public Attachment paymentReleaseAuthorization { get; set; }
    public Attachment homeEnergyScoreReportInputFile { get; set; }
    public Attachment homeEnergyScoreAdditionalDocuments { get; set; }
    public Attachment greenBuildingRegistryOptIn { get; set; }

    // Post-Application Attachments
    public Attachment clientSignedContractSOW { get; set; }
    public Attachment postHomePerformanceXML { get; set; }
    public Attachment postHomePerformanceSystemFile { get; set; }
    public Attachment testOutMeasurements { get; set; }
    public Attachment safetyQualityAcknowledgment { get; set; }
    public Attachment buildingPermit { get; set; }
    public Attachment postAdditionalDocuments { get; set; }
    public Attachment postPaymentReleaseAuthorization { get; set; }
    public Attachment postHomeEnergyScoreReportInputFile { get; set; }
    public Attachment postHomeEnergyScoreAdditionalDocuments { get; set; }
    public Attachment postGreenBuildingRegistryOptIn { get; set; }
    public Attachment postDeliveredSensibleEERScoresheet { get; set; }
    public BIGPortalAdvancedHUAppController injectedController { get; set; }

    public String xmlType { get; set; }
    public HPXML hpxmlEntry { get; set; }

    public Boolean hasAccountBPIAccreditation {
        get {
            return applicationUtility.hasAccountBPIAccreditation();
        }
    }

    public String formattedPreWorkFinishDate {
        get {
            return applicationUtility.formatDate(preApplication.Work_Finish_Date__c);
        }
        set {
            preApplication.Work_Finish_Date__c = String.isNotBlank(value) ? Date.parse(value) : null;
        }
    }

    public String formattedPreWorkStartDate {
        get {
            return applicationUtility.formatDate(preApplication.Work_Start_Date__c);
        }
        set {
            preApplication.Work_Start_Date__c = String.isNotBlank(value) ? Date.parse(value) : null;
        }
    }

    public String formattedPostWorkFinishDate {
        get {
            return applicationUtility.formatDate(postApplication.Work_Finish_Date__c);
        }
        set {
            postApplication.Work_Finish_Date__c = String.isNotBlank(value) ? Date.parse(value) : null;
        }
    }

    public String formattedPostWorkStartDate {
        get {
            return applicationUtility.formatDate(postApplication.Work_Start_Date__c);
        }
        set {
            postApplication.Work_Start_Date__c = String.isNotBlank(value) ? Date.parse(value) : null;
        }
    }

    public String formattedHomeEnergyScoreAssessmentDate {
        get {
            return applicationUtility.formatDate(application.Pre_HES_Assessment_Date__c);
        }
        set {
            application.Pre_HES_Assessment_Date__c = String.isNotBlank(value) ? Date.parse(value) : null;
        }
    }

    public String formattedPostHomeEnergyScoreAssessmentDate {
        get {
            return applicationUtility.formatDate(application.Post_HES_Assessment_Date__c);
        }
        set {
            application.Post_HES_Assessment_Date__c = String.isNotBlank(value) ? Date.parse(value) : null;
        }
    }

    public String formattedDeliveredSensibleEERAssessmentDate {
        get {
            return applicationUtility.formatDate(application.Delivered_Sensible_EER_Assessment_Date__c);
        }
        set {
            application.Delivered_Sensible_EER_Assessment_Date__c = String.isNotBlank(value)
                    ? Date.parse(value)
                    : null;
        }
    }

    public String formattedPreUnadjustedEnergySavingsPercent {
        get {
            return applicationUtility.formatUnadjustedEnergySavingsPercent(
                    preApplication.Unadjusted_Energy_Savings_Percent__c, 3);
        }
    }

    public String formattedPostUnadjustedEnergySavingsPercent {
        get {
            return applicationUtility.formatUnadjustedEnergySavingsPercent(
                    postApplication.Unadjusted_Energy_Savings_Percent__c, 3);
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

    public BIGPortalAdvancedHUAppController () {
        applicationUtility = new BIGPortalManageApplicationUtils();
        advanceApplicationUtility = new BIGPortalAdvanceHUApplicationUtils();

        isBuildingApplication = false;
        preXmlEndUseMap = new Map<String, XML_End_Use__c>();
        postXMLEndUseMap = new Map<String, XML_End_Use__c>();
        showMessages = true;
        isBpiCertified = !hasAccountBPIAccreditation;
        // Set account
        account = applicationUtility.getAccount();
        injectedController = this;
    }

    /**
     * Checks if user has access and then initialize the data model.
     *
     * @return Access Denied page if user does not have permissions to access the current page,
     * Advanced page with new parameters or null if we do not need redirect user.
     */
    public PageReference init() {
        PageReference redirect = BIGUtility.checkAHUContactAccess(advanceApplicationUtility.getUserUtils());
        if (redirect == null) {
            // Check if there is any HPHI Practitioner in order to hide/show that section on the page.
            hasHPHIPractitioner = !advanceApplicationUtility.getHPHIPractitioners(account.Id).isEmpty();

            validateParameters();
            isBuildingApplication = false;
            newBPIAnalyst = new Contact();
            credential = new Credential__c();
            if ((action == ACTION_NEW && application == null) || (action == null && applicationId == null)) {
                dwellingUnitsMap = new Map<String, Dwelling_Unit__c>();
                application = new Application__c(
                        RecordTypeId = BIGPortalAdvanceHUApplicationUtils.APPLICATION_RECORD_TYPE_ID);
                preApplication = new Sub_Application__c(
                        RecordTypeId = BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID);
                // Assign dwelling unit if it's specified by parameter
                if (dwellingUnitId != null) {
                    dwellingUnit = applicationUtility.getDwellingUnit(dwellingUnitId);
                    isDwellingUnitRequiredDataComplete = applicationUtility.isDwellingUnitRequiredDataComplete(dwellingUnit);
                    if (isDwellingUnitRequiredDataComplete) {
                        dwellingSearchText = dwellingUnit.Dwelling_Unit_Name__c;
                        // Set utility account
                        utilityAccount = dwellingUnit.Utility_Accounts__r;
                    } else {
                        dwellingUnit = null;
                    }
                }

                // Instantiate pre-application attachments
                clearPreApplicationViewState();
            } else if (action == ACTION_DETAIL || action == ACTION_EDIT || action == ACTION_VIEW
                    || action == ACTION_PRE_CONFIRM || action == ACTION_POST_CONFIRM
                    || (action == null && applicationId != null) || (action == ACTION_NEW && application != null)) {
                application = advanceApplicationUtility.getApplication(applicationId);
                loadSubApplicationData();

                if (action != ACTION_VIEW) {
                    // Check if the application status has been changed to approved since the last time the user refreshed
                    // the page and redirect the page according to the case.
                    if (application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS && action != ACTION_DETAIL) {
                        redirect = redirectToAction(ACTION_DETAIL, true);
                    } else if (application.Status__c ==  ApplicationUtils.CANCELED_STATUS
                            || application.Status__c == ApplicationUtils.REJECTED_STATUS
                            || application.Status__c == ApplicationUtils.REBATE_ISSUED_STATUS) {
                        redirect = redirectToAction(ACTION_VIEW, true);
                    }
                }
            }

            // preApplication actions
            // Check that the status is not Pre-Install Approved. This avoids the edge case that was changing the
            // application's status to Pre-Install Created whenever the user clicked on the browser's Back button while
            // standing on the confirm page with an application that was recently approved.
            if (Apexpages.currentPage().getParameters().get(EXECUTE_NEXT) == 'true'
                    && Apexpages.currentPage().getParameters().get('action') != ACTION_PRE_CONFIRM
                    && application.Status__c != ApplicationUtils.PRE_INSTALL_APPROVED_STATUS) {
                preAppNext();
            }

            if (Apexpages.currentPage().getParameters().get(PRE_APP_STATUS_HPXML) == 'true') {
                preAppNext();
            }

            // postApplication actions
            if (Apexpages.currentPage().getParameters().get(EXECUTE_POST_NEXT) == 'true'
                    && Apexpages.currentPage().getParameters().get('action') != ACTION_POST_CONFIRM) {
                postAppNext();
            }

            if (Apexpages.currentPage().getParameters().get(POST_APP_STATUS_HPXML) == 'true') {
                postAppNext();
            }

            // Redirect to the detail page when the status is Pre-Install Approved and the user clicks on the
            // "View Post-Application" link.
            if (application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS && action == ACTION_VIEW
                    && !Apexpages.currentPage().getParameters().containsKey('ispre')) {
                redirect = redirectToAction(ACTION_DETAIL, true);
            }

            // Whenever the status is Pre-Install Approved, the action is detail, and executeNext is true, redirect to the
            // same page without the executeNext parameter. This could happen whenever the user submits an application, it
            // is immediadetly approved, and the user clicks on the browser's back button while standing on the confirm page.
            if (application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS && action == ACTION_DETAIL
                    && Apexpages.currentPage().getParameters().get(EXECUTE_NEXT) == 'true') {
                redirect = redirectToAction(ACTION_DETAIL, true);
            }

            // For submitted and resubmitted pre and post applications, redirect to the view page.
            if (isApplicationSubmitted() && action != ACTION_VIEW && action != ACTION_PRE_CONFIRM
                    && action != ACTION_POST_CONFIRM) {
                redirect = redirectToAction(ACTION_VIEW, true);
            }
        }

        return redirect;
    }

    /**
     * Check if contact has AHU Enrollment Program suspended.
     *
     * @return True if AHU Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean getIsAHUSuspended() {
        return advanceApplicationUtility.getUserUtils().isAHUSuspended();
    }

    /**
     * Load sub Applications data
     */
    private void loadSubApplicationData() {
        if (application != null) {
            List<Sub_Application__c> subApps = application.Sub_Applications__r;
            if (subApps != null) {
                for (Sub_Application__c subApp : subApps) {
                    if (subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID
                            || subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_PRE_RECORD_TYPE_ID) {
                        // Load Pre-Application
                        preApplication = subApp;

                        // Check if an application review give some message
                        if (showMessages) {
                            checkForMessages(preApplication);
                        }

                        // set xmlEndUse
                        setXMLEndUseMap(preXmlEndUseMap, preApplication.Id);
                        // set Split Territory
                        setSplitTerritoryAjustmentValue(preApplication);
                        loadAttachments(preApplication);

                        selectedHESAssessor = application.Pre_HES_Assessor__c;
                    } else if (subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID
                            || subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_POST_RECORD_TYPE_ID) {
                        postApplication = subApp;
                        hasPostInstallSubApp = true;

                        // Check if an application review give some message
                        if (showMessages) {
                            checkForMessages(postApplication);
                        }

                        // set xmlEndUse
                        setXMLEndUseMap(postXmlEndUseMap, postApplication.Id);
                        // set Split Territory
                        setSplitTerritoryAjustmentValue(postApplication);
                        loadAttachments(postApplication);

                        selectedHESAssessor = application.Post_HES_Assessor__c;
                    }
                    selectedBPIAnalyst = subApp.BPI_Analyst__c;
                    selectedHPHIPractitioner = application.HPHI_Practitioner__c;
                }
                if (postApplication == null) {
                    postApplication = new Sub_Application__c(
                            RecordTypeId = BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID);
                    clearPostApplicationViewState();
                }
                prePopulatePostApplication();
            }
            // Assign application dwelling unit
            dwellingUnit = applicationUtility.getDwellingUnit(application.Dwelling_Unit__c);
            dwellingSearchText = dwellingUnit != null ? dwellingUnit.Dwelling_Unit_Name__c : null;
            isDwellingUnitRequiredDataComplete = applicationUtility.isDwellingUnitRequiredDataComplete(dwellingUnit);
            //Set utility account
            utilityAccount = dwellingUnit.Utility_Accounts__r;

            //call to getTemporaryNotes and populate AppsNotes
            List<Application_Note__c> tempNotes = advanceApplicationUtility.getTemporaryNotes(application.Id);

            if (tempNotes != null && tempNotes.size() > 0) {
                this.AppNotes = tempNotes.get(0).Note__c;
            }
        }
    }

    /**
     * Set a map with the XML_End_Use__c and the End_Use__c picklist in the key
     * @param Empty map with XML_End_Use objects
     * @param Sub Application Id
     * @return void
     */
    private void setXMLEndUseMap(Map<String, XML_End_Use__c> xmlEndUseMap, Id subApplicationId) {
        List<XML_End_Use__c> endUseList = advanceApplicationUtility.getXMLEndUse(subApplicationId);
        for (XML_End_Use__c endUse : endUseList) {
            xmlEndUseMap.put(endUse.End_Use__c, endUse);
        }

        XML_End_Use__c defaultObject = new XML_End_Use__c();
        defaultObject.Sub_Application__c = subApplicationId;
        defaultObject.Item_Incentive_Amount__c = 0;

        Set<String> endUseSet = new Set<String> { 'KWH Kicker', 'Therm Kicker', 'AC Kicker', 'Pool Pump Kicker' };

        for (String endUse : endUseSet) {
            if (!xmlEndUseMap.containsKey(endUse)) {
                defaultObject.End_Use__c = endUse;
                xmlEndUseMap.put(endUse, defaultObject);
            }
        }
    }
    /**
     * Calculate the Split Territory Ajustment Value for pre and post application
     */
    private void setSplitTerritoryAjustmentValue(Sub_Application__c subApp) {
        double totalIncentive;
        double payableSaving;

        if (application.Gas_Provider__c == 'Propane' && subApp.PGE_Payable_Modeled_Savings_Incentive__c != null
                && subApp.Total_Incentive_from_Tier__c != null) {
            totalIncentive = subApp.Total_Incentive_from_Tier__c;
            payableSaving = subApp.PGE_Payable_Modeled_Savings_Incentive__c;
            if (totalIncentive - payableSaving > 0) {
                if (subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID
                        || subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_PRE_RECORD_TYPE_ID) {
                    splitTerritoryAdjustmentPre = -1 * (totalIncentive - payableSaving);
                } else if (subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID
                        || subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_POST_RECORD_TYPE_ID) {
                    splitTerritoryAdjustmentPost = -1 * (totalIncentive - payableSaving);
                }
            } else {
                splitTerritoryAdjustmentPre = null;
                splitTerritoryAdjustmentPost = null;
            }
        }
    }

    /**
     * Check if the review message need to be displayed for the pre Application
     */
    private void checkForMessages(Sub_Application__c subApp) {
        List<Review__c> reviews = new List<Review__c>();
        String title = '';
        String titleApprovedPre = '<label class="strong">The pre-installation application for this job has been approved. '
                + 'You are now ready to complete post-installation application below.</label>';
        String titleApprovedPost = 'Your post-installation has been approved! It usually takes 6-8 weeks to process '
                + 'your rebate check.';

        if (subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID
                || subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_PRE_RECORD_TYPE_ID) {
            if (application.Status__c == ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS) {
                // get review object
                reviews = advanceApplicationUtility.getReviewObjects(preApplication.Id);
                title = '<label class="strong main-title">This Application requires Contractor action. Please'
                        + ' see the following feedback for your action:</label>';
            } else if (application.Status__c == ApplicationUtils.REJECTED_STATUS) {
                // get review object
                reviews = advanceApplicationUtility.getReviewObjects(preApplication.Id);
                title = '<label class="strong main-title">This Application has been rejected. Please see the'
                       + ' following comments: </label>';
            } else if (application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, titleApprovedPre));
            } else if (application.Status__c == ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS) {
                if (action == ACTION_VIEW || action == ACTION_DETAIL) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                            String.format(PRE_APP_SUBMIT_RESUBMIT, new List<String> {'submitted', application.Name})));
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                            String.format(PRE_APP_SUBMIT_RESUBMIT, new List<String> {'submitted', application.Name})));
                }
            } else if (application.Status__c == ApplicationUtils.PRE_INSTALL_RESUBMITTED_STATUS) {
                if (action == ACTION_VIEW || action == ACTION_DETAIL) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                            String.format(PRE_APP_SUBMIT_RESUBMIT, new List<String> {'resubmitted', application.Name})));
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                            String.format(PRE_APP_SUBMIT_RESUBMIT, new List<String> {'resubmitted', application.Name})));
                }
            }
        } else if (subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID
                        || subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_POST_RECORD_TYPE_ID) {
            if (application.Status__c == ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS) {
                // get review object
                reviews = advanceApplicationUtility.getReviewObjects(postApplication.Id);
                title = '<label class="strong main-title">This Application requires Contractor action. Please'
                        + ' see the following feedback for your action:</label>';
            } else if (application.Status__c == ApplicationUtils.REJECTED_STATUS) {
                reviews = advanceApplicationUtility.getReviewObjects(postApplication.Id);
                title = '<label class="strong main-title">This Application has been rejected. Please see the'
                       + ' following comments: </label>';
            } else if (application.Status__c == ApplicationUtils.POST_INSTALL_APPROVED_STATUS) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, titleApprovedPost));
            } else if (application.Status__c == ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS) {
                if (action == ACTION_VIEW || action == ACTION_DETAIL) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                            String.format(POST_APP_SUBMIT_RESUBMIT, new List<String> {'submitted', application.Name})));
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                            String.format(POST_APP_SUBMIT_RESUBMIT, new List<String> {'submitted', application.Name})));
                }

            } else if (application.Status__c == ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS) {
                if (action == ACTION_VIEW || action == ACTION_DETAIL) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                            String.format(POST_APP_SUBMIT_RESUBMIT, new List<String> {'resubmitted', application.Name})));
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                            String.format(POST_APP_SUBMIT_RESUBMIT, new List<String> {'resubmitted', application.Name})));
                }
            }
        }

        if (application.Status__c == ApplicationUtils.CANCELED_STATUS) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, ApplicationUtils.CANCELED_MESSAGE));
        } else if (application.Status__c == ApplicationUtils.REBATE_ISSUED_STATUS) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                    ApplicationUtils.REBATE_ISSUED_MESSAGE));
        }
        // Add message notifying a change in the building information
        if (application.Status__c == ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS
                || application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_CREATED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS) {
            if (applicationUtility.isDataUpdatedAfterInitialSubmissionByPortalUser(application)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                        BIGPortalManageApplicationUtils.MESSAGE_BUILDING_HAS_CHANGED));
            }
        }
        String titleIssues = '\n<label class="strong indented">Issues:';
        String titleAdditional = '\n<label class="strong indented">Comments: ';
        if (reviews.size() > 0 && reviews != null) {
            Review__c review = reviews.get(0);

            String comments = '';
            String additionalComments = '';
            if (String.isNotBlank(review.Comments__c)) {
                comments = review.Comments__c.replaceAll('\\n', '</br>');
            }
            if (String.isNotBlank(review.Additional_Comments__c)) {
                additionalComments = review.Additional_Comments__c.replaceAll('\\n', '</br>');
            }

            if (String.isNotBlank(review.Comments__c) && String.isBlank(review.Additional_Comments__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                       title + titleIssues + '</p>' + comments + '</label>'));
            } else if (String.isNotBlank(review.Comments__c) && String.isNotBlank(review.Additional_Comments__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        title + titleIssues + '<p>' + comments + '</p></label>' + titleAdditional
                                + '<p>' + additionalComments + '</p></label>'));
            }
        }
    }

    /**
     * Validate parameters received
     */
    private void validateParameters() {
        String pAction = ApexPages.currentPage().getParameters().get('action');
        String pId = ApexPages.currentPage().getParameters().get('id');
        String pDwellingId = ApexPages.currentPage().getParameters().get('dwellingId');
        String pIspre = ApexPages.currentPage().getParameters().get('ispre');
        if (pAction != null) {
            if(pAction == ACTION_DETAIL || pAction == ACTION_NEW || pAction == ACTION_VIEW || pAction == ACTION_EDIT
                    || pAction == ACTION_PRE_CONFIRM || pAction == ACTION_POST_CONFIRM) {
                action = pAction;
            }
            if (pId != null) {
                applicationId = String.escapeSingleQuotes(pId);
            }
            if (action == ACTION_NEW) {
                if (pDwellingId != null) {
                    dwellingUnitId = String.escapeSingleQuotes(pDwellingId);
                }
            }
            if (pIspre != null) {
                ispre = pIspre;
            }
        }
    }

    /**
     * Pre-Populate Post-Application with data from Pre-Application
     */
    private void prePopulatePostApplication() {
        // Assign BPI Analyst to postApplication (will be the same of Pre-Application when it's new Post-Application)
        if (postApplication.BPI_Analyst__c == null) {
            postApplication.BPI_Analyst__c = selectedBPIAnalyst;
        }
        // Assign Rebate Assignment to Post-Application (will be the same of Pre-Application when it's new Post-Application)
        if (postApplication.Rebate_Assignment__c == null) {
            postApplication.Rebate_Assignment__c = preApplication.Rebate_Assignment__c;
        }
        // Assign HPHI Practitioner to application.
        if (application.HPHI_Practitioner__c == null) {
            application.HPHI_Practitioner__c = selectedHPHIPractitioner;
        }
        // Copy Payment Release Authorization
        if (application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS
                && (preApplication.Rebate_Assignment__c == REBATE_ASSIGNMENT_CONTRACTOR_PAYEE
                || preApplication.Rebate_Assignment__c == REBATE_ASSIGNMENT_NOT_RATE_PAYEE)) {
            advanceApplicationUtility.copyPaymentReleaseAuthorization(application, preApplication, postApplication);
            loadAttachments(postApplication);
        }
    }

    private void setApplicationDetailInformation(Application__c application, Dwelling_Unit__c dwellingUnit) {
        dwellingUnit = applicationUtility.getDwellingUnit(dwellingUnit.Id);
        applicationUtility.setApplicationDetailInformation(application, dwellingUnit);
    }

    /**
     * Redirect page according to the view given by the action parameter.
     *
     * @param action string that indicates the way that the page will be displayed
     * @param redirect indicates if the view state should be flushed
     * @return Page reference
     */
    private PageReference redirectToAction(String action, Boolean redirect) {
        Map<String, String> params = new Map<String, String> {'id' => application.Id, 'action' => action};

        return setPageReference(Page.BIGPortalAdvancedHUApplication, redirect, params);
    }

    /**
     * Set up page reference with given parameters.
     *
     * @param page The page reference itself.
     * @param redirect Boolean that will redirect the page if set to true.
     * @param params Map containing the parameters needed to set the page.
     * @return Page reference
     */
    private PageReference setPageReference(PageReference page, Boolean redirect, Map<String, String> params) {
        page.setRedirect(redirect);

        for (String param : params.keySet()) {
            page.getParameters().put(param, params.get(param));
        }

        return page;
    }

    /**
     * Search for dwelling units
     */
    public void searchDwellingUnit() {
        String accId = applicationUtility.getAccount().Id;
        String filter = 'Building__r.Account_del__c = \'' + accId + '\'';

        // When creating a building from ahu component narrow down the results, otherwise
        // we'll get heap size exception.
        if (String.isNotBlank(dwellingToAssignId)) {
            filter += ' AND Id = \'' + dwellingToAssignId + '\'';
        }

        if (String.isNotEmpty(dwellingSearchText)) {
            String strToFind = '\'%' + String.escapeSingleQuotes(dwellingSearchText) + '%\'';
            String nameFilter = applicationUtility.buildFilterByNameForDwellingUnits(dwellingSearchText);

            filter += ' AND (Dwelling_Unit_Name__c LIKE ' + strToFind
                    + ' OR Street_Address__c LIKE ' + strToFind + ' OR Building__r.ZIP_Code__c LIKE ' + strToFind
                    + ' OR ' + nameFilter + ')';
        }

        dwellingUnitsMap = applicationUtility.getDwellingUnitsToCreateApps(filter);
        this.setRecords(dwellingUnitsMap.values());
    }

    public void clearDwellingSearch() {
        dwellingUnitsMap = new Map<String, Dwelling_Unit__c>();
        this.setRecords(dwellingUnitsMap.values());
    }

    /**
     * Assigns Dwelling
     * This method can be invoked by an action function setting the parameter dwellingToAssignId
     */
    public PageReference assignDwellingUnit() {

        if (applicationToAssignId != null) {
            application = advanceApplicationUtility.getApplication(applicationToAssignId);
            loadSubApplicationData();
        }

        if (dwellingToAssignId != null) {
            if (dwellingUnitsMap == null || dwellingUnitsMap.size() == 0) {
                searchDwellingUnit();
            }
            if (dwellingUnitsMap.get(dwellingToAssignId) != null) {
                dwellingUnit = dwellingUnitsMap.get(dwellingToAssignId);
                // Set utility account
                utilityAccount = dwellingUnit.Utility_Accounts__r;
            }
        }
        return null;
    }

    /**
     * List Dwelling Units
     * This is used by the dwelling unit search modal
     */
    public List<Dwelling_Unit__c> getDwellingUnitsList() {
        if (dwellingUnitsMap != null && stdController != null) {
            return (List<Dwelling_Unit__c>) stdController.getRecords();
        }
        return null;
    }

    /**
     * Saves Pre-Application record, it also creates application record.
     * @return PageReference
     */
    public PageReference savePreApplication() {
        PageReference returnPage = null;
        HPXMLResponseWrapper responseSave = new HPXMLResponseWrapper();

        if (application.Id != null && (!validSessionApplication() || isApplicationSubmitted())) {
            returnPage = redirectToAction(ACTION_VIEW, false);
        } else if (!validatePreApplicationRequiredFields(PRE_APP_ACTION_SAVE)) {
            loadAttachments(preApplication);
        } else {
            try {
                // Don't set the status if it's a returned application.
                if (application.Status__c != ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS) {
                    setApplicationDetailInformation(application, dwellingUnit);
                    application.Status__c = ApplicationUtils.PRE_INSTALL_CREATED_STATUS;
                }

                saveSelectedBPIAnalyst();

                preApplication.BPI_Analyst__c = selectedBPIAnalyst;
                preApplication.Has_HPHI__c = application.Has_HPHI__c;
                application.Application_Step__c = 2;
                // Set/Update rebate assignment
                preApplication.Rebate_Assignment__c = application.Rebate_Assignment__c;

                setHomeEnergyScoreContactsMap();
                setHomeEnergyScoreAssessorContact(true);
                setHomeEnergyScoreAssesorId(true);

                if (isNotHPHIPractioner()) {
                    removeHPHIData(application, preApplication, !hasHPHIPractitioner);
                } else if (application.Has_HPHI__c == BIGPortalAdvanceHUApplicationUtils.YES) {
                    application.HPHI_Practitioner__c = selectedHPHIPractitioner;
                    preApplication.HPHI_Practitioner__c = selectedHPHIPractitioner;
                }

                responseSave = advanceApplicationUtility.savePreApplication(application, dwellingUnit, preApplication,
                        createPreAppAttachments(), applicationUtility, PRE_APP_ACTION_SAVE, null);

                if (!isBuildingApplication) {
                    // Add success message
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                            BIGPortalAdvanceHUApplicationUtils.PRE_SAVE_MESSAGE));

                    this.processTemporaryNote(application, preApplication, AppNotes);

                    returnPage = Page.BIGPortalAdvancedHUApplication;
                    String returnAction = isPreAppNext ? ACTION_DETAIL : ACTION_EDIT;
                    returnPage.getParameters().put('action', returnAction);
                    returnPage.getParameters().put('id', application.Id);
                    returnPage.setRedirect(false);
                }

                if (!responseSave.getSuccess()) {
                    loadAttachments(preApplication);
                }
            } catch (Exception e) {
                ApexPages.addMessages(e);
                System.debug('### Exception while saving Pre-Application: ' + e.getMessage());
            } finally {
                loadAttachments(preApplication);
            }
        }

        return returnPage;
    }

    /**
     * Action of Pre-Application next button
     */
    public PageReference preAppNext() {
        PageReference returnPage;

        if (advanceApplicationUtility.getUserUtils().isAHUSuspended()
                && application.Rebate_Assignment__c == 'Contractor Payee'
                && application.Status__c != ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS) {
            application.addError(BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR);

            return returnPage;
        }

        // Hide messages in the step #3
        showMessages = false;

        if (application.Id != null && (!validSessionApplication() || isApplicationSubmitted())) {
            returnPage = redirectToAction(ACTION_VIEW, false);

            return returnPage;
        }

        Boolean success = validatePreApplicationRequiredFields(PRE_APP_ACTION_NEXT);
        Boolean successHPXML = false;
        Boolean flagHPXMLDeleted = false;
        HPXMLResponseWrapper responseSave = new HPXMLResponseWrapper();
        Decimal proposedPackageCost = 0;

        if (!success) {
            loadAttachments(preApplication);
            return returnPage;
        }

        // Delete HPXML if it has
        if (preApplication.Has_HPXML__c) {
            advanceApplicationUtility.deleteOldHPXMLData(preApplication);
            flagHPXMLDeleted = true;
        }

        // If NEXT button is clicked first
        if (preApplication.Id == null) {
            isPreAppNext = true;
            return preAppSaveBeforeNext();
        }

        // If attachment was deleted
        if (homePerformanceXML.Id == null || (homePerformanceXML.Id != null && flagHPXMLDeleted)) {
            if (preApplication.BPI_Analyst__c == null || (preApplication.BPI_Analyst__c != selectedBPIAnalyst)) {
                preApplication.BPI_Analyst__c = selectedBPIAnalyst;
                advanceApplicationUtility.saveSubApplicationBPIAnalyst(preApplication);
            }
            // Workaround to fix old payee information being displayed
            try {
                setHomeEnergyScoreAssessorContact(true);

                update application;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                System.debug('### Exception while trying to update the application: ' + e.getMessage());
                return returnPage;
            }
            saveSelectedBPIAnalyst();
            return saveHPXMLAttachmentsBeforeCallout();
        }

        try {
            if (application.Status__c == null || application.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS) {
                setApplicationDetailInformation(application, dwellingUnit);
            }

            if (application.Status__c != ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS
                    && application.Status__c != ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS) {
                application.Status__c = ApplicationUtils.PRE_INSTALL_CREATED_STATUS;
            }

            saveSelectedBPIAnalyst();
            preApplication.BPI_Analyst__c = selectedBPIAnalyst;
            preApplication.Has_HPHI__c = application.Has_HPHI__c;
            preApplication.Total_Incentive_from_Tier__c = 0;
            preApplication.Customer_Cost__c = 0;
            preApplication.Modeling_Type__c = 'NO VALUE';
            proposedPackageCost = preApplication.Proposed_Package_Cost__c;
            preApplication.Rebate_Assignment__c = application.Rebate_Assignment__c;

            setHomeEnergyScoreContactsMap();
            setHomeEnergyScoreAssessorContact(true);
            setHomeEnergyScoreAssesorId(true);

            if (isNotHPHIPractioner()) {
                removeHPHIData(application, preApplication, !hasHPHIPractitioner);
            } else if (application.Has_HPHI__c == BIGPortalAdvanceHUApplicationUtils.YES) {
                application.HPHI_Practitioner__c = selectedHPHIPractitioner;
                preApplication.HPHI_Practitioner__c = selectedHPHIPractitioner;
            }

            responseSave = advanceApplicationUtility.savePreApplication(application, dwellingUnit, preApplication,
                    createPreAppAttachments(), applicationUtility, PRE_APP_ACTION_NEXT, homePerformanceXML);

            if (!responseSave.getSuccess()) {
                // Performs a query to get the latest Application and its subApplication
                application = advanceApplicationUtility.getApplication(application.Id);
                for (Sub_Application__c subApp : application.Sub_Applications__r) {
                    if (subApp.Id == preApplication.Id) {
                        preApplication = subApp;
                    }
                }
                loadAttachments(preApplication);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, responseSave.getErrorMessage()));
                return returnPage;
            }

            try { //get the sub-application with any existing XML Results and XML End Uses
                preApplication = [
                    SELECT Id, Software__c, Software_Version__c, Building_Street_Address__c,
                        Building_City__c, Building_State__c, Building_ZIP_Code__c, Conditioned_Floor_Area__c,
                        Number_of_Dwelling_Units__c, Number_of_Stories__c, Number_of_Occupants__c, Foundation_Type__c,
                        Year_Built__c, Number_of_Bedrooms__c, Pool_Type__c, Spa_Type__c, Thermostat_Type__c,
                        Total_Window_Area__c, Avg_Window_U_Factor__c, Duct_Insulation_R_value__c,
                        Duct_Leakage_cfm25__c, Building_Leakage_cfm50__c, Avg_Ceiling_Height__c,
                        Avg_Floor_Insulation_U_Factor__c, Avg_Ceiling_Insulation_U_Factor__c, Total_Wall_Area__c,
                        Avg_Wall_Insulation_U_Factor__c, Proposed_Package_Cost__c, Total_Incentive__c,
                        Total_Incentive_Adjustment__c, Total_Energy_Savings_Percent__c, Total_Incentive_from_Tier__c,
                        RecordType.Id, Contract_Proposal_SOW__c, Home_Performance_XML__c, Test_In_Measurements__c,
                        Additional_Documents__c, Payment_Release_Authorization__c, Home_Performance_System_File__c,
                        Test_In_Date__c,
                        (SELECT Id FROM XML_Results__r),
                        (SELECT Id FROM XML_End_Uses__r)
                    FROM Sub_Application__c
                    WHERE Id = :preApplication.Id
                    ];
                preApplication.Proposed_Package_Cost__c = proposedPackageCost;
            } catch (Exception e) {
                System.debug('### Exception while trying to query for Sub-Application: ' + e.getMessage());
            }

            //get updated app and pre-app instances for energy pro applications
            if (preApplication.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_PRE_RECORD_TYPE_ID) {
                application = advanceApplicationUtility.getApplication(application.Id);
                for (Sub_Application__c subApp : application.Sub_Applications__r) {
                    if (subApp.Id == preApplication.Id) {
                        preApplication = subApp;
                    }
                }
            }

            // Need to update Application after HPXML was inserted.
            if (String.isNotEmpty(preApplication.Software__c)) {
                preApplication.Modeling_Type__c = preApplication.Software__c;
            }
            if (String.isNotEmpty(preApplication.Software_Version__c)) {
                preApplication.Modeling_Type__c += ' ' + preApplication.Software_Version__c;
            }

            if (preApplication.Proposed_Package_Cost__c - preApplication.Total_Incentive_from_Tier__c > 0) {
                if (preApplication.Total_Incentive__c != null){
                    preApplication.Customer_Cost__c = preApplication.Proposed_Package_Cost__c
                        - preApplication.Total_Incentive__c;
                } else {
                    preApplication.Customer_Cost__c = preApplication.Proposed_Package_Cost__c;
                }
            } else {
                preApplication.Customer_Cost__c = 0;
            }
            update preApplication;

            this.processTemporaryNote(application, preApplication, AppNotes);
            returnPage = Page.BIGPortalAdvancedHUApplication;
            returnPage.getParameters().put('action', ACTION_DETAIL);
            returnPage.getParameters().put('id', application.Id);
            // Clear this parameter. For some reason it's being kept from previous page references.
            returnPage.getParameters().put(EXECUTE_NEXT, '');
            returnPage.getParameters().put(PRE_APP_STATUS_HPXML, '');
            returnPage.setRedirect(false);

            // load all the information in order to display modeled energy saving information
            application = advanceApplicationUtility.getApplication(applicationId);
            loadSubApplicationData();
            return returnPage;
        } catch(Exception e) {
            ApexPages.addMessages(e);
        } finally {
            loadAttachments(preApplication);
        }
        return returnPage;
    }

    /**
     * Add param to Save application before execute preAppNext().
     */
    public PageReference preAppSaveBeforeNext() {
        PageReference returnPage = savePreApplication();
        returnPage.getParameters().put(EXECUTE_NEXT, 'true');
        returnPage.setRedirect(true);
        return returnPage;
    }

    /*
     * Save attachments before XML Callout.
     * @param
     * @return Page reference
     */
    public PageReference saveHPXMLAttachmentsBeforeCallout() {
        PageReference returnPage = Page.BIGPortalAdvancedHUApplication;

        if (application.Id != null && preApplication != null) {
            advanceApplicationUtility.insertSubApplicationFiles(application.Id, preApplication,
                    createPreAppAttachments());
        }

        this.processTemporaryNote(application, preApplication, AppNotes);

        returnPage.getParameters().put(PRE_APP_STATUS_HPXML, 'true');
        returnPage.getParameters().put('action', ACTION_DETAIL);
        returnPage.getParameters().put('id', application.Id);
        returnPage.setRedirect(true);
        return returnPage;
    }

    /**
     * It is used when the user clicks on save or continue because we need to show the value in more than one page but
     * it doesn't count for the history notes.
     */
    private void processTemporaryNote(Application__c application, Sub_Application__c subApp, String notes) {
        advanceApplicationUtility.processTemporaryNote(application.Id, subApp.Id, notes);
    }

    /**
     * Submit Pre-Application to review
     */
    public PageReference submitPreApplicationReview() {
        PageReference returnPage = null;
        if (!validSessionApplication()) {
            returnPage = redirectToAction(ACTION_VIEW, false);
            // Clear this parameter. For some reason it's being kept from previous page references
            returnPage.getParameters().put(PRE_APP_STATUS_HPXML, '');
        } else if (validatePreApplicationRequiredFields('review')) {
            List<Application_Note__c> tempNotes;
            Application_Note__c n;
            Savepoint sp = Database.setSavepoint();


            Application__c app = advanceApplicationUtility.getApplicationStatus(application.Id);

            if (application.Status__c != ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS) {
                application.Status__c = ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS;
                application.Application_Submission_Date__c = datetime.now();
                preApplication.Initial_Submission_Date__c = Datetime.now();
            } else {
                application.Status__c = ApplicationUtils.PRE_INSTALL_RESUBMITTED_STATUS;
            }

            application.Last_Application_Submission_Date__c = datetime.now();
            preApplication.Last_Submission_Date__c = Datetime.now();

            application.Preapplication_Submitted__c = Date.today();

            // keep building data for first submission only: Pre-Install submitted.
            if (application.Status__c == ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS) {
                applicationUtility.setApplicationDetailInformation(application, dwellingUnit);
            }

            try {
                update application;
                update preApplication;
                advanceApplicationUtility.processFinalNote(application.Id);
                advanceApplicationUtility.checkSubmittedApplicationFiles(preApplication.Id);

                returnPage = Page.BIGPortalAdvancedHUApplication;
                returnPage.getParameters().put('action', ACTION_PRE_CONFIRM);
                returnPage.getParameters().put('id', application.Id);
                returnPage.setRedirect(true);

            } catch (Exception e) {
                System.debug('An exception has ocurred during updating application: ' + e.getMessage());
                Database.rollback(sp);
                returnPage = Page.BIGPortalAdvancedHUApplication;
                returnPage.getParameters().put('action', ACTION_DETAIL);
                returnPage.getParameters().put('id', application.Id);
                // Clear this parameter. For some reason it's being kept from previous page references
                returnPage.getParameters().put(PRE_APP_STATUS_HPXML, '');
                returnPage.setRedirect(false);
                ApexPages.addMessages(e);
            }
        } else {
            preApplication.addError('Use "Back" to fix the errors here before Submit for Review.');
        }

        return returnPage;
    }

    /**
     * Validate Pre-Application required fields
     * @return TRUE if all req. fields are completed
     */
    public Boolean validatePreApplicationRequiredFields(String action) {
        Boolean success = true;
        // Building can't be null
        if (dwellingUnit == null) {
            success = false;
            preApplication.addError('Building is required, please select a building.');
        }
        if (action != 'save') {
            // Perform this validations only if no saving
            // Validate required Proposed Package Cost
            if (preApplication.Proposed_Package_Cost__c == null) {
                success = false;
                preApplication.addError('Proposed Package Cost is rquired.');
            }
            if (String.isEmpty(selectedBPIAnalyst)) {
                success = false;
                preApplication.addError('BPI Analyst is required.');
            }
            if (String.isEmpty(application.Has_Pre_Install_HES__c)) {
                success = false;
                application.addError('Did this home get a pre-installation Home Energy Score (HES)? is required.');
            } else if (application.Has_Pre_Install_HES__c == BIGPortalAdvanceHUApplicationUtils.YES) {
                if (application.Pre_Home_Energy_Score__c == null) {
                    success = false;
                    application.addError('Home Energy Score is required.');
                }
                if (application.Pre_HES_Assessment_Date__c == null) {
                    success = false;
                    application.addError('Home Energy Score Assessment Date is required.');
                }
                if (String.isEmpty(selectedHESAssessor)) {
                    success = false;
                    application.addError('Home Energy Score Assesor is required.');
                }
            }
            if (hasHPHIPractitioner) {
                if (String.isBlank(application.Has_HPHI__c)) {
                    success = false;
                    application.addError('Did home get High Performance HVAC installed? is required.');
                } else if (application.Has_HPHI__c == BIGPortalAdvanceHUApplicationUtils.YES
                        && String.isBlank(selectedHPHIPractitioner)) {
                    success = false;
                    application.addError('HPHI Practitioner is required.');
                }
            }
            // Validate required Test-In Date
            if (this.getFormattedTestInDate() == null) {
                success = false;
                preApplication.addError('Test-In Date is required.');
            }
            if (preApplication.Rebate_Assignment__c == null) {
                success = false;
                preApplication.addError('Please select rebate assignment.');
            }
            // Validate required attachments
            if (contractProposalSOW.Body == null && contractProposalSOW.Id == null) {
                success = false;
                preApplication.addError('Contract (Proposal)/SOW file is required.');
            }
            if (homePerformanceXML.Body == null && homePerformanceXML.Id == null) {
                success = false;
                preApplication.addError('Energy Model XML file is required.');
            }
            if (homePerformanceSystemFile.Body == null && homePerformanceSystemFile.Id == null) {
                success = false;
                preApplication.addError('Energy Model file is required.');
            }
            if (testInMeasurements.Body == null && testInMeasurements.Id == null) {
                success = false;
                preApplication.addError('Test-In Measurements (CAS) Form file is required.');
            }
            if (application.Rebate_Assignment__c == REBATE_ASSIGNMENT_CONTRACTOR_PAYEE
                    || application.Rebate_Assignment__c == REBATE_ASSIGNMENT_NOT_RATE_PAYEE) {
                if (paymentReleaseAuthorization.Body == null && paymentReleaseAuthorization.Id == null) {
                    success = false;
                    preApplication.addError('Payment Release Authorization is required.');
                }
            }
            if (application.Has_Pre_Install_HES__c == BIGPortalAdvanceHUApplicationUtils.YES) {
                if (homeEnergyScoreReportInputFile.Body == null && homeEnergyScoreReportInputFile.Id == null) {
                    success = false;
                    preApplication.addError('Home Energy Score Report / Input File is required.');
                }
                if (homeEnergyScoreAdditionalDocuments.Body == null && homeEnergyScoreAdditionalDocuments.Id == null) {
                    success = false;
                    preApplication.addError('Additional / Supplemental Home Energy Score Documents file is required');
                }
                if (greenBuildingRegistryOptIn.Body == null && greenBuildingRegistryOptIn.Id == null) {
                    success = false;
                    preApplication.addError('Green Building Registry Opt-In file is required');
                }
            }
        }

        // Validate file size and extensions
        if (contractProposalSOW != null && contractProposalSOW.Body != null && contractProposalSOW.Name != '') {
            if (BIGFileUtils.isFileSizeLarger(contractProposalSOW.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                preApplication.addError('Contract (Proposal)/SOW file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(
                    contractProposalSOW.Name, new Set<String> {'pdf', 'doc', 'docx', 'jpg', 'gif', 'png'})) {
                success = false;
                preApplication.addError(
                    'Contract (Proposal)/SOW file extension must be "pdf", "doc", "docx", "jpg", "gif" or "png".');
            }
        }
        if (homePerformanceXML != null && homePerformanceXML.Body != null && homePerformanceXML.Name != '') {
            if (BIGFileUtils.isFileSizeLarger(homePerformanceXML.BodyLength, MAX_HPXML_FILE_SIZE)) {
                success = false;
                preApplication.addError('Energy Model XML file size is exceeding 3MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(homePerformanceXML.Name, new Set<String> {'xml'})) {
                success = false;
                preApplication.addError('Energy Model XML file extension must be "xml".');
            }
        }
        if (homePerformanceSystemFile != null && homePerformanceSystemFile.Body != null
                && homePerformanceSystemFile.Name != '') {
            if (BIGFileUtils.isFileSizeLarger(homePerformanceSystemFile.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                preApplication.addError('Energy Model Input file size is exceeding 5MB.');
            }

            if (!BIGFileUtils.isFileExtensionIncluded(homePerformanceSystemFile.Name,
                    new Set<String> {'bld', 'opt', 'pdf', 'jpg', 'jpeg', 'gif', 'png'})) {
                success = false;
                preApplication.addError(
                    'Energy Model Input file extension must be "zip", "pdf", "doc", "docx", "jpg", "jpeg", ' +
                            '"gif" or "png".');
            }
        }
        if (testInMeasurements != null && testInMeasurements.Body != null && testInMeasurements.Name != '') {
            if (BIGFileUtils.isFileSizeLarger(testInMeasurements.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                preApplication.addError('Test-In Measurements (CAS) Form file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(testInMeasurements.Name, new Set<String> {'pdf'})) {
                success = false;
                preApplication.addError('Test-In Measurements (CAS) Form file extension must be "pdf".');
            }
        }
        if (additionalDocuments != null && additionalDocuments.Body != null && additionalDocuments.Name != '') {
            if (BIGFileUtils.isFileSizeLarger(additionalDocuments.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                preApplication.addError('Additional Documents file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(additionalDocuments.Name,
                    new Set<String> {'zip', 'pdf', 'doc', 'docx', 'jpg', 'gif', 'png'})) {
                success = false;
                preApplication.addError(
                    'Additional Documents file extension must be "zip", "pdf", "doc", "docx", "jpg", "gif" or "png".');
            }
        }
        if (paymentReleaseAuthorization != null && paymentReleaseAuthorization.Body != null
                && paymentReleaseAuthorization.Name != '') {
            if (BIGFileUtils.isFileSizeLarger(paymentReleaseAuthorization.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                preApplication.addError('Payment Release Authorization file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(paymentReleaseAuthorization.Name, new Set<String> {'pdf'})) {
                success = false;
                preApplication.addError('Payment Release Authorization file extension must be "pdf".');
            }
        }

        if (application.Has_Pre_Install_HES__c == BIGPortalAdvanceHUApplicationUtils.YES) {
            if (homeEnergyScoreReportInputFile != null && homeEnergyScoreReportInputFile.Body != null
                    && String.isNotBlank(homeEnergyScoreReportInputFile.Name)) {
                if (BIGFileUtils.isFileSizeLarger(homeEnergyScoreReportInputFile.BodyLength,
                        BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                    success = false;
                    preApplication.addError('Home Energy Score Report / Input File size is exceeding 5MB.');
                }
                if (!BIGFileUtils.isFileExtensionIncluded(homeEnergyScoreReportInputFile.Name,
                        new Set<String> {'bld', 'opt', 'pdf', 'jpg', 'jpeg', 'gif', 'png'})) {
                    success = false;
                    preApplication.addError('Home Energy Score Report / Input File extension must be "bld", "opt", '
                            + '"pdf", "jpg", "jpeg", "gif", "png".');
                }
            }

            if (homeEnergyScoreAdditionalDocuments != null && homeEnergyScoreAdditionalDocuments.Body != null
                    && String.isNotBlank(homeEnergyScoreAdditionalDocuments.Name)) {
                if (BIGFileUtils.isFileSizeLarger(homeEnergyScoreAdditionalDocuments.BodyLength,
                        BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                    success = false;
                    preApplication.addError('Additional/Supplemental Home Energy Score Documents file size is '
                            + 'exceeding 5MB.');
                }
                if (!BIGFileUtils.isFileExtensionIncluded(homeEnergyScoreAdditionalDocuments.Name,
                        new Set<String> {'zip', 'pdf', 'doc', 'docx', 'jpg', 'gif', 'png', 'xls', 'xlsx'})) {
                    success = false;
                    preApplication.addError('Additional/Supplemental Home Energy Score Documents file extension must '
                             + 'be "zip", "pdf", "doc","docx", "jpg", "gif", "png", "xls" or "xlsx".');
                }
            }

            if (greenBuildingRegistryOptIn != null && greenBuildingRegistryOptIn.Body != null
                    && String.isNotBlank(greenBuildingRegistryOptIn.Name)) {
                if (BIGFileUtils.isFileSizeLarger(greenBuildingRegistryOptIn.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                    success = false;
                    preApplication.addError('Green Building Registry Opt-In file size is exceeding 5MB.');
                }
                if (!BIGFileUtils.isFileExtensionIncluded(greenBuildingRegistryOptIn.Name,
                    new Set<String> {'zip', 'pdf', 'doc', 'docx', 'jpg', 'gif', 'png'})) {
                    success = false;
                    preApplication.addError('Green Building Registry Opt-In file extension must be "zip", "pdf", '
                            + '"doc", "docx", "jpg", "gif" or "png".');
                }
            }
        }
        return success;
    }

    /**
     * Save Post-Application, application record should be created.
     * @return PageReference
     */
    public PageReference savePostApplication() {
        PageReference returnPage = null;

        if (!validSessionApplication() || isApplicationSubmitted()) {
            returnPage = redirectToAction(ACTION_VIEW, false);
        } else if (!validatePostApplicationRequiredFields('save')) {
            loadAttachments(postApplication);
        } else {

            try {
                // Don't set the status if it's a returned application.
                if (application.Status__c != ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS) {
                    application.Status__c = ApplicationUtils.POST_INSTALL_CREATED_STATUS;
                }

                saveSelectedBPIAnalyst();

                application.Application_Step__c = 4;
                postApplication.BPI_Analyst__c = selectedBPIAnalyst;
                postApplication.Has_HPHI__c = application.Has_HPHI__c;
                application.HPHI_Practitioner__c = selectedHPHIPractitioner;
                postApplication.HPHI_Practitioner__c = selectedHPHIPractitioner;
                // Set/Update rebate assignment
                postApplication.Rebate_Assignment__c = application.Rebate_Assignment__c;

                setHomeEnergyScoreContactsMap();
                setHomeEnergyScoreAssessorContact(false);
                setHomeEnergyScoreAssesorId(false);

                if (isNotHPHIPractioner()) {
                    removeHPHIData(application, postApplication, !hasHPHIPractitioner);
                }

                advanceApplicationUtility.savePostApplication(application, postApplication, createPostAppAttachments(),
                        POST_APP_ACTION_SAVE, null);

                // Add success message
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                        BIGPortalAdvanceHUApplicationUtils.POST_SAVE_MESSAGE));
                this.processTemporaryNote(application, postApplication, AppNotes);

                returnPage = Page.BIGPortalAdvancedHUApplication;
                returnPage.getParameters().put('action', ACTION_DETAIL);
                returnPage.getParameters().put('id', application.Id);
                if (Apexpages.currentPage().getParameters().get(EXECUTE_POST_NEXT) == 'true') {
                    returnPage.setRedirect(true);
                } else {
                    returnPage.setRedirect(false);
                }
            } catch (Exception e) {
                ApexPages.addMessages(e);
                System.debug('### Exception while saving Post-Application: ' + e.getMessage());
            } finally {
                loadAttachments(postApplication);
            }
        }

        return returnPage;
    }

    /**
     * Action of Post-Application next button
     */
    public PageReference postAppNext() {
        PageReference returnPage;

        if (!validSessionApplication() || isApplicationSubmitted()) {
            returnPage = redirectToAction(ACTION_VIEW, false);
            return returnPage;
        }
        // Hide messages in the step #2
        showMessages = false;

        HPXMLResponseWrapper responseSave = new HPXMLResponseWrapper();
        Boolean success = validatePostApplicationRequiredFields('review');
        Boolean flagHPXMLDeleted = false;
        Decimal completedPackageCost = 0;

        if (!success) {
            loadAttachments(postApplication);
            return returnPage;
        }

        // if has HPXML
        if (postApplication.Has_HPXML__c) {
            advanceApplicationUtility.deleteOldHPXMLData(postApplication);
            flagHPXMLDeleted = true;
        }

        // if user click Next before Save
        if (postApplication.Id == null) {
            return postAppSaveBeforeNext();
        }

        // If attachment was deleted
        if (postHomePerformanceXML.Id == null || (postHomePerformanceXML.Id != null && flagHPXMLDeleted)) {
            if (postApplication.BPI_Analyst__c != selectedBPIAnalyst) {
                postApplication.BPI_Analyst__c = selectedBPIAnalyst;
                advanceApplicationUtility.saveSubApplicationBPIAnalyst(postApplication);
            }
            // Workaround to fix old payee information being displayed
            try {
                setHomeEnergyScoreAssessorContact(false);
                update application;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                System.debug('### Exception while trying to update the application: ' + e.getMessage());
                return returnPage;
            }
            saveSelectedBPIAnalyst();
            return saveHPXMLPostAttachmentsBeforeCallout();
        }

        try {
            if (application.Status__c != ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS) {
                application.Status__c = ApplicationUtils.POST_INSTALL_CREATED_STATUS;
            }

            saveSelectedBPIAnalyst();

            postApplication.BPI_Analyst__c = selectedBPIAnalyst;
            postApplication.Has_HPHI__c = application.Has_HPHI__c;
            application.HPHI_Practitioner__c = selectedHPHIPractitioner;
            postApplication.HPHI_Practitioner__c = selectedHPHIPractitioner;
            //postApplication.Total_Incentive_from_Tier__c = 0;
            postApplication.Modeling_Type__c = 'NO VALUE';
            completedPackageCost = postApplication.Completed_Package_Cost__c;
            postApplication.Rebate_Assignment__c = application.Rebate_Assignment__c;

            setHomeEnergyScoreContactsMap();
            setHomeEnergyScoreAssessorContact(false);
            setHomeEnergyScoreAssesorId(false);

            if (isNotHPHIPractioner()) {
                removeHPHIData(application, postApplication, !hasHPHIPractitioner);
            }

            responseSave = advanceApplicationUtility.savePostApplication(application, postApplication,
                    createPostAppAttachments(), POST_APP_ACTION_NEXT, postHomePerformanceXML);

            if (!responseSave.getSuccess()) {

                application = advanceApplicationUtility.getApplication(application.Id);
                if (advanceApplicationUtility.getSubApplication(application, postApplication) != null) {
                    postApplication = advanceApplicationUtility.getSubApplication(application, postApplication);
                }

                loadAttachments(postApplication);

                action = ACTION_EDIT;
                ApexPages.currentPage().getParameters().put('action', ACTION_EDIT);
                // Add error message
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, responseSave.getErrorMessage()));
                return returnPage;
            }

            //get updated app and post-app instances for energy pro applications
            if(postApplication.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_POST_RECORD_TYPE_ID){
                application = advanceApplicationUtility.getApplication(application.Id);
                for (Sub_Application__c subApp : application.Sub_Applications__r) {
                    if (subApp.Id == postApplication.Id) {
                        postApplication = subApp;
                    }
                }
            }

            // Need to update Application after HPXML was inserted.
            if (String.isNotEmpty(postApplication.Software__c)) {
                postApplication.Modeling_Type__c = postApplication.Software__c;
            }
            if (String.isNotEmpty(postApplication.Software_Version__c)) {
                postApplication.Modeling_Type__c += ' ' + postApplication.Software_Version__c;
            }

            postApplication = [
                SELECT Id, Software__c, Application__c, Air_Conditioning_Present__c, Building_Street_Address__c,
                    Building_City__c, Building_State__c, Building_ZIP_Code__c, Number_of_Stories__c,
                    Number_of_Dwelling_Units__c, Pre_Install_Electricity_Use_kWh__c, Pre_Install_Gas_Use_therms__c,
                    Total_Energy_Savings_kWh__c, Total_Energy_Savings_therms__c, Total_Energy_Savings_BTUs__c,
                    Total_Energy_Savings_Percent__c, Total_Incentive__c, Total_Incentive_Adjustment__c,
                    Total_Incentive_FROM_Tier__c, PGE_Payable_Modeled_Savings_Incentive__c
                FROM Sub_Application__c
                WHERE Id = :postApplication.Id
                ];
            postApplication.Completed_Package_Cost__c = completedPackageCost;

            update postApplication;

            this.processTemporaryNote(application, postApplication, AppNotes);
            returnPage = Page.BIGPortalAdvancedHUApplication;
            returnPage.getParameters().put('action', ACTION_DETAIL);
            returnPage.getParameters().put('id', application.Id);
            returnPage.setRedirect(false);

            // load all the information in order to display modeled energy saving information
            application = advanceApplicationUtility.getApplication(applicationId);
            loadSubApplicationData();

            return returnPage;
        } catch(Exception e) {
            ApexPages.addMessages(e);
            System.debug('### Exception while saving Post-Application: ' + e.getStackTraceString());
        } finally {
            loadAttachments(postApplication);
        }
        return returnPage;
     }


    /**
     * Add param to Save application before execute preAppNext().
     */
    public PageReference postAppSaveBeforeNext() {
        PageReference returnPage = savePostApplication();
        returnPage.getParameters().put(EXECUTE_POST_NEXT, 'true');
        returnPage.setRedirect(true);
        return returnPage;
    }

    /*
     * Save attachments before XML Callout.
     * @param
     * @return Page reference
     */
    public PageReference saveHPXMLPostAttachmentsBeforeCallout() {
        PageReference returnPage = Page.BIGPortalAdvancedHUApplication;

        if (application.Id != null && postApplication != null) {
            advanceApplicationUtility.insertSubApplicationFiles(application.Id, postApplication,
                    createPostAppAttachments());
        }
        this.processTemporaryNote(application, postApplication, AppNotes);
        returnPage.getParameters().put(POST_APP_STATUS_HPXML, 'true');
        returnPage.getParameters().put('action', ACTION_DETAIL);
        returnPage.getParameters().put('id', application.Id);
        returnPage.setRedirect(true);

        return returnPage;
    }

    /**
     * Submit Post-Application to review
     */
    public PageReference submitPostApplicationReview() {
        PageReference returnPage = null;
        if (!validSessionApplication()) {
            returnPage = redirectToAction(ACTION_VIEW, false);
            // Clear this parameter. For some reason it's being kept from previous page references
            returnPage.getParameters().put(POST_APP_STATUS_HPXML, '');
        } else if (validatePostApplicationRequiredFields('review')) {

            List<Application_Note__c> tempNotes;
            Application_Note__c note;
            Savepoint sp = Database.setSavepoint();

            if (application.Status__c != ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS) {
                application.Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS;
                postApplication.Initial_Submission_Date__c = DateTime.now();
            } else {
                application.Status__c = ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS;
            }

            application.Last_Application_Submission_Date__c = Datetime.now();
            postApplication.Last_Submission_Date__c = Datetime.now();

            if (application.Status__c == null || application.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS) {
                setApplicationDetailInformation(application, dwellingUnit);
            }

            try {
                update application;
                update postApplication;
                advanceApplicationUtility.processFinalNote(application.Id);
                advanceApplicationUtility.checkSubmittedApplicationFiles(postApplication.Id);

                String message = (application.Status__c == ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS)
                                 ? String.format(POST_APP_SUBMIT_RESUBMIT, new List<String> {
                                        'resubmitted', application.Name})
                                 : String.format(POST_APP_SUBMIT_RESUBMIT, new List<String> {
                                        'submitted', application.Name});
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
                returnPage = Page.BIGPortalAdvancedHUApplication;
                returnPage.getParameters().put('action', ACTION_POST_CONFIRM);
                returnPage.getParameters().put('id', application.Id);
                // Clear this parameter. For some reason it's being kept from previous page references
                returnPage.getParameters().put(POST_APP_STATUS_HPXML, '');
                returnPage.setRedirect(false);

            } catch (Exception e) {
                System.debug('An exception has occurred while trying to update application: ' + e.getMessage());
                Database.rollback(sp);
                returnPage = Page.BIGPortalAdvancedHUApplication;
                returnPage.getParameters().put('action', ACTION_DETAIL);
                returnPage.getParameters().put('id', application.Id);
                returnPage.setRedirect(false);
                ApexPages.addMessages(e);
            }

        } else {
            preApplication.addError('Use "Edit" to fix the errors here before Submit for Review.');
        }

        return returnPage;
    }


    /**
     * Validate Post-Application required fields
     * @return TRUE if all req. fields are completed
     */
    public Boolean validatePostApplicationRequiredFields(String action) {
        Boolean success = true;

        if (action != 'save') {
            // Validate required fields
            if (postApplication.Completed_Package_Cost__c == null) {
                success = false;
                postApplication.addError('Completed Installation Cost is required.');
            }

            if (this.getFormattedTestOutDate() == null) {
                success = false;
                postApplication.addError('Test Out Date is required.');
            }

            if (postApplication.Work_Start_Date__c == null) {
                success = false;
                postApplication.addError('Work Start Date is required.');
            }

            if (postApplication.Work_Finish_Date__c == null) {
                success = false;
                postApplication.addError('Work Finish Date is required.');
            }

            if (postApplication.Work_Start_Date__c != null && this.getFormattedTestInDate() != null
                    && postApplication.Work_Start_Date__c < Date.parse(this.getFormattedTestInDate())) {
                success = false;
                postApplication.addError('Work Start Date cannot be before Test-In Date.');
            }

            if (postApplication.Work_Start_Date__c != null && postApplication.Work_Finish_Date__c != null
                    && postApplication.Work_Start_Date__c > postApplication.Work_Finish_Date__c) {
                success = false;
                postApplication.addError('Work Finish Date cannot be before Work Start Date.');
            }

            if (postApplication.Work_Finish_Date__c != null && this.getFormattedTestOutDate() != null
                    && postApplication.Work_Finish_Date__c > Date.parse(this.getFormattedTestOutDate())) {
                success = false;
                postApplication.addError('Test Out Date cannot be before Work Finish Date.');
            }

            if (String.isEmpty(selectedBPIAnalyst)) {
                success = false;
                postApplication.addError('BPI Analyst is required.');
            }

            if (String.isEmpty(application.Has_Post_Install_HES__c)) {
                success = false;
                application.addError('Did this home get a post-installation Home Energy Score (HES)? is required.');
            } else if (application.Has_Post_Install_HES__c == BIGPortalAdvanceHUApplicationUtils.YES) {
                if (application.Post_Home_Energy_Score__c == null) {
                    success = false;
                    application.addError('Home Energy Score is required.');
                }
                if (application.Post_HES_Assessment_Date__c == null) {
                    success = false;
                    application.addError('Home Energy Score Assessment Date is required.');
                }
                if (String.isEmpty(selectedHESAssessor)) {
                    success = false;
                    application.addError('Home Energy Score Assessor is required.');
                }

                if (postHomeEnergyScoreReportInputFile.Body == null && postHomeEnergyScoreReportInputFile.Id == null) {
                    success = false;
                    postApplication.addError('Home Energy Score Report / Input File is required.');
                }
                if (postHomeEnergyScoreAdditionalDocuments.Body == null
                        && postHomeEnergyScoreAdditionalDocuments.Id == null) {
                    success = false;
                    postApplication.addError('Additional / Supplemental Home Energy Score Documents file is required');
                }
                if (postGreenBuildingRegistryOptIn.Body == null && postGreenBuildingRegistryOptIn.Id == null) {
                    success = false;
                    postApplication.addError('Green Building Registry Opt-In file is required');
                }
            }

            if (hasHPHIPractitioner) {
                if (String.isBlank(application.Has_HPHI__c)) {
                    success = false;
                    application.addError('Did home get High Performance HVAC installed? is required.');
                } else if (application.Has_HPHI__c == BIGPortalAdvanceHUApplicationUtils.YES) {
                    if (String.isBlank(selectedHPHIPractitioner)) {
                        success = false;
                        application.addError('HPHI Practitioner is required.');
                    }
                    if (application.Delivered_Sensible_EER__c == null) {
                        success = false;
                        application.addError('Delivered Sensible EER is required.');
                    }
                    if (application.Delivered_Sensible_EER_Assessment_Date__c == null) {
                        success = false;
                        application.addError('Delivered Sensible EER Assessment Date is required.');
                    }
                    if (postDeliveredSensibleEERScoresheet.Body == null && postDeliveredSensibleEERScoresheet.Id == null) {
                        success = false;
                        postApplication.addError('Delivered Sensible EER Scoresheet is required');
                    }
                }
            }

            if (String.isEmpty(application.Has_Conditioned_Area_Changed__c)) {
                success = false;
                application.addError('Has Conditioned Area is required.');
            } else if (application.Has_Conditioned_Area_Changed__c == BIGPortalAdvanceHUApplicationUtils.YES) {
                if (application.Post_Conditioned_Area__c == null) {
                    success = false;
                    application.addError('Post Conditioned Area is required.');
                }
            }

            if (postApplication.Rebate_Assignment__c == null) {
                success = false;
                postApplication.addError('Please select rebate assignment.');
            }
            // Validate required attachments
            if (clientSignedContractSOW.Body == null && clientSignedContractSOW.Id == null) {
                success = false;
                postApplication.addError('Client-Signed Contract/SOW file is required.');
            }
            if (postHomePerformanceXML.Body == null && postHomePerformanceXML.Id == null) {
                success = false;
                postApplication.addError('Home Performance XML (HPXML) file is required.');
            }
            if (postHomePerformanceSystemFile.Body == null && postHomePerformanceSystemFile.Id == null) {
                success = false;
                postApplication.addError('Home Performance System File file is required.');
            }
            if (testOutMeasurements.Body == null && testOutMeasurements.Id == null) {
                success = false;
                postApplication.addError('Test-Out Measurements (CAS) Form file is required.');
            }
            if (application.Rebate_Assignment__c == REBATE_ASSIGNMENT_CONTRACTOR_PAYEE
                    || application.Rebate_Assignment__c == REBATE_ASSIGNMENT_NOT_RATE_PAYEE) {
                if(postPaymentReleaseAuthorization.Body == null && postPaymentReleaseAuthorization.Id == null) {
                    success = false;
                    postApplication.addError('Payment Release Authorization is required.');
                }
            }

        }
        // Validate file size and extensions
        if (clientSignedContractSOW != null && clientSignedContractSOW.Body != null
                && String.isNotBlank(clientSignedContractSOW.Name)) {
            if (BIGFileUtils.isFileSizeLarger(clientSignedContractSOW.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                postApplication.addError('Client-Signed Contract/SOW file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(clientSignedContractSOW.Name,
                    new Set<String> {'pdf', 'doc', 'docx', 'jpg', 'gif', 'png'})) {
                success = false;
                postApplication.addError(
                    'Client-Signed Contract/SOW file extension must be "pdf", "doc", "docx", "jpg", "gif" or "png".');
            }
        }
        if (postHomePerformanceXML != null && postHomePerformanceXML.Body != null
                && String.isNotBlank(postHomePerformanceXML.Name)) {
            if (BIGFileUtils.isFileSizeLarger(postHomePerformanceXML.BodyLength, MAX_HPXML_FILE_SIZE)) {
                success = false;
                postApplication.addError('Home performance XML file size is exceeding 3MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(postHomePerformanceXML.Name, new Set<String> {'xml'})) {
                success = false;
                postApplication.addError('Home performance XML file extension must be "xml".');
            }
        }
        if (postHomePerformanceSystemFile != null && postHomePerformanceSystemFile.Body != null
                && String.isNotBlank(postHomePerformanceSystemFile.Name)) {
            if (BIGFileUtils.isFileSizeLarger(postHomePerformanceSystemFile.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                postApplication.addError('Energy Model Input file size is exceeding 5MB.');
            }

            if (!BIGFileUtils.isFileExtensionIncluded(postHomePerformanceSystemFile.Name,
                    new Set<String> {'bld', 'opt', 'pdf', 'jpeg', 'jpg', 'gif', 'png'})) {
                success = false;
                postApplication.addError('Energy Model Input file extension must be "bld", "opt", "tpgx", "pdf", '
                        + '"jpeg", "jpg", "gif", "png".');
            }
        }
        if (testOutMeasurements != null && testOutMeasurements.Body != null
                && String.isNotBlank(testOutMeasurements.Name)) {
            if (BIGFileUtils.isFileSizeLarger(testOutMeasurements.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                postApplication.addError('Test-Out Measurements (CAS) Form file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(testOutMeasurements.Name, new Set<String> {'pdf'})) {
                success = false;
                postApplication.addError('Test-Out Measurements (CAS) Form file extension must be "pdf".');
            }
        }
        if (safetyQualityAcknowledgment != null && safetyQualityAcknowledgment.Body != null
                && String.isNotBlank(safetyQualityAcknowledgment.Name)) {
            if (BIGFileUtils.isFileSizeLarger(safetyQualityAcknowledgment.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                postApplication.addError('Safety & Quality Acknowledgment file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(safetyQualityAcknowledgment.Name, new Set<String> {'pdf'})) {
                success = false;
                postApplication.addError('Safety & Quality Acknowledgment file extension must be "pdf".');
            }
        }
        if (buildingPermit != null && buildingPermit.Body != null && String.isNotBlank(buildingPermit.Name)) {
            if (BIGFileUtils.isFileSizeLarger(buildingPermit.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                postApplication.addError('Closed/Finaled Building Permit file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(buildingPermit.Name,
                    new Set<String> {'pdf', 'doc', 'docx', 'txt', 'jpeg', 'jpg', 'png', 'tif', 'tiff'})) {
                success = false;
                postApplication.addError('Closed/Finaled Building Permit file extension must be "pdf", "doc", "docx", '
                        + '"txt", "jpeg", "jpg", "png", "tif", "tiff".');
            }
        }
        if (postAdditionalDocuments != null && postAdditionalDocuments.Body != null
                && String.isNotBlank(postAdditionalDocuments.Name)) {
            if (BIGFileUtils.isFileSizeLarger(postAdditionalDocuments.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                postApplication.addError('Additional Documents file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(postAdditionalDocuments.Name,
                    new Set<String> {'zip', 'pdf', 'doc', 'docx', 'jpg', 'gif', 'png'})) {
                success = false;
                postApplication.addError(
                    'Additional Documents file extension must be "zip", "pdf", "doc", "docx", "jpg", "gif" or "png".');
            }
        }
        if (postPaymentReleaseAuthorization != null && postPaymentReleaseAuthorization.Body != null
                && String.isNotBlank(postPaymentReleaseAuthorization.Name)) {
            if (BIGFileUtils.isFileSizeLarger(postPaymentReleaseAuthorization.BodyLength,
                    BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                success = false;
                postApplication.addError('Payment Release Authorization file size is exceeding 5MB.');
            }
            if (!BIGFileUtils.isFileExtensionIncluded(postPaymentReleaseAuthorization.Name, new Set<String> {'pdf'})) {
                success = false;
                postApplication.addError('Payment Release Authorization file extension must be "pdf".');
            }
        }

        if (application.Has_Post_Install_HES__c == BIGPortalAdvanceHUApplicationUtils.YES) {
            if (postHomeEnergyScoreReportInputFile != null && postHomeEnergyScoreReportInputFile.Body != null
                    && String.isNotBlank(postHomeEnergyScoreReportInputFile.Name)) {
                if (BIGFileUtils.isFileSizeLarger(postHomeEnergyScoreReportInputFile.BodyLength,
                      BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                    success = false;
                    postApplication.addError('Post Home Energy Score file size is exceeding 5MB.');
                }

                if (!BIGFileUtils.isFileExtensionIncluded(postHomeEnergyScoreReportInputFile.Name,
                        new Set<String> {'bld', 'opt', 'pdf', 'jpeg', 'jpg', 'gif', 'png'})) {
                    success = false;
                    postApplication.addError('Post Home Energy Score file extension must be "bld", "opt", "tpgx", '
                            + '"pdf", "jpeg", "jpg", "gif", "png".');
                }
            }

            if (postHomeEnergyScoreAdditionalDocuments != null && postHomeEnergyScoreAdditionalDocuments.Body != null
                    && String.isNotBlank(postHomeEnergyScoreAdditionalDocuments.Name)) {

                if (BIGFileUtils.isFileSizeLarger(postHomeEnergyScoreAdditionalDocuments.BodyLength,
                        BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                    success = false;
                    postApplication.addError('Home Energy Score Additional file size is exceeding 5MB.');
                }
                if (!BIGFileUtils.isFileExtensionIncluded(postHomeEnergyScoreAdditionalDocuments.Name,
                        new Set<String> {'zip', 'pdf', 'doc', 'docx', 'jpg', 'gif', 'png', 'xls', 'xlsx'})) {
                    success = false;
                    postApplication.addError('Home Energy Score Additional file extension must be "zip", "pdf", '
                            + '"doc","docx", "jpg", "gif", "png", "xls" or "xlsx".');
                }
            }

            if (postGreenBuildingRegistryOptIn != null && postGreenBuildingRegistryOptIn.Body != null
                    && String.isNotBlank(postGreenBuildingRegistryOptIn.Name)) {
                if (BIGFileUtils.isFileSizeLarger(postGreenBuildingRegistryOptIn.BodyLength,
                        BIGPortalManageApplicationUtils.MAX_FILE_SIZE)) {
                    success = false;
                    postApplication.addError('Post Home Energy Score Building file size is exceeding 5MB.');
                }
                if (!BIGFileUtils.isFileExtensionIncluded(postGreenBuildingRegistryOptIn.Name,
                        new Set<String> {'zip', 'pdf', 'doc', 'docx', 'jpg', 'gif', 'png'})) {
                    success = false;
                    postApplication.addError('Post Home Energy Score Building file extension must be "zip", "pdf", '
                            +'"doc", "docx", "jpg", "gif" or "png".');
                }
            }

        }
        return success;
    }

    /**
     * Creates a list of all the attachments that will be related to pre application
     * @return List<Attachment>
     */
    private List<Attachment> createPreAppAttachments() {
        List<Attachment> attachmentsToSave = new List<Attachment>();
        if (contractProposalSOW != null && contractProposalSOW.Body != null
                && String.isNotBlank(contractProposalSOW.Name)) {
            contractProposalSOW.Description = BIGPortalAdvanceHUApplicationUtils.PRE_CONTRACT_SOW_FILE;
            attachmentsToSave.add(contractProposalSOW);
        }
        if (homePerformanceXML != null && homePerformanceXML.Body != null
                && String.isNotBlank(homePerformanceXML.Name)) {
            homePerformanceXML.Description = BIGPortalAdvanceHUApplicationUtils.PRE_HOME_PERFORMANCE_XML;
            attachmentsToSave.add(homePerformanceXML);
        }
        if (homePerformanceSystemFile != null && homePerformanceSystemFile.Body != null
                && String.isNotBlank(homePerformanceSystemFile.Name)) {
            homePerformanceSystemFile.Description = BIGPortalAdvanceHUApplicationUtils.PRE_HOME_PERFORMANCE_SYS;
            attachmentsToSave.add(homePerformanceSystemFile);
        }
        if (testInMeasurements != null && testInMeasurements.Body != null
                && String.isNotBlank(testInMeasurements.Name)) {
            testInMeasurements.Description = BIGPortalAdvanceHUApplicationUtils.PRE_TEST_IN_MEASUREMENTS;
            attachmentsToSave.add(testInMeasurements);
        }
        if (additionalDocuments != null && additionalDocuments.Body != null
                && String.isNotBlank(additionalDocuments.Name)) {
            additionalDocuments.Description = BIGPortalAdvanceHUApplicationUtils.PRE_ADDITIONAL_DOCUMENTS;
            attachmentsToSave.add(additionalDocuments);
        }
        if (paymentReleaseAuthorization != null && paymentReleaseAuthorization.Body != null
                && String.isNotBlank(paymentReleaseAuthorization.Name)) {
            paymentReleaseAuthorization.Description = BIGPortalAdvanceHUApplicationUtils.PRE_PAYMENT_RELEASE_AUTH;
            attachmentsToSave.add(paymentReleaseAuthorization);
        }

        if (application.Has_Pre_Install_HES__c == BIGPortalAdvanceHUApplicationUtils.YES) {
            if (homeEnergyScoreReportInputFile != null && homeEnergyScoreReportInputFile.Body != null
                    && String.isNotBlank(homeEnergyScoreReportInputFile.Name)) {
                homeEnergyScoreReportInputFile.Description =
                        BIGPortalAdvanceHUApplicationUtils.PRE_HOME_ENERGY_SCORE_REPORT_INPUT_FILE;
                attachmentsToSave.add(homeEnergyScoreReportInputFile);
            }
            if (homeEnergyScoreAdditionalDocuments != null && homeEnergyScoreAdditionalDocuments.Body != null
                    && String.isNotBlank(homeEnergyScoreAdditionalDocuments.Name)) {
                homeEnergyScoreAdditionalDocuments.Description =
                        BIGPortalAdvanceHUApplicationUtils.PRE_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS;
                attachmentsToSave.add(homeEnergyScoreAdditionalDocuments);
            }

            if (greenBuildingRegistryOptIn != null && greenBuildingRegistryOptIn.Body != null
                    && String.isNotBlank(greenBuildingRegistryOptIn.Name)) {
                greenBuildingRegistryOptIn.Description =
                        BIGPortalAdvanceHUApplicationUtils.PRE_GREEN_BUILDING_REGISTRY_OPT_IN;
                attachmentsToSave.add(greenBuildingRegistryOptIn);
            }
        }
        return attachmentsToSave;
    }

    /**
      * Creates a list of all the attachments that will be related to post application
      * @return List<Attachment>
      */
    private List<Attachment> createPostAppAttachments() {
        List<Attachment> attachmentsToSave = new List<Attachment>();
        if (clientSignedContractSOW != null && clientSignedContractSOW.Body != null
                && String.isNotBlank(clientSignedContractSOW.Name)) {
            clientSignedContractSOW.Description = BIGPortalAdvanceHUApplicationUtils.POST_CLIENT_SIGNED_SOW_FILE;
            attachmentsToSave.add(clientSignedContractSOW);
        }
        if (postHomePerformanceXML != null && postHomePerformanceXML.Body != null
                && String.isNotBlank(postHomePerformanceXML.Name)) {
            postHomePerformanceXML.Description = BIGPortalAdvanceHUApplicationUtils.POST_HOME_PERFORMANCE_XML;
            attachmentsToSave.add(postHomePerformanceXML);
        }
        if (postHomePerformanceSystemFile != null && postHomePerformanceSystemFile.Body != null
                && String.isNotBlank(postHomePerformanceSystemFile.Name)) {
            postHomePerformanceSystemFile.Description = BIGPortalAdvanceHUApplicationUtils.POST_HOME_PERFORMANCE_SYS;
            attachmentsToSave.add(postHomePerformanceSystemFile);
        }
        if (testOutMeasurements != null && testOutMeasurements.Body != null
                && String.isNotBlank(testOutMeasurements.Name)) {
            testOutMeasurements.Description = BIGPortalAdvanceHUApplicationUtils.POST_TEST_OUT_MEASUREMENTS;
            attachmentsToSave.add(testOutMeasurements);
        }
        if (safetyQualityAcknowledgment != null && safetyQualityAcknowledgment.Body != null
                && String.isNotBlank(safetyQualityAcknowledgment.Name)) {
            safetyQualityAcknowledgment.Description = BIGPortalAdvanceHUApplicationUtils.POST_QUALITY_ACKNOWLEDGMENT;
            attachmentsToSave.add(safetyQualityAcknowledgment);
        }
        if (buildingPermit != null && buildingPermit.Body != null && String.isNotBlank(buildingPermit.Name)) {
            buildingPermit.Description = BIGPortalAdvanceHUApplicationUtils.POST_BUILDING_PERMIT;
            attachmentsToSave.add(buildingPermit);
        }
        if (postAdditionalDocuments != null && postAdditionalDocuments.Body != null
                && String.isNotBlank(postAdditionalDocuments.Name)) {
            postAdditionalDocuments.Description = BIGPortalAdvanceHUApplicationUtils.POST_ADDITIONAL_DOCUMENTS;
            attachmentsToSave.add(postAdditionalDocuments);
        }
        if (postPaymentReleaseAuthorization != null && postPaymentReleaseAuthorization.Body != null
                && String.isNotBlank(postPaymentReleaseAuthorization.Name)) {
            postPaymentReleaseAuthorization.Description = BIGPortalAdvanceHUApplicationUtils.POST_PAYMENT_RELEASE_AUTH;
            attachmentsToSave.add(postPaymentReleaseAuthorization);
        }

        if (application.Has_Post_Install_HES__c == BIGPortalAdvanceHUApplicationUtils.YES) {
            if (postHomeEnergyScoreReportInputFile != null && postHomeEnergyScoreReportInputFile.Body != null
                    && String.isNotBlank(postHomeEnergyScoreReportInputFile.Name)) {
                postHomeEnergyScoreReportInputFile.Description =
                        BIGPortalAdvanceHUApplicationUtils.POST_HOME_ENERGY_SCORE_REPORT_INPUT_FILE;
                attachmentsToSave.add(postHomeEnergyScoreReportInputFile);
            }

            if (postHomeEnergyScoreAdditionalDocuments != null && postHomeEnergyScoreAdditionalDocuments.Body != null
                    && String.isNotBlank(postHomeEnergyScoreAdditionalDocuments.Name)) {
                postHomeEnergyScoreAdditionalDocuments.Description =
                        BIGPortalAdvanceHUApplicationUtils.POST_HOME_ENERGY_SCORE_ADDITIONAL_DOCUMENTS;
                attachmentsToSave.add(postHomeEnergyScoreAdditionalDocuments);
            }

            if (postGreenBuildingRegistryOptIn != null && postGreenBuildingRegistryOptIn.Body != null
                    && String.isNotBlank(postGreenBuildingRegistryOptIn.Name)) {
                postGreenBuildingRegistryOptIn.Description =
                        BIGPortalAdvanceHUApplicationUtils.POST_GREEN_BUILDING_REGISTRY_OPT_IN;
                attachmentsToSave.add(postGreenBuildingRegistryOptIn);
            }
        }

        if (application.Has_HPHI__c == BIGPortalAdvanceHUApplicationUtils.YES
                && postDeliveredSensibleEERScoresheet != null && postDeliveredSensibleEERScoresheet.Body != null
                && String.isNotBlank(postDeliveredSensibleEERScoresheet.Name)) {
            postDeliveredSensibleEERScoresheet.Description =
                    BIGPortalAdvanceHUApplicationUtils.POST_DELIVERED_SENSIBLE_EER_SCORESHEET;
            attachmentsToSave.add(postDeliveredSensibleEERScoresheet);
        }

        return attachmentsToSave;
    }

    /**
     * Load attachments for subApplication.
     *
     * @param subApp The Sub Application record to determine which attachments to load.
     */
    public void loadAttachments(Sub_Application__c subApp) {
        Set<Id> appFileIds;
        Map<Id, Attachment> loadedAttachments;

        if (subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID
                || subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_PRE_RECORD_TYPE_ID) {

            appFileIds = BIGUtility.getValidSFDCIds(
                    new Set<String> {
                        subApp.Contract_Proposal_SOW__c,
                        subApp.Home_Performance_XML__c,
                        subApp.Test_In_Measurements__c,
                        subApp.Additional_Documents__c,
                        subApp.Payment_Release_Authorization__c,
                        subApp.Home_Performance_System_File__c,
                        subApp.HES_Report_Input_File__c,
                        subApp.HES_Additional_Documents__c,
                        subApp.GBR_Opt_In__c});

            loadedApplicationFiles = advanceApplicationUtility.getApplicationFilesMap(appFileIds);
            loadedAttachments = getApplicationFileToAttachment(loadedApplicationFiles.values());

            contractProposalSOW =
                    loadedAttachments.get(subApp.Contract_Proposal_SOW__c) != null
                    ? loadedAttachments.get(subApp.Contract_Proposal_SOW__c)
                    : new Attachment();

            homePerformanceXML =
                    loadedAttachments.get(subApp.Home_Performance_XML__c) != null
                    ? loadedAttachments.get(subApp.Home_Performance_XML__c)
                    : new Attachment();

            homePerformanceSystemFile =
                    loadedAttachments.get(subApp.Home_Performance_System_File__c) != null
                    ? loadedAttachments.get(subApp.Home_Performance_System_File__c)
                    : new Attachment();

            testInMeasurements =
                    loadedAttachments.get(subApp.Test_In_Measurements__c) != null
                    ? loadedAttachments.get(subApp.Test_In_Measurements__c)
                    : new Attachment();

            additionalDocuments =
                    loadedAttachments.get(subApp.Additional_Documents__c) != null
                    ? loadedAttachments.get(subApp.Additional_Documents__c)
                    : new Attachment();

            paymentReleaseAuthorization =
                    loadedAttachments.get(subApp.Payment_Release_Authorization__c) != null
                    ? loadedAttachments.get(subApp.Payment_Release_Authorization__c)
                    : new Attachment();

            homeEnergyScoreReportInputFile =
                    loadedAttachments.get(subApp.HES_Report_Input_File__c) != null
                    ? loadedAttachments.get(subApp.HES_Report_Input_File__c)
                    : new Attachment();

            homeEnergyScoreAdditionalDocuments =
                    loadedAttachments.get(subApp.HES_Additional_Documents__c) != null
                    ? loadedAttachments.get(subApp.HES_Additional_Documents__c)
                    : new Attachment();

            greenBuildingRegistryOptIn =
                    loadedAttachments.get(subApp.GBR_Opt_In__c) != null
                    ? loadedAttachments.get(subApp.GBR_Opt_In__c)
                    : new Attachment();

        } else if (subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID
                || subApp.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_POST_RECORD_TYPE_ID) {
            appFileIds = BIGUtility.getValidSFDCIds(
                    new Set<String> {
                        subApp.Client_Signed_Contract_SOW__c,
                        subApp.Home_Performance_XML__c,
                        subApp.Test_Out_Measurements__c,
                        subApp.Additional_Documents__c,
                        subApp.Payment_Release_Authorization__c,
                        subApp.Home_Performance_System_File__c,
                        subApp.Safety_Quality_Acknowledgment__c,
                        subapp.Building_Permit__c,
                        subApp.HES_Report_Input_File__c,
                        subApp.HES_Additional_Documents__c,
                        subApp.GBR_Opt_In__c,
                        application.Delivered_Sensible_EER_Scoresheet__c});

            loadedPostApplicationFiles = advanceApplicationUtility.getApplicationFilesMap(appFileIds);
            loadedAttachments = getApplicationFileToAttachment(loadedPostApplicationFiles.values());

            clientSignedContractSOW =
                    loadedAttachments.get(subApp.Client_Signed_Contract_SOW__c) != null
                    ? loadedAttachments.get(subApp.Client_Signed_Contract_SOW__c)
                    : new Attachment();

            postHomePerformanceXML =
                    loadedAttachments.get(subApp.Home_Performance_XML__c) != null
                    ? loadedAttachments.get(subApp.Home_Performance_XML__c)
                    : new Attachment();

            postHomePerformanceSystemFile =
                    loadedAttachments.get(subApp.Home_Performance_System_File__c) != null
                    ? loadedAttachments.get(subApp.Home_Performance_System_File__c)
                    : new Attachment();

            testOutMeasurements =
                    loadedAttachments.get(subApp.Test_Out_Measurements__c) != null
                    ? loadedAttachments.get(subApp.Test_Out_Measurements__c)
                    : new Attachment();

            safetyQualityAcknowledgment =
                    loadedAttachments.get(subApp.Safety_Quality_Acknowledgment__c) != null
                    ? loadedAttachments.get(subApp.Safety_Quality_Acknowledgment__c)
                    : new Attachment();

            buildingPermit =
                    loadedAttachments.get(subApp.Building_Permit__c) != null
                    ? loadedAttachments.get(subApp.Building_Permit__c)
                    : new Attachment();

            postAdditionalDocuments =
                    loadedAttachments.get(subApp.Additional_Documents__c) != null
                    ? loadedAttachments.get(subApp.Additional_Documents__c)
                    : new Attachment();

            postPaymentReleaseAuthorization =
                    loadedAttachments.get(subApp.Payment_Release_Authorization__c) != null
                    ? loadedAttachments.get(subApp.Payment_Release_Authorization__c)
                    : new Attachment();

            postHomeEnergyScoreReportInputFile =
                    loadedAttachments.get(subApp.HES_Report_Input_File__c) != null
                    ? loadedAttachments.get(subApp.HES_Report_Input_File__c)
                    : new Attachment();

            postHomeEnergyScoreAdditionalDocuments =
                    loadedAttachments.get(subApp.HES_Additional_Documents__c) != null
                    ? loadedAttachments.get(subApp.HES_Additional_Documents__c)
                    : new Attachment();

            postGreenBuildingRegistryOptIn =
                    loadedAttachments.get(subApp.GBR_Opt_In__c) != null
                    ? loadedAttachments.get(subApp.GBR_Opt_In__c)
                    : new Attachment();

            postDeliveredSensibleEERScoresheet =
                    loadedAttachments.get(subApp.Application__r.Delivered_Sensible_EER_Scoresheet__c) != null
                    ? loadedAttachments.get(subApp.Application__r.Delivered_Sensible_EER_Scoresheet__c)
                    : new Attachment();
        }
    }

    /**
    * Build a map of attachments by application file id
    *
    * @param appFiles a list of application files with empty/non empty attachments
    * @return a map of attachments by application file id
    */
    private Map<Id, Attachment> getApplicationFileToAttachment(List<Application_File__c> appFiles) {
        Map<Id, Attachment> appFileToAttachment = new Map<Id, Attachment>();
        for (Application_File__c appFile : appFiles) {
            if (!appFile.Attachments.isEmpty()) {
                appFileToAttachment.put(appFile.Id, appFile.Attachments[0]);
            } else {
                appFileToAttachment.put(appFile.Id, new Attachment());
            }
            // Add Body field reference since we don't retrieve it from the query in order to avoid heap size
            // and view state issues.
            appFileToAttachment.get(appFile.Id).Body = null;
        }
        return appFileToAttachment;
    }

    /**
     *  Clears view state of pre application attachments
     *  To avoid overload heap size limit exception
     */
    public void clearPreApplicationViewState() {
        contractProposalSOW = new Attachment();
        homePerformanceXML = new Attachment();
        homePerformanceSystemFile = new Attachment();
        testInMeasurements = new Attachment();
        additionalDocuments = new Attachment();
        paymentReleaseAuthorization = new Attachment();
        homeEnergyScoreReportInputFile = new Attachment();
        homeEnergyScoreAdditionalDocuments = new Attachment();
        greenBuildingRegistryOptIn = new Attachment();
    }

    /**
     *  Clears view state of pre application attachments
     *  To avoid overload heap size limit exception
     */
    public void clearPostApplicationViewState() {
        clientSignedContractSOW = new Attachment();
        postHomePerformanceXML = new Attachment();
        postHomePerformanceSystemFile = new Attachment();
        testOutMeasurements = new Attachment();
        safetyQualityAcknowledgment = new Attachment();
        buildingPermit = new Attachment();
        postAdditionalDocuments = new Attachment();
        postPaymentReleaseAuthorization = new Attachment();
        postHomeEnergyScoreReportInputFile = new Attachment();
        postHomeEnergyScoreAdditionalDocuments = new Attachment();
        postGreenBuildingRegistryOptIn = new Attachment();
        postDeliveredSensibleEERScoresheet = new Attachment();
    }

    private PageReference removeAttachment(Sub_Application__c subApplication) {
        PageReference returnPage = null;
        if (this.attachToDelete != null) {
            List<Attachment> attachmentsToRemove = new List<Attachment> {contractProposalSOW, homePerformanceXML,
                    homePerformanceSystemFile, testInMeasurements, additionalDocuments, paymentReleaseAuthorization,
                    homeEnergyScoreReportInputFile, homeEnergyScoreAdditionalDocuments, greenBuildingRegistryOptIn,
                    clientSignedContractSOW, postHomePerformanceXML, postHomePerformanceSystemFile,
                    testOutMeasurements, safetyQualityAcknowledgment, buildingPermit, postAdditionalDocuments,
                    postPaymentReleaseAuthorization, postHomeEnergyScoreReportInputFile,
                    postHomeEnergyScoreAdditionalDocuments, postGreenBuildingRegistryOptIn,
                    postDeliveredSensibleEERScoresheet};

            for (Attachment attachmentToRemove : attachmentsToRemove) {
                if (attachmentToRemove.ParentId == attachToDelete) {
                    // Set Delivered_Sensible_EER_Scoresheet__c null on application in order to update it later.
                    // If we do the update here, whenever the user clicks on Next, it will redirect to the Edit view.
                    if (attachmentToRemove.Id == postDeliveredSensibleEERScoresheet.Id) {
                        application.Delivered_Sensible_EER_Scoresheet__c = null;
                    }

                    this.advanceApplicationUtility.deleteApplicationFiles(
                            new Set<Id> { String.escapeSingleQuotes(attachToDelete) }, subApplication);
                    // Add success message
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                            'Attachment was deleted successfully.'));
                    attachmentToRemove = new Attachment();
                    loadAttachments(subApplication);

                    return returnPage;
                }
            }
        }

        return returnPage;
    }

    /**
     * Remove Attachment from pre-application
     */
    public PageReference removeAttachmentPreApp() {
        return this.removeAttachment(preApplication);
    }

    /**
     * Remove Attachment from post-application
     */
    public PageReference removeAttachmentPostApp() {
        return this.removeAttachment(postApplication);
    }

    /**
     * List Pre-Application Notes
     */
    public List<Application_Note__c> getPreApplicationNotes() {
        return preApplication != null
               ? advanceApplicationUtility.listApplicationNotes(application.Id, preApplication.Id)
               : null;
    }

    /**
     * List Post-Application Notes
     */
    public List<Application_Note__c> getPostApplicationNotes() {
        return postApplication != null
               ? advanceApplicationUtility.listApplicationNotes(application.Id, postApplication.Id)
               : null;
    }

    /**
     * List Rebate Types For Rebate assignment
     */
    public List<SelectOption> getRebateTypes() {
        List<SelectOption> options = new List<SelectOption>();

        // Pre-select rebate type
        if (preApplication.Rebate_Assignment__c == null) {
            preApplication.Rebate_Assignment__c = REBATE_ASSIGNMENT_RATE_PAYEE;
            application.Rebate_Assignment__c = REBATE_ASSIGNMENT_RATE_PAYEE;
        }

        options.add(new SelectOption(REBATE_ASSIGNMENT_RATE_PAYEE,'Account Holder (PG&E Utility Service Account)'));
        options.add(new SelectOption(REBATE_ASSIGNMENT_NOT_RATE_PAYEE,
                'Non Account Holder (Landlord/Property Owner)'));
        options.add(new SelectOption(REBATE_ASSIGNMENT_CONTRACTOR_PAYEE,
                'Contractor Payee (Payment Release Authorization needs to be uploaded)'));
        return options;
    }

    /**
     * Boolean indicating if new pre-application form should be displayed or not
     */
    public Boolean getDisplayPreAppNew() {
        return (action == null || (action == ACTION_NEW && (application.Status__c == null
                || application.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS))
                || (action == ACTION_EDIT && (application.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS
                || application.Status__c == ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS))
                || (action == ACTION_DETAIL && application.Application_Step__c == 2));
    }

    /*
     * A boolean to indicate if the detail section for pre-Application should be displayed or not
     */
    public Boolean getDisplayPreAppDetailSection() {
        return (action == ACTION_EDIT && application.Status__c == ApplicationUtils.POST_INSTALL_CREATED_STATUS)
                || (action == ACTION_DETAIL && ((application.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS
                && application.Application_Step__c == 3)
                || (application.Status__c == ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS
                && application.Application_Step__c == 3)))
                || (action == ACTION_VIEW && (application.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS
                || application.Status__c == ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS
                || (application.Application_Step__c == 3
                && application.Status__c == ApplicationUtils.REJECTED_STATUS)));
    }

    /*
     * A boolean to indicate if the view section for pre-Application should be displayed or not
     */
    public Boolean getViewPreAppSection() {
        return (action == ACTION_VIEW && application.Status__c != null
                && (application.Status__c == ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS || ispre == 'true'
                || application.Status__c == ApplicationUtils.PRE_INSTALL_RESUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS
                || (application.Status__c == ApplicationUtils.REJECTED_STATUS && !hasPostInstallSubApp)
                || (application.Status__c == ApplicationUtils.CANCELED_STATUS && !hasPostInstallSubApp)));
    }

    public Boolean getViewPreAppButton() {
        return (action == ACTION_VIEW && application.Status__c != null
                && (application.Status__c == ApplicationUtils.PRE_INSTALL_CREATED_STATUS
                || application.Status__c == ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS));
    }

    public Boolean getViewPostAppButton() {
        return (action == ACTION_VIEW && application.Status__c != null
                && (application.Status__c != ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS
                && application.Status__c != ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS
                && application.Status__c != ApplicationUtils.POST_INSTALL_APPROVED_STATUS
                && application.Status__c != ApplicationUtils.REJECTED_STATUS
                && application.Status__c != ApplicationUtils.CANCELED_STATUS
                && application.Status__c != ApplicationUtils.REBATE_ISSUED_STATUS));
    }

    /**
     * Condition for post application tab be active on page load
     */
    public Boolean getPostAppTabEnabled() {
        return (application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_CREATED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_APPROVED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS
                || (application.Status__c == ApplicationUtils.REJECTED_STATUS && hasPostInstallSubApp)
                || (application.Status__c == ApplicationUtils.CANCELED_STATUS && hasPostInstallSubApp)
                || application.Status__c == ApplicationUtils.REBATE_ISSUED_STATUS);
    }

    /**
     * Condition for Post-Application tab to be displayed
     */
    public Boolean getDisplayPostAppTab() {
        return (application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_CREATED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_APPROVED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS
                || (application.Status__c == ApplicationUtils.REJECTED_STATUS && hasPostInstallSubApp)
                || (application.Status__c == ApplicationUtils.CANCELED_STATUS && hasPostInstallSubApp)
                || application.Status__c == ApplicationUtils.REBATE_ISSUED_STATUS);
    }

    public Boolean getDisplayPostAppNewSection() {
        return (action == ACTION_DETAIL
                && (application.Status__c == ApplicationUtils.PRE_INSTALL_APPROVED_STATUS || application.Application_Step__c == 4))
                || (action == ACTION_EDIT && (application.Status__c == ApplicationUtils.POST_INSTALL_CREATED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS));
    }

    /**
     * Returns if Post-Application has to be displayed or not
     */
    public Boolean getDisplayPostAppDetailSection() {
        return (action == ACTION_DETAIL && application.Application_Step__c == 5
                && (application.Status__c == ApplicationUtils.POST_INSTALL_CREATED_STATUS
                ||  application.Status__c == ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_APPROVED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS));
    }

    /**
     * Sets Test-In Date on class and pre-aplication object
     */
    public void setFormattedTestInDate(Date pDate) {
        formattedTestInDate = pDate;
        preApplication.Test_In_Date__c = pDate;
    }

    /**
     * Returns Test-In Date formatted
     * @return String
     */
    public String getFormattedTestInDate() {
        if (preApplication != null) {
            this.formattedTestInDate = preApplication.Test_In_Date__c;
        }
        if (this.formattedTestInDate != null) {
            return formattedTestInDate.format();
        }
        return null;
    }

    /**
     * Sets Test Out date on class and post-aplication object
     */
    public void setFormattedTestOutDate(Date pDate) {
        formattedTestOutDate = pDate;
        postApplication.Test_Out_Date__c = pDate;
    }

    /**
     * Returns Test Out date formatted
     * @return String
     */
    public String getFormattedTestOutDate() {
        if (postApplication != null) {
            this.formattedTestOutDate = postApplication.Test_Out_Date__c;
        }
        if (this.formattedTestOutDate != null) {
            return formattedTestOutDate.format();
        }
        return null;
    }

    /**
     * List all analysts available for the current contractor
     * @return List<SelectOption>
     */
    public List<SelectOption> getAnalysts() {
        List<SelectOption> options = new List<SelectOption>();
        List<Contact> contacts = applicationUtility.getAnalysts(account.Id);
        bpiAnalystsMap.putAll(contacts);
        for (Contact c : contacts) {
            options.add(
                new SelectOption(c.Id, (String.isNotBlank(c.FirstName)? c.LastName + ', ' + c.FirstName : c.LastName)));
        }
        return options;
    }

    /**
     * Gets all contacts that have an HPHI credential with an "Active - Verified" status, for the current account.
     *
     * @return A list of HPHI Practitioners.
     */
    public List<SelectOption> getHPHIPractitioners() {
        List<SelectOption> options = new List<SelectOption>();

        for (Contact c : advanceApplicationUtility.getHPHIPractitioners(account.Id)) {
            options.add(new SelectOption(c.Id, (c.FirstName != null ? c.LastName + ', ' + c.FirstName : c.LastName)));
        }

        return options;
    }

    /**
     * Saves BPI Analyst Contact
     */
    public void saveBPIAnalyst() {
        String errorMessage;

        // Check if BPI Analyst information is valid
        if (applicationUtility.validateBpiAnalyst(newBPIAnalyst, isBpiCertified)) {
            // Check if there is a BPI Analyst with the same first name and last name
            if (!applicationUtility.isBpiAnalystDuplicate(applicationUtility.getAnalysts(account.Id), newBPIAnalyst)) {
                selectedBPIAnalyst = applicationUtility.saveBpiAnalyst(credential, newBPIAnalyst, isBpiCertified);
                saveCredentialFile();
            } else {
                // If BPI Analyst is duplicated add an error message
                errorMessage = BIGPortalManageApplicationUtils.DUPLICATE_BPI_ANALYST_ERROR;
            }
        } else {
            // If BPI Analyst information is not valid add an error message
            errorMessage = BIGPortalManageApplicationUtils.INVALID_BPI_ANALYST_ERROR;
        }

        if (String.isNotBlank(errorMessage)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }

        newBPIAnalyst = new Contact();
        credential = new Credential__c();
    }

    /**
     * Call to the utility method that will populate and update/insert a new credential file record
     */
    private void saveCredentialFile() {
        if (String.isNotEmpty(BPI_IdCardFileName)) {
            if (applicationUtility.validateBpiFile(BPI_IdCardFileName, BPI_IdCardFileSize)) {
                BPI_IdCard = applicationUtility.saveCredentialFile(credential, BPI_IdCardFileName);
            } else {
                /* If the BPI_IdCardFileName is not empty and the file is invalid it means that there is something
                 * wrong with the javascript validation
                 */
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        BIGPortalManageApplicationUtils.BPI_FILE_ERROR));
            }
        }
    }

    /**
     * Get From PGE Portal Settings: Non-Account Owner Download Form Link
     */
    public String getNonAccountOwnerDownloadLink() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        if (settings != null && settings.HUP_Non_Account_Owner_Download_Link__c != null) {
            return settings.HUP_Non_Account_Owner_Download_Link__c;
        }
        return '';
    }

    /**
     * Get From PGE Portal Settings: Contractor Payee Download Form Link
     */
    public String getContractorPayeeDownloadLink() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        if (settings != null && settings.HUP_Contractor_Payee_Download_Link__c != null) {
            return settings.HUP_Contractor_Payee_Download_Link__c;
        }
        return '';
    }

    /**
     * If the user selected a bpi without creating a new one, we need to know if some data changed on it,
     * so... we get the whole object from a map which is filled when bpi analysts's picklist is rendered
     */
    private void saveSelectedBPIAnalyst() {
        // The user is selecting a bpi, isBpiCertified is not checked but it can still be a certified bpi.
        if (String.isNotEmpty(selectedBPIAnalyst) && bpiAnalystsMap.containsKey(selectedBPIAnalyst)) {
            applicationUtility.saveBpiAnalyst(credential, bpiAnalystsMap.get(selectedBPIAnalyst), false);
        }
    }

    /**
     * Detect if someone modified an app (by the portal or salesforce) while a user is working with it in the portal
     */
    private Boolean validSessionApplication() {
        Application__c newApp = advanceApplicationUtility.getApplication(application.Id);
        Boolean valid = true;
        if (application.LastModifiedDate < newApp.LastModifiedDate) {
            if (application.LastModifiedById != newApp.LastModifiedById) {
                valid = false;
                if (newApp.LastModifiedById != UserInfo.getUserId()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                            BIGPortalManageApplicationUtils.DATA_INTEGRITY_ERROR));
                }
            } else if (application.Status__c != newApp.Status__c) {
                valid = false;
            }
        }
        return valid;
    }

    /**
     * Determine if the application has been submitted.
     */
    private Boolean isApplicationSubmitted() {
        return (application.Status__c == ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.PRE_INSTALL_RESUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS);
    }

    public List<SelectOption> getHomeEnergyScoreContacts() {
        List<SelectOption> options = new List<SelectOption>();
        for (Contact c : applicationUtility.getHomeEnergyScoreContacts()) {
            options.add(new SelectOption(
                    c.Id,
                    (String.isNotBlank(c.FirstName) ? c.LastName + ', ' + c.FirstName : c.LastName)));
        }
        return options;
    }

    /**
     * Set a map <Id, Conctact> with the Home Energy Score contacts.
     */
    private void setHomeEnergyScoreContactsMap() {
        homeEnergyScoreContactsMap.putAll(applicationUtility.getHomeEnergyScoreContacts());
    }

    /**
     * Get the Provider_Issued_ID__c from the list of credentials of a contact.
     *
     * @return String with the Provider issued id from the selected HES Assessor.
     */
    private String getHomeEnergyScoreAssessorId() {
        return String.isNotBlank(selectedHESAssessor)
                && !homeEnergyScoreContactsMap.get(selectedHESAssessor).Credentials__r.isEmpty()
                ? homeEnergyScoreContactsMap.get(selectedHESAssessor).Credentials__r.get(0).Provider_Issued_ID__c
                : null;
    }

    /**
     * Set the lookup Home Energy Score Contact on Application__c.
     *
     * @param isPre Boolean that indicates the application phase.
     */
    private void setHomeEnergyScoreAssessorContact(Boolean isPre) {
        if (isPre) {
            application.Pre_HES_Assessor__c = selectedHESAssessor;
        } else {
            application.Post_HES_Assessor__c = selectedHESAssessor;
        }
    }

    /**
     * Set Home Energy Score Assessor Id on application record.
     *
     * @param isPre Boolean that indicates the application phase.
     */
    private void setHomeEnergyScoreAssesorId(Boolean isPre) {
        if (isPre) {
            application.Pre_HES_Assessor_ID__c = getHomeEnergyScoreAssessorId();
        } else {
            application.Post_HES_Assessor_ID__c = getHomeEnergyScoreAssessorId();
        }
    }

    /**
     * Set all HPHI fields to null and remove HPHI application file (only for post applications).
     *
     * @param application The application we have to remove hphi data from.
     * @param subApplication The sub application we have to remove hphi data from.
     * @param includeHasHPHI A flag to know if the application has any hphi practitioner credential.
     */
    private void removeHPHIData(Application__c application, Sub_Application__c subApplication, Boolean includeHasHPHI) {
        Set<String> applicationFields = new Set<String> {
                'HPHI_Practitioner__c',
                'Delivered_Sensible_EER__c',
                'Delivered_Sensible_EER_Assessment_Date__c',
                'Delivered_Sensible_EER_Scoresheet__c'};
        Set<String> subApplicationFields = new Set<String> {'HPHI_Practitioner__c'};
        // Remove post application's delivered sensible EER scoresheet file.
        if (subApplication.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID
                || subApplication.RecordTypeId == BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_POST_RECORD_TYPE_ID) {
            advanceApplicationUtility.deleteApplicationFiles(
                    new Set<Id>{application.Delivered_Sensible_EER_Scoresheet__c}, subApplication);
        }

        if (includeHasHPHI) {
            applicationFields.add('Has_HPHI__c');
            subApplicationFields.add('Has_HPHI__c');
        }
        // Nullify fields on application and sub application.
        BIGUtility.nullifySObjectFields(application, applicationFields);
        BIGUtility.nullifySObjectFields(subApplication, subApplicationFields);
    }

    /**
     * Checks if HPHI practitioner is set or not.
     *
     * @return True if HPHI practitioner is not set, otherwise false.
     */
    private Boolean isNotHPHIPractioner() {
        return String.isBlank(application.Has_HPHI__c)
                || application.Has_HPHI__c == BIGPortalAdvanceHUApplicationUtils.NO || !hasHPHIPractitioner;
    }

}