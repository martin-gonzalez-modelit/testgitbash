/**
 * This class contains unit tests for CreatePublicNoteOnSubApplication class.
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2017-08
 */
@isTest
private class TestCreatePublicNoteOnSubApplication {

    /**
     * Create Correction that creates a Public Note for AHU (Pre).
     */
    public static testMethod void testCreateAHUCorrectionForPre() {
        Application__c application = BIGPortalTestUtils.createApplication(ApplicationUtils.AHU_RECORD_TYPE);
        insert application;

        Sub_Application__c subApplication = BIGPortalTestUtils.createSubApplication(
                application.Id, BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID);
        insert subApplication;

        CreatePublicNoteOnSubApplication.createPublicNote(new List<Correction__c> {
                BIGPortalTestUtils.createCorrection(
                    application.Id,
                    'Pending',
                    'Reason Required test',
                    true,
                    Date.Today())});

        List<Application_Note__c> applicationNotes = BIGPortalTestUtils.getApplicationNotesByApplicationId(
                application.Id);
        Application_Note__c applicationNote = applicationNotes.get(0);

        System.assertEquals(1, applicationNotes.size());
        System.assertEquals(application.Id, applicationNote.Application__c);
        System.assertEquals(subApplication.Id, applicationNote.Sub_Application__c);
        System.assertEquals('Reason Required test', applicationNote.Note__c);
        System.assertEquals(true, applicationNote.Public__c);
    }

    /**
     * Create Correction that creates a Public Note for AHU (Post).
     */
    public static testMethod void testCreateAHUCorrectionForPost() {
        Application__c application = BIGPortalTestUtils.createApplication(ApplicationUtils.AHU_RECORD_TYPE);
        insert application;

        List<Sub_Application__c> subApplications = new List<Sub_Application__c> {
                BIGPortalTestUtils.createSubApplication(
                    application.Id,
                    BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID),
                BIGPortalTestUtils.createSubApplication(
                    application.Id,
                    BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID)};
        insert subApplications;

        CreatePublicNoteOnSubApplication.createPublicNote(new List<Correction__c> {
                BIGPortalTestUtils.createCorrection(
                    application.Id,
                    'Pending',
                    'Reason Required test',
                    true,
                    Date.Today())});

        List<Application_Note__c> applicationNotes = BIGPortalTestUtils.getApplicationNotesByApplicationId(
                application.Id);
        Application_Note__c applicationNote = applicationNotes.get(0);

        System.assertEquals(1, applicationNotes.size());
        System.assertEquals(application.Id, applicationNote.Application__c);
        System.assertEquals(subApplications.get(1).Id, applicationNote.Sub_Application__c);
        System.assertEquals('Reason Required test', applicationNote.Note__c);
        System.assertEquals(true, applicationNote.Public__c);
    }

}