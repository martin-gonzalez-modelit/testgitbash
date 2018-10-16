/**
 * This controller handles Application File object
 *
 * @author Ian Ray Lopez <ilopez@jway.com>
 * @since 2016-01
 */
public with sharing class ApplicationFileController {

    @AuraEnabled
    public static Application_File__c getApplicationFile(String Id) {
        return [SELECT Id, File_Name__c, JSON__c FROM Application_File__c WHERE Id =: Id LIMIT 1];
    }

}