public with sharing class HPXML{
    //set by parser
    public Boolean isPostApplication                    {get; set; }

    //private constants
    private static final String SOUTHERN_CA_GAS = 'Southern California Gas Company';
    private static final String ELECTRIC = 'Electric';
    private static final String ELECTRIC_RESISTANCE = 'ElectricResistance';
    private static final String GAS = 'Gas';
    private static final String GAS_FIRED = 'Gas Fired';
    private static final String GASFIRED = 'GasFired';
    private static final String HEAT_PUMP = 'Heat Pump';
    private static final String HEATPUMP = 'HeatPump';
    private static final String MIXED = 'Mixed';
    private static final String NONE = 'None';
    private static final String TEST_IN_HOME = 'Test-In Home';
    private static final String UNKNOWN = 'Unknown';
    private static final Decimal KWH_TO_BTU = 3412.14163;
    private static final Decimal THERMS_TO_BTU = 99976.129;
    //private static final Decimal HPHI_BONUS = 1200;

    //inner wrapper classes
    public Software software                                { get; set; }
    public Project project                                  { get; set; }
    public Building building                                { get; set; }
    public BusinessContact businesscontact                  { get; set; }
    public Customer customer                                { get; set; }
    public AirInfiltrationMeasurement aim                   { get; set; }
    public Attic attic                                      { get; set; }
    public AtticFloorInsulation afi                         { get; set; }
    public AtticRoofInsulation ari                          { get; set; }
    public Foundation foundation                            { get; set; }
    public Measure measure                                  { get; set; }
    public ModeledUsage modeledusage                        { get; set; }
    public HeatingSystem heatingsystem                      { get; set; }
    public CoolingSystem coolingsystem                      { get; set; }
    public WaterHeating waterheating                        { get; set; }
    public HVACControl hvaccontrol                          { get; set; }
    public LightingGroup lightinggroup                      { get; set; }
    public WallInsulation wallinsulation                    { get; set; }
    public FrameFloorInsulation framefloorinsulation        { get; set; }
    public XMLTransactionHeaderInfo xmltransactionheaderinfo { get; set; }
    public FuelSavings fuelsaving                           { get; set; }
    public HeatPump hp                                      { get; set; }
    public Window window                                    { get; set; }
    public Duct duct                                        { get; set; }
    public Roof roof                                        { get; set; }
    public DuctLeakageMeasurement ductleakagemeasurement    { get; set; }
    public Pool pool                                        { get; set; }
    public PoolPump poolpump                                { get; set; }
    public Refrigerator refrigerator                        { get; set; }
    public VentilationFan ventilationfan                    { get; set; }
    public HVACDistribution hvacdistribution                { get; set; }
    public LightingControl lightingcontrol                  { get; set; }
    public EnergySavingsInfo energySavingsInfo              { get; set; }

    public List<Building> buildings                         { get; set; }
    public List<Project> projects                           { get; set; }
    public List<HeatingSystem> heatingsystems               { get; set; }
    public List<CoolingSystem> coolingsystems               { get; set; }
    public List<AirInfiltrationMeasurement> aims            { get; set; }
    public List<Attic> attics                               { get; set; }
    public List<Foundation> foundations                     { get; set; }
    public List<Measure> measures                           { get; set; }
    public List<ModeledUsage> modeledusages                 { get; set; }
    public List<WaterHeating> waterheatings                 { get; set; }
    public List<HVACControl> hvaccontrols                   { get; set; }
    public List<LightingGroup> lightinggroups               { get; set; }
    public List<WallInsulation> wallinsulations             { get; set; }
    public List<FuelSavings> fuelsavings                    { get; set; }
    public List<HeatPump> heatpumps                         { get; set; }
    public List<Window> windows                             { get; set; }
    public List<HVACDistribution> hvacdistributions         { get; set; }
    public List<Duct> ducts                                 { get; set; }
    public List<DuctLeakageMeasurement> ductleakagemeasurements { get; set; }
    public List<Pool> pools                                 { get; set; }
    public List<PoolPump> poolpumps                         { get; set; }
    public List<Refrigerator> refrigerators                 { get; set; }
    public List<VentilationFan> ventilationfans             { get; set; }

    public List<Result> results                             { get; set; }
    private Summary summary;
    private SubAppBuilding subappbuilding;

    //maps storing individual end use values by type
    private Map<String, Decimal[]> endUsePreValues;
    private Map<String, Decimal[]> endUsePostValues;

    //database records
    public Application__c application {get; set; }
    public Sub_Application__c subApplication {get; set; }
    private List<XML_Result__c> xmlResults;
    private List<XML_End_Use__c> xmlEndUses;

    //-- Constructor
    public HPXML(Application__c app, Sub_Application__c subApp, Boolean isPostApp) {

        application = app;
        subApplication = subApp;
        isPostApplication = isPostApp;

        //update the Sub-Application RecordType
        Id preAppRTId = BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID;
        Id postAppRTId = BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID;
        if (preAppRTId != null && postAppRTId != null) {
            subApplication.RecordTypeId = isPostApplication ? postAppRTId : preAppRTId;
        }

        try {
            //upsert to insert records/modifications FROM portal
            upsert application;
            upsert subApplication;
        }
        catch (DMLException e) {
            System.debug('### DMLException when trying to update Application and Sub-Application: ' + e.getMessage());
        }
        catch (Exception e) {
            System.debug('### Exception when trying to update Application and Sub-Application: ' + e.getMessage());
        }

        //initialize inner wrapper classes for aggregating and analyzing data
        ducts = new List<Duct>();
        buildings = new List<Building>();
        projects = new List<Project>();
        aims = new List<AirInfiltrationMeasurement>();
        heatingsystems = new List<HeatingSystem>();
        coolingsystems = new List<CoolingSystem>();
        hvacdistributions = new List<HVACDistribution>();
        ductleakagemeasurements = new List<DuctLeakageMeasurement>();
        foundations = new List<Foundation>();
        attics = new List<Attic>();
        wallinsulations = new List<WallInsulation>();
        windows = new List<Window>();
        modeledusages = new List<ModeledUsage>();
        waterheatings = new List<WaterHeating>();
        hvaccontrols = new List<HVACControl>();
        lightinggroups = new List<LightingGroup>();
        wallinsulations = new List<WallInsulation>();
        fuelsavings = new List<FuelSavings>();
        heatpumps = new List<HeatPump>();
        windows = new List<Window>();
        ducts = new List<Duct>();
        ductleakagemeasurements = new List<DuctLeakageMeasurement>();
        pools = new List<Pool>();
        poolpumps = new List<PoolPump>();
        refrigerators = new List<Refrigerator>();
        ventilationfans = new List<VentilationFan>();
        measures = new List<Measure>();

        //initialize inner wrapper classes for aggregating and analyzing data
        //appliances = new List<Appliance>();
        //plants = new List<Plant>();
        //results = new List<Result>();
        //improvements = new List<Improvements>();

        //initialize maps for end uses
        endUsePreValues = new Map<String, Decimal[]>();
        endUsePostValues = new Map<String, Decimal[]>();
    }
    public class MyException extends Exception {}

    //-- Constructor without trying upsert
    public HPXML(Application__c app, Sub_Application__c subApp, Boolean isPostApp, Boolean tryUpsert) {

        application = app;
        subApplication = subApp;
        isPostApplication = isPostApp;

        //update the Sub-Application RecordType
        Id preAppRTId = BIGPortalAdvanceHUApplicationUtils.SUBAPP_PRE_RECORD_TYPE_ID;
        Id postAppRTId = BIGPortalAdvanceHUApplicationUtils.SUBAPP_POST_RECORD_TYPE_ID;
        if (preAppRTId != null && postAppRTId != null) {
            subApplication.RecordTypeId = isPostApplication ? postAppRTId : preAppRTId;
        }

        if(tryUpsert){
        try {
            //upsert to insert records/modifications FROM portal
            upsert application;
            upsert subApplication;
        }
        catch (DMLException e) {
            System.debug('### DMLException when trying to update Application and Sub-Application: ' + e.getMessage());
        }
        catch (Exception e) {
            System.debug('### Exception when trying to update Application and Sub-Application: ' + e.getMessage());
        }
        }

        //initialize inner wrapper classes for aggregating and analyzing data
        ducts = new List<Duct>();
        buildings = new List<Building>();
        projects = new List<Project>();
        aims = new List<AirInfiltrationMeasurement>();
        heatingsystems = new List<HeatingSystem>();
        coolingsystems = new List<CoolingSystem>();
        hvacdistributions = new List<HVACDistribution>();
        ductleakagemeasurements = new List<DuctLeakageMeasurement>();
        foundations = new List<Foundation>();
        attics = new List<Attic>();
        wallinsulations = new List<WallInsulation>();
        windows = new List<Window>();
        modeledusages = new List<ModeledUsage>();
        waterheatings = new List<WaterHeating>();
        hvaccontrols = new List<HVACControl>();
        lightinggroups = new List<LightingGroup>();
        wallinsulations = new List<WallInsulation>();
        fuelsavings = new List<FuelSavings>();
        heatpumps = new List<HeatPump>();
        windows = new List<Window>();
        ducts = new List<Duct>();
        ductleakagemeasurements = new List<DuctLeakageMeasurement>();
        pools = new List<Pool>();
        poolpumps = new List<PoolPump>();
        refrigerators = new List<Refrigerator>();
        ventilationfans = new List<VentilationFan>();
        measures = new List<Measure>();

        //initialize inner wrapper classes for aggregating and analyzing data
        //appliances = new List<Appliance>();
        //plants = new List<Plant>();
        //results = new List<Result>();
        //improvements = new List<Improvements>();

        //initialize maps for end uses
        endUsePreValues = new Map<String, Decimal[]>();
        endUsePostValues = new Map<String, Decimal[]>();
    }

        //inner classes to store data models
    public class Software {
        public String SoftwareProgramUsed;
        public String SoftwareProgramVersion;
        public String XMLGeneratedBy;
    }

    public class Project {
        public String Title;
        public String SystemIdentifier;
        public String ProjectStatusEventType;
        public String ProjectStatus;
        public String BuildingId;
    }

    public class Building {
        //parent is Address
        public String Address1;
        public String CityMunicipality;
        public String StateCode;
        public String ZipCode;

        //parent is BuildingOccupancy
        public Decimal NumberofResidents;

        //parent is BuildingConstruction
        public Integer YearBuilt;
        public String ResidentialFacilityType;
        public Integer NumberOfBedrooms;
        public Decimal ConditionedFloorArea;
        public Decimal NumberofStoriesAboveGrade;
        public Decimal AverageCeilingHeight;

        //lookup
        public String PrimaryCoolingSystem;
        public String PrimaryHeatingSystem;

        public String SystemIdentifier;
        public String ProjectStatusEventType;
        public String ProjectStatus;

        //[REFERENCE] CombustionVentilationSystem is referenced by the heating system's Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem/
        public String CombustionVentilationSystem;

        public String FoundationType;
        public String SameAs;
        public Integer hasCooling;
    }

    //this is not directly mapped to the custom object
    public class BusinessContact {
        public String FirstName;
        public String LastName;
        public String Email;
    }

    //this is not directly mapped to the custom object
    public class Customer {
        public String FirstName;
        public String LastName;
    }

    public class AirInfiltrationMeasurement {
        //parent node is AirInfiltrationMeasurement
        //can be multiple per file
        public Decimal HousePressure;
        public String TypeOfInfiltrationMeasurement;
        public String UnitofMeasure;
        public Decimal AirLeakage;
        public String SystemIdentifier; //get attribute ID value
        public String BuildingId;
        public String SameAs;
        //lookup - HP building
    }

    public class AirSealing {
        //parent node is AirSealing
        //can be multiple per file
        public String Attic;
        public String BasementCrawlspace;
        public Decimal Hours;
        public String LivingSpace;
        public String SystemIdentifier; //get attribute ID value
        //lookup - HP building
    }

    public class Attic {
        //parent node is Attic
        //can be multiple per file
        public Decimal Area;
        public String SystemIdentifier;
        public Decimal afiAssemblyEffectiveRValue;
        public Decimal afiNominalRValue;
        public String afiSystemIdentifier; //get attribute ID
        public Decimal ariAssemblyEffectiveRValue;
        public Decimal ariNominalRValue;
        public String ariSystemIdentifier; //get attribute ID
        public String BuildingId;
        public String SameAs;
    }

    public class AtticFloorInsulation {
        //can be multiple per file
        public Decimal AssemblyEffectiveRValue;
        public Decimal NominalRValue;
        public String SystemIdentifier; //get attribute ID
        public String SameAs;
    }

    public class AtticRoofInsulation {
        //can be multiple per file
        public Decimal AssemblyEffectiveRValue;
        public String SystemIdentifier; //get attribute ID
        public String SameAs;
    }

    public class BusinessInfo {
        //parent node is BusinessInfo
        //can be multiple per file
        public String[] Certifications;
        public String BusinessSpecialization;
        public String BusinessInfo;
        public String DayTelephone; //under Telephone, sibling of TelephoneType with value "day"
        public String EveningTelephone; //under Telephone, sibling of TelephoneType with value "evening"
        public String MobileTelephone; //under Telephone, sibling of TelephoneType with value "mobile"
        public String OtherEmail; //under Email, sibling of EmailType with value "other"
        public String PersonalEmail; //under Email, sibling of EmailType with value "personal"
        public String WorkEmail; //under Email, sibling of EmailType with value "work"
        public String SystemIdentifier; //get attribute ID value
    }

    public class ConsumptionDetail {
        //parent node is ConsumptionDetail
        //can be multiple per file
        public Decimal Consumption;
        public Decimal ConsumptionCost;
        public Date StartDateTime;
        public Date EndDateTime;
        public String ReadingType;

        //master-detail - HP Consumption Info
    }

    public class ConsumptionInfo {
        //can be multiple per file

        //parent node is ConsumptionInfo
        public Decimal BaseLoad;
        public Decimal MarginalRate;
        public String SystemIdentifier; //get attribute ID of Element UtilityID

        //parent node is BPI2400Inputs
        public Decimal CalibrationBaseloadWeatherRegressionCVRMSE;
        public Decimal DetailedModelCalibrationBaseloadAbsoluteError;
        public Decimal DetailedModelCalibrationBaseloadBiasError;
        public Decimal DetailedModelCalibrationCoolingAbsoluteError;
        public Decimal DetailedModelCalibrationCoolingBiasError;
        public Decimal DetailedModelCalibrationHeatingAbsoluteError;
        public Decimal DetailedModelCalibrationHeatingBiasError;
        public Decimal BaseloadWeatherNormalizedBaseloadUsage;
        public Decimal BaseloadWeatherNormalizedCoolingUsage;
        public Decimal BaseloadWeatherNormalizedHeatingUsage;
        public Date BaseloadBillingPeriodStartDate;
        public Date BaseloadBillingPeriodEndDate;

        //parent node is Energy
        public Decimal MarginalEnergyCostRate;
        public String FuelInterruptibility;
        public String FuelType;
        public String IntervalType;
        public String MeteringConfiguration;
        public String PeakSeason;
        public String ReadingTimeZone;
        public String SharedEnergySystem;
        public String UnitofMeasure;
        public Decimal EnergyUseIntensity;

        //parent node is Water
        public Decimal MarginalWaterCostRate;
        public String WaterType;

        //lookup
        //HP Building, HP Consumption, HP Cooling System, HP Door, HP Foundation, HP Heating System,
        //HP Heat Pump, HP RimJoist, HP Skylight, HP Wall, HP Window
        //master-detail - HP Utility
    }

    public class Contractor {
        //parent node is ContractorDetails
        public String SystemIdentifier; //get attribute ID

        //lookup - HP Business Info, HP Contractor, Sub Application
    }

    public class CoolingSystem {
        //can be multiple per file
        //parent node is CoolingSystem
        public Decimal FractionCoolLoadServed;
        public String SystemIdentifier; //get attribute ID

        public Decimal CoolingCapacity;
        public String CoolingSystemType;
        public String CoolingSystemFuel;
        public String Manufacturer;
        public String ModelNumber;
        public Integer ModelYear;

        public Decimal AFUE; //parent node is AnnualCoolingEfficiency, get value of 'Value' if Units is 'AFUE' -- not a field in the object
        public Decimal EER; //parent node is AnnualCoolingEfficiency, get value of 'Value' if Units is 'EER'
        public Decimal HSPF; //parent node is AnnualCoolingEfficiency, get value of 'Value' if Units is 'HSPF'
        public Decimal kWton; //parent node is AnnualCoolingEfficiency, get value of 'Value' if Units is 'kW/ton'
        public Decimal SEER; //parent node is AnnualCoolingEfficiency, get value of 'Value' if Units is 'SEER'
        public Decimal COP; //parent node is AnnualCoolingEfficiency, get value of 'Value' if Units is 'COP' -- not a field in the object

        public Integer isPrimary;
        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Zone
    }

    public class Door {
        //parent node is Door
        //can be multiple per file
        public Decimal Area;
        public Decimal Azimuth;
        public String DoorMaterial;
        public String DoorType;
        public String Orientation;
        public Integer Quantity;
        public Decimal RValue;
        public Boolean StormDoor;
        public String[] ThirdPartyCertification;
        public Boolean WeatherStripping;
        public String SystemIdentifier; //get attribute ID

        //master-detail - HP Building
        //lookup - HP Wall
    }

    public class Duct {
        //parent node is Ducts
        //can be multiple per file
        public Decimal ConditionedFloorAreaServed;
        public Decimal DuctInsulationRValue;
        public String DuctLocation;
        public Decimal FractionDuctArea;
        public String SystemIdentifier; //get attribute ID - hvac distribution
        //master-detail - HP HVAC Distribution
    }

    public class DuctLeakageMeasurement {
        //parent node is DuctLeakageMeasurement
        //can be multiple per file
        public String SystemIdentifier; //HVAC Distribution
        public String DuctLeakageUnits;
        public Decimal DuctLeakageValue=0;
        //master-detail - HP HVAC Distribution
    }

    public class EnergySavingsInfo {
        //parent node is EnergySavingsInfo
        //can be multiple per file
        public Decimal AnnualPercentReduction;
        public String DemandSavings;
        public String EnergySavingsReported;
        public String EnergySavingsType;

        //lookup - HP Measure, HP Project
    }

    public class Foundation {
        //can be multiple per file
        //parent node is Foundation
        public String SystemIdentifier; //get attribute ID
        public String Type; //get child of FoundationType

        //frame floor
        public Decimal Area;
        public Decimal NominalRValue;
        public String FrameFloorSystemIdentifier;

        // foundation wall system
        public String foundationWallSystemIdentifier;

        //frame floor insulation
        public Decimal AssemblyEffectiveRValue; //lookup to HP Insulation Info
        public String FrameFloorInsulationSystemIdentifier; //get attribute ID

        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Space
    }

    public class FoundationWall {
        //can be multiple per file
        //parent node is FoundationWall
        public String AdjacentTo;
        public Decimal Area;
        public Decimal BelowGradeDepth;
        public Decimal FramingFactor;
        public Decimal Height;
        public Decimal Length;
        public String Material;
        public Decimal Size;
        public Decimal Spacing;
        public Decimal Thickness;
        public String Type;
        public String SystemIdentifier; //get attribute ID
        //master-detail - HP Foundation
        //lookup - HP Foundation (AdjacentToFoundation), HP Insulation Info,
    }

    public class FrameFloor {
        //parent node is FrameFloor
        //can be multiple per file
        public Decimal Area;
        public String SystemIdentifier; //get attribute ID
        //master-detail - HP Foundation
        //lookup - HP Insulation Info
    }

    //this is not directly mapped to the custom object
    public class FrameFloorInsulation {
        public Decimal AssemblyEffectiveRValue; //lookup to HP Insulation Info
        public String SystemIdentifier; //get attribute ID
        public String FrameFloorSystemIdentifier;
        public String SameAs;
    }

    public class FuelLeak {
        //parent node is CombustionApplianceTest
        //can be multiple per file

        //parent node is FuelLeaks
        public String FuelType;
        public Boolean LeaksAddressed;
        public Boolean LeaksIdentified;
        public String Notes;

        //master-detail - HP Combustion Appliance Test
    }

    public class FuelSavings {
        //can be multiple per file
        //parent node is FuelSavings
        //public String Units;
        public String EndUse;
        public Decimal EndUseValue;
        public String EndUseFuel;
        public String EndUseUnits;
        public String ProjectId;
        //master-detail - HP Energy Savings Info
    }

    public class HVACControl {
        //parent node is HVACControl
        //can be multiple per file
        public String SystemIdentifier; //get attribute ID
        public Decimal SetpointTempHeatingSeason;
        public Decimal SetpointTempCoolingSeason;
        public String ControlType;
        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Zone
    }

    public class HVACDistribution {
        //parent node is HVACDistribution
        //can be multiple per file
        public String SystemIdentifier; //get attribute ID
        public Decimal ConditionedFloorAreaServed;
        public Decimal AnnualHeatingDistributionSystemEfficiency;
        public Decimal AnnualCoolingDistributionSystemEfficiency;
        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Zone
    }

    public class HeatPump {
        //parent node is HeatPump
        //can be multiple per file
        public Decimal AFUEcool;
        public Decimal EERcool;
        public Decimal HSPFcool;
        public Decimal kWtoncool;
        public Decimal SEERcool;
        public Decimal COPcool;
        public Decimal AFUEheat;
        public Decimal EERheat;
        public Decimal HSPFheat;
        public Decimal kWtonheat;
        public Decimal SEERheat;
        public Decimal COPheat;

        //not a field in the object
        //public String AnnualCoolEfficiencyUnit;
        //public String AnnualHeatEfficiencyUnit;

        public String SystemIdentifier; //get attribute ID
        public Decimal FractionHeatLoadServed;
        public Decimal FractionCoolLoadServed;
        public String HeatPumpType;
        public String Manufacturer;
        public String ModelNumber;
        public Integer ModelYear;
        public String AnnualEfficiencyType; //not a field in the object -- need to determine if annual efficiency is cool or heat
        public String BuildingId;
        public String SameAs;

        //master-detail - HP Building
        //lookup - HP Zone
    }

    public class HeatingSystem {
        //parent node is HeatingSystem
        //can be multiple per file
        public Decimal HeatingCapacity;
        public Decimal FractionHeatLoadServed;
        public String SystemIdentifier; //get attribute ID
        public Decimal AFUE; //parent node is AnnualHeatingEfficiency, get value of 'Value' if Units is 'AFUE'
        public Decimal COP; //parent node is AnnualHeatingEfficiency, get value of 'Value' if Units is 'COP'
        public Decimal HSPF; //parent node is AnnualHeatingEfficiency, get value of 'Value' if Units is 'HSPF'
        public Decimal Percent; //parent node is AnnualHeatingEfficiency, get value of 'Value' if Units is 'Percent'
        public String HeatingSystemFuel;
        public String Type; //get value of element after the node HeatingSystemType
        public String Units;
        public String Manufacturer;
        public String ModelNumber;
        public Integer ModelYear;
        public Integer isPrimary;
        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Zone
    }

    public class Incentive {
        //parent node is Incentive
        //can be multiple per file
        public String FundingSourceCode;
        public String FundingSourceName;
        public Decimal IncentiveAmount;
        public String SystemIdentifier; //get attribute ID of IncentiveType
        //lookup - HP Measure, HP Project
    }

    public class InsulationInfo {
        //can be multiple per file
        //parent node can be AtticFloorInsulation, AtticRoofInsulation, Insulation, PerimeterInsulation, UnderSlabInsulation
        public Decimal AssemblyEffectiveRValue;
        public String SystemIdentifier; //get attribute ID
        //can have multiple layers -- see below
    }

    public class Layer {
        //can be multiple per file
        //parent node can be Layer
        public String InstallationType;
        public Decimal NominalRValue;
        public Decimal Thickness;

        //lookup - HP Insulation Info -- see above

        //parent node is InsulationMaterial -- get the element name and
        public String Batt; //parent node is InsulationMaterial, get value of element 'Batt'
        public String LooseFill; //parent node is InsulationMaterial, get value of element 'LooseFill'
        public String Other; //parent node is InsulationMaterial, get value of element 'Other'
        public String Rigid; //parent node is InsulationMaterial, get value of element 'Rigid'
        public String SprayFoam; //parent node is InsulationMaterial, get value of element 'SprayFoam'
    }

    public class LightingControl {
        //parent node is LightingControl
        //can be multiple per file
        //public String LightingControlType;
        public String Location;
        //public Integer NumberofLightingControls;
        public String SystemIdentifier; //get attribute ID

        public String LightingGroup;

        //master-detail - HP Building
        //lookup - HP Lighting Control Group
    }

    public class LightingGroup {
        //parent node is LightingControl
        //can be multiple per file
        public Decimal AverageHoursPerDay;
        public String SystemIdentifier; //get attribute ID
        public String Location;
        public Integer NumberofUnits;
        public String LightingType; //get the element after LightingType
        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Space
    }

    public class Measure {
        //parent node is Measure
        //can be multiple per file
        public String MeasureDescription;
        public String SystemIdentifier; //get attribute ID of SystemIdentifiersInfo

        public String ProjectId;
        //lookup - HP Project, HP Contractor
    }

    public class ModeledUsage {
        //parent node is ModeledUsage
        //can be multiple per file
        public Decimal AnnualConsumption;
        public Decimal BaseLoad;
        public Decimal Cooling; //parent is ConsumptionByEndUse, if value of EndUse is 'Cooling', get the value of 'EndUseValue'
        public Decimal Heating; //parent is ConsumptionByEndUse, if value of EndUse is 'Heating', get the value of 'EndUseValue'

        public Decimal HotWater;
        public Decimal Appliance;
        public Decimal Lighting;
        public Decimal Other;
        public Decimal PV;
        public Decimal SolarThermal;

        public String EnergyType;

        public String BuildingId;
        //master-detail - HP Building
        //lookup - HP Weather Station
    }

    public class Person {
        //can be multiple per file

        //parent node is Person
        public Decimal DayTelephone; //parent is Telephone, if value of TelephoneType is 'day', get the value of 'TelephoneNumber'
        public Decimal EveningTelephone; //parent is Telephone, if value of TelephoneType is 'evening', get the value of 'TelephoneNumber'
        public Decimal MobileTelephone; //parent is Telephone, if value of TelephoneType is 'mobile', get the value of 'TelephoneNumber'
        public String IndividualType;
        public String LastName;
        public String MiddleName;
        public String OtherEmail; //parent is Email, if value of EmailType is 'other', get the value of 'EmailAddress'
        public String PersonalEmail; //parent is Email, if value of EmailType is 'personal', get the value of 'EmailAddress'
        public String WorkEmail; //parent is Email, if value of EmailType is 'work', get the value of 'EmailAddress'
        public String PrefixName;
        public String SuffixName;

        //parent node is MailingAddress
        public String Address1;
        public String Address2;
        public String AddressType;
        public String CityMunicipality;
        public String StateCode;
        public String USPSBarCode;
        public String ZipCode;

        //parent is ContactType, get the value of 'Description' under 'Other'
        public String OtherDescription;

        //parent node is Auditor
        public String[] AuditorQualification;
        public String AuditorStateWhereQualificationHeld;
        public Integer YearsExperience;

        //parent node is Implementer
        public String[] ImplementerQualification;
        public String ImplementerStateWhereQualificationHeld;

        public String SystemIdentifier; //get attribute ID
        //lookup - HP Business Info, HP Contractor, HP Person, HP Utility Fuel Provider, Sub Application,
    }

    public class PoolPump {
        //can be multiple per file
        //parent node is Pool
        public String PoolSystemIdentifier; //get attribute ID
        public String SystemIdentifier; //get attribute ID

        public Decimal HoursPerDay;
        public String Type; //not in object
        public Decimal RatedHorsepower;
        public String SpeedSetting;
        public Decimal PumpSpeedPower; // multiple!, not in object
        public String SameAs;
        //master-detail - HP Pool
    }

    public class Pool {
        public String SystemIdentifier; //get attribute ID
        public String BuildingId;
        public String SameAs;
    }

    public class Refrigerator {
        //can be multiple per file
        //parent node is Refrigerator
        public Boolean PrimaryIndicator;
        public Integer ModelYear;
        public String SystemIdentifier; //get attribute ID
        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Appliances Type Summary Info
    }

    public class Roof {
        //can be multiple per file
        //parent node is Roof
        public Boolean RadiantBarrier;
        public String RoofType;
        public String SystemIdentifier; //get attribute ID
        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Space
    }

    public class VentilationFan {
        //can be multiple per file
        //parent node is VentilationFan
        public boolean UsedForWholeBuildingVentilation;
        public boolean UsedForSeasonalCoolingLoadReduction;
        public String SystemIdentifier; //get attribute ID
        public String BuildingId;
        public String SameAs;
        //master-detail - HP Building
    }

    public class WaterHeating {
        //can be multiple per file
        //parent node is WaterHeatingSystem
        public String FuelType;
        public Decimal EnergyFactor;
        public Decimal HotWaterTemperature;
        public String SystemIdentifier; //get attribute ID

        public String Manufacturer;
        public String ModelNumber;
        public Integer ModelYear;
        public String Location;
        public Decimal TankVolume;
        public String WaterHeaterType;
        public Decimal LengthofPipeInsulated;
        public String BuildingId;
        public Decimal HeatingCapacity;

        public Integer WaterHeaterInsulation;
        public String SameAs;
        //master-detail - HP Building
        //lookup - HP Zone
    }

    //this is not directly mapped to the custom object
    public class WallInsulation {
        public Decimal NominalRValue; //lookup to HP Layer
        public Decimal AssemblyEffectiveRValue; //lookup to HP Insulation Info
        public Decimal Area; //mapped to HP Wall
        public String Type; //mapeed to HP Wall
        public String SystemIdentifier; //get attribute ID
        public String WallSystemIdentifier;
        public String BuildingId;
        public String SameAs;
    }

    public class Window {
        //can be multiple per file
        //parent node is Window
        public Decimal Area;
        public String FrameType;
        public Decimal SHGC;
        public Decimal UFactor;
        public String GlassLayers;
        public String SystemIdentifier; //get attribute ID
        public String BuildingId;
        public String SameAs;
    }

    public class XMLTransactionHeaderInfo {
        public String XMLGeneratedBy;
    }

    public class SubAppBuilding {
        public String Address1;
        public String CityMunicipality;
        public String StateCode;
        public String ZipCode;
        public Decimal ConditionedFloorArea;
        public Decimal NumberofDwellingUnits;
        public Decimal NumberofStoriesAboveGrade;
        public Decimal NumberofOccupants;
        public String FoundationType;
    }

    //////////////////////////////////////////

    public class Appliance {
        public String PoolType;
        public String SpaType;
    }
    //public class Plant {
        //Water Heating
      //  public String Name;
        //public String DHWType;

        //public List<HVAC> HVACs = new List<HVAC>();
    //}
    //public class HVAC {
      //  public String HVACSystemType;
        //public String HeatingHVACType;
        //public String CoolingHVACType;
        //public String ExistCFM50;
        //public String ExistSLA;
        //public String Thermostat;
        //public String DuctRValue;
        //public String DuctLocation;
        //public String DuctStatus;
        //public String Flow;
        //public String EER;

        //Existing Distribution
        //public String DuctLeakageCFM25;
        //public String AtticInsulR;

        //public List<Zone> zones = new List<Zone>();
    //}
    //

    //public class Zone {
      //  public String ZoneType;
        //public String FloorNo;

        //public List<Room> rooms = new List<Room>();
    //}

    /*
    public class Room {
        public String NBedrooms;
        public String FloorArea;
        public String CeilingHeight;
        public String YearBuilt;

        public List<Insulation> insulations = new List<Insulation>();
    }

    public class Insulation {
        public String SurfaceType;
        public String UFactor;
        public String Area;

        public List<Fenestration> fenestrations = new List<Fenestration>();
    }

    public class Fenestration {
        public String UFactor;
        public String Area;
    }
    */

    public class Result {
        public String ResultType;
        public String GasUseTherms;
        public String Heating;
        public String Cooling;
        public String WaterHeating;
        public String Appliances;
        public String Ancillary;
        public String IndoorLighting;
        public String Pumps;
        public String Fans;
        public String OutdoorLighting;
        public String Renewables;
        public String GasHeating;
        public String GasCooling;
        public String GasWaterHeating;
        public String GasAppliances;
        public String GasAncillary;
        public String GasIndoorLighting;
        public String GasPumps;
        public String GasFans;
        public String GasOutdoorLighting;
        public String GasRenewables;

        //public List<AlternativeDescription> alternativeDescriptions = new List<AlternativeDescription>();
    }

    public class Summary {
        public String ThermostatType;
        public Integer YearBuilt = 0;
        public String PoolType;
        public String SpaType;
        public Integer TotalBedrooms = 0;

        //calculate duct r value weighted
        public Decimal TotalDuctRValue = 0;
        public Decimal TotalDuctRValueByVolume = 0;
        public Decimal AvgDuctRValue = 0;

        //calculate ceiling height weighted by area
        public Decimal TotalCeilingHeight = 0;
        public Decimal TotalRoomArea = 0;
        public Decimal TotalVolume = 0;
        public Decimal AvgCeilingHeight = 0;
        //calculate floor ufactor weighted by area
        public Decimal TotalFloorUFactor = 0;
        public Decimal TotalFloorArea = 0;
        public Decimal TotalFloorUFactorByArea = 0;
        public Decimal AvgFloorUFactor = 0;
        //calculate roof ufactor weighted by area
        public Decimal TotalRoofUFactor = 0;
        public Decimal TotalRoofArea = 0;
        public Decimal TotalRoofUFactorByArea = 0;
        public Decimal AvgCeilingUFactor = 0;
        //calculate wall ufactor weighted by area
        public Decimal TotalWallUFactor = 0;
        public Decimal TotalWallArea = 0;
        public Decimal TotalWallUFactorByArea = 0;
        public Decimal AvgWallUFactor = 0;
        //calculate window ufactor weighted by area
        public Decimal TotalWindowUFactor = 0;
        public Decimal TotalWindowArea = 0;
        public Decimal TotalWindowUFactorByArea = 0;
        public Decimal AvgWindowUFactor = 0;

        public String InitialHeatingFuel;
        public String PostUpgradeHeatingFuel;
        public String InitialHotWaterFuel;
        public String PostUpgradeHotWaterFuel;
        public Decimal InitialBlowerDoorResults = 0;
        public Decimal PostUpgradeBlowerDoorResults = 0;
        public Decimal InitialDuctTestResults = 0;
        public Decimal PostUpgradeDuctTestResults = 0;
        public Boolean PostUpgradeCoolingPresent;

        public InitialElectricUse initialElectric = new InitialElectricUse();
        public InitialGasUse initialGas = new InitialGasUse();
        public ImprovedElectricUse improvedElectric = new ImprovedElectricUse();
        public ImprovedGasUse improvedGas = new ImprovedGasUse();
        public ElectricSavings electricSavings = new ElectricSavings();
        public GasSavings gasSavings = new GasSavings();
    }

    public class InitialElectricUse {
        public Decimal Heating = 0;
        public Decimal Cooling = 0;
        public Decimal WaterHeating = 0;
        public Decimal Appliances = 0;
        public Decimal Ancillary = 0;
        public Decimal IndoorLighting = 0;
        public Decimal Pumps = 0;
        public Decimal Fans = 0;
        public Decimal OutdoorLighting = 0;
        public Decimal Renewables = 0;
        public Decimal Total = 0;
    }

    public class InitialGasUse {
        public Decimal GasHeating = 0;
        public Decimal GasCooling = 0;
        public Decimal GasWaterHeating = 0;
        public Decimal GasAppliances = 0;
        public Decimal GasAncillary = 0;
        public Decimal GasIndoorLighting = 0;
        public Decimal GasPumps = 0;
        public Decimal GasFans = 0;
        public Decimal GasOutdoorLighting = 0;
        public Decimal GasRenewables = 0;
        public Decimal Total = 0;
    }

    public class ImprovedElectricUse {
        public Decimal Heating = 0;
        public Decimal Cooling = 0;
        public Decimal WaterHeating = 0;
        public Decimal Appliances = 0;
        public Decimal Ancillary = 0;
        public Decimal IndoorLighting = 0;
        public Decimal Pumps = 0;
        public Decimal Fans = 0;
        public Decimal OutdoorLighting = 0;
        public Decimal Renewables = 0;
        public Decimal Total = 0;
    }

    public class ImprovedGasUse {
        public Decimal GasHeating = 0;
        public Decimal GasCooling = 0;
        public Decimal GasWaterHeating = 0;
        public Decimal GasAppliances = 0;
        public Decimal GasAncillary = 0;
        public Decimal GasIndoorLighting = 0;
        public Decimal GasPumps = 0;
        public Decimal GasFans = 0;
        public Decimal GasOutdoorLighting = 0;
        public Decimal GasRenewables = 0;
        public Decimal Total = 0;
    }

    public class ElectricSavings {
        public Decimal Heating = 0;
        public Decimal Cooling = 0;
        public Decimal WaterHeating = 0;
        public Decimal Appliances = 0;
        public Decimal Ancillary = 0;
        public Decimal IndoorLighting = 0;
        public Decimal Pumps = 0;
        public Decimal Fans = 0;
        public Decimal OutdoorLighting = 0;
        public Decimal Renewables = 0;
        public Decimal Total = 0;
    }

    public class GasSavings {
        public Decimal GasHeating = 0;
        public Decimal GasCooling = 0;
        public Decimal GasWaterHeating = 0;
        public Decimal GasAppliances = 0;
        public Decimal GasAncillary = 0;
        public Decimal GasIndoorLighting = 0;
        public Decimal GasPumps = 0;
        public Decimal GasFans = 0;
        public Decimal GasOutdoorLighting = 0;
        public Decimal GasRenewables = 0;
        public Decimal Total = 0;
    }

    //-- Performs the logic which aggregates the data for the summary
    public void analyzeData() {
    //public Summary analyzeData() {

        summary = new Summary();
        subappbuilding = new SubAppBuilding();

        //for tracking thermostat type
        Integer setback = 0;
        Integer noSetback = 0;
        //for tracking total HVACs
        Integer totalHVACs = 0;
        //for tracking wall insulation UFactor
        Decimal totalUFactorbyArea = 0;
        //for tracking HVAC heating types
        Integer gasHeat = 0, electricHeat = 0, noHeat = 0;
        //for tracking pre-existing hot water fuel types
        Integer gasWater = 0, electricWater = 0;
        //for determining PostUpgradeHotWaterFuel
        Boolean waterResults = false, waterImprovements = false;
        Integer gasWaterAlts = 0, gasWaterImprov = 0, electricWaterAlts = 0, electricWaterImprov = 0, heatingAlts = 0;
        //for determining PostUpgradeHeatingFuel
        Boolean heatingResults = false, heatingImprovements = false, heatingFuelImprovements = false;
        Integer gasHeatingAlts = 0, gasHeatingImprov = 0, electricHeatingAlts = 0, electricHeatingImprov = 0;

        //get Average Ceiling Height from Dwelling Unit
        //List<Dwelling_Unit__c> dwellingunits = [SELECT Id, Avg_Ceiling_Height__c FROM Dwelling_Unit__c WHERE Id = 'a0NK000000K4tlA'];
        //Dwelling_Unit__c thisDwellingUnit =  dwellingunits.get(0);

        //get this hvacs duct r value and add to running total
        Decimal hvacDuctRValue = 0;
        for (Duct d: ducts) {
            if (d.DuctInsulationRValue != null && d.DuctInsulationRValue > 0) {
                hvacDuctRValue = d.DuctInsulationRValue;
                summary.TotalDuctRValue += d.DuctInsulationRValue;
            }
        }

        Decimal TotalVolumeByHVAC = 0; //used to track the total volume of current HVAC

        for (Building b: buildings) {

            //AUDIT - start
            if (b.ProjectStatus == 'audit'){

                subappbuilding.Address1 = b.Address1;
                subappbuilding.CityMunicipality = b.CityMunicipality;
                subappbuilding.StateCode = b.StateCode;
                subappbuilding.ZipCode = b.ZipCode;
                subappbuilding.ConditionedFloorArea = b.ConditionedFloorArea;
                subappbuilding.NumberofDwellingUnits = 0;
                subappbuilding.NumberofStoriesAboveGrade = b.NumberofStoriesAboveGrade;
                subappbuilding.NumberofOccupants = b.NumberofResidents;
                subappbuilding.FoundationType = b.FoundationType;

                for(AirInfiltrationMeasurement a: aims){
                     if(a.BuildingId == b.SystemIdentifier){
                        //add to running total of initial blower door results
                        if(a.TypeOfInfiltrationMeasurement == 'blower door' && math.abs(a.HousePressure) == 50){
                            summary.InitialBlowerDoorResults += a.AirLeakage;
                        }
                     }
                }

                for(HVACDistribution hd: hvacdistributions){
                    if(hd.BuildingId == b.SystemIdentifier){
                        for(HPXML.DuctLeakageMeasurement dlm: ductleakagemeasurements){
                            if(dlm.SystemIdentifier == hd.SystemIdentifier){
                                //add to running total of initial duct test results
                                summary.InitialDuctTestResults += dlm.DuctLeakageValue;
                            }
                        }
                    }
                }

                //End Use Pre Values
                //baseload
                Decimal electricAppliance = 0;
                Decimal electricOther = 0;
                Decimal gasAppliance = 0;
                Decimal gasOther = 0;

                //cooling
                Decimal electricCooling = 0;
                Decimal gasCooling = 0;

                //heating
                Decimal electricHeating = 0;
                Decimal gasHeating = 0;

                //fan
                Decimal electricFan = 0;
                Decimal gasFan = 0;

                //lighting
                Decimal electricLighting = 0;
                Decimal gasLighting = 0;

                //others
                Decimal electricPV = 0;
                Decimal electricSolarThermal = 0;
                Decimal electricHotWater = 0;
                Decimal gasPV = 0;
                Decimal gasSolarThermal = 0;
                Decimal gasHotWater = 0;

                for(ModeledUsage mu: modeledusages){
                     if(mu.BuildingId == b.SystemIdentifier){
                        if (mu.EnergyType == 'electricity'){
                            if(mu.Appliance != NULL)
                                electricAppliance = mu.Appliance;
                            if(mu.Other != NULL)
                                electricOther = mu.Other;
                            if(mu.Cooling != NULL)
                                electricCooling = mu.Cooling;
                            if(mu.Heating != NULL)
                                electricHeating = mu.Heating;
                            if(mu.HotWater != NULL)
                                electricHotWater = mu.HotWater;
                            if(mu.SolarThermal != NULL)
                                electricSolarThermal = mu.SolarThermal;
                            if(mu.PV != NULL)
                                electricPV = mu.PV;
                            if(mu.Lighting != NULL)
                                electricLighting = mu.Lighting;
                        }
                        if (mu.EnergyType == 'natural gas' || mu.EnergyType == 'propane'){
                            if(mu.Appliance != NULL)
                                gasAppliance = mu.Appliance;
                            if(mu.Other != NULL)
                                gasOther = mu.Other;
                            if(mu.Cooling != NULL)
                                gasCooling = mu.Cooling;
                            if(mu.Heating != NULL)
                                gasHeating = mu.Heating;
                            if(mu.HotWater != NULL)
                                gasHotWater = mu.HotWater;
                            if(mu.SolarThermal != NULL)
                                gasSolarThermal = mu.SolarThermal;
                            if(mu.PV != NULL)
                                gasPV = mu.PV;
                            if(mu.Lighting != NULL)
                                gasLighting = mu.Lighting;
                        }
                    }
                }

                Integer buildingHasCoolingAudit = 0;
                if (b.hasCooling == 1)
                    buildingHasCoolingAudit = 1;

                Decimal GasUseTherms = gasAppliance + gasOther + gasCooling + gasHeating + gasHotWater + gasSolarThermal + gasPV + gasLighting;

                //map initial values by end use and array of values (kW, kWh, therms)
                //base load should include pump an ancillary end uses
                endUsePreValues.put(
                    'Base Load', new Decimal[] {
                        electricAppliance + electricOther,
                        gasAppliance + gasOther
                    }
                );
                endUsePreValues.put(
                    'Cooling',
                    new Decimal[] {
                        electricCooling,
                        gasCooling
                    }
                );
                endUsePreValues.put(
                    'Fans',
                    new Decimal[] {
                        electricFan,
                        gasFan
                    }
                );
                endUsePreValues.put(
                    'Heating',
                    new Decimal[] {
                        electricHeating,
                        gasHeating
                    }
                );
                endUsePreValues.put(
                    'Water Heating',//hotwater
                    new Decimal[] {
                        electricHotWater,
                        gasHotWater
                    }
                );
                //lighting should include both indoor and outdoor lighting
                endUsePreValues.put(
                    'Lighting',
                    new Decimal[] {
                        electricLighting,
                        gasLighting
                    }
                );

                //store individual values and total for initial electric use
                summary.InitialElectric.Heating = electricHeating;
                summary.InitialElectric.Total += electricHeating;
                summary.InitialElectric.Cooling = electricCooling;
                summary.InitialElectric.Total += electricCooling;
                summary.InitialElectric.WaterHeating = electricHotWater;
                summary.InitialElectric.Total += electricHotWater;
                summary.InitialElectric.Appliances = electricAppliance;
                summary.InitialElectric.Total += electricAppliance;
                summary.InitialElectric.IndoorLighting = electricLighting;
                summary.InitialElectric.Total += electricLighting;
                summary.InitialElectric.Renewables = electricPV + electricSolarThermal;
                summary.InitialElectric.Total += electricPV + electricSolarThermal;
                summary.InitialElectric.Ancillary = 0;
                summary.InitialElectric.Pumps = 0;
                summary.InitialElectric.Fans = 0;
                summary.InitialElectric.OutdoorLighting = 0;

                //store individual values and total for initial gas use
                summary.initialGas.GasHeating = gasHeating;
                summary.initialGas.Total += gasHeating;
                summary.initialGas.GasCooling = gasCooling;
                summary.initialGas.Total += gasCooling;
                summary.initialGas.GasWaterHeating = gasHotWater;
                summary.initialGas.Total += gasHotWater;
                summary.initialGas.GasAppliances = gasAppliance;
                summary.initialGas.Total += gasAppliance;
                summary.initialGas.GasIndoorLighting = gasLighting;
                summary.initialGas.Total += gasLighting;
                summary.initialGas.GasRenewables = gasPV + gasSolarThermal;
                summary.initialGas.Total += gasPV + gasSolarThermal;
                summary.initialGas.GasAncillary = 0;
                summary.initialGas.GasPumps = 0;
                summary.initialGas.GasFans = 0;
                summary.initialGas.GasOutdoorLighting = 0;
            }
            //AUDIT - end

            //RETROFIT - start
            if (b.ProjectStatus == 'retrofit'){

                //add to running total
                if (b.NumberOfBedrooms != NULL)
                    summary.TotalBedrooms += b.NumberOfBedrooms;

                //evaluate if this is the earliest value for YearBuilt
                if (summary.YearBuilt != null || summary.YearBuilt > b.YearBuilt)
                    summary.YearBuilt = b.YearBuilt;

                //get Average Ceiling Height from Dwelling Unit

                //List<Dwelling_Unit__c> dwellingunits = [SELECT Id, Avg_Ceiling_Height__c FROM Dwelling_Unit__c WHERE Id = :application.Dwelling_Unit__c];
                //for(Dwelling_Unit__c thisDwellingUnit:dwellingUnits){
                 //   if (
                        //get temporarily from Dwelling Unit
                   //     thisDwellingUnit.Avg_Ceiling_Height__c != NULL && thisDwellingUnit.Avg_Ceiling_Height__c > 0 &&
                     //   b.ConditionedFloorArea != NULL && b.ConditionedFloorArea > 0
                    //) {
                      //  summary.TotalCeilingHeight += thisDwellingUnit.Avg_Ceiling_Height__c;
                        //summary.TotalRoomArea += b.ConditionedFloorArea;
                        //summary.TotalVolume += b.ConditionedFloorArea * thisDwellingUnit.Avg_Ceiling_Height__c;
                        //add to running total volume for the current HVAC
                        //TotalVolumeByHVAC += b.ConditionedFloorArea * thisDwellingUnit.Avg_Ceiling_Height__c;
                    //}
                //}


                //-- Evaluate Insulations
                //track floor area
                for(Foundation f: foundations){
                    if(foundation.BuildingId == b.SystemIdentifier){
                        Decimal thisFoundationUFactor = 1;
                        // Fixed: f.AssemblyEffectiveRValue should not be null. It can be null when there is no FrameFloor Insulation AssemblyEffectiveRValue.
                        if (f.AssemblyEffectiveRValue!=null && f.AssemblyEffectiveRValue != 0)
                            thisFoundationUFactor = 1 / f.AssemblyEffectiveRValue;
                        if (thisFoundationUFactor!=null)
                            summary.TotalFloorUFactor += thisFoundationUFactor;
                        if (f.Area!=null)
                            summary.TotalFloorArea += f.Area;
                        if (thisFoundationUFactor!=null && f.Area!=null)
                            summary.TotalFloorUFactorByArea += thisFoundationUFactor * f.Area;
                    }
                }
                //track ceiling area
                for(HPXML.Attic a: attics){
                    if(attic.BuildingId == b.SystemIdentifier){
                        Decimal thisAtticUFactor = 1;
                        if (a.ariAssemblyEffectiveRValue != NULL && a.ariAssemblyEffectiveRValue != 0)
                            thisAtticUFactor = 1 / a.ariAssemblyEffectiveRValue;
                        summary.TotalRoofUFactor += thisAtticUFactor;
                        summary.TotalRoofArea += a.Area;
                        summary.TotalRoofUFactorByArea  += thisAtticUFactor * a.Area;
                    }
                }

                //track wall area
                for(HPXML.WallInsulation wi: wallinsulations){
                    if(wi.BuildingId == b.SystemIdentifier){
                        Decimal thisWIUFactor = 1;
                        if (wi.AssemblyEffectiveRValue != NULL && wi.AssemblyEffectiveRValue != 0)
                            thisWIUFactor = 1 / wi.AssemblyEffectiveRValue;
                        summary.TotalWallUFactor += thisWIUFactor;
                        summary.TotalWallArea += wi.Area;
                        summary.TotalWallUFactorByArea  += thisWIUFactor * wi.Area;
                    }
                }

                //-- Evaluate Fenestrations
                //track window area
                for(Window win: windows){
                    if(win.BuildingId == b.SystemIdentifier){
                        summary.TotalWindowUFactor += win.UFactor;
                        summary.TotalWindowArea += win.Area;
                        summary.TotalWindowUFactorByArea  += win.UFactor * win.Area;
                    }
                }

                //End Use Post Values
                //baseload
                Decimal electricAppliance = 0;
                Decimal electricOther = 0;
                Decimal gasAppliance = 0;
                Decimal gasOther = 0;

                //cooling
                Decimal electricCooling = 0;
                Decimal gasCooling = 0;

                //heating
                Decimal electricHeating = 0;
                Decimal gasHeating = 0;

                //fan
                Decimal electricFan = 0;
                Decimal gasFan = 0;

                //lighting
                Decimal electricLighting = 0;
                Decimal gasLighting = 0;

                //others
                Decimal electricPV = 0;
                Decimal electricSolarThermal = 0;
                Decimal electricHotWater = 0;
                Decimal gasPV = 0;
                Decimal gasSolarThermal = 0;
                Decimal gasHotWater = 0;

                for(ModeledUsage mu: modeledusages){
                     if(mu.BuildingId == b.SystemIdentifier){
                        if (mu.EnergyType == 'electricity'){
                            if(mu.Appliance != NULL)
                                electricAppliance = mu.Appliance;
                            if(mu.Other != NULL)
                                electricOther = mu.Other;
                            if(mu.Cooling != NULL)
                                electricCooling = mu.Cooling;
                            if(mu.Heating != NULL)
                                electricHeating = mu.Heating;
                            if(mu.HotWater != NULL)
                                electricHotWater = mu.HotWater;
                            if(mu.SolarThermal != NULL)
                                electricSolarThermal = mu.SolarThermal;
                            if(mu.PV != NULL)
                                electricPV = mu.PV;
                            if(mu.Lighting != NULL)
                                electricLighting = mu.Lighting;
                        }
                        if (mu.EnergyType == 'natural gas' || mu.EnergyType == 'propane'){
                            if(mu.Appliance != NULL)
                                gasAppliance = mu.Appliance;
                            if(mu.Other != NULL)
                                gasOther = mu.Other;
                            if(mu.Cooling != NULL)
                                gasCooling = mu.Cooling;
                            if(mu.Heating != NULL)
                                gasHeating = mu.Heating;
                            if(mu.HotWater != NULL)
                                gasHotWater = mu.HotWater;
                            if(mu.SolarThermal != NULL)
                                gasSolarThermal = mu.SolarThermal;
                            if(mu.PV != NULL)
                                gasPV = mu.PV;
                            if(mu.Lighting != NULL)
                                gasLighting = mu.Lighting;
                        }
                    }
                }

                //store individual values and total for improved electric use
                summary.improvedElectric.Heating = electricHeating;
                summary.improvedElectric.Total += electricHeating;
                summary.improvedElectric.Cooling = electricCooling;
                summary.improvedElectric.Total += electricCooling;
                summary.improvedElectric.WaterHeating = electricHotWater;
                summary.improvedElectric.Total += electricHotWater;
                summary.improvedElectric.Appliances = electricAppliance;
                summary.improvedElectric.Total += electricAppliance;
                summary.improvedElectric.IndoorLighting = electricLighting;
                summary.improvedElectric.Total += electricLighting;
                summary.improvedElectric.Renewables = electricPV + electricSolarThermal;
                summary.improvedElectric.Total += electricPV + electricSolarThermal;
                summary.improvedElectric.Ancillary = 0;
                summary.improvedElectric.Pumps = 0;
                summary.improvedElectric.Fans = 0;
                summary.improvedElectric.OutdoorLighting = 0;

                //store individual values and total for improved gas use
                summary.improvedGas.GasHeating = gasHeating;
                summary.improvedGas.Total += gasHeating;
                summary.improvedGas.GasCooling = gasCooling;
                summary.improvedGas.Total += gasCooling;
                summary.improvedGas.GasWaterHeating = gasHotWater;
                summary.improvedGas.Total += gasHotWater;
                summary.improvedGas.GasAppliances = gasAppliance;
                summary.improvedGas.Total += gasAppliance;
                summary.improvedGas.GasIndoorLighting = gasLighting;
                summary.improvedGas.Total += gasLighting;
                summary.improvedGas.GasRenewables = gasPV + gasSolarThermal;
                summary.improvedGas.Total += gasPV + gasSolarThermal;
                summary.improvedGas.GasAncillary = 0;
                summary.improvedGas.GasPumps = 0;
                summary.improvedGas.GasFans = 0;
                summary.improvedGas.GasOutdoorLighting = 0;

                Integer buildingHasCoolingRetrofit = 0;
                if (b.hasCooling == 1)
                    buildingHasCoolingRetrofit = 1;
                Decimal GasUseTherms = gasAppliance + gasOther + gasCooling + gasHeating + gasHotWater + gasSolarThermal + gasPV + gasLighting;

                //map initial values by end use and array of values (kW, kWh, therms)
                //base load should include pump an ancillary end uses
                endUsePostValues.put(
                    'Base Load',
                    new Decimal[] {
                        electricAppliance + electricOther,
                        gasAppliance + gasOther
                    }
                );
                endUsePostValues.put(
                    'Cooling',
                    new Decimal[] {
                        electricCooling,
                        gasCooling
                    }
                );
                endUsePostValues.put(
                    'Fans',
                    new Decimal[] {
                        electricFan,
                        gasFan
                    }
                );
                endUsePostValues.put(
                    'Heating',
                    new Decimal[] {
                        electricHeating,
                        gasHeating
                    }
                );
                endUsePostValues.put(
                    'Water Heating',
                    new Decimal[] {
                        electricHotWater,
                        gasHotWater
                    }
                );
                //lighting should include both indoor and outdoor lighting
                endUsePostValues.put(
                    'Lighting',
                    new Decimal[] {
                        electricLighting,
                        gasLighting
                    }
                );

                //if the final result's UtilityElecUse has a cooling value greater than 0, value is true
                if (electricCooling != null && electricCooling > 0) {
                    summary.PostUpgradeCoolingPresent = true;
                }
                else {
                    summary.PostUpgradeCoolingPresent = false;
                }

            }
            //RETROFIT - end

            //add current HVACs duct insulation r factor value by volume to running total
            summary.TotalDuctRValueByVolume += hvacDuctRValue * TotalVolumeByHVAC;
        }

        //get the average duct R value weighted by total volume of all rooms
        if (summary.TotalDuctRValueByVolume != 0 && summary.TotalVolume != 0) {
            summary.AvgDuctRValue = summary.TotalDuctRValueByVolume / summary.TotalVolume;
        }

        //get Average Ceiling Height from Dwelling Unit
        Integer thisCounter = 0;
        List<Dwelling_Unit__c> dwellingunits = [SELECT Id, Avg_Ceiling_Height__c FROM Dwelling_Unit__c WHERE Id = :application.Dwelling_Unit__c];
        for(Dwelling_Unit__c thisDwellingUnit:dwellingUnits){
            if (
                //get temporarily from Dwelling Unit
                thisDwellingUnit.Avg_Ceiling_Height__c != NULL && thisDwellingUnit.Avg_Ceiling_Height__c > 0
            ) {
                summary.AvgCeilingHeight += thisDwellingUnit.Avg_Ceiling_Height__c;
                thisCounter += 1;
            }
        }

        if(thisCounter > 0)
            summary.AvgCeilingHeight = summary.AvgCeilingHeight/thisCounter;

        //get the average ceiling height
        //if (summary.TotalVolume != 0 && summary.TotalRoomArea != 0) {
        //    summary.AvgCeilingHeight = summary.TotalVolume / summary.TotalRoomArea;
        //}

        //get the average floor UFactor weighted by area
        if (summary.TotalFloorUFactorByArea != 0 && summary.TotalFloorArea != 0) {
            summary.AvgFloorUFactor = summary.TotalFloorUFactorByArea / summary.TotalFloorArea;
        }

        //get the average ceiling UFactor weighted by area
        if (summary.TotalRoofUFactorByArea != 0 && summary.TotalRoofArea != 0) {
            summary.AvgCeilingUFactor = summary.TotalRoofUFactorByArea / summary.TotalRoofArea;
        }

        //get the average wall UFactor weighted by area
        if (summary.TotalWallUFactorByArea != 0 && summary.TotalWallArea != 0) {
            summary.AvgWallUFactor = summary.TotalWallUFactorByArea / summary.TotalWallArea;
        }

        //get the average window ufactor weighted by area
        if (summary.TotalWindowUFactorByArea != 0 && summary.TotalWindowArea != 0) {
            summary.AvgWindowUFactor = summary.TotalWindowUFactorByArea / summary.TotalWindowArea;
        }

        //store individual savings and total savings for electric use
        summary.electricSavings.Heating = summary.initialElectric.Heating - summary.improvedElectric.Heating;
        summary.electricSavings.Cooling = summary.initialElectric.Cooling - summary.improvedElectric.Cooling;
        summary.electricSavings.WaterHeating = summary.initialElectric.WaterHeating - summary.improvedElectric.WaterHeating;
        summary.electricSavings.Appliances = summary.initialElectric.Appliances - summary.improvedElectric.Appliances;
        summary.electricSavings.Ancillary = summary.initialElectric.Ancillary - summary.improvedElectric.Ancillary;
        summary.electricSavings.IndoorLighting = summary.initialElectric.IndoorLighting - summary.improvedElectric.IndoorLighting;
        summary.electricSavings.Pumps = summary.initialElectric.Pumps - summary.improvedElectric.Pumps;
        summary.electricSavings.Fans = summary.initialElectric.Fans - summary.improvedElectric.Fans;
        summary.electricSavings.OutdoorLighting = summary.initialElectric.OutdoorLighting - summary.improvedElectric.OutdoorLighting;
        summary.electricSavings.Renewables = summary.initialElectric.Renewables - summary.improvedElectric.Renewables;
        summary.electricSavings.Total = summary.initialElectric.Total - summary.improvedElectric.Total;

        //store individual savings and total savings for gas use
        summary.gasSavings.GasHeating = summary.initialGas.GasHeating - summary.improvedGas.GasHeating;
        summary.gasSavings.GasCooling = summary.initialGas.GasCooling - summary.improvedGas.GasCooling;
        summary.gasSavings.GasWaterHeating = summary.initialGas.GasWaterHeating - summary.improvedGas.GasWaterHeating;
        summary.gasSavings.GasAppliances = summary.initialGas.GasAppliances - summary.improvedGas.GasAppliances;
        summary.gasSavings.GasAncillary = summary.initialGas.GasAncillary - summary.improvedGas.GasAncillary;
        summary.gasSavings.GasIndoorLighting = summary.initialGas.GasIndoorLighting - summary.improvedGas.GasIndoorLighting;
        summary.gasSavings.GasPumps = summary.initialGas.GasPumps - summary.improvedGas.GasPumps;
        summary.gasSavings.GasFans = summary.initialGas.GasFans - summary.improvedGas.GasFans;
        summary.gasSavings.GasOutdoorLighting = summary.initialGas.GasOutdoorLighting - summary.improvedGas.GasOutdoorLighting;
        summary.gasSavings.GasRenewables = summary.initialGas.GasRenewables - summary.improvedGas.GasRenewables;
        summary.gasSavings.Total = summary.initialGas.Total - summary.improvedGas.Total;

        storeData(); //store the data in database objects
    }

    //-- Stores the parsed data from inner classes in database objects
    private void storeData() {
        try {

            application = [
                SELECT Id, Application_Submission_Date__c, Electric_Provider__c, Gas_Provider__c,
                Incentive_Total__c, Notes__c, HC_Type__c, Customer_First_Name__c, Customer_Address__c,
                Customer_City__c, Customer_State__c, Customer_Zip_Code__c, Customer_Phone__c,
                Contractor__c, Contractor__r.First_Name__c, Contractor__r.Last_Name__c, Contractor__r.Name,
                Contractor__r.BillingStreet, Contractor__r.BillingCity, Contractor__r.BillingState,
                Contractor__r.BillingPostalCode, Contractor__r.Phone, Contractor__r.License_Number__c,
                BPI_Analyst__c, BPI_Analyst__r.Name, BPI_Analyst__r.BPI_License_Number__c, Dwelling_Unit__c,
                Building_Type__c, Building_Vintage__c, Electricity_Usage__c, Natural_Gas_Usage__c,
                Total_Energy_Usage_KBTUs__c, Proposed_Electricity_Savings__c, Proposed_Natural_Gas_Savings__c,
                Proposed_Total_Energy_Savings_KBTU__c, Completed_Electricity_Savings__c,
                Completed_Natural_Gas_Savings__c, Completed_Total_Energy_Savings_KBTU__c, Rebate_FROM_Tier__c,
                Granted_Exceptions__c//, Has_HPHI__c
                FROM Application__c
                WHERE Id = :application.Id
            ];
        }
        catch (Exception e) {
            System.debug('### Exception while trying to query for application: ' + e.getMessage());
        }

        //for tracking incentive and bonus eligibility
        Boolean electricProvider = false, gasProvider = false, eerBonus = false, seerBonus = false, pumpBonus = false;

        //determine if electric rebates should be included
        if (application.Electric_Provider__c == 'SoCalGas' || application.Electric_Provider__c == 'Pacific Gas and Electric Company') {
            electricProvider = true;
        }
        //determine if gas rebates should be included
        if (application.Gas_Provider__c == SOUTHERN_CA_GAS || application.Gas_Provider__c == 'Pacific Gas and Electric Company') {
            gasProvider = true;
        }

        //get the sub-application with any existing XML Results and XML End Uses
        try {
            subApplication = [
                SELECT Id, Software__c, Software_Version__c, Building_Street_Address__c, Building_City__c,
                Building_State__c, Building_ZIP_Code__c, Conditioned_Floor_Area__c, Number_of_Dwelling_Units__c,
                Number_of_Stories__c, Number_of_Occupants__c, Foundation_Type__c, Year_Built__c, Number_of_Bedrooms__c,
                Pool_Type__c, Spa_Type__c, Thermostat_Type__c, Total_Window_Area__c, Avg_Window_U_Factor__c,
                Duct_Insulation_R_value__c, Duct_Leakage_cfm25__c, Building_Leakage_cfm50__c, Avg_Ceiling_Height__c,
                Avg_Floor_Insulation_U_Factor__c, Avg_Ceiling_Insulation_U_Factor__c, Total_Wall_Area__c,
                Avg_Wall_Insulation_U_Factor__c, Demand_Savings_kW_HPXML__c,
                (SELECT Id FROM XML_Results__r),
                (SELECT Id FROM XML_End_Uses__r)
                FROM Sub_Application__c
                WHERE Id = :subApplication.Id
            ];
        }
        catch (Exception e) {
            System.debug('### Exception while trying to query for Sub-Application: ' + e.getMessage());
        }

        //extract sub applicataion info from parsed xml
        subApplication.Software__c = software.SoftwareProgramUsed;
        subApplication.Software_Version__c = software.SoftwareProgramVersion;
        subApplication.Building_Street_Address__c = subappbuilding.Address1;
        subApplication.Building_City__c = subappbuilding.CityMunicipality;
        subApplication.Building_State__c = subappbuilding.StateCode;
        subApplication.Building_ZIP_Code__c = subappbuilding.ZipCode;
        subApplication.Conditioned_Floor_Area__c = subappbuilding.ConditionedFloorArea;
        subApplication.Number_of_Dwelling_Units__c = 0;
        subApplication.Number_of_Stories__c = subappbuilding.NumberofStoriesAboveGrade;
        subApplication.Number_of_Occupants__c = subappbuilding.NumberofOccupants;
        subApplication.Foundation_Type__c = subappbuilding.FoundationType;
        subApplication.Year_Built__c = String.valueOf(summary.YearBuilt);
        subApplication.Number_of_Bedrooms__c = summary.TotalBedrooms;
        subApplication.Pool_Type__c = summary.PoolType;
        subApplication.Spa_Type__c = summary.SpaType;
        subApplication.Thermostat_Type__c = summary.ThermostatType;
        subApplication.Duct_Insulation_R_value__c = summary.AvgDuctRValue;
        subApplication.Duct_Leakage_cfm25__c = summary.InitialDuctTestResults;
        subApplication.Building_Leakage_cfm50__c = summary.InitialBlowerDoorResults;
        subApplication.Avg_Ceiling_Height__c = summary.AvgCeilingHeight;
        subApplication.Avg_Floor_Insulation_U_Factor__c = summary.AvgFloorUFactor;
        subApplication.Avg_Ceiling_Insulation_U_Factor__c = summary.AvgCeilingUFactor;
        subApplication.Total_Wall_Area__c = summary.TotalWallArea;
        subApplication.Avg_Wall_Insulation_U_Factor__c = summary.AvgWallUFactor;
        subApplication.Total_Window_Area__c = summary.TotalWindowArea;
        subApplication.Avg_Window_U_Factor__c = summary.AvgWindowUFactor;
        subApplication.Demand_Savings_kW_HPXML__c = Decimal.valueOf(energySavingsInfo.DemandSavings);
        update subApplication;

        //if results and end uses already exist, delete existing records
        if (subApplication.XML_Results__r.size() > 0) {
            delete subApplication.XML_Results__r;
        }
        if (subApplication.XML_End_Uses__r.size() > 0) {
            delete subApplication.XML_End_Uses__r;
        }

        Decimal positiveKWhSavings = 0;
        Decimal positiveThermSavings = 0;

        //extract end uses from pre and post value maps
        xmlEndUses = new List<XML_End_Use__c>(); //instantiate list
        for (String type : endUsePreValues.keySet()) {
            XML_End_Use__c endUse = new XML_End_Use__c();
            endUse.Sub_Application__c = subApplication.Id;
            endUse.End_Use__c = type; //map's key is the end use type
            //get initial values from map
            endUse.Pre_Install_Electricity_Use_kWh__c = endUsePreValues.get(type)[0];
            endUse.Pre_Install_Gas_Use_therms__c = endUsePreValues.get(type)[1];
            //get post values from map
            endUse.Post_Install_Electricity_Use_kWh__c = endUsePostValues.get(type)[0];
            endUse.Post_Install_Gas_Use_therms__c = endUsePostValues.get(type)[1];
            xmlEndUses.add(endUse);

            // Get only positive values for KWhSavings to calculate Incentive Amount later
            if (endUse.Pre_Install_Electricity_Use_kWh__c > 0) {
                positiveKWhSavings += endUse.Pre_Install_Electricity_Use_kWh__c;
            }
            if (endUse.Post_Install_Electricity_Use_kWh__c > 0) {
                positiveKWhSavings -= endUse.Post_Install_Electricity_Use_kWh__c;
            }
            // Get only positive values for thermSavings to calculate Incentive Amount later
            if (endUse.Pre_Install_Gas_Use_therms__c > 0) {
                positiveThermSavings += endUse.Pre_Install_Gas_Use_therms__c;
            }
            if (endUse.Post_Install_Gas_Use_therms__c > 0) {
                positiveThermSavings -= endUse.Post_Install_Gas_Use_therms__c;
            }
        }
        insert xmlEndUses;

        //query the sub-application object to get new formula values
        subApplication = [
            SELECT Id, RecordTypeId, Initial_Submission_Date__c, Air_Conditioning_Present__c,
                Building_Street_Address__c, Building_City__c, Building_State__c, Software__c, Building_ZIP_Code__c,
                Number_of_Stories__c, Number_of_Dwelling_Units__c, Pre_Install_Electricity_Use_kWh__c,
                Pre_Install_Gas_Use_therms__c, Total_Energy_Savings_kWh__c, Total_Energy_Savings_therms__c,
                Total_Energy_Savings_BTUs__c, Total_Energy_Savings_Percent__c, Total_Incentive__c,
                Total_Incentive_Adjustment__c, Total_Incentive_FROM_Tier__c, PGE_Payable_Modeled_Savings_Incentive__c,
                Proposed_Package_Cost__c, Completed_Package_Cost__c, Rebate_Assignment__c, Demand_Savings_kW__c,
                HPHI_Bonus__c
            FROM Sub_Application__c
            WHERE Id = :subApplication.Id
        ];

        //query xml end uses to get additional rebate fields and new formula values
        xmlEndUses = [
            SELECT Id, End_Use__c, Kicker__c, Item_Incentive_Amount__c, Gross_kW__c, Gross_kWh__c, Gross_Therms__c,
            End_Use_Energy_Savings_kW__c, End_Use_Energy_Savings_kWh__c, End_Use_Energy_Savings_therms__c
            FROM XML_End_Use__c
            WHERE Sub_Application__c = :subApplication.Id
        ];

        // Calculate incentive //
        //get the zip codes eligible for additional AC and Pool Pump bonus kickers
        Set<String> eligibleZips = new Set<String>();
        List<Eligible_Zip_Codes__c> zips = Eligible_Zip_Codes__c.getall().values();
        for (Eligible_Zip_Codes__c z : zips) {
            eligibleZips.add(z.Name);
        }

        Decimal acKicker = 0, poolPumpKicker = 0; //default to 0 to prevent bonuses if no values set
        //determine bonus eligibility based on building zip code and electric provider
        if (eligibleZips.contains(subApplication.Building_ZIP_Code__c) && electricProvider) {
            Decimal acBonusValue = 0, pumpBonusValue = 0;
            //get custom settings for AC and pool pump kickers/bonuses
            for (Bonuses__c b : Bonuses__c.getall().values()) {
                if (b.Name == 'AC Kicker') {
                    acBonusValue = b.Value__c;
                }
                else if (b.Name == 'Pool Pump Kicker') {
                    pumpBonusValue = b.Value__c;
                }
            }
            //apply bonus if EER and SEER qualified
            if (eerBonus && seerBonus) {
                acKicker = acBonusValue;
            }
            //apply bonus if pool pump qualified
            if (pumpBonus) {
                poolPumpKicker = pumpBonusValue;
            }
        }

        //determine whether the home is "heated and cooled" or "heated only"
        Boolean heatedAndCooled = subApplication.Air_Conditioning_Present__c;

        //no modifiers for HPXML for now - values in custom setting set to 1
        Decimal kWhModifier = 1, thermModifier = 1; //default to 1 to prevent modification if no values set
        Modifiers__c m = Modifiers__c.getValues('HPXML');
        if (m != null) {
            if (m.kWh_Modifier__c != null) {
                kWhModifier = m.kWh_Modifier__c;
            }
            if (m.Therm_Modifier__c != null) {
                thermModifier = m.Therm_Modifier__c;
            }
        }

        //adjust kWh savings only if heated and cooled
        Decimal kWhSavings = subApplication.Total_Energy_Savings_kWh__c;
        if (heatedAndCooled) {
            kWhSavings *= kWhModifier;
            positiveKWhSavings = positiveKWhSavings > 0 ? positiveKWhSavings * kWhModifier : 0;
        }

        //always adjust therm savings
        Decimal thermSavings = subApplication.Total_Energy_Savings_therms__c * thermModifier;
        positiveThermSavings = positiveThermSavings > 0 ? positiveThermSavings * thermModifier : 0;

        //determine initial usage for utilities provided by PG&E
        Decimal BTUInitialSum = 0;
        if (electricProvider) {
            BTUInitialSum += subApplication.Pre_Install_Electricity_Use_kWh__c * KWH_TO_BTU;
        }
        if (gasProvider) {
            BTUInitialSum += subApplication.Pre_Install_Gas_Use_therms__c * THERMS_TO_BTU;
        }

        //determine initial usage agnostic of provider
        Decimal agnosticBTUInitialSum = 0;
        agnosticBTUInitialSum += subApplication.Pre_Install_Electricity_Use_kWh__c * KWH_TO_BTU;
        agnosticBTUInitialSum += subApplication.Pre_Install_Gas_Use_therms__c * THERMS_TO_BTU;

        //determine total savings for utilities provided by PG&E
        Decimal BTUSavings = 0;
        if (electricProvider) {
            BTUSavings += (kWhSavings * KWH_TO_BTU);
        }
        if (gasProvider) {
            BTUSavings += (thermSavings * THERMS_TO_BTU);
        }

        //determine total savings agnostic of provider
        Decimal agnosticBTUSavings = (kWhSavings * KWH_TO_BTU) + (thermSavings * THERMS_TO_BTU);
        Decimal agnosticPositiveBTUSavings = (positiveKWhSavings * KWH_TO_BTU) + (positiveThermSavings * THERMS_TO_BTU);

        //determine the site savings, round to nearest tenth of a percentage
        Decimal agnosticSiteSavingsPercent = agnosticBTUInitialSum > 0
                ? ((agnosticBTUSavings / agnosticBTUInitialSum) * 100)
                : 0;

        //save the initial results, agnostic of provider
        application.Electricity_Usage__c = subApplication.Pre_Install_Electricity_Use_kWh__c;
        application.Natural_Gas_Usage__c = subApplication.Pre_Install_Gas_Use_therms__c;
        application.Total_Energy_Usage_KBTUs__c = agnosticBTUInitialSum / 1000;

        if (isPostApplication) {
           //save the adjusted/completed savings on the application
            application.Completed_Electricity_Savings__c = kWhSavings;
            application.Completed_Natural_Gas_Savings__c = thermSavings;
            application.Completed_Total_Energy_Savings_KBTU__c = agnosticBTUSavings / 1000;
        }
        else {
            application.Proposed_Electricity_Savings__c = kWhSavings;
            application.Proposed_Natural_Gas_Savings__c = thermSavings;
            application.Proposed_Total_Energy_Savings_KBTU__c = agnosticBTUSavings / 1000;
        }

        // Set structure to check later wich Rebate_Tiers__c should use
        Integer structure = BIGPortalAdvanceHUApplicationUtils.getStructureDependingOnDates(application,
                subApplication, isPostApplication);

        // Locate base incentive for modified site savings FROM appropriate tier
        List<Rebate_Tiers__c> tiers = Rebate_Tiers__c.getall().values();
        Decimal agnosticBaseIncentive = 0;
        for (Rebate_Tiers__c t : tiers) {
            // Assign Rabete depending on structure, lower and upper limit
            if (t.Structure__c == structure && agnosticSiteSavingsPercent >= t.Lower_Limit__c
                    && agnosticSiteSavingsPercent < t.Upper_Limit__c) {
                agnosticBaseIncentive = t.Rebate__c;
                break;
            }
        }

        application.Rebate_from_Tier__c = agnosticBaseIncentive;
        subApplication.Total_Incentive_from_Tier__c = agnosticBaseIncentive;

        //determine the amount of the rebate PG&E is responsible for
        Decimal percentPGEResponsibility = agnosticPositiveBTUSavings > 0
                ? (BTUSavings / agnosticPositiveBTUSavings).setScale(2)
                : 0;
        subApplication.PGE_Payable_Modeled_Savings_Incentive__c =
                (agnosticBaseIncentive * percentPGEResponsibility).setScale(2);

        //get custom settings for kickers
        Decimal kWhKickerMultiplier = 0, thermKickerMultiplier = 0; //default to 0 to prevent kicker bonus if not present
        for (Kickers__c k : Kickers__c.getall().values()) {
            if (k.Name == 'kWh Kicker') {
                kWhKickerMultiplier = k.Value__c;
            }
            else if (k.Name == 'Therm Kicker') {
                thermKickerMultiplier = k.Value__c;
            }
        }

        //calculate fuel type dependent kickers based on adjusted savings
        Decimal kWhkickers = 0, thermKickers = 0;
        //only apply kWh kicker if PG&E is electric provider
        if (electricProvider) {
            kWhkickers = (kWhSavings * kWhKickerMultiplier).setScale(2);
        }

        //only apply therm kicker if PG&E is gas provider
        if (gasProvider) {
            thermKickers = (thermSavings * thermKickerMultiplier).setScale(2);
        }

        // Determine total incentive
        Decimal totalIncentive = acKicker + poolPumpKicker + kWhKickers + thermKickers
                + subApplication.PGE_Payable_Modeled_Savings_Incentive__c;
        // Determine total incentive cap (50% of the proposed or completed cost depending on project phase)
        Decimal fiftyPercentIncentiveTotal = isPostApplication
                ? (0.5 * subApplication.Completed_Package_Cost__c).setScale(2)
                : (0.5 * subApplication.Proposed_Package_Cost__c).setScale(2);

        // Determine total incentive cap adjustment to reduce incentive total by
        // Use 0 if total incentive is below total incentive cap.
        Decimal totalIncentiveCapAdjustment = (totalIncentive > fiftyPercentIncentiveTotal)
                ? (-1 * (totalIncentive - fiftyPercentIncentiveTotal)).setScale(2)
                : 0;

        totalIncentive += totalIncentiveCapAdjustment;

        application.Incentive_Total__c = totalIncentive;
        subApplication.Total_Incentive__c = totalIncentive;
        subApplication.Total_Incentive_Adjustment__c = totalIncentiveCapAdjustment;
        application.Total_Incentive_Adjustment__c = totalIncentiveCapAdjustment;

        // Determine the estimated incentive total with bonus.
        if (subApplication.HPHI_Bonus__c != null) {
            subApplication.Total_Incentive__c += subApplication.HPHI_Bonus__c;
            application.Incentive_Total__c = subApplication.Total_Incentive__c;
        }

        // Calculate item incentive for each end use
        // Store the modified savings on each end use and calculate item incentive
        for (XML_End_Use__c eu : xmlEndUses) {
            eu.Gross_Kw__c = eu.End_Use_Energy_Savings_kW__c;
            //only apply kWh modifier if heated and cooled
            eu.Gross_KWH__c = heatedAndCooled
                    ? (eu.End_Use_Energy_Savings_kWh__c * kWhModifier)
                    : eu.End_Use_Energy_Savings_kWh__c;
            //always apply the therm modifier
            eu.Gross_Therms__c = eu.End_Use_Energy_Savings_therms__c * thermModifier;
            //calculate the adjusted savings percent to use in calculating item incentive
            Decimal adjustedEnergySavingsPercent = agnosticPositiveBTUSavings > 0
                    ? ((eu.Gross_KWH__c * KWH_TO_BTU) + (eu.Gross_Therms__c * THERMS_TO_BTU))
                    / agnosticPositiveBTUSavings
                    : 0;
            Decimal itemIncentiveAmount = agnosticBaseIncentive * adjustedEnergySavingsPercent;
            eu.Item_Incentive_Amount__c = itemIncentiveAmount > 0 ? itemIncentiveAmount : 0;
        }

        //create an xml end use for each of the kickers and bonuses
        XML_End_Use__c eu;

        eu = new XML_End_Use__c();
        eu.Sub_Application__c = subApplication.Id;
        eu.End_Use__c = 'AC Kicker';
        eu.Kicker__c = true;
        eu.Item_Incentive_Amount__c = acKicker;
        xmlEndUses.add(eu);

        eu = new XML_End_Use__c();
        eu.Sub_Application__c = subApplication.Id;
        eu.End_Use__c = 'Pool Pump Kicker';
        eu.Kicker__c = true;
        eu.Item_Incentive_Amount__c = poolPumpKicker;
        xmlEndUses.add(eu);

        eu = new XML_End_Use__c();
        eu.Sub_Application__c = subApplication.Id;
        eu.End_Use__c = 'KWH Kicker';
        eu.Kicker__c = true;
        eu.Item_Incentive_Amount__c = kWhkickers;
        xmlEndUses.add(eu);

        eu = new XML_End_Use__c();
        eu.Sub_Application__c = subApplication.Id;
        eu.End_Use__c = 'Therm Kicker';
        eu.Kicker__c = true;
        eu.Item_Incentive_Amount__c = thermKickers;
        xmlEndUses.add(eu);
        
        application.kW_Savings__c = subApplication.Demand_Savings_kW__c;

        upsert xmlEndUses;

        update subApplication;
        update application;

        List<HP_Building__c> listBuildings = new List<HP_Building__c>();
        List<HP_Cooling_System__c> listCoolingSystems = new List<HP_Cooling_System__c>();
        List<HP_Heating_System__c> listHeatingSystems = new List<HP_Heating_System__c>();

        if (BIGPortalAdvanceHUApplicationUtils.isContractorTaxInfoRequired(subApplication, application)) {
            throw new TaxInfoException(BIGPortalAdvanceHuApplicationUtils.TAX_INFO_REQUIRED_ERROR);
        }

        if (!BIGPortalAdvanceHUApplicationUtils.isValidEstimatedIncentive(subApplication)) {
            String msg = String.format(BIGPortalAdvanceHuApplicationUtils.ESTIMATED_INCENTIVE_TOTAL_ERROR,
                    new List<String>{subApplication.Total_Incentive__c.format()});
            throw new HPXMLException(msg);
        }

        Decimal minimumLowerLimit = BIGPortalAdvanceHUApplicationUtils.getMinimumLowerLimit(structure);
        Decimal totalEnergySavingsPercent = [
            SELECT Total_Energy_Savings_Percent__c
            FROM Sub_Application__c
            WHERE Id =: subApplication.Id].Total_Energy_Savings_Percent__c;
        if (!BIGPortalAdvanceHuApplicationUtils.isTotalEnergySavingsPercentValid(totalEnergySavingsPercent,
                minimumLowerLimit)) {
            String msg = String.format(BIGPortalAdvanceHuApplicationUtils.TOTAL_ENERGY_SAVINGS_PERCENT_ERROR,
                    new List<String>{minimumLowerLimit.round(System.RoundingMode.CEILING).format()});
            throw new TotalEnergySavingsPercentException(msg);
        }
        /*
        List<HP_Air_Infiltration_Measurement__c> listSystemIdentifiers =
        new List<HP_Air_Infiltration_Measurement__c>();
        List<HP_Insulation_Info__c> listAFI = new List<HP_Insulation_Info__c>();
        List<HP_Insulation_Info__c> listARI = new List<HP_Insulation_Info__c>();
        List<HP_Attic__c> listAttics = new List<HP_Attic__c>();
        List<HP_Foundation__c> listHPFundations = new List<HP_Foundation__c>();
        List<HP_Insulation_Info__c> listHPInsulationInfo = new List<HP_Insulation_Info__c>();
        List<HP_Frame_Floor__c> listHPFrameFloor = new List<HP_Frame_Floor__c>();
        List<HP_Modeled_Usage__c> listModeledUsage = new List<HP_Modeled_Usage__c>(); // Move above the for
        List<HP_Water_Heating__c> listWaterHeatings = new List<HP_Water_Heating__c>(); // Move above for
        List<HP_HVAC_Control__c> listHvac_Controls = new List<HP_HVAC_Control__c>(); // Move above for
        List<HP_Lighting_Group__c> listLightningGroups = new List<HP_Lighting_Group__c>(); // Move above
        List<HP_Insulation_Info__c> listInsulationInfo = new List<HP_Insulation_Info__c>(); //Move up
        List<HP_Wall__c> listHPWall = new List<HP_Wall__c>(); //Move up
        List<HP_Heat_Pump__c> listHeatPumps = new List<HP_Heat_Pump__c>(); // Move up
        List<HP_Window__c> listHpWindow = new List<HP_Window__c>(); // Move up
        List<HP_HVAC_Distribution__c> hvacDistributionList = new List<HP_HVAC_Distribution__c>();//Move up
        List<HP_Duct__c> listHPDucts = new List<HP_Duct__c>(); //Move up
        List<HP_Duct_Leakage_Measurement__c> listDuctLeakageMeasurement = new List<HP_Duct_Leakage_Measurement__c>(); // Move up
        List<HP_Pool__c> listHP_Pools = new List<HP_Pool__c>();//Move up
        List<HP_Pool_Pump__c> listPoolPumps = new List<HP_Pool_Pump__c>(); // Move up
        List<HP_Appliances_Type_Summary_Info__c> appliances = new List<HP_Appliances_Type_Summary_Info__c>(); //Move up
        List<HP_Refrigerator__c> listHpRefrigerators = new List<HP_Refrigerator__c>();
        List<HP_Ventilation_Fan__c> listHPVentilationFan = new List<HP_Ventilation_Fan__c>(); // Move up for
        List<HP_Project__c> listHP_Project = new List<HP_Project__c>(); // Move up
        List<HP_Energy_Savings_Info__c> listEnergySavingsInfo = new List<HP_Energy_Savings_Info__c>(); // Move above for
        List<HP_Fuel_Saving__c> listFuelHPSaving = new List<HP_Fuel_Saving__c>(); // Move above for
        List<HP_Measure__c> listHPMeasure = new List<HP_Measure__c>(); // Move above for
        */

        /*
        HP_Building__c thisBuilding;
        Integer index = 0;

        for (Building b: buildings) {
            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                thisBuilding = new HP_Building__c();
                thisBuilding.Address_1__c = b.Address1;
                thisBuilding.City_Municipality__c = b.CityMunicipality;
                thisBuilding.State_Code__c = b.StateCode;
                thisBuilding.Zip_Code__c = b.ZipCode;
                thisBuilding.Number_of_Residents__c = b.NumberofResidents;
                thisBuilding.Year_Built__c = b.YearBuilt;
                thisBuilding.Residential_Facility_Type__c = b.ResidentialFacilityType;
                thisBuilding.Number_of_Bedrooms__c = b.NumberOfBedrooms;
                thisBuilding.Conditioned_Floor_Area__c = b.ConditionedFloorArea;
                thisBuilding.Number_of_Stories_Above_Grade__c = b.NumberofStoriesAboveGrade;
                thisBuilding.Average_Ceiling_Height__c = b.AverageCeilingHeight;
                thisBuilding.Project_Status_Event_Type__c = b.ProjectStatusEventType;
                thisBuilding.System_Identifier__c = b.SystemIdentifier;
                thisBuilding.Sub_Application__c = subApplication.Id;

                listBuildings.add(thisBuilding);
            }

        }
        insert listBuildings;

        //heating system
        for (Building b: buildings) {
            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                if (index < listBuildings.size()) {
                    thisBuilding = listBuildings.get(index);
                }

                String primaryCoolingId;
                for (CoolingSystem cs: coolingsystems) {
                    if (cs.BuildingId == b.SystemIdentifier) {
                        HP_Cooling_System__c thisCoolingSystem = new HP_Cooling_System__c();
                        thisCoolingSystem.Fraction_Cool_Load_Served__c = cs.FractionCoolLoadServed;
                        thisCoolingSystem.Cooling_Capacity__c = cs.CoolingCapacity;
                        thisCoolingSystem.Type__c = cs.CoolingSystemType;
                        thisCoolingSystem.Fuel__c = cs.CoolingSystemFuel;
                        thisCoolingSystem.Manufacturer__c = cs.Manufacturer;
                        thisCoolingSystem.Model_Number__c = cs.ModelNumber;
                        thisCoolingSystem.Model_Year__c = cs.ModelYear;
                        thisCoolingSystem.COP__c = cs.COP;
                        thisCoolingSystem.EER__c = cs.EER;
                        thisCoolingSystem.kW_ton__c = cs.kWton;
                        thisCoolingSystem.SEER__c = cs.SEER;
                        thisCoolingSystem.AFUE__c = cs.AFUE;
                        thisCoolingSystem.HSPF__c = cs.HSPF;
                        thisCoolingSystem.System_Identifier__c = cs.SystemIdentifier;
                        thisCoolingSystem.HP_Building__c = thisBuilding.Id;
                        if(cs.isPrimary == 1)
                            primaryCoolingId = thisCoolingSystem.Id;

                        listCoolingSystems.add(thisCoolingSystem);
                        //insert thisCoolingSystem; //Move outside, replace thisCoolingSyste for listCool....
                    }
                }

                String primaryHeatingId;
                for (HeatingSystem hs: heatingsystems) {
                    if (hs.BuildingId == b.SystemIdentifier) {
                        HP_Heating_System__c thisHeatingSystem = new HP_Heating_System__c();
                        thisHeatingSystem.Capacity__c = hs.HeatingCapacity;
                        thisHeatingSystem.Fraction_Heat_Load_Served__c = hs.FractionHeatLoadServed;
                        thisHeatingSystem.AFUE__c = hs.AFUE;
                        thisHeatingSystem.COP__c = hs.COP;
                        thisHeatingSystem.HSPF__c = hs.HSPF;
                        thisHeatingSystem.Percent__c = hs.Percent;
                        thisHeatingSystem.Fuel__c = hs.HeatingSystemFuel;
                        thisHeatingSystem.Type__c = hs.Type;
                        thisHeatingSystem.Manufacturer__c = hs.Manufacturer;
                        thisHeatingSystem.Model_Number__c = hs.ModelNumber;
                        thisHeatingSystem.Model_Year__c = hs.ModelYear;
                        thisHeatingSystem.System_Identifier__c = hs.SystemIdentifier;
                        thisHeatingSystem.HP_Building__c = thisBuilding.Id;
                        if(hs.isPrimary == 1)
                            primaryHeatingId = thisHeatingSystem.Id;

                        listHeatingSystems.add(thisHeatingSystem);
                        //insert thisHeatingSystem; // Move this outside and use heatingSystems instead
                    }
                }

                if (primaryHeatingId != NULL || primaryCoolingId != NULL) {
                    if (primaryHeatingId != NULL)
                        thisBuilding.Primary_Heating_System__c = primaryHeatingId;
                    if (primaryCoolingId != NULL)
                        thisBuilding.Primary_Cooling_System__c = primaryCoolingId;

                    //update thisBuilding; // delete this and use upsert on buildings outside of for Matias.
                }

                //air infiltration measurement
                for (AirInfiltrationMeasurement aim: aims) {
                    if (aim.BuildingId == b.SystemIdentifier) {
                        HP_Air_Infiltration_Measurement__c thisAIM = new HP_Air_Infiltration_Measurement__c();
                        thisAIM.Type_Of_Infiltration_Measurement__c = aim.TypeOfInfiltrationMeasurement;
                        thisAIM.House_Pressure__c = aim.HousePressure;
                        thisAIM.Type_Of_Infiltration_Measurement__c = aim.UnitofMeasure;
                        thisAIM.Effective_Leakage_Area__c = aim.AirLeakage;
                        thisAIM.System_Identifier__c = aim.SystemIdentifier;
                        thisAIM.HP_Building__c = thisBuilding.Id;

                        listSystemIdentifiers.add(thisAIM);
                        //insert thisAIM; // Move this outside for. Matias TODO
                    }
                }

                index++;
            }
        }

        update listBuildings;
        insert listCoolingSystems;
        insert listHeatingSystems;
        //insert listSystemIdentifiers;
        */

        // HERE INSERT LIST LOADED ABOVE
        /*
        //---------------------PARENT-----------------------
        index = 0;
        for (Building b: buildings) {

            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                if (index < listBuildings.size()) {
                    thisBuilding = listBuildings.get(index);
                }
                //attic
                for (Attic att: attics) {
                    if (att.BuildingId == b.SystemIdentifier) {
                        //attic floor insulation
                        HP_Insulation_Info__c thisAFI = new HP_Insulation_Info__c();
                        thisAFI.Assembly_Effective_RValue__c = att.afiAssemblyEffectiveRValue;
                        thisAFI.Nominal_R_Value__c = att.afiNominalRValue;
                        thisAFI.System_Identifier__c = att.afiSystemIdentifier;

                        //attic roof insulation
                        HP_Insulation_Info__c thisARI = new HP_Insulation_Info__c();
                        thisARI.Assembly_Effective_RValue__c = att.ariAssemblyEffectiveRValue;
                        thisARI.Nominal_R_Value__c = att.ariNominalRValue;
                        thisARI.System_Identifier__c = att.ariSystemIdentifier;

                        listAFI.add(thisAFI);
                        listARI.add(thisARI);
                    }
                }

                for (Foundation f: foundations) {
                    if (f.BuildingId == b.SystemIdentifier) {
                        HP_Foundation__c thisF = new HP_Foundation__c();
                        thisF.System_Identifier__c = f.SystemIdentifier;
                        thisF.Type__c = f.Type;
                        thisF.HP_Building__c = thisBuilding.Id;

                        //insert thisF;

                        //frame floor insulation
                        HP_Insulation_Info__c thisFFI = new HP_Insulation_Info__c();
                        thisFFI.Assembly_Effective_RValue__c = f.AssemblyEffectiveRValue;
                        thisFFI.Nominal_R_Value__c = f.NominalRValue;
                        thisFFI.System_Identifier__c = f.FrameFloorInsulationSystemIdentifier;

                        listHPFundations.add(thisF);
                        listHPInsulationInfo.add(thisFFI);
                    }
                }

                for (HVACDistribution hd: hvacdistributions) {
                    if (hd.BuildingId == b.SystemIdentifier) {
                        HP_HVAC_Distribution__c thisHVACDist = new HP_HVAC_Distribution__c();
                        thisHVACDist.System_Identifier__c = hd.SystemIdentifier;
                        thisHVACDist.HP_Building__c = thisBuilding.Id;
                        thisHVACDIst.Conditioned_Floor_Area_Served__c = hd.ConditionedFloorAreaServed;

                        hvacDistributionList.add(thisHVACDist);
                    }
                }

                for (Pool p: pools) {
                    if (p.BuildingId == b.SystemIdentifier) {
                        HP_Pool__c thisPool = new HP_Pool__c();
                        thisPool.System_Identifier__c = p.SystemIdentifier;
                        thisPool.HP_Building__c = thisBuilding.Id;

                        listHP_Pools.add(thisPool);
                    }
                }

                //refrigerator
                for (Refrigerator r: refrigerators) {
                    if (r.BuildingId == b.SystemIdentifier) {
                        HP_Appliances_Type_Summary_Info__c thisAppliance = new HP_Appliances_Type_Summary_Info__c();
                        thisAppliance.Model_Year__c = r.ModelYear;
                        thisAppliance.System_Identifier__c = r.SystemIdentifier;

                        appliances.add(thisAppliance);
                    }
                }

                //wall
                for (WallInsulation wi: wallinsulations) {
                    if (wi.BuildingId == b.SystemIdentifier) {
                        //wall insulation
                        HP_Insulation_Info__c thisWI = new HP_Insulation_Info__c();
                        thisWI.Assembly_Effective_RValue__c = wi.AssemblyEffectiveRValue;
                        thisWI.Nominal_R_Value__c = wi.NominalRValue;
                        thisWI.System_Identifier__c = wi.SystemIdentifier;
                        listInsulationInfo.add(thisWI);
                    }
                }

                for (Project p: projects) {
                    if (p.BuildingId == b.SystemIdentifier) {
                        HP_Project__c thisProject = new HP_Project__c();
                        thisProject.Title__c = p.Title;
                        thisProject.System_Identifier__c = p.SystemIdentifier;
                        thisProject.HP_Building__c = thisBuilding.Id;
                        thisProject.Sub_Application__c = subApplication.Id;

                        listHP_Project.add(thisProject);
                    }
                }

                index++;
            }
        }

        insert listAFI;
        insert listARI;
        insert listHPFundations;
        insert listHPInsulationInfo;
        insert hvacDistributionList;
        //insert listHP_Pools;
        //insert appliances;
        insert listInsulationInfo;
        insert listHP_Project;
       //----------------------------PARENT---END---------------------------------------
       */
       //INSERT LIST HERE listAFI; listARI;

       /*
       index = 0;
       for (Building b: buildings) {
            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                if (index < listBuildings.size()) {
                    thisBuilding = listBuildings.get(index);
                }
                //attic

                for (Attic att: attics) {
                    if (att.BuildingId == b.SystemIdentifier) {
                        //attic
                        HP_Attic__c thisAttic = new HP_Attic__c();
                        thisAttic.Area__c = att.Area;
                        //thisAttic.HP_Floor_Insulation_Info__c = thisAFI.Id;
                        //thisAttic.HP_Roof_Insulation_Info__c = thisARI.Id;
                        thisAttic.System_Identifier__c = att.SystemIdentifier;
                        thisAttic.HP_Building__c = thisBuilding.Id;

                        listAttics.add(thisAttic);
                    }
                }

                index++;
            }
       }

       // can be moved to a METHOD -->GOOD
       for (Integer i = 0; i < listAttics.size(); i++) {
           listAttics.get(i).HP_Floor_Insulation_Info__c = listAFI.get(i).Id;
           listAttics.get(i).HP_Roof_Insulation_Info__c = listAri.get(i).Id;
       }
       insert listAttics;
       */
       //-------------------------------------

       // INSERT LIST HERE listAttics; listHPFundations; listHPInsulationInfo
       /*
       index = 0;
       for (Building b: buildings) {
            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {

                if (index < listBuildings.size()) {
                    thisBuilding = listBuildings.get(index);
                }

                for (Foundation f: foundations) {
                    if (f.BuildingId == b.SystemIdentifier) {
                        //frame floor
                        HP_Frame_Floor__c thisFF = new HP_Frame_Floor__c();
                        thisFF.Area__c = f.Area;
                        thisFF.System_Identifier__c = f.FrameFloorSystemIdentifier;
                        //thisFF.HP_Foundation__c = thisF.Id;
                        //thisFF.HP_Insulation_Info__c = thisFFI.Id;

                        listHPFrameFloor.add(thisFF);
                    }
                }

                //modeled usage
                for (ModeledUsage mu: modeledusages) {
                    if (mu.BuildingId == b.SystemIdentifier) {
                        HP_Modeled_Usage__c thisMU = new HP_Modeled_Usage__c();
                        thisMU.Annual_Consumption__c = mu.AnnualConsumption;
                        thisMU.Base_Load__c = mu.BaseLoad;
                        thisMU.Appliance__c = mu.Appliance;
                        thisMU.HotWater__c = mu.HotWater;
                        thisMU.Lighting__c = mu.Lighting;
                        thisMU.Other__c = mu.Other;
                        thisMU.PV__c = mu.PV;
                        thisMU.SolarThermal__c = mu.SolarThermal;
                        thisMU.Cooling__c = mu.Cooling;
                        thisMU.Heating__c = mu.Heating;
                        thisMU.Energy_Type__c = mu.EnergyType;
                        thisMU.HP_Building__c = thisBuilding.Id;

                        listModeledUsage.add(thisMU);
                        //insert thisMU; // Move outside for and use list instead
                    }
                }

                //water heating
                for (WaterHeating wh: waterheatings) {
                    if (wh.BuildingId == b.SystemIdentifier) {
                        HP_Water_Heating__c thisWH = new HP_Water_Heating__c();
                        thisWH.Fuel_Type__c = wh.FuelType;
                        thisWH.Energy_Factor__c = wh.EnergyFactor;
                        thisWH.Hot_Water_Temperature__c = wh.HotWaterTemperature;
                        thisWH.System_Identifier__c = wh.SystemIdentifier;
                        thisWH.Manufacturer__c = wh.Manufacturer;
                        thisWH.Model_Number__c = wh.ModelNumber;
                        thisWH.Model_Year__c = wh.ModelYear;
                        thisWH.Location__c = wh.Location;
                        thisWH.Tank_Volume__c = wh.TankVolume;
                        thisWH.Water_Heater_Type__c = wh.WaterHeaterType;
                        thisWH.Length_of_Pipe_Insulated__c = wh.LengthofPipeInsulated;
                        thisWH.HP_Building__c = thisBuilding.Id;

                        listWaterHeatings.add(thisWH);
                        //insert thisWH; // Move outside for, use list instead
                    }
                }

                //hvac control
                for (HVACControl hvc: hvaccontrols) {
                    if (hvc.BuildingId == b.SystemIdentifier) {
                        HP_HVAC_Control__c thisHVAC = new HP_HVAC_Control__c();
                        thisHVAC.System_Identifier__c = hvc.SystemIdentifier;
                        thisHVAC.Setpoint_Temp_Heating_Season__c = hvc.SetpointTempHeatingSeason;
                        thisHVAC.Setup_Temp_Cooling_Season__c = hvc.SetpointTempCoolingSeason;
                        thisHVAC.Control_Type__c = hvc.ControlType;
                        thisHVAC.HP_Building__c = thisBuilding.Id;

                        listHvac_Controls.add(thisHVAC);
                        //insert thisHVAC; // Move outside for, use list instead TODO
                    }
                }

                //lighting group
                for (LightingGroup lg: lightinggroups) {
                    if (lg.BuildingId == b.SystemIdentifier) {
                        HP_Lighting_Group__c thisLG = new HP_Lighting_Group__c();
                        thisLG.Average_Hours_Per_Day__c = lg.AverageHoursPerDay;
                        thisLG.System_Identifier__c = lg.SystemIdentifier;
                        thisLG.Location__c = lg.Location;
                        thisLG.Number_of_Units__c = lg.NumberofUnits;
                        thisLG.Lighting_Type__c = lg.LightingType;
                        thisLG.HP_Building__c = thisBuilding.Id;

                        listLightningGroups.add(thisLG);
                        //insert thisLG; // Outside for, use list instead
                    }
                }

                index++;
            }
       }

       //----------Maybe this can be moved out---------->GOOOOD

       for (Integer i=0; i < listHPFrameFloor.size(); i++) {
           listHPFrameFloor.get(i).HP_Foundation__c = listHPFundations.get(i).Id;
           listHPFrameFloor.get(i).HP_Insulation_Info__c = listHPInsulationInfo.get(i).Id;
       }
       insert listHPFrameFloor;
       insert listModeledUsage;

       */
       //insert listWaterHeatings;
       //insert listHvac_Controls;
       //insert listLightningGroups;
       //--------------------

       //INSERT LISTS listHPFrameFloor; listModeledUsage; listWaterHeatings; listHvac_Controls; listLightningGroups; listInsulationInfo
       /*
       index = 0;

       for (Building b: buildings) {
           if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
               if (index < listBuildings.size()) {
                   thisBuilding = listBuildings.get(0);
               }

               for (WallInsulation wi: wallinsulations) {
                    if (wi.BuildingId == b.SystemIdentifier) {
                        //wall
                        HP_Wall__c thisWall = new HP_Wall__c();
                        thisWall.Area__c = wi.Area;
                        thisWall.Type__c = wi.Type;
                        thisWall.System_Identifier__c = wi.WallSystemIdentifier;
                        //thisWall.HP_Insulation_Info__c = thisWI.Id;
                        thisWall.HP_Building__c = thisBuilding.Id;

                        listHPWall.add(thisWall);
                    }
                }

                //heat pump
                for (HeatPump hp: heatpumps) {
                    if (hp.BuildingId == b.SystemIdentifier) {
                        HP_Heat_Pump__c thisHP = new HP_Heat_Pump__c();
                        //thisHP.AFUE__c = hp.AFUEheat;
                        thisHP.System_Identifier__c = hp.SystemIdentifier;
                        thisHP.Fraction_Heat_Load_Served__c = hp.FractionHeatLoadServed;
                        thisHP.Fraction_Cool_Load_Served__c = hp.FractionCoolLoadServed;
                        thisHP.Type__c = hp.HeatPumpType;
                        thisHP.Manufacturer__c = hp.Manufacturer;
                        thisHP.Model_Number__c = hp.ModelNumber;
                        thisHP.Model_Year__c = hp.ModelYear;
                        thisHP.AFUE__c = hp.AFUEheat;
                        thisHP.COP__c = hp.COPcool;
                        thisHP.COP_Heating__c = hp.COPheat;
                        thisHP.EER__c = hp.EERcool;
                        thisHP.HSPF__c = hp.HSPFcool;
                        thisHP.kW_ton__c = hp.kWtoncool;
                        thisHP.SEER__c = hp.SEERcool;
                        thisHP.HP_Building__c = thisBuilding.Id;

                        //no equivalent
                        //public Decimal AFUEcool;
                        //public Decimal EERheat;
                        //public Decimal SEERheat;
                        //not found
                        //public Decimal HSPFheat;
                        //public Decimal kWtonheat;
                        //public String AnnualEfficiencyType;

                        listHeatPumps.add(thisHP);
                        //insert thisHP; // Move outside for, use list instead
                    }
                }

                //window
                for (Window w: windows) {
                    if (w.BuildingId == b.SystemIdentifier) {
                        HP_Window__c thisW = new HP_Window__c();
                        thisW.Area__c = w.Area;
                        thisW.Frame_Type__c = w.FrameType;
                        thisW.SHGC__c = w.SHGC;
                        thisW.UFactor__c = w.UFactor;
                        thisW.System_Identifier__c = w.SystemIdentifier;
                        thisW.HP_Building__c = thisBuilding.Id;

                        listHpWindow.add(thisW);
                        //insert thisW; // Move outside, use list instead
                    }
                }

                index++;
           }
       }
       //Maybe this can be moved later------->GOOD
       for (Integer i = 0; i < listHPWall.size(); i++) {
           listHPWall.get(i).HP_Insulation_Info__c = listInsulationInfo.get(i).Id;
       }
       //insert listHPWall;
       //insert listHeatPumps;
       insert listHpWindow;
       //---------------------------------------------

       //INSERT LISTS listHPWall; listHeatPumps; listHpWindow; hvacDistributionList
       index = 0;
       HP_HVAC_Distribution__c thisHVACDist;
       for (Building b: buildings) {
            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                for (HVACDistribution hd: hvacdistributions) {
                    if (hd.BuildingId == b.SystemIdentifier) {
                        thisHVACDist = hvacDistributionList.get(index);
                        for (Duct d: ducts) {
                            if (d.SystemIdentifier == hd.SystemIdentifier) {
                                HP_Duct__c thisDuct = new HP_Duct__c();
                                thisDuct.Insulation_RValue__c = d.DuctInsulationRValue;
                                thisDuct.Location__c = d.DuctLocation;
                                thisDuct.Fraction_Duct_Area__c = d.FractionDuctArea;
                                thisDuct.HP_HVAC_Distribution__c = thisHVACDIst.Id;

                                listHPDucts.add(thisDuct);
                                //insert thisDuct; // Move outside, use list
                            }
                        }

                        //duct leakage measurement
                        for (DuctLeakageMeasurement dlm: ductleakagemeasurements) {
                            if (dlm.SystemIdentifier == hd.SystemIdentifier) {
                                HP_Duct_Leakage_Measurement__c thisDLM = new HP_Duct_Leakage_Measurement__c();
                                thisDLM.Duct_Leakage__c = String.valueOf(dlm.DuctLeakageValue) + ' ' + dlm.DuctLeakageUnits;
                                thisDLM.HP_HVAC_Distribution__c = thisHVACDIst.Id;

                                listDuctLeakageMeasurement.add(thisDLM);

                                //insert thisDLM; // Move outside for, use list
                            }
                        }
                        index++;
                    }
                }
           }
       }
       insert listHPDucts;
       insert listDuctLeakageMeasurement;
       */

       // INSERT listHPDucts; listDuctLeakageMeasurement

       //INSERT listHP_Pools
       /*
       index = 0;
       HP_Pool__c thisPool;
       for (Building b: buildings) {
            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                for (Pool p: pools) {
                    if (p.BuildingId == b.SystemIdentifier) {
                        //pool pump
                        thisPool = listHP_Pools.get(index);
                        for (PoolPump pp: poolpumps) {
                            if (p.SystemIdentifier == pp.PoolSystemIdentifier) {
                                HP_Pool_Pump__c thisPP = new HP_Pool_Pump__c();
                                thisPP.Hours_Per_Day__c = pp.HoursPerDay;
                                thisPP.Rated_Horsepower__c = pp.RatedHorsepower;
                                thisPP.Speed_Setting__c = pp.SpeedSetting;
                                thisPP.Pump_Speed_Power__c = pp.PumpSpeedPower;
                                thisPP.System_Identifier__c = pp.SystemIdentifier;
                                thisPP.Type__c = pp.Type;
                                thisPP.HP_Pool__c = thisPool.Id;

                                listPoolPumps.add(thisPP);

                                //insert thisPP; // Outside for, use list instead
                            }
                        }
                        index++;
                    }
                }

            }
       }
       insert listPoolPumps;
       */

       /*
       // INSERT LISTS listPoolPumps; appliances; see a way to handle thisAppliance;
       index = 0;
       for (Building b: buildings) {
            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                if (index < listBuildings.size()) {
                    thisBuilding = listBuildings.get(index);
                }
                for (Refrigerator r: refrigerators) {
                    if (r.BuildingId == b.SystemIdentifier) {

                        HP_Refrigerator__c thisRef = new HP_Refrigerator__c();
                        thisRef.Primary_Indicator__c = r.PrimaryIndicator;
                        //thisRef.HP_Appliances_Type_Summary_Info__c = thisAppliance.Id;
                        thisRef.HP_Building__c = thisBuilding.Id;

                        listHpRefrigerators.add(thisRef);
                    }
                }

                //ventilation
                for (VentilationFan vf: ventilationfans) {
                    if (vf.BuildingId == b.SystemIdentifier) {
                        HP_Ventilation_Fan__c thisVF = new HP_Ventilation_Fan__c();
                        thisVF.Used_For_Whole_Building_Ventilation__c = vf.UsedForWholeBuildingVentilation;
                        thisVF.Used_For_Seasonal_Cooling_Load_Reduction__c = vf.UsedForSeasonalCoolingLoadReduction;
                        thisVF.System_Identifier__c = vf.SystemIdentifier;
                        thisVF.HP_Building__c = thisBuilding.Id;

                        listHPVentilationFan.add(thisVF);

                        //insert thisVF;// outside for, use list instead
                    }
                }

                index++;
            }
       }
       //Maybe it can be moved later----------------------------
       for (Integer i = 0; i < listHpRefrigerators.size(); i++) {
           listHpRefrigerators.get(i).HP_Appliances_Type_Summary_Info__c = appliances.get(i).Id;
       }
       insert listHpRefrigerators;
       insert listHPVentilationFan;
       //----------------------------------------
       //INSERT listHpRefrigerators; listHPVentilationFan; listHP_Project; how to handle thisProject
       */

       /*
       //INSERT listEnergySavingsInfo; how to handle thisESI
       for (Building b: buildings) {
           if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
               for (Project p: projects) {
                   if (p.BuildingId == b.SystemIdentifier) {
                       HP_Energy_Savings_Info__c thisESI = new HP_Energy_Savings_Info__c();
                       //thisESI.HP_Project__c = thisProject.Id;

                       listEnergySavingsInfo.add(thisESI);

                   }
               }
           }
       }

       //----------------maybe it can be moved-----------GOOOOD
       for (Integer i = 0; i < listEnergySavingsInfo.size(); i++) {
           listEnergySavingsInfo.get(i).HP_Project__c = listHP_Project.get(i).Id;
       }
       insert listEnergySavingsInfo;
       //----------------------------------------------------

       index = 0;
       HP_Energy_Savings_Info__c thisESI;
       for (Building b: buildings) {
            if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                for (Project p: projects) {
                    if (p.BuildingId == b.SystemIdentifier) {
                        //fuel savings
                        thisESI = listEnergySavingsInfo.get(index);
                        for (FuelSavings fs: fuelsavings) {
                            if (fs.ProjectId == 'p.SystemIdentifier') {
                                HP_Fuel_Saving__c thisFS = new HP_Fuel_Saving__c();
                                thisFS.Fuel__c = fs.EndUseFuel;
                                thisFS.Units__c = fs.EndUseUnits;
                                if (fs.EndUse == 'Appliance') {
                                    thisFS.Appliance__c = fs.EndUseValue;
                                }
                                else if (fs.EndUse == 'Cooling') {
                                    thisFS.Cooling__c = fs.EndUseValue;
                                }
                                else if (fs.EndUse == 'Heating') {
                                    thisFS.Heating__c = fs.EndUseValue;
                                }
                                else if (fs.EndUse == 'HotWater') {
                                    thisFS.HotWater__c = fs.EndUseValue;
                                }
                                else if (fs.EndUse == 'Lighting') {
                                    thisFS.Lighting__c = fs.EndUseValue;
                                }
                                else if (fs.EndUse == 'Other') {
                                    thisFS.Other__c = fs.EndUseValue;
                                }
                                else if (fs.EndUse == 'SolarThermal') {
                                    thisFS.SolarThermal__c = fs.EndUseValue;
                                }
                                thisFS.HP_Energy_Savings_Info__c = thisESI.Id;

                                listFuelHPSaving.add(thisFS);
                                //insert thisFS; // Move after for, use list instead
                            }
                        }

                        //measure
                        for (Measure measure: measures) {
                            HP_Measure__c thisMeasure = new HP_Measure__c();
                            thisMeasure.Measure_Description__c = measure.MeasureDescription;
                            thisMeasure.System_Identifier__c = measure.SystemIdentifier;
                            //thisMeasure.HP_Project__c = thisProject.Id;

                            listHPMeasure.add(thisMeasure);

                            //insert thisMeasure; // Move after for, use list instead
                        }
                        index++;
                    }
                }


            }
        }

        //--------------------Maybe it can be moved later-----------

        //------------------------

        //-------Maybe move this to a method------------------------------------GOOD
        for (HP_Project__c thisProject : listHP_Project) {
            for (HP_Measure__c thisMeasure : listHPMeasure) {
                thisMeasure.HP_Project__c = thisProject.Id;
            }
        }
        insert listFuelHPSaving;
        insert listHPMeasure;
        //------------------------------------------------------

        //INSERT listFuelHPSaving; listHPMeasure
        */

        /*
        //xml transaction header info
        HP_XML_Transaction_Header_Information__c thisXMLHeaderInfo = new HP_XML_Transaction_Header_Information__c();
        thisXMLHeaderInfo.XML_Generated_By__c = xmltransactionheaderinfo.XMLGeneratedBy;
        thisXMLHeaderInfo.Sub_Application__c = subApplication.Id;

        insert thisXMLHeaderInfo;
        */

    }

    public class TaxInfoException extends Exception {}
    public class HPXMLException extends Exception {}
    public class TotalEnergySavingsPercentException extends Exception {}

}