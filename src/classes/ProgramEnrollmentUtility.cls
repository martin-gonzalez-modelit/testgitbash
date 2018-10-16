/**
 * ProgramEnrollmentUtility is a utility class for the Program Enrollment object.
 *
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2015-10
 */
public with sharing class ProgramEnrollmentUtility {
    // Public Constants
    public static final String HU_RECORD_TYPE_NAME = 'HU';
    public static final String AHU_RECORD_TYPE_NAME = 'AHU';
    public static final String ACQC_RECORD_TYPE_NAME = 'ACQC';

    /**
     * Determines if a Program Enrollment of the given RecordType Name is present in a list of Program Enrollments
     *
     * @param programEnrollments the list of Program Enrollments inspect
     * @param recordTypeName the RecordType Name to inspect for
     * @return true if a Program Enrollment of the given RecordType Name is present in the list, else false
     */
    public static Boolean hasProgramEnrollment(List<Program_Enrollment__c> programEnrollments, String recordTypeName) {
        for (Program_Enrollment__c programEnrollment : programEnrollments) {
            if (programEnrollment.RecordType.Name == recordTypeName) {
                return true;
            }
        }
        return false;
    }
}