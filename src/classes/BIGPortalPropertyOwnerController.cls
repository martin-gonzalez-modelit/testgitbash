public with sharing class BIGPortalPropertyOwnerController {
    // Private properties
    private BIGPortalBuildingInformationUtils buildingInfoUtility;
    private Contact propertyOwner;
    // Public Properties
    public Building__c building { get; set; }
    public Boolean showOwnInfo { get; set; }
    public Dwelling_Unit__c dwellingUnit { get; set; }

    public BIGPortalPropertyOwnerController() {
        // Instantiate utility
        buildingInfoUtility = new BIGPortalBuildingInformationUtils();
    }

    /**
     * Save Property Owner to Database
     *
     * @return BigPortalManageBuilding page
     */
    public PageReference savePropertyOwner() {
        PageReference detail;

        try {
            if (building != null) {
                try {
                    Contact oldPropertyOwner = buildingInfoUtility.getPropertyOwner(this.propertyOwner.Id);
                    // Check that the property owner's basic information has changed: FirstName, LastName and Phone.
                    Boolean propertyOwnerInfoHasChanged = oldPropertyOwner != null
                            ? hasBasicInfoChanged(oldPropertyOwner, this.propertyOwner)
                            : true;

                    if (propertyOwnerInfoHasChanged) {
                        List<Utility_Account__c> utilityAccounts =
                                buildingInfoUtility.getUtilityAccounts(dwellingUnit.Id);

                        if (!utilityAccounts.isEmpty()) {
                            Utility_Account__c utility = utilityAccounts.get(0);
                            Contact propertyOwner = oldPropertyOwner != null
                                    ? oldPropertyOwner
                                    : this.propertyOwner;
                            // Update the utility account holder's information if:
                            // 1 - It matches the property owner's basic information.
                            // 2 - It's empty.
                            if (buildingInfoUtility.utilityAccountAndPropertyOwnerInfoMatch(utility, propertyOwner)) {
                                utility.Account_Holder_First_Name__c = this.propertyOwner.FirstName;
                                utility.Account_Holder_Last_Name__c = this.propertyOwner.LastName;
                                utility.Phone__c = this.propertyOwner.Phone;
                                update utility;
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error at savePropertyOwner(): Message: ' + e.getMessage());
                    System.debug('StackTrace: ' + e.getStackTraceString());
                }
                // Upsert property owner
                buildingInfoUtility.savePropertyOwner(this.propertyOwner, dwellingUnit, building);
                // Show property owner info
                showOwnInfo = true;
                detail = new PageReference(BIGPortalBuildingInformationUtils.ACTION_DETAIL_URL + building.Id);
                detail.setRedirect(false);
            }
        } catch(Exception e) {
            ApexPages.Message message = new ApexPages.message(ApexPages.severity.ERROR, e.getMessage());
            ApexPages.addMessage(message);
        }
        return detail;
    }

    public void setpropertyOwner(Contact pOwner) {
        // Set 'CA' state by default for new property owners.
        if (pOwner.Id == null) {
            pOwner.MailingState = 'CA';
        }
        propertyOwner = pOwner;
        displayInfo();
    }

    public Contact getPropertyOwner() {
        return propertyOwner;
    }

    public PageReference displayInfo() {
        showOwnInfo = (propertyOwner != null && propertyOwner.Id != null);
        return null;
    }

    public List<SelectOption> getStates() {
        return buildingInfoUtility.getStates();
    }

    /**
     * Determines if the property owner's basic information (First Name, Last Name and Phone) has changed.
     *
     * @param oldPropertyOwner The old version of the propery owner.
     * @param newPropertyOwner The new -actual- version of the propery owner.
     * @return True when at least one field has changed, returns false otherwise.
     */
    public Boolean hasBasicInfoChanged(Contact oldPropertyOwner, Contact newPropertyOwner) {
        return !(oldPropertyOwner.FirstName == newPropertyOwner.FirstName
                && oldPropertyOwner.LastName == newPropertyOwner.LastName
                && oldPropertyOwner.Phone == newPropertyOwner.Phone);
    }

    public Boolean sameAddress {
        get {
            return buildingInfoUtility.propertyOwnerAndBuildingAddressMatch(building, propertyOwner);
        }
        set {
            sameAddress = value;
        }
    }
}