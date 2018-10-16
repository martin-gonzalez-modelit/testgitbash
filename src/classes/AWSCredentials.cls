/**
 * Provides access to the AWS credentials used for accessing AWS services: AWS access key ID and secret access key.
 * These credentials are used to securely sign requests to AWS services.
 * A basic implementation of this interface is provided in {@link BasicAWSCredentials}, but callers are free
 * to provide their own implementation, for example, to load AWS credentials from an encrypted file.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-9
 */
public interface AWSCredentials {

    /**
     * Returns the AWS access key ID for this credentials object.
     *
     * @return The AWS access key ID for this credentials object.
     */
    String getAWSAccessKeyId();

    /**
     * Returns the AWS secret access key for this credentials object.
     *
     * @return The AWS secret access key for this credentials object.
     */
    String getAWSSecretKey();

}