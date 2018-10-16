/**
 * This class performs filtering operations.
 *
 * @author Matias Medina <matias.medina@modelit.xyz>
 * @since 2016-01
 */
public with sharing class MeasureUtils {

    public static final Id ACQC_RECORD_TYPE;
    public static final Id HU_RECORD_TYPE;
    public static final String PROGRAM_TYPE_ACQC = 'ACQC';
    public static final String PROGRAM_TYPE_HU = 'HU';
    // Map to associate distinct measure codes between rebate types and measure savings
    private static final Map<String, String> REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE =
            new Map<String, String> {'TK08' => 'HV287'};

    public static Boolean isTriggerExecuting = false;

    static {
        Map<String, Schema.RecordTypeInfo> recordTypeNameToId = Schema.SObjectType.Measure__c.getRecordTypeInfosByName();
        ACQC_RECORD_TYPE = recordTypeNameToId.get(PROGRAM_TYPE_ACQC).getRecordTypeId();
        HU_RECORD_TYPE = recordTypeNameToId.get(PROGRAM_TYPE_HU).getRecordTypeId();
    }

    /**
     * Get the measures that have Measure Type.
     *
     * @param measures The list of measure to be filtered.
     * @return a map of application ids by boolean, which determines if there has been a change on the qualifying
     * measures.
     */
    public static Map<Id, Boolean> filterMeasuresToMatchMeasureCombination(List<Measure__c> measures) {
        Map<Id, Boolean> appsIdToProcess = new Map<Id, Boolean>();

        List<Measure__c> existingMeasures = [
            SELECT Application__c, Measure_Code__c, Measure_Code_Abbreviation__c, Qualifying_Measure_Code__c
            FROM Measure__c
            WHERE Id IN :measures
            ];

        // existingMeasures list will be empty when this method is called from after delete trigger.
        // In this case, we need to use the old version of the list of measures.
        measures = existingMeasures.isEmpty() ? measures : existingMeasures;

        for (Measure__c measure : measures) {
            Boolean hasQualifyingMeasure = false;
            // HU Measures must have the Measure Code and Measure Code Abbreviation populated.
            if (String.isNotBlank(measure.Measure_Code__c) && String.isNotBlank(measure.Measure_Code_Abbreviation__c)) {
                // Determine if the measure is a qualifying measure.
                if (String.isNotBlank(measure.Qualifying_Measure_Code__c)) {
                    hasQualifyingMeasure = true;
                }

                if (!appsIdToProcess.containsKey(measure.Application__c) || !appsIdToProcess.get(measure.Application__c)) {
                    appsIdToProcess.put(measure.Application__c, hasQualifyingMeasure);
                }
            }
        }

        return appsIdToProcess;
    }

    /**
     * Wrapper class to keep the custom metadata from Mesure_Combination_Code__mdt for records for ACQC
     */
    public virtual class MeasureSavingsWrapper {
        public Integer climateZone { get; set; }
        public Decimal kwSavings { get; set; }
        public Decimal kwhSavings { get; set; }
        public Decimal thermsSavings { get; set; }

        public MeasureSavingsWrapper(Integer climateZone, Decimal kwSavings, Decimal kwhSavings,
                Decimal thermsSavings) {
            this.climateZone = climateZone;
            this.kwSavings = kwSavings;
            this.kwhSavings = kwhSavings;
            this.thermsSavings = thermsSavings;
        }
    }

    /**
     * Wrapper class to keep the custom metadata from Mesure_Combination_Code__mdt for records for HU
     */
    public class MeasureCodeWrapper extends MeasureSavingsWrapper {
        public String measureCode { get; set; }
        public String measureCombination { get; set; }
        public Decimal incrementalMeasureCost { get; set; }
        public Decimal kwSavings2ndBl { get; set; }
        public Decimal kwhSavings2ndBl { get; set; }
        public Decimal thermsSavings2ndBl { get; set; }
        public Decimal incrementalMeasureCost2ndBl { get; set; }
        public Integer measureCombinationSize { get; set; }
        public String buildingVintage { get; set; }
        public Set<String> measureCodes = new Set<String>();
        public String developerName;

        public MeasureCodeWrapper(String measureCode, String measureCombination, Decimal kwSavings, Decimal kwhSavings,
                Decimal thermsSavings, Decimal incrementalMeasureCost, Decimal kwSavings2ndBl, Decimal kwhSavings2ndBl,
                Decimal therms_savings_2nd_bl, Decimal incrementalMeasureCost2ndBl, Integer measureCombinationSize,
                String buildingVintage, Integer climateZone, String developerName) {
            super(climateZone, kwSavings, kwhSavings, thermsSavings);
            this.measureCode = measureCode;
            this.measureCombination = measureCombination;
            this.measureCodes = new Set<String>(measureCombination.split(','));
            this.incrementalMeasureCost = incrementalMeasureCost;
            this.kwSavings2ndBl = kwSavings2ndBl;
            this.kwhSavings2ndBl = kwhSavings2ndBl;
            this.thermsSavings2ndBl = therms_savings_2nd_bl;
            this.incrementalMeasureCost2ndBl = incrementalMeasureCost2ndBl;
            this.measureCombinationSize = measureCombinationSize;
            this.buildingVintage = buildingVintage;
            this.developerName = developerName;
        }
    }

    /**
     * Retrieve the custom metadata type records from Measure_Savings__mdt filtered by vintage year and climate zone.
     *
     * @param buildingVintages The set to filter by. It cannot be empty.
     * @param climateZones The set to filter by. It cannot be empty.
     * @param measuresCombinationSize The set to filter by. It cannot be empty.
     * @return A Map containing records from Measure_Savings__mdt wrapped by MeasureCodeWrapper.
     */
    public static Map<String, Map<Integer, Map<Integer, List<MeasureCodeWrapper>>>> getMeasureSavingsMetadata(
            Set<String> buildingVintages, Set<Integer> climateZones, Set<Integer> measuresCombinationSize) {
        Map<String, Map<Integer, Map<Integer, List<MeasureCodeWrapper>>>> measureSavingsMdtMap =
                new Map<String, Map<Integer, Map<Integer, List<MeasureCodeWrapper>>>>();

        // If one of the Sets is empty doesn't need to query for custom metadata records.
        if (!buildingVintages.isEmpty() && !climateZones.isEmpty() && !measuresCombinationSize.isEmpty()) {
            try {
                List<Measure_Savings__mdt> measureCombinationCodes = [
                    SELECT Label, Measure_Combination__c, kW_Savings__c, kWh_Savings__c, Therms_Savings__c,
                        Incremental_Measure_Cost__c, kW_Savings_2nd_BL__c, kWh_Savings_2nd_BL__c,
                        Therms_Savings_2nd_BL__c, Incremental_Measure_Cost_2nd_BL__c, Measure_Combination_Size__c,
                        Building_Vintage__c, Climate_Zone__c, developerName
                    FROM Measure_Savings__mdt
                    WHERE Building_Vintage__c IN :buildingVintages
                        AND Climate_Zone__c IN :climateZones
                        AND Measure_Combination_Size__c <= :measuresCombinationSize
                        AND Program_Type__c = :PROGRAM_TYPE_HU
                ];

                // Loop through the custom metadata type records to build a map with measure combination sorted as key
                // and the measure information into a wrapper class as value.
                for (Measure_Savings__mdt measureMdt: measureCombinationCodes) {
                    if (String.isNotBlank(measureMdt.Measure_Combination__c)) {
                        MeasureCodeWrapper mcw = new MeasureCodeWrapper(measureMdt.Label,
                                measureMdt.Measure_Combination__c, measureMdt.kW_Savings__c, measureMdt.kWh_Savings__c,
                                measureMdt.Therms_Savings__c, measureMdt.Incremental_Measure_Cost__c,
                                measureMdt.kW_Savings_2nd_BL__c, measureMdt.kWh_Savings_2nd_BL__c,
                                measureMdt.Therms_Savings_2nd_BL__c, measureMdt.Incremental_Measure_Cost_2nd_BL__c,
                                (Integer) measureMdt.Measure_Combination_Size__c, measureMdt.Building_Vintage__c,
                                (Integer) measureMdt.Climate_Zone__c, measureMdt.developerName);

                        if (!measureSavingsMdtMap.containsKey(mcw.buildingVintage)) {
                            measureSavingsMdtMap.put(mcw.buildingVintage,
                                    new Map<Integer, Map<Integer, List<MeasureCodeWrapper>>>());
                        }

                        if (!measureSavingsMdtMap.get(mcw.buildingVintage).containsKey(mcw.climateZone)) {
                            measureSavingsMdtMap.get(mcw.buildingVintage).put(mcw.climateZone,
                                    new Map<Integer, List<MeasureCodeWrapper>>());
                        }

                        if (!measureSavingsMdtMap.get(mcw.buildingVintage).get(mcw.climateZone)
                                .containsKey(mcw.measureCombinationSize)) {
                            measureSavingsMdtMap.get(mcw.buildingVintage).get(mcw.climateZone).put(
                                    mcw.measureCombinationSize, new List<MeasureCodeWrapper>());
                        }

                        measureSavingsMdtMap.get(mcw.buildingVintage).get(mcw.climateZone)
                                .get(mcw.measureCombinationSize).add(mcw);
                    }
                }
            } catch (QueryException e) {
                System.debug('###ApplicationUtils.getMeasuresCodeMedatadata():' + e.getStackTraceString());
            } catch (Exception e) {
                System.debug('###ApplicationUtils.getMeasuresCodeMedatadata():' + e.getStackTraceString());
            }
        }

        return measureSavingsMdtMap;
    }

    /**
     * Retrieve the custom metadata type records from Measure_Savings__mdt filtered by measure code and climate zone.
     *
     * @param climateZone get it from Site.
     * @param measureCodes set of selected measures from Portal.
     * @return Map containing savings data using the measure code as key.
     */
    public static Map<String, MeasureSavingsWrapper> getMeasureSavingsMetadata(Set<Integer> climateZones,
            Set<String> measureCodes) {
        Map<String, MeasureSavingsWrapper> measureSavingsMdtMap = new Map<String, MeasureSavingsWrapper>();

        // If one of the parameters are empty don't need to query for custom metadata records.
        if (!climateZones.isEmpty() && !measureCodes.isEmpty()) {
            try {
                List<Measure_Savings__mdt> measureSavings = [
                    SELECT DeveloperName, Climate_Zone__c, kW_Savings__c, kWh_Savings__c, Therms_Savings__c
                    FROM Measure_Savings__mdt
                    WHERE Label = :measureCodes
                        AND Climate_Zone__c IN :climateZones
                        AND Program_Type__c = :PROGRAM_TYPE_ACQC
                    ];

                // Loop through the custom metadata type records to build a map with measure code + climate zone as key
                // and the measure information into a wrapper class as value.
                for (Measure_Savings__mdt measureSaving : measureSavings) {
                    MeasureSavingsWrapper measureSavingWrapper = new MeasureSavingsWrapper(
                            Integer.valueOf(measureSaving.Climate_Zone__c), measureSaving.kW_Savings__c,
                            measureSaving.kWh_Savings__c, measureSaving.Therms_Savings__c);
                    measureSavingsMdtMap.put(measureSaving.DeveloperName, measureSavingWrapper);
                }
            } catch(QueryException e) {
                System.debug('###MeasureUtils.getMeasureSavingsMetadata():' + e.getStackTraceString());
            } catch(Exception e) {
                System.debug('###MeasureUtils.getMeasureSavingsMetadata():' + e.getStackTraceString());
            }
        }

        return measureSavingsMdtMap;
    }

    /**
     * Filter the measures whose Qualifying Measure Code are not null.
     *
     * @param The list of measures to check if they have a value for Qualifying Measure Code field.
     * @return A Map with the Qualifying Measure Code as key and the measure as value.
     */
    public static Map<String, Measure__c> getQualifyingMeasures(List<Measure__c> measures) {
        Map<String, Measure__c> qualifyingMeasures = new Map<String, Measure__c>();

        for (Measure__c measure : measures) {
            if (String.isNotBlank(measure.Qualifying_Measure_Code__c)) {
                qualifyingMeasures.put(measure.Qualifying_Measure_Code__c, measure);
            }
        }

        return qualifyingMeasures;
    }

    /**
     *  Sorts the measure code abbreviation list in ascending order.
     *
     * @param measures The list of measures to be sorted.
     * @return The string concatenated by comma.
     */
    public static String getMeasureAbbreviationSorted(List<Measure__c> measures) {
        List<String> appMeasuresAbbreviation = new List<String>();

        for (Measure__c measure : measures) {
            if (String.isNotBlank(measure.Measure_Code__c) && String.isNotBlank(measure.Measure_Code_Abbreviation__c)) {
                appMeasuresAbbreviation.add(measure.Measure_Code_Abbreviation__c);
            }
        }

        // Sort the measure abbreviation.
        appMeasuresAbbreviation.sort();

        return String.join(appMeasuresAbbreviation, ',');
    }

    /**
     * Construct a sorted measure combination representing all of the Application's measures.
     *
     * @param measures The list of measures to be sorted.
     * @return The string concatenated by comma.
     */
    public static String getMeasureCombinationSorted(List<Measure__c> measures) {
        List<String> appMeasuresCombination = new List<String>();

        for (Measure__c measure : measures) {
            appMeasuresCombination.add(measure.Measure_Code__c);
        }

        // Sort the measures code.
        appMeasuresCombination.sort();

        return String.join(appMeasuresCombination, ',');
    }

    /**
     * Sets Measure for Home Upgrade by using a related measureType custom metadata record.
     *
     * @param measure The measure to set
     * @param measureType The custom metadata type record associated with the measure
     */
    public static void setMeasure(Measure__c measure, Measure_Types__mdt measureType) {
        measure.RecordTypeId = HU_RECORD_TYPE;
        measure.Measure_Type_Name__c = measureType.DeveloperName;
        measure.Measure_Type__c = measureType.Measure_Type__c;
        measure.Name = getValidMeasureName(measureType.Measure_Description__c);
        measure.Measure_Description__c = measureType.Measure_Description__c;
        measure.Incentive__c = measureType.Incentive__c == null ? 0 : measureType.Incentive__c;
        measure.Measure_Code__c = measureType.Measure_Code__c;
        measure.Upgrade_Measure__c = measureType.Upgrade_Measure__c;
        measure.Measure_Code_Abbreviation__c = measureType.Measure_Code_Abbreviation__c;
        measure.Qualifying_Measure_Code__c = measureType.Qualifying_Measure_Code__c;
    }

    /**
     * Limits the measure name to a maximum of 80 characters.
     *
     * @param name The measure description.
     * @return A string with a maximum of 80 characters.
     */
    private static String getValidMeasureName(String name) {
        if (name.length() > 80) {
            // If the measure description is larger than 80 characters, discard the characters inside the parenthesis.
            name =  name.substringBefore('(').trim();

            if (name.length() > 80) {
                name = name.substring(0, 80);
            }
        }

        return name;
    }

    /**
     * Filter measures by checking if its measure code has changed.
     *
     * @param newMeasuresById Map of measures to be compared with its old version.
     * @param oldMeasuresById The old version of newMeasuresById.
     * @return Map of measures with its Id as key.
     */
    public static Map<Id, Measure__c> filterByMeasureCode(Map<Id, Measure__c> newMeasuresById,
            Map<Id, Measure__c> oldMeasuresById) {
        Map<Id, Measure__c> measuresById = new Map<Id, Measure__c>();

        for (Measure__c newMeasure : newMeasuresById.values()) {
            Measure__c oldMeasure = oldMeasuresById.get(newMeasure.Id);

            if (newMeasure.RecordTypeId == ACQC_RECORD_TYPE
                    && newMeasure.Measure_Code__c != oldMeasure.Measure_Code__c) {
                measuresById.put(newMeasure.Id, newMeasure);
            }
        }

        return measuresById;
    }

    /**
     * Filter measures by checking if their savings values have changed.
     *
     * @param newMeasuresById Map of measures to be compared with its old version.
     * @param oldMeasuresById The old version of newMeasuresById.
     * @return Map of measures with its Id as key.
     */
    public static Map<Id, Measure__c> filterBySavings(Map<Id, Measure__c> newMeasuresById,
            Map<Id, Measure__c> oldMeasuresById) {
        Map<Id, Measure__c> measuresById = new Map<Id, Measure__c>();

        for (Measure__c newMeasure : newMeasuresById.values()) {
            Measure__c oldMeasure = oldMeasuresById.get(newMeasure.Id);

            if (newMeasure.RecordTypeId == ACQC_RECORD_TYPE
                    && (newMeasure.kW_Savings__c != oldMeasure.kW_Savings__c
                    || newMeasure.kWh_Savings__c != oldMeasure.kWh_Savings__c
                    || newMeasure.Therms_Savings__c != oldMeasure.Therms_Savings__c)) {
                measuresById.put(newMeasure.Id, newMeasure);
            }
        }

        return measuresById;
    }

    /**
     * Filter measures by record type(s).
     *
     * @param measuresToProcess List of measures.
     * @param recordTypes Set of record type Ids.
     * @return List of measures.
     */
    public static List<Measure__c> filterByRecordType(List<Measure__c> measuresToProcess, Set<Id> recordTypes) {
        List<Measure__c> measures = new List<Measure__c>();

        for (Measure__c measure : measuresToProcess) {
            if (recordTypes.contains(measure.RecordTypeId)) {
                measures.add(measure);
            }
        }

        return measures;
    }

    /**
     * Sets measure savings.
     *
     * @param applicationsToProcess Map of applications with its Id as key.
     */
    public static void setSavingsWithApplications(Map<Id, Application__c> applicationsToProcess) {
        Set<Integer> climateZones = new Set<Integer>();
        Set<String> measureCodes = new Set<String>();
        List<Measure__c> measuresToMatch = new List<Measure__c>();
        List<Measure__c> measuresToProcess = new List<Measure__c>();
        Map<String, MeasureSavingsWrapper> measureSavingsMap;

        if (!applicationsToProcess.isEmpty()) {
            try {
                // Build measure code and climate zone sets to filter the custom metadata object.
                for (Measure__c measure : getMeasuresWithApplications(applicationsToProcess.keySet())) {
                    String measureCode = measure.Measure_Code__c;
                    // Get the application's climate zone if and the measure's measure code.
                    // Set the measure savings to null if any of them is null.
                    if (applicationsToProcess.get(measure.Application__c).Climate_Zone__c != null
                            && String.isNotBlank(measure.Measure_Code__c)) {
                        if (REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE.containsKey(measure.Measure_Code__c)) {
                            measureCode = REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE.get(measure.Measure_Code__c);
                        }
                        measureCodes.add(measureCode);
                        climateZones.add(Integer.valueOf(applicationsToProcess.get(measure.Application__c).Climate_Zone__c));
                        measuresToMatch.add(measure);
                    } else {
                        measure.kW_Savings__c = null;
                        measure.kWh_Savings__c = null;
                        measure.Therms_Savings__c = null;
                        measuresToProcess.add(measure);
                    }
                }

                measureSavingsMap = getMeasureSavingsMetadata(climateZones, measureCodes);

                for (Measure__c measure : measuresToMatch) {
                    String measureCode = REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE.containsKey(measure.Measure_Code__c)
                            ? REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE.get(measure.Measure_Code__c)
                            : measure.Measure_Code__c;
                    MeasureSavingsWrapper measureSavings = measureSavingsMap.get(measureCode + '_'
                            + (String.valueOf(applicationsToProcess.get(measure.Application__c).Climate_Zone__c)
                              .leftPad(2, '0')));
                    // Set measure savings.
                    if (measureSavings != null
                            && applicationsToProcess.get(measure.Application__c).Total_Unit_Capacity__c != null
                            && measureSavings.climateZone == applicationsToProcess.get(measure.Application__c).Climate_Zone__c) {
                        Decimal totalUnitCapacity = applicationsToProcess.get(measure.Application__c).Total_Unit_Capacity__c;
                        measure.kW_Savings__c = measureSavings.kwSavings * totalUnitCapacity;
                        measure.kWh_Savings__c = measureSavings.kwhSavings * totalUnitCapacity;
                        measure.Therms_Savings__c = measureSavings.thermsSavings * totalUnitCapacity;
                    } else {
                        measure.kW_Savings__c = null;
                        measure.kWh_Savings__c = null;
                        measure.Therms_Savings__c = null;
                    }
                    measuresToProcess.add(measure);
                }

                update measuresToProcess;
            } catch (Exception e) {
                System.debug('###MeasureUtils.setSavingsWithApplications(): Message: ' + e.getMessage());
                System.debug('###StackTrace: ' + e.getStackTraceString());
            }
        }
    }

    /**
     * Sets measure savings.
     *
     * @param measures List of measures.
     * @return Map of measures with its Id as key.
     */
    public static Map<Id, Measure__c> setSavingsWithMeasures(List<Measure__c> measures) {
        Set<Integer> climateZones = new Set<Integer>();
        Set<String> measureCodes = new Set<String>();
        List<Measure__c> measuresToMatch = new List<Measure__c>();
        Map<String, MeasureSavingsWrapper> measureSavingsMap;
        Map<Id, Measure__c> measuresById = new Map<Id, Measure__c>();
        Map<Id, Application__c> applicationsById;

        if (!measures.isEmpty()) {
            try {
                applicationsById = ApplicationUtils.getApplicationsWithMeasures(measures);
                // Build measure code and climate zone sets to filter the custom metadata object.
                for (Measure__c measure : measures) {
                    String measureCode = measure.Measure_Code__c;
                    Integer climateZone = applicationsById.get(measure.Application__c).Climate_Zone__c != null
                            ? Integer.valueOf(applicationsById.get(measure.Application__c).Climate_Zone__c)
                            : null;
                    // Get the application's climate zone if and the measure's measure code.
                    // Set the measure savings to null if any of them is null.
                    if (climateZone != null && String.isNotBlank(measure.Measure_Code__c)) {
                        if (REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE.containsKey(measure.Measure_Code__c)) {
                            measureCode = REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE.get(measure.Measure_Code__c);
                        }
                        measureCodes.add(measureCode);
                        climateZones.add(climateZone);
                        measuresToMatch.add(measure);
                    } else {
                        measure.kW_Savings__c = null;
                        measure.kWh_Savings__c = null;
                        measure.Therms_Savings__c = null;
                        measuresById.put(measure.Id, measure);
                    }
                }

                measureSavingsMap = getMeasureSavingsMetadata(climateZones, measureCodes);

                for (Measure__c measure : measuresToMatch) {
                    String measureCode = REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE.containsKey(measure.Measure_Code__c)
                            ? REBATE_MEASURE_CODE_TO_SAVINGS_MEASURE_CODE.get(measure.Measure_Code__c)
                            : measure.Measure_Code__c;
                    Integer climateZone = applicationsById.get(measure.Application__c).Climate_Zone__c != null
                            ? Integer.valueOf(applicationsById.get(measure.Application__c).Climate_Zone__c)
                            : null;
                    Decimal totalUnitCapacity =
                            applicationsById.get(measure.Application__c).Total_Unit_Capacity__c != null
                            ? applicationsById.get(measure.Application__c).Total_Unit_Capacity__c
                            : null;
                    MeasureSavingsWrapper measureSavings = measureSavingsMap.get(measureCode + '_'
                            + (String.valueOf(climateZone).leftPad(2, '0')));
                    // Set measure savings.
                    if (measureSavings != null && totalUnitCapacity != null
                            && measureSavings.climateZone == climateZone) {
                        measure.kW_Savings__c = measureSavings.kwSavings * totalUnitCapacity;
                        measure.kWh_Savings__c = measureSavings.kwhSavings * totalUnitCapacity;
                        measure.Therms_Savings__c = measureSavings.thermsSavings * totalUnitCapacity;
                    } else {
                        measure.kW_Savings__c = null;
                        measure.kWh_Savings__c = null;
                        measure.Therms_Savings__c = null;
                    }
                    measuresById.put(measure.Id, measure);
                }
            } catch (Exception e) {
                System.debug('###MeasureUtils.setSavingsWithMeasures(): Message: ' + e.getMessage());
                System.debug('###StackTrace: ' + e.getStackTraceString());
            }
        }

        return measuresById;
    }

    /**
     * Query ACQC measures.
     *
     * @param applicationIds Set of application Ids.
     * @return List of measures.
     */
    private static List<Measure__c> getMeasuresWithApplications(Set<Id> applicationIds) {
        List<Measure__c> measuresToProcess = new List<Measure__c>();

        try {
            measuresToProcess = [
                SELECT Measure_Code__c, kW_Savings__c, kWh_Savings__c, Therms_Savings__c, Application__r.Climate_Zone__c,
                    Application__r.Total_Unit_Capacity__c, Application__c
                FROM Measure__c
                WHERE RecordTypeId = :ACQC_RECORD_TYPE
                    AND Application__c IN :applicationIds
                ];
        } catch (Exception e) {
            System.debug('###MeasureUtils.getMeasuresWithApplications(): Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return measuresToProcess;
    }
}