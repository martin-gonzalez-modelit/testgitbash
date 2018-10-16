/**
 * Singleton class that assembles error messages that may occur during a
 * path of execution and saves to an error handling SObject.
 *
 * @ author Maiquel Cabrera  maiquel.cabrera@modelitsoftware.com
 * @ since 2013-02
 */
public with sharing class ErrorHandlingUtil {

    private Id currentSObjectId;
    private List<System_Error_Log__c> errorLogsToInsert = new List<System_Error_Log__c>();

    private static ErrorHandlingUtil errorUtilInstance = null;

    private static final String EXCEPTION_TYPE_STRING = 'Exception type: ';
    private static final String EXCEPTION_MESSAGE_STRING = 'Exception message: ';
    private static final Integer NAME_MAX_SIZE = System_Error_Log__c.Class_Name__c.getDescribe().getLength();

    public Id getCurrentSObjectId(){return this.currentSObjectId;}

    public List<System_Error_Log__c> getErrorLogsToInsert() {
        return errorLogsToInsert;
    }

    public void setCurrentSObjectId(Id pValue){this.currentSObjectId = pValue;}

    //private constructor to prevent external instantiation
    private ErrorHandlingUtil(){}

    public static ErrorHandlingUtil getInstance(){
        if(errorUtilInstance == null) {
            errorUtilInstance = new ErrorHandlingUtil();
        }
        return errorUtilInstance;
    }

    /**
     * Puts new log message into the queue, requires call to logMessage() to
     * write to custom object.
     */
    public void logDebug(String className, String moduleName, String detail, String objectId) {
        System_Error_Log__c log = new System_Error_Log__c();
        log.Log_Level__c = String.valueOf(LoggingLevel.DEBUG);
        logInternal(log, className, moduleName, detail, objectId);
    }

    private void logInternal(System_Error_Log__c log, String className, String moduleName, String detail, String objectId) {
        log.Class_Name__c = getLimitedString(className, NAME_MAX_SIZE);
        log.Log_Detail__c = detail;
        log.Module_Name__c = getLimitedString(moduleName, NAME_MAX_SIZE);
        log.Object_Id__c = objectId;

        errorLogsToInsert.add(log);
    }

    /**
     * Puts new log message into the queue, requires call to logMessage() to
     * write to custom object.
     */
    public void logInfo(String className, String moduleName, String detail, String objectId) {
        System_Error_Log__c log = new System_Error_Log__c();
        log.Log_Level__c = String.valueOf(LoggingLevel.INFO);
        logInternal(log, className, moduleName, detail, objectId);
    }

    /**
     * Puts new log message into the queue, requires call to logMessage() to
     * write to custom object.
     */
    public void logWarn(String className, String moduleName, String detail, String objectId) {
        System_Error_Log__c log = new System_Error_Log__c();
        log.Log_Level__c = String.valueOf(LoggingLevel.WARN);
        logInternal(log, className, moduleName, detail, objectId);
    }

    /**
     * Puts new log message into the queue, requires call to logMessage() to
     * write to custom object.
     */
    public void logError(String className, String moduleName, String detail, String objectId) {
        System_Error_Log__c log = new System_Error_Log__c();
        log.Log_Level__c = String.valueOf(LoggingLevel.ERROR);
        logInternal(log, className, moduleName, detail, objectId);
    }

    /**
     * Utility method to iterate SaveResult array and add any errors to the log detail.
     * @param pResults  a SaveResult array to process.
     */
    public void processDMLResults(Database.SaveResult[] pResults) {
        if(pResults != null){
            //Loop through the results and capture any errors
            for(Database.SaveResult result : pResults){
                if(!result.success){
                    recordErrorResult(result.getErrors(), result.getId(), 'saving');
                }
            }
        }
    }

    private void recordErrorResult(Database.Error[] errors, Id objectId, String operation) {
        System_Error_Log__c log = new System_Error_Log__c();
        //Need to initialize this because you can't initialize it to error (below)
        //But you can += error
        log.Log_Detail__c = '';
        if(errors != null){
            for(Database.Error error : errors){
                log.Log_Detail__c += error;
            }
        }else{
            log.Log_Detail__c = 'Error ' + operation + ', but there was no error message\n';
        }
        log.Object_Id__c = objectId;
        errorLogsToInsert.add(log);
    }

    /**
     * Utility method to iterate UpsertResult array and add any errors to the log detail
     * @param pResults  a UpsertResult array to process
     */
    public void processDMLResults(Database.UpsertResult[] pResults) {
        if(pResults != null){
            //Loop through the results and capture any errors
            for(Database.UpsertResult result : pResults){
                if(!result.success){
                    recordErrorResult(result.getErrors(), result.getId(), 'upserting');
                }
            }
        }
    }

    /**
     * Utility method to iterate DeleteResult array and add any errors to the log detail.
     * @param pResults  a DeleteResult array to process.
     */
    public void processDMLResults(Database.DeleteResult[] pResults) {
        if(pResults != null){
            //Loop through the results and capture any errors
            for(Database.DeleteResult result : pResults){
                if(!result.success) {
                    recordErrorResult(result.getErrors(), result.getId(), 'deleting');
                }
            }
        }
    }

    public void processException(String className, String moduleName, Exception pException) {
        if(pException != null){
            System_Error_Log__c log = new System_Error_Log__c();
            log.Log_Level__c = String.valueOf(LoggingLevel.ERROR);
            log.Module_Name__c = getLimitedString(moduleName, NAME_MAX_SIZE);
            log.Class_Name__c = getLimitedString(className, NAME_MAX_SIZE);
            //Print out the exception type
            log.Log_Detail__c = EXCEPTION_TYPE_STRING + pException.getTypeName() + '\n\n';
            //Print out the exception message
            log.Log_Detail__c += EXCEPTION_MESSAGE_STRING + pException.getMessage();

            if(pException instanceof DmlException){
                DmlException dmlEx = (DmlException)pException;
                for(Integer i=0; i < dmlEx.getNumDml(); i++){
                    log.Log_Detail__c += '\n\nRecord that failed to insert: ' + dmlEx.getDmlId(i) + '\n\n';
                    log.Log_Detail__c += 'DML Message: ' + dmlEx.getDmlMessage(i) + '\n\n';
                    log.Log_Detail__c += 'Field(s) that caused DML error: ' + dmlEx.getDmlFieldNames(i);
                }
            }
            //When keeping track of the current SObject that is being processed
            //Use it to stamp the Object Id reference
            log.Object_Id__c = this.currentSObjectId;
            this.errorLogsToInsert.add(log);
        }
    }

    /**
     * Utility method to get errors that were thrown from an Exception.
     * @param pException  the DmlException to process.
     */
    public void processException(Exception pException){
        processException('','', pException);
    }

    /**
     * Save System_Error_Log__c log objects that were built before.
     */
    public void logMessage(){
        if (errorLogsToInsert.size() > 0) {
            //If this fails, none of the previous stuff will be rolled back
            Database.UpsertResult[] results;
            try {
                results = Database.upsert(this.errorLogsToInsert);
            } catch (Exception e) {
                String errorMsg = 'exception thrown while saving System_Error_Log__c: ' + e.getMessage() + ' ';
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
            errorLogsToInsert.clear();
        }
    }

    /**
     * Get a string of a maximum length.
     */
    private String getLimitedString(String orig, Integer maxSize) {
        if (orig != null && orig.length() > maxSize)
            return orig.substring(0, maxSize);
        return orig;
    }
}