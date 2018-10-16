/**
 * This class implements the actions of the PG&E Application Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-02
 */
public with sharing class BIGPGEEnrollmentResendEmailExtension {
    // Constants
    @TestVisible
    private static String EMAIL_ADDRESS_NOT_FOUND_ERROR = 'We did not find any pending enrollment applications associated with the email address you have provided.';

    @TestVisible
    private static String EMAIL_CONFIRMATION_MESSAGE = 'A confirmation email has been sent to the address you have provided.';

    public BIGPGEEnrollmentResendEmailExtension(BIGPGEEnrollmentController controller) {}

    /**
     * This method sends an email to the enrollment application owner or primary contact.
     *
     * @param email The enrollment application recipient email address. It cannot be empty.
     * @return A response object containing the enrollment application if all goes well. Otherwise a message
     * error.
     */
    @RemoteAction
    public static BIGPGEEnrollmentResponseWrapper sendEmailToRecipient(String email) {
        List<Application_Enrollment__c> apps = new List<Application_Enrollment__c>();
        BIGPGEEnrollmentResponseWrapper response = new BIGPGEEnrollmentResponseWrapper();

        try {
            // Check if email address was supplied.
            if (String.isNotEmpty(email)) {
                apps = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByEmail(email);
            }

            if (apps.isEmpty()) {
                throw new applicationException(EMAIL_ADDRESS_NOT_FOUND_ERROR);
            }
            // Set field to false, so the email alert workflow will get triggered again.
            for (Application_Enrollment__c app : apps) {
                app.Email_Sent__c = false;
            }
            update apps;
            response.responseData = apps;
            response.success = true;
            response.message = EMAIL_CONFIRMATION_MESSAGE;
        } catch (Exception e) {
            System.debug('####:Error trying to update Enrollment Application: ' + e.getMessage());
            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    /** Custom Exception Class **/
    public class applicationException extends Exception {}

}