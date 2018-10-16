/**
 * This class handles the schedule ApplicationFileAttachmentBatch class to send attachments to Amazon S3
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2016-06
 */
 global class ScheduledApplicationFileAttachmentBatch implements Schedulable {
    global void execute(SchedulableContext sc) {
        Batch_Settings__c batchSettings = Batch_Settings__c.getInstance('ApplicationFileAttachmentBatch');
        Integer maxBodyLength = ApplicationFileAttachmentBatch.MAX_BODY_LENGTH;
        Integer batchSize = ApplicationFileAttachmentBatch.BATCH_SIZE;
        Integer delayPeriod = ApplicationFileAttachmentBatch.DELAY_PERIOD;

        if (batchSettings != null) {
            // If Max Body Length is between 0 and 2MB assign custom setting value, else assign a default from batch class
            if (batchSettings.Max_Body_Length__c >= 0 && batchSettings.Max_Body_Length__c <= maxBodyLength) {
                maxBodyLength = Integer.valueOf(batchSettings.Max_Body_Length__c);
            }
            // If Batch Size is between 0 and 101 assign custom setting value, else assign a default from batch class
            if (batchSettings.Batch_Size__c > 0 && batchSettings.Batch_Size__c <= 100) {
                batchSize = Integer.valueOf(batchSettings.Batch_Size__c);
            }
            // If Delay Period is greater than 0, assign the custom setting value, else just leave 0 as default value.
            if (batchSettings.Delay_Period__c > 0) {
                delayPeriod = Integer.valueOf(batchSettings.Delay_Period__c);
            }
        }

        // Execute batch
        Database.executeBatch(new ApplicationFileAttachmentBatch(maxBodyLength, delayPeriod), batchSize);
    }
}