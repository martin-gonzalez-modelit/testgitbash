public class BIGPGEEnrollmentReviewItem {
	public Enrollment_Application_Review__c appReview {get; set;}
	public Application_Program_Enrollment_Review__c programReview {get; set;}

    public sObject getReviewObject() {
		// Use a generic sObject to point either to the app review or the program review
		return (this.appReview != null) ?  (sObject) this.appReview
				   					    :  (sObject) this.programReview;
	}

    public Boolean isApproved() {
		Boolean isApproved = false;

		isApproved = (this.appReview != null) ? this.appReview.Approval_Status__c == 'Approved'
											  : this.programReview.Approval_Status__c == 'Approved';

		return isApproved;
	}

    public Boolean isUnread() {
        Boolean isUnread = false;

        if (this.appReview != null) {
            if (this.appReview.Approval_Status__c == null) {
                this.appReview.Approval_Status__c = 'Unread';
            }
            isUnread = this.appReview.Approval_Status__c == 'Unread';
        } else {
            if (this.programReview.Approval_Status__c == null) {
                this.programReview.Approval_Status__c = 'Unread';
            }
            isUnread = this.programReview.Approval_Status__c == 'Unread';
        }

        return isUnread;
    }

    public Application_Program_Enrollment__c appProgramEnrollment {get; set;}
    public Application_Enrollment__c appEnrollment {get; set;}

    public String statusField {get; set;}
    public String approvalStatusField {get; set;}
    public Map<Integer, String> subStatusFieldsMap {get; set;}
    public Map<Integer, Set<String>> approvalFieldSetMap {get; set;}
    public Map<String, Attachment> docTypeToAttachment {get; set;}

    public BIGPGEEnrollmentReviewItem(Enrollment_Application_Review__c appReview,
                                      Application_Enrollment__c appEnrollment,
                                      String statusField,
                                      Map<Integer, String> subStatusFieldsMap,
                                      Map<Integer, Set<String>> approvalFieldSetMap,
                                      Map<String, Attachment> docTypeToAttachment) {

        this.appReview = appReview;
        this.appEnrollment = appEnrollment;
        this.statusField = statusField;
        this.subStatusFieldsMap = subStatusFieldsMap;
        this.approvalFieldSetMap = approvalFieldSetMap;
        this.docTypeToAttachment = docTypeToAttachment;
        this.approvalStatusField = null;
    }

    public BIGPGEEnrollmentReviewItem(Application_Program_Enrollment_Review__c programReview,
                                      Application_Program_Enrollment__c appProgramEnrollment,
                                      String statusField,
                                      Map<Integer, String> subStatusFieldsMap,
                                      Map<Integer, Set<String>> approvalFieldSetMap,
                                      Map<String, Attachment> docTypeToAttachment) {

        this.programReview = programReview;
        this.appProgramEnrollment = appProgramEnrollment;
        this.statusField = statusField;
        this.subStatusFieldsMap = subStatusFieldsMap;
        this.approvalFieldSetMap = approvalFieldSetMap;
        this.docTypeToAttachment = docTypeToAttachment;
        this.approvalStatusField = null;
    }

	// Method to update either company information or program enrollment status
	// Depending on review item type

    public Boolean setStatus() {
		List<Application_Program_Enrollment__c> appProgEnrollmentsToUpdate = new List<Application_Program_Enrollment__c>();
		Boolean success = true;
		Application_Program_Enrollment__c huProgram;

		// Application review (company information)
		if (this.appReview != null && appEnrollment != null) {
			if (this.appReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REVIEW_APPROVED_STATUS) {
				this.appEnrollment.Company_Info_Status__c = BIGPGEEnrollmentReviewUtils.COMPANY_INFO_APPROVED_STATUS;
			} else if (this.appReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REVIEW_REJECTED_STATUS) {
				this.appEnrollment.Company_Info_Status__c = BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REJECTED_STATUS;
			} else if (this.appReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REVIEW_REQUEST_INFO_STATUS) {
				this.appEnrollment.Company_Info_Status__c = BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REQUEST_INFO_STATUS;
			} else if (this.appReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REVIEW_REJECTED_STATUS) {
				this.appEnrollment.Company_Info_Status__c = BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REJECTED_STATUS;
			}

            try {
                update this.appEnrollment;
            } catch (DmlException e) {
                System.debug ('Error updating app enrollment: ' + e.getMessage());
                success = false;
            } catch (Exception e) {
                System.debug ('Error updating app enrollment: ' + e.getMessage());
                success = false;
            }
		} else if (this.programReview != null && appProgramEnrollment != null) {
			// If the review item it's an AHU program then retrieve the HU one to update as well.
			if (this.appProgramEnrollment.RecordTypeId == BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_AHU_RECORDTYPE_ID) {
				huProgram =	BIGPGEEnrollmentReviewUtils.getProgramEnrollmentByApplicationEnrollmentIdAndRtName(this.appProgramEnrollment.Application_Enrollment__c, 'HU');
			}

			if (this.programReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_APPROVED_STATUS) {
				this.appProgramEnrollment.Status__c = BIGPGEEnrollmentReviewUtils.PROGRAM_APPROVED_STATUS;
			} else if (this.programReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REJECTED_STATUS) {
				this.appProgramEnrollment.Status__c = BIGPGEEnrollmentReviewUtils.PROGRAM_REJECTED_STATUS;
			} else if (this.programReview.Approval_Status__c == BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REQUEST_INFO_STATUS) {
				this.appProgramEnrollment.Status__c = BIGPGEEnrollmentReviewUtils.PROGRAM_REQUEST_INFO_STATUS;
			}

			if (huProgram != null) {
				huProgram.Status__c = this.appProgramEnrollment.Status__c;
				appProgEnrollmentsToUpdate.add(huProgram);
			}
			appProgEnrollmentsToUpdate.add(this.appProgramEnrollment);

			try {
				update appProgEnrollmentsToUpdate;
			}
			catch (DmlException e) {
				System.debug ('Error updating app enrollment: ' + e.getMessage());
				success = false;
			}
			catch (Exception e) {
				System.debug ('Error updating app enrollment: ' + e.getMessage());
				success = false;
			}
		} else {
			success = false;
		}

		return success;
	}

    public Void setStatus(String status) {
		if (status != null && status != '') {
			this.getReviewObject().put('Approval_Status__c', status);
		}
	}

    /* Returns a boolean indicating if a status accounts for finishing an application */
    public Boolean isStatusFinal() {
    	Boolean statusFinal = true;

    	if (this.appEnrollment != null) {
    		statusFinal = this.appEnrollment.Company_Info_Status__c == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_APPROVED_STATUS
    						|| this.appEnrollment.Company_Info_Status__c == BIGPGEEnrollmentReviewUtils.COMPANY_INFO_REJECTED_STATUS;

    	}
    	else {
    		statusFinal = this.appProgramEnrollment.Status__c == BIGPGEEnrollmentReviewUtils.PROGRAM_APPROVED_STATUS
    						|| this.appProgramEnrollment.Status__c == BIGPGEEnrollmentReviewUtils.PROGRAM_REJECTED_STATUS;
    	}

    	return statusFinal;
    }

    public Boolean areStepFieldsApproved(Integer substepIndex, Set<String> overridenFields) {
    	Boolean isApproved = true;

    	sObject reviewItem = this.getReviewObject();

		if (this.approvalFieldSetMap.containsKey(subStepIndex)
			&& this.approvalFieldSetMap.get(subStepIndex).size() > 0) {

			for (String approvalField : this.approvalFieldSetMap.get(substepIndex)) {
				isApproved = isApproved && (reviewItem.get(approvalField) == 'Yes'
											  || reviewItem.get(approvalField) == 'Override')
									      || overridenFields.contains(approvalField);

				if (overridenFields.contains(approvalField)) {
					// Automatically aprove overriden fields
					reviewItem.put(approvalField, 'Yes');
				}

			}
		}

		return isApproved;
    }

    public Boolean setEnrollmentAccount() {
        Boolean success = true;

        if (this.appEnrollment != null && this.appReview != null) {
            try{
                if (this.appReview.Match_Account__c != null) {
                    Account enrollmentAccount = new Account(Id = appReview.Match_Account__c);
                    enrollmentAccount.Tax_Status__c = this.appReview.Tax_Status__c;
                    enrollmentAccount.Tax_ID_Number__c = this.appReview.Tax_ID_Number__c;
                    enrollmentAccount.Workers_Compensation_Type__c = this.appReview.Workers_Compensation_Type__c;
                    // Per requirements just update account record type from Rater to Contractor.
                    if (this.appReview.Company_Type__c == BIGPGEEnrollmentReviewUtils.ACCOUNT_CONTRACTOR_RT_NAME) {
                        enrollmentAccount.RecordTypeId = BIGPGEEnrollmentReviewUtils.ACCOUNT_CONTRACTOR_RECORDTYPE_ID;
                    }
                    update enrollmentAccount;
                    this.appEnrollment.Account__c = enrollmentAccount.Id;
                } else {
                    this.createAccount();
                    success = this.appEnrollment.Account__c != null;
                }
            } catch (DmlException e) {
                System.debug ('Error updating account:' + e.getMessage());
                success = false;
            } catch (Exception e) {
                System.debug ('Error updating account:' + e.getMessage());
                success = false;
            }
        } else {
            success = false;
        }

        if (success) {
            try {
                upsert this.appEnrollment;
            } catch (DmlException e) {
                System.debug ('Error updating app enrollment:' + e.getMessage());
                success = false;
            } catch (Exception e) {
                System.debug ('Error updating app enrollment:' + e.getMessage());
                success = false;
            }
        }

        return success;
    }

    public void createAccount() {
        Account enrollmentAccount = new Account();

        enrollmentAccount.Name = this.appEnrollment.Company_Name__c;
        enrollmentAccount.RecordTypeId = (this.appReview.Company_Type__c == BIGPGEEnrollmentReviewUtils.ACCOUNT_CONTRACTOR_RT_NAME)
                                         ? BIGPGEEnrollmentReviewUtils.ACCOUNT_CONTRACTOR_RECORDTYPE_ID
                                         : BIGPGEEnrollmentReviewUtils.ACCOUNT_RATER_RECORDTYPE_ID;
        enrollmentAccount.DBA__c = this.appEnrollment.DBA__c;
        enrollmentAccount.Tax_ID_Number__c = this.appReview.Tax_ID_Number__c;
        enrollmentAccount.Tax_Status__c = this.appReview.Tax_Status__c;
        enrollmentAccount.Workers_Compensation_Type__c = this.appReview.Workers_Compensation_Type__c;
        enrollmentAccount.BillingStreet = this.appEnrollment.Address__c;
        enrollmentAccount.BillingCity = this.appEnrollment.City__c;
        enrollmentAccount.BillingState = 'CA';
        enrollmentAccount.BillingPostalCode = this.appEnrollment.Zip_Code__c;
        enrollmentAccount.Website = this.appEnrollment.Website__c;
        enrollmentAccount.In_PGE_SoCalGas_Shared_Territory__c = this.appEnrollment.Service_Territory__c;

        try {
            insert enrollmentAccount;
        } catch (DmlException e) {
            System.debug('Error inserting new account: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error inserting new account: ' + e.getMessage());
        }

        this.appEnrollment.Account__c = enrollmentAccount.Id;
    }

    public Program_Enrollment__c finishProgramEnrollment(Id accountId) {
		Program_Enrollment__c programEnrollment = null;

		if (this.appProgramEnrollment != null && this.appProgramEnrollment.Status__c == 'Approved' && accountId != null) {

			Id programEnrollmentRecordTypeId = null;

			programEnrollment = new Program_Enrollment__c();
			programEnrollment.Account__c = accountId;
			programEnrollment.RecordTypeId =
				BIGPGEEnrollmentReviewUtils.APP_PROG_ENROLLMENT_TO_PROG_ENROLLMENT_RTYPE_MAP.get(this.appProgramEnrollment.RecordTypeId);
			if (this.appProgramEnrollment.RecordTypeId == BIGPGEEnrollmentReviewUtils.APP_PROGRAM_ENROLLMENT_ACQC_RECORDTYPE_ID) {
                programEnrollment.Enrollment_Status__c = BIGPGEEnrollmentReviewUtils.PROGRAM_APPROVED_STATUS;
			} else {
                programEnrollment.Enrollment_Status__c = BIGPGEEnrollmentReviewUtils.PROGRAM_FULL_PARTICIPATION_STATUS;
			}
			//programEnrollment.Enrollment_Date__c = this.appProgramEnrollment.CreatedDate.date();

			try {
				insert programEnrollment;
			}
			catch (DmlException e) {
				System.debug ('Error inserting new program enrollment: '+ e.getMessage());
			}
			catch (Exception e) {
				System.debug ('Error inserting new program enrollment: '+ e.getMessage());
			}
		}

		if (programEnrollment != null) {
			// Set the status for this review to already enrolled
			this.programReview.Approval_Status__c = BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_ALREADY_ENROLLED_STATUS;
		}

		return programEnrollment;
	}

    public Boolean setFinishedFlag() {
		Boolean success = true;

		if (this.appReview != null) {
			this.appEnrollment.Is_Review_Finished__c = true;

			try {
				update this.appEnrollment;
			}
			catch (DmlException e) {
				System.debug ('Error updating finished flag ' + e.getMessage());
			}
			catch (Exception e) {
				System.debug ('Error updating finished flag ' + e.getMessage());
			}
		}

		return success;
	}

    public void rejectAllSteps() {

		sObject reviewObject = (this.programReview != null) ? (sObject) this.programReview : (sObject) this.appReview;

		if (this.subStatusFieldsMap != null && reviewObject != null) {
			for (String currentField : this.subStatusFieldsMap.values()) {
				reviewObject.put (currentField, BIGPGEEnrollmentReviewUtils.REVIEW_ITEM_REJECTED_STATUS);
			}
		}
	}
}