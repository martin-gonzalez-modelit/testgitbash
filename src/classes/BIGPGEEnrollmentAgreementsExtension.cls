/**
 * This controller implements the actions of the PG&E Application Enrollment Portal Agreements Page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentAgreementsExtension {
    private static Map<Id,String> appPrgMap;
    private static Map<String,Id> appPrgMapNameToId = new Map<String,Id>();
    public BIGPGEEnrollmentAgreementsExtension(BIGPGEEnrollmentController controller) {}

    @RemoteAction
    public static AgreementsWrapper getAgreementsEnrollment(String appId, String accessToken) {
        Map<Id, AgreementWrapper> agreementIdsMap = new Map<Id, AgreementWrapper>();
        AgreementsWrapper agreementWrapper = new AgreementsWrapper();
        Application_Enrollment__c app;

        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        }

        if (app != null) {
            try {
                // Load programs associated to the application.
                appPrgMap = getApplicationPrograms(appId);

                List<Application_Program_Enrollment_Agreement__c> appPrgAgmts = [
                    SELECT Agreement__r.Id, Application_Program_Enrollment__r.Id, Agreement__r.Program_Handbook__c,
                            Agreement__r.Combustion_Appliance__c, Agreement__r.Agree_Terms_and_Conditions__c,
                            Agreement__r.EUC_Graphic_Standards__c, Agreement__r.EUC_Customer_Collateral__c,
                            Agreement__r.ACQC_Agreement__c, Agreement__r.Contractor_Agreement__c,
                            Agreement__r.Rater_Agreement__c
                    FROM Application_Program_Enrollment_Agreement__c
                    WHERE Application_Program_Enrollment__r.Id =: appPrgMap.keySet()
                    AND Application_Program_Enrollment__r.Status__c
                        NOT IN (:BIGPGEEnrollmentAppProgramUtility.PROGRAM_REJECTED_STATUS,
                                :BIGPGEEnrollmentAppProgramUtility.PROGRAM_EXPIRED_STATUS,
                                :BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS)
                    ];

                for (Application_Program_Enrollment_Agreement__c appPrgAgmt : appPrgAgmts) {
                    if (!agreementIdsMap.containsKey(appPrgAgmt.Agreement__r.Id)) {
                        agreementIdsMap.put(appPrgAgmt.Agreement__r.Id, new AgreementWrapper(
                                appPrgAgmt.Agreement__r, appPrgMap.get(appPrgAgmt.Application_Program_Enrollment__r.Id)));
                    } else {
                        agreementIdsMap.get(appPrgAgmt.Agreement__r.Id).programs
                                .add(appPrgMap.get(appPrgAgmt.Application_Program_Enrollment__r.Id));
                    }
                }

                List<Document__c> sDocuments = [
                    SELECT Id, File_Type__c, File_Name__c, Agreement__r.Id,
                        (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                    FROM Document__c
                    WHERE Agreement__r.Id IN : agreementIdsMap.keySet()
                    ];

                for (Document__c sDocument : sDocuments) {
                    if (sDocument.Attachments.size() > 0) {
                        agreementIdsMap.get(sDocument.Agreement__r.Id).files.add(new DocumentWrapper(sDocument, false));
                    }
                }
                agreementWrapper.agreements.addAll(agreementIdsMap.values());
            } catch (Exception e) {
                System.debug('############# Error: ' + e.getMessage());
                agreementWrapper.success = false;
                agreementWrapper.message = e.getMessage();
            }
        }

        if (app == null) {
            agreementWrapper.isTokenExpired = true;
        }

        return agreementWrapper;
    }

    @RemoteAction
    public static AgreementsWrapper saveAgreementsEnrollment(String appId, String accessToken, String jsonApp) {
        AgreementsWrapper myAgreements =  new AgreementsWrapper();
        Application_Enrollment__c app;
        Map<Id, AgreementWrapper> agreementIdsMap = new Map<Id, AgreementWrapper>();
System.debug('##jsonApp = ' + jsonApp);
        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        }

        if (app != null) {
            try {
                // Load programs associated to the application.
                appPrgMap = getApplicationPrograms(appId);
                myAgreements = (AgreementsWrapper)JSON.deserialize(jsonApp, AgreementsWrapper.class);
                List<Agreement__c> agmtsToAdd = new List<Agreement__c>();

                for (AgreementWrapper agmtWrapper : myAgreements.agreements) {
                    agmtsToAdd.add(agmtWrapper.agreement);
                }
                upsert agmtsToAdd;

                Map<Id, Set<String>> agmtIdToPrgs = new Map<Id, Set<String>>();
                for (Application_Program_Enrollment_Agreement__c appPrgAgmt : [
                        SELECT Agreement__r.Id, Application_Program_Enrollment__r.Id
                        FROM Application_Program_Enrollment_Agreement__c
                        WHERE Agreement__r.Id IN : agmtsToAdd
                        ]) {
                    if (!agmtIdToPrgs.containsKey(appPrgAgmt.Agreement__r.Id)) {
                        agmtIdToPrgs.put(appPrgAgmt.Agreement__r.Id, new Set<String> {
                                appPrgMap.get(appPrgAgmt.Application_Program_Enrollment__r.Id) });
                    } else {
                        agmtIdToPrgs.get(appPrgAgmt.Agreement__r.Id)
                                .add(appPrgMap.get(appPrgAgmt.Application_Program_Enrollment__r.Id));
                    }
                }

                List<Application_Program_Enrollment_Agreement__c> appAgreementsToAdd = 
                        new List<Application_Program_Enrollment_Agreement__c>();
                for (AgreementWrapper agreementWrapper : myAgreements.agreements) {
                    for (String agmtPrg : agreementWrapper.programs) {
                        if (agmtIdToPrgs.get(agreementWrapper.agreement.Id) == null 
                                || (agmtIdToPrgs.get(agreementWrapper.agreement.Id) != null
                                    && !agmtIdToPrgs.get(agreementWrapper.agreement.Id).contains(agmtPrg))) {
                            Application_Program_Enrollment_Agreement__c appAgreement = 
                                    new Application_Program_Enrollment_Agreement__c();
                            appAgreement.Agreement__c = agreementWrapper.agreement.Id;
                            appAgreement.Application_Program_Enrollment__c = appPrgMapNameToId.get(agmtPrg);
                            appAgreementsToAdd.add(appAgreement);
                        }
                    }
                }

                if (appAgreementsToAdd.size() > 0) {
                    insert appAgreementsToAdd;
                }

                for (AgreementWrapper agreementWrapper : myAgreements.agreements) {
                        String agmtPrgs = String.join(agreementWrapper.programs, ',');
                        if (!agreementIdsMap.containsKey(agreementWrapper.agreement.Id)) {
                            agreementIdsMap.put(agreementWrapper.agreement.Id,
                                    new AgreementWrapper(agreementWrapper.agreement, agmtPrgs));
                        }
                }
                // Get existing documents
                List<Document__c> sDocuments = [
                    SELECT Id, File_Type__c, File_Name__c, Agreement__r.Id,
                        (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                    FROM Document__c
                    WHERE Agreement__r.Id IN : agmtIdToPrgs.keySet()
                    ];
                for (Document__c sDocument : sDocuments) {
                    if (sDocument.Attachments.size() > 0) {
                        agreementIdsMap.get(sDocument.Agreement__r.Id).files.add(new DocumentWrapper(sDocument, false));
                    }
                }
                myAgreements = new AgreementsWrapper();
                myAgreements.agreements.addAll(agreementIdsMap.values());
            } catch (Exception e) {
                System.debug('############# Error: ' + e.getMessage());
                myAgreements.success = false;
                myAgreements.message = e.getMessage();
            }
        }

        if (app == null) {
            myAgreements.isTokenExpired = true;
        }

        return myAgreements;
    }

    @RemoteAction
    public static BIGPGEEnrollmentResponseWrapper submitAgreementsEnrollment(String appId, String accessToken) {
        BIGPGEEnrollmentResponseWrapper response = new BIGPGEEnrollmentResponseWrapper();
        Application_Enrollment__c app;

        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationAndProgramsByIdAndToken(appId, accessToken);
        }

        if (app != null) {
            try {
                BIGPGEEnrollmentReviewResultUtility.setAllReviewsToUnread(app);
                BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToPendingReview(app);

                response.responseData = app;
            } catch (Exception e) {
                System.debug('####### Error trying to submit Enrollment application: ' + e.getMessage());
                response.success = false;
                response.message = e.getMessage();
            }
        }

        if (app == null) {
            response.isTokenExpired = true;
        }

        return response;
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

    public class AgreementWrapper {
        public Agreement__c agreement;
        public List<String> programs = new List<String>();
        public List<DocumentWrapper> files = new List<DocumentWrapper>();

        public AgreementWrapper(Agreement__c agreement, String program) {
            this.agreement = agreement;
            this.programs.add(program);
        }
    }

    public class AgreementsWrapper extends BIGPGEEnrollmentResponseWrapper {
        public List<AgreementWrapper> agreements = new List<AgreementWrapper>();
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
            appPrgsMap.put(appPrg.Id, appPrg.RecordType.Name);
            appPrgMapNameToId.put(appPrg.RecordType.Name, appPrg.Id);
        }

        return appPrgsMap;
    }
}