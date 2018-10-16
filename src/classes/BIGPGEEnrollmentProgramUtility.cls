/**
 * This class has utility methods for Program Enrollment object.
 *
 * @author Pablo Vigil pablo.vigil@modelitsoftware.com
 * @since 2015-02
 */
public with sharing class BIGPGEEnrollmentProgramUtility {

    public static final String PROGRAM_ENROLLMENT_HU_RT_NAME = 'HU';
    public static final String PROGRAM_ENROLLMENT_AHU_RT_NAME = 'AHU';
    public static final String PROGRAM_ENROLLMENT_ACQC_RT_NAME = 'ACQC';
    public static String PRG_HU_RT_ID;
    public static String PRG_AHU_RT_ID;
    public static String PRG_ACQC_RT_ID;

    static {
        setProgramEnrollmentRecordTypeIds();
    }

    private static void setProgramEnrollmentRecordTypeIds() {
        try {
            Map<String,Schema.RecordTypeInfo> appPrgSchema = 
                    Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName();
            PRG_HU_RT_ID = appPrgSchema.get(PROGRAM_ENROLLMENT_HU_RT_NAME).getRecordTypeId();
            PRG_AHU_RT_ID = appPrgSchema.get(PROGRAM_ENROLLMENT_AHU_RT_NAME).getRecordTypeId();
            PRG_ACQC_RT_ID = appPrgSchema.get(PROGRAM_ENROLLMENT_ACQC_RT_NAME).getRecordTypeId();
        } catch (Exception e) {
            System.debug('################ ' + e.getMessage());
            //errorMsg = PROGRAM_ENROLLMENT_RT_ERROR;
        }
    }

    public static Set<String> getEnrolledProgramsByAccount(Account usrAccount) {
        Set<String> enrolledPrograms = new Set<String>();
        try {
            // If Company is Rater, we do not need to check for enrolled programs.
            // Since the user has been logged we assume that it's already enrolled to all the programs available.
            if (usrAccount.RecordType.Name == BIGPGEEnrollmentUtility.APP_PARTICIPANT_CONTRACTOR) {
                for (Program_Enrollment__c prgEnrollment : usrAccount.Program_Enrollments__r) {
                    if (prgEnrollment.RecordTypeId == PRG_HU_RT_ID) {
                        enrolledPrograms.add(PROGRAM_ENROLLMENT_HU_RT_NAME);
                    } else if (prgEnrollment.RecordTypeId == PRG_AHU_RT_ID) {
                        enrolledPrograms.add(PROGRAM_ENROLLMENT_AHU_RT_NAME);
                    } else {
                        enrolledPrograms.add(PROGRAM_ENROLLMENT_ACQC_RT_NAME);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('###### ' + e.getMessage());
        }

        return enrolledPrograms;
    }

}