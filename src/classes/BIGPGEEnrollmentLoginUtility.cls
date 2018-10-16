/**
 * This utility implements the actions of the PG&E Application Enrollment Portal Login Page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentLoginUtility {
    // Constants.
    public static final String ALL_PROGRAMS_ENROLLED_ERROR = 'You are already enrolled for all programs.';
    public static final String USERNAME_PASSWORD_REQUIRED_ERROR = 'The username and password are required.';
    public static final String PGE_ENROLLMENT_SETTING_DATA_SET = 'PGEEnrollmentPortalSettings';

    // Instantiate the class to log the errors.
    private static ErrorHandlingUtil errorLog = ErrorHandlingUtil.getInstance();
    private static PGE_Enrollment_Portal_Settings__c setting;

    static {
        initCustomSetting();
    }

    /**
     * This method it is in charge to login the user if the credentials are right and if the account
     * associated to the user has not enrolled to all programs available.
     *
     * @param username The username entered by the user.
     * @param password The password entered by the user.
     * @return The response with success set to true. Otherwise false and the error msg.
     */
    public static BIGPGEEnrollmentResponseWrapper login(String username, String password) {
        BIGPGEEnrollmentResponseWrapper response = new BIGPGEEnrollmentResponseWrapper();
        response.success = true;

        PageReference page = Site.login(username, password, null);

        // If page not null it means user has logged in. Otherwise salesforce will add 
        // an error message to the current page reference.
        if (page != null) {
            BIGPGEEnrollmentUser pgeUser = new BIGPGEEnrollmentUser(username);
            if (!pgeUser.hasError()) {
                if (pgeUser.hasEnrolledAllPrograms()) {
                    // Add error message
                   BIGPGEEnrollmentUtility.addErrorMsg(ALL_PROGRAMS_ENROLLED_ERROR);
                } else if (pgeUser.hasPendingReview()) {
                    // Add error message
                    BIGPGEEnrollmentUtility.addErrorMsg(BIGPGEEnrollmentApplicationUtility.ENROLLMENT_APPLICATION_STATUS_ERROR);
                } else {
                    Application_Enrollment__c app = pgeUser.getApplicationEnrollment();
                    // If it's an existing application we need to set the token, otherwise
                    // will be set once the user save the application in the Company page.
                    if (app.Id != null) {
                        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
                        update app;
                    }
                    response.responseData = new LoginWrapper(app, pgeUser.getEnrolledPrograms());
                }
            } else {
                // Add error message
                BIGPGEEnrollmentUtility.addErrorMsg(pgeUser.getErrorMsg());
            }
        }

        // Check if there are errors and add the first one to the response result.
        if (ApexPages.hasMessages()) {
            response.success = false;
            response.message = ApexPages.getMessages().get(0).getSummary();
        }

        return response;
    }

    /**
     * Gets the session id with the credentials provided on the custom setting.
     *
     * @return The session id of the user. Otherwise an empty string.
     */
    public static String getSessionId() {
        String sid = '';

        // Check if there's no errors.
        if (errorLog.getErrorLogsToInsert().size() == 0) {
            SalesforceLoginUtility connection =
                    new SalesforceLoginUtility(setting.Username__c, setting.Password__c, setting.EndPointUrl__c);
            sid = connection.getSessionId();
        } else {
            // Insert log records.
            errorLog.logMessage();
        }

        return sid;
    }

    public class LoginWrapper {
        Application_Enrollment__c app;
        Set<String> enrolledPrograms;

        public LoginWrapper(Application_Enrollment__c app, Set<String> enrolledPrograms) {
            this.app = app;
            this.enrolledPrograms = enrolledPrograms;
        }
    }

    /**
     * Loads the values set on the custom setting.
     *
     */
    private static void initCustomSetting() {
        setting = PGE_Enrollment_Portal_Settings__c.getInstance(PGE_ENROLLMENT_SETTING_DATA_SET);

        if (setting == null || setting.Username__c == null || setting.Password__c == null
                || setting.EndPointURL__c == null || setting.DeadProgramEnrollmentStatuses__c == null
                || setting.DeadApplicationProgramEnrollmentStatuses__c == null) {

            errorLog.logDebug('BIGPGEEnrollmentLoginUtility', 'initCustomSetting', 
                    BIGPGEEnrollmentApplicationUtility.PGE_ENROLLMENT_SETTING_ERROR,'');
        }
    }
}