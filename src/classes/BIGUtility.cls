/*
 * BIG Utility contains collection of static reusable methods
 * @author Matias Medina <matias.medina@modelitsoftware.com>
 * @since 2015-8
 */
public with sharing class BIGUtility {
    private static final Integer ID_LENGTH = 15;

    /*
     * This method return ID of recordType when you pass the ObjecType and the recordType name
     */
    public static Id getRecordTyeIdByName(SObjectType sobType, String developerName) {
        String soqlQry = 'select Id, SObjectType, DeveloperName from RecordType ';
        soqlQry += 'where DeveloperName =\'' + developerName + '\' and SObjectType=\'' + String.valueOf(sobType) + '\'' ;
        Id rtId = null;
        List<RecordType> rcList = (List<RecordType>)Database.query(soqlQry);
        if (rcList != null && rcList.size() > 0) {
            rtId = rcList.get(0).id;
        }
        return rtId;
    }

    /*
     * This method return true if the user profile is equal to the profile name
     */
    public static boolean isObjectLastModifiedByUserWithProfile(SObject modifiedObject, Id profileId) {
        if (modifiedObject != null && modifiedObject.get('LastModifiedById') != null &&
            profileId != null && getLastModifiedByProfileId(modifiedObject) == profileId) {
            return true;
        }
        return false;
    }

    /*
     * This method return true if the last modified date of the object is after the application submission date
     */
    public static boolean isObjectLastModifiedAfterSubmissionDate(SObject modifiedObject,
            Datetime applicationSubmissionDate) {
        if (modifiedObject != null &&
            modifiedObject.get('LastModifiedDate') != null &&
            (Datetime)modifiedObject.get('LastModifiedDate') > applicationSubmissionDate &&
            applicationSubmissionDate != null) {
            return true;
        }
        return false;
    }

    /*
     * This method return Profile Id of the user that last modified the SObject
     */
    private static Id getLastModifiedByProfileId(SObject obj) {
        Id profileId;
        try {
            // query to get the ProfileId of the user that last modified the object
            List<User> users = [ SELECT ProfileId FROM User WHERE Id =: (Id) obj.get('LastModifiedById') ];
            if (!users.isEmpty()) {
                profileId = users.get(0).ProfileId;
            }
        } catch (QueryException  e) {
            System.debug('### QueryException while trying to query: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('### Exception while trying to query for User ProfileId: ' + e.getMessage());
        }
        return profileId;
    }

    /**
     * Returns the Id parsed from the text.
     *
     * @param prefix The three first characters of id contained on target.
     * @param target Text where we check if there is any sObjectId.
     * @return The Id as a String.
     */
    public static Id getSObjectId(String prefix, String target) {
        Id sObjectId;

        If (String.isNotBlank(prefix) && String.isNotBlank(target)) {
            try {
                Integer index = target.indexOf(prefix);
                sObjectId = target.substring(index, (index + ID_LENGTH));
            } catch (StringException e) {
            }
        }

        return sObjectId;
    }

    /**
     * Test a String to see if it is a valid SFDC Id.
     *
     * @param sfdcId The Id to test.
     * @return True if the Id is valid, false if it is not.
     */
    public static Boolean isValidSalesforceId(String sfdcId) {
        List<SObject> result = new List<SObject>();

        try {
            if (sfdcId instanceOf Id) {
                Id sObjectId = sfdcId;
                result = Database.query('SELECT Id FROM ' + sObjectId.getSObjectType() + ' WHERE Id = :sObjectId');
            }
        } catch (QueryException e) {
        }

        return !result.isEmpty();
    }

    /**
    * Evaluates a set of strings and determines if they are ids
    *
    * @param strings set of strings
    * @return set of ids
    */
    public static Set<Id> getValidSFDCIds(Set<String> strings) {
        Set<Id> ids = new Set<Id>();
        for (String s : strings) {
            try {
                ids.add(s);
            } catch (StringException e) {
                continue;
            }
        }
        ids.remove(null);
        return ids;
    }

    /**
     * Set a group of fields to null.
     *
     * @obj Sobject to be set.
     * @fields Set of fields to set to null.
     */
    public static void nullifySObjectFields(SObject obj, Set<String> fields) {
        for (String field : fields) {
            obj.put(field, null);
        }
    }

    /**
     * Check if contact has HUP/AHU access.
     *
     * @return Access Denied page if the portal user does not have permissions to access HU/AHU programs,
     * otherwise null.
     */
    public static PageReference checkHUOrAHUContactAccess(BIGPortalUser userUtility) {
        if (!userUtility.hasAdvanceHUProgram() && !userUtility.hasHUProgram()) {
            return Page.AccessDenied;
        }

        return null;
    }

    /**
     * Check if contact has AHU access.
     *
     * @return Access Denied page if the portal user does not have permission to access AHU program, otherwise null.
     */
    public static PageReference checkAHUContactAccess(BIGPortalUser userUtility) {
        if (!userUtility.hasAdvanceHUProgram()) {
            return Page.AccessDenied;
        }

        return null;
    }

    /**
     * Check if contact has ACQC access.
     *
     * @return Access Denied page if the portal user does not have permission to access ACQC program, otherwise null.
     */
    public static PageReference checkACQCContactAccess(BIGPortalUser userUtility) {
        if (!userUtility.hasACQCProgram()) {
            return Page.AccessDenied;
        }

        return null;
    }

    /**
     * Reverses the order of the elements in the specified list.
     *
     * @param toReverse The list whose elements are to be reversed.
     */
    public static void reverseList(List<Object> toReverse) {
        List<Object> reversed = new List<Object>();

        for (Integer i = toReverse.size() - 1; i >= 0; i--) {
            reversed.add(toReverse.get(i));
        }

        toReverse.clear();
        toReverse.addAll(reversed);
    }

    /**
     * Finds and returns the matches that match the pattern.
     *
     * @param regex The regular expression to check against.
     * @param input The string to look for occurrences.
     * @return A list with the matches found. If the regex does not match any part of the string, return an empty list.
     */
    public static List<String> findMatches(String regex, String input) {
        Matcher matcher = Pattern.compile(regex).matcher(input);
        List<String> matches = new List<String>();

        while (matcher.find()) {
            matches.add(matcher.group(0));
        }

        return matches;
    }

    /**
     * Use FOR UPDATE to lock sObject records while they’re being updated in order to prevent race conditions and
     * other thread safety problems. The lock gets released when the transaction completes.
     *
     * @param sObjectIds The list of sObject records to lock.
     * @return True if acquire the lock, otherwise false.
     */
    public static Boolean lockRecords(List<Id> sObjectIds) {
        String sObjectName = sObjectIds.get(0).getSObjectType().getDescribe().getName();

        // This query will wait up to 10 seconds. If it does not acquire the lock within that time,
        // an exception is thrown, and no results are returned. We can use this behavior to try again.
        List<SObject> sObjects;
        while (sObjects == null && Limits.getQueries() < Limits.getLimitQueries()) {
            try {
                sObjects = Database.query('SELECT Id FROM ' + sObjectName + ' WHERE Id = :sObjectIds FOR UPDATE');
            } catch (QueryException e) {
            }
        }

        return sObjects != null;
    }

    /**
     * Split a string into a list of strings.
     *
     * @param content The string to split
     * @param regExp The character chosen to split.
     * @return A list of strings.
     */
    public static List<String> getListFromPattern(String content, String regExp) {
        List<String> result = new List<String>();

        if (String.isNotBlank(content)) {
            for (String s : content.split(regExp)) {
                result.add(s.trim());
            }
        }

        return result;
    }
}