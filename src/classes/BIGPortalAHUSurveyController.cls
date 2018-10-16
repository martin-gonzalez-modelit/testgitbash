/**
 * This controller handles the BIGPortalAHUSurvey visualforce component.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2018-6
 */
public with sharing class BIGPortalAHUSurveyController {
    private static final String SURVEY_COOKIE_NAME = 'ahu_survey';
    public Boolean render { get; set; }

    public String sid {
        get {
            return EncodingUtil.urlEncode(UserInfo.getSessionId(), 'UTF-8');
        }
    }

    public BIGPortalAHUSurveyController () {
        BIGPortalUser userUtility = new BIGPortalUser();

        if (userUtility.hasAdvanceHUProgram() && !userUtility.isAHUSuspended()) {
            String cookieKey = SURVEY_COOKIE_NAME + '_' + sid;
            List<Cookie> cookies = new List<Cookie>();
            Cookie surveyCookie = getSurveyCookie();
            
            System.debug('### surveyCookie: ' + surveyCookie);
            if (surveyCookie != null) System.debug('### getName: ' + surveyCookie.getName());
            System.debug('### cookieKey: ' + cookieKey);

            if (surveyCookie == null || surveyCookie.getName() != cookieKey) {
                // If the survey cookie name does not match with the current cookie key means it was issued with an old
                // session id, so setting expiration date to '0' will remove the old cookie from the current cookies.
                if (surveyCookie != null && surveyCookie.getName() != cookieKey) {
                    cookies.add(new Cookie(surveyCookie.getName(), 'show', '/pgeportal', 0, true));
                }
                surveyCookie = new Cookie(cookieKey, 'show', '/pgeportal', -1, true);
                cookies.add(surveyCookie);
                ApexPages.currentPage().setCookies(cookies);
            }

            render = surveyCookie.getValue() == 'show';
        } else {
            render = false;
        }
    }

    /**
     * Gets the survey cookie if it was set previously.
     *
     * @return The survey cookie if it was found, otherwise null.
     */
    private Cookie getSurveyCookie() {
        Cookie surveyCookie;

        for (String key : ApexPages.currentPage().getCookies().keySet()) {
            if (key.startsWith(SURVEY_COOKIE_NAME)) {
                surveyCookie = ApexPages.currentPage().getCookies().get(key);
                break;
            }
        }

        return surveyCookie;
    }
}