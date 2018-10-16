/**
 * Triggers for Application records
 *
 * @author Camilo Herbert   camilo.herbert@modelitsoftware.com
 * @since 2013-12
 *
 * @author Jordan Dunn (jdunn@builditgreen.org)
 * @since 2014-12
 */
trigger ApplicationTrigger on Application__c (before insert, after insert, before update, after update) {
    Map<String, Schema.RecordTypeInfo> recordTypeNameToId = Schema.SObjectType.Application__c
            .getRecordTypeInfosByName();

    ApplicationUtils.isTriggerExecuting = true;

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            if (recordTypeNameToId.keySet().containsAll(new List<String>{'ACQC', 'HUP', 'AHU', 'AHUP'})) {

                // Applications to process Zip
                List<Application__c> applicationsToProcessZipCode = new List<Application__c>();
                // Applications to set HC Type
                List<Application__c> applicationsToSetHCType = new List<Application__c>();
                // Applications to set Building Vintage
                List<Application__c> applicationsToSetBuildingVintage = new List<Application__c>();
                // Applications (mapped by Contractor Id) to capture Submissions and Approvals
                Map<Id, List<Application__c>> accIdToApps = new Map<Id, List<Application__c>>();

                if (Trigger.isInsert) {
                    applicationsToProcessZipCode = Trigger.new;
                    applicationsToSetBuildingVintage = Trigger.new;
                    applicationsToSetHCType = Trigger.new;
                    ApplicationUtils.updateFundingSourceOnApplications(Trigger.new);
                } else {
                    for (Application__c newApp : Trigger.new) {
                        Application__c oldApp = Trigger.oldMap.get(newApp.Id); // applications before update

                        /* determine which utility class methods to call for each application */
                        // zip codes, climate zone
                        if ((newApp.RecordTypeId == ApplicationUtils.ACQC_RECORD_TYPE
                                && newApp.Building_Zip_Code__c != oldApp.Building_Zip_Code__c)
                                || ((newApp.RecordTypeId == ApplicationUtils.HUP_RECORD_TYPE
                                || newApp.RecordTypeId == ApplicationUtils.AHU_RECORD_TYPE
                                || newApp.RecordTypeId == ApplicationUtils.AHUP_RECORD_TYPE)
                                && (newApp.Building_Zip_Code__c != oldApp.Building_Zip_Code__c
                                || newApp.Customer_Zip_Code__c != oldApp.Customer_Zip_Code__c))) {
                            applicationsToProcessZipCode.add(newApp);
                        }

                        // building vintage, hc type
                        if (newApp.RecordTypeId == ApplicationUtils.HUP_RECORD_TYPE
                                || newApp.RecordTypeId == ApplicationUtils.AHU_RECORD_TYPE) {
                            if (newApp.Year_Built__c != oldApp.Year_Built__c) {
                                applicationsToSetBuildingVintage.add(newApp);
                            }
                            if (newApp.Air_Conditioning__c != oldApp.Air_Conditioning__c) {
                                applicationsToSetHCType.add(newApp);
                            }
                        }
                    }

                    ApplicationUtils.processGasElectricJunctions
                            (ApplicationUtils.filterAppsToMakeGasElectricJunctions(Trigger.new, Trigger.old));

                    if (!MeasureUtils.isTriggerExecuting) {
                        // Set measure savings for ACQC applications.
                        Map<Id, Application__c> applicationsToSetSavings =
                                ApplicationUtils.filterByClimateZoneAndCapacity(Trigger.newMap, Trigger.oldMap);
                        MeasureUtils.setSavingsWithApplications(applicationsToSetSavings);
                        // Get ACQC applications where its savings have changed.
                        Map<Id, Application__c> applicationsFilteredBySavings =
                                ApplicationUtils.filterBySavings(Trigger.newMap, Trigger.oldMap);
                        // Add applications filtered by savings in order to be processed.
                        for (Application__c application : applicationsFilteredBySavings.values()) {
                            if (!applicationsToSetSavings.containsKey(application.Id)) {
                                applicationsToSetSavings.put(application.Id, application);
                            }
                        }
                        // Set application savings for ACQC applications.
                        ApplicationUtils.setSavings(applicationsToSetSavings.values());
                    }
                }

                // contractor accounts
                for (Application__c app : Trigger.new) {
                    if (app.RecordTypeId == ApplicationUtils.ACQC_RECORD_TYPE
                            || app.RecordTypeId == ApplicationUtils.HUP_RECORD_TYPE
                            || app.RecordTypeId == ApplicationUtils.AHUP_RECORD_TYPE
                            || app.RecordTypeId == ApplicationUtils.AHU_RECORD_TYPE) {
                        if (!accIdToApps.containsKey(app.Contractor__c)) {
                            accIdToApps.put(app.Contractor__c, new List<Application__c>{app});
                        } else {
                            accIdToApps.get(app.Contractor__c).add(app);
                        }
                    }
                }

                // call utility class methods
                if (!applicationsToProcessZipCode.isEmpty()) {
                    ApplicationUtils.processZipCode(applicationsToProcessZipCode);
                }
                if (!applicationsToSetHCType.isEmpty()) {
                    ApplicationUtils.setHCType(applicationsToSetHCType);
                }
                if (!applicationsToSetBuildingVintage.isEmpty()) {
                    ApplicationUtils.setBuildingVintage(applicationsToSetBuildingVintage);
                }
                if (!accIdToApps.isEmpty()) {
                    ApplicationUtils.captureSubmissionsAndApprovals(accIdToApps);
                }
            }
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ApplicationUtils.processGasElectricJunctions(Trigger.new);
        }
        if (Trigger.isUpdate) {
            // Set measure combination code for HU applications.
            Map<Id, Boolean> appsToSetMeasureCode =
                    ApplicationUtils.filterAppsToMatchMeasureCombination(Trigger.new, Trigger.old);
            if (!appsToSetMeasureCode.isEmpty()) {
                ApplicationUtils.setMeasureCode(appsToSetMeasureCode);
            }

            ApplicationUtils.updateTechnicianLastSubmissionDate(
                    ApplicationUtils.filterByTechnician(Trigger.newMap, Trigger.oldMap));
        }
    }

    ApplicationUtils.isTriggerExecuting = false;
}