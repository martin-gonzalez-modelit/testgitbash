/**
 * This controller handles the ACQC header component.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2013-06
 */
public with sharing class BIGPortalBaseController {
    private BIGPortalUser userUtility;

    public BIGPortalBaseController() {
        userUtility = new BIGPortalUser();
    }

    public Boolean getHasHUProgram(){
        return userUtility.hasHUProgram();
    }

    public String getAccountName(){
        return userUtility.getAccount().Name;
    }

}