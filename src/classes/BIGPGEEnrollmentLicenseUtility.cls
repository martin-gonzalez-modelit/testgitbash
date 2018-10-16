/**
 * This class has utility methods for the License object.
 *
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2016-02
 *
 */
public with sharing class BIGPGEEnrollmentLicenseUtility {

    public static List<Database.DeleteResult> docDeleteResults;

    /**
     * Deletes all documents from the License object
     * @param licensesToDelete, list of licenses
     */
    public static void deleteLicenseDocuments(List<License__c> licensesToDelete) {
        try {
            // Get all license documents to delete
            List<License_Document__c> licenseDocsToDelete = [
                SELECT Document__c
                FROM License_Document__c
                WHERE License__c IN :licensesToDelete];

            if (!licenseDocsToDelete.isEmpty()) {
                 Set<Id> licDocsIds = new Set<Id>();
                 for (License_Document__c licenseDocToDelete : licenseDocsToDelete) {
                     licDocsIds.add(licenseDocToDelete.Document__c);
                 }
                 List<Document__c> documentsToDelete = [
                    SELECT Id, (SELECT Id FROM Attachments)
                    FROM Document__c
                    WHERE Id IN :licDocsIds];

                 if (!documentsToDelete.isEmpty()) {
                     docDeleteResults = BIGPGEEnrollmentDocumentUtility.deleteDocuments(documentsToDelete);
                 }
            }
        } catch (Exception e) {
            System.debug ('###### Error trying to delete license document: ' + e.getMessage());
        }
    }
}