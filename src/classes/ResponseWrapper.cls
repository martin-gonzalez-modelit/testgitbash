/**
 * Virtual convenience class that wraps a Response object. Subclasses can override individual methods as required
 * to provide the functionality that they require.
 * This provides methods that can be used to set various characteristics of the response.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2016-09
 */
public virtual class ResponseWrapper {

    public Boolean success { get; set; }
    public String errorMessage { get; set; }
    public String exceptionMessage { get; set; }
    public List<SObject> results { get; set; }

    public ResponseWrapper() {
        success = true;
        results = new List<SObject>();
    }

    public ResponseWrapper(Boolean success, String errorMessage, String exceptionMessage, List<SObject> results) {
        this.success = success;
        this.errorMessage = errorMessage;
        this.exceptionMessage = exceptionMessage;
        this.results = results;
    }
}