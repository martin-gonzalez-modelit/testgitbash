public with sharing class BIGPGEEnrollmentReviewController {

    public static final List<String> STEP_LETTERS {get; set;}
    static {
        STEP_LETTERS = new List<String> {'A', 'B', 'C', 'D', 'E', 'F'};
    }

    public Id currentUserId {get; set;}

    public static List<String> STD_CONTROLLER_FIELD_REFERENCE = new List<String>{'Account__c', 'Type__c', 'DBA__c',
            'EIN_or_SSN__c', 'Enrollment_Status__c', 'Tax_Status__c', 'Workers_Compensation_Type__c', 'Address__c',
            'City__c','State__c', 'Zip_Code__c', 'Website__c', 'Company_Name__c', 'Company_Info_Status__c',
            'LastModifiedById', 'Service_Territory__c', 'Auto_Liability_Insurance__c'};

    // Application program enrollment objects for this enrollment application.
    public Application_Program_Enrollment__c acqcEnrollment {get; set;}
    public Application_Program_Enrollment__c huEnrollment {get; set;}
    public Application_Program_Enrollment__c ahuEnrollment {get; set;}
    public Map<Id, Application_Program_Enrollment__c> programEnrollmentsMap;

    // To determine if the enrollment application review contains errors
    private Boolean success = true;

    // This map is used to relate a review object with an Index
    @testVisible
    private Map<Integer, BIGPGEEnrollmentReviewItem> reviewItemsMap;
    public Integer reviewItemsCount {get; set;}

    public Set<Id> alreadyMatchedStaff;
    Map<Id, Id> staffIdToMatchingContact;

    public Boolean hasReviewFinished {
        get {
            return (success && this.companyInformationReview.appReview.Approval_Status__c ==
                       BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REQUEST_INFO_STATUS
                || (success && this.companyInformationReview.appReview.Approval_Status__c !=
                           BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS
                    && (this.acqcReview == null || this.acqcReview.programReview.Approval_Status__c !=
                               BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS)
                    && (this.ahuReview == null || this.ahuReview.programReview.Approval_Status__c !=
                               BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS)
                    && (this.huReview == null || this.huReview.programReview.Approval_Status__c !=
                               BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS)));
        }
    }

    // This map is used to relate a staff listing with an index
    private Map<Integer, List<BIGPGEEnrollmentReviewUtils.StaffWithMatches>> staffListMap;
    private Integer staffListCount;

    // Variables for controller interaction
    public Integer currentReviewIndex {get; set;}
    public Integer currentReviewSubIndex {get; set;}
    public Integer targetReviewIndex {get; set;}
    public Integer currentStaffIndex {get; set;}
    public Boolean moveNext {get; set;}

    // ---------- Review Items ------------

    public String reviewItems {get; set;}

    private Map<Id, List<BIGPGEEnrollmentReviewUtils.StaffWithMatches>> matchingAppStaffMap;

    // Company Info
    public BIGPGEEnrollmentReviewItem companyInformationReview {get; set;}
    public List<Account> accountMatching {get; set;}
    public List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> companyContactStaffList;

    // Getter for company contacts staff list
    public List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> getcompanyContactStaffList() {

        if (this.companyContactStaffList == null) {
            this.companyContactStaffList = BIGPGEEnrollmentReviewUtils.getStaffWithMatchesListByEnrollmentApp (
                                                this.companyInformationReview.appReview.Enrollment_Application__c,
                                                this.companyInformationReview.appReview.Match_Account__c,
                                                alreadyMatchedStaff);

            this.staffListMap.put(this.staffListCount++, this.companyContactStaffList);
        }

        return this.companyContactStaffList;
    }

    // ACQC
    public BIGPGEEnrollmentReviewItem acqcReview {get; set;}
    public List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> acqcStaffList;

    // Getter for ACQC staff list
    public List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> getAcqcStaffList() {

        if (this.acqcStaffList == null) {
            this.acqcStaffList = BIGPGEEnrollmentReviewUtils.getStaffWithMatchesListByProgramId (this.acqcEnrollment, this.companyInformationReview.appReview.Match_Account__c, alreadyMatchedStaff);
            this.staffListMap.put(this.staffListCount++, this.acqcStaffList);
        }

        return this.acqcStaffList;
    }

    // AHU
    public BIGPGEEnrollmentReviewItem ahuReview {get; set;}
    public List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> ahuStaffList;

    // Getter for AHU staff list
    public List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> getAhuStaffList() {

        if (this.ahuStaffList == null) {
            this.ahuStaffList = BIGPGEEnrollmentReviewUtils.getStaffWithMatchesListByProgramId (this.ahuEnrollment, this.companyInformationReview.appReview.Match_Account__c, alreadyMatchedStaff);
            this.staffListMap.put(this.staffListCount++, this.ahuStaffList);
        }

        return this.ahuStaffList;
    }

    /**
     * Gets Select options common to most review options.
     *
     * @return list of selectOptions.
     */
    public static List<SelectOption> getSelectOptions() {
        List<SelectOption> selectOptions = new List<SelectOption>();
        selectOptions.add(new SelectOption('Yes', 'Yes'));
        selectOptions.add(new SelectOption('No', 'No'));
        selectOptions.add(new SelectOption('Override', 'No, but pass anyway.'));
        return selectOptions;
    }
    /**
     * Gets Select options where 'Yes' is displayed but disabled.
     * Needed when Auto_Liability_Insurance__c is false (user has selected 'Not using a company owned vehicle').
     *
     * @return list of selectOptions.
     */
    public static List<SelectOption> getSelectOptionsYesDisabled() {
        List<SelectOption> selectOptionsYesDisabled = new List<SelectOption>();
        selectOptionsYesDisabled.add(new SelectOption('Yes', 'Yes', true));
        selectOptionsYesDisabled.add(new SelectOption('No', 'No'));
        selectOptionsYesDisabled.add(new SelectOption('Override', 'No, but pass anyway.'));
        return selectOptionsYesDisabled;
    }

    // HU
    public BIGPGEEnrollmentReviewItem huReview {get; set;}
    public List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> huStaffList;

    // Getter for HU staff list
    public List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> gethuStaffList() {

        if (this.huStaffList == null) {
            this.huStaffList = BIGPGEEnrollmentReviewUtils.getStaffWithMatchesListByProgramId (this.huEnrollment, this.companyInformationReview.appReview.Match_Account__c, alreadyMatchedStaff);
            this.staffListMap.put(this.staffListCount++, this.huStaffList);
        }

        return this.huStaffList;
    }

    public final Application_Enrollment__c appEnrollment {get;set;}

    public BIGPGEEnrollmentReviewController(ApexPages.StandardController stdController) {

        if (!Test.isRunningTest()) {
            stdController.addFields (STD_CONTROLLER_FIELD_REFERENCE);
        }

        // Get application enrollment record
        this.appEnrollment = (Application_Enrollment__c) stdController.getRecord();
        this.currentUserId = appEnrollment.LastModifiedById;

        // initialize review items map
        initializeReviewMaps();

        // Initialize programs
        initializePrograms();

        // Initialize Company Information review step
        this.companyInformationReview = BIGPGEEnrollmentReviewUtils.getCompanyInformationReview(this.appEnrollment, false);
        this.reviewItemsMap.put(this.reviewItemsCount++, this.companyInformationReview);

        // initialize ACQC Step
        if (this.acqcEnrollment != null) {
            this.acqcReview = BIGPGEEnrollmentReviewUtils.getProgramReview(this.acqcEnrollment);
            this.reviewItemsMap.put(this.reviewItemsCount++, this.acqcReview);
        }

        // initialize AHU Step
        if (this.ahuEnrollment != null) {
            this.ahuReview = BIGPGEEnrollmentReviewUtils.getProgramReview(this.ahuEnrollment);
            this.reviewItemsMap.put(this.reviewItemsCount++, this.ahuReview);
        } else if (this.huEnrollment != null) {
            // initialize HU step
            this.huReview = BIGPGEEnrollmentReviewUtils.getProgramReview(this.huEnrollment);
            this.reviewItemsMap.put(this.reviewItemsCount++, this.huReview);
        }

        // Create a set with all the staffs with a review already matched to a staff
        staffIdToMatchingContact = BIGPGEEnrollmentReviewUtils.getAlreadyMatchedStaff(
                new List<BIGPGEEnrollmentReviewItem> {this.acqcReview, this.huReview, this.ahuReview});
        alreadyMatchedStaff = staffIdToMatchingContact.keySet().clone();

        // Populate the staff ID / staff enrollment map
        for (List<BIGPGEEnrollmentReviewUtils.StaffWithMatches> staffItems : staffListMap.values()) {
            for (BIGPGEEnrollmentReviewUtils.StaffWithMatches staffItem : staffItems) {
                if (matchingAppStaffMap.containsKey(staffItem.staff.Staff__c)) {
                    matchingAppStaffMap.get(staffItem.staff.Staff__c).add (staffItem);
                }
                else {
                    matchingAppStaffMap.put(staffItem.staff.Staff__c, 
                            new List<BIGPGEEnrollmentReviewUtils.StaffWithMatches>{staffItem});
                }
            }
        }

        // Set the current review index
        this.currentReviewIndex = 0;
        for (BIGPGEEnrollmentReviewItem reviewItem : new List<BIGPGEEnrollmentReviewItem>{companyInformationReview, acqcReview, ahuReview, huReview}) {
            if (reviewItem != null && reviewItem.isUnread()) {
                break;
            } else {
                this.currentReviewIndex++;
            }
        }

        // Load matching accounts for Company Information
        this.accountMatching = (this.companyInformationReview != null
                                    && this.companyInformationReview.appReview != null
                                    && this.companyInformationReview.appReview.Tax_ID_Number__c != null)
                                ? BIGPGEEnrollmentReviewUtils.getSimilarAccounts (this.appEnrollment, this.companyInformationReview.appReview.Tax_ID_Number__c)
                                : BIGPGEEnrollmentReviewUtils.getSimilarAccounts (this.appEnrollment, this.appEnrollment.EIN_or_SSN__c);

        // Serialize review items to reference them at front-end
        reviewItems = JSON.serialize(new List<BIGPGEEnrollmentReviewItem>{huReview, ahuReview, acqcReview});
    }

    public PageReference validateStatus() {
        PageReference page = null;

        if (this.appEnrollment.Enrollment_Status__c == BIGPGEEnrollmentApplicationUtility.ENROLLMENT_CREATED_STATUS) {
            page = new PageReference('/' + this.appEnrollment.Id);
            page.setRedirect(true);
        }

        return page;
    }

    /* Method for initializing review map related variables */
    private void initializeReviewMaps() {
        // Initialize review map & count
        this.reviewItemsMap = new map<Integer, BIGPGEEnrollmentReviewItem>();
        this.reviewItemsCount = 0;
        this.staffListMap = new map<Integer, List<BIGPGEEnrollmentReviewUtils.StaffWithMatches>>();
        this.staffListCount = 0;
        this.programEnrollmentsMap = new map<Id, Application_Program_Enrollment__c>();
        this.matchingAppStaffMap = new map<Id, List<BIGPGEEnrollmentReviewUtils.StaffWithMatches>>();
    }

    public Boolean getUserCanEdit() {
        return this.appEnrollment.Enrollment_Status__c != BIGPGEEnrollmentReviewUtils.APP_ENROLLMENT_CHECKED_OUT_STATUS
                    || this.currentUserId == UserInfo.getUserId();
    }

    /* Method for initializing program applications */

    private void initializePrograms() {
        List<Application_Program_Enrollment__c> programEnrollments = BIGPGEEnrollmentReviewUtils.getProgramEnrollmentsByApplicationEnrollmentId(this.appEnrollment.Id);

        if (programEnrollments != null && !programEnrollments.isEmpty()) {
            for (Application_Program_Enrollment__c pEnrollment : programEnrollments) {
                if (pEnrollment.RecordTypeId ==
                        BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID) {

                    this.acqcEnrollment = pEnrollment;
                    this.programEnrollmentsMap.put (this.acqcEnrollment.Id, this.acqcEnrollment);
                } else if (pEnrollment.RecordTypeId ==
                        BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID) {

                    this.ahuEnrollment = pEnrollment;
                    this.programEnrollmentsMap.put (this.ahuEnrollment.Id, this.ahuEnrollment);
                } else {
                    this.huEnrollment = pEnrollment;
                    this.programEnrollmentsMap.put (this.huEnrollment.Id, this.huEnrollment);
                }
            }
        }
    }

    public List<SelectOption> getAccountMatchingOptions() {
        List<SelectOption> accountMatchingOptions = null;

        if (this.accountMatching != null && !this.accountMatching.isEmpty()) {

            accountMatchingOptions = new List<SelectOption>();

            // Create a select option per matching account
            for (Account matchingAccount : this.accountMatching) {
                accountMatchingOptions.add (new SelectOption(matchingAccount.Id, matchingAccount.Name));
            }

            // Add an option for new accounts
            accountMatchingOptions.add (new SelectOption('', BIGPGEEnrollmentReviewUtils.ACCOUNT_INFO_NEW_RECORD_LABEL));
        }

        return accountMatchingOptions;
    }

    public void saveReview() {
        // Skip the previous programs if they are unread
        List<Application_Program_Enrollment_Review__c> appProgEnrollmentsToUpdate = null;
        for (Integer i = 1; i < this.currentReviewIndex; i++) {
            appProgEnrollmentsToUpdate = new List<Application_Program_Enrollment_Review__c>();
            if (this.reviewItemsMap.containsKey(i) && this.reviewItemsMap.get(i).isUnread()) {
                this.reviewItemsMap.get(i).setStatus(BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_SKIPPED_STATUS);
                appProgEnrollmentsToUpdate.add (this.reviewItemsMap.get(i).programReview);

                for (Integer j = 0; j < this.reviewItemsMap.get(i).subStatusFieldsMap.size(); j++) {
                    this.reviewItemsMap.get(i).getReviewObject().put(this.reviewItemsMap.get(i).subStatusFieldsMap.get(j),
                            BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_SKIPPED_STATUS);
                }
            }
        }

        if (appProgEnrollmentsToUpdate != null) {
            try {
                upsert appProgEnrollmentsToUpdate;
            } catch (DmlException e) {
                System.debug ('Error updating program reviews: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
            } catch (Exception e) {
                System.debug ('Error updating program reviews: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
            }
        }

        if (this.currentReviewIndex <= this.reviewItemsCount
            && this.reviewItemsMap.containsKey(this.currentReviewIndex)) {

            List<BIGPGEEnrollmentReviewUtils.staffWithMatches> staffReviews = null;
            List<Program_enrollment_Staff_Review__c> relatedStaffEnrollments = null;

            BIGPGEEnrollmentReviewItem currentItem = this.reviewItemsMap.get(currentReviewIndex);
            Boolean approveStep = true;

            // Use a generic sObject to point either to the app review or the program review
            sObject reviewItem = currentItem.getReviewObject();

            // Verify that the current item has a sub approval field (is not a main approval item)
            if (currentItem.subStatusFieldsMap.containsKey(this.currentReviewSubIndex)
                && currentItem.subStatusFieldsMap.get(this.currentReviewSubIndex) != '') {

                Set<String> overridenFields = new Set<String>();

                if (currentItem.programReview != null
                    && currentItem.approvalFieldSetMap.get(this.currentReviewSubIndex) != null
                    && currentItem.approvalFieldSetMap.get(this.currentReviewSubIndex).contains('Company_Operation_Proof__c')
                    && currentItem.programReview.get ('Company_Operation_Proof__c') == null
                    && this.getExperienceAlreadyProven()) {

                    overridenFields.add('Company_Operation_Proof__c');
                }

                // Check for all approval fields in the current review item
                approveStep = currentItem.areStepFieldsApproved(this.currentReviewSubIndex, overridenFields);

                // If it's a staff step, check all the staff items for step approval.
                if ((currentItem.subStatusFieldsMap.get(this.currentReviewSubIndex)
                        == BIGPGEEnrollmentReviewUtils.STAFF_APPROVAL_FIELD
                        || currentItem.subStatusFieldsMap.get(this.currentReviewSubIndex)
                            == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_CONTACTS_APPROVAL_FIELD)
                    && this.staffListMap.containsKey(this.currentStaffIndex)
                    && this.staffListMap.get(this.currentStaffIndex) != null) {

                    staffReviews = new List<BIGPGEEnrollmentReviewUtils.staffWithMatches>();

                    for (BIGPGEEnrollmentReviewUtils.staffWithMatches staff : this.staffListMap.get(this.currentStaffIndex)) {
                        approveStep = (approveStep
                                        && staff.staffReview.BPI_Certification_Active__c != 'No'
                                        && staff.staffReview.HERS_II_Certification_Active__c != 'No'
                                        && staff.staffReview.HVAC_EPA_License__c != 'No'
                                        && staff.staffReview.HVAC_Experience__c != 'No'
                                        && staff.staffReview.HVAC_School_or_Training__c != 'No');

                        staffReviews.add(staff);

                        if (staff.staffReview.Matching_Staff__c != null && !alreadyMatchedStaff.contains(staff.staff.Staff__c)) {
                            alreadyMatchedStaff.add (staff.staff.Staff__c);
                            staffIdToMatchingContact.put (staff.staff.Staff__c, staff.staffReview.Matching_Staff__c);
                        }
                    }

                    // Update other review items based on this staff
                    BIGPGEEnrollmentReviewUtils.updateMatchingStaff (staffIdToMatchingContact);
                }

                if (this.moveNext) {
                    if (approveStep) {
                        reviewItem.put(currentItem.subStatusFieldsMap.get(this.currentReviewSubIndex),
                                        BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_APPROVED_STATUS);
                    } else {
                        reviewItem.put(currentItem.subStatusFieldsMap.get(this.currentReviewSubIndex),
                                        BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REJECTED_STATUS);
                    }
                }
            }

            if (!currentItem.isStatusFinal()) {
                // If it's an already enrolled program, set the review step to rejected
                if (currentItem.appProgramEnrollment != null && currentItem.appProgramEnrollment.Status__c == BIGPGEEnrollmentReviewUtils.PROGRAM_ALREADY_ENROLLED_STATUS) {
                    currentItem.programReview.Approval_Status__c = BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REJECTED_STATUS;
                }

                try {
                    // Upsert the record
                    upsert reviewItem;
                } catch (DmlException e) {
                    System.debug ('Error upserting review item: ' + e.getMessage());
                } catch (Exception e) {
                    System.debug ('Error upserting review item: ' + e.getMessage());
                }

                // Upsert staff records if needed
                if (reviewItem.Id != null && staffReviews != null) {
                    List<Program_Enrollment_Staff_Review__c> staffToUpdate = new list<Program_Enrollment_Staff_Review__c>();

                    for (BIGPGEEnrollmentReviewUtils.staffWithMatches staff : staffReviews) {

                        // Set the parent review Id
                        if (staff.staffReview.Program_Enrollment__c == null && !staff.isAppContactReview) {
                            staff.staffReview.Program_Enrollment__c = reviewItem.Id;
                        } else if (staff.isAppContactReview && staff.staffReview.Enrollment_Application_Review__c == null) {
                            staff.staffReview.Enrollment_Application_Review__c = reviewItem.Id;
                        }
                        staffToUpdate.add(staff.staffReview);
                    }

                    try {
                        upsert staffToUpdate;
                    } catch (DmlException e) {
                        System.debug ('Error upserting staff reviews: ' + e.getMessage());
                    } catch (Exception e) {
                        System.debug ('Error upserting staff reviews: ' + e.getMessage());
                    }
                }

                // Check out the enrollment app record
                this.appEnrollment.Enrollment_Status__c = BIGPGEEnrollmentReviewUtils.APP_ENROLLMENT_CHECKED_OUT_STATUS;
                try {
                    update this.appEnrollment;
                } catch (DmlException e) {
                    System.debug ('Error updating enrollment status: ' + e.getMessage());
                } catch (Exception e) {
                    System.debug ('Error updating enrollment status: ' + e.getMessage());
                }

                this.currentUserId = UserInfo.getUserId();

                if (currentItem.appEnrollment != null && this.currentReviewSubIndex == 3) {

                    // If company Information step was rejected / requested more information update programs.
                    if (currentItem.appReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REVIEW_REJECTED_STATUS
                        || currentItem.appReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REVIEW_REQUEST_INFO_STATUS) {

                        List<Application_Program_Enrollment_Review__c> cpItemsToUpdate = new List<Application_Program_Enrollment_Review__c>();

                        for (BIGPGEEnrollmentReviewItem cpItem : new List<BIGPGEEnrollmentReviewItem>{acqcReview, ahuReview, huReview}) {
                            if (cpItem != null && cpItem.programReview != null) {
                                cpItem.programReview.Approval_Status__c = 'Unread';

                                cpItemsToUpdate.add(cpItem.programReview);
                            }
                        }

                        if (!cpItemsToUpdate.isEmpty()) {
                            try {
                                upsert cpItemsToUpdate;
                            } catch (DmlException e) {
                                System.debug ('Error updating application program enrollment reviews: ' + e.getMessage());
                            } catch (Exception e) {
                                System.debug ('Error updating application program enrollment reviews: ' + e.getMessage());
                            }
                        }
                    } else if (currentItem.appReview.Match_Account__c != null) {
                        // If the application was matched to an account look for already enrolled programs
                        BIGPGEEnrollmentReviewUtils.updateProgramEnrollmentsOnAccountMatching (currentItem.appReview.Match_Account__c, New List<BIGPGEEnrollmentReviewItem>{acqcReview, huReview, ahuReview});
                    }
                }
            }
        }
    }

    public void goBack() {
        // Skip the previous programs if they are unread
        List<Application_Program_Enrollment_Review__c> appProgEnrollmentsToUpdate = null;
        for (Integer i = 1; i < this.currentReviewIndex; i++) {
            appProgEnrollmentsToUpdate = new List<Application_Program_Enrollment_Review__c>();
            if (this.reviewItemsMap.containsKey(i) && this.reviewItemsMap.get(i).isUnread()) {
                this.reviewItemsMap.get(i).setStatus(BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_SKIPPED_STATUS);
                appProgEnrollmentsToUpdate.add(this.reviewItemsMap.get(i).programReview);

                for (Integer j = 0; j < this.reviewItemsMap.get(i).subStatusFieldsMap.size(); j++) {
                    this.reviewItemsMap.get(i).getReviewObject().put(this.reviewItemsMap.get(i).subStatusFieldsMap.get(j),
                            BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_SKIPPED_STATUS);
                }
            }
        }

        if (appProgEnrollmentsToUpdate != null) {
            try {
                upsert appProgEnrollmentsToUpdate;
            } catch (DmlException e) {
                System.debug ('Error updating program reviews: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
            } catch (Exception e) {
                System.debug ('Error updating program reviews: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
            }
        }

        BIGPGEEnrollmentReviewItem mainReviewItem = null;

        if (this.currentReviewSubIndex > 0) {
            mainReviewItem = this.reviewItemsMap.get(currentReviewIndex);
        } else {
            mainReviewItem = this.reviewItemsMap.get(currentReviewIndex - 1);
        }

        if (mainReviewItem != null) {
            // Use a generic sObject to point either to the app review or the program review
            sObject reviewRecord = (mainReviewItem.appReview != null) ? (sObject) mainReviewItem.appReview
                                                                      : (sObject) mainReviewItem.programReview;
            reviewRecord.put(mainReviewItem.statusField, BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS);

            if (mainReviewItem.subStatusFieldsMap.containsKey(currentReviewSubIndex - 1)
                && mainReviewItem.subStatusFieldsMap.get(currentReviewSubIndex - 1) != '') {

                reviewRecord.put(mainReviewItem.subStatusFieldsMap.get(currentReviewSubIndex - 1),
                                 BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS);
            }
        }
    }

    public PageReference finishReview() {
        PageReference returnPage = null;
        String errorMessage = '';
        Savepoint sp = Database.setSavepoint();

        // If the previous submission had errors, we need to process it again.
        success = true;

        // Do not commit changes to database if the enrollment application was completed or canceled.
        if (appEnrollment.Enrollment_Status__c == BIGPGEEnrollmentReviewUtils.APP_ENROLLMENT_COMPLETED_STATUS
               || appEnrollment.Enrollment_Status__c == BIGPGEEnrollmentReviewUtils.APP_ENROLLMENT_CANCELED_STATUS) {
            returnPage = new PageReference ('/' + this.appEnrollment.Id);
            return returnPage;
        }

        // Set the statuses for company info / program enrollment
        for (BIGPGEEnrollmentReviewItem reviewItem : this.reviewItemsMap.values()) {
            success = success && reviewItem.setStatus();
        }

        if (!success) {
            errorMessage = 'Error updating review step items statuses.';
        } else {
            // If all steps are approved then finish the current review
            if (this.companyInformationReview.isStatusFinal()
                && (this.acqcReview == null || this.acqcReview.isStatusFinal())
                && (this.ahuReview == null || this.ahuReview.isStatusFinal())
                && (this.huReview == null || this.huReview.isStatusFinal())) {

                success = BIGPGEEnrollmentReviewUtils.setEnrollmentApplicationStatus(this.appEnrollment,
                        BIGPGEEnrollmentReviewUtils.APP_ENROLLMENT_COMPLETED_STATUS);
            } else {
                // If review hasn't finished, make sure to check in the enrollment review status
                success = BIGPGEEnrollmentReviewUtils.setEnrollmentApplicationStatus(this.appEnrollment,
                        BIGPGEEnrollmentReviewUtils.APP_ENROLLMENT_CHECKED_IN_STATUS);
            }

            // If company information was approved and at least one of the programs was approved
            // Create/set existing account for the enrollment if needed and enroll the approved programs
            // for the account.
            if (success && this.companyInformationReview.isApproved()
                        && ((this.acqcReview != null && this.acqcReview.isApproved())
                             || (this.ahuReview != null && this.ahuReview.isApproved())
                             || (this.huReview != null && this.huReview.isApproved()))) {

                Map<Id, Program_Enrollment__c> appProgEnrollmentIdToProgramEnrollmentMap =
                        new Map<Id, Program_Enrollment__c>();
                Map<String, Application_Program_Enrollment_Review__c> appProgEnrollmentIdToReviewItemMap =
                        new Map<String, Application_Program_Enrollment_Review__c>();

                if (this.companyInformationReview.appEnrollment.Account__c == null) {
                    success = this.companyInformationReview.setEnrollmentAccount();
                }

                if (success && this.acqcEnrollment != null && this.acqcEnrollment.Program_Enrollment__c == null
                        && this.acqcEnrollment.Status__c == 'Approved') {

                    appProgEnrollmentIdToProgramEnrollmentMap.put(acqcEnrollment.Id,
                            this.acqcReview.finishProgramEnrollment(this.appEnrollment.Account__c));
                    appProgEnrollmentIdToReviewItemMap.put('ACQC', this.acqcReview.programReview);
                    success = appProgEnrollmentIdToProgramEnrollmentMap.get(acqcEnrollment.Id) != null;
                }

                if (success && this.ahuEnrollment != null && this.ahuEnrollment.Program_Enrollment__c == null
                        && this.ahuEnrollment.Status__c == 'Approved') {

                    appProgEnrollmentIdToProgramEnrollmentMap.put(ahuEnrollment.Id,
                            this.ahuReview.finishProgramEnrollment(this.appEnrollment.Account__c));
                    appProgEnrollmentIdToReviewItemMap.put('AHU', this.ahuReview.programReview);
                    success = appProgEnrollmentIdToProgramEnrollmentMap.get(ahuEnrollment.Id) != null;

                    // Forcefully approve HU step if present.
                    if (this.huEnrollment != null) {
                        // initialize HU step
                        BIGPGEEnrollmentReviewItem huReviewTmp = BIGPGEEnrollmentReviewUtils.getProgramReview(
                                this.huEnrollment);
                        BIGPGEEnrollmentReviewUtils.updateProgramEnrollmentsOnAccountMatching(
                                this.appEnrollment.Account__c, new List<BIGPGEEnrollmentReviewItem>{huReviewTmp});

                        if (huEnrollment.Status__c != 'Already Enrolled') {
                            huEnrollment.Status__c = 'Approved';
                            appProgEnrollmentIdToProgramEnrollmentMap.put(huEnrollment.Id,
                                    huReviewTmp.finishProgramEnrollment(this.appEnrollment.Account__c));
                            success = appProgEnrollmentIdToProgramEnrollmentMap.get(huEnrollment.Id) != null;
                        }
                    }
                }

                if (success  && this.ahuEnrollment == null && this.huEnrollment != null
                        && this.huEnrollment.Program_Enrollment__c == null
                        && this.huEnrollment.Status__c == 'Approved') {

                    appProgEnrollmentIdToProgramEnrollmentMap.put(huEnrollment.Id,
                            this.huReview.finishProgramEnrollment(this.appEnrollment.Account__c));
                    appProgEnrollmentIdToReviewItemMap.put('HU', this.huReview.programReview);
                    success = appProgEnrollmentIdToProgramEnrollmentMap.get(huEnrollment.Id) != null;
                }

                // Process staff
                if (success) {
                    success = BIGPGEEnrollmentReviewDataMappingUtils.processEnrollmentStaff(this.appEnrollment,
                            appProgEnrollmentIdToProgramEnrollmentMap);
                }

                // Process program files
                if (success) {
                    success = BIGPGEEnrollmentReviewDataMappingUtils.processProgramEnrollment(this.appEnrollment,
                            appProgEnrollmentIdToProgramEnrollmentMap, appProgEnrollmentIdToReviewItemMap);
                }

                // Process credentials
                if (success) {
                    success = BIGPGEEnrollmentReviewDataMappingUtils.processAppEnrollmentCredentials(this.appEnrollment.id,
                            this.appEnrollment.Account__c, this.companyInformationReview.appReview);
                }

                // Populate program enrollment field on application program enrollments
                if (success) {
                    success = BIGPGEEnrollmentReviewDataMappingUtils.setProgramEnrollmentFieldToAppProgramEnrollment(
                            appProgEnrollmentIdToProgramEnrollmentMap);
                }
            }
        }

        if (success) {
            success = this.companyInformationReview.setFinishedFlag();
        } else {
            success = false;
            // Don't set/create the account and rollback the changes
            Database.rollback(sp);
        }

        if (success) {
            returnPage = new PageReference ('/' + this.appEnrollment.Id);
        } else {
            errorMessage = String.isNotBlank(errorMessage) ? errorMessage : BIGPGEEnrollmentReviewUtils.REVIEW_MESSAGE_ERROR;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }

        return returnPage;
    }

    public void updateTaxID() {
        Account newMatchingAccount = BIGPGEEnrollmentReviewUtils.getAccountByTaxID (
                                                    this.companyInformationReview.appReview.Tax_ID_Number__c);

        if (newMatchingAccount != null) {
            this.accountMatching = new List<Account>{newMatchingAccount};
        }
        else {
            this.accountMatching = BIGPGEEnrollmentReviewUtils.getSimilarAccounts (this.appEnrollment, this.companyInformationReview.appReview.Tax_ID_Number__c);
        }
    }

    public Boolean getExperienceAlreadyProven() {
        return (this.acqcReview != null && this.reviewItemsMap.get(this.currentReviewIndex) != this.acqcReview && this.acqcReview.programReview.Company_Operation_Proof__c == 'Yes')
                || (this.ahuReview != null && this.reviewItemsMap.get(this.currentReviewIndex) != this.ahuReview && this.ahuReview.programReview.Company_Operation_Proof__c == 'Yes')
                || (this.huReview != null && this.reviewItemsMap.get(this.currentReviewIndex) != this.huReview && this.huReview.programReview.Company_Operation_Proof__c == 'Yes');
    }

    public void skipToStep() {
        BIGPGEEnrollmentReviewItem mainReviewItem = this.reviewItemsMap.get(targetReviewIndex);
        if (mainReviewItem != null) {

            // Use a generic sObject to point either to the app review or the program review
            sObject reviewRecord = (mainReviewItem.appReview != null) ? (sObject) mainReviewItem.appReview
                                                                      : (sObject) mainReviewItem.programReview;

            reviewRecord.put(mainReviewItem.subStatusFieldsMap.get(0), BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS);

            // Make the current step unread
            this.reviewItemsMap.get(targetReviewIndex).setStatus(BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS);

            // Make the current step review substeps unread
            for (String currentSubStatusField : this.reviewItemsMap.get(targetReviewIndex).subStatusFieldsMap.values()) {
                this.reviewItemsMap.get(targetReviewIndex).getReviewObject().put(currentSubStatusField, BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_UNREAD_STATUS);
            }
        }

        List<Application_Program_Enrollment_Review__c> appProgEnrollmentsToUpdate = null;

        // Skip the previous programs if they are unread
        for (Integer i = 1; i < targetReviewIndex; i++) {
            appProgEnrollmentsToUpdate = new List<Application_Program_Enrollment_Review__c>();
            if (this.reviewItemsMap.containsKey(i) && this.reviewItemsMap.get(i).isUnread()) {
                this.reviewItemsMap.get(i).setStatus(BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_SKIPPED_STATUS);
                appProgEnrollmentsToUpdate.add (this.reviewItemsMap.get(i).programReview);

                for (Integer j = 0; j < this.reviewItemsMap.get(i).subStatusFieldsMap.size(); j++) {
                    this.reviewItemsMap.get(i).getReviewObject().put(this.reviewItemsMap.get(i).subStatusFieldsMap.get(j), BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_SKIPPED_STATUS);
                }
            }
        }

        if (appProgEnrollmentsToUpdate != null) {
            try {
                upsert appProgEnrollmentsToUpdate;
            } catch (DmlException e) {
                System.debug ('Error updating program reviews: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
            } catch (Exception e) {
                System.debug ('Error updating program reviews: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage()));
            }
        }

        this.currentReviewSubIndex = 0;
        this.targetReviewIndex = 0;
    }

    public class myException extends exception{}
}