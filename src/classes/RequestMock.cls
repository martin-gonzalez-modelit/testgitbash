/**
 * This class contains functionality to retrieve a fake message for call out tests
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2016-06
 */
@isTest
public class RequestMock implements HttpCalloutMock {
    private List<HttpResponse> responses = new List<HttpResponse>();

    public RequestMock() { }

    /**
     * Add all fakes HttpResponse for callout on test methods.
     *
     * @param req HTTP request made it on createResponse method.
     */
    public void addResponse(HttpResponse response) {
        responses.add(response);
    }

    /**
     * Set a fake HttpResponse message for call out on test methods.
     *
     * @param req HTTP request made it on test method.
     * @return HTTP fake response.
     */
    public HttpResponse respond(HttpRequest request) {
        return responses.remove(0);
    }

    /**
     * Set a fake HttpResponse message for call out on test methods.
     *
     * @param code The fake message code.
     * @param status The fake message status.
     * @param body The fake message body.
     * @param headers The contents of the response header.
     * @return HTTP fake response.
     */
    public static HTTPResponse createResponse(Integer code, String status, String body, Map<String, String> headers) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(code);
        response.setStatus(status);
        response.setBody(body);

        if (headers != null) {
            for (String key : headers.keySet()) {
                response.setHeader(key, headers.get(key));
            }
        }

        return response;
    }

    /**
     * Set a fake HttpResponse message for call out on test methods.
     *
     * @param code The fake message code.
     * @param status The fake message status.
     * @param body The fake message body.
     * @param headers The contents of the response header.
     * @return HTTP fake response.
     */
    public static HTTPResponse createResponse(Integer code, String status, Blob body, Map<String, String> headers) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(code);
        response.setStatus(status);
        response.setBodyAsBlob(body);

        if (headers != null) {
            for (String key : headers.keySet()) {
                response.setHeader(key, headers.get(key));
            }
        }

        return response;
    }
}