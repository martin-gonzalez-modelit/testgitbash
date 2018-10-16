/**
 * This class contains unit tests for batch process in ApplicationFileAttachmentBatch class.
 *
 * @author Gabriela Rojas  <gabriela.rojas@modelit.xyz>
 * @since 2016-07
 */
@isTest
private class TestApplicationFileAttachmentBatch {
    // MD5 encrypt for this particular attachment Name = 'filename1.txt', Body = Blob.valueOf('abcdefg').
    private static final String MD5HEX = '7ac66c0f148de9519b8bd264312c4d64';
    private static List<Application__c> testApplicationsHUP;
    private static List<Sub_Application__c> testSubApplicationsHUP;
    private static Account account;
    private static Application__c testApplicationHUP;
    private static Sub_Application__c testSubApplicationHUP;
    private static List<Attachment> attachmentsToInsert;
    private static List<Application_File__c> applicationFiles;
    private static List<String> emailList;
    private static List<Attachment> attachments;

    /**
     * Initialize data for all test methods.
     */
    private static void initData() {
        testApplicationsHUP = new List<Application__c>();
        testSubApplicationsHUP = new List<Sub_Application__c>();
        attachmentsToInsert = new List<Attachment>();
        attachments = new List<Attachment>();
        applicationFiles = new List<Application_File__c>();
        emailList = new List<String>();

        // Create Amazon custom setting.
        BIGPortalTestUtils.createAmazonAWSConfigCustomSetting();

        // Create Email Custom setting.
        BIGPortalTestUtils.createEmailAmazonS3Setting();

        // Create Batch Custom settings.
        BIGPortalTestUtils.createBatchAmazonS3Setting();

        // Create an account for the application.
        account = new Account(Name = 'test account666');
        insert account;

        // Create Applications.
        for (Integer i = 0; i < 5; i++) {
            testApplicationHUP = new Application__c();

            //Preparing data, charging lists.
            if (i == 0) {
                testApplicationHUP.Status__c = ApplicationUtils.REBATE_ISSUED_STATUS;
            } else if (i >= 1 && i <= 2) {
                testApplicationHUP.Status__c = ApplicationUtils.CANCELED_STATUS;
            } else if (i > 2) {
                testApplicationHUP.Status__c = ApplicationUtils.REJECTED_STATUS;
            }

            testApplicationHUP.RecordTypeId = ApplicationUtils.HUP_RECORD_TYPE;
            testApplicationHUP.Last_Application_Submission_Date__c = DateTime.parse('8/31/2014 10:49 PM');
            testApplicationHUP.Application_Approval_Date__c = Date.parse('8/31/2014');
            testApplicationHUP.Contractor__c = account.Id;
            testApplicationHUP.Customer_Email__c = 'testeded@test.com' + i;
            emailList.add('testeded@test.com' + i);
            testApplicationsHUP.add(testApplicationHUP);
        }

        insert testApplicationsHUP;

        for (Application__c app : testApplicationsHUP) {
            // Change Last Status Change Date Time to 5 days ago.
            app.Last_Status_Change_Date_Time__c = Date.Today() - 5;
            // Create a Sub Application for each Application.
            testSubApplicationHUP = new Sub_Application__c();
            testSubApplicationHUP.Application__c = app.Id;
            testSubApplicationHUP.RecordTypeId = BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID;
            testSubApplicationsHUP.add(testSubApplicationHUP);
            // Create Application Files for each Application.
            applicationFiles.add(BIGPortalTestUtils.createApplicationFile(
                    'name.txt', BIGPortalAdvanceHUApplicationUtils.PRE_CONTRACT_SOW_FILE, app.Id));
            applicationFiles.add(BIGPortalTestUtils.createApplicationFile(
                    'name.txt', 'Home Performance System File', app.Id));
            applicationFiles.add(BIGPortalTestUtils.createApplicationFile(
                    'name.txt', 'Home Performance XML', app.Id));
        }

        update testApplicationsHUP;
        insert testSubApplicationsHUP;
        insert applicationFiles;

        Integer j = 0;
        for (Sub_Application__c testSubApplication : testSubApplicationsHUP) {
            j++;
            testSubApplication.Home_Performance_System_File__c = applicationFiles.get(j).Id;
            j++;
            testSubApplication.Home_Performance_XML__c = applicationFiles.get(j).Id;
        }

        update testSubApplicationsHUP;

        // Create one Attachment per Application_File__c.
        for (Application_File__c appFile : applicationFiles) {
            attachmentsToInsert.add(
                    BIGPortalTestUtils.createAttachment('filename1.txt', Blob.valueOf('abcdefg'), appFile.Id));
        }

        insert attachmentsToInsert;
    }

    /**
     * Test Amazon Attachment Batch, get a good response.
     */
    public static testMethod void testAmazonAWSBatchGoodResponse() {
        initData();

        // Create a fake response for the HttpCallOut called on the batch.
        Map<String, String> headers = new Map<String, String> { HttpConstants.HTTP_HEADER_ETAG => MD5HEX };

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_OK,
                HttpConstants.STATUS_OK,
                Blob.valueOf('Hello world!!'),
                headers));

        Test.startTest();
        // Execute Amazon batch.
        Database.executeBatch(
                new ApplicationFileAttachmentBatch(1048576, ApplicationFileAttachmentBatch.DELAY_PERIOD), 10);
        Test.stopTest();

        // Verify only 5 attachmentes were deleted.
        System.assertEquals(10, [SELECT Count() FROM Attachment]);
    }

    /**
     * Test Amazon Attachment Batch, get an error response.
     */
    public static testMethod void testAmazonAWSBatchErrorResponse() {
        initData();

        // Create a fake response for the HttpCallOut called on the batch.
        Map<String, String> headers = new Map<String, String> { HttpConstants.HTTP_HEADER_ETAG => MD5HEX };

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_NOT_FOUND,
                HttpConstants.STATUS_NOT_FOUND,
                Blob.valueOf('Hello bad world!!'),
                headers));

        Test.startTest();
        // Execute Amazon batch.
        Database.executeBatch(
                new ApplicationFileAttachmentBatch(1048576, ApplicationFileAttachmentBatch.DELAY_PERIOD), 10);
        Test.stopTest();

        // Verify none of the attachments were deleted.
        System.assertEquals(15, [SELECT Count() FROM Attachment]);
    }

    /**
     * Test Amazon Attachment Batch, check ETag not match.
     */
    public static testMethod void testAmazonAWSBatchEtagError() {
        initData();

        // Create a fake response for the HttpCallOut called on the batch.
        Map<String, String> headers = new Map<String, String> { HttpConstants.HTTP_HEADER_ETAG => 'EtagNotMatch' };

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_BAD_REQUEST,
                HttpConstants.STATUS_BAD_REQUEST,
                Blob.valueOf('Hello world!!'),
                headers));

        Test.startTest();
        // Execute Amazon batch.
        Database.executeBatch
                (new ApplicationFileAttachmentBatch(1048576, ApplicationFileAttachmentBatch.DELAY_PERIOD), 10);
        Test.stopTest();

        // Verify none of the attachments were deleted.
        System.assertEquals(15, [SELECT Count() FROM Attachment]);
    }

    /**
     * Test Amazon Attachment Batch, get a good response with delay period set to its default (0 days).
     */
    public static testMethod void testAmazonAWSBatchDelayPeriodBeforeAppStatusDate() {
        initData();

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_OK,
                HttpConstants.STATUS_OK,
                Blob.valueOf('Hello world!!'),
                null));

        Test.startTest();
        // Execute Amazon batch.
        Database.executeBatch(new ApplicationFileAttachmentBatch(1048576, 10), 100);
        Test.stopTest();

        // Verify none of the attachments were deleted.
        System.assertEquals(15, [SELECT Count() FROM Attachment]);
    }

    /**
     * Test Amazon Attachment Batch, get a good response with delay period set to its default (0 days). Test only files
     * that are not home performance are sent to Amazon.
     */
    public static testMethod void testAmazonAWSBatchDelayPeriodAfterAppStatusDate() {
        initData();

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_OK,
                HttpConstants.STATUS_OK,
                Blob.valueOf('Hello world!!'),
                null));

        Test.startTest();
        // Execute Amazon batch.
        Database.executeBatch(
                new ApplicationFileAttachmentBatch(1048576, ApplicationFileAttachmentBatch.DELAY_PERIOD), 100);
        Test.stopTest();

        // Verify only 5 attachments were deleted.
        System.assertEquals(10, [SELECT Count() FROM Attachment]);
    }

    /**
     * Test Amazon Attachment Batch. Application Files with more than one attachment are not going to be sent to Amazon,
     * meanwhile the ones with one attachment are going to be sent.
     */
    public static testMethod void testAmazonAWSBatchMoreThanOneAttachmentPerApplicationFile() {
        initData();
        Integer count = 0;

        attachmentsToInsert = new List<Attachment>();
        /*
         * Create one more Attachment for all Application Files created on initData.
         * More than one attachment on Application File are not going to send to Amazon.
         */
        for (Application_File__c appFile : applicationFiles) {
            if (count > 3) {
                attachmentsToInsert.add(
                        BIGPortalTestUtils.createAttachment('filename2.txt', Blob.valueOf('abcdefg'), appFile.Id));
            }
            count++;
        }

        insert attachmentsToInsert;

        // Create a fake response for the HttpCallOut called on the batch.
        Map<String, String> headers = new Map<String, String> { HttpConstants.HTTP_HEADER_ETAG => MD5HEX };

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_OK,
                HttpConstants.STATUS_OK,
                Blob.valueOf('Hello world!!'),
                headers));

        Test.startTest();
        // Execute Amazon batch.
        Database.executeBatch(
                new ApplicationFileAttachmentBatch(1048576, ApplicationFileAttachmentBatch.DELAY_PERIOD), 10);
        Test.stopTest();

        // Verify only 5 attachments were deleted.
        System.assertEquals(25, [SELECT Count() FROM Attachment]);
    }

    /**
     * Create fake response for call outs.
     *
     * @param statusCode The fake message code.
     * @param status The fake message status.
     * @param body The fake message body.
     * @param headers The contents of the response header.
     * @return RequestMock created with fake responses inside.
     */
    private static RequestMock createRequestMock(Integer statusCode, String status, Blob body,
            Map<String, String> headers) {
        RequestMock reqMock = new RequestMock();
        // Create 15 responses, one for each file that needs to be processed.
        for (Integer i = 0; i < 15; i++) {
            reqMock.addResponse(RequestMock.createResponse(statusCode, status, body, headers));
        }

        return reqMock;
    }

}