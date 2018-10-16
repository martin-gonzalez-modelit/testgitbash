/**
 * This controller handles BIGACQCRebateApplicationForm page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2013-06
 */
public with sharing class BIGPortalHVACCustRebateApplicController extends BIGPortalPaginationUtils {
    public static final String REBATE_ID = 'rebateIdsString';
    public static final String COMMENTS_FIELD_NAME = 'Issues';
    public static final String ADDITIONAL_COMMENTS_FIELD_NAME = 'Comments';
    public static final String EQUIPMENT_TYPE_DELAY = 'Enhanced Time Delay Relay';
    public static final String EQUIPMENT_TYPE_MOTOR = 'Replacement Blower Motor';
    public static final String MAKE_MODEL_MOTOR_OPTION = 'motorOptions';
    public static final String MAKE_MODEL_DELAY_OPTION = 'delayOptions';

    private static final String APPLICATION_FILE_HVAC_REBATE_FORM_TYPE = 'HVAC Rebate Application Form';
    private static final String APPLICATION_FILE_HVAC_COST_ESTIMATES_TYPE = 'HVAC Work - Cost Estimates';
    private static final String APPLICATION_FILE_QM_SERVICE_AGREEMENT_TYPE = 'QM Service Agreement Addendum';
    private static final String APPLICATION_FILE_SUPPLEMENTAL_DOCUMENTS_TYPE = 'Supplemental Documents';
    private static final String EQUIVALENT_MEASURE_ERROR = '<strong>Equivalent Measures:</strong><br> The same or an '
            + 'equivalent measure has already been applied to this AC unit within the last five years. Please ensure '
            + 'that the correct AC unit is selected and/or remove the following measure(s):';
    private static final String EQUIVALENT_MEASURE_SELECTED_ERROR = '<strong>Equivalent Measures:</strong><br> '
            + 'Please remove all but one of any equivalent measures. See the following:';
    private static final String APPLICATION_ERROR = 'There was an error processing your application. Please try'
            + ' again.';
    private static final String SELECT_OPTION = 'Select a Make/Model';
    private static final String REFRIGERANT_INCREASE_TXV = 'Refrigerant System Service: Increase Charge With TXV';
    private static final String REFRIGERANT_INCREASE_FIXED = 'Refrigerant System Service: Increase Charge With No TXV';
    private static final String REFRIGERANT_DECREASE_TXV = 'Refrigerant System Service: Decrease Charge With TXV';
    private static final String REFRIGERANT_DECREASE_FIXED = 'Refrigerant System Service: Decrease Charge With No TXV';
    private static final String UNIT_INDOOR_EXP_DEVICE_TXV = 'txv';
    private static final String UNIT_INDOOR_EXP_DEVICE_FIXED = 'fixed';
    private static final String CYCLE_TEST_FDSI_ACCEPTABLE = 'acceptable';
    private static final String CYCLE_TEST_POST_STG1 = 'POST STG 1';
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';

    // Map with Equipment_Type__c as a key and all make/model dependent options of it
    private static Map<String, List<String>> equipmentType = PicklistUtility.getDependentOptions('Measure__c',
            'Equipment_Type__c', 'Make_Model__c');
    private static PGE_Portal_Settings__c settings;

    private BIGPortalManageApplicationUtils applicationUtility;
    private Application__c application;
    private Id contractorId;
    private Map<Id, Rebate_Type__c> rebateTypesMap;

    public static List<String> delayDependentOptions {
        get {
            return equipmentType.get(EQUIPMENT_TYPE_DELAY);
        }
    }
    public static List<String> motorDependentOptions {
        get {
            return equipmentType.get(EQUIPMENT_TYPE_MOTOR);
        }
    }

    public String delaySelectedOption { get; set; }
    public String motorSelectedOption { get; set; }
    public List<Measure__c> measures { get; set; }
    public Boolean showQMServiceAgreement { get; set; }

    public BIGPortalHVACCustRebateApplicController() {
        // Instantiate application utility
        applicationUtility = new BIGPortalManageApplicationUtils();
        contractorId = getContractorId();
        Map<String, String> mapSelectedOption = obtainMakeModel();
        motorSelectedOption = mapSelectedOption.get(EQUIPMENT_TYPE_MOTOR);
        delaySelectedOption = mapSelectedOption.get(EQUIPMENT_TYPE_DELAY);
    }

    static {
        initCustomSetting();
    }

    private static void initCustomSetting() {
        settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);

        if (settings == null || settings.ACQC_EE_Measure_Code_List__c == null) {
            System.debug('Please define all the fields for the Custom Setting PGE Portal Settings.');
        }
    }

    /**
     * Update Last Application Submission Date on Employee Program Enrollment when the Application
     * related is submitted or resubmitted.
     *
     * @param technicianId The related Employee_Program_Enrollment__c.
     */
    private void updateTechnicianLastSubmissionDate(Id technicianId) {
        List<Employee_Program_Enrollment__c> employeeProgramsEnrollment;

        try {
            employeeProgramsEnrollment = [
                SELECT Id
                FROM Employee_Program_Enrollment__c
                WHERE Contact__c = :technicianId
                    AND Program_Enrollment__r.RecordTypeId = :ApplicationUtils.ACQC_PROGRAM_ENROLLMENT_RECORD_TYPE_ID
                ];

            for (Employee_Program_Enrollment__c employeeProgramEnrollment : employeeProgramsEnrollment) {
                employeeProgramEnrollment.Last_Application_Submission_Date__c = Datetime.now();
            }

            update employeeProgramsEnrollment;
        } catch (Exception e) {
            System.debug('Error. An Exception has occurred: ' + e.getMessage());
        }
    }

    public Attachment attachment1 {
        get {
            if (attachment1 == null) {
                attachment1 = new Attachment();
            }
            return attachment1;
            }
        set;
    }

    public Attachment attachment2 {
        get {
            if (attachment2 == null) {
                attachment2 = new Attachment();
            }
            return attachment2;
            }
        set;
    }

    public Attachment attachment3 {
        get {
            if (attachment3 == null) {
                attachment3 = new Attachment();
            }
            return attachment3;
            }
        set;
    }

    public Attachment attachment4 {
        get {
            if (attachment4 == null) {
                attachment4 = new Attachment();
            }
            return attachment4;
            }
        set;
    }

    public Integer att1size { get; set; }
    public Integer att2size { get; set; }
    public Integer att3size { get; set; }
    public Integer att4size { get; set; }

    /**
     * Checks if the user has access to the ACQC program and if it's not the case, it redirects to exception page.
     *
     * @return The current page if the user has access to the ACQC program, or a redirect to the Access Denied page.
     */
    public PageReference checkMessages() {
        PageReference redirect = BIGUtility.checkACQCContactAccess(applicationUtility.getUserUtils());

        if (redirect == null) {
            application = getApplication();
            measures = application.Measures__r;

            if (System.currentPageReference().getParameters().get('msg') == '1') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                        'This Application has been saved successfully. Please click ' +
                        '<a href="BIGACQCRebateApplications" style="margin:0;font-size:100%;text-decoration:underline;' +
                        'color:blue">here</a> to see the list of your applications'));
            } else if (System.currentPageReference().getParameters().get('msg') == '2') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                        'This Application has been submitted successfully. Please click ' +
                        '<a href="BIGACQCRebateApplications" style="margin:0;font-size:100%;text-decoration:underline;' +
                        'color:blue">here</a> to see the list of your applications'));
            } else if (System.currentPageReference().getParameters().get('msg') == '3') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                        'You have successfully resubmitted this Application. Please click ' +
                        '<a href="BIGACQCRebateApplications" style="margin:0;font-size:100%;text-decoration:underline;' +
                        'color:blue">here</a> to see the list of your applications'));
            } else if (System.currentPageReference().getParameters().get('msg') == '4') {
                // Get the rebate type groups of the equivalent measures.
                String equivalentMeasureGroups = System.currentPageReference().getParameters().get('equivalentMeasures');

                if (String.isNotBlank(equivalentMeasureGroups)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                            EQUIVALENT_MEASURE_ERROR + getEquivalentMeasureError(equivalentMeasureGroups)));
                }
            } else if (System.currentPageReference().getParameters().get('msg') == '5') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        '<strong>Your application requires attention:</strong><br> Please send details of any errors ' +
                        'encountered to acqualitycare@builditgreen.org or call (510) 306-2272.'));
            } else if (System.currentPageReference().getParameters().get('msg') == '6') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        BIGPortalManageApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_ERROR));
            } else if (System.currentPageReference().getParameters().get('msg') == '7') {
                // Get the rebate type groups of the equivalent measures.
                String equivalentMeasureGroups = System.currentPageReference().getParameters().get('equivalentMeasures');

                if (String.isNotBlank(equivalentMeasureGroups)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                            EQUIVALENT_MEASURE_SELECTED_ERROR + getEquivalentMeasureError(equivalentMeasureGroups)));
                }
            } else if (String.isNotBlank(application.Id)) {
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

                if (application.Status__c == ApplicationUtils.APPROVED_STATUS) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                            'This Application has already been approved.'));
                } else if (application.Status__c == ApplicationUtils.REBATE_ISSUED_STATUS) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                            ApplicationUtils.REBATE_ISSUED_MESSAGE));
                } else if (application.Status__c == ApplicationUtils.REJECTED_STATUS) {
                    if (additionalComments != null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                '<label class="strong">This Application has been rejected. Please ' +
                                'see the following comments: </label> ' +
                                '<label class="strong indented">' + COMMENTS_FIELD_NAME + '<p>' + comments +
                                '</p></label>' +
                                '<label class="strong indented">' + ADDITIONAL_COMMENTS_FIELD_NAME + '<p>' +
                                additionalComments + '</p></label>'));
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                '<label class="strong">This Application has been rejected. Please ' +
                                'see the following comments: </label> ' +
                                '<label class="strong indented">' + COMMENTS_FIELD_NAME + '<p>' + comments +
                                '</p></label>'));
                    }
                } else if (application.Status__c == ApplicationUtils.CORRECTION_REQUIRED_STATUS) {
                    // Display issues.
                    String message = '<label class="strong">This Application requires Contractor action. '
                            + 'Please see the following feedback for your action: </label> '
                            + '<label class="strong indented">' + COMMENTS_FIELD_NAME
                            + '<p>' + comments + '</p></label>';

                    if (String.isNotBlank(additionalComments)) {
                        // Display comments to the applicant.
                        message += '<label class="strong indented">' + ADDITIONAL_COMMENTS_FIELD_NAME
                                + '<p>' + additionalComments + '</p></label>';
                    }
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
                } else if (application.Status__c == ApplicationUtils.SUBMITTED_STATUS
                        || application.Status__c == ApplicationUtils.RESUBMITTED_STATUS) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                            'This Application is pending review.'));
                } else if (application.Status__c == ApplicationUtils.CANCELED_STATUS) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                            ApplicationUtils.CANCELED_MESSAGE));
                }
            }
        }

        return redirect;
    }

    public Application__c getApplication() {
        String appId = ApexPages.currentPage().getParameters().get('appId');
        Application__c application = new Application__c();

        try {
            if (String.isNotBlank(appId)) {
                application = [
                    SELECT Id, Name, Contractor__c, Customer_Phone__c, Customer_Email__c, Unit__r.Name,
                        Payable_to_Contractor__c, Status__c, PG_E_Sticker_Number__c, Technician__c, Notes__c,
                        Building_Name__c, Building_Street_Address__c, Building_City__c, Building_State__c,
                        Building_ZIP_Code__c, Electric_Account_Number__c, Application_Submission_Date__c,
                        Rebate_Application_Form__c, Cost_Estimate__c, QM_Service_Agreement_Addendum__c,
                        Others__c, Unit__r.FDSI_ID__c,
                        (SELECT Name, Incentive_Amount__c, Make_Model__c, Rebate_Type__r.Name,
                             Rebate_Type__r.Description__c, Rebate_Type__r.Date_Label__c
                         FROM Measures__r)
                    FROM Application__c
                    WHERE Id = :appId AND Contractor__c = :contractorId
                    ];
            }
        } catch (QueryException e) {
            System.debug(e.getTypeName() + ' : ' + e.getMessage() + ' : ' + e.getStackTraceString());
        }

        return application;
    }

    /**
     * Gets all active technicians related to ACQC program.
     *
     * @return A list with technician contacts
     */
    public List<Contact> getTechnicians() {
        List<Contact> contacts = new List<Contact>();

        try {
            List<Program_Enrollment__c> programsEnrollment = [
                SELECT Id
                FROM Program_Enrollment__c
                WHERE Account__c = :contractorId
                    AND recordTypeId = :ApplicationUtils.ACQC_PROGRAM_ENROLLMENT_RECORD_TYPE_ID
                ];

            contacts = [
                SELECT Id, Name, (SELECT Id, Last_Application_Submission_Date__c FROM Employee_Program_Enrollments__r)
                FROM Contact
                WHERE AccountId = :contractorId
                    AND Id IN (
                        SELECT Contact__c
                        FROM Employee_Program_Enrollment__c
                        WHERE Role__c includes ('Technician')
                            AND Program_Enrollment__c IN :programsEnrollment
                            AND Enrollment_Stage__c = 'Active')
                Order By Name
                ];
        } catch (QueryException e) {
            System.debug('Can\'t get Program Enrollment or Contacts. Error: ' + e.getMessage());
        }

        return contacts;
    }

    /**
     * Gets all active rebate types which haven't been retired.
     *
     * @return List of rebate types.
     */
    public List<Rebate_Type__c> getActiveNonRetiredRebateTypes() {
        Datetime now = Datetime.now();
        List<Rebate_Type__c> allRebateTypes = new List<Rebate_Type__c>();
        String queryStr = ''
            + 'SELECT Id, Name, Prerequisite__c, Rebate_Amount__c, Installation_Date_Required__c, Date_Label__c, '
                + 'Start_Install_Date__c, End_Install_Date__c, Description__c '
            + 'FROM Rebate_Type__c '
            + 'WHERE Active__c = True AND (Retirement_Date__c = null OR Retirement_Date__c > :now ';

        // If a measure type was submitted and then it expired it should continue appearing on the UI
        if (String.isNotBlank(application.Id) && application.Application_Submission_Date__c != null) {
            Datetime initialSubmissionDate = application.Application_Submission_Date__c;
            queryStr += 'OR Retirement_Date__c > :initialSubmissionDate ';
        }
        queryStr += ') Order By Display_Sequence__c ASC';

        try {
            allRebateTypes = Database.query(queryStr);
        } catch (QueryException e) {
            System.debug(e.getTypeName() + ' : ' + e.getMessage() + ' : ' + e.getStackTraceString());
        }

        return allRebateTypes;
    }

    /**
     * Gets all active and inactive rebate types which haven't been retired.
     *
     * @return List of rebate types.
     */
    public List<Rebate_Type__c> getRebateTypes() {
        Datetime now = Datetime.now();
        Map<String, Rebate_Type__c> distinctRebateTypesMap = new Map<String, Rebate_Type__c>();
        String queryStr = ''
            + 'SELECT Id, Name, Prerequisite__c, Rebate_Amount__c, Installation_Date_Required__c, Date_Label__c, '
                + 'Start_Install_Date__c, End_Install_Date__c, Active__c, Description__c '
            + 'FROM Rebate_Type__c '
            + 'WHERE (Retirement_Date__c = null OR Retirement_Date__c > :now ';

        // If a measure type was submitted and then it expired it should continue appearing on the UI
        if (String.isNotBlank(application.Id) && application.Application_Submission_Date__c != null) {
            Datetime initialSubmissionDate = application.Application_Submission_Date__c;
            queryStr += 'OR Retirement_Date__c > :initialSubmissionDate ';
        }
        queryStr += ') Order By Display_Sequence__c ASC';

        try {
            for (Rebate_Type__c rebate : Database.query(queryStr)) {
                // Create a map of distinct rebate types with the rebate type's name as its key.
                if (!distinctRebateTypesMap.containsKey(rebate.Name)) {
                    distinctRebateTypesMap.put(rebate.Name, rebate);
                } else {
                    // If the map contains the inactive rebate type, replace it with the active one.
                    if (!distinctRebateTypesMap.get(rebate.Name).Active__c && rebate.Active__c) {
                        distinctRebateTypesMap.put(rebate.Name, rebate);
                    }
                }
            }

            showQMServiceAgreement = distinctRebateTypesMap.containsKey('One-year QM Service Agreement');
        } catch (QueryException e) {
            System.debug(e.getTypeName() + ' : ' + e.getMessage() + ' : ' + e.getStackTraceString());
        }

        return distinctRebateTypesMap.values();
    }

    /**
     * Get all rebate types created.
     *
     * @return Map with Rebate Type Id as key and Rebate_Type__c as data.
     */
    public Map<Id, Rebate_Type__c> getAllRebateTypes() {
        if (rebateTypesMap == null) {
            rebateTypesMap = new Map<Id, Rebate_Type__c>([
                SELECT Id, Name, Prerequisite__c, Rebate_Amount__c, Installation_Date_Required__c, Date_Label__c,
                    Start_Install_Date__c, End_Install_Date__c, Active__c, Measure_Code__c, Description__c, Group__c,
                    Display_Sequence__c
                FROM Rebate_Type__c Order By Display_Sequence__c, End_Install_Date__c ASC
                ]);
        }

        return rebateTypesMap;
    }

    /**
     * Gets all the rebates types that are not retired yet or the ones that have been retired but the application was
     * previously submitted.
     *
     * @return List of rebates types ordered by sequence and end install date.
     */
    public List<Rebate_Type__c> getElegibleRebateTypes() {
        String queryStr = ''
                + 'SELECT Id, Name, Prerequisite__c, Rebate_Amount__c, Installation_Date_Required__c, Date_Label__c, '
                +      'Start_Install_Date__c, End_Install_Date__c, Active__c, Measure_Code__c, Retirement_Date__c, '
                +      'Description__c '
                + 'FROM Rebate_Type__c '
                + 'WHERE Retirement_Date__c = null ';

        if (application.Application_Submission_Date__c != null) {
            // Get the rebates not retired or those retired with a retirement date greater than the submission date.
            Datetime submissionDate = application.Application_Submission_Date__c;
            Set<Id> selectedRebateApplicationIds = getRebatesTypesByApplication().keySet();
            queryStr += 'OR (Retirement_Date__c > :submissionDate AND Id IN :selectedRebateApplicationIds) ';
        } else {
            // Get the rebates not retired only.
            queryStr += 'OR Retirement_Date__c > TODAY ';
        }

        queryStr += 'ORDER BY Display_Sequence__c, End_Install_Date__c ASC';

        return Database.query(queryStr);
    }

    /**
     * Get all the measure-rebate types selected by the user.
     *
     * @return Map of rebate types by id.
     */
    private Map<Id, Rebate_Type__c> getRebatesTypesByApplication() {
        Map<Id, Rebate_Type__c> rebateTypesByApp = new Map<Id, Rebate_Type__c>();

        if (String.isNotBlank(application.Id)) {
            rebateTypesByApp = new Map<Id, Rebate_Type__c>([
                SELECT Id
                FROM Rebate_Type__c
                WHERE Id IN (SELECT Rebate_Type__c FROM Measure__c WHERE Application__c = :application.Id)]);
        }

        return rebateTypesByApp;
    }

    /**
     * Gets all rebate types -active and inactive, which haven't been retired- indicating if they have been selected by
     * the user or not.
     *
     * @return Map of rebate types' names indicating if the user has selected a measure corresponding to the rebate type
     *         (indicated by the value 1) or not (indicated by the value 0). The map's key is the rebate type's name.
     */
    public Map<String, Integer> getRebateTypesUser() {
        String appId = System.currentPageReference().getParameters().get('appId');
        List<Rebate_Type__c> rebateTypes = getRebateTypes();
        Map<String, Integer> thisMap = new Map<String, Integer>();
        String rebateTypeString = System.currentPageReference().getParameters().get(REBATE_ID);
        String[] rebateTypesList;

        if (String.isNotBlank(rebateTypeString)) {
            rebateTypesList = rebateTypeString.split(',');
        } else if (appId != null) {
            return getApplicationRebateTypes(appId);
        }

        for (Rebate_Type__c rt : rebateTypes) {
            String thisName = rt.Name;
            Id thisRebateTypeId = rt.Id;
            Integer thisValue = 0;

            if (rebateTypesList != null) {
                for (String r : rebateTypesList) {
                    String userRebateType = r;
                    if (userRebateType == thisRebateTypeId) {
                        thisValue = 1;
                    }
                }
            }

            thisMap.put(thisName, thisValue);
        }

        return thisMap;
    }

    /**
     * Gets all rebate types indicating if they belong to the application or not.
     *
     * @param appId The application's id.
     * @return Map of rebate types' names indicating if it belongs to the application (indicated by the value 1) or not
     *         (indicated by the value 0). The map's key is the rebate type's name.
     */
    public Map<String, Integer> getApplicationRebateTypes(String appId) {
        Map<Id, Measure__c> measureMap = new Map<Id, Measure__c>([
            SELECT Application__c, Rebate_Type__c FROM Measure__c WHERE Application__c = :appId]);
        Map<Id, Rebate_Type__c> rebateMap = getAllRebateTypes();
        Map<String,Integer> thisMap = new Map<String,Integer>();

        for (Rebate_Type__c rt : rebateMap.values()) {
            thisMap.put(rt.Name, 0);
        }

        for (Measure__c m : measureMap.values()) {
            if (rebateMap.containsKey(m.Rebate_Type__c) && thisMap.containsKey(rebateMap.get(m.Rebate_Type__c).Name)) {
                thisMap.put(rebateMap.get(m.Rebate_Type__c).Name, 1);
            }
        }

        return thisMap;
    }

    /**
     * Get a map with a Rebate_Type__c and a Equipment_Type__c related to a measure.
     *
     * @return Map with Rebate Type as key with Make_Model__c saved related to it.
     */
    public Map<String, String> obtainMakeModel() {
        Map<String, String> thisMap = new Map<String, String>();
        String[] rts = new String[]{};
        Map<Id, Measure__c> measureMap;
        String rebateTypeString = System.currentPageReference().getParameters().get(REBATE_ID);
        String appId = System.currentPageReference().getParameters().get('appId');

        try {
            // Get all measures related to these Equipment_Type__c
            measureMap = new Map<Id, Measure__c>([
                SELECT Application__c, Installation_Date__c, Equipment_Type__c, Make_Model__c, Rebate_Type__r.Id,
                        Rebate_Type__r.Name
                FROM Measure__c
                WHERE Application__c =: appId
                    AND (Equipment_Type__c =: EQUIPMENT_TYPE_DELAY OR Equipment_Type__c =: EQUIPMENT_TYPE_MOTOR)
                ]);
        } catch (QueryException e) {
            System.debug('BIGPortalHVACCustRebateApplicController.obtainMakeModel():' + e.getStackTraceString());
        }

        if (String.isNotBlank(rebateTypeString)) {
            rts = rebateTypeString.split(',');
        }

        if (!rts.isEmpty() && !measureMap.isEmpty()) {
            measureMap = new Map<Id, Measure__c>();
            for (String rt : rts) {
                String equipmentTypeMotor = System.currentPageReference().getParameters().get(MAKE_MODEL_MOTOR_OPTION);
                String equipmentTypeDelay = System.currentPageReference().getParameters().get(MAKE_MODEL_DELAY_OPTION);

                Measure__c measure = new Measure__c();
                measure.Rebate_Type__c = rt;

                if (String.isNotBlank(equipmentTypeMotor) && rt == EQUIPMENT_TYPE_MOTOR) {
                    measure.Make_Model__c = equipmentTypeMotor;
                } else if (String.isNotBlank(equipmentTypeDelay) && rt == EQUIPMENT_TYPE_DELAY) {
                    measure.Make_Model__c = equipmentTypeDelay;
                }

                measureMap.put(rt, measure);
            }
        }

        for (Measure__c m : measureMap.values()) {
            if ((m.Rebate_Type__r.Name == EQUIPMENT_TYPE_MOTOR || m.Rebate_Type__r.Name == EQUIPMENT_TYPE_DELAY)
                    && m.Make_Model__c != null) {
                thisMap.put(m.Rebate_Type__r.Name, m.Make_Model__c);
            }
        }

        return thisMap;
    }

    public Map<String,String> getInstallationDates() {
        String appId = System.currentPageReference().getParameters().get('appId');
        Map<Id,Measure__c> measureMap = new Map<Id,Measure__c>([
            SELECT Application__c, Rebate_Type__c, Installation_Date__c
            FROM Measure__c
            WHERE Application__c = :appId]);
        Map<Id,Rebate_Type__c> rebateMap = getAllRebateTypes();
        Map<String,String> thisMap = new Map<String,String>();

        for (Rebate_Type__c rt:rebateMap.values()) {
            thisMap.put(rt.Name, '');
        }


        String[] rts = new String[]{};
        Map<Id, Rebate_Type__c> measures = getAllRebateTypes();
        String rebateTypeString = System.currentPageReference().getParameters().get(REBATE_ID);
        if (String.isNotBlank(rebateTypeString)) {
            rts = rebateTypeString.split(',');
        }
        //measure
        if (!rts.isEmpty()) {
            measureMap = new Map<Id,Measure__c>();
            for (String rt:rts) {
                String thisMeasureName = measures.get(rt).Name;
                String installationDate = System.currentPageReference().getParameters().get('installationDate' + rt);

                Measure__c measure = new Measure__c();
                measure.Rebate_Type__c = rt;
                if (String.isNotBlank(installationDate)) {
                    try {
                        measure.Installation_Date__c =
                                Date.newInstance(Integer.valueOf(installationDate.substring(6,10)),
                                        Integer.valueOf(installationDate.substring(0,2)),
                                        Integer.valueOf(installationDate.substring(3, 5)));
                    } catch (TypeException e) {
                        System.debug('### TypeException message: ' + e.getMessage());
                    }
                }
                if (thisMeasureName == 'Bonus Kicker' || thisMeasureName == 'Comprehensive Kicker') {
                    measure.Installation_Date__c = Date.today();
                }
                measureMap.put(rt, measure);
            }
        }

        for (Measure__c m : measureMap.values()) {
            if (rebateMap.containsKey(m.Rebate_Type__c)
                    && thisMap.containsKey(rebateMap.get(m.Rebate_Type__c).Name)
                    && m.Installation_Date__c != null) {
                String thisValue = Datetime.newInstance(m.Installation_Date__c, Time.newInstance(0,0,0,0))
                        .format('MM/dd/yyyy');
                thisMap.put(rebateMap.get(m.Rebate_Type__c).Name, thisValue);
            }
        }

        return thisMap;
    }

    public Map<String, Application_File__c> getApplicationFiles() {
        String appId = System.currentPageReference().getParameters().get('appId');

        List<Application_File__c> files = [
            SELECT File_Name__c, Application_File_Type__c, S3_Uploaded__c, (SELECT Id FROM Attachments)
            FROM Application_File__c
            WHERE Application_File_Type__c IN (:APPLICATION_FILE_HVAC_REBATE_FORM_TYPE,
                :APPLICATION_FILE_HVAC_COST_ESTIMATES_TYPE, :APPLICATION_FILE_QM_SERVICE_AGREEMENT_TYPE)
                AND Application__c =: appId order by CreatedDate desc
            ];

        Map<String, Application_File__c> thisMap = new Map<String, Application_File__c>();
        thisMap.put('Rebate Form', new Application_File__c());
        thisMap.put('Cost Estimate', new Application_File__c());
        thisMap.put('QM Addendum', new Application_File__c());

        for (Application_File__c file : files) {
            if (thisMap.get('Rebate Form').Id == null
                    && file.Application_File_Type__c == APPLICATION_FILE_HVAC_REBATE_FORM_TYPE) {
                thisMap.put('Rebate Form', file);
            } else if (thisMap.get('Cost Estimate').Id == null
                        && file.Application_File_Type__c == APPLICATION_FILE_HVAC_COST_ESTIMATES_TYPE) {
                thisMap.put('Cost Estimate', file);
            } else if (thisMap.get('QM Addendum').Id == null
                        && file.Application_File_Type__c == APPLICATION_FILE_QM_SERVICE_AGREEMENT_TYPE) {
                thisMap.put('QM Addendum', file);
            }
        }
        return thisMap;
    }

    public List<Application_File__c> getSupplementalDocs() {
        return [
            SELECT File_Name__c, S3_Uploaded__c, (SELECT Id FROM Attachments)
            FROM Application_File__c
            WHERE Application_File_Type__c = :APPLICATION_FILE_SUPPLEMENTAL_DOCUMENTS_TYPE
                AND Application__c = :System.currentPageReference().getParameters().get('appId')
            ORDER BY CreatedDate desc
            ];
    }

    public PageReference saveDraft() {
        if (application.Status__c == null && applicationUtility.getUserUtils().isACQCSuspended()) {
            PageReference redirect = Page.BIGACQCRebateApplicationForm;
            redirect.getParameters().put('msg','6');
            redirect.setRedirect(true);

            return redirect;
        }

        String status = (application.Status__c == ApplicationUtils.CORRECTION_REQUIRED_STATUS)
                ? ApplicationUtils.CORRECTION_REQUIRED_STATUS
                : ApplicationUtils.CREATED_STATUS;

        return saveApplication(status);
    }

    public PageReference saveRebate() {
        if (application.Status__c == null && applicationUtility.getUserUtils().isACQCSuspended()) {
            PageReference redirect = Page.BIGACQCRebateApplicationForm;
            redirect.getParameters().put('msg','6');
            redirect.setRedirect(true);

            return redirect;
        }

        String status = (application.Status__c == ApplicationUtils.CORRECTION_REQUIRED_STATUS)
            ? ApplicationUtils.RESUBMITTED_STATUS
            : ApplicationUtils.SUBMITTED_STATUS;

        return saveApplication(status);
    }

    public PageReference saveApplication(String status) {
        PageReference redirect = Page.BIGACQCRebateApplicationForm;
        redirect.setRedirect(true);

        String thisSiteName = System.currentPageReference().getParameters().get('inputName');
        String thisPhone = System.currentPageReference().getParameters().get('inputPhone');
        String thisAddress = System.currentPageReference().getParameters().get('j_id0:inputAddress');
        String thisCity = System.currentPageReference().getParameters().get('j_id0:inputCity');
        String thisState = System.currentPageReference().getParameters().get('inputState');
        String thisZip = System.currentPageReference().getParameters().get('j_id0:inputZip');
        String thisEmail = System.currentPageReference().getParameters().get('j_id0:inputEmail');
        String thisSaid = System.currentPageReference().getParameters().get('j_id0:inputSaid');
        String thisUnit = System.currentPageReference().getParameters().get('unitId');
        String thisUnitName = System.currentPageReference().getParameters().get('inputUnit');
        String thisStickerNumber = System.currentPageReference().getParameters().get('inputStickerNumber');
        String thisPayable = System.currentPageReference().getParameters().get('inputPayee');
        String thisTechnician = System.currentPageReference().getParameters().get('technician');
        String thisNotes = System.currentPageReference().getParameters().get('notes');
        String thisThermostat = System.currentPageReference().getParameters().get('thermostatSerialNumber');
        String thisEquipmentTypeMotor = System.currentPageReference().getParameters().get(MAKE_MODEL_MOTOR_OPTION);
        String thisEquipmentTypeDelay = System.currentPageReference().getParameters().get(MAKE_MODEL_DELAY_OPTION);
        Boolean thisPayee = false;
        List<String> rebateTypeIds = new List<String>();
        Map<Id, Rebate_Type__c> rebateTypesById = getAllRebateTypes();
        Review__c review;
        String rebateTypeString = System.currentPageReference().getParameters().get(REBATE_ID);

        if (String.isNotBlank(rebateTypeString)) {
            rebateTypeIds = rebateTypeString.split(',');
        }

        if (thisPayable == 'on') {
            thisPayee = true;
        }

        Integer hasError = 0;

        //attachments
        String thisAttachment1 = System.currentPageReference().getParameters().get('j_id0:rebateForm:inputFile:file');
        String thisAttachment2 = System.currentPageReference().getParameters().get('j_id0:costEstimate:inputFile:file');
        String thisAttachment3 = System.currentPageReference().getParameters().get('j_id0:qmAddendum:inputFile:file');
        String thisAttachment4 = System.currentPageReference().getParameters()
                .get('j_id0:supplementalDoc:inputFile:file');

        //validate file size
        if (String.isNotBlank(thisAttachment1)) {
            if(att1size == null || att1size > 5242880) {
                redirect.getParameters().put('f1', '1');
                hasError = 1;
            }
        }

        if (String.isNotBlank(thisAttachment2)) {
            if (att2size == null || att2size > 5242880) {
                redirect.getParameters().put('f2', '1');
                hasError = 1;
            }
        }

        if (String.isNotBlank(thisAttachment3)) {
            if (att3size == null || att3size > 5242880) {
                redirect.getParameters().put('f3', '1');
                hasError = 1;
            }
        }

        if (String.isNotBlank(thisAttachment4)) {
            if (att4size == null || att4size > 5242880) {
                redirect.getParameters().put('f4', '1');
                hasError = 1;
            }
        }

        if (hasError == 1) {
            redirect.getParameters().put('inputName', thisSiteName);
            redirect.getParameters().put('inputAddress', thisAddress);
            redirect.getParameters().put('inputCity', thisCity);
            redirect.getParameters().put('inputState', thisState);
            redirect.getParameters().put('inputZip', thisZip);
            redirect.getParameters().put('inputPhone', thisPhone);
            redirect.getParameters().put('inputEmail', thisEmail);
            redirect.getParameters().put('unitId', thisUnit);
            redirect.getParameters().put('inputUnit', thisUnitName);
            redirect.getParameters().put('msg', 'err');

            return redirect;
        }

        Integer thisSiteClimateZone;
        Decimal thisTotalUnitCapacity;

        Unit__c unitSiteData = getUnitData(thisUnit);
        thisTotalUnitCapacity = unitSiteData.Total_Unit_Capacity__c;

        application.Contractor__c = contractorId;
        application.Building_Name__c = thisSiteName;
        application.Dwelling_Unit_Name__c = thisSiteName;
        application.Building_Street_Address__c = thisAddress;
        application.Dwelling_Unit_Street_Address__c = thisAddress;
        application.Unit__c = thisUnit;
        application.Unit__r = unitSiteData;
        application.Building_City__c = thisCity;
        application.Building_State__c = thisState;
        application.Building_ZIP_Code__c = thisZip;
        application.Customer_Phone__c = thisPhone;
        application.Customer_Email__c = thisEmail;
        application.Electric_Account_Number__c = thisSaid;
        application.Payable_to_Contractor__c = thisPayee;
        application.PG_E_Sticker_Number__c = thisStickerNumber;
        application.Total_Unit_Capacity__c = thisTotalUnitCapacity;

        applicationUtility.saveBuildingAndDwellingUnitFieldsInApplication(application, thisAddress, thisCity,
                thisState, thisZip, thisSaid);

        if (thisTechnician != 'Please select one...') {
            application.Technician__c = thisTechnician;
        } else {
            application.Technician__c = null;
        }
        application.Notes__c = thisNotes;
        application.Thermostat_Serial_Number__c = thisThermostat;

        try {
            upsert application;
        } catch (DMLException e) {
            hasError = 1;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        }

        Id thisAppId = application.Id;

        //measure
        List<Measure__c> measures = new List<Measure__c>();

        for (String rebateTypeId : rebateTypeIds) {
            Rebate_Type__c rebateType = rebateTypesById.get(rebateTypeId);
            String installationDate =
                    System.currentPageReference().getParameters().get('installationDate' + rebateTypeId);
            Measure__c measure = new Measure__c();
            measure.RecordTypeId = MeasureUtils.ACQC_RECORD_TYPE;
            measure.Measure_Code__c = rebateType.Measure_Code__c;
            measure.Application__c = thisAppId;
            measure.Name = rebateType.Name;
            measure.Rebate_Type__c = rebateTypeId;
            if (String.isNotBlank(installationDate)) {
                try {
                    measure.Installation_Date__c =
                            Date.newInstance(Integer.valueOf(installationDate.substring(6,10)),
                                    Integer.valueOf(installationDate.substring(0,2)),
                                    Integer.valueOf(installationDate.substring(3, 5)));
                } catch (TypeException e) {
                    System.debug('### TypeException message: ' + e.getMessage());
                }
            }
            if (measure.Name == 'Bonus Kicker' || measure.Name == 'Comprehensive Kicker') {
                measure.Installation_Date__c = Date.today();
            }
            if (measure.Name == EQUIPMENT_TYPE_DELAY && thisEquipmentTypeDelay != SELECT_OPTION
                    && String.isNotBlank(thisEquipmentTypeDelay)) {
                measure.Equipment_Type__c = measure.Name;
                measure.Make_Model__c = thisEquipmentTypeDelay;
            }
            if (measure.Name == EQUIPMENT_TYPE_MOTOR && thisEquipmentTypeMotor != SELECT_OPTION
                    && String.isNotBlank(thisEquipmentTypeMotor)) {
                measure.Equipment_Type__c = measure.Name;
                measure.Make_Model__c = thisEquipmentTypeMotor;
            }

            measures.add(measure);
        }

        if (status == ApplicationUtils.SUBMITTED_STATUS || status == ApplicationUtils.RESUBMITTED_STATUS) {
            Set<String> equivalentMeasures = getSelectedEquivalentMeasures(measures, rebateTypesById);

            // Set error Nº7 in case we find multiples measures selected related to the same group.
            if (!equivalentMeasures.isEmpty()) {
                setEquivalentMeasuresError(equivalentMeasures, '7', redirect);
                hasError = 1;
            }

            if (hasError != 1) {
                // Check if there are multiple equivalent measures in another application with the same unit.
                equivalentMeasures = new Set<String>(
                        applicationUtility.getEquivalentMeasures(application, measures, rebateTypesById));

                // Check if there are potential equivalent measures in other application with the equivalent addresses.
                application.Flag_for_Desktop__c =
                        applicationUtility.getPotentialEquivalentMeasures(application, measures, rebateTypesById);

                // Set error Nº4 in case we find double dipping issue.
                if (!equivalentMeasures.isEmpty()) {
                    setEquivalentMeasuresError(equivalentMeasures, '4', redirect);
                    hasError = 1;
                }
            }
        }

        Application_File__c newDoc1;
        Application_File__c newDoc2;
        Application_File__c newDoc3;
        Application_File__c newDoc4;

        if (String.isNotBlank(thisAttachment1) && attachment1.body != null) {
            if (String.isNotBlank(application.Rebate_Application_Form__c)) {
                delete new Application_File__c(Id = application.Rebate_Application_Form__c);
            }

            newDoc1 = new Application_File__c(
                    Application__c = thisAppId,
                    File_Name__c = thisAttachment1,
                    Application_File_Type__c = APPLICATION_FILE_HVAC_REBATE_FORM_TYPE);
            insert newDoc1;

            attachment1.ParentId = newDoc1.Id;
            insert attachment1;

            // clears the viewstate
            attachment1 = new Attachment();
        }

        if (String.isNotBlank(thisAttachment2) && attachment2.body != null) {
            if (String.isNotBlank(application.Cost_Estimate__c)) {
                delete new Application_File__c(Id = application.Cost_Estimate__c);
            }

            newDoc2 = new Application_File__c(
                    Application__c = thisAppId,
                    File_Name__c = thisAttachment2,
                    Application_File_Type__c = APPLICATION_FILE_HVAC_COST_ESTIMATES_TYPE);
            insert newDoc2;

            attachment2.ParentId = newDoc2.Id;
            insert attachment2;

            // clears the viewstate
            attachment2 = new Attachment();
        }

        if ((String.isNotBlank(thisAttachment3) && attachment3.body != null)
                || ((status == ApplicationUtils.CREATED_STATUS || status == ApplicationUtils.SUBMITTED_STATUS)
                && application.Application_Submission_Date__c == null)) {
            // Delete previous file uploaded and remove the application file id from the application.
            if (String.isNotBlank(application.QM_Service_Agreement_Addendum__c)) {
                delete new Application_File__c(Id = application.QM_Service_Agreement_Addendum__c);
                application.QM_Service_Agreement_Addendum__c = null;
            }

            if (String.isNotBlank(thisAttachment3) && attachment3.body != null) {
                newDoc3 = new Application_File__c(
                        Application__c = thisAppId,
                        File_Name__c = thisAttachment3,
                        Application_File_Type__c = APPLICATION_FILE_QM_SERVICE_AGREEMENT_TYPE);
                insert newDoc3;

                attachment3.ParentId = newDoc3.Id;
                insert attachment3;

                // clears the viewstate
                attachment3 = new Attachment();
            }
        }

        if (String.isNotBlank(thisAttachment4) && attachment4.body != null) {
            if (String.isNotBlank(application.Others__c)) {
                delete new Application_File__c(Id = application.Others__c);
            }

            newDoc4 = new Application_File__c(
                    Application__c = thisAppId,
                    File_Name__c = thisAttachment4,
                    Application_File_Type__c = APPLICATION_FILE_SUPPLEMENTAL_DOCUMENTS_TYPE);
            insert newDoc4;

            attachment4.ParentId = newDoc4.Id;
            insert attachment4;

            // clears the viewstate
            attachment4 = new Attachment();
        }

        Savepoint sp;

        // Add attachments
        if (String.isNotBlank(thisAttachment1)) {
            application.Rebate_Application_Form__c = newDoc1.Id;
        }
        if (String.isNotBlank(thisAttachment2)) {
            application.Cost_Estimate__c = newDoc2.Id;
        }
        if (String.isNotBlank(thisAttachment3)) {
            application.QM_Service_Agreement_Addendum__c = newDoc3.Id;
        }
        if (String.isNotBlank(thisAttachment4)) {
            application.Others__c = newDoc4.Id;
        }

        try {
            // Create a savepoint while review and notes records are not created yet.
            sp = Database.setSavepoint();

            // Delete all old measures
            delete [SELECT Id FROM Measure__c WHERE Application__c = :application.Id];

            if (!rebateTypeIds.isEmpty()) {
                // Insert new measures
                insert measures;
            }
        } catch (DMLException e) {
            redirect.setRedirect(false);
            Database.rollback(sp);
            hasError = 1;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        }

        // Set application status
        application.Status__c = hasError == 0
                              ? status
                              : (application.Status__c == null || application.Status__c == ApplicationUtils.CREATED_STATUS
                                      ? ApplicationUtils.CREATED_STATUS
                                      : ApplicationUtils.CORRECTION_REQUIRED_STATUS);

        if (application.Status__c == ApplicationUtils.SUBMITTED_STATUS
                || application.Status__c == ApplicationUtils.RESUBMITTED_STATUS) {

            if (application.Status__c == ApplicationUtils.SUBMITTED_STATUS) {
                application.Application_Submission_Date__c = Datetime.now();
            } else if (application.Status__c == ApplicationUtils.RESUBMITTED_STATUS) {
                application.Desktop_Review_Status__c = ApplicationUtils.CORRECTION_PENDING_REVIEW;
            }
            // Set application's last submission date.
            application.Last_Application_Submission_Date__c = Datetime.now();
            // Set application's review.
            review = applicationUtility.setReview(application, review);
            // Update Last Submission Date for the Employee Program Enrollment.
            updateTechnicianLastSubmissionDate(thisTechnician);
        }

        redirect.getParameters().put('appId', thisAppId);

        try {
            update application;

            if (review != null) {
                insert review;
                // Create application note.
                ApplicationUtils.createApplicationNote(application);
            }
        } catch (Exception e) {
            redirect.setRedirect(false);
            Database.rollback(sp);
            hasError = 1;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        }

        if (hasError == 1) {
            // Clear msg parameter to remove previous messages.
            if (ApexPages.hasMessages()) {
                redirect.getParameters().put('msg', '');
            }
        } else {
            redirect.getParameters().put('appId', thisAppId);
            redirect.getParameters().put('msg',
                    (status == ApplicationUtils.CREATED_STATUS || status == ApplicationUtils.CORRECTION_REQUIRED_STATUS)
                            ? '1'
                            : (status == ApplicationUtils.SUBMITTED_STATUS)
                                    ? '2'
                                    : '3');
        }

        return redirect;
    }

    public Decimal getACQCIncentiveTotal() {
        String appId = System.currentPageReference().getParameters().get('appId');
        return applicationUtility.getIncentiveTotal(appId);
    }

    public Id getContractorId() {
        Id contractorId;

        try {
            contractorId = [SELECT Contact.AccountId FROM User WHERE Id = : UserInfo.getUserId()].Contact.AccountId;
        } catch (QueryException e) {
            System.debug(e.getTypeName() + ' : ' + e.getMessage() + ' : ' + e.getStackTraceString());
        }

        return contractorId;
    }

    /**
     * Get Unit and Site data based on an id.
     *
     * @return List of units.
     */
    public Unit__c getUnitData(String unitId) {
        List<Unit__c> units = new List<Unit__c>();

        try {
            units = [
                SELECT Total_Unit_Capacity__c, Site__r.Climate_Zone__c, Site__r.Name, FDSI_ID__c
                FROM Unit__c
                WHERE Id = :unitId
                    AND Site__r.Contractor__c = :contractorId
                ];
        } catch (QueryException e) {
            System.debug('Error. Couldn\'t get unit data: ' + e.getMessage());
        }

        return !units.isEmpty() ? units.get(0) : new Unit__c();
    }

    public Integer getMaximumRebate() {
        Integer result = 0;

        for (Rebate_Type__c rt : getActiveNonRetiredRebateTypes()) {
            result += Math.round(rt.Rebate_Amount__c);
        }

        return result;
    }

    public Review__c getReview() {
        String appId = System.currentPageReference().getParameters().get('appId');

        List<Review__c> reviews = [
            SELECT Id, Comments__c, Additional_Comments__c
            FROM Review__c
            WHERE Application__c = :appId ORDER BY CreatedDate DESC
            ];

        return !reviews.isEmpty() ? reviews.get(0) : new Review__c();
    }

    public List<Application_Note__c> getNotes() {
        String appId = System.currentPageReference().getParameters().get('appId');
        List<Application_Note__c> apps =  ACQCRebateApplicationService.getNotes(appId);
        return apps;
    }

    public List<Unit__c> getUnits() {
        String searchString = System.currentPageReference().getParameters().get('inputName');
        String userId = UserInfo.getUserId();
        User user = [SELECT ContactId FROM User WHERE Id = :userId limit 1];
        List<Contact> contacts = [SELECT AccountId FROM Contact WHERE Id = :user.ContactId];
        if (contacts.size() > 0 ) {
            List<Unit__c> l = new List<Unit__c>();
            String thisAccountId;
            for (Contact c:contacts) {
                thisAccountId = c.AccountId;
            }

            if (searchString == null) {
                l = [
                    SELECT Id, a.Name, a.CreatedDate, a.Site__r.Name, a.Site__r.Address_1__c, a.Site__r.Address_2__c,
                        a.Site__r.City__c, a.Site__r.State__c, a.Site__r.Zip__c, a.Site__r.Phone__c,
                        a.Site__r.Technician__c, a.Complete_Name__c, a.Make__c, a.Model__c, a.Sticker_Number__c
                    FROM Unit__c a
                    WHERE a.Site__r.Contractor__c =: thisAccountId order by a.Site__r.Name
                    ];
            } else {
                String s = '%' + searchString + '%';
                l = [
                    SELECT Id, a.Name, a.CreatedDate, a.Site__r.Name, a.Site__r.Address_1__c, a.Site__r.Address_2__c,
                        a.Site__r.City__c, a.Site__r.State__c, a.Site__r.Zip__c, a.Site__r.Phone__c,
                        a.Site__r.Technician__c, a.Complete_Name__c, a.Make__c, a.Model__c,
                        a.Sticker_Number__c
                    FROM Unit__c a
                    WHERE a.Site__r.Contractor__c =: thisAccountId
                        AND (a.Site__r.Name LIKE :s OR a.Name LIKE :s OR a.Site__r.Address_1__c LIKE :s
                            OR a.Site__r.Address_2__c LIKE :s OR a.Site__r.City__c LIKE :s
                            OR a.Site__r.State__c LIKE :s OR a.Site__r.Zip__c LIKE :s
                            OR a.Complete_Name__c LIKE :s)
                        order by a.Site__r.Name];
            }

            return l;
        } else {
            return new List<Unit__c>();
        }
    }

    public PageReference searchUnit() {
        String searchString = System.currentPageReference().getParameters().get('inputName');
        getUnits();

        PageReference pageRef = Page.BIGPortalHVACSearchCust;

        return pageRef;
    }

    public String getSearchString() {
        String test = System.currentPageReference().getParameters().get('inputName');
        return test;
    }

    public String getJSONUnits() {
        String thisAccountId = null;
        String userId = UserInfo.getUserId();
        User user = [SELECT ContactId FROM User WHERE Id = :userId limit 1];
        List<Contact> contacts = [SELECT AccountId FROM Contact WHERE Id = :user.ContactId];
        if (contacts.size() > 0) {
            List<Unit__c> l = new List<Unit__c>();
            for (Contact c:contacts) {
                thisAccountId = c.AccountId;
            }
        }
        if (this.query == null) {
            // Set query to get the list
            this.query = 'SELECT Id, a.Name, a.CreatedDate, a.Site__r.Name, a.Site__r.Address_1__c, ' +
                    'a.Site__r.Address_2__c, a.Site__r.City__c, a.Site__r.State__c, a.Site__r.Zip__c, ' +
                    'a.Site__r.Phone__c, a.Site__r.Technician__c, a.Complete_Name__c, a.Make__c, a.Model__c, ' +
                    'a.Sticker_Number__c FROM Unit__c a WHERE a.Site__r.Contractor__c = \'' + thisAccountId + '\'';
            this.orderBy = 'a.Site__r.Name';
            // Set Direction DESC
            this.direction = 'ASC';
            // Set query to pagination controller
            this.setQueryToController();
        }
        if (stdController != null) {
            // Raise the limit to return all the records.
            stdController.setPageSize(NUMBER_OF_RECORDS_JSON);
            return JSON.Serialize(stdController.getRecords());
        }

        return null;
    }

    /**
     * Get all non-applicable refrigerant system services.
     *
     * @param unit Id of the unit selected by the user.
     * @param rebates Map of all rebate type ids with their respective description as key.
     * @return List of all non-applicable refrigerant system services.
     */
    @RemoteAction
    public static List<Id> getNonApplicableRefrigerantSystemServices(Id unit, Map<String, Id> rebates) {
        Map<String, Id> nonApplicableRefrigerantsByDescription = new Map<String, Id>();

        try {
            List<Cycle_Test__c> postCycleTests = [
                SELECT Unit__r.Id, Unit__r.Indoor_Expansion_Device__c, Charge_Adjustment__c, FDSI_Diagnosis__c
                FROM Cycle_Test__c
                WHERE Unit__r.Id = :unit AND Name LIKE :'%' + CYCLE_TEST_POST_STG1 + '%'
                    AND Charge_Adjustment__c != null AND Charge_Adjustment__c != 0
                    AND Unit__r.Indoor_Expansion_Device__c IN (
                        :UNIT_INDOOR_EXP_DEVICE_TXV, :UNIT_INDOOR_EXP_DEVICE_FIXED)
                ];

            if (!postCycleTests.isEmpty()) {
                // Determine which refrigerant system service is applicable.
                Decimal chargeAdjustmentSum = 0;
                String indoorExpansionDevice = postCycleTests.get(0).Unit__r.Indoor_Expansion_Device__c;

                // Sum cycle tests' charge adjustments and filter them by acceptable diagnosis.
                // We can't include FDSI_Diagnosis__c in the WHERE clause because it's field type is a text area.
                // Since we can't use aggregate functions, sum them programmatically.
                for (Cycle_Test__c ct : postCycleTests) {
                    if (ct.FDSI_Diagnosis__c.startsWithIgnoreCase(CYCLE_TEST_FDSI_ACCEPTABLE)) {
                        chargeAdjustmentSum += ct.Charge_Adjustment__c;
                    }
                }

                Set<String> refrigerantDescriptions = new Set<String>{
                            REFRIGERANT_INCREASE_TXV,
                            REFRIGERANT_INCREASE_FIXED,
                            REFRIGERANT_DECREASE_TXV,
                            REFRIGERANT_DECREASE_FIXED};

                if (!rebates.isEmpty() && chargeAdjustmentSum != 0) {
                    // Get the refrigerant system service records.
                    for (String refrigerantDescription : refrigerantDescriptions) {
                        if (rebates.containsKey(refrigerantDescription)) {
                            nonApplicableRefrigerantsByDescription.put(
                                    refrigerantDescription,
                                    rebates.get(refrigerantDescription));
                        }
                    }

                    // Remove those refrigerant system services that are applicable.
                    // A maximum of one can be applicable at time.
                    if (!nonApplicableRefrigerantsByDescription.isEmpty()) {
                        if (chargeAdjustmentSum > 0) {
                            if (indoorExpansionDevice == UNIT_INDOOR_EXP_DEVICE_TXV) {
                                // Refrigerant System: Increase Charge with TXV.
                                nonApplicableRefrigerantsByDescription.remove(REFRIGERANT_INCREASE_TXV);
                            } else {
                                // Refrigerant System: Increase Charge with No TXV.
                                nonApplicableRefrigerantsByDescription.remove(REFRIGERANT_INCREASE_FIXED);
                            }
                        } else {
                            if (indoorExpansionDevice == UNIT_INDOOR_EXP_DEVICE_TXV) {
                                // Refrigerant System: Decrease Charge with TXV.
                                nonApplicableRefrigerantsByDescription.remove(REFRIGERANT_DECREASE_TXV);
                            } else {
                                // Refrigerant System: Decrease Charge with No TXV.
                                nonApplicableRefrigerantsByDescription.remove(REFRIGERANT_DECREASE_FIXED);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('###Error: Couldn\'t get Cycle_Test__c. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return nonApplicableRefrigerantsByDescription.values();
    }

    /**
     * Return a boolean indicating if Comprehensive Kicker measure is applicable.
     *
     * @param unitId Id of the unit selected by the user.
     * @param fdsi FDSI_ID__c field of the selected unit.
     * @param rebateTypeIds List of rebate ids of the measures selected by the user.
     * @return True if the kicker comprehensive measure is applicable.
     */
    @RemoteAction
    public static Boolean isComprehensiveKickerApplicable(Id unitId, String fdsi, List<String> rebateTypeIds) {
        Boolean result = false;
        List<String> selectedEEMeasures = new List<String>();
        Set<String> energyEfficiencyMeasureCodes = new Set<String>(settings.ACQC_EE_Measure_Code_List__c.split(';'));

        try {
            // Get the selected rebate types with their respective measure codes.
            Map<Id, Rebate_Type__c> selectedRebateTypes = new Map<Id, Rebate_Type__c>([
                SELECT Id, Measure_Code__c FROM Rebate_Type__c WHERE Id IN :rebateTypeIds]);

            // Check if measure selected by user are ee measures.
            for (String rebateTypeId : rebateTypeIds) {
                if (energyEfficiencyMeasureCodes.contains(selectedRebateTypes.get(rebateTypeId).Measure_Code__c)) {
                    selectedEEMeasures.add(rebateTypeId);
                }
            }

            if (selectedEEMeasures.size() == 1) {
                // If the user selected only one ee measure, determine if there are any other approved ee measures
                // for this unit.
                result = hasApprovedEEMeasures(unitId, fdsi);
            } else if (selectedEEMeasures.size() > 1) {
                // If the user selected at least 2 ee measures, the comprehensive kicker should be enabled.
                result = true;
            }
        } catch (Exception e) {
            System.debug('###Error: Couldn\'t Determine if Comprehensive Kicker is applicable. Message: '
                    + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return result;
    }

    /**
     * Return a boolean indicating if there are approved/rebate issued ee measures under same or equivalent unit.
     *
     * @param unitId Id of the unit selected by the user.
     * @param fdsi FDSI_ID__c field of the selected unit.
     * @return True if finds any ee measure.
     */
    private static Boolean hasApprovedEEMeasures(Id unitId, String fdsi) {
        List<Measure__c> measures = new List<Measure__c>();

        try {
            List<String> energyEfficiencyCodes = settings.ACQC_EE_Measure_Code_List__c.split(';');
            Id contractorId = new BIGPortalUser().getAccount().Id;
            // Get approved/rebate issued ee measures on apps with the same or equivalent unit selected by user.
            measures = [
                SELECT Id
                FROM Measure__c
                WHERE Measure_Code__c IN :energyEfficiencyCodes
                    AND Application__r.Status__c IN (
                        :ApplicationUtils.APPROVED_STATUS, :ApplicationUtils.REBATE_ISSUED_STATUS)
                    AND Application__r.Contractor__c = :contractorId
                    AND (Application__r.Unit__r.Id = :unitId
                        OR (Application__r.Unit__r.FDSI_ID__c != NULL AND Application__r.Unit__r.FDSI_ID__c = :fdsi))
                LIMIT 1
                ];
        } catch (Exception e) {
            System.debug('###Error: Couldn\'t get EE measures. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return !measures.isEmpty();
    }

    /**
     * Creates an error message for double dipping error.
     *
     * @param equivalentMeasures Rebate Type groups related to each double dipping measure.
     * @return Error with a list of measures that apply on double dipping.
     */
    private String getEquivalentMeasureError(String equivalentMeasures) {
        // Build the Ul list to show the duplicate measures.
        return '<ul><li>' + String.join(equivalentMeasures.split(';'), '</li><li>') + '</li></ul>';
    }

    /**
     * Sets an error at page level for equivalent measure issues.
     *
     * @param equivalentMeasureGroups List of measures we selected on portal.
     * @param messageNum The error message number to pass as a parameter to the url.
     * @param redirect The page reference to add error.
     */
    private void setEquivalentMeasuresError(Set<String> equivalentMeasureGroups, String messageNum,
            PageReference redirect) {
        application.Duplicate_Measure_Prevented_Datetime__c = Datetime.now();
        redirect.getParameters().put('equivalentMeasures', String.join(new List<String>(equivalentMeasureGroups), ';'));
        redirect.getParameters().put('msg', messageNum);
    }

    /**
     * Gets equivalent measures currently selected by portal user.
     *
     * @param measures List of measures user select via portal.
     * @param rebateTypesById List of measures user select via portal.
     * @return Groups of equivalent measures selected.
     */
    private Set<String> getSelectedEquivalentMeasures(List<Measure__c> measures,
            Map<Id, Rebate_Type__c> rebateTypesById) {
        // Auxiliary variable to check if user selected equivalent measures on portal.
        Set<String> rebateTypeGroups = new Set<String>();
        Set<String> equivalentMeasureGroups = new Set<String>();

        // Check if multiple equivalent measures were selected on portal.
        for (Measure__c measure : measures) {
            if (rebateTypesById.containsKey(measure.Rebate_Type__c)) {
                if (rebateTypeGroups.contains(rebateTypesById.get(measure.Rebate_Type__c).Group__c)) {
                    equivalentMeasureGroups.add(rebateTypesById.get(measure.Rebate_Type__c).Group__c);
                }

                rebateTypeGroups.add(rebateTypesById.get(measure.Rebate_Type__c).Group__c);
            }
        }

        return equivalentMeasureGroups;
    }

}