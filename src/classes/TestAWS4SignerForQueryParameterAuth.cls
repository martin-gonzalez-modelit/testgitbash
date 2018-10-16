/**
 * This class contains unit tests for validating the behavior of AWS4SignerForQueryParameterAuth class.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
@isTest
private class TestAWS4SignerForQueryParameterAuth {

    private static final String AWS_ACCESS_KEY = 'access';
    private static final String AWS_SECRET_KEY = 'secret';
    private static final String ENDPOINT = 'https://s3-us-west-1.amazonaws.com';
    private static final String REGION = 'us-west-1';

    @isTest
    static void testSigningQueryParameter() {
        String EXPECTED_AUTHORIZATION = ''
                + 'X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=access/20161101/us-west-1/s3/aws4_request'
                + '&X-Amz-Date=20161101T000000Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host'
                + '&X-Amz-Signature=92f048b9f1f0dbebb242848b09c75bb97d6ac9ee1be939c3b13e76470847fda5';

        Map<String, String> queryParams = new Map<String, String> { 'X-Amz-Expires' => '300' };
        // Signer will add 'host'
        Map<String, String> headers = new Map<String, String>();
        String authorizationQueryParameters;

        Test.startTest();
        AWS4SignerForQueryParameterAuth signer = new AWS4SignerForQueryParameterAuth(
                new Url(ENDPOINT), HttpConstants.HttpMethod.XGET, 's3', REGION);
        DateTime overridenDate = DateTime.newInstanceGMT(2016, 11, 1);
        signer.setOverrideDate(overridenDate);
        authorizationQueryParameters = signer.computeSignature(headers, queryParams,
                AWS4SignerBase.UNSIGNED_PAYLOAD, new BasicAWSCredentials(AWS_ACCESS_KEY, AWS_SECRET_KEY));
        Test.stopTest();

        System.assertEquals(EXPECTED_AUTHORIZATION, authorizationQueryParameters);
        System.assertNotEquals(null, headers.get(HttpConstants.HTTP_HEADER_HOST));
    }
}