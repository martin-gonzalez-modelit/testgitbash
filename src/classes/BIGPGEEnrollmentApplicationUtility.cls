/**
 * This class it's an utility of the PG&E Application Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentApplicationUtility {

    public static final String ENROLLMENT_CREATED_STATUS = 'Created';
    public static final String ENROLLMENT_CHECKED_OUT_STATUS = 'Checked out';
    public static final String ENROLLMENT_PENDING_STATUS = 'Pending Review';
    public static final String ENROLLMENT_COMPLETED_STATUS = 'Fully Completed';
    public static final String ENROLLMENT_CANCELED_STATUS = 'Canceled';

    public static final String COMPANY_INFO_PENDING_STATUS = 'Pending Review';
    public static final String COMPANY_INFO_APPROVED_STATUS = 'Approved';
    public static final String COMPANY_INFO_REQUEST_INFO_STATUS = 'Requested More Info';
    public static final String COMPANY_INFO_REJECTED_STATUS = 'Rejected';
    public static final String COMPANY_INFO_EXPIRED_STATUS = 'Expired';

    public static final String APP_TYPE_CONTRACTOR = 'Contractor';
    public static final String APP_TYPE_INDIVIDUAL_RATER = 'Individual Rater';
    public static final String APP_TYPE_RATER = 'Rater Company';

    public static String ENROLLMENT_APPLICATION_STATUS_ERROR;
    
    public static String PGE_ENROLLMENT_SETTING_ERROR = 'Please define all the fields for the Custom Setting ' + 
            'PGEEnrollmentPortalSettings.';

    // Instantiate the class to log the errors.
    private static ErrorHandlingUtil errorLog = ErrorHandlingUtil.getInstance();
    private static PGE_Enrollment_Portal_Settings__c setting;

    static {
        initCustomSetting();
    }

    public static Application_Enrollment__c getEnrollmentApplicationByIdAndToken(String appId, String accessToken) {
        Application_Enrollment__c app = null;
        try {
            app = [SELECT Name, Type__c, Workers_Compensation_Type__c, Email_Sent__c, Account__c, Enrollment_Status__c,
                     Company_Info_Status__c, Auto_Liability_Insurance__c
                   FROM Application_Enrollment__c
                   WHERE Id =: appId AND Access_Token__c =: accessToken];
        } catch (Exception e) {
            System.debug('### BIGPGEEnrollment::getApplicationEnrollment - The following error has ocurred while ' +
                    'attempting to get the application enrollment: ' + e.getMessage());
        }

        return app;
    }

    public static Application_Enrollment__c getEnrollmentApplicationAndProgramsByIdAndToken(String appId, 
            String accessToken) {

        Application_Enrollment__c app = null;
        try {
            app = [
                SELECT Name, Type__c, Workers_Compensation_Type__c, Email_Sent__c, Account__c, Enrollment_Status__c,
                    Company_Info_Status__c, Auto_Liability_Insurance__c, Company_Name__c, Website__c, Address__c, City__c,
                    State__c, Zip_Code__c, EIN_or_SSN__c, Service_Territory__c, Tax_Status__c, DBA__c,
                    (SELECT Id, Status__c FROM Applications_Program_Enrollment__r)
                FROM Application_Enrollment__c
                WHERE Id =: appId AND Access_Token__c =: accessToken
                ];
        } catch (QueryException e) {
            System.debug('### BIGPGEEnrollment::getApplicationEnrollment - The following error has ocurred while ' +
                    'attempting to get the application enrollment: ' + e.getMessage());
        }

        return app;
    }

    public static Application_Enrollment__c getEnrollmentApplicationByNameAndSecurityCode(String appName, 
            String secureCode) {

        Application_Enrollment__c app = null;
        try {
            app = [SELECT Name, Type__c, Workers_Compensation_Type__c, Email_Sent__c, Security_Code__c,
                       Enrollment_Status__c, Company_Info_Status__c, Auto_Liability_Insurance__c, 
                       (SELECT Id, Status__c FROM Applications_Program_Enrollment__r)
                   FROM Application_Enrollment__c
                   WHERE Name =: appName AND Security_Code__c =: secureCode];
        } catch (Exception e) {
            System.debug('### BIGPGEEnrollment::getApplicationEnrollment - The following error has ocurred while ' + 
                    'attempting to get the application enrollment: ' + e.getMessage());
        }

        return app;
    }

    public static List<Application_Enrollment__c> getEnrollmentApplicationByEmail(String email) {
        List<Application_Enrollment__c> apps = null;
        try {
            apps = [SELECT Name, Type__c, Workers_Compensation_Type__c, Email_Sent__c, Security_Code__c,
                        Auto_Liability_Insurance__c
                    FROM Application_Enrollment__c
                    WHERE Email_Recipient__c =: email
                    AND Enrollment_Status__c !=: ENROLLMENT_CANCELED_STATUS
                    AND Enrollment_Status__c !=: ENROLLMENT_COMPLETED_STATUS
                    AND Company_Info_Status__c !=: COMPANY_INFO_REJECTED_STATUS
                    AND Company_Info_Status__c !=: COMPANY_INFO_EXPIRED_STATUS];
        } catch (Exception e) {
            System.debug('### BIGPGEEnrollment::getApplicationEnrollment - The following error has ocurred while ' + 
                    'attempting to get the application enrollment: ' + e.getMessage());
        }

        return apps;
    }

    public static void setEnrollmentApplicationToken(Application_Enrollment__c app) {
        app.Access_Token__c = BIGPGEEnrollmentUtility.getRandomToken(app.Id);
    }

    public static void removeEnrollmentApplicationToken(Application_Enrollment__c app) {
        app.Access_Token__c = null;
    }

    public static Boolean isRetrievableEnrollmentApplication(Application_Enrollment__c app) {
        Boolean isEditable = false;

        if (app.Enrollment_Status__c == ENROLLMENT_CREATED_STATUS ||
                app.Enrollment_Status__c == ENROLLMENT_PENDING_STATUS) {
            isEditable = BIGPGEEnrollmentApplicationUtility.isReturnedForCorrectionEnrollmentApplication(app);
        }

        return isEditable;
    }

    public static Boolean isReturnedForCorrectionEnrollmentApplication(Application_Enrollment__c app) {
        Boolean returned = false;

        if (app.Enrollment_Status__c == ENROLLMENT_PENDING_STATUS) {
            if (app.Company_Info_Status__c == COMPANY_INFO_REQUEST_INFO_STATUS) {
                returned = true;
            } else if (app.Company_Info_Status__c == COMPANY_INFO_APPROVED_STATUS) {
                for (Application_Program_Enrollment__c appPrg : app.Applications_Program_Enrollment__r) {
                    if (appPrg.Status__c == BIGPGEEnrollmentAppProgramUtility.PROGRAM_REQUEST_INFO_STATUS) {
                        returned = true;
                        break;
                    }
                }
            }
        } else {
           returned = true;
        }

        return returned;
    }

    public static Boolean hasPendingReviewEnrollmentApplication(Application_Enrollment__c app) {
        Boolean hasPending = false;

        if (app.Enrollment_Status__c == ENROLLMENT_CHECKED_OUT_STATUS ||
                app.Enrollment_Status__c == ENROLLMENT_PENDING_STATUS) {
            if (app.Enrollment_Status__c == ENROLLMENT_CHECKED_OUT_STATUS) {
                hasPending = true;
            } else {
                if (app.Company_Info_Status__c == COMPANY_INFO_PENDING_STATUS) {
                    hasPending = true;
                } else if (app.Company_Info_Status__c == COMPANY_INFO_APPROVED_STATUS) {
                    for (Application_Program_Enrollment__c appPrg : app.Applications_Program_Enrollment__r) {
                        if (appPrg.Status__c == BIGPGEEnrollmentAppProgramUtility.PROGRAM_PENDING_STATUS) {
                            hasPending = true;
                            break;
                        }
                    }
                }
            }
        }

        return hasPending;
    }

    public static void setEnrollmentApplicationToPendingReview(Application_Enrollment__c app) {
        List<SObject> appsToUpdate = new List<SObject>();
        List<Application_Program_Enrollment__c> appPgrsTodelete = new List<Application_Program_Enrollment__c>();

        try {
             // If the list of the application programs it is empty, it would mean that didn't come with the aggregates.
            if (app.Applications_Program_Enrollment__r.isEmpty()) {
                app = [SELECT Enrollment_Status__c, Company_Info_Status__c,
                          (SELECT Id, Status__c FROM Applications_Program_Enrollment__r)
                       FROM Application_Enrollment__c
                       WHERE Id =: app.Id];
            }
            // Set enrollment status to Pending Review just when the application has been created.
            if (app.Enrollment_Status__c == ENROLLMENT_CREATED_STATUS) {
                app.Enrollment_Status__c = ENROLLMENT_PENDING_STATUS;
            }
            if (app.Company_Info_Status__c == COMPANY_INFO_REQUEST_INFO_STATUS) {
                app.Company_Info_Status__c = COMPANY_INFO_PENDING_STATUS;
            }

            // Remove the access token from enrollment application once is ready for review.
            BIGPGEEnrollmentApplicationUtility.removeEnrollmentApplicationToken(app);
            appsToUpdate.add(app);

            for (Application_Program_Enrollment__c appPrg : app.Applications_Program_Enrollment__r) {
                if (appPrg.Status__c == BIGPGEEnrollmentAppProgramUtility.PROGRAM_REQUEST_INFO_STATUS) {
                    appPrg.Status__c = BIGPGEEnrollmentAppProgramUtility.PROGRAM_PENDING_STATUS;
                    appsToUpdate.add(appPrg);
                // We need to delete the application programs with unused status once the user submits
                // the enrollment application.
                /*} else if (appPrg.Status__c == BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS) {
                    appPgrsTodelete.add(appPrg);*/
                }
            }

            if (!appsToUpdate.isEmpty()) {
                update appsToUpdate;
            }
            if (!appPgrsTodelete.isEmpty()) {
                //BIGPGEEnrollmentAppProgramUtility.deleteApplicationProgramEnrollment(appPgrsTodelete);
            }
        } catch (Exception e) {
            System.debug('### Error: ' + e.getMessage());
        }
    }

    public static Boolean hasDuplicateAccountInfo(String taxId) {
        List<Account> accs = new List<Account>([SELECT Id FROM Account WHERE Tax_ID_Number__c =: taxId]);
        return accs.size() > 0;
    }

    /**
     * Loads the values set on the custom setting.
     *
     */
    private static void initCustomSetting() {
        String contactEmail;
        setting = PGE_Enrollment_Portal_Settings__c.getInstance(BIGPGEEnrollmentLoginUtility.PGE_ENROLLMENT_SETTING_DATA_SET);

        if (setting == null || setting.ContactEmail__c == null) {
            errorLog.logDebug('BIGPGEEnrollmentLoginUtility', 'initCustomSetting', PGE_ENROLLMENT_SETTING_ERROR,'');
            // Set an email by default if its not defined.
            contactEmail = 'enrollment@homeupgrade.org';
        } else {
            contactEmail = setting.ContactEmail__c;
        }

        ENROLLMENT_APPLICATION_STATUS_ERROR = 'We cannot retrieve your application since it is not ' +
                'available for editing. If you need help, please email ' + contactEmail + ' or call (866) 970-7348.';
    }

    /**
     * Checks if there is a change of company type
     *
     * @param newApplication the enrollment application to be upserted
     * @return boolean indicating if the company type has changed
     */
    public static Boolean hasCompanyTypeChanged(Application_Enrollment__c newApplication) {
        Application_Enrollment__c oldApplication = new Application_Enrollment__c();
        try {
            oldApplication = [SELECT Type__c FROM Application_Enrollment__c WHERE Id = :newApplication.Id];
        } catch (QueryException e) {
            System.debug('Error retrieving enrollment application type: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving enrollment application type: ' + e.getMessage());
        }
        return oldApplication.Type__c != newApplication.Type__c;
    }
}