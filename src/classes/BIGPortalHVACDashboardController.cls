/**
 * This class implements the actions of the PG&E Portal ACQC program dashboard and list applications.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPortalHVACDashboardController {
    /*
     * BE CAREFUL IF YOU IMPLEMENT SOMETHING RELATED TO EDIT DATA ON BIGACQCDASHBOARD.
     * IF YOU TRY TO DO THAT YOU WON'T BE ABLE TO DO IT 'CAUSE THIS PAGE IS SET AS
     * READ ONLY. ALSO WE HANDLE THE LIST OF REBATE_APPLICTION__C BY TRANSIENT
     * VARIABLE. IT MEANS THAT YOU WON'T BE ABLE TO STORE THE STATE.
     * IT WORKS ONLY IN THE CONTEXT OF THE REQUEST.
     */

    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final String NUMBER_OF_RECORDS_PER_TABLE_ERROR = 'Too many results. Please narrow range';
    private static final String[] MONTHS =
            new String[]{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    @TestVisible
    private List<WrapperApplications> acqcApps = new List<WrapperApplications>();
    private BIGPortalUser userUtility;
    private String accountId;

    public BIGPortalHVACDashboardController() {
        userUtility = new BIGPortalUser();
        // Set account
        this.setAccountId(userUtility.getAccount().Id);
        this.setACQCApplications();
    }

    private void setACQCApplications() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        // Get Pre-Application status
        List<String> statusColorPair = null;
        if (settings != null && settings.ACQC_Application_Status_List__c != null) {
            for (String s : settings.ACQC_Application_Status_List__c.split(';')) {
                statusColorPair = s.trim().split('\\|');
                acqcApps.add(new WrapperApplications(
                        statusColorPair.get(0), (statusColorPair.size() > 1) ? statusColorPair.get(1) : '#000'));
            }
        }
    }

     /**
     * Gets a set of ACQC Application Statuses that are stored on the PG&E Portal Settings custom setting.
     *
     * @return The set of ACQC Application Statuses in JSON format.
     */
    public String getACQCStatuses() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        Set<String> statuses = new Set<String>();

        if (settings != null) {
            for (String s : BIGUtility.getListFromPattern(settings.ACQC_Application_Status_List__c, ';')) {
                List<String> statusColorPair = BIGUtility.getListFromPattern(s, '\\|');
                statuses.add(statusColorPair.get(0));
            }
        }

         return JSON.serialize(statuses);
    }

    /**
     * Gets a set of ACQC Field QC Statuses that are stored on the PG&E Portal Settings custom setting.
     *
     * @return The set of ACQC Field QC Statuses in JSON format.
     */
    public String getACQCFieldQCStatuses() {
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        Set<String> statuses = new Set<String>();

        if (settings != null) {
            statuses.addAll(BIGUtility.getListFromPattern(settings.ACQC_Field_QC_Status_List__c, ';'));
        }

        return JSON.serialize(statuses);
    }

    public List<WrapperApplications> getACQCApplications() {
        if (checkUserAccess() == null) {
            Map<String, Integer> totalApplicationsByStatus = groupAppsByStatus();

            for (WrapperApplications wp : acqcApps) {
                wp.numofApps = totalApplicationsByStatus.get(wp.status) != null
                        ? totalApplicationsByStatus.get(wp.status)
                        : 0;
            }

            return this.acqcApps;
        }

        return null;
    }

    /**
     * Navigate through the apps and group the apps by Status
     *
     * @return Map containing the number of apps group by Status
     */
    private Map<String,Integer> groupAppsByStatus() {
        Map<String, Integer> apps = new Map<String, Integer>();

        try {
            List<AggregateResult> results = [
                SELECT COUNT(Name) total, Status__c
                FROM Application__c
                WHERE Contractor__c = :accountId
                    AND RecordTypeId = :ApplicationUtils.ACQC_RECORD_TYPE
                    AND Status__c != :ApplicationUtils.REJECTED_STATUS
                    AND Status__c != null
                GROUP BY Status__c
                ];

            for (AggregateResult result : results) {
                apps.put((String)result.get('Status__c'), (Integer)result.get('total'));
            }
        } catch (QueryException e) {
            System.debug('### QueryException: ' + e.getMessage());
        }

        return apps;
    }

    public void setAccountId(String pAccId) {
        accountId = pAccId;
    }

    public Account getAccount() {
        return userUtility.getAccount();
    }

    /**
     * Checks if the user has access to the ACQC program and if it's not the case, it redirects to exception page.
     *
     * @return The current page if the user has access to the ACQC program, or a redirect to the Access Denied page.
     */
    public PageReference checkUserAccess() {
        return BIGUtility.checkACQCContactAccess(userUtility);
    }

    /**
     * Check if contact has ACQC Enrollment Program suspended.
     *
     * @return True if ACQC Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean getIsACQCSuspended() {
        return userUtility.isACQCSuspended();
    }

    /**
     * Gets the date of the first day of the month, 5 months ago from today.
     *
     * @return Date of the first day of the month, 5 months ago.
     */
    private Date getDateFiveMonthsAgo() {
        return System.today().addMonths(-5).toStartOfMonth();
    }

    /**
     * Get Measure Code as key and Rebate Types' Groups as values.
     *
     * @return Map with Rebate Type Measure Code as key and Rebate Type Group as data.
     */
    public Map<String, String> getRebateTypeGroupsByMeasureCode() {
        Map<String, String> groupsByMeasureCode = new Map<String, String>();

        try {
            for (Rebate_Type__c rebateType : [SELECT Measure_Code__c, Group__c FROM Rebate_Type__c]) {
                groupsByMeasureCode.put(rebateType.Measure_Code__c, rebateType.Group__c);
            }
        } catch (QueryException e) {
            System.debug('###Couldn\'t get rebate type groups by measure code. Message:' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return groupsByMeasureCode;
    }

    /**
     * Get the total rebate amount paid per month for the last six months.
     *
     * @return A map with month as key and amount as value.
     */
    public Map<String, Double> getTotalRebatePaidMonthly() {
        Map<String, Double> totalFinalRebateAmountByMonth = new Map<String, Double>();

        try {
            for (String monthWithYear : getLastSixMonthsWithYear()) {
                totalFinalRebateAmountByMonth.put(monthWithYear, 0);
            }

            for (AggregateResult record : [
                    SELECT SUM(Final_Rebate_Amount__c)total, CALENDAR_MONTH(Check_Date__c)month,
                        CALENDAR_YEAR(Check_Date__c)year
                    FROM Rebate_Application__c
                    WHERE Application__r.RecordTypeId = :ApplicationUtils.ACQC_RECORD_TYPE
                        AND Application__r.Status__c = :ApplicationUtils.REBATE_ISSUED_STATUS
                        AND Application__r.Contractor__c = :accountId
                        AND Check_Date__c >= :getDateFiveMonthsAgo()
                        AND Rebate_Status__c IN ('11A - Paid - D&C', 'Paid')
                        AND Project_Measure_Status_EI__c != :ApplicationUtils.REJECTED_STATUS
                    GROUP BY CALENDAR_MONTH(Check_Date__c), CALENDAR_YEAR(Check_Date__c)]) {
                String month = MONTHS[(Integer)record.get('month') - 1] + ' ' + record.get('year');
                Double totalAmount = record.get('total') != null ? (Decimal)record.get('total') : 0;
                totalFinalRebateAmountByMonth.put(month, totalAmount);
            }
        } catch (Exception e) {
            System.debug('###Error: Couldn\'t get Rebate Paid monthly. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return totalFinalRebateAmountByMonth;
    }

    /**
     * Get the total rebate amount paid for all the issued rebate applications.
     *
     * @return The sum of all the final rebate amounts for all the issued applications.
     */
    public Double getTotalRebatePaid() {
        Double totalRebatePaid = 0;

        try {
            List<AggregateResult> result = [
                    SELECT SUM(Final_Rebate_Amount__c)total
                    FROM Rebate_Application__c
                    WHERE Application__r.RecordTypeId = :ApplicationUtils.ACQC_RECORD_TYPE
                        AND Application__r.Status__c = :ApplicationUtils.REBATE_ISSUED_STATUS
                        AND Application__r.Contractor__c = :accountId
                        AND Rebate_Status__c IN ('11A - Paid - D&C', 'Paid')
                        AND Project_Measure_Status_EI__c != :ApplicationUtils.REJECTED_STATUS
                        AND Final_Rebate_Amount__c != null];
            if (!result.isEmpty()) {
                totalRebatePaid = (Decimal)result.get(0).get('total');
            }
        } catch(QueryException e) {
            System.debug('###Error. Can\'t get Rebate Application records. Message: ' + e.getMessage());
        }

        return totalRebatePaid;
    }

    /**
     * Get the names of the last 6 months with year.
     *
     * @return A list of last 6 months' names from today.
     */
    public List<String> getLastSixMonthsWithYear() {
        List<String> result = new List<String>();
        // Substract one month to match with MONTHS index.
        Date d = getDateFiveMonthsAgo().addMonths(-1);
        Integer year = d.year();
        Integer month = d.month();

        if (month == 12) {
            month = 11;
        }

        for (Integer i = 0; i < 6; i++) {
            result.add(MONTHS[month] + ' ' + year);
            month++;

            if (month == 12) {
                month = 0;
                year++;
            }
        }

        return result;
    }

    /**
     * Get the sum of Final Rebate Amount field from Rebate Applications, when its status is paid or  11A - Paid - D&C
     * and Measure Status is not Rejected and Check Date is within the past six months.
     *
     * @return A map of Group from Rebate Type as key and the sum of Final Rebate Amount as values.
     */
    public Map<String, Double> getTotalRebatePaidByRecordTypeGroup() {
        Map<String, Double> finalRebateAmountByGroup = new Map<String, Double>();

        try {
            Map<String, String> groupByMeasureCode = getRebateTypeGroupsByMeasureCode();

            for (AggregateResult rebateApplication : [
                    SELECT Measure_Code__c, SUM(Final_Rebate_Amount__c)total
                    FROM Rebate_Application__c
                    WHERE Application__r.RecordTypeId = :ApplicationUtils.ACQC_RECORD_TYPE
                        AND Application__r.Status__c = :ApplicationUtils.REBATE_ISSUED_STATUS
                        AND Application__r.Contractor__c = :accountId
                        AND Check_Date__c >= :getDateFiveMonthsAgo()
                        AND Rebate_Status__c IN ('11A - Paid - D&C', 'Paid')
                        AND Project_Measure_Status_EI__c != :ApplicationUtils.REJECTED_STATUS
                        AND Final_Rebate_Amount__c != null
                    GROUP BY Measure_Code__c]) {
                String groupName = groupByMeasureCode.get((String)rebateApplication.get('Measure_Code__c'));
                finalRebateAmountByGroup.put(groupName, (Double)rebateApplication.get('total'));
            }
        } catch (Exception e) {
            System.debug('###Couldn\'t process Rebate Applications. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return finalRebateAmountByGroup;
    }

    /**
     * Get rebate type groups for all issued Rebate Applications, where its status is paid or 11A - Paid - D&C,
     * Measure Status is not Rejected, Final Rebate Amount is not null and Check Date is within the past six months.
     *
     * @return Set of measure groups.
     */
    public Set<String> getRebateTypeGroups() {
        Set<String> groupNames = new Set<String>();
        Map<String, String> groupsByMeasureCode = getRebateTypeGroupsByMeasureCode();

        for (AggregateResult rebateApplication : [
                SELECT Measure_Code__c
                FROM Rebate_Application__c
                WHERE Application__r.RecordTypeId = :ApplicationUtils.ACQC_RECORD_TYPE
                    AND Application__r.Status__c = :ApplicationUtils.REBATE_ISSUED_STATUS
                    AND Application__r.Contractor__c = :accountId
                    AND Check_Date__c >= :getDateFiveMonthsAgo()
                    AND Rebate_Status__c IN ('11A - Paid - D&C', 'Paid')
                    AND Project_Measure_Status_EI__c != :ApplicationUtils.REJECTED_STATUS
                    AND Final_Rebate_Amount__c != null
                GROUP BY Measure_Code__c]) {
            groupNames.add(groupsByMeasureCode.get((String)rebateApplication.get('Measure_Code__c')));
        }

        return groupNames;
    }

    public List<Program_Announcement__c> getProgramAnnouncements() {
        return [
            SELECT Name, Announcement__c, Start_Date__c, URL__c
            FROM Program_Announcement__c
            WHERE (Program__c = 'ACQC' OR Program__c = 'ACQC; HUP')
                AND Type__c = 'Announcement'
                AND Start_Date__c <= :Date.today()
                AND End_Date__c >= :Date.today()
                AND Status__c = 'Active'
            ORDER BY Activity_Date__c
            ];
    }

    public List<Program_Announcement__c> getEvents() {
        return [
            SELECT Name, Announcement__c, Activity_Date__c, URL__c
            FROM Program_Announcement__c
            WHERE (Program__c = 'ACQC' OR Program__c = 'ACQC; HUP')
                AND Type__c = 'Event'
                AND Start_Date__c <= :Date.today()
                AND End_Date__c >= :Date.today()
                AND Status__c = 'Active'
            ORDER BY Activity_Date__c
            ];
    }

    public List<Quick_Reference__c> getQuickReferences() {
        return [
            SELECT Title__c, URL__c, New_window__c
            FROM Quick_Reference__c
            WHERE Program__c = 'ACQC'
            ORDER BY Sequence__c ASC
            ];
    }

    public List<Application__c> getInspections() {
        Account account = getAccount();
        return [
            SELECT Id, Building_Street_Address__c, Building_City__c, Field_QC_Date_Time__c
            FROM Application__c
            WHERE Field_QC_Date_Time__c >= :Date.today()
                AND Contractor__c = :account.Id
                AND RecordTypeId = :ApplicationUtils.ACQC_RECORD_TYPE
            ORDER BY Field_QC_Date_Time__c ASC
            ];
    }

    /**
     * Get the month and the quantity of Applications that its Rebate Applications' data were already sent to EI
     * per each last 6 months.
     *
     * @return A map with month as key and quantity of applications as values.
     */
    public Map<String, Double> getTotalApplicationsSubmittedByMonth() {
        Map<String, Double> quantityPerMonth = new Map<String, Double>();

        for (String monthWithYear : getLastSixMonthsWithYear()) {
            quantityPerMonth.put(monthWithYear, 0);
        }

        for (AggregateResult record : [
                SELECT COUNT(Id)total, CALENDAR_MONTH(Initial_VRS_Submission_Date__c)month,
                    CALENDAR_YEAR(Initial_VRS_Submission_Date__c)year
                FROM Application__c
                WHERE RecordTypeId = :ApplicationUtils.ACQC_RECORD_TYPE
                    AND Contractor__c = :accountId
                    AND Initial_VRS_Submission_Date__c >= :getDateFiveMonthsAgo()
                GROUP BY CALENDAR_MONTH(Initial_VRS_Submission_Date__c),
                    CALENDAR_YEAR(Initial_VRS_Submission_Date__c)]) {
            String month = MONTHS[(Integer)record.get('month') - 1] + ' ' + record.get('year');
            quantityPerMonth.put(month, (Decimal)record.get('total'));
        }

        return quantityPerMonth;
    }

    /**
     * Get the total number of applications whose rebate applications' data was submitted to EI.
     *
     * @return Application quantity.
     */
    public Integer getTotalApplicationsSubmitted() {
        return [
            SELECT COUNT()
            FROM Application__c
            WHERE Contractor__c = :accountId
                AND RecordTypeId = :ApplicationUtils.ACQC_RECORD_TYPE
                AND Initial_VRS_Submission_Date__c != null
            ];
    }

    @ReadOnly
    @RemoteAction
    public static ResponseWrapper getFilteredApplications(String jsonData) {
        ResponseWrapper response = new ResponseWrapper();

        try {
            Map<String, String> params = (Map<String, String>)JSON.deserialize(jsonData, Map<String, String>.class);
            PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);

            // Prevent SOQL injection.
            sanitizeInput(params);
            // Set query to get the list
            String query = ''
                + 'SELECT Id, Name, Building_Name__c, Building_Street_Address__c, Building_City__c, Building_State__c, '
                + 'Building_Zip_Code__c, Unit__r.Name, CreatedBy.Name, Status__c, Application_Submission_Date__c, '
                + 'Field_QC_Status__c, '
                + '(SELECT Check__c, Check_Date__c FROM Rebate_Applications__r ORDER BY CreatedDate DESC) '
                + 'FROM Application__c '
                + 'WHERE Contractor__c = \'' + new BIGPortalUser().getAccount().Id + '\' '
                    + 'AND RecordType.Name = \'' + params.get('recordType') + '\'';
            query += params.get('startDate') != null ? 'AND CreatedDate >= ' + params.get('startDate') : '';
            query += params.get('endDate') != null ? ' AND CreatedDate < ' + params.get('endDate') : '';
            query += params.get('status') != null
                    ? ' AND Status__c = \'' + params.get('status') + '\''
                    : ' AND Status__c != null';
            query += params.get('fieldQCStatus') != null
                    ? ' AND Field_QC_Status__c = \'' + params.get('fieldQCStatus') + '\''
                    : '';
            query += ' ORDER BY CreatedDate DESC';

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

    private static Integer getNroApp(String[] pArr) {
        Integer nroApp;
        for (String s: pArr) {
            if (s.isNumeric()) {
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
}