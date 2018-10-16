public with sharing class AppsWithSubmissionByStatusController {
	
    @AuraEnabled
    // Get the apps with submission date and the status in parameter in the last 5 years.
    public static Map<Integer, Integer> getStatusInLastFiveYears(String status, Id acc) {
        Map<Integer, Integer> result = new Map<Integer, Integer>();
        Datetime now = Datetime.now();
        Integer thisYear = now.year();
        Integer amountMonths = 12 * 5;
        Datetime last5YearsDate = now.addMonths(-1 * amountMonths);
        
        // Set initial values to map.
        result.put(thisYear, 0);
        for (Integer i = 1; i <= 5; i++) {
            result.put(thisYear - i, 0);
        }

        try {
            List<Application__c> apps = [
                SELECT Id, Application_Submission_Date__c
                FROM Application__c WHERE Application_Submission_Date__c != null
                    AND Status__c =: status
                    AND Application_Submission_Date__c >=: last5YearsDate 
                    AND Application_Submission_Date__c <=: now AND Contractor__c =: acc
                ];
            for (Application__c app : apps) {
                for (Integer key : result.keySet()) {
                    if (key == app.Application_Submission_Date__c.year()) {
                        result.put(key, result.get(key) + 1);
                    }
                }
            }
        } catch (QueryException e) {
            System.debug('query exception none accounts by name');
        } catch (Exception e) {
            System.debug('generic exception none accounts by name');
        }
        return result;
    }

}