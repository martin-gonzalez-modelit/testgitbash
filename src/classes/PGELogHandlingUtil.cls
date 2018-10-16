/* 
 * Singleton class that logs results of operations such as insert, update on a SObject. 
 * Determine whether or not the operation was successfull and saves such information to a handling SObject.  
 * @author dfebles - Francisco Cobas
 * @since 2014-07
 */
public with sharing class PGELogHandlingUtil {
	
	private static PGELogHandlingUtil logUtilInstance = null;
	private List<PGE_Log__c> logsToInsert = new List<PGE_Log__c>();
	
	private static final Integer NAME_MAX_SIZE = PGE_Log__c.Class_Name__c.getDescribe().getLength();
	
    //private constructor to prevent external instantiation
    private PGELogHandlingUtil(){}

    public static PGELogHandlingUtil getInstance(){
        if(logUtilInstance == null) {
            logUtilInstance = new PGELogHandlingUtil();
        }
        return logUtilInstance;
    }

  /*
   * puts new log message into the queue, requires call to logMessage() to write to custom object
   */
   public void logDebug(String className, String moduleName, String detail, String objectId) {
        PGE_Log__c log = new PGE_Log__c();
        log.Log_Level__c = String.valueOf(LoggingLevel.DEBUG);
        logInternal(log, className, moduleName, detail, objectId);
    }

    private void logInternal(PGE_Log__c log, String className, String moduleName, String detail, String objectId) {
        log.Class_Name__c = getLimitedString(className, NAME_MAX_SIZE);           
        log.Log_Detail__c = detail;
        log.Module_Name__c = getLimitedString(moduleName, NAME_MAX_SIZE);
        log.Object_Id__c = objectId;
        
        logsToInsert.add(log);
    }
    
	/**
     * Puts new log message into the queue, requires call to logMessage() to
     * write to custom object.
     */
    public void logError(String className, String moduleName, String detail, String objectId) {
        PGE_Log__c log = new PGE_Log__c();
        log.Log_Level__c = String.valueOf(LoggingLevel.ERROR);
        logInternal(log, className, moduleName, detail, objectId);
    }
	
	/*
	 * Method to instantiate a Service_Order_Log object that will hold the results 
	 */
    public void recordResult(Database.SaveResult result, Id objectId, String className, String operation, String attachment) {
        PGE_Log__c log = new PGE_Log__c();
        //Need to initialize this because you can't initialize it to error (below)
        //But you can += error
        log.Log_Detail__c = '';
        log.Object_Id__c = objectId;
        log.Class_Name__c = getLimitedString(className, NAME_MAX_SIZE);
        log.Module_Name__c = operation;
        log.Attachment__c = attachment;
        
        if (!result.success) {
	        if(result.getErrors() != null) {
	            for (Database.Error error : result.getErrors()) {
	                log.Log_Detail__c += error;
	            }
	        }else {
	            log.Log_Detail__c = 'Error ' + operation + ', but there was no error message\n';
	        }
    	} else {
    		log.Log_Detail__c = 'Success ' + operation;
    	}
    	
        logsToInsert.add(log);
    }
    
    /*
     * Save Service_Order_Log__c log objects that were built before
     */ 
    public void logMessage(){

        if (logsToInsert.size() > 0){
            //If this fails, none of the previous stuff will be rolled back
            Database.UpsertResult[] results;
            try { 
                results = Database.upsert(this.logsToInsert);
            } catch (Exception e) {
                String errorMsg = 'exception thrown while saving Service_Order_Log__c: ' + e.getMessage() + ' ';
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
            logsToInsert.clear();
        }
    }
    
    /**
    * get a string of a maximum length
    */
    private String getLimitedString(String orig, Integer maxSize) {
        if (orig != null && orig.length() > maxSize)
            return orig.substring(0, maxSize);
        return orig;
    }
        
}