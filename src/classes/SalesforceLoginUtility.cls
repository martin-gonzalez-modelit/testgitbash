/**
 * The following apex code demonstrates logging into another salesforce org via the SOAP/XML web service api
 * to get a valid session id.
 * Use session id across all APIs, including SOAP and REST endpoints.
 *
 * NOTES:
 * (1) You'll need to create a remote site setting for login url.
 * (2) You'll need to create a named credential if you want to skip remote site settings.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-10
 */
public with sharing class SalesforceLoginUtility {

    private static final String REQUEST_BODY = '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">'
            + '<Header/><Body><login xmlns="urn:partner.soap.sforce.com"><username>{0}</username>'
            + '<password>{1}</password></login></Body></Envelope>';
    private static final String SOAP_ENVELOPE_NS = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static final String PARTNER_NS = 'urn:partner.soap.sforce.com';
    private static final String REST_SERVICE = '/services/data/v40.0';

    private String sessionId;
    private String authEndpoint;
    private String serviceEndpoint;
    private String restEndpoint;

    public SalesforceLoginUtility(String username, String password, String endpoint) {
        login(username, password, endpoint);
    }

    public SalesforceLoginUtility(String namedCredential) {
        login(namedCredential);
    }

    public String getSessionId() {
        return sessionId;
    }

    public String getAuthEndpoint() {
        return authEndpoint;
    }

    public String getServiceEndpoint() {
        return serviceEndpoint;
    }

    public String getRestEndpoint() {
        return restEndpoint;
    }

    /**
     * Login via SOAP/XML web service api to establish session.
     *
     * @param username The username passed by the client.
     * @param password The password passed by the client.
     * @param endpoint The endpoint url passed by the client.
     */
    private void login(String username, String password, String endpoint) {
        String response = sendLoginRequest(username, password, endpoint);
        load(response);
    }

    /**
     * Login via SOAP/XML web service api to establish session.
     *
     * @param namedCredential The named credential specifies a callout endpoint and its required
     *        authentication parameters.
     */
    private void login(String namedCredential) {
        String response = sendLoginRequest(namedCredential);
        load(response);
    }

    /**
     * Perform request against the Soap API and return the response body.
     *
     * @param username The username passed by the client.
     * @param password The password passed by the client.
     * @param endpoint The endpoint url passed by the client.
     * @return The response body from the request.
     */
    private String sendLoginRequest(String username, String password, String endpoint) {
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod(HttpConstants.HttpMethod.XPOST.name().removeStart('X'));
            request.setHeader(HttpConstants.HTTP_HEADER_CONTENT_TYPE, 'text/xml;charset=UTF-8');
            request.setHeader('SOAPAction', '""');
            request.setBody(String.format(REQUEST_BODY, new List<String> {username, password}));
            HttpResponse res = new Http().send(request);
            return res.getBody();
        } catch (Exception e) {
            throw new SalesforceLoginUtilityException('Bad Request: ' + e.getMessage(), e);
        }
    }

    /**
     * Perform request against the Soap API and return the response body.
     *
     * @param namedCredential The named credential specifies a callout endpoint and its required
     *        authentication parameters.
     * @return The response body from the request.
     */
    private String sendLoginRequest(String namedCredential) {
        HttpResponse res;
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:' + namedCredential);
            request.setMethod(HttpConstants.HttpMethod.XPOST.name().removeStart('X'));
            request.setHeader(HttpConstants.HTTP_HEADER_CONTENT_TYPE, 'text/xml;charset=UTF-8');
            request.setHeader('SOAPAction', '""');
            request.setBody(
                String.format(REQUEST_BODY, new List<String> {'{!$Credential.UserName}', '{!$Credential.Password}'}));
            res = new Http().send(request);
        } catch (Exception e) {
            throw new SalesforceLoginUtilityException('Bad Request: ' + e.getMessage(), e);
        }
        return res.getBody();
    }

    /**
     * Get the session id from the request performed to the Soap API.
     *
     * @param loginResponse The response body from the request.
     * @return The session id if all goes well, otherwise an empty string.
     */
    private void load(String loginResponse) {
        if (String.isNotBlank(loginResponse) && !loginResponse.containsIgnoreCase('INVALID_LOGIN')) {
            Dom.Document loginDoc = new Dom.Document();
            loginDoc.load(loginResponse);
            Dom.XmlNode resultElmt = loginDoc.getRootElement()
                    .getChildElement('Body', SOAP_ENVELOPE_NS)
                    .getChildElement('loginResponse', PARTNER_NS)
                    .getChildElement('result', PARTNER_NS);
            /*Extract the session Id and Server url*/
            this.authEndpoint = resultElmt.getChildElement('serverUrl', PARTNER_NS)
                    .getText().split('/services')[0];
            this.serviceEndpoint = resultElmt.getChildElement('serverUrl', PARTNER_NS).getText();
            this.restEndpoint = this.authEndpoint + REST_SERVICE;
            this.sessionId = resultElmt.getChildElement('sessionId', PARTNER_NS).getText();
        } else {
           throw new SalesforceLoginUtilityException('Please check your Username and Password.');
        }
    }

    public class SalesforceLoginUtilityException extends Exception {
        public override String getStackTraceString() {
            return  super.getCause() != null ?  super.getCause().getStackTraceString() : super.getStackTraceString();
        }
    }
}