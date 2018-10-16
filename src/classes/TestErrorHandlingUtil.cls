/**
 * This class contains unit tests for ErrorHandlingUtil class.
 *
 * @author Maiquel Cabrera  mcabrera@builditgreen.org
 * @since 2014-04
 */
@isTest
private class TestErrorHandlingUtil {

    public static testmethod void testErrorHandlingUtil() {
        String reallyLongString = '';
        Integer i = 0;
        while (i < 350) {
            reallyLongString += 'a';
            i++;
        }

        ErrorHandlingUtil errorLog = ErrorHandlingUtil.getInstance();

        Id pValue = '01px00000008W74';
        errorLog.setCurrentSObjectId(pValue);
        System.assertEquals(errorLog.getCurrentSObjectId(), pValue);

        TestException te = new TestException();

        // make sure that we don't exceeed the custom object field sizes
        errorLog.processException(reallyLongString, reallyLongString, te);

        String CLAZZ = 'ErrorHandlingUtilTest';

        errorLog.processException(CLAZZ,'Test', te);

        errorLog.processException(te);

        errorLog.logDebug(CLAZZ, 'Test', '', '');
        errorLog.logInfo(CLAZZ, 'Test', '', '');
        errorLog.logWarn(CLAZZ, 'Test', '', '');

        errorLog.logInfo(null, null, null, null);

        System_Error_Log__c badLog;

        try {
            // cause exception to test logError methods by omitting required field
            badLog = new System_Error_Log__c();
            badLog.Class_Name__c = reallyLongString;

            insert badLog;

        } catch (System.Exception ex) {
            errorLog.processException(CLAZZ, 'Test', ex);
        }

        try {
            errorLog.processException(CLAZZ, 'Test', te);
            errorLog.processException(CLAZZ, 'Test', te);

            // cause another exception to test putDMLResults
            Database.SaveResult[] results = Database.insert(errorLog.getErrorLogsToInsert(),false);
            errorLog.processDMLResults(results);
        } catch (System.Exception ex) {
            errorLog.processException(CLAZZ, 'Test', ex);
        }

        errorLog.logMessage();

        Integer count = [select count() from System_Error_Log__c where Class_Name__c =: CLAZZ];
        System.assertEquals(7, count);

        try {
            // upsert the error logs
            Database.UpsertResult[] results = Database.upsert(errorLog.getErrorLogsToInsert(),false);
            errorLog.processDMLResults(results);
        } catch (System.Exception ex) {
            errorLog.processException(CLAZZ, 'Test', ex);
        }

        try {
            // delete the error logs
            Database.DeleteResult[] results = Database.delete(errorLog.getErrorLogsToInsert(),false);
            errorLog.processDMLResults(results);
        } catch (System.Exception ex) {
            errorLog.processException(CLAZZ, 'Test', ex);
        }

        try {
            // bad log will cause failures in insert/upsert
            errorLog.getErrorLogsToInsert().add(badLog);

            // cause an insert to fail to test putDMLResults
            Database.SaveResult[] results = Database.insert(errorLog.getErrorLogsToInsert(),false);
            errorLog.processDMLResults(results);

            // cause an delete to fail to test putDMLResults
            Database.UpsertResult[] results2 = Database.upsert(errorLog.getErrorLogsToInsert(),false);
            errorLog.processDMLResults(results2);

        } catch (System.Exception ex) {
            errorLog.processException(CLAZZ, 'Test', ex);
        }

        // create a log message, modify ownerId to be invalid, force exception
        errorLog.logWarn(CLAZZ, 'Test', '', '');

        for (System_Error_Log__c log: errorLog.getErrorLogsToInsert()) {
            // set invalid owner id
            log.OwnerId = '035000000000000';
        }

        // log message will cause exception when SelfServiceUser is owner without improved exception handling
        errorLog.logMessage();
    }

    public class TestException extends System.Exception {}
}