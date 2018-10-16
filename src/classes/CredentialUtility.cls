/**
 * CredentialUtility is a utility class for the Credential object.
 *
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2015-10
 */
public with sharing class CredentialUtility {
    
    /**
     * Filters and returns only the Credentials of the given Credential Type.
     *
     * @param credentials the list of Credentials to filter
     * @param credentialType the Credential Type to filter the Credentials by
     * @return a list of Credentials that is a subset of the given Credentials matching the given Credential Type
     */
    public static List<Credential__c> getCredentialsByCredentialType(List<Credential__c> credentials, String credentialType) {
        List<Credential__c> matches = new List<Credential__c>();    
        for (Credential__c credential : credentials) {
            if (credential.Credential_Type__c == credentialType) {
                matches.add(credential);
            }
        }
        return matches;
    }
    
    /**
     * Determines if a Credential of the given Credential Type is present in a list of Credentials
     *
     * @param credentials the list of Credentials to inspect
     * @param credentialType the Credential Type to inspect for
     * @return true if a Credential of the given Credential Type is present in the list, else false
     */
    public static Boolean hasCredential(List<Credential__c> credentials, String credentialType) {
        return !getCredentialsByCredentialType(credentials, credentialType).isEmpty();
    }
    
    /**
     * Determines if a Credential of the given Credential Type and Specialization is present in a list of Credentials
     *
     * @param credentials the list of Credentials to inspect
     * @param credentialType the Credential Type to inspect for
     * @param specialization the Specialization to inspect for
     * @return true if a Credential of the given Credential Type and Specialization is present in the list, else false
     */
    public static Boolean hasCredential(List<Credential__c> credentials, String credentialType, String specialization) {
        for (Credential__c credential : getCredentialsByCredentialType(credentials, credentialType)) {
            if (String.isNotBlank(credential.Specialization__c)
                  && credential.Specialization__c.contains(specialization)) {
                return true;
            }
        }
        return false;
    }
}