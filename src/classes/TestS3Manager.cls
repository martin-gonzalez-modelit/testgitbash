/**
 * This class contains unit tests for validating the behavior of S3Manager class.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
@isTest
private class TestS3Manager {
    private static final String BAD_RESPONSE_BODY = '<?xml version="1.0" encoding="UTF-8"?>'
            + '<Error><Code>{0}</Code><Message>{1}</Message><RequestId>B0B31C7DAF9A6D21</RequestId></Error>';
    private static final String AWS_ACCESS_KEY = 'access';
    private static final String AWS_SECRET_KEY = 'secret';
    private static final String ENDPOINT = 'https://s3-us-west-1.amazonaws.com';
    private static final String REGION = 'us-west-1';
    private static S3Manager s3Manager = new S3Manager(AWS_ACCESS_KEY, AWS_SECRET_KEY);

    /**
     * Test set and get region.
     */
    @isTest
    static void testSetRegion() {
        Test.startTest();
        s3Manager.setRegion(REGION);
        Test.stopTest();

        System.assertEquals(REGION, s3Manager.getRegion());
    }

    /**
     * Test set and get endpoint.
     */
    @isTest
    static void testSetEndPoint() {
        Test.startTest();
        s3Manager.setEndpoint(ENDPOINT);
        Test.stopTest();

        System.assertEquals(ENDPOINT, s3Manager.getEndpoint().toExternalForm());
        System.assertEquals(REGION, s3Manager.getRegion());
    }

    /**
     * Test get metadata from a file saved on Amazon S3.
     */
    @isTest
    static void testGetObjectMetadataSuccessfulResponse() {
        // Create a fake response for the HttpCallOut
        Map<String, String> headers = new Map<String, String> { 'x-amz-storage-class' => StorageClass.GLACIER.name() };

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_OK,
                HttpConstants.STATUS_OK,
                Blob.valueOf('AWS AmazonS3 Body'),
                headers));

        Test.startTest();
        Map<String, String> metadata = S3Manager.getObjectMetadata('bucketname', 'filename.txt');
        Test.stopTest();

        System.assertEquals(StorageClass.GLACIER.name(), metadata.get('x-amz-storage-class'));
    }

    /**
     * Test get metadata from a file saved on Amazon S3.
     */
    @isTest
    static void testGetObjectMetadataKeyDoesNotExist() {
        String EXPECTED_ERROR_CODE = 'NoSuchKey';
        String EXPECTED_ERROR_MESSAGE = 'The specified key does not exist.';
        AWSException.ServiceException awsException;

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_NOT_FOUND,
                HttpConstants.STATUS_NOT_FOUND,
                Blob.valueOf(String.format(
                    BAD_RESPONSE_BODY, new List<String> { EXPECTED_ERROR_CODE, EXPECTED_ERROR_MESSAGE })),
                null));

        Test.startTest();
        try {
            Map<String, String> metadata = S3Manager.getObjectMetadata('bucketname', 'filename.txt');
        } catch (AWSException.ServiceException e) {
            awsException = e;
        }
        Test.stopTest();

        System.assertEquals(EXPECTED_ERROR_CODE, awsException.code);
        System.assertEquals(EXPECTED_ERROR_MESSAGE, awsException.getMessage());
    }

    /**
     * Test upload a file to Amazon S3, get a successful response.
     */
    @isTest
    static void testUploadObjectSuccessfulResponse() {
        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_OK,
                HttpConstants.STATUS_OK,
                Blob.valueOf('AWS AmazonS3 Body'),
                null));

        Test.startTest();
        HttpResponse response = S3Manager.uploadObject('bucketName', 'storeFile', Blob.valueOf('filename1.txt'));
        Test.stopTest();

        System.assertEquals(HttpConstants.STATUS_CODE_OK, response.getStatusCode());
        System.assertEquals(HttpConstants.STATUS_OK, response.getStatus());
    }

    /**
     * Test upload a file to Amazon S3, get a bad response.
     */
    @isTest
    static void testUploadObjectErrorResponse() {
        String EXPECTED_ERROR_CODE = 'BadDigest';
        String EXPECTED_ERROR_MESSAGE = 'The Content-MD5 you specified did not match what we received.';
        AWSException.ServiceException awsException;

        Test.setMock(HttpCalloutMock.class, createRequestMock(
                HttpConstants.STATUS_CODE_BAD_REQUEST,
                HttpConstants.STATUS_BAD_REQUEST,
                Blob.valueOf(String.format(
                    BAD_RESPONSE_BODY, new List<String> { EXPECTED_ERROR_CODE, EXPECTED_ERROR_MESSAGE })),
                null));

        Test.startTest();
        try {
            HttpResponse response = S3Manager.uploadObject('bucketName', 'storeFile', Blob.valueOf('filename1.txt'));
        } catch (AWSException.ServiceException e) {
            awsException = e;
        }
        Test.stopTest();

        System.assertEquals(EXPECTED_ERROR_CODE, awsException.code);
        System.assertEquals(EXPECTED_ERROR_MESSAGE, awsException.getMessage());
    }

    /**
     * Test get presigned url from a file on Amazon S3.
     */
    @isTest
    static void testGetPresignedUrl() {
        String expectedPresignedUrl = endpoint + '/bucketName/FileName?'
                + 'X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=access/20161101/us-west-1/s3/aws4_request'
                + '&X-Amz-Date=20161101T000000Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host'
                + '&X-Amz-Signature=b86f31aaf8b443ca97b564c0a9a4be7c455869394d9e7de175fbabc942dc5d15';

        // Set date to get the same authorization everytime test is run
        S3Manager.setOverrideDate(DateTime.newInstanceGMT(2016, 11, 1));
        s3Manager.setEndpoint(ENDPOINT);

        Test.startTest();
        String presignedUrl = S3Manager.generatePresignedUrl('bucketName', 'FileName');
        Test.stopTest();

        System.assertEquals(expectedPresignedUrl, presignedUrl);
    }

    /**
     * Test get presigned url from a file on Amazon S3 for an invalid expiration date.
     */
    @isTest
    static void testGetPresignedUrlInvalidExpiration() {
        AWSException.ServiceException awsException;
        // Set date to get the same authorization everytime test is run
        S3Manager.setOverrideDate(DateTime.newInstanceGMT(2016, 11, 1));
        s3Manager.setEndpoint(ENDPOINT);

        Test.startTest();
        try {
            String presignedUrl = S3Manager.generatePresignedUrl(
                    'bucketName', 'FileName', AWS4SignerBase.PRESIGN_URL_MAX_EXPIRATION_SECONDS + 1);
        } catch (AWSException.ServiceException e) {
            awsException = e;
        }
        Test.stopTest();

        System.assert(awsException.getMessage().endsWith('has exceeded this limit.'));
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
        reqMock.addResponse(RequestMock.createResponse(statusCode, status, body, headers));

        return reqMock;
    }
}