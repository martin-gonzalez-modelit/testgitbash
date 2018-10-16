/**
 * This controller implements the actions of the PG&E Application Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentController {

    public String sid { get; set; }
    public String links { get; set; }

    public BIGPGEEnrollmentController() {
        try {
            System.debug('### getBaseCustomUrl(): ' + Site.getBaseCustomUrl());
            System.debug('### getBaseRequestUrl(): ' + Site.getBaseRequestUrl());
            System.debug('### getBaseUrl(): ' + Site.getBaseUrl());
            System.debug('### getDomain(): ' + Site.getDomain());
            System.debug('### getOriginalUrl(): ' + Site.getOriginalUrl());
            System.debug('### getPathPrefix(): ' + Site.getPathPrefix());
            // Generate Session Id to upload attachments with the ajax toolkit.
            sid = BIGPGEEnrollmentLoginUtility.getSessionId();
            links = String.escapeSingleQuotes(JSON.serialize(BIGPGEEnrollmentUtility.getPortalLinks()));
        } catch (SalesforceLoginUtility.SalesforceLoginUtilityException e) {
            System.debug('Exception type caught: ' + e.getTypeName());
            System.debug('Message: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('Exception type caught: ' + e.getTypeName());
            System.debug('Message: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }

}