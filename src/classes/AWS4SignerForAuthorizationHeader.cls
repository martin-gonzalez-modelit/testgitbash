/**
 * Signer implementation that signs requests with the AWS4 signing protocol.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
public without sharing class AWS4SignerForAuthorizationHeader extends AWS4SignerBase {

    public AWS4SignerForAuthorizationHeader(Url endpointUrl, HttpConstants.HttpMethod httpMethod, String serviceName,
            String regionName) {
        super(endpointUrl, httpMethod, serviceName, regionName);
    }

    /**
     * Computes an AWS4 signature for a request, ready for inclusion as an 'Authorization' header.
     *
     * @param headers The request headers; 'Host' and 'X-Amz-Date' will be added to this set.
     * @param queryParameters Any query parameters that will be added to the endpoint. The parameters should be
     *        specified in canonical format.
     * @param bodyHash Precomputed SHA256 hash of the request body content; this value should also be set as the header
     *        'X-Amz-Content-SHA256' for non-streaming uploads.
     * @param credentials The user's credentials (access key ID and secret key).
     * @return The computed authorization string for the request. This value needs to be set as the header
     *        'Authorization' on the subsequent HTTP request.
     */
    public String computeSignature(Map<String, String> headers, Map<String, String> queryParameters, String bodyHash,
            AWSCredentials credentials) {
        /* First get the date and time for the subsequent request, and convert to ISO 8601 format for use in signature
        generation */
        DateTime now = overriddenDate != null ? overriddenDate : DateTime.now();
        String dateTimeStamp = now.formatGMT(ISO_8601_BASIC_FORMAT);

        // Update the headers with required 'x-amz-date' and 'host' values
        addHostHeader(headers);
        headers.put(X_AMZ_DATE, dateTimeStamp);

        /* Canonicalize the headers; we need the set of header names as well as the names and values to go into the
        signature process*/
        String canonicalizedHeaderNames = getCanonicalizeHeaderNames(headers);
        String canonicalizedHeaders = getCanonicalizedHeaderString(headers);

        // If any query string parameters have been supplied, canonicalize them
        String canonicalizedQueryParameters = getCanonicalizedQueryString(queryParameters);

        // Canonicalize the various components of the request
        String canonicalRequest = createCanonicalRequest(endpointUrl, httpMethod, canonicalizedQueryParameters,
                canonicalizedHeaderNames, canonicalizedHeaders, bodyHash);

        // Construct the string to be signed
        String dateStamp = now.formatGMT(DATE_STRING_FORMAT);
        String scope = generateScope(dateStamp, regionName, serviceName);
        String stringToSign = createStringToSign(SIGNING_ALGORITHM, dateTimeStamp, scope, canonicalRequest);

        // Compute the signing key
        Blob signingKey = newSigningKey(credentials, dateStamp, regionName, serviceName);
        Blob signature = sign(stringToSign, signingKey);

        return buildAuthorizationHeader(credentials, signature, canonicalizedHeaderNames, scope);
    }

    /**
     * Creates the authorization header to be included in the request.
     */
    private String buildAuthorizationHeader(AWSCredentials credentials, Blob signature, String signedHeaders,
            String scope) {
        String credential = 'Credential=' + credentials.getAWSAccessKeyId() + '/' + scope;
        String signerHeaders = 'SignedHeaders=' + signedHeaders;
        String signatureHeader = 'Signature=' + EncodingUtil.convertToHex(signature);

        String authorizationHeader = SIGNING_ALGORITHM + ' '
                + credential + ', '
                + signerHeaders + ', '
                + signatureHeader;

        return authorizationHeader;
    }
}