/**
 * This controller handles ACQC SA Mobile search page.
 *
 * @author Pablo Vigil <pablo.vigil@modelit.xyz>
 * @since 2013-6
 */
public with sharing class BIGPortalHVACSearchCustController extends BIGPortalPaginationUtils {

    // Private Properties
    private BIGPortalUser userUtility;

    public BIGPortalHVACSearchCustController() {
        userUtility = new BIGPortalUser();
    }

    /**
     * Gets the units related to sites within the zipcode we pass as a parameter. If there's no sites with the zipcode
     * nor a valid zipcode value is passed as parameter returns an empty JSON object as string.
     *
     * @return The list of units as JSON string. If no records were found then return an empty JSON object as string.
     */
    public String getJSONUnits() {
        String zipcode = System.currentPageReference().getParameters().get('zipcode');

        if (String.isNotBlank(zipCode)) {
            if (this.query == null) {
                // Fetch all units filtered by the zipcode and the portal's user account.
                this.query = ''
                        + 'SELECT Id, Name, CreatedDate, Site__r.Name, Site__r.Address_1__c, Site__r.Address_2__c, '
                            + 'Site__r.City__c, Site__r.State__c, Site__r.Zip__c, Site__r.Phone__c, FDSI_ID__c, '
                            + 'Site__r.Technician__c, Complete_Name__c, Make__c, Model__c, Sticker_Number__c '
                        + 'FROM Unit__c '
                        + 'WHERE Site__r.Contractor__c=\'' + userUtility.getAccount().Id + '\' '
                            + 'AND Site__r.Zip__c =\'' + String.escapeSingleQuotes(zipcode) + '\'';
                this.limitQuery = NUMBER_OF_RECORDS_JSON;
                this.orderBy = 'CreatedDate';
                // List the most recent units created first in the table.
                this.direction = 'DESC';
                // Set query to pagination controller
                this.setQueryToController();
            }
            if (stdController != null) {
                // Raise the limit to return all the records.
                stdController.setPageSize(NUMBER_OF_RECORDS_JSON);
                return JSON.Serialize(stdController.getRecords());
            }
        }

        return JSON.Serialize(new List<Unit__c>());
    }

}