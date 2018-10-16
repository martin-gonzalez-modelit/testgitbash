/**
 * This class it's an utility of the PG&E Application Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentUser {
    private static String errorMsg = '';

    private Contact usrContact = null;
    private Account usrAccount = null;
    private String userName;
    private Id usrAccountId;
    private Application_Enrollment__c usrAppEnrollment = null;
    private List<Application_Enrollment__c> apps = null;
    private Boolean hasPendingReview = false;

    private static PGE_Enrollment_Portal_Settings__c setting;
    // Instantiate the class to log the errors.
    private static ErrorHandlingUtil errorLog = ErrorHandlingUtil.getInstance();

    static {
        initCustomSetting();
    }

    public BIGPGEEnrollmentUser(String username) {
        if (isValidCustomSetting()) {
            this.username = username;
            init();
        }
    }

    public BIGPGEEnrollmentUser(Id accId) {
        if (isValidCustomSetting()) {
            this.usrAccountId = accId;
            init();
        }
    }

    private void init() {
        // Get current user
        try {
            if (usrAccountId == null) {
                User u = [SELECT Contact.Id, Contact.AccountId
                          FROM User WHERE Username =: username AND isActive = true];
                usrContact = u.Contact;
                usrAccountId = u.Contact.AccountId;
            }
            usrAccount = [SELECT Id, RecordType.Name,
                            (SELECT Id, RecordTypeId FROM Program_Enrollments__r
                             WHERE Enrollment_Status__c NOT IN : getDeadProgramEnrollmentStatuses())
                          FROM Account WHERE Id =: usrAccountId];
            apps = [SELECT Id, Type__c, Security_Code__c, Enrollment_Status__c,
                        Company_Info_Status__c,
                        (SELECT Id, Status__c FROM Applications_Program_Enrollment__r)
                    FROM Application_Enrollment__c
                    WHERE Account__r.Id =: usrAccount.Id
                    AND (Enrollment_Status__c !=: BIGPGEEnrollmentApplicationUtility.ENROLLMENT_CANCELED_STATUS
                         AND Enrollment_Status__c !=: BIGPGEEnrollmentApplicationUtility.ENROLLMENT_COMPLETED_STATUS)];

            Boolean isRetrievable;
            for (Application_Enrollment__c app : apps) {
                isRetrievable = BIGPGEEnrollmentApplicationUtility.isRetrievableEnrollmentApplication(app);
                if (isRetrievable) {
                    usrAppEnrollment = app;
                } else if (BIGPGEEnrollmentApplicationUtility.hasPendingReviewEnrollmentApplication(app)) {
                    usrAppEnrollment = app;
                    hasPendingReview = true;
                }
            }
        } catch (Exception e) {
            System.debug('################ ' + e.getMessage());
            errorMsg = e.getMessage();
        }
    }

    public String getErrorMsg() {
        return errorMsg;
    }

    public Contact getContact() {
        return usrContact;
    }

    public Account getAccount() {
        return usrAccount;
    }

    public Application_Enrollment__c getApplicationEnrollment() {
        if (usrAppEnrollment == null) {
            usrAppEnrollment = 
                new Application_Enrollment__c(Account__c = usrAccount.Id,
                                              Type__c = BIGPGEEnrollmentUtility.APP_PARTICIPANT_CONTRACTOR);
        }
        return usrAppEnrollment;
    }

    public Set<String> getEnrolledPrograms() {
        return BIGPGEEnrollmentProgramUtility.getEnrolledProgramsByAccount(usrAccount);
    }

    public Boolean hasPendingReview() {
        return hasPendingReview;
    }

    public Boolean hasError() {
        return String.isNotEmpty(errorMsg);
    }

    public Boolean hasEnrolledAllPrograms() {
        Boolean allApproved = true;

        // If Company is Rater, we do not need to check for enrolled programs.
        // Since the user has been logged we assume that it's already enrolled to all the programs available.
        if (usrAccount.RecordType.Name == BIGPGEEnrollmentUtility.APP_PARTICIPANT_CONTRACTOR) {
            allApproved = getEnrolledPrograms().size() >= 3;
        }

        return allApproved;
    }

    /**
     * Loads the values set on the custom setting.
     *
     */
    private static void initCustomSetting() {
        setting = PGE_Enrollment_Portal_Settings__c.getInstance(BIGPGEEnrollmentLoginUtility.PGE_ENROLLMENT_SETTING_DATA_SET);

        if (setting == null || setting.Username__c == null || setting.Password__c == null ||
            setting.EndPointURL__c == null) {

            errorLog.logDebug('BIGPGEEnrollmentUser', 'initCustomSetting', 
                    BIGPGEEnrollmentApplicationUtility.PGE_ENROLLMENT_SETTING_ERROR,'');
            errorMsg = BIGPGEEnrollmentApplicationUtility.PGE_ENROLLMENT_SETTING_ERROR;
        }
    }

    private Boolean isValidCustomSetting() {
        return errorLog.getErrorLogsToInsert().size() == 0;
    }

    public static List<String> getDeadProgramEnrollmentStatuses() {
        List<String> deadProgramStatuses = new List<String>();
        if (String.isNotEmpty(setting.DeadProgramEnrollmentStatuses__c)) {
            deadProgramStatuses = setting.DeadProgramEnrollmentStatuses__c.split(';');
        }

        return deadProgramStatuses;
    }

}