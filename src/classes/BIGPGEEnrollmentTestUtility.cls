/**
 * This class contains methods for creating test data for PGE Enrollment Portal / PGE Enrolment Review
 * testing
 * @author Camilo Herbert <cherbert@builditgreen.org>
 * @since 2015-03
 */
@isTest
public with sharing class BIGPGEEnrollmentTestUtility {
    public static Integer TEST_LIST_SIZE = 1;
    public static final String PORTAL_USER_USERNAME = 'jdoepgeenrollment';
    public static final String PORTAL_USER_PASSWORD = 'testpassword1234';
    public static final String TEST_TAX_ID = '123456789';

    public User portalUser;
    public Id portalUserID;

    // List of application enrollments
    public List<Application_Enrollment__c> applicationEnrollments;

    // Enrollment application for matchings
    public Application_Enrollment__c taxMatchingAppEnrollment;

    // Mapping from App Enrollment type s list of app enrollments
    public Map<String, List<Application_Enrollment__c>> appEnrollmentTypeToAppEnrollmentList;

    // Mpping from App Enrollment statuses to list of map enrollments
    public Map<string, List<Application_Enrollment__c>> appEnrollmentStatusToAppEnrollmentList;

    // Mpping from App Enrollment company statuses to list of map enrollments
    public Map<string, List<Application_Enrollment__c>> appEnrollmentCompanyStatusToAppEnrollmentList;

    // Mapping from app  enrollment to list of related documents
    public Map<Id, List<Document__c>> appEnrollmentToDocumentListMap;

    // Mapping from application enrollment to staffs
    public Map<Id, List<Staff__c>> appEnrollmentToStaffMap;

    // Mapping from staff to related documents
    public Map<id, List<Document__c>> staffToDocumentListMap;

    // Mapping from App Enrollment to related records
    public Map<Id, List<Application_Program_Enrollment__c>> appEnrollmentToProgramEnrollmentsMap;

    // Mpping from Program status to enrollment program
    public Map<Id, Map<String, List<Application_Program_Enrollment__c>>> appEnrollmentToappProgEnrollmentStatusToAppEnrollmentList;

    // Mapping from Program Enrollment to related records
    public Map<Id, List<Application_Program_Enrollment_Staff__c>> programEnrollmentToStaffEnrollmentMap;

    // Mapping from staff enrollment to related records
    public Map<Id, Program_Enrollment_Staff_Review__c> progEnrollmentStaffToStaffReviewMap;

    // Set of staff Ids
    public set<Id> staffIds;

    // AGREEMENTS AND LICENSES
    public Map<Id, List<Application_Program_Enrollment_Agreement__c>> programToAgreementListMap;
    public Map<Id, List<Application_Program_Enrollment_License__c>> programToLicenseListMap;

    // Misc records for account/staff matching
    public Account testAccount;
    public List<Contact> testContacts;
    public List<Program_Enrollment__c> testAccountProgEnrollments;
    public List<Credential__c> testAccountCredentials;
    public List<Program_Enrollment_File__c> testAccountProgramEnrollmentFiles;
    public Map<Id, List<Employee_Program_Enrollment__c>> contactToEmployeeProgEnrollmentsMap;

    // Test data types/statuses   with default values
    private List<String> appEnrollmentTypes = new List<String>{'Contractor'};
    private List<String> appEnrollmentStatuses = new List<String>{'Pending Review'};
    private List<String> companyInfoStatuses = new List<String>{'Pending Review'};
    private List<String> programStatuses = new List<String>{'Pending Review'};

    // Class constructor. TODO: Create different set of records based on parameters
    public BIGPGEEnrollmentTestUtility() {
        // Create application enrollments for testing
        this.applicationEnrollments = new List<Application_Enrollment__c>();

        createApplicationEnrollments();
        createProgramEnrollments();
        createStaff();
        createLicense();
        createAgreements();
        createAllDocumentData();
        createAccountInformation();
    }

    // Class constructor with types. TODO: Create different set of records based on parameters
    public BIGPGEEnrollmentTestUtility(List<String> appEnrollmentTypes) {
        // Create application enrollments for testing
        this.applicationEnrollments = new List<Application_Enrollment__c>();

        this.appEnrollmentTypes = appEnrollmentTypes;
        createApplicationEnrollments();
        createProgramEnrollments();
        createStaff();
        createLicense();
        createAgreements();
        createAllDocumentData();
        createAccountInformation();
    }

    // Class constructor with app enrollment statuses. TODO: Create different set of records based on parameters
    public BIGPGEEnrollmentTestUtility(List<String> appEnrollmentTypes, List<String> appEnrollmentStatuses) {
        // Create application enrollments for testing
        this.applicationEnrollments = new List<Application_Enrollment__c>();

        this.appEnrollmentTypes = appEnrollmentTypes;
        this.appEnrollmentStatuses = appEnrollmentStatuses;
        createApplicationEnrollments();
        createProgramEnrollments();
        createStaff();
        createLicense();
        createAgreements();
        createAllDocumentData();
        createAccountInformation();
    }

    // Class constructor with statuses: ap enrollment, company info. TODO: Create different set of records based on parameters
    public BIGPGEEnrollmentTestUtility(List<String> appEnrollmentTypes, List<String> appEnrollmentStatuses, List<String> companyInfoStatuses) {
        // Create application enrollments for testing
        this.applicationEnrollments = new List<Application_Enrollment__c>();

        this.appEnrollmentTypes = appEnrollmentTypes;
        this.appEnrollmentStatuses = appEnrollmentStatuses;
        this.companyInfoStatuses = companyInfoStatuses;
        createApplicationEnrollments();
        createProgramEnrollments();
        createStaff();
        createLicense();
        createAgreements();
        createAllDocumentData();
        createAccountInformation();
    }

    // Class constructor with statuses: ap enrollment, company info, program status. TODO: Create different set of records based on parameters
    public BIGPGEEnrollmentTestUtility(List<String> appEnrollmentTypes, List<String> appEnrollmentStatuses, List<String> companyInfoStatuses, List<String> programStatuses) {
        // Create application enrollments for testing
        this.applicationEnrollments = new List<Application_Enrollment__c>();

        this.appEnrollmentTypes = appEnrollmentTypes;
        this.appEnrollmentStatuses = appEnrollmentStatuses;
        this.companyInfoStatuses = companyInfoStatuses;
        this.programStatuses = programStatuses;
        createApplicationEnrollments();
        createProgramEnrollments();
        createStaff();
        createLicense();
        createAgreements();
        createAllDocumentData();
        createAccountInformation();
    }

    private void createApplicationEnrollments() {
        appEnrollmentTypeToAppEnrollmentList = new Map<String, List<Application_Enrollment__c>>();
        appEnrollmentStatusToAppEnrollmentList = new Map<String, List<Application_Enrollment__c>>();
        appEnrollmentCompanyStatusToAppEnrollmentList = new Map<String, List<Application_Enrollment__c>>();

        for (String appEnrollmentType : appEnrollmentTypes) {
            for (String appEnrollmentStatus : appEnrollmentStatuses) {
                for (String companyInfoStatus : companyInfoStatuses) {

                    List<Application_Enrollment__c> appEnrollmentList = new List<Application_Enrollment__c>();

                    for (Integer i = 0; i < TEST_LIST_SIZE; i++) {
                        Application_Enrollment__c newAppEnrollment = new Application_Enrollment__c();
                        newAppEnrollment.City__c = 'Test city ' + string.valueOf(i);
                        newAppEnrollment.Company_Name__c = 'Test Company ' + string.valueOf(i);
                        newAppEnrollment.Company_Info_Status__c = 'Pending Review';
                        newAppEnrollment.Enrollment_Status__c = appEnrollmentStatus;
                        newAppEnrollment.State__c = 'CA';
                        newAppEnrollment.Email_Recipient__c = 'jdoe@mail.com';
                        newAppEnrollment.Type__c = appEnrollmentType;
                        newAppEnrollment.Tax_Status__c = 'Exempt';
                        newAppEnrollment.Workers_Compensation_Type__c = 'CSLB Waiver Statement';
                        newAppEnrollment.Security_Code__c = BIGPGEEnrollmentUtility.randomUUID();
                        newAppEnrollment.Company_Info_Status__c = companyInfoStatus;

                        if (taxMatchingAppEnrollment == null) {
                            newAppEnrollment.EIN_or_SSN__c = TEST_TAX_ID;
                            taxMatchingAppEnrollment = newAppEnrollment;
                        } else {
                            newAppEnrollment.EIN_or_SSN__c = '100000000'.substring(0, 9 - string.valueOf(i).length()) + string.valueOf(i);
                        }

                        this.applicationEnrollments.add (newAppEnrollment);
                        appEnrollmentList.add (newAppEnrollment);
                    }

                    this.appEnrollmentTypeToAppEnrollmentList.put (appEnrollmentType, appEnrollmentList);
                    this.appEnrollmentStatusToAppEnrollmentList.put (appEnrollmentStatus, appEnrollmentList);
                    this.appEnrollmentCompanyStatusToAppEnrollmentList.put (companyInfoStatus, appEnrollmentList);
                }
            }
        }

        insert this.applicationEnrollments;

        for (Application_Enrollment__c appEnrollment : this.applicationEnrollments) {
            System.assertNotEquals (appEnrollment, null);
        }
    }

    private void createProgramEnrollments() {
        Integer forCheck = 0;
        // Create a subset of program enrollments for each applicaton enrollment
        // based on app enrollment type
        appEnrollmentToProgramEnrollmentsMap = new Map<Id, List<Application_Program_Enrollment__c>>();
        appEnrollmentToappProgEnrollmentStatusToAppEnrollmentList = new Map<Id, Map<String, List<Application_Program_Enrollment__c>>>();

        for (Application_Enrollment__c appEnrollment : this.applicationEnrollments) {
            appEnrollmentToappProgEnrollmentStatusToAppEnrollmentList.put(appEnrollment.Id, new Map<String, List<Application_Program_Enrollment__c>>());

            for (String appProgEnrollmentStatus : programStatuses) {
                List<Application_Program_Enrollment__c> programEnrollments = new List<Application_Program_Enrollment__c>();
                if (forCheck > 0) {
                    Application_Program_Enrollment__c ahuEnrollment = new Application_Program_Enrollment__c();
                    ahuEnrollment.RecordTypeId = BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID;
                    programEnrollments.add(ahuEnrollment);
                }
                Application_Program_Enrollment__c huEnrollment = new Application_Program_Enrollment__c();
                huEnrollment.RecordTypeId = BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_HU_RECORDTYPE_ID;
                programEnrollments.add(huEnrollment);

                if (appEnrollment.Type__c == 'Contractor') {
                    Application_Program_Enrollment__c acqcEnrollment = new Application_Program_Enrollment__c();
                    acqcEnrollment.RecordTypeId = BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID;
                    programEnrollments.add(acqcEnrollment);
                }

                for (Application_Program_Enrollment__c programEnrollment : programEnrollments) {
                    programEnrollment.Application_Enrollment__c = appEnrollment.Id;
                    programEnrollment.Status__c = appProgEnrollmentStatus;
                }

                insert programEnrollments;

                for (Application_Program_Enrollment__c programEnrollment : programEnrollments) {
                    System.assertNotEquals(programEnrollment.Id, null);
                }

                appEnrollmentToProgramEnrollmentsMap.put(appEnrollment.Id, programEnrollments);
                appEnrollmentToappProgEnrollmentStatusToAppEnrollmentList.get(appEnrollment.Id).put(appProgEnrollmentStatus, programEnrollments);
            }
            forCheck++;
        }
    }

    private void createStaff () {
        programEnrollmentToStaffEnrollmentMap = new Map<Id, List<Application_Program_Enrollment_Staff__c>>();
        staffIds = new set<Id>();

        for (Application_Enrollment__c appEnrollment : this.applicationEnrollments) {
            Staff__c currentStaff = new Staff__c ();
            currentStaff.Email__c = 'test@test.com';
            currentStaff.First_Name__c = 'TestFirst';
            currentStaff.Last_Name__c = 'TestLast';

            insert currentStaff;
            System.assertNotEquals (currentStaff.Id, null);

            List<Application_Program_Enrollment_Staff__c> appProgEnrollmentStaffs = new List<Application_Program_Enrollment_Staff__c>();

            for (Application_Program_Enrollment__c progEnrollment : appEnrollmentToProgramEnrollmentsMap.get(appEnrollment.Id)) {
                Application_Program_Enrollment_Staff__c appEnrollmentStaff = new Application_Program_Enrollment_Staff__c();
                appEnrollmentStaff.Role__c = 'BPI Certified Professional;HVAC Technician;HERS II;Owner;Primary Program Contact;Rebate Administrator;Salesperson';
                appEnrollmentStaff.Staff__c = currentStaff.Id;
                appEnrollmentStaff.Application_Program_Enrollment__c = progEnrollment.Id;
                appProgEnrollmentStaffs.add(appEnrollmentStaff);

                staffIds.add(currentStaff.Id);

                // Just one app prog enrolment staff per program as for now. TODO: Create a parametrized way of create different staffs for different programs
                programEnrollmentToStaffEnrollmentMap.put (progEnrollment.Id, new List<Application_Program_Enrollment_Staff__c>{appEnrollmentStaff});
            }

            insert appProgEnrollmentStaffs;

            for (Application_Program_Enrollment_Staff__c appEnrollmentStaff : appProgEnrollmentStaffs) {
                System.assertNotEquals(null, appEnrollmentStaff.Id);
            }
        }
    }

    private void createAllDocumentData() {
        appEnrollmentToDocumentListMap = createDocuments('Bonding Document', 'Application_Enrollment__c', appEnrollmentToProgramEnrollmentsMap.keySet());
        appEnrollmentToDocumentListMap = createDocuments('General Liability Insurance', 'Application_Enrollment__c', appEnrollmentToProgramEnrollmentsMap.keySet());
        appEnrollmentToDocumentListMap = createDocuments('Auto Liability Insurance', 'Application_Enrollment__c', appEnrollmentToProgramEnrollmentsMap.keySet());
        appEnrollmentToDocumentListMap = createDocuments('W-9 Form', 'Application_Enrollment__c', appEnrollmentToProgramEnrollmentsMap.keySet());
        appEnrollmentToDocumentListMap = createDocuments('Worker\'s Compensation Insurance', 'Application_Enrollment__c', appEnrollmentToProgramEnrollmentsMap.keySet());

        staffToDocumentListMap = createDocuments('Copy of BPI Card', 'Staff__c', staffIds);
    }

    public static Map<Id, List<Document__c>> createDocumentsLicense(String type, String bondingField, Set<Id> licenseIds){
        Map<Id, List<Document__c>> parentObjectToDocumentListMap = new Map<Id, List<Document__c>>();

        for (Id licenseId : licenseIds) {
            List<Document__c> documentList = new List<Document__c>();
            List<Attachment> attachments = new List<Attachment>();

            Document__c newAppDocument0 = new Document__c();
            newAppDocument0.File_Name__c = 'Test file';
            newAppDocument0.File_Type__c = 'Proof Financial Records';
            insert newAppDocument0;
            documentList.add(newAppDocument0);

            License_Document__c licenseDocument = new License_Document__c();
            licenseDocument.Document__c = newAppDocument0.Id;
            licenseDocument.License__c = licenseId;
            insert licenseDocument;

            Document__c newAppDocument1 = new Document__c();
            newAppDocument1.File_Name__c = 'Test file';
            newAppDocument1.File_Type__c = 'Professional Reference 1';
            insert newAppDocument1;
            documentList.add(newAppDocument1);

            License_Document__c licenseDocument2 = new License_Document__c();
            licenseDocument2.Document__c = newAppDocument1.Id;
            licenseDocument2.License__c = licenseId;
            insert licenseDocument2;

            Document__c newAppDocument2 = new Document__c();
            newAppDocument2.File_Name__c = 'Test file';
            newAppDocument2.File_Type__c = 'Professional Reference 2';
            insert newAppDocument2;
            documentList.add(newAppDocument2);

            License_Document__c licenseDocument3 = new License_Document__c();
            licenseDocument3.Document__c = newAppDocument2.Id;
            licenseDocument3.License__c = licenseId;
            insert licenseDocument3;

            for (Document__c document : documentList) {
                System.assertNotEquals(document.Id, null);
                Attachment documentAttachment = new Attachment();
                documentAttachment.ParentId = document.Id;
                documentAttachment.Name = 'Test attachment';
                documentAttachment.Body = Blob.valueOf('Test Blob');
                attachments.add(documentAttachment);
            }
            insert attachments;

            for (Attachment documentAttachment : attachments) {
                System.assertNotEquals(documentAttachment.Id, null);
            }
            parentObjectToDocumentListMap.put (licenseId, documentList);
        }
        return parentObjectToDocumentListMap;
    }

    public static Map<Id, List<Document__c>> createDocuments(String type, String bondingField, Set<Id> parentIds) {
        Map<Id, List<Document__c>> parentObjectToDocumentListMap = new Map<Id, List<Document__c>>();

        for (Id parentId : parentIds) {
            List<Document__c> documentList = new List<Document__c>();
            List<Attachment> attachments = new List<Attachment>();

            for (Integer i = 0; i < TEST_LIST_SIZE; i++) {
                Document__c newAppDocument = new Document__c();
                newAppDocument.File_Name__c = 'Test file';
                newAppDocument.File_Type__c = type;
                newAppDocument.put(bondingField, parentId);
                documentList.add (newAppDocument);
            }

            insert documentList;

            for (Document__c document : documentList) {
                System.assertNotEquals(document.Id, null);
                Attachment documentAttachment = new Attachment();
                documentAttachment.ParentId = document.Id;
                documentAttachment.Name = 'Test attachment';
                documentAttachment.Body = Blob.valueOf('Test Blob');
                attachments.add(documentAttachment);
            }

            insert attachments;

            for (Attachment documentAttachment : attachments) {
                System.assertNotEquals(documentAttachment.Id, null);
            }

            parentObjectToDocumentListMap.put (parentId, documentList);
        }

        return parentObjectToDocumentListMap;
    }

    public static Map<Id, List<Document__c>> createAgreementDocuments(String type, String bondingField, Set<Id> agreementIds) {
        Map<Id, List<Document__c>> parentObjectToDocumentListMap = new Map<Id, List<Document__c>>();

        for (Id agreementId : agreementIds) {
            List<Document__c> documentList = new List<Document__c>();
            List<Attachment> attachments = new List<Attachment>();

            Document__c newAppDocument0 = new Document__c();
            newAppDocument0.File_Name__c = 'Test file';
            newAppDocument0.File_Type__c = 'Contractor Agreement';
            newAppDocument0.Agreement__c = agreementId;

            insert newAppDocument0;
            documentList.add(newAppDocument0);

            for (Document__c document : documentList) {
                System.assertNotEquals(document.Id, null);
                Attachment documentAttachment = new Attachment();
                documentAttachment.ParentId = document.Id;
                documentAttachment.Name = 'Test attachment';
                documentAttachment.Body = Blob.valueOf('Test Blob');
                attachments.add(documentAttachment);
            }

            insert attachments;

            for (Attachment documentAttachment : attachments) {
                System.assertNotEquals(documentAttachment.Id, null);
            }

            parentObjectToDocumentListMap.put (agreementId, documentList);
        }

        return parentObjectToDocumentListMap;
    }

    public static List<Document__c> createDocuments(List<String> docsType) {
        List<Document__c> documentsList = new List<Document__c>();

        for (String docType : docsType) {
            List<Attachment> attachments = new List<Attachment>();

            for (Integer i = 0; i < TEST_LIST_SIZE; i++) {
                Document__c newAppDocument = new Document__c();
                newAppDocument.File_Name__c = 'Test file';
                newAppDocument.File_Type__c = docType;
                documentsList.add (newAppDocument);
            }

            insert documentsList;

            for (Document__c document : documentsList) {
                System.assertNotEquals(document.Id, null);
                Attachment documentAttachment = new Attachment();
                documentAttachment.ParentId = document.Id;
                documentAttachment.Name = 'Test attachment';
                documentAttachment.Body = Blob.valueOf('Test Blob');
                attachments.add(documentAttachment);
            }

            insert attachments;

            for (Attachment documentAttachment : attachments) {
                System.assertNotEquals(documentAttachment.Id, null);
            }
        }

        return documentsList;
    }

    private void createLicense() {
        programToLicenseListMap = new Map<Id, List<Application_Program_Enrollment_License__c>>();

        Set<Id> licenseIds = new Set<Id>();
        for (Application_Enrollment__c appEnrollment : this.applicationEnrollments) {
            License__c license0 = new License__c(Type__c = 'B License', License_Number__c = '123456');
            insert license0;
            for (Application_Program_Enrollment__c appProgEnrollment : appEnrollmentToProgramEnrollmentsMap.get(appEnrollment.Id)) {
                System.assertNotEquals(license0.Id, null);
                licenseIds.add(license0.Id);

                Application_Program_Enrollment_License__c appProgEnrollmentLicense = new Application_Program_Enrollment_License__c();
                appProgEnrollmentLicense.License__c = license0.Id;
                appProgEnrollmentLicense.Application_Program_Enrollment__c = appProgEnrollment.Id;

                insert appProgEnrollmentLicense;
                System.assertNotEquals(appProgEnrollmentLicense.Id, null);
            }
            createDocumentsLicense('Participation License', 'License__c', licenseIds);
        }
    }

    private void createAgreements() {
        programToAgreementListMap = new Map<Id, List<Application_Program_Enrollment_Agreement__c>>();

        for (Application_Enrollment__c appEnrollment : this.applicationEnrollments) {
            Set<Id> agreementIds = new Set<Id>();
            Agreement__c agreement0 = new Agreement__c(Agree_Terms_and_Conditions__c = true,
                                                       Contractor_Agreement__c = true,
                                                       EUC_Customer_Collateral__c = true,
                                                       EUC_Graphic_Standards__c = true,
                                                       Program_Handbook__c = true);

            Agreement__c agreement1 = new Agreement__c(ACQC_Agreement__c = true);

            insert agreement0;
            insert agreement1;

            System.assertNotEquals(agreement0.Id, null);
            agreementIds.add(agreement0.Id);
            System.assertNotEquals(agreement1.Id, null);
            agreementIds.add(agreement1.Id);

            for (Application_Program_Enrollment__c appProgEnrollment : appEnrollmentToProgramEnrollmentsMap.get(appEnrollment.Id)) {
                Application_Program_Enrollment_Agreement__c appProgEnrollmentAgreement= new Application_Program_Enrollment_Agreement__c();
                if (appProgEnrollment.RecordType.Name == 'ACQC') {
                    appProgEnrollmentAgreement.Agreement__c = agreement1.Id;
                    appProgEnrollmentAgreement.Application_Program_Enrollment__c = appProgEnrollment.Id;

                    insert appProgEnrollmentAgreement;
                    System.assertNotEquals(appProgEnrollmentAgreement.Id, null);
                } else {
                    appProgEnrollmentAgreement.Agreement__c = agreement0.Id;
                    appProgEnrollmentAgreement.Application_Program_Enrollment__c = appProgEnrollment.Id;

                    insert appProgEnrollmentAgreement;
                    System.assertNotEquals(appProgEnrollmentAgreement.Id, null);
                }
            }
            createAgreementDocuments('Participation Agreement', 'Agreement__c', agreementIds);
        }
    }

    private void createAccountInformation() {
        this.testAccount = new Account();

        testAccount.Name = 'Test Company';
        testAccount.RecordTypeId = BIGPGEEnrollmentReviewUtils.CONTRACTOR_RECORDTYPE_ID;
        testAccount.Tax_ID_Number__c = TEST_TAX_ID;
        testAccount.Tax_Status__c = 'Exempt';
        testAccount.Workers_Compensation_Type__c = 'CSLB Waiver Statement';

        insert testAccount;
        System.assertNotEquals(testAccount.Id, null);

        for (Integer i=0; i < applicationEnrollments.size(); i++) {
            applicationEnrollments.get(i).Account__c = testAccount.Id;
           update applicationEnrollments.get(i);
        }

        testContacts = new List<Contact>();
        for (Integer i = 0; i < TEST_LIST_SIZE; i++) {
            Contact newContact = new Contact();
            newContact.LastName = 'Test';
            newContact.FirstName = 'Test';
            newContact.Email = 'test@test.com';
            newContact.Phone = '703-555-5555';
            newContact.AccountId = testAccount.Id;
            testContacts.add(newContact);
        }

        insert testContacts;

        for (Contact currentContact : testContacts) {
            System.assertNotEquals(currentContact.Id, null);
        }

        // Create Portal user
        Profile portalProfile = [SELECT Id, Name FROM Profile WHERE Name = 'PGE - EUC Portal User'];

        portalUser = BIGPortalTestUtils.createUser(PORTAL_USER_USERNAME, portalProfile.Id, 'BIGTest');
        portalUser.ContactId = testContacts.get(0).Id;
        insert portalUser;
        System.assertNotEquals(null, portalUser.Id);
    }
}