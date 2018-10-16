/**
 * Trigger for Enrollment Application License records.
 *
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2016-02
 *
 */
trigger LicenseTrigger on License__c (before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            BIGPGEEnrollmentLicenseUtility.deleteLicenseDocuments(Trigger.old);
        }
    }
}