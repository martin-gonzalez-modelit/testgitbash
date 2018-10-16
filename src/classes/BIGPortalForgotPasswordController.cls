public with sharing class BIGPortalForgotPasswordController {
	
	public String username { get; set; }
	public Boolean success { get; set; }   
       
    public BIGPortalForgotPasswordController() {
    	success = false;
    }
	
  	public PageReference forgotPassword() {
  		success = Site.forgotPassword(username);
  		return null;
  	}
  	
  	 @IsTest public static void testForgotPasswordController() {
    	// Instantiate a new controller with all parameters in the page
    	BIGPortalForgotPasswordController controller = new BIGPortalForgotPasswordController();
    	controller.username = 'test@salesforce.com';
    
    	System.assertEquals(controller.forgotPassword(),null); 
    }
}