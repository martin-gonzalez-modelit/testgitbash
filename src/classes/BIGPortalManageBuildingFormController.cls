/**
 * This class handles the Building Form Component.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2013-9
 */
public with sharing class BIGPortalManageBuildingFormController {

    // Constants
    private static final String ACTION_DETAIL = 'detail';
    private static final String ACTION_EDIT = 'edit';
    private static final String ACTION_NEW = 'new';
    private static final String DEFAULT_STATE_BUILDING = 'CA';
    private static final String SUBAPP_PRE_RECORD_TYPE_NAME = 'PRE-APP';
    private static final Id SUBAPP_PRE_RECORD_TYPE_ID = Schema.SObjectType.Sub_Application__c
            .getRecordTypeInfosByName().get(SUBAPP_PRE_RECORD_TYPE_NAME).getRecordTypeId();
    // Private properties
    private BIGPortalManageBuildingUtils buildingUtility;
    private BIGPortalBuildingInformationUtils buildingInfoUtil;
    private BIGPortalAdvancedHUAppController advancedController;
    private BIGPortalAdvanceHUApplicationUtils advanceApplicationUtility;
    private String buildingId;
    private Map<Id, Dwelling_Unit__c> buildingUnits;
    // Public properties
    public String action { get; set; }
    public String applicationId { get; set; }
    public Building__c building { get; set; }
    public Dwelling_Unit__c dwellingUnit { get; set; }
    public Contact propertyOwner { get; set; }
    public Utility_Account__c utilityAccount { get; set; }
    public String accountName { get; set; }
    public String accountId { get; set; }
    public String dwellingToEditId { get; set; }
    public Boolean isContinueAction { get; set; }

    /**
     * Get valid Zip_Code_mdt records
     */
     public String getPGETerritoryZipCodes() {
        return ApplicationUtils.getPGETerritoryZipCodes();
    }

    public BIGPortalManageBuildingFormController() {
        // Instantiate building utility
        buildingUtility = new BIGPortalManageBuildingUtils();
        buildingInfoUtil = new BIGPortalBuildingInformationUtils();
        advancedController = new BIGPortalAdvancedHUAppController();
        advanceApplicationUtility = new BIGPortalAdvanceHUApplicationUtils();
        // Set Account name and Id
        accountName = buildingUtility.getAccount().Name;
        accountId = buildingUtility.getAccount().Id;
	    isContinueAction = false;
        init();
    }

    /**
     * Initialize controller functionality
     */
    public void init() {
        // Validate parameters
        validateParameters();
        // Create new building instance
        building = new Building__c();
        // Create New Dwelling Unit Instance
        dwellingUnit = new Dwelling_Unit__c();
        propertyOwner = new Contact();
        utilityAccount = new Utility_Account__c();

        if (applicationId != null) {
        	try {
	            advancedController.application = advanceApplicationUtility.getApplication(applicationId);
            } catch(Exception e) {
               System.debug('An exception has occurred while trying to retrieve Application: ' + e.getMessage());
            }

           List<Sub_Application__c> subApps = advancedController.application.Sub_Applications__r;
           if (subApps != null) {
                for (Sub_Application__c subApp : subApps) {
                    if (subApp.RecordTypeId == SUBAPP_PRE_RECORD_TYPE_ID) {
                        // Load Pre-Application
                        advancedController.preApplication = subApp;
                        advancedController.selectedBPIAnalyst = subApp.BPI_Analyst__c;
                    }
                }
            }

            if (advancedController.application != null) {
               dwellingUnit = buildingInfoUtil.getDwellingUnitById(advancedController.application.Dwelling_Unit__c);
               if (dwellingUnit != null) {
                   building = buildingUtility.getBuilding(dwellingUnit.Building__c);
                   propertyOwner = buildingInfoUtil.getPropertyOwner(dwellingUnit.Property_Owner__c);
                   List<Utility_Account__c> utilities = buildingInfoUtil.getUtilityAccounts(dwellingUnit.Id);
                   if (utilities.size() == 1) {
                       utilityAccount = utilities.get(0);
                   }
               }
            }
        }
    }

    /**
     * Validate parameters recived
     */
    private void validateParameters() {
        String pAction = ApexPages.currentPage().getParameters().get('action');
        String pId = ApexPages.currentPage().getParameters().get('id');
        if (pAction != null) {
            if (pAction == ACTION_EDIT || pAction == ACTION_DETAIL || pAction == ACTION_NEW) {
                action = pAction;
            }
            if (pId !=null) {
                buildingId = String.escapeSingleQuotes(pId);
                applicationId = pId;
            }
        }
    }

    /**
     * Determine if user has ACQC Program
     */
    public Boolean getHasACQCProgram() {
        return buildingInfoUtil.getHasACQCProgram();
    }

    /**
    * Determine if user has AdvancedHUP
    */
    public Boolean getHasAdvancedHUPProgram(){
        return buildingInfoUtil.getHasHUPAdvancedProgram();
    }

    public List<SelectOption> getStates() {
        return buildingInfoUtil.getStates();
    }

    public PageReference saveBuildingInfo() {
        try {
            building.State__c = DEFAULT_STATE_BUILDING;
            buildingUtility.saveBuilding(building, dwellingUnit);
            buildingInfoUtil.saveDwellingUnit(dwellingUnit, building);

            // Check if the user filled last name field due is a required field.
            if (String.isNotBlank(propertyOwner.LastName)) {
                buildingInfoUtil.savePropertyOwner(propertyOwner, dwellingUnit, building);
            }

            buildingInfoUtil.saveUtilityAccount(utilityAccount, dwellingUnit, building);

            // Mark the building as INELIGIBLE FOR HUP
            if (buildingInfoUtil.isIneligible(building, dwellingUnit, utilityAccount)) {
                buildingInfoUtil.markBuildingIneligibility(dwellingUnit, BIGPortalBuildingInformationUtils.HUP);
            } else {
                buildingInfoUtil.markBuildingIneligibility(dwellingUnit, '');
            }

            if (advancedController.application == null) {
                advancedController.init();
                // init advancedController
                advancedController.isBuildingApplication = true;
                advancedController.dwellingToAssignId = dwellingUnit.Id;
                advancedController.dwellingUnit = dwellingUnit;
                advancedController.assignDwellingUnit();
                advancedController.savePreApplication();
                applicationId = advancedController.application.Id;
            } else {
                advancedController.dwellingToAssignId = dwellingUnit.Id;
                advancedController.dwellingUnit = dwellingUnit;
                advancedController.assignDwellingUnit();
                advancedController.savePreApplication();
            }
            ApexPages.Message message = new ApexPages.message(ApexPages.Severity.CONFIRM,
                    BIGPortalAdvanceHUApplicationUtils.PRE_SAVE_MESSAGE);
            ApexPages.addMessage(message);
        } catch (Exception e) {
            ApexPages.Message message = new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(message);
        }
        return null;
    }
    
}