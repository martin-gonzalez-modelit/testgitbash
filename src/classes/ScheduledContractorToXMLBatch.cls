/**
 * This class sets the schedule for batch process for
 * creating Contractor Resources XML.
 *
 * @author Pablo Vigil  pablo.vigil@modelitsoftware.com
 * @since 2014-04
 */
global class ScheduledContractorToXMLBatch implements Schedulable {

    // For testing purposes. Runs a scheduled job at midnight Sept. 3rd. 2022.
    public static String CRON_EXP = '0 0 0 3 9 ? 2022';

    global void execute(SchedulableContext sc) {
        // Execute ContractorToXmlBatch
        ContractorToXMLBatch xmlBatch = new ContractorToXMLBatch();
        Database.executeBatch(xmlBatch);
    }
}