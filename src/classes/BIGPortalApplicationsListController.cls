/**
 * This class implements the actions of the PG&E Portal list component.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPortalApplicationsListController extends BIGPortalPaginationUtils {

    // Constants.
    private static final String APPLICATION_RECORD_TYPE_NAME = 'HUP';
    private static final String ADVANCED_APPLICATION_RECORD_TYPE_NAME = 'AHU';
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final String NUMBER_OF_RECORDS_PER_TABLE_ERROR = 'Too many results. Please narrow range';

    // Properties.
    public String accountId;
    public Boolean hasAdvancedHUProgram { get; set; }
    private BIGPortalUser userUtility;

    public BIGPortalApplicationsListController() {
        userUtility = new BIGPortalUser();
    }

    public List<Application__c> getApplications() {
        if (stdController != null) {
            return (List<Application__c>) stdController.getRecords();
        }
        return null;
    }

    /**
     * Check if contact has HU Enrollment Program suspended.
     *
     * @return True if HU Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean getIsHUSuspended() {
        return userUtility.isHUSuspended();
    }

    /**
     * Check if contact has AHU Enrollment Program suspended.
     *
     * @return True if AHU Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean getIsAHUSuspended() {
        return userUtility.isAHUSuspended();
    }

    /**
     * Check if contact has HU Enrollment Program terminated.
     *
     * @return True if HU Program Enrollment is in "Terminated" status, otherwise return false.
     */
    public Boolean getIsHUTerminated() {
        return userUtility.isHUTerminated();
    }
    

    /**
     * Gets a set of AHU Application Statuses that are stored on the PG&E Portal Settings custom setting.
     *
     * @return The set of AHU Application Statuses in JSON format.
     */
    public String getAHUPrePostStatuses() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        Set<String> statuses = new Set<String>();

        if (settings != null) {
            List<String> prePostStatuses = new List<String>(
                    BIGUtility.getListFromPattern(settings.AHU_Pre_Application_Status_List__c, ';'));
            prePostStatuses.addAll(BIGUtility.getListFromPattern(settings.AHU_Post_Application_Status_List__c, ';'));

            for (String s : prePostStatuses) {
                List<String> statusColorPair = BIGUtility.getListFromPattern(s, '\\|');
                statuses.add(statusColorPair.get(0));
            }
        }

        return JSON.serialize(statuses);
    }

    /**
     * Gets a set of HUP Application Statuses that are stored on the PG&E Portal Settings custom setting.
     *
     * @return The set of HUP Application Statuses in JSON format.
     */
    public String getHUStatuses() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        Set<String> statuses = new Set<String>();

        if (settings != null) {
            for (String s : BIGUtility.getListFromPattern(settings.HUP_Application_Status_List__c, ';')) {
                List<String> statusColorPair = BIGUtility.getListFromPattern(s, '\\|');
                statuses.add(statusColorPair.get(0));
            }
        }

        return JSON.serialize(statuses);
    }

    /**
     * Gets a set of HUP Field QC Statuses that are stored on the PG&E Portal Settings custom setting.
     *
     * @return The set of Field QC Statuses in JSON format.
     */
    public String getHUFieldQCStatuses() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        Set<String> statuses = new Set<String>();

        if (settings != null) {
            statuses.addAll(BigUtility.getListFromPattern(settings.HUP_Field_QC_Status_List__c, ';'));
        }

        return JSON.serialize(statuses);
    }

    /**
     * Gets a set of AHU Field QC Statuses that are stored on the PG&E Portal Settings custom setting.
     *
     * @return The set of Field QC Statuses in JSON format.
     */
    public String getAHUFieldQCStatuses() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        Set<String> statuses = new Set<String>();

        if (settings != null) {
            statuses.addAll(BigUtility.getListFromPattern(settings.AHU_Field_QC_Status_List__c, ';'));
        }

        return JSON.serialize(statuses);
    }

    private static Integer getNroApp(String[] pArr) {
        Integer nroApp;
        for (String s: pArr) {
            if (s.isNumeric()){
                nroApp = Integer.valueOf(s);
                break;
            }
        }
        return nroApp;
    }

    private static List<Application__c> getSortedApplicationsByName(List<Application__c> appsToSort) {
        List<Integer> numberList = new List<Integer>();
        List<Application__c> appsSorted = new List<Application__c>();
        Map<Integer, Application__c> appsMap = new Map<Integer, Application__c>();
        Integer n;

        for (Application__c app : appsToSort) {
            n = getNroApp(app.Name.split('[^0-9]'));
            numberList.add(n);
            appsMap.put(n, app);
        }

        numberList.sort();
        for (Integer i = numberList.size()-1; i >= 0; i--){
            appsSorted.add(appsMap.get(numberList.get(i)));
        }

        return appsSorted;
    }

    private static void sanitizeInput(Map<String, String> params) {
        for (String param : params.keySet()) {
            params.put(param, params.get(param) != null ? String.escapeSingleQuotes(params.get(param)) : null);
        }
    }

    public String getAccountId() {
        return accountId;
    }

    public void setAccountId(String pAccId) {
        accountId = pAccId;
        if (this.query == null) {
            // Set query to get the list
            this.query = ''
                + 'SELECT Id, Name, Sub_Total__c, Incentive_Total__c, Status__c, Preapplication_Submitted__c, '
                    + 'CreatedBy.FirstName, CreatedBy.LastName, Dwelling_Unit_Street_Address__c, Building_City__c, '
                    + 'Building_State__c, Customer_First_Name__c, Customer_Last_Name__c, Building_ZIP_Code__c, '
                    + 'Dwelling_Unit_Number__c, RecordType.Name, Application_Submission_Date__c, Field_QC_Status__c, '
                    + '(SELECT Id, Total_Incentive__c, RecordType.Name from Sub_Applications__r) '
                + 'FROM Application__c '
                + 'WHERE Contractor__c = \'' + accountId + '\' '
                    + 'AND ' + (hasAdvancedHUProgram ? '(' : '') + 'RecordType.Name = \'' + APPLICATION_RECORD_TYPE_NAME
                    + '\'';
            if (hasAdvancedHUProgram) {
                // Include Advance Applications in the query
                this.query += ' OR RecordType.Name = \'' + ADVANCED_APPLICATION_RECORD_TYPE_NAME + '\')';
            }
            // Set current quarter by default.
            query += ' AND CreatedDate = THIS_QUARTER';
            this.orderBy = 'Name, Customer_Last_Name__c, Status__c';
            // Set Direction DESC
            this.direction = 'DESC';
            // Set query to pagination controller
            this.setQueryToController();
        }
    }

    public String getProgramTabSelection() {
        return new BIGPortalUser().getContact().Program_Tab_Selection__c;
    }

    @RemoteAction
    public static void saveProgramTabSelection(String programTabSelected) {
        try {
            Contact ct = new BIGPortalUser().getContact();
            ct.Program_Tab_Selection__c = programTabSelected;
            update ct;
        } catch (Exception e) {}
    }

    @ReadOnly
    @RemoteAction
    public static ResponseWrapper getFilteredApplications(String jsonData) {
        ResponseWrapper response = new ResponseWrapper();

        try {
            Map<String, String> params = (Map<String, String>)JSON.deserialize(jsonData, Map<String,String>.class);
            PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);

            // Prevent SOQL injection.
            sanitizeInput(params);
            // Set query to get the list.
            String query = ''
                + 'SELECT Id, Name, Sub_Total__c, Incentive_Total__c, Application_Submission_Date__c, '
                    + 'Status__c, Preapplication_Submitted__c, CreatedBy.FirstName, CreatedBy.LastName, '
                    + 'Dwelling_Unit_Street_Address__c, Building_City__c, Building_State__c, '
                    + 'Customer_First_Name__c, Customer_Last_Name__c, '
                    + 'Building_ZIP_Code__c, Dwelling_Unit_Number__c, RecordType.Name, Field_QC_Status__c, '
                    + '(SELECT Id, Total_Incentive__c, RecordType.Name from Sub_Applications__r), '
                    + '(SELECT Check__c, Check_Date__c FROM Rebate_Applications__r ORDER BY CreatedDate DESC) '
                + 'FROM Application__c '
                + 'WHERE Contractor__c = \'' + new BIGPortalUser().getAccount().Id + '\' '
                    + 'AND RecordType.Name = \'' + params.get('recordType') + '\' ';
            query += params.get('startDate') != null ? 'AND CreatedDate >= ' + params.get('startDate') : '';
            query += params.get('endDate') != null ? ' AND CreatedDate < ' + params.get('endDate') : '';
            query += params.get('status') != null
                    ? ' AND Status__c = \'' + params.get('status') + '\''
                    : ' AND Status__c != null';
            query += params.get('fieldQCStatus') != null
                    ? ' AND Field_QC_Status__c = \'' + params.get('fieldQCStatus') + '\''
                    : '';
            query += ' ORDER BY Name DESC, Customer_Last_Name__c DESC, Status__c DESC';

            List<Application__c> apps = Database.query(query);

            if (apps.size() > settings.Number_Of_Records_Per_Table__c) {
                throw new QueryException(NUMBER_OF_RECORDS_PER_TABLE_ERROR);
            }

            response.results = getSortedApplicationsByName(apps);
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = e.getMessage();
        }

        return response;
    }
}