/**
 * This class tests EmailReceiveApplicationNotification.cls.
 *
 * @author Jordan Dunn (jdunn@builditgreen.org)
 * @since 2015-3
 */
@IsTest
private class TestEmailReceiveApplicationNotification {

    private static Account account;
    private static Contact fromContact;
    private static Contact toContact;
    private static User toUser;
    private static Application__c application;
    
    private static Profile portalProfile;
    
    static {
        try {
            portalProfile = [SELECT Id, Name From Profile WHERE Name = 'PGE - EUC Portal User'];
        } catch (QueryException e) {
            System.debug('TestEmailReceiveApplicationNotification - A query exception has occurred: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('TestEmailReceiveApplicationNotification - An exception has occurred: ' + e.getMessage());
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
    
    private static testMethod void testAddTaskToContactFromEmailAddresses() {
        initData();
        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', 'plainTextBody',
               'htmlBody');
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        EmailReceiveApplicationNotification eran = new EmailReceiveApplicationNotification();
        
        Test.startTest();
        Messaging.InboundEmailResult result = eran.handleInboundEmail(email, env);
        Test.stopTest();
        
        System.assert(!result.Success);
        List<Id> whoIds = new List<Id>{fromContact.Id, toContact.Id};
        List<Task> tasks = [SELECT Subject, Description FROM Task WHERE WhoId IN :whoIds];
        System.assert(tasks.size() == 0, tasks.size());
    }
    
    private static testMethod void testAddTaskToContactAndApplicationFromPlainTextBody() {
        initData();
        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', application.Id, '');
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        EmailReceiveApplicationNotification eran = new EmailReceiveApplicationNotification();
        
        Test.startTest();
        Messaging.InboundEmailResult result = eran.handleInboundEmail(email, env);
        Test.stopTest();
        
        System.assert(result.Success);
        
        List<Id> whoIds = new List<Id>{toContact.Id};
        Map<Id, Task> tasks = new Map<Id, Task>([
                SELECT Id, Subject, Description
                FROM Task
                WHERE WhoId IN :whoIds OR WhatId = :application.Id]);
        System.assert(tasks.size() == 1, tasks.size());
    }
    
    private static testMethod void testAddTaskToContactsAndApplicationFromHtmlBody() {
        initData();
        List<String> toAddresses = new List<String>{toContact.Email};
        Messaging.InboundEmail email = createEmail(fromContact.Email, toAddresses, 'subject', '', application.Id);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        EmailReceiveApplicationNotification eran = new EmailReceiveApplicationNotification();
        
        Test.startTest();
        Messaging.InboundEmailResult result = eran.handleInboundEmail(email, env);
        Test.stopTest();
        
        System.assert(result.Success);
        
        List<Id> whoIds = new List<Id>{toContact.Id};
        Map<Id, Task> tasks = new Map<Id, Task>([
                SELECT Id, Subject, Description
                FROM Task
                WHERE WhoId IN :whoIds OR WhatId = :application.Id]);
        System.assert(tasks.size() == 1, tasks.size());
        
        List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId IN :tasks.keySet()];
        System.assert(attachments.size() == 1, attachments.size());
    }
}