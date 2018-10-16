/**
 * Trigger for Enrollment Application Agreements records.
 *
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2016-02
 *
 */
trigger AgreementTrigger on Agreement__c (before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            BIGPGEEnrollmentAgreementUtility.deleteAgreementDocuments(Trigger.old);
        }
    }
}