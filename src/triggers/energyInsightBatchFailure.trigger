trigger energyInsightBatchFailure on BatchApexErrorEvent (after insert) {
    System.debug('cacho en batchapexerrorevent');
	Set<Id> asyncApexJobIds = new Set<Id>();

    for (BatchApexErrorEvent batchApexErrorEvent : Trigger.new) {
        asyncApexJobIds.add(batchApexErrorEvent.AsyncApexJobId);
    } 

    Map<Id,AsyncApexJob> jobs = new Map<Id,AsyncApexJob>([
        SELECT id, ApexClass.Name
        FROM AsyncApexJob
        WHERE Id IN :asyncApexJobIds]);
System.debug(jobs);
    for (BatchApexErrorEvent batchApexErrorEvent : Trigger.new) {
        System.debug(batchApexErrorEvent);
        if (jobs.get(batchApexErrorEvent.AsyncApexJobId).ApexClass.Name == 'RebateApplicationsEnergyInsightBatch') {
    		List<Rebate_Application__c> rebateApplication = new List<Rebate_Application__c>();

            for (String item : batchApexErrorEvent.JobScope.split(',')) {
                System.debug('error cacho ' + item);
            }
        }
    }
}