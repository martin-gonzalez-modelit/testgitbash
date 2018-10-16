@isTest
private class AHUDesktopReviewControllerTest {

    private static ApexPages.StandardController sc;
    private static AHUDesktopReviewController con;

    private static void setUp(String appId) {
        Test.setCurrentPage(Page.AHUDesktopReview);
        ApexPages.currentPage().getParameters().put('appId', appId);
        sc = new ApexPages.StandardController(new Review__c());
        con = new AHUDesktopReviewController(sc);
    }

    private static Boolean hasPageMessage(String str) {
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        for (ApexPages.Message msg : msgs) {
            if (msg.getDetail().contains(str))
                return true;
        }
        return false;
    }

    @isTest static void testSettingsJson() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];
        Test.startTest();
        setUp(app.id);
        con.getSettingsJson();
        Test.stopTest();
    }

    @isTest static void testDynamicLists() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];
        insert new AHU_Desktop_Review_Related_Lists__c(name = 'Rel A', related_list_name__c = 'Related_List_A__r', object_name__c = 'Review__c');
        insert new AHU_Desktop_Review_Related_Lists__c(name = 'Rel B', related_list_name__c = 'Related_List_B__r', object_name__c = 'Application__c');
        insert new AHU_Desktop_Review_Related_Lists__c(name = 'Rel C', related_list_name__c = 'Related_List_C__r', object_name__c = 'Sub_Application__c');
        insert new AHU_Desktop_Review_Related_Lists__c(name = 'Rel D', related_list_name__c = 'Related_List_D__r', object_name__c = 'Invalid_Object__c');

        Test.startTest();
        setUp(app.id);
        Component.Apex.OutputPanel out = con.getDynamicLists();
        Test.stopTest();
    }

    @isTest static void testReviewSections() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];
        Integer ct = 0;
        for (Schema.SObjectField f : Review__c.sObjectType.getDescribe().fields.getMap().values()) {
            if (ct > 2) break;
            Schema.DescribeFieldResult descr = f.getDescribe();
            if (descr.getType() == Schema.DisplayType.Picklist)
                insert new AHU_Desktop_Review_Settings__c(name = 'Test ' + String.valueOf(ct++), api_binding_name__c = descr.getName(), text__c = 'Test {!"'+descr.getLabel()+'"}');
        }
        Map<String, List<AHUDesktopReviewController.FieldSet>> fieldSets = new Map<String, List<AHUDesktopReviewController.FieldSet>>();
        fieldSets.put('Review__c', new List<AHUDesktopReviewController.FieldSet>());
        AHUDesktopReviewController.FieldSet fs = new AHUDesktopReviewController.FieldSet();
        fieldSets.get('Review__c').add(fs);
        fs.label = 'FieldSet 1';
        for (AHU_Desktop_Review_Settings__c setting : AHU_Desktop_Review_Settings__c.getAll().values()) {
            AHUDesktopReviewController.FieldSetMember f = new AHUDesktopReviewController.FieldSetMember();
            f.fieldPath = setting.api_binding_name__c;
            f.required = false;
            f.dbRequired = false;
            fs.fields.add(f);
        }
        Test.startTest();
        setUp(app.id);
        con.fieldSets = fieldSets;
        Component.Apex.OutputPanel out = con.getReviewSections();
        Test.stopTest();
    }

    @isTest static void testWithoutURLParam() {
        Test.startTest();
        setUp(null);
        Test.stopTest();

        System.assert(hasPageMessage('URL parameter'));
        System.assert(!con.getDoDisplayForm());
    }

    @isTest static void testAppNotFound() {
        Test.startTest();
        setUp('000000000000000');
        Test.stopTest();

        System.assert(hasPageMessage('Application could not be found'));
        System.assert(!con.getDoDisplayForm());
    }

    @isTest static void testInvalidAppStatus() {
        Application__c app = new Application__c();
        insert app;

        Test.startTest();
        setUp(app.id);
        Test.stopTest();

        System.assert(hasPageMessage('Invalid application status'));
        System.assert(!con.getDoDisplayForm());
    }

    @isTest static void testSubAppNotFound() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS);
        insert app;

        Test.startTest();
        setUp(app.id);
        Test.stopTest();

        System.assert(hasPageMessage('Could not find a sub-application'));
        System.assert(!con.getDoDisplayForm());
    }

    @isTest static void testWithNonExistantReview() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];

        Test.startTest();
        setUp(app.id);
        Test.stopTest();

        System.assert(con.getDoDisplayForm());
        System.assertEquals(app.id, con.review.application__c);
        System.assertEquals(subApp.id, con.review.sub_application__c);
        System.assertEquals('Under Review', con.review.status__c);
        System.assertEquals(reviewRt.id, con.review.recordTypeId);
        System.assert(con.getDoDisplayForm());
        System.assert(!con.isPreInstall);
    }

    @isTest static void testWithIncompleteReview() {
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
        setUp(app.id);
        Test.stopTest();

        System.assert(con.getDoDisplayForm());
        System.assertEquals(review.id, con.review.id);
        System.assertEquals(app.id, con.review.application__c);
        System.assertEquals(subApp.id, con.review.sub_application__c);
        System.assertEquals('Under Review', con.review.status__c);
        System.assertEquals(reviewRt.id, con.review.recordTypeId);
        System.assert(con.getDoDisplayForm());
        System.assert(!con.isPreInstall);
    }

    @isTest static void testWithCompletedReview() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];
        Review__c review = new Review__c(application__c = app.id, sub_application__c = subApp.id, recordTypeId = reviewRt.id, status__c = 'Complete');
        insert review;

        Test.startTest();
        setUp(app.id);
        Test.stopTest();

        System.assert(con.getDoDisplayForm());
        System.assertNotEquals(review.id, con.review.id);
        System.assertEquals(app.id, con.review.application__c);
        System.assertEquals(subApp.id, con.review.sub_application__c);
        System.assertEquals('Under Review', con.review.status__c);
        System.assertEquals(reviewRt.id, con.review.recordTypeId);
        System.assert(con.getDoDisplayForm());
        System.assert(!con.isPreInstall);
    }

    @isTest static void testApprove() {
        // The zip code, climate zone and county should be in Zip Code Custom Metadata Type
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS, Building_County__c ='San Bernardino',
                Climate_Zone__c = 15, Building_ZIP_Code__c = '92304');
                
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];
        insert new AHU_Desktop_Review_Settings__c(name = 'testing', api_binding_name__c = 'Eligible_Contractor__c', text__c = 'testing');

        Test.startTest();
        setUp(app.id);
        con.review.eligible_contractor__c = 'Yes';
        PageReference pageRef = con.approve();
        Test.stopTest();

        PageReference expectedRef = Page.AHUDesktopReviewConfirmation;
        expectedRef.getParameters().put('appId', app.id);
        expectedRef.getParameters().put('reviewId', con.review.id);
        System.assertEquals(expectedRef.getUrl(), pageRef.getUrl());
        System.assertEquals(UserInfo.getUserId(), con.app.desktop_reviewer__c);
    }

    @isTest static void testApproveNotAllTrue() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];
        insert new AHU_Desktop_Review_Settings__c(name = 'testing', api_binding_name__c = 'Eligible_Contractor__c', text__c = 'testing');

        Test.startTest();
        setUp(app.id);
        PageReference pageRef = con.approve();
        Test.stopTest();

        System.assertEquals(null, pageRef);
        System.assert(hasPageMessage('all review fields must be true'));
    }

    @isTest static void testApproveIssuesNotBlank() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];
        insert new AHU_Desktop_Review_Settings__c(name = 'testing', api_binding_name__c = 'Eligible_Contractor__c', text__c = 'testing');

        Test.startTest();
        setUp(app.id);
        con.review.eligible_contractor__c = 'Yes';
        con.review.comments__c = 'cannot be blank';
        PageReference pageRef = con.approve();
        Test.stopTest();

        System.assertEquals(null, pageRef);
        System.assert(hasPageMessage('issues field must be blank'));
    }

    @isTest static void testReturnForCorrection() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];

        Test.startTest();
        setUp(app.id);
        con.review.comments__c = 'Has an issue.';
        con.review.additional_comments__c = 'A comment.';
        PageReference pageRef = con.returnForCorrection();
        Test.stopTest();

        PageReference expectedRef = Page.AHUDesktopReviewConfirmation;
        expectedRef.getParameters().put('appId', app.id);
        expectedRef.getParameters().put('reviewId', con.review.id);
        System.assertEquals(expectedRef.getUrl(), pageRef.getUrl());
    }

    @isTest static void testReturnForCorrectionWithoutComments() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Post-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];

        Test.startTest();
        setUp(app.id);
        PageReference pageRef = con.returnForCorrection();
        Test.stopTest();

        System.assertEquals(null, pageRef);
        System.assert(hasPageMessage('Issues or Comments must be provided to mark as Contractor Action Required'));
    }

    @isTest static void testReject() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Pre-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];

        Test.startTest();
        setUp(app.id);
        con.review.comments__c = 'Has an issue.';
        con.review.additional_comments__c = 'A comment.';
        PageReference pageRef = con.reject();
        Test.stopTest();

        PageReference expectedRef = Page.AHUDesktopReviewConfirmation;
        expectedRef.getParameters().put('appId', app.id);
        expectedRef.getParameters().put('reviewId', con.review.id);
        System.assertEquals(expectedRef.getUrl(), pageRef.getUrl());
    }

    @isTest static void testRejectWithoutComments() {
        Application__c app = new Application__c(RecordTypeId = ApplicationUtils.AHU_RECORD_TYPE,
                Status__c = ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS);
        insert app;
        RecordType postRt = [ SELECT id FROM RecordType WHERE name = 'EnergyPro Pre-Installation' AND sObjectType = 'Sub_Application__c' ];
        Sub_Application__c subApp = new Sub_Application__c(application__c = app.id, recordTypeId = postRt.id);
        insert subApp;
        RecordType reviewRt = [ SELECT id FROM RecordType WHERE name = 'AHU' AND sObjectType = 'Review__c' ];

        Test.startTest();
        setUp(app.id);
        PageReference pageRef = con.reject();
        Test.stopTest();

        System.assertEquals(null, pageRef);
        System.assert(hasPageMessage('Issues or Comments must be provided to reject'));
    }
}