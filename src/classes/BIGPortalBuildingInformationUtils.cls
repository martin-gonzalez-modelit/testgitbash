/**
 * This class handles building for PG&E HUP program.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2013-9
 */
public with sharing class BIGPortalBuildingInformationUtils {

    // Public constants
    public static final String ACQC = 'ACQC';
    public static final String AHU = 'AHU';
    public static final String HUP = 'HU';
    public static final String INELIGIBLE_PARAMETER = '&ineligible=true';
    public static final String ACTION_DETAIL_URL = '/BIGPortalManageBuilding?action=detail&id=';
    public static final String PGE = 'Pacific Gas and Electric Company';
    public static final String SOUTHERN_CA_GAS_COMPANY = 'Southern California Gas Company';
    public static final String SACRAMENTO_MUNICIPAL_UTILITY_DISTRICT = 'Sacramento Municipal Utility District';
    public static final String PROPANE = 'Propane';
    public static final String OTHER = 'Other';
    public static final String ALL_ELECTRIC_HOME = 'No Gas (All Electric Home)';
    // Private constants
    private static final String CONTACT_RT_PROPERTY_OWNER = 'Property Owner';
    private static final String CONTACT_ROLE_PROPERTY_OWNER = 'Property Owner';
    private static final String SINGLE_FAMILIY = 'Single Family';
    private static final String NONE = 'None';
    private static final String ELECTRICITY = 'Electricity';
    // Private properties
    private BIGPortalUser userUtility;
    // Billing contact record type id
    private static Id propertyOwnerRTId = Schema.Sobjecttype.Contact.getRecordTypeInfosByName()
            .get(CONTACT_RT_PROPERTY_OWNER).getRecordTypeId();

    public BIGPortalBuildingInformationUtils() {
        userUtility = new BIGPortalUser();
    }

    /**
     * Get Dwelling Units by building Id
     */
    public List<Dwelling_Unit__c> getDwellingUnits(Id buildingId) {
        List<Dwelling_Unit__c> dwellingUnitsList;
        try {
            dwellingUnitsList = [
                SELECT Id, Building__c, Air_Conditioning__c, Attic_Type__c, Avg_Ceiling_Height__c, Conditioned_Area__c,
                    Foundation_Type__c, Heating_System__c, Hot_Water_Fuel__c, Hot_Water_System__c,
                    Number_of_Bedrooms__c, Number_of_Occupants__c, Number_of_Stories__c, Pr_Heat_Contrib__c,
                    Primary_Fuel__c, Secondary_Fuel__c, Unit_Number__c, Year_Built__c, Property_Owner__c,
                    Dwelling_Unit_Name__c, Street_Address__c, Program_Ineligibility__c
                FROM Dwelling_Unit__c
                WHERE Building__c =: buildingId
                    AND Building__r.Account_del__c =: userUtility.getAccount().Id
                ];
        } catch (Exception e) {
            System.debug('### Exception while trying to query for Dwelling Units: ' + e.getMessage());
        }
        return dwellingUnitsList;
    }

    /**
     * Query for all the dwelling units related to the given building Id.
     *
     * @param buildingId The building id to look for.
     * @return Map<Id, Dwelling_Unit__c> Returns a map with all the dwelling units related to the building Id.
     */
    public Map<Id, Dwelling_Unit__c> getDwellingUnitsMap(Id buildingId) {
        Map<Id, Dwelling_Unit__c> dwellingUnitsMap;
        try {
            dwellingUnitsMap = new Map<Id, Dwelling_Unit__c>([
                SELECT Id, Program_Ineligibility__c, Unit_Number__c, Year_Built__c, Street_Address__c, Attic_Type__c,
                    Dwelling_Unit_Name__c, Foundation_Type__c, Heating_System__c, Air_Conditioning__c,
                    Avg_Ceiling_Height__c, Hot_Water_System__c, Number_of_Bedrooms__c, Number_of_Occupants__c,
                    Number_of_Stories__c, Pr_Heat_Contrib__c, Primary_Fuel__c, Secondary_Fuel__c, Hot_Water_Fuel__c,
                    Conditioned_Area__c, Building__c, Building__r.Building_Type__c, Building__r.City__c,
                    Building__r.State__c, Building__r.ZIP_Code__c, Building__r.County__c, Building__r.Building_Name__c,
                    Building__r.Street_Address__c, Property_Owner__c, Property_Owner__r.FirstName,
                    Property_Owner__r.LastName, Property_Owner__r.MailingStreet, Property_Owner__r.MailingCity,
                    Property_Owner__r.MailingState, Property_Owner__r.MailingPostalCode, Property_Owner__r.Email,
                    Property_Owner__r.Phone,
                    (SELECT Id, Account_Holder_First_Name__c, Account_Holder_Last_Name__c, Phone__c,
                        Electric_Provider__c, Electric_Account_Number__c, Gas_Provider__c, Gas_Account_Number__c
                     FROM Utility_Accounts__r ORDER BY LastModifiedDate DESC LIMIT 1)
                FROM Dwelling_Unit__c
                WHERE Building__c =: buildingId
                    AND Building__r.Account_del__c =: userUtility.getAccount().Id
                ORDER BY CreatedDate DESC LIMIT 1
                ]);
        } catch (QueryException e) {
            System.debug('### Exception while trying to query for Dwelling Units Map: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('### Exception while trying to query for Dwelling Units Map: ' + e.getMessage());
        }
        return dwellingUnitsMap;
    }

    /**
     * Query for dwelling unit by dwelling unit Id.
     * @return Dwelling_Unit__c Returns dwelling unit found.
     */
    public Dwelling_Unit__c getDwellingUnitById(Id dwellingUnitId) {
        Dwelling_Unit__c dw;
        try {
            dw = [
                SELECT Id, Building__c, Air_Conditioning__c, Attic_Type__c, Avg_Ceiling_Height__c, Conditioned_Area__c,
                    Foundation_Type__c, Heating_System__c, Hot_Water_Fuel__c, Hot_Water_System__c,
                    Number_of_Bedrooms__c, Number_of_Occupants__c, Number_of_Stories__c, Pr_Heat_Contrib__c,
                    Primary_Fuel__c, Secondary_Fuel__c, Unit_Number__c, Year_Built__c, Property_Owner__c,
                    Dwelling_Unit_Name__c, Street_Address__c
                FROM Dwelling_Unit__c WHERE Id=:dwellingUnitId
                ];
        } catch (DMLException ex) {
            System.debug('### A DMLException has occurred while trying to retrieve Dwelling Unit');
            System.debug('### Exception message: ' + ex.getMessage());
        } catch (Exception e) {
            System.debug('### A generic exception has occurred while trying to retrieve Dwelling Unit');
            System.debug('### Exception message: ' + e.getMessage());
        }
        return dw;
    }

    /**
     * Get Property Owner by Id
     */
    public Contact getPropertyOwner(Id propertyOwnerId) {
        Contact c = null;
        try {
            List<Contact> l = [
                SELECT Id, FirstName, LastName, Email, Phone, MailingStreet, MailingCity, MailingPostalCode,
                    MailingState
                FROM Contact WHERE Id =: propertyOwnerId
                    AND RecordTypeId =: propertyOwnerRTId AND AccountId =: userUtility.getAccount().Id
                ];
            if (!l.isEmpty()) {
                c = l.get(0);
            }
        } catch (Exception e) {
            System.debug('### Exception while trying to query for Property Owner: ' + e.getMessage());
        }
        return c;
    }

    /**
     * Get Utility Accounts List by dwelling unit Id
     */
    public List<Utility_Account__c> getUtilityAccounts(Id dwellingUnitId) {
        List<Utility_Account__c> utilityAccountsList = new List<Utility_Account__c>();
        try {
            utilityAccountsList = [
                SELECT Id, Electric_Provider__c, Electric_Account_Number__c, Gas_Provider__c, Gas_Account_Number__c,
                    Dwelling_Unit__c, Account_Holder_First_Name__c, Account_Holder_Last_Name__c, Phone__c
                FROM Utility_Account__c WHERE Dwelling_Unit__c =: dwellingUnitId
                ];
        } catch (Exception e) {
            System.debug('### Exception while trying to query for Property Owner: ' + e.getMessage());
        }
        return utilityAccountsList;
    }


    /**
     * Insert/Update Dwelling Unit into database
     */
    public Boolean saveDwellingUnit(Dwelling_Unit__c dwellingUnit, Building__c building) {
        Boolean success = true;
        try {
            upsert dwellingUnit;
        } catch (Exception e) {
            success = false;
            System.debug('### Exception while trying to upsert Dwelling Unit: ' + e.getMessage());
            throw e;
        }
        return success;
    }

    /**
     * Insert/Update Property Owner into database
     */
     public Boolean savePropertyOwner(Contact propertyOwner, Dwelling_Unit__c dwellingUnit, Building__c building) {
        Boolean success = true;

        try {
            // Set Record Type
            propertyOwner.RecordTypeId = propertyOwnerRTId;
            // Set account to Property Owner
            propertyOwner.AccountId = userUtility.getAccount().Id;
            // Set different address field
            propertyOwner.Different_Address__c = !propertyOwnerAndBuildingAddressMatch(building, propertyOwner);
            upsert propertyOwner;
            // Create contact role
            createPropertyOwnerContactRole(propertyOwner.Id);
            // Update Dwelling Unit
            dwellingUnit.Property_Owner__c = propertyOwner.Id;
            upsert dwellingUnit;
        } catch (Exception e) {
            success = false;
            System.debug('### Exception while trying to insert new Property Owner: ' + e.getMessage());
            throw e;
        }
        return success;
    }

    /**
     * Insert/Update Utility Account into database
     */
    public Boolean saveUtilityAccount(Utility_Account__c utilityAccount, Dwelling_Unit__c dwellingUnit,
            Building__c building) {
        Boolean success = true;
        try {
            // Set Dwelling unit
            utilityAccount.Dwelling_Unit__c = dwellingUnit.Id;
            upsert utilityAccount;
        } catch (Exception e) {
            success = false;
            System.debug('### Exception while trying to insert new Utility Account: ' + e.getMessage());
            throw e;
        }
        return success;
    }

    /**
    * Creates Contact role on account for property owner
    */
    private Boolean createPropertyOwnerContactRole(Id contactId) {
        Boolean success = true;
        try {
            AccountContactRole contactRole = new AccountContactRole();
            contactRole.ContactId = contactId;
            contactRole.AccountId = userUtility.getAccount().Id;
            contactRole.Role = CONTACT_ROLE_PROPERTY_OWNER;
            // Insert contact role
            insert contactRole;
        } catch (Exception e) {
            success = false;
            System.debug('### An error ocurred while creating property owner contact role on account : '
                    + e.getMessage());
        }
        return success;
    }
    /**
      * Determine if user has ACQC Program
      */
     public Boolean getHasACQCProgram() {
        return userUtility.hasACQCProgram();
     }

     /**
     *connect to BigPortalUser and check if HUPAdvancedProgram exists in Contact.Program_Enrollment__c picklist
     *@return Boolean
     */
     public Boolean getHasHUPAdvancedProgram(){
        return userUtility.hasAdvanceHUProgram();
     }

    /**
     * Check if the value is empty
     */
    public static Boolean isEmpty(String value){
        return !( value != null && value.length() > 0 );
    }

    public List<SelectOption> getStates() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('AL','AL'));
        options.add(new SelectOption('AK','AK'));
        options.add(new SelectOption('AZ','AZ'));
        options.add(new SelectOption('AR','AR'));
        options.add(new SelectOption('CA','CA'));
        options.add(new SelectOption('CO','CO'));
        options.add(new SelectOption('CT','CT'));
        options.add(new SelectOption('DE','DE'));
        options.add(new SelectOption('DC','DC'));
        options.add(new SelectOption('FL','FL'));
        options.add(new SelectOption('GA','GA'));
        options.add(new SelectOption('HI','HI'));
        options.add(new SelectOption('ID','ID'));
        options.add(new SelectOption('IL','IL'));
        options.add(new SelectOption('IN','IN'));
        options.add(new SelectOption('IA','IA'));
        options.add(new SelectOption('KS','KS'));
        options.add(new SelectOption('KY','KY'));
        options.add(new SelectOption('LA','LA'));
        options.add(new SelectOption('ME','ME'));
        options.add(new SelectOption('MD','MD'));
        options.add(new SelectOption('MA','MA'));
        options.add(new SelectOption('MI','MI'));
        options.add(new SelectOption('MN','MN'));
        options.add(new SelectOption('MS','MS'));
        options.add(new SelectOption('MO','MO'));
        options.add(new SelectOption('MT','MT'));
        options.add(new SelectOption('NE','NE'));
        options.add(new SelectOption('NV','NV'));
        options.add(new SelectOption('NH','NH'));
        options.add(new SelectOption('NJ','NJ'));
        options.add(new SelectOption('NM','NM'));
        options.add(new SelectOption('NY','NY'));
        options.add(new SelectOption('NC','NC'));
        options.add(new SelectOption('ND','ND'));
        options.add(new SelectOption('OH','OH'));
        options.add(new SelectOption('OK','OK'));
        options.add(new SelectOption('OR','OR'));
        options.add(new SelectOption('PA','PA'));
        options.add(new SelectOption('RI','RI'));
        options.add(new SelectOption('SC','SC'));
        options.add(new SelectOption('SD','SD'));
        options.add(new SelectOption('TN','TN'));
        options.add(new SelectOption('TX','TX'));
        options.add(new SelectOption('UT','UT'));
        options.add(new SelectOption('VT','VT'));
        options.add(new SelectOption('VA','VA'));
        options.add(new SelectOption('WA','WA'));
        options.add(new SelectOption('WV','WV'));
        options.add(new SelectOption('WI','WI'));
        options.add(new SelectOption('WY','WY'));

        return options;
    }

    /**
     * Dertermines if a builing is ineligible based on air conditioning, primary heating fuel, electric provider
     * gas provider, building type and year built
     *
     * @param building allows to dertermine ineligibility based on the building type
     * @param dw helps to the utility account object to determine ineligibility
     * @param ua based on data wich belongs to the dwelling unit object determines ineligibility
     * @return true if the building is ineligible.
     */
    public Boolean isIneligible(Building__c building, Dwelling_Unit__c dw, Utility_Account__c ua) {
        Boolean result = false;
        if (building != null && String.isNotEmpty(building.Building_Type__c)) {
            result = isBuidlingTypeIneligible(building);
        }

        if (!result && dw != null) {
            if (ua != null && String.isNotEmpty(ua.Electric_Provider__c) && String.isNotEmpty(ua.Gas_Provider__c)) {
                if (String.isNotEmpty(dw.Air_Conditioning__c)) {
                    result = isAirConditioningIneligible(ua, dw);
                }
                if (!result && String.isNotEmpty(dw.Primary_Fuel__c)) {
                    result = isPrimaryFuelIneligible(ua, dw);
                }
            }
            if (!result && dw.Year_Built__c != null && Integer.valueOf(dw.Year_Built__c) > 2001) {
                result = true;
            }
        }

        return result;
    }

    /**
     * Determines if a building is ineligible based on the building type
     * @param building contains the building type attribute which is used to determine ineligibility
     * @return true if it's ineligible
     */
    private Boolean isBuidlingTypeIneligible(Building__c building) {
        return (building.Building_Type__c != SINGLE_FAMILIY);
    }

    /**
     * Determines if a building is ineligible based on the combination of these attributes:
     * gas provider, electric provider and air conditioning
     * @param ua contains the gas provider attribute
     * @param dw contains the air conditioning attribute
     * @return true if it's ineligible
     */
    public Boolean isAirConditioningIneligible(Utility_Account__c ua, Dwelling_Unit__c dw) {
        Boolean res = false;

        if (dw.Air_Conditioning__c == NONE) {
            if ((ua.Electric_Provider__c == PGE)
                    && (ua.Gas_Provider__c != PGE && ua.Gas_Provider__c != SOUTHERN_CA_GAS_COMPANY)) {
                res = true;
            }
        }
        return res;
    }

    /**
     * Determines if a building is ineligible based on the combination of these attributes
     * gas provider, electric provider and primary heating fuel
     * @param ua contains the electric provider and gas provider attributes
     * @param dw contains the primary heating fuel attribute
     * @return true if it's ineligible
     */
    private Boolean isPrimaryFuelIneligible(Utility_Account__c ua, Dwelling_Unit__c dw) {
        Boolean res = false;

        if (dw.Primary_Fuel__c == ELECTRICITY) {
            if (ua.Electric_Provider__c != PGE) {
                if (ua.Gas_Provider__c == PGE) {
                    res = true;
                }
            }
        }
        return res;
    }

    /**
     * Save in salesforce if the given building is ineligible or not
     * @param program this string should be built this way: "HU" or "HU;ACQC;AHU;..."
     */
    public void markBuildingIneligibility(Dwelling_Unit__c dw, String program) {
        String [] listPrograms;
        Integer total = 0;
        Integer i = 0;
        Integer sizeListPrograms;

        try {
            if (dw != null && program != null
                    && ((String.isNotEmpty(dw.Program_Ineligibility__c) && String.isEmpty(program))
                        || (String.isEmpty(dw.Program_Ineligibility__c) && String.isNotEmpty(program))
                        || (String.isNotEmpty(dw.Program_Ineligibility__c) && String.isNotEmpty(program)
                        && dw.Program_Ineligibility__c != program))) {
                listPrograms = program.split(';');
                sizeListPrograms = listPrograms.size();
                while (i < sizeListPrograms) {
                    if (String.isBlank(listPrograms[i]) || listPrograms[i] == ACQC || listPrograms[i] == HUP
                            || listPrograms[i] == AHU) {
                        total++;
                    }
                    i++;
                }
                if (total != sizeListPrograms || (existsEmptyVal(listPrograms))) {
                    dw.addError('Invalid string program');
                }

                dw.Program_Ineligibility__c = program;
                update dw;
            }
        } catch (Exception e) {
            System.debug('###Invalid string program:' + e.getStackTraceString());
        }
    }

    /**
     * Checks if listPrograms has more than 1 element. If it's true then checks if there is an empty value in the list
     *
     * @param listPrograms collection which contains the pge programs
     * @return true if it contains an empty value and has more than 1 element.
     */
    private Boolean existsEmptyVal(String [] listPrograms) {
        Boolean result = false;
        Integer i = 0;
        Integer listProgramSize = listPrograms.size();

        if (listProgramSize > 1) {
            while (i < listProgramSize && !result) {
                result = String.isBlank(listPrograms[i]);
                i++;
            }
        }
        return result;
    }

    /**
     * Verify that the dwelling unit has all required fields and that property owner and utility account are not null
     *
     * @param dwellingUnit The dwelling unit to check all required fields have been filled.
     * @return True if all required fields were filled, false otherwise.
     */
    public static Boolean isDwellingUnitRequiredDataComplete(Dwelling_Unit__c dwellingUnit) {
        return (isDwellingUnitComplete(dwellingUnit)
                && isPropertyOwnerComplete(dwellingUnit.Property_Owner__r)
                && !dwellingUnit.Utility_Accounts__r.isEmpty()
                && isUtilityAccountComplete(dwellingUnit.Utility_Accounts__r));
    }

    /**
     * Checks if the dwelling unit has all required fields filled.
     *
     * @param dwellingUnit The dwelling unit to check.
     * @return True if the dwelling unit has been completed, false otherwise.
     */
    public static Boolean isDwellingUnitComplete(Dwelling_Unit__c dwellingUnit) {
        return (dwellingUnit != null
                && dwellingUnit.Conditioned_Area__c != null
                && dwellingUnit.Avg_Ceiling_Height__c != null
                && dwellingUnit.Number_of_Stories__c != null
                && dwellingUnit.Year_Built__c != null
                && String.isNotBlank(dwellingUnit.Attic_Type__c)
                && String.isNotBlank(dwellingUnit.Primary_Fuel__c)
                && String.isNotBlank(dwellingUnit.Heating_System__c)
                && String.isNotBlank(dwellingUnit.Air_Conditioning__c)
                && String.isNotBlank(dwellingUnit.Hot_Water_Fuel__c)
                && String.isNotBlank(dwellingUnit.Foundation_Type__c)
                && String.isNotBlank(dwellingUnit.Hot_Water_System__c));
    }

    /**
     * Checks if property owner (contact) has all required fields filled.
     *
     * @param propertyOwner The property owner to check.
     * @return True if the property owner has been completed, false otherwise.
     */
    public static Boolean isPropertyOwnerComplete(Contact propertyOwner) {
        return (propertyOwner != null
                && String.isNotBlank(propertyOwner.FirstName)
                && String.isNotBlank(propertyOwner.LastName)
                && String.isNotBlank(propertyOwner.Phone)
                && String.isNotBlank(propertyOwner.MailingStreet)
                && String.isNotBlank(propertyOwner.MailingCity)
                && String.isNotBlank(propertyOwner.MailingState)
                && String.isNotBlank(propertyOwner.MailingPostalCode));
    }

    /**
     * Checks if utility account has all required fields filled.
     *
     * @param utilityAccount The utility account to check.
     * @return True if the utility account has been completed, false otherwise.
     */
    public static Boolean isUtilityAccountComplete(Utility_Account__c utilityAccount) {
        Boolean isServiceProviderComplete = true;

        // Check that an electric account number has been supplied if the electric provider is not 'Other'.
        // In case that electric provider is set to 'Other' is not required to enter a value for the account number.
        if (String.isBlank(utilityAccount.Electric_Provider__c)
                || ((utilityAccount.Electric_Provider__c == PGE
                || utilityAccount.Electric_Provider__c == SACRAMENTO_MUNICIPAL_UTILITY_DISTRICT)
                && String.isBlank(utilityAccount.Electric_Account_Number__c))) {
            isServiceProviderComplete = false;
        }

        // Check that a gas account number has been supplied if the gas provider is
        // either 'Pacific Gas and Electric Company' or 'Southern California Gas Company'.
        if (String.isBlank(utilityAccount.Gas_Provider__c)
                || ((utilityAccount.Gas_Provider__c == PGE
                || utilityAccount.Gas_Provider__c == SOUTHERN_CA_GAS_COMPANY)
                && String.isBlank(utilityAccount.Gas_Account_Number__c))) {
            isServiceProviderComplete = false;
        }

        return (String.isNotBlank(utilityAccount.Account_Holder_First_Name__c)
                && String.isNotBlank(utilityAccount.Account_Holder_Last_Name__c)
                && String.isNotBlank(utilityAccount.Phone__c)
                && isServiceProviderComplete);
    }

    /**
     * Determines if the building and the property owner have different address information, and sets the value of the
     * checkbox "Same as mailing address".
     *
     * @param building The building.
     * @param propertyOwner The property owner.
     * @return True when all the fields match exactly, returns false otherwise.
     */
    public Boolean propertyOwnerAndBuildingAddressMatch(Building__c building, Contact propertyOwner) {
        return (building.Street_Address__c == propertyOwner.MailingStreet
                && building.City__c == propertyOwner.MailingCity
                && building.State__c == propertyOwner.MailingState
                && building.ZIP_Code__c == propertyOwner.MailingPostalCode);
    }

    /**
     * Determines if the utility account and the property owner have the same basic information (First Name, Last Name,
     * and Phone) and sets the value of the checkbox "Same as contract-signing customer".
     * If the utility account fields are empty, the checkbox is set to false.
     *
     * @param utilityAccount The utility account.
     * @param propertyOwner The property owner.
     * @return True when all the fields match exactly, returns false otherwise.
     */
    public Boolean utilityAccountAndPropertyOwnerInfoMatch(Utility_Account__c utilityAccount, Contact propertyOwner) {
        Boolean hasDifferentBasicInfo;

        if (String.isBlank(utilityAccount.Account_Holder_First_Name__c)
                && String.isBlank(utilityAccount.Account_Holder_Last_Name__c)
                && String.isBlank(utilityAccount.Phone__c)) {
            hasDifferentBasicInfo = false;
        } else {
            hasDifferentBasicInfo = (utilityAccount.Account_Holder_First_Name__c == propertyOwner.FirstName
                    && utilityAccount.Account_Holder_Last_Name__c == propertyOwner.LastName
                    && utilityAccount.Phone__c == propertyOwner.Phone);
        }

        return hasDifferentBasicInfo;
    }
}