/**
 * This class handles the Public Note creation for AHU for "CIP Correction is created" Process Builder.
 *
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @since 2017-09
 */
public class CreatePublicNoteOnSubApplication {

    @InvocableMethod(label='Create a Public Note on SubApplication'
            description='Create a Public Note on SubApplication')
    public static void createPublicNote(List<Correction__c> corrections) {
        List<Application_Note__c> applicationNotes = new List<Application_Note__c>();
        Set<Id> applicationIds = new Set<Id>();

        for (Correction__c co : corrections) {
            applicationIds.add(co.Application__c);
        }

        Map<Id, Application__c> applications = new Map<Id, Application__c>([
            SELECT Id, (SELECT Id FROM Sub_Applications__r ORDER BY CreatedDate DESC)
            FROM Application__c
            WHERE Id = :applicationIds]);

        // Create a Public Note for each Correction.
        for (Correction__c correction : corrections) {
            applicationNotes.add(new Application_Note__c(
                    Application__c = correction.Application__c,
                    Public__c = true,
                    Note__c = correction.Reason_Required__c,
                    Sub_Application__c = applications.get(correction.Application__c).Sub_Applications__r.get(0).Id));
        }

        upsert applicationNotes;
    }

}