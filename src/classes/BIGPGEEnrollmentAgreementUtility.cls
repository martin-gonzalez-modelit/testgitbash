/**
 * This class has utility methods for the Agreement object.
 *
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2016-02
 *
 */
public with sharing class BIGPGEEnrollmentAgreementUtility {

    public static List<Database.DeleteResult> docDeleteResults;

    /**
     * Deletes all documents from the Agreement object
     * @param agreementsToDelete, list of agreements
     */
    public static void deleteAgreementDocuments(List<Agreement__c> agreementsToDelete) {
        try {
            // Get all agreements documents to delete
            List<Document__c> documentsToDelete = [
                SELECT Id, (SELECT Id FROM Attachments)
                FROM Document__c
                WHERE Agreement__c IN :agreementsToDelete];

            if (!documentsToDelete.isEmpty()) {
                 docDeleteResults = BIGPGEEnrollmentDocumentUtility.deleteDocuments(documentsToDelete);
            }
        } catch (Exception e) {
            System.debug ('###### Error trying to delete agreement documents: ' + e.getMessage());
        }
    }
}