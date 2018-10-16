/**
 * This class handles the schedule RebateApplicationsEnergyInsightBatch class to retrieve data from Energy Insight org
 * and populate in our system.
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2017-08
 */
public class ScheduledRebateApplicationsEIBatch implements Schedulable {
    public void execute(SchedulableContext sc) {
        Batch_Settings__c batchSettings = Batch_Settings__c.getInstance('RebateApplicationsEnergyInsightBatch');
        Integer batchSize = RebateApplicationsEnergyInsightBatch.BATCH_SIZE;

        if (batchSettings != null) {
            // If Batch Size is between 0 and 101 assign custom setting value
            if (batchSettings.Batch_Size__c > 0 && batchSettings.Batch_Size__c <= 150) {
                batchSize = Integer.valueOf(batchSettings.Batch_Size__c);
            }
        }

        // Execute batch
        Database.executeBatch(new RebateApplicationsEnergyInsightBatch(), batchSize);
    }
}