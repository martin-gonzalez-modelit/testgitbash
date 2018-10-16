public with sharing class BIGPGEEnrollmentReviewDataMappingUtils {
    // Program enrollment file types
    private static final String LICENSE_PROGRAM_ENROLLMENT_FILE_TYPE = 'Participation License';
    private static final String AGREEMENT_PROGRAM_ENROLLMENT_FILE_TYPE = 'Participation Agreement (Signed and Dated)';

    // License Types
    private static final String C20_LICENSE_TYPE = 'C20 - Warm-Air Heating, Ventilating, AC';
    private static final String B_LICENSE_TYPE = 'B - General Building';

    // Licenses Credential Type
    private static final String CONTRACTOR_LICENSE_CREDENTIAL_TYPE = 'State Contractor\'s License';
    private static final String RATER_COMPANY_LICENSE_CREDENTIAL_TYPE = 'BPI Accreditation';
    private static final String AUTO_LIABILITY_INSURANCE_CREDENTIAL_TYPE = 'Auto Liability Insurance';
    private static final String BPI_CREDENTIAL_TYPE = 'BPI Certification';

    private static final String CREDENTIAL_ACTIVE_VERIFIED_STATUS = 'Active - Verified';
    private static final String CREDENTIAL_EXEMPT_VERIFIED_STATUS = 'Exempt - Verified';

    private static final List<String> BPI_STAFF_INFO_FIELD_LIST = new List<String> {'BPI_Certification_Exp_Date__c',
                                                                                    'BPI_Certification_Number__c'};

    private static final List<String> HERS_STAFF_INFO_FIELD_LIST = new List<String> {'HERS_II_Certification_Number__c',
                                                                                     'HERS_II_Certification_Exp_Date__c'};

    private static final Map<String, List<String>> DOCUMENT_TYPE_TO_STAFF_INFO_FIELD_LIST_MAP
                                                        = new Map <String, List<String>> {'Copy of BPI Card' => BPI_STAFF_INFO_FIELD_LIST,
                                                                                          'Copy of HERS II ID Card' => HERS_STAFF_INFO_FIELD_LIST};

    private static final Map<String, String> DOCUMENT_TYPE_TO_STAFF_CERTIFICATION_FIELD_MAP = new Map<String, String> {'Copy of BPI Card' => 'BPI_Certification_Active__c',
                                                                                                             'Copy of HERS II ID Card'  => 'HERS_II_Certification_Active__c'};

    private static final Map<String, String> REVIEW_FIELD_TO_CREDENTIAL_FIELD_MAP
                                                        = new Map<String, String> {'BPI_Certification_Exp_Date__c' => 'Expiration_Date__c',
                                                                                   'BPI_Certification_Number__c' => 'Provider_Issued_ID__c',
                                                                                   'HERS_II_Certification_Number__c' =>  'Provider_Issued_ID__c',
                                                                                   'HERS_II_Certification_Exp_Date__c' => 'Expiration_Date__c'};

    // Staff role to document type mapping
    private static final Map<String, String> DOCUMENT_TYPE_TO_STAFF_ROLE_MAP
                                                = new Map <String, String> {'Copy of BPI Card' => 'BPI Certified Professional',
                                                                            'Copy of HERS II ID Card' => 'HVAC Technician'};
    // Document type to Staff role mapping
    private static final Map<String, String> STAFF_ROLE_TO_DOCUMENT_TYPE_MAP
                                                = new Map <String, String> {'BPI Certified Professional' => 'Copy of BPI Card',
                                                                            'HVAC Technician' => 'Copy of HERS II ID Card'};

    // Staff role to credential file type mapping
    private static final Map<String, String> STAFF_ROLE_TO_CREDENTIAL_FILE_TYPE_MAP
                                                = new Map <String, String> {'BPI Certified Professional' => 'BPI Card',
                                                                            'HVAC Technician' => 'HERS ID Card'};

    private static final Map<String, String> CREDENTIAL_TYPE_TO_CREDENTIAL_FILE_TYPE_MAP
                                                = new Map <String, String> {'BPI Accreditation' => 'BPI Card',
                                                                            'HVAC Technician' => 'HERS ID Card',
                                                                            'BPI Certification' => 'BPI Card',
                                                                            'HERS II Certification' => 'HERS ID Card'};

    private static final Map<String, String> DOCUMENT_TYPE_TO_CREDENTIAL_TYPE_MAP
                                                = new Map<String, String> {'Bonding Document' => 'Bonding Document',
                                                                           'Copy of BPI Card' => 'BPI Certification',
                                                                           'Copy of HERS II ID Card' => 'HERS II Certification',
                                                                           'Worker\'s Compensation Insurance' => 'Worker\'s Compensation Insurance',
                                                                           'Auto Liability Insurance' => 'Auto Liability Insurance',
                                                                           'General Liability Insurance' => 'General Liability Insurance',
                                                                           'Copy of BPI Accreditation' => 'BPI Accreditation',
                                                                           'W-9 Form' => 'W-9 Form'};

    private static final Map<String, String> DOCUMENT_TYPE_TO_CREDENTIAL_FIELD_MAP
                                                = new Map<String, String> {'Bonding Document' => 'Bonding_Document__c',
                                                                           'Worker\'s Compensation Insurance' => 'Workers_Compensation__c',
                                                                           'Auto Liability Insurance' => 'Auto_Liability__c',
                                                                           'General Liability Insurance' => 'General_Liability_Insurance__c',
                                                                           'W-9 Form' => 'Tax_EIN_or_SSN_matches__c'};

    private static final Map<String, String> CREDENTIAL_TYPE_TO_DOCUMENT_TYPE_MAP
                                                = new Map<String, String> {'Bonding Document' => 'Bonding Document',
                                                                           'BPI Certification' => 'Copy of BPI Card',
                                                                           'HERS II Certification' => 'Copy of HERS II ID Card',
                                                                           'Worker\'s Compensation Insurance' => 'Worker\'s Compensation Insurance',
                                                                           'Auto Liability Insurance' => 'Auto Liability Insurance',
                                                                           'General Liability Insurance' => 'General Liability Insurance',
                                                                           'BPI Accreditation' => 'Copy of BPI Accreditation',
                                                                           'W-9 Form' => 'W-9 Form'};

    private static final Map<String, String> DOCUMENT_TYPE_TO_CREDENTIAL_FILE_TYPE_MAP
                                                = new Map<String, String> {'Bonding Document' => 'Bonding Document',
                                                                           'Copy of BPI Card' => 'BPI Card',
                                                                           'Copy of HERS II ID Card' => 'HERS ID Card',
                                                                           'Worker\'s Compensation Insurance' => 'Worker\'s Compensation Insurance or Waiver',
                                                                           'Auto Liability Insurance' => 'Auto Liability Insurance',
                                                                           'General Liability Insurance' => 'General Liability Insurance',
                                                                           'Copy of BPI Accreditation' => 'BPI Accreditation',
                                                                           'W-9 Form' => 'W-9 Form'};

    private static final Map<String, String> DOCUMENT_TYPE_TO_REVIEW_LICENSE_FIELD_MAP
                                                = new Map<String, String>{'Bonding Document' => 'Bonding_Document_Policy_Number__c',
                                                                          'Worker\'s Compensation Insurance' => 'Workers_Compensation_Policy_Number__c',
                                                                          'Auto Liability Insurance' => 'Auto_Liability_Policy_Number__c',
                                                                          'General Liability Insurance' => 'General_Liability_Policy_Number__c',
                                                                          'W-9 Form' => 'Tax_ID_Number__c'};

    private static final Map<String, String> DOCUMENT_TYPE_TO_REVIEW_EXP_DATE_FIELD_MAP
                                                = new Map<String, String>{'Bonding Document' => 'Bonding_Number_Expiration_Date__c',
                                                                          'Worker\'s Compensation Insurance' => 'Workers_Compensation_Expiration_Date__c',
                                                                          'Auto Liability Insurance' => 'Auto_Liability_Expiration_Date__c',
                                                                          'General Liability Insurance' => 'General_Liability_Expiration_Date__c'};

    public static final Map<Id, Id> APP_PROG_ENROLLMENT_RTYPE_ID_TO_PROG_ENROLLMENT_TYPE_MAP
                                            = new Map<Id, Id>{BIGPGEENrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID => BIGPGEENrollmentReviewUtils.PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID,
                                                                  BIGPGEENrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_HU_RECORDTYPE_ID => BIGPGEENrollmentReviewUtils.PROGRAM_ENROLLMENT_HU_RECORDTYPE_ID,
                                                                  BIGPGEENrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID => BIGPGEENrollmentReviewUtils.PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID};

    /*private static final Map<String, String> PROGRAM_TYPE_TO_REVIEW_LICENSE_ACTIVE_FIELD_MAP = new Map<String, String> {'ACQC' => 'C20_License_Active__c', 'AHU' => 'B_License_Active__c', 'HU' => 'License_Number_Active__c'};

    private static final Map<String, String> PROGRAM_TYPE_TO_REVIEW_LICENSE_DATE_FIELD_MAP = new Map<String, String> {'ACQC' => 'C20_Expiration_Date__c', 'AHU' => 'B_License_Exp_Date__c', 'HU' => 'License_Exp_Date__c'};

    private static final Map<String, String> PROGRAM_TYPE_TO_REVIEW_LICENSE_NUMBER_FIELD_MAP = new Map<String, String> {'ACQC' => 'C20_License_Number__c', 'AHU' => 'B_License_Number__c', 'HU' => 'License_Number__c'};
    */

    private static final Map<String, String> ACQC_CONTRACTOR_REVIEW_LICENSE_FIELDS = new Map<String, String> {'LicenseActive' => 'C20_License_Active__c', 'LicenseNumber' => 'C20_License_Number__c', 'LicenseDate' => 'C20_Expiration_Date__c'};

    private static final Map<String, String> AHU_CONTRACTOR_REVIEW_LICENSE_FIELDS = new Map<String, String> {'LicenseActive' => 'B_License_Active__c', 'LicenseNumber' => 'B_License_Number__c', 'LicenseDate' => 'B_License_Exp_Date__c'};

    private static final Map<String, String> HU_CONTRACTOR_REVIEW_LICENSE_FIELDS = new Map<String, String> {'LicenseActive' => 'License_Number_Active__c', 'LicenseNumber' => 'License_Number__c', 'LicenseDate' => 'License_Exp_Date__c'};

    private static final Map<String, String> AHU_RATER_REVIEW_LICENSE_FIELDS  = new Map<String,String> {'LicenseActive' => 'BPI_Accreditation_Active__c', 'LicenseNumber' => 'BPI_Accreditation_Number__c', 'LicenseDate' => 'BPI_Accreditation_Exp_Date__c'};

    private static final Map<String, Map<String, Map<String,String>>> COMPANY_TYPE_TO_REVIEW_LICENSE_FIELDS
                                            = new Map<String, Map<String, Map<String,String>>> {'Contractor' => new Map<String, Map<String,String>> {'ACQC' => ACQC_CONTRACTOR_REVIEW_LICENSE_FIELDS,
                                                                                                                                                     'AHU' => AHU_CONTRACTOR_REVIEW_LICENSE_FIELDS,
                                                                                                                                                     'HU' => HU_CONTRACTOR_REVIEW_LICENSE_FIELDS},
                                                                                                'Rater Company' => new Map<String, Map<String,String>> {'AHU' => AHU_RATER_REVIEW_LICENSE_FIELDS}};
    // Map that relates staffIds to corresponding contactIds.
    // It gets populated at the processEnrollmentStaff method.
    // It is needed at setStaffCredentials and setRaterCompanyLicenseCredentials
    private static final Map <Id, Id> staffIdToContactIdMap = new Map<Id, Id>();

    // Wrapper class for staff items and it's review items
    public class staffWithReviews {
        public Staff__c staff;
        public List<Program_Enrollment_Staff_Review__c> reviewList;

        staffWithReviews (Staff__c staff, List<Program_Enrollment_Staff_Review__c> reviewList) {
            this.staff = staff;
            this.reviewList = reviewList;
        }
    }

    // Wrapper for document and attachment
    public class documentWithAttachment {
        public Document__c document;
        public Attachment documentAttachment;

        public documentWithAttachment (Document__c document, Attachment documentAttachment) {
            this.document = document;
            this.documentAttachment = documentAttachment;
        }
    }

    /**
     * Creates new contacts
     *
     * @param accountId the account's id.
     * @param staff the enrollment application staff related to the contact that will be created.
     * @return staffContact the contact to be inserted.
     */
    public static Contact createNewContact(Id accountId, Staff__c staff) {
        Contact staffContact;

        if (accountId != null && staff != null) {
            staffContact = new Contact(AccountId = accountId, FirstName = staff.First_Name__c,
                    LastName = staff.Last_Name__c, Email = staff.Email__c, Phone = staff.Phone__c,
                    RecordTypeId = BIGPGEEnrollmentReviewUtils.CONTACT_CONTRACTOR_RECORDTYPE_ID);
        }

        return staffContact;
    }

    /**
     * Creates new employee program enrollments
     *
     * @param programEnrollmentId the program enrollment's id.
     * @param contactId the contact's id.
     * @param appProgEnrollmentStaff the application program enrollment staff related to the contact.
     * @return employeeProgramEnrollment the employee program enrollment to be inserted.
     */
    public static Employee_Program_Enrollment__c createNewEmployeeProgramEnrollment(Id programEnrollmentId,
            Id contactId, Application_Program_Enrollment_Staff__c appProgEnrollmentStaff) {
        Employee_Program_Enrollment__c employeeProgramEnrollment;

        if (programEnrollmentId != null && contactId != null && appProgEnrollmentStaff != null) {
            employeeProgramEnrollment = new Employee_Program_Enrollment__c();
            employeeProgramEnrollment.Contact__c = contactId;
            employeeProgramEnrollment.Program_Enrollment__c = programEnrollmentId;
            employeeProgramEnrollment.Role__c = appProgEnrollmentStaff.Role__c;
        }

        return employeeProgramEnrollment;
    }

    public static Map<Id, Map<String, Map<String, Credential__c>>> getStaffExistingCredentials(List<Id> contactIds) {
        Map<Id, Map<String, Map<String, Credential__c>>> existingCredentials = null;

        if (contactIds != null && !contactIds.isEmpty()) {
            List<Credential__c> loginCredentials = null;
            try {
                loginCredentials = [
                    SELECT Account__c, Contact__c, Credential_Type__c, Expiration_Date__c, Provider_Issued_ID__c,
                        Status__c, Specialization__c,
                        (SELECT File_Name__c, File_Type__c, Credential__c FROM Credential_Files__r)
                    FROM Credential__c
                    WHERE Contact__c IN : contactIds
                    ORDER BY LastModifiedDate asc
                    ];
            } catch (DmlException e) {
                System.debug('Error retrieving credentials for given contacts: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('Error retrieving credentials for given contacts: ' + e.getMessage());
            }

            if (!loginCredentials.isEmpty()) {
                existingCredentials = new Map<Id, Map<String, Map<String, Credential__c>>>();
                for (Credential__c credential : loginCredentials) {
                    String credentialType = CREDENTIAL_TYPE_TO_DOCUMENT_TYPE_MAP.get(credential.Credential_Type__c);
                    if (existingCredentials.containsKey(credential.Contact__c)) {
                        if (!existingCredentials.get(credential.Contact__c).containsKey(credentialType)) {
                            existingCredentials.get(credential.Contact__c).put(credentialType,
                                    new Map<String, Credential__c> {credential.Provider_Issued_ID__c => credential});
                        } else {
                            existingCredentials.get(credential.Contact__c).get(credentialType)
                                    .put(credential.Provider_Issued_ID__c, credential);
                        }
                    } else {
                        existingCredentials.put(credential.Contact__c, new Map <String, Map<String, Credential__c>> {
                                credentialType =>
                                new Map <String, Credential__c> {credential.Provider_Issued_ID__c => credential}});
                    }
                }
            }
        }

        return existingCredentials;
    }

    public static map<Id, map<String, documentWithAttachment>> getStaffDocumentTypeToDocumentMap (set<Id> staffIds) {
        map<Id, map<String, documentWithAttachment>> staffDocumentTypeToDocumentMap = null;

        if (staffIds != null && !staffIds.isEmpty()) {
            staffDocumentTypeToDocumentMap = new map<Id, Map<String, documentWithAttachment>>();
            Map<Id, Document__c> documentIdToDocumentMap = null;

            try {
                documentIdToDocumentMap =  new map<Id, Document__c>([SELECT Id, File_Name__c, File_Type__c, Expiration_Date__c,
                                                                                       Staff__c, Agreement__c
                                                                               FROM Document__c
                                                                               WHERE Staff__c IN : staffIds]);

            } catch (DmlException e) {
                System.debug('Error retrieving documents: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('Error retrieving documents: ' + e.getMessage());
            }

            if (documentIdToDocumentMap != null) {

                Boolean getAttachmentsSuccess = true;

                List<Attachment> documentAttachments = null;

                try {
                    documentAttachments = [
                        SELECT Id, Name, ParentId, Body
                        FROM Attachment
                        WHERE ParentId IN :documentIdToDocumentMap.keySet()
                        ];
                } catch (QueryException e) {
                    System.debug('Error retrieving attachemnts for documents' + e.getMessage());
                    getAttachmentsSuccess = false;
                } catch (Exception e) {
                    System.debug('Error retrieving attachemnts for documents' + e.getMessage());
                    getAttachmentsSuccess = false;
                }

                if (getAttachmentsSuccess) {
                    Map<Id, Attachment> documentIdToAttachmentMap = new Map<Id, Attachment>();

                    if (documentAttachments != null && !documentAttachments.isEmpty()) {
                        for (Attachment currentAttachment : documentAttachments) {
                            if (!documentIdToAttachmentMap.containsKey(currentAttachment.ParentId)) {
                                documentIdToAttachmentMap.put (currentAttachment.ParentId, currentAttachment);
                            }
                        }
                    }

                    for (Document__c document : documentIdToDocumentMap.values()) {
                        DocumentWithAttachment currentDocumentWithAttachment = new DocumentWithAttachment(document, documentIdToAttachmentMap.get(document.Id));

                        if (staffDocumentTypeToDocumentMap.containsKey(document.Staff__c)) {
                            staffDocumentTypeToDocumentMap.get(document.Staff__c).put(document.File_Type__c, currentDocumentWithAttachment);
                        } else {
                            staffDocumentTypeToDocumentMap.put(document.Staff__c, new map<String, DocumentWithAttachment>{document.File_Type__c => currentDocumentWithAttachment});
                        }
                    }
                }
            }
        }

        return staffDocumentTypeToDocumentMap;
    }

    public static Map<Id, Map<String, Map<String, String>>> getStaffIdToStaffCredentialInformation (List<StaffWithReviews> staffWithReviews) {
        Map<Id, Map<String, Map<String, String>>>  staffIdToStaffCredentialInformation = null;

        if (staffWithReviews != null && !staffWithReviews.isEmpty()) {
            staffIdToStaffCredentialInformation = new Map<Id, Map<String, Map<String, String>>>();

            for (staffWithReviews currentStaff : staffWithReviews) {
                if (currentStaff.reviewList != null && !currentStaff.reviewList.isEmpty()) {
                    Map<String, Map<String, String>> currentCredentialInformationMap = new Map<String, Map<String, String>>();

                    for (Program_Enrollment_Staff_Review__c currentReview : currentStaff.reviewList) {
                        for (String currentDocType : DOCUMENT_TYPE_TO_STAFF_INFO_FIELD_LIST_MAP.keySet()) {
                            Boolean isCurrent = true;

                            Map<String, String> currentInfoMap = new Map<String, String>();

                            for (String currentField : DOCUMENT_TYPE_TO_STAFF_INFO_FIELD_LIST_MAP.get(currentDocType)) {
                                isCurrent = isCurrent && currentReview.get(currentField) != null;
                                if (isCurrent) {
                                    currentInfoMap.put(currentField, String.valueOf(currentReview.get(currentField)));
                                }
                            }

                            if (isCurrent) {
                                currentCredentialInformationMap.put (currentDocType, currentInfoMap);
                            }
                        }
                    }
                    staffIdToStaffCredentialInformation.put (currentStaff.staff.Id, currentCredentialInformationMap);
                }
            }
        }

        return staffIdToStaffCredentialInformation;
    }

   public static Map<Id,Set<String>> getStaffActiveId(List<StaffWithReviews> staffWithReviews) {
        Map<Id,Set<String>> idStaffsActives = new Map<Id,Set<String>>();
        if (staffWithReviews != null && !staffWithReviews.isEmpty()) {

            for (staffWithReviews currentStaff : staffWithReviews) {

                if (currentStaff.reviewList != null && !currentStaff.reviewList.isEmpty()) {

                    for (Program_Enrollment_Staff_Review__c currentReview : currentStaff.reviewList) {

                        for (String currentDocType : DOCUMENT_TYPE_TO_STAFF_CERTIFICATION_FIELD_MAP.keySet()) {

                            if (DOCUMENT_TYPE_TO_STAFF_CERTIFICATION_FIELD_MAP.get(currentDocType) != null
                                    && (String)currentReview.get(DOCUMENT_TYPE_TO_STAFF_CERTIFICATION_FIELD_MAP
                                        .get(currentDocType)) == 'Yes') {

                                Id currentStaffId = (Id)currentStaff.Staff.get('Id');

                                if (idStaffsActives.containsKey(currentStaffId)) {
                                    idStaffsActives.get(currentStaffId).add(currentDocType);
                                } else {
                                    idStaffsActives.put(currentStaffId, new Set<String>{currentDocType});
                                }
                            }
                        }
                    }
                }
            }
        }
        return idStaffsActives;
    }

    /**
     * Set staff members credentials that will be inserted into the account
     * @param accountId, id of the account
     * @param staffWithReviewMap, map containing the staff members that have an application review
     * @param staffIdToContactIdMap, map that relates the staff member to a contact
     */
    public static Boolean setStaffCredentials(Id accountId, Map<Id, staffWithReviews> staffWithReviewMap) {
        Boolean success = true;

        if (staffWithReviewMap != null && !staffWithReviewMap.isEmpty() && staffIdToContactIdMap != null 
                && !staffIdToContactIdMap.isEmpty()) {

            List<Credential__c> credentialsToUpsert = new List<Credential__c>();
            List<Credential_File__c> credentialFilesToUpsert = new List<Credential_File__c>();
            List<Attachment> attachmentsToInsert = new List<Attachment>();

            Map<String, Credential__c> staffIdTypeToCredentialMap = new map<String, Credential__c>();
            Map<String, Credential_File__c> staffIdTypeToCredentialFile = new map <String, Credential_File__c>();
            Map<String, Attachment> staffIdTypeToAttachment = new map <String, Attachment>();

            // Flag to check if a credential has to be created or not
            Boolean createCredential = false;

            // Get ids of active staff members
            Map<Id,Set<String>> idsActiveStaff = getStaffActiveId(staffWithReviewMap.values());

            // Get credential information from the review classified by document type
            Map<Id, Map<String, Map<String, String>>> staffIdToStaffCredentialInformation =
                    getstaffIdToStaffCredentialInformation(staffWithReviewMap.values());

            // Get the existing credentials for the current staff members
            Map<Id, Map<String, Map<String, Credential__c>>> existingCredentials =
                    getStaffExistingCredentials(staffIdToContactIdMap.values());

            Map<Id, Map<String, DocumentWithAttachment>> staffDocumentTypeToDocumentMap =
                    getStaffDocumentTypeToDocumentMap(staffWithReviewMap.keySet());

            if (staffDocumentTypeToDocumentMap != null && !staffDocumentTypeToDocumentMap.isEmpty()) {

                for (Id staffId : staffDocumentTypeToDocumentMap.keySet()) {
                    // If the map of active staff members contains the current staff member it set/creates a credential
                    // and its corresponding file
                    if (idsActiveStaff.containsKey(staffId)) {
                        for (String currentDocumentType : staffDocumentTypeToDocumentMap.get(staffId).keySet()) {

                            if (idsActiveStaff.get(staffId).contains(currentDocumentType)) {
                                Credential__c currentCredential = null;
                                Credential_File__c currentCredentialFile = null;

                                // If there's already an existing credential for the current staff member 
                                // and document type, then update it instead of creating a new one.
                                if (existingCredentials != null && staffIdToContactIdMap.containsKey(staffId)
                                        && existingCredentials.containsKey(staffIdToContactIdMap.get(staffId))
                                        && existingCredentials.get(staffIdToContactIdMap.get(staffId))
                                        .get(currentDocumentType) != null) {

                                    if (staffIdToStaffCredentialInformation.containsKey(staffId)
                                            && staffIdToStaffCredentialInformation.get(staffId)
                                            .containsKey(currentDocumentType)) {

                                        for (String currentField : staffIdToStaffCredentialInformation.get(staffId)
                                                .get(currentDocumentType).keySet()) {

                                            if (Schema.SObjectType.Credential__c.fields.getMap()
                                                    .get(REVIEW_FIELD_TO_CREDENTIAL_FIELD_MAP.get(currentField))
                                                    .getDescribe().type.name() != 'DATE') {

                                                String providerIssuedId = (String)staffIdToStaffCredentialInformation
                                                        .get(staffId).get(currentDocumentType).get(currentField);
                                                if (existingCredentials.get(staffIdToContactIdMap.get(staffId))
                                                        .get(currentDocumentType).containsKey(providerIssuedId)) {

                                                    currentCredential = existingCredentials.get(staffIdToContactIdMap
                                                            .get(staffId)).get(currentDocumentType).get(providerIssuedId);

                                                    // Create a new credential file
                                                    currentCredentialFile = new Credential_File__c();
                                                    currentCredentialFile.Credential__c = currentCredential.Id;

                                                    Attachment docAttachment = staffDocumentTypeToDocumentMap
                                                            .get(staffId).get(currentDocumentType).documentAttachment;
                                                    Attachment cfAttachment = docAttachment.clone();
                                                    attachmentsToInsert.add(cfattachment);

                                                    currentCredentialFile.File_Name__c = cfAttachment.Name;
                                                    currentCredentialFile.File_Type__c =
                                                            DOCUMENT_TYPE_TO_CREDENTIAL_FILE_TYPE_MAP
                                                            .get(currentDocumentType);

                                                    // Populate maps to relate new credentials file with their parent
                                                    // credential IDs after inserting
                                                    staffIdTypeToCredentialMap.put(staffId + currentDocumentType,
                                                            currentCredential);
                                                    staffIdTypeToCredentialFile.put(staffId + currentDocumentType,
                                                            currentCredentialFile);
                                                    staffIdTypeToAttachment.put(staffId + currentDocumentType,
                                                            cfAttachment);
                                                }
                                            }
                                        }
                                    }

                                }
                                // Create a new credential
                                if (currentCredential == null) {
                                    currentCredential = new Credential__c();
                                    currentCredential.Account__c = accountId;
                                    currentCredential.Contact__c = staffIdToContactIdMap.get(staffId);
                                    currentCredential.Credential_Type__c =
                                            DOCUMENT_TYPE_TO_CREDENTIAL_TYPE_MAP.get(currentDocumentType);
                                    currentCredential.Status__c = CREDENTIAL_ACTIVE_VERIFIED_STATUS;

                                    try {
                                        // Map the information fields for this credential
                                        if (staffIdToStaffCredentialInformation.containsKey(staffId)
                                                && staffIdToStaffCredentialInformation.get(staffId)
                                                .containsKey(currentDocumentType)) {

                                            for (String currentField : staffIdToStaffCredentialInformation.get(staffId)
                                                    .get(currentDocumentType).keySet()) {

                                                if (Schema.SObjectType.Credential__c.fields.getMap()
                                                        .get(REVIEW_FIELD_TO_CREDENTIAL_FIELD_MAP.get(currentField))
                                                        .getDescribe().type.name() != 'DATE') {

                                                    currentCredential.put(
                                                            REVIEW_FIELD_TO_CREDENTIAL_FIELD_MAP.get(currentField),
                                                            staffIdToStaffCredentialInformation.get(staffId)
                                                                .get(currentDocumentType).get(currentField));
                                                }
                                            }
                                        }
                                    } catch (TypeException e) {
                                        System.debug('Error mapping fields to final data model: ' + e.getMessage());
                                    } catch (Exception e) {
                                        System.debug('Error mapping fields to final data model: ' + e.getMessage());
                                    }

                                    // Create a new credential file
                                    Document__c currentDocument = staffDocumentTypeToDocumentMap.get(staffId)
                                            .get(currentDocumentType).document;

                                    currentCredentialFile = new Credential_File__c();
                                    currentCredentialFile.File_Type__c =
                                            DOCUMENT_TYPE_TO_CREDENTIAL_FILE_TYPE_MAP.get(currentDocumentType);
                                    currentCredentialFile.File_Name__c = currentDocument.File_Name__c;

                                    Attachment docAttachment = staffDocumentTypeToDocumentMap.get(staffId)
                                            .get(currentDocumentType).documentAttachment;
                                    Attachment cfAttachment = docAttachment.clone();
                                    attachmentsToInsert.add(cfattachment);

                                    // Populate maps to relate new credentials file with their parent credential IDs
                                    // after inserting
                                    staffIdTypeToCredentialMap.put(staffId + currentDocumentType, currentCredential);
                                    staffIdTypeToCredentialFile.put(staffId + currentDocumentType, currentCredentialFile);
                                    staffIdTypeToAttachment.put(staffId + currentDocumentType, cfAttachment);
                                }

                                // Add specialization to credentials with BPI type.
                                if (currentCredential.Credential_Type__c == BPI_CREDENTIAL_TYPE) {
                                    Set<String> specializations = new Set<String>();
                                    if (String.isNotBlank(currentCredential.Specialization__c)) {
                                        specializations.addAll(currentCredential.Specialization__c.split(';'));
                                    }
                                    specializations.add(staffWithReviewMap.get(staffId).staff.BPI_Certification_Type__c);
                                    currentCredential.Specialization__c = String.join(new List<String>(
                                            specializations), ';');
                                }

                                // Set status to active verified
                                currentCredential.Status__c = CREDENTIAL_ACTIVE_VERIFIED_STATUS;

                                // Update credential expiration date
                                if (staffIdToStaffCredentialInformation.containsKey(staffId)
                                        && staffIdToStaffCredentialInformation.get(staffId)
                                        .containsKey(currentDocumentType)) {

                                    for (String currentField : staffIdToStaffCredentialInformation.get(staffId)
                                            .get(currentDocumentType).keySet()) {

                                        if (Schema.SObjectType.Credential__c.fields.getMap()
                                                .get(REVIEW_FIELD_TO_CREDENTIAL_FIELD_MAP.get(currentField))
                                                .getDescribe().type.name() == 'DATE') {

                                            Date expDate = (Date)Date.valueOf(staffIdToStaffCredentialInformation
                                                    .get(staffId).get(currentDocumentType).get(currentField));
                                            if (expDate != null) {
                                                currentCredential.put(REVIEW_FIELD_TO_CREDENTIAL_FIELD_MAP
                                                        .get(currentField), expDate);
                                            }
                                        }
                                    }
                                }

                                credentialsToUpsert.add(currentCredential);
                                credentialFilesToUpsert.add(currentCredentialFile);
                            }
                        }
                    }
                }

                try {
                    upsert credentialsToUpsert;
                } catch (DmlException e) {
                    System.debug('Error upserting credentials for staffs: ' + e.getMessage());
                    success = false;
                } catch (Exception e) {
                    System.debug('Error upserting credentials for staffs: ' + e.getMessage());
                    success = false;
                }

                if (success) {
                    for (String key : staffIdTypeToCredentialFile.keySet()) {
                        staffIdTypeToCredentialFile.get(key).Credential__c = staffIdTypeToCredentialMap.get(key).Id;
                    }

                    try {
                        upsert staffIdTypeToCredentialFile.values();
                    } catch (DmlException e) {
                        System.debug('Error inserting new credential files: ' + e.getMessage());
                        success = false;
                    } catch (Exception e) {
                        System.debug('Error inserting new credential files: ' + e.getMessage());
                        success = false;
                    }
                }

                if (success) {
                    for (String key : staffIdTypeToAttachment.keySet()) {
                        staffIdTypeToAttachment.get(key).ParentId = staffIdTypeToCredentialFile.get(key).Id;
                    }

                    try {
                        upsert staffIdTypeToAttachment.values();
                    } catch (DmlException e) {
                        System.debug('Error inserting attachments: ' + e.getMessage());
                        success = false;
                    } catch (Exception e) {
                        System.debug('Error inserting attachments: ' + e.getMessage());
                        success = false;
                    }
                }

            }
        } else {
            success = false;
        }

        return success;
    }

    public static Map<Id, staffWithReviews> getStaffIdToStaffReviewMapByAppProgEnrollmentIds (Set<Id> appEnrollmentIds) {
        Map<Id, staffWithReviews> appEnrollmentStaffMap = null;

        if (appEnrollmentIds != null && !appEnrollmentIds.isEmpty()) {
            List<Staff__c> tempAppEnrollmentStaffList = null;

            try {
                tempAppEnrollmentStaffList = [
                    SELECT Id, Name, Application_Enrollment__c, First_Name__c, Last_Name__c, Phone__c, Email__c,
                        BPI_Certification_Type__c,
                        (SELECT Role__c, Id, Application_Program_Enrollment__c
                         FROM Application_Program_Enrollment_Staffs__r)
                    FROM Staff__c
                    WHERE Id IN
                        (SELECT Staff__c
                         FROM Application_Program_Enrollment_Staff__c
                         WHERE Application_Program_Enrollment__c IN : appEnrollmentIds)
                    ];
            } catch (QueryException e) {
                System.debug('Error retrieving staff for given application: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('Error retrieving staff for given application: ' + e.getMessage());
            }

            if (tempAppEnrollmentStaffList != null && !tempAppEnrollmentStaffList.isEmpty()) {
                // Get all the program staff enrollment Ids
                set<Id> staffEnrollmentIds = new set<Id>();
                appEnrollmentStaffMap = new Map<Id, staffWithReviews>();

                for (Staff__c staff : tempAppEnrollmentStaffList) {
                    staffEnrollmentIds.addAll((new Map<Id,SObject>(staff.Application_Program_enrollment_Staffs__r)).keySet());
                    appEnrollmentStaffMap.put (staff.Id, new StaffWithReviews (staff, new List<Program_Enrollment_Staff_Review__c>()));
                }

                if (!staffEnrollmentIds.isEmpty()) {
                    List<Program_Enrollment_Staff_Review__c> staffReviews = null;

                    try {
                        staffReviews = [
                            SELECT Program_Enrollment__c, Expiration_Date__c, License_Number__c,
                                BPI_Certification_Active__c, BPI_Certification_Active_Override__c,
                                BPI_Certification_Exp_Date__c, BPI_Certification_Number__c,
                                HERS_II_Certification_Active__c, HERS_II_Certification_Active_Override__c,
                                HERS_II_Certification_Exp_Date__c, HERS_II_Certification_Number__c,
                                HVAC_EPA_License__c, HVAC_EPA_License_Override__c, HVAC_Experience__c,
                                HVAC_Experience_Override__c, HVAC_School_or_Training__c,
                                HVAC_School_or_Training_Override__c,
                                Matching_Staff__c, Staff__c, Staff__r.Staff__c, Staff__r.Role__c
                            FROM Program_Enrollment_Staff_Review__c
                            WHERE Staff__c IN : staffEnrollmentIds
                            ];
                    } catch (QueryException e) {
                        System.debug('Error retrieving staff reviews for given staffs: ' + e.getMessage());
                    } catch (Exception e) {
                        System.debug('Error retrieving staff reviews for given staffs: ' + e.getMessage());
                    }

                    if (staffReviews != null && !staffReviews.isEmpty()) {
                        for (Program_Enrollment_Staff_Review__c staffReview : staffReviews) {
                            if (appEnrollmentStaffMap.containsKey(staffReview.Staff__r.Staff__c)) {
                                appEnrollmentStaffMap.get (staffReview.Staff__r.Staff__c).reviewList.add(staffReview);
                            }
                        }
                    }
                }
            }
        }

        return appEnrollmentStaffMap;
    }

    /**
     * Upserts contacts and staff-related credentials
     *
     * @param enrollmentApplication the enrollment application
     * @param appProgEnrollmentIdToProgramEnrollmentMap map that relates the application program id with its corresponding
     * program enrollment
     * @return success if the whole operation was successful
     */
    public static Boolean processEnrollmentStaff(Application_Enrollment__c enrollmentApplication,
            Map<Id, Program_Enrollment__c> appProgEnrollmentIdToProgramEnrollmentMap) {

        Boolean success = true;
        Map<Id, Contact> staffIdToContactMap = new Map<Id, Contact>();
        List<Employee_Program_Enrollment__c> employeeProgEnrollments = new List<Employee_Program_Enrollment__c>();
        List<Program_Enrollment_Staff_Review__c> staffReviews = new List<Program_Enrollment_Staff_Review__c>();
        List<Contact> newContacts = new List<Contact>();

        if (enrollmentApplication != null) {
            Map<Id, staffWithReviews> appEnrollmentStaffMap = getStaffIdToStaffReviewMapByAppProgEnrollmentIds(
                    appProgEnrollmentIdToProgramEnrollmentMap.keySet());

            if (appEnrollmentStaffMap != null && !appEnrollmentStaffMap.isEmpty()) {
                for (staffWithReviews currentStaff : appEnrollmentStaffMap.values()) {
                    if (!currentStaff.reviewList.isEmpty()) {
                        Id matchingStaffId;
                        // Iterate over the staff reviews of the current staff member.
                        for (Program_Enrollment_Staff_Review__c staffReview : currentStaff.reviewList) {
                            if (staffReview.Matching_Staff__c != null) {
                                matchingStaffId = staffReview.Matching_Staff__c;
                                break;
                            }
                        }
                        if (matchingStaffId == null) {
                            // If there isn't any matching staff in any staff review, create a new contact.
                            Contact newContact = createNewContact(enrollmentApplication.Account__c, currentStaff.staff);
                            staffIdToContactMap.put(currentStaff.staff.Id, newContact);
                            newContacts.add(newContact);
                        } else {
                            staffIdToContactMap.put(currentStaff.staff.Id, new Contact(Id = matchingStaffId));
                        }
                    }
                }
                // Insert contacts
                try {
                    insert newContacts;
                } catch (DMLException e) {
                    System.debug('Error while inserting contacts: ' + e.getMessage());
                    success = false;
                }

                if (success) {
                    for (staffWithReviews currentStaff : appEnrollmentStaffMap.values()) {
                        for (Program_Enrollment_Staff_Review__c staffReview : currentStaff.reviewList) {
                            // Populate the matching staff in every staff review for the current staff member.
                            if (staffReview.Matching_Staff__c == null) {
                                staffReview.Matching_Staff__c = staffIdToContactMap.get(currentStaff.staff.Id).Id;
                                staffReviews.add(staffReview);
                            }
                        }
                    }
                    // Update program enrollment staff reviews
                    try {
                        update staffReviews;
                    } catch (DMLException e) {
                        System.debug('Error while updating program enrollment staff reviews: ' + e.getMessage());
                        success = false;
                    }

                    if (success) {
                        // TODO: Remove staffIdToContactIdMap and use staffIdToContactMap instead
                        for (Id staffId : staffIdToContactMap.keySet()) {
                            staffIdToContactIdMap.put(staffId, staffIdToContactMap.get(staffId).Id);
                        }

                        for (staffWithReviews currentStaff : appEnrollmentStaffMap.values()) {
                            for (Application_Program_Enrollment_Staff__c appProgEnrollmentStaff :
                                    currentStaff.staff.Application_Program_Enrollment_Staffs__r) {
                                Id appProgEnrollmentId = appProgEnrollmentStaff.Application_Program_Enrollment__c;
                                // Create a new employee program enrollment
                                if (appProgEnrollmentIdToProgramEnrollmentMap.containsKey(appProgEnrollmentId)
                                        && staffIdToContactIdMap.containsKey(currentStaff.staff.Id)) {
                                    employeeProgEnrollments.add(createNewEmployeeProgramEnrollment(
                                                appProgEnrollmentIdToProgramEnrollmentMap.get(appProgEnrollmentId).Id,
                                                staffIdToContactIdMap.get(currentStaff.staff.Id), appProgEnrollmentStaff));
                                }
                            }
                        }
                        // Insert employee program enrollments
                        try {
                            insert employeeProgEnrollments;
                        } catch (DMLException e) {
                            System.debug('Error while inserting employee program enrollments: ' + e.getMessage());
                            success = false;
                        }
                        // Create/Update credentials for staff items
                        if (success) {
                            success = setStaffCredentials(enrollmentApplication.Account__c, appEnrollmentStaffMap);
                        }
                    }
                }
            }
        } else {
            success = false;
        }

        return success;
    }

    public static List<Application_Program_Enrollment_License__c> getLicensesByApplicationProgramEnrollmentIds(
            Set<Id> programEnrollmentIds) {
        List<Application_Program_Enrollment_License__c> appProgEnrollmentLicenses = null;

        // Get all program licenses
        try {
            appProgEnrollmentLicenses = [
                SELECT Application_Program_Enrollment__c, License__c, License__r.Expiration_Date__c, License__r.Type__c,
                    License__r.Has2YearsExperience__c, License__r.License_Number__c, License__r.Staff__c
                FROM Application_Program_Enrollment_License__c
                WHERE Application_Program_Enrollment__c IN :programEnrollmentIds
                ];
        } catch (DmlException e) {
            System.debug('Error retrieving licenses for the specified programs: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving licenses for the specified programs: ' + e.getMessage());
        }
        return appProgEnrollmentLicenses;
    }

    public static List<Application_Program_Enrollment_Agreement__c> getAgreementsByApplicationProgramEnrollmentIds (set<Id> programEnrollmentIds) {
        List<Application_Program_Enrollment_Agreement__c> appProgEnrollmentAgreements = null;

        // get all the licenses for the programs
        try {
            appProgEnrollmentAgreements = [SELECT Application_Program_Enrollment__c, Agreement__c
                                                FROM Application_Program_Enrollment_Agreement__c
                                                WHERE Application_Program_Enrollment__c IN : programEnrollmentIds];
        } catch (DmlException e) {
            System.debug('Error retrieving agreements for the specified programs: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving agreements for the specified programs: ' + e.getMessage());
        }

        return appProgEnrollmentAgreements;
    }

    public static List<License_Document__c> getLicenseDocumentsByLicenseId (Set<Id> licenseIds) {
        // Get the license/document information for the retrieved licenses
        List<License_Document__c> licenseDocuments = null;

        try {
            licenseDocuments = [SELECT Document__c, License__c,
                                       Document__r.Expiration_Date__c,
                                       Document__r.File_Name__c, Document__r.File_Type__c, Document__r.Staff__c
                                FROM License_Document__c
                                WHERE License__c IN : licenseIds];
        } catch (QueryException e) {
            System.debug('Error retrieving license documents: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving license documents: ' + e.getMessage());
        }

        return licenseDocuments;
    }

    public static List<Document__c> getAgreementDocumentsByAgreementId (Set<Id> agreementIds) {
        // Get the license/document information for the retrieved agreements
        List<Document__c> agreementDocuments = null;

        try {
            agreementDocuments = [SELECT Id, Agreement__c,
                                         Expiration_Date__c,
                                         File_Name__c, File_Type__c, Staff__c
                                FROM Document__c
                                WHERE Agreement__c IN : agreementIds];
        } catch (QueryException e) {
            System.debug('Error retrieving agreement documents: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error retrieving agreement documents: ' + e.getMessage());
        }

        return agreementDocuments;
    }

    public static Boolean cloneAttachments (Map<Id, sObject> originalIdToNewParentMap) {
        Boolean success = false;

        if (originalIdToNewParentMap != null) {
            List<Attachment> attachments = null;

            try {
                attachments = [
                    SELECT Id, Name, Body, ParentId
                    FROM Attachment
                    WHERE ParentId IN :originalIdToNewParentMap.keySet()
                    ];
            } catch (QueryException e) {
                System.debug('Error retrieving attachments for the specified ids ' + e.getMessage());
                success = false;
            } catch (Exception e) {
                System.debug('Error retrieving attachments for the specified ids ' + e.getMessage());
                success = false;
            }

            if (attachments != null) {

                List<Attachment> newAttachments = new List<Attachment>();

                for (Attachment oldAttachment : attachments) {
                    Attachment newAttachment = oldAttachment.clone();
                    newAttachment.ParentId = originalIdToNewParentMap.get(oldAttachment.ParentId).Id;
                    newAttachments.add(newAttachment);
                }

                try {
                    insert newAttachments;
                }
                catch (DmlException e) {
                    System.debug('Error inserting new attachments: ' + e.getMessage());
                    success = false;
                }
                catch (Exception e) {
                    System.debug('Error inserting new attachments: ' + e.getMessage());
                    success = false;
                }
            }
        } else {
            success = false;
        }

        return success;
    }

    /**
     * Creates credential files to be inserted in the corresponding license credential of the account
     * @param licenseDocuments, list of license documents
     * @param licenseCredential, the license crendential of the account
     */
    public static List<Credential_File__c> createProgramLicenseDocumentFiles(
            List<License_Document__c> licenseDocuments, Credential__c licenseCredential) {

        List<Credential_File__c>  licenseCredentialFiles = null;

        if (licenseDocuments != null && !licenseDocuments.isEmpty() && licenseCredential != null) {

            licenseCredentialFiles = new List<Credential_File__c>();
            Map<Id, Credential_File__c> licenseIdToCredentialFileMap = new Map<Id, Credential_File__c>();

            for (License_Document__c licenseDocument : licenseDocuments) {
                if (!licenseIdToCredentialFileMap.containsKey(licenseDocument.Document__c)) {
                    Credential_File__c newCredentialFile = new Credential_File__c();
                    newCredentialFile.Credential__c = licenseCredential.Id;
                    newCredentialFile.File_Type__c = licenseDocument.Document__r.File_Type__c;
                    newCredentialFile.File_Name__c = licenseDocument.Document__r.File_Name__c;
                    licenseCredentialFiles.add(newCredentialFile);
                    licenseIdToCredentialFileMap.put (licenseDocument.Document__c, newCredentialFile);
                }
            }

            try {
                insert licenseCredentialFiles;
                cloneAttachments (licenseIdToCredentialFileMap);

            } catch (DmlException e) {
                System.Debug('Error creating license credential files: ' + e.getMessage());
            } catch (Exception e) {
                System.Debug('Error creating license credential files: ' + e.getMessage());
            }
        }

        return licenseCredentialFiles;
    }

    public static List<Program_Enrollment_File__c> createProgramAgreementDocumentFiles (List<Document__c> agreementDocuments,
                                                                                      Map<Id, Program_Enrollment__c> newAppProgEnrollments,
                                                                                      Map<Id, List<Application_Program_Enrollment_Agreement__c>> appProgEnrollmentToAgreementsMap) {

        Map<Id, List<Document__c>> agreementToDocumentMap = new Map<Id, List<Document__c>> ();
        Boolean success = true;
        List<Program_Enrollment_File__c> newProgramEnrollmentFiles = null;

        for (Document__c agreementDocument : agreementDocuments) {
            if (agreementToDocumentMap.containsKey(agreementDocument.Agreement__c)) {
                agreementToDocumentMap.get(agreementDocument.Agreement__c).add (agreementDocument);
            } else {
                agreementToDocumentMap.put(agreementDocument.Agreement__c, new list<Document__c>{agreementDocument});
            }

        }

        // Create the program enrollment files
        newProgramEnrollmentFiles = new list<Program_Enrollment_File__c>();

        // Map to clone attachments
        Map<Id, Program_Enrollment_File__c> documentIdToProgramEnrollmentFile = new Map <Id, Program_Enrollment_File__c>();

        for (Id progEnrollmentId : newAppProgEnrollments.keySet()) {
            if (appProgEnrollmentToAgreementsMap.containsKey(progEnrollmentId)) {

                for (Application_Program_Enrollment_Agreement__c appProgEnrollmentAgreement : appProgEnrollmentToAgreementsMap.get(progEnrollmentId)) {
                    if (agreementToDocumentMap.containsKey(appProgEnrollmentAgreement.Agreement__c)) {
                        for (Document__c agreementDocument : agreementToDocumentMap.get(appProgEnrollmentAgreement.Agreement__c)) {
                            Program_Enrollment_File__c programEnrollmentFile = new Program_Enrollment_File__c();

                            programEnrollmentFile.Program_Enrollment__c = newAppProgEnrollments.get(progEnrollmentId).Id;
                            programEnrollmentFile.File_Name__c = agreementDocument.File_Name__c;
                            programEnrollmentFile.File_Type__c = AGREEMENT_PROGRAM_ENROLLMENT_FILE_TYPE;
                            newProgramEnrollmentFiles.add (programEnrollmentFile);
                            documentIdToProgramEnrollmentFile.put(agreementDocument.Id, programEnrollmentFile);
                        }
                    }
                }
            }
        }

        try {
            insert newProgramEnrollmentFiles;
        } catch (DmlException e) {
            success = false;
        } catch (Exception e) {
            success = false;
        }

        if (success) {
            success = cloneAttachments(documentIdToProgramEnrollmentFile);
        }

        return newProgramEnrollmentFiles;
    }

    /**
     * Upserts program enrollments and program-related credentials
     *
     * @param enrollmentApplication the enrollment application
     * @param newAppProgEnrollments map containing new program enrollments to be inserted into the account
     * @param appProgEnrollmentReviews map containing the application program enrollment reviews
     * @return success if the whole operation was successful
     */
    public static Boolean processProgramEnrollment(Application_Enrollment__c enrollmentApplication,
            Map<Id, Program_Enrollment__c> newAppProgEnrollments,
            Map<String, Application_Program_Enrollment_Review__c> appProgEnrollmentReviews) {
        Boolean success = true;

        if (enrollmentApplication != null) {
            List<Application_Program_Enrollment_License__c> appProgEnrollmentLicenses;
            List<Application_Program_Enrollment_Agreement__c> appProgEnrollmentAgreements;
            Map<Id, List<Application_Program_Enrollment_Agreement__c>> appProgEnrollmentToAgreementsMap;
            Map<String, Map<String, Date>> licenseNumberToProgTypeExpDate;

            appProgEnrollmentLicenses = getLicensesByApplicationProgramEnrollmentIds(newAppProgEnrollments.keySet());
            appProgEnrollmentAgreements = getAgreementsByApplicationProgramEnrollmentIds(newAppProgEnrollments.keySet());
            licenseNumberToProgTypeExpDate = getReviewLicensesActive(appProgEnrollmentReviews, enrollmentApplication.Type__c);

            // Process program licenses
            if (appProgEnrollmentLicenses != null && !appProgEnrollmentLicenses.isEmpty() &&
                    !licenseNumberToProgTypeExpDate.isEmpty()) {
                success = setProgramCredentials(enrollmentApplication, appProgEnrollmentLicenses, licenseNumberToProgTypeExpDate);
            }

            // Process program agreements
            if (appProgEnrollmentAgreements != null && success) {
                appProgEnrollmentToAgreementsMap = new Map<Id, List<Application_Program_Enrollment_Agreement__c>>();
                Set<Id> agreementIds = new Set<Id>();

                for (Application_Program_Enrollment_Agreement__c appProgEnrollmentAgreement : appProgEnrollmentAgreements) {
                    if (appProgEnrollmentToAgreementsMap.containsKey(appProgEnrollmentAgreement.Application_Program_Enrollment__c)) {
                        appProgEnrollmentToAgreementsMap.get(appProgEnrollmentAgreement.Application_Program_Enrollment__c)
                                                            .add (appProgEnrollmentAgreement);
                    } else {
                        appProgEnrollmentToAgreementsMap.put(appProgEnrollmentAgreement.Application_Program_Enrollment__c,
                                                            new list<Application_Program_Enrollment_Agreement__c>{appProgEnrollmentAgreement});
                    }

                    agreementIds.add (appProgEnrollmentAgreement.Agreement__c);
                }

                // Get the agreement/document information for the retrieved agreements
                List<Document__c> agreementDocuments = getAgreementDocumentsByAgreementId (agreementIds);

                if (agreementDocuments != null) {
                    List<Program_Enrollment_File__c> newProgramEnrollmentFiles = createProgramAgreementDocumentFiles(agreementDocuments, newAppProgEnrollments, appProgEnrollmentToAgreementsMap);
                }
            }
        }

        return success;
    }

    /**
     * Set program credentials
     *
     * @param enrollmentApplication the enrollment application
     * @param appProgEnrollmentLicenses list of application program enrollments
     * @param licenseNumberToProgTypeExpDate map that relates the license number with its corresponding program type and exp date
     * @return success if the operation was successful
     */
    private static Boolean setProgramCredentials(Application_Enrollment__c enrollmentApplication,
            List<Application_Program_Enrollment_License__c> appProgEnrollmentLicenses,
            Map<String, Map<String, Date>> licenseNumberToProgTypeExpDate) {

        Boolean success = true;
        String credentialType;

        credentialType = enrollmentApplication.Type__c == 'Contractor'
                                                          ? CONTRACTOR_LICENSE_CREDENTIAL_TYPE
                                                          : RATER_COMPANY_LICENSE_CREDENTIAL_TYPE;

        // Set licence credentials for Contractor or Rater Company
        if (credentialType == RATER_COMPANY_LICENSE_CREDENTIAL_TYPE) {
            success = setRaterCompanyLicenseCredentials(enrollmentApplication, licenseNumberToProgTypeExpDate,
                    appProgEnrollmentLicenses);
        } else {
            success = setContractorLicenseCredentials(enrollmentApplication, licenseNumberToProgTypeExpDate,
                    appProgEnrollmentLicenses);
        }
        return success;
    }

    /**
     * Get active licenses
     *
     * @param appProgEnrollmentReviews map containing the program type as key, and the program review as value
     * @param companyType type of company
     * @return myMap map containing every active license's number (provider-issed id), program type, and expiration date
     */
    private static Map<String, Map<String, Date>> getReviewLicensesActive(
            Map<String, Application_Program_Enrollment_Review__c> appProgEnrollmentReviews, String companyType) {

        Application_Program_Enrollment_Review__c appPrgReview;
        Map<String, Map<String,Date>> myMap = new Map<String, Map<String,Date>>();
        Map<String, String> reviewLicenseFields;

        // Individual Raters company don't have licenses.
        if (companyType != 'Individual Rater') {
            for (String appPrgType : appProgEnrollmentReviews.keySet()) {
                appPrgReview = appProgEnrollmentReviews.get(appPrgType);
                reviewLicenseFields = COMPANY_TYPE_TO_REVIEW_LICENSE_FIELDS.get(companyType).get(appPrgType);

                if ((String)appPrgReview.get(reviewLicenseFields.get('LicenseActive')) == 'Yes') {
                    String licenseNumber = (String)appPrgReview.get(reviewLicenseFields.get('LicenseNumber'));
                    Date licenseDate = (Date)appPrgReview.get(reviewLicenseFields.get('LicenseDate'));

                    if (!myMap.containsKey(licenseNumber)) {
                        myMap.put(licenseNumber, new Map<String, Date>{ appPrgType => licenseDate});
                    } else {
                        myMap.get(licenseNumber).put(appPrgType, licenseDate);
                    }
                }
            }
        }
        return myMap;
    }

    private static Map<String, documentWithAttachment> getDocumentsByEnrollmentApplicationId(Id appEnrollmentId) {
        Map<String, documentWithAttachment> documentTypeToDocumentMap = null;

        if (appEnrollmentId != null) {
            Map<Id, Document__c> appEnrollmentDocumentsMap = null;

            try {
                appEnrollmentDocumentsMap = new Map<Id, Document__c>([
                    SELECT Id, Name, File_Name__c, File_Type__c, Application_Enrollment__c
                    FROM Document__c WHERE Application_Enrollment__c = :appEnrollmentId
                    ]);
            } catch (QueryException e) {
                System.debug('Error retrieving application enrollment documents: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('Error retrieving application enrollment documents: ' + e.getMessage());
            }

            if (appEnrollmentDocumentsMap != null) {
                // Get the attachments
                Boolean success = true;
                List<Attachment> documentAttachments = null;

                try {
                    documentAttachments = [
                        SELECT Id, Name, ParentId, Body
                        FROM Attachment
                        WHERE ParentId IN :appEnrollmentDocumentsMap.keySet()
                        ];
                } catch (QueryException e) {
                    System.debug('Error retrieving document attachments: ' + e.getMessage());
                    success = false;
                } catch (Exception e) {
                    System.debug('Error retrieving document attachments: ' + e.getMessage());
                    success = false;
                }

                if (success) {
                    documentTypeToDocumentMap = new Map<String, documentWithAttachment>();

                    // Populate the relationship list for the documents
                    for (Attachment documentAttachment : documentAttachments) {
                        DocumentWithAttachment newDocument = new DocumentWithAttachment(
                                appEnrollmentDocumentsMap.get(documentAttachment.parentId), documentAttachment);
                        documentTypeToDocumentMap.put(newDocument.document.File_Type__c, newDocument);
                    }
                    // If the user didn't upload a document for auto liability insurance, we still need to add it to
                    // the map to create the credential at the account (set with Exempt - Verified status).
                    if (!documentTypeToDocumentMap.containsKey(AUTO_LIABILITY_INSURANCE_CREDENTIAL_TYPE)) {
                        documentTypeToDocumentMap.put(AUTO_LIABILITY_INSURANCE_CREDENTIAL_TYPE, null);
                    }
                }
            }
        }

        return documentTypeToDocumentMap;
    }

    private static Map<String, Map<String, Credential__c>> getCredentialsByAccountId(Id accountId) {
        Map<String, Map<String, Credential__c>> credentialTypeToCredentialMap;

        if (accountId != null) {
            List<Credential__c> accountCredentials;

            try {
                accountCredentials = [
                    SELECT Id, Name, Account__c, Credential_Type__c, Expiration_Date__c, Provider_Issued_ID__c,
                        Status__c
                    FROM Credential__c
                    WHERE Account__c = : accountId
                    ];
            } catch (QueryException e) {
                System.debug('Error retrieving account credentials: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('Error retrieving account credentials: ' + e.getMessage());
            }

            if (accountCredentials != null) {
                credentialTypeToCredentialMap = new Map<String, Map<String,Credential__c>>();

                for (Credential__c currentCredential : accountCredentials) {
                    if (!credentialTypeToCredentialMap.containsKey(currentCredential.Credential_Type__c)) {
                        credentialTypeToCredentialMap.put(currentCredential.Credential_Type__c,
                                new Map<String, Credential__c> {
                                        currentCredential.Provider_Issued_ID__c => currentCredential
                                    });
                    } else {
                        credentialTypeToCredentialMap.get(currentCredential.Credential_Type__c)
                                .put(currentCredential.Provider_Issued_ID__c, currentCredential);
                    }
                }
            }
        }

        return credentialTypeToCredentialMap;
    }

    /**
     * Set program credential for Contractor license
     *
     * @param enrollmentApplication the enrollment application
     * @param licenseNumberToProgTypeExpDate map that relates the license number with its corresponding program type and exp date
     * @param appProgEnrollmentLicenses list of application program enrollments
     * @return success if the operation was successful
     */
    private static Boolean setContractorLicenseCredentials(Application_Enrollment__c enrollmentApplication,
            Map<String, Map<String, Date>> licenseNumberToProgTypeExpDate,
            List<Application_Program_Enrollment_License__c> appProgEnrollmentLicenses) {

        Map<String, Credential__c> licenseCredentials = new Map<String, Credential__c>();
        Map<Id, License__c> progIdToLicense = new Map<Id, License__c>();
        List<Credential__c> credentialsToProcess = new List<Credential__c>();
        Set<Id> licenseIds = new Set<Id>();
        Set<String> specializations = new Set<String>();
        Set<String> newSpecs = new Set<String>();
        Credential__c licenseCredential;
        Boolean success = true;
        Id accountId = enrollmentApplication.Account__c;

        if (accountId != null) {
            try {
                List<Credential__c> existingCredentials = [
                    SELECT Id, Name, Account__c, Credential_Type__c, Expiration_Date__c, Contact__c, Status__c,
                        Specialization__c, Provider_Issued_ID__c,
                        (SELECT Id, Name, Credential__c, File_Name__c, File_Type__c
                         FROM Credential_Files__r)
                    FROM Credential__c 
                    WHERE Account__c = :accountId AND Credential_Type__c = :CONTRACTOR_LICENSE_CREDENTIAL_TYPE
                    ORDER BY LastModifiedDate asc
                    ];
                for (Credential__c credential : existingCredentials) {
                    licenseCredentials.put(credential.Provider_Issued_ID__c, credential);
                }
            } catch (QueryException e) {
                System.debug('Error retrieving account credentials: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('Error retrieving account credentials: ' + e.getMessage());
            }
        }

        for (Application_Program_Enrollment_License__c license : appProgEnrollmentLicenses) {
            progIdToLicense.put(license.Application_Program_Enrollment__c, license.License__r);
        }

        // Get license number. It will always be unique due to front-end validation.
        String licenseNumber = new List<String>(licenseNumberToProgTypeExpDate.keySet())[0];
        // Get expiration date. It will always be unique due to front-end validation.
        Map<String, Date> progTypeToDate = licenseNumberToProgTypeExpDate.get(licenseNumber);
        Date licenseExpDate = progTypeToDate.values()[0];

        for (String progId : progIdToLicense.keySet()) {
            // Need license ids to get license documents
            licenseIds.add(progIdToLicense.get(progId).Id);
            // Add new specializations
            newSpecs.add(progIdToLicense.get(progId).Type__c);
            // For ACQC + AHU, if only one license number is provided, add only it's corresponding specialization.
            if (progTypeToDate.containsKey(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME)
                    && !progTypeToDate.containsKey(BIGPGEEnrollmentAppProgramUtility.APP_PRG_AHU_RT_NAME)) {
                newSpecs.remove(B_LICENSE_TYPE);
            } else if (!progTypeToDate.containsKey(BIGPGEEnrollmentAppProgramUtility.APP_PRG_ACQC_RT_NAME)
                    && progTypeToDate.containsKey(BIGPGEEnrollmentAppProgramUtility.APP_PRG_AHU_RT_NAME)) {
                newSpecs.remove(C20_LICENSE_TYPE);
            }
            specializations.addAll(newSpecs);
        }

        // For matching credentials, add existing specializations
        if (licenseCredentials.get(licenseNumber) != null) {
            licenseCredential = licenseCredentials.get(licenseNumber);
            specializations.addAll(licenseCredential.Specialization__c.split(';'));
        }

        // Set credential fields
        licenseCredential = setCredentialFields(licenseCredential, accountId, null, CONTRACTOR_LICENSE_CREDENTIAL_TYPE,
                licenseNumber, licenseExpDate, specializations);
            credentialsToProcess.add(licenseCredential);

        // Upsert the licenseCredential
        try {
            upsert credentialsToProcess;
        } catch (DmlException e) {
            System.debug('Error upserting license credential: ' + e.getMessage());
            success = false;
        }
        if (success) {
            // Get the license/document information for the retrieved licenses
            List<License_Document__c> licenseDocuments = getLicenseDocumentsByLicenseId(licenseIds);
            if (licenseDocuments != null) {
                createProgramLicenseDocumentFiles(licenseDocuments, licenseCredential);
            }
        }
        return success;
    }

    /**
     * Set program credential for Rater Company license
     *
     * @param enrollmentApplication the enrollment application
     * @param licenseNumberToProgTypeExpDate map that relates the license number with its corresponding program type and exp date
     * @param appProgEnrollmentLicenses list of application program enrollments
     * @return success if the operation was successful
     */
    private static Boolean setRaterCompanyLicenseCredentials(Application_Enrollment__c enrollmentApplication,
            Map<String, Map<String, Date>> licenseNumberToProgTypeExpDate,
            List<Application_Program_Enrollment_License__c> appProgEnrollmentLicenses) {

        Map<Id, Map<String, Credential__c>> existingCredentials;
        Map<Id, License__c> progIdToLicense = new Map<Id, License__c>();
        List<Credential__c> licenseCredentials;
        List<Credential__c> credentialsToProcess = new List<Credential__c>();
        Credential__c licenseCredential;
        Set<Id> licenseIds = new Set<Id>();
        Boolean success = true;
        Id qualifyingIndividualStaffId;
        Id qualifyingIndividualContactId;
        Id accountId = enrollmentApplication.Account__c;

        if (accountId != null) {
            try {
                licenseCredentials = [
                    SELECT Id, Name, Account__c, Credential_Type__c, Expiration_Date__c, Contact__c, Status__c,
                        Specialization__c, Provider_Issued_ID__c,
                        (SELECT Id, Name, Credential__c, File_Name__c, File_Type__c
                         FROM Credential_Files__r)
                    FROM Credential__c
                    WHERE Account__c = :accountId AND Credential_Type__c = :RATER_COMPANY_LICENSE_CREDENTIAL_TYPE
                    ORDER BY LastModifiedDate asc
                    ];
            } catch (QueryException e) {
                System.debug('Error retrieving account credentials: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('Error retrieving account credentials: ' + e.getMessage());
            }
        }

        // Need license ids to get license documents
        for (Application_Program_Enrollment_License__c license : appProgEnrollmentLicenses) {
            licenseIds.add(license.License__c);
        }

        // Get Qualifying Individual for BPI Accreditation/Goldstar Status
        qualifyingIndividualStaffId = appProgEnrollmentLicenses.get(0).License__r.Staff__c;
        qualifyingIndividualContactId = staffIdToContactIdMap.get(qualifyingIndividualStaffId);
        // Get license number. It will always be unique due to front-end validation.
        String licenseNumber = new List<String>(licenseNumberToProgTypeExpDate.keySet())[0];
        // Get expiration date. It will always be unique due to front-end validation.
        Map<String, Date> progTypeToDate = licenseNumberToProgTypeExpDate.get(licenseNumber);
        Date licenseExpDate = progTypeToDate.values()[0];

        if (!licenseCredentials.isEmpty()) {
            existingCredentials = new Map<Id, Map<String, Credential__c>>();
            for (Credential__c credential : licenseCredentials) {
                if (existingCredentials.containsKey(credential.Contact__c)) {
                    existingCredentials.get(credential.Contact__c).put(credential.Provider_Issued_ID__c, credential);
                } else {
                    existingCredentials.put(credential.Contact__c, new Map<String, Credential__c> {
                            credential.Provider_Issued_ID__c => credential});
                }
            }
            if (existingCredentials.containsKey(qualifyingIndividualContactId)
                    && existingCredentials.get(qualifyingIndividualContactId).containsKey(licenseNumber)) {
                // Get matching credential
                licenseCredential = existingCredentials.get(qualifyingIndividualContactId).get(licenseNumber);
            }
        }
        // Set credential fields
        licenseCredential = setCredentialFields(licenseCredential, accountId, qualifyingIndividualContactId,
                    RATER_COMPANY_LICENSE_CREDENTIAL_TYPE, licenseNumber, licenseExpDate, null);
        credentialsToProcess.add(licenseCredential);
        // Upsert the licenseCredential
        try {
            upsert credentialsToProcess;
        } catch (DmlException e) {
            System.debug('Error upserting license credential: ' + e.getMessage());
            success = false;
        }
        if (success) {
            // Get the license/document information for the retrieved licenses
            List<License_Document__c> licenseDocuments = getLicenseDocumentsByLicenseId(licenseIds);
            if (licenseDocuments != null) {
                createProgramLicenseDocumentFiles(licenseDocuments, licenseCredential);
            }
        }
        return success;
    }

    /**
     * Set credential field values
     *
     * @param credential the existing credential
     * @param accountId the account id
     * @param contactId the contact id
     * @param credentialType the credential type based on the company type
     * @param licenseNumber the licenseNumber/provider issued id
     * @param licenseExpDate the license's expiration date
     * @param specialiations the license's specializations
     * @return credential the credential with their values set
     */
    private static Credential__c setCredentialFields(Credential__c credential, Id accountId, Id contactId,
            String credentialType, String licenseNumber, Date licenseExpDate, Set<String> specializations) {

        if (credential == null) {
            credential = new Credential__c();
            credential.Account__c = accountId;
        }
        credential.Contact__c = contactId;
        credential.Credential_Type__c = credentialType;
        credential.Provider_Issued_ID__c = licenseNumber;
        credential.Status__c = CREDENTIAL_ACTIVE_VERIFIED_STATUS;
        credential.Expiration_Date__c = licenseExpDate;
        credential.Specialization__c = String.join(new List<String>(specializations), ';');

        return credential;
    }

    public class MyException extends Exception {}

    public static Boolean processAppEnrollmentCredentials(Id appEnrollmentId, Id accountId,
            Enrollment_Application_Review__c appReview) {
        Boolean success = true;

        if (accountId != null && appEnrollmentId != null && appReview != null) {
            // Get the credential documents for this application
            Map<String, documentWithAttachment> documentTypeToDocumentMap =
                    getDocumentsByEnrollmentApplicationId(appEnrollmentId);

            if (documentTypeToDocumentMap != null) {
                // Get existing enrollment credentials for the account
                Map<String, Map<String, Credential__c>> credentialTypeToCredentialMap =
                        getCredentialsByAccountId(accountId);

                List<Credential__c> credentialsToUpsert = new List<Credential__c>();
                List<Credential_File__c> credentialFilesToUpsert = new List<Credential_File__c>();
                List<Attachment> attachmentsToInsert = new List<Attachment>();

                // Maps used to set new attachment parent IDs
                Map<Id, Credential_File__c> documentIdToCredentialFileMap = new Map<Id, Credential_File__c>();
                Map<Id, Attachment> documentIdToAttachmentMap = new Map<Id, Attachment>();
                Map<Id, Credential__c> documentIdToCredentialMap = new Map<Id, Credential__c>();

                for (String documentType : documentTypeToDocumentMap.keySet()) {
                    String credentialField = DOCUMENT_TYPE_TO_CREDENTIAL_FIELD_MAP.get(documentType);
                    Boolean isAutoLiabilityOverride = (String.isNotBlank(credentialField)
                            && (String)appReview.get(credentialField) == 'Override'
                            && documentType == AUTO_LIABILITY_INSURANCE_CREDENTIAL_TYPE);

                    if (String.isNotBlank(credentialField) && ((String)appReview.get(credentialField) == 'Yes'
                            || isAutoLiabilityOverride)) {
                        // There is no need for a document and an attachment when auto liability is overriden.
                        Document__c currentDocument;
                        Attachment currentAttachment;
                        if (!isAutoLiabilityOverride) {
                            currentDocument = documentTypeToDocumentMap.get(documentType).document;
                            currentAttachment = documentTypeToDocumentMap.get(documentType).documentAttachment;
                        }
                        Credential__c currentCredential;
                        Credential_File__c currentCredentialFile;
                        String credentialType = DOCUMENT_TYPE_TO_CREDENTIAL_TYPE_MAP.get(documentType);
                        // Add a variable to check if Workers Compensation Insurance Option was checked on review in
                        // order to add or update a credential on Account
                        Boolean upsertCredential = documentType != 'Worker\'s Compensation Insurance'
                                || appReview.Workers_Compensation_Type__c == 'Worker\'s Compensation Insurance';
                        String credentialPolicyNumberField = DOCUMENT_TYPE_TO_REVIEW_LICENSE_FIELD_MAP.get(documentType);

                        if (String.isNotBlank(credentialType)
                                && credentialTypeToCredentialMap.get(credentialType) != null
                                && String.isNotBlank(credentialPolicyNumberField)
                                && credentialTypeToCredentialMap.get(credentialType)
                                        .containsKey((String)appReview.get(credentialPolicyNumberField))
                                && upsertCredential) {
                            currentCredential = credentialTypeToCredentialMap.get(credentialType)
                                    .get((String)appReview.get(credentialPolicyNumberField));
                        } else if (upsertCredential) {
                            currentCredential = new Credential__c();
                            currentCredential.Account__c = accountId;
                            currentCredential.Credential_Type__c = credentialType;
                        }

                        // Update credential license number
                        if (currentCredential != null && String.isNotBlank(credentialPolicyNumberField)) {
                            currentCredential.Provider_Issued_ID__c =
                                    (String)appReview.get(credentialPolicyNumberField);
                        }

                        // Update credential expiration date
                        if (currentCredential != null &&
                                DOCUMENT_TYPE_TO_REVIEW_EXP_DATE_FIELD_MAP.containsKey(documentType)) {
                            Date expDate =
                                    (Date)appReview.get(DOCUMENT_TYPE_TO_REVIEW_EXP_DATE_FIELD_MAP.get(documentType));
                            if (expDate != null) {
                                currentCredential.Expiration_Date__c = expDate;
                            }
                        }

                        if (currentCredential != null) {
                            currentCredential.Status__c = isAutoLiabilityOverride
                                                          ? CREDENTIAL_EXEMPT_VERIFIED_STATUS
                                                          : CREDENTIAL_ACTIVE_VERIFIED_STATUS;
                            credentialsToUpsert.add(currentCredential);
                        }

                        // Insert credential files
                        if (currentAttachment != null && upsertCredential) {
                            currentCredentialFile = new Credential_File__c();
                            currentCredentialFile.File_Name__c = currentDocument.File_Name__c;
                            currentCredentialFile.File_Type__c =
                                    DOCUMENT_TYPE_TO_CREDENTIAL_FILE_TYPE_MAP.get(documentType);
                            // Clone the attachment
                            Attachment newAttachment = currentAttachment.clone();

                            documentIdToCredentialMap.put(currentDocument.Id, currentCredential);
                            documentIdToCredentialFileMap.put (currentDocument.Id, currentCredentialFile);
                            documentIdToAttachmentMap.put (currentDocument.Id, newAttachment);

                            attachmentsToInsert.add(newAttachment);
                            credentialFilesToUpsert.add(currentCredentialFile);
                        }

                        // Set documentAttachment to null to avoid heap size exceptions while working with large files.
                        if (currentAttachment != null) {
                            documentTypeToDocumentMap.get(documentType).documentAttachment = null;
                        }
                    }
                }

                try {
                    upsert credentialsToUpsert;
                } catch (DmlException e) {
                    System.debug('Error creating credential & credential files: ' + e.getMessage());
                    success = false;
                } catch (Exception e) {
                    System.debug('Error creating credential & credential files: ' + e.getMessage());
                    success = false;
                }

                if (success) {
                    if (!documentIdToCredentialFileMap.isEmpty()) {
                        // Update credential ID for credential files
                        for (DocumentWithAttachment currentDocument : documentTypeToDocumentMap.values()) {
                            if (currentDocument != null
                                    && documentIdToCredentialFileMap.containsKey(currentDocument.document.Id)) {
                                // Auto liability is not overridden
                                documentIdToCredentialFileMap.get(currentDocument.document.Id).Credential__c =
                                        documentIdToCredentialMap.get(currentDocument.document.Id).Id;
                            }
                        }

                        try {
                            upsert credentialFilesToUpsert;
                        } catch (DmlException e) {
                            success = false;
                        } catch (Exception e) {
                            success = false;
                        }

                        if (success) {
                            // Update parent ID for new attachments on new credential files
                            for (DocumentWithAttachment currentDocument : documentTypeToDocumentMap.values()) {
                                if (currentDocument != null
                                        && documentIdToCredentialFileMap.containsKey(currentDocument.document.Id)
                                        && documentIdToAttachmentMap.containsKey(currentDocument.document.Id)) {
                                    // Auto liability is not overridden
                                    documentIdToAttachmentMap.get(currentDocument.document.Id).ParentId =
                                            documentIdToCredentialFileMap.get(currentDocument.document.Id).Id;
                                }
                            }

                            try {
                                insert attachmentsToInsert;
                            } catch (DmlException e) {
                                System.debug('Error creating attachments for the given Credential Files: ' + e.getMessage());
                                success = false;
                            } catch (Exception e) {
                                System.debug('Error creating attachments for the given Credential Files: ' + e.getMessage());
                                success = false;
                            }
                        }
                    }
                }

            }
        }

        return success;
    }

    /**
     * Populates the program enrollment field on every application program enrollment
     *
     * @param appProgEnrollmentIdToProgramEnrollmentMap map that relates application program enrollment ids with its
     * corresponding program enrollment
     * @return boolean success if the operation was successful
     */
    public static Boolean setProgramEnrollmentFieldToAppProgramEnrollment(
            Map<Id, Program_Enrollment__c> appProgEnrollmentIdToProgramEnrollmentMap) {

        Boolean success = true;
        List<Application_Program_Enrollment__c> appProgEnrollments = new List<Application_Program_Enrollment__c>();

        for (Id appProgEnrollmentId : appProgEnrollmentIdToProgramEnrollmentMap.keySet()) {
                appProgEnrollments.add(new Application_Program_Enrollment__c(Id = appProgEnrollmentId,
                        Program_Enrollment__c = appProgEnrollmentIdToProgramEnrollmentMap.get(appProgEnrollmentId).Id));
        }

        try {
            update appProgEnrollments;
        } catch (DmlException e) {
            System.debug('### Error while updating application program enrollments: ' + e.getMessage());
            success = false;
        }
        return success;
    }
}