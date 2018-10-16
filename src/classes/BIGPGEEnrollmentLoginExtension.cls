/**
 * This class implements the actions of the PG&E Application Enrollment Portal Login Page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentLoginExtension {

    public BIGPGEEnrollmentLoginExtension(BIGPGEEnrollmentController controller) {}

    @RemoteAction
    public static BIGPGEEnrollmentResponseWrapper login(String username, String password) {
        BIGPGEEnrollmentResponseWrapper response = new BIGPGEEnrollmentResponseWrapper();

        try {
            if (String.isEmpty(username) || String.isEmpty(password)) {
                throw new applicationException(BIGPGEEnrollmentLoginUtility.USERNAME_PASSWORD_REQUIRED_ERROR);
            }
            response = BIGPGEEnrollmentLoginUtility.login(username, password);
        } catch (Exception e) {
            System.debug('### Error trying to do login: ' + e.getMessage());
            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    /** Custom Exception Class **/
    public class applicationException extends Exception {}
}