/**
 * This class contains unit tests for validating the behavior of AWS4SignerForAuthorizationHeader class.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
@isTest
private class TestAWS4SignerForAuthorizationHeader {

    private static final String AWS_ACCESS_KEY = 'access';
    private static final String AWS_SECRET_KEY = 'secret';
    private static final String ENDPOINT = 'https://s3-us-west-1.amazonaws.com';
    private static final String REGION = 'us-west-1';

    @isTest
    static void testSigning() {
        String EXPECTED_AUTHORIZATION_HEADER_UNSIGNED_PAYLOAD = ''
               + 'AWS4-HMAC-SHA256 Credential=access/20161101/us-west-1/s3/aws4_request, '
               + 'SignedHeaders=host;x-amz-content-sha256;x-amz-date, '
               + 'Signature=f75ab6b6defe26250df8d11c3e06bd55a2a0b166789b986a6a188459b146bd37';

        String EXPECTED_AUTHORIZATION_HEADER_SIGNED_PAYLOAD = ''
               + 'AWS4-HMAC-SHA256 Credential=access/20161101/us-west-1/s3/aws4_request, '
               + 'SignedHeaders=host;x-amz-content-sha256;x-amz-date, '
               + 'Signature=e57c59d475c611fc84acacecc74e1e5c5e7f22c759003ff6e6cd830c2d1e9044';

        Map<String, String> headers = new Map<String, String>();
        String authorizationSignedPayload, authorizationUnsignedPayload;
        BasicAWSCredentials credentials = new BasicAWSCredentials(AWS_ACCESS_KEY, AWS_SECRET_KEY);

        Test.startTest();
        AWS4SignerForAuthorizationHeader signer = new AWS4SignerForAuthorizationHeader(
                new Url(ENDPOINT), HttpConstants.HttpMethod.XGET, 's3', REGION);
        DateTime overridenDate = DateTime.newInstanceGMT(2016, 11, 1);
        signer.setOverrideDate(overridenDate);
        headers.put(AWS4SignerBase.X_AMZ_CONTENT_SHA256, AWS4SignerBase.UNSIGNED_PAYLOAD);

        // Test request with unsigned 'x-amz-content-sha256' header.
        authorizationUnsignedPayload = signer.computeSignature(headers, null, AWS4SignerBase.UNSIGNED_PAYLOAD,
                credentials);

        // Test request with signed 'x-amz-content-sha256' header.
        String hashedPayload = EncodingUtil.convertToHex(AWS4SignerBase.hash('required'));
        headers.put(AWS4SignerBase.X_AMZ_CONTENT_SHA256, hashedPayload);
        signer = new AWS4SignerForAuthorizationHeader(new Url(ENDPOINT), HttpConstants.HttpMethod.XPUT, 's3', REGION);
        signer.setOverrideDate(overridenDate);
        authorizationSignedPayload = signer.computeSignature(headers, null, hashedPayload, credentials);
        Test.stopTest();

        System.assertEquals(EXPECTED_AUTHORIZATION_HEADER_UNSIGNED_PAYLOAD, authorizationUnsignedPayload);
        System.assertEquals(EXPECTED_AUTHORIZATION_HEADER_SIGNED_PAYLOAD, authorizationSignedPayload);
    }
}