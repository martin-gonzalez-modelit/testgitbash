public without sharing class ACQCRebateApplicationService {

    public static List<Application_Note__c> getNotes(String appId) {
        List<Application_Note__c> result = new List<Application_Note__c>();
        if (appId != null) {
             for (Application_Note__c an : [
                    SELECT Note__c, Additional_Comments_Note__c, CreatedDate, CreatedBy.Name 
                    FROM Application_Note__c 
                    WHERE Application__c=:appId AND Public__c =: true order by CreatedDate desc]) {
                result.add(an);
             }
        } 
        
        return result;
    }
}