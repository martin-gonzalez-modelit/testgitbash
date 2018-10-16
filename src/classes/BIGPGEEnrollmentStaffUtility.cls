/**
 * This class has utility methods for the Staff object.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-01
 *
 */
public with sharing class BIGPGEEnrollmentStaffUtility {

    public static final String OWNER_ROLE = 'Owner';
    public static final String PRIMARY_PROGRAM_CONTACT_ROLE = 'Primary Program Contact';
    public static final String REBATE_ADMIN_ROLE = 'Rebate Administrator';
    public static final String SALESPERSON_ROLE = 'Salesperson';
    public static final String HERSII_ROLE = 'HERS II';
    public static final String BPI_CERT_PROF_ROLE = 'BPI Certified Professional';
    public static final String HVAC_TECHNICIAN_ROLE = 'HVAC Technician';
    public static List<Database.DeleteResult> docDeleteResults;

    /**
     * Deletes all records related to a Staff member
     * @param staffToDelete, list of Staff members
     */
    public static void deleteStaffRelatedObjects(List<Staff__c> staffToDelete) {
        // Delete staff documents
        List<Document__c> docsToDelete = new List<Document__c>();
        try {
            for (Staff__c staff : [SELECT Id, (SELECT Id FROM Documents__r) FROM Staff__c WHERE Id IN :staffToDelete]) {
                if (!staff.Documents__r.isEmpty()) {
                    docsToDelete.addAll(staff.Documents__r);
                }
            }
        } catch (Exception e) {
            System.debug('###### Error retrieving staff documents to delete: ' + e.getMessage());
        }

        if (!docsToDelete.isEmpty()) {
            docDeleteResults = BIGPGEEnrollmentDocumentUtility.deleteDocuments(docsToDelete);
        }

        // Delete staff reviews
        try {
            List<Program_Enrollment_Staff_Review__c> staffReviewsToDelete = [
                SELECT Id 
                FROM Program_Enrollment_Staff_Review__c 
                WHERE Staff__r.Staff__c IN :staffToDelete
                ];
            if (!staffReviewsToDelete.isEmpty()) {
                delete staffReviewsToDelete;
            }
        } catch (Exception e) {
            System.debug('###### Error trying to delete program enrollment staff reviews: ' + e.getMessage());
        }
    }

    public static void copyStaffRoles(String copyFromPrg, String copyToPrg, List<Staff__c> avoidStaff) {
        List<Application_Program_Enrollment_Staff__c> staffAppsToProcess = new List<Application_Program_Enrollment_Staff__c>();
        Map<String, Application_Program_Enrollment_Staff__c> staffIdToAppPrgStaffCopyFromMap = new Map<String, Application_Program_Enrollment_Staff__c>();
        Map<String, Application_Program_Enrollment_Staff__c> staffIdToAppPrgStaffCopyToMap = new Map<String, Application_Program_Enrollment_Staff__c>();
        List<String> prgIds = new List<String> {copyFromPrg, copyToPrg};

        try {
            List<Application_Program_Enrollment_Staff__c> staffApps = new List<Application_Program_Enrollment_Staff__c>([
                SELECT Staff__r.Id, Staff__c, Application_Program_Enrollment__r.RecordTypeId,
                        Application_Program_Enrollment__r.Id, Application_Program_Enrollment__c, Role__c
                FROM Application_Program_Enrollment_Staff__c
                WHERE Application_Program_Enrollment__r.Status__c !=: BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS
                    AND Application_Program_Enrollment__r.Id =: prgIds AND Staff__r.Id NOT IN :avoidStaff
                ]);

            for (Application_Program_Enrollment_Staff__c staffApp : staffApps) {
                if (staffApp.Application_Program_Enrollment__r.Id == copyFromPrg) {
                    staffIdToAppPrgStaffCopyFromMap.put(staffApp.Staff__r.Id, staffApp);
                } else {
                    staffIdToAppPrgStaffCopyToMap.put(staffApp.Staff__r.Id, staffApp);
                }
            }

            for (String staffId : staffIdToAppPrgStaffCopyFromMap.keySet()) {
                String rolesToCopy = staffIdToAppPrgStaffCopyFromMap.get(staffId).Role__c;

                if (staffIdToAppPrgStaffCopyToMap.containsKey(staffId)) {
                    staffAppsToProcess.add(new Application_Program_Enrollment_Staff__c(Id = staffIdToAppPrgStaffCopyToMap.get(staffId).Id, Role__c = rolesToCopy));
                } else {
                    staffAppsToProcess.add(new Application_Program_Enrollment_Staff__c(Application_Program_Enrollment__c = copyToPrg, Role__c = rolesToCopy, Staff__c = staffId));
                }
            }

            upsert staffAppsToProcess;
        } catch (Exception e) {
            System.debug('###### Error trying to copy staff roles: ' + e.getMessage());
        }
    }

    /**
     * Sets Owner/Primary Contact fields to null
     *
     * @param staffToReset set of staff members
     * @return list of staff members with their field values set to null
     */
    public static List<Staff__c> resetOwnerPrimaryStaffFieldValues(Set<Staff__c> staffToReset) {
        Set<String> fieldsToReset = new Set<String> {'BPI_Certification_Type__c', 'BPI_Relationship__c',
                'HVAC_Credential__c', 'HVAC_EPA_License__c', 'HVAC_Years_Of_Experience__c'};

        for (Staff__c staff : staffToReset) {
            for (String field : fieldsToReset) {
                staff.put(field, null);
            }
        }
        return new List<Staff__c>(staffToReset);
    }
}