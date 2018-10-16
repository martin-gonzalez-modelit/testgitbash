public with sharing class BIGACQCRebateApplicationReviewController {

    public Boolean hasComments { get; set; }
    public Boolean hasIssues { get; set; }
    private List<String> applicationErrors = new List<String>();
    private Review__c review;

    public BIGACQCRebateApplicationReviewController() {
        review = getReview();
        hasIssues = String.isNotBlank(review.Comments__c);
        hasComments = String.isNotBlank(review.Additional_Comments__c);
    }

    public void checkAction() {
        if (review.Status__c == 'Approved') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rebate Application Form has been approved.'));
        } else if (review.Status__c == 'Rejected') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rebate Application Form has been rejected.'));
        } else if (review.Status__c == 'Correction Required') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rebate Application Form has been marked as Contractor Action Required.'));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rebate Application Form has been saved successfully.'));
        }
    }

    public Boolean getHasError() {
        return ApexPages.hasMessages(ApexPages.Severity.ERROR);
    }

    public Application__c getApplication() {
        String appId = System.currentPageReference().getParameters().get('id');

        if (String.isNotBlank(appId)) {
            List<Application__c> custs = [
                    SELECT Id, Name, Contractor__c, Building_Name__c, Building_Street_Address__c, Building_City__c,
                        Building_State__c, Building_Zip_Code__c, Customer_Phone__c, Customer_Email__c, Unit__r.Name,
                        Payable_to_Contractor__c, Status__c, Electric_Account_Number__c, PG_E_Sticker_Number__c,
                        Technician__c, Notes__c, Approval_Override__c, Customer_First_Name__c, Customer_Last_Name__c
                    FROM Application__c
                    WHERE Id = :appId
                    ];
            if (!custs.isEmpty()) {
                return custs.get(0);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                        'Application record does not exist.'));
            }
        }

        return new Application__c();
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

    public String getTechnicianStatus() {
        Application__c app = getApplication();
        String rtId = Schema.SObjectType.Program_Enrollment__c.getRecordTypeInfosByName().get('ACQC').getRecordTypeId();

        List<Employee_Program_Enrollment__c> epes = [
            SELECT Enrollment_Stage__c
            FROM Employee_Program_Enrollment__c
            WHERE Contact__c = :app.Technician__c AND Program_Enrollment__r.RecordTypeId = :rtId
            ];

        if (!epes.isEmpty()) {
            return epes.get(0).Enrollment_Stage__c;
        } else {
            return 'No status';
        }
    }

    public String getApplicationFormId() {
        return getAttachmentId('HVAC Rebate Application Form');
    }

    public String getApplicationFormFileDownload(){
        return getFileDownload(getApplicationFormId());
    }


    private String getFileDownload(String id) {
        String aId = '';
        List<Attachment> atts = [select Id, Name, Body, ParentId from Attachment where ParentId = :id];
        if (!atts.isEmpty()) {
            aId = atts.get(0).Id;
        }
        return '/servlet/servlet.FileDownload?file=' + aId;
    }

    private String getAttachmentId(String fileType) {
        Application__c a = getApplication();
        List<Application_File__c> cefs = [
            SELECT Id, File_Name__c
            FROM Application_File__c WHERE Application__c = :a.Id AND Application_File_Type__c = :fileType
            ];

        if (!cefs.isEmpty()) {
            return cefs.get(0).Id;
        }
        return '';
    }

    public String getHVACWorkAttachmentDownloadUrl() {
        return getFileDownload(getAttachmentId('HVAC Work - Cost Estimates'));
    }

    public List<ACQC_Review_Message__c> getReviewMessages() {
        return [SELECT Field__c, Message__c FROM ACQC_Review_Message__c];
    }

    public PageReference validateRebateApplication() {
        List<String> errors = new List<String>();
        Application__c app = getApplication();

        if (!app.Approval_Override__c) {
            Account contractor = [
                SELECT Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, Tax_ID_Number__c
                FROM Account WHERE Id = :app.Contractor__c
                ];
            Unit__c unit = [
                SELECT Site__c, Site__r.Address_1__c, Site__r.City__c, Site__r.State__c, Site__r.Zip__c,
                    Total_Unit_Capacity__c, Make__c, Equipment_Type__c, Model__c, Serial__c
                FROM Unit__c WHERE Id = :app.Unit__c
                ];
            Boolean hasError = false;
            String numericPhone = '';

            // Validation
            if (String.isBlank(app.Electric_Account_Number__c)) {
                errors.add('This Application does not have an Electric Account Number.');
                hasError = true;
            } else if (!app.Electric_Account_Number__c.isNumeric() || app.Electric_Account_Number__c.length() != 10) {
                errors.add('Electric Account Number must be exactly 10 digits');
                hasError = true;
            }
            if (String.isBlank(app.Customer_Last_Name__c) || String.isBlank(app.Customer_First_Name__c)) {
                errors.add('Contact has not been specified.');
                hasError = true;
            }
            if (app.Unit__c == null) {
                errors.add('This Application does not have a related Unit.');
                hasError = true;
            } else {
                if (unit.Site__c == null) {
                    errors.add('This Application does not have a related Site.');
                    hasError = true;
                } else {
                    if (unit.Site__r.Address_1__c == null) {
                        errors.add('Site does not have an Address');
                        hasError = true;
                    }
                    if (unit.Site__r.City__c == null) {
                        errors.add('Site does not have a City');
                        hasError = true;
                    }
                    if (unit.Site__r.State__c == null) {
                        errors.add('Site does not have a State');
                        hasError = true;
                    } else {
                        if (unit.Site__r.State__c.length() > 2) {
                            errors.add('Site must be a valid 2-character state code, CA.');
                            hasError = true;
                        }
                    }
                    if (String.isBlank(unit.Site__r.Zip__c)) {
                        errors.add('Site does not have a Zip Code');
                        hasError  = true;
                    } else if (!unit.Site__r.Zip__c.isNumeric() || unit.Site__r.Zip__c.length() != 5) {
                        errors.add('Site Zip Code must be exactly 5 digits');
                        hasError = true;
                    }
                }
                if (unit.Total_Unit_Capacity__c == null) {
                    errors.add('Total Unit Capacity needs to be populated');
                    hasError = true;
                }
                if (unit.Make__c == null) {
                    errors.add('Unit Make is not specified');
                    hasError = true;
                }
                if (unit.Equipment_Type__c == null) {
                    errors.add('Unit Equipment Type is not specified');
                    hasError = true;
                } else {
                    if (unit.Equipment_Type__c.indexOf('Split') < 0 && unit.Equipment_Type__c.indexOf('Package') < 0) {
                        errors.add('Equipment Type should contain the word "Split" or "Package"');
                        hasError = true;
                    }
                }
                if (unit.Model__c == null) {
                    errors.add('Unit Condenser Model is not specified.');
                    hasError = true;
                }
            }
            if (app.Contractor__c == null) {
                errors.add('This Application does not have a Contractor');
                hasError = true;
            } else {
                if (contractor.BillingStreet == null) {
                    errors.add('Contractor does not have a Street Address');
                    hasError = true;
                }
                if (contractor.BillingCity == null) {
                    errors.add('Contractor does not have a City');
                    hasError = true;
                }
                if (contractor.BillingState == null) {
                    errors.add('Contractor does not have a State');
                    hasError = true;
                }
                if (contractor.BillingPostalCode == null) {
                    errors.add('Contractor does not have a Postal Code');
                    hasError = true;
                } else {
                    if (contractor.BillingPostalCode.length() != 5) {
                        errors.add('Contractor Zip Code must be exactly 5 digits');
                        hasError = true;
                    }
                }
                if (app.Payable_to_Contractor__c) {
                    if (contractor.Tax_ID_Number__c == null) {
                        errors.add('Contractor does not have a Tax ID Number');
                        hasError = true;
                    } else {
                        if (contractor.Tax_ID_Number__c.length() != 9) {
                            errors.add('Contractor Tax ID Number should be exaclty 9 digits');
                            hasError = true;
                        }
                    }
                }
            }
            if (String.isBlank(app.Building_Name__c)) {
                errors.add('Building Name is not specified');
                hasError = true;
            }
            if (app.Customer_Phone__c == null) {
                errors.add('Contact Phone is not specified');
                hasError = true;
            } else {
                numericPhone = app.Customer_Phone__c.replaceAll('[^0-9]', '');
                if (numericPhone.length() > 10) {
                    errors.add('Contact Phone cannot exceed 10 numbers');
                    hasError = true;
                }
            }

            List<Rebate_Application__c> ras = [SELECT Id FROM Rebate_Application__c WHERE Application__c = :app.Id];
            if (ras.isEmpty()) {
                //Retrieve all Inspection records
                List<Inspection__c> inspections = [
                    SELECT Id, Unit__r.Site__c, Log_Time__c
                    FROM Inspection__c WHERE Unit__c = :app.Unit__c ORDER BY Log_Time__c DESC
                    ];
                Datetime inspectionDate = null;
                //Inspection__c inspection = null;
                for (Inspection__c i : inspections) {
                    if ( inspectionDate == null) {
                        inspectionDate = i.Log_Time__c;
                    }
                }
                if (inspectionDate == null) {
                    inspections = [
                        SELECT Id, Site__c, Log_Time__c
                        FROM Inspection__c WHERE Site__c = :unit.Site__c ORDER BY Log_Time__c DESC
                        ];
                    for (Inspection__c i : inspections) {
                        if (inspectionDate == null) {
                            inspectionDate = i.Log_Time__c;
                        }
                    }
                }
                if (inspectionDate == null) {
                    errors.add('This Application does not have a valid Inspection record');
                    hasError = true;
                }
                //Retrieve all related Measures
                List<Measure__c> measures = [
                    SELECT Id, Application__c, Measure_Code__c FROM Measure__c WHERE Application__c= :app.Id
                    ];
                if (measures.isEmpty()) {
                    errors.add('This Application does not have related Measures');
                    hasError = true;
                }
            }
        }
        setApplicationErrors(errors);
        return null;
    }

    public void setApplicationErrors(List<String> errors) {
        applicationErrors = errors;
    }

    public List<String> getApplicationErrors() {
        return applicationErrors;
    }

}