/**
 * Sample AWS4 signer demonstrating how to sign requests to Amazon S3 using query string parameters.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
public without sharing class AWS4SignerForQueryParameterAuth extends AWS4SignerBase {

    public AWS4SignerForQueryParameterAuth(URL endpointUrl, HttpConstants.HttpMethod httpMethod, String serviceName,
            String regionName) {
        super(endpointUrl, httpMethod, serviceName, regionName);
    }

    /**
     * Computes an AWS4 authorization for a request, suitable for embedding in query parameters.
     *
     * @param headers The request headers; 'Host' and 'X-Amz-Date' will be added to this set.
     * @param queryParameters  Any query parameters that will be added to the endpoint. The parameters should be
     *        specified in canonical format.
     * @param bodyHash Precomputed SHA256 hash of the request body content; this value should also be set as the header
     *        'X-Amz-Content-SHA256' for non-streaming uploads.
     * @param credentials The user's credentials (access key ID and secret key).
     * @return The computed authorization string for the request. This value needs to be set as the header
     *         'Authorization' on the subsequent HTTP request.
     */
    public String computeSignature(Map<String, String> headers, Map<String, String> queryParameters, String bodyHash,
            AWSCredentials credentials) {
        /* First get the date and time for the subsequent request, and convert to ISO 8601 format for use in signature
        generation */
        DateTime now = overriddenDate != null ? overriddenDate : DateTime.now();
        String dateTimeStamp = now.formatGMT(ISO_8601_BASIC_FORMAT);

        // Update the headers with required 'host' values
        addHostHeader(headers);

        // Canonicalized headers need to be expressed in the query parameters processed in the signature
        String canonicalizedHeaderNames = getCanonicalizeHeaderNames(headers);
        String canonicalizedHeaders = getCanonicalizedHeaderString(headers);
        // We need scope as part of the query parameters
        String dateStamp = now.formatGMT(DATE_STRING_FORMAT);
        String scope = generateScope(dateStamp, regionName, serviceName);

        // Add the fixed authorization params required by Signature V4
        addPreSignInformationToRequest(credentials, queryParameters, canonicalizedHeaderNames, dateTimeStamp, scope);

        // Build the expanded canonical query parameter string that will go into the signature computation
        String canonicalizedQueryParameters = getCanonicalizedQueryString(queryParameters);

        // Express all the header and query parameter data as a canonical request string
        String canonicalRequest = createCanonicalRequest(endpointUrl, httpMethod, canonicalizedQueryParameters,
                canonicalizedHeaderNames, canonicalizedHeaders, bodyHash);

        // Construct the string to be signed
        String stringToSign = createStringToSign(SIGNING_ALGORITHM, dateTimeStamp, scope, canonicalRequest);

        // Compute the signing key
        Blob signingKey = newSigningKey(credentials, dateStamp, regionName, serviceName);
        Blob signature = sign(stringToSign, signingKey);

        // Form up the authorization parameters for the caller to place in the query string
        String authString = X_AMZ_ALGORITHM + '=' + queryParameters.get(X_AMZ_ALGORITHM)
                + '&' + X_AMZ_CREDENTIAL + '=' + queryParameters.get(X_AMZ_CREDENTIAL)
                + '&' + X_AMZ_DATE + '=' + queryParameters.get(X_AMZ_DATE)
                + '&' + X_AMZ_EXPIRES + '=' + queryParameters.get(X_AMZ_EXPIRES)
                + '&' + X_AMZ_SIGNED_HEADER + '=' + queryParameters.get(X_AMZ_SIGNED_HEADER)
                + '&' + X_AMZ_SIGNATURE + '=' + EncodingUtil.convertToHex(signature);

        return authString;
    }

    /**
     * Includes all the signing headers as request parameters for pre-signing.
     */
    private void addPreSignInformationToRequest(AWSCredentials credentials, Map<String, String> queryParameters,
            String signedHeaders, String timeStamp, String scope) {
        // Add the fixed authorization params required by Signature V4
        queryParameters.put(X_AMZ_ALGORITHM, SIGNING_ALGORITHM);
        queryParameters.put(X_AMZ_CREDENTIAL, credentials.getAwsAccessKeyId() + '/' + scope);
        // x-amz-date is now added as a query parameter, but still need to be in ISO8601 basic form
        queryParameters.put(X_AMZ_DATE, timeStamp);
        queryParameters.put(X_AMZ_SIGNED_HEADER, signedHeaders);
    }

}