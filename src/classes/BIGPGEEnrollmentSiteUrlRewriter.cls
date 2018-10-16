/**
 * This class implements the interface Site.UrlRewriter. It maps the original URLs to user-friendly URLs.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2015-08
 */
global class BIGPGEEnrollmentSiteUrlRewriter implements Site.UrlRewriter {

    private static Set<String> URL_MAPPINGS = new Set<String> {
                                                                '/login',
                                                                '/company',
                                                                '/staff',
                                                                '/credentials',
                                                                '/insurance',
                                                                '/agreement',
                                                                '/confirmation',
                                                                '/summary',
                                                                '/retrieve',
                                                                '/resendemail',
                                                                '/help',
                                                                '/review'
                                                              };

    global PageReference mapRequestUrl(PageReference myFriendlyUrl) {
        String url = myFriendlyUrl.getUrl().toLowerCase();

        for (String uri : URL_MAPPINGS) {
            if (url.startsWith(uri)) {
                return Page.BIGPGEEnrollmentHome;
            }
        } 

        return null;
    }

    global PageReference[] generateUrlFor(PageReference[] mySalesforceUrls) {
        return mySalesforceUrls;
    }
}