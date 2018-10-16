/**
 * This class contains test methodds for PG&E Enrollment URL rewrite class.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-08
 */
@isTest
public with sharing class TestBIGPGEEnrollmentSiteUrlRewriter {

    private static testMethod void testURLRewriting() {
        // Test incoming mapping
        BIGPGEEnrollmentSiteUrlRewriter rewriter = new BIGPGEEnrollmentSiteUrlRewriter();
        String urlResult = rewriter.mapRequestUrl(new PageReference('/login')).getUrl();
        System.assertEquals('/apex/bigpgeenrollmenthome', urlResult);
    }

    private static testMethod void testNonExistingURLRewriting() {
        // Test incoming mapping
        BIGPGEEnrollmentSiteUrlRewriter rewriter = new BIGPGEEnrollmentSiteUrlRewriter();
        PageReference pageResult = rewriter.mapRequestUrl(new PageReference('/dummypagetest'));
        System.assertEquals(null, pageResult);

        // Test outcoming mapping
        rewriter = new BIGPGEEnrollmentSiteUrlRewriter();
        List<PageReference> mySalesforceUrls = new List<PageReference>();
        mySalesforceUrls.add(Page.BIGPGEEnrollmentHome);

        System.assertNotEquals (null, rewriter.generateUrlFor(mySalesforceUrls));
    }

}