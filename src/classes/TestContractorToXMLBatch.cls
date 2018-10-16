/**
 * This class contains unit tests for the ContractorToXMLBatch class.
 *
 * @author Pablo Vigil <pvigil@builditgreen.org>
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2014-04
 */
@isTest
private class TestContractorToXMLBatch {

    static testMethod void testFailBatch() {
        // Setup data. Missing custom setting information.
        createCustomSetting(null);
        Id contractorAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Contractor').getRecordTypeId();
        Id raterAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rater').getRecordTypeId();
        List<Account> accs = new List<Account>();

        for (Integer i = 0; i < 20; i++) {
            Id accRTId = Math.mod(i,2) == 0 ? contractorAccRTId : raterAccRTId;
            Account acc = createAccount('Doe Test' + i, accRTId);
            accs.add(acc);
        }
        insert accs;

        // Check if accounts were inserted.
        System.assertEquals(20, [Select count() from Account where Name Like 'Doe Test%']);
        Test.startTest();
            Id batchprocessid = Database.executeBatch(new ContractorToXMLBatch());
        Test.stopTest();
    }

    static testMethod void testContract() {
        // Setup data.
        createCustomSetting('johndoe.test@acmeinc.com');
        Id contractorAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Contractor').getRecordTypeId();
        Id raterAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rater').getRecordTypeId();
        List<Account> accs = new List<Account>();
        List<Contact> cts = new List<Contact>();

        for (Integer i = 0; i < 20; i++) {
            Id accRTId = Math.mod(i,2) == 0 ? contractorAccRTId : raterAccRTId;
            Account acc = createAccount('Doe Test' + i, accRTId);
            accs.add(acc);
        }
        insert accs;

        for (Account acc : accs) {
            Contact ct = createContact('Jhon', 'DoeXML', acc.Id);
            cts.add(ct);
        }
        insert cts;

        // Check if accounts were inserted.
        System.assertEquals(20, [Select count() from Account where Name Like 'Doe Test%']);
        // Check if contacts were inserted.
        System.assertEquals(20, [Select count() from Contact where LastName Like 'DoeXML%']);
        Test.startTest();
            Id batchprocessid = Database.executeBatch(new ContractorToXMLBatch());
        Test.stopTest();
    }

    static testMethod void testContractorContract() {
        // Setup data.
        createCustomSetting('johndoe.test@acmeinc.com');
        Id contractorAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Contractor').getRecordTypeId();
        List<Account> accs = new List<Account>();
        List<Contact> cts = new List<Contact>();

        for (Integer i = 0; i < 20; i++) {
            Account acc = createAccount('Doe Test' + i, contractorAccRTId);
            accs.add(acc);
        }
        insert accs;

        for (Account acc : accs) {
            Contact ct = createContact('Jhon', 'DoeXML', acc.Id);
            cts.add(ct);
        }
        insert cts;

        // Check if accounts were inserted.
        System.assertEquals(20, [Select count() from Account where Name Like 'Doe Test%']);
        // Check if contacts were inserted.
        System.assertEquals(20, [Select count() from Contact where LastName Like 'DoeXML%']);
        Test.startTest();
            Id batchprocessid = Database.executeBatch(new ContractorToXMLBatch());
        Test.stopTest();
    }

    static testMethod void testRaterContract() {
        // Setup data.
        createCustomSetting('johndoe.test@acmeinc.com');
        Id raterAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rater').getRecordTypeId();
        List<Account> accs = new List<Account>();
        List<Contact> cts = new List<Contact>();

        for (Integer i = 0; i < 20; i++) {
            Account acc = createAccount('Doe Test' + i, raterAccRTId);
            accs.add(acc);
        }
        insert accs;

        for (Account acc : accs) {
            Contact ct = createContact('Jhon', 'DoeXML', acc.Id);
            cts.add(ct);
        }
        insert cts;

        // Check if accounts were inserted.
        System.assertEquals(20, [Select count() from Account where Name Like 'Doe Test%']);
        // Check if contacts were inserted.
        System.assertEquals(20, [Select count() from Contact where LastName Like 'DoeXML%']);
        Test.startTest();
            Id batchprocessid = Database.executeBatch(new ContractorToXMLBatch());
        Test.stopTest();
    }

    static testMethod void testScheduledContractorToXMLBatch() {
        createCustomSetting('johndoe.test@acmeinc.com');
        Test.startTest();
            // Schedule the test job.
            String jobId = System.schedule('Contractor XML Batch',
            ScheduledContractorToXMLBatch.CRON_EXP, 
                new ScheduledContractorToXMLBatch());

            // Get the information from the CronTrigger API object.
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                              FROM CronTrigger WHERE id = :jobId];

            // Verify the expressions are the same.
            System.assertEquals(ScheduledContractorToXMLBatch.CRON_EXP, 
                                ct.CronExpression);

            // Verify the job has not run.
            System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    }

    /**
     * This method creates an account object.
     * @param name The account name.
     * @param accRTId The record type id for the account.
     * @return The account object.
     */
    private static Account createAccount(String name, Id accRTId) {
        Account acc = new Account(Name = name, RecordTypeId = accRTId);
        acc.Application_Status__c = 'Approved';
        acc.EGIA_Contractor_ID__c = name;
        acc.EGIA_Rater_ID__c = name;
        return acc;
    }

    /**
     * This method creates a contact object.
     * @param firstName The contact first name.
     * @param lastName The contact last name.
     * @param accId The account's id related to contact.
     * @return The contact object.
     */
    private static Contact createContact(String firstName, String lastName, Id accId) {
        Contact ct = new Contact(FirstName = firstName, LastName = lastName);
        ct.AccountId = accId;
        ct.Primary_Contact__c = true;
        return ct;
    }

    /**
     * This method creates a custom setting to set email information.
     * @param emailTo The receiver email address.
     */
    private static void createCustomSetting(String emailTo) {
        PGE_Contractor_Rater_Email__c settings = PGE_Contractor_Rater_Email__c.getInstance(ContractorToXMLBatch.PGE_SETTING_DATA_SET);

        if (settings != null) {
            delete [select Id from PGE_Contractor_Rater_Email__c where Name =: ContractorToXMLBatch.PGE_SETTING_DATA_SET];
        }

        OrgWideEmailAddress orgWideEmail = [Select id, Address, DisplayName from OrgWideEmailAddress].get(0);

        settings = new PGE_Contractor_Rater_Email__c();
        settings.Name = ContractorToXMLBatch.PGE_SETTING_DATA_SET;
        settings.Email_Attachment_Name__c = 'Contract.xml';
        settings.Email_Subject__c = 'Contractor resources processing finished';
        settings.Email_To__c = emailTo;
        settings.Email_Content__c = '';
        settings.OrgWideEmailAddressId__c = orgWideEmail.Id;
        settings.Enrollment_Grace_Period__c = 185;
        insert settings;
    }
}