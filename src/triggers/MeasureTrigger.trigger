/**
 * Triggers for Measure records
 *
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2014-5
 *
 * Last Update: 4/8/2014
 * Matias Medina <matias.medina@modelitsoftware.com>
 */
trigger MeasureTrigger on Measure__c (after insert, after update, after delete, before insert, before update,
        before delete) {

    MeasureUtils.isTriggerExecuting = true;

    if (Trigger.isBefore) {

        if (Trigger.isDelete) {
            Map<Id, Boolean> appsToSetMeasureCode = MeasureUtils.filterMeasuresToMatchMeasureCombination(Trigger.old);
            // Set measure code for HU applications.
            if (!appsToSetMeasureCode.isEmpty()) {
                ApplicationUtils.setMeasureCode(appsToSetMeasureCode);
            }
            // Set savings and measure combination for ACQC applications.
            ApplicationUtils.setSavingsAndMeasureCombination(
                    ApplicationUtils.filterApplicationsToSetSavings(Trigger.old), true);
        }

        if (Trigger.isUpdate) {
            // Get ACQC measures where its measure code has changed, and set its savings.
            Map<Id, Measure__c> measuresToSetSavings = MeasureUtils.filterByMeasureCode(Trigger.newMap, Trigger.oldMap);
            measuresToSetSavings = MeasureUtils.setSavingsWithMeasures(measuresToSetSavings.values());

            if (!ApplicationUtils.isTriggerExecuting) {
                // Get ACQC measures where its savings have changed.
                Map<Id, Measure__c> measuresFilteredBySavings =
                        MeasureUtils.filterBySavings(Trigger.newMap, Trigger.oldMap);
                // Add measures filtered by savings in order to be processed.
                for (Measure__c measure : measuresFilteredBySavings.values()) {
                    if (!measuresToSetSavings.containsKey(measure.Id)) {
                        measuresToSetSavings.put(measure.Id, measure);
                    }
                }
                // Set savings for ACQC applications.
                Map<Id, List<Measure__c>> measuresByAppId =
                        ApplicationUtils.filterApplicationsToSetSavings(measuresToSetSavings.values());
                ApplicationUtils.setSavingsOnMeasureUpdate(measuresByAppId);
            }
        }

        if (Trigger.isInsert) {
            // Set savings for ACQC measures.
            Map<Id, Measure__c> measuresToSetSavings = MeasureUtils.setSavingsWithMeasures(
                        MeasureUtils.filterByRecordType(Trigger.new, new Set<Id>{MeasureUtils.ACQC_RECORD_TYPE}));
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
            // Set measure combination code for HU applications.
            List<Measure__c> measures = Trigger.isDelete ? Trigger.old : Trigger.new;
            Map<Id, Boolean> appsToSetMeasureCode = MeasureUtils.filterMeasuresToMatchMeasureCombination(measures);
            if (!appsToSetMeasureCode.isEmpty()) {
                ApplicationUtils.setMeasureCode(appsToSetMeasureCode);
            }

            // Populate incentive total for ACQC applications.
            Map<Id, Measure__c> measuresMap = Trigger.isDelete ? Trigger.oldMap : Trigger.newMap;
            if (!ApplicationUtils.isTriggerExecuting) {
                ApplicationUtils.populateIncentiveTotal(measuresMap);
            }

            if (Trigger.isUpdate && !ApplicationUtils.isTriggerExecuting) {
                // Set measure combination for ACQC applications.
                ApplicationUtils.setMeasureCombination(MeasureUtils.filterByMeasureCode(Trigger.newMap, Trigger.oldMap));
            }

            if (Trigger.isInsert) {
                // Set savings and measure combination for ACQC applications.
                ApplicationUtils.setSavingsAndMeasureCombination(
                        ApplicationUtils.filterApplicationsToSetSavings(Trigger.new), false);
            }
        }
    }

    MeasureUtils.isTriggerExecuting = false;
}