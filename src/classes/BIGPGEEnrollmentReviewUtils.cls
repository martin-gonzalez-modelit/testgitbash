public class BIGPGEEnrollmentReviewUtils {
    // Contact Contractor record type Id
    public static final String CONTACT_CONTRACTOR_RECORDTYPE_ID =
            Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contractor').RecordTypeId;

    // Account Contractor record type Id
    public static final String CONTRACTOR_RECORDTYPE_ID =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Contractor').RecordTypeId;

    // Appication program enrollment review information schema
    public static final  Map<String,Schema.RecordTypeInfo> appPrgReviewSchema =
            Schema.SObjectType.Application_Program_Enrollment_Review__c.getRecordTypeInfosByName();

    // Appication enrollment review information schema
    public static final  Map<String,Schema.RecordTypeInfo> appReviewSchema =
            Schema.SObjectType.Enrollment_Application_Review__c.getRecordTypeInfosByName();

    // ENROLLMENT STATUSES (APP_ENROLLMENT / PROGRAM_ENROLLMENT)
    public static final String STAFF_OWNER_ROLE = 'Owner';
    public static final String STAFF_PRIMARY_ROLE = 'Primary Program Contact';
    public static final String STAFF_BPI_ROLE = 'BPI Certified Professional';
    public static final String STAFF_HVAC_ROLE = 'HVAC Technician';
    public static final String STAFF_HERS_ROLE = 'HERS II';
    public static final String STAFF_REBATE_ADMIN_ROLE = 'Rebate Administrator';
    public static final String STAFF_SALESPERSON_ROLE = 'Salesperson';

    public static final String APP_ENROLLMENT_CHECKED_OUT_STATUS = 'Checked out';
    public static final String APP_ENROLLMENT_CHECKED_IN_STATUS = 'Pending Review';
    public static final String APP_ENROLLMENT_COMPLETED_STATUS = 'Fully Completed';
    public static final String APP_ENROLLMENT_CANCELED_STATUS = 'Canceled';

    public static final String COMPANY_INFO_PENDING_STATUS = 'Pending Review';
    public static final String COMPANY_INFO_APPROVED_STATUS = 'Approved';
    public static final String COMPANY_INFO_REQUEST_INFO_STATUS = 'Requested More Info';
    public static final String COMPANY_INFO_REJECTED_STATUS = 'Rejected';
    public static final String COMPANY_INFO_EXPIRED_STATUS = 'Expired';

    public static final String PROGRAM_PENDING_STATUS = 'Pending Review';
    public static final String PROGRAM_APPROVED_STATUS = 'Approved';
    public static final String PROGRAM_REQUEST_INFO_STATUS = 'Requested More Info';
    public static final String PROGRAM_REJECTED_STATUS = 'Rejected';
    public static final String PROGRAM_ALREADY_ENROLLED_STATUS = 'Already Enrolled';
    public static final String PROGRAM_EXPIRED_STATUS = 'Expired';
    public static final String PROGRAM_FULL_PARTICIPATION_STATUS = 'Full Participation';

    // RT DEFS
    public static final String APP_REVIEW_APPROVAL_RT_NAME = 'Approval';
    public static final String APP_REVIEW_INFORMATION_RT_NAME = 'Information';
    public static final String APP_REVIEW_INSURANCE_RT_NAME = 'Insurance';

    public static final String PRG_REVIEW_AGREEMENTS_RT_NAME = 'Agreements';
    public static final String PRG_REVIEW_APPROVAL_RT_NAME = 'Approval';
    public static final String PRG_REVIEW_CREDENTIALS_RT_NAME = 'Credentials';
    public static final String PRG_REVIEW_RATER_CREDENTIALS_RT_NAME = 'Rater Credentials';
    public static final String PRG_REVIEW_STAFF_RT_NAME = 'Staff';
    public static final String ACCOUNT_CONTRACTOR_RT_NAME = 'Contractor'; 
    public static final String ACCOUNT_RATER_RT_NAME = 'Rater';

    // Review item statuses
    public static final String REVIEW_ITEM_UNREAD_STATUS = 'Unread';
    public static final String REVIEW_ITEM_REJECTED_STATUS = 'Rejected';
    public static final String REVIEW_ITEM_SKIPPED_STATUS = 'Skipped';
    public static final String REVIEW_ITEM_REQUEST_INFO_STATUS = 'Request More Info';
    public static final String REVIEW_ITEM_APPROVED_STATUS = 'Approved';
    public static final String REVIEW_ITEM_ALREADY_ENROLLED_STATUS = 'AlreadyEnrolled';

    // Company information statuses
    public static final String COMPANY_INFO_REVIEW_PENDING_REVIEW_STATUS = 'Pending Review';
    public static final String COMPANY_INFO_REVIEW_APPROVED_STATUS = 'Approved';
    public static final String COMPANY_INFO_REVIEW_REQUEST_INFO_STATUS = 'Request More Info';
    public static final String COMPANY_INFO_REVIEW_REJECTED_STATUS = 'Rejected';
    public static final String COMPANY_INFO_REVIEW_EXPIRED_STATUS = 'Expired';

    // Review Error Messages
    public static final String REVIEW_MESSAGE_ERROR = 'Error while processing review enrollment application';

    // ------- Documents Type -------
    // Application documents type
    public static Set<String> APPLICATION_DOCUMENT_TYPE = new Set<String>{'W-9 Form',
                                                                          'Worker\'s Compensation Insurance',
                                                                          'General Liability Insurance',
                                                                          'Auto Liability Insurance',
                                                                          'Bonding Document'};

    // Program documents type
    public static Set<String> PROGRAM_DOCUMENT_TYPE = new Set<String>{'Contractor Agreement', 'Rater Agreement',
                                                                      'ACQC Agreement', 'Proof Financial Records',
                                                                      'Professional Reference 1',
                                                                      'Professional Reference 2',
                                                                      'Copy of BPI Accreditation',
                                                                      'Copy of HERS II ID Card',
                                                                      'Copy of BPI Card'};

    // ------- Approval field settings ---------
    // Company Information
    public static final String COMPANY_INFO_ACCOUNT_APPROVAL_FIELD = 'Account_Status__c';
    public static final String COMPANY_INFO_CONTACTS_APPROVAL_FIELD = 'Contacts_Status__c';
    public static final String COMPANY_INFO_INSURANCE_APPROVAL_FIELD = 'Insurance_Status__c';
    public static final String COMPANY_INFO_MAIN_APPROVAL_FIELD = 'Approval_Status__c';
    public static final Map<Integer, String> COMPANY_INFO_APPROVAL_FIELDS_MAP
                                                = new Map<Integer, String>{0 => COMPANY_INFO_ACCOUNT_APPROVAL_FIELD,
                                                                           1 => COMPANY_INFO_INSURANCE_APPROVAL_FIELD,
                                                                           2 => COMPANY_INFO_CONTACTS_APPROVAL_FIELD};
    // Program approval fields
    public static final String STAFF_APPROVAL_FIELD = 'Staff_Status__c';
    public static final String CREDENTIALS_APPROVAL_FIELD = 'Credentials_Status__c';
    public static final String AGREEMENTS_APPROVAL_FIELD = 'Agreements_Status__c';
    public static final String PROGRAM_MAIN_APPROVAL_FIELD = 'Approval_Status__c';

    public static final Map<Integer, String> PROGRAM_APPROVAL_FIELD_MAP = new map<Integer, String>{0 => STAFF_APPROVAL_FIELD,
                                                                                                   1 => CREDENTIALS_APPROVAL_FIELD,
                                                                                                   2 => AGREEMENTS_APPROVAL_FIELD};

    // ---- APPROVAL FIELD LISTS -------
    public static Set<String> COMPANY_INFO_INSURANCE_APPROVAL_FIELDS = new Set<String>{'Workers_Compensation__c',
                                                                                       'General_Liability_Insurance__c',
                                                                                       'Auto_Liability__c','Bonding_Document__c'};

    public static Set<String> COMPANY_INFO_RATER_COMPANY_INSURANCE_APPROVAL_FIELDS = new Set<String>{'Workers_Compensation__c',
                                                                                                     'General_Liability_Insurance__c',
                                                                                                     'Auto_Liability__c'};

    public static Set<String> COMPANY_APPROVAL_FIELDS = new Set<String> {'Tax_EIN_or_SSN_matches__c'};

    public static final Map<Integer, Set<String>> COMPANY_INFO_APPROVAL_FIELD_SETS_MAP
                                                = new Map<Integer, Set<String>>{0 => COMPANY_APPROVAL_FIELDS,
                                                                                1 => COMPANY_INFO_INSURANCE_APPROVAL_FIELDS};

    public static final Map<Integer, Set<String>> COMPANY_INFO_RATER_COMPANY_APPROVAL_FIELD_SETS_MAP
                                                = new Map<Integer, Set<String>>{0 => COMPANY_APPROVAL_FIELDS,
                                                                                1 => COMPANY_INFO_RATER_COMPANY_INSURANCE_APPROVAL_FIELDS};

    // --- PROGRAMS ------

    // ACQC
    public static Set<String> ACQC_CREDENTIALS_APPROVAL_FIELDS = new Set<String>{'Company_Operation_Proof__c','C20_License_Active__c'};

    public static Set<String> ACQC_AGREEMENTS_APPROVAL_FIELDS = new Set<String>{'Dated_pg2__c','Signed_pg2__c',
                                                                     'License_Number_pg2__c',
                                                                     'Contractor_Name_Address_pg1__c'};

    public static Map<Integer, Set<String>> ACQC_APPROVAL_FIELD_SETS_MAP = new Map<Integer, Set<String>>{1 => ACQC_CREDENTIALS_APPROVAL_FIELDS,
                                                                                                            2 => ACQC_AGREEMENTS_APPROVAL_FIELDS};

    // AHU
    public static Set<String> AHU_CREDENTIALS_APPROVAL_FIELDS = new Set<String>{'B_License_Active__c',
                                                                                  'Company_Operation_Proof__c',
                                                                                  'Attended_Participation_Workshop__c',
                                                                                  'BPI_Professional_AHU_Training__c'};

    public static Set<String> AHU_AGREEMENTS_APPROVAL_FIELDS = new Set<String>{'Dated_pg2__c','Signed_pg2__c',
                                                                                 'License_Number_pg2__c',
                                                                                 'Contractor_Name_Address_pg1__c'};

    public static Map<Integer, Set<String>> AHU_APPROVAL_FIELD_SETS_MAP = new Map<Integer, Set<String>>{1 => AHU_CREDENTIALS_APPROVAL_FIELDS,
                                                                                                           2 => AHU_AGREEMENTS_APPROVAL_FIELDS};


    // HU
    public static Set<String> HU_CONTRACTOR_CREDENTIALS_APPROVAL_FIELDS = new Set<String>{'License_Number_Active__c',
                                                                                          'Company_Operation_Proof__c',
                                                                                          'Attended_Participation_Workshop__c',
                                                                                          'Attended_Core_Training__c'};

    public static Set<String> AHU_RATER_CREDENTIALS_APPROVAL_FIELDS = new Set<String>{'BPI_Accreditation_Active__c',
                                                                                      'Attended_Participation_Workshop__c',
                                                                                      'BPI_Professional_AHU_Training__c'};

    public static Set<String> AHU_INDIVIDUAL_CREDENTIALS_APPROVAL_FIELDS = new Set<String>{'Attended_Participation_Workshop__c',
                                                                                           'BPI_Professional_AHU_Training__c'};

    public static Set<String> HU_AGREEMENTS_APPROVAL_FIELDS = new Set<String>{'Dated_pg2__c','Signed_pg2__c',
                                                                                 'License_Number_pg2__c',
                                                                                 'Contractor_Name_Address_pg1__c'};

    public static Map<Integer, Set<String>> HU_CONTRACTOR_APPROVAL_FIELD_SETS_MAP = new Map<Integer, Set<String>>{1 => HU_CONTRACTOR_CREDENTIALS_APPROVAL_FIELDS,
                                                                                                                  2 => HU_AGREEMENTS_APPROVAL_FIELDS};

    public static Map<Integer, Set<String>> AHU_RATER_APPROVAL_FIELD_SETS_MAP = new Map<Integer, Set<String>>{1 => AHU_RATER_CREDENTIALS_APPROVAL_FIELDS,
                                                                                                              2 => AHU_AGREEMENTS_APPROVAL_FIELDS};

    public static Map<Integer, Set<String>> AHU_INDIVIDUAL_APPROVAL_FIELD_SETS_MAP = new Map<Integer, Set<String>>{1 => AHU_INDIVIDUAL_CREDENTIALS_APPROVAL_FIELDS,
                                                                                                                  2 => AHU_AGREEMENTS_APPROVAL_FIELDS};

    // Application Program Enrollment Record Types
    private static final  Map<String,Schema.RecordTypeInfo> appPrgSchema =
                Schema.SObjectType.Application_Program_Enrollment__c.getRecordTypeInfosByName();

    public static final Id APP_PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID = appPrgSchema.get('ACQC').RecordTypeId;
    public static final Id APP_PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID = appPrgSchema.get('AHU').RecordTypeId;
    public static final Id APP_PROGRAM_ENROLLMENT_HU_RECORDTYPE_ID = appPrgSchema.get('HU').RecordTypeId;

    // Program Enrollment Record Types
    private static final Map<String, Schema.RecordTypeInfo> progEnrollmentSchema =
                Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName();

    public static final Id PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID = progEnrollmentSchema.get('ACQC').RecordTypeId;
    public static final Id PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID = progEnrollmentSchema.get('AHU').RecordTypeId;
    public static final Id PROGRAM_ENROLLMENT_HU_RECORDTYPE_ID = progEnrollmentSchema.get('HU').RecordTypeId;

    // Account Record Types
    public static final Map<String, Schema.RecordTypeInfo> accountSchema =
            Schema.SObjectType.Account.getRecordTypeInfosByName();

    public static final Id ACCOUNT_CONTRACTOR_RECORDTYPE_ID = accountSchema.get(ACCOUNT_CONTRACTOR_RT_NAME).RecordTypeId;
    public static final Id ACCOUNT_RATER_RECORDTYPE_ID = accountSchema.get(ACCOUNT_RATER_RT_NAME).RecordTypeId;

    // Application Program Enrollment to Program Enrollment RecordType mapping
    public static final map<Id, Id> APP_PROG_ENROLLMENT_TO_PROG_ENROLLMENT_RTYPE_MAP
                                                = new Map<Id, Id> {APP_PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID => PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID,
                                                                   APP_PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID => PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID,
                                                                   APP_PROGRAM_ENROLLMENT_HU_RECORDTYPE_ID => PROGRAM_ENROLLMENT_HU_RECORDTYPE_ID};

    /**
    * Get all documents type from a Program (PROGRAM_DOCUMENT_TYPE) or Application (APPLICATION_DOCUMENT_TYPE)
    * and save them on a Map as keys to a new Attachment
    * @param applicationFieldsType a list of document type that it could be
    *          from a program documents or application documents
    * @return The map with the document type from a Program or an Application
    */
    public static Map<String, Attachment> initializeMapDocumentType(Set<String> documentsType){
        Map<String, Attachment> doctypeAttachment = new Map<String, Attachment>();

        for (String documentType : documentsType) {
            doctypeAttachment.put(String.escapeSingleQuotes(documentType), new Attachment());
        }

        return doctypeAttachment;
    } 

    public static Map<Integer, Set<String>> getProgramApprovalFields (Id recordTypeId, String companyType) {
        Map<Integer, Set<String>> programApprovalFieldMap = null;

        if (String.isNotEmpty(recordTypeId) && String.isNotEmpty(companyType)) {
            if (recordTypeId == APP_PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID) {
                programApprovalFieldMap = ACQC_APPROVAL_FIELD_SETS_MAP;
            } else if (recordTypeId == APP_PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID) {
                if (companyType == 'Contractor') {
                    programApprovalFieldMap = AHU_APPROVAL_FIELD_SETS_MAP;
                } else if (companyType == 'Individual Rater') {
                    programApprovalFieldMap = AHU_INDIVIDUAL_APPROVAL_FIELD_SETS_MAP;
                } else {
                    programApprovalFieldMap = AHU_RATER_APPROVAL_FIELD_SETS_MAP;
                }
            } else if (recordTypeId == APP_PROGRAM_ENROLLMENT_HU_RECORDTYPE_ID) {
                if (companyType == 'Contractor') {
                    programApprovalFieldMap = HU_CONTRACTOR_APPROVAL_FIELD_SETS_MAP;
                }
            }
        }

        return programApprovalFieldMap;
    }

    public static final string ACCOUNT_INFO_NEW_RECORD_LABEL = 'Not already in Salesforce. Create a new record.';

    // Wrapper for account matching
    public class AccountMatchingWrapper {
        public Enrollment_Application_Review__c reviewObject {get; set;}
        public List<Account> matchingAccounts;

        public accountMatchingWrapper (Enrollment_Application_Review__c reviewObject, List<Account> matchingAccounts) {
            this.reviewObject = reviewObject;

            if (this.reviewObject.Status__c == null) {
                reviewObject.Status__c = REVIEW_ITEM_UNREAD_STATUS;
            }

            this.matchingAccounts = matchingAccounts;
        }
    }

    // Wrapper for staff matching
    public class staffWithMatches {
        public Application_Program_Enrollment_Staff__c staff {get; set;}
        public Program_Enrollment_Staff_Review__c staffReview {get; set;}
        public List<SelectOption> selectOptions {get; set;}
        public boolean isAppContactReview;

        staffWithMatches (Boolean isAppContactReview, Application_Program_Enrollment_Staff__c staff, List<Contact> matchingStaffs) {
            this.staff = staff;
            this.isAppContactReview = isAppContactReview;

            if (staff.Staff_Reviews__r != null && !staff.Staff_Reviews__r.isEmpty()) {
                this.staffReview = staff.Staff_Reviews__r.get(0);
            }
            else {
                this.staffReview = new Program_Enrollment_Staff_Review__c();
                this.staffReview.Staff__c = staff.Id;
            }

            if (matchingStaffs != null) {
                this.selectOptions = new List<SelectOption>();
                for (Contact matchingStaff : matchingStaffs) {

                    this.selectOptions.add(new SelectOption(matchingStaff.Id,
                                                            matchingStaff.FirstName + ' ' + matchingStaff.LastName));
                }
                this.selectOptions.add(new SelectOption('', ACCOUNT_INFO_NEW_RECORD_LABEL));
            }
        }
    }

    /**
     * Gets a list of application program enrollments for a given enrollment application Id
     *
     * @param appEnrollmentId enrollment application Id
     * @return programEnrollmentList list of application program enrollments
     */
    public static List<Application_Program_Enrollment__c> getProgramEnrollmentsByApplicationEnrollmentId(Id appEnrollmentId) {
        List<Application_Program_Enrollment__c> programEnrollmentList = null;

        if (appEnrollmentId != null) {
            try {
                programEnrollmentList = [
                    SELECT Id, Name, RecordTypeId, RecordType.Name, Application_Enrollment__c, Status__c,
                        Program_Enrollment__c, Application_Enrollment__r.Type__c
                    FROM Application_Program_Enrollment__c
                    WHERE Application_Enrollment__c = :appEnrollmentId
                        AND Status__c != :BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS
                    ];
            } catch (QueryException e) {
                System.debug ('Error retrieving program enrollments: ' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Error retrieving program enrollments: ' + e.getMessage());
            }
        }

        return programEnrollmentList;
    }

    // this method returns a list of related program enrollment by application enrollment id
    public static Application_Program_Enrollment__c getProgramEnrollmentByApplicationEnrollmentIdAndRtName(Id appEnrollmentId, String appProgRtName) {
        Application_Program_Enrollment__c programEnrollment;

        if (appEnrollmentId != null && appProgRtName != null) {
            try {
                programEnrollment = [SELECT Id, Name, RecordTypeId, Application_Enrollment__c, Status__c,
                                         Program_Enrollment__c, Application_Enrollment__r.Type__c
                                         FROM Application_Program_Enrollment__c
                                         WHERE Application_Enrollment__c = : appEnrollmentId
                                         AND RecordType.Name = : appProgRtName
                                         AND Status__c != 'Unused'];
            }
            catch (QueryException e) {
                System.debug ('Error retrieving program enrollments: ' + e.getMessage());
            }
            catch (Exception e) {
                System.debug ('Error retrieving program enrollments: ' + e.getMessage());
            }
        }

        return programEnrollment;
    }

    public static List<Account> getSimilarAccounts (Application_Enrollment__c appEnrollment, String taxID) {
        List<Account> similarAccounts = null;

        if (appEnrollment != null) {
            try {

                String companySearch = '%'+appEnrollment.Company_Name__c+'%';
                String addressSearch = '%'+appEnrollment.Address__c+'%';

                List<Account> similarAccountsTmp = [SELECT Id, RecordTypeId, License_Number__c,
                                                        Name, BillingStreet, Tax_ID_Number__c
                                                    FROM Account
                                                    WHERE (Tax_ID_Number__c != null AND Tax_ID_Number__c = : taxID) 
                                                    OR (Name LIKE :companySearch AND BillingStreet LIKE : addressSearch)]; 

                if (!similaraccountsTmp.isEmpty()) {

                    similarAccounts = new List<Account>();

                    Account sameTaxId = null;
                    Integer c = 0;                  
                    // Search for an account matching the Tax ID (We should return only that record if there's a match
                    while (c < similarAccountsTmp.size() && sameTaxId == null) {
                        if (similarAccountsTmp.get(c).Tax_ID_Number__c == taxID) {
                            sameTaxId = similarAccountsTmp.get(c);
                        }
                        c++;
                    }

                    if (sameTaxId != null) {
                        similarAccounts.add(sameTaxId);
                    } else {
                        similarAccounts.addAll(similarAccountsTmp);
                    }
                } else {
                    // If there's no match, perform a less strict search for company name and billing address
                    similarAccounts = [SELECT Id, RecordTypeId, License_Number__c, Name, BillingStreet
                                        FROM Account
                                        WHERE Name LIKE :companySearch 
                                        OR BillingStreet LIKE : addressSearch LIMIT 3];
                }
            } catch (QueryException e) {
                System.debug ('Error getting accounts: ' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Error getting accounts: ' + e.getMessage());
            }
        }

        return similarAccounts;
    }

    public static Account getAccountByTaxID (String taxID) {
        Account matchingAccount = null;

        if (taxID != null) {
            try {
                matchingAccount = [SELECT Id, RecordTypeId, License_Number__c, 
                                    Name, BillingStreet, Tax_ID_Number__c
                                    FROM Account
                                    WHERE Tax_ID_Number__c != null 
                                    AND Tax_ID_Number__c = : taxID LIMIT 1];
            } catch (DmlException e) {
                System.debug ('Error getting Account by tax ID' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Error getting Account by tax ID' + e.getMessage());
            }
        }

        return matchingAccount;
    }

    public static Set<Id> getPreviousProgramApplicationIds (Id accountId, Id currentApplicationId, Id currentProgramId) {
        Set<Id> previousProgramApplicationIds = null;

        if (currentApplicationId != null) {
            try {
                if (accountId != null) {

                    Set<Id> relatedAccountAppEnrollments =
                                new map<Id, Application_Enrollment__c>([SELECT Id FROM Application_Enrollment__c
                                                                        WHERE Account__c = : accountId]).keySet();

                    previousProgramApplicationIds =
                                new map<Id, Application_Program_Enrollment__c>([SELECT Id, Name, Application_Enrollment__c 
                                                                                FROM Application_Program_Enrollment__c 
                                                                                WHERE Application_Enrollment__c IN :relatedAccountAppEnrollments
                                                                                    OR (Application_Enrollment__c = : currentApplicationId
                                                                                    AND Id != :currentProgramId)]).keySet();
                }
                else {
                    previousProgramApplicationIds =
                        new map<Id, Application_Program_Enrollment__c>([SELECT Id, Name, Application_Enrollment__c 
                                                                        FROM Application_Program_Enrollment__c 
                                                                        WHERE Application_Enrollment__c = : currentApplicationId
                                                                        AND Id != : currentProgramId]).keySet();
                }
            }
            catch (DmlException e) {
                System.debug ('Error retrieving previous program applications: ' + e.getMessage());
            }
            catch (Exception e) {
                System.debug ('Error retrieving previous program applications: ' + e.getMessage());
            }
        }

        return previousProgramApplicationIds;
   } 

    public static AccountMatchingWrapper createAccountMatchingStep (Application_Enrollment__c enrollmentApplication) {
        AccountMatchingWrapper accountMatchingStep = null;

        if (enrollmentApplication != null) {
            List<Account> similarAccounts = getSimilarAccounts (enrollmentApplication, enrollmentApplication.EIN_or_SSN__c);

            Enrollment_Application_Review__c accountMatchingReview = new Enrollment_Application_Review__c ();
            accountMatchingReview.RecordTypeId = appReviewSchema.get(APP_REVIEW_INFORMATION_RT_NAME).getRecordTypeId();
            accountMatchingReview.Enrollment_Application__c = enrollmentApplication.Id;

            if (similarAccounts == null || similarAccounts.isEmpty()) {
                // Set the status for this review to approved since there's nothing to match to
                accountMatchingReview.Status__c = REVIEW_ITEM_APPROVED_STATUS;
            }

            accountMatchingStep = new AccountMatchingWrapper (accountMatchingReview, similarAccounts);
        }

        return accountMatchingStep;
    }

    public static List<StaffWithMatches> getStaffWithMatchesListByProgramId (Application_Program_Enrollment__c programEnrollment, Id accountId, Set<Id> alreadyMatchedStaff) {
        List<StaffWithMatches> staffsWithMatches = null;

        if (programEnrollment != null) {
            List<Application_Program_Enrollment_Staff__c> staffAppProgEnrollments = null;

            try {
                // Get all the staffs related to the retrieved program
                staffAppProgEnrollments = [SELECT Id, Name, Role__c, Application_Program_Enrollment__c, Staff__c,
                                                  Staff__r.First_Name__c, Staff__r.Last_Name__c, Staff__r.Application_Enrollment__r.Type__c,
                                                  (SELECT Program_Enrollment__c,
                                                        BPI_Certification_Active__c, BPI_Certification_Active_Override__c,
                                                        BPI_Certification_Exp_Date__c, BPI_Certification_Number__c,
                                                        HERS_II_Certification_Active__c, HERS_II_Certification_Active_Override__c,
                                                        HERS_II_Certification_Exp_Date__c, HERS_II_Certification_Number__c,
                                                        HVAC_EPA_License__c, HVAC_EPA_License_Override__c, HVAC_Experience__c,
                                                        HVAC_Experience_Override__c, HVAC_School_or_Training__c, HVAC_School_or_Training_Override__c,
                                                        Matching_Staff__c, Staff__c, Enrollment_Application_Review__c
                                                   FROM Staff_Reviews__r ORDER BY LastModifiedDate LIMIT 1)
                                                   FROM Application_Program_Enrollment_Staff__c
                                                   WHERE Application_Program_Enrollment__c = : programEnrollment.Id
                                                   AND Application_Program_Enrollment__r.Status__c != 'Unused'
                                                   AND (Role__c includes (:STAFF_BPI_ROLE,:STAFF_REBATE_ADMIN_ROLE,
                                                                         :STAFF_HVAC_ROLE, :STAFF_HERS_ROLE, 
                                                                         :STAFF_SALESPERSON_ROLE)
                                           OR (Role__c includes (:STAFF_OWNER_ROLE) 
                                               AND Staff__r.Application_Enrollment__r.Type__c = : 'Individual Rater'))];

            }
            catch (DmlException e) {
                System.debug ('Error retrieving staff application program enrollments: ' + e.getMessage());
            }
            catch (Exception e) {
                System.debug ('Error retrieving staff application program enrollments: ' + e.getMessage());
            }

            if (staffAppProgEnrollments != null && !staffAppProgEnrollments.isEmpty()) {
                staffsWithMatches = new List<StaffWithMatches>();

                for (Application_Program_Enrollment_Staff__c staffApp: staffAppProgEnrollments) {

                    List<Contact> matchingStaffs = null;

                    // Only add staff matching options if the staff item hasn't been reviewed yet or not matched yet.
                    if (accountId != null &&  (alreadyMatchedStaff == null  || !alreadyMatchedStaff.contains(staffApp.Staff__c)) && (staffApp.Staff_Reviews__r.isEmpty()
                        || staffApp.Staff_Reviews__r.get(0).Matching_Staff__c == null)) {

                        try {
                            String firstNameMatchingString = '%' + staffApp.Staff__r.First_Name__c + '%';
                            String lastNameMatchingString  = '%' + staffApp.Staff__r.Last_Name__c  + '%';
                            
                            matchingStaffs = [SELECT Id, FirstName, LastName
                                              FROM Contact
                                              WHERE AccountId = : accountId
                                              AND FirstName LIKE : firstNameMatchingString
                                              AND LastName LIKE : lastNameMatchingString LIMIT 3];
                        }
                        catch (DmlException e) {
                            System.debug ('Error retrieving matching staff for current staff item: ' + e.getMessage());
                        }
                        catch (Exception e) {
                            System.debug ('Error retrieving matching staff for current staff item: ' + e.getMessage());
                        }
                    }   

                    staffsWithMatches.add (new StaffWithMatches(false, staffApp, matchingStaffs));
                }
            }
            
        }

        return staffsWithMatches;
    }

    public static List<StaffWithMatches> getStaffWithMatchesListByEnrollmentApp (Id appId, Id accountId, Set<Id> alreadyMatchedStaff) {
        List<StaffWithMatches> staffsWithMatches = null;

        if (appId != null) {
            List<Application_Program_Enrollment_Staff__c> staffAppProgEnrollments = null;

            try {
                staffAppProgEnrollments = new List<Application_Program_Enrollment_Staff__c>();

                // Get all the staffs related to the application
                List<Application_Program_Enrollment_Staff__c> tmpStaffAppProgEnrollments = 
                                                [SELECT Id, Name, Role__c, Application_Program_Enrollment__c, Staff__c,
                                                                                            Staff__r.First_Name__c, Staff__r.Last_Name__c,
                                                                                            (SELECT Program_Enrollment__c,
                                                                                                    Matching_Staff__c, Staff__c,
                                                                                                    BPI_Certification_Active__c, HERS_II_Certification_Active__c,
                                                                                                    HVAC_EPA_License__c, HVAC_Experience__c,
                                                                                                    HVAC_School_or_Training__c, Enrollment_Application_Review__c
                                                                                                    FROM Staff_Reviews__r
                                                                                                    ORDER BY LastModifiedDate LIMIT 1)
                                                                                              FROM Application_Program_Enrollment_Staff__c
                                                                                              WHERE Application_Program_Enrollment__r.Application_Enrollment__c = : appId
                                                                                              AND Application_Program_Enrollment__r.Status__c != 'Unused'
                                                                                              AND Role__c includes (:STAFF_OWNER_ROLE, :STAFF_PRIMARY_ROLE)];

                // Add only one record per role
                Application_Program_Enrollment_Staff__c primary = null;
                Application_Program_Enrollment_Staff__c owner = null;
                Integer cont = 0;

                while (cont < tmpStaffAppProgEnrollments.size() && (primary == null || owner == null)) {
                    if (tmpStaffAppProgEnrollments.get(cont).Role__c.contains(STAFF_PRIMARY_ROLE)) {
                        primary = tmpStaffAppProgEnrollments.get(cont);
                    } else if (tmpStaffAppProgEnrollments.get(cont).Role__c.contains(STAFF_OWNER_ROLE)) {
                        owner = tmpStaffAppProgEnrollments.get(cont);
                    }
                    cont++;
                }

                // If there's a primary contact add that as default. If there's an owner contact and 
                // it's different than the primary add that as well
                if (primary != null) {
                    staffAppProgEnrollments.add(primary);
                }
                if (owner != null && owner.Staff__c != primary.Staff__c) {
                    staffAppProgEnrollments.add(owner);
                }

            }
            catch (DmlException e) {
                System.debug ('Error retrieving staff application program enrollments: ' + e.getMessage());
            }
            catch (Exception e) {
                System.debug ('Error retrieving staff application program enrollments: ' + e.getMessage());
            }

            if (staffAppProgEnrollments != null && !staffAppProgEnrollments.isEmpty()) {
                staffsWithMatches = new List<StaffWithMatches>();

                for (Application_Program_Enrollment_Staff__c staffApp: staffAppProgEnrollments) {

                    List<Contact> matchingStaffs = null;

                    // Only add staff matching options if the staff item hasn't been reviewed yet or not matched yet.
                    if (accountId != null && (alreadyMatchedStaff == null  || !alreadyMatchedStaff.contains(staffApp.Staff__c)) && (staffApp.Staff_Reviews__r.isEmpty()
                        || staffApp.Staff_Reviews__r.get(0).Matching_Staff__c == null)) {

                        try {
                            String firstNameMatchingString = '%' + staffApp.Staff__r.First_Name__c + '%';
                            String lastNameMatchingString  = '%' + staffApp.Staff__r.Last_Name__c  + '%';

                            matchingStaffs = [SELECT Id, FirstName, LastName
                                              FROM Contact
                                              WHERE AccountId = : accountId
                                              AND FirstName LIKE : firstNameMatchingString
                                              AND LastName LIKE : lastNameMatchingString LIMIT 3];
                        }
                        catch (DmlException e) {
                            System.debug ('Error retrieving matching staff for current staff item: ' + e.getMessage());
                        }
                        catch (Exception e) {
                            System.debug ('Error retrieving matching staff for current staff item: ' + e.getMessage());
                        }
                    }   

                    staffsWithMatches.add (new StaffWithMatches(true, staffApp, matchingStaffs));
                }
            }
            
        }

        return staffsWithMatches;
    }

    // This method returns an existing company information review if exist or a new one if doesn't
    public static BIGPGEEnrollmentReviewItem getCompanyInformationReview(Application_Enrollment__c appEnrollment, 
                                                                                        Boolean skipAccountMatching) {
        BIGPGEEnrollmentReviewItem companyInformationReview = null;

        if (appEnrollment.Id != null) {
            Map<String, Attachment> doctypeAttachment = initializeMapDocumentType(APPLICATION_DOCUMENT_TYPE);
            List<Document__c> insuranceDocuments = new List<Document__c>();
            Enrollment_Application_Review__c applicationReview = null;

            try {
                applicationReview = [SELECT Id, Account_External_Message__c, Account_Internal_Message__c,
                                            Account_Status__c, Approval_External_Message__c,
                                            Approval_Internal_Message__c, Approval_Status__c, Auto_Liability__c,
                                            Auto_Liability_Expiration_Date__c, Auto_Liability_Override__c,
                                            Auto_Liability_Policy_Number__c, Bonding_Document__c,
                                            Bonding_Document_Override__c, Bonding_Document_Policy_Number__c,
                                            Bonding_Number_Expiration_Date__c, Company_Type__c,
                                            Contacts_External_Message__c, Contacts_Internal_Message__c,
                                            Contacts_Status__c, Contractor_name_matches__c,
                                            Contractor_Name_Matches_Override__c, Enrollment_Application__c,
                                            General_Liability_Insurance__c, General_Liability_Insurance_Override__c,
                                            General_Liability_Policy_Number__c, General_Liability_Expiration_Date__c,
                                            Insurance_External_Message__c, Insurance_Internal_Message__c,
                                            Insurance_Status__c, Match_Account__c, Status__c,
                                            Tax_EIN_or_SSN_matches__c, Tax_Status__c, Workers_Compensation_Type__c,
                                            Tax_EIN_or_SSN_matches_Override__c, Tax_ID_Number__c,
                                            W9_Signed_and_dated__c, W9_Signed_and_dated_Override__c,
                                            Workers_Compensation__c, Workers_Compensation_expiration_Date__c,
                                            Workers_Compensation_Override__c, Workers_Compensation_Policy_Number__c,
                                            Finish_Review_External_Message__c, Finish_Review_Internal_Message__c
                                     FROM Enrollment_Application_Review__c
                                     WHERE Enrollment_Application__c = : appEnrollment.Id LIMIT 1];

            } catch (QueryException e) {
                System.debug ('Couldn\'t retrieve application review for enrollment: ' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Couldn\'t retrieve application review for enrollment: ' + e.getMessage());
            }

            // Get all documents (Insurance section) from Application Enrollment
            try {
                insuranceDocuments = [SELECT File_Type__c,
                                             (SELECT Id, Name FROM Attachments Order By CreatedDate Desc LIMIT 1)
                                      FROM Document__c
                                      WHERE Application_Enrollment__r.Id = : appEnrollment.Id];

                // Add on map the related attachment
                for (Document__c insuraceDocument : insuranceDocuments) {
                    if (!insuraceDocument.Attachments.isEmpty()) {
                        doctypeAttachment.put(String.escapeSingleQuotes(insuraceDocument.File_Type__c), 
                                              insuraceDocument.Attachments.get(0));
                    }
                }
            } catch (QueryException e) {
                System.debug ('Couldn\'t retrieve documents for enrollment: ' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Couldn\'t retrieve documents for enrollment: ' + e.getMessage());
            }

            companyInformationReview = initializeCompanyInformationStep(appEnrollment,
                                                                        applicationReview, skipAccountMatching,
                                                                        doctypeAttachment);
        }

        return companyInformationReview;
    } 

    // Method for initializing new company information review step
    public static BIGPGEEnrollmentReviewItem initializeCompanyInformationStep(Application_Enrollment__c appEnrollment, 
                                                                    Enrollment_Application_Review__c applicationReview, 
                                                                    Boolean skipAccountMatching, 
                                                                    Map<String, Attachment> doctypeAttachment) {        

        // Create the company information review step if is null
        if (applicationReview == null) {
            applicationReview = new Enrollment_Application_Review__c ();
            applicationReview.Approval_Status__c = REVIEW_ITEM_UNREAD_STATUS;
            applicationReview.Enrollment_Application__c = appEnrollment.Id;

            if (skipAccountMatching) {
                applicationReview.Account_Status__c = REVIEW_ITEM_APPROVED_STATUS;
            }
            else {
                applicationReview.Account_Status__c = REVIEW_ITEM_UNREAD_STATUS;
            }

            applicationReview.Insurance_Status__c = REVIEW_ITEM_UNREAD_STATUS;
            applicationReview.Contacts_Status__c = REVIEW_ITEM_UNREAD_STATUS;
        }

        BIGPGEEnrollmentReviewItem ciReview = null;

        if (appEnrollment.Type__c == 'Rater Company' || appEnrollment.Type__c == 'Individual Rater') {
            ciReview = new BIGPGEEnrollmentReviewItem(applicationReview, appEnrollment,
                                                      COMPANY_INFO_MAIN_APPROVAL_FIELD,
                                                      COMPANY_INFO_APPROVAL_FIELDS_MAP,
                                                      COMPANY_INFO_RATER_COMPANY_APPROVAL_FIELD_SETS_MAP,
                                                      doctypeAttachment);
        }
        else {
            ciReview = new BIGPGEEnrollmentReviewItem(applicationReview, appEnrollment,
                                                      COMPANY_INFO_MAIN_APPROVAL_FIELD,
                                                      COMPANY_INFO_APPROVAL_FIELDS_MAP,
                                                      COMPANY_INFO_APPROVAL_FIELD_SETS_MAP,
                                                      doctypeAttachment);
        }

        return ciReview;
    } 

    public static BIGPGEEnrollmentReviewItem  getProgramReview(Application_Program_Enrollment__c programEnrollment) {
        BIGPGEEnrollmentReviewItem programBIGPGEEnrollmentReviewItem = null;

        if (programEnrollment.Id != null) {
            Map<String, Attachment> doctypeAttachment = initializeMapDocumentType(PROGRAM_DOCUMENT_TYPE);
            Application_Program_Enrollment_Review__c programReview = null;
            Set<String> licenseDocumentIds = new Set<String>();

            try {
                programReview = [
                    SELECT Agreements_External_Message__c, Agreements_Internal_Message__c, Agreements_Status__c,
                        Program_Enrollment__c, Approval_External_Message__c, Approval_Internal_Message__c,
                        Approval_Status__c, BPI_Accreditation_Active__c, BPI_Accreditation_Active_Override__c,
                        BPI_Accreditation_Exp_Date__c, BPI_Accreditation_Number__c, C20_License_Active__c,
                        C20_License_Active_Override__c, B_License_Number__c, B_License_Exp_Date__c, B_License_Active__c,
                        B_License_Active_Override__c, License_Number__c, License_Exp_Date__c, License_Number_Active__c,
                        License_Override__c, Attended_Core_Training_Override__c, Attended_Core_Training__c,
                        Attended_Participation_Workshop__c, Attended_Participation_Workshop_Override__c,
                        BPI_Professional_AHU_Training__c, BPI_Professional_AHU_Training_Override__c,
                        Contractor_Name_Address_pg1__c, Contractor_Name_Address_pg1_Override__c,
                        Credentials_External_Message__c, Credentials_Internal_Message__c, Credentials_Status__c,
                        CSLB_License_Active__c, CSLB_license_Override__c, Dated_pg2__c, Company_Operation_Proof__c,
                        Company_Operation_Proof_Override__c, C20_License_Number__c, C20_Expiration_Date__c,
                        Dated_pg2_Override__c, License_Number_pg2__c, License_Number_pg2_Override__c,
                        Name_Address_pg1__c, Signed_pg2__c, Signed_pg2_Override__c, Staff_External_Message__c,
                        Staff_Internal_Message__c, Staff_Status__c, Status__c
                    FROM Application_Program_Enrollment_Review__c
                    WHERE Program_Enrollment__c = :programEnrollment.Id
                    ];
            } catch (QueryException e) {
                System.debug('Error retrieving existing program review: ' + e.getMessage());
            } catch (Exception e) {
                System.debug('Error retrieving existing program review: ' + e.getMessage());
            }

            // Get all documents from Agreements section
            try {
                List<Document__c> agreementDocuments = [
                    SELECT File_Type__c,
                        (SELECT Id, Name
                         FROM Attachments
                         Order By CreatedDate Desc LIMIT 1)
                    FROM Document__c
                    WHERE Agreement__c IN 
                        (SELECT Agreement__c
                         FROM Application_Program_Enrollment_Agreement__c
                         WHERE Application_Program_Enrollment__r.Id = :programEnrollment.Id)
                    ];

                for (Document__c agreementDocument : agreementDocuments) {
                    if (!agreementDocument.Attachments.isEmpty()) {
                        doctypeAttachment.put(agreementDocument.File_Type__c, agreementDocument.Attachments.get(0));
                    }
                }
            } catch (QueryException e) {
                System.debug ('Error retrieving existing program review: ' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Error retrieving existing program review: ' + e.getMessage());
            }

            // Get all the documents from Credentials section for Contractor or Rater Company only
            try {
                if (programEnrollment.Application_Enrollment__r.Type__c == 'Rater Company' || 
                                                programEnrollment.Application_Enrollment__r.Type__c == 'Contractor') {

                    List<License_Document__c> licenseDocuments = [
                        SELECT Document__r.File_Type__c
                        FROM License_Document__c
                        WHERE License__c IN 
                            (SELECT License__c
                             FROM Application_Program_Enrollment_License__c
                             WHERE Application_Program_Enrollment__r.Id = :programEnrollment.Id)
                        ];

                    for (License_Document__c licenseDocument : licenseDocuments) {
                        licenseDocumentIds.add(licenseDocument.Document__r.Id);
                    }

                    List<Document__c> documents = [
                        SELECT File_Type__c,
                            (SELECT Id, Name
                             FROM Attachments
                             Order By CreatedDate Desc LIMIT 1)
                        FROM Document__c
                        WHERE Document__c.Id IN :licenseDocumentIds
                        ];

                    for (Document__c document : documents) {
                        if (!document.Attachments.isEmpty()) {
                            doctypeAttachment.put(document.File_Type__c, document.Attachments.get(0));
                        }
                    }
                }
            } catch (QueryException e) {
                System.debug ('Error retrieving existing program review: ' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Error retrieving existing program review: ' + e.getMessage());
            }

            // Get all documents (Credentials section) as Individual Rater from Program Enrollment App Staff (Owner)
            try {
                if (programEnrollment.Application_Enrollment__r.Type__c == 'Individual Rater') {
                    List<Document__c> licenseDocumentsIndividualRater = [
                        SELECT File_Type__c, File_Name__c,
                            (SELECT Id, Name
                             FROM Attachments
                             Order By CreatedDate Desc LIMIT 1)
                        FROM Document__c
                        WHERE Staff__r.Application_Enrollment__r.Id = :programEnrollment.Application_Enrollment__r.Id
                        ];

                    for (Document__c document : licenseDocumentsIndividualRater) {
                        if (!document.Attachments.isEmpty()) {
                            doctypeAttachment.put(document.File_Type__c, document.Attachments.get(0));
                        }
                    }
                }
            } catch (QueryException e) {
                System.debug ('Error retrieving existing program review: ' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Error retrieving existing program review: ' + e.getMessage());
            }
            programBIGPGEEnrollmentReviewItem = initializeProgramReview(programEnrollment, programReview, doctypeAttachment);
        }
        return programBIGPGEEnrollmentReviewItem;
    }

    // method for initializing Program review step
    public static BIGPGEEnrollmentReviewItem initializeProgramReview (Application_Program_Enrollment__c programEnrollment,
                                                                Application_Program_Enrollment_Review__c programReview,
                                                                Map<String, Attachment> doctypeAttachment) {

        if (programReview == null) {
            programReview = new Application_Program_Enrollment_Review__c();
            programReview.Program_Enrollment__c = programEnrollment.Id;
            programReview.Approval_Status__c = REVIEW_ITEM_UNREAD_STATUS;
            programReview.Staff_Status__c = REVIEW_ITEM_UNREAD_STATUS;
            programReview.Credentials_Status__c = REVIEW_ITEM_UNREAD_STATUS;
            programReview.Agreements_Status__c  = REVIEW_ITEM_UNREAD_STATUS;
        }
        
        return new BIGPGEEnrollmentReviewItem(programReview, programEnrollment,
                                              PROGRAM_MAIN_APPROVAL_FIELD, PROGRAM_APPROVAL_FIELD_MAP,
                                              getProgramApprovalFields (programEnrollment.RecordTypeId,
                                              programEnrollment.Application_Enrollment__r.Type__c), doctypeAttachment);
    } 

    public static Boolean setEnrollmentApplicationStatus(Application_Enrollment__c appEnrollment, 
                                                         String appEnrollmentStatus) {
        Boolean success = true;

        appEnrollment.Enrollment_Status__c = appEnrollmentStatus;

        try {
            update appEnrollment;
        }
        catch (DmlException e) {
            System.debug ('Error updating app enrollment status: ' + e.getMessage());
            success = false;
        }
        catch (Exception e) {
            System.debug ('Error updating app enrollment status: ' + e.getMessage());
            success = false;
        }

        return success;
    }

    public class MyException extends Exception{}

    public static Boolean updateProgramEnrollmentsOnAccountMatching (Id accountId, List<BIGPGEEnrollmentReviewItem> reviewItems) {
        Boolean success = true; 

        if (accountId != null && reviewItems != null) {
            List<Program_Enrollment__c> existingEnrollments = null;

            try {
                existingEnrollments = [SELECT Id, Name, Account__c, Program_Type__c, Enrollment_Status__c, RecordTypeId
                                       FROM Program_Enrollment__c
                                       WHERE Account__c = : accountId
                                       AND Enrollment_Status__c = : 'Approved'];
            }
            catch (QueryException e) {
                System.debug ('Error retrieving program enrollments for the given Accoutn: ' + e.getMessage());
                success = false;
            }
            catch (Exception e) {
                System.debug ('Error retrieving program enrollments for the given Accoutn: ' + e.getMessage());
                success = false;
            }

            if (existingEnrollments != null) {

                Map<String, BIGPGEEnrollmentReviewItem> programTypeToProgramReviewItem = new Map<String, BIGPGEEnrollmentReviewItem>();

                for (BIGPGEEnrollmentReviewItem reviewItem : reviewItems) {
                    if (reviewItem != null && BIGPGEEnrollmentReviewDataMappingUtils.APP_PROG_ENROLLMENT_RTYPE_ID_TO_PROG_ENROLLMENT_TYPE_MAP
                                                                                        .containsKey(reviewItem.appProgramEnrollment.RecordTypeId)) {

                        programTypeToProgramReviewItem.put (BIGPGEEnrollmentReviewDataMappingUtils.APP_PROG_ENROLLMENT_RTYPE_ID_TO_PROG_ENROLLMENT_TYPE_MAP.get(reviewItem.appProgramEnrollment.RecordTypeId),
                                                            reviewItem);
                    }
                }

                if (!programTypeToProgramReviewItem.isEmpty()) { 

                    List<Application_Program_Enrollment__c> appProgEnrollmentsToUpdate = new List<Application_Program_Enrollment__c>();
                    List<Application_Program_Enrollment_Review__c> appProgEnrollmentReviewsToUpdate = new List<Application_Program_Enrollment_Review__c>();

                    // Update the review items based on the retrieved program applications
                    for (Program_Enrollment__c existingEnrollment : existingEnrollments) {
                        if (programTypeToProgramReviewItem.containsKey(existingEnrollment.RecordTypeId)) {

                            BIGPGEEnrollmentReviewItem reviewItem = programTypeToProgramReviewItem.get(existingEnrollment.RecordTypeId);

                            reviewItem.appProgramEnrollment.Status__c = 'Already Enrolled';
                            reviewItem.programReview.Approval_Status__c = 'AlreadyEnrolled';

                            reviewItem.rejectAllSteps();

                            appProgEnrollmentReviewsToUpdate.add (reviewItem.programReview);
                            appProgEnrollmentsToUpdate.add (reviewItem.appProgramEnrollment);
                        }
                    }

                    // Update the records
                    try {
                        update appProgEnrollmentReviewsToUpdate;
                        update appProgEnrollmentsToUpdate;
                    }
                    catch (DmlException e) {
                        System.debug ('Error updating review item information: ' + e.getMessage());
                        success = false;
                    }
                    catch (Exception e) {
                        System.debug ('Error updating review item information: ' + e.getMessage());
                        success = false;
                    }

                }

            }
        }

        return success;
    }

    public static Map<Id, Id> getAlreadyMatchedStaff(List<BIGPGEEnrollmentReviewItem> targetReviews) {
        Map<Id, Id> alreadyMatchedStaffIds = new Map<Id, Id>();

        if (targetReviews != null) {
            Set<Id> programEnrollmentIds = new Set<Id>();

            for (BIGPGEEnrollmentReviewItem targetReview: targetReviews) {
                if (targetReview != null && targetReview.appProgramEnrollment != null) {
                    programEnrollmentIds.add (targetReview.appProgramEnrollment.Id);
                }
            }

            if (!programEnrollmentIds.isEmpty()) {
                List<Program_Enrollment_Staff_Review__c> tmpStaffReviews = null;

                try {
                    tmpStaffReviews =  [SELECT Id, Name, Program_Enrollment__c, Staff__c, Staff__r.Staff__c,
                                                Matching_Staff__c
                                        FROM Program_Enrollment_Staff_Review__c
                                        WHERE Staff__r.Application_Program_Enrollment__c IN : programEnrollmentIds
                                        AND Matching_Staff__c != null];
                }
                catch (QueryException e) {
                    System.debug ('Error retrieving staff Ids: ' + e.getMessage());
                }
                catch (Exception e) {
                    System.debug ('Error retrieving staff Ids: ' + e.getMessage());
                }

                if (tmpStaffReviews != null && !tmpStaffReviews.isEmpty()) {
                    for (Program_Enrollment_Staff_Review__c sr : tmpStaffReviews) {
                        alreadyMatchedStaffIds.put(sr.Staff__r.Staff__c, sr.Matching_Staff__c);
                    }
                }
            }
        }

        return alreadyMatchedStaffIds;
    }

    public static void updateMatchingStaff (Map<Id, Id> staffIdToMatchingContact) {
        if (staffIdToMatchingContact != null && !staffIdToMatchingContact.isEmpty()) {

            List<Program_Enrollment_Staff_Review__c> staffReviewsToUpdate = null;

            try {
                staffReviewsToUpdate = [SELECT Id, Name, Staff__c, Staff__r.Staff__c, Matching_Staff__c
                                        FROM Program_Enrollment_Staff_Review__c
                                        WHERE Staff__r.Staff__c IN : staffIdtoMatchingContact.keySet()];

            }
            catch (QueryException e) {
                System.debug ('Error retrieving review items for given staff: ' + e.getMessage());
            }
            catch (Exception e) {
                System.debug ('Error retrieving review items for given staff: ' + e.getMessage());
            }

            if (staffReviewsToUpdate != null && !staffReviewsToupdate.isEmpty()) {
                for (Program_Enrollment_Staff_Review__c staffReview : staffReviewsToUpdate) {
                    staffReview.Matching_Staff__c = staffIdToMatchingContact.get(staffReview.Staff__r.Staff__c);
                }
            }

            try {
                update staffReviewsToUpdate;
            }
            catch (DmlException e) {
                System.debug ('Error updating staff reviews: ' + e.getMessage());
            }
            catch (Exception e) {
                System.debug ('Error updating staff reviews: ' + e.getMessage());
            }
        }
    }

}