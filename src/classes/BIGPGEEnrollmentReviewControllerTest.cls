@isTest
public with sharing class BIGPGEEnrollmentReviewControllerTest {

    /* Method to test the constructor & init methods for the controller */
    public static testMethod void testBIGPGEEnrollmentReviewController() {

        // Utility class for testing data
        BIGPGEEnrollmentTestUtility reviewUtils = new BIGPGEEnrollmentTestUtility(New List<String>{'Contractor'});
        List<Application_Program_Enrollment__c> appProgramEnrollments = new List<Application_Program_Enrollment__c>();
        // Test the page and constructor for every created enrollment application
        Test.startTest();

        for (Application_Enrollment__c applicationEnrollment : reviewUtils.applicationEnrollments) {
            PageReference pageRef = Page.BIGPGEEnrollmentReview;
            pageRef.getParameters().put('id',applicationEnrollment.Id);

            Test.setCurrentPage(pageRef);

            // Get the standard controller for this enrollment application
            ApexPages.StandardController con = new ApexPages.StandardController(applicationEnrollment);

            // Get the controller extension
            BIGPGEEnrollmentReviewController controllerExt = new BIGPGEEnrollmentReviewController(con);

            try {
                Account appEnrollmentAccount = [
                    SELECT Tax_Status__c, Workers_Compensation_Type__c, In_PGE_SoCalGas_Shared_Territory__c
                    FROM Account
                    WHERE Account.Id = : applicationEnrollment.Account__c
                    ];
            } catch (Exception e) {
                System.debug ('Error retrieving appEnrollmentAccount: ' + e.getMessage());
            }

            // Get program enrollments
            appProgramEnrollments.addAll(controllerExt.programEnrollmentsMap.values());

            // Verify the company information review step
            System.assertNotEquals(controllerExt.companyInformationReview, null);
            System.assertNotEquals(controllerExt.companyInformationReview.appReview, null);
            System.assertNotEquals(controllerExt.companyInformationReview.appEnrollment, null);
            System.assert(applicationEnrollment.Tax_Status__c == 'Exempt');
            System.assert(applicationEnrollment.Workers_Compensation_Type__c == 'CSLB Waiver Statement');

            Set<String> overridenFields = new Set<String>();

            // Check all the company information steps
            Integer substepCount = 0;
            controllerExt.currentStaffIndex = 0;
            controllerExt.currentReviewIndex = 0;
            controllerExt.moveNext = true;

            controllerExt.getcompanyContactStaffList();

            for (String currentApprovalField : controllerExt.companyInformationReview.subStatusFieldsMap.values()) {
                controllerExt.currentReviewSubIndex = substepCount;

                if (substepCount == 0 && applicationEnrollment.EIN_or_SSN__c == BIGPGEEnrollmentTestUtility.TEST_TAX_ID) {
                    controllerExt.companyInformationReview.appReview.Match_Account__c = reviewUtils.testAccount.Id;
                    System.assertNotEquals(controllerExt.getAccountMatchingOptions(), null);
                }

                if (controllerExt.companyInformationReview.approvalFieldSetMap.containsKey(substepCount)) {
                    for (String currentField : controllerExt.companyInformationReview.approvalFieldSetMap.get(substepCount)) {
                        controllerExt.companyInformationReview.appReview.put(currentField, 'Yes');
                    }
                }

                controllerExt.companyInformationReview.appReview.Approval_Status__c = 'Approved';
                System.assert(!controllerExt.companyInformationReview.isUnread());

                System.assert(controllerExt.companyInformationReview.areStepFieldsApproved(substepCount, overridenFields));
                substepCount++;

                // Save the current review status
                controllerExt.saveReview();
                System.assertNotEquals(controllerExt.companyInformationReview.appReview.Id, null);
            }
            controllerExt.currentStaffIndex = 1;
            // Advance review through programs
            for (Integer currentReviewIndex = 1; currentReviewIndex < controllerExt.reviewItemsMap.size(); currentReviewIndex++) {
                controllerExt.currentReviewIndex = currentReviewIndex;
                BIGPGEEnrollmentReviewItem currentReviewItem = controllerExt.reviewItemsMap.get(currentReviewIndex);
                System.assertNotEquals(currentReviewItem.appProgramEnrollment, null);
                System.assertNotEquals(currentReviewItem.programReview, null);

                substepCount = 0;

                currentReviewItem.programReview.Approval_Status__c = 'Approved';
                System.assert(!currentReviewItem.isUnread());

                if (currentReviewItem.appProgramEnrollment.RecordTypeId
                        == BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID) {
                    controllerExt.getAcqcStaffList();
                } else if (currentReviewItem.appProgramEnrollment.RecordTypeId
                        == BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID) {
                    controllerExt.getAhuStaffList();
                } else {
                    controllerExt.gethuStaffList();
                }

                for (String currentApprovalField : currentReviewItem.subStatusFieldsMap.values()) {
                    controllerExt.currentReviewSubIndex = substepCount;

                    if (currentReviewItem.approvalFieldSetMap.containsKey(substepCount)) {
                        for (String currentField : currentReviewItem.approvalFieldSetMap.get(substepCount)) {
                            currentReviewItem.programReview.put(currentField, 'Yes');
                        }
                    }

                    System.assert(currentReviewItem.areStepFieldsApproved(substepCount, overridenFields));
                    substepCount++;
                    controllerExt.currentStaffIndex++;

                    // Save the current review status
                    controllerExt.saveReview();
                    System.assertNotEquals(currentReviewItem.programReview.Id, null);
                }

                List<Attachment> attachmentListInsurance = new List<Attachment>();

                if (controllerExt.companyInformationReview.docTypeToAttachment.get('W-9 Form').Id != null
                        && controllerExt.companyInformationReview.docTypeToAttachment.get('General Liability Insurance').Id != null
                        && controllerExt.companyInformationReview.docTypeToAttachment.get('Auto Liability Insurance').Id != null
                        && controllerExt.companyInformationReview.docTypeToAttachment.get(String.escapeSingleQuotes('Worker\'s Compensation Insurance')).Id != null
                        && controllerExt.companyInformationReview.docTypeToAttachment.get('Bonding Document').Id != null){
                    attachmentListInsurance.add(controllerExt.companyInformationReview.docTypeToAttachment.get('W-9 Form'));
                    attachmentListInsurance.add(controllerExt.companyInformationReview.docTypeToAttachment.get(String.escapeSingleQuotes('Worker\'s Compensation Insurance')));
                    attachmentListInsurance.add(controllerExt.companyInformationReview.docTypeToAttachment.get('General Liability Insurance'));
                    attachmentListInsurance.add(controllerExt.companyInformationReview.docTypeToAttachment.get('Auto Liability Insurance'));
                    attachmentListInsurance.add(controllerExt.companyInformationReview.docTypeToAttachment.get('Bonding Document'));
                }

                System.assert(attachmentListInsurance.size() == 5);

                List<Attachment> attachmentListCredentials = new List<Attachment>();

                if (currentReviewItem.docTypeToAttachment.get('Proof Financial Records').Id != null
                        && currentReviewItem.docTypeToAttachment.get('Professional Reference 1').Id != null
                        && currentReviewItem.docTypeToAttachment.get('Professional Reference 2').Id != null){
                    attachmentListCredentials.add(currentReviewItem.docTypeToAttachment.get('Proof Financial Records'));
                    attachmentListCredentials.add(currentReviewItem.docTypeToAttachment.get('Professional Reference 1'));
                    attachmentListCredentials.add(currentReviewItem.docTypeToAttachment.get('Professional Reference 2'));
                }

                System.assert(attachmentListCredentials.size() == 3);

                List<Attachment> attachmentListAgreement = new List<Attachment>();

                if (currentReviewItem.docTypeToAttachment.get('Contractor Agreement').Id != null) {
                    attachmentListAgreement.add(currentReviewItem.docTypeToAttachment.get('Contractor Agreement'));
                }
                System.debug('##attachmentListAgreement.size() = ' + attachmentListAgreement.size());
                System.assert(attachmentListAgreement.size() == 1);
            }

            System.assert(controllerExt.getExperienceAlreadyProven());
            System.assert(controllerExt.hasReviewFinished);

            controllerExt.validateStatus();
            // Finish it!!
            controllerExt.finishReview();

            controllerExt.goBack();

            controllerExt.targetReviewIndex = 1;
            controllerExt.skipToStep();

            controllerExt.getExperienceAlreadyProven();
            controllerExt.updateTaxID();
            System.assert(controllerExt.getUserCanEdit());

            controllerExt.companyInformationReview.appReview.Approval_Status__c = 'Unread';
            controllerExt.companyInformationReview.setStatus();

            controllerExt.companyInformationReview.appReview.Approval_Status__c = 'Rejected';
            controllerExt.companyInformationReview.setStatus();

            controllerExt.companyInformationReview.appReview.Approval_Status__c = 'Request More info';
            controllerExt.companyInformationReview.setStatus();

            controllerExt.acqcReview.programReview.Approval_Status__c = 'Unread';
            controllerExt.acqcReview.setStatus();

            controllerExt.acqcReview.programReview.Approval_Status__c = 'Rejected';
            controllerExt.acqcReview.setStatus();

            controllerExt.acqcReview.programReview.Approval_Status__c = 'Request More info';
            controllerExt.acqcReview.setStatus();

            controllerExt.companyInformationReview.rejectAllSteps();
        }

        // Delete all Programs for all Enrollment Applications
        // We pass 'false' as the third variable to perform a full deletion
        BIGPGEEnrollmentAppProgramUtility.deleteApplicationProgramEnrollment(reviewUtils.applicationEnrollments, 
                appProgramEnrollments, false);

        Test.stopTest();

        // Check if all programs were deleted successfully
        for (Application_Enrollment__c applicationEnrollment : reviewUtils.applicationEnrollments) {
            List<Application_Program_Enrollment__c> appsPgrEnrollment = new List<Application_Program_Enrollment__c>();
            try {
                appsPgrEnrollment = [
                    SELECT Id
                    FROM Application_Program_Enrollment__c
                    WHERE Application_Enrollment__r.Id = :applicationEnrollment.Id
                    ];
                System.assert(appsPgrEnrollment.isEmpty());
            } catch (QueryException e) {
                System.debug ('Error retrieving existing appEnrollment: ' + e.getMessage());
            } catch (Exception e) {
                System.debug ('Error retrieving existing appEnrollment: ' + e.getMessage());
            }
        }
    }

    public class MyException extends Exception {}
}