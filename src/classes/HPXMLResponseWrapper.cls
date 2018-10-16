public with sharing class HPXMLResponseWrapper {
    private boolean success;
    private string errorMessage;
    private string exceptionMessage;
    
    public HPXMLResponseWrapper() {
        success = false;
        errorMessage = '';
        exceptionMessage = '';
    }
    
    public boolean getSuccess() {
        return success;
    }
    
    public void setSuccess(boolean success) {
        this.success = success;
    }
    
    public string getErrorMessage() {
        return errorMessage;
    }
    
    public string getExceptionMessage() {
        return exceptionMessage;
    }
    
    public void setErrorMessage(String value) {
        errorMessage = value;
    }
}