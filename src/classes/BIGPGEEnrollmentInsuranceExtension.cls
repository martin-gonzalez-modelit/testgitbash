/**
 * This class implements the actions of the PG&E Application Enrollment Portal Insurance Page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentInsuranceExtension {

    public BIGPGEEnrollmentInsuranceExtension(BIGPGEEnrollmentController controller) {}

    @RemoteAction
    public static InsuranceWrapper getInsuranceEnrollment(String appId, String accessToken) {
        InsuranceWrapper insuranceWrapperObj = new InsuranceWrapper(null);
        Application_Enrollment__c app;

        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        }

        if (app != null) {
            try {
                List<Document__c> documents = [
                    SELECT File_Type__c, File_Name__c,
                        (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                    FROM Document__c
                    WHERE Application_Enrollment__r.Id =: app.Id
                    ];
                insuranceWrapperObj = new InsuranceWrapper(app);
                for (Document__c doc : documents) {
                    insuranceWrapperObj.files.add(new DocumentWrapper(doc, false));
                }
            } catch (Exception e) {
                System.debug('############# Error: ' + e.getMessage());
                insuranceWrapperObj.success = false;
                insuranceWrapperObj.message = e.getMessage();
            }
        }

        if (app == null) {
            insuranceWrapperObj.isTokenExpired = true;
        }
        return insuranceWrapperObj;
    }

    @RemoteAction
    public static InsuranceWrapper saveInsuranceEnrollment(String appId, String accessToken, String jsonApp) {
        InsuranceWrapper myInsurance = new InsuranceWrapper(null);
        Application_Enrollment__c app;
        // Check if application id and access token were supplied.
        if (BIGPGEEnrollmentUtility.isValidSFDCId(appId) && String.isNotEmpty(accessToken)) {
            app = BIGPGEEnrollmentApplicationUtility.getEnrollmentApplicationByIdAndToken(appId, accessToken);
        }

        if (app != null) {
            try {
                myInsurance = (InsuranceWrapper)JSON.deserialize(jsonApp, InsuranceWrapper.class);
                // Update, at this point the app should be created.
                update myInsurance.app;
                // Get documents
                for (Document__c doc : [SELECT File_Type__c, File_Name__c,
                                            (SELECT Id FROM Attachments Order By CreatedDate Desc LIMIT 1)
                                        FROM Document__c
                                        WHERE Application_Enrollment__r.Id =: myInsurance.app.Id]) {
                    myInsurance.files.add(new DocumentWrapper(doc, false));
                }
            } catch (Exception e) {
                System.debug('############# Error: ' + e.getMessage());
                myInsurance.success = false;
                myInsurance.message = e.getMessage();
            }
        }

        if (app == null) {
            myInsurance.isTokenExpired = true;
        }
        return myInsurance;
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

    public class InsuranceWrapper extends BIGPGEEnrollmentResponseWrapper {
        public Application_Enrollment__c app;
        public List<DocumentWrapper> files = new List<DocumentWrapper>();

        public InsuranceWrapper(Application_Enrollment__c app) {
            this.app = app;
        }
    }

}