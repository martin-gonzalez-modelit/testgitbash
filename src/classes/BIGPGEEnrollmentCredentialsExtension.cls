/**
 * This class implements the actions of the PG&E Application Enrollment Portal Credentials Page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public without sharing class BIGPGEEnrollmentCredentialsExtension {
    private static Map<Id,String> appPrgMap;
    private static Map<String,Id> appPrgMapNameToId = new Map<String,Id>();
    private static final String C20_LICENSE_TYPE = 'C20 - Warm-Air Heating, Ventilating, AC';

    public BIGPGEEnrollmentCredentialsExtension(BIGPGEEnrollmentController controller) {}

    @RemoteAction
    public static CredentialsWrapper getCredentialsEnrollment(String appId, String accessToken) {
        Map<Id, LicenseWrapper> licenseIdsMap = new Map<Id, LicenseWrapper>();
        CredentialsWrapper credsWrapperObj = new CredentialsWrapper();
        Application_Enrollment__c app;

        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        }

        if (app != null) {
            try {
                // Load programs associated to the application.
                appPrgMap = getApplicationPrograms(appId);
                if (app.Type__c != BIGPGEEnrollmentApplicationUtility.APP_TYPE_INDIVIDUAL_RATER) {
                    List<Application_Program_Enrollment_License__c> appPrgLicenses = [
                        SELECT Application_Program_Enrollment__r.RecordTypeId, License__r.Has2YearsExperience__c, 
                            License__r.Expiration_Date__c, License__r.License_Number__c, License__r.Type__c, 
                            License__r.Staff__c, License__c
                        FROM Application_Program_Enrollment_License__c
                        WHERE Application_Program_Enrollment__r.Application_Enrollment__c =: appId
                            AND Application_Program_Enrollment__r.Status__c NOT IN
                                (:BIGPGEEnrollmentAppProgramUtility.PROGRAM_REJECTED_STATUS,
                                 :BIGPGEEnrollmentAppProgramUtility.PROGRAM_EXPIRED_STATUS)
                        ];

                    for (Application_Program_Enrollment_License__c appLicense : appPrgLicenses) {
                        Id recordTypeId = appLicense.Application_Program_Enrollment__r.RecordTypeId;
                        if (!licenseIdsMap.containsKey(appLicense.License__r.Id)) {
                            licenseIdsMap.put(appLicense.License__r.Id,
                                    new LicenseWrapper(appLicense.License__r, appPrgMap.get(recordTypeId)));
                        } else {
                            licenseIdsMap.get(appLicense.License__r.Id).programs.add(appPrgMap.get(recordTypeId));
                        }
                    }

                    List<License_Document__c> licenseDocuments = [
                        SELECT License__r.Id, Document__r.Id
                        FROM License_Document__c
                        WHERE License__r.Id IN : licenseIdsMap.keySet()
                        ];

                    Map<Id, Set<Id>> docsToLicsId = new Map<Id, Set<Id>>();
                    for (License_Document__c licenseDocument : licenseDocuments) {
                        if (!docsToLicsId.containsKey(licenseDocument.Document__r.Id)) {
                            docsToLicsId.put(licenseDocument.Document__r.Id, new Set<Id> {licenseDocument.License__r.Id});
                        } else {
                            docsToLicsId.get(licenseDocument.Document__r.Id).add(licenseDocument.License__r.Id);
                        }
                    }

                    List<Document__c> sDocuments = [
                        SELECT Id, File_Type__c, File_Name__c,
                            (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                        FROM Document__c
                        WHERE Id IN : docsToLicsId.keySet()
                        ];

                    for (Document__c sDocument : sDocuments) {
                        if (sDocument.Attachments.size() > 0) {
                            for (String licId : docsToLicsId.get(sDocument.Id)) {
                                licenseIdsMap.get(licId).files.add(new DocumentWrapper(sDocument, false));
                            }
                        }
                    }
                } else {
                    // Grab the information from the staff.
                    Map<Id, StaffWrapper> staffIdsMap = new Map<Id, StaffWrapper>();
                    List<Application_Program_Enrollment_Staff__c> staffProgramsList = [
                        SELECT Staff__r.Id, Role__c, Staff__r.BPI_Certification_Type__c
                        FROM Application_Program_Enrollment_Staff__c
                        WHERE Application_Program_Enrollment__r.Id =: appPrgMapNameToId.get('AHU')
                            AND Role__c INCLUDES (:BIGPGEEnrollmentStaffUtility.OWNER_ROLE)
                        ];

                    for (Application_Program_Enrollment_Staff__c sApp : staffProgramsList) {
                        if (!staffIdsMap.containsKey(sApp.Staff__r.Id)) {
                            staffIdsMap.put(sApp.Staff__r.Id, new StaffWrapper(sApp.Staff__r));
                        }
                    }

                    if (!staffIdsMap.isEmpty()) {
                        List<String> staffIds = new List<String>();
                        for (String staffId : staffIdsMap.keySet()) {
                            staffIds.add(staffId);
                        }

                        List<Document__c> sDocuments = [
                            SELECT Staff__r.Id, Staff__c, File_Type__c, File_Name__c,
                                (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                            FROM Document__c
                            WHERE Staff__r.Id =: staffIds
                            ];

                        for (Document__c sDocument : sDocuments) {
                            if (sDocument.Attachments.size() > 0) {
                                staffIdsMap.get(sDocument.Staff__r.Id).files.add(new DocumentWrapper(sDocument, false));
                            }
                        }
                        credsWrapperObj.staff = staffIdsMap.get(staffIds.get(0));
                    }
                }
                credsWrapperObj.licenses.addAll(licenseIdsMap.values());
            } catch (Exception e) {
                System.debug('############# Error: ' + e.getMessage());
                credsWrapperObj.success = false;
                credsWrapperObj.message = e.getMessage();
            }
        }

        if (app == null) {
            credsWrapperObj.isTokenExpired = true;
        }

        return credsWrapperObj;
    }

    @RemoteAction
    public static CredentialsWrapper saveCredentialsEnrollment(String appId, String accessToken, String jsonApp) {
        CredentialsWrapper myCredentials = new CredentialsWrapper();
        Application_Enrollment__c app;

        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        }

        if (app != null) {
            try {
                // Load programs associated to the application.
                appPrgMap = getApplicationPrograms(appId);
                myCredentials = (CredentialsWrapper)JSON.deserialize(jsonApp, CredentialsWrapper.class);

                if (app.Type__c != BIGPGEEnrollmentApplicationUtility.APP_TYPE_INDIVIDUAL_RATER) {
                    List<License__c> credsToAdd = new List<License__c>();
                    Map<Id, License__c> staffMap = new Map<Id, License__c>();
                    List<LicenseWrapper> licensesToAdd = new List<LicenseWrapper>();
                    List<Application_Program_Enrollment_License__c> appLicensesToRemove =
                            new List<Application_Program_Enrollment_License__c>();
                    String programsToAdd;
                    for (LicenseWrapper licenseWrapper : myCredentials.licenses) {
                        credsToAdd.add(licenseWrapper.license);
                        programsToadd = String.join(licenseWrapper.programs, ',');
                    }
                    upsert credsToAdd;

                    Map<Id, Set<String>> licIdToPrgs = new Map<Id, Set<String>>();
                    List<Application_Program_Enrollment_License__c> appLicenses = [
                        SELECT License__r.Id, License__r.Type__c, License__c, Application_Program_Enrollment__r.RecordTypeId,
                            Application_Program_Enrollment__r.RecordType.Name
                        FROM Application_Program_Enrollment_License__c
                        WHERE License__r.Id IN : credsToAdd
                        ];
                    for (Application_Program_Enrollment_License__c appLicense : appLicenses) {
                        Id recordTypeId = appLicense.Application_Program_Enrollment__r.RecordTypeId;
                        if (!licIdToPrgs.containsKey(appLicense.License__r.Id)) {
                            licIdToPrgs.put(appLicense.License__r.Id, new Set<String>{appPrgMap.get(recordTypeId)});
                        } else {
                            licIdToPrgs.get(appLicense.License__r.Id).add(appPrgMap.get(recordTypeId));
                        }
                    }
                    List<Application_Program_Enrollment_License__c> appLicensesToAdd =
                            new List<Application_Program_Enrollment_License__c>();
                    for (LicenseWrapper licenseWrapper : myCredentials.licenses) {
                        for (String licPrg : licenseWrapper.programs) {
                            if (licIdToPrgs.get(licenseWrapper.license.Id) == null
                                || (licIdToPrgs.get(licenseWrapper.license.Id) != null
                                    && !licIdToPrgs.get(licenseWrapper.license.Id).contains(licPrg))) {
                                Application_Program_Enrollment_License__c appLicense =
                                        new Application_Program_Enrollment_License__c();
                                appLicense.License__c = licenseWrapper.license.Id;
                                appLicense.Application_Program_Enrollment__c = appPrgMapNameToId.get(licPrg);
                                appLicensesToAdd.add(appLicense);
                            }
                        }
                    }

                    List<Application_Program_Enrollment_License__c> existingAppLicenses = [
                        SELECT License__r.Type__c, Application_Program_Enrollment__r.Status__c,
                            Application_Program_Enrollment__r.RecordType.Name
                        FROM Application_Program_Enrollment_License__c
                        WHERE Application_Program_Enrollment__r.Application_Enrollment__c =: appId
                        ];
                    for (Application_Program_Enrollment_License__c appLicense : existingAppLicenses) {
                        // Get all licenses from unused programs to be deleted
                        if (appLicense.Application_Program_Enrollment__r.Status__c ==
                                BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS) {
                            appLicensesToRemove.add(appLicense);
                        }
                    }
                    if (credsToAdd.size() == 2) {
                        // Check if we applying for AHU + ACQC, only case in which we add 2 licenses.
                        for (Application_Program_Enrollment_License__c appLicense : existingAppLicenses) {
                            // Check if there is an existing junction record that needs to be removed.
                            if ((appLicense.License__r.Type__c != C20_LICENSE_TYPE
                                 && appLicense.Application_Program_Enrollment__r.RecordType.Name == 'ACQC') 
                                 || (appLicense.License__r.Type__c == C20_LICENSE_TYPE
                                 && appLicense.Application_Program_Enrollment__r.RecordType.Name == 'HU')) {
                                 appLicensesToRemove.add(appLicense);
                            }
                        }
                    } else if (credsToAdd.size() == 1 && programsToAdd.contains('ACQC,HU')) {
                        // Going from AHU + ACQC (2 licenses), to HU + ACQC (1 license)
                        for (Application_Program_Enrollment_License__c appLicense : existingAppLicenses) {
                            if (appLicense.License__r.Type__c != C20_LICENSE_TYPE
                                && appLicense.Application_Program_Enrollment__r.RecordType.Name == 'HU') {
                                appLicensesToRemove.add(appLicense);
                            }
                        }
                    }
                    // Insert application program enrollment licenses
                    if (!appLicensesToAdd.isEmpty()) {
                        insert appLicensesToAdd;
                    }
                    // Remove old/unused licenses
                    if (!appLicensesToRemove.isEmpty()) {
                        delete appLicensesToRemove;
                    }

                    Map<Id, Set<String>> licIdToDocs = new Map<Id, Set<String>>();
                    List<License_Document__c> licenseDocuments = [
                        SELECT License__r.Id, License__c, Document__r.Id
                        FROM License_Document__c
                        WHERE License__r.Id IN : credsToAdd
                        ];
                    for (License_Document__c licenseDocument : licenseDocuments) {
                        if (!licIdToDocs.containsKey(licenseDocument.License__r.Id)) {
                            licIdToDocs.put(licenseDocument.License__r.Id, new Set<String> {licenseDocument.Document__r.Id});
                        } else {
                            licIdToDocs.get(licenseDocument.License__r.Id).add(licenseDocument.Document__r.Id);
                        }
                    }

                    List<License_Document__c> licenseDocsToAdd = new List<License_Document__c>();
                    for (LicenseWrapper licenseWrapper : myCredentials.licenses) {
                        for (DocumentWrapper docWrapper : licenseWrapper.files) {
                            if (licIdToDocs.get(licenseWrapper.license.Id) == null
                                || !licIdToDocs.get(licenseWrapper.license.Id).contains(docWrapper.doc.Id)) {
                                License_Document__c licenseDoc = new License_Document__c();
                                licenseDoc.License__c = licenseWrapper.license.Id;
                                licenseDoc.Document__c = docWrapper.doc.Id;
                                licenseDocsToAdd.add(licenseDoc);
                            }
                        }
                    }
                    if (!licenseDocsToAdd.isEmpty()) {
                        insert licenseDocsToAdd;
                    }

                    List<License_Document__c> licDocuments = [
                        SELECT License__r.Id, Document__r.Id
                        FROM License_Document__c
                        WHERE License__r.Id IN : credsToAdd
                        ];

                    Map<Id, Set<Id>> docsToLicsId = new Map<Id, Set<Id>>();
                    for (License_Document__c licenseDocument : licDocuments) {
                        if (!docsToLicsId.containsKey(licenseDocument.Document__r.Id)) {
                            docsToLicsId.put(licenseDocument.Document__r.Id, new Set<Id> {licenseDocument.License__r.Id});
                        } else {
                            docsToLicsId.get(licenseDocument.Document__r.Id).add(licenseDocument.License__r.Id);
                        }
                    }

                    List<Document__c> sDocuments = [
                        SELECT Id, File_Type__c, File_Name__c,
                            (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                        FROM Document__c
                        WHERE Id IN : docsToLicsId.keySet()
                        ];

                    for (Document__c sDocument : sDocuments) {
                        if (sDocument.Attachments.size() > 0) {
                            for (String licId : docsToLicsId.get(sDocument.Id)) {
                                for (LicenseWrapper licenseWrapper : myCredentials.licenses) {
                                    if (licenseWrapper.license.Id == licId) {
                                        licenseWrapper.files.add(new DocumentWrapper(sDocument, false));
                                    }
                                }
                            }
                        }
                    }
                } else {
                    StaffWrapper wStaff = myCredentials.staff;
                    if (wStaff.staff != null) {
                        upsert wStaff.staff;
                    }
                    // Get existing documents
                    List<Document__c> sDocuments = [
                        SELECT Id, File_Type__c, File_Name__c, Staff__c,
                            (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                        FROM Document__c
                        WHERE Staff__c =: wStaff.staff.Id
                        ];
                    Map<Id, StaffWrapper> staffIdsMap = new Map<Id, StaffWrapper>();
                    if (!staffIdsMap.containsKey(wStaff.staff.Id)) {
                        staffIdsMap.put(wStaff.staff.Id, new StaffWrapper(wStaff.staff));
                    }
                    for (Document__c sDocument : sDocuments) {
                        if (sDocument.Attachments.size() > 0) {
                            staffIdsMap.get(sDocument.Staff__c).files.add(new DocumentWrapper(sDocument, false));
                        }
                    }
                    myCredentials.staff = staffIdsMap.get(wStaff.staff.Id);

                    // Add BPI and HERS II roles to owner (for Individual Rater only)
                    Set<String> roles = new Set<String>();
                    List<Application_Program_Enrollment_Staff__c> staffApps = [
                        SELECT Staff__r.Id, Staff__c, Application_Program_Enrollment__c, Role__c
                        FROM Application_Program_Enrollment_Staff__c
                        WHERE Staff__r.Id =: wStaff.staff.Id
                        ];

                    for (Application_Program_Enrollment_Staff__c staffApp : staffApps) {
                        roles.addAll(staffApp.Role__c.split(';'));
                        roles.add(BIGPGEEnrollmentReviewUtils.STAFF_BPI_ROLE);
                        roles.add(BIGPGEEnrollmentReviewUtils.STAFF_HERS_ROLE);
                        staffApp.Role__c = String.join(New List<String>(roles), ';');
                    }
                    upsert staffApps;
                }
            } catch (Exception e) {
                System.debug('############# Error: ' + e.getMessage());
                myCredentials.success = false;
                myCredentials.message = e.getMessage();
            }
        }

        if (app == null) {
            myCredentials.isTokenExpired = true;
        }

        return myCredentials;
    }

    public class StaffWrapper {
        Staff__c staff;
        List<DocumentWrapper> files = new List<DocumentWrapper>();

        public StaffWrapper(Staff__c staff) {
            this.staff = staff;
        }
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

    public class LicenseWrapper {
        public License__c license;
        public List<String> programs = new List<String>();
        public List<DocumentWrapper> files = new List<DocumentWrapper>();

        public LicenseWrapper(License__c license, String program) {
            this.license = license;
            this.programs.add(program);
        }
    }

    public class CredentialsWrapper extends BIGPGEEnrollmentResponseWrapper {
        public List<LicenseWrapper> licenses = new List<LicenseWrapper>();
        StaffWrapper staff = null;

        public CredentialsWrapper() {

        }
    }

    private static Map<Id, String> getApplicationPrograms(String appId) {
        Map<Id,String> appPrgsMap = new Map<Id, String>();
        for(Application_Program_Enrollment__c appPrg : [SELECT Id, RecordType.Name, RecordType.Id
                                                        FROM Application_Program_Enrollment__c
                                                        WHERE Application_Enrollment__r.Id =: appId
                                                        AND Status__c NOT IN
                                                            (:BIGPGEEnrollmentAppProgramUtility.PROGRAM_REJECTED_STATUS,
                                                             :BIGPGEEnrollmentAppProgramUtility.PROGRAM_EXPIRED_STATUS,
                                                             :BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS)
                                                        ]) {
            appPrgsMap.put(appPrg.RecordType.Id, appPrg.RecordType.Name);
            appPrgMapNameToId.put(appPrg.RecordType.Name, appPrg.Id);
        }

        return appPrgsMap;
    }

}