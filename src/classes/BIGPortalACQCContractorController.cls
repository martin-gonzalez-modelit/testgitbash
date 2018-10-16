/**
 * This controller handles BIGACQCContractorServiceTerritory page.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @since 2014-2
 */
public with sharing class BIGPortalACQCContractorController {

    // Private Properties
    private BIGPortalUser userUtility;

    public BIGPortalACQCContractorController() {
        userUtility = new BIGPortalUser();
    }

    /**
     * Checks if the user has access to the ACQC program and if it's not the case, it redirects to exception page.
     *
     * @return The current page if the user has access to the ACQC program, or a redirect to the Access Denied page.
     */
    public PageReference checkUserAccess() {
        return BIGUtility.checkACQCContactAccess(userUtility);
    }

    public Boolean getHasError() {
        return ApexPages.hasMessages(ApexPages.Severity.ERROR);
    }

    public Map<String, List<String>> getCounties() {
        Map<String, List<String>> result = new Map<String, List<String>>();

        for (String region:getRegions()) {
            result.put(region, new List<String>());
        }

        for (Service_Territory__c county : [
                SELECT County__c, Region__c
                FROM Service_Territory__c
                ORDER BY Region__c, Name]) {
            List<String> l = result.get(county.Region__c);
            Set<String> s = new Set<String>();

            if (l != null) {
                s.addAll(l);
            }

            s.add(county.County__c);
            l = new List<String>(s);
            l.sort();
            result.put(county.Region__c, l);
        }

        return result;
    }

    public Map<String, List<Service_Territory__c>> getZipCodes() {
        Map<String, List<Service_Territory__c>> result = new Map<String, List<Service_Territory__c>>();

        for (Service_Territory__c zipCode : [
                SELECT Id, Name, County__c, Region__c, City__c
                FROM Service_Territory__c
                ORDER BY City__c, Name]) {
            List<Service_Territory__c> l = new List<Service_Territory__c>();
            String key = zipCode.Region__c + '::' + zipCode.County__c;
            if (result.containsKey(key)) {
                l = result.get(key);
            }
            l.add(zipCode);
            result.put(key, l);
        }

        return result;
    }

    public PageReference saveServiceTerritories() {
        String contractorId = userUtility.getAccount().Id;
        delete [SELECT Id FROM Contractor_Service_Territory__c WHERE Contractor__c = :contractorId];
        List<Contractor_Service_Territory__c> csts = new List<Contractor_Service_Territory__c>();
        String zipCodes = ApexPages.currentPage().getParameters().get('zipCodes');
        if (String.isNotBlank(zipCodes)) {
            for (String zipCode : zipCodes.split(',')){
                csts.add(new Contractor_Service_Territory__c(Contractor__c = contractorId, Zip_Code__c = zipCode));
            }
        }
        insert csts;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Your Service Territories have been saved.'));
        return Page.BIGACQCContractorServiceTerritory;
    }

    public List<Contractor_Service_Territory__c> getServiceTerritories() {
        return [
            SELECT Id, Zip_Code__c, Zip_Code__r.County__c, Zip_Code__r.Region__c
            FROM Contractor_Service_Territory__c
            WHERE Contractor__c = :userUtility.getAccount().Id
            ];
    }

    public List<String> getRegions() {
        Set<String> result = new Set<String>();

        for (Service_Territory__c st : [SELECT Region__c FROM Service_Territory__c]) {
            result.add(st.Region__c);
        }

        return new List<String>(result);
    }
}