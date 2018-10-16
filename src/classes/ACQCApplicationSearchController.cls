/**
 * This class contains functionality for the ACQCApplicationSearchCmp lightning component.
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2017-12
 */
public with sharing class ACQCApplicationSearchController {
    // Constants
    /* The max number of suggested addresses to be displayed. Defaults to 10. */
    private static Integer AUTOCOMPLETE_DISPLAY_LIMIT = 10;
    // Private Properties
    private static List<Street_Suffix_Abbreviations__mdt> suffixRecords;

    static {
        setSuffixes();
    }

    /**
     * Checks if the user has access to the ACQC program and if it's not the case, it redirects to exception page.
     *
     * @return The current page if the user has access to the ACQC program, or a redirect to the Access Denied page.
     */
    public PageReference checkUserAccess() {
        return BIGUtility.checkACQCContactAccess(new BIGPortalUser());
    }

    /**
     * Wrapper class that is used to paginate the list of resultant applications.
     */
    public class ApplicationListWrapper {
        @AuraEnabled
        public Integer page { get; set; }
        @AuraEnabled
        public Integer totalRecords { get; set; }
        @AuraEnabled
        public List<Application__c> applications { get; set; }
    }

    /**
     * Sets the list of suffix abbreviations.
     */
    private static void setSuffixes() {
        if (suffixRecords == null) {
            suffixRecords = [SELECT Id, MasterLabel, Suffix__c FROM Street_Suffix_Abbreviations__mdt];
        }
    }

    /**
     * Gets the user's account Id.
     *
     * @return The user's account Id.
     */
    @AuraEnabled
    public static Id getAccount() {
        // Get User's Account.
        return new BIGPortalUser().getAccount().Id;
    }

    /**
     * Given the user's input string, gets a list of all matching addresses (partial and full matches).
     *
     * @param input The user's input string.
     * @return List of addresses.
     */
    @AuraEnabled
    public static List<String> getAddresses(String input) {
        List<Application__c> applications = new List<Application__c>();
        Set<String> addressesToReturn = new Set<String>();

        try {
            if (String.isNotEmpty(input)) {
                Set<String> addresses;
                DateTime todayFiveYearsAgo = System.Now().addYears(-5);
                // Normalize user's input whenever it's not a single word.
                if (input.containsWhitespace()) {
                    addresses = normalizeData(input);
                } else {
                    addresses = new Set<String>{input};
                }

                String query = ''
                        + 'SELECT Dwelling_Unit_Street_Address__c, Building_City__c, Building_ZIP_Code__c, '
                            + '(SELECT Id FROM Measures__r) '
                        + 'FROM Application__c '
                        + 'WHERE RecordType.Id = \'' + ApplicationUtils.ACQC_RECORD_TYPE + '\' '
                            + 'AND Status__c != \'' + ApplicationUtils.CANCELED_STATUS + '\' '
                            + 'AND Status__c != \'' + ApplicationUtils.REJECTED_STATUS + '\' '
                            + 'AND Contractor__r.Name != \'' + ApplicationUtils.BIG_ACCOUNT_NAME + '\' '
                            + 'AND CreatedDate > ' + todayFiveYearsAgo.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') + ' ';

                if (!addresses.isEmpty()) {
                    Integer counter = 0;
                    query += 'AND (';

                    for (String address : addresses) {
                        query += counter > 0 ? 'OR ' : '';
                        query +=
                            + 'Dwelling_Unit_Street_Address__c LIKE \'%' + String.escapeSingleQuotes(address) + '%\' '
                            + 'OR Building_City__c LIKE \'%' + String.escapeSingleQuotes(address) + '%\' '
                            + 'OR Building_ZIP_Code__c LIKE \'%' + String.escapeSingleQuotes(address) + '%\' '
                            + 'OR Building_Full_Address__c LIKE \'%' + String.escapeSingleQuotes(address) + '%\' ';
                        counter++;
                    }
                    query += ') ORDER BY Dwelling_Unit_Street_Address__c ASC ';
                }
                query += 'LIMIT 1000';
                // Perform query.
                applications = Database.query(query);
            }

            for (Application__c app : applications) {
                if (addressesToReturn.size() < AUTOCOMPLETE_DISPLAY_LIMIT) {
                    if (!app.Measures__r.isEmpty()) {
                        String street = formatStringFirstUppercase(normalizeStreet(app.Dwelling_Unit_Street_Address__c));
                        String city = formatStringFirstUppercase(app.Building_City__c);
                        String zip = String.isNotBlank(app.Building_ZIP_Code__c)
                                   ? app.Building_ZIP_Code__c
                                   : '';
                        String address = street + ', ' + city + ' ' + zip;
                        addressesToReturn.add(address);
                    }
                } else {
                    // Get out of the for loop whenever we reach the limit of 10 results (10 different addresses) or
                    // we have processed all the queried applications.
                    break;
                }
            }
        } catch (Exception e) {
            System.debug('###Error Couldn\'t get addresses. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return new List<String>(addressesToReturn);
    }

    /**
     * Given the user's input string, gets a list of all matching addresses (partial and full matches).
     *
     * @param input The address selected by the user.
     * @param pageNumber The current page number.
     * @param pageSize The current page size.
     * @return Wrapper class containing the list of resultant applications, the total amount of results, and the current
     *         page number.
     */
    @AuraEnabled
    public static ApplicationListWrapper getApplications(String input, Decimal pageNumber, Decimal pageSize) {
        ApplicationListWrapper wrapper = new ApplicationListWrapper();

        try {
            // Get offset.
            Integer offset = (Integer.valueOf(pageNumber) - 1) * Integer.valueOf(pageSize);
            // Set page number.
            wrapper.page = Integer.valueOf(pageNumber);

            if (String.isNotEmpty(input)) {
                // Normalize the address selected by the user.
                Set<String> addresses = normalizeData(input);

                String queryStart = ''
                        + 'SELECT Id, Name, Status__c, Dwelling_Unit_Street_Address__c, Building_City__c, '
                            + 'Building_ZIP_Code__c, Application_Submission_Date__c, CreatedDate, Contractor__c , '
                            + '(SELECT Name, Installation_Date__c, Rebate_Type__r.Date_Label__c '
                            + 'FROM Measures__r '
                            + 'ORDER BY Installation_Date__c DESC NULLS LAST, Name ASC) '
                        + 'FROM Application__c ';

                if (!addresses.isEmpty()) {
                    DateTime todayFiveYearsAgo = System.Now().addYears(-5);
                    Integer counter = 0;
                    String whereClause =
                            + 'WHERE Id IN (SELECT Application__c FROM Measure__c) '
                                + 'AND RecordType.Id = \'' + ApplicationUtils.ACQC_RECORD_TYPE + '\' '
                                + 'AND Status__c != \'' + ApplicationUtils.CANCELED_STATUS + '\' '
                                + 'AND Status__c != \'' + ApplicationUtils.REJECTED_STATUS + '\' '
                                + 'AND Contractor__r.Name != \'' + ApplicationUtils.BIG_ACCOUNT_NAME + '\' '
                                + 'AND CreatedDate > ' + todayFiveYearsAgo.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') + ' '
                                + 'AND (';

                    for (String address : addresses) {
                        whereClause += counter > 0 ? 'OR ' : '';
                        whereClause +=
                                + 'Building_Full_Address__c LIKE \'' + String.escapeSingleQuotes(address) + '\' ';
                        counter++;
                    }
                    whereClause += ') ';

                    // Perform query.
                    String queryEnd = ''
                            + 'ORDER BY Installation_Date__c DESC '
                            + 'LIMIT ' + pageSize + ' OFFSET ' + offset;
                    String query = queryStart + whereClause + queryEnd;
                    wrapper.applications = Database.query(query);

                    // Get total amount of results.
                    String queryCount = 'SELECT COUNT() FROM Application__c ' + whereClause;
                    wrapper.totalRecords = database.countQuery(queryCount);
                }
            }
        } catch (Exception e) {
            System.debug('###Error Couldn\'t get applications. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return wrapper;
    }

    /**
     * It checks if the string contains a street suffix. If that's the case, it returns a set of all the possible
     * addresses by replacing that suffix with all its related secondary suffixes.
     *
     * @param data A string. It would either be user input, or an address selected by the user.
     * @return Set of addresses.
     */
    public static Set<String> normalizeData(String data) {
        Map<String, List<String>> suffixesByMatchedSuffix = new Map<String, List<String>>();
        Set<String> addresses = new Set<String>();
        Integer lastSuffixOccurrence = -1;

        try {
            // If the string has commas, get the string prior to the first comma.
            String addressStart = data.substringBefore(',');
            String addressEnd = String.isNotBlank(data.substringAfter(','))
                              ? data.substringAfter(',').toUpperCase()
                              : '';
            // Remove dots and commas, add white space at both ends, and capitalize.
            // Need to capitilize string in order to String.replace() method correctly.
            String sanitizedString = ' ' + addressStart.replace('.', '').replace(',', '').toUpperCase() + ' ';

            for (Street_Suffix_Abbreviations__mdt suffixRecord : suffixRecords) {
                for (String secondarySuffix : suffixRecord.Suffix__c.split(';')) {
                    if (sanitizedString.contains(' ' + secondarySuffix + ' ')
                            && sanitizedString.lastIndexOf(' ' + secondarySuffix + ' ') > lastSuffixOccurrence) {
                        lastSuffixOccurrence = sanitizedString.lastIndexOf(' ' + secondarySuffix + ' ');
                        suffixesByMatchedSuffix = new Map<String, List<String>>{
                                secondarySuffix => suffixRecord.Suffix__c.split(';')};
                    }
                }
            }

            if (!suffixesByMatchedSuffix.isEmpty()) {
                String matchedSuffix = new List<String>(suffixesByMatchedSuffix.keySet())[0];

                for (String replacementSuffix : suffixesByMatchedSuffix.get(matchedSuffix)) {
                    String suffixToReplace = sanitizedString.substring(lastSuffixOccurrence);
                    String newSuffix = suffixToReplace.replace(matchedSuffix, replacementSuffix).trim();
                    String address = sanitizedString.substring(0, lastSuffixOccurrence) + ' ' + newSuffix + addressEnd;
                    addresses.add(address.trim());
                }
            } else {
                // Add the user's input even though there were no suffix matches.
                String address = sanitizedString.trim() + addressEnd;
                addresses.add(address.trim());
            }
        } catch (Exception e) {
            System.debug('###Error Couldn\'t normalized data. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return addresses;
    }

    /**
     * It checks if the string contains a street suffix. If that's the case, it replaces this suffix with the primary
     * suffix, and returns this string.
     *
     * @param street The dwelling unit street address.
     * @return Normalized dwelling unit street address.
     */
    private static String normalizeStreet(String street) {
        String primarySuffix;
        String matchedSuffix;
        Integer lastSuffixOccurrence = -1;

        try {
            if (String.isBlank(street)) {
                return '';
            }
            // Remove dots, add white space at both ends, and capitalize.
            // Need to capitilize string in order to String.replace() method correctly.
            String sanitizedString = ' ' + street.replace('.', '').toUpperCase() + ' ';

            for (Street_Suffix_Abbreviations__mdt suffixRecord : suffixRecords) {
                for (String secondarySuffix : suffixRecord.Suffix__c.split(';')) {
                    if (sanitizedString.contains(' ' + secondarySuffix + ' ')
                            && sanitizedString.lastIndexOf(' ' + secondarySuffix + ' ') > lastSuffixOccurrence) {
                        // We want to use only the last suffix that the string contains.
                        lastSuffixOccurrence = sanitizedString.lastIndexOf(' ' + secondarySuffix + ' ');
                        matchedSuffix = secondarySuffix;
                        primarySuffix = suffixRecord.MasterLabel;
                        break;
                    }
                }
            }

            if (String.isNotBlank(primarySuffix)) {
                // Replace only the last suffix occurrence.
                String streetEnd = sanitizedString.substring(lastSuffixOccurrence + matchedSuffix.length() + 2);
                String suffixToReplace = sanitizedString.substring(lastSuffixOccurrence,
                        lastSuffixOccurrence + matchedSuffix.length() + 2);
                String newSuffix = suffixToReplace.replace(suffixToReplace, primarySuffix);
                street = sanitizedString.substring(0, lastSuffixOccurrence) + ' ' + newSuffix + ' ' + streetEnd;
            } else {
                // Use the string even though there were no suffix matches.
                street = sanitizedString;
            }
        } catch (Exception e) {
            System.debug('###Error Couldn\'t normalized street. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return street.trim();
    }

    /**
     * For a given string, if gives the following format for every word: first letter should be in uppercase, and the
     * rest should be in lowercase.
     *
     * @param address A string, in this case, the dwelling unit street address.
     * @return Formatted string with the first letter of each word in uppercase, and the rest is lowercase.
     */
    private static String formatStringFirstUppercase(String address) {
       String formattedAddress = '';

       if (String.isBlank(address)) {
           return formattedAddress;
       }

       for (String word : address.toLowerCase().split(' ')) {
           formattedAddress += word.substring(0,1).toUpperCase() + word.substring(1, word.length()) + ' ';
       }

       return formattedAddress.trim();
    }
}