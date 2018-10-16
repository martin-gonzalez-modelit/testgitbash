/**
 * Data Model for holding and analyzing EnergyPro XML used in Advanced Home Upgrade Applications.
 *
 * @author Anna Woodall, RedTeal Inc. <admin@redteal.com>
 * @since 2014-09
 */
 public with sharing class EnergyProXML {

    //set by parser
    public Boolean isPostApplication                    {get; set; }
    public String SoftwareVersion                       {get; set; }

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
    
    //inner wrapper classes
    public Project project                              {get; set; }
    public List<Appliance> appliances                   {get; set; }
    public List<Plant> plants                           {get; set; }
    public List<Result> results                         {get; set; }
    public List<Improvements> improvements              {get; set; }
    private Summary summary;
    
    //maps storing individual end use values by type
    private Map<String, Decimal[]> endUsePreValues;
    private Map<String, Decimal[]> endUsePostValues;

    //database records
    private Application__c application;
    private Sub_Application__c subApplication;
    private List<XML_Result__c> xmlResults;
    private List<XML_End_Use__c> xmlEndUses;

    
    //-- Constructor
    public EnergyProXML(Application__c app, Sub_Application__c subApp, Boolean isPostApp) {
        
        application = app;
        subApplication = subApp;
        isPostApplication = isPostApp;

        //update the Sub-Application RecordType
        Id preAppRTId = BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_PRE_RECORD_TYPE_ID;
        Id postAppRTId = BIGPortalAdvanceHUApplicationUtils.EP_SUBAPP_POST_RECORD_TYPE_ID;
        if (preAppRTId != null && postAppRTId != null) {
            subApplication.RecordTypeId = isPostApplication ? postAppRTId : preAppRTId;
        }

        try { //upsert to insert records/modifications FROM portal
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
        appliances = new List<Appliance>();
        plants = new List<Plant>();
        results = new List<Result>();
        improvements = new List<Improvements>();

        //initialize maps for end uses
        endUsePreValues = new Map<String, Decimal[]>();
        endUsePostValues = new Map<String, Decimal[]>();
    }

    //inner classes to store data models
    public class Project {
        public String CAZone;
        public String PlanName;
        public String Address;
        public String City;
        public String State;
        public String Zip;
        public String Name;
        public String Company;
        public String BuildingType;
        public String ConditionedFloorArea;
        public String NumberOfDwellingUnits;
        public String Stories;
        
        //Building Retrofit
        public String Occupants;
        public String FoundationType;
    }
    
    public class Appliance {
        public String PoolType;
        public String SpaType;
    }
    
    public class Plant {
        //Water Heating
        public String Name;
        public String DHWType;

        public List<HVAC> HVACs = new List<HVAC>();
    }
        
    public class HVAC {
        public String HVACSystemType;
        public String HeatingHVACType;
        public String CoolingHVACType;
        public String ExistCFM50;
        public String ExistSLA;
        public String Thermostat;
        public String DuctRValue;
        public String DuctLocation;
        public String DuctStatus;
        public String Flow;
        public String EER;
        
        //Existing Distribution
        public String DuctLeakageCFM25;
        public String AtticInsulR;
        
        public List<Zone> zones = new List<Zone>();
    }
    
    public class Zone {
        public String ZoneType;
        public String FloorNo;
        
        public List<Room> rooms = new List<Room>();
    }
    
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

    public class Result {
        public String ResultType;
        public String GasUseTherms;
        public String ElectricityUsekWh;
        public String ElectricityAvgkW;
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
        
        public List<AlternativeDescription> alternativeDescriptions = new List<AlternativeDescription>();
    }

    public class AlternativeDescription {
        public String Label;
        public String Value;
        public String Units;
    }

    public class Improvements {
        public String ImprovementCategory;
        public String ImprovementName;
        public String ImprovementAmount;
        public String ImprovementAction;

        public List<ImprovementValues> improvementValues = new List<ImprovementValues>();
    }

    public class ImprovementValues {
        public String Characteristic;
        public String InitialValue;
        public String FinalValue;
    }

    public class Summary {
        public String ThermostatType;
        public String YearBuilt;
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
        public Decimal InitialElectricityUsekW = 0;
        public Decimal PostUpgradeElectricityUsekW = 0;
        public Decimal InitialElectricityUsekWh = 0;
        public Decimal PostUpgradeElectricityUsekWh = 0;
        public Decimal InitialGasUseTherms = 0;
        public Decimal PostUpgradeGasUseTherms = 0;
        public Decimal TotalEnergySavingskW = 0;
        public Decimal TotalEnergySavingskWh = 0;
        public Decimal TotalEnergySavingsTherms = 0;
        public Decimal TotalEnergySavingsPercent = 0;
        public Boolean PostUpgradeCoolingPresent;
        
        public InitialElectricUse initialElectric = new InitialElectricUse();
        public InitialGasUse initialGas = new InitialGasUse();
        public ImprovedElectricUse improvedElectric = new ImprovedElectricUse();
        public ImprovedGasUse improvedGas = new ImprovedGasUse();
        public ElectricSavings electricSavings = new ElectricSavings();
        public GasSavings gasSavings = new GasSavings();
        public Decimal TotalEnergySavingsPercentFromIndividualValues = 0;
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
        
        summary = new Summary();

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
        
        //-- Evaluate Appliances
        for (Appliance app : appliances) {
            //get pool type and spa type (usually attributes of same node)
            if (String.isNotEmpty(app.PoolType)) {
                summary.PoolType = app.PoolType;
            }
            if (String.isNotEmpty(app.SpaType)) {
                summary.SpaType = app.SpaType;
            }
        }

        //-- Evaluate Plants (usually only one plant)
        for (Plant plant : plants) {
            //-- Evaluate HVACs
            for (HVAC hvac : plant.HVACs) {
                //add to running total of HVACs
                totalHVACs++;
                //evaluate thermostat type
                if (hvac.Thermostat == 'Setback') {
                    setback++;
                }
                else if (hvac.Thermostat == 'NoSetback') {
                    noSetback++;
                }
                //get this hvacs duct r value and add to running total
                Decimal hvacDuctRValue = 0;
                if (hvac.DuctRValue != null && Decimal.valueOf(hvac.DuctRValue) > 0) {
                    hvacDuctRValue = Decimal.valueOf(hvac.DuctRValue);
                    summary.TotalDuctRValue += Decimal.valueOf(hvac.DuctRValue);
                }
                //add to running total of initial blower door results
                if (String.isNotEmpty(hvac.ExistCFM50)) {
                    summary.InitialBlowerDoorResults += Decimal.valueOf(hvac.ExistCFM50);
                }
                //add to running total of initial duct test results
                if (String.isNotEmpty(hvac.DuctLeakageCFM25)) {
                    summary.InitialDuctTestResults += Decimal.valueOf(hvac.DuctLeakageCFM25);
                }
                //evaluate initial heating fuel type
                if (hvac.HeatingHVACType == 'GasFurnace') {
                    gasHeat++;
                }
                else if (hvac.HeatingHVACType == 'ElectricHeatPump' || hvac.HeatingHVACType == ELECTRIC_RESISTANCE) {
                    electricHeat++;
                }
                else if (hvac.HeatingHVACType == NONE) {
                    noHeat++;
                }
                else if (hvac.HeatingHVACType == 'HotWater') {
                    if (plant.DHWType == GASFIRED) {
                        gasHeat++;
                    }
                    else if (plant.DHWType == ELECTRIC_RESISTANCE || plant.DHWType == HEATPUMP) {
                        electricHeat++;
                    }
                }
                //evaluate hot water fuel type
                if (plant.DHWType == GASFIRED) {
                    gasWater++;
                }
                else if (plant.DHWType == HEATPUMP || plant.DHWType == ELECTRIC_RESISTANCE) {
                    electricWater++;
                }

                Decimal TotalVolumeByHVAC = 0; //used to track the total volume of current HVAC

                //-- Evaluate Zones
                for (Zone zone : hvac.zones) {
                    //-- Evaluate Rooms
                    for (Room rm : zone.rooms) {
                        if (String.isNotEmpty(rm.NBedrooms)) {
                            //add to running total
                            summary.TotalBedrooms += Integer.valueOf(rm.NBedrooms);
                        }
                        if (String.isNotEmpty(rm.YearBuilt)) {
                            //evaluate if this is the earliest value for YearBuilt
                            if (summary.YearBuilt == null || Integer.valueOf(summary.YearBuilt) > Integer.valueOf(rm.YearBuilt)) {
                                summary.YearBuilt = rm.YearBuilt;
                            }
                        }
                        if (
                            String.isNotEmpty(rm.CeilingHeight) && Decimal.valueOf(rm.CeilingHeight) > 0 &&
                            String.isNotEmpty(rm.FloorArea) && Decimal.valueOf(rm.FloorArea) > 0
                        ) {
                            summary.TotalCeilingHeight += Decimal.valueOf(rm.CeilingHeight);
                            summary.TotalRoomArea += Decimal.valueOf(rm.FloorArea);
                            summary.TotalVolume += (Decimal.valueOf(rm.FloorArea) * Decimal.valueOf(rm.CeilingHeight));
                            //add to running total volume for the current HVAC
                            TotalVolumeByHVAC += (Decimal.valueOf(rm.FloorArea) * Decimal.valueOf(rm.CeilingHeight));
                        }

                        //-- Evaluate Insulations
                        for (Insulation insul : rm.insulations) {
                            if (
                                String.isNotEmpty(insul.UFactor) && Decimal.valueOf(insul.UFactor) > 0 &&
                                String.isNotEmpty(insul.Area) && Decimal.valueOf(insul.Area) > 0
                            ) {
                                //track floor area
                                if (insul.SurfaceType == 'Floor' || insul.SurfaceType == 'Slab') {
                                    summary.TotalFloorUFactor += Decimal.valueOf(insul.UFactor);
                                    summary.TotalFloorArea += Decimal.valueOf(insul.Area);
                                    summary.TotalFloorUFactorByArea += (Decimal.valueOf(insul.UFactor) * Decimal.valueOf(insul.Area));
                                }
                                //track ceiling area
                                else if (insul.SurfaceType == 'Roof') {
                                    summary.TotalRoofUFactor += Decimal.valueOf(insul.UFactor);
                                    summary.TotalRoofArea += Decimal.valueOf(insul.Area);
                                    summary.TotalRoofUFactorByArea  += (Decimal.valueOf(insul.UFactor) * Decimal.valueOf(insul.Area));
                                }
                                //track wall area
                                else if (insul.SurfaceType == 'Wall') {
                                    summary.TotalWallUFactor += Decimal.valueOf(insul.UFactor);
                                    summary.TotalWallArea += Decimal.valueOf(insul.Area);
                                    summary.TotalWallUFactorByArea  += (Decimal.valueOf(insul.UFactor) * Decimal.valueOf(insul.Area));
                                }
                            }
                            //-- Evaluate Fenestrations
                            for (Fenestration f : insul.fenestrations) {
                                if (
                                    String.isNotEmpty(f.UFactor) && Decimal.valueOf(f.UFactor) > 0 &&
                                    String.isNotEmpty(f.Area) && Decimal.valueOf(f.Area) > 0
                                ) {
                                    //track window area
                                    summary.TotalWindowUFactor += Decimal.valueOf(f.UFactor);
                                    summary.TotalWindowArea += Decimal.valueOf(f.Area);
                                    summary.TotalWindowUFactorByArea  += (Decimal.valueOf(f.UFactor) * Decimal.valueOf(f.Area));
                                }
                            }
                        }
                    }
                }
                //add current HVACs duct insulation r factor value by volume to running total
                summary.TotalDuctRValueByVolume += hvacDuctRValue * TotalVolumeByHVAC;
            }
        }

        //determine thermostat type
        if (setback == 0 && noSetback > 0) {
            summary.ThermostatType = 'No Setback';
        }
        else if (noSetback == 0 && setback > 0) {
            summary.ThermostatType = 'Setback';
        }

        //get the average duct R value weighted by total volume of all rooms
        if (summary.TotalDuctRValueByVolume != 0 && summary.TotalVolume != 0) {
            summary.AvgDuctRValue = summary.TotalDuctRValueByVolume / summary.TotalVolume;
        }

        //get the average ceiling height
        if (summary.TotalVolume != 0 && summary.TotalRoomArea != 0) {
            summary.AvgCeilingHeight = summary.TotalVolume / summary.TotalRoomArea;
        }

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

        //determine initial heating fuel type
        if (gasHeat > 0) {
            if (electricHeat > 0) {
                summary.InitialHeatingFuel = MIXED;
            }
            else { //no electric hvacs
                summary.InitialHeatingFuel = GAS;
            }
        }
        else { //no gas hvacs
            if (electricHeat > 0) {
                summary.InitialHeatingFuel = ELECTRIC;
            }
            else { //no gas and no electric hvacs
                if (totalHVACs == 1 && noHeat == 1) {
                    summary.InitialHeatingFuel = NONE;
                }
                else { //more than one unknown hvac type
                    summary.InitialHeatingFuel = UNKNOWN;
                }
            }
        }

        //determine initial hot water fuel type
        if (gasWater > 0) {
            if (electricWater > 0) {
                summary.InitialHotWaterFuel = MIXED;
            }
            else { //no electric heating
                summary.InitialHotWaterFuel = GAS;
            }
        }
        else {
            if (electricWater > 0) {
                summary.InitialHotWaterFuel = ELECTRIC;
            }
            else { //no gas and no electric heating
                summary.InitialHotWaterFuel = UNKNOWN;
            }
        }

        //-- Evaluate Results
        if (results.size() > 0) {

            Result improvementResult = null; //store the result holding the final improvement values

            for (Result r : results) {
                //get kw conversion factor
                Decimal ElectricityAvgkW = Decimal.valueOf(r.ElectricityAvgkW);
                Decimal ElectricityUsekWh = Decimal.valueOf(r.ElectricityUsekWh);
                Decimal kWconversion = ElectricityUsekWh != 0 ? ElectricityAvgkW / ElectricityUsekWh : 0;

                //save the latest qualifying result as the improvement results
                if (r.ResultType != TEST_IN_HOME && r.ResultType != 'Test out' && r.ResultType != 'Improved') {
                    improvementResult = r;
                }

                //get 'Test In Home' results
                if (r.ResultType == TEST_IN_HOME) {

                    //map initial values by end use and array of values (kW, kWh, therms)
                    //base load should include pump an ancillary end uses
                    endUsePreValues.put(
                        'Base Load', new Decimal[] {
                            (Decimal.valueOf(r.Appliances) + Decimal.valueOf(r.Ancillary) + Decimal.valueOf(r.Pumps)) * kWconversion,
                            Decimal.valueOf(r.Appliances) + Decimal.valueOf(r.Ancillary) + Decimal.valueOf(r.Pumps),
                            Decimal.valueOf(r.GasAppliances) + Decimal.valueOf(r.GasAncillary) + Decimal.valueOf(r.GasPumps)
                        }
                    );
                    endUsePreValues.put(
                        'Cooling',
                        new Decimal[] {
                            Decimal.valueOf(r.Cooling) * kWconversion,
                            Decimal.valueOf(r.Cooling),
                            Decimal.valueOf(r.GasCooling)
                        }
                    );
                    endUsePreValues.put(
                        'Fans',
                        new Decimal[] {
                            Decimal.valueOf(r.Fans) * kWconversion,
                            Decimal.valueOf(r.Fans),
                            Decimal.valueOf(r.GasFans)
                        }
                    );
                    endUsePreValues.put(
                        'Heating',
                        new Decimal[] {
                            Decimal.valueOf(r.Heating) * kWconversion,
                            Decimal.valueOf(r.Heating),
                            Decimal.valueOf(r.GasHeating)
                        }
                    );
                    endUsePreValues.put(
                        'Water Heating',
                        new Decimal[] {
                            Decimal.valueOf(r.WaterHeating) * kWconversion,
                            Decimal.valueOf(r.WaterHeating),
                            Decimal.valueOf(r.GasWaterHeating)
                        }
                    );
                    //lighting should include both indoor and outdoor lighting
                    endUsePreValues.put(
                        'Lighting',
                        new Decimal[] {
                            (Decimal.valueOf(r.IndoorLighting) + Decimal.valueOf(r.OutdoorLighting)) * kWconversion,
                            Decimal.valueOf(r.IndoorLighting) + Decimal.valueOf(r.OutdoorLighting),
                            Decimal.valueOf(r.GasIndoorLighting) + Decimal.valueOf(r.GasOutdoorLighting)
                        }
                    );

                    //store initial values
                    summary.InitialElectricityUsekW = ElectricityAvgkW;
                    summary.InitialElectricityUsekWh = ElectricityUsekWh;
                    summary.InitialGasUseTherms = Decimal.valueOf(r.GasUseTherms);

                    //store individual values and total for initial electric use
                    summary.InitialElectric.Heating = Decimal.valueOf(r.Heating);
                    summary.InitialElectric.Total += Decimal.valueOf(r.Heating);
                    summary.InitialElectric.Cooling = Decimal.valueOf(r.Cooling);
                    summary.InitialElectric.Total += Decimal.valueOf(r.Cooling);
                    summary.InitialElectric.WaterHeating = Decimal.valueOf(r.WaterHeating);
                    summary.InitialElectric.Total += Decimal.valueOf(r.WaterHeating);
                    summary.InitialElectric.Appliances = Decimal.valueOf(r.Appliances);
                    summary.InitialElectric.Total += Decimal.valueOf(r.Appliances);
                    summary.InitialElectric.Ancillary = Decimal.valueOf(r.Ancillary);
                    summary.InitialElectric.Total += Decimal.valueOf(r.Ancillary);
                    summary.InitialElectric.IndoorLighting = Decimal.valueOf(r.IndoorLighting);
                    summary.InitialElectric.Total += Decimal.valueOf(r.IndoorLighting);
                    summary.InitialElectric.Pumps = Decimal.valueOf(r.Pumps);
                    summary.InitialElectric.Total += Decimal.valueOf(r.Pumps);
                    summary.InitialElectric.Fans = Decimal.valueOf(r.Fans);
                    summary.InitialElectric.Total += Decimal.valueOf(r.Fans);
                    summary.InitialElectric.OutdoorLighting = Decimal.valueOf(r.OutdoorLighting);
                    summary.InitialElectric.Total += Decimal.valueOf(r.OutdoorLighting);
                    summary.InitialElectric.Renewables = Decimal.valueOf(r.Renewables);
                    summary.InitialElectric.Total += Decimal.valueOf(r.Renewables);

                    //store individual values and total for initial gas use
                    summary.initialGas.GasHeating = Decimal.valueOf(r.GasHeating);
                    summary.initialGas.Total += Decimal.valueOf(r.GasHeating);
                    summary.initialGas.GasCooling = Decimal.valueOf(r.GasCooling);
                    summary.initialGas.Total += Decimal.valueOf(r.GasCooling);
                    summary.initialGas.GasWaterHeating = Decimal.valueOf(r.GasWaterHeating);
                    summary.initialGas.Total += Decimal.valueOf(r.GasWaterHeating);
                    summary.initialGas.GasAppliances = Decimal.valueOf(r.GasAppliances);
                    summary.initialGas.Total += Decimal.valueOf(r.GasAppliances);
                    summary.initialGas.GasAncillary = Decimal.valueOf(r.GasAncillary);
                    summary.initialGas.Total += Decimal.valueOf(r.GasAncillary);
                    summary.initialGas.GasIndoorLighting = Decimal.valueOf(r.GasIndoorLighting);
                    summary.initialGas.Total += Decimal.valueOf(r.GasIndoorLighting);
                    summary.initialGas.GasPumps = Decimal.valueOf(r.GasPumps);
                    summary.initialGas.Total += Decimal.valueOf(r.GasPumps);
                    summary.initialGas.GasFans = Decimal.valueOf(r.GasFans);
                    summary.initialGas.Total += Decimal.valueOf(r.GasFans);
                    summary.initialGas.GasOutdoorLighting = Decimal.valueOf(r.GasOutdoorLighting);
                    summary.initialGas.Total += Decimal.valueOf(r.GasOutdoorLighting);
                    summary.initialGas.GasRenewables = Decimal.valueOf(r.GasRenewables);
                    summary.initialGas.Total += Decimal.valueOf(r.GasRenewables);
                }

                //evaluate water results
                if (r.ResultType == 'WaterHeater') {
                    waterResults = true;
                    //check alternative descriptions for gas or electric type
                    for (AlternativeDescription alt : r.alternativeDescriptions) {
                        if (alt.Label == 'Type') {
                            if (alt.Value == GAS_FIRED) {
                                gasWaterAlts++;
                            }
                            else if (alt.Value == 'Electric Res' || alt.Value == HEAT_PUMP) {
                                electricWaterAlts++;
                            }
                        }
                    }
                }

                //-- Evaluate AlternativeDescriptions
                for (AlternativeDescription alt : r.alternativeDescriptions) {
                    //determine PostUpgradeBlowerDoorResults
                    if (alt.Label == 'Leakage Rate at 50 Pascals') {
                        summary.PostUpgradeBlowerDoorResults = (Decimal.valueOf(alt.Value) * totalHVACs);
                    }
                    //determine PostUpgradeDuctTestResults
                    if (alt.Label == 'Leakage Rate at 25 Pascals') {
                        summary.PostUpgradeDuctTestResults = (Decimal.valueOf(alt.Value) * totalHVACs);
                    }
                    //evaluate heating alternative descriptions
                    if (alt.Label == 'Heating') {
                        heatingAlts++;
                    }
                }
            }

            //store individual values and total for improved electric use
            summary.improvedElectric.Heating = Decimal.valueOf(improvementResult.Heating);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.Heating);
            summary.improvedElectric.Cooling = Decimal.valueOf(improvementResult.Cooling);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.Cooling);
            summary.improvedElectric.WaterHeating = Decimal.valueOf(improvementResult.WaterHeating);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.WaterHeating);
            summary.improvedElectric.Appliances = Decimal.valueOf(improvementResult.Appliances);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.Appliances);
            summary.improvedElectric.Ancillary = Decimal.valueOf(improvementResult.Ancillary);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.Ancillary);
            summary.improvedElectric.IndoorLighting = Decimal.valueOf(improvementResult.IndoorLighting);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.IndoorLighting);
            summary.improvedElectric.Pumps = Decimal.valueOf(improvementResult.Pumps);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.Pumps);
            summary.improvedElectric.Fans = Decimal.valueOf(improvementResult.Fans);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.Fans);
            summary.improvedElectric.OutdoorLighting = Decimal.valueOf(improvementResult.OutdoorLighting);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.OutdoorLighting);
            summary.improvedElectric.Renewables = Decimal.valueOf(improvementResult.Renewables);
            summary.improvedElectric.Total += Decimal.valueOf(improvementResult.Renewables);

            //store individual values and total for improved gas use
            summary.improvedGas.GasHeating = Decimal.valueOf(improvementResult.GasHeating);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasHeating);
            summary.improvedGas.GasCooling = Decimal.valueOf(improvementResult.GasCooling);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasCooling);
            summary.improvedGas.GasWaterHeating = Decimal.valueOf(improvementResult.GasWaterHeating);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasWaterHeating);
            summary.improvedGas.GasAppliances = Decimal.valueOf(improvementResult.GasAppliances);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasAppliances);
            summary.improvedGas.GasAncillary = Decimal.valueOf(improvementResult.GasAncillary);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasAncillary);
            summary.improvedGas.GasIndoorLighting = Decimal.valueOf(improvementResult.GasIndoorLighting);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasIndoorLighting);
            summary.improvedGas.GasPumps = Decimal.valueOf(improvementResult.GasPumps);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasPumps);
            summary.improvedGas.GasFans = Decimal.valueOf(improvementResult.GasFans);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasFans);
            summary.improvedGas.GasOutdoorLighting = Decimal.valueOf(improvementResult.GasOutdoorLighting);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasOutdoorLighting);
            summary.improvedGas.GasRenewables = Decimal.valueOf(improvementResult.GasRenewables);
            summary.improvedGas.Total += Decimal.valueOf(improvementResult.GasRenewables);

            //get the final result values (values referenced in the last of the results)
            Result fr = results[results.size() - 1];

            //get kw conversion factor
            Decimal ElectricityAvgkW = Decimal.valueOf(fr.ElectricityAvgkW);
            Decimal ElectricityUsekWh = Decimal.valueOf(fr.ElectricityUsekWh);
            Decimal kWconversion = ElectricityUsekWh != 0 ? ElectricityAvgkW / ElectricityUsekWh : 0;

            //map initial values by end use and array of values (kW, kWh, therms)
            //base load should include pump an ancillary end uses
            endUsePostValues.put(
                'Base Load',
                new Decimal[] {
                    (Decimal.valueOf(fr.Appliances) + Decimal.valueOf(fr.Ancillary) + Decimal.valueOf(fr.Pumps)) * kWconversion,
                    Decimal.valueOf(fr.Appliances) + Decimal.valueOf(fr.Ancillary) + Decimal.valueOf(fr.Pumps),
                    Decimal.valueOf(fr.GasAppliances) + Decimal.valueOf(fr.GasAncillary) + Decimal.valueOf(fr.GasPumps)
                }
            );
            endUsePostValues.put(
                'Cooling',
                new Decimal[] {
                    Decimal.valueOf(fr.Cooling) * kWconversion,
                    Decimal.valueOf(fr.Cooling),
                    Decimal.valueOf(fr.GasCooling)
                }
            );
            endUsePostValues.put(
                'Fans',
                new Decimal[] {
                    Decimal.valueOf(fr.Fans) * kWconversion,
                    Decimal.valueOf(fr.Fans),
                    Decimal.valueOf(fr.GasFans)
                }
            );
            endUsePostValues.put(
                'Heating',
                new Decimal[] {
                    Decimal.valueOf(fr.Heating) * kWconversion,
                    Decimal.valueOf(fr.Heating),
                    Decimal.valueOf(fr.GasHeating)
                }
            );
            endUsePostValues.put(
                'Water Heating',
                new Decimal[] {
                    Decimal.valueOf(fr.WaterHeating) * kWconversion,
                    Decimal.valueOf(fr.WaterHeating),
                    Decimal.valueOf(fr.GasWaterHeating)
                }
            );
            //lighting should include both indoor and outdoor lighting
            endUsePostValues.put(
                'Lighting',
                new Decimal[] {
                    (Decimal.valueOf(fr.IndoorLighting) + Decimal.valueOf(fr.OutdoorLighting)) * kWconversion,
                    Decimal.valueOf(fr.IndoorLighting) + Decimal.valueOf(fr.OutdoorLighting),
                    Decimal.valueOf(fr.GasIndoorLighting) + Decimal.valueOf(fr.GasOutdoorLighting)
                }
            );

            //get the final values
            summary.PostUpgradeGasUseTherms = Decimal.valueOf(fr.GasUseTherms);
            summary.PostUpgradeElectricityUsekWh = Decimal.valueOf(fr.ElectricityUsekWh);
            summary.PostUpgradeElectricityUsekW = Decimal.valueOf(fr.ElectricityAvgkW);

            //if the final result's UtilityElecUse has a cooling value greater than 0, value is true
            if (fr.Cooling != null && Decimal.valueOf(fr.Cooling) > 0) {
                summary.PostUpgradeCoolingPresent = true;
            }
            else {
                summary.PostUpgradeCoolingPresent = false;
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

            //sum initial values
            Decimal BTUInitialSum = 0;
            BTUInitialSum += summary.InitialElectric.Total * KWH_TO_BTU;
            BTUInitialSum += summary.InitialGas.Total * THERMS_TO_BTU;
            //sum savings
            Decimal BTUEnergySavings = 0;
            BTUEnergySavings += (summary.TotalEnergySavingsTherms * THERMS_TO_BTU);
            BTUEnergySavings += (summary.TotalEnergySavingskWh * KWH_TO_BTU);
            //get the total energy savings percentage
            summary.TotalEnergySavingsPercentFromIndividualValues = BTUInitialSum > 0 ?
                ((BTUEnergySavings / BTUInitialSum) * 100).setScale(2) : 0;

            //get the total energy savings
            summary.TotalEnergySavingsTherms = summary.InitialGasUseTherms - summary.PostUpgradeGasUseTherms;
            summary.TotalEnergySavingskW = summary.InitialElectricityUsekW - summary.PostUpgradeElectricityUsekW;
            summary.TotalEnergySavingskWh = summary.InitialElectricityUsekWh - summary.PostUpgradeElectricityUsekWh;

            //get the total sum of initial gas and electric usage in BTUs
            BTUInitialSum = 0;
            BTUInitialSum += summary.InitialGasUseTherms * THERMS_TO_BTU;
            BTUInitialSum += summary.InitialElectricityUsekWh * KWH_TO_BTU;
            
            //get the total sum of gas and electric energy savings in BTUs
            BTUEnergySavings = 0;
            BTUEnergySavings += (summary.TotalEnergySavingsTherms * THERMS_TO_BTU);
            BTUEnergySavings += (summary.TotalEnergySavingskWh * KWH_TO_BTU);

            //get the total energy savings percentage
            summary.TotalEnergySavingsPercent = BTUInitialSum > 0 ?
                ((BTUEnergySavings / BTUInitialSum) * 100).setScale(2) : 0;
        }

        //-- Evaluate Improvements
        for (Improvements improv : improvements) {
            //if PostUpgradeBlowerDoorResults not obtained from alternative descriptions
            if (summary.PostUpgradeBlowerDoorResults == null) {
                if (improv.ImprovementName == 'Air Sealing') {
                    //get the value stored in the string of the ImprovementAction
                    String action = improv.ImprovementAction;
                    action = action.replace('50 Pascals = ', '');
                    action = action.replace(' cfm', '');
                    summary.PostUpgradeBlowerDoorResults = Decimal.valueOf(action) * totalHVACs;
                }
            }
            //if PostUpgradeDuctTestResults not obtained from alternative descriptions
            if (summary.PostUpgradeDuctTestResults == null) {
                if (improv.ImprovementName == 'Duct Sealing' || improv.ImprovementName == 'Duct Replacement') {
                    //get the value stored in the string of the ImprovementAction
                    String action = improv.ImprovementAction;
                    action = action.replace('25 Pascals = ', '');
                    action = action.replace(' cfm', '');
                    summary.PostUpgradeDuctTestResults = Decimal.valueOf(action) * totalHVACs;
                }
            }
            //evaluate water improvements
            if (improv.ImprovementName == 'Water Heater' || improv.ImprovementName == 'Domestic Hot Water Heater') {
                waterImprovements = true;
                if (gasWaterAlts == 0) { //only evaluate if no gas alternative descriptions
                    if (improv.ImprovementAction.contains(GAS_FIRED)) {
                        gasWaterImprov++;
                    }
                }
                if (electricWaterAlts == 0) { //only evaluate if no electric alternative descriptions
                    if (improv.ImprovementAction.contains('Electric Res') || improv.ImprovementAction.contains(HEAT_PUMP)) {
                        electricWaterImprov++;
                    }
                }
            }
            //general heating system improvements
            if (improv.ImprovementName == 'Heating System') {
                heatingImprovements = true;
            }
        }

        //determine PostUpgradeHotWaterFuel
        if (summary.InitialHotWaterFuel == GAS && waterResults == false && waterImprovements == false) {
            summary.PostUpgradeHotWaterFuel = GAS;
        }
        else if (((gasWaterAlts + gasWaterImprov) - electricWater) >= 0) {
            summary.PostUpgradeHotWaterFuel = GAS;
        }
        else if (summary.InitialHotWaterFuel == ELECTRIC && waterResults == false && waterImprovements == false) {
            summary.PostUpgradeHotWaterFuel = ELECTRIC;
        }
        else if (((electricWaterAlts + electricWaterImprov) - gasWater) >= 0) {
            summary.PostUpgradeHotWaterFuel = ELECTRIC;
        }
        else if (summary.InitialHotWaterFuel == MIXED && heatingAlts == 0 && heatingImprovements == false) {
            summary.PostUpgradeHotWaterFuel = MIXED;
        }
        else {
            summary.PostUpgradeHotWaterFuel = UNKNOWN;
        }

        //-- Re-evaluate Results for PostUpgradeHeating -- must occur after PostUpgradeHotWaterFuel is determined
        for (Result r : results) {
            //evaluate heating results
            if (r.ResultType == 'Heating Boiler') {
                heatingResults = true;
                //check alternative descriptions for gas or electric type
                for (AlternativeDescription alt : r.alternativeDescriptions) {
                    if (alt.Label == 'Type') {
                        if (alt.Value == GAS_FIRED) {
                            gasHeatingAlts++;
                        }
                        else if (alt.Value == 'Hot Water' || alt.Value == 'Combined Hydronic') {
                            if (summary.PostUpgradeHotWaterFuel == GAS) {
                                gasHeatingAlts++;
                            }
                        }
                    }
                }
            }

            //-- Re-evaluate AlternativeDescriptions
            for (AlternativeDescription alt : r.alternativeDescriptions) {
                //evaluate heating alternative descriptions
                if (alt.Label == 'Heating') {
                    //do not increment heatingAlts this time around
                    if (alt.Value.contains('Furnace')) {
                        gasHeatingAlts++;
                    }
                    if (alt.Value.contains('Packaged Heat Pump') || alt.Value.contains('Split Heat Pump')) {
                        electricHeatingAlts++;
                    }
                    if (summary.PostUpgradeHotWaterFuel == ELECTRIC) {
                        if (alt.Value.contains('Hot Water') || alt.Value.contains('Combined Hydronic')) {
                            electricHeatingAlts++;
                        }
                    }
                }
            }
        }

        //-- Re-evaluate Improvements for PostUpgradeHeating
        for (Improvements improv : improvements) {
            if (improv.ImprovementName == 'HVAC System' || improv.ImprovementName == 'Heating Boiler') {
                heatingFuelImprovements = true;
            }
            //evaluate heating improvements
            if (
                improv.ImprovementName == 'Heating System' || improv.ImprovementName == 'Air Conditioning System' ||
                improv.ImprovementName == 'Heating Boiler'
            ) {
                if (gasHeatingAlts == 0 && summary.PostUpgradeHotWaterFuel == GAS) {
                    if (
                        improv.ImprovementAction.contains('Furnace') || improv.ImprovementAction.contains('Type = Gas Fired') ||
                        improv.ImprovementAction.contains('Hot Water Efficiency')
                    ) {
                        gasHeatingImprov++;
                    }
                }
                if (improv.ImprovementName != 'Heating Boiler') {
                    if (electricHeatingAlts == 0 && summary.PostUpgradeHotWaterFuel == ELECTRIC) {
                        if (improv.ImprovementAction.contains(HEAT_PUMP) || improv.ImprovementAction.contains('Hot Water Efficiency')) {
                            electricHeatingImprov++;
                        }
                    }
                }
            }
        }

        //determine PostUpgradeHeatingFuel
        if (summary.InitialHeatingFuel == GAS && heatingAlts == 0 && heatingResults == false && heatingFuelImprovements == false) {
            summary.PostUpgradeHeatingFuel = GAS;
        }
        else if (((gasHeatingAlts + gasHeatingImprov) - electricHeat) >= 0) {
            summary.PostUpgradeHeatingFuel = GAS;
        }
        else if (summary.InitialHeatingFuel == ELECTRIC && heatingAlts == 0 && heatingImprovements == false) {
            summary.PostUpgradeHeatingFuel = ELECTRIC;
        }
        else if ((electricHeatingAlts + electricHeatingImprov) - electricHeat >= 0) {
            summary.PostUpgradeHeatingFuel = ELECTRIC;
        }
        else if (summary.InitialHeatingFuel == MIXED && heatingAlts == 0 && heatingImprovements == false) {
            summary.PostUpgradeHeatingFuel = MIXED;
        }
        else if (summary.InitialHeatingFuel == NONE && heatingAlts == 0 && heatingImprovements == false) {
            summary.PostUpgradeHeatingFuel = NONE;
        }
        else {
            summary.PostUpgradeHeatingFuel = UNKNOWN;
        }

        storeData(); //store the data in database objects
    }


    //-- Stores the parsed data from inner classes in database objects
    private void storeData() {
        try {
            application = [
                SELECT Id, Application_Submission_Date__c, Electric_Provider__c, Gas_Provider__c, Incentive_Total__c,
                Notes__c, HC_Type__c, Customer_First_Name__c, Customer_Address__c, Customer_City__c,
                Customer_State__c, Customer_Zip_Code__c, Customer_Phone__c, Contractor__c,
                Contractor__r.First_Name__c, Contractor__r.Last_Name__c, Contractor__r.Name,
                Contractor__r.BillingStreet, Contractor__r.BillingCity, Contractor__r.BillingState,
                Contractor__r.BillingPostalCode, Contractor__r.Phone, Contractor__r.License_Number__c,
                BPI_Analyst__c, BPI_Analyst__r.Name, BPI_Analyst__r.BPI_License_Number__c, Dwelling_Unit__c,
                Building_Type__c, Building_Vintage__c, Electricity_Usage__c, Natural_Gas_Usage__c,
                Total_Energy_Usage_KBTUs__c, Proposed_Electricity_Savings__c, Proposed_Natural_Gas_Savings__c,
                Proposed_Total_Energy_Savings_KBTU__c, Completed_Electricity_Savings__c,
                Completed_Natural_Gas_Savings__c, Completed_Total_Energy_Savings_KBTU__c, Rebate_FROM_Tier__c,
                Granted_Exceptions__c
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

        try { //get the sub-application with any existing XML Results and XML End Uses
            subApplication = [
                SELECT Id, Software__c, Software_Version__c, Building_Street_Address__c, Building_City__c, Building_State__c,
                Building_ZIP_Code__c, Conditioned_Floor_Area__c, Number_of_Dwelling_Units__c, Number_of_Stories__c, Number_of_Occupants__c,
                Foundation_Type__c, Year_Built__c, Number_of_Bedrooms__c, Pool_Type__c, Spa_Type__c, Thermostat_Type__c, Total_Window_Area__c,
                Avg_Window_U_Factor__c, Duct_Insulation_R_value__c, Duct_Leakage_cfm25__c, Building_Leakage_cfm50__c, Avg_Ceiling_Height__c,
                Avg_Floor_Insulation_U_Factor__c, Avg_Ceiling_Insulation_U_Factor__c, Total_Wall_Area__c, Avg_Wall_Insulation_U_Factor__c,
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
        subApplication.Software__c = 'EnergyPro';
        subApplication.Software_Version__c = SoftwareVersion;
        subApplication.Building_Street_Address__c = project.Address;
        subApplication.Building_City__c = project.City;
        subApplication.Building_State__c = project.State;
        subApplication.Building_ZIP_Code__c = project.Zip;
        subApplication.Conditioned_Floor_Area__c = String.isNotEmpty(project.ConditionedFloorArea) ?
            Decimal.valueOf(project.ConditionedFloorArea) : 0;
        subApplication.Number_of_Dwelling_Units__c = String.isNotEmpty(project.NumberOfDwellingUnits) ?
            Integer.valueOf(project.NumberOfDwellingUnits) : 0;
        subApplication.Number_of_Stories__c = String.isNotEmpty(project.Stories) ?
            Integer.valueOf(project.Stories) : 0;
        subApplication.Number_of_Occupants__c = String.isNotEmpty(project.Occupants) ?
            Decimal.valueOf(project.Occupants) : 0;
        subApplication.Foundation_Type__c = project.FoundationType;
        subApplication.Year_Built__c = summary.YearBuilt;
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
        update subApplication;

        //if results and end uses already exist, delete existing records
        if (subApplication.XML_Results__r.size() > 0) {
            delete subApplication.XML_Results__r;
        }
        if (subApplication.XML_End_Uses__r.size() > 0) {
            delete subApplication.XML_End_Uses__r;
        }

        //extract results
        xmlResults = new List<XML_Result__c>();

        Integer index = 0; //index for comparing current result to previous result
        for (Result r : results) {
            //exclude test in home result
            if (r.ResultType != TEST_IN_HOME) {
                XML_Result__c result = new XML_Result__c();
                result.Sub_Application__c = subApplication.Id;
                result.Improvement_Type__c = r.ResultType;

                if (index != 0) {
                    //calculate energy savings from last result
                    result.Electricity_Savings_kW__c = Decimal.valueOf(results[index - 1].ElectricityAvgkW) - Decimal.valueOf(r.ElectricityAvgkW);
                    result.Electricity_Savings_kWh__c = Decimal.valueOf(results[index - 1].ElectricityUsekWh) - Decimal.valueOf(r.ElectricityUsekWh);
                    result.Natural_Gas_Savings_therms__c = Decimal.valueOf(results[index - 1].GasUseTherms) - Decimal.valueOf(r.GasUseTherms);
                }

                //record relevant alternative descriptions
                for (AlternativeDescription ad : r.alternativeDescriptions) {
                    if (ad.Label == 'Air Conditioner Refrigerant Charge') {
                        result.Air_Conditioner_Refrigerant_Charge__c = ad.Value;
                    }
                    else if (ad.Label == 'Air Handler Airflow') {
                        result.Air_Handler_Airflow__c = String.isNotEmpty(ad.Value) ? Integer.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Air Handler Fan Wattage') {
                        result.Air_Handler_Fan_Wattage__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'All Energy Efficiency Upgrades Included') {
                        if (ad.Value == 'true') {
                            result.All_Energy_Efficiency_Upgrades_Included__c = true;
                        }
                        else if (ad.Value == 'false') {
                            result.All_Energy_Efficiency_Upgrades_Included__c = false;
                        }
                    }
                    else if (ad.Label == 'Annual Production') {
                        result.Annual_Production__c = String.isNotEmpty(ad.Value) ? Integer.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Building Leakage') {
                        result.Building_Leakage__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Cavity Insulation') {
                        result.Cavity_Insulation__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Control') {
                        result.Control__c = ad.Value;
                    }
                    else if (ad.Label == 'Cooling') {
                        result.Cooling__c = ad.Value;
                    }
                    else if (ad.Label == 'Cooling Distribution') {
                        result.Cooling_Distribution__c = ad.Value;
                    }
                    else if (ad.Label == 'DC Rating') {
                        result.DC_Rating__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'DHW Distribution Type') {
                        result.DHW_Distribution_Type__c = ad.Value;
                    }
                    else if (ad.Label == 'Dishwasher') {
                        result.Dishwasher__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Duct Insulation') {
                        result.Duct_Insulation__c = String.isNotBlank(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Duct Location') {
                        result.Duct_Location__c = ad.Value;
                    }
                    else if (ad.Label == 'EER') {
                        result.EER__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                        //track eligibility for bonus
                        if (result.EER__c >= 12) {
                            eerBonus = true;
                        }
                    }
                    else if (ad.Label == 'Efficiency') {
                        result.Efficiency__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Exterior Insulation') {
                        result.Exterior_Insulation__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Garage Refrigerator') {
                        result.Garage_Refrigerator__c = String.isNotEmpty(ad.Value) ? Integer.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Heating') {
                        result.Heating__c = ad.Value;
                    }
                    else if (ad.Label == 'Heating Distribution') {
                        result.Heating_Distribution__c = ad.Value;
                    }
                    else if (ad.Label == 'Indoor Lighting Type') {
                        result.Indoor_Lighting_Type__c = ad.Value;
                    }
                    else if (ad.Label == 'Indoor Refrigerator') {
                        result.Indoor_Refrigerator__c = String.isNotEmpty(ad.Value) ? Integer.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Interior Insulation') {
                        result.Interior_Insulation__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Leakage') {
                        result.Leakage__c = String.isNotEmpty(ad.Value) ? Integer.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Leakage Rate at 25 Pascals') {
                        result.Leakage_Rate_at_25_Pascals__c = String.isNotEmpty(ad.Value) ? Integer.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Leakage Rate at 50 Pascals') {
                        result.Leakage_Rate_at_50_Pascals__c = String.isNotEmpty(ad.Value) ? Integer.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Leakage Type') {
                        result.Leakage_Type__c = ad.Value;
                    }
                    else if (ad.Label == 'Name') {
                        result.Name = ad.Value;
                    }
                    else if (ad.Label == 'Outdoor Lighting Type') {
                        result.Outdoor_Lighting_Type__c = ad.Value;
                    }
                    else if (ad.Label == 'Pool Pump') {
                        result.Pool_Pump__c = ad.Value;
                        //track eligibility for bonus
                        if (result.Pool_Pump__c == 'Variable Speed') {
                            pumpBonus = true;
                        }
                    }
                    else if (ad.Label == 'SEER') {
                        result.SEER__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                        //track eligibility for bonus
                        if (result.SEER__c >= 14) {
                            seerBonus = true;
                        }
                    }
                    else if (ad.Label == 'SHGC') {
                        result.SHGC__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Type') {
                        result.Type__c = ad.Value;
                    }
                    else if (ad.Label == 'U-Factor') {
                        result.U_Factor__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else if (ad.Label == 'Volume') {
                        result.Volume__c = String.isNotEmpty(ad.Value) ? Decimal.valueOf(ad.Value) : 0;
                    }
                    else {
                        if (result.Other_Result_Info__c == '') {
                            result.Other_Result_Info__c = ad.Label + ' = ' + ad.Value + ' ' + ad.Units;
                        }
                        else {
                            result.Other_Result_Info__c += '; ' + ad.Label + ' = ' + ad.Value + ' ' + ad.Units;
                        }
                    }
                }
                xmlResults.add(result);
            }
            index++;
        }
        insert xmlResults;

        //extract end uses from pre and post value maps
        xmlEndUses = new List<XML_End_Use__c>(); //instantiate list
        for (String type : endUsePreValues.keySet()) {
            XML_End_Use__c endUse = new XML_End_Use__c();
            endUse.Sub_Application__c = subApplication.Id;
            endUse.End_Use__c = type; //map's key is the end use type
            //get initial values from map
            endUse.Pre_Install_Electricity_Use_kW__c = endUsePreValues.get(type)[0];
            endUse.Pre_Install_Electricity_Use_kWh__c = endUsePreValues.get(type)[1];
            endUse.Pre_Install_Gas_Use_therms__c = endUsePreValues.get(type)[2];
            //get post values from map
            endUse.Post_Install_Electricity_Use_kW__c = endUsePostValues.get(type)[0];
            endUse.Post_Install_Electricity_Use_kWh__c = endUsePostValues.get(type)[1];
            endUse.Post_Install_Gas_Use_therms__c = endUsePostValues.get(type)[2];
            xmlEndUses.add(endUse);
        }
        insert xmlEndUses;
        
        //query the sub-application object to get new formula values
        subApplication = [
            SELECT Id, Initial_Submission_Date__c, Air_Conditioning_Present__c, Building_Street_Address__c,
                Building_City__c, Building_State__c, Building_ZIP_Code__c, Number_of_Stories__c,
                Number_of_Dwelling_Units__c, Pre_Install_Electricity_Use_kWh__c, Pre_Install_Gas_Use_therms__c,
                Total_Energy_Savings_kWh__c, Total_Energy_Savings_therms__c, Rebate_Assignment__c,
                Total_Energy_Savings_BTUs__c, Total_Energy_Savings_Percent__c, Total_Incentive__c,
                Total_Incentive_FROM_Tier__c, PGE_Payable_Modeled_Savings_Incentive__c, Proposed_Package_Cost__c,
                Completed_Package_Cost__c, Stage__c, Application__r.Status__c, RecordType.Id, HPHI_Bonus__c
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


        /* Calculate incentive */
        //get the zip codes eligible for additional AC and Pool Pump bonus kickers
        Set<String> eligibleZips = new Set<String>();
        List<Eligible_Zip_Codes__c> zips = Eligible_Zip_Codes__c.getall().values();
        for (Eligible_Zip_Codes__c z : zips) {
            eligibleZips.add(z.Name);
        }

        Decimal acKicker = 0, poolPumpKicker = 0; //default to 0 to prevent bonuses if no values set
        //determine bonus eligibility based on building zip code and electric provider
        if (eligibleZips.contains(subApplication.Building_ZIP_Code__c) && electricProvider == true) {
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
            if (eerBonus == true && seerBonus == true) {
                acKicker = acBonusValue;
            }
            //apply bonus if pool pump qualified
            if (pumpBonus == true) {
                poolPumpKicker = pumpBonusValue;
            }
        }

        //determine whether the home is "heated and cooled" or "heated only"
        Boolean heatedAndCooled = false;
        if (subApplication.Air_Conditioning_Present__c == true) {
            heatedAndCooled = true;
        }

        //get custom settings for 'EnergyPro' modifiers (haircuts)
        Decimal kWhModifier = 1, thermModifier = 1; //default to 1 to prevent modification if no values set
        Modifiers__c m = Modifiers__c.getValues('EnergyPro');
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
        if (heatedAndCooled == true) {
            kWhSavings *= kWhModifier;
        }
        
        //always adjust therm savings
        Decimal thermSavings = subApplication.Total_Energy_Savings_therms__c * thermModifier;
        
        //determine initial usage for utilities provided by PG&E
        Decimal BTUInitialSum = 0;
        if (electricProvider == true) {
            BTUInitialSum += subApplication.Pre_Install_Electricity_Use_kWh__c * KWH_TO_BTU;
        }
        if (gasProvider == true) {
            BTUInitialSum += subApplication.Pre_Install_Gas_Use_therms__c * THERMS_TO_BTU;
        }
        
        //determine initial usage agnostic of provider
        Decimal agnosticBTUInitialSum = 0;
        agnosticBTUInitialSum += subApplication.Pre_Install_Electricity_Use_kWh__c * KWH_TO_BTU;
        agnosticBTUInitialSum += subApplication.Pre_Install_Gas_Use_therms__c * THERMS_TO_BTU;
        
        //determine total savings for utilities provided by PG&E
        Decimal BTUSavings = 0;
        if (electricProvider == true) {
            BTUSavings += (kWhSavings * KWH_TO_BTU);
        }
        if (gasProvider == true) {
            BTUSavings += (thermSavings * THERMS_TO_BTU);
        }
        
        //determine total savings agnostic of provider
        Decimal agnosticBTUSavings = 0;
        agnosticBTUSavings += (kWhSavings * KWH_TO_BTU);
        agnosticBTUSavings += (thermSavings * THERMS_TO_BTU);
        
        //determine the site savings, round to nearest tenth of a percentage
        Decimal agnosticSiteSavingsPercent = agnosticBTUInitialSum > 0 ?
            ((agnosticBTUSavings / agnosticBTUInitialSum) * 100) : 0;
        
        //save the initial results, agnostic of provider
        application.Electricity_Usage__c = subApplication.Pre_Install_Electricity_Use_kWh__c;
        application.Natural_Gas_Usage__c = subApplication.Pre_Install_Gas_Use_therms__c;
        application.Total_Energy_Usage_KBTUs__c = agnosticBTUInitialSum / 1000;

        if (isPostApplication == false) {
            application.Proposed_Electricity_Savings__c = kWhSavings;
            application.Proposed_Natural_Gas_Savings__c = thermSavings;
            application.Proposed_Total_Energy_Savings_KBTU__c = agnosticBTUSavings / 1000;
        }
        else {
            //save the adjusted/completed savings on the application
            application.Completed_Electricity_Savings__c = kWhSavings;
            application.Completed_Natural_Gas_Savings__c = thermSavings;
            application.Completed_Total_Energy_Savings_KBTU__c = agnosticBTUSavings / 1000;
        }

        // Set structure to check later wich Rebate_Tiers__c should use
        Integer structure = BIGPortalAdvanceHUApplicationUtils.getStructureDependingOnDates(application,
                subApplication, isPostApplication);

        //locate base incentive for modified site savings FROM appropriate tier
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
        Decimal percentPGEResponsibility = agnosticBTUSavings > 0 ? BTUSavings / agnosticBTUSavings : 0;
        subApplication.PGE_Payable_Modeled_Savings_Incentive__c = (agnosticBaseIncentive * percentPGEResponsibility).setScale(2);
        
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
        if (electricProvider == true) {
            kWhkickers = (kWhSavings * kWhKickerMultiplier).setScale(2);
        }

        //only apply therm kicker if PG&E is gas provider
        if (gasProvider == true) {
            thermKickers = (thermSavings * thermKickerMultiplier).setScale(2);
        }

        //determine total incentive
        Decimal totalIncentive = acKicker + poolPumpKicker + kWhKickers + thermKickers + (agnosticBaseIncentive * percentPGEResponsibility);
        application.Incentive_Total__c = totalIncentive;
        subApplication.Total_Incentive__c = totalIncentive;

        // Determine the estimated incentive total with bonus.
        if (subApplication.HPHI_Bonus__c != null) {
            subApplication.Total_Incentive__c += subApplication.HPHI_Bonus__c;
            application.Incentive_Total__c = subApplication.Total_Incentive__c;
        }

        /* Calculate item incentive for each end use*/
        //store the modified savings on each end use and calculate item incentive
        for (XML_End_Use__c eu : xmlEndUses) {
            eu.Gross_Kw__c = eu.End_Use_Energy_Savings_kW__c;
            //only apply kWh modifier if heated and cooled
            eu.Gross_KWH__c = heatedAndCooled ? (eu.End_Use_Energy_Savings_kWh__c * kWhModifier) : eu.End_Use_Energy_Savings_kWh__c;
            //always apply the therm modifier
            eu.Gross_Therms__c = eu.End_Use_Energy_Savings_therms__c * thermModifier;
            //calculate the adjusted savings percent to use in calculating item incentive
            Decimal adjustedEnergySavingsPercent = agnosticBTUSavings > 0 ?
                ((eu.Gross_KWH__c * KWH_TO_BTU) + (eu.Gross_Therms__c * THERMS_TO_BTU)) / agnosticBTUSavings : 0;
            eu.Item_Incentive_Amount__c = (agnosticBaseIncentive * adjustedEnergySavingsPercent);
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
        
        upsert xmlEndUses;
        
        update application;
        
        update subApplication;
        
        if (BIGPortalAdvanceHUApplicationUtils.isContractorTaxInfoRequired(subApplication, application)) {
            throw new TaxInfoException(BIGPortalAdvanceHuApplicationUtils.TAX_INFO_REQUIRED_ERROR);
        }
        if (!BIGPortalAdvanceHUApplicationUtils.isValidEstimatedIncentive(subApplication)) {
            String msg = String.format(BIGPortalAdvanceHuApplicationUtils.ESTIMATED_INCENTIVE_TOTAL_ERROR, 
                    new List<String>{subApplication.Total_Incentive__c.format()});
            throw new EnergyProXMLException(msg);
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
        
    }

    public class EnergyProXMLException extends Exception {}
    public class TaxInfoException extends Exception {}
    public class TotalEnergySavingsPercentException extends Exception {}

}