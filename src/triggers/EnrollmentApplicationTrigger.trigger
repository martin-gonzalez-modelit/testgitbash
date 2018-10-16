/**
 * Triggers for Enrollment Application records.
 *
 * @author Pablo Vigil pablo.vigil@modelitsoftware.com
 * @since 2015-01
 *
 */
trigger EnrollmentApplicationTrigger on Application_Enrollment__c (before update, before delete, after update) {

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            BIGPGEEnrollmentAppProgramUtility.processApplicationProgramEnrollment(Trigger.old, Trigger.new);
        }
    }
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            BIGPGEEnrollmentAppProgramUtility.processApplicationProgramEnrollment(Trigger.old, null);
        }
    }

}