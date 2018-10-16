/**
 * This class implements the actions of the PG&E Application Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-02
 */
public with sharing class BIGPGEEnrollmentRetrieveAppExtension {
    // Constants
    @TestVisible
    private static String ENROLLMENT_APPLICATION_NOT_FOUND_ERROR = 'The Enrollment Application Number or Security Code are wrong';

    public BIGPGEEnrollmentRetrieveAppExtension(BIGPGEEnrollmentController controller) {}

    /**
     * This method tries to find an existing enrollment application with the data supplied by the user.
     *
     * @param appName The enrollment application name. It cannot be empty.
     * @param secureCode The security code that was generated when the user saved the application the first
     * time. It cannot be empty.
     * @return A response object containing the enrollment application if all goes well. Otherwise a message
     * error.
     */
    @RemoteAction
    public static BIGPGEEnrollmentResponseWrapper retrieveEnrollmentApplication(String appName, String secureCode) {
        Application_Enrollment__c app;
        BIGPGEEnrollmentResponseWrapper response = new BIGPGEEnrollmentResponseWrapper();

        try {
            // Check if application name and secure code were supplied.
            if (String.isNotEmpty(appName) && String.isNotEmpty(secureCode)) {
                app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByNameAndSecurityCode(appName, secureCode);
            }

            if (app == null) {
                throw new applicationException(ENROLLMENT_APPLICATION_NOT_FOUND_ERROR);
            }

            if (!BIGPGEEnrollmentApplicationUtility.isRetrievableEnrollmentApplication(app)) {
                throw new applicationException(BIGPGEEnrollmentApplicationUtility.ENROLLMENT_APPLICATION_STATUS_ERROR);
            }

            BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
            update app;
            response.responseData = app;
            response.success = true;
        } catch (Exception e) {
            System.debug('####:Error trying to update Enrollment Application: ' + e.getMessage());
            response.success = false;
            response.message= e.getMessage();
        }

        return response;
    }

    /** Custom Exception Class **/
    public class applicationException extends Exception {}

}