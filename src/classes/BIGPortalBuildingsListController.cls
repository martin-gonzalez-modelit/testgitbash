public with sharing class BIGPortalBuildingsListController extends BIGPortalPaginationUtils {

    public String accountId;
    private BIGPortalUser userUtility;

    public BIGPortalBuildingsListController() {}

    public String getAccountId() {
        return accountId;
    }

    public List<Building__c> getBuildings() {
        return (List<Building__c>)stdController.getRecords();
    }

    public String getJSONBuildings() {
        if (stdController != null) {
            // Raise the limit to return all the records.
            stdController.setPageSize(NUMBER_OF_RECORDS_JSON);
            List<Building__c> buildings = stdController.getRecords();

            // Map with the BuildingId and ContactId
            Map<Id, Id> mapIds = new Map<Id, Id>();
            Map<Id, Contact> mapContacts;
            List<BuildingListWrapper> buildingWrappers = new List<BuildingListWrapper>();

            if (buildings.size() > 0) {
                for (Building__c building : buildings) {
                    if (building.Dwelling_Units__r.size() > 0) {
                        Id contactId = building.Dwelling_Units__r.get(0).Property_Owner__c;
                        mapIds.put(building.Id, contactId);
                    }
                }

                try {
                    mapContacts = new Map<Id, Contact>([SELECT Id, Name, FirstName, LastName FROM Contact WHERE Id = :mapIds.values()]);
                } catch (DMLException e) {
                    System.debug('An Exception has occurred while trying to get contacts: ' + e.getMessage());
                }

                for (Building__c building: buildings) {
                    if (mapIds.containsKey(building.Id)) {
                        Contact contact = mapContacts.get(mapIds.get(building.Id));
                        BuildingListWrapper wrapper = new BuildingListWrapper();
                        wrapper.setFields(building, contact);
                        buildingWrappers.add(wrapper);
                    }
                }
            }
            return JSON.Serialize(buildingWrappers);
        }
        return null;
    }

    public void setAccountId(String pAccId) {
        accountId = pAccId;
        if (this.query == null) {
            // Set query to get the list
            this.query = ''
                    + 'SELECT Id, Building_Name__c, Building_Type__c, City__c, State__c, Street_Address__c, ZIP_Code__c, '
                        + '(SELECT Id, Property_Owner__c FROM Dwelling_Units__r) '
                    + 'FROM Building__c '
                    + 'WHERE Account_del__c = \'' + accountId + '\'';
            this.orderBy = 'Street_Address__c,City__c,ZIP_Code__c';
            // Set query to pagination controller
            this.setQueryToController();
        }
    }

    public class BuildingListWrapper {
        public String buildingName;
        public String buildingType;
        public String buildingAddress;
        public String buildingCity;
        public String buildingZipCode;
        public String propertyOwnerFirstName;
        public String propertyOnwerLastName;
        public Id buildingId;
        private Id contactId;

        public void setFields(Building__c building, Contact contact) {
            this.buildingId = building.Id;
            this.buildingName = building.Building_Name__c;
            this.buildingType = building.Building_Type__c;
            this.buildingAddress = building.Street_Address__c;
            this.buildingCity = building.City__c;
            this.buildingZipCode = building.ZIP_Code__c;
            if (contact != null) {
                this.propertyOwnerFirstName = contact.FirstName;
                this.propertyOnwerLastName = contact.LastName;
            }
        }
    }
}