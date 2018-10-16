@isTest
private class AHUDesktopReviewConfirmControllerTest {
	
    @isTest static void testInit() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
		RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
		Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
		insert subApp;
		RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];
		Review__c review = new Review__c(application__c = app.id, sub_application__c = subApp.id, recordTypeId = reviewRt.id, status__c = 'Under Review');
		insert review;

		Test.startTest();
		Test.setCurrentPage(Page.AHUDesktopReviewConfirmation);
		ApexPages.currentPage().getParameters().put('appId', app.id);
		ApexPages.currentPage().getParameters().put('reviewId', review.id);
		AHUDesktopReviewConfirmationController con = new AHUDesktopReviewConfirmationController();

		con.review.status__c = 'Approved';
		con.checkAction();
		con.review.status__c = 'Rejected';
		con.checkAction();
		con.review.status__c = 'Contractor Action Required';
		con.checkAction();
		con.review.status__c = 'Other';
		con.checkAction();

		Test.stopTest();

	}
	
}