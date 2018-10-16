/**
 * This class contains unit tests for validating the behavior 
 * of HPXMLResponseWrapper.
 */
@isTest
private class TestHPXMLResponseWrapper {

    static testMethod void testHPXMLResponseWrapper() {
    	Test.startTest();
    	
    	HPXMLResponseWrapper wrapper = new HPXMLResponseWrapper();
    	
    	string jsonString = '{"success":false, "errorMessage":"My test error message", "exceptionMessage": "My exception message"}';
    	
    	wrapper = (HPXMLResponseWrapper)JSON.deserialize(jsonString, HPXMLResponseWrapper.Class);
    	
    	boolean testSuccess = wrapper.getSuccess();
    	System.assertEquals(testSuccess, false);
    	
    	string testError = wrapper.getErrorMessage();
    	System.assertEquals(testError, 'My test error message');
    	
    	string testException = wrapper.getExceptionMessage();
    	System.assertEquals(testException, 'My exception message');
    }
	
}