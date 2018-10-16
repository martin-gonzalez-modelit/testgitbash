/**
 *
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2013-3
 */
public with sharing class BIGPortalUser {
    private Contact usrContact;
    private Account usrAccount;
    private Set<String> suspendedPrograms;
    private Set<String> terminatedPrograms;

    public BIGPortalUser() {
        // Get current user
        User u = [
            SELECT Id, Contact.Id, Contact.AccountId, Contact.Program_Tab_Selection__c, Contact.Program_Enrollment__c,
                    Contact.Default_Program__c
            FROM User
            WHERE Id = :UserInfo.getUserId() //'00518000002S4gu'
            ];

        usrContact = u.Contact;
        usrAccount = [
            SELECT Id, Name, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                (SELECT Credential_Type__c FROM Credentials__r),
                (SELECT Id, RecordType.Name, Enrollment_Status__c FROM Program_Enrollments__r)
            FROM Account
            WHERE Id = :usrContact.AccountId
            ];

        suspendedPrograms = new Set<String>();
        terminatedPrograms = new Set<String>();

        for (Program_Enrollment__c programEnrollment : getAccount().Program_Enrollments__r) {
            if (programEnrollment.Enrollment_Status__c == ApplicationUtils.PROGRAM_ENROLLMENT_SUSPENDED_STATUS) {
                suspendedPrograms.add(programEnrollment.RecordType.Name);
            } else if (programEnrollment.Enrollment_Status__c == 'Terminated') {
                terminatedPrograms.add(programEnrollment.RecordType.Name);
            }
        }
    }

    public Contact getContact() {
        return usrContact;
    }

    public Account getAccount() {
        return usrAccount;
    }

    public Boolean hasACQCProgram() {
        if (usrContact.Program_Enrollment__c != null) {
            return usrContact.Program_Enrollment__c.indexOf('ACQC') >= 0;
        } else {
            return false;
        }
    }

    public Boolean hasAdvanceHUProgram() {
        if (usrContact != null && usrContact.Program_Enrollment__c != null) {
            return usrContact.Program_Enrollment__c.indexOf('AHU') >= 0;
        } else {
            return false;
        }
    }

    public Boolean hasHUProgram() {
        if (usrContact != null && usrContact.Program_Enrollment__c != null) {
            return usrContact.Program_Enrollment__c.indexOf('HU') >= 0;
        } else {
            return false;
        }
    }

    public Contact getBPIAnalystById(String pId) {
        try {
            List<Contact> res = [
                SELECT Id, Name, First_Name__c, Last_Name__c, BPI_License_Number__c FROM Contact WHERE Id = :pId
                ];
            if (!res.isEmpty()) {
                return res[0];
            }
        } catch (QueryException e) {
            System.debug('BIGPortalUser.getBPIAnalystById():' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('BIGPortalUser.getBPIAnalystById():' + e.getStackTraceString());
        }
        return null;
    }

    /**
     * Check if ACQC Program Enrollment is in "Suspended" Status.
     *
     * @return True if ACQC Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean isACQCSuspended() {
        return suspendedPrograms.contains('ACQC');
    }

    /**
     * Check if HU Program Enrollment is in "Suspended" Status.
     *
     * @return True if HU Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean isHUSuspended() {
        return suspendedPrograms.contains('HU');
    }

    /**
     * Check if AHU Program Enrollment is in "Suspended" Status.
     *
     * @return True if AHU Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean isAHUSuspended() {
        return suspendedPrograms.contains('AHU');
    }

    /**
     * Check if HU Program Enrollment is in "Terminated" Status.
     *
     * @return True if HU Program Enrollment is in "Terminated" status, otherwise return false.
     */
    public Boolean isHUTerminated() {
        return terminatedPrograms.contains('HU');
    }
}