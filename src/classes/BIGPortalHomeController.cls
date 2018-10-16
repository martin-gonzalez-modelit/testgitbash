public with sharing class BIGPortalHomeController {
	
	public BIGPortalHomeController() {
	
	}
	
	public PageReference skipHome() {
		return new PageReference('/bigportalmanagebuilding').setRedirect(true);
	}

}