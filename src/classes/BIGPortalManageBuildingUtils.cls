/**
 * This class is in charge to handle buldings for PG&E Portal.
 *
 * @author Maiquel Cabrera <maiquel.cabrera@modelitsoftware.com>
 * @since 2013-6
 */
public with sharing class BIGPortalManageBuildingUtils {

    // Constants
    public static final String BUILDING_TYPE_SINGLE = 'Single Family';
    public static final String BUILDING_TYPE_MULTY = '2-4 Units';
    // Private Properties
    private BIGPortalUser userUtility;
    private BIGPortalBuildingInformationUtils buildingInfoUtils;

    public BIGPortalManageBuildingUtils() {
        userUtility = new BIGPortalUser();
        buildingInfoUtils = new BIGPortalBuildingInformationUtils();
    }

    /**
     * Get Building by Id
     */
    public Building__c getBuilding(String buildingId) {
        Building__c building;
        try {
            List<Building__c> l = [
                SELECT Id, Building_Name__c, Building_Type__c, City__c, State__c, Street_Address__c, ZIP_Code__c
                FROM Building__c WHERE Id = :buildingId AND Account_del__c = :userUtility.getAccount().Id
                ];
            if (!l.isEmpty()) {
                building = l.get(0);
            }
        } catch (Exception e) {
            System.debug('### Exception while trying to query for Building: ' + e.getMessage());
        }
        return building;
    }

    /**
     * Get User Account
     */
    public Account getAccount() {
        return userUtility.getAccount();
    }

    /**
     * Get BIGPortalUser instance.
     *
     * @return BIGPortalUser instance.
     */
    public BIGPortalUser getUserUtils() {
        return this.userUtility;
    }

    /**
     * Insert/Update Building into database
     *
     * @param building The building. It can't be null.
     * @param dw The dwelling unit. 
     * @return True if the operation was successful, false otherwise. 
     */
    public Boolean saveBuilding(Building__c building, Dwelling_Unit__c dw) {
        Boolean success = true;
        Building__c oldBuilding;

        try {
            // Set account
            building.Account_del__c = userUtility.getAccount().Id;

            if (building.Id != null) {
                oldBuilding = getBuilding(building.Id);
            }

            // Insert/Update building
            upsert building;

            if (dw == null) {
                dw = new Dwelling_Unit__c();
            }
            success = createDwellingUnit(building, dw);
            success = updatePropertyOwner(oldBuilding, building, dw);
        } catch (Exception e) {
            success = false;
            System.debug('### Exception while trying to insert new Building: ' + e.getMessage());
            throw e;
        }
        return success;
    }

    /**
     * Insert/Update Dwelling Unit into database
     */
    private Boolean createDwellingUnit(Building__c building, Dwelling_Unit__c dw) {
        Boolean success = true;
        Dwelling_Unit__c dwellingUnit = dw;
        try {
            // Set Building
            dwellingUnit.Building__c = building.Id;
            // Set Dwelling Unit Name
            dwellingUnit.Dwelling_Unit_Name__c = building.Building_Name__c;
            // Set Dwelling Unit Street Address
            dwellingUnit.Street_Address__c = building.Street_Address__c;
            upsert dwellingUnit;
        } catch (Exception e) {
            success = false;
            System.debug('### Exception while trying to insert new Dwelling Unit: ' + e.getMessage());
            throw e;
        }
        return success;
    }

    /**
     * Updates Property Owner.
     *
     * @param building The actual building.
     * @param dwellingUnit The dwelling unit.
     * @param oldBuilding The old version of the building.
     * @return True if the operation was successful, false otherwise.
     */
    private Boolean updatePropertyOwner(Building__c oldBuilding, Building__c building, Dwelling_Unit__c dwellingUnit) {
        Boolean success = true;

        try {
            if (oldBuilding != null) {
                Contact propertyOwner = buildingInfoUtils.getPropertyOwner(dwellingUnit.Property_Owner__c);
                // Check if property owner exists.
                if (propertyOwner != null
                        && buildingInfoUtils.propertyOwnerAndBuildingAddressMatch(oldBuilding, propertyOwner)) {
                    // Update propery owner if it had the same building's address.
                    propertyOwner.MailingStreet = building.Street_Address__c;
                    propertyOwner.MailingCity = building.City__c;
                    propertyOwner.MailingState = building.State__c;
                    propertyOwner.MailingPostalCode = building.ZIP_Code__c;
                    update propertyOwner;
                }
            }
        } catch (Exception e) {
            success = false;
            System.debug('### Exception while trying to update property owner ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
            throw e;
        }
        return success;
    }
}