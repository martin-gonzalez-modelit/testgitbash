public class HPXMLParser {

    public Application__c application              { get; set; }
    public Sub_Application__c subApplication       { get; set; }
    private Boolean isPostApplication               { get; set; }
    public String xmlString                         { get; set; }
    public HPXML entry { get; set; }
    private static final String PGE_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final String DEMAND_SAVINGS_REQUIRED_ERROR = 'Energy Model Output: Project/ProjectDetails/' +
            'EnergySavingsInfo/DemandSavings value is required.';
    private static final String DEMAND_SAVINGS_INVALID_ERROR = 'Energy Model Output: Project/ProjectDetails/' +
            'EnergySavingsInfo/DemandSavings value is invalid.';
    private static final String ELECTRICITY_ENERGY_TYPE = 'electricity';
    private static final String NATURAL_GAS_ENERGY_TYPE = 'natural gas';
    private static final String PROPANE_ENERGY_TYPE = 'propane';
    public static final String GAS_ENERGY_TYPE_ERROR = 'The given gas provider information and energy type(s) in the '
            + 'energy model are inconsistent. Please revise or contact us at jobs@homeupgrade.org for assistance.';
    public static final String ELECTRICITY_ENERGY_TYPE_ERROR = 'The given electric provider information and energy '
            + 'type(s) in the energy model are inconsistent. Please revise or contact us at jobs@homeupgrade.org for '
            + 'assistance.';
    public static final String PHOTOVOLTAICS_ERROR = 'Photovoltaics (PV) must be removed from the energy model to '
            + 'continue. Please revise or contact us at jobs@homeupgrade.org for assistance.';

    /**
     * Compares two version strings.
     *
     * @note It does not work if "1.10" is supposed to be equal to "1.10.0".
     *
     * @param str1 a string of ordinal numbers separated by decimal points.
     * @param str2 a string of ordinal numbers separated by decimal points.
     * @return The result is a negative integer if str1 is _numerically_ less than str2.
     *         The result is a positive integer if str1 is _numerically_ greater than str2.
     *         The result is zero if the strings are _numerically_ equal.
     */
    public Integer versionCompare(String str1, String str2) {
        String[] vals1 = str1.split('\\.');
        String[] vals2 = str2.split('\\.');

        Integer i = 0;
        // set index to first non-equal ordinal or length of shortest version string
        while (i < vals1.size() && i < vals2.size() && vals1[i] == vals2[i]) {
            i++;
        }
        // compare first non-equal ordinal number
        if (i < vals1.size() && i < vals2.size()) {
            return Integer.valueOf(vals1[i]) - Integer.valueOf(vals2[i]);
        }
        // the strings are equal or one string is a substring of the other
        // e.g. "1.2.3" = "1.2.3" or "1.2.3" < "1.2.3.4"
        else {
            return vals1.size() - vals2.size();
        }
    }

    //-- Get supported software from custom setting
    public Software_Version__c getSupportedSoftware(String software) {
        Map<String, String> supportedSoftware = new Map<String, String>();
        Software_Version__c sw = Software_Version__c.getInstance(software);
        return sw;
    }

    //-- Validate Software
    public Integer getSoftwareValidation(String uploadedSWName, String uploadedSWVersion) {
        Set<String> supportedSoftwareSet = new Set<String>{'OptiMiser', 'CakeSystems', 'SnuggPro', 'Snugg Pro', 'TREAT'};
        Integer isValid = 1;
        Integer isMinSupported = 0;
        Integer isMaxSupported = 0;
        Software_Version__c supportedSW = getSupportedSoftware(uploadedSWName);
        if (supportedSW==null) {
            return 0;
        }
        String minimumVersion = supportedSW.Minimum__c;
        String maximumVersion = supportedSW.Maximum__c;

        //check if uploaded software is in the list
        if (supportedSoftwareSet.contains(uploadedSWName)) {
            //compare with minimum version
            if (minimumVersion != '' && minimumVersion != NULL)
                isMinSupported = versionCompare(minimumVersion, uploadedSWVersion);
            //compare with maximum version
            if (maximumVersion != '' && maximumVersion != NULL)
                isMaxSupported = versionCompare(uploadedSWVersion, maximumVersion);

            if (isMinSupported < 0 && isMaxSupported < 0) {
                isValid = 0;
            }
        } else {
            isValid = 0;
        }

        return isValid;
    }

    public List<String> processHPXML(xmlStreamReader reader, Boolean isPostAppStatus){
        return processHPXML(reader, isPostAppStatus, 'test');
    }

    public List<String> processHPXML(xmlStreamReader reader, Boolean isPostAppStatus, String xmlBody) {
        entry = new HPXML(application, subApplication, isPostAppStatus, true);
        entry.isPostApplication = isPostAppStatus;
        entry.customer = new HPXML.Customer();
        entry.businesscontact = new HPXML.BusinessContact();
        entry.software = new HPXML.Software();
        entry.building = new HPXML.Building();
        List<HPXML.Building> buildings = new List<HPXML.Building>();
        List<HPXML.AirInfiltrationMeasurement> aims = new List<HPXML.AirInfiltrationMeasurement>();
        List<HPXML.Attic> attics = new List<HPXML.Attic>();
        List<HPXML.AtticFloorInsulation> afis = new List<HPXML.AtticFloorInsulation>();
        List<HPXML.AtticRoofInsulation> aris = new List<HPXML.AtticRoofInsulation>();
        List<HPXML.Foundation> foundations = new List<HPXML.Foundation>();
        List<HPXML.Measure> measures = new List<HPXML.Measure>();
        List<HPXML.ModeledUsage> modeledusages = new List<HPXML.ModeledUsage>();
        List<HPXML.HeatingSystem> heatingsystems = new List<HPXML.HeatingSystem>();
        List<HPXML.CoolingSystem> coolingsystems = new List<HPXML.CoolingSystem>();
        List<HPXML.WaterHeating> waterheatings = new List<HPXML.WaterHeating>();
        List<HPXML.HVACControl> hvaccontrols = new List<HPXML.HVACControl>();
        List<HPXML.LightingGroup> lightinggroups = new List<HPXML.LightingGroup>();
        List<HPXML.LightingControl> lightingcontrols = new List<HPXML.LightingControl>();
        List<HPXML.WallInsulation> wallinsulations = new List<HPXML.WallInsulation>();
        List<HPXML.FrameFloorInsulation> framefloorinsulations = new List<HPXML.FrameFloorInsulation>();
        entry.xmltransactionheaderinfo = new HPXML.XMLTransactionHeaderInfo();
        List<HPXML.FuelSavings> fuelsavings = new List<HPXML.FuelSavings>();
        List<HPXML.HeatPump> heatpumps = new List<HPXML.HeatPump>();
        List<HPXML.Window> windows = new List<HPXML.Window>();
        List<HPXML.Duct> ducts = new List<HPXML.Duct>();
        List<HPXML.Roof> roofs = new List<HPXML.Roof>();
        List<HPXML.DuctLeakageMeasurement> ductleakagemeasurements = new List<HPXML.DuctLeakageMeasurement>();
        List<HPXML.Pool> pools = new List<HPXML.Pool>();
        List<HPXML.PoolPump> poolpumps = new List<HPXML.PoolPump>();
        List<HPXML.Refrigerator> refrigerators = new List<HPXML.Refrigerator>();
        List<HPXML.VentilationFan> ventilationfans = new List<HPXML.VentilationFan>();
        List<HPXML.HVACDistribution> hvacdistributions = new List<HPXML.HVACDistribution>();
        List<HPXML.Project> projects = new List<HPXML.Project>();

        List<String> componentsList = new List<String>();
        List<String> programsList = new List<String>();

        List<String> result = new List<String>();

        Integer hasDuct = 0;
        Integer hasRoof = 0;
        Integer hasDuctLeakageMeasurement = 0;
        Integer hasPoolPump = 0;
        Integer measureFound = 0;
        String thisFuel;
        String thisUnits;
        String thisHPSystemIdentifier;
        String thisHPSameAs;
        Decimal thisHPFractionHeatLoadServed;
        Decimal thisHPFractionCoolLoadServed;
        String thisHPHeatPumpType;
        String thisHPManufacturer;
        String thisHPModelNumber;
        Integer thisHPModelYear;
        String thisHPUnits;
        String thisCoolingUnits;
        String thisPoolId;
        String thisPoolSameAs;
        Decimal thisPoolHoursPerDay;
        String thisPoolType;
        Decimal thisPoolRatedHorsepower;
        String thisPoolSpeedSetting;
        String PrimaryHeatingId;
        String PrimaryCoolingId;

        Integer hasAudit;
        Integer hasRetrofit = 0;
        Integer hasPreAppRetrofit = 0;
        Integer hasPostAppRetrofit = 0;
        Boolean hasPhotovoltaics = false;

        Map<String, Set<String>> buildingMap = new Map<String, Set<String>>();

        while (reader.hasNext()) {
        reader.next();
            //get all installed and replaced components
            if (elementStart(reader, 'InstalledComponent')) {
                String thisValue = reader.getAttributeValue(null, 'id');
                componentsList.add(thisValue);
            }
            if (elementStart(reader, 'ReplacedComponent')) {
                String thisValue = reader.getAttributeValue(null, 'id');
                componentsList.add(thisValue);
            }
            //get all program participation
            if (elementStart(reader, 'SystemIdentifier')) {
                String thisValue = reader.getAttributeValue(null, 'id');
                programsList.add(thisValue);
            }

            //XMLTransactionHeaderInformation - Start
            if (elementStart(reader, 'XMLTransactionHeaderInformation')) {
                while (elementNotEnd(reader, 'XMLTransactionHeaderInformation')) {
                    reader.next();
                    if (elementStart(reader, 'XMLGeneratedBy')) {
                        reader.next();
                        if (reader.hasText()) {
                            entry.xmltransactionheaderinfo.XMLGeneratedBy = string.valueOf(reader.getText());
                            entry.software.XMLGeneratedBy = string.valueOf(reader.getText());
                        }
                    }
                }
            }
            //XMLTransactionHeaderInformation - End

            //SOFTWARE - START
            if (elementStart(reader, 'SoftwareInfo')) {
                while (elementNotEnd(reader, 'SoftwareInfo')) {
                    reader.next();
                    if (elementStart(reader, 'SoftwareProgramUsed')) {
                        reader.next();
                        if (reader.hasText()) {
                            entry.software.SoftwareProgramUsed = string.valueOf(reader.getText());
                        }
                    }
                    if (elementStart(reader, 'SoftwareProgramVersion')) {
                        reader.next();
                        if (reader.hasText()) {
                            entry.software.SoftwareProgramVersion = string.valueOf(reader.getText());
                        }
                    }
                }
            }
            //SOFTWARE - END

            //BUSINESS CONTACT - START
            if (elementStart(reader, 'Contractor')) {
                while (elementNotEnd(reader, 'Contractor')) {
                    reader.next();
                    if (elementStart(reader, 'BusinessContact')) {
                        while (elementNotEnd(reader, 'BusinessContact')) {
                            reader.next();
                            if (elementStart(reader, 'FirstName')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.businesscontact.FirstName = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'LastName')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.businesscontact.LastName = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'Email')) {
                                reader.next();
                                while (elementNotEnd(reader, 'Email')) {
                                    reader.next();
                                    if (elementStart(reader, 'EmailAddress')) {
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.businesscontact.Email = string.valueOf(reader.getText());
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            //BUSINESS CONTACT - END

            //CUSTOMER - START
            if (elementStart(reader, 'CustomerDetails')) {
                while (elementNotEnd(reader, 'CustomerDetails')) {
                    reader.next();
                    if (elementStart(reader, 'FirstName')) {
                        reader.next();
                        if (reader.hasText()) {
                            entry.customer.FirstName = string.valueOf(reader.getText());
                        }
                    }
                    if (elementStart(reader, 'LastName')) {
                        reader.next();
                        if (reader.hasText()) {
                            entry.customer.LastName = string.valueOf(reader.getText());
                        }
                    }
                }
            }
            //CUSTOMER - END

            Set<String> buildingsSet = new Set<String>();
            //BUILDING - START
            if (elementStart(reader, 'Building')) {
                //create new building
                entry.building = new HPXML.Building();
                reader.nextTag();
                if (elementStart(reader, 'BuildingID')) {
                    String thisValue = reader.getAttributeValue(null, 'id');
                    entry.building.SystemIdentifier = string.valueOf(thisValue);
                    entry.building.SameAs = reader.getAttributeValue(null, 'sameas');
                }

                while (elementNotEnd(reader, 'Building')) {
                    reader.next();
                    //Address - start
                    if (elementStart(reader, 'Address')) {
                        while (elementNotEnd(reader, 'Address')) {
                            reader.next();
                            if (elementStart(reader, 'Address1')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.Address1 = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'CityMunicipality')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.CityMunicipality = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'StateCode')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.StateCode = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ZipCode')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.ZipCode = string.valueOf(reader.getText());
                                }
                            }
                        }
                    }
                    //Address - end

                    //ProjectStatus - start
                    if (elementStart(reader, 'ProjectStatus')) {
                        while (elementNotEnd(reader, 'ProjectStatus')) {
                            reader.next();
                            if (elementStart(reader, 'EventType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.ProjectStatusEventType = string.valueOf(reader.getText());
                                    if(string.valueOf(reader.getText()) == 'audit')
                                        entry.building.ProjectStatus = 'audit';
                                        hasAudit = 1;
                                    if(string.valueOf(reader.getText()) == 'proposed workscope'){
                                        entry.building.ProjectStatus = 'retrofit';
                                        hasPreAppRetrofit = 1;
                                    }
                                    if(string.valueOf(reader.getText()) == 'job completion testing/final inspection'){
                                        entry.building.ProjectStatus = 'retrofit';
                                        hasPostAppRetrofit = 1;
                                    }
                                }
                            }
                        }
                    }
                    //ProjectStatus - end

                    //BuildingOccupancy - start
                    if (elementStart(reader, 'BuildingOccupancy')) {
                        while (elementNotEnd(reader, 'BuildingOccupancy')) {
                            reader.next();
                            if (elementStart(reader, 'NumberofResidents')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.NumberofResidents = decimal.valueOf(reader.getText());
                                }
                            }
                        }
                    }
                    //BuildingOccupancy - end
                    //BuildingConstruction - start
                    if (elementStart(reader, 'BuildingConstruction')) {
                        while (elementNotEnd(reader, 'BuildingConstruction')) {
                            reader.next();
                            if (elementStart(reader, 'YearBuilt')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.YearBuilt = integer.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ResidentialFacilityType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.ResidentialFacilityType = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'NumberOfBedrooms')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.NumberOfBedrooms = integer.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ConditionedFloorArea')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.ConditionedFloorArea = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'NumberofStoriesAboveGrade')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.NumberofStoriesAboveGrade = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'AverageCeilingHeight')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.building.AverageCeilingHeight = decimal.valueOf(reader.getText());
                                }
                            }
                        }
                    }
                    //BuildingConstruction - end
                    //AirInfiltrationMeasurement - start
                    if (elementStart(reader, 'AirInfiltrationMeasurement')) {
                        //create new aim
                        entry.aim = new HPXML.AirInfiltrationMeasurement();
                        entry.aim.BuildingId = entry.building.SystemIdentifier;
                        while (elementNotEnd(reader, 'AirInfiltrationMeasurement')) {
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.aim.SystemIdentifier = string.valueOf(thisValue);
                                entry.aim.SameAs = reader.getAttributeValue(null, 'sameas');
                            }
                            if (elementStart(reader, 'TypeOfInfiltrationMeasurement')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.aim.TypeOfInfiltrationMeasurement = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'HousePressure')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.aim.HousePressure = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'UnitofMeasure')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.aim.UnitofMeasure = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'AirLeakage')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.aim.AirLeakage = decimal.valueOf(reader.getText());
                                }
                            }
                        }
                        //add aim to list of aims
                        aims.add(entry.aim);
                        entry.aims.add(entry.aim);
                        //hasAIM = 1;
                    }
                    //AirInfiltrationMeasurement - end
                    //Attic - start
                    if (elementStart(reader, 'Attics')) {

                        while (elementNotEnd(reader, 'Attics')) {
                        reader.next();
                            if (elementStart(reader, 'Attic')) {
                                //create new aim
                                entry.attic = new HPXML.Attic();
                                entry.attic.BuildingId = entry.building.SystemIdentifier;
                                reader.nextTag();
                                if (elementStart(reader, 'SystemIdentifier')) {
                                    String thisValue = reader.getAttributeValue(null, 'id');
                                    entry.attic.SystemIdentifier = string.valueOf(thisValue);
                                    entry.attic.SameAs = reader.getAttributeValue(null, 'sameas');
                                }

                                while (elementNotEnd(reader, 'Attic')) {
                                    reader.next();
                                    if (elementStart(reader, 'Area')) {
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.attic.Area = decimal.valueOf(reader.getText());
                                        }
                                    }

                                    //AtticFloorInsulation - start
                                    if (elementStart(reader, 'AtticFloorInsulation')) {
                                        //create new afi
                                        entry.afi = new HPXML.AtticFloorInsulation();
                                        while (elementNotEnd(reader, 'AtticFloorInsulation')) {
                                            reader.next();
                                            if (elementStart(reader, 'SystemIdentifier')) {
                                                String thisValue = reader.getAttributeValue(null, 'id');
                                                entry.afi.SystemIdentifier = string.valueOf(thisValue);
                                                entry.attic.afiSystemIdentifier = string.valueOf(thisValue);
                                                entry.afi.SameAs = reader.getAttributeValue(null, 'sameas');
                                            }
                                            if (elementStart(reader, 'AssemblyEffectiveRValue')) {
                                                reader.next();
                                                if (reader.hasText()) {
                                                    entry.afi.AssemblyEffectiveRValue = decimal.valueOf(reader.getText());
                                                    entry.attic.afiAssemblyEffectiveRValue = decimal.valueOf(reader.getText());
                                                }
                                            }
                                            if (elementStart(reader, 'Layer')) {
                                                while (elementNotEnd(reader, 'Layer')) {
                                                    reader.next();
                                                    if (elementStart(reader, 'NominalRValue')) {
                                                        reader.next();
                                                        if (reader.hasText()) {
                                                            entry.afi.NominalRValue = decimal.valueOf(reader.getText());
                                                            entry.attic.afiNominalRValue = decimal.valueOf(reader.getText());
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        //add atticfloorinsulation to list of afis
                                        afis.add(entry.afi);
                                        //hasAFI = 1;
                                    }
                                    //AtticFloorInsulation - end

                                    //AtticRoofInsulation - start
                                    if (elementStart(reader, 'AtticRoofInsulation')) {
                                        //create new afi
                                        entry.ari = new HPXML.AtticRoofInsulation();
                                        while (elementNotEnd(reader, 'AtticRoofInsulation')) {
                                            reader.next();
                                            if (elementStart(reader, 'SystemIdentifier')) {
                                                String thisValue = reader.getAttributeValue(null, 'id');
                                                entry.ari.SystemIdentifier = string.valueOf(thisValue);
                                                entry.attic.ariSystemIdentifier = string.valueOf(thisValue);
                                                entry.ari.SameAs = reader.getAttributeValue(null, 'sameas');
                                            }
                                            if (elementStart(reader, 'AssemblyEffectiveRValue')) {
                                                reader.next();
                                                if (reader.hasText()) {
                                                    entry.ari.AssemblyEffectiveRValue = decimal.valueOf(reader.getText());
                                                    entry.attic.ariAssemblyEffectiveRValue = decimal.valueOf(reader.getText());
                                                }
                                            }
                                            if (elementStart(reader, 'NominalRValue')) {
                                                reader.next();
                                                if (reader.hasText()) {
                                                    entry.attic.ariNominalRValue = decimal.valueOf(reader.getText());
                                                }
                                            }
                                        }
                                        //add atticroofinsulation to list of aris
                                        aris.add(entry.ari);
                                        //hasARI = 1;
                                    }
                                    //AtticRoofInsulation - end

                                }
                                //add attic to list of attics
                                attics.add(entry.attic);
                                entry.attics.add(entry.attic);
                                //hasAttic = 1;
                            }
                        }
                    }
                    //Attic - end
                    //Foundation - start
                    if (elementStart(reader, 'Foundation')) {
                        //create new foundation
                        entry.foundation = new HPXML.Foundation();
                        entry.foundation.BuildingId = entry.building.SystemIdentifier;
                        reader.nextTag();
                        if (elementStart(reader, 'SystemIdentifier')) {
                            String thisValue = reader.getAttributeValue(null, 'id');
                            entry.foundation.SystemIdentifier = string.valueOf(thisValue);
                            entry.foundation.SameAs = reader.getAttributeValue(null, 'sameas');
                        }
                        while (elementNotEnd(reader, 'Foundation')) {
                            reader.next();
                            String foundationType = '';
                            if (elementStart(reader, 'FoundationType')) {
                                reader.nextTag();
                                if (reader.getEventType() == XmlTag.START_ELEMENT)
                                    entry.foundation.Type = string.valueOf(reader.getLocalName());
                                    entry.building.FoundationType = string.valueOf(reader.getLocalName());
                                    if(string.valueOf(reader.getLocalName()) == 'SlabOnGrade')
                                        foundationType = 'SlabOnGrade';
                            }

                            // FoundationWall
                             if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'FoundationWall') {
                                 reader.nextTag();
                                 if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'SystemIdentifier') {
                                    String thisValue = reader.getAttributeValue(null, 'id');
                                    entry.foundation.foundationWallSystemIdentifier = string.valueOf(thisValue);
                                 }
                            }

                            //FrameFloorInsulation - start
                            if (elementStart(reader, 'FrameFloor')) {
                                //create new framefloorinsulation
                                entry.framefloorinsulation = new HPXML.FrameFloorInsulation();
                                reader.nextTag();
                                if (elementStart(reader, 'SystemIdentifier')) {
                                    String thisValue = reader.getAttributeValue(null, 'id');
                                    entry.framefloorinsulation.FrameFloorSystemIdentifier = string.valueOf(thisValue);
                                    entry.foundation.FrameFloorSystemIdentifier = string.valueOf(thisValue);
                                    entry.foundation.SameAs = reader.getAttributeValue(null, 'sameas');
                                }

                                while (elementNotEnd(reader, 'FrameFloor')) {
                                    reader.next();
                                    //only get framefloor if foundationtype is not slabongrade
                                    if(foundationType == '') {
                                        if (elementStart(reader, 'Area')) {
                                            reader.next();
                                            if (reader.hasText()) {
                                                entry.foundation.Area = decimal.valueOf(reader.getText());
                                            }
                                        }
                                    }

                                    if (elementStart(reader, 'Insulation')) {
                                        reader.nextTag();
                                        if (elementStart(reader, 'SystemIdentifier')) {
                                            String thisValue = reader.getAttributeValue(null, 'id');
                                            entry.foundation.FrameFloorInsulationSystemIdentifier = string.valueOf(thisValue);
                                        }

                                        while (elementNotEnd(reader, 'Insulation')) {
                                            reader.next();
                                            if (elementStart(reader, 'AssemblyEffectiveRValue')) {
                                                reader.next();
                                                if (reader.hasText()) {
                                                    entry.framefloorinsulation.AssemblyEffectiveRValue =
                                                        decimal.valueOf(reader.getText());
                                                    entry.foundation.AssemblyEffectiveRValue =
                                                        decimal.valueOf(reader.getText());
                                                }
                                            }
                                            //only get framefloor if foundationtype is not slabongrade
                                            if(foundationType == '') {
                                                if (elementStart(reader, 'NominalRValue')) {
                                                    reader.next();
                                                    if (reader.hasText()) {
                                                        entry.foundation.NominalRValue = decimal.valueOf(reader.getText());
                                                    }
                                                }
                                            }//end of framefloor condition
                                        }
                                    }

                                }
                                //add framefloorinsulation to list of framefloorinsulations
                                framefloorinsulations.add(entry.framefloorinsulation);
                                //hasFrameFloorInsulation = 1;
                            }
                            //FrameFloorInsulation - end
                        }
                        //add attic to list of attics
                        foundations.add(entry.foundation);
                        buildingsSet.add('foundation');
                        entry.foundations.add(entry.foundation);
                        //hasFoundation = 1;
                     }
                    //Foundation - end
                    //ModeledUsage - start
                    if (elementStart(reader, 'ModeledUsage')) {
                        //create new modeledusage
                        entry.modeledusage = new HPXML.ModeledUsage();
                        entry.modeledusage.BuildingId = entry.building.SystemIdentifier;
                        while (elementNotEnd(reader, 'ModeledUsage')) {
                            reader.next();
                            if (elementStart(reader, 'AnnualConsumption')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.modeledusage.AnnualConsumption = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'BaseLoad')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.modeledusage.BaseLoad = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'EnergyType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.modeledusage.EnergyType = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'EndUse')) {
                                reader.next();
                                String EndUseText = string.valueOf(reader.getText());
                                reader.nextTag();reader.nextTag();
                                reader.next();
                                if (reader.hasText()) {
                                    if(EndUseText == 'Heating')
                                        entry.modeledusage.Heating = decimal.valueOf(reader.getText());
                                    if(EndUseText == 'Cooling')
                                        entry.modeledusage.Cooling = decimal.valueOf(reader.getText());
                                    if(EndUseText == 'Other')
                                        entry.modeledusage.Other = decimal.valueOf(reader.getText());
                                    if(EndUseText == 'HotWater')
                                        entry.modeledusage.HotWater = decimal.valueOf(reader.getText());
                                    if(EndUseText == 'SolarThermal')
                                        entry.modeledusage.SolarThermal = decimal.valueOf(reader.getText());
                                    if(EndUseText == 'PV') {
                                        hasPhotovoltaics = true;
                                    }
                                    if(EndUseText == 'Appliance')
                                        entry.modeledusage.Appliance = decimal.valueOf(reader.getText());
                                    if(EndUseText == 'Lighting')
                                        entry.modeledusage.Lighting = decimal.valueOf(reader.getText());
                                }
                            }
                        }
                        //add atticroofinsulation to list of aris
                        modeledusages.add(entry.modeledusage);
                        entry.modeledusages.add(entry.modeledusage);
                        //hasModeledUsage = 1;
                    }
                    //ModeledUsage - end
                    //PrimaryHeating and PrimaryCooling - start
                    if (elementStart(reader, 'PrimaryHeatingSystem')) {
                        PrimaryHeatingId = reader.getAttributeValue(null, 'idref');
                    }
                    if (elementStart(reader, 'PrimaryCoolingSystem')) {
                        PrimaryCoolingId = reader.getAttributeValue(null, 'idref');
                    }
                    //PrimaryHeating and PrimaryCooling - end
                    //HeatingSystem - start
                    if (elementStart(reader, 'HeatingSystem')) {
                        //create new heatingsystem
                        entry.heatingsystem = new HPXML.HeatingSystem();
                        entry.heatingsystem.BuildingId = entry.building.SystemIdentifier;
                        while (elementNotEnd(reader, 'HeatingSystem')) {
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.heatingsystem.SystemIdentifier = string.valueOf(thisValue);
                                entry.heatingsystem.SameAs = reader.getAttributeValue(null, 'sameas');
                                if (thisValue == PrimaryHeatingId)
                                    entry.heatingsystem.isPrimary = 1;
                            }
                            if (elementStart(reader, 'HeatingCapacity')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.heatingsystem.HeatingCapacity = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'FractionHeatLoadServed')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.heatingsystem.FractionHeatLoadServed = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'HeatingSystemFuel')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.heatingsystem.HeatingSystemFuel = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'HeatingSystemType')) {
                                reader.nextTag();
                                if (reader.getEventType() == XmlTag.START_ELEMENT)
                                    entry.heatingsystem.Type = string.valueOf(reader.getLocalName());
                            }
                            if (elementStart(reader, 'Manufacturer')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.heatingsystem.Manufacturer = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelNumber')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.heatingsystem.ModelNumber = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelYear')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.heatingsystem.ModelYear = integer.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'Units')) {
                                reader.next();
                                String AnnualHeatingEfficiencyText = string.valueOf(reader.getText());
                                entry.heatingsystem.Units = AnnualHeatingEfficiencyText;
                                reader.nextTag();reader.nextTag();
                                reader.next();
                                if (reader.hasText()) {
                                    if(AnnualHeatingEfficiencyText == 'AFUE')
                                        entry.heatingsystem.AFUE = decimal.valueOf(reader.getText());
                                    if(AnnualHeatingEfficiencyText == 'COP')
                                        entry.heatingsystem.COP = decimal.valueOf(reader.getText());
                                    if(AnnualHeatingEfficiencyText == 'HSPF')
                                        entry.heatingsystem.HSPF = decimal.valueOf(reader.getText());
                                    if(AnnualHeatingEfficiencyText == 'Percent')
                                        entry.heatingsystem.Percent = decimal.valueOf(reader.getText());
                                }
                            }
                        }
                        //add heatingsystem to list of heatingsystems
                        heatingsystems.add(entry.heatingsystem);
                        entry.heatingsystems.add(entry.heatingsystem);
                        buildingsSet.add('heatingsystem');
                        //hasHeatingSystem = 1;
                    }
                    //HeatingSystem - end
                    //CoolingSystem - start
                    if (elementStart(reader, 'CoolingSystem')) {
                        //create new coolingsystem
                        entry.coolingsystem = new HPXML.CoolingSystem();
                        entry.coolingsystem.BuildingId = entry.building.SystemIdentifier;
                        entry.building.hasCooling = 1;
                        while (elementNotEnd(reader, 'CoolingSystem')) {
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.coolingsystem.SystemIdentifier = string.valueOf(thisValue);
                                entry.coolingsystem.SameAs = reader.getAttributeValue(null, 'sameas');
                                if (thisValue == PrimaryCoolingId)
                                    entry.coolingsystem.isPrimary = 1;
                            }
                            if (elementStart(reader, 'FractionCoolLoadServed')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.coolingsystem.FractionCoolLoadServed = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'CoolingCapacity')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.coolingsystem.CoolingCapacity = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'CoolingSystemType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.coolingsystem.CoolingSystemType = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'CoolingSystemFuel')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.coolingsystem.CoolingSystemFuel = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'Manufacturer')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.coolingsystem.Manufacturer = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelNumber')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.coolingsystem.ModelNumber = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelYear')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.coolingsystem.ModelYear = integer.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'AnnualCoolingEfficiency')) {
                                while (elementNotEnd(reader, 'AnnualCoolingEfficiency')) {
                                    reader.next();
                                    if (elementStart(reader, 'Units')) {
                                        reader.next();
                                        thisCoolingUnits = string.valueOf(reader.getText());                                
                                    }
                                    if (elementStart(reader, 'Value')) {
                                        reader.next();
                                        if (reader.hasText()) {
                                            Decimal thisCoolingValue = decimal.valueOf(reader.getText());
                                            if(thisCoolingUnits == 'AFUE')
                                                entry.coolingsystem.AFUE = thisCoolingValue;
                                            if(thisCoolingUnits == 'EER')
                                                entry.coolingsystem.EER = thisCoolingValue;
                                            if(thisCoolingUnits == 'HSPF')
                                                entry.coolingsystem.HSPF = thisCoolingValue;
                                            if(thisCoolingUnits == 'kWton')
                                                entry.coolingsystem.kWton = thisCoolingValue;
                                            if(thisCoolingUnits == 'SEER')
                                                entry.coolingsystem.SEER = thisCoolingValue;
                                            if(thisCoolingUnits == 'COP')
                                                entry.coolingsystem.COP = thisCoolingValue;
                                        }
                                    }
                                }
                            }
                        }
                        //add coolingsystem to list of coolingsystems
                        coolingsystems.add(entry.coolingsystem);
                        entry.coolingsystems.add(entry.coolingsystem);
                        buildingsSet.add('coolingsystem');
                        //hasCoolingSystem = 1;
                    }
                    //CoolingSystem - end
                    //WaterHeating - start
                    if (elementStart(reader, 'WaterHeatingSystem')) {
                        //create new waterheating
                        entry.waterheating = new HPXML.WaterHeating();
                        entry.waterheating.BuildingId = entry.building.SystemIdentifier;
                        while (elementNotEnd(reader, 'WaterHeatingSystem')) {
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.waterheating.SystemIdentifier = string.valueOf(thisValue);
                                entry.waterheating.SameAs = reader.getAttributeValue(null, 'sameas');
                            }
                            if (elementStart(reader, 'FuelType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.FuelType = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'EnergyFactor')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.EnergyFactor = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'HotWaterTemperature')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.HotWaterTemperature = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'Manufacturer')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.Manufacturer = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelNumber')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.ModelNumber = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelYear')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.ModelYear = integer.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'Location')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.Location = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'WaterHeaterType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.WaterHeaterType = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'TankVolume')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.TankVolume = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'HeatingCapacity')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.HeatingCapacity = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'PipeInsulated')) {
                                reader.next();
                                entry.waterheating.WaterHeaterInsulation = 1;
                            }
                            if (elementStart(reader, 'LengthofPipeInsulated')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.waterheating.LengthofPipeInsulated = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'CombustionVentingSystem')) {
                                String thisValue = reader.getAttributeValue(null, 'idref');
                                entry.building.CombustionVentilationSystem = string.valueOf(thisValue);
                            }
                        }
                        //add coolingsystem to list of coolingsystems
                        waterheatings.add(entry.waterheating);
                        entry.waterheatings.add(entry.waterheating);
                        buildingsSet.add('waterheating');
                        //hasWaterHeating = 1;
                    }
                    //WaterHeating - end
                    //HVACControl - start
                    if (elementStart(reader, 'HVACControl')) {
                        //create new hvaccontrol
                        entry.hvaccontrol = new HPXML.HVACControl();
                        entry.hvaccontrol.BuildingId = entry.building.SystemIdentifier;
                        while (elementNotEnd(reader, 'HVACControl')) {
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.hvaccontrol.SystemIdentifier = string.valueOf(thisValue);  
                                entry.hvaccontrol.SameAs = reader.getAttributeValue(null, 'sameas');             
                            }
                            if (elementStart(reader, 'SetpointTempHeatingSeason')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.hvaccontrol.SetpointTempHeatingSeason = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'SetpointTempCoolingSeason')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.hvaccontrol.SetpointTempCoolingSeason = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ControlType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.hvaccontrol.ControlType = string.valueOf(reader.getText());
                                }
                            }
                        }
                        //add hvaccontrol to list of hvaccontrols
                        hvaccontrols.add(entry.hvaccontrol);
                        entry.hvaccontrols.add(entry.hvaccontrol);
                        //hasHVACControl = 1;
                    }
                    //HVACControl - end
                    //LightingGroup - start
                    if (elementStart(reader, 'LightingGroup')) {
                        //create new lightinggroup  
                        entry.lightinggroup = new HPXML.LightingGroup(); 
                        entry.lightinggroup.BuildingId = entry.building.SystemIdentifier;  
                        while (elementNotEnd(reader, 'LightingGroup')) { 
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {     
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.lightinggroup.SystemIdentifier = string.valueOf(thisValue);      
                                entry.lightinggroup.SameAs = reader.getAttributeValue(null, 'sameas');           
                            }
                            if (elementStart(reader, 'AverageHoursPerDay')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.lightinggroup.AverageHoursPerDay = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'NumberofUnits')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.lightinggroup.NumberofUnits = integer.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'LightingType')) {
                                reader.nextTag();
                                if (reader.getEventType() == XmlTag.START_ELEMENT) 
                                     entry.lightinggroup.LightingType = string.valueOf(reader.getLocalName());
                            }
                            if (elementStart(reader, 'Location')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.lightinggroup.Location = string.valueOf(reader.getText());
                                }
                            }
                        }
                        //add lightinggroup to list of lightinggroups
                        lightinggroups.add(entry.lightinggroup);
                        entry.lightinggroups.add(entry.lightinggroup);
                        buildingsSet.add('lightinggroup');
                        //hasLightingGroup = 1;
                    }
                    //LightingGroup - end
                    //WallInsulation - start
                    if (elementStart(reader, 'Wall')) {
                        //create new wallinsulation
                        entry.wallinsulation = new HPXML.WallInsulation();   
                        entry.wallinsulation.BuildingId = entry.building.SystemIdentifier;    
                        reader.nextTag();
                        if (elementStart(reader, 'SystemIdentifier')) {   
                            String thisValue = reader.getAttributeValue(null, 'id');
                            entry.wallinsulation.WallSystemIdentifier = string.valueOf(thisValue);  
                            entry.wallinsulation.SameAs = reader.getAttributeValue(null, 'sameas');              
                        }

                        while (elementNotEnd(reader, 'Wall')) { 
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.wallinsulation.SystemIdentifier = string.valueOf(thisValue);              
                            }
                            if (elementStart(reader, 'NominalRValue')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.wallinsulation.NominalRValue = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'AssemblyEffectiveRValue')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.wallinsulation.AssemblyEffectiveRValue = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'Area')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.wallinsulation.Area = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'WallType')) {
                                reader.nextTag();
                                if (reader.getEventType() == XmlTag.START_ELEMENT) 
                                    entry.wallinsulation.Type = string.valueOf(reader.getLocalName());
                            }
                        }
                        //add wallinsulation to list of wallinsulations
                        wallinsulations.add(entry.wallinsulation);
                        entry.wallinsulations.add(entry.wallinsulation); 
                        //hasWallInsulation = 1;
                    }
                    //WallInsulation - end                             
                    //HeatPump - start
                    if (elementStart(reader, 'HeatPump')) {
                        //create new heatpump
                        entry.hp = new HPXML.HeatPump();
                        entry.hp.BuildingId = entry.building.SystemIdentifier;   
                        while (elementNotEnd(reader, 'HeatPump')) { 
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {    
                                thisHPSystemIdentifier = reader.getAttributeValue(null, 'id');  
                                thisHPSameAs = reader.getAttributeValue(null, 'sameas');       
                            }
                            if (elementStart(reader, 'HeatPumpType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    thisHPHeatPumpType = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'FractionHeatLoadServed')) {
                                reader.next();
                                if (reader.hasText()) {
                                    thisHPFractionHeatLoadServed = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'FractionCoolLoadServed')) {
                                reader.next();
                                if (reader.hasText()) {
                                    thisHPFractionCoolLoadServed = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'Manufacturer')) {
                                reader.next();
                                if (reader.hasText()) {
                                    thisHPManufacturer = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelNumber')) {
                                reader.next();
                                if (reader.hasText()) {
                                    thisHPModelNumber = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelYear')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    thisHPModelYear = integer.valueOf(reader.getText());
                                }
                            }

                            entry.hp.HeatPumpType = thisHPHeatPumpType;
                            entry.hp.FractionHeatLoadServed = thisHPFractionHeatLoadServed;
                            entry.hp.FractionCoolLoadServed = thisHPFractionCoolLoadServed;
                            entry.hp.Manufacturer = thisHPManufacturer;
                            entry.hp.ModelNumber = thisHPModelNumber;
                            entry.hp.ModelYear = thisHPModelYear;
                            entry.hp.SystemIdentifier = thisHPSystemIdentifier;
                            entry.hp.SameAs = thisHPSameAs;

                            if (elementStart(reader, 'AnnualCoolEfficiency')) { 
                                while (elementNotEnd(reader, 'AnnualCoolEfficiency')) { 
                                    reader.next();
                                    if (elementStart(reader, 'Units')) { 
                                        reader.next();
                                        thisHPUnits = string.valueOf(reader.getText());                             
                                    }
                                    if (elementStart(reader, 'Value')) { 
                                        reader.next();
                                        if (reader.hasText()) {
                                            Decimal thisHPValue = decimal.valueOf(reader.getText());
                                            if(thisHPUnits == 'AFUE')
                                                entry.hp.AFUEcool = thisHPValue;
                                            if(thisHPUnits == 'EER')
                                                entry.hp.EERcool = thisHPValue;
                                            if(thisHPUnits == 'HSPF')
                                                entry.hp.HSPFcool = thisHPValue;
                                            if(thisHPUnits == 'kWton')
                                                entry.hp.kWtoncool = thisHPValue;
                                            if(thisHPUnits == 'SEER')
                                                entry.hp.SEERcool = thisHPValue;
                                            if(thisHPUnits == 'COP')
                                                entry.hp.COPcool = thisHPValue;
                                        }
                                    }

                                }
                            }
                            if (elementStart(reader, 'AnnualHeatEfficiency')) { 
                                while (elementNotEnd(reader, 'AnnualHeatEfficiency')) {
                                    reader.next();
                                    if (elementStart(reader, 'Units')) {                 
                                        reader.next();
                                        thisHPUnits = string.valueOf(reader.getText());                             
                                    }
                                    if (elementStart(reader, 'Value')) { 
                                        reader.next();
                                        if (reader.hasText()) {
                                            Decimal thisHPValue = decimal.valueOf(reader.getText());
                                            if(thisHPUnits == 'AFUE')
                                                entry.hp.AFUEheat = thisHPValue;
                                            if(thisHPUnits == 'EER')
                                                entry.hp.EERheat = thisHPValue;
                                            if(thisHPUnits == 'HSPF')
                                                entry.hp.HSPFheat = thisHPValue;
                                            if(thisHPUnits == 'kWton')
                                                entry.hp.kWtonheat = thisHPValue;
                                            if(thisHPUnits == 'SEER')
                                                entry.hp.SEERheat = thisHPValue;
                                            if(thisHPUnits == 'COP')
                                                entry.hp.COPheat = thisHPValue;
                                        }
                                    }
                                }
                            }
                        }
                        //add heatpump to list of heatpumps
                        heatpumps.add(entry.hp);
                        entry.heatpumps.add(entry.hp);  
                        buildingsSet.add('heatpump');
                        //hasHeatPump = 1;                      
                    }
                    //HeatPump - end
                    //Window - start
                    if (elementStart(reader, 'Window')) { 
                        //create new window
                        entry.window = new HPXML.Window(); 
                        entry.window.BuildingId = entry.building.SystemIdentifier;  
                        while (elementNotEnd(reader, 'Window')) {
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {     
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.window.SystemIdentifier = string.valueOf(thisValue);         
                                entry.window.SameAs = reader.getAttributeValue(null, 'sameas');              
                            }
                            if (elementStart(reader, 'Area')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.window.Area = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'SHGC')) {   
                                reader.next();
                                if (reader.hasText()) {
                                    entry.window.SHGC = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'UFactor')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.window.UFactor = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'GlassLayers')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.window.GlassLayers = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'FrameType')) {
                                reader.nextTag();
                                if (reader.getEventType() == XmlTag.START_ELEMENT) 
                                    entry.window.FrameType = string.valueOf(reader.getLocalName());
                            }
                        }
                        //add attic to window of windows
                        windows.add(entry.window);
                        entry.windows.add(entry.window);
                        buildingsSet.add('window');
                        //hasWindow = 1;
                     }
                    //Window - end
                    //Roof - start
                    if (elementStart(reader, 'Roof')) {
                        //create new roof
                        entry.roof = new HPXML.Roof();  
                        entry.roof.BuildingId = entry.building.SystemIdentifier;   
                        while (elementNotEnd(reader, 'Roof')) {    
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {     
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.roof.SystemIdentifier = string.valueOf(thisValue);     
                                entry.roof.SameAs = reader.getAttributeValue(null, 'sameas');            
                            }
                            if (elementStart(reader, 'RadiantBarrier')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.roof.RadiantBarrier = boolean.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'RoofType')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.roof.RoofType = string.valueOf(reader.getText());
                                }
                            }
                        }
                        //add roof to list of roofs
                        roofs.add(entry.roof);
                        buildingsSet.add('roof');
                        hasRoof = 1;
                     }
                    //Roof - end
                    //DuctLeakageMeasurement - start
                    if (elementStart(reader, 'HVACDistribution')) {  
                        entry.hvacdistribution = new HPXML.hvacdistribution();   
                        entry.hvacdistribution.BuildingId = entry.building.SystemIdentifier;     
                        reader.nextTag();
                        if (elementStart(reader, 'SystemIdentifier')) {    
                            String thisValue = reader.getAttributeValue(null, 'id');
                            entry.hvacdistribution.SystemIdentifier = string.valueOf(thisValue); 
                            entry.hvacdistribution.SameAs = reader.getAttributeValue(null, 'sameas');            
                        }
                        //create new ductleakagemeasurement
                        entry.ductleakagemeasurement = new HPXML.DuctLeakageMeasurement(); 
                        entry.ductleakagemeasurement.SystemIdentifier = entry.hvacdistribution.SystemIdentifier;  
                        while (elementNotEnd(reader, 'HVACDistribution')) {     
                            reader.next();
                            if (elementStart(reader, 'ConditionedFloorAreaServed')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.hvacdistribution.ConditionedFloorAreaServed = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'AnnualHeatingDistributionSystemEfficiency')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.hvacdistribution.AnnualHeatingDistributionSystemEfficiency = decimal.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'AnnualCoolingDistributionSystemEfficiency')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.hvacdistribution.AnnualCoolingDistributionSystemEfficiency = decimal.valueOf(reader.getText());
                                }
                            }
                            //Duct - start
                            if (elementStart(reader, 'Ducts')) { 
                                //create new duct
                                entry.duct = new HPXML.Duct(); 
                                entry.duct.SystemIdentifier = entry.hvacdistribution.SystemIdentifier;  
                                while (elementNotEnd(reader, 'Ducts')) {
                                    reader.next();
                                    if (elementStart(reader, 'ConditionedFloorAreaServed')) { 
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.duct.ConditionedFloorAreaServed = decimal.valueOf(reader.getText());
                                        }
                                    }
                                    if (elementStart(reader, 'DuctInsulationRValue')) { 
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.duct.DuctInsulationRValue = decimal.valueOf(reader.getText());
                                        }
                                    }
                                    if (elementStart(reader, 'DuctLocation')) {
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.duct.DuctLocation = string.valueOf(reader.getText());
                                        }
                                    }
                                    if (elementStart(reader, 'FractionDuctArea')) {
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.duct.FractionDuctArea = decimal.valueOf(reader.getText());
                                        }
                                    }
                                }
                                //add duct to list of ducts
                                ducts.add(entry.duct);
                                entry.ducts.add(entry.duct);
                                hasDuct = 1;
                             }
                            //Duct - end
                            if (elementStart(reader, 'DuctLeakage')) { 
                                while (elementNotEnd(reader, 'DuctLeakage')) {        
                                    reader.next();
                                    if (elementStart(reader, 'Units')) { 
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.ductleakagemeasurement.DuctLeakageUnits = string.valueOf(reader.getText());
                                        }
                                    }
                                    if (elementStart(reader, 'Value')) { 
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.ductleakagemeasurement.DuctLeakageValue = decimal.valueOf(reader.getText());
                                        }
                                    }
                                }
                            }
                        }
                        //add ductleakagemeasurement to list of ductleakagemeasurements
                        ductleakagemeasurements.add(entry.ductleakagemeasurement);
                        entry.ductleakagemeasurements.add(entry.ductleakagemeasurement);  
                        hvacdistributions.add(entry.hvacdistribution);
                        entry.hvacdistributions.add(entry.hvacdistribution);  
                        buildingsSet.add('hvacdistribution');
                        hasDuctLeakageMeasurement = 1;
                        //hasHVACDistribution = 1;
                     }
                    //DuctLeakageMeasurement - end 
                    //Pool - start
                    if (elementStart(reader, 'Pool')) { 
                        //create new pool   
                        entry.pool = new HPXML.Pool();  
                        entry.pool.BuildingId = entry.building.SystemIdentifier;    
                        reader.nextTag();
                        if (elementStart(reader, 'SystemIdentifier')) {     
                            String thisValue = reader.getAttributeValue(null, 'id');
                            entry.pool.SystemIdentifier = string.valueOf(thisValue);          
                            entry.pool.SameAs = reader.getAttributeValue(null, 'sameas');            
                        }
                        while (elementNotEnd(reader, 'Pool')) {      
                            reader.next();

                            //PoolPump - start
                            if (elementStart(reader, 'PoolPump')) {  
                                while (elementNotEnd(reader, 'PoolPump')) {        
                                    reader.next();
                                    if (elementStart(reader, 'SystemIdentifier')) {    
                                        thisPoolId = reader.getAttributeValue(null, 'id');  
                                        thisPoolSameAs = reader.getAttributeValue(null, 'sameas');                          
                                    }
                                    if (elementStart(reader, 'Type')) {    
                                        reader.next();
                                        if (reader.hasText()) {
                                            thisPoolType = string.valueOf(reader.getText());                        
                                        }
                                    }
                                    if (elementStart(reader, 'RatedHorsepower')) { 
                                        reader.next();
                                        if (reader.hasText()) {
                                            thisPoolRatedHorsepower = decimal.valueOf(reader.getText());                            
                                        }
                                    }
                                    if (elementStart(reader, 'SpeedSetting')) { 
                                        reader.next();
                                        if (reader.hasText()) {
                                            thisPoolSpeedSetting = string.valueOf(reader.getText());                            
                                        }
                                    }
                                    if (elementStart(reader, 'PumpSpeed')) { 
                                        //create new poolpump
                                        entry.poolpump = new HPXML.PoolPump();   
                                        entry.poolpump.SystemIdentifier = thisPoolId; 
                                        entry.poolpump.SameAs = thisPoolSameAs;  
                                        entry.poolpump.PoolSystemIdentifier = entry.pool.SystemIdentifier;  
                                        entry.poolpump.HoursPerDay = thisPoolHoursPerDay;     
                                        entry.poolpump.Type = thisPoolType;
                                        entry.poolpump.RatedHorsepower = thisPoolRatedHorsepower;
                                        entry.poolpump.SpeedSetting = thisPoolSpeedSetting;

                                        while (elementNotEnd(reader, 'PumpSpeed')) { 
                                            reader.next();
                                            if (elementStart(reader, 'Power')) { 
                                                reader.next();
                                                if (reader.hasText()) {
                                                    entry.poolpump.PumpSpeedPower = decimal.valueOf(reader.getText());
                                                }
                                            }
                                            if (elementStart(reader, 'HoursPerDay')) { 
                                                reader.next();
                                                if (reader.hasText()) {
                                                    entry.poolpump.HoursPerDay = decimal.valueOf(reader.getText());
                                                }
                                            }
                                        }
                                        //add poolpump to list of poolpumps
                                        poolpumps.add(entry.poolpump);
                                        entry.poolpumps.add(entry.poolpump);
                                    }
                                }
                                hasPoolPump = 1;
                             }
                            //PoolPump - end
                        }
                        //add pool to list of pools
                        pools.add(entry.pool);
                        entry.pools.add(entry.pool); 
                        buildingsSet.add('pool');
                    }
                    //Pool - end
                    //Refrigerator - start
                    if (elementStart(reader, 'Refrigerator')) { 
                        //create new refrigerator
                        entry.refrigerator = new HPXML.Refrigerator();   
                        entry.refrigerator.BuildingId = entry.building.SystemIdentifier;    
                        while (elementNotEnd(reader, 'Refrigerator')) {
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {  
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.refrigerator.SystemIdentifier = string.valueOf(thisValue); 
                                entry.refrigerator.SameAs = reader.getAttributeValue(null, 'sameas');            
                            }
                            if (elementStart(reader, 'PrimaryIndicator')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.refrigerator.PrimaryIndicator = boolean.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'ModelYear')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.refrigerator.ModelYear = integer.valueOf(reader.getText());
                                }
                            }
                        }
                        //add refrigerator to list of refrigerators
                        refrigerators.add(entry.refrigerator);
                        entry.refrigerators.add(entry.refrigerator); 
                        buildingsSet.add('refrigerator');
                        //hasRefrigerator = 1;
                     }
                    //Refrigerator - end 
                    //VentilationFan - start
                    if (elementStart(reader, 'VentilationFan')) {
                        //create new ventilationfan
                        entry.ventilationfan = new HPXML.VentilationFan();   
                        entry.ventilationfan.BuildingId = entry.building.SystemIdentifier; 
                        while (elementNotEnd(reader, 'VentilationFan')) { 
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifier')) {
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.ventilationfan.SystemIdentifier = string.valueOf(thisValue);  
                                entry.ventilationfan.SameAs = reader.getAttributeValue(null, 'sameas');              
                            }
                            if (elementStart(reader, 'UsedForWholeBuildingVentilation')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.ventilationfan.UsedForWholeBuildingVentilation = 
                                        boolean.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'UsedForSeasonalCoolingLoadReduction')) { 
                                reader.next();
                                if (reader.hasText()) {
                                    entry.ventilationfan.UsedForSeasonalCoolingLoadReduction = 
                                        boolean.valueOf(reader.getText());
                                }
                            }
                        }
                        //add refrigerator to list of refrigerators
                        ventilationfans.add(entry.ventilationfan);
                        entry.ventilationfans.add(entry.ventilationfan); 
                        buildingsSet.add('ventilationfan');
                        //hasVentilationFan = 1;
                     }
                    //VentilationFan - end 
                }
                buildings.add(entry.building);
                buildingMap.put(entry.building.SystemIdentifier, buildingsSet); 
                entry.buildings.add(entry.building);           
            }
            //BUILDING - END     

            //PROJECT - START
            if (elementStart(reader, 'Project')) { 
                //create new project
                entry.project = new HPXML.Project();
                while (elementNotEnd(reader, 'Project')) { 
                    reader.next();
                    if (elementStart(reader, 'BuildingID')) {    
                        String thisValue = reader.getAttributeValue(null, 'id');
                        entry.project.BuildingId = string.valueOf(thisValue);           
                    }
                    if (elementStart(reader, 'ProjectID')) {     
                        String thisValue = reader.getAttributeValue(null, 'id');
                        entry.project.SystemIdentifier = string.valueOf(thisValue);             
                    }
                    if (elementStart(reader, 'Title')) {                                                     
                        reader.next();  
                        if (reader.hasText()) {
                            entry.project.Title = string.valueOf(reader.getText());
                        }
                    }
                    //ProjectStatus - start
                    if (elementStart(reader, 'ProjectStatus')) {
                        while (elementNotEnd(reader, 'ProjectStatus')) { 
                            reader.next();
                            if (elementStart(reader, 'EventType')) {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.project.ProjectStatusEventType = string.valueOf(reader.getText());
                                    if(string.valueOf(reader.getText()) == 'audit')
                                        entry.building.ProjectStatus = 'audit';

                                    if(isPostAppStatus == true && string.valueOf(reader.getText()) == 
                                            'job completion testing/final inspection'){
                                        entry.project.ProjectStatus = 'retrofit';
                                        //hasRetrofit = 1;
                                    }
                                    if(isPostAppStatus == false && string.valueOf(reader.getText()) == 
                                            'proposed workscope'){
                                        entry.project.ProjectStatus = 'retrofit';
                                        //hasRetrofit = 1;
                                    }
                                }
                            }
                        }
                    }
                    //ProjectStatus - end              
                    //EnergySavingsInfo - start
                    if (elementStart(reader, 'EnergySavingsInfo') && measureFound == 0) {
                        while (elementNotEnd(reader, 'EnergySavingsInfo')) { 
                            reader.next();

                            if (elementStart(reader, 'DemandSavings')) {
                                reader.next();
                                entry.energySavingsInfo = new HPXML.EnergySavingsInfo();
                                if (reader.hasText()) {
                                    entry.energySavingsInfo.DemandSavings = String.valueOf(reader.getText());
                                }
                             }

                            if (elementStart(reader, 'Fuel')) {
                                reader.next();
                                if (reader.hasText()) {
                                    thisFuel = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'Units')) {
                                reader.next();
                                if (reader.hasText()) {
                                    thisUnits = string.valueOf(reader.getText());
                                }
                            }
                            if (elementStart(reader, 'EndUseSavings')) {
                                //create new fuelsaving
                                entry.fuelsaving = new HPXML.FuelSavings();
                                while (elementNotEnd(reader, 'EndUseSavings')) {
                                    reader.next();
                                    entry.fuelsaving.ProjectId = entry.project.SystemIdentifier;
                                    entry.fuelsaving.EndUseFuel = thisFuel;
                                    entry.fuelsaving.EndUseUnits = thisUnits;

                                    if (elementStart(reader, 'EndUse')) {
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.fuelsaving.EndUse = string.valueOf(reader.getText());
                                        }
                                    }
                                    if (elementStart(reader, 'EndUseValue')) {
                                        reader.next();
                                        if (reader.hasText()) {
                                            entry.fuelsaving.EndUseValue = decimal.valueOf(reader.getText());
                                        }
                                    }
                                }
                                //add fuelsaving to list of fuelsavings
                                fuelsavings.add(entry.fuelsaving);
                                entry.fuelsavings.add(entry.fuelsaving);
                                //hasFuelSavings = 1;
                            }
                        }
                    }
                    //EnergySavingsInfo - end

                    //Measure - start 
                    if (elementStart(reader, 'Measure')) {
                        //create new measure
                        entry.measure = new HPXML.Measure();   
                        entry.measure.ProjectId = entry.project.SystemIdentifier;
                        //measure found - set marker
                        measureFound = 1;
                        while (elementNotEnd(reader, 'Measure')) {
                            reader.next();
                            if (elementStart(reader, 'SystemIdentifiersInfo')) {
                                String thisValue = reader.getAttributeValue(null, 'id');
                                entry.measure.SystemIdentifier = string.valueOf(thisValue);             
                            }
                            if (elementStart(reader, 'MeasureDescription')) {
                                reader.next();
                                entry.measure.MeasureDescription = string.valueOf(reader.getText());
                            }
                        }
                        //add measure to list of measures
                        measures.add(entry.measure);
                        entry.measures.add(entry.measure); 
                        //hasMeasure = 1;
                     }
                    //Measure - end

                }
                //add project to list of projects
                projects.add(entry.project);
                entry.projects.add(entry.project); 
                //hasProject = 1; 
            }
            //PROJECT - END
        }

        if (isPostAppStatus == true) {
            if (hasPostAppRetrofit == 1) {
                hasRetrofit = 1;
            }
        } else if (hasPreAppRetrofit == 1) {
                hasRetrofit = 1;
        }

        //check if xml should be validated
        Integer validationLevel = getValidationLevel();
        if (validationLevel != 0) {

            ValidateHPXMLWrapper validateHPXML = new ValidateHPXMLWrapper();
            validateHPXML.customer = entry.customer;
            validateHPXML.businesscontact = entry.businesscontact;
            validateHPXML.software = entry.software;
            validateHPXML.buildings = buildings;
            validateHPXML.aims = aims;
            validateHPXML.attics = attics;
            validateHPXML.foundations = foundations;
            validateHPXML.measures = measures;
            validateHPXML.modeledusages = modeledusages;
            validateHPXML.heatingsystems = heatingsystems;
            validateHPXML.coolingsystems = coolingsystems;
            validateHPXML.waterheatings = waterheatings;
            validateHPXML.hvaccontrols = hvaccontrols;
            validateHPXML.lightinggroups = lightinggroups;
            validateHPXML.lightingcontrols = lightingcontrols;
            validateHPXML.wallinsulations = wallinsulations;
            validateHPXML.componentsList = componentsList;
            validateHPXML.programsList = programsList;
            validateHPXML.fuelsavings = fuelsavings;
            validateHPXML.heatpumps = heatpumps;
            validateHPXML.windows = windows;
            validateHPXML.ducts = ducts;
            validateHPXML.roofs = roofs;
            validateHPXML.ductleakagemeasurements = ductleakagemeasurements;
            validateHPXML.pools = pools;
            validateHPXML.poolpumps = poolpumps;
            validateHPXML.refrigerators = refrigerators;
            validateHPXML.ventilationfans = ventilationfans;
            validateHPXML.hvacdistributions = hvacdistributions;
            validateHPXML.projects = projects;
            validateHPXML.buildingMap = buildingMap;
            validateHPXML.hasRetrofit = hasRetrofit;
            validateHPXML.energySavingsInfo = entry.energySavingsInfo;
            validateHPXML.isPostApp = isPostAppStatus;
            validateHPXML.hasPhotovoltaics = hasPhotovoltaics;

            result = validateHPXML(validateHPXML);
        }


        return result;
    }

    public class ValidateHPXMLWrapper {
        public HPXML.Customer customer;
        public HPXML.BusinessContact businesscontact;
        public HPXML.Software software;
        public List<HPXML.Building> buildings;
        public List<HPXML.AirInfiltrationMeasurement> aims;
        public List<HPXML.Attic> attics;
        public List<HPXML.Foundation> foundations;
        public List<HPXML.Measure> measures;
        public List<HPXML.ModeledUsage> modeledusages;
        public List<HPXML.HeatingSystem> heatingsystems;
        public List<HPXML.CoolingSystem> coolingsystems;
        public List<HPXML.WaterHeating> waterheatings;
        public List<HPXML.HVACControl> hvaccontrols;
        public List<HPXML.LightingGroup> lightinggroups;
        public List<HPXML.LightingControl> lightingcontrols;
        public List<HPXML.WallInsulation> wallinsulations;
        public List<String> componentsList;
        public List<String> programsList;
        public List<HPXML.FuelSavings> fuelsavings;
        public List<HPXML.HeatPump> heatpumps;
        public List<HPXML.Window> windows;
        public List<HPXML.Duct> ducts;
        public List<HPXML.Roof> roofs;
        public List<HPXML.DuctLeakageMeasurement> ductleakagemeasurements;
        public List<HPXML.Pool> pools;
        public List<HPXML.PoolPump> poolpumps;
        public List<HPXML.Refrigerator> refrigerators;
        public List<HPXML.VentilationFan> ventilationfans;
        public List<HPXML.HVACDistribution> hvacdistributions;
        public List<HPXML.Project> projects;
        public Map<String, Set<String>> buildingMap;
        public Integer hasRetrofit;
        public HPXML.EnergySavingsInfo energySavingsInfo;
        public Boolean isPostApp = false;
        public Boolean hasPhotovoltaics = false;
    }

    public List<String> validateHPXML (ValidateHPXMLWrapper validateHPXML) {
        List<String> result = new List<String>();
        Set<String> energyTypeErrors = new Set<String>();
        Boolean hasElectricity = false;
        Set<String> acceptableEnergyType = new Set<String>{ELECTRICITY_ENERGY_TYPE, NATURAL_GAS_ENERGY_TYPE, 'fuel oil',
                'fuel oil 1', 'fuel oil 2', 'fuel oil 4', 'fuel oil 5/6', PROPANE_ENERGY_TYPE, 'kerosene','diesel'};
        Integer validationLevel = getValidationLevel();

        //VALIDATION - START
        //SOFTWARE VALIDATION - start
        Integer validSoftware = getSoftwareValidation(validateHPXML.software.SoftwareProgramUsed, 
                validateHPXML.software.SoftwareProgramVersion);

        if (validSoftware == 1) {

            //no required fields validation - start
            if (validationLevel > 0) {
                //STATUS VALIDATION - start
                if (validateHPXML.hasRetrofit == 0) {
                    if (validateHPXML.isPostApp) {
                        result.add('Building with retrofit status is required.');
                    } else {
                        result.add('Building with audit status is required.');
                    }
                } else {
                    if (validateHPXML.hasPhotovoltaics) {
                        result.add(PHOTOVOLTAICS_ERROR);
                    }
                    if (validateHPXML.software.XMLGeneratedBy == NULL || validateHPXML.software.XMLGeneratedBy == '')
                        result.add('Software program used is required.');
                    if (validateHPXML.software.SoftwareProgramVersion == NULL 
                            || validateHPXML.software.SoftwareProgramVersion == '')
                        result.add('Software information: Software program version is required.');
                    if (validateHPXML.businesscontact.FirstName == NULL
                            || validateHPXML.businesscontact.FirstName == '')
                        result.add('Contractor Information: First name is required.');
                    if (validateHPXML.businesscontact.LastName == NULL || validateHPXML.businesscontact.LastName == '')
                        result.add('Contractor Information: Last name is required.');
                    if (validateHPXML.businesscontact.Email == NULL || validateHPXML.businesscontact.Email == '')
                        result.add('Contractor Information: Email is required.');
                    if (validateHPXML.customer.FirstName == NULL || validateHPXML.customer.FirstName == '')
                        result.add('Customer Information: First name is required.');
                    if (validateHPXML.customer.LastName == NULL || validateHPXML.customer.LastName == '')
                        result.add('Customer Information: Last name is required.');
                    if (validateHPXML.energySavingsInfo == NULL
                            || String.isBlank(validateHPXML.energySavingsInfo.DemandSavings)) {
                        result.add(DEMAND_SAVINGS_REQUIRED_ERROR);
                    } else {
                        try {
                            // accepts all valid xs:double values, including e-notation, except 'INF', '-INF', or 'NaN'
                            Decimal demandSavings = Decimal.valueOf(
                                    Double.valueOf(validateHPXML.energySavingsInfo.DemandSavings));
                        } catch (Exception e) {
                            result.add(DEMAND_SAVINGS_INVALID_ERROR);
                        }
                    }

                    for (HPXML.Building b: validateHPXML.buildings) {

                        Integer hasAtticArea = 0;
                        Integer hasAtticFloorInsulationValue = 0;
                        Integer hasAtticRoofInsulationValue = 0;
                        Integer hasAtticRoofInsulationNominalRValue = 0;
                        Integer hasFoundationType = 0;
                        Integer hasMUAnnualConsumption = 0;
                        Integer hasMUBaseLoad = 0;
                        Integer hasMUEnergyType = 0;
                        Integer hasMUConsumptionEndUse = 0;
                        Integer hasHSHeatingCapacity = 0;
                        Integer hasHSFractionHeatLoadServed = 0;
                        Integer hasHSAnnualHeatingEfficiency = 0;
                        Integer hasCSFractionCoolLoadServed = 0;
                        Integer hasWHFuelType = 0;
                        Integer hasWHEnergyFactor = 0;
                        Integer hasWHHotWaterTemperature = 0;
                        Integer hasHVACControlCooling = 0;
                        Integer hasHVACControlHeating = 0;
                        Integer hasHVACControlControlType = 0;
                        Integer hasLGHours = 0;
                        Integer hasWINominalRValue = 0;
                        Integer hasWIAssemblyEffectiveRValue = 0;
                        Integer hasWIArea = 0;
                        Integer hasWIType = 0;
                        Integer hasFrameFloorInsulationValue = 0;
                        Integer hasAIMHousePressure = 0;
                        Integer hasAIMUOM = 0;
                        Integer hasAIMAirLeakage = 0;
                        Integer hasProjTitle = 0;
                        Integer hasMeasureDescription = 0;
                        Integer hasHSFuel = 0;
                        Integer hasHSType = 0;
                        Integer hasHSFHLS = 0;
                        Integer hasFuelSavingsEndUse = 0;
                        Integer hasFuelSavingsEndUseValue = 0;
                        Integer hasFuelSavingsEndUseUnits = 0;
                        Integer hasFuelSavingsEndUseFuel = 0;
                        Integer hasCSCoolingCapacity = 0;
                        Integer hasCSCoolingSystemType = 0;
                        Integer hasCSCoolingSystemFuel = 0;
                        Integer hasCSManufacturer = 0;
                        Integer hasCSModelNumber = 0;
                        Integer hasCSModelYear = 0;
                        Integer hasCSCoolingValue = 0;
                        Integer hasHSManufacturer = 0;
                        Integer hasHSModelNumber = 0;
                        Integer hasHSModelYear = 0;
                        Integer hasHSUnits = 0;
                        Integer hasWHManufacturer = 0;
                        Integer hasWHModelNumber = 0;
                        Integer hasWHModelYear = 0;
                        Integer hasWHLocation = 0;
                        Integer hasWHWaterHeaterType = 0;
                        Integer hasWHHeatingCapacity = 0;
                        Integer hasWHTankVolume = 0;
                        Integer hasHPFractionCoolLoadServed = 0;
                        Integer hasHPFractionHeatLoadServed = 0;
                        Integer hasHPHeatPumpType = 0;
                        Integer hasHPManufacturer = 0;
                        Integer hasHPModelNumber = 0;
                        Integer hasHPModelYear = 0;
                        Integer hasHPCooling = 0;
                        Integer hasHPHeating = 0;
                        Integer hasWindowArea = 0;
                        Integer hasWindowSHGC = 0;
                        Integer hasWindowFrameType = 0;
                        Integer hasWindowUFactor = 0;
                        Integer hasRoofRadiantBarrier = 0;
                        Integer hasRoofRoofType = 0;
                        Integer hasFoundationArea = 0;
                        Integer hasFoundationNominalRValue = 0;
                        Integer hasLGNumberofUnits = 0;
                        Integer hasLGLightingType = 0;
                        Integer hasLGLocation = 0;
                        Integer hasRefPrimaryIndicator = 0;
                        Integer hasRefModelYear = 0;
                        Integer hasWHLengthofPipeInsulated = 0;
                        Integer hasVFUsedForWholeBuildingVentilation = 0;
                        Integer hasVFUsedForSeasonalCoolingLoadReduction = 0;
                        Integer hasDuctConditionedFloorAreaServed = 0;
                        Integer hasDuctInsulationRValue = 0;
                        Integer hasDuctLocation = 0;
                        Integer hasDuctFractionDuctArea = 0;
                        Integer hasDLMUnits = 0;
                        Integer hasDLMValue = 0;
                        Integer hasPPHoursPerDay = 0;
                        Integer hasPPType = 0;
                        Integer hasPPRatedHorsepower = 0;
                        Integer hasPPSpeedSetting = 0;
                        Integer hasPPPumpSpeedPower = 0;
                        Integer hasAIMUOMCFM = 0;
                        Integer hasDLMUnitsCFM25 = 0;
                        Integer hasMUEnergyTypeRenawable = 0;
                        Integer hasAtticFloorBuilding = 0;
                        Integer hasAtticRoofBuilding = 0;
                        Integer hasAnnualHeatingDistributionSystemEfficiency = 0;
                        Integer hasAnnualCoolingDistributionSystemEfficiency = 0;

                        //AUDIT AND RETROFIT - START
                        if (b.ProjectStatus == 'audit' || b.ProjectStatus == 'retrofit') {
                            //required - start
                            if (b.SameAs == NULL) {
                                if (b.Address1 == NULL || b.Address1 == '')
                                    result.add('Building ' + b.SystemIdentifier + ' Site Address: Address 1 is required.'); 
                                if (b.CityMunicipality == NULL || b.CityMunicipality == '')
                                    result.add('Building ' + b.SystemIdentifier + 
                                        ' Site Address: City or municipality is required.'); 
                                if (b.StateCode == NULL || b.StateCode == '')
                                    result.add('Building ' + b.SystemIdentifier + ' Site Address: State is required.'); 
                                if (b.ZipCode == NULL){
                                    result.add('Building ' + b.SystemIdentifier + ' Site Address: Zip code is required.'); 
                                } else {
                                    try {
                                        Zip_Code__mdt zcd = [
                                            SELECT Id, Climate_Zone__c
                                            FROM Zip_Code__mdt
                                            WHERE Zip_Code__c =: b.ZipCode
                                                AND PGE_Territory__c = true
                                                limit 1
                                            ];
                                    } catch (QueryException e) {
                                        result.add('Building ' + b.SystemIdentifier + 
                                            ' Site Address: Zip Code in the model is not included in Pacific Gas and Electric Company Service Territory.'); 
                                    }
                                }
                                if (b.NumberofResidents == NULL || b.NumberofResidents == 0.0)
                                    result.add('Building ' + b.SystemIdentifier + 
                                        ' Building Occupancy: Number of residents is required.');         
                                if (b.YearBuilt == NULL ||b.YearBuilt == 0)
                                    result.add('Building ' + b.SystemIdentifier + 
                                        ' Building Construction: Year built is required.'); 
                                if (b.ResidentialFacilityType == NULL || b.ResidentialFacilityType == '')
                                    result.add('Building ' + b.SystemIdentifier + 
                                        ' Building Construction: Residential facility type is required.');    
                                if (b.ConditionedFloorArea == NULL || b.ConditionedFloorArea == 0.0)
                                    result.add('Building ' + b.SystemIdentifier + 
                                        ' Building Construction: Conditioned floor area is required.');
                                if (b.NumberofStoriesAboveGrade == NULL || b.NumberofStoriesAboveGrade == 0.0)
                                    result.add('Building ' + b.SystemIdentifier + 
                                        ' Building Construction: Number of stories above grade is required.');
                            } else {
                                for (HPXML.Building b2: validateHPXML.buildings) {
                                    if (b2.SystemIdentifier == b.SameAs) {
                                        if (b.Address1 == NULL) {
                                            if (b2.Address1 == NULL || b2.Address1 == '')
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Site Address: Address 1 is required.'); 
                                        }
                                        if (b.CityMunicipality == NULL) {
                                            if (b2.CityMunicipality == NULL || b2.CityMunicipality == '')
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Site Address: City or municipality is required.');
                                        }
                                        if (b.StateCode == NULL) {
                                            if (b2.StateCode == NULL || b2.StateCode == '')
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Site Address: State is required.'); 
                                        }
                                        if (b.ZipCode == NULL) {
                                            if (b2.ZipCode == NULL)
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Site Address: Zip code is required.'); 
                                        }
                                        if (b.NumberofResidents == NULL) {
                                            if (b2.NumberofResidents == NULL || b2.NumberofResidents == 0.0)
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Building Occupancy: Number of residents is required.'); 
                                        }
                                        if (b.YearBuilt == NULL) {
                                            if (b2.YearBuilt == NULL ||b2.YearBuilt == 0)
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Building Construction: Year built is required.'); 
                                        }
                                        if (b.ResidentialFacilityType == NULL) {
                                            if (b2.ResidentialFacilityType == NULL || b2.ResidentialFacilityType == '')
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Building Construction: Residential facility type is required.');   
                                        }
                                        if (b.ConditionedFloorArea == NULL) {
                                            if (b2.ConditionedFloorArea == NULL || b2.ConditionedFloorArea == 0.0)
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Building Construction: Conditioned floor area is required.');
                                        }
                                        if (b.NumberofStoriesAboveGrade == NULL) {
                                            if (b2.NumberofStoriesAboveGrade == NULL || b2.NumberofStoriesAboveGrade == 0.0)
                                                result.add('Building ' + b2.SystemIdentifier + 
                                                    ' Building Construction: Number of stories above grade is required.');
                                        }
                                    }
                                }
                            }

                            if (validateHPXML.attics.size() > 0) {
                                for(HPXML.Attic attic: validateHPXML.attics){
                                    if(attic.BuildingId == b.SystemIdentifier){
                                        if (attic.SameAs == NULL) {
                                            if(attic.Area == NULL && hasAtticArea == 0){                                        
                                                result.add('Building ' + b.SystemIdentifier + ' Attic: Area is required.');     
                                                hasAtticArea = 1;
                                            }
                                            if(attic.afiAssemblyEffectiveRValue != NULL){                                           
                                                hasAtticFloorBuilding = 1;
                                            }
                                            if(attic.ariAssemblyEffectiveRValue != NULL){                                           
                                                hasAtticRoofBuilding = 1;
                                            }
                                        } else {
                                            for(HPXML.Attic attic2: validateHPXML.attics){
                                                if (attic2.SystemIdentifier == attic.SameAs) {
                                                    if (attic.Area == NULL) {
                                                        if(attic2.Area == NULL && hasAtticArea == 0){                                        
                                                            result.add('Building ' + b.SystemIdentifier + ' Attic: Area is required.');     
                                                            hasAtticArea = 1;
                                                        }
                                                    }
                                                    if (attic.afiAssemblyEffectiveRValue != NULL) {
                                                        if(attic2.afiAssemblyEffectiveRValue != NULL){                                          
                                                            hasAtticFloorBuilding = 1;
                                                        }
                                                    }
                                                    if (attic.ariAssemblyEffectiveRValue != NULL) {
                                                        if(attic2.ariAssemblyEffectiveRValue != NULL){                                          
                                                            hasAtticRoofBuilding = 1;
                                                        }
                                                    }
                                                }
                                            }

                                        }

                                    }
                                }

                                if (hasAtticFloorBuilding == 0 && hasAtticRoofBuilding == 0)
                                    result.add('Building ' + b.SystemIdentifier + 
                                        ': Assembly effective R value is required for Attic Roof Insulation or Attic Floor Insulation.');

                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Attic: Area is required.');     
                            }

                            if (validateHPXML.foundations.size() > 0) {
                                for (HPXML.Foundation foundation: validateHPXML.foundations) {
                                    if (foundation.BuildingId == b.SystemIdentifier) {
                                        if (foundation.SameAs == NULL) {
                                            if (foundation.Type == NULL && hasFoundationType == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                        ' Foundation: Foundation type is required.');     
                                                hasFoundationType = 1;
                                            }
                                            if (foundation.AssemblyEffectiveRValue == NULL 
                                                    && hasFrameFloorInsulationValue == 0 
                                                    && ((foundation.type != 'SlabOnGrade' 
                                                    && foundation.Type != 'AboveApartment') 
                                                    || foundation.Type == 'AboveApartment') 
                                                    && foundation.foundationWallSystemIdentifier == null 
                                                    && b.ResidentialFacilityType != 'single-family attached') {

                                                result.add('Building ' + b.SystemIdentifier 
                                                        + ' Insulation - Floor - System: Assembly effective R value'
                                                        +' is required.');
                                                hasFrameFloorInsulationValue = 1;
                                            }
                                        } else {
                                            for (HPXML.Foundation foundation2: validateHPXML.foundations) {
                                                if (foundation2.SystemIdentifier == foundation.SameAs) {
                                                    if (foundation.Type == NULL) {
                                                        if (foundation2.Type == NULL && hasFoundationType == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Foundation: Foundation type is required.');     
                                                            hasFoundationType = 1;
                                                        }
                                                    }
                                                    if (foundation.AssemblyEffectiveRValue == NULL) {
                                                        if (foundation2.AssemblyEffectiveRValue == NULL 
                                                                && hasFrameFloorInsulationValue == 0 
                                                                && ((foundation.type != 'SlabOnGrade' 
                                                                && foundation.Type != 'AboveApartment') 
                                                                || foundation.Type == 'AboveApartment') 
                                                                && foundation.foundationWallSystemIdentifier == null 
                                                                && b.ResidentialFacilityType 
                                                                != 'single-family attached') {

                                                            result.add('Building ' + b.SystemIdentifier 
                                                                    + ' Insulation - Floor - System: Assembly ' 
                                                                    + ' effective R value is required.');
                                                            hasFrameFloorInsulationValue = 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Foundation: Foundation type is required.');
                            }

                            if (validateHPXML.modeledusages.size() > 0) {
                                boolean coolingFound = false;
                                boolean heatingFound = false;

                                for (HPXML.ModeledUsage mo: validateHPXML.modeledusages) {
                                    if (mo.BuildingId == b.SystemIdentifier) {
                                        if (mo.AnnualConsumption == NULL && hasMUAnnualConsumption == 0) {
                                            result.add('Building ' + b.SystemIdentifier + 
                                                ' Modeled Usage: Annual consumption is required.');   
                                            hasMUAnnualConsumption = 1;
                                        }
                                        if (mo.BaseLoad == NULL && hasMUBaseLoad == 0) {
                                            result.add('Building ' + b.SystemIdentifier + 
                                                ' Modeled Usage: Base load is required.');    
                                            hasMUBaseLoad = 1;
                                        }
                                        if (mo.EnergyType == NULL && hasMUEnergyType == 0) {
                                            result.add('Building ' + b.SystemIdentifier + 
                                                ' Modeled Usage: Energy type is required.');  
                                            hasMUBaseLoad = 1;
                                        } else {
                                            if (acceptableEnergyType.contains(mo.EnergyType) == false && 
                                                    hasMUEnergyTypeRenawable == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Modeled Usage: Energy type should not be renewable.');
                                                hasMUEnergyTypeRenawable = 1;
                                            }

                                            if (mo.EnergyType == ELECTRICITY_ENERGY_TYPE) {
                                                hasElectricity = true;
                                            } else if ((
                                                    application.Gas_Provider__c == BIGPortalBuildingInformationUtils.PGE
                                                    || application.Gas_Provider__c ==
                                                            BIGPortalBuildingInformationUtils.SOUTHERN_CA_GAS_COMPANY
                                                    || application.Gas_Provider__c ==
                                                            BIGPortalBuildingInformationUtils.OTHER)
                                                    && mo.EnergyType != NATURAL_GAS_ENERGY_TYPE) {
                                                energyTypeErrors.add(GAS_ENERGY_TYPE_ERROR);
                                            } else if (application.Gas_Provider__c ==
                                                    BIGPortalBuildingInformationUtils.PROPANE
                                                    && mo.EnergyType != PROPANE_ENERGY_TYPE) {
                                                energyTypeErrors.add(GAS_ENERGY_TYPE_ERROR);
                                            } else if (application.Gas_Provider__c ==
                                                    BIGPortalBuildingInformationUtils.ALL_ELECTRIC_HOME
                                                    && (mo.EnergyType == NATURAL_GAS_ENERGY_TYPE
                                                            || mo.EnergyType == PROPANE_ENERGY_TYPE)) {
                                                energyTypeErrors.add(GAS_ENERGY_TYPE_ERROR);
                                            }
                                        }

                                        if (mo.Cooling != null) {
                                            coolingFound = true;
                                        }

                                        if (mo.Heating != null) {
                                           heatingFound = true;
                                        }
                                    }
                                }

                                if (!hasElectricity) {
                                    energyTypeErrors.add(ELECTRICITY_ENERGY_TYPE_ERROR);
                                }

                                /**
                                 * Added by dannyteng. Heating or cooling end use should be reported in one of
                                 * ModeledEndUse
                                 */
                                if (!heatingFound  && !coolingFound) {
                                    result.add('Building ' + b.SystemIdentifier
                                            + ' Modeled Usage - Consumption by End Use is required.');
                                    hasMUConsumptionEndUse = 1;
                                 }
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Modeled Usage is required.');
                            }

                            if (validateHPXML.heatingsystems.size() > 0) {
                                for (HPXML.HeatingSystem hs: validateHPXML.heatingsystems) {
                                    if (hs.BuildingId == b.SystemIdentifier) {
                                        if (hs.SameAs == NULL) {
                                            if (hs.HeatingCapacity == NULL && hasHSHeatingCapacity == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Heating - System: Heating capacity is required.');  
                                                hasHSHeatingCapacity = 1;
                                            }
                                            if (hs.FractionHeatLoadServed == NULL && hasHSFractionHeatLoadServed == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Heating - System: Fraction of heating load served is required.');   
                                                hasHSFractionHeatLoadServed = 1;
                                            }
                                            if (hs.AFUE == NULL && hs.COP == NULL && hs.HSPF == NULL && hs.Percent == NULL && 
                                                    hasHSAnnualHeatingEfficiency == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Heating - System: Annual heating efficiency is required.');     
                                                hasHSAnnualHeatingEfficiency = 1;
                                            }
                                        } else {
                                            for (HPXML.HeatingSystem hs2: validateHPXML.heatingsystems) {
                                                if (hs2.SystemIdentifier == hs.SameAs) {
                                                    if (hs.HeatingCapacity == NULL) {
                                                        if (hs2.HeatingCapacity == NULL && hasHSHeatingCapacity == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Heating - System: Heating capacity is required.');  
                                                            hasHSHeatingCapacity = 1;
                                                        }
                                                    }
                                                    if (hs.FractionHeatLoadServed == NULL) {
                                                        if (hs2.FractionHeatLoadServed == NULL && hasHSFractionHeatLoadServed == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Heating - System: Fraction of heating load served is required.');   
                                                            hasHSFractionHeatLoadServed = 1;
                                                        }
                                                    }
                                                    if (hs.AFUE == NULL && hs.COP == NULL && hs.HSPF == NULL && 
                                                            hs.Percent == NULL && hasHSAnnualHeatingEfficiency == 0) {
                                                        if (hs2.AFUE == NULL && hs2.COP == NULL && hs2.HSPF == NULL && 
                                                                hs2.Percent == NULL && hasHSAnnualHeatingEfficiency == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Heating - System: Annual heating efficiency is required.');     
                                                            hasHSAnnualHeatingEfficiency = 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }
                            } else {

                                // check heat pump exist
                                Set<String> thisHeatPumpSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisHeatPumpSetResult = thisHeatPumpSet.contains('heatpump');

                                if (thisHeatPumpSetResult != true) {
                                    result.add('Building ' + b.SystemIdentifier + ' Heating system is required.');   
                                }
                            }

                            if (validateHPXML.waterheatings.size() > 0) {
                                for (HPXML.WaterHeating wh: validateHPXML.waterheatings) {
                                    if (wh.BuildingId == b.SystemIdentifier) {
                                        if (wh.SameAs == NULL) {
                                            if (wh.FuelType == NULL && hasWHFuelType == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Water Heater - System: Fuel type is required.');    
                                                hasWHFuelType = 1;
                                            }
                                            if (wh.EnergyFactor == NULL && hasWHEnergyFactor == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Water Heater - System: Energy factor is required.');    
                                                hasWHEnergyFactor = 1;
                                            }
                                            if (wh.HotWaterTemperature == NULL && hasWHHotWaterTemperature == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Water Heater - System: Hot water temperature is required.');    
                                                hasWHHotWaterTemperature = 1;
                                            }
                                        } else {
                                            for (HPXML.WaterHeating wh2: validateHPXML.waterheatings) {
                                                if (wh2.SystemIdentifier == wh.SameAs) {
                                                    if (wh.FuelType == NULL) {
                                                        if (wh2.FuelType == NULL && hasWHFuelType == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Water Heater - System: Fuel type is required.');    
                                                            hasWHFuelType = 1;
                                                        }
                                                    }
                                                    if (wh.EnergyFactor == NULL) {
                                                        if (wh2.EnergyFactor == NULL && hasWHEnergyFactor == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Water Heater - System: Energy factor is required.');    
                                                            hasWHEnergyFactor = 1;
                                                        }
                                                    }
                                                    if (wh.HotWaterTemperature == NULL) {
                                                        if (wh2.HotWaterTemperature == NULL && hasWHHotWaterTemperature == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Water Heater - System: Hot water temperature is required.');    
                                                            hasWHHotWaterTemperature = 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Water Heater - System is required.');   
                            }

                            if (validateHPXML.hvaccontrols.size() > 0) {
                                for (HPXML.HVACControl hc: validateHPXML.hvaccontrols) {
                                    if (hc.BuildingId == b.SystemIdentifier) {
                                        if (hc.SameAs == NULL) {
                                            if (hc.SetpointTempCoolingSeason == NULL && hasHVACControlCooling == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Thermostat - System: Setpoint temperature cooling season is required.');    
                                                hasHVACControlCooling = 1;
                                            }
                                            if (hc.SetpointTempHeatingSeason == NULL && hasHVACControlHeating == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Thermostat - System: Setpoint temperature heating season is required.');    
                                                hasHVACControlHeating = 1;
                                            }
                                            if (hc.ControlType == NULL && hasHVACControlControlType == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Thermostat - System: Control type is required.');   
                                                hasHVACControlControlType = 1;
                                            }
                                        } else {
                                            for (HPXML.HVACControl hc2: validateHPXML.hvaccontrols) {
                                                if (hc2.SystemIdentifier == hc.SameAs) {
                                                    if (hc.SetpointTempCoolingSeason == NULL) {
                                                        if (hc2.SetpointTempCoolingSeason == NULL && hasHVACControlCooling == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Thermostat - System: Setpoint temperature cooling season is required.');    
                                                            hasHVACControlCooling = 1;
                                                        }
                                                    }
                                                    if (hc.SetpointTempHeatingSeason == NULL) {
                                                        if (hc2.SetpointTempHeatingSeason == NULL && hasHVACControlHeating == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Thermostat - System: Setpoint temperature heating season is required.');    
                                                            hasHVACControlHeating = 1;
                                                        }
                                                    }
                                                    if (hc.ControlType == NULL) {
                                                        if (hc2.ControlType == NULL && hasHVACControlControlType == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Thermostat - System: Control type is required.');   
                                                            hasHVACControlControlType = 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Thermostat - System is required.');     
                            }

                            if (validateHPXML.lightinggroups.size() > 0) {
                                for (HPXML.LightingGroup lg: validateHPXML.lightinggroups) {
                                    if (lg.SameAS == NULL) {
                                        if (lg.BuildingId == b.SystemIdentifier) {                                    
                                            if (lg.AverageHoursPerDay == NULL && hasLGHours == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Lighting - System: Average hours per day is required.');    
                                                hasLGHours = 1;
                                            }
                                        }
                                    } else {
                                        for (HPXML.LightingGroup lg2: validateHPXML.lightinggroups) {
                                            if (lg2.SystemIdentifier == lg.SameAs) {
                                                if (lg.AverageHoursPerDay == NULL) {
                                                    if (lg2.AverageHoursPerDay == NULL && hasLGHours == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Lighting - System: Average hours per day is required.');    
                                                        hasLGHours = 1;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                }
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Lighting - System is required.');   
                            }

                            if (validateHPXML.wallinsulations.size() > 0) {
                                for (HPXML.WallInsulation wi: validateHPXML.wallinsulations) {
                                    if (wi.BuildingId == b.SystemIdentifier) {
                                        if (wi.SameAs == NULL) {
                                            if (wi.NominalRValue == NULL && hasWINominalRValue  == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Insulation - Wall - System: Nominal R value is required.');     
                                                hasWINominalRValue = 1;
                                            }
                                            if (wi.AssemblyEffectiveRValue == NULL && hasWIAssemblyEffectiveRValue == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Insulation - Wall - System: Assembly effective R value is required.');  
                                                hasWIAssemblyEffectiveRValue = 1;
                                            }
                                            if (wi.Area == NULL && hasWIArea == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Insulation - Wall - System: Surface area is required.');    
                                                hasWIArea = 1;
                                            }
                                            if (wi.Type == NULL && hasWIType == 0) {
                                                result.add('Building ' + b.SystemIdentifier + ' Wall: Wall type is required.');     
                                                hasWIType = 1;
                                            }
                                        } else {
                                            for (HPXML.WallInsulation wi2: validateHPXML.wallinsulations) {
                                                if (wi2.SystemIdentifier == wi.SameAs) {
                                                    if (wi.NominalRValue == NULL) {
                                                        if (wi2.NominalRValue == NULL && hasWINominalRValue  == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Insulation - Wall - System: Nominal R value is required.');     
                                                            hasWINominalRValue = 1;
                                                        }
                                                    }
                                                    if (wi.AssemblyEffectiveRValue == NULL) {
                                                        if (wi2.AssemblyEffectiveRValue == NULL && hasWIAssemblyEffectiveRValue == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Insulation - Wall - System: Assembly effective R value is required.');  
                                                            hasWIAssemblyEffectiveRValue = 1;
                                                        }
                                                    }
                                                    if (wi.Area == NULL) {
                                                        if (wi2.Area == NULL && hasWIArea == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Insulation - Wall - System: Surface area is required.');    
                                                            hasWIArea = 1;
                                                        }
                                                    }
                                                    if (wi.Type == NULL) {
                                                        if (wi2.Type == NULL && hasWIType == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Wall: Wall type is required.');     
                                                            hasWIType = 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Insulation - Wall - System is required.');
                            }

                            if (validateHPXML.projects.size() > 0) {
                                Integer projectCount = 0;
                                for (HPXML.Project proj: validateHPXML.projects){
                                    if (proj.BuildingId == b.SystemIdentifier) {

                                        if (validateHPXML.measures.size() > 0) {
                                            for (HPXML.Measure measure: validateHPXML.measures) {
                                                if (measure.ProjectId == proj.SystemIdentifier) {
                                                    if (measure.MeasureDescription == NULL && hasMeasureDescription == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Project Measures: Measure description is required.');   
                                                        hasMeasureDescription = 1;
                                                    }
                                                }
                                            }
                                        } else {
                                            result.add('Building ' + b.SystemIdentifier + 
                                                ' Project Measures: Measure description is required.');   
                                        }

                                        if (validateHPXML.fuelsavings.size() > 0) {
                                            for (HPXML.FuelSavings fs: validateHPXML.fuelsavings) {
                                                if (fs.ProjectId == proj.SystemIdentifier) {
                                                    if (fs.EndUse == NULL && hasFuelSavingsEndUse == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Project Energy savings information: End use is required.');     
                                                        hasFuelSavingsEndUse = 1;
                                                    }
                                                    if (fs.EndUseValue == NULL && hasFuelSavingsEndUseValue == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Project Energy savings information: End use is required.');     
                                                        hasFuelSavingsEndUseValue = 1;
                                                    }
                                                    if (fs.EndUseFuel == NULL && hasFuelSavingsEndUseFuel == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Project Energy savings information - Fuel Savings: Fuel is required.');     
                                                        hasFuelSavingsEndUseFuel = 1;
                                                    }
                                                    if (fs.EndUseUnits == NULL && hasFuelSavingsEndUseUnits == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Project Energy savings information - Fuel Savings: Units is required.');    
                                                        hasFuelSavingsEndUseUnits = 1;
                                                    }
                                                }
                                            }
                                        } else {
                                            result.add('Building ' + b.SystemIdentifier + 
                                                ' Project Energy savings information is required.');  
                                        }
                                    }

                                }

                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Project is required.');  
                            }
                            //required - end

                            //dependent and required - start
                            if (validationLevel == 2) {
                                //compare installed/replaced components with program participation
                                Set<String> programsSet = new Set<String>();
                                programsSet.addAll(validateHPXML.programsList);

                                for (String i : validateHPXML.componentsList) {
                                    if (!programsSet.contains(i)) {
                                        result.add('Measure ' + i + ' must be installed.');
                                    }
                                }

                                Set<String> thisCoolingSystemSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisCoolingSetResult = thisCoolingSystemSet.contains('coolingsystem');

                                if (thisCoolingSetResult == true) {
                                    for (HPXML.CoolingSystem cs: validateHPXML.coolingsystems) {
                                        if (cs.BuildingId == b.SystemIdentifier) {
                                            if (cs.SameAs == NULL) {
                                                if(cs.CoolingCapacity == NULL && hasCSCoolingCapacity == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Cooling - System: Cooling capacity is required.');  
                                                    hasCSCoolingCapacity = 1;
                                                }
                                                if (cs.CoolingSystemType == NULL && hasCSCoolingSystemType == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Cooling - System:Cooling system type is required.');    
                                                    hasCSCoolingSystemType = 1;
                                                }
                                                if (cs.CoolingSystemFuel == NULL && hasCSCoolingSystemFuel == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Cooling - System: Fuel is required.');  
                                                    hasCSCoolingSystemFuel = 1;
                                                }
                                                if (cs.Manufacturer == NULL && hasCSManufacturer == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Cooling - System: Manufacturer is required.');  
                                                    hasCSManufacturer = 1;
                                                }
                                                if (cs.ModelNumber == NULL && hasCSModelNumber == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Cooling - System: Model number is required.');  
                                                    hasCSModelNumber = 1;
                                                }
                                                if (cs.ModelYear == NULL && hasCSModelYear == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Cooling - System: Model year is required.');    
                                                    hasCSModelYear = 1;
                                                }
                                                if (cs.FractionCoolLoadServed == NULL && hasCSFractionCoolLoadServed == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Cooling - System: Fraction of cooling load served is required.');   
                                                    hasCSFractionCoolLoadServed = 1;
                                                }
                                                if (cs.AFUE == NULL && cs.EER == NULL && cs.HSPF == NULL && 
                                                        cs.kWton == NULL && cs.SEER == NULL && cs.COP == NULL && 
                                                        hasCSCoolingValue == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Cooling - System: Annual cooling efficiency is required.'); 
                                                    hasCSCoolingValue = 1;
                                                }
                                            } else {
                                                for (HPXML.CoolingSystem cs2: validateHPXML.coolingsystems) {
                                                    if (cs2.SystemIdentifier == cs.SameAs) {
                                                        if (cs.CoolingCapacity == NULL) {
                                                            if (cs2.CoolingCapacity == NULL && hasCSCoolingCapacity == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Cooling - System: Cooling capacity is required.');  
                                                                hasCSCoolingCapacity = 1;
                                                            }
                                                        }
                                                        if (cs.CoolingSystemType == NULL) {
                                                            if (cs2.CoolingSystemType == NULL && hasCSCoolingSystemType == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Cooling - System:Cooling system type is required.');    
                                                                hasCSCoolingSystemType = 1;
                                                            }
                                                        }
                                                        if (cs.CoolingSystemFuel == NULL) {
                                                            if (cs2.CoolingSystemFuel == NULL && hasCSCoolingSystemFuel == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Cooling - System: Fuel is required.');  
                                                                hasCSCoolingSystemFuel = 1;
                                                            }
                                                        }
                                                        if (cs.Manufacturer == NULL) {
                                                            if (cs2.Manufacturer == NULL && hasCSManufacturer == 0){
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Cooling - System: Manufacturer is required.');  
                                                                hasCSManufacturer = 1;
                                                            }
                                                        }
                                                        if (cs.ModelNumber == NULL) {
                                                            if (cs2.ModelNumber == NULL && hasCSModelNumber == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Cooling - System: Model number is required.');  
                                                                hasCSModelNumber = 1;
                                                            }
                                                        }
                                                        if (cs.ModelYear == NULL) {
                                                            if (cs2.ModelYear == NULL && hasCSModelYear == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Cooling - System: Model year is required.');    
                                                                hasCSModelYear = 1;
                                                            }
                                                        }
                                                        if (cs.FractionCoolLoadServed == NULL) {
                                                            if (cs2.FractionCoolLoadServed == NULL && hasCSFractionCoolLoadServed == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Cooling - System: Fraction of cooling load served is required.');   
                                                                hasCSFractionCoolLoadServed = 1;
                                                            }
                                                        }
                                                        if (cs.AFUE == NULL && cs.EER == NULL && cs.HSPF == NULL && 
                                                                cs.kWton == NULL && cs.SEER == NULL && cs.COP == NULL) {
                                                            if (cs2.AFUE == NULL && cs2.EER == NULL && cs2.HSPF == NULL && 
                                                                    cs2.kWton == NULL && cs2.SEER == NULL && cs2.COP == NULL && 
                                                                    hasCSCoolingValue == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Cooling - System: Annual cooling efficiency is required.'); 
                                                                hasCSCoolingValue = 1;
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisHeatingSystemSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisHeatingSetResult = thisHeatingSystemSet.contains('heatingsystem');

                                if (thisHeatingSetResult == true) {
                                    for (HPXML.HeatingSystem hs: validateHPXML.heatingsystems) {
                                        if (hs.BuildingId == b.SystemIdentifier) {
                                            if (hs.SameAs == NULL) {
                                                if (hs.Units == NULL && hasHSUnits == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heating - System: Annual heating efficiency units year is required.');  
                                                    hasHSUnits = 1;
                                                }
                                                if (hs.Manufacturer == NULL && hasHSManufacturer == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heating - System: Manufacturer is required.');  
                                                    hasHSManufacturer = 1;
                                                }
                                                if (hs.ModelNumber == NULL && hasHSModelNumber == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heating - System: Model number is required.');  
                                                    hasHSModelNumber = 1;
                                                }
                                                if (hs.ModelYear == NULL && hasHSModelYear == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heating - System: Model year is required.');    
                                                    hasHSModelYear = 1;
                                                }
                                            } else {
                                                for (HPXML.HeatingSystem hs2: validateHPXML.heatingsystems) {
                                                    if (hs2.SystemIdentifier == hs.SameAs) {
                                                        if (hs.Units == NULL) {
                                                            if (hs2.Units == NULL && hasHSUnits == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heating - System: Annual heating efficiency units year is required.');  
                                                                hasHSUnits = 1;
                                                            }
                                                        }
                                                        if (hs.Manufacturer == NULL) {
                                                            if (hs2.Manufacturer == NULL && hasHSManufacturer == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heating - System: Manufacturer is required.');  
                                                                hasHSManufacturer = 1;
                                                            }
                                                        }
                                                        if (hs.ModelNumber == NULL) {
                                                            if (hs2.ModelNumber == NULL && hasHSModelNumber == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heating - System: Model number is required.');  
                                                                hasHSModelNumber = 1;
                                                            }
                                                        }
                                                        if (hs.ModelYear == NULL) {
                                                            if (hs2.ModelYear == NULL && hasHSModelYear == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heating - System: Model year is required.');    
                                                                hasHSModelYear = 1;
                                                            }

                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisWaterHeatingSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisWaterHeatingSetResult = thisWaterHeatingSet.contains('waterheating');

                                if (thisWaterHeatingSetResult == true) {
                                    for (HPXML.WaterHeating wh: validateHPXML.waterheatings) {
                                        if (wh.BuildingId == b.SystemIdentifier) {
                                            if (wh.SameAs == NULL) {
                                                if (wh.Manufacturer == NULL && hasWHManufacturer == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Water Heater - System: Manufacturer is required.');     
                                                    hasWHManufacturer = 1;
                                                }
                                                if (wh.ModelNumber == NULL && hasWHModelNumber == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Water Heater - System: Model number is required.');     
                                                    hasWHModelNumber = 1;
                                                }
                                                if (wh.ModelYear == NULL && hasWHModelYear == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Water Heater - System: Model year is required.');   
                                                    hasWHModelYear = 1;
                                                }
                                                if (wh.Location == NULL && hasWHLocation == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Water Heater - System: Location is required.');     
                                                    hasWHLocation = 1;
                                                }
                                                if (wh.WaterHeaterType == NULL && hasWHWaterHeaterType == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Water Heater - System: Water heater type is required.');    
                                                    hasWHWaterHeaterType = 1;
                                                }
                                                if (wh.HeatingCapacity == NULL && hasWHHeatingCapacity == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Water Heater - System: Water heater heating capacity is required.');    
                                                    hasWHHeatingCapacity = 1;
                                                }
                                                //[REFERENCE] CombustionVentilationSystem is referenced by the heating system's 
                                                if (b.CombustionVentilationSystem != NULL) {
                                                    if (wh.TankVolume == NULL && hasWHTankVolume == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Water Heater - System: Tank volume is required.');  
                                                        hasWHTankVolume = 1;
                                                    }
                                                }
                                            } else {
                                                for (HPXML.WaterHeating wh2: validateHPXML.waterheatings) {
                                                    if (wh2.SystemIdentifier == wh.SameAs) {
                                                        if (wh.Manufacturer == NULL) {
                                                            if (wh2.Manufacturer == NULL && hasWHManufacturer == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Water Heater - System: Manufacturer is required.');     
                                                                hasWHManufacturer = 1;
                                                            }
                                                        }
                                                        if (wh.ModelNumber == NULL) {
                                                            if (wh2.ModelNumber == NULL && hasWHModelNumber == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Water Heater - System: Model number is required.');     
                                                                hasWHModelNumber = 1;
                                                            }
                                                        }
                                                        if (wh.ModelYear == NULL) {
                                                            if (wh2.ModelYear == NULL && hasWHModelYear == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Water Heater - System: Model year is required.');   
                                                                hasWHModelYear = 1;
                                                            }
                                                        }
                                                        if (wh.Location == NULL) {
                                                            if (wh2.Location == NULL && hasWHLocation == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Water Heater - System: Location is required.');     
                                                                hasWHLocation = 1;
                                                            }
                                                        }
                                                        if (wh.WaterHeaterType == NULL) {
                                                            if (wh2.WaterHeaterType == NULL && hasWHWaterHeaterType == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Water Heater - System: Water heater type is required.');    
                                                                hasWHWaterHeaterType = 1;
                                                            }
                                                        }
                                                        if (wh.HeatingCapacity == NULL) {
                                                            if (wh2.HeatingCapacity == NULL && hasWHHeatingCapacity == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Water Heater - System: Water heater heating capacity is required.');    
                                                                hasWHHeatingCapacity = 1;
                                                            }
                                                        }
                                                        //[REFERENCE] CombustionVentilationSystem is referenced by the heating system's 
                                                        if (b.CombustionVentilationSystem != NULL) {
                                                            if (wh.HeatingCapacity == NULL) {
                                                                if (wh2.TankVolume == NULL && hasWHTankVolume == 0) {
                                                                    result.add('Building ' + b.SystemIdentifier + 
                                                                        ' Water Heater - System: Tank volume is required.');  
                                                                    hasWHTankVolume = 1;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisHeatPumpSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisHeatPumpSetResult = thisHeatPumpSet.contains('heatpump');

                                if (thisHeatPumpSetResult == true) {
                                    for (HPXML.HeatPump hp: validateHPXML.heatpumps) {
                                        if (hp.BuildingId == b.SystemIdentifier) {
                                            if (hp.SameAs == NULL) {
                                                if (hp.AFUEcool == NULL && hp.EERcool == NULL && hp.HSPFcool == NULL && 
                                                        hp.kWtoncool == NULL && hp.SEERcool == NULL && hp.COPcool == NULL && 
                                                        hasHPCooling == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heat Pump - System: Annual cooling efficiency is required.'); 
                                                    hasHPCooling = 1;
                                                }
                                                if (hp.AFUEheat == NULL && hp.EERheat == NULL && hp.HSPFheat == NULL && 
                                                        hp.kWtonheat == NULL && hp.SEERheat == NULL && hp.COPheat == NULL && 
                                                        hasHPHeating == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heat Pump - System: Annual heating efficiency is required.'); 
                                                    hasHPHeating = 1;
                                                }
                                                if (hp.FractionCoolLoadServed == NULL && hasHPFractionCoolLoadServed == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heat Pump - System: Fraction of cooling load served is required.');     
                                                    hasHPFractionCoolLoadServed = 1;
                                                }
                                                if (hp.FractionHeatLoadServed == NULL && hasHPFractionHeatLoadServed == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heat Pump - System: Fraction of heating load served is required.');     
                                                    hasHPFractionHeatLoadServed = 1;
                                                }
                                                if (hp.HeatPumpType == NULL && hasHPHeatPumpType == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heat Pump - System: Heat pump type is required.');  
                                                    hasHPHeatPumpType = 1;
                                                }
                                                if (hp.Manufacturer == NULL && hasHPManufacturer == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heat Pump - System: Manufacturer is required.');    
                                                    hasHPManufacturer = 1;
                                                }
                                                if (hp.ModelNumber == NULL && hasHPModelNumber == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heat Pump - System: Model number is required.');    
                                                    hasHPModelNumber = 1;
                                                }
                                                if (hp.ModelYear == NULL && hasHPModelYear == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Heat Pump - System: Model year is required.');  
                                                    hasHPModelYear = 1;
                                                }
                                                if (hp.AFUEcool == NULL && hp.EERcool == NULL && hp.HSPFcool == NULL && 
                                                        hp.kWtoncool == NULL && hp.SEERcool == NULL && hp.COPcool == NULL && 
                                                        hasHPCooling == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + ' Building ' + 
                                                        b.SystemIdentifier +
                                                        ' Heat Pump - System: Annual cooling efficiency is required.'); 
                                                    hasHPCooling = 1;
                                                }
                                                if (hp.AFUEheat == NULL && hp.EERheat == NULL && hp.HSPFheat == NULL && 
                                                        hp.kWtonheat == NULL && hp.SEERheat == NULL && hp.COPheat == NULL && 
                                                        hasHPHeating == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + ' Building ' + 
                                                        b.SystemIdentifier +
                                                        ' Heat Pump - System: Annual heating efficiency is required.'); 
                                                    hasHPHeating = 1;
                                                }
                                            } else {
                                                for (HPXML.HeatPump hp2: validateHPXML.heatpumps) {
                                                    if (hp2.SystemIdentifier == hp.SameAs) {
                                                        if (hp.FractionCoolLoadServed == NULL) {
                                                            if (hp2.FractionCoolLoadServed == NULL && hasHPFractionCoolLoadServed == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heat Pump - System: Fraction of cooling load served is required.');     
                                                                hasHPFractionCoolLoadServed = 1;
                                                            }
                                                        }
                                                        if (hp.FractionHeatLoadServed == NULL) {
                                                            if (hp2.FractionHeatLoadServed == NULL && hasHPFractionHeatLoadServed == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heat Pump - System: Fraction of heating load served is required.');     
                                                                hasHPFractionHeatLoadServed = 1;
                                                            }
                                                        }
                                                        if (hp.HeatPumpType == NULL) {
                                                            if (hp2.HeatPumpType == NULL && hasHPHeatPumpType == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + ' Heat Pump - System: Heat pump type is required.');  
                                                                hasHPHeatPumpType = 1;
                                                            }
                                                        }
                                                        if (hp.Manufacturer == NULL) {
                                                            if (hp2.Manufacturer == NULL && hasHPManufacturer == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heat Pump - System: Manufacturer is required.');    
                                                                hasHPManufacturer = 1;
                                                            }
                                                        }
                                                        if (hp.ModelNumber == NULL) {
                                                            if (hp2.ModelNumber == NULL && hasHPModelNumber == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heat Pump - System: Model number is required.');    
                                                                hasHPModelNumber = 1;
                                                            }
                                                        }
                                                        if (hp.ModelYear == NULL) {
                                                            if (hp2.ModelYear == NULL && hasHPModelYear == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Heat Pump - System: Model year is required.');  
                                                                hasHPModelYear = 1;
                                                            }
                                                        }
                                                        if (hp.AFUEcool == NULL && hp.EERcool == NULL && hp.HSPFcool == NULL && 
                                                            hp.kWtoncool == NULL && hp.SEERcool == NULL && hp.COPcool == NULL) {
                                                            if (hp2.AFUEcool == NULL && hp2.EERcool == NULL && hp2.HSPFcool == NULL && 
                                                                    hp2.kWtoncool == NULL && hp2.SEERcool == NULL && hp2.COPcool == NULL && 
                                                                    hasHPCooling == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Building ' + b.SystemIdentifier + 
                                                                    ' Heat Pump - System: Annual cooling efficiency is required.'); 
                                                                hasHPCooling = 1;
                                                            }
                                                        }
                                                        if (hp.AFUEheat == NULL && hp.EERheat == NULL && hp.HSPFheat == NULL && 
                                                            hp.kWtonheat == NULL && hp.SEERheat == NULL && hp.COPheat == NULL) {
                                                            if (hp2.AFUEheat == NULL && hp2.EERheat == NULL && hp2.HSPFheat == NULL && 
                                                                    hp2.kWtonheat == NULL && hp2.SEERheat == NULL && hp2.COPheat == NULL && 
                                                                    hasHPHeating == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + ' Building ' + 
                                                                    b.SystemIdentifier + 
                                                                    ' Heat Pump - System: Annual heating efficiency is required.'); 
                                                                hasHPHeating = 1;
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisWindowSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisWindowSetResult = thisWindowSet.contains('window');

                                if (thisWindowSetResult == true) {
                                    for (HPXML.Window win: validateHPXML.windows) {
                                        if (win.BuildingId == b.SystemIdentifier) {
                                            if (win.SameAs == NULL) {
                                                if (win.Area == NULL && hasWindowArea == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Windows - System: Area is required.');  
                                                    hasWindowArea = 1;
                                                }
                                                if (win.SHGC == NULL && hasWindowSHGC == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Windows - System: Solar heat gain coefficient (SHGC) is required.');    
                                                    hasWindowSHGC = 1;
                                                }
                                                if (win.UFactor == NULL && hasWindowUFactor == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Windows - System: U-factor is required.');  
                                                    hasWindowUFactor = 1;
                                                }
                                                if (win.GlassLayers == 'single-pane'){
                                                    if(win.FrameType == NULL && hasWindowFrameType == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Windows - System: Frame type is required.');    
                                                        hasWindowFrameType = 1;
                                                    }
                                                }
                                            } else {
                                                for (HPXML.Window win2: validateHPXML.windows) {
                                                    if (win2.SystemIdentifier == win.SameAs) {
                                                        if (win.Area == NULL) {
                                                            if (win2.Area == NULL && hasWindowArea == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Windows - System: Area is required.');  
                                                                hasWindowArea = 1;
                                                            }
                                                        }
                                                        if (win.SHGC == NULL) {
                                                            if (win2.SHGC == NULL && hasWindowSHGC == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Windows - System: Solar heat gain coefficient (SHGC) is required.');    
                                                                hasWindowSHGC = 1;
                                                            }
                                                        }
                                                        if (win.UFactor == NULL) {
                                                            if (win2.UFactor == NULL && hasWindowUFactor == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Windows - System: U-factor is required.');  
                                                                hasWindowUFactor = 1;
                                                            }
                                                        }
                                                        if (win.GlassLayers == NULL) {
                                                            if(win2.GlassLayers == 'single-pane') {
                                                                if (win2.FrameType == NULL && hasWindowFrameType == 0) {
                                                                    result.add('Building ' + b.SystemIdentifier + 
                                                                        ' Windows - System: Frame type is required.');    
                                                                    hasWindowFrameType = 1;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisFoundationSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisFoundationSetResult = thisFoundationSet.contains('foundation');

                                if (thisFoundationSetResult == true) {
                                    for (HPXML.Foundation foundation: validateHPXML.foundations) {
                                        if (foundation.BuildingId == b.SystemIdentifier) {
                                            if (foundation.SameAs == NULL) {
                                                if (foundation.Type != 'SlabOnGrade') {
                                                    if (foundation.Area == NULL && hasFoundationArea == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Insulation - Floor - System: Surface area is required.');   
                                                        hasFoundationArea = 1;
                                                    }
                                                    if (foundation.NominalRValue == NULL && hasFoundationNominalRValue == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Insulation - Floor - System: Insulation nominal R-value is required.');     
                                                        hasFoundationNominalRValue = 1;
                                                    }
                                            }
                                            } else {
                                                for (HPXML.Foundation foundation2: validateHPXML.foundations) {
                                                    if (foundation2.SystemIdentifier == foundation.SameAs) {
                                                        if (foundation2.Type != 'SlabOnGrade') {
                                                            if (foundation2.Area == NULL && hasFoundationArea == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Insulation - Floor - System: Surface area is required.');   
                                                                hasFoundationArea = 1;
                                                            }
                                                            if (foundation2.NominalRValue == NULL && hasFoundationNominalRValue == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Insulation - Floor - System: Insulation nominal R-value is required.');     
                                                                hasFoundationNominalRValue = 1;
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisHVACDistributionSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisHVACDistributionSetResult = thisHVACDistributionSet.contains('hvacdistribution');

                                if (thisHVACDistributionSetResult == true) {
                                    for (HPXML.HVACDistribution hd: validateHPXML.hvacdistributions) {
                                        if (hd.BuildingId == b.SystemIdentifier) {

                                            if (hd.SameAS == NULL) {
                                                if (hd.ConditionedFloorAreaServed == NULL && hasDuctConditionedFloorAreaServed == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' HVAC Distribution - System: Conditioned floor area served is required.');   
                                                    hasDuctConditionedFloorAreaServed = 1;
                                                }
                                            } else {
                                                for (HPXML.HVACDistribution hd2: validateHPXML.hvacdistributions) {
                                                    if (hd2.SystemIdentifier == hd.SameAs) {
                                                        if (hd.ConditionedFloorAreaServed == NULL) {
                                                            if (hd2.ConditionedFloorAreaServed == NULL && 
                                                                    hasDuctConditionedFloorAreaServed == 0){
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' HVAC Distribution - System: Conditioned floor area served is required.');   
                                                                hasDuctConditionedFloorAreaServed = 1;
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            if (validateHPXML.ducts.size() > 0) {
                                                for(HPXML.Duct d: validateHPXML.ducts){
                                                    if (d.SystemIdentifier == hd.SystemIdentifier) {
                                                        if (d.DuctInsulationRValue == NULL && hasDuctInsulationRValue == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' HVAC Distribution - System: Duct insulation R-value is required.');     
                                                            hasDuctInsulationRValue = 1;
                                                        }
                                                        if (d.DuctLocation == NULL && hasDuctLocation == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' HVAC Distribution - System: Duct location is required.');   
                                                            hasDuctLocation = 1;
                                                        }
                                                    }
                                                }
                                            }

                                            if (validateHPXML.ductleakagemeasurements.size() > 0) {
                                                for (HPXML.DuctLeakageMeasurement dlm: validateHPXML.ductleakagemeasurements) {
                                                    if (dlm.SystemIdentifier == hd.SystemIdentifier) {
                                                        if (dlm.DuctLeakageUnits == NULL && hasDLMUnits == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' HVAC Distribution - System: Duct leakage test units is required.');     
                                                            hasDLMUnits = 1;
                                                        } else {
                                                            if (dlm.DuctLeakageUnits != 'CFM25' && hasDLMUnitsCFM25 == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' HVAC Distribution - System: Duct leakage test units must be CFM25.');     
                                                                hasDLMUnitsCFM25 = 1;
                                                            }
                                                        }
                                                        if (dlm.DuctLeakageValue == NULL && hasDLMValue == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' HVAC Distribution - System: Duct leakage test value is required.');     
                                                            hasDLMValue = 1;
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisRoofSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisRoofSetResult = thisRoofSet.contains('roof');

                                if (thisRoofSetResult == true) {
                                    for (HPXML.Roof r: validateHPXML.roofs) {
                                        if (r.BuildingId == b.SystemIdentifier) {
                                            if (r.RadiantBarrier == NULL && hasRoofRadiantBarrier == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Roof: Radiant barrier is required.');  
                                                hasRoofRadiantBarrier = 1;
                                            }
                                            if (r.RoofType == NULL && hasRoofRoofType == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Roof: Roof type is required.');  
                                                hasRoofRoofType = 1;
                                            }
                                        }
                                    }
                                }
                            }
                            //dependent and required - end                              
                        }
                        //AUDIT AND RETROFIT - END  

                        //AUDIT ONLY - START
                        //required - start
                        if (b.ProjectStatus == 'audit') {
                            if (validateHPXML.aims.size() > 0) {
                                for (HPXML.AirInfiltrationMeasurement a: validateHPXML.aims) {
                                    if (a.BuildingId == b.SystemIdentifier) {
                                        if (a.SameAs == NULL) {
                                            if (a.HousePressure == NULL && hasAIMHousePressure == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Air Infiltration - Test In: House pressure is required.');  
                                                hasAIMHousePressure = 1;
                                            }
                                            if (a.UnitofMeasure == NULL && hasAIMUOM == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Air Infiltration - Test In: Building air leakage unit is required.');
                                                hasAIMUOM = 1;
                                            } else {
                                                if (a.UnitofMeasure != 'CFM' && hasAIMUOMCFM == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Air Infiltration - Test In: Building air leakage unit must be CFM.');
                                                    hasAIMUOMCFM = 1;
                                                }
                                            }
                                            if (a.AirLeakage == NULL && hasAIMAirLeakage == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Air Infiltration - Test In: Building air leakage is required.'); 
                                                hasAIMAirLeakage = 1;
                                            }
                                        } else {
                                            for (HPXML.AirInfiltrationMeasurement a2: validateHPXML.aims) {
                                                if (a2.SystemIdentifier == a.SameAs) {
                                                    if (a.HousePressure == NULL) {
                                                        if (a2.HousePressure == NULL && hasAIMHousePressure == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Air Infiltration - Test In: House pressure is required.');  
                                                            hasAIMHousePressure = 1;
                                                        }
                                                    }
                                                    if (a.UnitofMeasure == NULL) {
                                                        if (a2.UnitofMeasure == NULL && hasAIMUOM == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Air Infiltration - Test In: Building air leakage unit is required.');
                                                            hasAIMUOM = 1;
                                                        } else {
                                                            if (a2.UnitofMeasure != 'CFM' && hasAIMUOMCFM == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Air Infiltration - Test In: Building air leakage unit must be CFM.');
                                                                hasAIMUOMCFM = 1; 
                                                            }
                                                        }
                                                    }
                                                    if (a.AirLeakage == NULL) {
                                                        if (a2.AirLeakage == NULL && hasAIMAirLeakage == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Air Infiltration - Test In: Building air leakage is required.'); 
                                                            hasAIMAirLeakage = 1;   
                                                        }
                                                    }



                                                }
                                            }
                                        }

                                    }
                                }
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Air Infiltration - Test In is required.');  
                            }
                        }
                        //required - end
                        //AUDIT ONLY - END

                        //RETROFIT ONLY - START                    
                        if (b.ProjectStatus == 'retrofit') {
                            //required - start
                            if (b.SameAs == NULL) {
                                if (b.NumberOfBedrooms == NULL || b.NumberOfBedrooms == 0.0)
                                    result.add('Building ' + b.SystemIdentifier + 
                                        ' Building Construction: Number of bedrooms is required.');
                            } else {
                                for (HPXML.Building b2: validateHPXML.buildings){
                                    if (b2.SystemIdentifier == b.SameAs) {
                                        if (b.NumberOfBedrooms == NULL) {
                                            if (b2.NumberOfBedrooms == NULL || b2.NumberOfBedrooms == 0.0)
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Building Construction: Number of bedrooms is required.');
                                        }
                                    }
                                }
                            }

                            if (validateHPXML.aims.size() > 0) {
                                for (HPXML.AirInfiltrationMeasurement a: validateHPXML.aims) {
                                    if (a.BuildingId == b.SystemIdentifier) {
                                        if (a.SameAs == NULL) {
                                            if (a.HousePressure == NULL && hasAIMHousePressure == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Air Infiltration - Test Out: House pressure is required.');  
                                                hasAIMHousePressure = 1;
                                            }
                                            if (a.UnitofMeasure == NULL && hasAIMUOM == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Air Infiltration - Test Out: Building air leakage unit is required.');
                                                hasAIMUOM = 1;
                                            } else {
                                                if (a.UnitofMeasure != 'CFM' && hasAIMUOMCFM == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Air Infiltration - Test Out: Building air leakage unit must be CFM.');
                                                    hasAIMUOMCFM = 1;
                                                }
                                            }
                                            if (a.AirLeakage == NULL && hasAIMAirLeakage == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Air Infiltration - Test Out: Building air leakage is required.'); 
                                                hasAIMAirLeakage = 1;
                                            }
                                        } else {
                                            for (HPXML.AirInfiltrationMeasurement a2: validateHPXML.aims) {
                                                if (a2.SystemIdentifier == a.SameAs) {
                                                    if (a.HousePressure == NULL) {
                                                        if (a2.HousePressure == NULL && hasAIMHousePressure == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Air Infiltration - Test Out: House pressure is required.');  
                                                            hasAIMHousePressure = 1;
                                                        }
                                                    }
                                                    if (a.UnitofMeasure == NULL) {
                                                        if (a2.UnitofMeasure == NULL && hasAIMUOM == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Air Infiltration - Test Out: Building air leakage unit is required.');
                                                            hasAIMUOM = 1;
                                                        } else {
                                                            if (a2.UnitofMeasure != 'CFM' && hasAIMUOMCFM == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Air Infiltration - Test Out: Building air leakage unit must be CFM.');
                                                                hasAIMUOMCFM = 1; 
                                                            }
                                                        }
                                                    }
                                                    if (a.AirLeakage == NULL) {
                                                        if (a2.AirLeakage == NULL && hasAIMAirLeakage == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Air Infiltration - Test Out: Building air leakage is required.'); 
                                                            hasAIMAirLeakage = 1;   
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Air Infiltration - Test Out is required.');
                            }

                            if (validateHPXML.heatingsystems.size() > 0) {
                                for (HPXML.HeatingSystem hs: validateHPXML.heatingsystems) {
                                    if (hs.BuildingId == b.SystemIdentifier) {
                                        if (hs.SameAs == NULL) {
                                            if (hs.HeatingSystemFuel == NULL && hasHSFuel == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Heating - Measure: Fuel is required.');     
                                                hasHSFuel = 1;
                                            }
                                            if (hs.Type == NULL && hasHSType  == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Heating - Measure: Heating system type is required.');  
                                                hasHSType = 1;
                                            }
                                            if (hs.FractionHeatLoadServed == NULL && hasHSFHLS == 0) {
                                                result.add('Building ' + b.SystemIdentifier + 
                                                    ' Heating - Measure: Fraction heat load served is required.');  
                                                hasHSFHLS = 1;
                                            }
                                        } else {
                                            for (HPXML.HeatingSystem hs2: validateHPXML.heatingsystems) {
                                                if (hs2.SystemIdentifier == hs.SameAs) {
                                                    if (hs.HeatingSystemFuel == NULL) {
                                                        if (hs2.HeatingSystemFuel == NULL && hasHSFuel == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Heating - Measure: Fuel is required.');     
                                                            hasHSFuel = 1;
                                                        }
                                                    }
                                                    if (hs.Type == NULL) {
                                                        if (hs2.Type == NULL && hasHSType  == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Heating - Measure: Heating system type is required.');  
                                                            hasHSType = 1;
                                                        }
                                                    }
                                                    if (hs.FractionHeatLoadServed == NULL) {
                                                        if (hs2.FractionHeatLoadServed == NULL && hasHSFHLS == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Heating - Measure: Fraction heat load served is required.');  
                                                            hasHSFHLS = 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }
                            } else {
                                // check heat pump exist
                                Set<String> thisHeatPumpSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisHeatPumpSetResult = thisHeatPumpSet.contains('heatpump');

                                if (thisHeatPumpSetResult != true) {
                                   result.add('Building ' + b.SystemIdentifier 
                                           + ' Heating - Measure: Heating system is required.');  
                                }
                            }

                            if (validateHPXML.projects.size() > 0) {
                                Integer projectCount = 0;
                                for (HPXML.Project proj: validateHPXML.projects){
                                    if (proj.BuildingId == b.SystemIdentifier) {
                                        projectCount =+ 1;
                                        if (proj.Title == NULL || proj.Title == '' && hasProjTitle == 0) {
                                            result.add('Building ' + b.SystemIdentifier + ' Project: Title is required.');  
                                            hasProjTitle = 1;
                                        }
                                    }
                                }

                                //if (projectCount == 0)
                                //        result.add('Building ' + b.SystemIdentifier + ' Project is required.');     
                            } else {
                                result.add('Building ' + b.SystemIdentifier + ' Project: Title is required.');  
                            }
                            //required - end

                            //dependent and required - start
                            if (validationLevel == 2) {
                                Set<String> thisLightingGroupSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisLightingGroupSetResult = thisLightingGroupSet.contains('lightinggroup');

                                if (thisLightingGroupSetResult == true) {
                                    for (HPXML.LightingGroup lg: validateHPXML.lightinggroups) {
                                        if (lg.BuildingId == b.SystemIdentifier) {
                                            if (lg.SameAs == NULL) {
                                                if (lg.NumberofUnits == NULL && hasLGNumberofUnits == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Lighting - Measure: Number of units is required.');     
                                                    hasLGNumberofUnits = 1;
                                                }
                                                if (lg.LightingType == NULL && hasLGLightingType == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Lighting - Measure: Lighting type is required.');   
                                                    hasLGLightingType = 1;
                                                }
                                            } else {
                                                for (HPXML.LightingGroup lg2: validateHPXML.lightinggroups) {
                                                    if (lg2.SystemIdentifier == lg.SameAs) {
                                                        if (lg.NumberofUnits == NULL) {
                                                            if (lg2.NumberofUnits == NULL && hasLGNumberofUnits == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Lighting - Measure: Number of units is required.');     
                                                                hasLGNumberofUnits = 1;
                                                            }
                                                        }
                                                        if (lg.LightingType == NULL) {
                                                            if (lg2.LightingType == NULL && hasLGLightingType == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Lighting - Measure: Lighting type is required.');   
                                                                hasLGLightingType = 1;
                                                            }
                                                        }

                                                    }
                                                }
                                            }


                                        }
                                    }
                                }

                                Set<String> thisRefrigeratorSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisRefrigeratorSetResult = thisRefrigeratorSet.contains('refrigerator');

                                if (thisRefrigeratorSetResult == true) {
                                    for (HPXML.Refrigerator ref: validateHPXML.refrigerators) {
                                        if (ref.BuildingId == b.SystemIdentifier) {
                                            if (ref.SameAs == NULL) {
                                                if (ref.PrimaryIndicator == NULL && hasRefPrimaryIndicator == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Refrigerator - Measure: Primary refrigerator is required.');    
                                                    hasRefPrimaryIndicator = 1;
                                                }
                                                if (ref.ModelYear == NULL && hasRefModelYear == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Refrigerator - Measure: Model year is required.');  
                                                    hasRefModelYear = 1;
                                                }
                                            } else {
                                                for (HPXML.Refrigerator ref2: validateHPXML.refrigerators) {
                                                    if (ref2.SystemIdentifier == ref.SameAs) {
                                                        if (ref.PrimaryIndicator == NULL) {
                                                            if (ref2.PrimaryIndicator == NULL && hasRefPrimaryIndicator == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Refrigerator - Measure: Primary refrigerator is required.');    
                                                                hasRefPrimaryIndicator = 1;
                                                            }
                                                        }
                                                        if (ref.ModelYear == NULL) {
                                                            if (ref2.ModelYear == NULL && hasRefModelYear == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Refrigerator - Measure: Model year is required.');  
                                                                hasRefModelYear = 1;
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisWaterHeatingSet2 = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisWaterHeatingSetResult2 = thisWaterHeatingSet2.contains('waterheating');

                                if (thisWaterHeatingSetResult2 == true) {
                                    for (HPXML.WaterHeating wh: validateHPXML.waterheatings) {
                                        if (wh.BuildingId == b.SystemIdentifier) {
                                            if (wh.SameAs == NULL) {
                                                if (wh.WaterHeaterInsulation == 1) {
                                                    if (wh.LengthofPipeInsulated == NULL && hasWHLengthofPipeInsulated == 0) {
                                                        result.add('Building ' + b.SystemIdentifier + 
                                                            ' Water heater - Measure: Length of Pipe Insulated is required.');    
                                                        hasWHLengthofPipeInsulated = 1;
                                                    }
                                                }
                                            } else {
                                                for (HPXML.WaterHeating wh2: validateHPXML.waterheatings) {
                                                    if (wh2.SystemIdentifier == wh.SameAs) {
                                                        if (wh2.WaterHeaterInsulation == 1) {
                                                            if (wh2.LengthofPipeInsulated == NULL && hasWHLengthofPipeInsulated == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Water heater - Measure: Length of Pipe Insulated is required.');    
                                                                hasWHLengthofPipeInsulated = 1;
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisVentilationFanSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisVentilationFanSetResult = thisVentilationFanSet.contains('ventilationfan');

                                if (thisVentilationFanSetResult == true) {
                                    for (HPXML.VentilationFan f: validateHPXML.ventilationfans) {
                                        if (f.SameAs == NULL) {
                                            if (f.BuildingId == b.SystemIdentifier) {
                                                if (f.UsedForWholeBuildingVentilation == NULL && 
                                                        hasVFUsedForWholeBuildingVentilation == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Ventilation Fans: Used For Whole Building Ventilation is required.');   
                                                    hasVFUsedForWholeBuildingVentilation = 1;
                                                }
                                                if (f.UsedForSeasonalCoolingLoadReduction == NULL && 
                                                        hasVFUsedForSeasonalCoolingLoadReduction == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' Ventilation Fans: Used For Seasonal Cooling Load Reduction is required.');  
                                                    hasVFUsedForSeasonalCoolingLoadReduction = 1;
                                                }
                                            }
                                        } else {
                                            for (HPXML.VentilationFan f2: validateHPXML.ventilationfans) {
                                                if (f2.SystemIdentifier == f.SameAs) {
                                                    if (f.UsedForWholeBuildingVentilation == NULL) {
                                                        if (f2.UsedForWholeBuildingVentilation == NULL && 
                                                                hasVFUsedForWholeBuildingVentilation == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Ventilation Fans: Used For Whole Building Ventilation is required.');   
                                                            hasVFUsedForWholeBuildingVentilation = 1;
                                                        }
                                                    }
                                                    if (f.UsedForSeasonalCoolingLoadReduction == NULL) {
                                                        if (f2.UsedForSeasonalCoolingLoadReduction == NULL && 
                                                                hasVFUsedForSeasonalCoolingLoadReduction == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' Ventilation Fans: Used For Seasonal Cooling Load Reduction is required.');  
                                                            hasVFUsedForSeasonalCoolingLoadReduction = 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }

                                Set<String> thisHVACDistributionSet2 = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisHVACDistributionSetResult2 = thisHVACDistributionSet2.contains('foundation');

                                if (thisHVACDistributionSetResult2 == true) {
                                    for(HPXML.HVACDistribution hd: validateHPXML.hvacdistributions) {
                                        if(hd.BuildingId == b.SystemIdentifier) {

                                            if (hd.SameAS == NULL) {
                                                if (hd.AnnualHeatingDistributionSystemEfficiency == NULL && 
                                                        hasAnnualHeatingDistributionSystemEfficiency == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' HVAC Distribution: Annual heating distribution system efficiency is required.');   
                                                    hasAnnualHeatingDistributionSystemEfficiency = 1;
                                                }
                                                if (hd.AnnualCoolingDistributionSystemEfficiency == NULL && 
                                                        hasAnnualCoolingDistributionSystemEfficiency == 0) {
                                                    result.add('Building ' + b.SystemIdentifier + 
                                                        ' HVAC Distribution: Annual cooling distribution system efficiency is required.');   
                                                    hasAnnualCoolingDistributionSystemEfficiency = 1;
                                                }
                                            } else {
                                                for (HPXML.HVACDistribution hd2: validateHPXML.hvacdistributions) {
                                                    if (hd2.SystemIdentifier == hd.SameAs) {
                                                        if (hd.AnnualHeatingDistributionSystemEfficiency == NULL) {
                                                            if (hd2.AnnualHeatingDistributionSystemEfficiency == NULL && 
                                                                    hasAnnualHeatingDistributionSystemEfficiency == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' HVAC Distribution: Annual heating distribution system efficiency is required.');   
                                                                hasAnnualHeatingDistributionSystemEfficiency = 1;
                                                            }
                                                        }
                                                        if (hd.AnnualCoolingDistributionSystemEfficiency == NULL) {
                                                            if (hd2.AnnualCoolingDistributionSystemEfficiency == NULL && 
                                                                    hasAnnualCoolingDistributionSystemEfficiency == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' HVAC Distribution: Annual cooling distribution system efficiency is required.');   
                                                                hasAnnualCoolingDistributionSystemEfficiency = 1;
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            if (validateHPXML.ducts.size() > 0) {
                                                for (HPXML.Duct d: validateHPXML.ducts) {
                                                    if (d.SystemIdentifier == hd.SystemIdentifier) {
                                                        if (d.FractionDuctArea == NULL && hasDuctFractionDuctArea == 0) {
                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                ' HVAC Distribution: Fraction duct area is required.');   
                                                            hasDuctFractionDuctArea = 1;
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                }

                                Set<String> thisPoolSet = validateHPXML.buildingMap.get(b.SystemIdentifier);
                                Boolean thisPoolSetResult = thisPoolSet.contains('pool');

                                if (thisPoolSetResult == true) {
                                    for (HPXML.Pool p: validateHPXML.pools){
                                        if (p.BuildingId == b.SystemIdentifier) {

                                            if (validateHPXML.poolpumps.size() > 0) {
                                                for (HPXML.PoolPump pp: validateHPXML.poolpumps) {
                                                    if(pp.PoolSystemIdentifier == p.SystemIdentifier) {
                                                        if(pp.SameAs == NULL) {
                                                            if (pp.HoursPerDay == NULL && hasPPHoursPerDay == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Pool Pumps: Hours per day is required.');   
                                                                hasPPHoursPerDay = 1;
                                                            }
                                                            if (pp.Type == NULL && hasPPType == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Pool Pumps: Pool pump type is required.');  
                                                                hasPPType = 1;
                                                            }
                                                            if (pp.RatedHorsepower == NULL && hasPPRatedHorsepower == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Pool Pumps: Rate horsepower is required.');     
                                                                hasPPRatedHorsepower = 1;
                                                            }
                                                            if (pp.SpeedSetting == NULL && hasPPSpeedSetting == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Pool Pumps: Speed setting is required.');   
                                                                hasPPSpeedSetting = 1;
                                                            }
                                                            if (pp.PumpSpeedPower == NULL && hasPPPumpSpeedPower == 0) {
                                                                result.add('Building ' + b.SystemIdentifier + 
                                                                    ' Pool Pumps: Power is required.');   
                                                                hasPPPumpSpeedPower = 1;
                                                            }
                                                        } else {
                                                            for (HPXML.PoolPump pp2: validateHPXML.poolpumps) {
                                                                if (pp2.SystemIdentifier == pp.SameAs) {
                                                                    if (pp.HoursPerDay == NULL) {
                                                                        if (pp2.HoursPerDay == NULL && hasPPHoursPerDay == 0) {
                                                                            result.add('Building ' + b.SystemIdentifier + 
                                                                                ' Pool Pumps: Hours per day is required.');
                                                                            hasPPHoursPerDay = 1;
                                                                        }
                                                                    }
                                                                    if (pp.Type == NULL) {
                                                                        if (pp2.Type == NULL && hasPPType == 0) {
                                                                            result.add('Building ' + b.SystemIdentifier +
                                                                                ' Pool Pumps: Pool pump type is required.');
                                                                            hasPPType = 1;
                                                                        }
                                                                    }
                                                                    if (pp.RatedHorsepower == NULL) {
                                                                        if(pp2.RatedHorsepower == NULL && hasPPRatedHorsepower == 0) {
                                                                            result.add('Building ' + b.SystemIdentifier +
                                                                                ' Pool Pumps: Rate horsepower is required.');
                                                                            hasPPRatedHorsepower = 1;
                                                                        }
                                                                    }
                                                                    if (pp.SpeedSetting == NULL) {
                                                                        if (pp2.SpeedSetting == NULL && hasPPSpeedSetting == 0) {
                                                                            result.add('Building ' + b.SystemIdentifier +
                                                                                ' Pool Pumps: Speed setting is required.');
                                                                            hasPPSpeedSetting = 1;
                                                                        }
                                                                    }
                                                                    if (pp.PumpSpeedPower == NULL) {
                                                                        if (pp2.PumpSpeedPower == NULL && hasPPPumpSpeedPower == 0) {
                                                                            result.add('Building ' + b.SystemIdentifier +
                                                                                ' Pool Pumps: Power is required.');
                                                                            hasPPPumpSpeedPower = 1;
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }

                                                    }
                                                }
                                            }

                                        }
                                    }
                                }
                            }
                            //dependent and required - end

                        }
                        //RETROFIT ONLY - END
                    }
                }
                result.addAll(energyTypeErrors);
                //STATUS VALIDATION - end
            } //end no validation
        } else {
            result.add('Software is not supported.');
        }
        //SOFTWARE VALIDATION - end

        //VALIDATION - END
        return result;
    }

    private Boolean elementStart(xmlStreamReader reader, String tagName) {
        return (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == tagName);
    }

    private Boolean elementNotEnd(xmlStreamReader reader, String tagName) {
        return (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == tagName));
    }

    public Integer getValidationLevel() {
        //0 - skip validation, 1 = validate all required fields, 2 = validate all required and dependent required
        Integer validationLevel = 0;
        Boolean validateRequired = false;
        Boolean validateDependent = false;

        // Get hpxml validation
        PGE_Portal_Settings__c settings =  PGE_Portal_Settings__c.getInstance(PGE_SETTINGS_DATASET_NAME);
        if (settings != null && settings.HPXML_Validation__c != null) {
            for (String c : settings.HPXML_Validation__c.split(';')) {
                if (c.toLowerCase() == 'required')
                    validateRequired = true;
                if (c.toLowerCase() == 'dependent & required')
                    validateDependent = true;
            }
        }

        if (validateDependent == true)
            validationLevel = 2;
        if (validateRequired == true && validateDependent == false)
            validationLevel = 1;

        return validationLevel;
    }

}