public with sharing class PicklistUtility {
    public Map<String, Integer> AlphaNumCharCodes { get; set; }
    public Map<String, Integer> Base64CharCodes { get; set; }
    public PicklistUtility() {
        loadCharCodes();
    }

    /**
     * Method loads the char codes
     */
    private void loadCharCodes() {
        AlphaNumCharCodes = new Map<String, Integer>{'A'=>65, 'B'=>66, 'C'=>67, 'D'=>68, 'E'=>69, 'F'=>70, 'G'=>71,
                'H'=>72, 'I'=>73, 'J'=>74, 'K'=>75, 'L'=>76, 'M'=>77, 'N'=>78, 'O'=>79, 'P'=>80, 'Q'=>81, 'R'=>82,
                'S'=>83, 'T'=>84, 'U'=>85, 'V'=>86, 'W'=>87, 'X'=>88, 'Y'=>89, 'Z'=>90};
        Base64CharCodes = new Map<String, Integer>();
        // Lower case
        Set<String> pUpperCase = AlphaNumCharCodes.keySet();
        for (String pKey : pUpperCase) {
            // The difference between upper case and lower case is 32
            AlphaNumCharCodes.put(pKey.toLowerCase(), AlphaNumCharCodes.get(pKey)+32);
            // Base 64 alpha starts from 0 (The ascii charcodes started from 65)
            Base64CharCodes.put(pKey, AlphaNumCharCodes.get(pKey) - 65);
            Base64CharCodes.put(pKey.toLowerCase(), AlphaNumCharCodes.get(pKey) - (65) + 26);
        }
        // Numerics
        for (Integer i=0; i<=9; i++) {
            AlphaNumCharCodes.put(string.valueOf(i),i+48);
            // Base 64 numeric starts from 52
            Base64CharCodes.put(string.valueOf(i), i + 52);
        }
    }

    public class TPicklistEntry {
        public string active { get;set; }
        public string defaultValue { get;set; }
        public string label { get;set; }
        public string value { get;set; }
        public string validFor { get;set; }
        public TPicklistEntry() { }
    }

    public Boolean testPicklistUtility(String pValidFor, Integer n) {
        // The list of bytes
        List<Integer> pBytes = new List<Integer>();
        // Multiply by 6 since base 64 uses 6 bits
        Integer bytesBeingUsed = (pValidFor.length() * 6)/8;
        // Will be used to hold the full decimal value
        Integer pFullValue = 0;
        // Must be more than 1 byte
        if (bytesBeingUsed <= 1) {
            return false;
        }
        // Calculate the target bit for comparison
        Integer bit = 7 - (Math.mod(n,8));
        // Calculate the octet that has in the target bit
        Integer targetOctet = (bytesBeingUsed - 1) - (n >> bytesBeingUsed);
        // The number of bits to shift by until we find the bit to compare for true or false
        Integer shiftPicklist = (targetOctet * 8) + bit;
        // Get the base64bytes
        for (Integer i=0; i < pValidFor.length(); i++) {
            // Get current character value
            pBytes.Add((Base64CharCodes.get((pValidFor.Substring(i, i+1)))));
        }
        // Calculate the full decimal value
        for (Integer i = 0; i < pBytes.size(); i++) {
            // Used to shift by a factor 6 bits to get the value
            Integer pShiftAmount = (pBytes.size() - (i + 1)) * 6;
            pFullValue = pFullValue + (pBytes[i] << (pShiftAmount));
        }
        // & is to set the same set of bits for testing
        // Shift to the bit which will dictate true or false
        Integer tPicklistVal = ((Integer)(Math.Pow(2, shiftPicklist)) & pFullValue) >> shiftPicklist;
        return  tPicklistVal == 1;
    }

    /**
     * Get all dependent values from dependent picklist, based on a controlling picklist in a particularly object
     *
     * @param objectName name of object that have the controlling and dependent picklist
     * @param controlling Picklist Name
     * @param dependent Picklist Name
     * @result Map with controlling Picklist values as a key and a list with the related values for each key
     */
    public static Map<String, List<String>> getDependentOptions(String objectName, String controllingPicklistName,
            String dependentPicklistName) {
        Map<String, List<String>> dependentValuesResult = new Map<String, List<String>>();
        // Get the string to sobject global map
        Map<String, Schema.SObjectType> globalObjects = Schema.getGlobalDescribe();
        if (!globalObjects.containsKey(objectName)) {
            return dependentValuesResult;
        }
        // Get the type being dealt with
        Schema.SObjectType objectContainsPicklist = globalObjects.get(objectName);
        Map<String, Schema.SObjectField> objectContainsPicklisFields =
                objectContainsPicklist.getDescribe().fields.getMap();
        // Verify field names
        if (!objectContainsPicklisFields.containsKey(controllingPicklistName)
                || !objectContainsPicklisFields.containsKey(dependentPicklistName)) {
            return dependentValuesResult;
        }
        // Get the control values
        List<Schema.PicklistEntry> controllingPicklistValues =
                objectContainsPicklisFields.get(controllingPicklistName).getDescribe().getPicklistValues();
        // Get the dependent values
        List<Schema.PicklistEntry> dependentPicklistValues =
                objectContainsPicklisFields.get(dependentPicklistName).getDescribe().getPicklistValues();
        // Iterate through the values and get the ones valid for the controlling field name
        PicklistUtility picklistUtilityObject = new PicklistUtility();
        // Set up the results
        for (Integer i = 0; i < controllingPicklistValues.size(); i++) {
            // Get the pointer to the entry
            Schema.PicklistEntry controllingPicklistValue = controllingPicklistValues[i];
            // Get the label
            String controllingPicklistLabel = controllingPicklistValue.getLabel();
            // Create the entry with the label
            dependentValuesResult.put(controllingPicklistLabel, new List<String>());
        }
        // Cater for null and empty
        dependentValuesResult.put('', new List<String>());
        dependentValuesResult.put(null, new List<String>());
        // Check the dependent values
        for (Integer j = 0; j < dependentPicklistValues.size(); j++) {
            // Get the pointer to the dependent index
           	Schema.PicklistEntry dependentPicklistValue = dependentPicklistValues[j];
           	// Get the valid for
            String picklistEntryStructure = JSON.serialize(dependentPicklistValue);
            PicklistUtility.TPicklistEntry dependentPicklistEntry = (PicklistUtility.TPicklistEntry)JSON.deserialize(
                    picklistEntryStructure, PicklistUtility.TPicklistEntry.class);
            // If valid for is empty, skip
            if (dependentPicklistEntry.validFor == null || dependentPicklistEntry.validFor == '') {
                continue;
            }
            // Iterate through the controlling values
            for (Integer k = 0; k < controllingPicklistValues.size(); k++) {
                if (picklistUtilityObject.testPicklistUtility(dependentPicklistEntry.validFor, k)) {
                    // Get the label
                    String controllingPicklistLabel = controllingPicklistValues[k].getLabel();
                    dependentValuesResult.get(controllingPicklistLabel).add(dependentPicklistEntry.label);
                }
            }
        }
        return dependentValuesResult;
    }
}