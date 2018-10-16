public with sharing class ApplicationOverride {

    public Application__c app {get; private set;}
    public Sub_Application__c preApp {get; private set;}
    public Sub_Application__c postApp {get; private set;}
    public String tabFocus {get; private set;}

    //-- Constructor
    public ApplicationOverride(ApexPages.StandardController controller) {
        app = (Application__c)controller.getRecord();

        app = [
            SELECT Id, RecordType.Name,
                (SELECT Id, CreatedDate, CreatedBy.Name, Field, OldValue, NewValue
                 FROM Histories
                 ORDER BY CreatedDate DESC),
                (SELECT Id, RecordType.DeveloperName FROM Sub_Applications__r)
            FROM Application__c
            WHERE Id = :app.Id
        ];

        //get sub-applications
        for (Sub_Application__c sa : app.Sub_Applications__r) {
            if (sa.RecordType.DeveloperName == 'EnergyPro_Pre_Installation'
                    || sa.RecordType.DeveloperName == 'PRE_APP'){
                preApp = sa;
            } else if (sa.RecordType.DeveloperName == 'EnergyPro_Post_Installation'
                    || sa.RecordType.DeveloperName == 'POST_APP') {
                postApp = sa;
            }
        }
        tabFocus = (postApp == null ? 'preApp' : 'postApp');
    }

    //-- get the RecordType to determine the application layout
    public PageReference getRecordType() {
        //redirect to standard page if not AHU RecordType
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;

        if (app.RecordType.Name != 'AHU' || ProfileName == 'SoCalGas' || ProfileName == 'External Field Verifier') {
            PageReference appPage = new PageReference('/' + app.Id + '?nooverride=1');
            return appPage;
        } else {
            return null;
        }
    }
}