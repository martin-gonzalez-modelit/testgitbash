/**
 * Triggers for Enrollment Application Staff records.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-01
 *
 */
trigger StaffTrigger on Staff__c (before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            BIGPGEEnrollmentStaffUtility.deleteStaffRelatedObjects(Trigger.old);
        }
    }
}