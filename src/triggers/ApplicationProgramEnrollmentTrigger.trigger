/**
 * Triggers for Application Program Enrollment records.
 *
 * @author Pablo Vigil pablo.vigil@modelitsoftware.com
 * @since 2015-01
 *
 */
trigger ApplicationProgramEnrollmentTrigger on Application_Program_Enrollment__c (before delete, after insert, after update) {

    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            BIGPGEEnrollmentAppProgramUtility.setProgramEnrollmentsField(Trigger.old, true);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            BIGPGEEnrollmentAppProgramUtility.setProgramEnrollmentsField(Trigger.new, false);
        } else if (Trigger.isUpdate) {
            BIGPGEEnrollmentAppProgramUtility.setProgramEnrollmentsField(
                    BIGPGEEnrollmentAppProgramUtility.filterAppsToPopulateProgramEnrollments(Trigger.old, Trigger.new), false);
        }
    }
}