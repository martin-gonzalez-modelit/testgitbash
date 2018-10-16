/**
 * This class implements the actions of the PG&E Application Enrollment Portal Company Page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentCompanyExtension {
    private static final String APP_PRG_PENDING_STATUS = 'Pending Review';
    private static final String APP_PRG_ACTION_REQUIRED_STATUS = 'Enrollment Action Required';
    public ApplicationEnrollmentWrapper appEnrollment { get; set; }
    private static Map<Id,String> appPrgMap;
    private static Map<String,Id> appPrgMapNameToId = new Map<String,Id>();
    private static Set<String> enrolledPrograms = new Set<String>();
    private static BIGPGEEnrollmentUser pgeUser;

    public BIGPGEEnrollmentCompanyExtension(BIGPGEEnrollmentController controller) {}

    @RemoteAction
    public static ApplicationEnrollmentWrapper saveApplicationEnrollment(String appId, String accessToken, String jsonApp) {
        ApplicationEnrollmentWrapper myapp = new ApplicationEnrollmentWrapper();
        Application_Enrollment__c app;
        Boolean hasCompanyTypeChanged = false;

        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId)) {
            if (String.isNotEmpty(accessToken)) {
                app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
            }
            if (app == null) {
                myapp.isTokenExpired = true;
                return myapp;
            }
        }

        try {
            myapp = (ApplicationEnrollmentWrapper)JSON.deserialize(jsonApp, ApplicationEnrollmentWrapper.class);

            if (myapp.app.Id == null) {
                if (BIGPGEEnrollmentApplicationUtility.hasDuplicateAccountInfo(myapp.app.EIN_or_SSN__c) && !myapp.proceed) {
                    myapp.hasDuplicate = true;
                    return myapp;
                }
                myapp.app.Security_Code__c = BIGPGEEnrollmentUtility.randomUUID();
                myapp.app.Access_Token__c = BIGPGEEnrollmentUtility.getRandomToken(null);
            }
            if (myapp.app.Id != null) {
                // For an existing application, check if the company type has been changed
                hasCompanyTypeChanged = BIGPGEEnrollmentApplicationUtility.hasCompanyTypeChanged(myapp.app);
            }

            myapp.app.Email_Recipient__c = myapp.app.Different_Contact__c ? myapp.contact.Email__c : myapp.owner.Email__c;
            List<Application_Program_Enrollment__c> appsToAdd = new List<Application_Program_Enrollment__c>();
            List<Application_Program_Enrollment__c> appsToRemove = new List<Application_Program_Enrollment__c>();

            // Upsert application
            upsert myapp.app;

            // Load programs associated to the application.
            appPrgMap = getApplicationPrograms(myapp.app.Id);
            Boolean processAhuRoles = false;

            if (String.isNotEmpty(myapp.app.Account__c)) {
                pgeUser = new BIGPGEEnrollmentUser(myapp.app.Account__c);
                enrolledPrograms = pgeUser.getEnrolledPrograms();
            }

            for (String prg : myapp.programs.keySet()) {
                if (myapp.programs.get(prg).checked && !enrolledPrograms.contains(prg) &&
                            (myapp.programs.get(prg).appPrg == null || appPrgMapNameToId.get(prg) == null)) {
                    Id appPrgRTId = null;
                    if (prg == BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_NAME) {
                        appPrgRTId = BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_ID;
                    } else if (prg == BIGPGEEnrollmentAppProgramUtility.APP_PRG_AHU_RT_NAME) {
                        // Set processAhuRoles variable to true only if we've never inserted the AHU program before.
                        processAhuRoles = myapp.app.Type__c == 'Contractor';
                        appPrgRTId = BIGPGEEnrollmentAppProgramUtility.APP_PRG_AHU_RT_ID;
                    } else if (prg == BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME) {
                        appPrgRTId = BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_ID;
                    }
                    if (appPrgMapNameToId.get(prg) == null) {
                        myapp.programs.get(prg).appPrg = new Application_Program_Enrollment__c(
                                Application_Enrollment__c = myapp.app.Id, Status__c = APP_PRG_PENDING_STATUS);
                        myapp.programs.get(prg).appPrg.RecordTypeId = appPrgRTId;
                    } else {
                        myapp.programs.get(prg).appPrg = new Application_Program_Enrollment__c(
                                Id = appPrgMapNameToId.get(prg), Status__c = APP_PRG_PENDING_STATUS);
                    }
                    appsToAdd.add(myapp.programs.get(prg).appPrg);
                } else if (!myapp.programs.get(prg).checked && myapp.programs.get(prg).appPrg != null) {
                    if (appPrgMapNameToId.get(prg) != null) {
                        myapp.programs.get(prg).appPrg.Status__c = 'Unused';
                        appsToAdd.add(myapp.programs.get(prg).appPrg);
                    }
                    myapp.programs.get(prg).appPrg = null;
                }
            }

            if (!appsToAdd.isEmpty()) {
                upsert appsToAdd;
            }

            myapp.owner.Name = myapp.owner.First_Name__c + ' ' + myapp.owner.Last_Name__c;
            myapp.owner.Application_Enrollment__c = myapp.app.Id;

            if (myapp.app.Different_Contact__c) {
                myapp.contact.Name = myapp.contact.First_Name__c + ' ' + myapp.contact.Last_Name__c;
                myapp.contact.Application_Enrollment__c = myapp.app.Id;
            } else {
                // Owner is Primary Program Contact
                if (myapp.contact != null && myapp.contact.Id != null && myapp.owner.Id != myapp.contact.Id) {
                    delete myapp.contact;
                    // Instantiate a new Staff so we don't display the old data into the form UI.
                    myapp.contact = new Staff__c();
                }
            }

            // Load programs associated to the application.
            appPrgMap = getApplicationPrograms(myapp.app.Id);

            List<Staff__c> staffsToAdd = new List<Staff__c>();
            staffsToAdd.add(myapp.owner);
            if (myapp.app.Different_Contact__c) {
                staffsToAdd.add(myapp.contact);
            }
            if (hasCompanyTypeChanged) {
                // Reset Owner/Primary Contact values when company type changes
                Set<Staff__c> staffsToAddSet = new Set<Staff__c>(staffsToAdd);
                staffsToAdd = BIGPGEEnrollmentStaffUtility.resetOwnerPrimaryStaffFieldValues(staffsToAddSet);
            }
            // Upsert Owner/Primary Contact
            upsert staffsToAdd;

            // Insert/Remove Program Enrollment Staffs.
            Map<String, Application_Program_Enrollment_Staff__c> staffAppsMap =
                    new Map<String, Application_Program_Enrollment_Staff__c>();
            List<Application_Program_Enrollment_Staff__c> staffApps = [
                SELECT Staff__r.Id, Staff__c, Application_Program_Enrollment__r.RecordTypeId,
                    Application_Program_Enrollment__r.Id, Application_Program_Enrollment__c, Role__c
                FROM Application_Program_Enrollment_Staff__c
                WHERE Staff__r.Id IN :staffsToAdd
                ];

            for (Application_Program_Enrollment_Staff__c staffApp : staffApps) {
                String prgType = appPrgMap.get(staffApp.Application_Program_Enrollment__r.RecordTypeId);

                staffAppsMap.put(staffApp.Staff__r.Id + '#' + prgType, staffApp);
            }

            List<Application_Program_Enrollment_Staff__c> staffAppsToAdd = new List<Application_Program_Enrollment_Staff__c>();
            List<Application_Program_Enrollment_Staff__c> staffAppsToRemove = new List<Application_Program_Enrollment_Staff__c>();
            Map<String, Set<String>> staffAppsToProcess = new Map<String, Set<String>>();

            for (Staff__c staff : staffsToAdd) {
                for (String prgType : myapp.programs.keySet()) {
                    if (myapp.programs.get(prgType).appPrg != null) {
                        String staffIdPrg = staff.Id + '#' + prgType;

                        if (!staffAppsToProcess.containsKey(staffIdPrg)) {
                            staffAppsToProcess.put(staffIdPrg, new Set<String>{});
                        }

                        Set<String> roles = new Set<String>();
                        if (myapp.owner.Id == staff.Id) {
                            if (staffAppsMap.containsKey(staffIdPrg)) {
                                roles = new Set<String>(staffAppsMap.get(staffIdPrg).Role__c.split(';'));
                            } else {
                                // Copy roles to AHU program for owner
                                String staffIdPrgHU = staff.Id + '#' + BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_NAME;
                                if (processAhuRoles && staffAppsMap.containsKey(staffIdPrgHU) 
                                        && !staffIdPrg.contains(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME)) {
                                    roles = new Set<String>(staffAppsMap.get(staffIdPrgHU).Role__c.split(';'));
                                } else {
                                    roles.add(BIGPGEEnrollmentStaffUtility.OWNER_ROLE);
                                }
                            }
                            roles.add(BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE);
                            if (myapp.app.Different_Contact__c 
                                    && roles.contains(BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE)) {
                                roles.remove(BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE);
                            }
                            staffAppsToProcess.get(staffIdPrg).addAll(roles);
                        }

                        if (!myapp.app.Different_Contact__c || myapp.contact.Id == staff.Id) {
                            if (staffAppsMap.containsKey(staffIdPrg)) {
                                roles = new Set<String>(staffAppsMap.get(staffIdPrg).Role__c.split(';'));
                                staffAppsToProcess.get(staffIdPrg).addAll(roles);
                            } else {
                                //  Copy roles to AHU program for primary contact
                                String staffIdPrgHU = staff.Id + '#' + BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_NAME;
                                if (!processAhuRoles && staffAppsMap.containsKey(staffIdPrgHU) 
                                        && !staffIdPrg.contains(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME)) {
                                    roles = new Set<String>(staffAppsMap.get(staffIdPrgHU).Role__c.split(';'));
                                    staffAppsToProcess.get(staffIdPrg).addAll(roles);
                                } else {
                                    staffAppsToProcess.get(staffIdPrg).
                                            add(BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE);
                                }
                            }
                        }

                    }
                }
            }

            for (String staffIdPrg : staffAppsToProcess.keySet()) {
                if (!staffAppsToProcess.get(staffIdPrg).isEmpty()) {
                    if (staffAppsMap.containsKey(staffIdPrg)) {
                        String roles = String.join(new List<String>(staffAppsToProcess.get(staffIdPrg)), ';');
                        staffAppsToAdd.add(new Application_Program_Enrollment_Staff__c(
                                Id = staffAppsMap.get(staffIdPrg).Id, Role__c = roles));
                    } else {
                        List<String> staffPrgKey = staffIdPrg.split('#');
                        String roles = String.join(new List<String>(staffAppsToProcess.get(staffIdPrg)), ';');
                        staffAppsToAdd.add(new Application_Program_Enrollment_Staff__c(
                                Role__c = roles, Staff__c = staffPrgKey.get(0),
                                Application_Program_Enrollment__c = myapp.programs.get(staffPrgKey.get(1)).appPrg.Id));
                    }
                } else {
                    if (staffAppsMap.containsKey(staffIdPrg)) {
                        staffAppsToRemove.add(staffAppsMap.get(staffIdPrg));
                    }
                }
            }

            if (processAhuRoles) {
                BIGPGEEnrollmentStaffUtility.copyStaffRoles(
                        appPrgMapNameToId.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_NAME), 
                        appPrgMapNameToId.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_AHU_RT_NAME), staffsToAdd);
            }

            upsert staffAppsToAdd;
            delete staffAppsToRemove;
        } catch (Exception e) {
            System.debug('############# Error: ' + e.getMessage());
            myapp.success = false;
            myapp.message = e.getMessage();
        }
        return myapp;
    }

    @RemoteAction
    public static ApplicationEnrollmentWrapper getApplicationEnrollment(String appId, String accessToken) {
        ApplicationEnrollmentWrapper app = new ApplicationEnrollmentWrapper();
        Application_Enrollment__c appE = null;
        List<BIGPGEEnrollmentReviewResultUtility.EnrollmentApplicationReviewWrapper> reviews;

        Map<Id, Staff__c> staffIdsMap = new Map<Id, Staff__c>();
        Map<String, Id> staffRolesMap = new Map<String, Id>();

        // Check if enrollment application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            appE = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        } else {
            return app;
        }
        

        if (appE != null) {
                try {
                    appE = [SELECT Name, Company_Name__c, Type__c, Website__c,Company_Info_Status__c,
                               Address__c, EIN_or_SSN__c, Enrollment_Status__c, Tax_Status__c,
                               City__c, State__c, Zip_Code__c, DBA__c, Email_Sent__c,
                               Service_Territory__c, Different_Contact__c, Account__c,
                               (SELECT Application_Enrollment__c, Status__c, RecordTypeId
                                FROM Applications_Program_Enrollment__r
                                WHERE Status__c NOT IN (:BIGPGEEnrollmentAppProgramUtility.PROGRAM_REJECTED_STATUS,
                                                        :BIGPGEEnrollmentAppProgramUtility.PROGRAM_EXPIRED_STATUS,
                                                        :BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS))
                            FROM Application_Enrollment__c
                            WHERE Id =: appId AND Access_Token__c =: accessToken];

                    if (BIGPGEEnrollmentApplicationUtility.isReturnedForCorrectionEnrollmentApplication(appE)) {
                        reviews = BIGPGEEnrollmentReviewResultUtility.getAllReviewsForEnrollmentApplication(appE);
                    }

                    if (String.isNotEmpty(appE.Account__c)) {
                        pgeUser = new BIGPGEEnrollmentUser(appE.Account__c);
                        enrolledPrograms = pgeUser.getEnrolledPrograms();
                    }
                    app = new ApplicationEnrollmentWrapper(appE, enrolledPrograms);
                    app.reviews = reviews;

                    List<Application_Program_Enrollment_Staff__c> staffProgramsList =
                                    [SELECT Application_Program_Enrollment__r.Id,
                                        Application_Program_Enrollment__r.Name,
                                        Application_Program_Enrollment__r.RecordTypeId,
                                        Staff__r.First_Name__c, Staff__r.Last_Name__c,
                                        Staff__r.Email__c, Staff__r.Phone__c,
                                        Staff__r.Phone_Extension__c,
                                        Staff__r.Id, Staff__r.BPI_Relationship__c, 
                                        Staff__r.BPI_Certification_Type__c,
                                        Staff__r.HVAC_EPA_License__c,
                                        Staff__r.HVAC_Credential__c,
                                        Staff__r.HVAC_Years_Of_Experience__c,
                                        Role__c
                                     FROM Application_Program_Enrollment_Staff__c
                                     WHERE Application_Program_Enrollment__r.Application_Enrollment__c =: appId
                                     AND Role__c INCLUDES (:BIGPGEEnrollmentStaffUtility.OWNER_ROLE,
                                                           :BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE)];

                for (Application_Program_Enrollment_Staff__c sApp : staffProgramsList) {
                    if (!staffIdsMap.containsKey(sApp.Staff__r.Id)) {
                        staffIdsMap.put(sApp.Staff__r.Id, sApp.Staff__r);
                    }
                    if (String.isNotEmpty(sApp.Role__c)) {
                        for (String role : sApp.Role__c.split(';')) {
                            staffRolesMap.put(role, sApp.Staff__r.Id);
                        }
                    }
                }

                if (String.isNotEmpty(staffRolesMap.get(BIGPGEEnrollmentStaffUtility.OWNER_ROLE))) {
                    Id ownerId = staffRolesMap.get(BIGPGEEnrollmentStaffUtility.OWNER_ROLE);
                    app.owner = staffIdsMap.get(ownerId);

                    if (String.isNotEmpty(staffRolesMap.get(BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE))) {
                        Id contactId = staffRolesMap.get(BIGPGEEnrollmentStaffUtility.PRIMARY_PROGRAM_CONTACT_ROLE);
                        if (contactId != ownerId) {
                            app.contact = staffIdsMap.get(contactId);
                        }
                    }
                }

                } catch (Exception e) {
                    System.debug('#### Error trying to retrive the enrollment application: ' + e.getMessage());
                }
        }

        if (appE == null) {
            app.isTokenExpired = true;
        }
        return app;
    }

    public class ApplicationProgramWrapper {
        public Application_Program_Enrollment__c appPrg { get; set; }
        public Boolean checked { get; set; }
        Boolean enrolled;

        public ApplicationProgramWrapper(Application_Program_Enrollment__c appPrg, Boolean enrolled) {
            this.enrolled = enrolled;
            setApplicationProgram(appPrg);
        }
        
        public void setApplicationProgram(Application_Program_Enrollment__c appPrg) {
            this.appPrg = appPrg;
            this.checked = appPrg != null ? true : false;
        }
    }

    public class ApplicationEnrollmentWrapper extends BIGPGEEnrollmentResponseWrapper {
        public Application_Enrollment__c app { get; set; }
        public Staff__c owner { get; set; }
        public Staff__c contact { get; set; }
        public Boolean hasDuplicate { get; set; }
        Boolean proceed;
        @TestVisible
        Map<String,ApplicationProgramWrapper> programs = new Map<String,ApplicationProgramWrapper>();
        Map<String, List<String>> picklistMap = new Map<String, List<String>>();
        List<BIGPGEEnrollmentReviewResultUtility.EnrollmentApplicationReviewWrapper> reviews;

        public ApplicationEnrollmentWrapper() {
            this(new Application_Enrollment__c(), new Set<String>());
        }

        public ApplicationEnrollmentWrapper(Application_Enrollment__c app, Set<String> enrolledPrgs) {
            this.app = app;
            this.proceed = false;
            this.hasDuplicate = false;
            this.picklistMap = BIGPGEEnrollmentUtility.getPicklistValuesMap(Application_Enrollment__c.getSObjectType(), 'Tax_Status__c');

            if (app != null) {
                Map<Id, Application_Program_Enrollment__c> appsPrgMap = new Map<Id, Application_Program_Enrollment__c>();
                Boolean enrolled = false;

                List<String> programList = new List<String>{
                        BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_NAME,
                        BIGPGEEnrollmentAppProgramUtility.APP_PRG_AHU_RT_NAME,
                        BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME};
                for (String s : programList) {
                    enrolled = enrolledPrgs.contains(s);
                    programs.put(s, new ApplicationProgramWrapper(null, enrolled));
                }
                for (Application_Program_Enrollment__c appPrg : app.Applications_Program_Enrollment__r) {
                    if (appPrg.RecordTypeId == BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_ID) {
                        programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_HU_RT_NAME).setApplicationProgram(appPrg);
                    } else if (appPrg.RecordTypeId == BIGPGEEnrollmentAppProgramUtility.APP_PRG_AHU_RT_ID) {
                        programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_AHU_RT_NAME).setApplicationProgram(appPrg);
                    } else if (appPrg.RecordTypeId == BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_ID) {
                        programs.get(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME).setApplicationProgram(appPrg);
                    }
                }
            }
        }
    }

    private static Map<Id, String> getApplicationPrograms(String appId) {
        Map<Id, String> appPrgsMap = new Map<Id, String>();
        for(Application_Program_Enrollment__c appPrg : [SELECT Id, RecordType.Name, RecordType.Id
                                                        FROM Application_Program_Enrollment__c
                                                        WHERE Application_Enrollment__r.Id =: appId
                                                        AND (Status__c =: BIGPGEEnrollmentAppProgramUtility.PROGRAM_PENDING_STATUS
                                                        OR Status__c =: BIGPGEEnrollmentAppProgramUtility.PROGRAM_REQUEST_INFO_STATUS
                                                        OR Status__c =: BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS
                                                        OR Status__c =: BIGPGEEnrollmentAppProgramUtility.PROGRAM_APPROVED_STATUS)]) {
            appPrgsMap.put(appPrg.RecordType.Id, appPrg.RecordType.Name);
            appPrgMapNameToId.put(appPrg.RecordType.Name, appPrg.Id);
        }

        return appPrgsMap;
    }

}