/**
 * This class implements the actions of the PG&E Application Enrollment Portal Staff Page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentStaffExtension {
    private static Map<Id,String> appPrgMap;
    private static Map<String,Id> appPrgMapNameToId = new Map<String,Id>();

    public BIGPGEEnrollmentStaffExtension(BIGPGEEnrollmentController controller) {}

    @RemoteAction
    public static StaffEnrollmentWrapper getStaffEnrollment(String appId, String accessToken) {
        StaffEnrollmentWrapper staffWrapperObj = new StaffEnrollmentWrapper();
        Map<Id, StaffWrapper> staffIdsMap = new Map<Id, StaffWrapper>();
        Application_Enrollment__c app = null;

        // Check if enrollment application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        }

        // Check if user id was supplied
        if (app != null) {
            try {
                // Load programs associated to the application.
                appPrgMap = getApplicationPrograms(appId);
                staffWrapperObj.programs = appPrgMapNameToId;

                List<Application_Program_Enrollment_Staff__c> staffProgramsList =
                                           [SELECT Application_Program_Enrollment__r.Id,
                                                Application_Program_Enrollment__r.Name,
                                                Application_Program_Enrollment__r.RecordTypeId,
                                                Staff__r.First_Name__c, Staff__r.Last_Name__c,
                                                Staff__r.Email__c, Staff__r.Phone__c, Staff__r.Phone_Extension__c,
                                                Staff__r.Id, Staff__r.BPI_Relationship__c, 
                                                Staff__r.BPI_Certification_Type__c,
                                                Staff__r.HVAC_EPA_License__c,
                                                Staff__r.HVAC_Credential__c,
                                                Staff__r.HVAC_Years_Of_Experience__c,
                                                Role__c
                                            FROM Application_Program_Enrollment_Staff__c
                                            WHERE Application_Program_Enrollment__r.Application_Enrollment__c =: appId
                                            AND Application_Program_Enrollment__r.Status__c NOT IN
                                                            (:BIGPGEEnrollmentAppProgramUtility.PROGRAM_REJECTED_STATUS,
                                                             :BIGPGEEnrollmentAppProgramUtility.PROGRAM_EXPIRED_STATUS,
                                                             :BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS)];

                for (Application_Program_Enrollment_Staff__c sApp : staffProgramsList) {
                    if (!staffIdsMap.containsKey(sApp.Staff__r.Id)) {
                        staffIdsMap.put(sApp.Staff__r.Id, new StaffWrapper(sApp.Staff__r));
                    }
                    if (String.isNotEmpty(sApp.Role__c)) {
                        String prgType = appPrgMap.get(sApp.Application_Program_Enrollment__r.RecordTypeId);
                        for (String role : sApp.Role__c.split(';')) {
                            staffIdsMap.get(sApp.Staff__r.Id).roles.add(new StaffRoleWrapper(role, prgType, true));
                        }
                    }
                }

                List<Document__c> sDocuments = [SELECT Staff__r.Id, Staff__c, File_Type__c, File_Name__c,
                                                   (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                                                FROM Document__c
                                                WHERE Staff__r.Id IN :staffIdsMap.keySet()];

                for (Document__c sDocument : sDocuments) {
                    if (sDocument.Attachments.size() > 0) {
                        staffIdsMap.get(sDocument.Staff__r.Id).files.add(new DocumentWrapper(sDocument, false));
                    }
                }

                staffWrapperObj.staffs = staffIdsMap.values();
                System.debug('############### ' + staffWrapperObj);
            } catch (Exception e) {
                System.debug('############# Error: ' + e.getMessage());
                staffWrapperObj.success = false;
                staffWrapperObj.message = e.getMessage();
            }
        }

        if (app == null) {
            staffWrapperObj.isTokenExpired = true;
        }

        return staffWrapperObj;
    }

    @RemoteAction
    public static StaffEnrollmentWrapper saveStaffEnrollment(String appId, String accessToken, String jsonApp) {
        StaffEnrollmentWrapper myStaff = new StaffEnrollmentWrapper();
        Application_Enrollment__c app;

        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        }

        if (app != null) {
            try {
                // Load programs associated to the application.
                appPrgMap = getApplicationPrograms(appId);
                myStaff = (StaffEnrollmentWrapper)JSON.deserialize(jsonApp, StaffEnrollmentWrapper.class);

                List<Staff__c> staffsToAdd = new List<Staff__c>();
                for (StaffWrapper sWrapper : myStaff.staffs) {
                    sWrapper.staff.Name = sWrapper.staff.First_Name__c + ' ' + sWrapper.staff.Last_Name__c;
                    staffsToAdd.add(sWrapper.staff);
                }
                System.debug('####################### ' + staffsToAdd);
                upsert staffsToAdd;

                // Remove staffs
                if (!myStaff.staffsToDelete.isEmpty()) {
                    delete [SELECT Id FROM Staff__c WHERE Id IN :myStaff.staffsToDelete];
                }

                // Insert/Remove Program Enrollment Staffs.
                Map<String, Application_Program_Enrollment_Staff__c> staffAppsMap = new Map<String, Application_Program_Enrollment_Staff__c>();
                List<Application_Program_Enrollment_Staff__c> staffApps = new List<Application_Program_Enrollment_Staff__c>([SELECT Staff__r.Id, Staff__c, Application_Program_Enrollment__r.RecordTypeId,
                                                                              Application_Program_Enrollment__r.Id, Application_Program_Enrollment__c
                                                                           FROM Application_Program_Enrollment_Staff__c
                                                                           WHERE Staff__r.Id IN :staffsToAdd
                                                                           AND Application_Program_Enrollment__r.Status__c NOT IN
                                                                                    (:BIGPGEEnrollmentAppProgramUtility.PROGRAM_REJECTED_STATUS,
                                                                                     :BIGPGEEnrollmentAppProgramUtility.PROGRAM_EXPIRED_STATUS,
                                                                                     :BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS)
                                                                           ]);

                for (Application_Program_Enrollment_Staff__c staffApp : staffApps) {
                    String prgType = appPrgMap.get(staffApp.Application_Program_Enrollment__r.RecordTypeId);
                    staffAppsMap.put(staffApp.Staff__r.Id + '#' + prgType, staffApp);
                }

                List<Application_Program_Enrollment_Staff__c> staffAppsToAdd = new List<Application_Program_Enrollment_Staff__c>();
                List<Application_Program_Enrollment_Staff__c> staffAppsToRemove = new List<Application_Program_Enrollment_Staff__c>();
                Map<String, List<String>> staffAppsToProcess = new Map<String, List<String>>();

                for (StaffWrapper sWrapper : myStaff.staffs) {
                    for (StaffRoleWrapper sRoleWrapper : sWrapper.roles) {
                        if (appPrgMapNameToId.get(sRoleWrapper.program) != null) {
                            if (!staffAppsToProcess.containsKey(sWrapper.staff.Id + '#' + sRoleWrapper.program)) {
                                staffAppsToProcess.put(sWrapper.staff.Id + '#' + sRoleWrapper.program, new List<String>{});
                            }

                            if (sRoleWrapper.checked == true) {
                                staffAppsToProcess.get(sWrapper.staff.Id + '#' + sRoleWrapper.program).add(sRoleWrapper.type);
                                System.debug(staffAppsToProcess);
                            }
                        }
                    }
                }
                System.debug('%%%%%%%%%%%%%%%%%%%%% ' + staffAppsToProcess);

                for (String staffIdPrg : staffAppsToProcess.keySet()) {
                    System.debug('############ ' + staffIdPrg);
                    System.debug('################## ' + staffAppsToProcess.get(staffIdPrg));
                    if (staffAppsToProcess.get(staffIdPrg).size() > 0) {
                        String roles = String.join(staffAppsToProcess.get(staffIdPrg), ';');
                        if (staffAppsMap.containsKey(staffIdPrg)) {
                            staffAppsToAdd.add(new Application_Program_Enrollment_Staff__c(Id = staffAppsMap.get(staffIdPrg).Id, Role__c = roles));
                        } else {
                            List<String> staffPrgKey = staffIdPrg.split('#');
                            staffAppsToAdd.add(new Application_Program_Enrollment_Staff__c(Role__c = roles, Staff__c = staffPrgKey.get(0), Application_Program_Enrollment__c = appPrgMapNameToId.get(staffPrgKey.get(1))));
                        }
                    } else {
                        if (staffAppsMap.containsKey(staffIdPrg)) {
                            staffAppsToRemove.add(staffAppsMap.get(staffIdPrg));
                        }
                    }
                }

                upsert staffAppsToAdd;
                delete staffAppsToRemove;
            } catch (Exception e) {
                 System.debug('############# Error: ' + e.getMessage());
                 myStaff.success = false;
                 myStaff.message = e.getMessage();
            }
        }

        if (app == null) {
            myStaff.isTokenExpired = true;
        }

        return myStaff;
    }

    public class DocumentWrapper {
        Document__c doc;
        String fileId;
        Boolean toDelete;

        public DocumentWrapper(Document__c doc, Boolean toDelete) {
            this.doc = doc;
            this.fileId = doc.Attachments.get(0) != null ? doc.Attachments.get(0).Id : '';
            this.toDelete = toDelete;
        }
    }

    public class StaffRoleWrapper {
        String type;
        String program;
        Boolean checked;
        Id id;

        public StaffRoleWrapper(String rType, String prgType, Boolean checked) {
            this.type = rType;
            this.program = prgType;
            this.checked = checked;
        }
    }

    public class StaffWrapper {
        public Staff__c staff;
        public List<StaffRoleWrapper> roles = new List<StaffRoleWrapper>();
        List<DocumentWrapper> files = new List<DocumentWrapper>();

        public StaffWrapper(Staff__c staff) {
            this.staff = staff;
        }
    }

    public class StaffEnrollmentWrapper extends BIGPGEEnrollmentResponseWrapper{
        public List<StaffWrapper> staffs = new List<StaffWrapper>();
        List<String> staffsToDelete = new List<String>();
        Map<String,id> programs;

        public StaffEnrollmentWrapper() {

        }
    }

    private static Map<Id, String> getApplicationPrograms(String appId) {
        Map<Id, String> appPrgsMap = new Map<Id, String>();
        for(Application_Program_Enrollment__c appPrg : [SELECT Id, RecordType.Name, RecordType.Id
                                                        FROM Application_Program_Enrollment__c
                                                        WHERE Application_Enrollment__r.Id =: appId
                                                        AND Status__c NOT IN
                                                            (:BIGPGEEnrollmentAppProgramUtility.PROGRAM_REJECTED_STATUS,
                                                             :BIGPGEEnrollmentAppProgramUtility.PROGRAM_EXPIRED_STATUS,
                                                             :BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS)
                                                        ]) {
            //appPrgsMap.put(appPrg.RecordType.Name, appPrg.Id);
            appPrgsMap.put(appPrg.RecordType.Id, appPrg.RecordType.Name);
            appPrgMapNameToId.put(appPrg.RecordType.Name, appPrg.Id);
        }

        return appPrgsMap;
    }

}