/**
 * This class tests InboundEmailTaskHandler.cls.
 *
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2015-3
 */
@IsTest
private class TestInboundEmailTaskHandler {
    private static final String PGE_PORTAL_USER = 'PGE - EUC Portal User';
    private static final String LONG_STRING_BODY = 'Email body which exceeds the fifty characters long';
    private static Account account;
    private static Contact fromContact;
    private static Contact toContact;
    private static User toUser;
    private static Application__c application;
    private static Profile portalProfile;

    static {
        try {
            portalProfile = [SELECT Id, Name From Profile WHERE Name = :PGE_PORTAL_USER];
        } catch (QueryException e) {
            System.debug('TestInboundEmailTaskHandler - A query exception has occurred: ' + e.getMessage());
        }
    }

    private static void initData() {
        account = new Account(Name = 'test account');
        insert account;

        System.assertNotEquals(null, account.Id);

        fromContact = new Contact(LastName = 'from', Email = 'from@test.com', AccountId = account.Id);
        toContact = new Contact(LastName = 'to', Email = 'to@test.com', AccountId = account.Id);
        List<Contact> contacts = new List<Contact>{fromContact, toContact};
        insert contacts;

        for (Contact c : contacts) {
            System.assertNotEquals(null, c.Id);
        }

        toUser = BIGPortalTestUtils.createUser('toUser', portalProfile.Id, 'toUser');
        toUser.ContactId = toContact.Id;
        insert toUser;

        System.assertNotEquals(null, toUser.Id);

        application = new Application__c(Contractor__c = account.Id, OwnerId = toUser.Id);
        insert application;

        System.assert(application.Id != null);
    }

    /**
     * Test create tastk and attachment.
     *
     * @param fromAddress Address email comes from.
     * @param toAddresses Address email of recipient.
     * @param subject Theme of email.
     * @param plainTextBody Body of email as String.
     * @param htmlBody Body of email as html.
     * @return inboundEmail Email created based on received data.
     */
    private static Messaging.InboundEmail createEmail(String fromAddress, List<String> toAddresses, String subject,
            String plainTextBody, String htmlBody) {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = fromAddress;
        email.toAddresses = toAddresses;
        email.ccAddresses = toAddresses;
        email.plainTextBody = plainTextBody;
        email.htmlBody = htmlBody;
        email.subject = subject;

        return email;
    }

    /**
     * Test task not getting created if there's no id on the email body.
     */
    private static testMethod void testTaskNotCreatedWithoutIdOnEmailBody() {
        initData();

        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', 'plainText', 'htmlBody');
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailTaskHandler emailTaskHandler = new InboundEmailTaskHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = emailTaskHandler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(!result.Success);

        List<Task> tasks = [SELECT Subject, Description FROM Task WHERE WhoId = :toContact.Id];

        System.assertEquals(0, tasks.size());
    }

    /**
     * Test create task on Application and Contact by processing email plain text body.
     */
    private static testMethod void testAddTaskToContactAndApplicationFromPlainTextBody() {
        initData();

        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', application.Id, '');
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailTaskHandler emailTaskHandler = new InboundEmailTaskHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = emailTaskHandler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.Success);

        Map<Id, Task> tasks = new Map<Id, Task>([
            SELECT Id, Subject, Description
            FROM Task
            WHERE WhoId = :toContact.Id OR WhatId = :application.Id]);

        System.assertEquals(1, tasks.size());
    }

    /**
     * Test create task on Application and Contact by processing email htmlBody.
     */
    private static testMethod void testAddTaskToContactsAndApplicationFromHtmlBody() {
        initData();

        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', '', 'ref: ' + application.Id);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailTaskHandler emailTaskHandler = new InboundEmailTaskHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = emailTaskHandler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.Success);

        Map<Id, Task> tasks = new Map<Id, Task>([
            SELECT Id, Subject, Description
            FROM Task
            WHERE WhoId = :toContact.Id OR WhatId = :application.Id]);
        System.assertEquals(1, tasks.size());
    }

    /**
     * Test create task on Account and Contact.
     */
    private static testMethod void testAddTaskToContactAndAccountFromHtmlBody() {
        initData();

        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', '',
                '001111 ' + account.Id);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailTaskHandler emailTaskHandler = new InboundEmailTaskHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = emailTaskHandler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.Success);

        Map<Id, Task> tasks = new Map<Id, Task>([
            SELECT Id, Subject, Description
            FROM Task
            WHERE WhoId = :toContact.Id OR WhatId = :account.Id]);
        System.assertEquals(1, tasks.size());
    }

    /**
     * Test create task on Application and Contact's owner by processing email htmlBody.
     */
    private static testMethod void testAddTaskToOwnerAndApplicationFromHtmlBody() {
        initData();

        // Insert contact with duplicate email address.
        insert new Contact(LastName = 'Duplicate', Email = toContact.Email);

        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', '', application.Id);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailTaskHandler emailTaskHandler = new InboundEmailTaskHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = emailTaskHandler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.Success);

        Map<Id, Task> tasks = new Map<Id, Task>([
            SELECT Id, Subject, Description
            FROM Task
            WHERE WhoId = :toContact.Id OR WhatId = :application.Id]);
        System.assertEquals(1, tasks.size());
    }

    /**
     * Test create task on a sobject record detail with a master-detail relantionship and Contact's owner by processing
     * email htmlBody.
     */
    private static testMethod void testAddTaskToOwnerAndMasterDetailRelantionshipRecordFromHtmlBody() {
        initData();

        // Insert contact with duplicate email address.
        insert new Contact(LastName = 'Duplicate', Email = toContact.Email);

        // Insert SubApplication which has a master-detail relationship to Application.
        Sub_Application__c subApp =  new Sub_Application__c(Application__c = application.Id);
        insert subApp;

        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', '', subApp.Id);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailTaskHandler emailTaskHandler = new InboundEmailTaskHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = emailTaskHandler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.Success);

        Map<Id, Task> tasks = new Map<Id, Task>([
            SELECT Id, Subject, Description
            FROM Task
            WHERE WhoId = :toContact.Id OR WhatId = :subApp.Id]);
        System.assertEquals(1, tasks.size());
    }

    /**
     * Test creation of task on Application with the Contact as the owner, from an html body that exceeds 50 characters.
     */
    private static testMethod void testAddTaskToContactAndAccountFromLongHtmlBody() {
        initData();

        List<String> toAddresses = new List<String>{toContact.Email};
        // Create HTML body with more than 50 characters and that the record for email message is created with
        // all the correct data without any truncate or trimming of the HTML body data.
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', '',
                LONG_STRING_BODY + ' ref' + application.Id);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        InboundEmailTaskHandler emailTaskHandler = new InboundEmailTaskHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = emailTaskHandler.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.Success);

        Map<Id, Task> tasks = new Map<Id, Task>([
            SELECT Id, Subject, Description
            FROM Task
            WHERE WhoId = :toContact.Id OR WhatId = :application.Id]);
        System.assertEquals(1, tasks.size());
    }
}