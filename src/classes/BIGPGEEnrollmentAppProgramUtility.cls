/**
 * This class has utility methods for Application Enrollment Program object.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-01
 */
public with sharing class BIGPGEEnrollmentAppProgramUtility {

    public static final String PROGRAM_PENDING_STATUS = 'Pending Review';
    public static final String PROGRAM_APPROVED_STATUS = 'Approved';
    public static final String PROGRAM_REQUEST_INFO_STATUS = 'Requested More Info';
    public static final String PROGRAM_REJECTED_STATUS = 'Rejected';
    public static final String PROGRAM_ALREADY_ENROLLED_STATUS = 'Already Enrolled';
    public static final String PROGRAM_EXPIRED_STATUS = 'Expired';
    public static final String PROGRAM_UNUSED_STATUS = 'Unused';
    public static final String APP_PRG_HU_RT_NAME = 'HU';
    public static final String APP_PRG_AHU_RT_NAME = 'AHU';
    public static final String APP_PRG_ACQC_RT_NAME = 'ACQC';
    public static Id APP_PRG_HU_RT_ID;
    public static Id APP_PRG_AHU_RT_ID;
    public static Id APP_PRG_ACQC_RT_ID;
    public static Map<String, String> appPrgRecordTypeIdToRecordTypeName = new Map<String, String>();
    public static Map<String, String> appPrgRecordTypeNameToRecordTypeId = new Map<String, String>();

    static {
        setApplicationProgramEnrollmentRecordTypeMaps();
        setApplicationProgramEnrollmentRecordTypeIds();
    }

    /**
     * Set application program enrollment record type maps
     */
    private static void setApplicationProgramEnrollmentRecordTypeMaps() {
        Map<String, Schema.RecordTypeInfo> appPrgSchema =
                Schema.SObjectType.Application_Program_Enrollment__c.getRecordTypeInfosByName();

        for (String programType : new List<String>{APP_PRG_HU_RT_NAME, APP_PRG_AHU_RT_NAME, APP_PRG_ACQC_RT_NAME}) {
            appPrgRecordTypeIdToRecordTypeName.put(appPrgSchema.get(programType).getRecordTypeId(), programType);
            appPrgRecordTypeNameToRecordTypeId.put(programType, appPrgSchema.get(programType).getRecordTypeId());
        }
    }

    /**
     * Set application program enrollment record type ids
     */
    private static void setApplicationProgramEnrollmentRecordTypeIds() {
        APP_PRG_HU_RT_ID = appPrgRecordTypeNameToRecordTypeId.get(APP_PRG_HU_RT_NAME);
        APP_PRG_AHU_RT_ID = appPrgRecordTypeNameToRecordTypeId.get(APP_PRG_AHU_RT_NAME);
        APP_PRG_ACQC_RT_ID = appPrgRecordTypeNameToRecordTypeId.get(APP_PRG_ACQC_RT_NAME);
    }

    /**
     * Deletes all records related to an Enrollment Application
     *
     * @param appsEnrollment list of enrollment applications
     * @param appsPgrEnrollment list of program enrollments
     * @param hasCompanyTypeChanged if true it deletes all the related records but keeps the Owner/Primary Contact staff
     */
    public static void deleteApplicationProgramEnrollment(List<Application_Enrollment__c> appsEnrollment,
            List<Application_Program_Enrollment__c> appsPgrEnrollment, boolean hasCompanyTypeChanged) {

        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();
        List<Database.SaveResult> updateResults = new List<Database.SaveResult>();
        List<Document__c> documentsToDelete = new List<Document__c>();
        List<Program_Enrollment_Staff_Review__c> programStaffReviews = new List<Program_Enrollment_Staff_Review__c>();
        List<Enrollment_Application_Review__c> enrollmentReviews = new List<Enrollment_Application_Review__c>();
        List<Application_Program_Enrollment_Review__c> programReviews = new List<Application_Program_Enrollment_Review__c>();
        List<License__c> licenses = new List<License__c>();
        List<Agreement__c> agreements = new List<Agreement__c>();
        List<Staff__c> staffToReset = new List<Staff__c>();
        Set<Staff__c> ownerPrimaryStaff = new Set<Staff__c>();
        Set<Id> staffToDelete = new Set<Id>();

        try {
            // Get Enrollment Application Reviews
            enrollmentReviews = [
                SELECT Id
                FROM Enrollment_Application_Review__c
                WHERE Enrollment_Application__r.Id IN :appsEnrollment
                ];
        } catch (QueryException e) {
            System.debug('Error retrieving existing application review: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving existing application review: ' + e.getMessage());
        }

        try {
            // Get Program Enrollment Reviews
            programReviews = [
                SELECT Id
                FROM Application_Program_Enrollment_Review__c
                WHERE Program_Enrollment__r.Id IN :appsPgrEnrollment
                ];

            // Get Program Application Staff Reviews for Owner/Primary Contact
            programStaffReviews = [
                SELECT Id
                FROM Program_Enrollment_Staff_Review__c
                WHERE Enrollment_Application_Review__c IN :enrollmentReviews
                    OR (Program_Enrollment__c IN :programReviews
                    AND Staff__r.Role__c INCLUDES (:BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE,
                                                   :BIGPGEEnrollmentStaffUtility.OWNER_ROLE))
                ];
        } catch (Exception e) {
            System.debug('Error retrieving existing application|program staff review: ' + e.getMessage());
        }

        try {
            // Get Program Enrollment Staff
            List<Application_Program_Enrollment_Staff__c> programStaff = [
                SELECT Id, Role__c, Staff__r.Id
                FROM Application_Program_Enrollment_Staff__c
                WHERE Application_Program_Enrollment__c IN :appsPgrEnrollment
                ];

            // Get Owner/Primary Contact
            Map<Id, Staff__c> enrollmentStaffMap = new Map<Id, Staff__c>([
                SELECT Id
                FROM Staff__c
                WHERE Application_Enrollment__c IN :appsEnrollment
                ]);

            // Keep Owner/Primary Contact when company type is changed
            // If the enrollment application is to be deleted, add the Owner/Primary Contact for deletion
            if (hasCompanyTypeChanged) {
                for (Application_Program_Enrollment_Staff__c progStaff : programStaff) {
                    if (!progStaff.Role__c.Contains(BIGPGEEnrollmentStaffUtility.OWNER_ROLE)
                            && !progStaff.Role__c.Contains(BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE)) {
                        staffToDelete.add(progStaff.Staff__r.Id);
                    } else {
                        // Retain Owner/Primary Contact to delete their documents and reset their HVAC/BPI values
                        ownerPrimaryStaff.add(progStaff.Staff__r);
                    }
                }
                // Reset Owner/Primary Contact fields to null
                staffToReset = BIGPGEEnrollmentStaffUtility.resetOwnerPrimaryStaffFieldValues(ownerPrimaryStaff);
            } else {
                for (Application_Program_Enrollment_Staff__c progStaff : programStaff) {
                    staffToDelete.add(progStaff.Staff__r.Id);
                }
                if (programStaff.isEmpty()) {
                    staffToDelete.addAll(enrollmentStaffMap.keySet());
                }
            }
        } catch (QueryException e) {
            System.debug('Error retrieving staff: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving staff: ' + e.getMessage());
        }

        // Get all Insurance documents + Primary/Owner documents (if needed)
        // If the company type is changed, there is a need to delete the Owner/PPC documents since these staff members
        // remain in the application.
        String query = 'SELECT Id, (SELECT Id FROM Attachments)' +
            ' FROM Document__c' +
            ' WHERE Application_Enrollment__r.Id IN :appsEnrollment';
        query += hasCompanyTypeChanged ? ' OR Staff__r.Id IN :ownerPrimaryStaff' : '';
        documentsToDelete = (List<Document__c>)Database.query(query);

        try {
            // Get Agreements
            agreements = [
                SELECT Id
                FROM Agreement__c
                WHERE Agreement__c.Id IN (
                    SELECT Agreement__c
                    FROM Application_Program_Enrollment_Agreement__c
                    WHERE Application_Program_Enrollment__r.Id IN :appsPgrEnrollment)
                ];
        } catch (QueryException e) {
            System.debug('Error retrieving existing agreement: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving existing agreement: ' + e.getMessage());
        }

        try {
            // Get Licenses
            licenses = [
                SELECT Id
                FROM License__c
                WHERE License__c.Id IN (
                    SELECT License__c
                    FROM Application_Program_Enrollment_License__c
                    WHERE Application_Program_Enrollment__r.Id IN :appsPgrEnrollment)
                ];
        } catch (QueryException e) {
            System.debug('Error retrieving licenses: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving licenses: ' + e.getMessage());
        }

        try {
            // Delete all records
            if (!documentsToDelete.isEmpty()) {
                deleteResults = BIGPGEEnrollmentDocumentUtility.deleteDocuments(documentsToDelete);
            }
            if (!staffToReset.isEmpty()) {
                updateResults = Database.update(staffToReset, true);
            }
            if (!programStaffReviews.isEmpty()) {
                deleteResults = Database.delete(programStaffReviews, true);
            }
            if (!enrollmentReviews.isEmpty()) {
                deleteResults = Database.delete(enrollmentReviews, true);
            }
            if (!programReviews.isEmpty()) {
                deleteResults = Database.delete(programReviews, true);
            }
            if (!staffToDelete.isEmpty()) {
                deleteResults = Database.delete([SELECT Id FROM Staff__c WHERE Id IN :staffToDelete], true);
            }
            if (!agreements.isEmpty()) {
                deleteResults = Database.delete(agreements, true);
            }
            if (!licenses.isEmpty()) {
                deleteResults = Database.delete(licenses, true);
            }
            if (!appsPgrEnrollment.isEmpty()) {
                deleteResults = Database.delete(appsPgrEnrollment, true);
            }
        } catch (QueryException e) {
            System.debug('Error on deletion section: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error on deletion section: ' + e.getMessage());
        }
    }

    /**
     * Filters the enrollment applications to determine which type of deletion should be applied, full or partial.
     *
     * @param oldEnrollmentApp list of enrollment applications (old versions)
     * @param newEnrollmentApp list of enrollment applications (new versions)
     */
    public static void processApplicationProgramEnrollment(List<Application_Enrollment__c> oldEnrollmentApp, 
           List<Application_Enrollment__c> newEnrollmentApp) {

        List<Application_Enrollment__c> appsToProcess = new List<Application_Enrollment__c>();
        List<Application_Program_Enrollment__c> programsToProcess = new List<Application_Program_Enrollment__c>();
        Boolean hasCompanyTypeChanged;

        try {
            if (newEnrollmentApp != null && !newEnrollmentApp.isEmpty()) {
                hasCompanyTypeChanged = true;
                for (Integer i = 0; i < oldEnrollmentApp.size(); i++) {
                    String oldCompanyType = oldEnrollmentApp.get(i).Type__c;
                    String newCompanyType = newEnrollmentApp.get(i).Type__c;
                    if (String.isNotEmpty(oldCompanyType) && String.isNotEmpty(newCompanyType)
                                && (oldCompanyType != newCompanyType)) {
                        appsToProcess.add(newEnrollmentApp.get(i));
                    }
                }
            } else {
                hasCompanyTypeChanged = false;
                for (Integer i = 0; i < oldEnrollmentApp.size(); i++) {
                    appsToProcess.add(oldEnrollmentApp.get(i));
                }
            }
        } catch (Exception e) {
            System.debug('### Error BIGPGEEnrollmentAppProgramUtility.processApplicationProgramEnrollment: ' +
                    e.getMessage());
        }
        if (!appsToProcess.isEmpty()) {
            try {
                programsToProcess = [
                    SELECT Id
                    FROM Application_Program_Enrollment__c
                    WHERE Application_Enrollment__r.Id IN :appsToProcess
                    ];
            } catch (Exception e) {
                System.debug('### Error while retrieving enrollment programs: ' + + e.getMessage());
            }
            BIGPGEEnrollmentAppProgramUtility.deleteApplicationProgramEnrollment(appsToProcess, programsToProcess, 
                    hasCompanyTypeChanged);
        }
    }

    /**
     * Filters program enrollments applications before sending them to the method that populates the enrollment programs
     * field of the enrollment application.
     *
     * @param oldEnrollmentApp list of program enrollment applications (old versions)
     * @param newEnrollmentApp list of program enrollment applications (new versions)
     * @return enrollmentPrgAppsToProcess list of filtered program enrollment applications
     */
    public static List<Application_Program_Enrollment__c> filterAppsToPopulateProgramEnrollments(
            List<Application_Program_Enrollment__c> oldProgramEnrollmentApps,
            List<Application_Program_Enrollment__c> newProgramEnrollmentApps) {

        List<Application_Program_Enrollment__c> programEnrollmentAppsToProcess = new List<Application_Program_Enrollment__c>();

        if (oldProgramEnrollmentApps != null && newProgramEnrollmentApps != null) {
            Map<Id, Application_Program_Enrollment__c> oldProgEnrollmentAppsById = 
                    new Map<Id, Application_Program_Enrollment__c>(oldProgramEnrollmentApps);

            for (Application_Program_Enrollment__c newProgramEnrollmentApp : newProgramEnrollmentApps) {
                Application_Program_Enrollment__c oldProgramEnrollmentApp = 
                        oldProgEnrollmentAppsById.get(newProgramEnrollmentApp.Id);

                if (oldProgramEnrollmentApp != null
                        && oldProgramEnrollmentApp.Status__c != newProgramEnrollmentApp.Status__c) {
                    programEnrollmentAppsToProcess.add(newProgramEnrollmentApp);
                }
            }
        }

        return programEnrollmentAppsToProcess;
    }

    /**
     * Sets the program enrollments multi-select picklist on the enrollment application.
     *
     * @param programEnrollmentApps list of program enrollment applications
     * @param isDelete boolean that determines that the programs should be deleted when it's value is true
     */
    public static void setProgramEnrollmentsField(List<Application_Program_Enrollment__c> programEnrollmentApps, 
            Boolean isDelete) {

        Map<String, Set<String>> programEnrollmentAppsToAdd = new Map<String, Set<String>>();
        Map<String, Set<String>> programEnrollmentAppsToRemove = new Map<String, Set<String>>();
        Set<String> enrollmentAppIds = new Set<String>();

        try {
            for (Application_Program_Enrollment__c programEnrollmentApp : programEnrollmentApps) {
                enrollmentAppIds.add(programEnrollmentApp.Application_Enrollment__c);
                String programType = appPrgRecordTypeIdToRecordTypeName.get(programEnrollmentApp.RecordTypeId);

                if (!isDelete && String.isNotBlank(programEnrollmentApp.Status__c)
                        && programEnrollmentApp.Status__c != PROGRAM_UNUSED_STATUS) {
                    // Add program
                    if (!programEnrollmentAppsToAdd.containsKey(programEnrollmentApp.Application_Enrollment__c)) {
                        programEnrollmentAppsToAdd.put(programEnrollmentApp.Application_Enrollment__c,
                                new Set<String>{programType});
                    } else {
                        programEnrollmentAppsToAdd.get(programEnrollmentApp.Application_Enrollment__c).add(programType);
                    }
                } else {
                    // Remove program
                    if (!programEnrollmentAppsToRemove.containsKey(programEnrollmentApp.Application_Enrollment__c)) {
                        programEnrollmentAppsToRemove.put(programEnrollmentApp.Application_Enrollment__c,
                                new Set<String>{programType});
                    } else {
                        programEnrollmentAppsToRemove.get(programEnrollmentApp.Application_Enrollment__c).add(programType);
                    }
                }
            }

            if (!programEnrollmentAppsToAdd.isEmpty() || !programEnrollmentAppsToRemove.isEmpty()) {
                List<Application_Enrollment__c> applicationEnrollments = [
                    SELECT Id, Program_Enrollments__c
                    FROM Application_Enrollment__c
                    WHERE Application_Enrollment__c.Id IN :enrollmentAppIds
                    ];

                for (Application_Enrollment__c applicationEnrollment : applicationEnrollments) {
                    Set<String> auxPrograms = new Set<String>();
                    if (applicationEnrollment.Program_Enrollments__c != null) {
                        // Add existing programs
                        auxPrograms.addAll(applicationEnrollment.Program_Enrollments__c.split(';'));
                    }
                    if (!programEnrollmentAppsToAdd.isEmpty()) {
                        // Add program enrollments
                        auxPrograms.addAll(programEnrollmentAppsToAdd.get(applicationEnrollment.Id));
                    }
                    if (!programEnrollmentAppsToRemove.isEmpty()) {
                        // Remove program enrollments
                        auxPrograms.removeAll(programEnrollmentAppsToRemove.get(applicationEnrollment.Id));
                    }
                    List<String> processedPrograms = new List<String>(auxPrograms);
                    applicationEnrollment.Program_Enrollments__c = String.join(processedPrograms, ';');
                }

                update applicationEnrollments;
            }
        } catch (QueryException e) {
            System.debug('### QueryException caught while retrieving existing programs enrollments: ' + e.getMessage());
        } catch (DmlException e) {
            System.debug('### DmlException caught while updating programs enrollments: ' + e.getMessage());
        }
    }
}