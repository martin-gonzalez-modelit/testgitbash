public with sharing class BIGPortalDwellingUnitController {
    // Private properties
    private BIGPortalBuildingInformationUtils buildingInfoUtility;
    private Dwelling_Unit__c dwellingUnit;
    // Public Properties
    public Building__c building { get; set; }
    public Boolean showInfo { get; set; }

	public BIGPortalDwellingUnitController() {
		// Instantiate utility
        buildingInfoUtility = new BIGPortalBuildingInformationUtils();
	}

    /**
     * Save Dwelling Unit to Database
     *
     * @return BigPortalManageBuilding page
     */
    public PageReference saveDwellingUnit() {
        PageReference detail;

        try {
            if (building != null && dwellingUnit != null) {
                String url = BIGPortalBuildingInformationUtils.ACTION_DETAIL_URL + building.Id;
                buildingInfoUtility.saveDwellingUnit(dwellingUnit, building);
                List<Utility_Account__c> utilityAccList = buildingInfoUtility.getUtilityAccounts(dwellingUnit.Id);
                Utility_Account__c ua = !utilityAccList.isEmpty() ? utilityAccList.get(0) : null;


                if (buildingInfoUtility.isIneligible(building, dwellingUnit, ua)) {
                    url += BIGPortalBuildingInformationUtils.INELIGIBLE_PARAMETER;
                    buildingInfoUtility.markBuildingIneligibility(dwellingUnit,
                            BIGPortalBuildingInformationUtils.HUP);
                } else {
                    buildingInfoUtility.markBuildingIneligibility(dwellingUnit, '');
                }

                detail = new PageReference(url);
                detail.setRedirect(false);

                // Show dwelling unit info
                showInfo = true;
            }
        } catch (Exception e) {
            ApexPages.Message message = new ApexPages.message(ApexPages.severity.ERROR, e.getMessage());
            ApexPages.addMessage(message);
        }

        return detail;
    }

    public void setDwellingUnit(Dwelling_Unit__c dwUnit) {
        dwellingUnit = dwUnit;
        prepareDwellingUnit();
    }


    public Dwelling_Unit__c getDwellingUnit() {
        return dwellingUnit;
    }

    /**
     * Set Dwelling unit based on building type
     */
    public PageReference prepareDwellingUnit() {
        showInfo = false;
        if (building != null && dwellingUnit != null) {
            // Show dwelling unit info
            showInfo = checkRequiredFields();
        }
        return null;
    }

    /**
     * Check that all required fields are populated
     */
    private Boolean checkRequiredFields() {
        return (dwellingUnit.Conditioned_Area__c != null &&
                dwellingUnit.Avg_Ceiling_Height__c != null &&
                dwellingUnit.Number_of_Stories__c != null &&
                !BIGPortalBuildingInformationUtils.isEmpty(dwellingUnit.Attic_Type__c) &&
                !BIGPortalBuildingInformationUtils.isEmpty(dwellingUnit.Primary_Fuel__c) &&
                !BIGPortalBuildingInformationUtils.isEmpty(dwellingUnit.Heating_System__c) &&
                !BIGPortalBuildingInformationUtils.isEmpty(dwellingUnit.Air_Conditioning__c) &&
                !BIGPortalBuildingInformationUtils.isEmpty(dwellingUnit.Hot_Water_Fuel__c) &&
                !BIGPortalBuildingInformationUtils.isEmpty(dwellingUnit.Foundation_Type__c) &&
                !BIGPortalBuildingInformationUtils.isEmpty(dwellingUnit.Hot_Water_System__c) &&
                dwellingUnit.Year_Built__c != null);
    }

}