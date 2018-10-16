/**
 * This class contains unit tests for validating the behavior of BIGPGEEnrollmentInsuranceExtension
 * for PG&E Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
@isTest
private class TestBIGPGEEnrollmentInsuranceExtension {

    private static BIGPGEEnrollmentInsuranceExtension.InsuranceWrapper response;
    private static BIGPGEEnrollmentInsuranceExtension.InsuranceWrapper insuranceWrapper;
    private static Application_Enrollment__c app;
    private static final Set<String> INSURANCE_DOCUMENT_TYPE = new Set<String> {'Bonding Document',
            'Workers Compensation Insurance', 'Auto Liability Insurance', 'General Liability Insurance'};

    @testSetup
    static void initSetupData() {
        // Setup init data.
        BIGPGEEnrollmentTestUtility.TEST_LIST_SIZE = 1;
        BIGPGEEnrollmentTestUtility testData = new BIGPGEEnrollmentTestUtility(new List<String> {'Contractor'},
                new List<String> {BIGPGEEnrollmentApplicationUtility.ENROLLMENT_CREATED_STATUS},
                new List<String> {BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS,
                BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_REQUEST_INFO_STATUS});
    }

    static testMethod void getInsuranceEnrollmentFailed() {
        app = [SELECT Name, Security_Code__c, Access_Token__c
               FROM Application_Enrollment__c
               WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
               LIMIT 1];

        System.assertNotEquals(null, app.Id);

        Test.startTest();
        BIGPGEEnrollmentController ctrl = new BIGPGEEnrollmentController();
        BIGPGEEnrollmentInsuranceExtension insuranceCtrl = new BIGPGEEnrollmentInsuranceExtension(ctrl);

        response = BIGPGEEnrollmentInsuranceExtension.getInsuranceEnrollment(app.Id , app.Access_Token__c);
        // Token expired should be true since access token is invalid.
        System.assert(response.isTokenExpired == true);
        Test.stopTest();
    }

    static testMethod void getInsuranceEnrollmentSuccessfully() {
        app = [SELECT Name, Security_Code__c, Access_Token__c
               FROM Application_Enrollment__c
               WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
               LIMIT 1];

        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        createDocuments(INSURANCE_DOCUMENT_TYPE, app.Id);

        Test.startTest();
        response = BIGPGEEnrollmentInsuranceExtension.getInsuranceEnrollment(app.Id , app.Access_Token__c);
        // Check if staffs were successfully retrieved.
        System.assert(response.files.size() > 0);
        Test.stopTest();
    }

    static testMethod void saveInsuranceEnrollmentAccessTokenExpired() {

        Test.startTest();
        response = BIGPGEEnrollmentInsuranceExtension.saveInsuranceEnrollment(null, null, '{}');
        // Token expired should be true since access token is invalid.
        System.assert(response.isTokenExpired == true);
        Test.stopTest();
    }

    static testMethod void saveInsuranceEnrollmentSuccessfully() {
        app = [SELECT Name, Security_Code__c, Access_Token__c
               FROM Application_Enrollment__c
               WHERE Company_Info_Status__c =: BIGPGEEnrollmentApplicationUtility.COMPANY_INFO_PENDING_STATUS
               LIMIT 1];

        System.assertNotEquals(null, app.Id);

        BIGPGEEnrollmentApplicationUtility.setEnrollmentApplicationToken(app);
        update app;

        // Set the Workers Compensation Type
        app.Workers_Compensation_Type__c = 'Workers Compensation Insurance';
        insuranceWrapper = new BIGPGEEnrollmentInsuranceExtension.InsuranceWrapper(app);
        String JSONApp = JSON.serialize(insuranceWrapper);

        Test.startTest();
        response = BIGPGEEnrollmentInsuranceExtension.saveInsuranceEnrollment(app.Id, app.Access_Token__c, JSONApp);
        // Token expired should be false since access token is valid.
        System.assert(response.isTokenExpired == false);
        // Check if the application was successfully updated.
        System.assertEquals('Workers Compensation Insurance', response.app.Workers_Compensation_Type__c);
        Test.stopTest();
    }

    private static List<BIGPGEEnrollmentInsuranceExtension.DocumentWrapper> createDocuments(Set<String> fileTypes,
            String parentId) {

        List<BIGPGEEnrollmentInsuranceExtension.DocumentWrapper> docsWrapper =
                new List<BIGPGEEnrollmentInsuranceExtension.DocumentWrapper>();
        List<Document__c> docs = new List<Document__c>();
        List<Attachment> files = new List<Attachment>();

        for (String fileType : fileTypes) {
            docs.add(createDocument('Application_Enrollment__c', parentId, fileType, 'test ' + filetype + '.png', null));
        }
        insert docs;

        for (Document__c doc : docs) {
            files.add(createAttachment(doc.Id, doc.File_Type__c, doc.File_Name__c));
        }
        insert files;

        List<Document__c> documents = [
            SELECT File_Type__c, File_Name__c, Application_Enrollment__c,
                (SELECT Id, ParentId, Description, Name FROM Attachments Order By CreatedDate Desc LIMIT 1)
            FROM Document__c
            WHERE Id IN : docs
            ];

        for (Document__c document : documents) {
            docsWrapper.add(new BIGPGEEnrollmentInsuranceExtension.DocumentWrapper(document, false));

            // Verify that the documents were inserted correctly
            System.assertEquals(document.Application_Enrollment__c, parentId);
            System.assertEquals(documents.size(), fileTypes.size());
            // Verify that the attachments were inserted correctly
            for (Attachment file : document.Attachments) {
                if (file.ParentId == document.Id) {
                    System.assertEquals(file.Name, document.File_Name__c);
                    System.assertEquals(file.Description, document.File_Type__c);
                }
            }
        }

        return docsWrapper;
    }

    private static Document__c createDocument(String parentType, String parentId, String fileType, String fileName,
            Date expDate) {

        Document__c doc = new Document__c();
        doc.put(parentType, parentId);
        doc.File_Type__c = fileType;
        doc.File_Name__c = fileName;
        doc.Expiration_Date__c = expDate;

        return doc;
    }

    private static Attachment createAttachment(String parentId, String fileType, String fileName) {

        Attachment attachment = new Attachment();
        attachment.Name = fileName;
        attachment.Description = fileType;
        attachment.IsPrivate   = false;
        attachment.Body = Blob.valueOf('');
        attachment.ParentId = parentId;

        return attachment;
    }
}