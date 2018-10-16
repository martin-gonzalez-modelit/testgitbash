/**
 * This class handles the batch process to retrieve data from Energy Insight org
 * to populate it on Rebate Applications on PG&E org.
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2017-07
 */
public class RebateApplicationsEnergyInsightBatch implements Database.Batchable<SObject>, Database.AllowsCallouts,
        Database.RaisesPlatformEvents {
    // Default value
    public static final Integer BATCH_SIZE = 100;
    private static final String NAMED_CREDENTIAL = 'EnergyInsight';
    private static final String APEX_JOB_COMPLETED_STATUS = 'Completed';
    private static final String SIMPLE_DATE_FORMAT = 'yyyy-MM-dd\'T\'hh:mm:ss\'z\'';
    private static final String CLASS_NAME = RebateApplicationsEnergyInsightBatch.class.getName();
    private static Map<String, Id> rebateApplicationRecordTypeNameToId;
    private String lastBatchRunDate;
    private ErrorHandlingUtil errorLog = ErrorHandlingUtil.getInstance();


    static {
        setRebateApplicationtRecordTypeMap();
    }

    /**
     * Save on a Map RecordTypeName as Key and RecordTypeId as related data.
     */
    private static void setRebateApplicationtRecordTypeMap() {
        Map<String, Schema.RecordTypeInfo> rebateApplicatonSchema =
                Schema.SObjectType.Rebate_Application__c.getRecordTypeInfosByName();
        rebateApplicationRecordTypeNameToId = new Map<String, Id>();

        for (Schema.RecordTypeInfo rtName: rebateApplicatonSchema.values()) {
            rebateApplicationRecordTypeNameToId.put(rtName.getName(),
                    rebateApplicatonSchema.get(rtName.getName()).getRecordTypeId());
        }
    }

    /**
     * Wrapper class to keep Opportunity data from Energy Insight org.
     */
    private class Opportunity {
        public Id id { get; set; }
        public String application_Number_EI { get; set; }
        public DateTime createdDate { get; set; }
        public String name { get; set; }
        public String stageName { get; set; }
        public String main_Project_ID_EI { get; set; }
        public String contractor_Company_Name_EI { get; set; }
        public String program_Code_EI { get; set; }
        public String contractor_Address_EI { get; set; }
        public String contractor_City_EI { get; set; }
        public String contractor_State_EI { get; set; }
        public String contractor_Zip_Code_EI { get; set; }
        public String contractor_Phone_EI { get; set; }
        public String contractor_Email_EI { get; set; }
        public Date project_Install_Date_EI { get; set; }
        public Date project_Start_Date_EI { get; set; }
        public String cip_Status_EI { get; set; }
        public String overall_CIP_Status { get; set; }
        public String cip_FIN_EI { get; set; }
        public Date sent_to_CIP_Date_EI { get; set; }
        public Date cip_Inspection_Date_EI { get; set; }
        public Decimal r_Total_Inc_Amount_EI { get; set; }
    }

    /**
     * Wrapper class to keep OpportunityLineItem data from Energy Insight org.
     */
    private class OpportunityLineItem {
        public Id id { get; set; }
        public Opportunity opportunity { get; set; }
        public Date cip_Actual_Insp_Date_EI { get; set; }
        public String cip_Measure_Status { get; set; }
        public String cip_Notes { get; set; }
        public Date check_Issue_Date_EI { get; set; }
        public String check_Number_EI { get; set; }
        public String equipment_Serial_Number_s { get; set; }
        public String equipment_Model_EI { get; set; }
        public String equip_Manufacturer_EI { get; set; }
        public Decimal f_KW_Savings_EI { get; set; }
        public Decimal f_KWH_Savings_EI { get; set; }
        public Decimal f_Therm_Savings_EI { get; set; }
        public Date install_Date_EI { get; set; }
        public String site_Con_F_Name_EI { get; set; }
        public String site_Con_L_Name_EI { get; set; }
        public String site_Contact_Phone_EI { get; set; }
        public String site_Address_EI { get; set; }
        public String site_City_EI { get; set; }
        public String site_State_EI { get; set; }
        public String f_Site_Zip_Code_EI { get; set; }
        public String payee_Mailing_Add_EI { get; set; }
        public String payee_Mailing_City_EI { get; set; }
        public String payee_Mailing_State { get; set; }
        public String payee_Mailing_Zip_EI { get; set; }
        public String payee_Phone_EI { get; set; }
        public String payee_EI { get; set; }
        public Decimal pc_Code_kW_Sav_EI { get; set; }
        public Decimal pc_Code_kWh_Sav_EI { get; set; }
        public Decimal pc_Code_Therm_Sav_EI { get; set; }
        public String measure_Code_EI { get; set; }
        public Date migrated_Check_Date { get; set; }
        public String migrated_Check_Number { get; set; }
        public String project_Measure_Id_EI { get; set; }
        public String measure_Comments_EI { get; set; }
        public String site_Bldg_Type_EI { get; set; }
        public String site_Vintage_Year_EI { get; set; }
        public Decimal materials_Cost_EI { get; set; }
        public Decimal provided_Incentive_EI { get; set; }
        public Decimal f_Capped_Incentive_EI { get; set; }
        public String measure_App_Type_EI { get; set; }
        public String payee_Tax_ID_enc_EI { get; set; }
        public String payee_Tax_Status_EI { get; set; }
        public String sku_ID { get; set; }
        public Decimal improvement { get; set; }
        public Decimal full_Measure_Cost_EI { get; set; }
        public Decimal inc_Measure_Cost_EI { get; set; }
        public Decimal quantity { get; set; }
        public String project_Measure_Status_EI { get; set; }
        public Date cip_Sch_Insp_Date { get; set; }
        public String cip_Measure_Status_EI { get; set; }
        public String cip_FIN_EI { get; set; }
        public String cip_Batch_Id_EI { get; set; }
        public String cip_Results_Status_ei { get; set; }
        public Boolean mandatory_CIP_EI { get; set; }
    }

    /**
     * Constructor to get last job CreatedDate field for completed jobs refered on RebateApplicationsEnergyInsightBatch.
     */
    public RebateApplicationsEnergyInsightBatch() {
        //try {
            List<AsyncApexJob> apexJobs = [
                SELECT CreatedDate
                FROM AsyncApexJob
                WHERE ApexClass.Name = :CLASS_NAME
                    AND Status = :APEX_JOB_COMPLETED_STATUS
                    AND NumberOfErrors = 0
                ORDER BY CreatedDate DESC
                LIMIT 1
                ];

            if (!apexJobs.isEmpty()) {
                this(apexJobs.get(0).CreatedDate);
            }
        /*} catch (QueryException e) {
            System.debug('Can\'t get CreatedDate from AsyncApexJob. Error: ' + e.getMessage());
        }*/
    }

    /**
     * Constructor specifying a date/datetime as string to filter later on the opportunities from EI.
     * Parses the passed in string as a DateTime first and it fallbacks to Date in case of exception.
     *
     * @param stringDate The date/datetime passed in as a string and that is formatted depending on the local
     *        date format. You may need to change the format of the date string if you have a different locale.
     */
    public RebateApplicationsEnergyInsightBatch(String stringDate) {
        //try {
            //this(DateTime.parse(stringDate));
        //} catch (TypeException e) {
            this(Date.parse(stringDate));
        //}
    }

    /**
     * Constructor specifying a date object to filter later on the opportunities from EI.
     *
     * @param filterDate The date object to filter opportunities from EI.
     */
    public RebateApplicationsEnergyInsightBatch(Date filterDate) {
        this(DateTime.newInstance(filterDate.year(), filterDate.month(), filterDate.day()));
    }

    /**
     * Constructor specifying a datetime object to filter later on the opportunities from EI.
     *
     * @param filterDateTime The datetime object to filter opportunities from EI.
     */
    public RebateApplicationsEnergyInsightBatch(DateTime filterDateTime) {
        lastBatchRunDate = filterDateTime.format(SIMPLE_DATE_FORMAT);
    }

    /**
     * Collect Application__c records with their Rebate_Application__c to pass them to execute method.
     *
     * @param BC A reference to the Database.BatchableContext object.
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(''
                /*+ 'SELECT Id, Name, '
                    + '(SELECT Application__c, Application__r.Name, Application__r.RecordType.Name, '
                    + 'Name, Rebate_Status__c, Final_Rebate_Amount__c, Check_Date__c, Contractor_Business_Name__c, '
                    + 'Check__c, Inspection_Date__c,  Inspection_Status__c, Inspection_Notes__c, EI_kW_Savings__c, '
                    + 'EI_kWh_Savings__c, EI_Therm_Savings__c, Program_Serial_Number__c, Project_Name__c, '
                    + 'Installed_Date__c, Customer_First_Name__c, Customer_Last_Name__c, Customer_Phone__c, '
                    + 'Installation_Site_Address__c, Installation_Site_City__c, Installation_Site_State__c, '
                    + 'Installation_Site_ZIP_Code__c, Payee_Mailing_Address__c, Payee_Mailing_City__c, '
                    + 'Payee_Mailing_State__c, Payee_Mailing_ZIP_Code__c, Payee_Phone__c, Measure_Code__c, '
                    + 'Quantity__c, Installation_Site_Building_Type__c, Vintage_Code__c, Total_Project_Cost__c, '
                    + 'Energy_Savings_Percentage__c, Project_Start_Date__c, Item_Incentive_Amount__c, Site_Notes__c, '
                    + 'Measure_Application_Type__c, Full_Measure_Cost__c, Incremental_Measure_Cost__c, KW_Savings__c, '
                    + 'KWH_Savings__c, Therms_Savings__c, SKU_ID__c, Project_Install_Date__c, '
                    + 'Contractor_Mailing_Address__c, Contractor_Mailing_City__c, Contractor_Mailing_State__c, '
                    + 'Contractor_Mailing_ZIP_Code__c, Contractor_Phone__c, Contractor_Email__c, '
                    + 'Payee_Federal_Tax_ID_Social_Security_Nu__c, Payee_Tax_Status__c, Manufacturer__c, '
                    + 'RTU_Condenser_Model_Number__c, Unit_Serial_Number__c, Vendor_Transaction_ID__c, '
                    + 'VRS_Application_ID__c, Project_Measure_ID__c, Make_Check_Payable_To__c, Date_Uploaded_to_VRS__c '
                    + 'FROM Rebate_Applications__r '
                    + 'WHERE Project_Name__c != null AND Vendor_Transaction_ID__c != null) '
                + 'FROM Application__c '
                + 'WHERE Id IN (SELECT Application__c FROM Rebate_Application__c '
                        + 'WHERE Project_Name__c != null AND Vendor_Transaction_ID__c != null) ');*/
                + 'SELECT Id '
                + 'FROM Application__c '
                + 'WHERE Id IN (SELECT Application__c FROM Rebate_Application__c '
                        + 'WHERE Project_Name__c != null AND Vendor_Transaction_ID__c != null)');
    }

    public class myException extends Exception {}

    /**
     * Start the processing for each block of data get it from Start method.
     *
     * @param BC a reference to the Database.BatchableContext object.
     * @param attachments list of records get it from Start method.
     */
    public void execute(Database.BatchableContext BC, List<Application__c> applications) {
        /*if (true) {
            throw new myException('cachoexceptionl lalalala');
        }*/
        // Project Measure Id as key and Rebate Application related to that Project Measure Id
        Map<String, Rebate_Application__c> rebateAppsToUpsertByProjMeasureId = new Map<String, Rebate_Application__c>();
        // Project Name from Rebate Application as key and List of Rebate Application related to that Project Name
        Map<String, List<Rebate_Application__c>> rebateAppListByProjectName =
                new Map<String, List<Rebate_Application__c>>();
        Set<String> projectNamesFromEI = new Set<String>();
        Set<String> projectIdsFromEI = new Set<String>();
        Set<String> projectMeasureIds = new Set<String>();
        Set<String> projectNames = new Set<String>();
        String projectMeasureId;
        String recordType;
        String exceptionType;
        String exceptionMsg;
        String stackTrace;
        Id applicationId;
        Savepoint sp;

        // Get all Rebate Applications related to those Applications from start method.
        List<Rebate_Application__c> rebatesApp = [
            SELECT Application__c, Application__r.Name, Application__r.RecordType.Name, Name, Rebate_Status__c,
                Final_Rebate_Amount__c, Check_Date__c, Contractor_Business_Name__c, Check__c, Inspection_Date__c,
                Inspection_Status__c, Inspection_Notes__c, EI_kW_Savings__c, Project_Name__c, EI_kWh_Savings__c,
                EI_Therm_Savings__c, Program_Serial_Number__c, Installed_Date__c, Customer_First_Name__c,
                Customer_Last_Name__c, Customer_Phone__c, Installation_Site_Address__c, Installation_Site_City__c,
                Installation_Site_State__c, Installation_Site_ZIP_Code__c, Payee_Mailing_Address__c, SKU_ID__c,
                Payee_Mailing_City__c, Payee_Mailing_State__c, Payee_Mailing_ZIP_Code__c, Payee_Phone__c,
                Measure_Code__c, Quantity__c, Installation_Site_Building_Type__c, Vintage_Code__c, KW_Savings__c,
                Total_Project_Cost__c, Energy_Savings_Percentage__c, Project_Start_Date__c, Item_Incentive_Amount__c,
                Site_Notes__c, Measure_Application_Type__c, Full_Measure_Cost__c, Incremental_Measure_Cost__c,
                KWH_Savings__c, Therms_Savings__c, Project_Install_Date__c, Contractor_Email__c, Unit_Serial_Number__c,
                Contractor_Mailing_Address__c, Contractor_Mailing_City__c, Contractor_Mailing_State__c,
                Contractor_Mailing_ZIP_Code__c, Contractor_Phone__c, Payee_Tax_Status__c, Manufacturer__c,
                Payee_Federal_Tax_ID_Social_Security_Nu__c, Make_Check_Payable_To__c, Date_Uploaded_to_VRS__c,
                RTU_Condenser_Model_Number__c, Vendor_Transaction_ID__c, VRS_Application_ID__c, Project_Measure_ID__c
            FROM Rebate_Application__c
            WHERE Application__c = :applications];

        // Loop for Rebate Applications to get Project Name and Project Measure Id.
        for (Rebate_Application__c rebateApplication : rebatesApp) {
            // Save Project Measure Id to check them later.
            projectMeasureIds.add(rebateApplication.Project_Measure_Id__c);
            projectNames.add(rebateApplication.Project_Name__c);

            if (!rebateAppListByProjectName.containsKey(rebateApplication.Project_Name__c)) {
                rebateAppListByProjectName.put(rebateApplication.Project_Name__c,
                        new List<Rebate_Application__c>());
            }

            rebateAppListByProjectName.get(rebateApplication.Project_Name__c).add(rebateApplication);
        }

        // Query for Energy Insight data.
        String opportunityLineItemQuery =
                + 'SELECT Id, Check_Issue_Date_EI__c, Check_Number_EI__c, '
                    + 'CIP_Actual_Insp_Date_EI__c, CIP_Measure_Status__c, CIP_Notes__c, F_KW_Savings_EI__c, '
                    + 'F_KWH_Savings_EI__c, F_Therm_Savings_EI__c, Install_Date_EI__c, Site_Con_F_Name_EI__c, '
                    + 'Site_Con_L_Name_EI__c, Site_Contact_Phone_EI__c, Site_Address_EI__c, Site_City_EI__c, '
                    + 'Site_State_EI__c, F_Site_Zip_Code_EI__c, Payee_Mailing_Add_EI__c, Payee_Mailing_City_EI__c, '
                    + 'Payee_Mailing_State__c, Payee_Mailing_Zip_EI__c, Payee_Phone_EI__c, Full_Measure_Cost_EI__c, '
                    + 'Measure_Comments_EI__c, Site_Bldg_Type_EI__c, Materials_Cost_EI__c, Provided_Incentive_EI__c, '
                    + 'Measure_App_Type_EI__c, Payee_Tax_ID_enc_EI__c, Payee_Tax_Status_EI__c, Measure_Code_EI__c, '
                    + 'Site_Vintage_Year_EI__c, Payee_EI__c, SKU_ID__c, Improvement__c, Project_Measure_Id_EI__c, '
                    + 'Inc_Measure_Cost_EI__c, F_Capped_Incentive_EI__c, PC_Code_kW_Sav_EI__c, PC_Code_kWh_Sav_EI__c, '
                    + 'PC_Code_Therm_Sav_EI__c, Equip_Manufacturer_EI__c, Equipment_Model_EI__c, '
                    + 'Equipment_Serial_Number_s__c, Migrated_Check_Date__c, Migrated_Check_Number__c, Quantity, '
                    + 'Project_Measure_Status_EI__c, CIP_Sch_Insp_Date__c, CIP_Measure_Status_EI__c, CIP_FIN_EI__c, '
                    + 'CIP_Batch_Id_EI__c, CIP_Results_Status_ei__c, Mandatory_CIP_EI__c, '
                    // Opportunity query section.
                    + 'Opportunity.Id, Opportunity.Name, Opportunity.StageName, Opportunity.CreatedDate, '
                    + 'Opportunity.Application_Number_EI__c, Opportunity.Program_Code_EI__c, '
                    + 'Opportunity.Main_Project_ID_EI__c, Opportunity.Contractor_Company_Name_EI__c, '
                    + 'Opportunity.Contractor_Address_EI__c, Opportunity.Contractor_City_EI__c, '
                    + 'Opportunity.Contractor_State_EI__c, Opportunity.Contractor_Zip_Code_EI__c, '
                    + 'Opportunity.Contractor_Phone_EI__c, Opportunity.Contractor_Email_EI__c, '
                    + 'Opportunity.Project_Start_Date_EI__c, Opportunity.Project_Install_Date_EI__c, '
                    + 'Opportunity.CIP_Status_EI__c, Opportunity.Overall_CIP_Status__c, Opportunity.CIP_FIN_EI__c, '
                    + 'Opportunity.Sent_to_CIP_Date_EI__c, Opportunity.CIP_Inspection_Date_EI__c, '
                    + 'Opportunity.R_Total_Inc_Amount_EI__c '
                + 'FROM OpportunityLineItem '
                + 'WHERE (Opportunity.Main_Project_ID_EI__c != null OR Opportunity.Name != null) '
                    + 'AND Opportunity.Name IN (\'' + String.join(new List<String>(projectNames), '\', \'') + '\') '
                    + 'AND (Opportunity.Main_Project_ID_EI__c LIKE \''
                    + String.join(new List<String>(projectNames), '%\' OR Opportunity.Main_Project_ID_EI__c LIKE \'')
                    + '%\') ';

        if (String.isNotBlank(lastBatchRunDate)) {
            opportunityLineItemQuery += 'AND (LastModifiedDate >= ' + lastBatchRunDate + ' '
                    + 'OR Opportunity.LastModifiedDate >= ' + lastBatchRunDate   + ' '
                    + 'OR CreatedDate >= ' + lastBatchRunDate + ' '
                    + 'OR Opportunity.CreatedDate >= ' + lastBatchRunDate + ')';
        }

        //try {
            // Do REST API call passed query EI for OpportunityLineItems.
            JSONParser parser = restApiCallEIObjects(opportunityLineItemQuery);

            // Get OpportunityLineItems to match with Rebate Applications later.
            for (OpportunityLineItem opportunityLineItem : (List<OpportunityLineItem>)parser.readValueAs(
                    List<OpportunityLineItem>.class)) {
                projectNamesFromEI.add(opportunityLineItem.Opportunity.name);
                projectIdsFromEI.add(opportunityLineItem.Opportunity.main_Project_ID_EI);
                projectMeasureId = opportunityLineItem.project_Measure_Id_EI;
                // Get Rebate Rpplications by Opportunity/Project Name and match with OpportunityLineItem.
                for (Rebate_Application__c rebateApplication : rebateAppListByProjectName.get(
                        opportunityLineItem.Opportunity.name)) {
                    // Set required information to create (if needed) a Rebate Application on variables.
                    recordType = rebateApplication.Application__r.RecordType.Name;
                    applicationId = rebateApplication.Application__c;

                    /* Check if the Project Measure Id is already in rebateAppsToUpsertByProjMeasureId to know
                     * if we need to continue wit match process or not.
                     */
                    if (!rebateAppsToUpsertByProjMeasureId.containsKey(projectMeasureId)
                            && rebateApplication.Vendor_Transaction_ID__c
                            == opportunityLineItem.Opportunity.main_Project_ID_EI) {
                        // Project Id match found, continue with match process. Priority now: Measure Code match.
                        if (String.isNotBlank(opportunityLineItem.measure_Code_EI)) {
                            if (opportunityLineItem.measure_Code_EI == rebateApplication.Measure_Code__c) {
                                // Measure Codes match, only have to find Project Measure Ids Match.
                                if (String.isNotBlank(rebateApplication.Project_Measure_Id__c)) {
                                    if (rebateApplication.Project_Measure_Id__c == projectMeasureId) {
                                        rebateAppsToUpsertByProjMeasureId.put(projectMeasureId,
                                                updateRebateApplication(rebateApplication, opportunityLineItem));
                                    }
                                } else if (!projectMeasureIds.contains(projectMeasureId)) {
                                    /* Project Measure Id is null/blank and there isn't any Rebate Application
                                     * with that Project Measure Id populated. Update Rebate Application.
                                     */
                                    rebateAppsToUpsertByProjMeasureId.put(projectMeasureId,
                                            updateRebateApplication(rebateApplication, opportunityLineItem));
                                }
                            }
                        } else {
                            /* Measure Code is null. Check if that Project Measure Id from OpportuniytLineItem
                             * is in Rebate Applications list to know if we create a new one or wait for loop
                             * to update the Rebate Application upcoming.
                             */
                            if (projectMeasureIds.contains(projectMeasureId)) {
                                // Project Measure Id is in any Rebate Applications. Priority: Project Measure Id match.
                                if (projectMeasureId == rebateApplication.Project_Measure_Id__c) {
                                    // There is a match on Project Measure Ids. Update Rebate Application.
                                    rebateAppsToUpsertByProjMeasureId.put(projectMeasureId,
                                            updateRebateApplication(rebateApplication, opportunityLineItem));
                                }
                            } else {
                                // Project Measure id not match to any Project Measure Id on Rebate App. Create new one.
                                rebateAppsToUpsertByProjMeasureId.put(projectMeasureId,
                                        createRebateApplication(opportunityLineItem, applicationId, recordType));
                            }
                        }
                    }
                }

                if (!rebateAppsToUpsertByProjMeasureId.containsKey(projectMeasureId)) {
                    // OpportuniytLineItem not matched to an existing Rebate Application, create a new one.
                    rebateAppsToUpsertByProjMeasureId.put(projectMeasureId,
                            createRebateApplication(opportunityLineItem, applicationId, recordType));
                }
            }

            sp = Database.setSavepoint();

            // Upsert all Rebate Applications processed.
            upsert rebateAppsToUpsertByProjMeasureId.values();

            // Delete all Rebate Applications processed that doesn't have a Project Measure Id populated.
            delete getRebateApplicationsWithoutProjectMeasureId(projectNames, projectNamesFromEI, projectIdsFromEI,
                    rebateAppListByProjectName);
        //} catch (DmlException e) {
            Database.rollback(sp);
            /*System.debug('Exception type caught: ' + e.getTypeName());
            System.debug('Message: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            errorLog.logDebug(
                    CLASS_NAME,
                    'Execute',
                    'An exception on execute code block has occurred: ' + e.getMessage()
                    + ' Stack Trace: ' + e.getStackTraceString(), '');

            // Insert errors into database.
            errorLog.logMessage();
        } catch (SalesforceLoginUtility.SalesforceLoginUtilityException e) {
            exceptionType = 'Exception type caught: ' + e.getTypeName();
            exceptionMsg = 'Message: ' + e.getMessage();
            stackTrace = 'Stack trace: ' + e.getStackTraceString();

            System.debug(exceptionType);
            System.debug(exceptionMsg);
            System.debug(stackTrace);
            errorLog.logDebug(
                    CLASS_NAME,
                    'Execute',
                    'An exception on execute code block has occurred: ' + e.getMessage() + ' ' + stackTrace,
                    '');

            // Insert errors into database.
            errorLog.logMessage();

            String apexJobSummary = ''
                        + '<h3>' + CLASS_NAME + ' Async Apex Job Results</h3>'
                        + '<ul>'
                        + '    <li>' + exceptionType + '</li>'
                        + '    <li>' + exceptionMsg + '</li>'
                        + '    <li>' + stackTrace + '</li>'
                        + '</ul>';
            abortJob(BC.getJobId(), apexJobSummary);
        } catch (Exception e) {
            System.debug('Exception type caught: ' + e.getTypeName());
            System.debug('Message: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            errorLog.logDebug(
                    CLASS_NAME,
                    'Execute',
                    'An exception on execute code block has occurred: ' + e.getMessage()
                    + ' Stack Trace: ' + e.getStackTraceString(), '');

            // Insert errors into database.
            errorLog.logMessage();
        }*/
    }

    /**
     * Aborts a batch apex job and sends an email with the errors caught
     *
     * @param jobId The id of the batch apex job.
     * @param apexJobSummary List of errors caught in HTML format.
     */
    private void abortJob(Id jobId, String apexJobSummary) {
        //try {
            if (String.isNotBlank(jobId)) {
                System.abortJob(jobId);

                AsyncApexJob apexJob = [
                    SELECT Id, JobType, MethodName, CreatedDate, CompletedDate, Status, ExtendedStatus, NumberOfErrors,
                        JobItemsProcessed, TotalJobItems
                    FROM AsyncApexJob
                    WHERE Id = :jobId
                    ];

                // Set email settings
                Email_Settings__c emailSettings = Email_Settings__c.getInstance(CLASS_NAME);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(emailSettings.Email_To__c.split(';'));
                mail.setOrgWideEmailAddressId(emailSettings.OrgWideEmailAddressId__c);
                mail.setSubject(emailSettings.Email_Subject__c);

                apexJobSummary += ''
                        + '<ul>'
                        + '    <li>Id: ' + apexJob.Id + '</li>'
                        + '    <li>Job Type: ' + apexJob.JobType + '</li>'
                        + '    <li>Method Name: ' + apexJob.MethodName + '</li>'
                        + '    <li>Created Date: ' + apexJob.CreatedDate + '</li>'
                        + '    <li>Completed Date: ' + apexJob.CompletedDate + '</li>'
                        + '    <li>Status: ' + apexJob.Status + '</li>'
                        + '    <li>Extended Status: ' + apexJob.ExtendedStatus + '</li>'
                        + '    <li>Total Batches: ' + apexJob.TotalJobItems + '</li>'
                        + '    <li>Batches Processed: ' + apexJob.JobItemsProcessed + '</li>'
                        + '    <li>Failures: ' + apexJob.NumberOfErrors + '</li>'
                        + '</ul>';
                mail.setHtmlBody(apexJobSummary);

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        /*} catch (QueryException e) {
            System.debug('Couldn\'t query apex job: ' + e.getMessage());
        } catch (EmailException e) {
            System.debug('Couldn\'t send email: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('An error has ocurred: ' + e.getMessage());
        }*/
    }

    /**
     * TODO: determine actions to take after batch has been processed for next releases.
     *
     * @param BC a reference to the Database.BatchableContext object.
     */
    public void finish(Database.BatchableContext BC) {
    }

    /**
     * Assign Rebate Application fields for Insert
     *
     * @param opportunityLineItem where we get the data to populate the new Rebate Application.
     * @param applicationId Application related to that new Rebate Application.
     * @param recordType Application recordType related to that new Rebate Application.
     * @return Rebate_Application__c with fields populated.
     */
    private Rebate_Application__c createRebateApplication(OpportunityLineItem opportunityLineItem,
            Id applicationId, String recordType) {
        Rebate_Application__c rebateApp = new Rebate_Application__c();
        rebateApp.Application__c = applicationId;
        // Get new Rebate Application populated with those fields that have to update/insert
        rebateApp = updateRebateApplication(rebateApp, opportunityLineItem);
        // Set RecordType on new Rebate Application based on RecordType from Application
        rebateApp.RecordTypeId = rebateApplicationRecordTypeNameToId.get(recordType);
        // Populate Rebate Application with those fields that have to insert in the new Rebate Application
        rebateApp.Measure_Code__c = opportunityLineItem.measure_Code_EI;
        rebateApp.Installed_Date__c = opportunityLineItem.install_Date_EI;
        rebateApp.Customer_First_Name__c = opportunityLineItem.site_Con_F_Name_EI;
        rebateApp.Customer_Last_Name__c = opportunityLineItem.site_Con_L_Name_EI;
        rebateApp.Customer_Phone__c = opportunityLineItem.site_Contact_Phone_EI;
        rebateApp.Installation_Site_Address__c = opportunityLineItem.site_Address_EI;
        rebateApp.Installation_Site_City__c = opportunityLineItem.site_City_EI;
        rebateApp.Installation_Site_State__c = opportunityLineItem.site_State_EI;
        rebateApp.Installation_Site_ZIP_Code__c = opportunityLineItem.f_Site_Zip_Code_EI;
        rebateApp.Payee_Mailing_Address__c = opportunityLineItem.payee_Mailing_Add_EI;
        rebateApp.Payee_Mailing_City__c = opportunityLineItem.payee_Mailing_City_EI;
        rebateApp.Payee_Mailing_State__c = opportunityLineItem.payee_Mailing_State;
        rebateApp.Payee_Mailing_ZIP_Code__c = opportunityLineItem.payee_Mailing_Zip_EI;
        rebateApp.Payee_Phone__c = opportunityLineItem.payee_Phone_EI;
        rebateApp.Site_Notes__c = opportunityLineItem.measure_Comments_EI;
        rebateApp.Installation_Site_Building_Type__c = opportunityLineItem.site_Bldg_Type_EI;
        rebateApp.Total_Project_Cost__c = opportunityLineItem.materials_Cost_EI;
        rebateApp.Item_Incentive_Amount__c = opportunityLineItem.provided_Incentive_EI;
        rebateApp.Measure_Application_Type__c = opportunityLineItem.measure_App_Type_EI;
        rebateApp.Payee_Federal_Tax_ID_Social_Security_Nu__c = opportunityLineItem.payee_Tax_ID_enc_EI;
        rebateApp.Payee_Tax_Status__c = opportunityLineItem.payee_Tax_Status_EI;
        rebateApp.Vintage_Code__c = opportunityLineItem.site_Vintage_Year_EI;
        rebateApp.Make_Check_Payable_To__c = opportunityLineItem.payee_EI;
        rebateApp.Quantity__c = String.valueOf(opportunityLineItem.quantity);
        rebateApp.SKU_ID__c = opportunityLineItem.sku_ID;
        rebateApp.Energy_Savings_Percentage__c = opportunityLineItem.improvement;
        rebateApp.Full_Measure_Cost__c = opportunityLineItem.full_Measure_Cost_EI;
        rebateApp.Incremental_Measure_Cost__c = opportunityLineItem.inc_Measure_Cost_EI;
        rebateApp.KWH_Savings__c = opportunityLineItem.pc_Code_kWh_Sav_EI;
        rebateApp.Therms_Savings__c = opportunityLineItem.pc_Code_Therm_Sav_EI;
        rebateApp.Manufacturer__c = opportunityLineItem.equip_Manufacturer_EI;
        rebateApp.RTU_Condenser_Model_Number__c = opportunityLineItem.equipment_Model_EI;
        rebateApp.Unit_Serial_Number__c = opportunityLineItem.equipment_Serial_Number_s;
        rebateApp.KW_Savings__c = opportunityLineItem.pc_Code_kW_Sav_EI;
        rebateApp.Project_Name__c = opportunityLineItem.Opportunity.name;
        rebateApp.Contractor_Business_Name__c = opportunityLineItem.Opportunity.contractor_Company_Name_EI;
        rebateApp.Contractor_Mailing_Address__c = opportunityLineItem.Opportunity.contractor_Address_EI;
        rebateApp.Contractor_Mailing_City__c = opportunityLineItem.Opportunity.contractor_City_EI;
        rebateApp.Contractor_Mailing_State__c = opportunityLineItem.Opportunity.contractor_State_EI;
        rebateApp.Contractor_Mailing_ZIP_Code__c = opportunityLineItem.Opportunity.contractor_Zip_Code_EI;
        rebateApp.Contractor_Phone__c = opportunityLineItem.Opportunity.contractor_Phone_EI;
        rebateApp.Contractor_Email__c = opportunityLineItem.Opportunity.contractor_Email_EI;
        rebateApp.Program_Serial_Number__c = opportunityLineItem.Opportunity.program_Code_EI;
        rebateApp.Project_Start_Date__c = String.valueOf(opportunityLineItem.Opportunity.project_Start_Date_EI);
        rebateApp.Project_Install_Date__c = opportunityLineItem.Opportunity.project_Install_Date_EI;

        return rebateApp;
    }

    /**
     * Assign Rebate Application fields for update.
     *
     * @param rebateApp to be updated.
     * @param opportunityLineItem where we get the data to populate the existing Rebate Application.
     * @return Rebate_Application__c with fields populated.
     */
    private Rebate_Application__c updateRebateApplication(Rebate_Application__c rebateApp,
            OpportunityLineItem opportunityLineItem) {
        rebateApp.Check_Date__c = opportunityLineItem.check_Issue_Date_EI != null
                ? opportunityLineItem.check_Issue_Date_EI
                : opportunityLineItem.migrated_Check_Date;
        rebateApp.Check__c = opportunityLineItem.check_Number_EI != null
                ? rebateApp.Check__c = opportunityLineItem.check_Number_EI
                : opportunityLineItem.migrated_Check_Number;
        rebateApp.Project_Measure_Id__c = opportunityLineItem.project_Measure_Id_EI;
        rebateApp.Inspection_Date__c = opportunityLineItem.cip_Actual_Insp_Date_EI;
        rebateApp.Inspection_Status__c = opportunityLineItem.cip_Measure_Status;
        rebateApp.Inspection_Notes__c = opportunityLineItem.cip_Notes;
        rebateApp.EI_kW_Savings__c = opportunityLineItem.f_KW_Savings_EI;
        rebateApp.EI_kWh_Savings__c = opportunityLineItem.f_KWH_Savings_EI;
        rebateApp.EI_Therm_Savings__c = opportunityLineItem.f_Therm_Savings_EI;
        rebateApp.Final_Rebate_Amount__c = opportunityLineItem.f_Capped_Incentive_EI;
        rebateApp.Project_Measure_Status_EI__c = opportunityLineItem.project_Measure_Status_EI;
        rebateApp.CIP_Sch_Insp_Date__c = opportunityLineItem.cip_Sch_Insp_Date;
        rebateApp.CIP_Measure_Status_EI__c = opportunityLineItem.cip_Measure_Status_EI;
        rebateApp.CIP_FIN_EI__c = opportunityLineItem.cip_FIN_EI;
        rebateApp.CIP_Batch_Id_EI__c = opportunityLineItem.cip_Batch_Id_EI;
        rebateApp.CIP_Results_Status_ei__c = opportunityLineItem.cip_Results_Status_ei;
        rebateApp.Mandatory_CIP_EI__c = opportunityLineItem.mandatory_CIP_EI;
        rebateApp.Vendor_Transaction_ID__c = opportunityLineItem.Opportunity.main_Project_ID_EI;
        rebateApp.Date_Uploaded_to_VRS__c =  Date.newinstance(opportunityLineItem.Opportunity.createdDate.year(),
                opportunityLineItem.Opportunity.createdDate.month(), opportunityLineItem.Opportunity.createdDate.day());
        rebateApp.Rebate_Status__c = opportunityLineItem.Opportunity.stageName;
        rebateApp.VRS_Application_ID__c = opportunityLineItem.Opportunity.application_Number_EI;
        rebateApp.CIP_Status_EI__c = opportunityLineItem.Opportunity.cip_Status_EI;
        rebateApp.Overall_CIP_Status__c = opportunityLineItem.Opportunity.overall_CIP_Status;
        rebateApp.Sent_to_CIP_Date_EI__c = opportunityLineItem.Opportunity.sent_to_CIP_Date_EI;
        rebateApp.CIP_Inspection_Date_EI__c = opportunityLineItem.Opportunity.cip_Inspection_Date_EI;
        rebateApp.R_Total_Inc_Amount_EI__c = opportunityLineItem.Opportunity.r_Total_Inc_Amount_EI;

        return rebateApp;
    }

    /**
     * Get every Rebate Application that doesn't have Project Measure Id populated.
     *
     * @param projectNames All Opportunity/Project Names of Rebate Applications that were processed.
     * @param projectNamesFromEI All Opportunity/Project Names of Opportunities that were processed.
     * @param projectIdsFromEI All Project Id of Opportunities that were processed.
     * @param rebateAppListByProjectName All Rebate Applications related to Opportunity/Project Name.
     * @return The list with the Rebate Applications without a project measure id associated.
     */
    private List<Rebate_Application__c> getRebateApplicationsWithoutProjectMeasureId(Set<String> projectNames,
            Set<String> projectNamesFromEI, Set<String> projectIdsFromEI,
            Map<String, List<Rebate_Application__c>> rebateAppListByProjectName) {
        // Check for Rebate Applications processed.
        List<Rebate_Application__c> rebateApplicationsToDelete = new List<Rebate_Application__c>();

        for (String projectNameFromApp : projectNames) {
            if (projectNamesFromEI.contains(projectNameFromApp)) {
                for (Rebate_Application__c rebateApp : rebateAppListByProjectName.get(projectNameFromApp)) {
                    if (projectIdsFromEI.contains(rebateApp.Vendor_Transaction_ID__c)
                            && String.isEmpty(rebateApp.Project_Measure_Id__c)) {
                        rebateApplicationsToDelete.add(rebateApp);
                    }
                }
            }
        }

        return rebateApplicationsToDelete;
    }

    /**
     * Make a REST API Call to Energy Insight to get the data related to a particular query.
     *
     * @param query specified the records that we want.
     * @return JSONParser with records obtained from query on it.
     */
    private JSONParser restApiCallEIObjects(String query) {
        JSONParser parser;
        SalesforceLoginUtility connection = new SalesforceLoginUtility(NAMED_CREDENTIAL);
        HttpRequest request = new HttpRequest();

        request.setTimeout(120000);
        request.setEndpoint(connection.getRestEndpoint() + '/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
        request.setMethod(HttpConstants.HttpMethod.XGET.name().removeStart('X'));
        request.setHeader(HttpConstants.HTTP_HEADER_AUTHORIZATION, 'OAuth ' + connection.getSessionId());
        // Remove __c and __r from each field in order to match with properties in the wrapper classes
        // (Opportunity and OpportunityLineItem).
        String body = (new Http()).send(request).getBody().replace('__c', '').replace('__r', '');
        parser = JSON.createParser(body);
        // Navigate through parser until reach the retrieved records.
        parser.nextToken();

        while (parser.hasCurrentToken() && !'records'.equals(parser.getCurrentName())) {
            parser.nextToken();
        }
        parser.nextToken();

        return parser;
    }
}