public with sharing class BIGPortalUtilityAccountController {
    // Private properties
    private BIGPortalBuildingInformationUtils buildingInfoUtility;
    private Utility_Account__c utilityAccount;

    // Public Properties
    public Building__c building { get; set; }
    public Boolean showAccInfo { get; set; }
    public Dwelling_Unit__c dwellingUnit { get; set; }
    public Contact propertyOwner { get; set; }

    public BIGPortalUtilityAccountController() {
        // Instantiate utility
        buildingInfoUtility = new BIGPortalBuildingInformationUtils();
    }

    /**
     * Save Utility Account to Database
     *
     * @return BigPortalManageBuilding page
     */
    public PageReference saveUtilityAccount() {
        PageReference detail;
        try {
            if(building != null && dwellingUnit != null) {
                // Save utility account
                buildingInfoUtility.saveUtilityAccount(utilityAccount, dwellingUnit, building);
                // Show Utility Account info
                showAccInfo = true;
                String url = BIGPortalBuildingInformationUtils.ACTION_DETAIL_URL + building.Id;
                if (buildingInfoUtility.isIneligible(building, dwellingUnit, utilityAccount)) {
                    url += BIGPortalBuildingInformationUtils.INELIGIBLE_PARAMETER;
                    buildingInfoUtility.markBuildingIneligibility(dwellingUnit, BIGPortalBuildingInformationUtils.HUP);
                } else {
                    buildingInfoUtility.markBuildingIneligibility(dwellingUnit, '');
                }
                detail = new PageReference(url);
                detail.setRedirect(false);
            }
        } catch (Exception e) {
            ApexPages.Message message = new ApexPages.message(ApexPages.severity.ERROR, e.getMessage());
            ApexPages.addMessage(message);
        }
        return detail;
    }

    public void setUtilityAccount(Utility_Account__c uAcc) {
        utilityAccount = uAcc;
        displayInfo();
    }

    public Utility_Account__c getUtilityAccount() {
        return utilityAccount;
    }

    public PageReference displayInfo() {
        showAccInfo = (utilityAccount != null && utilityAccount.Id != null);
        return null;
    }

    public Boolean sameCustomerInfo {
        get {
            return buildingInfoUtility.utilityAccountAndPropertyOwnerInfoMatch(utilityAccount, propertyOwner);
        }
        set {
            sameCustomerInfo = value;
        }
    }

}