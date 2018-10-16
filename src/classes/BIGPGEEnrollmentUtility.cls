/**
 * This class it's an utility of the PG&E Application Enrollment Portal.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-09
 */
public with sharing class BIGPGEEnrollmentUtility {
    private static final String kHexChars = '0123456789abcdefABCDEF';

    public static final String PROGRAM_PENDING_STATUS = 'Pending Review';
    public static final String PROGRAM_APPROVED_STATUS = 'Approved';
    public static final String PROGRAM_REQUEST_INFO_STATUS = 'Requested More Info';
    public static final String PROGRAM_REJECTED_STATUS = 'Rejected';
    public static final String PROGRAM_ALREADY_ENROLLED_STATUS = 'Already Enrolled';
    public static final String PROGRAM_EXPIRED_STATUS = 'Expired';

    public static final String APP_PARTICIPANT_CONTRACTOR = 'Contractor';

    /**
     * Convert an object to a JSON string
     *
     * @param Object obj
     * @return String jsonString
     */
    public static String convertToJSON(Object obj) {
        String jsonString = null;
        try {
            if (obj != null) {
                jsonString = JSON.serializePretty(obj);
            }   
        } catch (Exception e) {
            System.debug('### BIGPGEEnrollment::convertToJSON - The following error has ocurred while attempting to convert to JSON: ' + e.getMessage());
        }

        return jsonString;
    }

    public static String generateSecureCode() {
        return '';
    }

    public static String generatePrivateUrl() {
        return '';
    }

    public static void addErrorMsg(String errorMsg) {
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg);
        ApexPages.addMessage(msg);
    }

    /**
     * Checks if a Salesforce Id is valid
     *
     * @param String s
     * @return Boolean isValid
     */
    public static Boolean isValidSFDCId(String s) {
        Boolean isValid = true;
        if (String.isEmpty(s)) {
            return false;
        }

        try {
            Id id = s; // try to cast string to id
        } catch (Exception e) {
            isValid = false;
            System.debug('### BIGPGEEnrollmentUtility::isValidSFDCId - The following error has ocurred: ' + e.getMessage());
        }
        
        return isValid;
    }

    public static String charAt(String str, Integer index) {
        if(str == null){
            return null;
        }
        if(str.length() <= 0){
            return str; 
        }
        if(index < 0 || index >= str.length()){
            return null;    
        }
        return str.substring(index, index+1);
    }

    public static String randomUUID() {
        String returnValue = '';
        Integer nextByte = 0;
        for(Integer i = 0; i < 16; i++){
            if(i==4 || i==6 || i==8 || i==10){
                returnValue += '-';
            }
            //generate a "byte"; i.e., number in range [-2^7,2^7-1]
            nextByte = (Math.round(Math.random() * 255)-128) & 255;

            if(i==6){
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);
            }
            if(i==8){
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
            }

            returnValue += charAt(kHexChars,nextByte >> 4);
            returnValue += charAt(kHexChars,nextByte & 15);
        }
        return returnValue;
    }

    public static String getRandomToken(String id) {
        Long num = Crypto.getRandomlong();
        Blob targetBlob = Blob.valueOf(String.valueOf(num) + id);
        Blob hash = Crypto.generateDigest('SHA1', targetBlob);

        return  EncodingUtil.convertToHex(hash);
    }

    public static Map<String, List<String>> getPicklistValuesMap(String objectApiName, String fieldName) {
        return getPicklistValuesMap(Schema.getGlobalDescribe().get(objectApiName).newSObject().getSObjectType(),fieldName);
    }

    public static Map<String, List<String>> getPicklistValuesMap(Schema.SObjectType sobjectType, String fieldName) {
        Map<String, List<String>> picklistMap = new Map<String, List<String>>();
        List<String> lstPickvals = new List<String>();

        // Describe the sobject
        Schema.DescribeSObjectResult sobject_describe = sobjectType.getDescribe();
        // Get a map of fields for the passed sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();

        return getPicklistValuesMap(new Set<SObjectField>{field_map.get(fieldName)});
    }

    public static Map<String, List<String>> getPicklistValuesMap(Set<SObjectField> picklistFields) {
        Map<String, List<String>> picklistMap = new Map<String, List<String>>();
        List<String> picklistValues;

        if (picklistFields != null && !picklistFields.isEmpty()) {
            for (SObjectField field : picklistFields) {
                picklistValues = new List<String>();
                for (Schema.PicklistEntry picklistValue : field.getDescribe().getPicklistValues()) {
                    picklistValues.add(picklistValue.getLabel());
                }
                picklistMap.put(field.getDescribe().getLabel(), picklistValues);
            }
        }
        return picklistMap;
    }

    /**
     * Gets a map containing every link label and URL of the Enrollment Portal site ordered by API name
     *
     * @return Map<String, Map<String, String>> linksMap
     */
    public static Map<String, Map<String, String>> getPortalLinks() {
        Map<String, Map<String, String>> linksMap = new Map<String, Map<String, String>>();

        try {
            for (Link__mdt link : [SELECT Link_Label__c, Link_URL__c, DeveloperName FROM Link__mdt]) {
                if (!linksMap.containsKey(link.DeveloperName)) {
                    linksMap.put(link.DeveloperName, new Map<String, String>{link.Link_Label__c => link.Link_URL__c});
                } else {
                    linksMap.get(link.DeveloperName).put(link.Link_Label__c, link.Link_URL__c);
                }
            }
        } catch (QueryException e) {
            System.debug('Error while retrieving links: ' + e.getMessage());
        }

        return linksMap;
    }
}