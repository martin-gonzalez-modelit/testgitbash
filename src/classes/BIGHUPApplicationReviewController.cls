/**
 * This class manages desktop review operations for HU.
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2014-04
 */
public with sharing class BIGHUPApplicationReviewController {

    public Boolean hasComments { get; set; }
    public Boolean hasIssues { get; set; }
    private Review__c review;

    public BIGHUPApplicationReviewController() {
        review = getReview();
        hasIssues = String.isNotBlank(review.Comments__c);
        hasComments = String.isNotBlank(review.Additional_Comments__c);
    }

    public void checkAction() {
        if (review.Status__c == 'Application Approved') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                    'HUP Application Form has been approved.'));
        } else if (review.Status__c == 'Application Rejected') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                    'HUP Application Form has been rejected.'));
        } else if (review.Status__c == 'Contractor Action Required') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                    'HUP Application Form has been marked as Contractor Action Required.'));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                    'HUP Application Form has been saved successfully.'));
        }
    }

    public Boolean getHasError() {
        return ApexPages.hasMessages(ApexPages.Severity.ERROR);
    }

    public Application__c getApplication() {
        String appId = System.currentPageReference().getParameters().get('id');
        Application__c app = new Application__c();

        if (String.isNotBlank(appId)) {
            try {
                app = [SELECT Id, Name, Contractor__c, Status__c FROM Application__c WHERE Id = :appId];
            } catch (QueryException e) {
                System.debug('Couldn\'t find the application. Error: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        'Application record does not exist.'));
            }
        }
        return app;
    }

    public Review__c getReview() {
        String appId = System.currentPageReference().getParameters().get('id');

        List<Review__c> reviews = [
            SELECT Id, Status__c, Comments__c, Additional_Comments__c
            FROM Review__c
            WHERE Application__c = :appId
            ORDER BY CreatedDate DESC LIMIT 1
            ];

        return (!reviews.isEmpty() ? reviews.get(0) : new Review__c());
    }

    public List<HUP_Review_Message__c> getReviewMessages() {
        return [SELECT Field__c, Message__c FROM HUP_Review_Message__c];
    }

    public List<Contact> getRaters() {
        Application__c app = getApplication();
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Rater').getRecordTypeId();

        return [
            SELECT Name, Email
            FROM Contact
            WHERE RecordTypeId = :recordTypeId
                AND AccountId IN (SELECT AccountToId FROM Partner WHERE AccountFromId = :app.Contractor__c)
            ORDER BY Name
            ];
    }
}