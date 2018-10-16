/**
 * Parser for EnergyPro XML used in Advanced Home Upgrade Applications.
 *
 * @author Anna Woodall, RedTeal Inc. <admin@redteal.com>
 * @since 2014-09
 */
 public class EnergyProXMLParser {

    private static final String ENERGYPRO_SOFTWARE_VERSION_ERROR = 'EnergyPro {0} is not supported. Please replace' + 
            'Energy Model files to continue.';

    private Application__c application              {get; set; }
    private Sub_Application__c subApplication       {get; set; }
    private Boolean isPostApplication               {get; set; }
    private String xmlString                        {get; set; }
    private String softwareVersion                  {get; set; }

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


    //-- Constructor
    public EnergyProXMLParser(Application__c app, Sub_Application__c subApp, Boolean isPostApp, Attachment xmlFile) {
        application = app;
        subApplication = subApp;
        isPostApplication = isPostApp;

        //requery the attachment
        List<Attachment> xmlFiles = [SELECT Id, Body FROM Attachment WHERE Id = :xmlFile.Id limit 1];
        if (xmlFiles.size() > 0) {
            xmlFile = xmlFiles[0];
            if (xmlFiles[0].Body != null) { 
                xmlString = xmlFiles[0].Body.toString();
                System.debug('xmlString: ' + xmlString);
            }
        }
    }

    //-- Parse the software name
    public String getSoftwareName() {
        String softwareName = '';

        if (String.isNotEmpty(xmlString)) {
            //create a stream reader
            xmlStreamReader reader = new xmlStreamReader(xmlString);

            while (reader.hasNext() && softwareName == '') {
                //if start of RunDetails node
                if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'RunDetails') {
                    softwareName = reader.getAttributeValue(null, 'SoftwareName');
                }
                else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'XMLType') {
                    reader.next();
                    if (reader.hasText()) {
                        softwareName = reader.getText();
                    }
                }
                reader.next();
            }
        }
        return softwareName;
    }

    private Boolean isSoftwareVersionValid() {
        Boolean validSoftwareVersion = false;

        //get software version requirements from custom setting
        String minimum = '', maximum = '';
        Software_Version__c sv = Software_Version__c.getValues('EnergyPro');
        if (sv != null) {
            if (sv.Minimum__c != null) {
                minimum = sv.Minimum__c;
            }
            if (sv.Maximum__c != null) {
                maximum = sv.Maximum__c;
            }
        }

        //only support specified versions
        if (String.isNotEmpty(softwareVersion) && String.isNotEmpty(minimum) && String.isNotEmpty(maximum) &&
            versionCompare(softwareVersion, minimum) >= 0 && versionCompare(softwareVersion, maximum) <= 0) {
            validSoftwareVersion = true;
        }

        return validSoftwareVersion;
    }

    //-- Parses EnergyPro XML data into an instance of the EnergyProXML class
    public void parseEnergyProXML() {
        Boolean validVersion = true;
        //create a stream reader
        xmlStreamReader reader = new xmlStreamReader(xmlString);

        //create an instance to hold the data
        EnergyProXML entry = new EnergyProXML(application, subApplication, isPostApplication);

        entry.isPostApplication = isPostApplication;

        while (reader.hasNext() && validVersion) {
            //if start of RunDetails node
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'RunDetails') {
                //parse the software version
                softwareVersion = reader.getAttributeValue(null, 'SoftwareVersion');

                validVersion = isSoftwareVersionValid();
                if (validVersion) {
                    entry.SoftwareVersion = softwareVersion;
                }
            }
            //if start of Project node
            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Project') {
                //create new project
                entry.project = new EnergyProXML.Project();

                //get project attributes of interest
                entry.project.CAZone = reader.getAttributeValue(null, 'CAZone');
                entry.project.PlanName = reader.getAttributeValue(null, 'PlanName');

                while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Project')) {
                    reader.next();
                    
                    //if start of ProjectTitle node
                    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ProjectTitle') {
                        //get project attributes of interest
                        entry.project.Address = reader.getAttributeValue(null, 'Address');
                        entry.project.City = reader.getAttributeValue(null, 'City');
                        entry.project.State = reader.getAttributeValue(null, 'State');
                        entry.project.Zip = reader.getAttributeValue(null, 'Zip');
                        entry.project.Name = reader.getAttributeValue(null, 'Name');
                    }

                    //if start of DocumentationAuthorTitle node
                    else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'DocumentationAuthorTitle') {
                        //get project attributes of interest
                        entry.project.Company = reader.getAttributeValue(null, 'Company');
                    }
                }
            }

            //if start of Building node
            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Building') {
                //get building attributes of interest
                entry.project.BuildingType = reader.getAttributeValue(null, 'BuildingType');
                entry.project.ConditionedFloorArea = reader.getAttributeValue(null, 'ConditionedFloorArea');
                entry.project.NumberOfDwellingUnits = reader.getAttributeValue(null, 'NumberOfDwellingUnits');
                entry.project.Stories = reader.getAttributeValue(null, 'Stories');
               
                while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Building')) {
                    reader.next();

                    //if start of Appliance node
                    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Appliance') {
                        //create new Appliance
                        EnergyProXML.Appliance app = new EnergyProXML.Appliance();
                        //get Appliance attributes of interest
                        app.PoolType = reader.getAttributeValue(null, 'PoolType');
                        app.SpaType = reader.getAttributeValue(null, 'SpaType');
                        //add to list of appliances
                        entry.appliances.add(app);
                    }
                    
                    //if start of Plant node
                    else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Plant') {
                        //create new Plant
                        EnergyProXML.Plant plant = new EnergyProXML.Plant();
                        //add to list of plants
                        entry.plants.add(plant);

                        while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Plant')) {
                            reader.next();

                            //if start of WaterHeating node
                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'WaterHeating') {
                                //get Plant attributes of interest
                                plant.Name = reader.getAttributeValue(null, 'Name');
                                plant.DHWType = reader.getAttributeValue(null, 'DHWType');
                            }

                            //if start of HVAC node
                            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'HVAC') {
                                //create new HVAC
                                EnergyProXML.HVAC hvac = new EnergyProXML.HVAC();
                                //add to list of HVACs
                                plant.HVACs.add(hvac);

                                //get HVAC attributes of interest
                                hvac.ExistCFM50 = reader.getAttributeValue(null, 'ExistCFM50');
                                hvac.ExistSLA = reader.getAttributeValue(null, 'ExistSLA');
                                hvac.DuctStatus = reader.getAttributeValue(null, 'DuctStatus');
                                hvac.Thermostat = reader.getAttributeValue(null, 'Thermostat');
                                hvac.EER = reader.getAttributeValue(null, 'EER');
                                hvac.DuctRValue = reader.getAttributeValue(null, 'DuctRValue');
                                hvac.DuctLocation = reader.getAttributeValue(null, 'DuctLocation');
                                hvac.Flow = reader.getAttributeValue(null, 'Flow');
                                hvac.CoolingHVACType = reader.getAttributeValue(null, 'CoolingHVACType');
                                hvac.HeatingHVACType = reader.getAttributeValue(null, 'HeatingHVACType');
                                hvac.HVACSystemType = reader.getAttributeValue(null, 'HVACSystemType');

                                while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'HVAC')) {
                                    reader.next();

                                    //if start of Zone node
                                    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Zone') {
                                        //create new Zone and add to list
                                        EnergyProXML.Zone zone = new EnergyProXML.Zone();
                                        hvac.zones.add(zone);

                                        //get Zone attributes of interest
                                        zone.ZoneType = reader.getAttributeValue(null, 'ZoneType');
                                        zone.FloorNo = reader.getAttributeValue(null, 'FloorNo');
                                        
                                        while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Zone')) {
                                            reader.next();

                                            //if start of Room node
                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Room') {
                                                //create new Room and add to list
                                                EnergyProXML.Room room = new EnergyProXML.Room();
                                                zone.rooms.add(room);

                                                //get Room attributes of interest
                                                room.NBedrooms = reader.getAttributeValue(null, 'NBedrooms');
                                                room.FloorArea = reader.getAttributeValue(null, 'FloorArea');
                                                room.CeilingHeight = reader.getAttributeValue(null, 'CeilingHeight');
                                                room.YearBuilt = reader.getAttributeValue(null, 'YearBuilt');
                                                
                                                while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Room')) {
                                                    reader.next();
                                                    
                                                    //if start of Insulation node
                                                    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Insulation') {
                                                        
                                                        //create new Insulation and add to list
                                                        EnergyProXML.Insulation insul = new EnergyProXML.Insulation();
                                                        room.insulations.add(insul);
                                                        insul.SurfaceType = reader.getAttributeValue(null, 'SurfaceType');
                                                        insul.Area = reader.getAttributeValue(null, 'Area');
                                                        insul.UFactor = reader.getAttributeValue(null, 'UFactor');

                                                        while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Insulation')) {
                                                            reader.next();

                                                            //if start of Fenestration node
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Fenestration') {
                                                                //create new fenestration and add to list
                                                                EnergyProXML.Fenestration fenestration = new EnergyProXML.Fenestration();
                                                                insul.fenestrations.add(fenestration);

                                                                //get Fenestration attributes of interest
                                                                fenestration.Area = reader.getAttributeValue(null, 'Area');
                                                                fenestration.UFactor = reader.getAttributeValue(null, 'UFactor');
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    //if start of ExistingDistribution node
                                    else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ExistingDistribution') {
                                        //get ExistingDistribution attributes of interest
                                        hvac.DuctLeakageCFM25 = reader.getAttributeValue(null, 'DuctLeakageCFM25');
                                        hvac.AtticInsulR = reader.getAttributeValue(null, 'AtticInsulR');
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //if start of Result node
            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Result') {
                //create new Result and add to list
                EnergyProXML.Result result = new EnergyProXML.Result();
                entry.results.add(result);

                //get Result attributes of interest
                result.ResultType = reader.getAttributeValue(null, 'ResultType');
                result.GasUseTherms = reader.getAttributeValue(null, 'GasUseTherms');
                result.ElectricityUsekWh = reader.getAttributeValue(null, 'ElectricityUsekWh');
                result.ElectricityAvgkW = reader.getAttributeValue(null, 'ElectricityAvgkW');
                
                while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Result')) {
                    reader.next();

                    //if start of UtilityElecUse node
                    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'UtilityElecUse') {
                        //get UtilityElecUse attributes of interest
                        result.Heating = reader.getAttributeValue(null, 'Heating');
                        result.Cooling = reader.getAttributeValue(null, 'Cooling');
                        result.WaterHeating = reader.getAttributeValue(null, 'WaterHeating');
                        result.Appliances = reader.getAttributeValue(null, 'Appliances');
                        result.Ancillary = reader.getAttributeValue(null, 'Ancillary');
                        result.IndoorLighting = reader.getAttributeValue(null, 'IndoorLighting');
                        result.Pumps = reader.getAttributeValue(null, 'Pumps');
                        result.Fans = reader.getAttributeValue(null, 'Fans');
                        result.OutdoorLighting = reader.getAttributeValue(null, 'OutdoorLighting');
                        result.Renewables = reader.getAttributeValue(null, 'Renewables');
                    }
                    
                    //if start of UtilityGasUse node
                    else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'UtilityGasUse') {
                        //get UtilityGasUse attributes of interest
                        result.GasHeating = reader.getAttributeValue(null, 'Heating');
                        result.GasCooling = reader.getAttributeValue(null, 'Cooling');
                        result.GasWaterHeating = reader.getAttributeValue(null, 'WaterHeating');
                        result.GasAppliances = reader.getAttributeValue(null, 'Appliances');
                        result.GasAncillary = reader.getAttributeValue(null, 'Ancillary');
                        result.GasIndoorLighting = reader.getAttributeValue(null, 'IndoorLighting');
                        result.GasPumps = reader.getAttributeValue(null, 'Pumps');
                        result.GasFans = reader.getAttributeValue(null, 'Fans');
                        result.GasOutdoorLighting = reader.getAttributeValue(null, 'OutdoorLighting');
                        result.GasRenewables = reader.getAttributeValue(null, 'Renewables');
                    }
                    
                    //if start of AlternativeDescription node
                    else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'AlternativeDescription') {
                        //create new AlternativeDescription and add to list
                        EnergyProXML.AlternativeDescription alt = new EnergyProXML.AlternativeDescription();
                        result.alternativeDescriptions.add(alt);
                        
                        //get AlternativeDescription attributes of interest
                        alt.Label = reader.getAttributeValue(null, 'Label');
                        alt.Value = reader.getAttributeValue(null, 'Value');
                        alt.Units = reader.getAttributeValue(null, 'Units');
                    }
                }
            }

            //if start of BuildingRetrofit node
            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'BuildingRetrofit') {
                while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'BuildingRetrofit')) {
                    reader.next();

                    //if start of Building node
                    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Building') {
                        while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Building')) {
                            reader.next();

                            //if start of Occupants node
                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Occupants') {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.project.Occupants = reader.getText();
                                }
                            }

                            //if start of FoundationType node
                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'FoundationType') {
                                reader.next();
                                if (reader.hasText()) {
                                    entry.project.FoundationType = reader.getText();
                                }
                            }
                        }
                    }

                    //if start of Improvements node
                    else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Improvements') {
                        //create new Improvement and add to list
                        EnergyProXML.Improvements improvement = new EnergyProXML.Improvements();
                        entry.improvements.add(improvement);

                        while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Improvements')) {
                            reader.next();

                            //if start of ImprovementCategory node
                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ImprovementCategory') {
                                reader.next();
                                if (reader.hasText()) {
                                    improvement.ImprovementCategory = reader.getText();
                                }
                            }

                            //if start of ImprovementName node
                            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ImprovementName') {
                                reader.next();
                                if (reader.hasText()) {
                                    improvement.ImprovementName = reader.getText();
                                }
                            }

                            //if start of ImprovementAmount node
                            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ImprovementAmount') {
                                reader.next();
                                if (reader.hasText()) {
                                    improvement.ImprovementAmount = reader.getText();
                                }
                            }

                            //if start of ImprovementAction node
                            //this node has neither attributes nor text -- no data to capture!!!
                            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ImprovementAction') {
                                reader.next();
                                if (reader.hasText()) {
                                    improvement.ImprovementAction = reader.getText();
                                }
                            }

                            //if start of ImprovementValues node
                            else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ImprovementValues') {
                                //create new ImprovementValues and add to list
                                EnergyProXML.ImprovementValues values = new EnergyProXML.ImprovementValues();
                                improvement.improvementValues.add(values);

                                while (reader.hasNext() && !(reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'ImprovementValues')) {
                                    reader.next();

                                    //if start of Characteristic node
                                    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Characteristic') {
                                        reader.next();
                                        if (reader.hasText()) {
                                            values.Characteristic = reader.getText();
                                        }
                                    }

                                    //if start of InitialValue node
                                    else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'InitialValue') {
                                        reader.next();
                                        if (reader.hasText()) {
                                            values.InitialValue = reader.getText();
                                        }
                                    }

                                    //if start of FinalValue node
                                    else if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'FinalValue') {
                                        reader.next();
                                        if (reader.hasText()) {
                                            values.FinalValue = reader.getText();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            reader.next();
        }
        
        if (!validVersion) {
            String msg = String.format(ENERGYPRO_SOFTWARE_VERSION_ERROR, new List<String>{softwareVersion});
            throw new EnergyProXMLParserException(msg);
        }
        
        //analyze the parsed data
        entry.analyzeData();
    }

    public class EnergyProXMLParserException extends Exception {}
    
}