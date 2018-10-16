/**
 * This class contains unit tests for validating apex code in the ApplicationFileService.cls
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2018-6
 */
@isTest
private class TestApplicationFileService {
    private static Application__c application;
    private static Application_File__c applicationFile;
    private static Attachment attachment;

    /**
     * Tests the getAttachmentURL() method, which retrieves the URL that's needed to open or download attachments.
     */
    private static testMethod void testGetAttachmentURL() {
        Test.startTest();
        String attachmentURL = ApplicationFileService.getAttachmentURL();
        Test.stopTest();
        // Verify that the URL is correct.
        System.assertEquals(URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=',
                attachmentURL);
    }

    /**
     * Tests the saveChunk() method with an empty application file id, so a new application file with its
     * corresponding attachment should be created.
     */
    private static testMethod void testSaveChunkWithoutApplicationFileId() {
        createTestData();

        Test.startTest();
        ApplicationFileService.saveChunk(application.Id, 'Photo', 'content in base64Data', 'pdf', '', '');
        Test.stopTest();

        Application_File__c applicationFile = [
            SELECT FQC_Billable__c, Application_File_Type__c, (SELECT Name, ContentType FROM Attachments)
            FROM Application_File__c
            WHERE Application__c = :application.Id AND File_Name__c = 'Photo'
            LIMIT 1
            ];
        // Verify that the new application file was created correctly.
        System.assertEquals('Field QC Photos', applicationFile.Application_File_Type__c);
        System.assertEquals(true, applicationFile.FQC_Billable__c);
        // Verify that the new attachment was created correctly.
        System.assertEquals(1, applicationFile.Attachments.size());
        System.assertEquals('Photo', applicationFile.Attachments[0].Name);
        System.assertEquals('pdf', applicationFile.Attachments[0].ContentType);
    }


    /**
     * Tests the saveChunk() method with an existing application file id, in order for the chuncks of the file to be
     * attached to the existing attachment.
     */
    private static testMethod void testSaveChunkWithApplicationFileId() {
        createTestData();
        // Get the body length of the attachment before appending more content to it.
        Application_File__c existingApplicationFile = [
            SELECT Id, (SELECT BodyLength FROM Attachments)
            FROM Application_File__c
            LIMIT 1
            ];

        Test.startTest();
        ApplicationFileService.saveChunk(application.Id, attachment.Name, 'more content', 'pdf', applicationFile.Id,
                attachment.Id);
        Test.stopTest();

        List<Application_File__c> applicationFileList = [
            SELECT Application__c, File_Name__c, FQC_Billable__c, Application_File_Type__c,
                (SELECT Name, ContentType, BodyLength FROM Attachments)
            FROM Application_File__c
            ];
        Application_File__c applicationFile = applicationFileList[0];
        // Verify that there is only one application file, and that is was created correctly.
        System.assertEquals(1, applicationFileList.size());
        System.assertEquals(application.Id, applicationFile.Application__c);
        System.assertEquals('Field QC Photos', applicationFile.Application_File_Type__c);
        System.assertEquals(true, applicationFile.FQC_Billable__c);
        System.assertEquals(attachment.Name, applicationFile.File_Name__c);
        // Verify that the application file has only one attachment, that it was created correctly, and that more
        // content was appended to it.
        System.assertEquals(1, applicationFile.Attachments.size());
        System.assertEquals('filename', applicationFile.Attachments[0].Name);
        System.assertEquals('pdf', applicationFile.Attachments[0].ContentType);
        System.assert(existingApplicationFile.Attachments[0].BodyLength < applicationFile.Attachments[0].BodyLength);
    }

    /**
     * Tests the deleteApplicationFile() method, which deletes an existing application file.
     */
    private static testMethod void testDeleteApplicationFile() {
        createTestData();

        Test.startTest();
        ApplicationFileService.deleteApplicationFile(applicationFile.Id);
        Test.stopTest();

        List<Application_File__c> applicationFileList = [
            SELECT Id
            FROM Application_File__c
            ];
        // Verify that the existing application file was deleted.
        System.assertEquals(0, applicationFileList.size());
    }

    /**
     * Creates test data needed to the unit tests.
     */
    private static void createTestData() {
        // Create an ACQC application.
        application = BIGPortalTestUtils.createApplication(ApplicationUtils.ACQC_RECORD_TYPE);
        insert application;
        // Create an application file for the previous application.
        applicationFile = BIGPortalTestUtils.createApplicationFile('filename', 'Field QC Photos', application.Id);
        applicationFile.FQC_Billable__c = true;
        insert applicationFile;
        // Create an attachment for the previous application file.
        attachment = BIGPortalTestUtils.createAttachment(
                'filename', 'pdf', Blob.valueof('attach content'), applicationFile.Id);
        insert attachment;
    }
}