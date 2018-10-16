/**
 * Basic implementation of the AWSCredentials interface that allows callers to
 * pass in the AWS access key and secret access in the constructor.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-9
 */
public without sharing class BasicAWSCredentials implements AWSCredentials {

    private final String accessKey;
    private final String secretKey;

    /**
     * Constructs a new BasicAWSCredentials object, with the specified AWS access key and AWS secret key.
     *
     * @param accessKey The AWS access key.
     * @param secretKey The AWS secret access key.
     */
    public BasicAWSCredentials(String accessKey, String secretKey) {
        if (String.isBlank(accessKey)) {
            throw new AWSException.IllegalArgumentException('Access key cannot be null.');
        }
        if (String.isBlank(secretKey)) {
            throw new AWSException.IllegalArgumentException('Secret key cannot be null.');
        }

        this.accessKey = accessKey;
        this.secretKey = secretKey;
    }

    /**
     * Returns the AWS access key ID for this credentials object.
     *
     * @return The AWS access key ID for this credentials object.
     */
    public String getAWSAccessKeyId() {
        return accessKey;
    }

    /**
     * Returns the AWS secret access key for this credentials object.
     *
     * @return The AWS secret access key for this credentials object.
     */
    public String getAWSSecretKey() {
        return secretKey;
    }

}