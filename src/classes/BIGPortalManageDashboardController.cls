/**
 * This controller handles Dashboards display.
 *
 * @author Maiquel Cabrera <maiquel.cabrera@modelitsoftware.com>
 * @author Pablo Vigil <pablo.vigil@modelitsoftware.com>
 * @since 2014-1
 */
public with sharing class BIGPortalManageDashboardController extends BIGPortalPaginationUtils {

    // Constants
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final String APPLICATION_RECORD_TYPE_NAME = 'HUP';
    private static final String ADVANCE_APPLICATION_RECORD_TYPE_NAME = 'AHU';

    // Properties
    private Map<String,WrapperApplications> appsStatusLegendColors;
    private Map<String,WrapperApplications> advanceAppsStatusLegendColors;
    private String accountId;
    private BIGPortalUser userUtility;
    private List<WrapperApplications> preApps = new List<WrapperApplications>();
    private List<WrapperApplications> postApps = new List<WrapperApplications>();
    private List<WrapperApplications> HUPApplications = new List<WrapperApplications>();

    public String programTabSelected { get; set; }
    public BIGPortalManageDashboardController controller { get; set; }

    public BIGPortalManageDashboardController() {
        userUtility = new BIGPortalUser();
        // Set account
        this.setAccountId(userUtility.getAccount().Id);
        this.setApplicationStatus();
        this.setAdvanceApplicationStatus();
        controller = this;
    }

    /**
     * Checks if the user has access to either HU or AHU programs and if it's not the case,
     * it redirects to exception page.
     *
     * @return The current page if the user has access to HU/AHU programs, or a redirect to the Access Denied page.
     */
    public PageReference checkUserAccess() {
        return BIGUtility.checkHUOrAHUContactAccess(userUtility);
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

    public List<WrapperApplications> getHUPApplicationsByStatus() {
        Boolean hup = userUtility.hasHUProgram();
        Boolean ahup = userUtility.hasAdvanceHUProgram();

        if (stdController != null && (hup || ahup)) {
            // Raise the limit to return all the records.
            stdController.setPageSize(NUMBER_OF_RECORDS_JSON);
            Map<String,List<Application__c>> apps = this.groupAppsByStatus(APPLICATION_RECORD_TYPE_NAME);

            for(WrapperApplications wp : HUPApplications) {
                wp.numofApps = apps.get(wp.status) != null ? apps.get(wp.status).size() : 0;
            }

            return HUPApplications;
        }
        return null;
    }

    public Map<String,WrapperApplications> getApplicationsByStatus() {
        if (stdController != null) {
            // Raise the limit to return all the records.
            stdController.setPageSize(NUMBER_OF_RECORDS_JSON);

            Map<String,List<Application__c>> apps = this.groupAppsByStatus(APPLICATION_RECORD_TYPE_NAME);

            for(String status : appsStatusLegendColors.keySet()) {
                appsStatusLegendColors.get(status).numofApps = apps.get(status) != null ? apps.get(status).size() : 0;
            }

            return appsStatusLegendColors;
        }
        return null;
    }

    public Map<String,WrapperApplications> getAdvanceApplicationsByStatus() {
        if (stdController != null) {
            // Raise the limit to return all the records.
            stdController.setPageSize(NUMBER_OF_RECORDS_JSON);

            Map<String,List<Application__c>> apps = this.groupAppsByStatus(ADVANCE_APPLICATION_RECORD_TYPE_NAME);

            for(String status : advanceAppsStatusLegendColors.keySet()) {
                advanceAppsStatusLegendColors.get(status).numofApps = apps.get(status) != null ? apps.get(status).size() : 0;
            }

            return advanceAppsStatusLegendColors;
        }
        return null;
    }

    /**
    *filter the advanced application list and get the PRE-APPS only.
    *@return Map<String,WrapperApplications> PRE-APPS
    */
    public String getAdvancePreApplicationsByStatus() {
        if (stdController != null) {
            // Raise the limit to return all the records.
            stdController.setPageSize(NUMBER_OF_RECORDS_JSON);

            Map<String,List<Application__c>> apps = this.groupAppsByStatus(ADVANCE_APPLICATION_RECORD_TYPE_NAME);

            for(WrapperApplications wp : preApps) {
                wp.numofApps = apps.get(wp.status) != null ? apps.get(wp.status).size() : 0;
            }

            return JSON.serialize(preApps);
        }
        return null;
    }

    /**
    *filter the advanced application list and get the POST-APPS only.
    *@return Map<String,WrapperApplications> POST-APPS
    */
    public String getAdvancePostApplicationsByStatus() {
        if (stdController != null) {
            // Raise the limit to return all the records.
            stdController.setPageSize(NUMBER_OF_RECORDS_JSON);

            Map<String,List<Application__c>> apps = this.groupAppsByStatus(ADVANCE_APPLICATION_RECORD_TYPE_NAME);

            for(WrapperApplications wp : postApps) {
                    wp.numofApps = apps.get(wp.status) != null ? apps.get(wp.status).size() : 0;
            }

            return JSON.serialize(postApps);
        }
        return null;
    }

    /**
    *Navigate through the apps and group the apps by Status
    *@param recordType indicates if the records is HUP or AHU
    *@return Map containing the apps group by Status
    */
    private Map<String,List<Application__c>> groupAppsByStatus(String recordType){
        Map<String,List<Application__c>> apps = new Map<String,List<Application__c>>();

        for (Application__c app : (List<Application__c>) stdController.getRecords()) {
            if (app.RecordType.Name == recordType) {

                if(!apps.containsKey(app.Status__c)) {
                        apps.put(app.Status__c, new List<Application__c>{app});
                } else {
                        apps.get(app.Status__c).add(app);
                }
            }
        }
        return apps;
    }

    public Integer getApplicationsSize() {
        Integer counter = 0;
        for (Application__c app : (List<Application__c>) stdController.getRecords()) {
            if (app.RecordType.Name == APPLICATION_RECORD_TYPE_NAME) {
                counter ++;
            }
        }
        return counter;
    }

    public Integer getAdvanceApplicationsSize() {
        Integer counter = 0;
        for (Application__c app : (List<Application__c>) stdController.getRecords()) {
            if (app.RecordType.Name == ADVANCE_APPLICATION_RECORD_TYPE_NAME) {
                counter ++;
            }
        }
        return counter;
    }

    public void setAccountId(String pAccId) {
        accountId = pAccId;

        if (this.query == null) {
            // Set query to get the list
            this.query = 'SELECT Id, Name, Sub_Total__c, Incentive_Total__c, Status__c, Dwelling_Unit_Name__c,' +
                               ' Dwelling_Unit_Street_Address__c, Building_City__c, Building_State__c,' +
                               ' Building_ZIP_Code__c, Dwelling_Unit_Number__c, CreatedBy.FirstName,' +
                               ' CreatedBy.LastName, RecordType.Name' +
                         ' FROM Application__c WHERE Contractor__c = \'' + accountId + '\'' +
                               ' AND ' + (getHasAdvanceHUProgram() ? '(' : '') + 'RecordType.Name = \'' +
                                APPLICATION_RECORD_TYPE_NAME + '\'' + (getHasAdvanceHUProgram() ? ' OR RecordType.Name = \'' +
                                ADVANCE_APPLICATION_RECORD_TYPE_NAME + '\')' : '');
            this.orderBy = 'Name, Dwelling_Unit_Name__c, Status__c';
            // Set Direction DESC
            this.direction = 'DESC';
            // Set query to pagination controller
            this.setQueryToController();
        }
    }

    public List<Program_Announcement__c> getProgramAnnouncements(){
        return [select Name, Announcement__c, Start_Date__c, Activity_Date__c, URL__c from Program_Announcement__c where (Program__c ='HUP' OR Program__c='ACQC; HUP') and Type__c = 'Announcement' and Start_Date__c<=:Date.today() and End_Date__c>=:Date.today() and Status__c = 'Active' order by Activity_Date__c];
    }

    public List<Program_Announcement__c> getEvents(){
        return [select Name, Announcement__c, Start_Date__c, Activity_Date__c, URL__c from Program_Announcement__c where (Program__c='HUP' OR Program__c='ACQC; HUP') and Type__c = 'Event' and Start_Date__c<=:Date.today() and End_Date__c>=:Date.today() and Status__c = 'Active' order by Activity_Date__c];
    }

    public List<Quick_Reference__c> getQuickReferences(){
        return [select Title__c, URL__c, New_window__c from Quick_Reference__c where Program__c = 'HUP' order by Sequence__c ASC];
    }

    public List<Application__c> getInspections(){
        return [
            SELECT Id, RecordType.Name, Building_Street_Address__c, Building_City__c, Field_QC_Date_Time__c
            FROM Application__c
            WHERE Field_QC_Date_Time__c>=:Date.today()
                AND (RecordType.Name =: APPLICATION_RECORD_TYPE_NAME
                        OR RecordType.Name =: ADVANCE_APPLICATION_RECORD_TYPE_NAME)
                AND Contractor__c =: accountId
            ];
    }


    private void setApplicationStatus() {
        Map<String,String> statusColors = new Map<String,String>();
        appsStatusLegendColors = new Map<String,WrapperApplications>();
        // Get Statuses from custom setting
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        if (settings != null && settings.HUP_Application_Status_List__c != null && settings.HUP_Application_Status_List__c.trim() != '') {
            List<String> statusColorPair = null;
            for (String s : settings.HUP_Application_Status_List__c.trim().split(';')) {
                statusColorPair = s.trim().split('\\|');
                WrapperApplications HUPApp = new WrapperApplications(statusColorPair.get(0),statusColorPair.size() > 1 ? statusColorPair.get(1) : '#000000');
                HUPApplications.add(HUPApp);
                statusColors.put(statusColorPair.get(0), statusColorPair.size() > 1 ? statusColorPair.get(1) : '#000000');
            }
        }
        // Populate appsStatusLegendColors to use on the UI
        for (String status : statusColors.keySet()) {
            appsStatusLegendColors.put(status, new WrapperApplications(statusColors.get(status)));
        }
    }

    private void setAdvanceApplicationStatus() {
        Map<String,String> statusColors = new Map<String,String>();
        advanceAppsStatusLegendColors = new Map<String,WrapperApplications>();

        // Get Statuses from custom setting
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        // Get Pre-Application status
        List<String> statusColorPair = null;
        if (settings != null && settings.AHU_Pre_Application_Status_List__c != null && settings.AHU_Pre_Application_Status_List__c.trim() != '') {
            for (String s : settings.AHU_Pre_Application_Status_List__c.trim().split(';')) {
                statusColorPair = s.trim().split('\\|');
                WrapperApplications preA = new WrapperApplications(statusColorPair.get(0),statusColorPair.size() > 1 ? statusColorPair.get(1) : '#000000');
                preApps.add(preA);
                statusColors.put(statusColorPair.get(0), statusColorPair.size() > 1 ? statusColorPair.get(1) : '#000000');
            }
        }
        // Get Post-Application status
        if (settings != null && settings.AHU_Post_Application_Status_List__c != null && settings.AHU_Post_Application_Status_List__c.trim() != '') {
            for (String s : settings.AHU_Post_Application_Status_List__c.trim().split(';')) {
                statusColorPair = s.trim().split('\\|');
                WrapperApplications postA = new WrapperApplications(statusColorPair.get(0),statusColorPair.size() > 1 ? statusColorPair.get(1) : '#000000');
                postApps.add(postA);
                statusColors.put(statusColorPair.get(0), statusColorPair.size() > 1 ? statusColorPair.get(1) : '#000000');
            }
        }
        // Populate appsStatusLegendColors to use on the UI
        for (String status : statusColors.keySet()) {
            advanceAppsStatusLegendColors.put(status, new WrapperApplications(statusColors.get(status)));
        }
    }

    public Class WrapperApplications {
        public String color {get; set;}
        public Integer numofApps {get; set;}
        public String status {get; set;}

        public WrapperApplications(String color) {
            this.color = color;
            this.numofApps = 0;
        }

        public WrapperApplications(String status, String color){
            this.status = status;
            this.color = color;
            this.numofApps = 0;
        }
    }

    public Boolean getHasAdvanceHUProgram() {
        return userUtility.hasAdvanceHUProgram();
    }

    public String getProgramTabSelection() {
        return userUtility.getContact().Program_Tab_Selection__c;
    }

    public PageReference saveProgramTabSelection() {
        try {
            Contact ct = userUtility.getContact();
            ct.Program_Tab_Selection__c = programTabSelected;
            update ct;
        } catch (Exception e) {
            System.debug('###: Error trying to update tab selected ' + e.getMessage());
        }

        return null;
    }
}