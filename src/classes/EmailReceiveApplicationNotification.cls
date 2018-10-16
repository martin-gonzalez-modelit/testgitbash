/**
 * For each inbound email, this class inserts a Task (under Activity History)
 * related to each Contact with an email address matching the email's to/from
 * addressess and, if an Application No. or record Id is parsed from the email
 * body, to the indentified Application/record. This class can be used with
 * an Email Service to save a record of Application Notification emails sent
 * via Workflow + Email Alert.
 *
 * @author Jordan Dunn (jdunn@builditgreen.org)
 * @since 2015-3
 */
global class EmailReceiveApplicationNotification implements Messaging.InboundEmailHandler {
    
    private static final Integer APPLICATION_ID_LENGTH = 15;
    private static final String  APPLICATION_ID_PREFIX;
    private static final Integer TASK_DESCRIPTION_MAX_LENGTH;
    
    static {
        try {
            APPLICATION_ID_PREFIX = String.valueOf([SELECT Id FROM Application__c LIMIT 1].Id).substring(0, 3);
            TASK_DESCRIPTION_MAX_LENGTH = Task.Description.getDescribe().getLength();
        } catch (QueryException e) {
            System.debug('EmailReceiveApplicationNotification - A query exception has occurred: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('EmailReceiveApplicationNotification - An exception has occurred: ' + e.getMessage());
        }
    }
    
    /**
     * Returns the Application Id parsed from the email plainTextBody
     * @param plainTextBody the email's plainTextBody String
     * @return              the Application Id as a String 
     */
    private String getApplicationId(Messaging.InboundEmail email) {
        
        String appId = null;
        String body = '';
        
        if (String.isNotBlank(email.htmlBody)) {
            body += email.htmlBody;
        }
        if (String.isNotBlank(email.plainTextBody)) {
            body += email.plainTextBody;
        }
        
        if (body != null && body.contains(APPLICATION_ID_PREFIX)
                && body.substring(body.indexOf(APPLICATION_ID_PREFIX)).length() >= APPLICATION_ID_LENGTH) {
            Integer index = body.indexOf(APPLICATION_ID_PREFIX);
            appId = body.substring(index, (index + APPLICATION_ID_LENGTH));
        }
        
        if (appId != null && (String.isBlank(appId) || !appId.isAlphanumeric())) {
            appId = null;
        }
        
        return appId;
    }
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        List<String> addresses = new List<String>(email.toAddresses);
        if (email.ccAddresses != null && !email.ccAddresses.isEmpty()) {
            addresses.addAll(email.ccAddresses);
        }
        addresses.add(email.fromAddress);
        
        String appId = getApplicationId(email);
        if (appId != null) {
        
            // If the application owner's email address is in addresses, then get their contact Id
            Id ownerContactId;
            try {
                Application__c app = [
                    SELECT OwnerId
                    FROM Application__c
                    WHERE Id = :appId AND Owner.Email IN :addresses LIMIT 1];
                if (app != null && app.OwnerId != null) {
                    ownerContactId = [SELECT ContactId FROM User WHERE Id = :app.OwnerId LIMIT 1].ContactId;
                }
            } catch (QueryException e) {
                System.debug(
                    'EmailReceiveApplicationNotification.handleInboundEmail - A query exception has occurred: '
                    + e.getMessage());
            } catch (Exception e) {
                System.debug(
                    'EmailReceiveApplicationNotification.handleInboundEmail - An exception has occurred: '
                    + e.getMessage());
            }
            
            Boolean isPlainTextBody = false;
            Boolean isHtmlBody = false;
            if (email.plainTextBody != null && String.isNotEmpty(email.plainTextBody)) {
                isPlainTextBody = true;
            }
            if (email.htmlBody != null && String.isNotEmpty(email.htmlBody)) {
                isHtmlBody = true;
            }
            
            // Create Task
            Task task = new Task();
            task.Priority = 'Normal';
            task.Status = 'Completed';
            task.ActivityDate = Date.Today();
            task.Subject = 'Email: ' + email.subject;
            task.IsRecurrence = false;
            task.OwnerID = UserInfo.getUserId();
            
            // Relate the Task to the Application
            task.WhatId = appId;
            
            if (ownerContactId != null) {
                task.WhoId = ownerContactId; // Relate the Task to the Application Owner's Contact
            }
            
            // Construct Description
            String description = 'From: ' + email.fromAddress + '\n';
            if (email.toAddresses != null && !email.toAddresses.isEmpty()) {
                description += 'To: '
                    + (String.valueOf(email.toAddresses)).subString(1, String.valueOf(email.toAddresses).length() - 1)
                    + '\n';
            }
            if (email.ccAddresses != null && !email.ccAddresses.isEmpty()) {
                description += 'Cc: '
                    + (String.valueOf(email.ccAddresses)).subString(1, String.valueOf(email.ccAddresses).length() - 1)
                    + '\n';
            }
            
            // Assign Description
            if (isPlainTextBody) {
                // Append plain text body to Description
                description += ('\n' + email.plainTextBody);
                if (description.length() > TASK_DESCRIPTION_MAX_LENGTH) {
                    task.Description = description.substring(0, TASK_DESCRIPTION_MAX_LENGTH);
                } else {
                   task.Description = description;
                }
            } else if (isHtmlBody) {
                // The html body will be saved as an Attachment
                task.Description = description;
            }
            
            // Insert Task (and Attachment)
            try {
                if (task != null) {
                    insert task;
                    if (isHtmlBody) {
                        Attachment attachment = new Attachment();
                        attachment.Name = 'body.html';
                        attachment.Body = Blob.valueOf(email.htmlBody);
                        attachment.ParentId = task.Id;
                        insert attachment;
                    }
                }
            } catch (DmlException e) {
                System.debug(
                    'EmailReceiveApplicationNotification.handleInboundEmail - A Dml exception has occurred: '
                    + e.getMessage());
            } catch (Exception e) {
                System.debug(
                    'EmailReceiveApplicationNotification.handleInboundEmail - An exception has occurred: '
                    + e.getMessage());
            }
            
            result.success = true;
        } else {
            result.success = false;
        }
        return result;
    }
}