/**
 * This controller handles Manage Building Page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-03
 */
public with sharing class BIGPortalManageBuildingController {

    // Constants
    private static final String ACTION_DETAIL = 'detail';
    private static final String ACTION_EDIT = 'edit';
    private static final String ACTION_NEW = 'new';
    private static final String DEFAULT_STATE_BUILDING = 'CA';
    private static final String INELIGIBLE = 'ineligible';
    // Constants error messages
    private static final String INELIGIBLE_MSG = 'This home is currently ineligible for the Home Upgrade incentive.';
    private static final String INELIGIBLE_YEAR_BUILT_MSG = 'Homes built after 2001 are not eligible for the Home '
            + 'Upgrade pathway. If you are enrolled in Advanced and the job scope is eligible, consider submitting '
            + 'as an Advanced Home Upgrade application.';
    private static final String BUILDING_NAME_REQUIRED_ERROR = 'Building Name is required';
    private static final String BUILDING_ST_ADDRESS_REQUIRED_ERROR = 'Building Street Address is required';
    private static final String BUILDING_CITY_REQUIRED_ERROR = 'Building City is required';
    private static final String BUILDING_ZIP_REQUIRED_ERROR = 'Building Zip Code is required';
    private static final String BUILDING_TYPE_REQUIRED_ERROR = 'Building Type is required';
    // Private properties
    private BIGPortalManageBuildingUtils buildingUtility;
    private BIGPortalBuildingInformationUtils buildingInfoUtil;
    private String buildingId;
    private Map<Id, Dwelling_Unit__c> buildingUnits;
    // Public properties
    public String action { get; set; }
    public Building__c building { get; set; }
    public Dwelling_Unit__c dwellingUnit { get; set; }
    public Contact propertyOwner { get; set; }
    public Utility_Account__c utilityAccount { get; set; }
    public String accountName { get; set; }
    public String accountId { get; set; }
    public String dwellingToEditId { get; set; }
    public Boolean ineligibleForHUP { get; set; }

    /**
     * Get valid Zip_Code_mdt records
     */
    public String getPGETerritoryZipCodes() {
        return ApplicationUtils.getPGETerritoryZipCodes();
    }

    public BIGPortalManageBuildingController() {
        // Instantiate building utility
        buildingUtility = new BIGPortalManageBuildingUtils();
        buildingInfoUtil = new BIGPortalBuildingInformationUtils();
        // Set Account name and Id
        accountName = buildingUtility.getAccount().Name;
        accountId = buildingUtility.getAccount().Id;
    }

    /**
     * Checks if user has access and then initialize the data model.
     *
     * @return The current page if the user has access to HU/AHU programs, or a redirect to the Access Denied page.
     */
    public PageReference init() {
        PageReference redirect = BIGUtility.checkHUOrAHUContactAccess(buildingUtility.getUserUtils());
        if (redirect == null) {
            // Validate parameters
            validateParameters();
            if (action == ACTION_NEW) {
                // Create new building instance
                building = new Building__c();
            } else if (action == ACTION_EDIT || action == ACTION_DETAIL) {
                // Get building by Id
                building = buildingUtility.getBuilding(buildingId);
                // Get list of dwelling units associated to this building
                buildingUnits = buildingInfoUtil.getDwellingUnitsMap(building.Id);
                // Process the information when single family detach
                if (buildingUnits != null && buildingUnits.size() > 0) {
                    // Set the unique dwelling unit
                    dwellingUnit = buildingUnits.values().get(0);
                } else {
                    // Create New Dwelling Unit Instance
                    dwellingUnit = new Dwelling_Unit__c();
                    // Assign Building Id
                    dwellingUnit.Building__c = building.Id;
                }
                // Assign Property Owner
                assignPropertyOwner();
                // Assign Utility Account
                assignUtilityAccount();

                if (dwellingUnit != null && String.isNotEmpty(dwellingUnit.Program_Ineligibility__c)) {
                    Set<String> ineligiblePrograms = new Set<String>(dwellingUnit.Program_Ineligibility__c.split(';'));
                    ineligibleForHUP = ineligiblePrograms.contains(BIGPortalBuildingInformationUtils.HUP);
                }

                if (ApexPages.currentPage().getParameters().containsKey(INELIGIBLE) || ineligibleForHUP == true) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, INELIGIBLE_MSG));
                    Boolean inelegibleYearBuilt =
                            dwellingUnit.Year_Built__c != null && Integer.valueOf(dwellingUnit.Year_Built__c) > 2001;
                    if (inelegibleYearBuilt) {
                        ApexPages.addMessage( new ApexPages.message(ApexPages.severity.INFO,
                                INELIGIBLE_YEAR_BUILT_MSG));
                    }
                }
            }
        }

        return redirect;
    }

    /**
     * Check if contact has HU Enrollment Program suspended.
     *
     * @return True if HU Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean getIsHUSuspended() {
        return buildingUtility.getUserUtils().isHUSuspended();
    }
    /**
     * Check if contact has AHU Enrollment Program suspended.
     *
     * @return True if AHU Program Enrollment is in "Suspended" status, otherwise return false.
     */
    public Boolean getIsAHUSuspended() {
        return buildingUtility.getUserUtils().isAHUSuspended();
    }
    
    /**
     * Check if contact has HU Enrollment Program terminated.
     *
     * @return True if HU Program Enrollment is in "Terminated" status, otherwise return false.
     */
    public Boolean getIsHuTerminated() {
        return buildingUtility.getUserUtils().isHuTerminated();
    }

    /**
     * Validate parameters recived
     */
    private void validateParameters() {
        String pAction = ApexPages.currentPage().getParameters().get('action');
        String pId = ApexPages.currentPage().getParameters().get('id');
        if (pAction != null) {
            if(pAction == ACTION_EDIT || pAction == ACTION_DETAIL || pAction == ACTION_NEW) {
                action = pAction;
            }
            if (pId !=null) {
                buildingId = String.escapeSingleQuotes(pId);
            }
        }
    }

    /**
     * Save New Dwelling unit
     * This method is called from the popup when building type is 2-4 units
     */
    public void saveNewDwellingUnit() {
        try {
            // Save dwelling unit
            if (buildingInfoUtil.saveDwellingUnit(dwellingUnit, building)) {
                // Update dwelling units list
                if (buildingUnits == null) {
                    buildingUnits = new Map<Id, Dwelling_Unit__c>();
                }
                buildingUnits.put(dwellingUnit.Id, dwellingUnit);
            }
        } catch (Exception e) {

        }
    }

    /**
     * Create New Dwelling Unit
     * This method sets dwellingUnit, propertyOwner and utilityAccount attributes
     * when building type is 2-4 units
     */
    public void createNewDwellingUnit() {
        // Unset Dwelling Unit
        dwellingUnit = null;
        // Unset Property Owner
        propertyOwner = null;
        // Unset Utility Account
        utilityAccount = null;
        if (dwellingToEditId == null || dwellingToEditId == '') {
            // Create a new dwelling unit
            dwellingUnit = new Dwelling_Unit__c();
            // Set Building
            dwellingUnit.Building__c = building.Id;
        } else {
            // Edit an existing dwelling unit
            dwellingUnit = buildingUnits.get(dwellingToEditId);
        }
        assignPropertyOwner();
        assignUtilityAccount();
    }

    /**
     * This method is used to determine if the additional dwelling unit
     * information is displayed on the new dwelling unit popup
     */
    public Boolean getShowAdditionalInfo() {
        return dwellingUnit != null && dwellingUnit.Street_Address__c != null && dwellingUnit.Unit_Number__c != null
               && dwellingUnit.Dwelling_Unit_Name__c != null;
    }


    /**
     * Save building record
     */
    public PageReference saveBuilding() {
        PageReference detailPage;
        Boolean success = true;
        Dwelling_Unit__c dw;
        List<Dwelling_Unit__c> dwList;

        if (String.isEmpty(building.Building_Name__c)) {
            building.addError(BUILDING_NAME_REQUIRED_ERROR);
            success = false;
        }
        if (String.isEmpty(building.Street_Address__c)) {
            building.addError(BUILDING_ST_ADDRESS_REQUIRED_ERROR);
            success = false;
        }
        if (String.isEmpty(building.City__c)) {
            building.addError(BUILDING_CITY_REQUIRED_ERROR);
            success = false;
        }
        if (String.isEmpty(building.ZIP_Code__c)) {
            building.addError(BUILDING_ZIP_REQUIRED_ERROR);
            success = false;
        }
        if (String.isEmpty(building.Building_Type__c)) {
            building.addError(BUILDING_TYPE_REQUIRED_ERROR);
            success = false;
        }
        if (!success) {
            return detailPage;
        }

        try {
            if (building != null) {
                building.State__c = DEFAULT_STATE_BUILDING;
                if (buildingUtility.saveBuilding(building, dwellingUnit)) {
                    String url = BIGPortalBuildingInformationUtils.ACTION_DETAIL_URL + building.Id;
                    dwList = buildingInfoUtil.getDwellingUnits(building.Id);
                    dw = (dwList != null && dwList.size() > 0) ? dwList.get(0) : null;

                    // Set BuildingManage page
                    if (buildingInfoUtil.isIneligible(building, null, null)) {
                        url+= BIGPortalBuildingInformationUtils.INELIGIBLE_PARAMETER;
                        if (dw != null) {
                            buildingInfoUtil.markBuildingIneligibility(dw, BIGPortalBuildingInformationUtils.HUP);
                        }
                    } else {
                        if (dw != null) {
                            buildingInfoUtil.markBuildingIneligibility(dw, '');
                        }
                    }
                    detailPage = new PageReference(url);
                    detailPage.setRedirect(false);

                }
            }
        } catch (Exception e) {
            ApexPages.Message message = new ApexPages.message(ApexPages.severity.ERROR, e.getMessage());
            ApexPages.addMessage(message);
        }
        return detailPage;
    }

    /**
     * Query for property owner contact related to the building and assign it to class attribute
     */
    private void assignPropertyOwner() {
        if (dwellingUnit != null) {
            // Set property owner
            if (dwellingUnit.Property_Owner__c != null) {
                propertyOwner = buildingInfoUtil.getPropertyOwner(dwellingUnit.Property_Owner__c);
            }

            if (propertyOwner == null) {
                propertyOwner = new Contact();
            }
        }
    }

    /**
     * Query for utility account related to the building and assign it to class attribute
     */
    private void assignUtilityAccount() {
        if (dwellingUnit != null) {
            // Set utility account
            List<Utility_Account__c> utilityAccLst = buildingInfoUtil.getUtilityAccounts(dwellingUnit.Id);
            utilityAccount = !utilityAccLst.isEmpty() ? utilityAccLst.get(0) : new Utility_Account__c();
        }
    }

    /**
     * Edit building action
     */
    public PageReference editBuilding() {
        PageReference editPage;
        // Set BuildingManage page
        editPage = Page.BIGPortalManageBuilding;
        // Set action parameter to edit
        editPage.getParameters().put('action', 'edit');
        // Set building Id parameter
        editPage.getParameters().put('id', String.valueOf(building.Id));
        return editPage.setRedirect(false);
    }

    /**
     * Determine if user has ACQC Program
     */
    public Boolean getHasACQCProgram() {
        return buildingInfoUtil.getHasACQCProgram();
    }

    /**
    *Determine if user has AdvancedHUP
    */
    public Boolean getHasAdvancedHUPProgram(){
        return buildingInfoUtil.getHasHUPAdvancedProgram();
    }

    /**
     * Verify that the dwelling unit has all required fields and that property owner and utility account are not null
     */
    public Boolean getIsDwellingUnitRequiredDataComplete() {
        return BIGPortalBuildingInformationUtils.isDwellingUnitRequiredDataComplete(dwellingUnit);
    }

}