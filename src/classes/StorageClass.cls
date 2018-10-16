/**
 * Specifies constants that define Amazon S3 storage classes. The standard storage class is the default storage class.
 * Amazon S3 offers multiple storage classes for different customers' needs.
 * The STANDARD storage class is the default storage class, and means that redundant copies of data will be
 * stored in different locations.
 * The REDUCED_REDUNDANCY storage class offers customers who are using Amazon S3 for storing non-critical,
 * reproducible data a low-cost highly available, but less redundant, storage option.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
public enum StorageClass {

    /**
     * The default Amazon S3 storage class. This storage class is recommended for critical, non-reproducible data.
     * The standard storage class is a highly available and highly redundant storage option provided
     * for an affordable price.
     */
    STANDARD,

    /**
     * Standard Infrequent Access storage class
     */
    STANDARD_IA,

    /**
     * The reduced redundancy storage class.
     * This storage class allows customers to reduce their storage costs in return for a
     * reduced level of data redundancy. Customers who are using Amazon S3 for storing non-critical,
     * reproducible data can choose this low cost and highly available, but less redundant, storage option.
     */
    REDUCED_REDUNDANCY,

     /**
     * The Amazon Glacier storage class.
     * This storage class means your object's data is stored in Amazon Glacier, and Amazon S3 stores a reference
     * to the data in the Amazon S3 bucket.
     */
    GLACIER
}