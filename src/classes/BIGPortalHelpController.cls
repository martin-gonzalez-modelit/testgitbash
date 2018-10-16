/**
 * This class handles the redirection page for ACQC and HUP Portal help page depending on User access.
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2018-02
 */
public with sharing class BIGPortalHelpController {
    /**
     * Checks if the user has access to the ACQC program and if it's not the case, it redirects to exception page.
     *
     * @return The current page if the user has access to the ACQC program, or a redirect to the Access Denied page.
     */
    public PageReference checkUserACQCAccess() {
        return BIGUtility.checkACQCContactAccess(new BIGPortalUser());
    }

    /**
     * Checks if the user has access to either HU or AHU programs and if it's not the case,
     * it redirects to exception page.
     *
     * @return The current page if the user has access to HU/AHU programs, or a redirect to the Access Denied page.
     */
    public PageReference checkUserHUOrAHUAccess() {
        return BIGUtility.checkHUOrAHUContactAccess(new BIGPortalUser());
    }
}