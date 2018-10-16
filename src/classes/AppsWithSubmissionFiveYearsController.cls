public with sharing class AppsWithSubmissionFiveYearsController {
    @AuraEnabled
    // Method to get the picklist values from Schema
    public static Map<Integer, Integer> getAppsInLastFiveYears(String acc) {
        Map<Integer, Integer> result = new Map<Integer, Integer>();
        Datetime now = Datetime.now();
        Integer thisYear = now.year();
        List<Integer> years = new List<Integer>();
        Integer amountMonths = 12 * 5;

        years.add(thisYear);
        result.put(thisYear, 0);
        for (Integer i = 1; i <= 5; i++) {
            Integer year = thisYear - i;
            years.add(year);
            result.put(year, 0);
        }
        
        Datetime last5YearsDate = now.addMonths(-1*amountMonths);
        try {
            List<Application__c> apps = [
                SELECT Application_Submission_Date__c 
                FROM Application__c WHERE Application_Submission_Date__c != null 
                    AND Application_Submission_Date__c >=: last5YearsDate 
                    AND Application_Submission_Date__c <=: now AND Contractor__c =: acc
                ];

            for (Application__c app : apps) {
                for (Integer i = 0; i < years.size(); i++) {
                    Integer year = years.get(i);
                    if (year == app.Application_Submission_Date__c.year()) {
                        if (result.containsKey(year)) {
                            result.put(year, result.get(year) + 1);
                        }
                    }
                }
            }
        } catch (QueryException e) {
            System.debug('query exception none apps by year');
        } catch (Exception e) {
            System.debug('generic exception none apps by name');
        }
        return result;
    }

}