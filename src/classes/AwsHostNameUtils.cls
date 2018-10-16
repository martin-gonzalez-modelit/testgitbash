/**
 * Helper class for amazon services host.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
public without sharing class AwsHostNameUtils {

    /**
     * Parse the full URL, and takes the AWS region part of it.
     *
     * @param endpoint The full URL, including the protocol, of the region-specific AWS endpoint.
     * @return An AWS region as a string (e.g. us-east-1, us-west-1, eu-west-2, etc.).
     */
    public static String parseRegionName(Url endpoint) {
        return parseRegionName(endpoint.getHost());
    }

    /**
     * Parse the AWS domain, and takes the AWS region part of it.
     *
     * @param host The AWS endpoint.
     * @return An AWS region as a string (e.g. us-east-1, us-west-1, eu-west-2, etc.).
     */
    public static String parseRegionName(String host) {
        String serviceAndRegion = host.substring(0, host.indexOf('.amazonaws.com'));
        String separator = '.';

        // If we don't recognize the domain, just return the default
        if (!host.endsWith('.amazonaws.com')) {
            return 'us-east-1';
        }

        if (serviceAndRegion.startsWith('s3')) {
            separator = '-';
        }

        if (!serviceAndRegion.contains(separator)) {
            return 'us-east-1';
        }

        String region = serviceAndRegion.substring(serviceAndRegion.indexOf(separator) + 1);

        if ('us-gov'.equals(region)) {
            return 'us-gov-west-1';
        }

        return region;
    }

    /**
     * Prefixes the protocol if the endpoint given does not have it.
     *
     * @param endpoint The AWS endpoint.
     * @return A full URL including the protocol in case it was missing.
     */
    public static Url toUri(String endpoint) {
        // If the endpoint doesn't explicitly specify a protocol to use, then we'll defer to the default 'https'.
        if (!endpoint.contains('://')) {
            endpoint = 'https://' + endpoint;
        }

        return new Url(endpoint);
    }
}