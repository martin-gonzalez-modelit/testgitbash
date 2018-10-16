/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class RollupService {
    global static Exception LastMetadataAPIConnectionException {
        get;
    }
    global RollupService() {

    }
    global static Boolean checkMetadataAPIConnection() {
        return null;
    }
    global static List<SObject> rollup(List<SObject> childRecords) {
        return null;
    }
    global static void rollup(List<dlrs.RollupService.RollupToCalculate> rollupsToCalculate) {

    }
    global static void rollup(Map<Id,SObject> existingRecords, Map<Id,SObject> newRecords, Schema.SObjectType sObjectType) {

    }
    global static Id runJobToCalculate(Id lookupId) {
        return null;
    }
    global static Id runJobToCalculate(String lookupId) {
        return null;
    }
    global static Id runJobToCalculate(Id lookupId, String masterWhereClause) {
        return null;
    }
    global static Id runJobToCalculate(String lookupId, String masterWhereClause) {
        return null;
    }
    global static Id runJobToProcessScheduledItems() {
        return null;
    }
    global static void testHandler(SObject dummyChildRecord) {

    }
    global static void triggerHandler() {

    }
global class RollupToCalculate {
    global Id parentId;
    global String rollupSummaryUniqueName;
    global RollupToCalculate() {

    }
}
}
