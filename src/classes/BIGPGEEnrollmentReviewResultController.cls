/**
 * This controller implements the actions of the PG&E Enrollment Review component.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-03
 */
public with sharing class BIGPGEEnrollmentReviewResultController {
    private List<BIGPGEEnrollmentReviewResultUtility.EnrollmentApplicationReviewWrapper> reviews;
    public String appId {get; set;}
    public Boolean showInternalMessages {get; set;}

    public BIGPGEEnrollmentReviewResultController() { }

    public List<BIGPGEEnrollmentReviewResultUtility.EnrollmentApplicationReviewWrapper> getReviews() {
        List<BIGPGEEnrollmentReviewResultUtility.EnrollmentApplicationReviewWrapper> reviews;
        try {
            Application_Enrollment__c appE = [SELECT Name, Company_Name__c, Type__c, Website__c,Company_Info_Status__c,
                                                  Address__c, EIN_or_SSN__c, Enrollment_Status__c,
                                                  City__c, State__c, Zip_Code__c, DBA__c, Email_Sent__c,
                                                  Service_Territory__c, Different_Contact__c, Account__c,
                                                  (SELECT Application_Enrollment__c, Status__c, RecordTypeId
                                                   FROM Applications_Program_Enrollment__r
                                                   WHERE Status__c !=: BIGPGEEnrollmentAppProgramUtility.PROGRAM_UNUSED_STATUS)
                                              FROM Application_Enrollment__c
                                              WHERE Id =: appId];

            reviews = BIGPGEEnrollmentReviewResultUtility.getAllReviewsForEnrollmentApplication(appE);

        } catch (Exception e) {
            System.debug('### Error: ' + e.getMessage());
        }
        return reviews;
    }

}