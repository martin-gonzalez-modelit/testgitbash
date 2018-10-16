/**
 * Simple wrapper response class. Makes it so all replies via this API have the same basic structure
 * including a boolean success flag, a message, any sObjects affected and some debugging params.
 */
public virtual with sharing class BIGPGEEnrollmentResponseWrapper {
    public String message { get; set; }
    public Boolean success { get; set; }
    public Boolean isTokenExpired { get; set; }
    public Object responseData { get; set; }
    public Object inputData { get; set; }

    public BIGPGEEnrollmentResponseWrapper() {
        isTokenExpired = false;
    }

}