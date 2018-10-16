/**
 * This class it's an utility of the PG&E Application Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
public with sharing class BIGPGEEnrollmentReviewResultUtility {

    private static final Set<String> COMPANY_INFO_EXTERNAL_MESSAGE_FIELDS = new Set<String> {'Account_External_Message__c', 'Contacts_External_Message__c', 'Insurance_External_Message__c', 'Approval_External_Message__c'};
    private static final  Set<String> COMPANY_INFO_INTERNAL_MESSAGE_FIELDS = new Set<String> {'Account_Internal_Message__c', 'Contacts_Internal_Message__c', 'Insurance_Internal_Message__c', 'Approval_Internal_Message__c'};
    private static final Set<String> PROGRAM_EXTERNAL_MESSAGE_FIELDS = new Set<String> {'Credentials_External_Message__c', 'Staff_External_Message__c', 'Agreements_External_Message__c', 'Approval_External_Message__c'};
    private static final Set<String> PROGRAM_INTERNAL_MESSAGE_FIELDS = new Set<String> {'Credentials_Internal_Message__c', 'Staff_Internal_Message__c', 'Agreements_Internal_Message__c', 'Approval_Internal_Message__c'};
    public static final String APP_REVIEW_APPROVAL_REQUEST_MORE_INFO_STATUS = 'Request More Info';
    private static PGE_Enrollment_API_To_Display_Map__c setting;
    public static final String PGE_ENROLLMENT_API_SETTING_DATA_SET = 'PGEEnrollmentPortalAPISettings';

    static {
        initCustomSetting();
    }

    public static EnrollmentApplicationReviewWrapper getEnrollmentApplicationReviewInfo(Application_Enrollment__c app) {
        EnrollmentApplicationReviewWrapper appReviewWrapper = null;
        Enrollment_Application_Review__c appReview = null;
        List<String> returnedFields = new List<String>();
        List<String> externalMsg = new List<String>();
        List<String> internalMsg = new List<String>();

        try {
            List<Enrollment_Application_Review__c> appReviews =
                        [SELECT Id, Account_External_Message__c, Account_Internal_Message__c,
                            Account_Status__c, Approval_External_Message__c, Approval_Internal_Message__c,
                            Approval_Status__c, Auto_Liability__c, Auto_Liability_Expiration_Date__c,
                            Auto_Liability_Override__c, Auto_Liability_Policy_Number__c, Bonding_Document__c,
                            Bonding_Document_Override__c, Bonding_Document_Policy_Number__c,
                            Bonding_Number_Expiration_Date__c, Company_Type__c, Contacts_External_Message__c,
                            Contacts_Internal_Message__c, Contacts_Status__c, Contractor_name_matches__c,
                            Contractor_Name_Matches_Override__c, Enrollment_Application__c,
                            General_Liability_Insurance__c, General_Liability_Insurance_Override__c,
                            General_Liability_Policy_Number__c, General_Liability_Expiration_Date__c, 
                            Insurance_External_Message__c, Insurance_Internal_Message__c, Insurance_Status__c,
                            Match_Account__c, Status__c, Tax_EIN_or_SSN_matches__c,
                            Tax_EIN_or_SSN_matches_Override__c, Tax_ID_Number__c, W9_Signed_and_dated__c,
                            W9_Signed_and_dated_Override__c, Workers_Compensation__c,
                            Workers_Compensation_expiration_Date__c, Workers_Compensation_Override__c,
                            Workers_Compensation_Policy_Number__c, Finish_Review_External_Message__c,
                            Finish_Review_Internal_Message__c
                         FROM Enrollment_Application_Review__c
                         WHERE Enrollment_Application__c =: app.Id LIMIT 1];

            if (!appReviews.isEmpty()) {
                appReview = appReviews.get(0);
            }
        } catch (Exception e) {
            System.debug('#### Error: ' + e.getMessage());
            //response.success = false;
            //response.message = e.getMessage();
        }

        if (appReview != null) {
            if (appReview.Approval_Status__c == APP_REVIEW_APPROVAL_REQUEST_MORE_INFO_STATUS) {
                if (app.Type__c != BIGPGEEnrollmentApplicationUtility.APP_TYPE_INDIVIDUAL_RATER) {
                    returnedFields = getReturnedFieldsForCorrection(appReview, BIGPGEEnrollmentReviewUtils.COMPANY_INFO_APPROVAL_FIELD_SETS_MAP);
                } else {
                    returnedFields = getReturnedFieldsForCorrection(appReview, BIGPGEEnrollmentReviewUtils.COMPANY_INFO_RATER_COMPANY_APPROVAL_FIELD_SETS_MAP);
                }
            }

            externalMsg.addAll(getReviewExternalMessages(appReview));
            internalMsg.addAll(getReviewInternalMessages(appReview));
            appReviewWrapper = new EnrollmentApplicationReviewWrapper('Application', appReview.Approval_Status__c, returnedFields, externalMsg, internalMsg);
        }

        return appReviewWrapper;
    }

    public static List<EnrollmentApplicationReviewWrapper> getAllApplicationsProgramEnrollmentReviewInfo(
            Application_Enrollment__c app) {

        Map<String,EnrollmentApplicationReviewWrapper> prgToEnrollmentReview = new Map<String,EnrollmentApplicationReviewWrapper>();
        List<EnrollmentApplicationReviewWrapper> reviews = new List<EnrollmentApplicationReviewWrapper>();
        EnrollmentApplicationReviewWrapper appReviewWrapper;
        List<String> externalMsg = new List<String>();
        List<String> internalMsg = new List<String>();
        List<String> returnedFields = new List<String>();
        String title;

        try {
            List<Application_Program_Enrollment_Review__c> programReviews = [
                SELECT Agreements_External_Message__c, Agreements_Internal_Message__c, Agreements_Status__c,
                    Program_Enrollment__c, Program_Enrollment__r.RecordTypeId, Approval_External_Message__c,
                    Approval_Internal_Message__c, Approval_Status__c, BPI_Accreditation_Active__c,
                    BPI_Accreditation_Active_Override__c, BPI_Accreditation_Exp_Date__c, C20_License_Active__c,
                    C20_License_Active_Override__c,  C20_License_Number__c, C20_Expiration_Date__c, B_License_Active__c,
                    B_License_Active_Override__c, B_License_Number__c, B_License_Exp_Date__c, License_Number_Active__c,
                    Attended_Core_Training__c, Attended_Participation_Workshop__c, Attended_Participation_Workshop_Override__c,
                    BPI_Professional_AHU_Training__c, BPI_Professional_AHU_Training_Override__c, Contractor_Name_Address_pg1__c,
                    Contractor_Name_Address_pg1_Override__c, Credentials_External_Message__c, Credentials_Internal_Message__c,
                    Credentials_Status__c, CSLB_License_Active__c, CSLB_license_Override__c, Dated_pg2__c,
                    Company_Operation_Proof_Override__c , Company_Operation_Proof__c, Dated_pg2_Override__c,
                    License_Number_pg2__c, License_Number_pg2_Override__c, Name_Address_pg1__c, Signed_pg2__c,
                    Signed_pg2_Override__c, Staff_External_Message__c, Staff_Internal_Message__c, Staff_Status__c, Status__c
                FROM Application_Program_Enrollment_Review__c
                WHERE Program_Enrollment__r.Application_Enrollment__c =: app.Id
                AND Approval_Status__c != : BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS
                ];

            for (Application_Program_Enrollment_Review__c programReview : programReviews) {
                returnedFields = getReturnedFieldsForCorrection(programReview,
                        BIGPGEEnrollmentReviewUtils.getProgramApprovalFields(programReview.Program_Enrollment__r.RecordTypeId,
                        app.Type__c));
                externalMsg = getReviewExternalMessages(programReview);
                internalMsg = getReviewInternalMessages(programReview);
                title = BIGPGEEnrollmentAppProgramUtility.appPrgRecordTypeIdToRecordTypeName
                        .get(programReview.Program_Enrollment__r.RecordTypeId);
                appReviewWrapper = new EnrollmentApplicationReviewWrapper(title, programReview.Approval_Status__c,
                        returnedFields, externalMsg, internalMsg);
                reviews.add(appReviewWrapper);
            }
        } catch (Exception e) {
            System.debug('##### Error: ' + e.getMessage());
        }

        return reviews;
    }

    public static List<EnrollmentApplicationReviewWrapper> getAllReviewsForEnrollmentApplication(Application_Enrollment__c app) {
        List<EnrollmentApplicationReviewWrapper> reviews = new List<EnrollmentApplicationReviewWrapper>();

        if (app != null && String.isNotEmpty(app.Id)) {
            reviews.add(BIGPGEEnrollmentReviewResultUtility.getEnrollmentApplicationReviewInfo(app));
            reviews.addAll(BIGPGEEnrollmentReviewResultUtility.getAllApplicationsProgramEnrollmentReviewInfo(app));
        }

        return reviews;
    }

    public static void setEnrollmentApplicationReviewToUnread(Application_Enrollment__c app) {
        // Retrieve the application review only if it has been returned for correction.
        if (app.Company_Info_Status__c == BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_REQUEST_INFO_STATUS) {
            try {
                List<Enrollment_Application_Review__c> appReviews =
                            [SELECT Id, Account_Status__c, Contacts_Status__c, Insurance_Status__c
                             FROM Enrollment_Application_Review__c
                             WHERE Enrollment_Application__c =: app.Id
                             AND Approval_Status__c =: BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REQUEST_INFO_STATUS
                             LIMIT 1];

                if (!appReviews.isEmpty()) {
                    Enrollment_Application_Review__c appReview = appReviews.get(0);
                    appReview.Status__c = BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS;
                    appReview.Approval_Status__c = BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS;

                    for (Integer i = 0; i < BIGPGEEnrollmentReviewUtils.COMPANY_INFO_APPROVAL_FIELDS_MAP.size(); i++) {
                        String approvalField = BIGPGEEnrollmentReviewUtils.COMPANY_INFO_APPROVAL_FIELDS_MAP.get(i);
                        if (appReview.get(approvalField) == BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REJECTED_STATUS) {
                            appReview.put(approvalField, BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS);
                        }
                    }
                    update appReviews;
                }
            } catch (Exception e) {
                System.debug('#### Error: ' + e.getMessage());
            }
        }
    }

    public static void setApplicationsProgramEnrollmentReviewToUnread(Application_Enrollment__c app) {
        try {
            List<Application_Program_Enrollment_Review__c> programReviews =
                            [SELECT Id, Staff_Status__c, Credentials_Status__c, Agreements_Status__c
                             FROM Application_Program_Enrollment_Review__c
                             WHERE Program_Enrollment__r.Application_Enrollment__c =: app.Id
                             AND Approval_Status__c =: BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REQUEST_INFO_STATUS];

            for (Application_Program_Enrollment_Review__c programReview : programReviews) {
                programReview.Status__c = BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS;
                programReview.Approval_Status__c = BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS;

                for (Integer i = 0; i < BIGPGEEnrollmentReviewUtils.PROGRAM_APPROVAL_FIELD_MAP.size(); i++) {
                    String approvalField = BIGPGEEnrollmentReviewUtils.PROGRAM_APPROVAL_FIELD_MAP.get(i);
                    if (programReview.get(approvalField) == BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REJECTED_STATUS) {
                        programReview.put(approvalField, BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS);
                    }
                }
            }

            update programReviews;
        } catch (Exception e) {
            System.debug('##### Error: ' + e.getMessage());
        }
    }

    public static void setAllReviewsToUnread(Application_Enrollment__c app) {
        setEnrollmentApplicationReviewToUnread(app);
        setApplicationsProgramEnrollmentReviewToUnread(app);
    }

    private static List<String> getReviewExternalMessages(SObject oReview) {
        List<String> msgs = new List<String>();
        Set<String> externalFieldsMsg = new Set<String>();

        if (oReview.getsobjecttype().getDescribe().getName() == 'Enrollment_Application_Review__c') {
            externalFieldsMsg = COMPANY_INFO_EXTERNAL_MESSAGE_FIELDS;
        } else {
            externalFieldsMsg = PROGRAM_EXTERNAL_MESSAGE_FIELDS;
        }

        for (String fieldName : externalFieldsMsg) {
            if (String.isNotEmpty((String)oReview.get(fieldName))) {
                msgs.add((String)oReview.get(fieldName));
            }
        }

        return msgs;
    }

    private static List<String> getReviewInternalMessages(SObject oReview) {
        List<String> msgs = new List<String>();
        Set<String> internalFieldsMsg = new Set<String>();

        if (oReview.getsobjecttype().getDescribe().getName() == 'Enrollment_Application_Review__c') {
            internalFieldsMsg = COMPANY_INFO_INTERNAL_MESSAGE_FIELDS;
        } else {
            internalFieldsMsg = PROGRAM_INTERNAL_MESSAGE_FIELDS;
        }

        for (String fieldName : internalFieldsMsg) {
            if (String.isNotEmpty((String)oReview.get(fieldName))) {
                msgs.add((String)oReview.get(fieldName));
            }
        }
        return msgs;
    }

    public static List<String> getReturnedFieldsForCorrection(SObject oReview, Map<Integer, Set<String>> fieldsMap) {
        List<String> returnedFields = new List<String>();

        if (oReview.get('Approval_Status__c') == APP_REVIEW_APPROVAL_REQUEST_MORE_INFO_STATUS) {
            for (Integer i : fieldsMap.keySet()) {
                for (String fieldName : fieldsMap.get(i)) {
                    if ((String)oReview.get(fieldName) == 'No') {
                        String fieldLabel;
                        try {
                            fieldLabel = (String)setting.get(fieldName);
                        } catch (Exception e) {
                            System.debug('### Error: ' + e.getMessage());
                        }
                        // In case the api field it's not defined in the custom settings
                        // use the api name to display.
                        fieldLabel = String.isNotEmpty(fieldLabel) ? fieldLabel : fieldName;

                        returnedFields.add(fieldLabel);
                    }
                }
            }
        }

        return returnedFields;
    }

    /**
     * Loads the values set on the custom setting.
     *
     */
    private static void initCustomSetting() {
        setting = PGE_Enrollment_API_To_Display_Map__c.getInstance(PGE_ENROLLMENT_API_SETTING_DATA_SET);

        if (setting == null) {
            System.debug('### Error BIGPGEEnrollmentReviewResultUtility initCustomSetting: Please define all the fields for the Custom Setting PGEEnrollmentPortalAPISettings.');
        }
    }

    public class EnrollmentApplicationReviewWrapper {
        public List<String> externalMsg {get; set;}
        public List<String> internalMsg {get; set;}
        public List<String> returnedField {get; set;}
        public String title {get; set;}
        public String status {get; set;}

        public EnrollmentApplicationReviewWrapper(String title, String status, List<String> returnedField,
                                                  List<String> externalMsg, List<String> internalMsg) {
            this.title = title;
            this.status = status;
            this.returnedField = returnedField;
            this.externalMsg = externalMsg;
            this.internalMsg = internalMsg;
        }
    }

}