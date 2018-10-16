/**
 * This controller handles Application File uploaded to Amazon S3.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
public with sharing class ApplicationFileS3Controller {

    private Application_File__c appFile;
    private Amazon_AWS_Config__c amazonConfig;
    public String url {get; set;}

    /**
     * Initializes the private member variable appFile by using the getRecord method from the standard controller.
     */
    public ApplicationFileS3Controller(ApexPages.StandardController stdController) {
        stdController.addFields(new List<String> { 'S3_File_Name__c', 'S3_Uploaded__c' });
        amazonConfig = Amazon_AWS_Config__c.getInstance('BIG-PGE-S3-BUCKET');
        appFile = (Application_File__c)stdController.getRecord();
    }

    /**
     * Downloads the file from Amazon S3 if it's available (e.g. Storage Class STANDARD_IA).
     * If the file has been moved to GLACIER or was not uploaded to Amazon S3, display a message according to
     * the file's state.
     */
    public void checkAmazonS3File() {
        ApexPages.Message message;

        if (appFile.S3_Uploaded__c) {
            S3Manager s3Manager = new S3Manager(amazonConfig.Access_Key__c, amazonConfig.Secret_Key__c);
            s3Manager.setEndpoint(amazonConfig.Endpoint__c);
            String fileExtension = BIGFileUtils.getFileExtension(appFile.S3_File_Name__c);
            String s3fileName = appFile.Id + '.' + fileExtension;

            try {
                Map<String, String> objectMetadata = s3Manager.getObjectMetadata(
                        amazonConfig.Bucket_Name__c, appFile.S3_File_Name__c);

                if (objectMetadata.get('x-amz-storage-class') != StorageClass.GLACIER.name()) {
                    url = s3Manager.generatePresignedUrl(amazonConfig.Bucket_Name__c, appFile.S3_File_Name__c);
                    message = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Your request is being processed.');
                } else {
                    String msg =
                            + 'The file you\'ve requested is currently archived in long-term, glacier storage. '
                            + 'Please email <a href="mailto:system.support@builditgreen.org">System Support</a>, '
                            + 'providing the Application File System No.(s), '
                            + 'to request temporary restoration to standard storage for access. Once initiated, '
                            + 'restoration takes between 3-5 hours to complete (5-12 for bulk requests).';
                    message = new ApexPages.Message(ApexPages.Severity.INFO, msg);
                }
            } catch (AWSException.ServiceException e) {
                message = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            } catch (Exception e) {
                System.debug('####### getStackTraceString: ' + e.getStackTraceString());
                System.debug('####### getCause: ' + e.getCause());
                message = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            }
        } else {
            message = new ApexPages.Message(ApexPages.Severity.ERROR, 'This file was not uploaded to Amazon S3 yet.');
        }

        ApexPages.addMessage(message);
    }

}