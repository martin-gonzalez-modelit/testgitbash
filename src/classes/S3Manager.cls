/**
 * Provides the client for accessing the Amazon S3 web service.
 * The Amazon S3 Client provides a simple interface that can be used to store and retrieve data.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
public without sharing class S3Manager {

    /** Default hostname for the S3 service endpoint */
    private static final String S3_HOSTNAME = 's3.amazonaws.com';
    /** The default number of seconds before the amazon link should expire. */
    private static final Integer EXPIRE_SECONDS = 300;
    private AWSCredentials credentials;
    /**
     * The S3 client region that is set by either (a) calling setRegion OR (b) calling setEndpoint with a
     * region-specific S3 endpoint. This region string will be used for signing requests sent by this client.
     */
    private String clientRegion;
    private Url endpoint;
    private DateTime overriddenDate;

    /**
     * Constructs a new Amazon S3 manager using the specified AWS credentials to access Amazon S3.
     *
     * @param credentials The AWS credentials to use when making requests to Amazon S3 with this client.
     */
    public S3Manager(AWSCredentials credentials) {
        this.credentials = credentials;
        setEndpoint(S3_HOSTNAME);
    }

    /**
     * Constructs a new Amazon S3 manager using the specified acces key and secret key credentials to access Amazon S3.
     *
     * @param accessKey The access key to use for an Amazon request.
     * @param secretKey The secret access key to use for an Amazon request.
     */
    public S3Manager(String accessKey, String secretKey) {
        this(new BasicAWSCredentials(accessKey, secretKey));
    }

    /**
     * An alternative to setEndpoint, sets the regional endpoint for this client's service calls.
     * Callers can use this method to control which AWS region they want to work with.
     *
     * @param region The region this client will communicate with.
     */
    public void setRegion(String region) {
        clientRegion = region;
    }

    /**
     * Overrides the default endpoint for this client.
     * Use this method to send requests to the specified AWS region.
     * Pass the endpoint (e.g. 's3.amazonaws.com') or a full URL, including
     * the protocol (e.g. 'https://s3.amazonaws.com').
     *
     * @param endpoint The endpoint or the full URL, including the protocol, of the region-specific AWS endpoint
     *        this client will communicate with.
     */
    public void setEndpoint(String endpoint) {
        setEndpoint(AwsHostNameUtils.toUri(endpoint));
    }

    /**
     * Overrides the default endpoint for this client.
     * Use this method to send requests to the specified AWS region.
     * Pass the full URL, including the protocol (e.g. 'https://s3.amazonaws.com').
     *
     * @param endpoint The full URL, including the protocol, of the region-specific AWS endpoint
     *        this client will communicate with.
     */
    public void setEndpoint(Url endpoint) {
        this.endpoint = endpoint;

        // Extract the region string from the endpoint if it's not known to be a global S3 endpoint.
        clientRegion = AwsHostNameUtils.parseRegionName(this.endpoint);
    }

    /**
     * Gets the metadata for the specified Amazon S3 object without actually fetching the object itself.
     * This is useful in obtaining only the object metadata, and avoids wasting bandwidth on fetching the object data.
     * The object metadata contains information such as content type, content disposition, etc.,
     * as well as custom user metadata that can be associated with an object in Amazon S3.
     *
     * @param bucketName The name of the bucket containing the object's whose metadata is being retrieved.
     * @param key The key of the object whose metadata is being retrieved.
     * @return All Amazon S3 object metadata for the specified object.
     */
    public Map<String, String> getObjectMetadata(String bucketName, String key) {
        Map<String, String> objectMetadata = new Map<String, String>();
        HttpRequest request = createRequest(bucketName, key, HttpConstants.HttpMethod.XGET, endpoint);
        AWS4SignerForAuthorizationHeader signer = new AWS4SignerForAuthorizationHeader(
                new Url(request.getEndpoint()), HttpConstants.HttpMethod.XGET, 's3', clientRegion);

        Map<String, String> headers = new Map<String, String> {
                AWS4SignerBase.X_AMZ_CONTENT_SHA256 => AWS4SignerBase.UNSIGNED_PAYLOAD };
        // Get authorization header
        String authorization = signer.computeSignature(headers, null, AWS4SignerBase.UNSIGNED_PAYLOAD, credentials);

        headers.put(HttpConstants.HTTP_HEADER_AUTHORIZATION, authorization);
        // Use Range to download the specified range bytes of an object. Setting it up to 0 behaves pretty much
        // like HEAD does.
        // Salesforce doesn't properly handle HEAD request for non-existing bucket/key,
        // just throws a CalloutException instead of a 404 status code response.
        headers.put(HttpConstants.HTTP_HEADER_RANGE, 'bytes=0-0');
        populateRequestHeaders(request, headers);
        request.setCompressed(true);

        // Execute call out and get the object metadata response.
        HttpResponse response = new Http().send(request);

        // If we get back any 2xx status code, then we know we should treat the service call as successful.
        if (isRequestSuccessful(response)) {
            for (String headerKey : response.getHeaderKeys()) {
                objectMetadata.put(headerKey, response.getHeader(headerKey));
            }
            return objectMetadata;
        }

        handleErrorResponse(response, objectMetadata);

        return objectMetadata;
    }

    /**
     * Determines if we should treat the service call as successful.
     *
     * @param httpStatusCode The status code returned by a service call.
     * @return True if status code is any of the 2xx value.
     */
    private Boolean isRequestSuccessful(HttpResponse response) {
        return response.getStatusCode() / 100 == HttpConstants.STATUS_CODE_OK / 100;
    }

    private Boolean isObjectStorageGlacier(String storageClassName) {
        return storageClassName == 'InvalidObjectState';
    }

    private void handleErrorResponse(HttpResponse response, Map<String, String> objectMetadata) {
        AWSException.ServiceException awsException = new AWSException.ServiceException(
                response.getBodyDocument().getRootElement());

        if (isObjectStorageGlacier(awsException.code)) {
            objectMetadata.put('x-amz-storage-class', StorageClass.GLACIER.name());
        } else {
            throw awsException;
        }
    }

    /**
     * Uploads the specified file to Amazon S3 under the specified bucket and key name.
     * Using the file extension, Amazon S3 attempts to determine the correct content type and content disposition
     * to use for the object.
     * The specified bucket must already exist and the caller must have permission to the bucket to upload an object.
     *
     * @param bucketName path where you want to save the Amazon S3 file.
     * @param key The key under which to store the specified file.
     * @param file The file containing the data to be uploaded to Amazon S3.
     * @return An object containing the information returned by Amazon S3 for the newly created object.
     */
    public HttpResponse uploadObject(String bucketName, String key, Blob file) {
        return uploadObject(bucketName, key, file, new Map<String,String>());
    }

    /**
     * Uploads the specified file to Amazon S3 under the specified bucket and key name.
     * Using the file extension, Amazon S3 attempts to determine the correct content type and content disposition
     * to use for the object.
     * The specified bucket must already exist and the caller must have permission to the bucket to upload an object.
     *
     * @param bucketName path where you want to save the Amazon S3 file.
     * @param key file name.
     * @param file The file containing the data to be uploaded to Amazon S3.
     * @param metadata Additional metadata instructing Amazon S3 how to handle
     *        the uploaded data (e.g. custom user metadata, hooks for specifying content type, etc.).
     * @return The response of the call out when you send the file.
     */
    public HttpResponse uploadObject(String bucketName, String key, Blob file, Map<String, String> metadata) {
        HttpRequest request = createRequest(bucketName, key, HttpConstants.HttpMethod.XPUT, endpoint);
        AWS4SignerForAuthorizationHeader signer = new AWS4SignerForAuthorizationHeader(
                new Url(request.getEndpoint()), HttpConstants.HttpMethod.XPUT, 's3', clientRegion);

        // Precompute hash of the body content
        String contentHashString = EncodingUtil.convertToHex(AWS4SignerBase.hash(file));
        Map<String, String> headers = new Map<String, String> {
                AWS4SignerBase.X_AMZ_CONTENT_SHA256 => contentHashString,
                HttpConstants.HTTP_HEADER_CONTENT_LENGTH => '' + file.size() };
        for (String keyObject : metadata.keySet()) {
            headers.put(keyObject, metadata.get(keyObject));
        }
        // Get authorization header
        String authorization = signer.computeSignature(headers, null, contentHashString, credentials);

        headers.put(HttpConstants.HTTP_HEADER_AUTHORIZATION, authorization);
        populateRequestHeaders(request, headers);
        request.setBodyAsBlob(file);

        // Execute the call out and send the file.
        HttpResponse response = new Http().send(request);

        if (!isRequestSuccessful(response)) {
            handleErrorResponse(response, null);
        }

        return response;
    }

    /**
     * Returns a pre-signed URL for accessing an Amazon S3 resource.
     * Pre-signed URLs allow clients to form a URL for an Amazon S3 resource,
     * and then sign it with the current AWS security credentials.
     * The pre-signed URL can be shared to other users, allowing access to the resource without
     * providing an account's AWS security credentials.
     *
     * @param bucketName The name of the bucket containing the desired object.
     * @param key The key in the specified bucket under which the desired object is stored.
     * @return A pre-signed URL which expires at the specified time (5 minutes by default), and can be used to allow
     *         anyone to download the specified object from S3, without exposing the owner's AWS secret access key.
     */
    public String generatePresignedUrl(String bucketName, String key) {
        return generatePresignedUrl(bucketName, key, EXPIRE_SECONDS);
    }

    /**
     * Returns a pre-signed URL for accessing an Amazon S3 resource.
     * Pre-signed URLs allow clients to form a URL for an Amazon S3 resource,
     * and then sign it with the current AWS security credentials.
     * The pre-signed URL can be shared to other users, allowing access to the resource without
     * providing an account's AWS security credentials.
     *
     * @param bucketName The name of the bucket containing the desired object.
     * @param key The key in the specified bucket under which the desired object is stored.
     * @param expiration The time defined on seconds at which the returned pre-signed URL will expire.
     *        For SignatureV4, the max expiry for a presigned url is 7 days.
     * @return A pre-signed URL which expires at the specified time, and can be used to allow anyone
     *         to download the specified object from S3, without exposing the owner's AWS secret access key.
     */
    public String generatePresignedUrl(String bucketName, String key, Integer expiration) {
        Url endpointUrl = resolveRequestEndpoint(bucketName, key, endpoint);
        // Construct the query parameter string to accompany the url.
        Map<String, String> queryParams = new Map<String, String> {
                    AWS4SignerBase.X_AMZ_EXPIRES => '' + AWS4SignerBase.generateExpirationDate(expiration) };
        // We have no headers for this sample, but the signer will add 'host'
        Map<String, String> headers = new Map<String, String>();
        AWS4SignerForQueryParameterAuth signer = new AWS4SignerForQueryParameterAuth(endpointUrl,
                HttpConstants.HttpMethod.XGET, 's3', clientRegion);
        if (overriddenDate != null) {
            signer.setOverrideDate(overriddenDate);
        }
        String authorizationQueryParameters = signer.computeSignature(headers, queryParams,
                AWS4SignerBase.UNSIGNED_PAYLOAD, credentials);

        // Build the presigned url to incorporate the authorization elements as query parameters
        return endpointUrl.toExternalForm() + '?' + authorizationQueryParameters;
    }

    /**
     * Creates and initializes a new request for the specified S3 resource.
     * The returned request object has the endpoint and resource path correctly populated.
     * Callers can take the request, add any additional headers or parameters, then sign and execute the request.
     *
     * @param bucketName The name of the bucket containing the desired object.
     * @param key The key in the specified bucket under which the desired object is stored.
     * @param httpMethod The HTTP method to use when sending the request (PUT, GET, HEAD, etc).
     * @param endpoint Amazon S3 URL.
     * @return A new request object, populated with endpoint and resource path, ready for callers to populate
     *         any additional headers or parameters, and execute.
     */
    private HttpRequest createRequest(String bucketName, String key, HttpConstants.HttpMethod httpMethod, Url endpoint) {
        HttpRequest request = new HttpRequest();
        request.setMethod(httpMethod.name().removeStart('X'));
        request.setEndpoint(resolveRequestEndpoint(bucketName, key, endpoint).toExternalForm());
        return request;
    }

    /**
     * Configure the given request with all headers needed.
     *
     * @param request HttpRequest created.
     * @param headers Amazon headers used for the request.
     */
    private void populateRequestHeaders(HttpRequest request, Map<String, String> headers) {
        for (String headerKey : headers.keySet()) {
            request.setHeader(headerKey, headers.get(headerKey));
        }
    }

    /**
     * Returns an url with an endpoint and resource path based on the bucket name and key provided.
     *
     * @param bucketName The name of the bucket containing the desired object.
     * @param key The key in the specified bucket under which the desired object is stored.
     * @param endpoint The endpoint or the full URL, including the protocol.
     * @return The url with an endpoint and resource path.
     */
    private Url resolveRequestEndpoint(String bucketName, String key, Url endpoint) {
        String resourcePath = '/'
                + (String.isNotBlank(bucketName) ? bucketName + '/' : '')
                + (String.isNotBlank(key) ? key : '');
        return new Url(endpoint.toExternalForm() + resourcePath);
    }

    /**
     * Sets the date that overrides the signing date in the request.
     * This method is internal and should be used only for testing purposes.
     *
     * @param overrideDate date that we want to override
     */
    @TestVisible
    private void setOverrideDate(DateTime overriddenDate) {
        this.overriddenDate = overriddenDate;
    }

    /**
     * Gets the endpoint this client will communicate with.
     * This method is internal and should be used only for testing purposes.
     */
    @TestVisible
    private Url getEndpoint() {
        return this.endpoint;
    }

    /**
     * Gets region-specific AWS endpoint.
     * This method is internal and should be used only for testing purposes.
     */
    @TestVisible
    private String getRegion() {
        return this.clientRegion;
    }

}