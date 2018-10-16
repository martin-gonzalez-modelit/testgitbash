@isTest
public with sharing class BIGPortalHomeTest {

	static testMethod void testSkipHome(){
        BIGPortalHomeController controller = new BIGPortalHomeController();
		Test.startTest();
		controller.skipHome();
		Test.stopTest();		
	}
}