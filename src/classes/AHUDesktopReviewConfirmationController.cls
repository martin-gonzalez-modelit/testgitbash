public class AHUDesktopReviewConfirmationController {
    
    public Application__c app {get; set;}
    public Review__c review {get; set;}
    
    public AHUDesktopReviewConfirmationController() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String appId = params.get('appId');
        String reviewId = params.get('reviewId');
        
        app = [
            SELECT Id, Name
            FROM Application__c
            WHERE Id = :appId
        ];
        
        review = [
            SELECT Id, Comments__c, Additional_Comments__c, Status__c
            FROM Review__c
            WHERE Id = :reviewId
        ];
    }
    
    public void checkAction(){
        if(review.Status__c == 'Approved'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rebate Application Form has been approved.'));
        }else if(review.Status__c == 'Rejected'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rebate Application Form has been rejected.'));
        }else if(review.Status__c == 'Contractor Action Required'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rebate Application Form has been marked as Contractor Action Required.'));
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rebate Application Form has been saved successfully.'));
        }
    }

}