public with sharing class ApssWithSubmissionInYearController {
    @AuraEnabled
    public static Map<String, Integer> getAppsWithSubmissionInYear(Integer year, Id acc) {
        Map<String, Integer> result = new Map<String, Integer>();
        List<Application__c> apps = [
            SELECT Status__c, Application_Submission_Date__c FROM Application__c 
            WHERE Contractor__c =: acc 
                AND Status__c != NULL AND Application_Submission_Date__c != NULL
        ];
        for (Application__c app : apps) {
            Datetime dt = app.Application_Submission_Date__c;
            if (year == dt.year()) {
                if (!result.containsKey(app.Status__c)) {
                    result.put(app.Status__c, 1);
                } else {
                    result.put(app.Status__c, result.get(app.Status__c) + 1);
                }
            }
        }
        return result;
    }
}