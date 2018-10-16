/**
 * This controller handles BIGPortalProgram page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2013-6
 */
public with sharing class BIGPortalProgramController {

    public PageReference checkPortal() {
        BIGPortalUser userUtility = new BIGPortalUser();
        Contact userContact = userUtility.getContact();
        PageReference redirect;

        if (String.isBlank(userContact.Program_Enrollment__c)) {
            redirect = Page.AccessDenied;
        } else {
            Boolean hasACQC = userUtility.hasACQCProgram();
            Boolean hasHU = userUtility.hasHUProgram();
            Boolean hasAHU = userUtility.hasAdvanceHUProgram();

            if (hasACQC && (hasHU || hasAHU)) {
                String program = System.currentPageReference().getParameters().get('p'); // if parameter is passed
                if (String.isNotBlank(program)) {
                    userContact.Default_Program__c = String.escapeSingleQuotes(program);
                    update userContact;
                }
                String defaultProgram = userContact.Default_Program__c;
                if (String.isBlank(defaultProgram)) {
                    return null;
                } else if (defaultProgram == 'ACQC') {
                    redirect = Page.BIGACQCDashboard;
                } else if (defaultProgram == 'HU' || defaultProgram == 'AHU') {
                    redirect = Page.BIGPortalManageDashboard;
                }
            } else if (hasACQC) {
                redirect = Page.BIGACQCDashboard;
            } else if (hasHU || hasAHU){
                redirect = Page.BIGPortalManageDashboard;
            } else {
                redirect = Page.AccessDenied;
            }
        }
        redirect.setRedirect(true);

        return redirect;
    }
}