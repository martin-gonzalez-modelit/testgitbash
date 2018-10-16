/**
 * Common methods and properties for all AWS4 signer variants.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
public without sharing abstract class AWS4SignerBase {

    public static final String UNSIGNED_PAYLOAD = 'UNSIGNED-PAYLOAD';
    public static final String AUTHENTICATION_SCHEME = 'AWS4';
    public static final String SIGNING_ALGORITHM = 'AWS4-HMAC-SHA256';
    public static final String HMAC_SHA256_ALGORITHM = 'hmacSHA256';
    public static final String TERMINATOR = 'aws4_request';
    // Seconds in a week, which is the max expiration time Sig-v4 accepts
    public static final Integer PRESIGN_URL_MAX_EXPIRATION_SECONDS = 60 * 60 * 24 * 7;
    public static final String X_AMZ_SECURITY_TOKEN = 'X-Amz-Security-Token';
    public static final String X_AMZ_CREDENTIAL = 'X-Amz-Credential';
    public static final String X_AMZ_DATE = 'X-Amz-Date';
    public static final String X_AMZ_EXPIRES = 'X-Amz-Expires';
    public static final String X_AMZ_SIGNED_HEADER = 'X-Amz-SignedHeaders';
    public static final String X_AMZ_CONTENT_SHA256 = 'X-amz-content-sha256';
    public static final String X_AMZ_SIGNATURE = 'X-Amz-Signature';
    public static final String X_AMZ_ALGORITHM = 'X-Amz-Algorithm';

    // Format strings for the date/time and date stamps required during signing
    public static final String ISO_8601_BASIC_FORMAT = 'yyyyMMdd\'T\'HHmmss\'Z\'';
    public static final String DATE_STRING_FORMAT = 'yyyyMMdd';

    protected Url endpointUrl;
    protected String httpMethod, serviceName, regionName;
    protected DateTime overriddenDate;

    /**
     * Create a new AWS V4 signer.
     *
     * @param endpointUrl The service endpoint, including the path to any resource.
     * @param httpMethod The HTTP verb for the request, e.g. GET.
     * @param serviceName The signing name of the service, e.g. 's3'.
     * @param regionName The system name of the AWS region associated with the endpoint, e.g. us-east-1.
     */
    public AWS4SignerBase(Url endpointUrl, HttpConstants.HttpMethod httpMethod, String serviceName, String regionName) {
        this.endpointUrl = endpointUrl;
        this.httpMethod = httpMethod.name().removeStart('X');
        this.serviceName = serviceName;
        this.regionName = regionName;
    }

    /**
     * Returns the canonical collection of header names that will be included in the signature.
     * For AWS4, all header names must be included in the process in sorted canonicalized order.
     *
     * @param headers we need to make cannonical request.
     * @return headers' name separated with ";".
     */
    protected String getCanonicalizeHeaderNames(Map<String, String> headers) {
        List<String> sortedHeaders = new List<String>();

        for (String header : headers.keySet()) {
            sortedHeaders.add(header.toLowerCase());
        }
        sortedHeaders.sort();

        String result = '';
        for (String header : sortedHeaders) {
            if (String.isNotBlank(result)) {
                result += ';';
            }
            result += header;
        }

        return result;
    }

    /**
     * Computes the canonical headers with values for the request.
     * For AWS4, all headers must be included in the signing process.
     *
     * @param headers we need to make cannonical request.
     * @return headers' name with its value.
     */
    protected String getCanonicalizedHeaderString(Map<String, String> headers) {
        if (headers == null || headers.isEmpty()) {
            return '';
        }

        // Step1: sort the headers by case-insensitive order
        List<String> sortedHeaders = new List<String>();
        Map<String, String> lowerCaseMap = new Map<String, String>();
        for (String header : headers.keySet()) {
            lowerCaseMap.put(header.toLowerCase(), headers.get(header));
        }
        sortedHeaders.addAll(lowerCaseMap.keySet());
        sortedHeaders.sort();

        // Step2: form the canonical header:value entries in sorted order.
        // Multiple white spaces in the values should be compressed to a single space.
        String result = '';
        for (String key : sortedHeaders) {
            result += (key.replaceAll('\\s+', ' ') + ':' + lowerCaseMap.get(key).replaceAll('\\s+', ' '));
            result += '\n';
        }

        return result;
    }

    /**
     * Returns the canonical request string to go into the signer process, this consists of several canonical sub-parts.
     *
     * @param endpoint The URI from the HTTP host to the question mark character ('?') that begins the
     *        query string parameters (if any).
     * @param httpMethod The HTTP verb for the request (e.g. PUT, POST, GET, HEAD and DELETE).
     * @param queryParameters The URI-encoded query string parameters. You URI-encode name and values individually.
     *        You must also sort the parameters in the canonical query string alphabetically by key name.
     * @param canonicalizedHeaderNames The alphabetically sorted, semicolon-separated list of lowercase request
     *        header names. The request headers in the list are the same headers that you included in the
     *        canonicalizedHeaders string.
     * @param canonicalizedHeaders The list of request headers with their values.
     * @param bodyHash The hexadecimal value of the SHA256 hash of the object body.
     * @return A string that includes information from your request in a standardized (canonical) format.
     */
    protected String createCanonicalRequest(Url endpoint, String httpMethod, String queryParameters,
            String canonicalizedHeaderNames, String canonicalizedHeaders, String bodyHash) {
        String canonicalRequest = httpMethod + '\n'
                + getCanonicalizedResourcePath(endpoint) + '\n'
                + queryParameters + '\n'
                + canonicalizedHeaders + '\n'
                + canonicalizedHeaderNames + '\n'
                + bodyHash;
        return canonicalRequest;
    }

    /**
     * Encodes a string into the application/x-www-form-urlencoded format using a specific encoding scheme,
     * for example 'UTF-8'.
     *
     * @param url The string url to encode.
     * @param keepPathSlash The if replace "%2F" to "/" is needed.
     * @return A safe url encoded.
     */
    private static String urlEncode(String url, Boolean keepPathSlash) {
        String encoded = EncodingUtil.urlEncode(url, 'UTF-8');
        if (keepPathSlash) {
            encoded = encoded.replace('%2F', '/');
        }
        return encoded;
    }

    /**
     * Get the canonicalized resource path for the service endpoint.
     *
     * @param endpoint Amazon URL.
     * @return the canonicalized resource path.
     */
    protected String getCanonicalizedResourcePath(Url endpoint) {
        if (endpoint == null) {
            return '/';
        }
        String path = endpoint.getPath();
        if (String.isBlank(path)) {
            return '/';
        }

        String encodedPath = urlEncode(path, true);
        if (!encodedPath.startsWith('/')) {
            encodedPath = '/' + encodedPath;
        }
        return encodedPath;
    }

    /**
     * Examines the specified query string parameters and returns a canonicalized form. The canonicalized query string
     * is formed by first sorting all the query string parameters, then URI encoding both the key and value and then
     * joining them, in order, separating key value pairs with an '&'.
     *
     * @param parameters The query string parameters to be canonicalized.
     * @return A canonicalized form for the specified query string parameters.
     */
    public String getCanonicalizedQueryString(Map<String, String> parameters) {
        if (parameters == null || parameters.isEmpty()) {
            return '';
        }

        List<String> sorted = new List<String>(parameters.keySet());
        sorted.sort();
        Map<String, String> sortedMap = new Map<String, String>();

        for (String key : sorted) {
            sortedMap.put(urlEncode(key, false), urlEncode(parameters.get(key), false));
        }

        String builder = '';
        for (String key : sortedMap.keySet()) {
            builder += (key + '=' + sortedMap.get(key) + '&');
        }
        builder = builder.removeEnd('&');

        return builder;
    }

    /**
     * Creates the string to sign by concatenating the algorithm, date, credential scope, and the digest of
     * the canonical request.
     * The string to sign includes meta information about the request and about the canonical request created by
     * 'getCanonicalRequest' method.
     *
     * @param algorithmName The hashing algorithm to calculate the digests in the canonical request.
     * @param dateTimeData The request date value. This value must match the value in any previous steps.
     * @param scope The string that includes the date, the region you are targeting, the service you are requesting,
     *        and a termination string ('aws4_request') in lowercase characters.
     * @param canonicalRequest The hash of the canonical request that you created in 'getCanonicalRequest' method.
     *        The hashed canonical request must be lowercase base-16 encoded.
     * @return A formatted string to calculate the request signature.
     */
    protected String createStringToSign(String algorithmName, String dateTimeData, String scope,
            String canonicalRequest) {
        String stringToSign = algorithmName + '\n'
                + dateTimeData + '\n'
                + scope + '\n'
                + EncodingUtil.convertToHex(hash(canonicalRequest));
        return stringToSign;
    }

    /**
     * Hashes the string contents (assumed to be UTF-8) using the SHA-256 algorithm.
     *
     * @param text The supplied input string to be one-way hash digest.
     * @return A secure hash digest based on the supplied input string and the SHA-256 algorithm.
     */
    public static Blob hash(String text) {
        return hash(Blob.valueof(text));
    }

    /**
     * Hashes the blob data using the SHA-256 algorithm.
     *
     * @param data The supplied blob to be one-way hash digest.
     * @return A secure hash digest based on the supplied input string and the SHA-256 algorithm.
     */
    public static Blob hash(Blob data) {
        try {
            // Set SHA-256, with a Digest
            return Crypto.generateDigest('SHA-256', data);
        } catch (Exception e) {
            throw new AWSException('Unable to compute hash while signing request: ' + e.getMessage(), e);
        }
    }

    /**
     * Computes a message authentication code (MAC) for the input string, using the private key
     * and the HMAC-SHA256 algorithm by default.
     *
     * @param stringToSign The string value to be signed.
     * @param signingKey The value of signingKey does not need to be in decoded form.
     * @return A digest (binary format) ouput.
     */
    protected Blob sign(String stringToSign, Blob signingKey) {
        return sign(stringToSign, signingKey, HMAC_SHA256_ALGORITHM);
    }

    /**
     * Computes a message authentication code (MAC) for the input string, using the private key
     * and the specified algorithm.
     *
     * @param stringToSign The string value to be signed.
     * @param signingKey The value of signingKey does not need to be in decoded form.
     * @param algorithmName The algorithm to be used. The valid values for algorithmName are:
     *        (hmacMD5, hmacSHA1, hmacSHA256, hmacSHA512).
     * @return A digest (binary format) ouput.
     */
    protected Blob sign(String stringToSign, Blob signingKey, String algorithmName) {
        try {
            return Crypto.generateMac(algorithmName, Blob.valueOf(stringToSign), signingKey);
        } catch (Exception e) {
            throw new AWSException('Unable to calculate a request signature: ' + e.getMessage(), e);
        }
    }

    /**
     * Returns the string that includes the date, the region you are targeting, the service you are requesting,
     * and a termination string ('aws4_request') in lowercase characters.
     *
     * @param dateStamp The UTC formatted signing date with time stamp stripped.
     * @regionName The AWS region to be used for computing the signature.
     * @param serviceName The name of the AWS service.
     * @return The scope to be used for the signing.
     */
    protected String generateScope(String dateStamp, String regionName, String serviceName) {
        return dateStamp + '/' + regionName + '/' + serviceName + '/' + TERMINATOR;
    }

    /**
     * Generates a new signing key from the given parameters and returns it.
     *
     * @param credentials The user's credentials (access key ID and secret key).
     * @param dateStamp The UTC formatted signing date with time stamp stripped.
     * @param regionName The AWS region to be used for computing the signature.
     * @param serviceName The name of the AWS service.
     * @return The digest (binary format) for the derived signing key specific to the date, service, and region,
     *         it offers a greater degree of protection.
     */
    protected Blob newSigningKey(AWSCredentials credentials, String dateStamp, String regionName, String serviceName) {
        Blob kSecret = Blob.valueOf(AUTHENTICATION_SCHEME + credentials.getAwsSecretKey());
        Blob kDate = sign(dateStamp, kSecret);
        Blob kRegion = sign(regionName, kDate);
        Blob kService = sign(serviceName, kRegion);
        return sign(TERMINATOR, kService);
    }

    /**
     * AWS4 requires that we sign the Host header so we have to have it in the request by the time we sign.
     */
    protected void addHostHeader(Map<String, String> headers) {
        String hostHeader = endpointUrl.getHost();
        Integer port = endpointUrl.getPort();

        if (port > -1) {
            hostHeader += (':' + port.format());
        }

        headers.put(HttpConstants.HTTP_HEADER_HOST, hostHeader);
    }
    
    protected void addHostHeader(HttpRequest request) {
        String hostHeader = endpointUrl.getHost();
        Integer port = endpointUrl.getPort();

        if (port > -1) {
            hostHeader += (':' + port.format());
        }

        request.setHeader(HttpConstants.HTTP_HEADER_HOST, hostHeader);
    }

    /**
     * Calculate the hash of the request's payload. Subclass could override this
     * method to provide different values for "x-amz-content-sha256" header or
     * do any other necessary set-ups on the request headers. (e.g. aws-chunked
     * uses a pre-defined header value, and needs to change some headers
     * relating to content-encoding and content-length.)
     */
    protected String calculateContentHash(Blob payloadStream) {
        return payloadStream == null ? UNSIGNED_PAYLOAD : EncodingUtil.convertToHex(hash(payloadStream));
    }
    
    /**
     * Calculate the hash of the request's payload. Subclass could override this
     * method to provide different values for "x-amz-content-sha256" header or
     * do any other necessary set-ups on the request headers. (e.g. aws-chunked
     * uses a pre-defined header value, and needs to change some headers
     * relating to content-encoding and content-length.)
     */
    protected String calculateContentHash(HttpRequest request) {
        Blob payloadStream = request.getBodyAsBlob();
        return payloadStream == null ? UNSIGNED_PAYLOAD : EncodingUtil.convertToHex(hash(payloadStream));
    }

    /**
     * Sets the date that overrides the signing date in the request.
     * This method is internal and should be used only for testing purposes.
     */
    public void setOverrideDate(DateTime overriddenDate) {
        this.overriddenDate = overriddenDate;
    }

    /**
     * Generates an expiration date for the presigned url. If user has specified
     * an expiration date, check if it is in the given limit.
     */
    public static Integer generateExpirationDate(Integer expirationDate) {
        Integer expirationInSeconds = expirationDate != null
                ? expirationDate
                : AWS4SignerBase.PRESIGN_URL_MAX_EXPIRATION_SECONDS;

        if (expirationInSeconds > AWS4SignerBase.PRESIGN_URL_MAX_EXPIRATION_SECONDS) {
            throw new AWSException.ServiceException(
                    'Requests that are pre-signed by SigV4 algorithm are valid for at most 7 days. '
                            + 'The expiration date set on the current request ['
                            + DateTime.now().addSeconds(expirationInSeconds)
                                  .formatGMT(AWS4SignerBase.ISO_8601_BASIC_FORMAT) + '] has exceeded this limit.');
        }
        return expirationInSeconds;
    }

}