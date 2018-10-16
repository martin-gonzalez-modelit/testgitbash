/**
 * This class handles the Measure Types.
 *
 * @author Matias Medina <matias.medina@modelit.xyz>
 * @since 2016-6
 */
public with sharing class MeasureTypeUtils {

    private static List<Measure_Types__mdt> measureTypes;

    static {
        measureTypes = getAllMeasureTypes();
    }
    
    /**
     * Get all measure Types
     *
     * @return the list with all measure types
     */
    private static List<Measure_Types__mdt> getAllMeasureTypes() {
        List<Measure_Types__mdt> allMeasureTypes = new List<Measure_Types__mdt>();
        
        try {
            allMeasureTypes = [
                SELECT Id, Measure_Type__c, Measure_Description__c, Upgrade_Measure__c, Incentive__c, Display_Sequence__c,
                    Retirement_Date__c, Measure_Code__c, DeveloperName, Measure_Code_Abbreviation__c, Qualifying_Measure_Code__c
                FROM Measure_Types__mdt 
                WHERE Program_Type__c =: BIGPortalManageApplicationUtils.HUP order BY Display_Sequence__c asc
                ];
        } catch (Exception e) {
            System.debug('######MeasureTypeMdtUtils.getMeasureTypes():' + e.getStackTraceString());
        }
        
        return allMeasureTypes;
    }
    
    /**
     * Get all measure Types
     *
     * @return the list with all measure types
     */
    public static List<Measure_Types__mdt> getMeasureTypes() {
        return measureTypes;
    }
    
    /**
     * Retrieve non retired measures types
     *
     * @return list of Measure_Types__mdt filtered by Retirement_Date__c
     */
    public static List<Measure_Types__mdt> getNonRetiredMeasureTypes() {
        List<Measure_Types__mdt> nonRetiredMeasureTypes = new List<Measure_Types__mdt>();
        Datetime currentDate = Datetime.now();
        try {
            for (Measure_Types__mdt measureType : measureTypes) {
                if (measureType.Retirement_Date__c == null || currentDate < measureType.Retirement_Date__c) {
                    nonRetiredMeasureTypes.add(measureType);
                }
            }
        } catch (Exception e) {
            System.debug('###MeasureTypeMdtUtils.getNonRetiredMeasureTypes():'+ e.getStackTraceString());
        }
        
        return nonRetiredMeasureTypes;
    }

}