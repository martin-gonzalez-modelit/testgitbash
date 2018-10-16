/**
 * This class has utility methods for the Document object.
 *
 * @author Pablo Vigil pablo.vigil@modelitsoftware.com
 * @since 2015-01
 *
 */
public with sharing class BIGPGEEnrollmentDocumentUtility {
    public static List<Database.DeleteResult> results;

    public static List<Database.DeleteResult> deleteDocuments(List<Document__c> docsToDelete) {
        try {
            // Delete all documents from docsToDelete list
            results = Database.delete(docsToDelete);
        } catch (Exception e) {
            System.debug('#### Error trying to delete documents: ' + e.getMessage());
        }
        return results;
    }

}