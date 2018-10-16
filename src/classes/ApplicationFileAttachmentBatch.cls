/**
 * This class handles the batch process to send attachments to Amazon S3.
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2016-06
 */
public class ApplicationFileAttachmentBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,
        Database.Stateful, Database.RaisesPlatformEvents {
    // Default values
    /** The maximum size (12 MB) of the file in bytes. */
    public static final Integer MAX_BODY_LENGTH = 12582912;

    /**
     * The number of records to process. Use a lower limit since there are many operations for each record being
     * passed in and are running into governor limits.
     */
    public static final Integer BATCH_SIZE = 1;

    /** The number of days an Application has been in it's current status. */
    public static final Integer DELAY_PERIOD = 0;

    // Private attributes
    private Amazon_AWS_Config__c amazonConfig;
    private S3Manager s3Manager;
    private ErrorHandlingUtil errorLog;
    // To create hyperlink to record
    private String baseURL;
    private Integer maxBodyLength;
    private Integer delayPeriod;
    // Set of items for summary email
    private Set<String> applicationFilesFailOnProcess;
    private Set<String> applicationFilesFailOnCallout;
    private Set<String> applicationFilesFailOnDML;

    // Counters
    private Integer attachmentCount;
    private Integer attachmentErrorCount;
    private Integer calloutCount;
    private Integer calloutErrorCount;
    private Integer dmlCount;
    private Integer dmlErrorCount;

    /**
     * Constructor taking parameter for maximum attachment body length to process and initialize variables.
     *
     * @param maxBodyLength Maximum attachment body length to process.
     */
    public ApplicationFileAttachmentBatch(Integer maxBodyLength, Integer delayPeriod) {
        amazonConfig = Amazon_AWS_Config__c.getInstance('BIG-PGE-S3-BUCKET');
        s3Manager = new S3Manager(amazonConfig.Access_Key__c, amazonConfig.Secret_Key__c);
        s3Manager.setEndpoint(amazonConfig.Endpoint__c);
        errorLog = ErrorHandlingUtil.getInstance();
        baseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        this.maxBodyLength = maxBodyLength;
        this.delayPeriod = delayPeriod;
        applicationFilesFailOnProcess = new Set<String>();
        applicationFilesFailOnCallout = new Set<String>();
        applicationFilesFailOnDML = new Set<String>();
        // Attachments count
        attachmentCount = 0;
        attachmentErrorCount = 0;
        // Callout count
        calloutCount= 0;
        calloutErrorCount = 0;
        // DML count
        dmlCount= 0;
        dmlErrorCount = 0;
    }

    public class myException extends Exception {}

    /**
     * Collect Attachment records to pass them to execute method.
     *
     * @param BC A reference to the Database.BatchableContext object.
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        /*
         * Sum 1 to delayPeriod: today() returns the current date with the time component to 00:00:00,
         * it means if an application change its status today, it won't be sent
         * due the time component of Last_Status_Change_Date_Time__c won't match.
         * Example: 01/01/2017 14:00:00 <= 01/01/2017 00:00:00
         */
        Datetime delayDate = Date.today().addDays(-delayPeriod + 1);
        Set<String> appFileIdsToExclude = new Set<String>();

        // Get latest Home_Performance_System_File__c, Home_Performance_XML__c from Sub_Application__c
        // to prevent upload them to S3 later.
        for (Sub_Application__c subApplication : [
                SELECT Home_Performance_System_File__c, Home_Performance_XML__c
                FROM Sub_Application__c
                WHERE RecordType.Name = 'POST-APP'
                    AND Application__r.Last_Status_Change_Date_Time__c <= :delayDate
                    AND (Home_Performance_System_File__c != null OR Home_Performance_XML__c != null)
                    AND (Application__r.Status__c = :ApplicationUtils.REBATE_ISSUED_STATUS
                        OR Application__r.Status__c = :ApplicationUtils.CANCELED_STATUS
                        OR Application__r.Status__c = :ApplicationUtils.REJECTED_STATUS)
                ]) {

            if (String.isNotEmpty(subApplication.Home_Performance_System_File__c)) {
                appFileIdsToExclude.add(subApplication.Home_Performance_System_File__c);
            }
            if (String.isNotEmpty(subApplication.Home_Performance_XML__c)) {
                appFileIdsToExclude.add(subApplication.Home_Performance_XML__c);
            }
        }

        return Database.getQueryLocator(''
                + 'SELECT Id, Name, Body, ParentId '
                + 'FROM Attachment '
                + 'WHERE ParentId IN ('
                    + 'SELECT Id '
                    + 'FROM Application_File__c '
                    + 'WHERE Application__r.Last_Status_Change_Date_Time__c <= :delayDate '
                        + 'AND (Application__r.Status__c = \'' + ApplicationUtils.REBATE_ISSUED_STATUS + '\' '
                        + 'OR Application__r.Status__c = \'' + ApplicationUtils.CANCELED_STATUS + '\' '
                        + 'OR Application__r.Status__c = \'' + ApplicationUtils.REJECTED_STATUS + '\') '
                        + 'AND S3_Uploaded__c = false '
                        + 'AND Id NOT IN :appFileIdsToExclude'
                + ') '
                + 'AND BodyLength <= ' + maxBodyLength);
    }

    /**
     * Start the processing for each block of data get it from Start method.
     *
     * @param BC A reference to the Database.BatchableContext object.
     * @param attachments List of records get it from Start method.
     */
    public void execute(Database.BatchableContext BC, List<Attachment> attachments) {
        if (true) {
            throw new myException('cachoexceptionl lalalala');
        }
        List<Attachment> attachmentsToDelete = new List<Attachment>();
        List<Application_File__c> applicationFilesToUpdate = new List<Application_File__c>();
        Set<Id> applicationFileIds = new Set<Id>();
        Map<Id, Application_File__c> applicationFilesById;

        for (Attachment att : attachments) {
            applicationFileIds.add(att.ParentId);
        }

        /*
         * Get the application files and their attachments to prevent processing application files
         * with more than one attachment.
         */
        applicationFilesById = new Map<Id, Application_File__c>([
            SELECT Id, (SELECT Id FROM Attachments)
            FROM Application_File__c
            WHERE Id IN :applicationFileIds]);

        // Upload each attachment to the Amazon S3 bucket
        attachmentCount += attachments.size();
        applicationFileIds = new Set<Id>();

        for (Attachment attachment : attachments) {
            if (applicationFilesById.get(attachment.ParentId).Attachments.Size() == 1) {
                String fileExtension = BIGFileUtils.getFileExtension(attachment.Name);

                if (attachment.Body == null || String.isEmpty(fileExtension)) {
                    attachmentErrorCount++;
                    applicationFilesFailOnProcess.add('<li>' + baseURL + attachment.ParentId + '</li>');
                } else {
                    calloutCount++;
                    String s3fileName = attachment.ParentId + '.' + fileExtension;
                    // Set MD5 with a Digest
                    Blob hash = Crypto.generateDigest('MD5', attachment.Body);

                    // Execute web service call and send the attachment
                    try {
                        HttpResponse response = s3Manager.uploadObject(
                                amazonConfig.Bucket_Name__c,
                                s3fileName,
                                attachment.Body,
                                new Map<String, String> {
                                    'x-amz-storage-class' => StorageClass.STANDARD_IA.name(),
                                    HttpConstants.HTTP_HEADER_CONTENT_MD5 => EncodingUtil.base64Encode(hash)
                                });
                        // Attachment uploaded successfully, add it to list to delete and update parent
                        attachmentsToDelete.add(attachment);
                        // Create an Application File with the Id = ParentId of attachment and set fields
                        applicationFilesToUpdate.add(new Application_File__c(
                                Id = attachment.ParentId,
                                S3_Uploaded__c = true,
                                S3_File_Name__c = s3fileName));
                    } catch (Exception e) {
                        calloutErrorCount++;
                        applicationFilesFailOnCallout.add('<li>' + baseURL + attachment.ParentId + '</li>');
                        System.debug('Exception type caught: ' + e.getTypeName() + ' on ' + s3fileName);
                        System.debug('Message: ' + e.getMessage());
                        System.debug('Stack trace: ' + e.getStackTraceString());
                        errorLog.logDebug(
                                'ApplicationFileAttachmentBatch',
                                'Execute',
                                'An exception on callout code block has occurred: ' + e.getMessage(),
                                attachment.ParentId);
                    }
                }
            } else {
                attachmentErrorCount++;
                applicationFileIds.add(attachment.ParentId);
            }
        }

        // Loop applicationFileIds that has multiple attachments and add them to error message.
        for (Id appFileId : applicationFileIds) {
            applicationFilesFailOnProcess.add('<li>' + baseURL + appFileId + '</li>');
        }

        dmlCount += applicationFilesToUpdate.size();
        Savepoint sp = Database.setSavepoint();
        Database.SaveResult[] saveResultList;
        Database.DeleteResult[] deleteResultList;

        try {
            saveResultList = Database.update(applicationFilesToUpdate);
            deleteResultList = Database.delete(attachmentsToDelete);
        } catch (DMLException e) {
            Database.rollback(sp);

            for (Application_File__c appFile : applicationFilesToUpdate) {
                applicationFilesFailOnDML.add('<li>' + baseURL + appFile.Id + '</li>');
                dmlErrorCount++;
            }
            System.debug('Message: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            errorLog.processDMLResults(saveResultList);
            errorLog.processDMLResults(deleteResultList);
        }

    }

    /**
     * Define and send summary email about batch processed.
     *
     * @param BC A reference to the Database.BatchableContext object.
     */
    public void finish(Database.BatchableContext BC) {
        Email_Settings__c emailSettings = Email_Settings__c.getInstance('ApplicationFileAttachmentBatch');

        if (emailSettings != null) {
            AsyncApexJob apexJob;
            String apexJobSummary = '';

            // Get AsyncApexJob information to show on email
            try {
                apexJob = [
                        SELECT Id, JobType, MethodName, CreatedDate, CompletedDate, Status, ExtendedStatus,
                            NumberOfErrors, JobItemsProcessed, TotalJobItems
                        FROM AsyncApexJob
                        WHERE Id =: BC.getJobId()
                        ];
            } catch (QueryException e) {
                System.debug('Message: ' + e.getMessage());
                errorLog.logDebug(
                        'ApplicationFileAttachmentBatch',
                        'Finish',
                        'A query exception has occurred: ' + e.getMessage(),
                        '');
            }

            if (apexJob != null) {
                // Assign Apex Job summary to apexJobSummary
                apexJobSummary = ''
                        + '<h3>Async Apex Job Results</h3>'
                        + '<ul>'
                        + '    <li>Id: ' + apexJob.Id + '</li>'
                        + '    <li>Job Type: ' + apexJob.JobType + '</li>'
                        + '    <li>Method Name: ' + apexJob.MethodName + '</li>'
                        + '    <li>Created Date: ' + apexJob.CreatedDate + '</li>'
                        + '    <li>Completed Date: ' + apexJob.CompletedDate + '</li>'
                        + '    <li>Status: ' + apexJob.Status + '</li>'
                        + '    <li>Extended Status: ' + apexJob.ExtendedStatus + '</li>'
                        + '    <li>Total Batches: ' + apexJob.TotalJobItems + '</li>'
                        + '    <li>Batches Processed: ' + apexJob.JobItemsProcessed + '</li>'
                        + '    <li>Failures: ' + apexJob.NumberOfErrors + '</li>'
                        + '</ul>';
            }

            // If there are Attachments processed set values else set to 0
            Integer successAttachment = attachmentCount - attachmentErrorCount;
            Decimal percentageAttachmentSuccess = 0;
            Decimal percentageAttachmentErrors = 0;
            if (attachmentCount != 0) {
                percentageAttachmentSuccess = ((successAttachment * 100.0) / attachmentCount).setScale(2,
                        System.RoundingMode.HALF_UP);
                percentageAttachmentErrors = 100 - percentageAttachmentSuccess;
            }
            // If there are Attachments processed to Amazon set values else set to 0
            Integer successCallOut = calloutCount - calloutErrorCount;
            Decimal percentageCallOutSuccess = 0;
            Decimal percentageCallOutErrors = 0;
            if (calloutCount != 0) {
                percentageCallOutSuccess = ((successCallOut * 100.0) / calloutCount).setScale(2,
                        System.RoundingMode.HALF_UP);
                percentageCallOutErrors = 100 - percentageCallOutSuccess;
            }
            // If there are Application Files processed set values else set to 0
            Integer successDML = dmlCount - dmlErrorCount;
            Decimal percentageDMLSuccess = 0;
            Decimal percentageDMLErrors = 0;
            if (dmlCount != 0) {
                percentageDMLSuccess = ((successDML * 100.0) / dmlCount).setScale(2, System.RoundingMode.HALF_UP);
                percentageDMLErrors = 100 - percentageDMLSuccess;
            }

            // Set email settings
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emailSettings.Email_To__c.split(';'));
            mail.setOrgWideEmailAddressId(emailSettings.OrgWideEmailAddressId__c);
            mail.setSubject(emailSettings.Email_Subject__c);

            /*
             * Enumerate section e-mail: Async Apex Job Results, Callouts (Attachments Uploaded to S3)
             * and DML Operations (Attachments Deleted,  Application Files Updated).
             */
            mail.setHtmlBody(apexJobSummary
                    + '<hr><h3>Summary</h3><h4>Attachment Processing</h4>'
                    + '<ul>'
                    + '    <li>Successes: ' + successAttachment + '/' + attachmentCount + '(' + percentageAttachmentSuccess + '%)</li>'
                    + '    <li>Failures: ' + attachmentErrorCount + '/' + attachmentCount + '(' + percentageAttachmentErrors + '%)'
                    + '        <ol>' + String.join(new List<String>(applicationFilesFailOnProcess), '')+ '</ol>'
                    + '    </li>'
                    + '</ul>'
                    + '<h4>Callouts (Attachments Uploaded to S3)</h4>'
                    + '<ul>'
                    + '    <li>Successes: ' + successCallOut + '/' + calloutCount + ' (' + percentageCallOutSuccess + '%)</li>'
                    + '    <li>Failures: ' + calloutErrorCount + '/' + calloutCount + ' (' + percentageCallOutErrors + '%)'
                    + '        <ol>' + String.join(new List<String>(applicationFilesFailOnCallout), '') + '</ol>'
                    + '    </li>'
                    + '</ul>'
                    + '<h4>DML Operations (Attachments Deleted, Application Files Updated)</h4>'
                    + '<ul>'
                    + '    <li>Successes: ' + successDML + '/' + dmlCount + '(' + percentageDMLSuccess + '%)</li>'
                    + '    <li>Failures: ' + dmlErrorCount + '/' + dmlCount + '(' + percentageDMLErrors + '%)'
                    + '        <ol>' + String.join(new List<String>(applicationFilesFailOnDML), '') + '</ol>'
                    + '    </li>'
                    + '</ul>');

            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } catch (EmailException e) {
                System.debug('Couldn\'t sent email: ' + e.getMessage());
                errorLog.logDebug(
                        'ApplicationFileAttachmentBatch',
                        'Finish',
                        'An email exception has occurred: ' + e.getMessage(),
                        '');
            }
        }

        // Insert errors into database.
        errorLog.logMessage();
    }

}