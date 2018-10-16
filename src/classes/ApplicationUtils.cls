/**
 * This class contains functionality for populating fields both on the Application and other objects that are dependent
 * upon fields on the Application, it's children, and/or other closely related objects.
 * @author Camilo Herbert (camilo.herbert@modelitsoftware.com)
 * @since 2013-12
 * @author Jordan Dunn (jdunn@builditgreen.org)
 * @since 2014-10
 * @author Matias Medina (matias.medina@modelitsoftware.com)
 * @since 2015-07
 */
 
public with sharing class ApplicationUtils {
    // Private Constants
    private static final Integer MEASURE_COMBINATION_FIELD_LENGTH;
    private static final Map<String, String> BUILDING_VINTAGES_TO_MEASURE_COMBINATION_YEARS =
            new Map<String, String> {
                '75' => '1975', '85' => '1985', '96' => '1996', '03' => '1996', '07' => '1996',
                '11' => '1996', 'NEW' => '1996'
            };

    // Public Constants
    public static final String PGE_GAS_ELECTRIC_PROVIDER = 'Pacific Gas and Electric Company';
    public static final String FUNDING_SOURCE_HU = 'PG&E Home Upgrade';
    public static final String FUNDING_SOURCE_AHU = 'PG&E Advanced Home Upgrade';
    public static final Id ACQC_RECORD_TYPE;
    public static final Id HUP_RECORD_TYPE;
    public static final Id AHU_RECORD_TYPE;
    public static final Id AHUP_RECORD_TYPE;
    public static final Id ACQC_PROGRAM_ENROLLMENT_RECORD_TYPE_ID;
    public static final String HYBRID_PACKAGE_TYPE = 'Hybrid';
    public static final String CUSTOM_PACKAGE_TYPE = 'Custom';
    public static final String SECURED_LOAN = 'Secured Loan';
    public static final String UNSECURED_LOAN = 'Unsecured Loan';
    public static final String BIG_ACCOUNT_NAME = 'BUILD IT GREEN';
    public static final String CREDENTIAL_ACTIVE_VERIFIED_STATUS = 'Active - Verified';
    public static final String PROGRAM_ENROLLMENT_SUSPENDED_STATUS = 'Suspended';
    // AHU Statuses
    // PRE APP STATUSES
    public static final String PRE_INSTALL_CREATED_STATUS = 'Pre-Install Created';
    public static final String PRE_INSTALL_SUBMITTED_STATUS = 'Pre-Install Submitted';
    public static final String PRE_INSTALL_APPROVED_STATUS = 'Pre-Install Approved';
    public static final String PRE_INSTALL_CORRECTION_REQUIRED_STATUS = 'Pre-Install Correction Required';
    public static final String PRE_INSTALL_RESUBMITTED_STATUS = 'Pre-Install Resubmitted';
    // POST APP STATUSES
    public static final String POST_INSTALL_CREATED_STATUS = 'Post-Install Created';
    public static final String POST_INSTALL_SUBMITTED_STATUS = 'Post-Install Submitted';
    public static final String POST_INSTALL_APPROVED_STATUS = 'Post-Install Approved';
    public static final String POST_INSTALL_CORRECTION_REQUIRED_STATUS = 'Post-Install Correction Required';
    public static final String POST_INSTALL_RESUBMITTED_STATUS = 'Post-Install Resubmitted';
    // ACQC and HUP Statuses
    public static final String CREATED_STATUS = 'Created';
    public static final String SUBMITTED_STATUS = 'Submitted';
    public static final String CORRECTION_REQUIRED_STATUS = 'Correction Required';
    public static final String RESUBMITTED_STATUS = 'Resubmitted';
    public static final String APPROVED_STATUS = 'Approved';
    // ACQC, HUP, AHU & AHUP Statuses
    public static final String CANCELED_STATUS = 'Canceled';
    public static final String REJECTED_STATUS = 'Rejected';
    public static final String REBATE_ISSUED_STATUS = 'Rebate Issued';
    public static final String CORRECTION_PENDING_REVIEW = 'Correction Pending Review';
    // ACQC, HU & AHU Messages
    public static final String CANCELED_MESSAGE = 'This Application has been canceled.';
    public static final String REBATE_ISSUED_MESSAGE = 'The Rebate has been issued for this Application.';

    public static Boolean isTriggerExecuting = false;

    static {
        Map<String, Schema.RecordTypeInfo> recordTypeNameToId =
                Schema.SObjectType.Application__c.getRecordTypeInfosByName();
        ACQC_RECORD_TYPE = recordTypeNameToId.get('ACQC').getRecordTypeId();
        HUP_RECORD_TYPE = recordTypeNameToId.get('HUP').getRecordTypeId();
        AHU_RECORD_TYPE = recordTypeNameToId.get('AHU').getRecordTypeId();
        AHUP_RECORD_TYPE = recordTypeNameToId.get('AHUP').getRecordTypeId();
        MEASURE_COMBINATION_FIELD_LENGTH =
                Schema.SObjectType.Application__c.fields.Measure_Combination__c.getLength();
        ACQC_PROGRAM_ENROLLMENT_RECORD_TYPE_ID =
                Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName().get('ACQC').getRecordTypeId();
    }

    /**
     * Populates all zip code dependent fields on the Application based on their respective zip code field.
     * The fields populated includes County__c, Building_County__c, Customer_County__c and Climate_Zone__c.
     *
     * @params applications is a list of Applications to process.
     */
    public static void processZipCode(List<Application__c> applications) {
        Map<String, Zip_Code__mdt> zipCodes = new Map<String, Zip_Code__mdt>();

        // create a set of the case Zip Codes
        Set<String> applicationZipCodes = new Set<String>();
        for (Application__c a : applications) {
            if (a.RecordTypeId == ACQC_RECORD_TYPE
                    || a.RecordTypeId == HUP_RECORD_TYPE
                    || a.RecordTypeId == AHU_RECORD_TYPE
                    || a.RecordTypeId == AHUP_RECORD_TYPE) {
                if (a.RecordTypeId != ACQC_RECORD_TYPE) {
                    applicationZipCodes.add(a.Customer_Zip_Code__c);
                }
                applicationZipCodes.add(a.Building_Zip_Code__c);
            }
        }

        try {
            /*
             * Retrieve all the Zip_Code__mdt records for the zip codes of the application records being
             * updated/inserted and create a Zipcode to Zip Code Data map
             */
            for (Zip_Code__mdt zipCode : [
                    SELECT County__c, Climate_Zone__c, Zip_Code__c
                    FROM Zip_Code__mdt
                    WHERE Zip_Code__c IN :applicationZipCodes]) {
                zipCodes.put (zipCode.Zip_Code__c, zipCode);
            }
        } catch (DmlException e) {
            System.debug('### Error retrieving Application ZIP Code Data: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('### Error updating Application County Name: ' + e.getMessage());
        }

        // iterate over the list of records being processed
        try {
            for (Application__c a : applications) {
                // Set County and Climate Zone
                if (a.RecordTypeId == ACQC_RECORD_TYPE
                        || a.RecordTypeId == HUP_RECORD_TYPE
                        || a.RecordTypeId == AHU_RECORD_TYPE
                        || a.RecordTypeId == AHUP_RECORD_TYPE) {
                    if (a.RecordTypeId != ACQC_RECORD_TYPE && zipCodes.containsKey(a.Customer_Zip_Code__c)) {
                        a.Customer_County__c = zipCodes.get(a.Customer_Zip_Code__c).County__c;
                    } else {
                        a.Customer_County__c = null;
                    }
                    if (zipCodes.containsKey(a.Building_Zip_Code__c)) {
                        a.Building_County__c = zipCodes.get(a.Building_Zip_Code__c).County__c;
                        a.Climate_Zone__c = zipCodes.get(a.Building_Zip_Code__c).Climate_Zone__c;
                    } else {
                        a.Building_County__c = null;
                        a.Climate_Zone__c = null;
                    }
                }
            }
        } catch (Exception e) {
            System.debug('### Error updating Application Zip Code dependent fields: ' + e.getMessage());
        }
    }

    /**
     * Captures both the last submission and approval dates by record type for each Application's related Contractor
     * Account.
     *
     * @param accIdToApps is a map of Application__c lists keyed by their related Contractor Account Id
     */
    public static void captureSubmissionsAndApprovals(Map<Id, List<Application__c>> accIdToApps) {
        Map<Id, Account> accsToProcess = new Map<Id, Account>();

        for (Account acc : [
                SELECT Id, ACQC_Last_App_Submission_Date__c , AHU_Last_App_Submission_Date__c,
                    HU_Last_App_Submission_Date__c, ACQC_Last_App_Approval_Date__c, AHU_Last_App_Approval_Date__c,
                    HU_Last_App_Approval_Date__c
                FROM Account
                WHERE Id =: accIdToApps.keySet()]) {

            for (Application__c  app : accIdToApps.get(acc.Id)) {
                if (app.RecordTypeId == ACQC_RECORD_TYPE) {
                    if (app.Last_Application_Submission_Date__c != null
                            && (acc.ACQC_Last_App_Submission_Date__c == null
                            || (acc.ACQC_Last_App_Submission_Date__c != null
                            && (acc.ACQC_Last_App_Submission_Date__c < app.Last_Application_Submission_Date__c)))) {
                        acc.ACQC_Last_App_Submission_Date__c = app.Last_Application_Submission_Date__c;
                        if(!accsToProcess.containsKey(acc.Id)) {
                            accsToProcess.put(acc.Id, acc);
                        }
                    }

                    if (app.Application_Approval_Date__c != null) {
                        Date appApprDate = app.Application_Approval_Date__c.dateGMT();
                        if (acc.ACQC_Last_App_Approval_Date__c == null
                                || (acc.ACQC_Last_App_Approval_Date__c != null
                                && (appApprDate != null && (acc.ACQC_Last_App_Approval_Date__c < appApprDate)))) {
                            acc.ACQC_Last_App_Approval_Date__c = appApprDate;
                            if(!accsToProcess.containsKey(acc.Id)) {
                                accsToProcess.put(acc.Id, acc);
                            }
                        }
                    }
                } else if (app.RecordTypeId == HUP_RECORD_TYPE) {
                    if (app.Last_Application_Submission_Date__c != null
                            && (acc.HU_Last_App_Submission_Date__c == null
                            || (acc.HU_Last_App_Submission_Date__c != null
                            && (acc.HU_Last_App_Submission_Date__c < app.Last_Application_Submission_Date__c)))) {
                        acc.HU_Last_App_Submission_Date__c = app.Last_Application_Submission_Date__c;
                        if (!accsToProcess.containsKey(acc.Id)) {
                            accsToProcess.put(acc.Id, acc);
                        }
                    }

                    if (app.Application_Approval_Date__c != null) {
                        Date appApprDate = app.Application_Approval_Date__c.dateGMT();
                        if (acc.HU_Last_App_Approval_Date__c == null
                                || (acc.HU_Last_App_Approval_Date__c != null
                                && (appApprDate != null && (acc.HU_Last_App_Approval_Date__c < appApprDate)))) {
                            acc.HU_Last_App_Approval_Date__c = appApprDate;
                            if (!accsToProcess.containsKey(acc.Id)) {
                                accsToProcess.put(acc.Id, acc);
                            }
                        }
                    }
                } else if (app.RecordTypeId == AHUP_RECORD_TYPE) {
                    if (app.Preapplication_Submitted__c != null) {
                        Date appDate = app.Preapplication_Submitted__c;
                        Datetime appDateTime = Datetime.newInstanceGmt(appDate, Time.newinstance(12,0,0,0));
                        if (acc.AHU_Last_App_Submission_Date__c == null
                                || (acc.AHU_Last_App_Submission_Date__c != null
                                && (appDateTime != null && (acc.AHU_Last_App_Submission_Date__c < appDateTime)))) {
                            acc.AHU_Last_App_Submission_Date__c = appDateTime;
                            if (!accsToProcess.containsKey(acc.Id)) {
                                accsToProcess.put(acc.Id, acc);
                            }
                        }
                    }

                    if (app.Full_Application_Approved__c != null) {
                        if (acc.AHU_Last_App_Approval_Date__c == null
                                || (acc.AHU_Last_App_Approval_Date__c != null
                                && (acc.AHU_Last_App_Approval_Date__c < app.Full_Application_Approved__c))) {
                            acc.AHU_Last_App_Approval_Date__c = app.Full_Application_Approved__c;
                            if (!accsToProcess.containsKey(acc.Id)) {
                                accsToProcess.put(acc.Id, acc);
                            }
                        }
                    }
                }
                else if (app.RecordTypeId == AHU_RECORD_TYPE) {
                    if (app.Last_Application_Submission_Date__c != null
                           && (acc.AHU_Last_App_Submission_Date__c == null
                           || (acc.AHU_Last_App_Submission_Date__c != null
                           && (acc.AHU_Last_App_Submission_Date__c < app.Last_Application_Submission_Date__c)))) {
                       acc.AHU_Last_App_Submission_Date__c = app.Last_Application_Submission_Date__c;
                       if (!accsToProcess.containsKey(acc.Id)) {
                            accsToProcess.put(acc.Id, acc);
                       }
                    }

                    if (app.Application_Approval_Date__c != null) {
                        Date appApprDate = app.Application_Approval_Date__c.dateGMT();
                        if (acc.AHU_Last_App_Approval_Date__c == null
                                || (acc.AHU_Last_App_Approval_Date__c != null
                                && (appApprDate != null && (acc.AHU_Last_App_Approval_Date__c < appApprDate)))) {
                            acc.AHU_Last_App_Approval_Date__c = appApprDate;
                            if (!accsToProcess.containsKey(acc.Id)) {
                                accsToProcess.put(acc.Id, acc);
                            }
                        }
                    }
                }
            }
        }

        if (accsToProcess.size() > 0) {
            update accsToProcess.values();
        }
    }

    /**
     * Populates HC_Type__c based on the value of Air_Conditioning__c for each Application__c.
     *
     * @param applications is the list of Application__c records
     */
    public static void setHCType(List<Application__c> applications) {
        try {
            // set HC_Type__c
            for (Application__c application : applications) {
                if (application.Air_Conditioning__c == 'Heat Pump'
                        || application.Air_Conditioning__c == 'Packaged DX'
                        || application.Air_Conditioning__c == 'Split DX') {
                    application.HC_Type__c = 'AC';
                } else if (application.Air_Conditioning__c == 'Evaporative'
                        || application.Air_Conditioning__c == 'None'
                        || application.Air_Conditioning__c == 'Room AC') {
                    application.HC_Type__c = 'hG';
                } else {
                    application.HC_Type__c = null;
                }
            }
        } catch (Exception e) {
            System.debug('### Error setting HC Type: ' + e.getMessage());
        }
    }

    /**
     * Populates Building_Vintage__c based on the value of Year_Built__c for each Application__c.
     *
     * @param applications is a list of Application__c records to process
     */
    public static void setBuildingVintage(List<Application__c> applications) {
        try {
            // set Building_Vintage__c
            for (Application__c application : applications) {
                Integer yearBuilt;
                if (application.Year_Built__c != null
                        && application.Year_Built__c.isNumeric()) {
                    yearBuilt = integer.valueof(application.Year_Built__c);
                }

                if (application.Year_Built__c == null
                        || !application.Year_Built__c.isNumeric()
                        || yearBuilt < 0) {
                    application.Building_Vintage__c = null;
                } else if (yearBuilt < 1978) {
                    application.Building_Vintage__c = '75';
                } else if (yearBuilt <= 1992) {
                    application.Building_Vintage__c = '85';
                } else if (yearBuilt <= 2001) {
                    application.Building_Vintage__c = '96';
                } else if (yearBuilt <= 2005) {
                    application.Building_Vintage__c = '03';
                } else if (yearBuilt <= 2009) {
                    application.Building_Vintage__c = '07';
                } else if (yearBuilt <= 2012) {
                    application.Building_Vintage__c = '11';
                } else if (yearBuilt > 2012) {
                    application.Building_Vintage__c = 'NEW';
                } else {
                    application.Building_Vintage__c = null;
                }
            }
        } catch (Exception e) {
            System.debug('### Error setting Building Vintage: ' + e.getMessage());
        }
    }

    /**
     * Populate the incentive total on the applications where their measures got changes.
     *
     * @param measures. The affected measures by the trigger (delete, insert and update).
     */
    public static void populateIncentiveTotal(Map<Id, Measure__c> measures) {
        Set<Id> appIds = new Set<Id>();
        Set<Id> rebateTypeIds = new Set<Id>();

        // Takes the applications to update, based on the affected measures by the trigger.
        for (Measure__c m : measures.values()) {
            appIds.add(m.Application__c);
        }

        try {
            // Apps to update
            List<Application__c> appsToProcess = [
                SELECT Id, RecordTypeId, (SELECT Rebate_Type__c FROM Measures__r)
                FROM Application__c WHERE Id IN :appIds
                ];
            // Get the needed rebate types (those to belong to the measures that belong to the affected apps).
            for (Application__c app : appsToProcess) {
                for (Measure__c m : app.Measures__r) {
                    rebateTypeIds.add(m.Rebate_Type__c);
                }
            }
            // Queries Rebate_Amount__c in order to know what value we should use to calculate the incentive total.
            Map<Id, Rebate_Type__c> rebateTypeMap = new Map<Id, Rebate_Type__c>([
                SELECT Id, Rebate_Amount__c FROM Rebate_Type__c WHERE Id IN :rebateTypeIds
                ]);

            for (Application__c app : appsToProcess) {
                // If we perform other kind of calculation for other apps (AHU, HU) we will just need to add else if.
                if (app.RecordTypeId == ACQC_RECORD_TYPE) {
                    app.Incentive_Total__c = calculateIncentiveTotal(app.Measures__r, rebateTypeMap);
                }
            }

            // Updates the incentive total field on Application__c
            update appsToProcess;
        } catch (Exception e) {
            System.debug('##Error when calculating incentive total:' + e.getMessage());
            System.debug('##StackTrace: ' + e.getStackTraceString());
        }
    }

    /**
     * Take all the measures related to an application and sum the rebate type related to each measure.
     * Each measure contains a reference to a rebate type.
     *
     * @param measures. The measures that belong to a given application.
     * @param rebateTypes. This map contains the rebate types needed to calculate the incentive total.
     * @return The incentive total for one given application.
     */
    private static Decimal calculateIncentiveTotal(List<Measure__c> measures, Map<Id, Rebate_Type__c> rebateTypes) {
        Decimal incentiveTotal = 0;
        if (measures != null && (!measures.isEmpty())) {
            for (Measure__c m : measures) {
                incentiveTotal += rebateTypes.get(m.Rebate_Type__c).Rebate_Amount__c;
            }
        }
        return incentiveTotal;
    }

    public static void updateFundingSourceOnApplications(List<Application__c> appsToProcess) {
        if (appsToProcess != null) {
            try {
                for (Application__c app : appsToProcess) {
                    if (app.RecordTypeId == HUP_RECORD_TYPE) {
                        app.Funding_Source__c = FUNDING_SOURCE_HU;
                    } else if (app.RecordTypeId == AHU_RECORD_TYPE) {
                        app.Funding_Source__c = FUNDING_SOURCE_AHU;
                    }
                }
            } catch (Exception e) {
                System.debug('###ApplicationUtils.updateFundingSourceOnApplications():' + e.getStackTraceString());
            }
        }
    }

    /**
     * Create/delete junctions records between Application__c and PGE_Customer__c
     *
     * @param applications the list of applications records to process
     */
    public static void processGasElectricJunctions(List<Application__c> applications) {
        Map<String, Set<Id>> electricIdToPGECustomers = new Map<String, Set<Id>>();
        Map<String, Set<Id>> gasIdToPGECustomers = new Map<String, Set<Id>>();
        Set<Application__c> applicationsWithPgeService = new Set<Application__c>();
        Set<Application__c> applicationsWithoutPgeService = new Set<Application__c>();
        List<PGE_Customer_Application__c> newJunctions = new List<PGE_Customer_Application__c>();
        Map<String, PGE_Customer_Application__c> existingJunctions = new Map<String, PGE_Customer_Application__c>();

        try {
            // Perform the matches between apps and pge customers.
            findGasElectricIdsMatchesWithPGECustomers(applications, applicationsWithPgeService, gasIdToPGECustomers,
                    electricIdToPGECustomers);

            for (PGE_Customer_Application__c junction : [
                    SELECT Id, Application__c, PGE_Customer__c
                    FROM PGE_Customer_Application__c
                    WHERE Application__c IN :applications]) {
                // Build a map to look for existing matches quickly. We don't want to create repeated junctions.
                existingJunctions.put((String)junction.Application__c + junction.PGE_Customer__c, junction);
            }

            // Loop through the applications in order to determine whether a junction object
            // needs to be created or deleted.
            Set<String> junctionsToKeep = new Set<String>();
            for (Application__c app : applicationsWithPgeService) {
                Set<Id> matches = new Set<Id>();
                if (gasIdToPGECustomers.get(app.Gas_Account_Number__c) != null
                        && (!gasIdToPGECustomers.get(app.Gas_Account_Number__c).isEmpty())) {
                    matches.addAll(gasIdToPGECustomers.get(app.Gas_Account_Number__c));
                }
                if (electricIdToPGECustomers.get(app.Electric_Account_Number__c) != null
                        && (!electricIdToPGECustomers.get(app.Electric_Account_Number__c).isEmpty())) {
                    matches.addAll(electricIdToPGECustomers.get(app.Electric_Account_Number__c));
                }

                for (Id match : matches) {
                    if (!existingJunctions.keySet().contains((String) app.Id + match)) {
                        newJunctions.add(new PGE_Customer_Application__c(Application__c = app.Id,
                                PGE_Customer__c = match));
                    } else {
                        // There is already a junction for this match, keep it.
                        junctionsToKeep.add((String) app.Id + match);
                    }
                }
            }

            // Every junction that is not added or kept we will want to delete.
            existingJunctions.keySet().removeAll(junctionsToKeep);
            // Only delete existing junctions that we don't want to keep (that no longer match).
            delete existingJunctions.values();

            insert newJunctions;
        } catch (DmlException e) {
            System.debug('###ApplicationUtils.processGasElectricJunctions():' + e.getStackTraceString());
        } catch (QueryException e) {
            System.debug('###ApplicationUtils.processGasElectricJunctions():' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('###ApplicationUtils.processGasElectricJunctions():' + e.getStackTraceString());
        }
    }

    /**
     * Finds the matches between the gas/electric ids of the apps and the gas/electric ids of pge customers
     *
     * @param applications apps to process
     * @param applictionsWithPgeService stores those applications that have pge gas/electric service ids
     * @param gasIdToPGECustomers stores pge customers (those that match with the gas id of @applictionsWithPgeService)
     * @param electricIdToPGECustomers stores pge customers
     * (those that match with the electric id of @applictionsWithPgeService)
     */
    private static void findGasElectricIdsMatchesWithPGECustomers(List<Application__c> applications,
            Set<Application__c> applicationsWithPgeService, Map<String, Set<Id>> gasIdToPGECustomers,
            Map<String, Set<Id>> electricIdToPGECustomers) {

        try {
            // Find PGE gas/electric service ids matches.
            for (Application__c app : applications) {
                if (app.RecordTypeId == HUP_RECORD_TYPE || app.RecordTypeId == AHU_RECORD_TYPE
                        || app.RecordTypeId == ACQC_RECORD_TYPE) {
                    if (app.RecordTypeId != ACQC_RECORD_TYPE && app.Gas_Provider__c == PGE_GAS_ELECTRIC_PROVIDER
                            && !String.isBlank(app.Gas_Account_Number__c)) {
                        gasIdToPGECustomers.put(app.Gas_Account_Number__c, new Set<Id>());
                        applicationsWithPgeService.add(app);
                    }
                    if ((app.RecordTypeId == ACQC_RECORD_TYPE || (app.RecordTypeId != ACQC_RECORD_TYPE
                            && app.Electric_Provider__c == PGE_GAS_ELECTRIC_PROVIDER))
                            && !String.isBlank(app.Electric_Account_Number__c)) {
                        electricIdToPGECustomers.put(app.Electric_Account_Number__c, new Set<Id>());
                        applicationsWithPgeService.add(app);
                    }
                }
            }
            if (!applicationsWithPgeService.isEmpty()) {
                // Get PG&E customers that match with electric/gas id of apps.
                List<PGE_Customer__c> pge_customers = [
                    SELECT ID, Gas_SAID__c, Electric_SAID__c
                    FROM PGE_Customer__c
                    WHERE Gas_SAID__c IN: gasIdToPGECustomers.keySet()
                        OR Electric_SAID__c IN: electricIdToPGECustomers.keySet()
                    ];

                // Map key Gas id-->pge customers list. Electric id-->pge customers list.
                for (PGE_Customer__c pgeCust : pge_customers) {
                    if (gasIdToPGECustomers.containsKey(pgeCust.Gas_SAID__c)) {
                        gasIdToPGECustomers.get(pgeCust.Gas_SAID__c).add(pgeCust.Id);
                    }
                    if (electricIdToPGECustomers.containsKey(pgeCust.Electric_SAID__c)) {
                        electricIdToPGECustomers.get(pgeCust.Electric_SAID__c).add(pgeCust.Id);
                    }
                }
            }

        } catch (QueryException e) {
            System.debug('###ApplicationUtils.findGasElectricIdsMatchesWithPGECustomers():' + e.getStackTraceString());
            throw e;
        } catch (Exception e) {
            System.debug('###ApplicationUtils.findGasElectricIdsMatchesWithPGECustomers():' + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * Filter apps before sending them to the method that matches apps and pge customers.
     *
     * @param newApps apps to be processed
     * @param oldApps apps to be compared with newApps
     * @return list that contains apps that are going to be used to create/delete PGE_Customer_Application__c objects
     */
    public static List<Application__c> filterAppsToMakeGasElectricJunctions(List<Application__c> newApps,
            List<Application__c> oldApps) {
        // Applications to match with PGE Customers
        List<Application__c> appsToRelateWithPgeCustomers = new List<Application__c>();

        try {
            if (newApps != null && oldApps != null) {
                Map<Id, Application__c> oldAppsById = new Map<Id, Application__c>(oldApps);

                for (Application__c newApp : newApps) {
                    Application__c oldApp = oldAppsById.get(newApp.Id);
                    if (oldApp!= null && ((newApp.Electric_Provider__c != oldApp.Electric_Provider__c)
                            || (newApp.Gas_Provider__c != oldApp.Gas_Provider__c)
                            || (newApp.Gas_Account_Number__c != oldApp.Gas_Account_Number__c)
                            || (newApp.Electric_Account_Number__c != oldApp.Electric_Account_Number__c))) {
                        appsToRelateWithPgeCustomers.add(newApp);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('###ApplicationUtils.filterAppsToMakeGasElectricJunctions():' + e.getStackTraceString());
        }
        return appsToRelateWithPgeCustomers;
    }

    /**
    * Filter apps by checking their record types and the previous and current value of some fields.
    * Ideally both lists (newApps and oldApps) contains the same apps.
    *
    * @newApps list of apps to be compared with its old version
    * @oldApps the old version of newApps
    * @return a map of application ids by boolean, which determines if values should be reset or not
    */
    public static Map<Id, Boolean> filterAppsToMatchMeasureCombination(List<Application__c> newApps,
            List<Application__c> oldApps) {
        Map<Id, Boolean> appsIdToProcces = new Map<Id, Boolean>();
        Map<Id, Application__c> oldAppsMap = new Map<Id, Application__c>(oldApps);

            for (Application__c newApp : newApps) {
                Application__c oldApp = oldAppsMap.get(newApp.Id);
                /* Applications will be re-evaluated if Override Package Type is false and:
                *  1) Building vintage or climate zone change.
                *  2) Package Type is Hybrid and one of the following values change:
                *     Measure Combination Code, Measure Combination, Measure Combination Abbreviation, kW Savings,
                *     kWh Savings, Therms Savings, Incremental Measure Cost, kW Savings (2nd B/L), kWh Savings (2nd B/L),
                *     Therms Savings (2nd B/L), Incremental Measure Cost (2nd B/L).
                */
                if ((newApp.RecordTypeId == HUP_RECORD_TYPE && !newApp.Override_Package_Type__c && oldApp != null)
                        && (newApp.Override_Package_Type__c != oldApp.Override_Package_Type__c
                        || newApp.Building_Vintage__c != oldApp.Building_Vintage__c
                        || newApp.Climate_Zone__c != oldApp.Climate_Zone__c
                        || (oldApp.Package_Type__c == HYBRID_PACKAGE_TYPE
                        && (newApp.Package_Type__c != oldApp.Package_Type__c
                        || newApp.Measure_Combination_Code__c != oldApp.Measure_Combination_Code__c
                        || newApp.Measure_Combination__c != oldApp.Measure_Combination__c
                        || newApp.Measure_Combination_Abbreviation__c != oldApp.Measure_Combination_Abbreviation__c
                        || newApp.Building_Vintage__c != oldApp.Building_Vintage__c
                        || newApp.Climate_Zone__c != oldApp.Climate_Zone__c
                        || newApp.kW_Savings__c != oldApp.kW_Savings__c
                        || newApp.kWh_Savings__c != oldApp.kWh_Savings__c
                        || newApp.Therms_Savings__c != oldApp.Therms_Savings__c
                        || newApp.Incremental_Measure_Cost__c != oldApp.Incremental_Measure_Cost__c
                        || newApp.kW_Savings_2nd_BL__c != oldApp.kW_Savings_2nd_BL__c
                        || newApp.kWh_Savings_2nd_BL__c != oldApp.kWh_Savings_2nd_BL__c
                        || newApp.Therms_Savings_2nd_BL__c != oldApp.Therms_Savings_2nd_BL__c
                        || newApp.Incremental_Measure_Cost_2nd_BL__c != oldApp.Incremental_Measure_Cost_2nd_BL__c)))) {
                    appsIdToProcces.put(newApp.Id, true);
                }
            }

        return appsIdToProcces;
    }

    /**
     * Get applications with its measures.
     *
     * @param applicationIds The applications' Ids.
     * @return List of applications with its corresponding measures.
     */
    private static List<Application__c> getApplicationsWithMeasures(Set<Id> applicationIds) {
        List<Application__c> appsToProcess = new List<Application__c>();

        try {
            appsToProcess = [
                SELECT Package_Type__c, Measure_Combination_Code__c, Measure_Combination__c,
                    Measure_Combination_Abbreviation__c, kW_Savings__c, kWh_Savings__c, Therms_Savings__c,
                    Energy_Savings_Percentage__c, Hybrid_Measure_Savings__c, Building_Vintage__c, Climate_Zone__c,
                    (SELECT Id, Measure_Code__c, Measure_Code_Abbreviation__c, Qualifying_Measure_Code__c,
                        Measure_Type_Name__c
                     FROM Measures__r WHERE Measure_Code__c != null AND Measure_Code_Abbreviation__c != null)
                FROM Application__c
                WHERE Id IN :applicationIds AND RecordTypeId =: HUP_RECORD_TYPE AND Override_Package_Type__c = false
                ];
        } catch (QueryException e) {
            System.debug('Error: Couldn\'t get applications with measures. Message:' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }

        return appsToProcess;
    }

    /**
     * Get ACQC applications' climate zone and total capacity unit.
     *
     * @param measures List of measures.
     * @return Map containing applications with its Id as key.
     */
    public static Map<Id, Application__c> getApplicationsWithMeasures(List<Measure__c> measures) {
        List<Application__c> applications = new List<Application__c>();
        Set<Id> applicationIds = new Set<Id>();
        Map<Id, Application__c> applicationsById = new Map<Id, Application__c>();

        try {
            // Get application Ids.
            for (Measure__c measure : measures) {
                applicationIds.add(measure.Application__c);
            }

            applications = [
                SELECT Climate_Zone__c, Total_Unit_Capacity__c
                FROM Application__c
                WHERE RecordTypeId = :ACQC_RECORD_TYPE
                    AND Id IN :applicationIds
                ];

            for (Application__c application : applications) {
                if (!applicationsById.containsKey(application.Id)) {
                    applicationsById.put(application.Id, application);
                }
            }
        } catch (Exception e) {
            System.debug('###ApplicationUtils.getApplicationsWithMeasures(): Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return applicationsById;
    }

    /**
     * Populates Package Type, Measure Combination and KW Savings fields for each Application depending on
     * the value of its Building Vintage, Climate Zone and its related Measure records' Measure Code.
     * If a match is found, then the Application's Package Type is set to 'Hybrid' and its dependent fields
     * are populated with the matching Measure Combination Code custom metadata record's corresponding field values.
     * If a match is not found, then the Application's Package Type is set to 'Custom' and any values set by a
     * previous match are set to null.
     * If Package Type is once more determined to be 'Custom', then any manually entered values in the
     * dependent fields are preserved.
     * If qualifying measures, climate zone or building vintage change the application is re-evaluated.
     * Applications not of the HUP record type or where Override Package Type is true will not be updated.
     *
     * @param applicationIds a map of application ids by boolean, which determines if values should be reset or not
     */
    public static void setMeasureCode(Map<Id, Boolean> applicationIds) {
        List<Application__c> appsToUpdate = new List<Application__c>();
        Set<String> buildingVintages = new Set<String>();
        Set<Integer> climateZones = new Set<Integer>();
        Set<Integer> measuresCombinationSize = new Set<Integer>();
        Map<String, Map<Integer, Map<Integer, List<MeasureUtils.MeasureCodeWrapper>>>> measuresCodeMap;
        Map<Application__c, List<MeasureUtils.MeasureCodeWrapper>> appsToMeasureWrappers =
                new Map<Application__c, List<MeasureUtils.MeasureCodeWrapper>>();

        try {
            List<Application__c> appMeasuresData = new List<Application__c>();

            // Build building vintage and climate zone sets to filter the custom metadata object.
            for (Application__c application : getApplicationsWithMeasures(applicationIds.keySet())) {
                if (String.isNotBlank(application.Building_Vintage__c)
                        && BUILDING_VINTAGES_TO_MEASURE_COMBINATION_YEARS.containsKey(application.Building_Vintage__c)
                        && application.Climate_Zone__c != null && !application.Measures__r.isEmpty()) {
                    buildingVintages.add(
                            BUILDING_VINTAGES_TO_MEASURE_COMBINATION_YEARS.get(application.Building_Vintage__c));
                    climateZones.add((Integer) application.Climate_Zone__c);
                    measuresCombinationSize.add(MeasureUtils.getQualifyingMeasures(application.Measures__r).size());
                    appMeasuresData.add(application);
                } else {
                    // Set to null the value meaning that the three required data are missing or invalid.
                    appsToMeasureWrappers.put(application, null);
                }
            }

            measuresCodeMap =
                    MeasureUtils.getMeasureSavingsMetadata(buildingVintages, climateZones, measuresCombinationSize);

            // Loop through applications that have met the criteria (Vintage,Climate and has related Measures records).
            for (Application__c application : appMeasuresData) {
                Map<String, Measure__c> qualifyingMeasures =
                        MeasureUtils.getQualifyingMeasures(application.Measures__r);
                String appBuildingVintage =
                        BUILDING_VINTAGES_TO_MEASURE_COMBINATION_YEARS.get(application.Building_Vintage__c);
                Integer appClimateZone = (Integer)application.Climate_Zone__c;
                appsToMeasureWrappers.put(application, new List<MeasureUtils.MeasureCodeWrapper>());

                if (measuresCodeMap.get(appBuildingVintage) != null) {
                    if (measuresCodeMap.get(appBuildingVintage).get(appClimateZone) != null) {
                        Map<Integer, List<MeasureUtils.MeasureCodeWrapper>> measureSizeWrapperMap =
                                measuresCodeMap.get(appBuildingVintage).get(appClimateZone);
                        Integer qualifyingAppMeasuresSize = qualifyingMeasures.size();
                        Integer numberOfMatches = 0;

                        // We loop through wrappers with at least 3 qualifying measures
                        for (Integer i = qualifyingAppMeasuresSize; i > 2; i--) {
                            if (measureSizeWrapperMap.get(i) != null && !measureSizeWrapperMap.get(i).isEmpty()) {
                                // Loop through each custom metadata record where building vintage,
                                // climate zone and measure combination set size match.
                                for (MeasureUtils.MeasureCodeWrapper measureWrapper : measureSizeWrapperMap.get(i)) {
                                    Boolean match = true;

                                    // Loop through each measure code of the measure combination field (custom metadata)
                                    for (String measureCode : measureWrapper.measureCodes) {
                                        if (!qualifyingMeasures.containsKey(measureCode)) {
                                            match = false;
                                            break;
                                        }
                                    }
                                    // There's a match, could be a full set or subset.
                                    if (match) {
                                        numberOfMatches++;
                                        // Add the custom metadata record wrapper to keep track of matches.
                                        // Also this will let us know if there was more than one match.
                                        appsToMeasureWrappers.get(application).add(measureWrapper);

                                        // If indexes are equals, means we found a full set (exact match)
                                        // and we don't have to keep looking for other matches.
                                        // Also if we found more than one match, don't need to keep looking for matches
                                        // since the application measure combination code will set to 'Error'.
                                        if (i == qualifyingAppMeasuresSize || numberOfMatches > 1) {
                                            break;
                                        }
                                    }
                                }
                            }

                            // If we found a match there's no need to keep looking through custom metadata records
                            // with a lower measure combination code size.
                            if (numberOfMatches > 0) {
                                break;
                            }
                        }
                    }
                }
            }

            for (Application__c application : appsToMeasureWrappers.keySet()) {
                List<MeasureUtils.MeasureCodeWrapper> measureWrappers = appsToMeasureWrappers.get(application);
                String appMeasureAbbreviation = MeasureUtils.getMeasureAbbreviationSorted(application.Measures__r);

                // In case that there's one custom metadata type record and this one has a full set match
                // set the application to 'Hybrid'.
                if (measureWrappers != null && measureWrappers.size() == 1) {
                    MeasureUtils.MeasureCodeWrapper measureWrapper = measureWrappers.get(0);

                    application.Package_Type__c = HYBRID_PACKAGE_TYPE;
                    application.Measure_Combination_Code__c = measureWrapper.measureCode;
                    application.Measure_Combination__c = measureWrapper.measureCombination;
                    application.Measure_Combination_Abbreviation__c = appMeasureAbbreviation;
                    application.kW_Savings__c = measureWrapper.kwSavings;
                    application.kWh_Savings__c = measureWrapper.kwhSavings;
                    application.Therms_Savings__c = measureWrapper.thermsSavings;
                    application.Incremental_Measure_Cost__c = measureWrapper.incrementalMeasureCost;
                    application.kW_Savings_2nd_BL__c = measureWrapper.kwSavings2ndBl;
                    application.kWh_Savings_2nd_BL__c = measureWrapper.kwhSavings2ndBl;
                    application.Therms_Savings_2nd_BL__c = measureWrapper.thermsSavings2ndBl;
                    application.Incremental_Measure_Cost_2nd_BL__c = measureWrapper.incrementalMeasureCost2ndBl;
                } else {
                    application.Measure_Combination_Abbreviation__c = appMeasureAbbreviation;
                    String measureCombinationSorted = MeasureUtils.getMeasureCombinationSorted(application.Measures__r);
                    application.Measure_Combination__c =
                            measureCombinationSorted.length() > MEASURE_COMBINATION_FIELD_LENGTH
                            ? measureCombinationSorted.substring(0, MEASURE_COMBINATION_FIELD_LENGTH)
                            : measureCombinationSorted;

                    // Set the values to null if there has been a change on the qualifying measures, climate zone or
                    // building vintage. Otherwise keep the previous values.
                    if (applicationIds.get(application.Id) || measureWrappers == null) {
                        application.Measure_Combination_Code__c =
                                measureWrappers != null && measureWrappers.size() > 1
                                ? 'Error'
                                : null;
                        application.kW_Savings__c = null;
                        application.kWh_Savings__c = null;
                        application.Therms_Savings__c = null;
                        application.Incremental_Measure_Cost__c = null;
                        application.kW_Savings_2nd_BL__c = null;
                        application.kWh_Savings_2nd_BL__c = null;
                        application.Therms_Savings_2nd_BL__c = null;
                        application.Incremental_Measure_Cost_2nd_BL__c = null;
                    }

                    application.Package_Type__c = measureWrappers == null ? null : CUSTOM_PACKAGE_TYPE;
                }

                appsToUpdate.add(application);
            }

            update appsToUpdate;
        } catch (QueryException e) {
            System.debug('###ApplicationUtils.setMeasureCode():' + e.getStackTraceString());
        } catch (DMLException e) {
            System.debug('###ApplicationUtils.setMeasureCode():' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('###ApplicationUtils.setMeasureCode():' + e.getMessage());
        }
    }

    /**
     * Sets and updates the applications' kW Savings, kWh Savings, and Therms Savings when measures are updated.
     *
     * @param measuresByAppId Map of applications with its Id as key.
     */
    public static void setSavingsOnMeasureUpdate(Map<Id, List<Measure__c>> measuresByAppId) {

        if (!measuresByAppId.isEmpty()) {
            Set<Id> measureIds = new Set<Id>();
            for (Id applicationId : measuresByAppId.keySet()) {
                for (Measure__c measure : measuresByAppId.get(applicationId)) {
                    measureIds.add(measure.Id);
                }
            }

            try {
                List<Application__c> applicationsWithMeasures = [
                    SELECT kW_Savings__c, kWh_Savings__c, Therms_Savings__c, Climate_Zone__c, Total_Unit_Capacity__c,
                        Building_Zip_Code__c,
                        (SELECT kW_Savings__c, kWh_Savings__c, Therms_Savings__c
                         FROM Measures__r
                         WHERE Id NOT IN :measureIds)
                    FROM Application__c
                    WHERE Id IN :measuresByAppId.keySet()
                        AND RecordTypeId = :ACQC_RECORD_TYPE
                    ];

                for (Application__c application : applicationsWithMeasures) {
                    Decimal sumKWSavings = 0;
                    Decimal sumKWhSavings = 0;
                    Decimal sumThermSavings = 0;
                    // Determines if at least one of the measures has savings.
                    Boolean hasKWSavings = false;
                    Boolean hasKWhSavings = false;
                    Boolean hasThermsSavings = false;
                    // Get measures.
                    List<Measure__c> measures = measuresByAppId.get(application.Id);
                    measures.addAll(application.Measures__r);

                    if (application.Climate_Zone__c != null && application.Total_Unit_Capacity__c != null) {
                        for (Measure__c measure : measures) {
                            if (measure.kW_Savings__c != null) {
                                hasKWSavings = true;
                                sumKWSavings += measure.kW_Savings__c;
                            }
                            if (measure.kWh_Savings__c != null) {
                                hasKWhSavings = true;
                                sumKWhSavings += measure.kWh_Savings__c;
                            }
                            if (measure.Therms_Savings__c != null) {
                                hasThermsSavings = true;
                                sumThermSavings += measure.Therms_Savings__c;
                            }
                        }
                    }
                    // Set application savings.
                    application.kW_Savings__c = hasKWSavings ? sumKWSavings : null;
                    application.kWh_Savings__c = hasKWhSavings ? sumKWhSavings : null;
                    application.Therms_Savings__c = hasThermsSavings ? sumThermSavings : null;
                }

                update applicationsWithMeasures;
            } catch (Exception e) {
                System.debug('###ApplicationUtils.setSavingsOnMeasureUpdate(). Message: ' + e.getMessage());
                System.debug('###StackTrace: ' + e.getStackTraceString());
            }
        }
    }

    /**
     * Sets and updates the applications' savings fields (kW Savings, kWh Savings, and Therms Savings) and the measure
     * combination field, whenever measures are either inserted or deleted.
     *
     * @param measuresByAppId Map of applications with its Id as key.
     * @param isDelete Boolean that determines if measures are being deleted (true), or inserted (false).
     */
    public static void setSavingsAndMeasureCombination(Map<Id, List<Measure__c>> measuresByAppId, Boolean isDelete) {

        if (!measuresByAppId.isEmpty()) {
            try {
                List<Application__c> applicationsWithMeasures = [
                    SELECT kW_Savings__c, kWh_Savings__c, Therms_Savings__c, Climate_Zone__c, Total_Unit_Capacity__c,
                        Building_Zip_Code__c, Measure_Combination__c,
                        (SELECT kW_Savings__c, kWh_Savings__c, Therms_Savings__c, Application__c, Measure_Code__c
                         FROM Measures__r)
                    FROM Application__c
                    WHERE Id IN :measuresByAppId.keySet()
                        AND RecordTypeId = :ACQC_RECORD_TYPE
                    ];

                for (Application__c application : applicationsWithMeasures) {
                    setSavings(application, measuresByAppId, isDelete);
                    setMeasureCombination(application, measuresByAppId, isDelete);
                }

                update applicationsWithMeasures;
            } catch (Exception e) {
                System.debug('###ApplicationUtils.setSavingsAndMeasureCombination(). Message: ' + e.getMessage());
                System.debug('###StackTrace: ' + e.getStackTraceString());
            }
        }
    }

    /**
     * Sets and updates the applications' measure combination.
     *
     * @param application The application to set its measure combination to.
     * @param measuresByAppId Map of applications with its Id as key.
     * @param isDelete Boolean that determines if measures are being deleted (true), or inserted (false).
     * @return application The application with its measure combination set.
     */
    public static void setMeasureCombination(Application__c application,
            Map<Id, List<Measure__c>> measuresByAppId, Boolean isDelete) {
        Set<String> measureCodes = new Set<String>();
        // Create map of deleted measures with its Id as key.
        Map<Id, Measure__c> deletedMeasuresById = new Map<Id, Measure__c>(measuresByAppId.get(application.Id));

        for (Measure__c measure : application.Measures__r) {
            if (String.isNotBlank(measure.Measure_Code__c)
                    && ((!isDelete && application.Id == measure.Application__c)
                    || (isDelete && !deletedMeasuresById.containsKey(measure.Id)))) {
                // Get measure codes to determine measure combination.
                measureCodes.add(measure.Measure_Code__c);
            }
        }

        // Set application's measure combination.
        if (!measureCodes.isEmpty()) {
            List<String> appMeasureCombination = new List<String>(measureCodes);
            appMeasureCombination.sort();
            application.Measure_Combination__c = String.join(appMeasureCombination, ',');
        } else {
            application.Measure_Combination__c = null;
        }
    }

    /**
     * Sets and updates the applications' kW Savings, kWh Savings, and Therms Savings.
     *
     * @param application The application to set its savings to.
     */
    public static void setSavings(Application__c application, Map<Id, List<Measure__c>> measuresByAppId,
            Boolean isDelete) {
        Decimal sumKWSavings = 0;
        Decimal sumKWhSavings = 0;
        Decimal sumThermSavings = 0;
        // Determines if at least one of the measures has savings.
        Boolean hasKWSavings = false;
        Boolean hasKWhSavings = false;
        Boolean hasThermsSavings = false;
        // Create map of deleted measures with its Id as key.
        Map<Id, Measure__c> deletedMeasuresById = new Map<Id, Measure__c>(measuresByAppId.get(application.Id));

        for (Measure__c measure : application.Measures__r) {
            if (application.Climate_Zone__c != null && application.Total_Unit_Capacity__c != null
                    && ((!isDelete && application.Id == measure.Application__c)
                    || (isDelete && !deletedMeasuresById.containsKey(measure.Id)))) {
                // Calculate savings.
                if (measure.kW_Savings__c != null) {
                    hasKWSavings = true;
                    sumKWSavings += measure.kW_Savings__c;
                }
                if (measure.kWh_Savings__c != null) {
                    hasKWhSavings = true;
                    sumKWhSavings += measure.kWh_Savings__c;
                }
                if (measure.Therms_Savings__c != null) {
                    hasThermsSavings = true;
                    sumThermSavings += measure.Therms_Savings__c;
                }
            }
        }

        // Set application savings.
        application.kW_Savings__c = hasKWSavings ? sumKWSavings : null;
        application.kWh_Savings__c = hasKWhSavings ? sumKWhSavings : null;
        application.Therms_Savings__c = hasThermsSavings ? sumThermSavings : null;
    }

    /**
     * Sets the applications' savings fields (kW Savings, kWh Savings, and Therms Savings).
     * It executes whenever an update occurs on the application's savings fields, climate zone or total capacity unit.
     *
     * @param applicationsToProcess List of applications.
     */
    public static void setSavings(List<Application__c> applicationsToProcess) {

        if (!applicationsToProcess.isEmpty()) {
            try {
                List<Measure__c> measures = [
                    SELECT kW_Savings__c, kWh_Savings__c, Therms_Savings__c, Application__c
                    FROM Measure__c
                    WHERE Application__c IN :applicationsToProcess
                        AND RecordTypeId = :MeasureUtils.ACQC_RECORD_TYPE
                    ];

                for (Application__c application : applicationsToProcess) {
                    Decimal sumKWSavings = 0;
                    Decimal sumKWhSavings = 0;
                    Decimal sumThermSavings = 0;
                    // Determines if at least one of the measures has savings.
                    Boolean hasKWSavings = false;
                    Boolean hasKWhSavings = false;
                    Boolean hasThermsSavings = false;

                    if (application.Climate_Zone__c != null && application.Total_Unit_Capacity__c != null) {
                        for (Measure__c measure : measures) {
                            if (application.Id == measure.Application__c) {
                                if (measure.kW_Savings__c != null) {
                                    hasKWSavings = true;
                                    sumKWSavings += measure.kW_Savings__c;
                                }
                                if (measure.kWh_Savings__c != null) {
                                    hasKWhSavings = true;
                                    sumKWhSavings += measure.kWh_Savings__c;
                                }
                                if (measure.Therms_Savings__c != null) {
                                    hasThermsSavings = true;
                                    sumThermSavings += measure.Therms_Savings__c;
                                }
                            }
                        }
                    }
                    // Set application savings.
                    application.kW_Savings__c = hasKWSavings ? sumKWSavings : null;
                    application.kWh_Savings__c = hasKWhSavings ? sumKWhSavings : null;
                    application.Therms_Savings__c = hasThermsSavings ? sumThermSavings : null;
                }
            } catch (Exception e) {
                System.debug('###ApplicationUtils.setSavings(). Message: ' + e.getMessage());
                System.debug('###StackTrace: ' + e.getStackTraceString());
            }
        }
    }

    /**
     * Get the ACQC Ids of the applications that need to be processed, and its measures.
     *
     * @param measures List of measures.
     * @param measureIds Set of measures Ids.
     * @return Map of ACQC measures with its Id as key.
     */
    public static Map<Id, List<Measure__c>> filterApplicationsToSetSavings(List<Measure__c> measures,
            Set<Id> measureIds) {
        Map<Id, List<Measure__c>> measuresByAppId = new Map<Id, List<Measure__c>>();
        List<Measure__c> existingMeasures;

        if (measureIds != null) {
            existingMeasures = [
                SELECT Application__c
                FROM Measure__c
                WHERE Id IN :measureIds
                    AND RecordTypeId = :MeasureUtils.ACQC_RECORD_TYPE
                ];
        }
        // existingMeasures list will be empty when this method is called from after delete trigger.
        // In this case, we need to use the old version of the list of measures.
        measures = existingMeasures == null ? measures : existingMeasures;

        for (Measure__c measure : measures) {
            if (measuresByAppId.containsKey(measure.Application__c)) {
                measuresByAppId.get(measure.Application__c).add(measure);
            } else {
                measuresByAppId.put(measure.Application__c, new List<Measure__c>{measure});
            }
        }
        return measuresByAppId;
    }

    /**
     * Get the ACQC Ids of the applications that need to be processed, and its measures.
     *
     * @param measures List of measures.
     * @return Map of ACQC measures with its Id as key.
     */
    public static Map<Id, List<Measure__c>> filterApplicationsToSetSavings(List<Measure__c> measures) {
        return filterApplicationsToSetSavings(measures, null);
    }

    /**
     * Get the ACQC Ids of the applications that need to be processed, and its measures.
     *
     * @param measureIds Set of measures Ids.
     * @return Map of ACQC measures with its Id as key.
     */
    public static Map<Id, List<Measure__c>> filterApplicationsToSetSavings(Set<Id> measureIds) {
        return filterApplicationsToSetSavings(null, measureIds);
    }

    /**
     * Filter applications by checking if their climate zone or total unit capacity have changed.
     *
     * @param newAppsById Map of apps to be compared with its old version.
     * @param oldAppsById The old version of newAppsById.
     * @return Map of applications with its Id as Key.
     */
    public static Map<Id, Application__c> filterByClimateZoneAndCapacity(Map<Id, Application__c> newAppsById,
            Map<Id, Application__c> oldAppsById) {
        Map<Id, Application__c> appsToProcess = new Map<Id, Application__c>();

        for (Application__c newApp : newAppsById.values()) {
            Application__c oldApp = oldAppsById.get(newApp.Id);

            if (newApp.RecordTypeId == ACQC_RECORD_TYPE
                    && (newApp.Climate_Zone__c != oldApp.Climate_Zone__c
                    || newApp.Total_Unit_Capacity__c != oldApp.Total_Unit_Capacity__c)) {
                appsToProcess.put(newApp.Id, newApp);
            }
        }

        return appsToProcess;
    }

    /**
     * Filter applications by checking if their savings values have changed.
     *
     * @param newAppsById Map of apps to be compared with its old version.
     * @param oldAppsById The old version of newAppsById.
     * @return Map of applications with its Id as key.
     */
    public static Map<Id, Application__c> filterBySavings(Map<Id, Application__c> newAppsById,
            Map<Id, Application__c> oldAppsById) {
        Map<Id, Application__c> appsToProcess = new Map<Id, Application__c>();

        for (Application__c newApp : newAppsById.values()) {
            Application__c oldApp = oldAppsById.get(newApp.Id);

            if (newApp.RecordTypeId == ACQC_RECORD_TYPE
                    && (newApp.kWh_Savings__c != oldApp.kWh_Savings__c
                    || newApp.kW_Savings__c != oldApp.kW_Savings__c
                    || newApp.Therms_Savings__c != oldApp.Therms_Savings__c)) {
                appsToProcess.put(newApp.Id, newApp);
            }
        }

        return appsToProcess;
    }

    /**
     * Filter ACQC submitted/resubmitted applications whose technicians have changed.
     *
     * @param newAppsById Map of apps to be compared with its old version.
     * @param oldAppsById The old version of newAppsById.
     * @return Set of contact Ids.
     */
    public static Set<Id> filterByTechnician(Map<Id, Application__c> newAppsById, Map<Id, Application__c> oldAppsById) {
        Set<Id> contactIdsToProcess = new Set<Id>();

        for (Application__c newApp : newAppsById.values()) {
            if (newApp.RecordTypeId == ACQC_RECORD_TYPE && newApp.Last_Application_Submission_Date__c != null) {
                Id newTechnician = newApp.Technician__c;

                Application__c oldApp = oldAppsById.get(newApp.Id);
                /* If technician was changed, save both id of them to update the date
                 * on Last Application Submission Date Employee Program Enrollment later
                 */
                if (newTechnician != oldApp.Technician__c) {
                    if (newTechnician != null) {
                        contactIdsToProcess.add(newTechnician);
                    }
                    if (oldApp.Technician__c != null && oldApp.Last_Application_Submission_Date__c != null) {
                        contactIdsToProcess.add(oldApp.Technician__c);
                    }
                }
            }
        }

        return contactIdsToProcess;
    }

    /**
     * Update Last Application Submission Date on Employee Program Enrollment when the Application related is submitted.
     *
     * @param technicianIds related to their Employee_Program_Enrollment__c.
     */
    public static void updateTechnicianLastSubmissionDate(Set<Id> technicianIds) {
        List<Employee_Program_Enrollment__c> employeeProgramsEnrollment = new List<Employee_Program_Enrollment__c>();
        List<Application__c> applications = new List<Application__c>();

        if (!technicianIds.isEmpty()) {
            try {
                employeeProgramsEnrollment = [
                    SELECT Id, Contact__c, Last_Application_Submission_Date__c
                    FROM Employee_Program_Enrollment__c
                    WHERE Contact__c IN :technicianIds
                        AND Program_Enrollment__r.RecordTypeId = :ACQC_PROGRAM_ENROLLMENT_RECORD_TYPE_ID
                    ];

                if (!employeeProgramsEnrollment.isEmpty()) {
                    applications = [
                        SELECT Id, Technician__c, Last_Application_Submission_Date__c
                        FROM Application__c
                        WHERE Technician__c IN :technicianIds
                            AND Application_Submission_Date__c != null
                        ];
                }
            } catch (QueryException e) {
                System.debug('Error. Couldn\'t retrieve Employee_Program_Enrollment__c/Application__c: '
                        + e.getMessage());
            }

            for (Employee_Program_Enrollment__c employeeProgramEnrollment : employeeProgramsEnrollment) {
                DateTime lastSubmissionDate;

                for (Application__c application : applications) {
                    if (application.Technician__c == employeeProgramEnrollment.Contact__c) {
                        lastSubmissionDate = (lastSubmissionDate == null
                                || lastSubmissionDate < application.Last_Application_Submission_Date__c)
                                ? application.Last_Application_Submission_Date__c
                                : lastSubmissionDate;
                    }
                }
                employeeProgramEnrollment.Last_Application_Submission_Date__c = lastSubmissionDate;
            }

            try {
                update employeeProgramsEnrollment;
            } catch (DmlException e) {
                System.debug('Error. Couldn\'t update Employee_Program_Enrollment__c: ' + e.getMessage());
            }
        }
    }

    /**
     * Sets the measure combination for ACQC applications.
     *
     * @param measuresById Map containing measures with its Id as key.
     */
    public static void setMeasureCombination(Map<Id, Measure__c> measuresById) {
        Set<Id> applicationIds = new Set<Id>();

        try {
            // Get application Ids
            for (Measure__c measure : measuresById.values()) {
                applicationIds.add(measure.Application__c);
            }
            // Get all applications with its measures
            List<Application__c> applicationsWithMeasures = [
                SELECT Id, Measure_Combination__c,
                    (SELECT Id, Measure_Code__c FROM Measures__r)
                FROM Application__c
                WHERE RecordTypeId = :ACQC_RECORD_TYPE
                    AND Id IN :applicationIds
                ];

            for (Application__c application : applicationsWithMeasures) {
                Set<String> measureCodes = new Set<String>();
                // Create set of measure codes.
                for (Measure__c measure : application.Measures__r) {
                    if (String.isNotBlank(measure.Measure_Code__c)) {
                        measureCodes.add(measure.Measure_Code__c);
                    }
                }
                // Set application's measure combination.
                if (!measureCodes.isEmpty()) {
                    List<String> appMeasureCombination = new List<String>(measureCodes);
                    appMeasureCombination.sort();
                    application.Measure_Combination__c = String.join(appMeasureCombination, ',');
                } else {
                    application.Measure_Combination__c = null;
                }
            }

            if (!applicationsWithMeasures.isEmpty()) {
                update applicationsWithMeasures;
            }
        } catch (Exception e) {
            System.debug('###ApplicationUtils.setMeasureCombination(). Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }
    }

    /**
     * Retrieves the valid PG&E addresses.
     * @return Map of cities by zip code.
     */
    public static String getPGETerritoryZipCodes() {
        Map<String, List<String>> zipCodesByCity = new Map<String, List<String>>();
        String zipCodeMetadata;

        try {
            List<Zip_Code__mdt> zipCodes = [
                SELECT Zip_Code__c, City__c
                FROM Zip_Code__mdt
                WHERE PGE_Territory__c = true AND Zip_Code__c != null AND City__c != null
                ];

            // Creates a map based on the cities and their respective zip codes.
            // NOTE: there's a salesforce bug when moving the custom metadata type to a soql for loop.
            // Some of the records we loop through have null cities, so looks like != null filter does not work.
            for (Zip_Code__mdt md : zipCodes) {
                for (String city : md.City__c.split(';')) {
                    city = city.trim();
                    if (!zipCodesByCity.containsKey(city)) {
                        zipCodesByCity.put(city, new List<String>());
                    }
                    zipCodesByCity.get(city).add(md.Zip_Code__c);
                }
            }

            zipCodeMetadata = JSON.serialize(zipCodesByCity);
        } catch (Exception e) {
            System.debug('Error: Couldn\'t get Zip_Code__mdt. Message: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }

        return zipCodeMetadata;
    }

    /**
     * Create a new Application Note.
     *
     * @param application Application related to the new Application Note.
     */
    public static void createApplicationNote(Application__c application) {
        if (String.isNotBlank(application.Notes__c)) {
            insert new Application_Note__c(
                    Application__c = application.Id,
                    Additional_Comments_Note__c = application.Notes__c,
                    Public__c = true);
        }
    }

    /**
     * Create a new Application Note.
     *
     * @param appId The Id of application related to the new application note.
     * @param actionType Action type of note.
     * @param isPublic True if note would be public, otherwise false.
     * @param note Note description.
     */
    public static void createApplicationNote(Id appId, String actionType, Boolean isPublic, String note) {
        insert new Application_Note__c(
                Application__c = appId,
                Action_Type__c = actionType,
                Public__c = isPublic,
                Note__c = note);
    }

}