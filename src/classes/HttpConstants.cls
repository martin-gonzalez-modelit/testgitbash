/**
 * Constants enumerating the HTTP status codes, HTTP methods and HTTP request and response headers.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-11
 */
public without sharing class HttpConstants {

    /** Status response indicating the request has been accepted for processing,
     * but the processing has not been completed.
     */
    public static final String STATUS_ACCEPTED = 'Accepted';

    /** Status response indicating the request sent by the client was syntactically incorrect. */
    public static final String STATUS_BAD_REQUEST = 'Bad Request';

    /** Status response for a request that could not be completed due to a resource conflict. */
    public static final String STATUS_CONFLICT = 'Conflict';

    /** Status response for a server that understood the request, but is refusing to fulfill it. */
    public static final String STATUS_FORBIDDEN = 'Forbidden';

    /** Status response for a server that refuses to accept the request without a defined Content- Length. */
    public static final String STATUS_LENGTH_REQUIRED = 'Length Required';

    /** Status response for a resource that has permanently moved to a new URI. */
     public static final String STATUS_MOVED_PERMANENTLY = 'Moved Permanently';

    /** Status response indicates that the server does not support the functionality required to fulfill the request. */
    public static final String STATUS_NOT_IMPLEMENTED = 'Not Implemented';

    /** Status response for a server that has not found anything matching the Request-URI. */
    public static final String STATUS_NOT_FOUND = 'Not Found';

    /** Status response for a successful request. */
    public static final String STATUS_OK = 'OK';

    /** Status response for a successful range request for a resource by transferring one or more parts. */
    public static final String STATUS_PARTIAL_CONTENT = 'Partial Content';

    /** Status response indicates a precondition given in one or more of the request-header fields evaluated
     * to false when it was tested on the server.
     */
    public static final String STATUS_PRECONDITION_FAILED = 'Precondition Failed';

    /** Status response for an invalid ranges or an excessive request of small or overlapping ranges. */
    public static final String STATUS_REQUESTED_RANGE_NOT_SATISFIABLE = 'Requested Range Not Satisfiable';

    /** Status response for a service that is unavailable on the server. */
    public static final String STATUS_SERVICE_UNAVAILABLE = 'Service Unavailable';

    /** Status response for a resource that has temporarily moved to a new URI. */
    public static final String STATUS_TEMPORARY_REDIRECT = 'Temporary Redirect';

    /** Status response for a request that requires user authentication. */
    public static final String STATUS_UNAUTHORIZED = 'Unauthorized';

    /** Status code for a successful request. */
    public static final Integer STATUS_CODE_OK = 200;

    /** Status code for a successful request with no content information. */
    public static final Integer STATUS_CODE_NO_CONTENT = 204;

    /** Status code for a successful range request for a resource by transferring one or more parts. */
    public static final Integer STATUS_CODE_PARTIAL_CONTENT = 206;

    /** Status code for a resource corresponding to any one of a set of representations. */
    public static final Integer STATUS_CODE_MULTIPLE_CHOICES = 300;

    /** Status code for a resource that has permanently moved to a new URI. */
    public static final Integer STATUS_CODE_MOVED_PERMANENTLY = 301;

    /** Status code for a resource that has temporarily moved to a new URI. */
    public static final Integer STATUS_CODE_FOUND = 302;

    /** Status code for a resource that has moved to a new URI and should be retrieved using GET. */
    public static final Integer STATUS_CODE_SEE_OTHER = 303;

    /** Status code for a resource that access is allowed but the document has not been modified. */
    public static final Integer STATUS_CODE_NOT_MODIFIED = 304;

    /** Status code for a resource that has temporarily moved to a new URI. */
    public static final Integer STATUS_CODE_TEMPORARY_REDIRECT = 307;

    /** Status code indicating the request sent by the client was syntactically incorrect. */
    public static final Integer STATUS_CODE_BAD_REQUEST = 400;

    /** Status code for a request that requires user authentication. */
    public static final Integer STATUS_CODE_UNAUTHORIZED = 401;

    /** Status code for a server that understood the request, but is refusing to fulfill it. */
    public static final Integer STATUS_CODE_FORBIDDEN = 403;

    /** Status code for a server that has not found anything matching the Request-URI. */
    public static final Integer STATUS_CODE_NOT_FOUND = 404;

    /** Status code for a request that could not be completed due to a resource conflict. */
    public static final Integer STATUS_CODE_CONFLICT = 409;

    /** Status code for a server that refuses to accept the request without a defined Content- Length. */
    public static final Integer STATUS_CODE_LENGTH_REQUIRED = 411;

    /** Status code indicates a precondition given in one or more of the request-header fields evaluated
     * to false when it was tested on the server.
     */
    public static final Integer STATUS_CODE_PRECONDITION_FAILED = 412;

    /** Status code for an invalid ranges or an excessive request of small or overlapping ranges. */
    public static final Integer STATUS_CODE_REQUESTED_RANGE_NOT_SATISFIABLE = 416;

    /** Status code for an Integerernal server error. */
    public static final Integer STATUS_CODE_SERVER_ERROR = 500;

    /** Status code indicates that the server does not support the functionality required to fulfill the request. */
    public static final Integer STATUS_CODE_NOT_IMPLEMENTED = 501;

    /** Status code for a bad gateway. */
    public static final Integer STATUS_CODE_BAD_GATEWAY = 502;

    /** Status code for a service that is unavailable on the server. */
    public static final Integer STATUS_CODE_SERVICE_UNAVAILABLE = 503;

    public static final String HTTP_HEADER_ACCEPT = 'Accept';

    public static final String HTTP_HEADER_ACCEPT_CHARSET = 'Accept-Charset';

    public static final String HTTP_HEADER_ACCEPT_ENCODING = 'Accept-Encoding';

    public static final String HTTP_HEADER_ACCEPT_LANGUAGE = 'Accept-Language';

    public static final String HTTP_HEADER_ACCEPT_RANGES = 'Accept-Ranges';

    public static final String HTTP_HEADER_ACCESS_CONTROL_ALLOW_CREDENTIALS = 'Access-Control-Allow-Credentials';

    public static final String HTTP_HEADER_ACCESS_CONTROL_ALLOW_HEADERS = 'Access-Control-Allow-Headers';

    public static final String HTTP_HEADER_ACCESS_CONTROL_ALLOW_METHODS = 'Access-Control-Allow-Methods';

    public static final String HTTP_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN = 'Access-Control-Allow-Origin';

    public static final String HTTP_HEADER_ACCESS_CONTROL_EXPOSE_HEADERS = 'Access-Control-Expose-Headers';

    public static final String HTTP_HEADER_ACCESS_CONTROL_MAX_AGE = 'Access-Control-Max-Age';

    public static final String HTTP_HEADER_ACCESS_CONTROL_REQUEST_HEADERS = 'Access-Control-Request-Headers';

    public static final String HTTP_HEADER_ACCESS_CONTROL_REQUEST_METHOD = 'Access-Control-Request-Method';

    public static final String HTTP_HEADER_AGE = 'Age';

    public static final String HTTP_HEADER_ALLOW = 'Allow';

    /**
     * The "Authorization" header field allows a user agent to authenticate itself with an origin server -- usually,
     * but not necessarily, after receiving a 401 (Unauthorized) response.
     * Its value consists of credentials containing the authentication information of the user agent for
     * the realm of the resource being requested.
     */
    public static final String HTTP_HEADER_AUTHORIZATION = 'Authorization';

    public static final String HTTP_HEADER_CACHE_CONTROL = 'Cache-Control';

    public static final String HTTP_HEADER_CONNECTION = 'Connection';

    public static final String HTTP_HEADER_CONTENT_ENCODING = 'Content-Encoding';

    public static final String HTTP_HEADER_CONTENT_DISPOSITION = 'Content-Disposition';

    public static final String HTTP_HEADER_CONTENT_LANGUAGE = 'Content-Language';

    public static final String HTTP_HEADER_CONTENT_LENGTH = 'Content-Length';

    public static final String HTTP_HEADER_CONTENT_LOCATION = 'Content-Location';

    /**
     * The "Content-MD5", which may be used as a message integrity check (MIC), to verify that the decoded data are
     * the same data that were initially sent.
     */
    public static final String HTTP_HEADER_CONTENT_MD5 = 'Content-Md5';

    public static final String HTTP_HEADER_CONTENT_RANGE = 'Content-Range';

    /**
     * The "Content-Type" header field indicates the media type of the associated representation:
     * either the representation enclosed in the message payload or the selected representation, as determined by the
     * message semantics.
     */
    public static final String HTTP_HEADER_CONTENT_TYPE = 'Content-Type';

    public static final String HTTP_HEADER_COOKIE = 'Cookie';

    /**
     * The "Date" header field represents the date and time at which the message was originated,
     * having the same semantics as the Origination Date Field (orig-date).
     */
    public static final String HTTP_HEADER_XDATE = 'Date';

    /**
     * The "ETag" header field in a response provides the current entity-tag for the selected representation,
     * as determined at the conclusion of handling the request.
     */
    public static final String HTTP_HEADER_ETAG = 'ETag';

    public static final String HTTP_HEADER_EXPECT = 'Expect';

    /** The "Expires" header field gives the date/time after which the response is considered stale. */
    public static final String HTTP_HEADER_EXPIRES = 'Expires';

    public static final String HTTP_HEADER_HOST = 'Host';

    public static final String HTTP_HEADER_IF_MATCH = 'If-Match';

    public static final String HTTP_HEADER_IF_MODIFIED_SINCE = 'If-Modified-Since';

    public static final String HTTP_HEADER_IF_NONE_MATCH = 'If-None-Match';

    public static final String HTTP_HEADER_IF_RANGE = 'If-Range';

    public static final String HTTP_HEADER_IF_UNMODIFIED_SINCE = 'If-Unmodified-Since';

    /**
     * The "Last-Modified" header field in a response provides a timestamp indicating the date and time
     * at which the origin server believes the selected representation was last modified, as determined
     * at the conclusion of handling the request.
     */
    public static final String HTTP_HEADER_LAST_MODIFIED = 'Last-Modified';

    public static final String HTTP_HEADER_LINK = 'Link';

    public static final String HTTP_HEADER_LOCATION = 'Location';

    public static final String HTTP_HEADER_MAX_FORWARDS = 'Max-Forwards';

    public static final String HTTP_HEADER_METHOD_OVERRIDE = 'X-HTTP-Method';

    public static final String HTTP_HEADER_ORIGIN = 'Origin';

    public static final String HTTP_HEADER_XPRAGMA = 'Pragma';

    public static final String HTTP_HEADER_PROXY_AUTHENTICATE = 'Proxy-Authenticate';

    public static final String HTTP_HEADER_PROXY_AUTHORIZATION = 'Proxy-Authorization';

    /**
     * The "Range" header field on a GET request modifies the method semantics to request transfer of only one or more
     * subranges of the selected representation data, rather than the entire selected representation data.
     */
    public static final String HTTP_HEADER_RANGE = 'Range';

    public static final String HTTP_HEADER_REFERER = 'Referer';

    public static final String HTTP_HEADER_HTTP_HEADER_RETRY_AFTER = 'Retry-After';

    public static final String HTTP_HEADER_HTTP_HEADER_SERVER = 'Server';

    public static final String HTTP_HEADER_SET_COOKIE = 'Set-Cookie';

    public static final String HTTP_HEADER_SET_COOKIE2 = 'Set-Cookie2';

    public static final String HTTP_HEADER_TE = 'TE';

    public static final String HTTP_HEADER_TRAILER = 'Trailer';

    public static final String HTTP_HEADER_TRANSFER_ENCODING = 'Transfer-Encoding';

    public static final String HTTP_HEADER_UPGRADE = 'Upgrade';

    public static final String HTTP_HEADER_USER_AGENT = 'User-Agent';

    public static final String HTTP_HEADER_VARY = 'Vary';

    public static final String HTTP_HEADER_VIA = 'Via';

    public static final String HTTP_HEADER_WARNING = 'Warning';

    public static final String HTTP_HEADER_WWW_AUTHENTICATE = 'WWW-Authenticate';

    /** Enumeration of valid HTTP methods. */
    public enum HttpMethod { XGET, XPOST, XPUT, XDELETE, XHEAD, XPATCH }
}